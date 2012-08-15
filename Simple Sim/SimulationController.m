//
//  SimulationController.m
//  Simple Sim
//
//  Created by Martin O'Connor on 09/02/2012.
//  Copyright (c) 2012 OCONNOR RESEARCH. All rights reserved.
//

#import "SimulationController.h"
#import "Simulation.h"
#import "DataController.h"
#import "DataSeriesValue.h"
#import "DataSeries.h"
#import "EpochTime.h"
#import "UtilityFunctions.h"


#define DAY_SECONDS 24*60*60

//6 Minutes to trade
//#define STATIC_LAG 6*60
#define POSITION_CUSHION 0.25

@interface SimulationController()
- (void) tradingSimulation:(NSDictionary *) parameters;
- (void) plotSimulationData:(DataSeries *) dataToPlot;
- (void) addSimulationDataToResultsTableView: (DataSeries *) analysisDataSeries;
@end

@implementation SimulationController

#pragma mark -
#pragma mark Setup Methods 

-(id)init
{
    self = [super init];
    if(self){
        allSimulations = [[NSMutableDictionary alloc] init];
        simData = [[DataController alloc] init];
        [simData setDelegate:self];
        interestRates = [[NSMutableDictionary alloc] init];
        doThreads = NO;
        return self;
    }
    return nil;
}

-(void)setDelegate:(id)del
{
    delegate = del;
}

-(id)delegate 
{ 
    return delegate;
};

- (BOOL) doThreads
{
    return [self doThreads];
}

- (void) setDoThreads:(BOOL)doThreadedProcedures
{
    doThreads = doThreadedProcedures;
    [simData setDoThreads:doThreadedProcedures];
}

#pragma mark -
#pragma mark General Methods

+(BOOL)positioningUnderstood:(NSString *) positioningString
{
    BOOL understood = NO;
    NSArray *positioningComponents = [positioningString componentsSeparatedByString:@"/"];
    if([[positioningComponents objectAtIndex:0] isEqualToString:@"STP"]){
        if([positioningComponents count]==2){
            understood = YES;
        }
    }
    return understood;
}


-(void)askSimulationToCancel
{
    [self setCancelProcedure:YES];
}

