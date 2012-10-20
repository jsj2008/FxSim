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
#import "PositioningSystem.h"
#import "SignalSystem.h"
#import "RulesSystem.h"
#import "BasicParameters.h"

#define DAY_SECONDS 24*60*60

@interface SimulationController()
- (void) tradingSimulation:(NSDictionary *) parameters;
- (double) setExposureToUnits:(int) exposureAmount
                   AtTimeDate:(long) currentDateTime
                ForSimulation: (Simulation *) simulation
              ForSignalAtTime: (long) timeOfSignal;
- (double) calculateInterestForSimulation: (Simulation *) simulation 
                               ToDateTime: (long) endDateTime;
- (double) getPrice:(PriceType) priceType 
             AtTime:(long) dateTime 
        WithSuccess:(BOOL *) success;
- (NSArray *) getInterestRateDataFor:(NSString *) baseCode 
                                 And: (NSString *) quoteCode;
- (int) getRequiredExposureForSimulation: (Simulation *) simulation
                                  AtTime: (long) currentDateTime
                                 WithNav: (double) nav;
- (BOOL) checkSignalAndAdjustPositionAtTime: (long) simulationDateTime 
                              ForSimulation: (Simulation *) simulation doCloseout: (BOOL) doCloseOut;


- (void) summariseSimulation: (Simulation *) simulation;
- (void) registerSimulation: (Simulation *) sim;
- (void) clearUserInterfaceMessages;
- (void) outputSimulationMessage:(NSString *) message;
- (void) analyseSimulation: (Simulation *) simulation;
- (void) progressBarOn;
- (void) progressBarOff;
- (void) progressAsFraction:(NSNumber *) progressValue;
- (void) readingRecordSetsProgress: (NSNumber *) progressFraction;

@end

@implementation SimulationController

#pragma mark -
#pragma mark Setup Methods 

