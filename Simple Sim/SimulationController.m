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
-(void) tradingSimulation:(NSDictionary *) parameters;
-(void) plotSimulationData:(DataSeries *) dataToPlot;
-(void) addSimulationDataToResultsTableView: (DataSeries *) analysisDataSeries;
-(void) progressBarOn;
-(void) progressBarOff;
-(void) incrementProgressBy:(NSNumber *) increment;
-(void) setProgressRangeWithMinAndMax: (NSArray *) minAndMax;

@end

@implementation SimulationController
@synthesize currentSimulation;
@synthesize doThreads;
@synthesize cancelProcedure;


-(id)init
{
    self = [super init];
    if(self){
        allSimulations = [[NSMutableDictionary alloc] init];
        marketData = [[DataController alloc] init];
        interestRates = [[NSMutableDictionary alloc] init];
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

-(void)askSimulationToCancel
{
    [self setCancelProcedure:YES];
}

-(void)tradingSimulation:(NSDictionary *) parameters
{
    NSString *tradingPair;
    long minDateTime, maxDateTime;
    float nav, cashPosition, debits;
    float unrealisedPnl = 0.0;
    float marginUsed = 0.0;
    float marginAvailable = 0.0;
    float requiredMargin = 0.0;
    
    //Only u;se these varibles for data request, they may not reflect the actual data returned
    long dataRequestMinDateTime, dataRequestMaxDateTime;
    BOOL allOk = YES;
    BOOL closeOut = NO;
    
    //BOOL enoughData = YES;
    NSString *userMessage;
    
    cancelProcedure = NO;
    
    NSString *simName = [parameters objectForKey:@"SIMNAME"];
    NSString *baseCode = [parameters objectForKey:@"BASECODE"];
    NSString *quoteCode = [parameters objectForKey:@"QUOTECODE"];
    NSString *accCode = [parameters objectForKey:@"ACCOUNTCODE"];
    long startDateTime = [[parameters objectForKey:@"STARTTIME"] longValue];
    long endDateTime = [[parameters objectForKey:@"ENDTIME"] longValue];
    int maxLeverage = [[parameters objectForKey:@"MAXLEVERAGE"] intValue];
    float startingBalance = [[parameters objectForKey:@"STARTBALANCE"] floatValue];  
    long initialDataBeforeStart = [[parameters objectForKey:@"WARMUPDATA"] longValue]; 
    int timeStep = [[parameters objectForKey:@"TIMESTEP"] intValue];
    int tradingLag = [[parameters objectForKey:@"TRADINGLAG"] intValue];
    NSString *simDescription = [parameters objectForKey:@"SIMTYPE"];
    long tradingDayStart = [[parameters objectForKey:@"TRADINGDAYSTART"] longValue];
    long tradingDayEnd = [[parameters objectForKey:@"TRADINGDAYEND"] longValue];
    BOOL weekendTrading =   [[parameters objectForKey:@"WEEKENDTRADING"] boolValue];
    int tradingDayStartHour = tradingDayStart/(60*60) ; 
    int tradingDayEndHour = tradingDayEnd/(60*60) ;
    int tradingDayStartMinute = (tradingDayStart-(tradingDayStartHour*60*60))%60; 
    int tradingDayEndMinute = (tradingDayEnd-(tradingDayEndHour*60*60))%60; 
    
    int newSignal = 0;
    int currentSignal = 0;
    float currentSignalEntryPrice;
    float currentSignalExitPrice;
    float currentSignalMaxUp;
    float currentSignalMaxDown;
    long currentSignalEntryTime;
    long currentSignalExitTime;
    int currentSignalTotalSamples = 0;
    int currentSignalSamplesInProfit = 0;
    
    
    NSString *slowSig;
    NSString *fastSig;
    BOOL accountCurrencyIsQuoteCurrency = NO;
    
    if([accCode isEqualToString:quoteCode]){
        accountCurrencyIsQuoteCurrency = YES;
    }

    int requiredPositionSize = 0;
    //int currentPositionSize = 0;
    
  
    
    // Decode how to run the simulation
    
    BOOL simDescriptionUnderstood = YES;
    NSArray *descriptionOfSimulation = [simDescription componentsSeparatedByString:@"/"];
    //SECO/20/24
    if([[descriptionOfSimulation objectAtIndex:0] isEqualToString:@"SECO"]){
        if([descriptionOfSimulation count] == 3){
            fastSig = [NSString stringWithFormat:@"EWMA%@",[descriptionOfSimulation objectAtIndex:1]];
            slowSig = [NSString stringWithFormat:@"EWMA%@",[descriptionOfSimulation objectAtIndex:2]];
        }
        
    }else{
        simDescriptionUnderstood = NO;
    }
     
    tradingPair = [NSString stringWithFormat:@"%@%@",baseCode,quoteCode];
    
    minDateTime = [marketData getMinDataDateTimeForPair:tradingPair];
    maxDateTime = [marketData getMaxDataDateTimeForPair:tradingPair];
    
    if(startDateTime < (minDateTime + initialDataBeforeStart))
    {
        startDateTime =  minDateTime + initialDataBeforeStart;
    }
    startDateTime = [EpochTime epochTimeAtZeroHour:startDateTime] + timeStep  * ((startDateTime-[EpochTime epochTimeAtZeroHour:startDateTime])/timeStep);
    startDateTime = startDateTime + timeStep;
    
    endDateTime = [EpochTime epochTimeNextDayAtZeroHour:endDateTime] - 1;
    //long endDateTime = startDateTime + simulationLength;
    if(endDateTime > maxDateTime){
        endDateTime = maxDateTime; 
    }
    
    
    [self clearUserInterfaceMessages];
    userMessage = [NSString stringWithFormat:@"Starting %@",simName];
    if(doThreads){
        [self performSelectorOnMainThread:@selector(sendMessageToUserInterface:) withObject:userMessage waitUntilDone:NO];
    }
    
    // Set up the simulation data object
    int tradingDayStartSeconds = (tradingDayStartMinute*60) + (tradingDayStartHour * 60 * 60);
    int tradingDayEndSeconds = (tradingDayEndMinute*60) + (tradingDayEndHour * 60 * 60);
    

    Simulation *newSimulation = [[Simulation alloc] initWithName:simName 
                                                AndDate:startDateTime 
                                             AndBalance:startingBalance 
                                            AndCurrency:accCode
                                         AndTradingPair:tradingPair
                                         AndMaxLeverage: maxLeverage];
    //[newSimulation setStartDate:startDateTime];
    [newSimulation setEndDate:endDateTime];
    [newSimulation setSamplingRate:timeStep];
    [newSimulation setTradingLag:tradingLag];
    [newSimulation setSignalParameters:simDescription];
    [newSimulation setTradingDayStart:tradingDayStartSeconds];
    [newSimulation setTradingDayEnd:tradingDayEndSeconds]; 
    [allSimulations setObject:newSimulation forKey:simName];
    [self setCurrentSimulation:newSimulation];
        
    
    //Getting Interest Rate Data
    
    if(!cancelProcedure){
    
        userMessage = @"Getting Interest Rate data";
        if(doThreads){
            [self performSelectorOnMainThread:@selector(updateStatus:) withObject:userMessage waitUntilDone:NO];
            [self performSelectorOnMainThread:@selector(readingDatabaseOn) withObject:nil waitUntilDone:NO]; 
        }
    
        NSArray *interestRateSeries;
        if([interestRates objectForKey:[NSString stringWithFormat:@"%@IRBID",baseCode]] == nil){
            interestRateSeries = [marketData getAllInterestRatesForCurrency:baseCode AndField:@"BID"];
            [interestRates setValue:interestRateSeries forKey:[NSString stringWithFormat:@"%@IRBID",baseCode]];
        }
        if([interestRates objectForKey:[NSString stringWithFormat:@"%@IRASK",baseCode]] == nil){
            interestRateSeries = [marketData getAllInterestRatesForCurrency:baseCode AndField:@"ASK"];
            [interestRates setValue:interestRateSeries forKey:[NSString stringWithFormat:@"%@IRASK",baseCode]];
        }    
        if([interestRates objectForKey:[NSString stringWithFormat:@"%@IRBID",quoteCode]] == nil){
            interestRateSeries = [marketData getAllInterestRatesForCurrency:quoteCode AndField:@"BID"];
            [interestRates setValue:interestRateSeries forKey:[NSString stringWithFormat:@"%@IRBID",quoteCode]];
        }
        if([interestRates objectForKey:[NSString stringWithFormat:@"%@IRASK",quoteCode]] == nil){
            interestRateSeries = [marketData getAllInterestRatesForCurrency:quoteCode AndField:@"ASK"];
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
        //[self sendMessageTsimulationDateTimeoUserInterface:@"Setting up the data"];
        userMessage = @"Setting up initial data";
        if(doThreads){
            [self performSelectorOnMainThread:@selector(updateStatus:) withObject:userMessage waitUntilDone:NO];
            [self performSelectorOnMainThread:@selector(readingDatabaseOn) withObject:nil waitUntilDone:NO]; 
        }
    
        dataRequestMinDateTime = startDateTime - initialDataBeforeStart;
        dataRequestMaxDateTime = endDateTime + (3 * DAY_SECONDS);
    
        [newSimulation setDataStartDateTime:dataRequestMinDateTime];
        allOk = [marketData setupDataSeriesForName:tradingPair];
        if(!allOk){
            userMessage = @"***Problem setting up database***";
            if(doThreads){
                [self performSelectorOnMainThread:@selector(updateStatus:) withObject:userMessage waitUntilDone:NO];
            }
            cancelProcedure = YES;
        }
        allOk = [marketData getDataSeriesForStartDateTime:dataRequestMinDateTime
                                           AndEndDateTime:dataRequestMaxDateTime];
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
    double **simulationData;
    NSMutableData *dateTimesData;
    NSMutableDictionary *simulationDataDictionary;
    if(!cancelProcedure){

        userMessage = @"Adding indicators";
        if(doThreads){
            [self performSelectorOnMainThread:@selector(updateStatus:) withObject:userMessage waitUntilDone:NO];
            [self performSelectorOnMainThread:@selector(readingDatabaseOff) withObject:nil waitUntilDone:NO];
        }
        if([fastSig length]>4){
            if([[fastSig substringToIndex:4] isEqualToString:@"EWMA"]){
                int ewmaNumber = [[fastSig substringFromIndex:4] intValue];
                [marketData addEWMAByIndex:ewmaNumber];
            }
        }
        if([slowSig length]>4){
            if([[slowSig substringToIndex:4] isEqualToString:@"EWMA"]){
                int ewmaNumber = [[slowSig substringFromIndex:4] intValue];
                [marketData addEWMAByIndex:ewmaNumber];
            }
        }
    
        userMessage = @"Indicators added";
        if(doThreads){
            [self performSelectorOnMainThread:@selector(updateStatus:) withObject:userMessage waitUntilDone:NO];
        }
    
        
        //Creating a timeseries object to store the data that is actually used in the simulation
        
        fieldNames = [NSArray arrayWithObjects:@"BID",@"ASK",@"MID",fastSig,slowSig, nil];
        
        long numberOfSimulationSteps = (endDateTime -startDateTime)/timeStep;
    
        
        dateTimesData = [[NSMutableData alloc] initWithLength:numberOfSimulationSteps * sizeof(long)]; 
        simDateTimes = [dateTimesData mutableBytes];
    
        simulationDataDictionary = [[NSMutableDictionary alloc] initWithCapacity:[fieldNames count]];
        simulationData = malloc([fieldNames count] * sizeof(double*));
        for(fieldIndex = 0; fieldIndex < [fieldNames count]; fieldIndex++){
            [simulationDataDictionary setObject:[[NSMutableData alloc] initWithLength:numberOfSimulationSteps * sizeof(double)] forKey:[fieldNames objectAtIndex:fieldIndex]];
            simulationData[fieldIndex] = [[simulationDataDictionary objectForKey:[fieldNames objectAtIndex:fieldIndex]] mutableBytes];
        }
    }
    
    
    
    NSDictionary *values;
    //NSString *formattedDataDate;
    
    NSString *currentDateAsString;
    //****ACTUAL START OF THE SIMULATION****//
    
    if(doThreads && !cancelProcedure){
        userMessage = @"Simulation Loop";
        [self performSelectorOnMainThread:@selector(updateStatus:) withObject:userMessage waitUntilDone:NO];

        [self performSelectorOnMainThread:@selector(setProgressRangeWithMinAndMax:) withObject:[NSArray arrayWithObjects:[NSNumber numberWithLong:startDateTime], [NSNumber numberWithLong:endDateTime], nil] waitUntilDone:YES];
        [self performSelectorOnMainThread:@selector(progressBarOn) withObject:nil waitUntilDone:NO];
        
    }
    
    BOOL tradingTime;
    int simStepIndex = 0;
    long timeOfDayInSeconds;
    simulationDateTime = startDateTime;
    
    cashPosition = startingBalance;
    nav = startingBalance;
    if(!cancelProcedure){
        do{
            double slow, fast, mid, bid, ask;
            BOOL isNewSignal = NO;
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
            if(simulationDateTime > [marketData getMaxDateTimeForLoadedData] )
            {
                dataRequestMinDateTime = [marketData getMaxDateTimeForLoadedData];
                dataRequestMaxDateTime = endDateTime + (3 * DAY_SECONDS);
                                
               if(doThreads){
                    [self performSelectorOnMainThread:@selector(updateStatus:) withObject:userMessage waitUntilDone:NO];
                    [self performSelectorOnMainThread:@selector(readingDatabaseOn) withObject:nil waitUntilDone:NO]; 
                }
                
                [marketData moveDataToStartDateTime: dataRequestMinDateTime
                                     AndEndDateTime: dataRequestMaxDateTime];

                
//                int tries = 0;
//                while(simulationDateTime > [marketData getMaxDateTimeForLoadedData])
//                {
//                    dataRequestMinDateTime = [marketData getMaxDateTimeForLoadedData];
//                    //data chunk is number of data requested but if there is a big gap (long weekend)
//                    //we need to expand the dat range to get over this hole
//                    if(endDateTime < [marketData getMaxDateTimeForLoadedData] + MAX_DATA_CHUNK && tries == 0)
//                    {
//                        dataRequestMaxDateTime = endDateTime + (3 * DAY_SECONDS);
//                    }else{
//                        if(tries > 0){
//                            dataRequestMaxDateTime = dataRequestMaxDateTime + MAX_DATA_CHUNK - [marketData getDataSeriesLength];
//                        }else{
//                            dataRequestMaxDateTime = [marketData getMaxDateTimeForLoadedData] + MAX_DATA_CHUNK;
//                        }
//                    }
//                    [marketData moveDataToStartDateTime: dataRequestMinDateTime
//                                      AndEndDateTime:dataRequestMaxDateTime];
//                    tries++;
//                }
                if(doThreads){
                    [self performSelectorOnMainThread:@selector(readingDatabaseOff) withObject:nil waitUntilDone:NO];
                }
            }
            
            //Check we successfully have data for the required date 
            if(simulationDateTime > [marketData getMaxDateTimeForLoadedData]){
                [NSException raise:@"DataSeries does not cover current date" format:@"Max: %l current %l ",[marketData getMaxDateTimeForLoadedData],simulationDateTime];
            }
            values = [marketData getValuesForFields: fieldNames AtDateTime:simulationDateTime ];
        
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
            fast = [[values objectForKey:fastSig] doubleValue];
            slow = [[values objectForKey:slowSig] doubleValue];
            mid = [[values objectForKey:@"MID"] doubleValue];
            bid = [[values objectForKey:@"BID"] doubleValue];
            ask =  [[values objectForKey:@"ASK"] doubleValue];
            
            
            
            if(simulationDateTime+timeStep > endDateTime || closeOut){
                newSignal = 0;
                signalCausesTrade = NO;
            }else{
                newSignal = (fast > slow) ? 1 : -1;
                signalCausesTrade = YES;
            }
            
            //This part deals with with signal and price performance
            if(currentSignal != newSignal && tradingTime){
                isNewSignal = YES;
                if(currentSignal != 0){
                    currentSignalTotalSamples++;
                    if(currentSignal > 0){
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
                                                            AndTimeInProfit:(float)currentSignalSamplesInProfit/currentSignalTotalSamples
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
            
            if(isNewSignal){
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
                
                if(currentSignal > 0){
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
                        debits = [self setExposureToUnits:requiredPositionSize 
                                              AtTimeDate:simulationDateTime + tradingLag
                                           ForSimulation: newSimulation
                                          AndSignalIndex:signalIndex];
                    }
                }else{
                    if(currentSignal < 0){
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
                        if(currentSignal == 0){
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
                [self performSelectorOnMainThread:@selector(incrementProgressBy:) withObject:[NSNumber numberWithInt:timeStep] waitUntilDone:NO];
            }
        }while(simulationDateTime < endDateTime && allOk && !cancelProcedure);
    }
     
    if(!cancelProcedure){
        currentDateAsString = [EpochTime stringDateWithTime:simulationDateTime]; 
        userMessage = [NSString stringWithFormat:@"%@ Finished Simulation",currentDateAsString];
        if(doThreads){
            [self performSelectorOnMainThread:@selector(updateStatus:) withObject:userMessage waitUntilDone:NO];
        }  
    }
    
    NSLog(@"%f",cashPosition);
    
    if(doThreads){
        [self performSelectorOnMainThread:@selector(progressBarOff) withObject:nil waitUntilDone:YES];
    }
    
    
    //***END OF THE SIMULATION****//
    
    
    if(!cancelProcedure)
    {
        DataSeries *simulationDataSeries;
        simulationDataSeries = [marketData newDataSeriesWithXData: dateTimesData
                                                         AndYData: simulationDataDictionary 
                                                    AndSampleRate: timeStep];
        [newSimulation setSimulationDataSeries:simulationDataSeries];
    //}
//        [self plotSimulationData:simulationDataSeries];
//    }
    
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
    
//        double spreadCrossCost;
//        spreadCrossCost = [newSimulation getSpreadCrossingCostInBaseCurrency];
//        userMessage = [NSString stringWithFormat:@"Estimated %5.2f %@ used crossing the spread",[newSimulation baseCode],spreadCrossCost];
//        if(doThreads){
//            [self performSelectorOnMainThread:@selector(sendMessageToUserInterface:) withObject:userMessage waitUntilDone:NO];
//        }
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
    NSArray *bidAskFields = [NSArray arrayWithObjects:@"BID",@"ASK", nil];
    
    NSMutableData *dateTimesData;
    long *dateTimesArray;
    NSMutableDictionary *simulationDataDictionary;
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
    
    int dateCount = 0, timeStep = 0, tradeIndex, signalIndex, cashMoveIndex;
    int signal;
    long startDateTime, endDateTime, stepDateTime, nextTradeDateTime;
    BOOL allTradesFinished, allCashMovesFinished;
    
    long signalStartDateTime, signalEndDateTime, nextCashMoveDateTime;
    float nextCashMoveAmount, allCashTransfers = 0.0;
    NSString *nextCashMoveReason;
    NSDictionary *tradeDetails;
    NSDictionary *signalDetails;
    NSDictionary *cashMoveDetails;
    BOOL accountCurrencyIsQuoteCurrency;
    NSMutableArray *positionDateTime = [[NSMutableArray alloc] init];
    NSMutableArray *positionAmount = [[NSMutableArray alloc] init];
    NSMutableArray *positionPrice = [[NSMutableArray alloc] init];
    
    int currentPosition, currentPositionSign, currentSignal;
    long currentDateTime;
    double currentBid = 0.0,currentAsk = 0.0;
    float nextTradeAmount, nextTradePrice, currentCashBalance, tradePnl, interestCosts;
    float largestDrawdown;
    long largestDrawdownDateTime;
    double currentMaximumNav, spreadCost;
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
    nextTradeDateTime = [simulation getDateTimeForTradeAtIndex:tradeIndex];
    
    NSMutableArray *activityDates = [[NSMutableArray alloc] init];
    long activityDateTime;
    int activityIndex = 0;
    BOOL allActivityFinished;
    
    activityDateTime = startDateTime;
    
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
        //numberOfSteps = dateCount;
            
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
        
        //    
        simulationDataDictionary = [[NSMutableDictionary alloc] initWithCapacity:[simDataFieldNames count]];
        simulationDataArray = malloc([simDataFieldNames count] * sizeof(double*));
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
        dataRequestMaxDateTime = endDateTime + (3 * DAY_SECONDS);
        
        if(doThreads){
            [self performSelectorOnMainThread:@selector(readingDatabaseOn) withObject:nil waitUntilDone:NO]; 
        }
      
        if(![marketData getDataSeriesForStartDateTime:dataRequestMinDateTime
                                       AndEndDateTime:dataRequestMaxDateTime]){
            [NSException raise:@"Database problem" format:nil];
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
    signal = [[signalDetails objectForKey:@"SIGNAL"] longValue];
    
    cashMoveIndex = 0;
    allCashMovesFinished = NO;
    cashMoveDetails = [simulation detailsOfBalanceAdjustmentIndex:cashMoveIndex];
    nextCashMoveDateTime = [[cashMoveDetails objectForKey:@"DATETIME"] longValue];
    nextCashMoveAmount = [[cashMoveDetails objectForKey:@"AMOUNT"] floatValue]; 
    nextCashMoveReason = [cashMoveDetails objectForKey:@"REASON"]; 
    
    tradeIndex = 0;
    allTradesFinished = NO;
    tradeDetails = [simulation detailsOfTradeAtIndex:tradeIndex];
    nextTradeDateTime = [[tradeDetails objectForKey:@"DATETIME"] longValue];
    nextTradeAmount = [[tradeDetails objectForKey:@"AMOUNT"] intValue];
    nextTradePrice = [[tradeDetails objectForKey:@"PRICE"] floatValue];
  
    
    tradePnl = 0.0;
    interestCosts = 0.0;
    largestDrawdown = 0.0;
    
    // Main loop
    
    for(int dateIndex = 0; dateIndex < [dateTimesOfAnalysis count]; dateIndex++)
    {
        currentDateTime = [[dateTimesOfAnalysis objectAtIndex:dateIndex] longValue];
        
        // Update the database if needed
        if(currentDateTime > [marketData getMaxDateTimeForLoadedData])
        {
            if(doThreads){
                [self performSelectorOnMainThread:@selector(readingDatabaseOn) withObject:nil waitUntilDone:NO]; 
            }
            dataRequestMinDateTime = [marketData getMaxDateTimeForLoadedData];
            dataRequestMaxDateTime = endDateTime + (3 * DAY_SECONDS);
            [marketData moveDataToStartDateTime:dataRequestMinDateTime
                                 AndEndDateTime:dataRequestMaxDateTime];
//            int tries = 0;
//            while(currentDateTime > [marketData getMaxDateTimeForLoadedData]){
//                
//                dataRequestMinDateTime = [marketData getMaxDateTimeForLoadedData];
//                if(endDateTime < [marketData getMaxDateTimeForLoadedData] + MAX_DATA_CHUNK && tries == 0)
//                {
//                    dataRequestMaxDateTime = endDateTime + (3 * DAY_SECONDS);
//                }else{
//                    if(tries >0){
//                        dataRequestMaxDateTime = dataRequestMaxDateTime + MAX_DATA_CHUNK - [marketData getDataSeriesLength];
//                    }else{
//                        dataRequestMaxDateTime = [marketData getMaxDateTimeForLoadedData] + MAX_DATA_CHUNK;
//                    }
//                }
//                [marketData moveDataToStartDateTime: dataRequestMinDateTime
//                                     AndEndDateTime:dataRequestMaxDateTime];
//                tries ++;
//            }
            if(doThreads){
                [self performSelectorOnMainThread:@selector(readingDatabaseOff) 
                                       withObject:nil 
                                    waitUntilDone:NO];
            }   
        }
        
        // Get the price data values for today
        
        currentDataValues = [marketData getValuesForFields:simDataFieldNames 
                                                AtDateTime:currentDateTime];
        
        for(int fieldIndex = 0; fieldIndex < [simDataFieldNames count]; fieldIndex++){
            simulationDataArray[fieldIndex][dateIndex] = [[currentDataValues objectForKey:[simDataFieldNames objectAtIndex:fieldIndex]] doubleValue];
        }
        
        currentDataValues = [marketData getValuesForFields:bidAskFields 
                                                AtDateTime:currentDateTime];
        
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
                [positionPrice addObject:[NSNumber numberWithFloat:nextTradePrice]];
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
                        [positionPrice addObject:[NSNumber numberWithFloat:nextTradePrice]]; 
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
                            [positionPrice addObject:[NSNumber numberWithFloat:nextTradePrice]];
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
                nextTradePrice = [[tradeDetails objectForKey:@"PRICE"] floatValue];
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
                nextCashMoveAmount = [[cashMoveDetails objectForKey:@"AMOUNT"] floatValue];
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
            signal = [[signalDetails objectForKey:@"SIGNAL"] intValue];
        }
        if(currentDateTime >= signalStartDateTime && currentDateTime < signalEndDateTime){
            currentSignal = signal;
        }else{
            currentSignal = 0;
        }
            
 
               
        dateTimesArray[dateIndex] = currentDateTime;
        signalArray[dateIndex] = (double)currentSignal;
        marketPositionArray[dateIndex] = (double)currentPosition;
        
        shortIndicatorArray[dateIndex] = ([UtilityFunctions signum:currentPosition] < 0)? (double)-currentPosition: 0.0; 
        longIndicatorArray[dateIndex] =  ([UtilityFunctions signum:currentPosition] > 0)? (double)currentPosition: 0.0;
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
        double unrealisedPnl = 0.0;
        if(currentPosition > 0){
            for(int positionIndex = 0; positionIndex < [positionAmount count]; positionIndex++){
                unrealisedPnl = unrealisedPnl + [[positionAmount objectAtIndex:positionIndex] intValue] * ((currentBid -[[positionPrice objectAtIndex:positionIndex] floatValue]));
            }
        }
                              
        if(currentPosition < 0){
            for(int positionIndex = 0; positionIndex < [positionAmount count]; positionIndex++){
                    unrealisedPnl = unrealisedPnl + [[positionAmount objectAtIndex:positionIndex] intValue] * ((currentAsk -[[positionPrice objectAtIndex:positionIndex] floatValue]));
            }
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
                    float accBaseAsk = currentAsk;
                    navArray[dateIndex] = cashPositionArray[dateIndex] + (unrealisedPnl/accBaseAsk);
                }else{
                    float accBaseBid = currentBid;
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
    }
    
    if(!cancelProcedure)
    {
    
        if(!allTradesFinished ){
            [NSException raise:@"All trades were not included for some reason!" format:nil];
        }
        if(!allCashMovesFinished ){
            [NSException raise:@"All cash transactions were not included for some reason!" format:nil];
        }
    
        [simulationDataDictionary setObject:signalData forKey:@"SIGNAL"];
        [simulationDataDictionary setObject:marketPositionData forKey:@"POSITION"];
        [simulationDataDictionary setObject:cashPositionData forKey:@"CASHBALANCE"]; 
        [simulationDataDictionary setObject:navData forKey:@"NAV"];
        [simulationDataDictionary setObject:drawDownData forKey:@"DRAWDOWN"];
        [simulationDataDictionary setObject:marginUsedData forKey:@"MARGINUSED"];
        [simulationDataDictionary setObject:marginAvailableData forKey:@"MARGINAVAIL"];
        [simulationDataDictionary setObject:marginCloseOutData forKey:@"CLOSEOUT"];
        [simulationDataDictionary setObject:shortIndicatorData forKey:@"SHORT"];
        [simulationDataDictionary setObject:longIndicatorData forKey:@"LONG"];
    
        positionDataSeries = [marketData newDataSeriesWithXData: dateTimesData
                                                       AndYData: simulationDataDictionary 
                                                  AndSampleRate: timeStep];
     
        
        [simulation addObjectToSimulationResults:[NSNumber numberWithDouble:navArray[[dateTimesOfAnalysis count]-1]]
                                                  ForKey:@"FINALNAV"];
        [simulation addObjectToSimulationResults:[NSNumber numberWithInt:[simulation numberOfTrades]]
                                                  ForKey:@"NUMBEROFTRADES"];
        [simulation addObjectToSimulationResults:[NSNumber numberWithFloat:allCashTransfers] ForKey:@"CASHTRANSFERS"];
        [simulation addObjectToSimulationResults:[NSNumber numberWithFloat:tradePnl]
                                                  ForKey:@"TRADE PNL"];
        [simulation addObjectToSimulationResults:[NSNumber numberWithFloat:interestCosts]
                                                  ForKey:@"INTEREST"];
        [simulation addObjectToSimulationResults:[NSNumber numberWithFloat:spreadCost]
                                                  ForKey:@"SPREADCOST"]; 
        [simulation addObjectToSimulationResults:[NSNumber numberWithFloat:largestDrawdown]
                                          ForKey:@"BIGGESTDRAWDOWN"];
        [simulation addObjectToSimulationResults:[NSNumber numberWithLong:largestDrawdownDateTime] 
                                          ForKey:@"DRAWDOWNTIME"];
        //         
        //        [simulation addObjectToSimulationResults:[NSNumber numberWithLong:positiveTime]  
        //                                        ForKey:@"PNLUPTIME"];
        //        [simulation addObjectToSimulationResults:[NSNumber numberWithLong:negativeTime]  
        //                                          ForKey:@"PNLDOWNTIME"]; 
        //        
        //        [simulation addObjectToSimulationResults:[NSNumber numberWithFloat:cumulativeMtmPositionalPnlInQuote]
        //                                          ForKey:@"POSITIONPNL"];
        //        //[simulation addObjectToSimulationResults:[NSNumber numberWithFloat:cummulativeTradeCashFlow]
        //        //                                  ForKey:@"TRADECASHFLOW"];
        
        
        int activityCount = [simulation numberOfBalanceAdjustments];
        for(int i = 0; i < activityCount; i++){
            NSDictionary *accountActivity = [simulation detailsOfBalanceAdjustmentIndex:i];
            NSString *reason = [accountActivity objectForKey:@"REASON"];
            NSString *dateTimeString = [EpochTime stringDateWithTime:[[accountActivity objectForKey:@"DATETIME"] longValue]];
            float amount = [[accountActivity objectForKey:@"AMOUNT"] floatValue];
            float resultingBalance = [[accountActivity objectForKey:@"ENDBAL"] floatValue]; 
            userMessage = [NSString stringWithFormat:@"%@",dateTimeString,reason,amount,resultingBalance];
            
            if(doThreads){
                [self performSelectorOnMainThread:@selector(sendMessageToUserInterface:) 
                                       withObject:userMessage waitUntilDone:NO];
            }
        }
    }
    
    if(!cancelProcedure)
    {
        [simulation setAnalysisDataSeries:positionDataSeries];
        [self addSimulationDataToResultsTableView:positionDataSeries];
        [self plotSimulationData:positionDataSeries];
        [self populateAboutPane:simulation];
        [self initialiseSignalTableView];
        [self setupResultsReport];
    
        if(doThreads){
            userMessage = @"Plot Prepared";
            [self performSelectorOnMainThread:@selector(updateStatus:) withObject:userMessage waitUntilDone:NO];
            userMessage = @"Done";
            [self performSelectorOnMainThread:@selector(sendMessageToUserInterface:) withObject:userMessage waitUntilDone:NO];
        }
    }

}



//-(void)analyseSimulation: (Simulation *) simulation
//{
//    NSString *userMessage;
//    long startDateTime, endDateTime;
//    int timeStep;
//    long nextTradeDateTime;
//    int nextTradeAmount;
//    long nextBalAdjDateTime;
//    float nextBalAdjAmount;
//    BOOL nextBalAdjIsTransfer;
//    
//    long signalStartDateTime;
//    long signalEndDateTime;
//    int  signal;
//    int signalIndex;
//    
//    float nextTradePrice;
//    int currentPosition;
//    
//    BOOL allTradesFinished, noMoreBalanceAdjustments, allOk;
//    int tradeIndex = 0;
//    int balAdjIndex = 0;
//    int dateCount = 0;
//    int numberOfSteps;
//    
//    long simulationDateTime;
//    NSMutableData *dateTimesData;
//    long *dateTimesArray;
//    NSMutableDictionary *simulationDataDictionary;
//    double **simulationDataArray;
//    NSMutableData *signalData;
//    double *signalArray;
//    NSMutableData *positionData;
//    double *positionArray;
//    NSMutableData *shortIndicatorData;
//    double *shortIndicatorArray;
//    NSMutableData *longIndicatorData;
//    double *longIndicatorArray;
//    NSMutableData *marginUsedData;
//    double *marginUsedArray;
//    NSMutableData *marginAvailableData;
//    double *marginAvailableArray;
//    NSMutableData *marginCloseOutData;
//    double *marginCloseOutArray;
//
//    NSMutableData *cashFlowData;
//    double *cashFlowArray;
//    
//    NSMutableData *cashPositionData;
//    double *cashPositionArray;
//    
//    NSMutableData *navData;
//    double *navArray;
//    
//    NSMutableArray *positionDateTime = [[NSMutableArray alloc] init];
//    NSMutableArray *positionAmount = [[NSMutableArray alloc] init];
//    NSMutableArray *positionPrice = [[NSMutableArray alloc] init];
//    float cashPosition = 0;
//    float unrealisedPnl;
//    int currentPositionSign = 0;
//    double maxSoFar;
//    double largestDrawdown;
//    long largestDrawdownDateTime;
//    
//    //Account can only be in the quote currency or the base currency for now
//    BOOL accountCurrencyIsQuoteCurrency = NO;
//    
//    NSArray *fieldNames;
//    DataSeries *positionDataSeries;
//    
//    if(!cancelProcedure){
//        if([[simulation accCode] isEqualToString:[simulation quoteCode]]){
//            accountCurrencyIsQuoteCurrency = YES;
//        }
//       
//        userMessage = [NSString stringWithFormat:@"There were %d trades",[simulation numberOfTrades]];
//        if(doThreads){
//            [self performSelectorOnMainThread:@selector(sendMessageToUserInterface:) withObject:userMessage waitUntilDone:NO];
//        }
//        startDateTime = [simulation startDate];
//        endDateTime = [simulation endDate];
//        timeStep = [simulation samplingRate];
//        nextTradeDateTime = [simulation getDateTimeForTradeAtIndex:0];
//        
//        
//        allTradesFinished = NO;
//    
//        simulationDateTime = startDateTime;
//        do{
//            if(!allTradesFinished){
//                if(simulationDateTime >= nextTradeDateTime){
//                    //If the nextTradeDate doesn't fall on the sample time add in an extra 
//                    if(simulationDateTime > nextTradeDateTime){
//                        dateCount++; 
//                    }
//                    tradeIndex++;
//                    if(tradeIndex<[simulation numberOfTrades]){
//                        nextTradeDateTime = [simulation getDateTimeForTradeAtIndex:tradeIndex];
//                        if(nextTradeDateTime > endDateTime)
//                        {
//                            endDateTime = nextTradeDateTime;
//                        }
//                    }else{
//                        allTradesFinished = YES;
//                    }
//                }
//            }
//            dateCount++;
//            simulationDateTime = simulationDateTime + timeStep;
//        }while((simulationDateTime <= endDateTime || !allTradesFinished) && !cancelProcedure);
//    }
//    
//    long dataRequestMinDateTime, dataRequestMaxDateTime;
//    if(!cancelProcedure){
//        numberOfSteps = dateCount;
//        
//        dateTimesData = [[NSMutableData alloc] initWithLength:dateCount * sizeof(long)]; 
//        dateTimesArray = [dateTimesData mutableBytes];
//        
//        signalData = [[NSMutableData alloc] initWithLength:dateCount * sizeof(double)];
//        signalArray = [signalData mutableBytes];
//        
//        positionData = [[NSMutableData alloc] initWithLength:dateCount * sizeof(double)]; 
//        positionArray = [positionData mutableBytes];
//    
//        shortIndicatorData = [[NSMutableData alloc] initWithLength:dateCount * sizeof(double)]; 
//        shortIndicatorArray = [shortIndicatorData mutableBytes];
//
//        longIndicatorData = [[NSMutableData alloc] initWithLength:dateCount * sizeof(double)]; 
//        longIndicatorArray = [longIndicatorData mutableBytes];
//    
//        marginUsedData = [[NSMutableData alloc] initWithLength:dateCount * sizeof(double)];
//        marginUsedArray = [marginUsedData mutableBytes];
//        
//        marginAvailableData = [[NSMutableData alloc] initWithLength:dateCount * sizeof(double)];
//        marginAvailableArray = [marginAvailableData mutableBytes];
//       
//        marginCloseOutData = [[NSMutableData alloc] initWithLength:dateCount * sizeof(double)];
//        marginCloseOutArray = [marginCloseOutData mutableBytes];
// 
//        cashPositionData = [[NSMutableData alloc] initWithLength:dateCount * sizeof(double)]; 
//        cashPositionArray = [cashPositionData mutableBytes]; 
//    
//        navData = [[NSMutableData alloc] initWithLength:dateCount * sizeof(double)]; 
//        navArray = [navData mutableBytes]; 
//    
//        DataSeries *simulationDataSeries;
//        simulationDataSeries = [simulation simulationDataSeries];
//        
//        fieldNames = [simulationDataSeries getFieldNames];
//    
//        simulationDataDictionary = [[NSMutableDictionary alloc] initWithCapacity:[fieldNames count]];
//        simulationDataArray = malloc([fieldNames count] * sizeof(double*));
//        for(int fieldIndex = 0; fieldIndex < [fieldNames count]; fieldIndex++){
//            [simulationDataDictionary setObject:[[NSMutableData alloc] initWithLength:dateCount * sizeof(double)] forKey:[fieldNames objectAtIndex:fieldIndex]];
//            simulationDataArray[fieldIndex] = [[simulationDataDictionary objectForKey:[fieldNames objectAtIndex:fieldIndex]] mutableBytes];
//        }
//    
//        //This ensures that ac variables are similar and there is no problems 
//        // due to not getting the first price, which may be slightly older 
//        // than the start time of the simulation
//        dataRequestMinDateTime = [simulation dataStartDateTime];
//        dataRequestMaxDateTime = [simulation dataStartDateTime] +MAX_DATA_CHUNK;
//    
//        if(doThreads){
//            [self performSelectorOnMainThread:@selector(readingDatabaseOn) withObject:nil waitUntilDone:NO]; 
//        }
//    
//        allOk = [marketData getDataSeriesForStartDateTime:dataRequestMinDateTime
//                                       AndEndDateTime:dataRequestMaxDateTime];
//
//        if(doThreads){
//            [self performSelectorOnMainThread:@selector(readingDatabaseOff) withObject:nil waitUntilDone:NO];
//        }
//    }     
//    
//    if(allOk && !cancelProcedure){
//        for(int i = 0; i < [fieldNames count]; i++){
//            NSString *fieldName = [fieldNames objectAtIndex:i];
//            if(![fieldName isEqualToString:@"MID"]){
//                if([fieldName length]>4){
//                    if([[fieldName substringToIndex:4] isEqualToString:@"EWMA"]){
//                        int ewmaNumber = [[fieldName substringFromIndex:4] intValue];
//                        [marketData addEWMAByIndex:ewmaNumber];
//                    }
//                }
//            }
//        }
//      
//        double currentBid = 0.0,currentAsk = 0.0;
//        BOOL tradeAtThisTime;
//        //positiveTime = 0; 
//        //negativeTime = 0;
//        long previousDateTime;
//        
//        NSArray *bidAskFields = [NSArray arrayWithObjects:@"BID",@"ASK", nil];
//        NSDictionary *valuesAtDate;
//        
//        tradeIndex = 0;
//        signalIndex = 0;
//        dateCount = 0;
//        startDateTime = [simulation startDate];
//        endDateTime = [simulation endDate];
//        
//        nextTradeDateTime = [simulation getDateTimeForTradeAtIndex:tradeIndex];
//        nextTradeAmount = [simulation getAmountForTradeAtIndex:tradeIndex];
//        nextTradePrice = [simulation getPriceForTradeAtIndex:tradeIndex];
//        
//        nextBalAdjDateTime = [simulation getDateTimeForBalanceAdjustmentAtIndex:balAdjIndex];
//        nextBalAdjAmount = [simulation getAmountForBalanceAdjustmentAtIndex:balAdjIndex];
//        nextBalAdjIsTransfer = [simulation  isTransferBalanceAdjustmentAtIndex:balAdjIndex];
//        
//        signalStartDateTime = [simulation getDateTimeStartForBiasChangeAtIndex:signalIndex];
//        signalEndDateTime = [simulation getDateTimeEndForBiasChangeAtIndex:signalIndex];
//        signal = [simulation getNewBiasForChangeAtIndex:signalIndex];
//        
//        //currentPosition = 0;
//        
//        allTradesFinished = NO;
//        noMoreBalanceAdjustments = NO;
//        
//        simulationDateTime = startDateTime;
//        
//        if(doThreads){
//            [self performSelectorOnMainThread:@selector(setProgressRangeWithMinAndMax:) withObject:[NSArray arrayWithObjects:[NSNumber numberWithLong:startDateTime], [NSNumber numberWithLong:endDateTime], nil] waitUntilDone:YES];
//            [self performSelectorOnMainThread:@selector(progressBarOn) withObject:nil waitUntilDone:NO];
//        }
//
//        if(doThreads){
//            userMessage = @"Analysis of Simulation";
//            [self performSelectorOnMainThread:@selector(updateStatus:) withObject:userMessage waitUntilDone:NO];
//        }
//        do{
//            tradeAtThisTime = NO;
//            if(!allTradesFinished){
//                //currentDateAsString = [EpochTime stringDateWithTime:simulationDateTime];
//                if(MIN(nextTradeDateTime,simulationDateTime) > [marketData getMaxDateTimeForLoadedData])
//                {
//                    if(doThreads){
//                        [self performSelectorOnMainThread:@selector(readingDatabaseOn) withObject:nil waitUntilDone:NO]; 
//                    }
//                    int tries = 0;
//                    while(MIN(nextTradeDateTime,simulationDateTime) > [marketData getMaxDateTimeForLoadedData]){
//                        dataRequestMinDateTime = [marketData getMaxDateTimeForLoadedData];
//                        if(endDateTime < [marketData getMaxDateTimeForLoadedData] + MAX_DATA_CHUNK && tries == 0)
//                        {
//                            dataRequestMaxDateTime = endDateTime + (3 * DAY_SECONDS);
//                        }else{
//                            if(tries >0){
//                                dataRequestMaxDateTime = dataRequestMaxDateTime + MAX_DATA_CHUNK - [marketData getDataSeriesLength];
//                            }else{
//                                dataRequestMaxDateTime = [marketData getMaxDateTimeForLoadedData] + MAX_DATA_CHUNK;
//                            }
//                        }
//                        [marketData moveDataToStartDateTime: dataRequestMinDateTime
//                                         AndEndDateTime:dataRequestMaxDateTime];
//                        tries ++;
//                    }
//                    
//                    if(doThreads){
//                        [self performSelectorOnMainThread:@selector(readingDatabaseOff) withObject:nil waitUntilDone:NO];
//                    }
//                }
//                //Get all the data and fill it in. This is an extra day to the to days the 
//                // samples fall on
//                                
//                if(simulationDateTime >= nextTradeDateTime){
//                    //We trade on this day. It may the next sample day ==
//                    // or the next sample day may be greater than the tradign day so 
//                    // we impute an extra sample time 
//                    
//                    tradeAtThisTime = YES;
//                    
//                    //mtmTradingPnlData[dateCount] = tradingPnl;
//                    if(currentPosition > 0){
//                        currentPositionSign = 1;
//                    }
//                    if(currentPosition < 0){
//                        currentPositionSign = -1;
//                    }
//                    
//                    // If the next trade is on the opposite side of the current positions
//                    // we start by reducing current positions towards zero
//                    if(currentPosition !=0 && (currentPositionSign * nextTradeAmount) < 0)
//                    {
//                        int remainingTrade = nextTradeAmount;
//                        int numberOfTradesToRemove = 0;
//                        while(remainingTrade != 0){
//                        if([positionDateTime count] ==0){
//                            [positionDateTime addObject:[NSNumber numberWithLong:nextTradeDateTime]]; 
//                            [positionAmount addObject:[NSNumber numberWithInt:remainingTrade]];
//                            [positionPrice addObject:[NSNumber numberWithFloat:nextTradePrice]];     
//                        }else{
//                            int positionIndex = 0;
//                            int openPositionAmount = 0;
//                                while((positionIndex < [positionDateTime count]) && (remainingTrade != 0)){
//                                    openPositionAmount = [[positionAmount objectAtIndex:positionIndex] intValue];
//                                    if(ABS(openPositionAmount) > ABS(remainingTrade)){
//                                        [positionAmount replaceObjectAtIndex:positionIndex withObject:[NSNumber numberWithInt:openPositionAmount - remainingTrade]];
//                                            remainingTrade = 0;
//                                    }else{
//                                        remainingTrade = remainingTrade + openPositionAmount;
//                                        numberOfTradesToRemove++;
//                                    }
//                                    positionIndex++;
//                                }
//                                if(remainingTrade != 0){
//                                    [positionDateTime addObject:[NSNumber numberWithLong:nextTradeDateTime]]; 
//                                    [positionAmount addObject:[NSNumber numberWithInt:remainingTrade]];
//                                    [positionPrice addObject:[NSNumber numberWithFloat:nextTradePrice]];
//                                    remainingTrade = 0;
//                                }
//                            }
//                        }
//                        // Remove any trades which have been fully closed out 
//                        if(numberOfTradesToRemove > 0){
//                            for(int i = 0;i < numberOfTradesToRemove; i++){
//                                [positionDateTime removeObjectAtIndex:0];
//                                [positionAmount removeObjectAtIndex:0];
//                                [positionPrice removeObjectAtIndex:0];
//                            }
//                        }
//                   
//                    }else{
//                        [positionDateTime addObject:[NSNumber numberWithLong:nextTradeDateTime]]; 
//                        [positionAmount addObject:[NSNumber numberWithInt:nextTradeAmount]];
//                        [positionPrice addObject:[NSNumber numberWithFloat:nextTradePrice]];
//                    }
//                    
//                    //If the nextTradeDate doesn't fall on the sample time add in an extra 
//                    // So the nextTradeDateTime takes over form the simulationDateTime in this section
//                    
//                    if(simulationDateTime > nextTradeDateTime){
//                        //A trade fell occured on a date not in the sampling schedule so stick it in extra 
//                        
//                        valuesAtDate = [marketData getValuesForFields:fieldNames 
//                                                                         AtDateTime:nextTradeDateTime];
//                        
//                        for(int fieldIndex = 0; fieldIndex < [fieldNames count]; fieldIndex++){
//                            simulationDataArray[fieldIndex][dateCount] = [[valuesAtDate objectForKey:[fieldNames objectAtIndex:fieldIndex]] doubleValue];
//                        }
//                        
//                        valuesAtDate = [marketData getValuesForFields:bidAskFields 
//                                                           AtDateTime:nextTradeDateTime];
//                        currentBid = [[valuesAtDate objectForKey:@"BID"] doubleValue];
//                        currentAsk = [[valuesAtDate objectForKey:@"ASK"] doubleValue];
//                        
//                        currentPosition = currentPosition + nextTradeAmount;   
//                        dateTimesArray[dateCount] = nextTradeDateTime;
//                        positionArray[dateCount] = (double)currentPosition; 
//                        
//                        if(currentPosition < 0){
//                            shortIndicatorArray[dateCount] = -positionArray[dateCount];
//                            longIndicatorArray[dateCount] = 0.0;
//                        }
//                        if(currentPosition > 0){
//                            shortIndicatorArray[dateCount] = 0.0;
//                            longIndicatorArray[dateCount] = positionArray[dateCount];
//                        }
//                        if(currentPosition == 0){
//                            shortIndicatorArray[dateCount] = 0.0;
//                            longIndicatorArray[dateCount] = 0.0;
//                        }
//                        
//                        marginUsedArray[dateCount] =  ABS(currentPosition) /[simulation maxLeverage];
//                        if(accountCurrencyIsQuoteCurrency){
//                            if(currentPosition < 0){
//                                marginUsedArray[dateCount] = marginUsedArray[dateCount] * currentBid;
//                            }else{
//                                marginUsedArray[dateCount] = marginUsedArray[dateCount] * currentAsk;
//                            }
//                        }
//                        
//                        previousDateTime = nextTradeDateTime;
//                        
//                        while(nextBalAdjDateTime <= nextTradeDateTime && !noMoreBalanceAdjustments){
//                            if(nextBalAdjIsTransfer){
//                                cashPosition = cashPosition + nextBalAdjAmount;
//                            }
//                            if(balAdjIndex < ([simulation numberOfBalanceAdjustments]-1)){
//                                balAdjIndex++;
//                                nextBalAdjDateTime = [simulation getDateTimeForBalanceAdjustmentAtIndex:balAdjIndex];
//                                nextBalAdjAmount = [simulation getAmountForBalanceAdjustmentAtIndex:balAdjIndex];
//                                nextBalAdjIsTransfer = [simulation isTransferBalanceAdjustmentAtIndex:balAdjIndex];
//                            }else{
//                                noMoreBalanceAdjustments = YES;
//                            }
//                        }
//                        cashPositionArray[dateCount] = currentSimulationBalanceInQuote;
//                        cashFlowArray[dateCount] = cashPosition;
//                        unrealisedPnl = 0.0;
//                        if(currentPosition > 0){
//                            for(int positionIndex = 0; positionIndex < [positionAmount count]; positionIndex++){
//                                unrealisedPnl = unrealisedPnl + [[positionAmount objectAtIndex:positionIndex] intValue] * ((currentBid -[[positionPrice objectAtIndex:positionIndex] floatValue]));
//                            }
//                        }
//                        if(currentPosition < 0){
//                            for(int positionIndex = 0; positionIndex < [positionAmount count]; positionIndex++){
//                                unrealisedPnl = unrealisedPnl + [[positionAmount objectAtIndex:positionIndex] intValue] * ((currentAsk -[[positionPrice objectAtIndex:positionIndex] floatValue]));
//                            }
//       
//                        }
//                        if(currentPosition == 0){
//                            navArray[dateCount] = cashPositionArray[dateCount];
//                        }else{
//                            if(unrealisedPnl > 0){
//                                float accBaseAsk = currentAsk;
//                                navArray[dateCount] = cashPositionArray[dateCount] + (unrealisedPnl/accBaseAsk);
//                            }else{
//                                float accBaseBid = currentBid;
//                                navArray[dateCount] = cashPositionArray[dateCount] + (unrealisedPnl/accBaseBid);
//                            }
//                        }
//                        marginAvailableArray[dateCount] = navArray[dateCount] - marginUsedArray[dateCount];
//                        marginCloseOutArray[dateCount] = navArray[dateCount] - (marginUsedArray[dateCount]/2);
//                        
//                        
//                        //This part adds in the current signal
//                        
//                        while((signalEndDateTime <= nextTradeDateTime) && (signalIndex < ([simulation numberOfBiasStats]-1))){
//                            signalIndex++;
//                            signalStartDateTime = [simulation getDateTimeStartForBiasChangeAtIndex:signalIndex];
//                            signalEndDateTime = [simulation getDateTimeEndForBiasChangeAtIndex:signalIndex];
//                            signal = [simulation getNewBiasForChangeAtIndex:signalIndex];
//                        }
//                        if((simulationDateTime >= signalStartDateTime) & (simulationDateTime <= signalEndDateTime)){
//                            signalArray[dateCount] = (double)signal;
//                        }
//                        
//                        ////
//                        dateCount++;
//                        //Done with this trade
//                        tradeAtThisTime = NO;
//                    }   
//                    tradeIndex++;
//                    if(tradeIndex<[simulation numberOfTrades]){
//                        nextTradeDateTime = [simulation getDateTimeForTradeAtIndex:tradeIndex];
//                        nextTradeAmount = [simulation getAmountForTradeAtIndex:tradeIndex];
//                        nextTradePrice = [simulation getPriceForTradeAtIndex:tradeIndex];
//                        if(nextTradeDateTime > endDateTime)
//                        {
//                            endDateTime = nextTradeDateTime;
//                        }
//                    }else{
//                        allTradesFinished = YES;
//                    }
//                }
//            }else{
//                if(simulationDateTime > [marketData getMaxDateTimeForLoadedData])
//                {
//                    if(doThreads){
//                        [self performSelectorOnMainThread:@selector(readingDatabaseOn) withObject:nil waitUntilDone:NO]; 
//                    }
//                    int tries = 0;
//                    while(simulationDateTime > [marketData getMaxDateTimeForLoadedData]){
//                        dataRequestMinDateTime = [marketData getMaxDateTimeForLoadedData];
//                        if(endDateTime < [marketData getMaxDateTimeForLoadedData] + MAX_DATA_CHUNK && tries == 0)
//                        {
//                            dataRequestMaxDateTime = endDateTime + (3 * DAY_SECONDS);
//                        }else{
//                            if(tries >0){
//                                dataRequestMaxDateTime = dataRequestMaxDateTime + MAX_DATA_CHUNK - [marketData getDataSeriesLength];
//                            }else{
//                                dataRequestMaxDateTime = [marketData getMaxDateTimeForLoadedData] + MAX_DATA_CHUNK;
//                            }
//                        }
//                        [marketData moveDataToStartDateTime: dataRequestMinDateTime
//                                             AndEndDateTime:dataRequestMaxDateTime];
//                        tries ++;
//                    }
//                    
//                    if(doThreads){
//                        [self performSelectorOnMainThread:@selector(readingDatabaseOff) withObject:nil waitUntilDone:NO];
//                    }
//                }
//
//            }
//             
//            valuesAtDate = [marketData getValuesForFields:bidAskFields 
//                                                             AtDateTime:simulationDateTime];
//            //Check if this is successful!!!!!
//     
//            currentBid = [[valuesAtDate objectForKey:@"BID"] doubleValue];
//            currentAsk = [[valuesAtDate objectForKey:@"ASK"] doubleValue];
//            if(currentPosition > 0){
//                cumulativeMtmPositionalPnlInQuote = cumulativeMtmPositionalPnlInQuote  + currentPosition *(currentBid - previousBid);
//                if((currentBid - previousBid)>=0){
//                    positiveTime = positiveTime + (simulationDateTime - previousDateTime);
//                }else{
//                    negativeTime = negativeTime + (simulationDateTime - previousDateTime);
//                }
//            }
//            if(currentPosition < 0){
//                cumulativeMtmPositionalPnlInQuote = cumulativeMtmPositionalPnlInQuote + currentPosition *(currentAsk - previousAsk);
//                if((currentAsk - previousAsk)<0){
//                    positiveTime = positiveTime + (simulationDateTime - previousDateTime);
//                }else{
//                    negativeTime = negativeTime + (simulationDateTime - previousDateTime);
//                }
//            }
//          
//            valuesAtDate = [marketData getValuesForFields:fieldNames 
//                                               AtDateTime:simulationDateTime];
//            for(int fieldIndex = 0; fieldIndex < [fieldNames count]; fieldIndex++){
//                simulationDataArray[fieldIndex][dateCount] = [[valuesAtDate objectForKey:[fieldNames objectAtIndex:fieldIndex]] doubleValue];
//            }
//            if(tradeAtThisTime){
//                currentPosition = currentPosition + nextTradeAmount;
//            }
//            
//            dateTimesArray[dateCount] = simulationDateTime;
//            positionArray[dateCount] = (double)currentPosition;
//            
//            if(currentPosition < 0){
//                shortIndicatorArray[dateCount] = -positionArray[dateCount];
//                longIndicatorArray[dateCount] = 0.0;
//            }
//            if(currentPosition > 0){
//                shortIndicatorArray[dateCount] = 0.0;
//                longIndicatorArray[dateCount] = positionArray[dateCount];
//            }
//            if(currentPosition == 0){
//                shortIndicatorArray[dateCount] = 0.0;
//                longIndicatorArray[dateCount] = 0.0;
//            }
//            
//            marginUsedArray[dateCount] =  ABS(currentPosition)/[simulation maxLeverage];
//            if(accountCurrencyIsQuoteCurrency){
//                if(currentPosition < 0){
//                    marginUsedArray[dateCount] = marginUsedArray[dateCount] * currentBid;
//                }else{
//                    marginUsedArray[dateCount] = marginUsedArray[dateCount] * currentAsk;
//                }
//            }
//            
// //           mtmPositionalPnlArray[dateCount] = cumulativeMtmPositionalPnlInQuote; 
//            tradeCashFlowArray[dateCount] = cummulativeTradeCashFlowInQuote;
//            
//            while(nextBalAdjDateTime <= simulationDateTime && !noMoreBalanceAdjustments){
//                currentSimulationBalanceInQuote = currentSimulationBalanceInQuote + nextBalAdjAmount;
//                if(nextBalAdjIsTransfer){
//                    cashPosition = cashPosition + nextBalAdjAmount;
//                }
//                if(balAdjIndex < ([simulation numberOfBalanceAdjustments]-1)){
//                    balAdjIndex++;
//                    nextBalAdjDateTime = [simulation getDateTimeForBalanceAdjustmentAtIndex:balAdjIndex];
//                    nextBalAdjAmount = [simulation getAmountForBalanceAdjustmentAtIndex:balAdjIndex];
//                    nextBalAdjIsTransfer = [simulation isTransferBalanceAdjustmentAtIndex:balAdjIndex];
//                }else{
//                    noMoreBalanceAdjustments = YES;
//                }
//            }
//            cashPositionArray[dateCount] = currentSimulationBalanceInQuote;
//            cashFlowArray[dateCount] = cashPosition;
//            unrealisedPnl = 0.0;
//            if(currentPosition > 0){
//                for(int positionIndex = 0; positionIndex < [positionAmount count]; positionIndex++){
//                    unrealisedPnl = unrealisedPnl + [[positionAmount objectAtIndex:positionIndex] intValue] * ((currentBid-[[positionPrice objectAtIndex:positionIndex] floatValue]));
//                }
//            }
//            if(currentPosition < 0){
//                for(int positionIndex = 0; positionIndex < [positionAmount count]; positionIndex++){
//                    unrealisedPnl = unrealisedPnl + [[positionAmount objectAtIndex:positionIndex] intValue] * ((currentAsk - [[positionPrice objectAtIndex:positionIndex] floatValue]));
//                }
//                
//            }
//            if(currentPosition == 0){
//                navArray[dateCount] = cashPositionArray[dateCount];
//            }else{
//                if(unrealisedPnl > 0){
//                    float accBaseAsk = currentAsk;
//                    navArray[dateCount] = cashPositionArray[dateCount] + (unrealisedPnl/accBaseAsk);
//                }else{
//                    float accBaseBid = currentBid;
//                    navArray[dateCount] = cashPositionArray[dateCount] + (unrealisedPnl/accBaseBid);
//                }
//            }
//            marginAvailableArray[dateCount] = navArray[dateCount] - marginUsedArray[dateCount];
//            marginCloseOutArray[dateCount] = navArray[dateCount] - (marginUsedArray[dateCount]/2);
//            
//            
//            //This part adds in the current signal
//            
//            while((signalEndDateTime <= simulationDateTime) && (signalIndex < ([simulation numberOfBiasStats]-1))){
//                signalIndex++;
//                signalStartDateTime = [simulation getDateTimeStartForBiasChangeAtIndex:signalIndex];
//                signalEndDateTime = [simulation getDateTimeEndForBiasChangeAtIndex:signalIndex];
//                signal = [simulation getNewBiasForChangeAtIndex:signalIndex];
//            }
//            if((simulationDateTime >= signalStartDateTime) & (simulationDateTime <= signalEndDateTime)){
//                signalArray[dateCount] = (double)signal;
//            }
//            
//            ////
//            
//            dateCount++;
//            previousDateTime = simulationDateTime;
//            simulationDateTime = simulationDateTime + timeStep;
//            if(doThreads){
//                [self performSelectorOnMainThread:@selector(incrementProgressBy:) withObject:[NSNumber numberWithInt:timeStep] waitUntilDone:NO];
//            }
//            
//        }while((simulationDateTime <= endDateTime || !allTradesFinished) && !cancelProcedure);
//    }
//    if(doThreads){
//        [self performSelectorOnMainThread:@selector(progressBarOff) withObject:nil waitUntilDone:YES];
//    }
//
//    int finalDataIndex = dateCount-1;    
//    // Done, now gather numbers together to report
//    
//    
//    
//    if(allOk && !cancelProcedure){
//        NSString *userMessage;
//       
//        double finalNav = navArray[finalDataIndex];
//        float spreadCost = 0.0;
//        for(int i = 0; i<[simulation numberOfTrades];i++){
//            spreadCost = spreadCost + [simulation getTotalSpreadCostForTradeAtIndex:i];
//        }
//        float cashTransfers = 0.0;
//        float interestCosts = 0.0;
//        float tradePnl = 0.0;
//        
//        
//        NSDictionary *balanceAdjustment;
//        
//        for(int i = 0; i <[simulation numberOfBalanceAdjustments]; i++){
//            balanceAdjustment = [simulation detailsOfBalanceAdjustmentIndex:i];
//            if([[balanceAdjustment objectForKey:@"REASON"] isEqualToString:@"TRANSFER"])
//            {
//                cashTransfers = cashTransfers + [[balanceAdjustment objectForKey:@"AMOUNT"] floatValue];
//            }
//            if([[balanceAdjustment objectForKey:@"REASON"] isEqualToString:@"INTEREST"])
//            {
//                interestCosts = interestCosts + [[balanceAdjustment objectForKey:@"AMOUNT"] floatValue];
//            }
//            if([[balanceAdjustment objectForKey:@"REASON"] isEqualToString:@"TRADE PNL"])
//            {
//                tradePnl = tradePnl + [[balanceAdjustment objectForKey:@"AMOUNT"] floatValue];
//            }
//        }
//        
//        largestDrawdown = 0.0;
//        maxSoFar = navArray[0];
//        for(int i = 0; i < dateCount; i++){
//           if(navArray[i] > maxSoFar){
//               maxSoFar = navArray[i];
//           }else{
//               if( (maxSoFar-navArray[i]) > largestDrawdown){
//                   largestDrawdown = maxSoFar-navArray[i];
//                   largestDrawdownDateTime = dateTimesArray[i];
//               }
//           }
//        } 
//        
//        [simulation addObjectToSimulationResults:[NSNumber numberWithDouble:finalNav]
//                                          ForKey:@"FINALNAV"];
//        [simulation addObjectToSimulationResults:[NSNumber numberWithInt:[simulation numberOfTrades]]
//                                          ForKey:@"NUMBEROFTRADES"];
//        [simulation addObjectToSimulationResults:[NSNumber numberWithFloat:cashTransfers]
//                                          ForKey:@"CASHTRANSFERS"];
//        [simulation addObjectToSimulationResults:[NSNumber numberWithFloat:tradePnl]
//                                          ForKey:@"TRADE PNL"];
//        [simulation addObjectToSimulationResults:[NSNumber numberWithFloat:interestCosts]
//                                          ForKey:@"INTEREST"];
//        [simulation addObjectToSimulationResults:[NSNumber numberWithFloat:spreadCost]
//                                          ForKey:@"SPREADCOST"]; 
//        
//        
//        
//        [simulation addObjectToSimulationResults:[NSNumber numberWithFloat:largestDrawdown]
//                                          ForKey:@"BIGGESTDRAWDOWN"];
//        [simulation addObjectToSimulationResults:[NSNumber numberWithLong:largestDrawdownDateTime]
//                                          ForKey:@"DRAWDOWNTIME"];
//         
//        [simulation addObjectToSimulationResults:[NSNumber numberWithLong:positiveTime]  
//                                        ForKey:@"PNLUPTIME"];
//        [simulation addObjectToSimulationResults:[NSNumber numberWithLong:negativeTime]  
//                                          ForKey:@"PNLDOWNTIME"]; 
//        
//        [simulation addObjectToSimulationResults:[NSNumber numberWithFloat:cumulativeMtmPositionalPnlInQuote]
//                                          ForKey:@"POSITIONPNL"];
//        //[simulation addObjectToSimulationResults:[NSNumber numberWithFloat:cummulativeTradeCashFlow]
//        //                                  ForKey:@"TRADECASHFLOW"];
//        
//        
//        
//        userMessage = [NSString stringWithFormat:@"Largest Drawdown of: %5.2f on %@", largestDrawdown,[EpochTime stringDateWithTime:largestDrawdownDateTime]];
//        
//        if(doThreads){
//            [self performSelectorOnMainThread:@selector(sendMessageToUserInterface:) withObject:userMessage waitUntilDone:NO];
//        }
//        userMessage = [NSString stringWithFormat:@"P&L due to Exposure: %5.2f",cumulativeMtmPositionalPnlInQuote];
//        if(doThreads){
//            [self performSelectorOnMainThread:@selector(sendMessageToUserInterface:) withObject:userMessage waitUntilDone:NO];
//        }
//        userMessage = [NSString stringWithFormat:@"Trading Cash Flow: %5.2f",cummulativeTradeCashFlowInQuote];
//        if(doThreads){
//            [self performSelectorOnMainThread:@selector(sendMessageToUserInterface:) withObject:userMessage waitUntilDone:NO];
//        }
//        userMessage = [NSString stringWithFormat:@"P&L went up about %5.2f and down %5.2f days, out of %5.2f",(double)positiveTime/(24*60*60),(double)negativeTime/(24*60*60),(double)(dateTimesArray[dateCount-1]-dateTimesArray[0])/(24*60*60)] ; 
//        if(doThreads){
//            [self performSelectorOnMainThread:@selector(sendMessageToUserInterface:) withObject:userMessage waitUntilDone:NO];
//        }
//    }else{
//        [self updateStatus:@"Database Problem; quitting"];
//    }
//    
//    if(allOk && !cancelProcedure){
//        
//        if(doThreads){
//            userMessage = @"Preparing Plot";
//            [self performSelectorOnMainThread:@selector(updateStatus:) withObject:userMessage waitUntilDone:NO];
//        }
//    
//        //Get arrays of the long and short periods
//        NSMutableArray *shortPeriods = [[NSMutableArray alloc] init];
//        NSMutableArray *longPeriods = [[NSMutableArray alloc] init];
//    
//        currentPosition = 0;
//        long positionStartTime = 0;
//        for(int tradeIndex = 0; tradeIndex < [simulation numberOfTrades]; tradeIndex++){
//            if(currentPosition == 0){
//                positionStartTime = [simulation getDateTimeForTradeAtIndex:tradeIndex];
//            }else{
//                if(currentPosition > 0){
//                    if(currentPosition + [simulation getAmountForTradeAtIndex:tradeIndex] <=0){
//                        [longPeriods addObject:[NSNumber numberWithLong:positionStartTime]];
//                        [longPeriods addObject:[NSNumber numberWithLong:[simulation getDateTimeForTradeAtIndex:tradeIndex]]];
//                    }
//                    if(currentPosition + [simulation getAmountForTradeAtIndex:tradeIndex] <0){
//                        positionStartTime = [simulation getDateTimeForTradeAtIndex:tradeIndex];
//                    }else{
//                        positionStartTime = 0;
//                    }
//                }
//                if(currentPosition < 0){
//                    if(currentPosition + [simulation getAmountForTradeAtIndex:tradeIndex] >=0){
//                        [shortPeriods addObject:[NSNumber numberWithLong:positionStartTime]];
//                        [shortPeriods addObject:[NSNumber numberWithLong:[simulation getDateTimeForTradeAtIndex:tradeIndex]]];
//                    }
//                    if(currentPosition + [simulation getAmountForTradeAtIndex:tradeIndex] >0){
//                        positionStartTime = [simulation getDateTimeForTradeAtIndex:tradeIndex];
//                    }else{
//                        positionStartTime = 0;
//                    }
//                }
//            }
//            currentPosition = currentPosition + [simulation getAmountForTradeAtIndex:tradeIndex];
//        }
//
//        [simulation setShortPeriods:shortPeriods];
//        [simulation setLongPeriods:longPeriods];
//        //Get arrays of the long and short periods DONE
//    }
//    
//    if(allOk && !cancelProcedure)
//    {
//        [simulationDataDictionary setObject:signalData forKey:@"SIGNAL"];
//        [simulationDataDictionary setObject:positionData forKey:@"POSITION"];
//        //[simulationDataDictionary setObject:mtmPositionalPnlData forKey:@"POS_PNL"];
//        //[simulationDataDictionary setObject:tradeCashFlowData forKey:@"TRADE_PNL"];
//        [simulationDataDictionary setObject:cashPositionData forKey:@"BALANCE"]; 
//        [simulationDataDictionary setObject:navData forKey:@"NAV"];
//        [simulationDataDictionary setObject:marginUsedData forKey:@"MARGINUSED"];
//        [simulationDataDictionary setObject:marginAvailableData forKey:@"MARGINAVAIL"];
//        [simulationDataDictionary setObject:marginCloseOutData forKey:@"CLOSEOUT"];
//        [simulationDataDictionary setObject:cashFlowData forKey:@"CASHTRANSFER"];
//        [simulationDataDictionary setObject:shortIndicatorData forKey:@"SHORT"];
//        [simulationDataDictionary setObject:longIndicatorData forKey:@"LONG"];
//        positionDataSeries = [marketData newDataSeriesWithXData: dateTimesData
//                                                       AndYData: simulationDataDictionary 
//                                                  AndSampleRate: timeStep];
//        [simulation setAnalysisDataSeries:positionDataSeries];
//        [self addSimulationDataToResultsTableView:positionDataSeries];
//        [self plotSimulationData:positionDataSeries];
//        [self populateAboutPane:simulation];
//        [self initialiseSignalTableView];
//        [self setupResultsReport];
//        if(doThreads){
//            userMessage = @"Plot Prepared";
//            [self performSelectorOnMainThread:@selector(updateStatus:) withObject:userMessage waitUntilDone:NO];
//            userMessage = @"Done";
//            [self performSelectorOnMainThread:@selector(sendMessageToUserInterface:) withObject:userMessage waitUntilDone:NO];
//        }
//    }
//    
//    //NSLog(@"There were %d Signal Bias Statistics",[simulation numberOfBiasStats]);
//}
//
-(float)calculateInterestForSimulation: (Simulation *) simulation ToDateTime: (long) endDateTime
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
    float interestAccrued = 0.0;

    
    if([simulation currentExposure] !=0)
    {
        accBaseCode = [NSString stringWithFormat:@"%@%@",[simulation accCode],[simulation baseCode]];
        accQuoteCode = [NSString stringWithFormat:@"%@%@",[simulation accCode],[simulation quoteCode]];
        
        accBaseAskPrice = [marketData valueFromDataBaseForFxPair:accBaseCode 
                                                       AndDateTime:endDateTime 
                                                          AndField:@"ASK"];                                         
        
        accQuoteAskPrice = [marketData valueFromDataBaseForFxPair:accQuoteCode 
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
        float positionEntryPrice;
        int positionSize;
        float interestRate;
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
                        interestAccrued = interestAccrued - ((positionSize * interestRate)*((float)(interestRateEnd-interestUpToDateDateTime)/(365*24*60*60))/[accBaseAskPrice value]); 
                    }else{
                        interestAccrued = interestAccrued + ((positionSize * positionEntryPrice * interestRate)*((float)(interestRateEnd-interestUpToDateDateTime)/(365*24*60*60))) /[accQuoteAskPrice value];
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
                        interestAccrued = interestAccrued + ((positionSize * positionEntryPrice * interestRate)*((float)(interestRateEnd-interestUpToDateDateTime)/(365*24*60*60))/[accQuoteAskPrice value]); 
                    }else{
                        interestAccrued = interestAccrued - ((positionSize *  interestRate)*((float)(interestRateEnd-interestUpToDateDateTime)/(365*24*60*60))) / [accBaseAskPrice value];
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

-(float) setExposureToUnits:(int) exposureAmount 
                AtTimeDate:(long) currentDateTime
             ForSimulation: (Simulation *) simulation
             AndSignalIndex: (int) signalIndex
{
    int currentExposure = [simulation currentExposure];
    int exposureAdjustment = exposureAmount-currentExposure;
    int tradeIndex;
    double tradePrice;
    BOOL success;
    float interestAccrued = 0.0;
    float realisedPnl = 0.0;
    
    NSString *accQuoteCode, *baseQuoteCode;
    DataSeriesValue *accQuoteBidPrice, *accQuoteAskPrice;
    DataSeriesValue *baseQuoteBidPrice, *baseQuoteAskPrice;
    
    //First make sure interest calculations are up-to-date
    interestAccrued = [self calculateInterestForSimulation:simulation 
                           ToDateTime:currentDateTime];
    
    
    accQuoteCode = [NSString stringWithFormat:@"%@%@",[simulation accCode],[simulation quoteCode]];
    
    baseQuoteCode = [NSString stringWithFormat:@"%@%@",[simulation baseCode],[simulation quoteCode]]; 
    
    
    accQuoteBidPrice = [marketData valueFromDataBaseForFxPair:accQuoteCode 
                                                 AndDateTime:currentDateTime 
                                                    AndField:@"BID"];
    accQuoteAskPrice = [marketData valueFromDataBaseForFxPair:accQuoteCode 
                                                 AndDateTime:currentDateTime 
                                                    AndField:@"ASK"];
    
    baseQuoteBidPrice = [marketData valueFromDataBaseForFxPair:baseQuoteCode 
                                                   AndDateTime:currentDateTime 
                                                      AndField:@"BID"];
    
    baseQuoteAskPrice = [marketData valueFromDataBaseForFxPair:baseQuoteCode 
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
    NSDictionary *dataBaseValues = [marketData getValuesForFields: fieldNames AtDateTime:dateTime];
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
    DataSeries* simData = [currentSimulation analysisDataSeries]; 
    allOk = [simData writeDataSeriesToFile:urlOfFile];
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
    }
    
}

-(void) clearUserInterfaceMessages
{
    if([[self delegate] respondsToSelector:@selector(clearSimulationMessage)])
    {
        [[self delegate] clearSimulationMessage]; 
    }
   
}

-(void) sendMessageToUserInterface:(NSString *) message
{
    if([[self delegate] respondsToSelector:@selector(outputSimulationMessage:)])
    {
        [[self delegate] outputSimulationMessage:message]; 
    }
        
   // -(void)clearSimulationMessage;
}

-(void) readingDatabaseOn
{
    if([[self delegate] respondsToSelector:@selector(gettingDataIndicatorSwitchOn)])
    {
        [[self delegate] gettingDataIndicatorSwitchOn]; 
    }
   
}
-(void) readingDatabaseOff
{
    if([[self delegate] respondsToSelector:@selector(gettingDataIndicatorSwitchOff)])
    {
        [[self delegate] gettingDataIndicatorSwitchOff]; 
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

-(void) incrementProgressBy:(NSNumber *) increment{
    if([[self delegate] respondsToSelector:@selector(incrementProgressBarBy:)])
    {
        [[self delegate] incrementProgressBarBy:increment]; 
    }else{
        NSLog(@"Delegate not responding to \'incrementProgressBarBy\'"); 
    }
}

-(void) simulationEnded{
    if([[self delegate] respondsToSelector:@selector(simulationEnded)])
    {
        [[self delegate] simulationEnded]; 
    }else{
        NSLog(@"Delegate not responding to \'simulationEnded\'"); 
    }
}

-(void) setProgressRangeWithMinAndMax: (NSArray *) minAndMax
{
    if([[self delegate] respondsToSelector:@selector(setProgressMinAndMax:)])
    {
        [[self delegate] setProgressMinAndMax:minAndMax]; 
    }else{
        NSLog(@"Delegate not responding to \'setProgressMinAndMax\'"); 
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

@end