-(void)tradingSimulation:(NSDictionary *) parameters
{
    NSString *tradingPair;
    long minDateTime, maxDateTime;
    double nav, cashPosition, debits;
    double unrealisedPnl = 0.0;
    double marginUsed = 0.0;
    double marginAvailable = 0.0;
    double requiredMargin = 0.0;
    
    //Only use these varibles for data request, they may not reflect the actual data returned
    long dataRequestMinDateTime, dataRequestMaxDateTime;
    BOOL allOk = YES;
    BOOL closeOut = NO;
    int dataRequestTruncated = 1;
    NSString *userMessage;
    
    int tradingDayStartHour; 
    int tradingDayEndHour;
    int tradingDayStartMinute; 
    int tradingDayEndMinute; 
    double newSignal = 0.0;
    double currentSignal = 0.0;
    double currentSignalEntryPrice;
    double currentSignalExitPrice;
    double currentSignalMaxUp;
    double currentSignalMaxDown;
    long currentSignalEntryTime;
    long currentSignalExitTime;
    int currentSignalTotalSamples = 0;
    int currentSignalSamplesInProfit = 0;
    BOOL accountCurrencyIsQuoteCurrency = NO;
    Simulation *newSimulation;
    int tradingDayStartSeconds;
    int tradingDayEndSeconds;
    
    cancelProcedure = NO;
    
    NSString *simName = [parameters objectForKey:@"SIMNAME"];
    NSString *baseCode = [parameters objectForKey:@"BASECODE"];
    NSString *quoteCode = [parameters objectForKey:@"QUOTECODE"];
    NSString *accCode = [parameters objectForKey:@"ACCOUNTCODE"];
    long startDateTime = [[parameters objectForKey:@"STARTTIME"] longValue];
    long endDateTime = [[parameters objectForKey:@"ENDTIME"] longValue];
    int maxLeverage = (int)[[parameters objectForKey:@"MAXLEVERAGE"] doubleValue];
    double startingBalance = [[parameters objectForKey:@"STARTBALANCE"] doubleValue];  
    long initialDataBeforeStart = [[parameters objectForKey:@"WARMUPDATA"] longValue]; 
    int timeStep = [[parameters objectForKey:@"TIMESTEP"] intValue];
    int tradingLag = [[parameters objectForKey:@"TRADINGLAG"] intValue];
    NSString *simDescription = [parameters objectForKey:@"SIMTYPE"];
    NSString *positioningString = [parameters objectForKey:@"POSTYPE"]; 
    long tradingDayStart = [[parameters objectForKey:@"TRADINGDAYSTART"] longValue];
    long tradingDayEnd = [[parameters objectForKey:@"TRADINGDAYEND"] longValue];
    BOOL weekendTrading =   [[parameters objectForKey:@"WEEKENDTRADING"] boolValue];
    BOOL userDataGiven =  [[parameters objectForKey:@"USERDATAGIVEN"] boolValue];
    //double signalThreshold = [[parameters objectForKey:@"SIGNALTHRESHOLD"] doubleValue];
    
    double signalThreshold;
    NSArray *positioningComponents = [positioningString componentsSeparatedByString:@"/"];
    if([[positioningComponents objectAtIndex:0] isEqualToString:@"STP"]){
        signalThreshold = [[positioningComponents objectAtIndex:1] doubleValue];
    }else{
        [NSException raise:@"Don't understand positioning:" format:@"%@", positioningString];
        cancelProcedure = YES;
    }
    
    NSArray *userData;
    NSString *userDataFilename;
    int requiredPositionSize = 0;
    
    
    if(!cancelProcedure){
        if(userDataGiven){
            userData = [parameters objectForKey:@"USERDATA"];
            userDataFilename = [parameters objectForKey:@"USERDATAFILE"];
            [simData setData:userData 
                    FromFile:userDataFilename];
        }
    
        if([accCode isEqualToString:quoteCode]){
            accountCurrencyIsQuoteCurrency = YES;
        }

        tradingDayStartHour = tradingDayStart/(60*60) ; 
        tradingDayEndHour = tradingDayEnd/(60*60) ;
        tradingDayStartMinute = (tradingDayStart-(tradingDayStartHour*60*60))%60; 
        tradingDayEndMinute = (tradingDayEnd-(tradingDayEndHour*60*60))%60; 

        tradingPair = [NSString stringWithFormat:@"%@%@",baseCode,quoteCode];
    
        minDateTime = [simData getMinDataDateTimeForPair:tradingPair];
        maxDateTime = [simData getMaxDataDateTimeForPair:tradingPair];
    
        if(startDateTime < (minDateTime + initialDataBeforeStart))
        {
            startDateTime =  minDateTime + initialDataBeforeStart;
        }
        startDateTime = [EpochTime epochTimeAtZeroHour:startDateTime] + timeStep  * ((startDateTime-[EpochTime epochTimeAtZeroHour:startDateTime])/timeStep);
        startDateTime = startDateTime + timeStep;
   
        [self clearUserInterfaceMessages];
        userMessage = [NSString stringWithFormat:@"Starting %@",simName];
        if(doThreads){
            [self performSelectorOnMainThread:@selector(sendMessageToUserInterface:) 
                                   withObject:userMessage waitUntilDone:NO];
        }
    
        // Set up the simulation data object
        tradingDayStartSeconds = (tradingDayStartMinute*60) + (tradingDayStartHour * 60 * 60);
        tradingDayEndSeconds = (tradingDayEndMinute*60) + (tradingDayEndHour * 60 * 60);
        newSimulation = [[Simulation alloc] initWithName: simName 
                                                 AndDate: startDateTime 
                                              AndBalance: startingBalance 
                                             AndCurrency: accCode
                                          AndTradingPair: tradingPair
                                          AndMaxLeverage: maxLeverage];
        [newSimulation setEndDate: endDateTime];
        [newSimulation setSamplingRate: timeStep];
        [newSimulation setTradingLag: tradingLag];
        [newSimulation setSignalParameters: simDescription];
        [newSimulation setPositioningType:positioningString];
        [newSimulation setTradingDayStart: tradingDayStartSeconds];
        [newSimulation setTradingDayEnd: tradingDayEndSeconds]; 
        if(userData){
            [newSimulation setUserAddedData:userDataFilename];
        }
    
        [allSimulations setObject: newSimulation 
                           forKey: simName];
        [self setCurrentSimulation: newSimulation];
    }
    
    //Getting Interest Rate Data
    if(!cancelProcedure){
        userMessage = @"Getting Interest Rate data";
        if(doThreads){
            [self performSelectorOnMainThread:@selector(updateStatus:) withObject:userMessage waitUntilDone:NO];
            [self performSelectorOnMainThread:@selector(readingDatabaseOn) withObject:nil waitUntilDone:NO]; 
        }
    
        NSArray *interestRateSeries;
        if([interestRates objectForKey:[NSString stringWithFormat:@"%@IRBID",baseCode]] == nil){
            interestRateSeries = [simData getAllInterestRatesForCurrency:baseCode AndField:@"BID"];
            [interestRates setValue:interestRateSeries forKey:[NSString stringWithFormat:@"%@IRBID",baseCode]];
        }
        if([interestRates objectForKey:[NSString stringWithFormat:@"%@IRASK",baseCode]] == nil){
            interestRateSeries = [simData getAllInterestRatesForCurrency:baseCode AndField:@"ASK"];
            [interestRates setValue:interestRateSeries forKey:[NSString stringWithFormat:@"%@IRASK",baseCode]];
        }    
        if([interestRates objectForKey:[NSString stringWithFormat:@"%@IRBID",quoteCode]] == nil){
            interestRateSeries = [simData getAllInterestRatesForCurrency:quoteCode AndField:@"BID"];
            [interestRates setValue:interestRateSeries forKey:[NSString stringWithFormat:@"%@IRBID",quoteCode]];
        }
        if([interestRates objectForKey:[NSString stringWithFormat:@"%@IRASK",quoteCode]] == nil){
            interestRateSeries = [simData getAllInterestRatesForCurrency:quoteCode AndField:@"ASK"];
            [interestRates setValue:interestRateSeries forKey:[NSString stringWithFormat:@"%@IRASK",quoteCode]];
        } 
    
        if(doThreads){
            [self performSelectorOnMainThread:@selector(readingDatabaseOff) withObject:nil waitUntilDone:NO]; 
        }
    }
    
    //Getting the initial data
    long simulationDateTime;
    simulationDateTime = startDateTime;
    
    if(!cancelProcedure){
        userMessage = @"Setting up initial data";
        if(doThreads){
            [self performSelectorOnMainThread:@selector(updateStatus:) withObject:userMessage waitUntilDone:NO];
            [self performSelectorOnMainThread:@selector(readingDatabaseOn) withObject:nil waitUntilDone:NO]; 
        }
    
        dataRequestMinDateTime = startDateTime - initialDataBeforeStart;
        dataRequestMaxDateTime = endDateTime;
    
        [newSimulation setDataStartDateTime:dataRequestMinDateTime];
        allOk = [simData setupDataSeriesForName:tradingPair AndStrategy:simDescription];
        if(!allOk){
            userMessage = @"***Problem setting up database***";
            if(doThreads){
                [self performSelectorOnMainThread:@selector(updateStatus:) withObject:userMessage waitUntilDone:NO];
            }
            cancelProcedure = YES;
        }
        allOk = [simData getMoreDataForStartDateTime: dataRequestMinDateTime
                                      AndEndDateTime: dataRequestMaxDateTime
                              AndReturningStatsArray: nil
                            WithRequestTruncatedFlag: &dataRequestTruncated];
        userMessage = @"Data set up";
        if(doThreads){
            [self performSelectorOnMainThread:@selector(updateStatus:) withObject:userMessage waitUntilDone:NO];
            [self performSelectorOnMainThread:@selector(readingDatabaseOff) withObject:nil waitUntilDone:NO]; 
        }
    }

    //Adding the signal variables 
    long *simDateTimes;
    NSArray *fieldNames;
    int fieldIndex;
    NSMutableData *simulationDataArrays; 
    double **simulationData;
    NSMutableData *dateTimesData;
    NSMutableDictionary *simulationDataDictionary;
    
    if(!cancelProcedure){    
        //Creating a timeseries object to store the data that is actually used in the simulation
        fieldNames = [simData getFieldNames];
        long numberOfSimulationSteps = (endDateTime-startDateTime)/timeStep;
        
        dateTimesData = [[NSMutableData alloc] initWithLength:numberOfSimulationSteps * sizeof(long)]; 
        simDateTimes = [dateTimesData mutableBytes];
    
        simulationDataDictionary = [[NSMutableDictionary alloc] initWithCapacity:[fieldNames count]];
        simulationDataArrays = [[NSMutableData alloc] initWithLength:[fieldNames count] * sizeof(double*)];
        simulationData = (double **)[simulationDataArrays mutableBytes];
        for(fieldIndex = 0; fieldIndex < [fieldNames count]; fieldIndex++){
            [simulationDataDictionary setObject:[[NSMutableData alloc] initWithLength:numberOfSimulationSteps * sizeof(double)] forKey:[fieldNames objectAtIndex:fieldIndex]];
            simulationData[fieldIndex] = [[simulationDataDictionary objectForKey:[fieldNames objectAtIndex:fieldIndex]] mutableBytes];
        }
    }
    

    //****ACTUAL START OF THE SIMULATION****//
    NSDictionary *values;
    NSString *currentDateAsString;
    
    if(doThreads && !cancelProcedure){
        userMessage = @"Simulation Loop";
        [self performSelectorOnMainThread:@selector(updateStatus:) withObject:userMessage waitUntilDone:NO];
        [self performSelectorOnMainThread:@selector(progressBarOn) withObject:nil waitUntilDone:NO];
    }
    
    BOOL tradingTime;
    int simStepIndex = 0;
    long timeOfDayInSeconds;

    simulationDateTime = startDateTime;
    signalThreshold = signalThreshold * [[simData dataSeries] pipSize];
    cashPosition = startingBalance;
    nav = startingBalance;

    if(!cancelProcedure){
        do{
            //double slow, fast, mid, bid, ask;
            double dataSignal, mid, bid, ask; 
            BOOL isNewTradeSignal = NO;
            BOOL tradingDay;
            int signalIndex = -1;
            BOOL signalCausesTrade;
            
            tradingDay = YES;
            if(!weekendTrading){
                NSString *dayOfWeek = [[NSDate dateWithTimeIntervalSince1970:simulationDateTime] descriptionWithCalendarFormat:@"%w" timeZone:[NSTimeZone timeZoneWithName:@"GMT"] locale:nil];
                if([dayOfWeek isEqualToString:@"0"] || [dayOfWeek isEqualToString:@"6"]){
                    tradingDay = NO;
                }else{
                    tradingDay = YES;
                }
            }
            timeOfDayInSeconds = simulationDateTime - [EpochTime epochTimeAtZeroHour:simulationDateTime];
            
            if((timeOfDayInSeconds >= tradingDayStartSeconds) && (timeOfDayInSeconds <= tradingDayEndSeconds)){
                tradingTime = YES;
            }else{
                tradingTime = NO;
            }
            tradingTime = tradingTime && tradingDay;
            // First make sure the data is in order
           
            //If the current date is greater than the last day of data we need to move the data forward
            if(simulationDateTime > [simData getMaxDateTimeForLoadedData] )
            {
                dataRequestMinDateTime = [simData getMaxDateTimeForLoadedData];
                if((simulationDateTime) > endDateTime){
                    dataRequestMaxDateTime = simulationDateTime + 3*DAY_SECONDS + tradingLag;
                }else{
                    dataRequestMaxDateTime = endDateTime + 3*DAY_SECONDS  + tradingLag;
                }          
               if(doThreads){
                    [self performSelectorOnMainThread:@selector(updateStatus:) withObject:userMessage waitUntilDone:NO];
                    [self performSelectorOnMainThread:@selector(readingDatabaseOn) withObject:nil waitUntilDone:NO]; 
                }
                
                [simData getMoreDataForStartDateTime: dataRequestMinDateTime
                                      AndEndDateTime: dataRequestMaxDateTime
                              AndReturningStatsArray: nil 
                            WithRequestTruncatedFlag: &dataRequestTruncated];
                if(dataRequestTruncated == 0){
                    endDateTime = MIN(endDateTime,[simData getMaxDateTimeForLoadedData]);
                }
                if(doThreads){
                    [self performSelectorOnMainThread:@selector(readingDatabaseOff) withObject:nil waitUntilDone:NO];
                }
            }
            
            //Check we successfully have data for the required date 
            if(simulationDateTime > [simData getMaxDateTimeForLoadedData]){
                [NSException raise:@"DataSeries does not cover current date" format:@"Max: %l current %l ",[simData getMaxDateTimeForLoadedData],simulationDateTime];
            }
            values = [simData getValuesForFields: fieldNames AtDateTime:simulationDateTime ];
        
            if(![[values objectForKey:@"SUCCESS"] boolValue])
            {
                userMessage = @"Data Problem, Stopping....";
                [NSException raise: @"Data Problem in getValuesForFields" format:@"datetime %d",simulationDateTime];
            }
            simDateTimes[simStepIndex] = [[values objectForKey:@"DATETIME"] longValue];
            for(fieldIndex=0;fieldIndex<[fieldNames count];fieldIndex++){
                simulationData[fieldIndex][simStepIndex] = [[values objectForKey:[fieldNames objectAtIndex:fieldIndex]] doubleValue];
            }
 
            // Here we check the signal and act accordingly
            mid = [[values objectForKey:@"MID"] doubleValue];
            bid = [[values objectForKey:@"BID"] doubleValue];
            ask =  [[values objectForKey:@"ASK"] doubleValue];
            dataSignal = [[values objectForKey:@"SIGNAL"] doubleValue]; 
            
            
            if(simulationDateTime+timeStep > endDateTime || closeOut){
                newSignal = 0.0;
                signalCausesTrade = NO;
                tradingTime = YES;
            }else{
                newSignal = dataSignal;
                signalCausesTrade = YES;
            }
            
            //This part deals with with signal and price performance
            isNewTradeSignal = NO;
            if(currentSignal >= signalThreshold && newSignal < signalThreshold){
                isNewTradeSignal = YES;
            }
            if(currentSignal <= -signalThreshold && newSignal > -signalThreshold){
                isNewTradeSignal = YES;
            }
            if(fabs(currentSignal) < signalThreshold && fabs(newSignal) > signalThreshold){
                isNewTradeSignal = YES;
            }
            //[UtilityFunctions signOfDouble:currentSignal] != [UtilityFunctions signOfDouble:newSignal]
            if(isNewTradeSignal && tradingTime){
                if(fabs(currentSignal) >= signalThreshold){
                    currentSignalTotalSamples++;
                    if(currentSignal >= signalThreshold){
                        currentSignalMaxUp = fmaxf(currentSignalMaxUp, bid - currentSignalEntryPrice);
                        currentSignalMaxDown = fminf(currentSignalMaxUp, bid - currentSignalEntryPrice); 
                        if((bid - currentSignalEntryPrice) >= 0){
                            currentSignalSamplesInProfit++;
                        }
                    }
                    if(currentSignal < 0)
                    {
                        currentSignalMaxUp = fmaxf(currentSignalMaxUp, currentSignalEntryPrice - ask);
                        currentSignalMaxDown = fminf(currentSignalMaxDown,currentSignalEntryPrice - ask); 
                        if(currentSignalEntryPrice - ask){
                            currentSignalSamplesInProfit++;
                        }
                    }
                    currentSignalExitPrice = (currentSignal > 0) ? bid : ask;
                    currentSignalExitTime = simulationDateTime;
                    signalIndex = [newSimulation  addSignalStatisticsWithSignal:currentSignal
                                                               AndEntryTime:currentSignalEntryTime
                                                                AndExitTime:currentSignalExitTime
                                                              AndEntryPrice:currentSignalEntryPrice
                                                               AndExitPrice:currentSignalExitPrice
                                                            AndTimeInProfit:(double)currentSignalSamplesInProfit/currentSignalTotalSamples
                                                      AndMaxPotentialProfit:currentSignalMaxUp/currentSignalEntryPrice
                                                        AndMaxPotentialLoss:currentSignalMaxDown/currentSignalEntryPrice];
                }
                currentSignal = newSignal;
                currentSignalEntryPrice = (currentSignal > 0) ? ask : bid; 
                currentSignalEntryTime = simulationDateTime;
                currentSignalMaxDown = 0.0;
                currentSignalMaxUp = 0.0;
                currentSignalTotalSamples = 0;
                currentSignalSamplesInProfit = 0;
            }else{
                currentSignalTotalSamples++;
                if(currentSignal > 0){
                    currentSignalMaxUp = fmaxf(currentSignalMaxUp, bid - currentSignalEntryPrice);
                    currentSignalMaxDown = fminf(currentSignalMaxUp, bid - currentSignalEntryPrice); 
                    if((bid - currentSignalEntryPrice) >= 0){
                        currentSignalSamplesInProfit++;
                    }
                }
                if(currentSignal <0)
                {
                    currentSignalMaxUp = fmaxf(currentSignalMaxUp, currentSignalEntryPrice - ask);
                     currentSignalMaxDown = fminf(currentSignalMaxDown,currentSignalEntryPrice - ask); 
                    if(currentSignalEntryPrice - ask){
                        currentSignalSamplesInProfit++;
                    }
                }
            }
            
            //This part deals with turning signal in a position
            
            if(isNewTradeSignal){
                // Check our margin available before we can trade
                unrealisedPnl = 0.0;
                marginUsed = 0.0;
                if([newSimulation currentExposure] > 0)
                {
                    unrealisedPnl = [newSimulation currentExposure] * (bid - [newSimulation wgtAverageCostOfPosition]);
                 }else{
                    if([newSimulation currentExposure] < 0){
                        unrealisedPnl = [newSimulation currentExposure] * (ask - [newSimulation wgtAverageCostOfPosition]);
                    }
                    
                }
                if(!accountCurrencyIsQuoteCurrency){
                    if(unrealisedPnl > 0){
                        unrealisedPnl = unrealisedPnl/ask;
                    }
                    if(unrealisedPnl < 0){
                        unrealisedPnl = unrealisedPnl/bid;
                    }
                }
                if(accountCurrencyIsQuoteCurrency){
                    if([newSimulation currentExposure] > 0){
                        marginUsed = fabsf([newSimulation currentExposure] * ask / maxLeverage);
                    }else{
                        marginUsed = fabsf([newSimulation currentExposure] * bid / maxLeverage);
                    }
                }else{
                    marginUsed = fabsf([newSimulation currentExposure] / maxLeverage);
                    
                }
                nav = cashPosition + unrealisedPnl;
                marginAvailable = nav - marginUsed;
                
                // This is temporary, need to properly specify position sizing
                if(accountCurrencyIsQuoteCurrency){ 
                    requiredPositionSize =  floor((1-POSITION_CUSHION) * nav/ask * maxLeverage);
                }else{
                    requiredPositionSize =  floor((1-POSITION_CUSHION) * nav * maxLeverage);
                }
                
                //NSLog(@"%f", marginAvailable);
                
                if(currentSignal >= signalThreshold){
                    if(accountCurrencyIsQuoteCurrency){
                        requiredMargin = fabsf((requiredPositionSize*ask)/maxLeverage);
                    }else{
                        requiredMargin = fabsf((requiredPositionSize)/maxLeverage);
                    }
                    if(requiredMargin > (1-POSITION_CUSHION)*nav){
                        [NSException raise:@"Fix this" format:@""];
                        if(accountCurrencyIsQuoteCurrency){ 
                            requiredPositionSize =  floor((1-POSITION_CUSHION) * nav/ask * maxLeverage);
                        }else{
                            requiredPositionSize =  floor((1-POSITION_CUSHION) * maxLeverage);
                        }
                    }
                                   
                    if([newSimulation currentExposure] <= 0)
                    {
                        debits = [self setExposureToUnits: requiredPositionSize 
                                               AtTimeDate: simulationDateTime + tradingLag
                                            ForSimulation: newSimulation
                                           AndSignalIndex: signalIndex];
                    }
                }else{
                    if(currentSignal <= -signalThreshold){
                        if(accountCurrencyIsQuoteCurrency){
                            requiredMargin = fabsf((requiredPositionSize*bid)/maxLeverage);
                        }else {
                            requiredMargin = fabsf(requiredPositionSize/maxLeverage);
                        }
                        if(requiredMargin > (1-POSITION_CUSHION)*nav){
                            [NSException raise:@"Fix this" format:@""];
                            if(accountCurrencyIsQuoteCurrency){ 
                                requiredPositionSize =  floor((1-POSITION_CUSHION) * nav/ask * maxLeverage);
                            }else{
                                requiredPositionSize =  floor((1-POSITION_CUSHION) * maxLeverage);
                            }
                      
                        }
                        
                        if([newSimulation currentExposure] >= 0)
                        {
                            debits = [self setExposureToUnits:-1*requiredPositionSize
                                                   AtTimeDate:simulationDateTime + tradingLag
                                                ForSimulation: newSimulation
                                               AndSignalIndex:signalIndex];
                        }
                    }else{
                        if(fabs(currentSignal) < signalThreshold){
                            if([newSimulation currentExposure] != 0)
                            {
                                debits = [self setExposureToUnits:0
                                                       AtTimeDate:simulationDateTime + tradingLag
                                                    ForSimulation: newSimulation
                                                   AndSignalIndex:signalIndex];
                            }
                        }
                    }
                }
                cashPosition = cashPosition + debits;
                debits = 0.0;
                nav = cashPosition;
                unrealisedPnl = 0.0;
            }else{
                unrealisedPnl = 0.0;
                if([newSimulation currentExposure] > 0)
                {
                    unrealisedPnl = [newSimulation currentExposure] * (bid - [newSimulation wgtAverageCostOfPosition]);
                }else{
                    if([newSimulation currentExposure] < 0){
                        unrealisedPnl = [newSimulation currentExposure] * (ask - [newSimulation wgtAverageCostOfPosition]);
                    }
                }
                if(!accountCurrencyIsQuoteCurrency){
                    if(unrealisedPnl > 0){
                        unrealisedPnl = unrealisedPnl/ask;
                    }else{
                        unrealisedPnl = unrealisedPnl/bid;
                    }
                }
                nav = cashPosition + unrealisedPnl;
            }
            if(accountCurrencyIsQuoteCurrency){
                if([newSimulation currentExposure] > 0)
                {
                    marginUsed = fabsf([newSimulation currentExposure] * ask / maxLeverage);
                }else{
                    marginUsed = fabsf([newSimulation currentExposure] * bid / maxLeverage);
                }
            }else{
                marginUsed = fabsf([newSimulation currentExposure]  / maxLeverage);
            }

            if((marginUsed/2) >= nav){
                closeOut = YES;
            }
            
            simulationDateTime= simulationDateTime+timeStep;
            simStepIndex++;
            //NSLog(@"%@ CASH:%f NAV:%f",[EpochTime stringDateWithTime:simulationDateTime], cashPosition, nav);
            if(doThreads){
                [self performSelectorOnMainThread:@selector(progressAsFraction:) 
                                       withObject:[NSNumber numberWithDouble:(double)(simulationDateTime - startDateTime)/(endDateTime - startDateTime) ] waitUntilDone:NO];
            }
        }while((simulationDateTime <= endDateTime)   && allOk && !cancelProcedure);
    }
     
    if(!cancelProcedure){
        currentDateAsString = [EpochTime stringDateWithTime:simulationDateTime]; 
        userMessage = [NSString stringWithFormat:@"%@ Finished Simulation",currentDateAsString];
        if(doThreads){
            [self performSelectorOnMainThread:@selector(updateStatus:) withObject:userMessage waitUntilDone:NO];
        }  
    }
    
    if(doThreads){
        [self performSelectorOnMainThread:@selector(progressBarOff) withObject:nil waitUntilDone:YES];
    }
    //***END OF THE SIMULATION****//
    
    if(!cancelProcedure)
    {
        DataSeries *simulationDataSeries;
        simulationDataSeries = [simData createNewDataSeriesWithXData: dateTimesData
                                                            AndYData: simulationDataDictionary 
                                                       AndSampleRate: timeStep];
        [newSimulation setSimulationDataSeries:simulationDataSeries];
    
        userMessage = @"----Details----";
        if(doThreads){
            [self performSelectorOnMainThread:@selector(sendMessageToUserInterface:) withObject:userMessage waitUntilDone:NO];
        }
    
        int numberOfTrades = [newSimulation numberOfTrades];
        userMessage = [NSString stringWithFormat:@"There were %ld transactions",numberOfTrades];
        if(doThreads){
            [self performSelectorOnMainThread:@selector(sendMessageToUserInterface:) withObject:userMessage waitUntilDone:NO];
        }     
    
        for(int iTrade = 0; iTrade < numberOfTrades; iTrade++){
            userMessage = [newSimulation getTradeDetailToPrint:iTrade];
            if(doThreads){
                [self performSelectorOnMainThread:@selector(sendMessageToUserInterface:) withObject:userMessage waitUntilDone:NO];
            }
        }
        int numberOfBalanceAdjustments = [newSimulation numberOfBalanceAdjustments];
        userMessage = [NSString stringWithFormat:@"There were %ld balance Adjustments",numberOfBalanceAdjustments];
        if(doThreads){
            [self performSelectorOnMainThread:@selector(sendMessageToUserInterface:) withObject:userMessage waitUntilDone:NO];
        }  

        for(int iBalAdj = 0; iBalAdj < numberOfBalanceAdjustments; iBalAdj++)
        {
            userMessage = [newSimulation getBalanceDetailToPrint:iBalAdj];
            if(doThreads){
                [self performSelectorOnMainThread:@selector(sendMessageToUserInterface:) withObject:userMessage waitUntilDone:NO];
            }
        }
        NSDictionary *performanceAttribution;
        NSArray *perfAttribKeys;
        NSString *perfAttribMessage;
        performanceAttribution = [newSimulation getPerformanceAttribution];
        perfAttribKeys = [performanceAttribution allKeys];
        for(int i = 0; i < [perfAttribKeys count]; i++){
            double amount = [[performanceAttribution objectForKey:[perfAttribKeys objectAtIndex:i]] doubleValue];
            NSString *reason = [perfAttribKeys objectAtIndex:i];                 
            perfAttribMessage = [NSString stringWithFormat:@"%@     :%5.2f",reason,amount];
            if(doThreads){
                [self performSelectorOnMainThread:@selector(sendMessageToUserInterface:) withObject:perfAttribMessage waitUntilDone:NO];
            }
        }
    }

    if(!cancelProcedure)
    {
        userMessage = @"Analysing The Simulation";
        if(doThreads){
            [self performSelectorOnMainThread:@selector(updateStatus:) withObject:userMessage waitUntilDone:NO];
        }
    
        [self analyseSimulation:newSimulation];
        
    }
    if(cancelProcedure){
        userMessage = @"Simulation Cancelled";
        if(doThreads){
            [self performSelectorOnMainThread:@selector(updateStatus:) withObject:userMessage waitUntilDone:NO];
        }else{
            [self updateStatus:userMessage];
        }
    }
    [self simulationEnded];
}