-(id)init
{
    self = [super init];
    if(self){
        simDataController = [[DataController alloc] init];
        [simDataController setDelegate:self];
        interestRates = [[NSMutableDictionary alloc] init];
        _doThreads = NO;
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
    return _doThreads;
}

- (void) setDoThreads:(BOOL)doThreadedProcedures
{
    _doThreads = doThreadedProcedures;
    [simDataController setDoThreads:doThreadedProcedures];
}

#pragma mark -
#pragma mark General Methods

+(BOOL)positioningUnderstood:(NSString *) positioningString
{
    return [PositioningSystem basicCheck:positioningString];
}

+(BOOL)signalingUnderstood:(NSString *) signalString
{
    return [SignalSystem basicCheck:signalString];
}

+(BOOL)rulesUnderstood:(NSString *) rulesString
{
    return [RulesSystem basicCheck:rulesString];
}


-(void)askSimulationToCancel
{
    [self setCancelProcedure:YES];
}

-(void)tradingSimulation:(NSDictionary *) parameters
{
    
    NSString *tradingPair;
    Simulation *newSimulation;
    long minDateTime, maxDateTime;
    //BOOL accountCurrencyIsQuoteCurrency = NO;
    NSArray *userData;
    NSString *userDataFilename;
    int tradingDayStartHour; 
    int tradingDayEndHour;
    int tradingDayStartMinute; 
    int tradingDayEndMinute; 
    NSString *userMessage;
    int tradingDayStartSeconds;
    int tradingDayEndSeconds;
    long dataRequestMinDateTime, dataRequestMaxDateTime;
    int dataRequestTruncatedFlag = 1;
    BOOL allOk = YES;
    
    long leadTimeRequiredForPositioning;
    long leadTimeRequiredForSignal;
    long leadTicsRequiredForPositioning;
    long leadTicsRequiredForSignal;
    long leadTimeRequired;
    long leadTicsRequired;
    
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
    NSString *rulesString = [parameters objectForKey:@"RULES"];
    long tradingDayStart = [[parameters objectForKey:@"TRADINGDAYSTART"] longValue];
    long tradingDayEnd = [[parameters objectForKey:@"TRADINGDAYEND"] longValue];
    BOOL weekendTrading =   [[parameters objectForKey:@"WEEKENDTRADING"] boolValue];
    BOOL userDataGiven =  [[parameters objectForKey:@"USERDATAGIVEN"] boolValue];
    NSArray *extraRequiredVariables;

    SignalSystem *newSigSystem;
    PositioningSystem *newPosSystem;
    
    if(!cancelProcedure){
        if(userDataGiven){
            userData = [parameters objectForKey:@"USERDATA"];
            userDataFilename = [parameters objectForKey:@"USERDATAFILE"];
            [simDataController setData:userData 
                              FromFile:userDataFilename];
        }
        
//        if([accCode isEqualToString:quoteCode]){
//            accountCurrencyIsQuoteCurrency = YES;
//        }
        
        tradingDayStartHour = tradingDayStart/(60*60) ; 
        tradingDayEndHour = tradingDayEnd/(60*60) ;
        tradingDayStartMinute = (tradingDayStart-(tradingDayStartHour*60*60))%60; 
        tradingDayEndMinute = (tradingDayEnd-(tradingDayEndHour*60*60))%60; 
        
        tradingPair = [NSString stringWithFormat:@"%@%@",baseCode,quoteCode];
        
        minDateTime = [simDataController getMinDataDateTimeForPair:tradingPair];
        maxDateTime = [simDataController getMaxDataDateTimeForPair:tradingPair];
        
        leadTimeRequiredForSignal = [simDataController leadTimeRequired:simDescription];
        initialDataBeforeStart = MAX(initialDataBeforeStart,leadTimeRequiredForSignal);
        
        if(startDateTime < (minDateTime + initialDataBeforeStart))
        {
            startDateTime =  minDateTime + initialDataBeforeStart;
        }
        startDateTime = [EpochTime epochTimeAtZeroHour:startDateTime] + timeStep  * ((startDateTime-[EpochTime epochTimeAtZeroHour:startDateTime])/timeStep);
        startDateTime = startDateTime + timeStep;
        
        [self clearUserInterfaceMessages];
        userMessage = [NSString stringWithFormat:@"Starting %@\n",simName];
        [[[newSimulation simulationRunOutput] mutableString] appendString:userMessage];
        if([self doThreads]){
            [self performSelectorOnMainThread:@selector(outputSimulationMessage:) 
                                   withObject:userMessage waitUntilDone:NO];
        }
        
        // Set up the simulation data object
        tradingDayStartSeconds = (tradingDayStartMinute*60) + (tradingDayStartHour * 60 * 60);
        tradingDayEndSeconds = (tradingDayEndMinute*60) + (tradingDayEndHour * 60 * 60);
        
        newSimulation = [[Simulation alloc] initWithName:simName 
                                                AndStartDate:startDateTime 
                                                  AndEndDate:endDateTime 
                                                  AndBalance:startingBalance 
                                                 AndCurrency:accCode 
                                              AndTradingPair:tradingPair 
                                              AndMaxLeverage:maxLeverage 
                                             AndSamplingRate:timeStep 
                                               AndTradingLag:tradingLag 
                                         AndTradingTimeStart:tradingDayStartSeconds
                                           AndTradingTimeEnd:tradingDayEndSeconds];
        
        if(userData){
            [newSimulation setUserAddedData:userDataFilename];
        }
        
        newSigSystem = [[SignalSystem alloc] initWithString:simDescription];
        [newSimulation setSignalSystem: newSigSystem];
        newPosSystem = [[PositioningSystem alloc] initWithString:positioningString]; 
        [newSimulation setPositionSystem:newPosSystem];
        
        BOOL rulesAdded = YES;
        if([rulesString length] > 0){
            rulesAdded = [newSimulation addTradingRules:rulesString];
            if(!rulesAdded){
                userMessage = @"***Problem setting up rules***";
                if([self doThreads]){
                    [self performSelectorOnMainThread:@selector(updateStatus:) 
                                           withObject:userMessage 
                                        waitUntilDone:NO];
                }
                cancelProcedure = YES;
            }
        }
    }
    
    if(!cancelProcedure){
//        [allSimulations setObject: newSimulation 
//                           forKey: simName];
        
        //Getting Interest Rate Data
        userMessage = @"Getting Interest Rate data";
        if([self doThreads]){
            [self performSelectorOnMainThread:@selector(updateStatus:) withObject:userMessage waitUntilDone:NO];
            [self performSelectorOnMainThread:@selector(readingDatabaseOn) withObject:nil waitUntilDone:NO]; 
        }
        
        NSArray *interestRateSeries;
        
        interestRateSeries = [self getInterestRateDataFor:baseCode 
                                                      And:quoteCode];
        
        if([self doThreads]){
            [self performSelectorOnMainThread:@selector(readingDatabaseOff) withObject:nil waitUntilDone:NO]; 
        }
    }
    
    leadTicsRequiredForSignal = [simDataController leadTimeRequired:simDescription];
    leadTimeRequiredForPositioning = [[newSimulation positionSystem] leadTimeRequired];
    leadTicsRequiredForPositioning = [[newSimulation positionSystem] leadTicsRequired];
    
    leadTimeRequired = MAX(leadTimeRequiredForPositioning,leadTimeRequiredForSignal);
    leadTicsRequired = MAX(leadTicsRequiredForPositioning,leadTicsRequiredForSignal);
        
    //Getting the initial data
    long simulationDateTime;
    simulationDateTime = startDateTime;
        
    if(!cancelProcedure){
        userMessage = @"Setting up initial data";
        if([self doThreads]){
            [self performSelectorOnMainThread:@selector(updateStatus:) 
                                   withObject:userMessage 
                                waitUntilDone:NO];
            [self performSelectorOnMainThread:@selector(readingDatabaseOn) 
                                   withObject:nil 
                                waitUntilDone:NO]; 
        }
        
        extraRequiredVariables =  [SimulationController getNamesOfRequiredVariablesForSignal:[newSimulation signalSystem]                                                       
                                                                              AndPositioning:[newSimulation positionSystem] 
                                                                                    AndRules:[newSimulation rulesSystem]];
        
        dataRequestMinDateTime = startDateTime - initialDataBeforeStart;
        dataRequestMaxDateTime = endDateTime;
        
        [newSimulation setDataStartDateTime:dataRequestMinDateTime];
        allOk = [simDataController setupDataSeriesForName:tradingPair];
        if(!allOk){
            userMessage = @"***Problem setting up database***";
            if([self doThreads]){
                [self performSelectorOnMainThread:@selector(updateStatus:) 
                                       withObject:userMessage 
                                    waitUntilDone:NO];
            }
            cancelProcedure = YES;
        }
        allOk = [simDataController getMoreDataForStartDateTime: dataRequestMinDateTime
                                                AndEndDateTime: dataRequestMaxDateTime
                                             AndExtraVariables: extraRequiredVariables
                                               AndSignalSystem: [newSimulation signalSystem]
                                        AndReturningStatsArray: nil
                                         IncludePrecedingTicks: leadTicsRequired
                                      WithRequestTruncatedFlag: &dataRequestTruncatedFlag];
        userMessage = @"Data set up";
        if([self doThreads]){
            [self performSelectorOnMainThread:@selector(updateStatus:) 
                                   withObject:userMessage 
                                waitUntilDone:NO];
            [self performSelectorOnMainThread:@selector(readingDatabaseOff) 
                                   withObject:nil 
                                waitUntilDone:NO]; 
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
        fieldNames = [simDataController getFieldNames];
        long numberOfSimulationSteps = (endDateTime-startDateTime)/timeStep;
  
        dateTimesData = [[NSMutableData alloc] initWithLength:numberOfSimulationSteps * sizeof(long)]; 
        simDateTimes = [dateTimesData mutableBytes];
        
        simulationDataDictionary = [[NSMutableDictionary alloc] initWithCapacity:[fieldNames count]];
        simulationDataArrays = [[NSMutableData alloc] initWithLength:[fieldNames count] * sizeof(double*)];
        simulationData = (double **)[simulationDataArrays mutableBytes];
        for(fieldIndex = 0; fieldIndex < [fieldNames count]; fieldIndex++){
            [simulationDataDictionary setObject:[[NSMutableData alloc] initWithLength:numberOfSimulationSteps * sizeof(double)] 
                                         forKey:[fieldNames objectAtIndex:fieldIndex]];
            simulationData[fieldIndex] = [[simulationDataDictionary objectForKey:[fieldNames objectAtIndex:fieldIndex]] mutableBytes];
        }
    }

    //****ACTUAL START OF THE SIMULATION****//
    if([self doThreads] && !cancelProcedure){
        userMessage = @"Simulation Loop";
        [self performSelectorOnMainThread:@selector(updateStatus:) withObject:userMessage waitUntilDone:NO];
        [self performSelectorOnMainThread:@selector(progressBarOn) withObject:nil waitUntilDone:NO];
    }
    
    BOOL isTradingTime;
    BOOL doCloseOut = NO;
    int simStepIndex = 0;
    //signalIndex = 0;
    long timeOfDayInSeconds;
    NSDictionary *values;

    simulationDateTime = startDateTime;
    cashPosition = startingBalance;
    //nav = startingBalance;

    if(!cancelProcedure){        
        do{
            // 
            //BOOL isNewTradeSignal = NO;
            BOOL tradingDay;
            //int signalIndex = -1;
            //BOOL signalCausesTrade;
            
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
                    isTradingTime = YES;
            }else{
                isTradingTime = NO;
            }
            isTradingTime = isTradingTime && tradingDay;
            
            if(simulationDateTime == 1281466800){
                NSLog(@"STOP");
            }
            
            // First make sure the data is ok
            //If the current date is greater than the last day of data we need to move the data forward
            if(simulationDateTime + tradingLag > [simDataController getMaxDateTimeForLoadedData] )
            {
                dataRequestMinDateTime = MIN(simulationDateTime-leadTimeRequired,[simDataController getMaxDateTimeForLoadedData]);
                if((simulationDateTime) > endDateTime){
                    dataRequestMaxDateTime = simulationDateTime + 3*DAY_SECONDS + tradingLag;
                }else{
                    dataRequestMaxDateTime = endDateTime + 3*DAY_SECONDS  + tradingLag;
                }          
                if([self doThreads]){
                    [self performSelectorOnMainThread:@selector(updateStatus:) withObject:userMessage waitUntilDone:NO];
                    [self performSelectorOnMainThread:@selector(readingDatabaseOn) withObject:nil waitUntilDone:NO]; 
                }
                
                [simDataController getMoreDataForStartDateTime: dataRequestMinDateTime
                                                AndEndDateTime: dataRequestMaxDateTime
                                             AndExtraVariables: extraRequiredVariables
                                               AndSignalSystem: [newSimulation signalSystem]
                                        AndReturningStatsArray: nil 
                                         IncludePrecedingTicks: leadTicsRequired
                                      WithRequestTruncatedFlag: &dataRequestTruncatedFlag];
                
                
                
                if(dataRequestTruncatedFlag == 0){
                    endDateTime = MIN(endDateTime,[simDataController getMaxDateTimeForLoadedData]);
                }   
                if([self doThreads]){
                    [self performSelectorOnMainThread:@selector(readingDatabaseOff) withObject:nil waitUntilDone:NO];
                }
            }
            
            //Check we successfully have data for the required date 
            if(simulationDateTime > [simDataController getMaxDateTimeForLoadedData]){
                [NSException raise:@"DataSeries does not cover current date" format:@"Max: %ld current %ld",[simDataController getMaxDateTimeForLoadedData],simulationDateTime];
            }
            
            values = [simDataController getValues: fieldNames 
                                       AtDateTime:simulationDateTime ];
            
            if(![[values objectForKey:@"SUCCESS"] boolValue])
            {
                userMessage = @"Data Problem, Stopping....";
                [NSException raise: @"Data Problem in getValuesForFields" format:@"datetime %ld",simulationDateTime];
            }
            simDateTimes[simStepIndex] = [[values objectForKey:@"DATETIME"] longValue];
            for(fieldIndex=0;fieldIndex<[fieldNames count];fieldIndex++){
                simulationData[fieldIndex][simStepIndex] = [[values objectForKey:[fieldNames objectAtIndex:fieldIndex]] doubleValue];
            }

            
            if(simulationDateTime+timeStep > endDateTime)
            {
                doCloseOut = YES;
            }
            
            if(isTradingTime || doCloseOut){
                doCloseOut = ![self checkSignalAndAdjustPositionAtTime:simulationDateTime 
                                                         ForSimulation:newSimulation 
                                                            doCloseout:doCloseOut];
            }
            
            simulationDateTime= simulationDateTime+timeStep;
            simStepIndex++;
            //NSLog(@"%@ CASH:%f NAV:%f",[EpochTime stringDateWithTime:simulationDateTime], cashPosition, nav);
            if([self doThreads]){
                [self performSelectorOnMainThread:@selector(progressAsFraction:) 
                                       withObject:[NSNumber numberWithDouble:(double)(simulationDateTime - startDateTime)/(endDateTime - startDateTime) ] waitUntilDone:NO];
            }
        }while((simulationDateTime <= endDateTime)   && allOk && !cancelProcedure);
    }
     
    if(!cancelProcedure){
        //currentDateAsString = [EpochTime stringDateWithTime:simulationDateTime]; 
        userMessage = @"Finished Simulation - Starting Analysis....";
        if([self doThreads]){
            [self performSelectorOnMainThread:@selector(updateStatus:) withObject:userMessage waitUntilDone:NO];
        }  
    }
    
    if([self doThreads]){
        [self performSelectorOnMainThread:@selector(progressBarOff) withObject:nil waitUntilDone:YES];
    }
    //***END OF THE SIMULATION****//
    
    if(!cancelProcedure)
    {
        DataSeries *simulationDataSeries;
        simulationDataSeries = [simDataController createNewDataSeriesWithXData: dateTimesData
                                                                      AndYData: simulationDataDictionary 
                                                                 AndSampleRate: timeStep];
        [newSimulation setSimulationDataSeries:simulationDataSeries];
        [self summariseSimulation:newSimulation];
    }

    if(!cancelProcedure)
    {
        userMessage = @"Analysing The Simulation";
        if([self doThreads]){
            [self performSelectorOnMainThread:@selector(updateStatus:) withObject:userMessage waitUntilDone:NO];
        }
        [self analyseSimulation:newSimulation];
        
    }

    if(cancelProcedure){
        userMessage = @"Simulation Cancelled \n";
        [[[newSimulation simulationRunOutput] mutableString] appendString:userMessage];
        if([self doThreads]){
            [self performSelectorOnMainThread:@selector(updateStatus:) withObject:userMessage waitUntilDone:NO];
            [self performSelectorOnMainThread:@selector(outputSimulationMessage:) withObject:userMessage waitUntilDone:NO];
        }else{
            [self updateStatus:userMessage];
            [self outputSimulationMessage:userMessage];
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
    
    NSUInteger dateCount = 0, timeStep = 0, tradeIndex, cashMoveIndex;
    double signal, currentSignal;
    long startDateTime, endDateTime, stepDateTime, nextTradeDateTime;
    BOOL allTradesFinished, allCashMovesFinished;
    int dataRequestTruncated = 1;
    NSArray *extraRequiredVariables; 
    
    long signalStartDateTime, signalEndDateTime, nextCashMoveDateTime;
    double nextCashMoveAmount, allCashTransfers = 0.0;
    NSString *nextCashMoveReason;
    NSDictionary *tradeDetails;
    NSDictionary *cashMoveDetails;
    BOOL accountCurrencyIsQuoteCurrency;
    NSMutableArray *positionDateTime = [[NSMutableArray alloc] init];
    NSMutableArray *positionAmount = [[NSMutableArray alloc] init];
    NSMutableArray *positionOriginalAmount = [[NSMutableArray alloc] init];
    NSMutableArray *positionPrice = [[NSMutableArray alloc] init];
    NSMutableArray *positionAveClosePrice = [[NSMutableArray alloc] init];
    
    int currentPosition, currentPositionSign, nextTradeAmount;
    double wgtPositionClosePrice;
    int exposureAfterTrade;
    long currentDateTime;
    double currentBid = 0.0,currentAsk = 0.0;
    double nextTradePrice, currentCashBalance, tradePnl, interestCosts;
    double largestDrawdown;
    long largestDrawdownDateTime;
    double currentMaximumNav, spreadCost= 0.0;
    NSUInteger arraySize;
    long dataRequestMinDateTime, dataRequestMaxDateTime;
    
    
    userMessage = @"Performing Analysis of Simulation\n";
    [[[simulation simulationRunOutput] mutableString] appendString:userMessage];
    if([self doThreads]){
        [self performSelectorOnMainThread:@selector(outputSimulationMessage:) withObject:userMessage waitUntilDone:NO];
    }
    
    simulationDataSeries = [simulation simulationDataSeries];
    simDataFieldNames = [simulationDataSeries getFieldNames];
    
    startDateTime = [[simulation basicParameters] startDate];
    endDateTime = [[simulation basicParameters] endDate];
    timeStep = [[simulation basicParameters] samplingRate];
    
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
            extraRequiredVariables = [SimulationController getNamesOfRequiredVariablesForSignal: [simulation signalSystem]
                                                                                 AndPositioning: [simulation positionSystem] 
                                                                                       AndRules: [simulation rulesSystem]];
            
            if([self doThreads]){
                [self performSelectorOnMainThread:@selector(readingDatabaseOn) withObject:nil waitUntilDone:NO]; 
            }
            
            if(![simDataController getMoreDataForStartDateTime: dataRequestMinDateTime
                                                AndEndDateTime: dataRequestMaxDateTime
                                             AndExtraVariables: extraRequiredVariables
                                               AndSignalSystem: [simulation signalSystem]
                                        AndReturningStatsArray: nil
                                         IncludePrecedingTicks: 0
                                      WithRequestTruncatedFlag: &dataRequestTruncated]){
                [NSException raise:@"Database problem" 
                            format:nil];
            }
            
            if([self doThreads]){
                [self performSelectorOnMainThread:@selector(readingDatabaseOff) withObject:nil waitUntilDone:NO];
            }
        }
        
        dateCount = 0;
        currentPosition = 0;
        currentPositionSign = 0;
        currentCashBalance = 0.0;
        currentMaximumNav = 0.0;
        
        if([[[simulation basicParameters] accCode] isEqualToString:[[simulation basicParameters] quoteCode]]){
            accountCurrencyIsQuoteCurrency = YES;
        }else{
            accountCurrencyIsQuoteCurrency = NO;
        }
        
        // Get the first signal
        //signalIndex = 0;
        //signalDetails = [simulation detailsOfSignalAtIndex:signalIndex];
        //signalStartDateTime = [[signalDetails objectForKey:@"ENTRYTIME"] longValue];
        //signalEndDateTime = [[signalDetails objectForKey:@"EXITTIME"] longValue];
        //signal = [[signalDetails objectForKey:@"SIGNAL"] doubleValue];
        
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
        exposureAfterTrade = [[tradeDetails objectForKey:@"ENDEXP"] doubleValue];
        
        signalStartDateTime = [[tradeDetails objectForKey:@"SIGDATETIME"] longValue];
        tradeDetails = [simulation detailsOfTradeAtIndex:tradeIndex+1];
        signalEndDateTime = [[tradeDetails objectForKey:@"SIGDATETIME"] longValue];
        signal = exposureAfterTrade < 0 ? -1 : 1;
        
        tradePnl = 0.0;
        interestCosts = 0.0;
        largestDrawdown = 0.0;
        
        // Main loop
        [self performSelectorOnMainThread:@selector(progressBarOn) withObject:nil waitUntilDone:NO];
        
        for(int dateIndex = 0; dateIndex < [dateTimesOfAnalysis count]; dateIndex++)
        {
            currentDateTime = [[dateTimesOfAnalysis objectAtIndex:dateIndex] longValue];
            //            if(currentDateTime==1075808400){
            //                NSLog(@"STOP");
            //            }
            // Update the database if needed
            if(currentDateTime > [simDataController getMaxDateTimeForLoadedData])
            {
                if([self doThreads]){
                    [self performSelectorOnMainThread:@selector(readingDatabaseOn) withObject:nil waitUntilDone:NO]; 
                }
                dataRequestMinDateTime = [simDataController getMaxDateTimeForLoadedData];
                dataRequestMaxDateTime = MAX(currentDateTime,endDateTime);
                [simDataController getMoreDataForStartDateTime: dataRequestMinDateTime
                                                AndEndDateTime: dataRequestMaxDateTime
                                             AndExtraVariables: extraRequiredVariables
                                               AndSignalSystem: [simulation signalSystem]
                                        AndReturningStatsArray: nil
                                         IncludePrecedingTicks: 0
                                      WithRequestTruncatedFlag: &dataRequestTruncated];
                if([self doThreads]){
                    [self performSelectorOnMainThread:@selector(readingDatabaseOff) 
                                           withObject:nil 
                                        waitUntilDone:NO];
                }   
            }
            
            // Get the price data values for today
            currentDataValues = [simDataController getValues:simDataFieldNames 
                                                  AtDateTime:currentDateTime];
            
            for(int fieldIndex = 0; fieldIndex < [simDataFieldNames count]; fieldIndex++){
                simulationDataArray[fieldIndex][dateIndex] = [[currentDataValues objectForKey:[simDataFieldNames objectAtIndex:fieldIndex]] doubleValue];
            }
            
            currentBid = [[currentDataValues objectForKey:@"BID"] doubleValue];
            currentAsk = [[currentDataValues objectForKey:@"ASK"] doubleValue];
            
            //Add in the trades and any cash moves 
            if(currentDateTime == nextTradeDateTime){
                if([UtilityFunctions signOfInt:currentPosition] != [UtilityFunctions signOfInt:currentPosition + nextTradeAmount]){
                    NSLog(@"Trading from %d to %d",currentPosition, currentPosition + nextTradeAmount);
                }
                
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
                    [positionOriginalAmount addObject:[NSNumber numberWithInt:nextTradeAmount]];
                    [positionPrice addObject:[NSNumber numberWithDouble:nextTradePrice]];
                    [positionAveClosePrice addObject:[NSNumber numberWithDouble:0.0]];
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
                        int positionIndex = 0;
                        int openPositionAmount = 0;
                        while((positionIndex < [positionDateTime count]) && (remainingTrade != 0)){
                            openPositionAmount = [[positionAmount objectAtIndex:positionIndex] intValue];
                            if(ABS(openPositionAmount) > ABS(remainingTrade)){
                                [positionAmount replaceObjectAtIndex:positionIndex withObject:[NSNumber numberWithInt:openPositionAmount + remainingTrade]];
                                wgtPositionClosePrice = [[positionAveClosePrice objectAtIndex:positionIndex] doubleValue] + ABS(remainingTrade) * nextTradePrice;
                                remainingTrade = 0;
                            }else{
                                wgtPositionClosePrice = [[positionAveClosePrice objectAtIndex:positionIndex] doubleValue] + ABS(openPositionAmount) * nextTradePrice;
                                remainingTrade = remainingTrade + openPositionAmount;
                                numberOfTradesToRemove++;
                            }
                            [positionAveClosePrice replaceObjectAtIndex:positionIndex withObject:[NSNumber numberWithDouble:wgtPositionClosePrice]];
                            positionIndex++;
                        }
                        if(remainingTrade != 0){
                            [positionDateTime addObject:[NSNumber numberWithLong:nextTradeDateTime]]; 
                            [positionAmount addObject:[NSNumber numberWithInt:remainingTrade]];
                            [positionPrice addObject:[NSNumber numberWithDouble:nextTradePrice]];
                            [positionOriginalAmount addObject:[NSNumber numberWithInt:remainingTrade]];
                            [positionAveClosePrice addObject:[NSNumber numberWithDouble:0.0]];
                            if(accountCurrencyIsQuoteCurrency){
                                spreadCost = spreadCost + (ABS(remainingTrade) * (currentBid - currentAsk));
                            }else{
                                spreadCost = spreadCost + (ABS(remainingTrade) * (currentBid - currentAsk)/currentBid);
                            }
                            remainingTrade = 0;
                        }   
                        
                    }
                    // Remove any trades which have been fully closed out 
                    if(numberOfTradesToRemove > 0){
                        for(int i = 0;i < numberOfTradesToRemove; i++){
                            [simulation  addSignalStatisticsWithSignal:[UtilityFunctions signOfInt:[[positionOriginalAmount objectAtIndex:0] intValue]] 
                                                          AndEntryTime:[[positionDateTime objectAtIndex:0] longValue] 
                                                           AndExitTime:currentDateTime 
                                                         AndEntryPrice:[[positionPrice objectAtIndex:0] doubleValue]
                                                          AndExitPrice:[[positionAveClosePrice objectAtIndex:0] doubleValue]/ABS([[positionOriginalAmount objectAtIndex:0] intValue])];
                            
                            [positionDateTime removeObjectAtIndex:0];
                            [positionAmount removeObjectAtIndex:0];
                            [positionPrice removeObjectAtIndex:0];
                            [positionOriginalAmount removeObjectAtIndex:0];
                            [positionAveClosePrice removeObjectAtIndex:0];
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
                    exposureAfterTrade = [[tradeDetails objectForKey:@"ENDEXP"] doubleValue];
                    
                    signalStartDateTime = [[tradeDetails objectForKey:@"SIGDATETIME"] longValue];
                    if(tradeIndex < [simulation numberOfTrades]-1){
                        NSDictionary *lookAheadTradeDetails = [simulation detailsOfTradeAtIndex:tradeIndex+1];
                        signalEndDateTime = [[lookAheadTradeDetails objectForKey:@"SIGDATETIME"] longValue];
                    }else{
                        signalEndDateTime = endDateTime;
                    }
                    signal = exposureAfterTrade < 0 ? -1 : 1;
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
            //            while((signalEndDateTime <= currentDateTime) && (signalIndex < ([simulation numberOfSignals]-1))){
            //                signalIndex++;
            //                signalDetails = [simulation detailsOfSignalAtIndex:signalIndex];
            //                signalStartDateTime = [[signalDetails objectForKey:@"ENTRYTIME"] longValue];
            //                signalEndDateTime = [[signalDetails objectForKey:@"EXITTIME"] longValue];
            //                signal = [[signalDetails objectForKey:@"SIGNAL"] doubleValue];
            //            }
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
            marginUsedArray[dateIndex] =  ABS(currentPosition) /[[simulation basicParameters] maxLeverage];
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
            int posUnits = 0;
            if(currentPosition > 0){
                for(int positionIndex = 0; positionIndex < [positionAmount count]; positionIndex++){
                    unrealisedPnl = unrealisedPnl + [[positionAmount objectAtIndex:positionIndex] intValue] * ((currentBid -[[positionPrice objectAtIndex:positionIndex] doubleValue]));
                    
                    posAvePrice = posAvePrice + (double)[[positionAmount objectAtIndex:positionIndex] intValue] * [[positionPrice objectAtIndex:positionIndex] doubleValue];
                    posUnits = posUnits + [[positionAmount objectAtIndex:positionIndex] intValue];
                }
                posAvePrice = posAvePrice/posUnits;
            }
            
            if(currentPosition < 0){
                for(int positionIndex = 0; positionIndex < [positionAmount count]; positionIndex++){
                    unrealisedPnl = unrealisedPnl + [[positionAmount objectAtIndex:positionIndex] intValue] * ((currentAsk -[[positionPrice objectAtIndex:positionIndex] doubleValue]));
                    
                    posAvePrice = posAvePrice + (double)[[positionAmount objectAtIndex:positionIndex] intValue] * [[positionPrice objectAtIndex:positionIndex] doubleValue];
                    posUnits = posUnits + [[positionAmount objectAtIndex:positionIndex] intValue];
                }
                posAvePrice = posAvePrice/posUnits;
                
            }
            if(currentPosition == 0){
                if([positionAmount count] != 0){
                    NSLog(@"Check analyseSimulation %ld", currentDateTime);
                }
                positionAvePriceArray[dateIndex] = (currentBid + currentAsk)/2;
            }else{
                positionAvePriceArray[dateIndex] = posAvePrice;
            }
            
            if(currentPosition != posUnits){
                NSLog(@"Check: Current Pos: %d vs check: %d",currentPosition,posUnits);
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
            if([self doThreads]){
                [self performSelectorOnMainThread:@selector(progressAsFraction:) withObject:[NSNumber   numberWithDouble:(double) (currentDateTime-startDateTime)/(endDateTime-startDateTime)  ] waitUntilDone:NO];
            }
            int checkPosition =  0 ;
            for(int i = 0; i < [positionAmount count]; i++){
                checkPosition = checkPosition + [[positionAmount objectAtIndex:i] intValue];
            }
            if(checkPosition != currentPosition){
                NSLog(@"Check: %ld - %d - %d",currentDateTime, currentPosition, checkPosition);
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
            
            positionDataSeries = [simDataController createNewDataSeriesWithXData: dateTimesData
                                                                        AndYData: simulationDataDictionary 
                                                                   AndSampleRate: timeStep];
            
            [simulation addObjectToSimulationResults:[NSNumber numberWithDouble:navArray[[dateTimesOfAnalysis count]-1]]
                                              ForKey:@"FINALNAV"];
            [simulation addObjectToSimulationResults:[NSNumber numberWithInteger:[simulation numberOfTrades]]
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
            
//            int activityCount = [simulation numberOfBalanceAdjustments];
//            for(int i = 0; i < activityCount; i++){
//                NSDictionary *accountActivity = [simulation detailsOfBalanceAdjustmentIndex:i];
//                NSString *reason = [accountActivity objectForKey:@"REASON"];
//                NSString *dateTimeString = [EpochTime stringDateWithTime:[[accountActivity objectForKey:@"DATETIME"] longValue]];
//                double amount = [[accountActivity objectForKey:@"AMOUNT"] doubleValue];
//                double resultingBalance = [[accountActivity objectForKey:@"ENDBAL"] doubleValue]; 
//                userMessage = [NSString stringWithFormat:@"%@ %@ %5.3f %5.3f",dateTimeString,reason,amount,resultingBalance];
//                
//                if([self doThreads]){
//                    [self performSelectorOnMainThread:@selector(outputSimulationMessage:) 
//                                           withObject:userMessage waitUntilDone:NO];
//                }
//            }
        }
        
        if(!cancelProcedure)
        {
            [simulation setAnalysisDataSeries:positionDataSeries];
            [simulation setIsAnalysed:YES];
            
            [self performSelectorOnMainThread:@selector(registerSimulation:) withObject:simulation waitUntilDone:YES];
            
            
//            [self performSelectorOnMainThread:@selector(prepareForSimulationReport) withObject:nil waitUntilDone:YES];
//            [self performSelectorOnMainThread:@selector(addSimulationDataToResultsTableView:) withObject:positionDataSeries waitUntilDone:YES];
//            [self performSelectorOnMainThread:@selector(plotSimulationData:) withObject:positionDataSeries waitUntilDone:YES];
//            [self performSelectorOnMainThread:@selector(populateAboutPane:) withObject:simulation waitUntilDone:YES];
//            [self performSelectorOnMainThread:@selector(initialiseSignalTableView) withObject:nil waitUntilDone:YES];
//            [self performSelectorOnMainThread:@selector(setupResultsReport) withObject:nil waitUntilDone:YES];
            userMessage = @"Analysis Prepared";
            [[[simulation simulationRunOutput] mutableString] appendString:userMessage];
            if([self doThreads]){
                [self performSelectorOnMainThread:@selector(updateStatus:) withObject:userMessage waitUntilDone:NO];
            }
            userMessage = @"Analysis Prepared\n";
            [[[simulation simulationRunOutput] mutableString] appendString:userMessage];
            if([self doThreads]){
                [self performSelectorOnMainThread:@selector(outputSimulationMessage:) withObject:userMessage waitUntilDone:NO];
            }
        }
    }else{
        userMessage = @"There were no trades \n";
        [[[simulation simulationRunOutput] mutableString] appendString:userMessage];
        if([self doThreads]){
            [self performSelectorOnMainThread:@selector(updateStatus:) withObject:userMessage waitUntilDone:NO];
        }else{
            [self updateStatus:userMessage];
            
        }
        userMessage = @"Done \n";
        [[[simulation simulationRunOutput] mutableString] appendString:userMessage];
        if([self doThreads]){
            [self performSelectorOnMainThread:@selector(outputSimulationMessage:) withObject:userMessage waitUntilDone:NO];
        }else{
            
            [self outputSimulationMessage:userMessage];
        }  
    }
}
     
        
- (BOOL) checkSignalAndAdjustPositionAtTime: (long) simulationDateTime 
                              ForSimulation: (Simulation *) simulation 
                                 doCloseout: (BOOL) doCloseOut;
{
    double dataSignal, bid, ask;
    NSString *userMessage;
    NSDictionary *values;
    double unrealisedPnl = 0.0;
    double marginUsed = 0.0;
    BOOL accountCurrencyIsQuoteCurrency;
    double nav, debits;
    double marginAvailable = 0.0;
    int requiredPositionSize = 0;
    BOOL marginCloseOut = NO;
    
    if([[[simulation basicParameters] accCode] isEqualToString:[[simulation basicParameters] quoteCode]]){
        accountCurrencyIsQuoteCurrency = YES;
    }else{
        accountCurrencyIsQuoteCurrency = NO;
    }
    
    //fieldNames = [simData getFieldNames];
    values = [simDataController getValues: [NSArray arrayWithObjects:@"BID", @"ASK", nil] 
                               AtDateTime: simulationDateTime ];
            
    if(![[values objectForKey:@"SUCCESS"] boolValue])
    {
        userMessage = @"Data Problem, Stopping....";
        [NSException raise: @"Data Problem in getValuesForFields" format:@"datetime %ld",simulationDateTime];
    }
    
    if(doCloseOut){
        dataSignal = 0.0;
        debits = [self setExposureToUnits: requiredPositionSize 
                               AtTimeDate: simulationDateTime + [simulation tradingLag]
                            ForSimulation: simulation
                          ForSignalAtTime: simulationDateTime];
    }else{
        bid = [[values objectForKey:@"BID"] doubleValue];
        ask =  [[values objectForKey:@"ASK"] doubleValue];
        
        //This part deals with turning signal in a position
      
        // Check our margin available before we can trade
        unrealisedPnl = 0.0;
        marginUsed = 0.0;
        
        
//        if(simulationDateTime==1077177600){
//            NSLog(@"STOP");
//        }
        if([simulation currentExposure] > 0)
        {
            unrealisedPnl = [simulation currentExposure] * (bid - [simulation wgtAverageCostOfPosition]);
        }else{
            if([simulation currentExposure] < 0){
                unrealisedPnl = [simulation currentExposure] * (ask - [simulation wgtAverageCostOfPosition]);
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
            if([simulation currentExposure] > 0){
                marginUsed = fabsf([simulation currentExposure] * ask / [[simulation basicParameters] maxLeverage]);
            }else{
                marginUsed = fabsf([simulation currentExposure] * bid / [[simulation basicParameters] maxLeverage]);
            }
        }else{
            marginUsed = fabsf([simulation currentExposure] / [[simulation basicParameters] maxLeverage]);
        }
        nav = cashPosition + unrealisedPnl;
        marginAvailable = nav - marginUsed;
            
        requiredPositionSize = [self getRequiredExposureForSimulation: simulation
                                                               AtTime: simulationDateTime
                                                              WithNav: nav];
    
        if(requiredPositionSize != [simulation currentExposure]){
            int keepCurrentExposure = [simulation currentExposure];
              
            
            
            debits = [self setExposureToUnits: requiredPositionSize
                                   AtTimeDate: simulationDateTime + [simulation tradingLag]
                                ForSimulation: simulation
                              ForSignalAtTime: simulationDateTime];
            
            cashPosition = cashPosition + debits;
            debits = 0.0;
            nav = cashPosition;
            unrealisedPnl = 0.0;
            NSString *userMessage = [NSString stringWithFormat:@"%@ Trade from %d to %d %@ -- NAV: %5.2f %@ \n",[EpochTime stringDateWithTime:simulationDateTime + [simulation tradingLag]], keepCurrentExposure,requiredPositionSize, [simulation baseCode], nav,[simulation accCode]];
            [[[simulation simulationRunOutput] mutableString] appendString:userMessage];
            if([self doThreads]){
                [self performSelectorOnMainThread:@selector(outputSimulationMessage:) withObject:userMessage waitUntilDone:NO];
            }else{
                [self outputSimulationMessage:userMessage];
            }
        }else{
            unrealisedPnl = 0.0;
            if([simulation currentExposure] > 0)
            {
                unrealisedPnl = [simulation currentExposure] * (bid - [simulation wgtAverageCostOfPosition]);
            }else{
                if([simulation currentExposure] < 0){
                    unrealisedPnl = [simulation currentExposure] * (ask - [simulation wgtAverageCostOfPosition]);
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
            if([simulation currentExposure] > 0)
            {
                marginUsed = fabsf([simulation currentExposure] * ask / [[simulation basicParameters] maxLeverage]);
            }else{
                marginUsed = fabsf([simulation currentExposure] * bid / [[simulation basicParameters] maxLeverage]);
            }
        }else{
            marginUsed = fabsf([simulation currentExposure]  / [[simulation basicParameters] maxLeverage]);
        }
        
        if((marginUsed/2) >= nav){
            marginCloseOut = YES;
        }
    }        
    return !marginCloseOut;            
            
}
      
-(int)getRequiredExposureForSimulation: (Simulation *) simulation
                                AtTime:(long) currentDateTime
                               WithNav:(double) nav
{
    int requiredExposure = 0;
    PositioningSystem *posSys = [simulation positionSystem];
    NSArray *fieldNames = [simDataController getFieldNames];
    
    
    if([[posSys type] isEqualToString:@"STP"]){
        NSDictionary *values = [simDataController getValues: fieldNames 
                                                 AtDateTime:currentDateTime ];
        double mid, bid, ask, dataSignal, adjustedThreshold;
        int targetAbsolutePositionSize;
        BOOL accountCurrencyIsQuoteCurrency;
        mid = [[values objectForKey:@"MID"] doubleValue];
        bid = [[values objectForKey:@"BID"] doubleValue];
        ask =  [[values objectForKey:@"ASK"] doubleValue];
        dataSignal = [[values objectForKey:@"SIGNAL"] doubleValue]; 
        adjustedThreshold = [posSys signalThreshold] * [[simDataController dataSeries] pipSize];
        
        //Get a handle on an target position size 
        if([[[simulation basicParameters] accCode] isEqualToString:[[simulation basicParameters] quoteCode]]){
            accountCurrencyIsQuoteCurrency = YES;
        }else{
            accountCurrencyIsQuoteCurrency = NO;
        }
       
        if(accountCurrencyIsQuoteCurrency){ 
            targetAbsolutePositionSize =  (int)floor((1-[posSys positionCushion]) * nav/ask * [[simulation basicParameters] maxLeverage]);
        }else{
            targetAbsolutePositionSize =  (int)floor((1-[posSys positionCushion]) * nav * [[simulation basicParameters] maxLeverage]);
        }
    
        if( dataSignal > adjustedThreshold){
            if([simulation currentExposure] <= 0){
                requiredExposure = targetAbsolutePositionSize;
            }else{
                requiredExposure = [simulation currentExposure];
            }
        }
        
        if(dataSignal < -adjustedThreshold){  
            if([simulation currentExposure] >= 0){
                requiredExposure = -targetAbsolutePositionSize;
            }else{
                requiredExposure = [simulation currentExposure];
                
            }
        }   
            
        if(fabs(dataSignal) <= adjustedThreshold){
            requiredExposure = 0;
        }
    }
    
    if([[posSys type] isEqualToString:@"SFP"]){
        double adjustedThreshold = [posSys signalThreshold] * [[simDataController dataSeries] pipSize];;
        double stepProportion = [posSys stepProportion];
        NSString *stepUnit =   [posSys stepUnit];
        int perfSmoothParam = [posSys perfSmoothParam];
        long smoothLength = 0, dateOffset = 0;
        
        if([stepUnit isEqualToString:@"P"]){
            smoothLength = (long)[UtilityFunctions fib:perfSmoothParam]/[posSys stepLength];
        }
        if([stepUnit isEqualToString:@"S"] || [stepUnit isEqualToString:@"M"] || [stepUnit isEqualToString:@"H"] || [stepUnit isEqualToString:@"D"]){
            dateOffset = [posSys leadTimeRequired];
        } 
        
        
        NSString *signalPerfField = [NSString stringWithFormat:@"EMA%d",perfSmoothParam];
        
        
        NSDictionary *values = [simDataController getValues: fieldNames 
                                                 AtDateTime:currentDateTime];
        double mid, bid, ask, dataSignal;
        int targetAbsolutePositionSize;
        BOOL accountCurrencyIsQuoteCurrency;
        mid = [[values objectForKey:@"MID"] doubleValue];
        bid = [[values objectForKey:@"BID"] doubleValue];
        ask =  [[values objectForKey:@"ASK"] doubleValue];
        dataSignal = [[values objectForKey:@"SIGNAL"] doubleValue]; 
        //adjustedThreshold = [posSys signalThreshold] * [[simDataController dataSeries] pipSize];
        
        
        fieldNames = [NSArray arrayWithObjects:signalPerfField, nil];
        NSDictionary *trailingValues = [simDataController getValues: fieldNames 
                                                        AtDateTime: currentDateTime - dateOffset
                                                     WithTicOffset: smoothLength]; 
        if(smoothLength != [[trailingValues objectForKey:@"TICOFFSET"] longValue]){
            NSLog(@"Check: Tic offset %ld and %ld",smoothLength,[[trailingValues objectForKey:@"TICOFFSET"] longValue]);  
        }
        
        double smoothedPerf = [[values objectForKey:signalPerfField] doubleValue] - [[trailingValues objectForKey:signalPerfField] doubleValue];
        
        if(fabs(dataSignal) >= adjustedThreshold && [UtilityFunctions signOfDouble:smoothedPerf] == [UtilityFunctions signOfDouble:dataSignal]){
            
            
            //Get a handle on an target position size 
            if([[[simulation basicParameters] accCode] isEqualToString:[[simulation basicParameters] quoteCode]]){
                accountCurrencyIsQuoteCurrency = YES;
            }else{
                accountCurrencyIsQuoteCurrency = NO;
            }
            
            if(accountCurrencyIsQuoteCurrency){ 
                targetAbsolutePositionSize =  (int)floor((1-[posSys positionCushion]) * nav/ask * [[simulation basicParameters] maxLeverage]);
            }else{
                targetAbsolutePositionSize =  (int)floor((1-[posSys positionCushion]) * nav * [[simulation basicParameters] maxLeverage]);
            }

            if(ABS([simulation currentExposure])+(targetAbsolutePositionSize*stepProportion) <= targetAbsolutePositionSize){
                targetAbsolutePositionSize = ABS([simulation currentExposure])+(targetAbsolutePositionSize*stepProportion);
            }else{
                targetAbsolutePositionSize = targetAbsolutePositionSize;
            }
                
            if( dataSignal > adjustedThreshold){
                requiredExposure = targetAbsolutePositionSize;
            }
            
            if(dataSignal < -adjustedThreshold){  
                requiredExposure = -targetAbsolutePositionSize;
            }   
        }else{
            requiredExposure = 0;
        }
    }    
    if(requiredExposure > 100000){
        NSLog(@"Check this");
    }
     
    return requiredExposure;
}



- (void) summariseSimulation: (Simulation *) simulation
{
    NSString *userMessage;
    userMessage = @"----Details---- \n";
    [[[simulation simulationRunOutput] mutableString] appendString:userMessage];
    if([self doThreads]){
        [self performSelectorOnMainThread:@selector(outputSimulationMessage:) withObject:userMessage waitUntilDone:NO];
    }
    
    NSUInteger numberOfTrades = [simulation numberOfTrades];
    userMessage = [NSString stringWithFormat:@"There were %ld transactions \n",numberOfTrades];
    [[[simulation simulationRunOutput] mutableString] appendString:userMessage];
    if([self doThreads]){
        [self performSelectorOnMainThread:@selector(outputSimulationMessage:) withObject:userMessage waitUntilDone:NO];
    }     
    
    for(int iTrade = 0; iTrade < numberOfTrades; iTrade++){
        userMessage = [simulation getTradeDetailToPrint:iTrade];
        [[[simulation simulationRunOutput] mutableString] appendString:userMessage];
        if([self doThreads]){
            [self performSelectorOnMainThread:@selector(outputSimulationMessage:) withObject:userMessage waitUntilDone:NO];
        }
    }
    int numberOfBalanceAdjustments = [simulation numberOfBalanceAdjustments];
    userMessage = [NSString stringWithFormat:@"There were %d balance Adjustments \n",numberOfBalanceAdjustments];
    [[[simulation simulationRunOutput] mutableString] appendString:userMessage];
    if([self doThreads]){
        [self performSelectorOnMainThread:@selector(outputSimulationMessage:) withObject:userMessage waitUntilDone:NO];
    }  
    
    for(int iBalAdj = 0; iBalAdj < numberOfBalanceAdjustments; iBalAdj++)
    {
        userMessage = [simulation getBalanceDetailToPrint:iBalAdj];
        [[[simulation simulationRunOutput] mutableString] appendString:userMessage];
        if([self doThreads]){
            [self performSelectorOnMainThread:@selector(outputSimulationMessage:) withObject:userMessage waitUntilDone:NO];
        }
    }
    NSDictionary *performanceAttribution;
    NSArray *perfAttribKeys;
    NSString *perfAttribMessage;
    performanceAttribution = [simulation getPerformanceAttribution];
    perfAttribKeys = [performanceAttribution allKeys];
    for(int i = 0; i < [perfAttribKeys count]; i++){
        double amount = [[performanceAttribution objectForKey:[perfAttribKeys objectAtIndex:i]] doubleValue];
        NSString *reason = [perfAttribKeys objectAtIndex:i]; 
        perfAttribMessage = [NSString stringWithFormat:@"Final balance value of: %5.2f     due to: %@ \n",amount,reason];
        [[[simulation simulationRunOutput] mutableString] appendString:perfAttribMessage];
        if([self doThreads]){
            [self performSelectorOnMainThread:@selector(outputSimulationMessage:) withObject:perfAttribMessage waitUntilDone:NO];
        }
    }
}
        
        
- (NSArray *) getInterestRateDataFor:(NSString *) baseCode And: (NSString *) quoteCode
{
    NSArray *interestRateSeries; 
    if([interestRates objectForKey:[NSString stringWithFormat:@"%@IRBID",baseCode]] == nil){
        interestRateSeries = [simDataController getAllInterestRatesForCurrency:baseCode 
                                                                      AndField:@"BID"];
        [interestRates setValue:interestRateSeries forKey:[NSString stringWithFormat:@"%@IRBID",baseCode]];
    }
    if([interestRates objectForKey:[NSString stringWithFormat:@"%@IRASK",baseCode]] == nil){
        interestRateSeries = [simDataController getAllInterestRatesForCurrency:baseCode 
                                                                      AndField:@"ASK"];
        [interestRates setValue:interestRateSeries forKey:[NSString stringWithFormat:@"%@IRASK",baseCode]];
    }    
    if([interestRates objectForKey:[NSString stringWithFormat:@"%@IRBID",quoteCode]] == nil){
        interestRateSeries = [simDataController getAllInterestRatesForCurrency:quoteCode 
                                                                      AndField:@"BID"];
        [interestRates setValue:interestRateSeries forKey:[NSString stringWithFormat:@"%@IRBID",quoteCode]];
    }
    if([interestRates objectForKey:[NSString stringWithFormat:@"%@IRASK",quoteCode]] == nil){
        interestRateSeries = [simDataController getAllInterestRatesForCurrency:quoteCode 
                                                                      AndField:@"ASK"];
        [interestRates setValue:interestRateSeries forKey:[NSString stringWithFormat:@"%@IRASK",quoteCode]];
    } 
    return interestRateSeries;
}
        
        
- (double) calculateInterestForSimulation: (Simulation *) simulation 
                               ToDateTime: (long) endDateTime
{
    long earliestPositionDateTime;
    earliestPositionDateTime = [simulation timeDateOfEarliestPosition];
    
    NSArray *borrowingInterestRates;
    NSArray *lendingInterestRates;
    
    NSString *borrowingCode;
    NSString *lendingCode; 
    NSString *accBaseCode, *accQuoteCode;
    double accBaseAskPrice,accQuoteAskPrice;
    
    //DataSeriesValue *accBaseAskPrice;
    //DataSeriesValue *accQuoteAskPrice;
    double interestAccrued = 0.0;
    
    
    
    if([simulation currentExposure] !=0)
    {
        NSArray *fieldNames = [NSArray arrayWithObjects:@"BID",@"ASK",nil];
        NSDictionary *dataBaseValues = [simDataController getValues: fieldNames 
                                                         AtDateTime: endDateTime];
        
        
        accBaseCode = [NSString stringWithFormat:@"%@%@",[[simulation basicParameters] accCode],[[simulation basicParameters] baseCode]];
        accQuoteCode = [NSString stringWithFormat:@"%@%@",[[simulation basicParameters] accCode],[[simulation basicParameters] quoteCode]];
        
        
        if([[[simulation basicParameters] quoteCode] isEqualToString:[[simulation basicParameters] accCode]]){
            
            accQuoteAskPrice = 1;
            accBaseAskPrice = 1/[[dataBaseValues objectForKey:@"ASK"] doubleValue];
        }else{
            accBaseAskPrice = 1;
            accQuoteAskPrice = [[dataBaseValues objectForKey:@"ASK"] doubleValue];
        }
        
        
        
        
        //accBaseAskPrice = [simDataController valueFromDataBaseForFxPair:accBaseCode 
        //                                                    AndDateTime:endDateTime 
        //                                                       AndField:@"ASK"];                                         
        
        //accQuoteAskPrice = [simDataController valueFromDataBaseForFxPair:accQuoteCode 
        //                                                     AndDateTime:endDateTime 
        //                                                        AndField:@"ASK"]; 
        
        if([simulation currentExposure] >0)
        {
            borrowingCode = [[simulation basicParameters] baseCode];
            lendingCode = [[simulation basicParameters] quoteCode];
        }else{
            borrowingCode = [[simulation basicParameters] quoteCode];
            lendingCode = [[simulation basicParameters] baseCode];
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
                    DataSeriesValue *interestRateDSV = [borrowingInterestRates objectAtIndex:(iRateUpdateIndex + 1)];
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
                        interestAccrued = interestAccrued - ((positionSize * interestRate)*((double)(interestRateEnd-interestUpToDateDateTime)/(365*24*60*60))/accBaseAskPrice); 
                    }else{
                        interestAccrued = interestAccrued + ((positionSize * positionEntryPrice * interestRate)*((double)(interestRateEnd-interestUpToDateDateTime)/(365*24*60*60))) /accQuoteAskPrice;
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
                if(iRateUpdateIndex == ([lendingInterestRates count]-1))
                {
                    interestRateEnd = endDateTime;
                }else{
                    DataSeriesValue *interestRateDSV = [lendingInterestRates objectAtIndex:(iRateUpdateIndex + 1)];
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
                        interestAccrued = interestAccrued + ((positionSize * positionEntryPrice * interestRate)*((double)(interestRateEnd-interestUpToDateDateTime)/(365*24*60*60))/accQuoteAskPrice); 
                    }else{
                        interestAccrued = interestAccrued - ((positionSize *  interestRate)*((double)(interestRateEnd-interestUpToDateDateTime)/(365*24*60*60))) / accBaseAskPrice;
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
              ForSignalAtTime: (long) timeOfSignal
{
    int currentExposure = [simulation currentExposure];
    int exposureAdjustment = exposureAmount-currentExposure;
    NSUInteger tradeIndex;
    double tradePrice;
    double interestAccrued = 0.0;
    double realisedPnl = 0.0;
    
    NSString *accQuoteCode, *baseQuoteCode;
    double accQuoteBidPrice, accQuoteAskPrice, baseQuoteBidPrice, baseQuoteAskPrice;
    
    //First make sure interest calculations are up-to-date
    interestAccrued = [self calculateInterestForSimulation:simulation 
                                                ToDateTime:currentDateTime];
    
    
    accQuoteCode = [NSString stringWithFormat:@"%@%@",[[simulation basicParameters] accCode],[[simulation basicParameters] quoteCode]];
    
    baseQuoteCode = [NSString stringWithFormat:@"%@%@",[[simulation basicParameters] baseCode],[[simulation basicParameters] quoteCode]]; 
    
    NSArray *fieldNames = [NSArray arrayWithObjects:@"BID",@"ASK",nil];
    NSDictionary *dataBaseValues = [simDataController getValues: fieldNames 
                                                     AtDateTime: currentDateTime];
    if([[[simulation basicParameters] quoteCode] isEqualToString:[[simulation basicParameters] accCode]]){
        accQuoteBidPrice = 1;
        accQuoteAskPrice = 1;
    }else{
        accQuoteBidPrice = [[dataBaseValues objectForKey:@"BID"] doubleValue];
        accQuoteAskPrice = [[dataBaseValues objectForKey:@"ASK"] doubleValue];
    }
    baseQuoteBidPrice = [[dataBaseValues objectForKey:@"BID"] doubleValue];  
    baseQuoteAskPrice = [[dataBaseValues objectForKey:@"ASK"] doubleValue];
    
    if(exposureAdjustment != 0)
    {
        if(exposureAdjustment > 0){
            tradePrice = baseQuoteAskPrice;
        }else{
            tradePrice = baseQuoteBidPrice;
        }
        
        tradeIndex = [simulation numberOfTrades];
        realisedPnl = [simulation addTradeWithAmount:exposureAdjustment 
                                              AtTime:currentDateTime 
                                           WithPrice:tradePrice
                                 AndAccQuoteBidPrice:accQuoteBidPrice
                                 AndAccQuoteAskPrice:accQuoteAskPrice
                                AndBaseQuoteBidPrice:baseQuoteBidPrice
                                AndBaseQuoteAskPrice:baseQuoteAskPrice
                                       AndSignalTime:timeOfSignal ];    
    }
    return interestAccrued + realisedPnl;
}

+ (NSArray *) getNamesOfRequiredVariablesForSignal: (SignalSystem *) signalSystem
                                    AndPositioning: (PositioningSystem *) positionSystem
                                          AndRules: (NSArray *) rulesSystem
{
    NSArray *variablesForSignal;
    NSArray *variablesForPositioning;
    NSArray *variablesForRules;
    NSMutableArray *derivedVariables;


    if(signalSystem != Nil){
        variablesForSignal = [signalSystem variablesNeeded];
    }else{
        variablesForSignal = [[NSArray alloc] init];
    }
    derivedVariables = [variablesForSignal mutableCopy];

    if(positionSystem != Nil){
        variablesForPositioning = [positionSystem variablesNeeded];
    
        for(int i = 0; i < [variablesForPositioning count]; i++){
            NSString *variableToAdd = [variablesForPositioning objectAtIndex:i];
            BOOL duplicate = FALSE;
            for(int j = 0; j < [variablesForSignal count]; j++){
                if([[variablesForSignal objectAtIndex:j] isEqualToString:variableToAdd]){
                    duplicate = TRUE;
                    break;
                }
            }
            if(!duplicate){
                [derivedVariables addObject:variableToAdd];
            }
        }
    }
    if(rulesSystem != Nil){
        for(int j = 0; j < [rulesSystem count]; j++)
        {
            RulesSystem *singleRule = [rulesSystem objectAtIndex:j];
            variablesForRules = [singleRule variablesNeeded];
            for(int i = 0; i < [variablesForRules count]; i++){
                NSString *variableToAdd = [variablesForRules objectAtIndex:i];
                BOOL duplicate = FALSE;
                for(int j = 0; j < [variablesForSignal count]; j++){
                    if([[variablesForSignal objectAtIndex:j] isEqualToString:variableToAdd]){
                        duplicate = TRUE;
                        break;
                    }
                }
                if(!duplicate){
                    [derivedVariables addObject:variableToAdd];
                }
            }
        }
    }
    return derivedVariables;
}

- (double) getPrice:(PriceType) priceType 
             AtTime:(long) dateTime 
        WithSuccess:(BOOL *) success
{
    //long laggedTime;
    double price;
    NSArray *fieldNames;
    NSString *priceField;
    if(priceType == BID){
        priceField = @"BID";
    }
    if(priceType == ASK){
        priceField = @"ASK";
    }
    if(priceType == MID){
        priceField = @"MID";
    }
    fieldNames = [NSArray arrayWithObject:priceField];
    
    //laggedTime = dateTime + STATIC_LAG;
    NSDictionary *dataBaseValues = [simDataController getValues: fieldNames 
                                                     AtDateTime:dateTime];
    if([[dataBaseValues objectForKey:@"SUCCESS"] boolValue])
    {
        price = [[dataBaseValues objectForKey:priceField] doubleValue];
        *success = YES;
    }else{
        price = 0.0;
        *success = NO;
    }
    return price;
}


//-(Simulation *)getSimulationForName: (NSString *) name;
//{
//    Simulation *acc = nil;
//    acc = [allSimulations objectForKey:name];
//    return acc;
//}

-(double) getBalanceForSimulation: (Simulation *) simulation
{
    return [simulation currentBalance];
}

-(int) getExposureForSimulation: (Simulation *) simulation
{
    return [simulation currentExposure];
}
     
-(BOOL)exportWorkingSimulationDataToFile: (NSURL *) urlOfFile
{
    BOOL allOk;
    DataSeries* analysisData = [[self workingSimulation] analysisDataSeries]; 
    allOk = [analysisData writeDataSeriesToFile:urlOfFile];
    return allOk;
}

- (BOOL) exportWorkingSimulationTradesToFile: (NSURL *) urlOfFile
{
    BOOL allOk;
    allOk = [[self workingSimulation] writeTradesToFile:urlOfFile]; 
    return allOk;
}

- (BOOL) exportWorkingSimulationBalAdjmtsToFile: (NSURL *) urlOfFile
{
    BOOL allOk;
    allOk = [[self workingSimulation] writeBalanceAdjustmentsToFile:urlOfFile]; 
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

-(void) outputSimulationMessage:(NSString *) message
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

-(void) registerSimulation: (Simulation *) sim
{
    if([[self delegate] respondsToSelector:@selector(registerSimulation:)])
    {
        [[self delegate] registerSimulation:sim]; 
    }else{
        NSLog(@"Delegate not responding to \'registerSimulation:\'"); 
    }
}

- (void) progressBarOn{
    if([[self delegate] respondsToSelector:@selector(progressBarOn)])
    {
        [[self delegate] progressBarOn]; 
    }else{
        NSLog(@"Delegate not responding to \'progressBarOn\'"); 
    }
}

- (void) progressBarOff{
    if([[self delegate] respondsToSelector:@selector(progressBarOff)])
    {
        [[self delegate] progressBarOff]; 
    }else{
        NSLog(@"Delegate not responding to \'progressBarOff\'"); 
    }    
}

- (void) progressAsFraction:(NSNumber *) progressValue
{
    if([[self delegate] respondsToSelector:@selector(progressAsFraction:)])
    {
        [[self delegate] progressAsFraction:progressValue]; 
    }else{
        NSLog(@"Delegate not responding to \'progressAsFraction\'"); 
    }    
}

- (void) simulationEnded{
    if([[self delegate] respondsToSelector:@selector(simulationEnded)])
    {
        [[self delegate] simulationEnded]; 
    }else{
        NSLog(@"Delegate not responding to \'simulationEnded\'"); 
    }
}

- (BOOL) exportWorkingSimulationReportToFile:(NSURL *) urlOfFile
{
    NSArray *dataFieldNames = [[self workingSimulation] reportDataFieldsArray];
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
                lineOfFile = [NSString stringWithFormat:@"%@ , %@\r\n",[dataFieldNames objectAtIndex:fieldIndex],[[self workingSimulation] getReportDataFieldAtIndex:fieldIndex]];
            }
            [outFile writeData:[lineOfFile dataUsingEncoding:NSUTF8StringEncoding]];
        }
        [outFile closeFile];
        
    }
    return allOk;
}

#pragma mark -
#pragma mark Variables 

@synthesize cancelProcedure;
@synthesize workingSimulation = _workingSimulation;
@synthesize doThreads = _doThreads;

@end