-(void)analyseSimulation: (Simulation *) simulation
{
    NSString *userMessage;
    DataSeries *positionDataSeries;
    DataSeries *simulationDataSeries;
    NSDictionary *currentDataValues;
    NSArray *simDataFieldNames;
    
    NSMutableData *dateTimesData;
    long *dateTimesArray;
    NSMutableDictionary *simulationDataDictionary;
    NSMutableData *simulationDataArrayData;
    double **simulationDataArray;
    NSMutableData *signalData;
    double *signalArray;
    NSMutableData *marketPositionData;
    double *marketPositionArray;
    NSMutableData *shortIndicatorData;
    double *shortIndicatorArray;
    NSMutableData *longIndicatorData;
    double *longIndicatorArray;
    NSMutableData *marginUsedData;
    double *marginUsedArray;
    NSMutableData *marginAvailableData;
    double *marginAvailableArray;
    NSMutableData *marginCloseOutData;
    double *marginCloseOutArray;
    NSMutableData *cashPositionData;
    double *cashPositionArray;
    NSMutableData *navData;
    double *navArray;
    NSMutableData *drawDownData;
    double *drawDownArray;
    NSMutableData *positionAvePriceData;
    double *positionAvePriceArray;
    
    int dateCount = 0, timeStep = 0, tradeIndex, signalIndex, cashMoveIndex;
    double signal, currentSignal;
    long startDateTime, endDateTime, stepDateTime, nextTradeDateTime;
    BOOL allTradesFinished, allCashMovesFinished;
    int dataRequestTruncated = 1;
    
    long signalStartDateTime, signalEndDateTime, nextCashMoveDateTime;
    double nextCashMoveAmount, allCashTransfers = 0.0;
    NSString *nextCashMoveReason;
    NSDictionary *tradeDetails;
    NSDictionary *signalDetails;
    NSDictionary *cashMoveDetails;
    BOOL accountCurrencyIsQuoteCurrency;
    NSMutableArray *positionDateTime = [[NSMutableArray alloc] init];
    NSMutableArray *positionAmount = [[NSMutableArray alloc] init];
    NSMutableArray *positionPrice = [[NSMutableArray alloc] init];
    
    int currentPosition, currentPositionSign;
    long currentDateTime;
    double currentBid = 0.0,currentAsk = 0.0;
    double nextTradeAmount, nextTradePrice, currentCashBalance, tradePnl, interestCosts;
    double largestDrawdown;
    long largestDrawdownDateTime;
    double currentMaximumNav, spreadCost= 0.0;
    int arraySize;
    long dataRequestMinDateTime, dataRequestMaxDateTime;
    
    simulationDataSeries = [simulation simulationDataSeries];
    simDataFieldNames = [simulationDataSeries getFieldNames];
    
    startDateTime = [simulation startDate];
    endDateTime = [simulation endDate];
    timeStep = [simulation samplingRate];
     
    cashMoveIndex = 0;
    allCashMovesFinished = NO;
    nextCashMoveDateTime = [simulation getDateTimeForBalanceAdjustmentAtIndex:cashMoveIndex];
    
    tradeIndex = 0;
    allTradesFinished = NO;
    if([simulation numberOfTrades] >0){
        nextTradeDateTime = [simulation getDateTimeForTradeAtIndex:tradeIndex];
    
        NSMutableArray *activityDates = [[NSMutableArray alloc] init];
        long activityDateTime;
        int activityIndex = 0;
        BOOL allActivityFinished;
    
        activityDateTime = startDateTime;
    
        // Get an array of all datetimes related to trading and cash movements
        // If these are not included in the regular (sampled at interval)dates 
        // of analysis they have to be stuck in
    
        while(!allCashMovesFinished && !allTradesFinished){
            if(nextCashMoveDateTime < nextTradeDateTime){
                if(activityDateTime != nextCashMoveDateTime){
                    [activityDates addObject:[NSNumber numberWithLong:nextCashMoveDateTime]];
                    activityDateTime = nextCashMoveDateTime;
                }
                
                cashMoveIndex++;
                if(cashMoveIndex < [simulation numberOfBalanceAdjustments]){
                    nextCashMoveDateTime = [simulation getDateTimeForBalanceAdjustmentAtIndex:cashMoveIndex];
                }else{
                    allCashMovesFinished = YES;
                }
            }else{
                if(nextTradeDateTime != activityDateTime){
                    [activityDates addObject:[NSNumber numberWithLong:nextTradeDateTime]];
                    activityDateTime = nextTradeDateTime;
                }
                tradeIndex++;
                if(tradeIndex < [simulation numberOfTrades]){
                    nextTradeDateTime = [simulation getDateTimeForTradeAtIndex:tradeIndex];
                }else{
                    allTradesFinished = YES;
                }
            }
        }
        while(!allCashMovesFinished){
            if(activityDateTime != nextCashMoveDateTime){
                [activityDates addObject:[NSNumber numberWithLong:nextCashMoveDateTime]];
                activityDateTime = nextCashMoveDateTime;
            }
        
            cashMoveIndex++;
            if(cashMoveIndex < [simulation numberOfBalanceAdjustments]){
                nextCashMoveDateTime = [simulation getDateTimeForBalanceAdjustmentAtIndex:cashMoveIndex];
            }else{
                allCashMovesFinished = YES;
            }
        }
        while(!allTradesFinished){
            if(nextTradeDateTime != activityDateTime){
                [activityDates addObject:[NSNumber numberWithLong:nextTradeDateTime]];
                activityDateTime = nextTradeDateTime;
            }
            tradeIndex++;
            if(tradeIndex < [simulation numberOfTrades]){
                nextTradeDateTime = [simulation getDateTimeForTradeAtIndex:tradeIndex];
            }else{
                allTradesFinished = YES;
            }
        }   
    
        NSMutableArray *dateTimesOfAnalysis = [[NSMutableArray alloc] init];
    
        activityIndex = 0;
        activityDateTime = [[activityDates objectAtIndex:activityIndex] longValue];
        allActivityFinished = NO;
        stepDateTime = startDateTime;
        do{
            if(activityIndex != [activityDates count]){
                if(stepDateTime >= activityDateTime){
                    //If the next Date doesn't fall on the sample time add in an extra 
                    if(stepDateTime > activityDateTime){
                        [dateTimesOfAnalysis addObject:[NSNumber numberWithLong:activityDateTime]];
                    }
                    activityIndex++;
                    if(activityIndex<[activityDates count]){
                        activityDateTime = [[activityDates objectAtIndex:activityIndex] longValue];
                        if(activityDateTime > endDateTime)
                        {
                            endDateTime = activityDateTime;
                        }
                    }else{
                        allActivityFinished = YES;
                    }
                }
                [dateTimesOfAnalysis addObject:[NSNumber numberWithLong:stepDateTime]];
            }else{
                [dateTimesOfAnalysis addObject:[NSNumber numberWithLong:stepDateTime]];
            }
  
            stepDateTime = stepDateTime + timeStep;
        }while((stepDateTime <= endDateTime || !allActivityFinished) && !cancelProcedure);
    
        arraySize = [dateTimesOfAnalysis count] - 1;
    
        if(!cancelProcedure){
            dateTimesData = [[NSMutableData alloc] initWithLength:arraySize * sizeof(long)]; 
            dateTimesArray = [dateTimesData mutableBytes];
            
            signalData = [[NSMutableData alloc] initWithLength:arraySize * sizeof(double)];
            signalArray = [signalData mutableBytes];
            
            marketPositionData = [[NSMutableData alloc] initWithLength:arraySize * sizeof(double)]; 
            marketPositionArray = [marketPositionData mutableBytes];
        
            shortIndicatorData = [[NSMutableData alloc] initWithLength:arraySize * sizeof(double)]; 
            shortIndicatorArray = [shortIndicatorData mutableBytes];
    
            longIndicatorData = [[NSMutableData alloc] initWithLength:arraySize * sizeof(double)]; 
            longIndicatorArray = [longIndicatorData mutableBytes];
        
            marginUsedData = [[NSMutableData alloc] initWithLength:arraySize * sizeof(double)];
            marginUsedArray = [marginUsedData mutableBytes];
            
            marginAvailableData = [[NSMutableData alloc] initWithLength:arraySize * sizeof(double)];
            marginAvailableArray = [marginAvailableData mutableBytes];
           
            marginCloseOutData = [[NSMutableData alloc] initWithLength:arraySize * sizeof(double)];
            marginCloseOutArray = [marginCloseOutData mutableBytes];
     
            cashPositionData = [[NSMutableData alloc] initWithLength:arraySize * sizeof(double)]; 
            cashPositionArray = [cashPositionData mutableBytes]; 
        
            navData = [[NSMutableData alloc] initWithLength:arraySize * sizeof(double)]; 
            navArray = [navData mutableBytes]; 
        
            drawDownData = [[NSMutableData alloc] initWithLength:arraySize * sizeof(double)]; 
            drawDownArray = [drawDownData mutableBytes]; 
        
            positionAvePriceData = [[NSMutableData alloc] initWithLength:arraySize * sizeof(double)];
            positionAvePriceArray = [positionAvePriceData mutableBytes]; 
        
            //    
            simulationDataDictionary = [[NSMutableDictionary alloc] initWithCapacity:[simDataFieldNames count]];
            simulationDataArrayData = [[NSMutableData alloc] initWithLength:[simDataFieldNames count] * sizeof(double*)];
            simulationDataArray = (double **)[simulationDataArrayData mutableBytes];
            for(int fieldIndex = 0; fieldIndex < [simDataFieldNames count]; fieldIndex++){
                [simulationDataDictionary setObject:[[NSMutableData alloc] initWithLength:arraySize * sizeof(double)] forKey:[simDataFieldNames objectAtIndex:fieldIndex]];
                simulationDataArray[fieldIndex] = [[simulationDataDictionary objectForKey:[simDataFieldNames objectAtIndex:fieldIndex]] mutableBytes];
            }
        }
    
        if(!cancelProcedure){
            //This ensures that ac variables are similar and there is no problems 
            // due to not getting the first price, which may be slightly older 
            // than the start time of the simulation
            dataRequestMinDateTime = [simulation dataStartDateTime];
            dataRequestMaxDateTime = endDateTime;
        
            if(doThreads){
                [self performSelectorOnMainThread:@selector(readingDatabaseOn) withObject:nil waitUntilDone:NO]; 
            }
      
            if(![simData getMoreDataForStartDateTime: dataRequestMinDateTime
                                      AndEndDateTime: dataRequestMaxDateTime
                              AndReturningStatsArray: nil
                            WithRequestTruncatedFlag: &dataRequestTruncated]){
                [NSException raise:@"Database problem" 
                        format:nil];
            }
    
            if(doThreads){
                [self performSelectorOnMainThread:@selector(readingDatabaseOff) withObject:nil waitUntilDone:NO];
            }
        }
    
        dateCount = 0;
        currentPosition = 0;
        currentPositionSign = 0;
        currentCashBalance = 0.0;
        currentMaximumNav = 0.0;
    
        if([[simulation accCode] isEqualToString:[simulation quoteCode]]){
            accountCurrencyIsQuoteCurrency = YES;
        }else{
            accountCurrencyIsQuoteCurrency = NO;
        }
    
        // Get the first signal
        signalIndex = 0;
        signalDetails = [simulation detailsOfSignalAtIndex:signalIndex];
        signalStartDateTime = [[signalDetails objectForKey:@"ENTRYTIME"] longValue];
        signalEndDateTime = [[signalDetails objectForKey:@"EXITTIME"] longValue];
        signal = [[signalDetails objectForKey:@"SIGNAL"] doubleValue];
    
        cashMoveIndex = 0;
        allCashMovesFinished = NO;
        cashMoveDetails = [simulation detailsOfBalanceAdjustmentIndex:cashMoveIndex];
        nextCashMoveDateTime = [[cashMoveDetails objectForKey:@"DATETIME"] longValue];
        nextCashMoveAmount = [[cashMoveDetails objectForKey:@"AMOUNT"] doubleValue]; 
        nextCashMoveReason = [cashMoveDetails objectForKey:@"REASON"]; 
    
        tradeIndex = 0;
        allTradesFinished = NO;
        tradeDetails = [simulation detailsOfTradeAtIndex:tradeIndex];
        nextTradeDateTime = [[tradeDetails objectForKey:@"DATETIME"] longValue];
        nextTradeAmount = [[tradeDetails objectForKey:@"AMOUNT"] intValue];
        nextTradePrice = [[tradeDetails objectForKey:@"PRICE"] doubleValue];
    
        tradePnl = 0.0;
        interestCosts = 0.0;
        largestDrawdown = 0.0;
    
        // Main loop
        [self performSelectorOnMainThread:@selector(progressBarOn) withObject:nil waitUntilDone:NO];
    
        for(int dateIndex = 0; dateIndex < [dateTimesOfAnalysis count]; dateIndex++)
        {
            currentDateTime = [[dateTimesOfAnalysis objectAtIndex:dateIndex] longValue];
            
            // Update the database if needed
            if(currentDateTime > [simData getMaxDateTimeForLoadedData])
            {
                if(doThreads){
                    [self performSelectorOnMainThread:@selector(readingDatabaseOn) withObject:nil waitUntilDone:NO]; 
                }
                dataRequestMinDateTime = [simData getMaxDateTimeForLoadedData];
                dataRequestMaxDateTime = MAX(currentDateTime,endDateTime);
                [simData getMoreDataForStartDateTime: dataRequestMinDateTime
                                      AndEndDateTime: dataRequestMaxDateTime
                              AndReturningStatsArray: nil
                            WithRequestTruncatedFlag: &dataRequestTruncated];
                if(doThreads){
                    [self performSelectorOnMainThread:@selector(readingDatabaseOff) 
                                           withObject:nil 
                                        waitUntilDone:NO];
                }   
            }
        
            // Get the price data values for today
            currentDataValues = [simData getValuesForFields:simDataFieldNames 
                                                 AtDateTime:currentDateTime];
        
            for(int fieldIndex = 0; fieldIndex < [simDataFieldNames count]; fieldIndex++){
                simulationDataArray[fieldIndex][dateIndex] = [[currentDataValues objectForKey:[simDataFieldNames objectAtIndex:fieldIndex]] doubleValue];
            }
        
            currentBid = [[currentDataValues objectForKey:@"BID"] doubleValue];
            currentAsk = [[currentDataValues objectForKey:@"ASK"] doubleValue];
        
            //Add in the trades and any cash moves 
            if(currentDateTime == nextTradeDateTime){
                if(currentPosition > 0){
                    currentPositionSign = 1;
                }   
                if(currentPosition < 0){
                    currentPositionSign = -1;
                }
                //If the trade is from a position of zero or increasing the size of the trade
                if(currentPosition ==0 || (currentPositionSign * nextTradeAmount) > 0){
                    [positionDateTime addObject:[NSNumber numberWithLong:nextTradeDateTime]]; 
                    [positionAmount addObject:[NSNumber numberWithInt:nextTradeAmount]];
                    [positionPrice addObject:[NSNumber numberWithDouble:nextTradePrice]];
                    if(accountCurrencyIsQuoteCurrency){
                        spreadCost = spreadCost + (ABS(nextTradeAmount) * (currentBid - currentAsk));
                    }else{
                        spreadCost = spreadCost + (ABS(nextTradeAmount) * (currentBid - currentAsk))/currentBid;
                    }
                }else{
                    // If the next trade is on the opposite side of the current positions
                    // we start by reducing current positions towards zero
                    int remainingTrade = nextTradeAmount;
                    int numberOfTradesToRemove = 0;
                    while(remainingTrade != 0){
                        if([positionDateTime count] ==0){
                            // Don't think this code is ever used but can't think straight now, starbucks music!
                            [positionDateTime addObject:[NSNumber numberWithLong:nextTradeDateTime]]; 
                            [positionAmount addObject:[NSNumber numberWithInt:remainingTrade]];
                            [positionPrice addObject:[NSNumber numberWithDouble:nextTradePrice]]; 
                            if(accountCurrencyIsQuoteCurrency){
                                spreadCost = spreadCost + (ABS(remainingTrade) * (currentBid - currentAsk));
                            }else{
                                spreadCost = spreadCost + (ABS(remainingTrade) * (currentBid - currentAsk)/currentBid);
                            }
                        }else{
                            int positionIndex = 0;
                            int openPositionAmount = 0;
                            while((positionIndex < [positionDateTime count]) && (remainingTrade != 0)){
                                openPositionAmount = [[positionAmount objectAtIndex:positionIndex] intValue];
                                if(ABS(openPositionAmount) > ABS(remainingTrade)){
                                    [positionAmount replaceObjectAtIndex:positionIndex withObject:[NSNumber numberWithInt:openPositionAmount - remainingTrade]];
                                    remainingTrade = 0;
                                }else{
                                    remainingTrade = remainingTrade + openPositionAmount;
                                    numberOfTradesToRemove++;
                                }
                                positionIndex++;
                            }
                            if(remainingTrade != 0){
                                [positionDateTime addObject:[NSNumber numberWithLong:nextTradeDateTime]]; 
                                [positionAmount addObject:[NSNumber numberWithInt:remainingTrade]];
                                [positionPrice addObject:[NSNumber numberWithDouble:nextTradePrice]];
                                if(accountCurrencyIsQuoteCurrency){
                                    spreadCost = spreadCost + (ABS(remainingTrade) * (currentBid - currentAsk));
                                }else{
                                    spreadCost = spreadCost + (ABS(remainingTrade) * (currentBid - currentAsk)/currentBid);
                                }
                                remainingTrade = 0;
                            }   
                        }
                    }
                    // Remove any trades which have been fully closed out 
                    if(numberOfTradesToRemove > 0){
                        for(int i = 0;i < numberOfTradesToRemove; i++){
                            [positionDateTime removeObjectAtIndex:0];
                            [positionAmount removeObjectAtIndex:0];
                            [positionPrice removeObjectAtIndex:0];
                        }
                    }
                }
                       
                currentPosition = currentPosition + nextTradeAmount;
                tradeIndex++;
                if(tradeIndex == [simulation numberOfTrades]){
                    allTradesFinished = YES;
                }else{
                    tradeDetails = [simulation detailsOfTradeAtIndex:tradeIndex];
                    nextTradeDateTime = [[tradeDetails objectForKey:@"DATETIME"] longValue];
                    nextTradeAmount = [[tradeDetails objectForKey:@"AMOUNT"] intValue];
                    nextTradePrice = [[tradeDetails objectForKey:@"PRICE"] doubleValue];
                }
            }
        
            //Cash Balance
            while(nextCashMoveDateTime == currentDateTime && !allCashMovesFinished){
                currentCashBalance = currentCashBalance + nextCashMoveAmount;
                if([nextCashMoveReason isEqualToString:@"TRANSFER"]){
                    allCashTransfers = allCashTransfers + nextCashMoveAmount;
                }
                if([nextCashMoveReason isEqualToString:@"TRADE PNL"]){
                    tradePnl = tradePnl + nextCashMoveAmount;
                }
                if([nextCashMoveReason isEqualToString:@"INTEREST"]){
                    interestCosts = interestCosts + nextCashMoveAmount;
                }
                if(cashMoveIndex < ([simulation numberOfBalanceAdjustments]-1)){
                    cashMoveIndex++;
                    cashMoveDetails = [simulation detailsOfBalanceAdjustmentIndex:cashMoveIndex];
                    nextCashMoveDateTime = [[cashMoveDetails objectForKey:@"DATETIME"] longValue];
                    nextCashMoveAmount = [[cashMoveDetails objectForKey:@"AMOUNT"] doubleValue];
                    nextCashMoveReason =  [cashMoveDetails objectForKey:@"REASON"];
                }else{
                    allCashMovesFinished = YES;
                }
            }
                     
            // Update the signal as needed 
            while((signalEndDateTime <= currentDateTime) && (signalIndex < ([simulation numberOfSignals]-1))){
                signalIndex++;
                signalDetails = [simulation detailsOfSignalAtIndex:signalIndex];
                signalStartDateTime = [[signalDetails objectForKey:@"ENTRYTIME"] longValue];
                signalEndDateTime = [[signalDetails objectForKey:@"EXITTIME"] longValue];
                signal = [[signalDetails objectForKey:@"SIGNAL"] doubleValue];
            }
            if(currentDateTime >= signalStartDateTime && currentDateTime < signalEndDateTime){
                currentSignal = signal;
            }else{
                currentSignal = 0.0;
            }
               
            dateTimesArray[dateIndex] = currentDateTime;
            signalArray[dateIndex] = currentSignal;
            marketPositionArray[dateIndex] = (double)currentPosition;
        
            shortIndicatorArray[dateIndex] = ([UtilityFunctions signOfInt:currentPosition] < 0)? (double) -currentPosition: 0.0; 
            longIndicatorArray[dateIndex] =  ([UtilityFunctions signOfInt:currentPosition] > 0)? (double) currentPosition: 0.0;
            // If there has been a trade one indicator will stop at t-1 and another start at time t
            // as these indictors are for plots better to join up the indicator for better visuals
            if(dateIndex > 0 ){
                //There has been a trade at this time
                if(marketPositionArray[dateIndex] != marketPositionArray[dateIndex-1]){
                    if(marketPositionArray[dateIndex] > 0){
                        shortIndicatorArray[dateIndex] = shortIndicatorArray[dateIndex-1];
                    }
                    if(marketPositionArray[dateIndex] < 0){
                        longIndicatorArray[dateIndex] = longIndicatorArray[dateIndex-1];
                    }
                }
            }

            cashPositionArray[dateIndex] =  currentCashBalance;
            marginUsedArray[dateIndex] =  ABS(currentPosition) /[simulation maxLeverage];
            if(accountCurrencyIsQuoteCurrency){
                if(currentPosition < 0){
                    marginUsedArray[dateIndex] = marginUsedArray[dateIndex] * currentBid;
                }else{
                    marginUsedArray[dateIndex] = marginUsedArray[dateIndex] * currentAsk;
                }
            }    
            
            // To get the unrealised P&L we have to consider each position and its entry price
            // Also will get hte position average price here
            double unrealisedPnl = 0.0;
            double posAvePrice = 0.0;
            int posShares = 0;
            if(currentPosition > 0){
                for(int positionIndex = 0; positionIndex < [positionAmount count]; positionIndex++){
                    unrealisedPnl = unrealisedPnl + [[positionAmount objectAtIndex:positionIndex] intValue] * ((currentBid -[[positionPrice objectAtIndex:positionIndex] doubleValue]));
                
                posAvePrice = posAvePrice + (double)[[positionAmount objectAtIndex:positionIndex] intValue] * [[positionPrice objectAtIndex:positionIndex] doubleValue];
                posShares = posShares + [[positionAmount objectAtIndex:positionIndex] intValue];
            }
            posAvePrice = posAvePrice/posShares;
        }
                              
        if(currentPosition < 0){
            for(int positionIndex = 0; positionIndex < [positionAmount count]; positionIndex++){
                    unrealisedPnl = unrealisedPnl + [[positionAmount objectAtIndex:positionIndex] intValue] * ((currentAsk -[[positionPrice objectAtIndex:positionIndex] doubleValue]));
                
                    posAvePrice = posAvePrice + (double)[[positionAmount objectAtIndex:positionIndex] intValue] * [[positionPrice objectAtIndex:positionIndex] doubleValue];
                    posShares = posShares + [[positionAmount objectAtIndex:positionIndex] intValue];
                }
                posAvePrice = posAvePrice/posShares;
            }
            if(currentPosition == 0){
                positionAvePriceArray[dateIndex] = (currentBid + currentAsk)/2;
            }else{
                positionAvePriceArray[dateIndex] = posAvePrice;
            }
            // If the quote currency and base currency are different the unrealised p&l
            // must be converted
       
            if(currentPosition == 0){
                navArray[dateIndex] = cashPositionArray[dateIndex];
            }else{
                if(accountCurrencyIsQuoteCurrency){
                    navArray[dateIndex] = cashPositionArray[dateIndex] + unrealisedPnl;
                }else{
                    if(unrealisedPnl > 0){
                        double accBaseAsk = currentAsk;
                        navArray[dateIndex] = cashPositionArray[dateIndex] + (unrealisedPnl/accBaseAsk);
                    }else{
                        double accBaseBid = currentBid;
                        navArray[dateIndex] = cashPositionArray[dateIndex] + (unrealisedPnl/accBaseBid);
                    }
                }
            }
            
            marginAvailableArray[dateIndex] = navArray[dateIndex] - marginUsedArray[dateIndex];
            marginCloseOutArray[dateIndex] = navArray[dateIndex] - (marginUsedArray[dateIndex]/2);
            
            currentMaximumNav = ( navArray[dateIndex] > currentMaximumNav ) ? navArray[dateIndex] : currentMaximumNav; 

            drawDownArray[dateIndex] = MIN(0,navArray[dateIndex]-currentMaximumNav);
            if(drawDownArray[dateIndex] < largestDrawdown){
                largestDrawdown = drawDownArray[dateIndex];
                largestDrawdownDateTime = currentDateTime;
            }
            if(doThreads){
                [self performSelectorOnMainThread:@selector(progressAsFraction:) withObject:[NSNumber   numberWithDouble:(double) (currentDateTime-startDateTime)/(endDateTime-startDateTime)  ] waitUntilDone:NO];
            }
        }
    
        [self performSelectorOnMainThread:@selector(progressBarOff) withObject:nil waitUntilDone:NO];
    
        if(!cancelProcedure)
        {
            if(!allTradesFinished ){
                [NSException raise:@"All trades were not included for some reason!" format:nil];
            }
            if(!allCashMovesFinished ){
                [NSException raise:@"All cash transactions were not included for some reason!" format:nil];
            }
    
            //[simulationDataDictionary setObject:signalData forKey:@"SIGNAL"];
            [simulationDataDictionary setObject:marketPositionData forKey:@"POSITION"];
            [simulationDataDictionary setObject:cashPositionData forKey:@"CASHBALANCE"]; 
            [simulationDataDictionary setObject:navData forKey:@"NAV"];
            [simulationDataDictionary setObject:drawDownData forKey:@"DRAWDOWN"];
            [simulationDataDictionary setObject:marginUsedData forKey:@"MARGINUSED"];
            [simulationDataDictionary setObject:marginAvailableData forKey:@"MARGINAVAIL"];
            [simulationDataDictionary setObject:marginCloseOutData forKey:@"CLOSEOUT"];
            [simulationDataDictionary setObject:shortIndicatorData forKey:@"SHORT"];
            [simulationDataDictionary setObject:longIndicatorData forKey:@"LONG"];
            [simulationDataDictionary setObject:positionAvePriceData forKey:@"POSAVEPRICE"];
    
            positionDataSeries = [simData createNewDataSeriesWithXData: dateTimesData
                                                              AndYData: simulationDataDictionary 
                                                         AndSampleRate: timeStep];
        
            [simulation addObjectToSimulationResults:[NSNumber numberWithDouble:navArray[[dateTimesOfAnalysis count]-1]]
                                                  ForKey:@"FINALNAV"];
            [simulation addObjectToSimulationResults:[NSNumber numberWithInt:[simulation numberOfTrades]]
                                                  ForKey:@"NUMBEROFTRADES"];
            [simulation addObjectToSimulationResults:[NSNumber numberWithDouble:allCashTransfers] ForKey:@"CASHTRANSFERS"];
            [simulation addObjectToSimulationResults:[NSNumber numberWithDouble:tradePnl]
                                                  ForKey:@"TRADE PNL"];
            [simulation addObjectToSimulationResults:[NSNumber numberWithDouble:interestCosts]
                                                  ForKey:@"INTEREST"];
            [simulation addObjectToSimulationResults:[NSNumber numberWithDouble:spreadCost]
                                                  ForKey:@"SPREADCOST"]; 
            [simulation addObjectToSimulationResults:[NSNumber numberWithDouble:largestDrawdown]
                                              ForKey:@"BIGGESTDRAWDOWN"];
            [simulation addObjectToSimulationResults:[NSNumber numberWithLong:largestDrawdownDateTime] 
                                              ForKey:@"DRAWDOWNTIME"];
        
            int activityCount = [simulation numberOfBalanceAdjustments];
            for(int i = 0; i < activityCount; i++){
                NSDictionary *accountActivity = [simulation detailsOfBalanceAdjustmentIndex:i];
                NSString *reason = [accountActivity objectForKey:@"REASON"];
                NSString *dateTimeString = [EpochTime stringDateWithTime:[[accountActivity objectForKey:@"DATETIME"] longValue]];
                double amount = [[accountActivity objectForKey:@"AMOUNT"] doubleValue];
                double resultingBalance = [[accountActivity objectForKey:@"ENDBAL"] doubleValue]; 
                userMessage = [NSString stringWithFormat:@"%@ %@ %5.3f %5.3f",dateTimeString,reason,amount,resultingBalance];
            
                if(doThreads){
                    [self performSelectorOnMainThread:@selector(sendMessageToUserInterface:) 
                                       withObject:userMessage waitUntilDone:NO];
                }
            }
        }
    
        if(!cancelProcedure)
        {
            [simulation setAnalysisDataSeries:positionDataSeries];
            [self performSelectorOnMainThread:@selector(prepareForSimulationReport) withObject:nil waitUntilDone:YES];
            [self performSelectorOnMainThread:@selector(addSimulationDataToResultsTableView:) withObject:positionDataSeries waitUntilDone:YES];
            [self performSelectorOnMainThread:@selector(plotSimulationData:) withObject:positionDataSeries waitUntilDone:YES];
            [self performSelectorOnMainThread:@selector(populateAboutPane:) withObject:simulation waitUntilDone:YES];
            [self performSelectorOnMainThread:@selector(initialiseSignalTableView) withObject:nil waitUntilDone:YES];
            [self performSelectorOnMainThread:@selector(setupResultsReport) withObject:nil waitUntilDone:YES];
    
            if(doThreads){
                userMessage = @"Plot Prepared";
                [self performSelectorOnMainThread:@selector(updateStatus:) withObject:userMessage waitUntilDone:NO];
                userMessage = @"Done";
                [self performSelectorOnMainThread:@selector(sendMessageToUserInterface:) withObject:userMessage waitUntilDone:NO];
            }
        }
    }else{
        if(doThreads){
            userMessage = @"There were no trades";
            [self performSelectorOnMainThread:@selector(updateStatus:) withObject:userMessage waitUntilDone:NO];
            userMessage = @"Done";
            [self performSelectorOnMainThread:@selector(sendMessageToUserInterface:) withObject:userMessage waitUntilDone:NO];
        }else{
            userMessage = @"There were no trades";
            [self performSelectorOnMainThread:@selector(sendMessageToUserInterface:) withObject:userMessage waitUntilDone:NO];
        }

    }
}

-(double)calculateInterestForSimulation: (Simulation *) simulation ToDateTime: (long) endDateTime
{
    long earliestPositionDateTime;
    earliestPositionDateTime = [simulation timeDateOfEarliestPosition];
    
    NSArray *borrowingInterestRates;
    NSArray *lendingInterestRates;
    
    NSString *borrowingCode;
    NSString *lendingCode; 
    NSString *accBaseCode, *accQuoteCode;
    DataSeriesValue *accBaseAskPrice;
    DataSeriesValue *accQuoteAskPrice;
    double interestAccrued = 0.0;

    
    if([simulation currentExposure] !=0)
    {
        accBaseCode = [NSString stringWithFormat:@"%@%@",[simulation accCode],[simulation baseCode]];
        accQuoteCode = [NSString stringWithFormat:@"%@%@",[simulation accCode],[simulation quoteCode]];
        
        accBaseAskPrice = [simData valueFromDataBaseForFxPair:accBaseCode 
                                                       AndDateTime:endDateTime 
                                                          AndField:@"ASK"];                                         
        
        accQuoteAskPrice = [simData valueFromDataBaseForFxPair:accQuoteCode 
                                                      AndDateTime:endDateTime 
                                                         AndField:@"ASK"]; 
        
        if([simulation currentExposure] >0)
        {
            borrowingCode = [simulation baseCode];
            lendingCode = [simulation quoteCode];
        }else{
            borrowingCode = [simulation quoteCode];
            lendingCode = [simulation baseCode];
        }
    
        borrowingInterestRates = [interestRates objectForKey:[NSString stringWithFormat:@"%@IRASK",borrowingCode]];
        lendingInterestRates = [interestRates objectForKey:[NSString stringWithFormat:@"%@IRBID",lendingCode]];
    
        long positionInterestDateTime;
        double positionEntryPrice;
        int positionSize;
        double interestRate;
        long interestRateStart, interestRateEnd;
    
    
        for(int iPos = 0; iPos < [simulation numberOfPositions]; iPos++)
        {
            //Borrowing
            positionInterestDateTime = [simulation dateTimeOfInterestForPositionAtIndex:iPos];
            positionSize = [simulation sizeOfPositionAtIndex:iPos];
            positionEntryPrice = [simulation entryPriceOfPositionAtIndex:iPos];
            long interestUpToDateDateTime = positionInterestDateTime;
        
            int iRateUpdate, iRateUpdateIndex;
            iRateUpdateIndex = 0;
            while(interestUpToDateDateTime < endDateTime){
                for(iRateUpdate = iRateUpdateIndex; iRateUpdate < [borrowingInterestRates count]; iRateUpdate++)
                {
                    DataSeriesValue *interestRateDSV = [borrowingInterestRates objectAtIndex:iRateUpdate];
                    if([interestRateDSV dateTime] <= interestUpToDateDateTime)
                    {
                        iRateUpdateIndex = iRateUpdate;
                        interestRate = [interestRateDSV value];
                        interestRateStart = [interestRateDSV dateTime];
                    }else{
                        break;
                    }
                }
                if(iRateUpdateIndex == ([borrowingInterestRates count]-1))
                {
                    interestRateEnd = endDateTime;
                }else{
                    DataSeriesValue *interestRateDSV = [borrowingInterestRates objectAtIndex:(iRateUpdate + 1)];
                    if([interestRateDSV dateTime] > endDateTime)
                    {
                        interestRateEnd = endDateTime;
                    }else{
                        interestRateEnd = [interestRateDSV dateTime];
                    }
                }
                if(interestRate < 0){
                    interestRate = 0;
                }else{
                    if(positionSize > 0){
                        interestAccrued = interestAccrued - ((positionSize * interestRate)*((double)(interestRateEnd-interestUpToDateDateTime)/(365*24*60*60))/[accBaseAskPrice value]); 
                    }else{
                        interestAccrued = interestAccrued + ((positionSize * positionEntryPrice * interestRate)*((double)(interestRateEnd-interestUpToDateDateTime)/(365*24*60*60))) /[accQuoteAskPrice value];
                    }
                }   
                interestUpToDateDateTime = interestRateEnd;
            }    
    
    
            //Lending
            iRateUpdateIndex = 0;
            interestUpToDateDateTime = positionInterestDateTime;
            while(interestUpToDateDateTime < endDateTime){
                for(iRateUpdate = iRateUpdateIndex; iRateUpdate < [lendingInterestRates count]; iRateUpdate++)
                {
                    DataSeriesValue *interestRateDSV = [lendingInterestRates objectAtIndex:iRateUpdate];
                    if([interestRateDSV dateTime] <= interestUpToDateDateTime)
                    {
                        iRateUpdateIndex = iRateUpdate;
                        interestRate = [interestRateDSV value];
                        interestRateStart = [interestRateDSV dateTime];
                    }else{
                        break;
                    }
                }
                if(iRateUpdateIndex == ([borrowingInterestRates count]-1))
                {
                    interestRateEnd = endDateTime;
                }else{
                    DataSeriesValue *interestRateDSV = [lendingInterestRates objectAtIndex:(iRateUpdate + 1)];
                    if([interestRateDSV dateTime] > endDateTime)
                    {
                        interestRateEnd = endDateTime;
                    }else{
                        interestRateEnd = [interestRateDSV dateTime];
                    }
                }
                if(interestRate < 0)
                {
                    interestRate = 0;
                }else{
                    if(positionSize > 0){
                        interestAccrued = interestAccrued + ((positionSize * positionEntryPrice * interestRate)*((double)(interestRateEnd-interestUpToDateDateTime)/(365*24*60*60))/[accQuoteAskPrice value]); 
                    }else{
                        interestAccrued = interestAccrued - ((positionSize *  interestRate)*((double)(interestRateEnd-interestUpToDateDateTime)/(365*24*60*60))) / [accBaseAskPrice value];
                    }
                }
                interestUpToDateDateTime = interestRateEnd;
            } 
            [simulation addInterestToPosition:iPos
                                WithAmount:interestAccrued 
                                    AtTime:endDateTime];
        }
    }
    return interestAccrued;
}

-(double) setExposureToUnits: (int) exposureAmount 
                 AtTimeDate: (long) currentDateTime
              ForSimulation: (Simulation *) simulation
             AndSignalIndex: (int) signalIndex
{
    int currentExposure = [simulation currentExposure];
    int exposureAdjustment = exposureAmount-currentExposure;
    int tradeIndex;
    double tradePrice;
    BOOL success;
    double interestAccrued = 0.0;
    double realisedPnl = 0.0;
    
    NSString *accQuoteCode, *baseQuoteCode;
    DataSeriesValue *accQuoteBidPrice, *accQuoteAskPrice;
    DataSeriesValue *baseQuoteBidPrice, *baseQuoteAskPrice;
    
    //First make sure interest calculations are up-to-date
    interestAccrued = [self calculateInterestForSimulation:simulation 
                           ToDateTime:currentDateTime];
    
    
    accQuoteCode = [NSString stringWithFormat:@"%@%@",[simulation accCode],[simulation quoteCode]];
    
    baseQuoteCode = [NSString stringWithFormat:@"%@%@",[simulation baseCode],[simulation quoteCode]]; 
    
    
    accQuoteBidPrice = [simData valueFromDataBaseForFxPair:accQuoteCode 
                                                 AndDateTime:currentDateTime 
                                                    AndField:@"BID"];
    accQuoteAskPrice = [simData valueFromDataBaseForFxPair:accQuoteCode 
                                                 AndDateTime:currentDateTime 
                                                    AndField:@"ASK"];
    
    baseQuoteBidPrice = [simData valueFromDataBaseForFxPair:baseQuoteCode 
                                                   AndDateTime:currentDateTime 
                                                      AndField:@"BID"];
    
    baseQuoteAskPrice = [simData valueFromDataBaseForFxPair:baseQuoteCode 
                                                   AndDateTime:currentDateTime 
                                                      AndField:@"ASK"];
    
    if(exposureAdjustment != 0)
    {
        if(exposureAdjustment > 0){
            tradePrice = [self getPrice:ASK AtTime:currentDateTime WithSuccess:&success];
        }else{
            tradePrice = [self getPrice:BID AtTime:currentDateTime  WithSuccess:&success];
        }
        
        if(success){
            tradeIndex = [simulation numberOfTrades];
            realisedPnl = [simulation addTradeWithAmount:exposureAdjustment 
                                                  AtTime:currentDateTime 
                                               WithPrice:tradePrice
                                     AndAccQuoteBidPrice:[accQuoteBidPrice value]
                                     AndAccQuoteAskPrice:[accQuoteAskPrice value]
                                    AndBaseQuoteBidPrice:[baseQuoteBidPrice value]
                                    AndBaseQuoteAskPrice:[baseQuoteAskPrice value]
                                          AndSignalIndex: signalIndex];    
        }else{
            [NSException raise:@"Problem with data" format:@"%l",currentDateTime];
        }
    }
    return interestAccrued + realisedPnl;
}
 
         
-(double)getPrice:(PriceType) priceType AtTime:(long) dateTime WithSuccess:(BOOL *) success
{
    //long laggedTime;
    double price;
    NSArray *fieldNames;
    NSString *priceField;
    if(priceType == BID){
        priceField = [NSString stringWithString:@"BID"];
    }
    if(priceType == ASK){
        priceField = [NSString stringWithString:@"ASK"];
    }
    if(priceType == MID){
        priceField = [NSString stringWithString:@"MID"];
    }
    fieldNames = [NSArray arrayWithObject:priceField];
    
    //laggedTime = dateTime + STATIC_LAG;
    NSDictionary *dataBaseValues = [simData getValuesForFields: fieldNames AtDateTime:dateTime];
    if([dataBaseValues objectForKey:@"SUCCESS"])
    {
        price = [[dataBaseValues objectForKey:priceField] doubleValue];
        *success = YES;
    }else{
        price = 0.0;
        *success = NO;
    }
    return price;
}


-(Simulation *)getSimulationForName: (NSString *) name;
{
    Simulation *acc = nil;
    acc = [allSimulations objectForKey:name];
    return acc;
}

-(double) getBalanceForSimulation: (Simulation *) simulation
{
    return [simulation currentBalance];
}

-(int) getExposureForSimulation: (Simulation *) simulation
{
    return [simulation currentExposure];
}
     
-(BOOL)exportData: (NSURL *) urlOfFile
{
    BOOL allOk;
    DataSeries* analysisData = [currentSimulation analysisDataSeries]; 
    allOk = [analysisData writeDataSeriesToFile:urlOfFile];
    return allOk;
}

-(BOOL)exportTrades: (NSURL *) urlOfFile
{
    BOOL allOk;
    allOk = [currentSimulation writeTradesToFile:urlOfFile]; 
    return allOk;
}

-(BOOL)exportBalAdjmts: (NSURL *) urlOfFile
{
    BOOL allOk;
    allOk = [currentSimulation writeBalanceAdjustmentsToFile:urlOfFile]; 
    return allOk;
    
}

#pragma mark -
#pragma mark Methods For Delegate

-(void)updateStatus:(NSString *) statusMessage
{
    if([[self delegate] respondsToSelector:@selector(updateStatus:)])
    {
        [[self delegate] updateStatus:statusMessage];
    }else{
        NSLog(@"Delegate doesn't respond to \'updateStatus:\'");
    }
    
}

-(void) clearUserInterfaceMessages
{
    if([[self delegate] respondsToSelector:@selector(clearSimulationMessage)])
    {
        [[self delegate] clearSimulationMessage]; 
    }else{
        NSLog(@"Delegate doesn't respond to \'clearSimulationMessage\'");
    }
   
}

-(void) sendMessageToUserInterface:(NSString *) message
{
    if([[self delegate] respondsToSelector:@selector(outputSimulationMessage:)])
    {
        [[self delegate] outputSimulationMessage:message]; 
    }else{
        NSLog(@"Delegate doesn't respond to \'outputSimulationMessage:\'");
    }
        
   // -(void)clearSimulationMessage;
}

-(void) readingDatabaseOn
{
    if([[self delegate] respondsToSelector:@selector(gettingDataIndicatorSwitchOn)])
    {
        [[self delegate] gettingDataIndicatorSwitchOn]; 
    }else{
        NSLog(@"Delegate doesn't respond to \'gettingDataIndicatorSwitchOn\'");
    }
   
}
-(void) readingDatabaseOff
{
    if([[self delegate] respondsToSelector:@selector(gettingDataIndicatorSwitchOff)])
    {
        [[self delegate] gettingDataIndicatorSwitchOff]; 
    }else{
        NSLog(@"Delegate doesn't respond to \'gettingDataIndicatorSwitchOff\'");
    }
    
}

- (void) readingRecordSetsProgress: (NSNumber *) progressFraction
{
    if([[self delegate] respondsToSelector:@selector(readingRecordSetsProgress:)])
    {
        [[self delegate] readingRecordSetsProgress:progressFraction]; 
    }else{
        NSLog(@"Delegate doesn't respond to \'readingRecordSetsProgress\'");
    }
}



-(void)prepareForSimulationReport
{
    if([[self delegate] respondsToSelector:@selector(prepareForSimulationReport)])
    {
        [[self delegate] prepareForSimulationReport]; 
    }else{
        NSLog(@"Delegate not responding to \'prepareForSimulationReport\'"); 
    }    
    
}

-(void) plotSimulationData:(DataSeries *) simulationData
{
    if([[self delegate] respondsToSelector:@selector(plotSimulationData:)])
    {
        [[self delegate] plotSimulationData:simulationData]; 
    }else{
        NSLog(@"Delegate not responding to \'plotSimulationData\'"); 
    }
}

-(void) addSimulationDataToResultsTableView: (DataSeries *) analysisDataSeries
{
    if([[self delegate] respondsToSelector:@selector(addSimulationDataToResultsTableView:)])
    {
        [[self delegate] addSimulationDataToResultsTableView:analysisDataSeries]; 
    }else{
        NSLog(@"Delegate not responding to \'addSimulationDataToResultsTableView\'"); 
    }
}


-(void) initialiseSignalTableView
{
    if([[self delegate] respondsToSelector:@selector(initialiseSignalTableView)])
    {
        [[self delegate] initialiseSignalTableView]; 
    }else{
        NSLog(@"Delegate not responding to \'initialiseSignalTableView\'"); 
    }
    
}

-(void) setupResultsReport
{
if([[self delegate] respondsToSelector:@selector(setupResultsReport)])
{
    [[self delegate] setupResultsReport]; 
}else{
    NSLog(@"Delegate not responding to \'setupResultsReport\'"); 
}

}


-(void) progressBarOn{
    if([[self delegate] respondsToSelector:@selector(progressBarOn)])
    {
        [[self delegate] progressBarOn]; 
    }else{
        NSLog(@"Delegate not responding to \'progressBarOn\'"); 
    }
}

-(void) progressBarOff{
    if([[self delegate] respondsToSelector:@selector(progressBarOff)])
    {
        [[self delegate] progressBarOff]; 
    }else{
        NSLog(@"Delegate not responding to \'progressBarOff\'"); 
    }    
}

-(void) progressAsFraction:(NSNumber *) progressValue
{
    if([[self delegate] respondsToSelector:@selector(progressAsFraction:)])
    {
        [[self delegate] progressAsFraction:progressValue]; 
    }else{
        NSLog(@"Delegate not responding to \'progressAsFraction\'"); 
    }    
}

//-(void) incrementProgressBy:(NSNumber *) increment{
//    if([[self delegate] respondsToSelector:@selector(incrementProgressBarBy:)])
//    {
//        [[self delegate] incrementProgressBarBy:increment]; 
//    }else{
//        NSLog(@"Delegate not responding to \'incrementProgressBarBy\'"); 
//    }
//}

-(void) simulationEnded{
    if([[self delegate] respondsToSelector:@selector(simulationEnded)])
    {
        [[self delegate] simulationEnded]; 
    }else{
        NSLog(@"Delegate not responding to \'simulationEnded\'"); 
    }
}

-(void) populateAboutPane: (Simulation *) simulation
{
    if([[self delegate] respondsToSelector:@selector(addSimInfoToAboutPanelWithName:AndFxPair:AndAccountCurrency:AndSimStartTime:AndSimEndTime:AndSamplingRate:AndTradingLag:AndTradingWindowStart:AndTradingWindowEnd:AndSimParameters:)])
    {
        NSString *tradingPair = [NSString stringWithFormat:@"%@%@",[simulation baseCode],[simulation quoteCode]];
        int tradingDayStartSeconds = [simulation tradingDayStart];
        NSString *tradingDayStartString = [EpochTime  stringOfDateTimeForTime:tradingDayStartSeconds WithFormat:@"%H:%M"];
        int tradingDayEndSeconds = [simulation tradingDayEnd];
        NSString *tradingDayEndString = [EpochTime  stringOfDateTimeForTime:tradingDayEndSeconds WithFormat:@"%H:%M"];
        
        [[self delegate] addSimInfoToAboutPanelWithName:[simulation name]
                                              AndFxPair:tradingPair 
                                     AndAccountCurrency:[simulation accCode]
                                        AndSimStartTime:[EpochTime stringDateWithTime:[simulation startDate]]
                                          AndSimEndTime:[EpochTime stringDateWithTime:[simulation endDate]]
                                        AndSamplingRate:[NSString stringWithFormat:@"%d",[simulation samplingRate]] 
                                          AndTradingLag:[NSString stringWithFormat:@"%d",[simulation tradingLag]]
                                  AndTradingWindowStart:tradingDayStartString
                                    AndTradingWindowEnd:tradingDayEndString
                                       AndSimParameters:[simulation signalParameters]];
    }
}
         
-(BOOL)writeReportToCsvFile:(NSURL *) urlOfFile
{
    NSArray *dataFieldNames = [currentSimulation reportDataFieldsArray];
    BOOL allOk = YES;
    NSFileHandle *outFile;
    
    // Create the output file first if necessary
    // Need to remove file: //localhost for some reason
    NSString *filePathString = [urlOfFile path];//[[fileNameAndPath absoluteString] substringFromIndex:16];
    allOk = [[NSFileManager defaultManager] createFileAtPath: filePathString
                                                    contents: nil 
                                                  attributes: nil];
    if(allOk){
        outFile = [NSFileHandle fileHandleForWritingAtPath:filePathString];
        [outFile truncateFileAtOffset:0];
        
        NSString *lineOfFile;
        for(int fieldIndex = 0; fieldIndex < [dataFieldNames count]; fieldIndex++){
            if([[dataFieldNames objectAtIndex:fieldIndex] isEqualToString:@"BLANK"]){
                lineOfFile = @",\r\n";
            }else{
                lineOfFile = [NSString stringWithFormat:@"%@ , %@\r\n",[dataFieldNames objectAtIndex:fieldIndex],[currentSimulation getReportDataFieldAtIndex:fieldIndex]];
            }
            [outFile writeData:[lineOfFile dataUsingEncoding:NSUTF8StringEncoding]];
        }
        [outFile closeFile];
        
    }
    return allOk;
}

#pragma mark -
#pragma mark Variables 

@synthesize currentSimulation;
@synthesize cancelProcedure;


@end
