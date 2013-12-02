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

#define DAY_SECONDS (24*60*60)
#define FRI_MARKET_CLOSE 20
#define SUN_MARKET_OPEN 22

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
                              ForSimulation: (Simulation *) simulation
                      doNotIncreasePosition: (BOOL) doNotIncrease
                                 doCloseout: (BOOL) doCloseOut;

- (void) summariseSimulation: (Simulation *) simulation;
- (void) registerSimulation: (Simulation *) sim;
- (void) clearUserInterfaceMessages;
- (void) outputSimulationMessage:(NSString *) message;
- (void) analyseSimulation: (Simulation *) simulation
   withOptionalPreloadedData: (BOOL) preloadedData;
- (void) progressBarOn;
- (void) progressBarOff;
- (void) progressAsFraction:(NSNumber *) progressValue;
- (void) readingRecordSetProgress: (NSNumber *) progressFraction;
- (void) readingRecordSetMessage: (NSString *) progressMessage;

@property long timer;

@end

@implementation SimulationController

#pragma mark -
#pragma mark Setup Methods 

-(id)init
{
    self = [super init];
    if(self){
        _dataController = [[DataController alloc] init];
        [_dataController setDelegate:self];
        _interestRates = [[NSMutableDictionary alloc] init];
        _doThreads = NO;
        _loadAllData = YES;
        _simulationRunning = NO;
        return self;
    }
    return nil;
}

-(void)setDelegate:(id)del
{
    _delegate = del;
}

-(id)delegate 
{ 
    return _delegate;
};

- (BOOL) doThreads
{
    return _doThreads;
}

- (void) setDoThreads:(BOOL)doThreadedProcedures
{
    _doThreads = doThreadedProcedures;
    [[self dataController] setDoThreads:doThreadedProcedures];
}

#pragma mark -
#pragma mark General Methods

+(BOOL)positioningUnderstood:(NSString *) positioningString
{
    return [PositioningSystem basicCheck:positioningString];
}

+ (BOOL)simulationUnderstood:(NSString *) signalString
{
    return [SignalSystem basicSignalCheck:signalString];
}

+ (BOOL)seriesUnderstood:(NSString *) seriesString
{
    return [SignalSystem basicSeriesCheck:seriesString];
}


+ (BOOL)rulesUnderstood:(NSString *) rulesString
{
    return [RulesSystem basicCheck:rulesString];
}


- (void)askSimulationToCancel
{
    [self setCancelProcedure:YES];
}

- (void)tradingSimulation:(NSDictionary *) parameters
{
    NSString *tradingPair;
    Simulation *newSimulation;
    long minDateTime, maxDateTime;
    //BOOL accountCurrencyIsQuoteCurrency = NO;
    NSArray *userData;
    NSString *userDataFilename;
    long tradingDayStartHour;
    long tradingDayEndHour;
    long tradingDayStartMinute;
    long tradingDayEndMinute;
    NSString *userMessage;
    long tradingDayStartSeconds = 0;
    long tradingDayEndSeconds = 0;
    long dataRequestMinDateTime, dataRequestMaxDateTime;
    long dataRequestTruncatedFlag = 1;
    BOOL allOk = YES;
    BOOL fullDataLoaded = YES;
    
    long leadTimeRequiredForPositioning;
    long leadTimeRequiredForSignal;
    long leadTimeRequired;
    
    [self setCancelProcedure:NO];
    
    [self setSimulationRunning:YES];
    
    NSDate *calculationStartTime = [NSDate date];
    NSString *simName = [parameters objectForKey:@"SIMNAME"];
    NSString *baseCode = [parameters objectForKey:@"BASECODE"];
    NSString *quoteCode = [parameters objectForKey:@"QUOTECODE"];
    NSString *accCode = [parameters objectForKey:@"ACCOUNTCODE"];
    long startDateTime = [[parameters objectForKey:@"STARTTIME"] longValue];
    long endDateTime = [[parameters objectForKey:@"ENDTIME"] longValue];
    int maxLeverage = (int)[[parameters objectForKey:@"MAXLEVERAGE"] doubleValue];
    double startingBalance = [[parameters objectForKey:@"STARTBALANCE"] doubleValue];  
    long initialDataBeforeStart = [[parameters objectForKey:@"WARMUPTIME"] longValue]; 
    int timeStep = [[parameters objectForKey:@"TIMESTEP"] intValue];
    int tradingLag = [[parameters objectForKey:@"TRADINGLAG"] intValue];
    long dataRate = [[parameters objectForKey:@"DATARATE"] longValue];
    NSString *simDescription = [parameters objectForKey:@"SIMTYPE"];
    NSString *positioningString = [parameters objectForKey:@"POSTYPE"];
    NSString *rulesString = [parameters objectForKey:@"RULES"];
    long tradingDayStart = [[parameters objectForKey:@"TRADINGDAYSTART"] longValue];
    long tradingDayEnd = [[parameters objectForKey:@"TRADINGDAYEND"] longValue];
    BOOL weekendTrading =   [[parameters objectForKey:@"WEEKENDTRADING"] boolValue];
    BOOL userDataGiven =  [[parameters objectForKey:@"USERDATAGIVEN"] boolValue];
    NSArray *extraRequiredVariables;
    
    
    long dataStoreIndex = 0;
    BOOL useDataStore = NO;
    BOOL doDatabaseProgress;
    doDatabaseProgress =  [[self dataController] databaseSamplingRate] < 3600;

    SignalSystem *newSigSystem;
    PositioningSystem *newPosSystem;
    
    if(![self cancelProcedure]){
        if(userDataGiven){
            userData = [parameters objectForKey:@"USERDATA"];
            userDataFilename = [parameters objectForKey:@"USERDATAFILE"];
            [[self dataController] setData:userData
                              FromFile:userDataFilename];
            [[self dataController] setFileDataAdded:YES];
        }else{
             [[self dataController] setFileDataAdded:NO];
        }
        
        tradingDayStartHour = (int)tradingDayStart/(60*60) ;
        tradingDayEndHour = (int)tradingDayEnd/(60*60) ;
        tradingDayStartMinute = (tradingDayStart-(tradingDayStartHour*60*60))%60; 
        tradingDayEndMinute = (tradingDayEnd-(tradingDayEndHour*60*60))%60; 
        
        tradingPair = [NSString stringWithFormat:@"%@%@",baseCode,quoteCode];
        
        minDateTime = [[self dataController] getMinDataDateTimeForPair:tradingPair];
        maxDateTime = [[self dataController] getMaxDataDateTimeForPair:tradingPair];
        
        if(((double)endDateTime - startDateTime)/[DataController getMaxDataLength] > 1.0){
            [self setLoadAllData:NO];
        }else{
            [self setLoadAllData:YES];
        }
        
        leadTimeRequiredForSignal = [newSigSystem leadTimeRequired];
        initialDataBeforeStart = MAX(initialDataBeforeStart,leadTimeRequiredForSignal);
        
        if(startDateTime < (minDateTime + initialDataBeforeStart))
        {
            startDateTime =  minDateTime + initialDataBeforeStart;
        }
        startDateTime = [EpochTime epochTimeAtZeroHour:startDateTime] + timeStep  * ((startDateTime-[EpochTime epochTimeAtZeroHour:startDateTime])/timeStep);
        startDateTime = startDateTime + timeStep;
        
        [self clearUserInterfaceMessages];
        
        
        NSDate * now = [NSDate date];
        NSDateFormatter *outputFormatter = [[NSDateFormatter alloc] init];
        [outputFormatter setDateFormat:@"YYYY/MM/dd HH:mm:ss"];
        NSString *currentDateString = [outputFormatter stringFromDate:now];
        
        userMessage = [NSString stringWithFormat:@"%@ Starting %@\n",currentDateString, simName];
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
                                             AndDataRate:dataRate
                                         AndSamplingRate:timeStep
                                           AndTradingLag:tradingLag
                                     AndTradingTimeStart:tradingDayStartSeconds
                                       AndTradingTimeEnd:tradingDayEndSeconds
                                       AndWeekendTrading:weekendTrading
                                           AndWarmupTime:initialDataBeforeStart];
        
        if(userData){
            [newSimulation setUserAddedData:userDataFilename];
        }
        
        newSigSystem = [[SignalSystem alloc] initWithString:simDescription];
        [newSimulation setSignalSystem: newSigSystem];
        newPosSystem = [[PositioningSystem alloc] initWithString:positioningString]; 
        [newSimulation setPositionSystem:newPosSystem];
        
        if( [newPosSystem signalInThreshold] > 0 ){
            [newSigSystem setThreshold:[newPosSystem signalInThreshold]*[[self dataController] getPipsizeForSeriesName:tradingPair]];
        }else{
            [newSigSystem setThreshold:[newPosSystem signalThreshold]*[[self dataController] getPipsizeForSeriesName:tradingPair]];
        }
        
        BOOL rulesAdded = YES;
        if([rulesString length] > 0){
            rulesAdded = [newSimulation addTradingRules:rulesString];
            if(!rulesAdded){
                userMessage = @"***Problem setting up rules***\n";
                [[[newSimulation simulationRunOutput] mutableString] appendString:userMessage];
                if([self doThreads]){
                    [self performSelectorOnMainThread:@selector(outputSimulationMessage:) 
                                           withObject:userMessage 
                                        waitUntilDone:NO];
                }
                [self setCancelProcedure:YES];
            }
        }
    }
    
    if(![self cancelProcedure]){
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
    
    leadTimeRequiredForSignal = [newSigSystem leadTimeRequired];
    leadTimeRequiredForPositioning = [newPosSystem leadTimeRequired];
    
    leadTimeRequired = MAX(leadTimeRequiredForPositioning,leadTimeRequiredForSignal);
        
    //Getting the initial data
    long simulationDateTime;
    simulationDateTime = startDateTime;
    
    
    
    if(![self cancelProcedure]){
        userMessage = @"Importing initial price data";
        [[[newSimulation simulationRunOutput] mutableString] appendString:userMessage];
        if([self doThreads]){
            [self performSelectorOnMainThread:@selector(outputSimulationMessage:)
                                   withObject:userMessage waitUntilDone:NO];
            [self performSelectorOnMainThread:@selector(updateStatus:) 
                                   withObject:userMessage 
                                waitUntilDone:NO];
            
            if(doDatabaseProgress){
                [self performSelectorOnMainThread:@selector(readingDatabaseOn)
                                       withObject:nil
                                    waitUntilDone:NO];
            }
        }
        
        extraRequiredVariables =  [SimulationController getNamesOfRequiredVariablesForSignal:[newSimulation signalSystem]                                                       
                                                                              AndPositioning:[newSimulation positionSystem] 
                                                                                    AndRules:[newSimulation rulesSystem]];
        
        dataRequestMinDateTime = startDateTime - initialDataBeforeStart;
        dataRequestMaxDateTime = endDateTime + 7*DAY_SECONDS  + tradingLag;
        
        [newSimulation setDataStartDateTime:dataRequestMinDateTime];
        allOk = [[self dataController] setupDataSeriesForName:tradingPair];
        if(!allOk){
            userMessage = @"***Problem setting up database***";
            if([self doThreads]){
                [self performSelectorOnMainThread:@selector(updateStatus:) 
                                       withObject:userMessage 
                                    waitUntilDone:NO];
            }
            [self setCancelProcedure:YES];
        }
        
        useDataStore = [[self dataController] okToUseDataStoreFrom:dataRequestMinDateTime
                                                                To:dataRequestMaxDateTime
                                                      WithDataRate:dataRate
                                                           ForCode:tradingPair];
        
        if(useDataStore){
            dataStoreIndex--;
        }else{
            dataStoreIndex++;
        }
        allOk = [[self dataController] getDataForStartDateTime: dataRequestMinDateTime
                                                AndEndDateTime: dataRequestMaxDateTime
                                             AndExtraVariables: extraRequiredVariables
                                               AndSignalSystem: [newSimulation signalSystem]
                                                   AndDataRate: dataRate
                                                 WithStoreCode: dataStoreIndex
                                      WithRequestTruncatedFlag: &dataRequestTruncatedFlag];
        
        //NSURL *dumpFile = [[NSURL alloc] initFileURLWithPath:[NSString stringWithFormat:@"/Users/Martin/Desktop/datadump%ld.csv",dataStoreIndex]];
        //[[[self dataController] dataSeries] writeDataSeriesToFile:dumpFile];
        
        userMessage = @"Data set up";
        if([self doThreads] ){
            [self performSelectorOnMainThread:@selector(updateStatus:) 
                                   withObject:userMessage
                                waitUntilDone:NO];
            if(doDatabaseProgress){
                [self performSelectorOnMainThread:@selector(readingDatabaseOff)
                                       withObject:nil
                                    waitUntilDone:NO];
            }
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
    if(![self cancelProcedure]){
        //Creating a timeseries object to store the data that is actually used in the simulation
        fieldNames = [[self dataController] getFieldNames];
        long numberOfSimulationSteps = (endDateTime-startDateTime)/timeStep;
  
        dateTimesData = [[NSMutableData alloc] initWithLength:numberOfSimulationSteps * sizeof(long)]; 
        simDateTimes = (long *)[dateTimesData mutableBytes];
        
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
    if([self doThreads] && ![self cancelProcedure]){
        userMessage = @"Simulation Loop";
        [self performSelectorOnMainThread:@selector(updateStatus:) withObject:userMessage waitUntilDone:NO];
        [self performSelectorOnMainThread:@selector(progressBarOn) withObject:nil waitUntilDone:NO];
    }
    
    BOOL isTradingTime;
    BOOL doCloseOut = NO, preventIncreasePos = NO, doOutOfHoursCloseout = NO, isTradingDay = YES;
    BOOL marketClosed = NO;
    int simStepIndex = 0;
    
    //signalIndex = 0;
    long timeOfDayInSeconds;
    NSDictionary *values;

    [self setCashPosition:startingBalance];
    
    double fridayCutoff = [RulesSystem fridayRule:[newSimulation rulesSystem]];
    doOutOfHoursCloseout = [RulesSystem outOfHoursCloseRule:[newSimulation rulesSystem]];

    if(![self cancelProcedure]){
        do{
            isTradingDay = YES;
            preventIncreasePos = NO;
            
            marketClosed = NO;
            
            if(simulationDateTime+timeStep > endDateTime)
            {
                doCloseOut = YES;
            }else{
                if([EpochTime dayOfWeek:simulationDateTime] == 5){
                    if(simulationDateTime > [EpochTime epochTimeAtZeroHour:simulationDateTime] + (FRI_MARKET_CLOSE * 60 * 60))
                    {
                        marketClosed = YES;
                    }
                }
                if([EpochTime dayOfWeek:simulationDateTime] == 6){
                    marketClosed = YES;
                }
                if([EpochTime dayOfWeek:simulationDateTime] == 0){
                    if(simulationDateTime < [EpochTime epochTimeAtZeroHour:simulationDateTime] + (SUN_MARKET_OPEN * 60 * 60))
                    {
                        marketClosed = YES;
                    }
                }
            }
            
            if(!marketClosed){
                
                if(!weekendTrading){
                    NSString *dayOfWeek = [[NSDate dateWithTimeIntervalSince1970:simulationDateTime] descriptionWithCalendarFormat:@"%w" timeZone:[NSTimeZone timeZoneWithName:@"GMT"] locale:nil];
                    if([dayOfWeek isEqualToString:@"0"] || [dayOfWeek isEqualToString:@"6"]){
                        isTradingDay = NO;
                    }else{
                        isTradingDay = YES;
                    }
                }
                timeOfDayInSeconds = simulationDateTime - [EpochTime epochTimeAtZeroHour:simulationDateTime];
                
                if((timeOfDayInSeconds >= tradingDayStartSeconds) && (timeOfDayInSeconds <= tradingDayEndSeconds)){
                    isTradingTime = YES;
                }else{
                    isTradingTime = NO;
                }
                isTradingTime = isTradingTime && isTradingDay;
                
                // First make sure the data is ok
                //If the current date is greater than the last day of data we need to move the data forward
                if(simulationDateTime + tradingLag > [[self dataController] getMaxDateTimeForLoadedData] )
                {
                    if([self loadAllData]){
                        dataRequestMinDateTime = [[self dataController] getMinDateTimeForLoadedData];
                    }else{
                        dataRequestMinDateTime = MIN(simulationDateTime-leadTimeRequired-3*timeStep ,[[self dataController] getMaxDateTimeForLoadedData]);
                        fullDataLoaded = NO;
                    }
                    
                    if(simulationDateTime > endDateTime){
                        dataRequestMaxDateTime = simulationDateTime + 7*DAY_SECONDS + tradingLag;
                    }else{
                        dataRequestMaxDateTime = endDateTime + 7*DAY_SECONDS  + tradingLag;
                    }
                    if([self doThreads]  && dataStoreIndex >= 0 && doDatabaseProgress){
                        [self performSelectorOnMainThread:@selector(readingDatabaseOn) withObject:nil waitUntilDone:NO];
                        
                    }
                    if(useDataStore){
                        dataStoreIndex--;
                    }else{
                        dataStoreIndex++;
                    }
                    [[self dataController] getDataForStartDateTime: dataRequestMinDateTime
                                                    AndEndDateTime: dataRequestMaxDateTime
                                                 AndExtraVariables: extraRequiredVariables
                                                   AndSignalSystem: [newSimulation signalSystem]
                                                       AndDataRate:dataRate
                                                     WithStoreCode: dataStoreIndex
                                          WithRequestTruncatedFlag: &dataRequestTruncatedFlag];
                    
                    if(dataRequestTruncatedFlag == 0){
                        endDateTime = MIN(endDateTime,[[self dataController] getMaxDateTimeForLoadedData]);
                    }
                    if([self doThreads] && doDatabaseProgress){
                        [self performSelectorOnMainThread:@selector(readingDatabaseOff)
                                               withObject:nil
                                            waitUntilDone:NO];
                    }
                }
                
                //Check we successfully have data for the required date
                if(simulationDateTime > [[self dataController] getMaxDateTimeForLoadedData]){
                    userMessage = [NSString stringWithFormat:@"@DataSeries does not cover current date, Max: %ld current %ld",[[self dataController] getMaxDateTimeForLoadedData],simulationDateTime];
                    [self performSelectorOnMainThread:@selector(updateStatus:) withObject:userMessage waitUntilDone:NO];
                    [self setCancelProcedure:YES];
                }
                values = [[self dataController] getValues: fieldNames
                                               AtDateTime:simulationDateTime ];
                
                if(![[values objectForKey:@"SUCCESS"] boolValue])
                {
                    userMessage = [NSString stringWithFormat:@"Data Problem in getValuesForFields %ld",simulationDateTime];
                    [self performSelectorOnMainThread:@selector(updateStatus:) withObject:userMessage waitUntilDone:NO];
                    [self setCancelProcedure:YES];
                    
                }
                simDateTimes[simStepIndex] = [[values objectForKey:@"DATETIME"] longValue];
                for(fieldIndex=0;fieldIndex<[fieldNames count];fieldIndex++){
                    simulationData[fieldIndex][simStepIndex] = [[values objectForKey:[fieldNames objectAtIndex:fieldIndex]] doubleValue];
                }
                
                
                                
                if(fridayCutoff > 0.0){
                    if([EpochTime dayOfWeek:simulationDateTime] == 5){
                        if(simulationDateTime > [EpochTime epochTimeAtZeroHour:simulationDateTime] + (fridayCutoff * 60 * 60))
                        {
                            preventIncreasePos = YES;
                        }
                    }
                }
                
                
                if(doCloseOut){
                    doCloseOut = ![self checkSignalAndAdjustPositionAtTime:simulationDateTime
                                                             ForSimulation:newSimulation
                                                     doNotIncreasePosition:YES
                                                                doCloseout:YES];
                }else{
                    if((!isTradingTime) && doOutOfHoursCloseout){
                        doCloseOut = ![self checkSignalAndAdjustPositionAtTime:simulationDateTime
                                                                 ForSimulation:newSimulation
                                                         doNotIncreasePosition:YES
                                                                    doCloseout:NO];
                    }else{
                        if(isTradingTime){
                            doCloseOut = ![self checkSignalAndAdjustPositionAtTime:simulationDateTime
                                                                     ForSimulation:newSimulation
                                                             doNotIncreasePosition:preventIncreasePos
                                                                        doCloseout:NO];
                        }
                    }
                }
                
            }
            simulationDateTime= simulationDateTime+timeStep;
            simStepIndex++;
            //NSLog(@"%@ CASH:%f NAV:%f",[EpochTime stringDateWithTime:simulationDateTime], cashPosition, nav);
            if([self doThreads]){
                [self performSelectorOnMainThread:@selector(progressAsFraction:)
                                       withObject:[NSNumber numberWithDouble:(double)(simulationDateTime - startDateTime)/(endDateTime - startDateTime) ] waitUntilDone:NO];
            }
        }while((simulationDateTime <= endDateTime)   && allOk && ![self cancelProcedure]);
    }
    
    if(![self cancelProcedure]){
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
    
    if(![self cancelProcedure])
    {
        DataSeries *simulationDataSeries;
        simulationDataSeries = [[self dataController] createNewDataSeriesWithXData: dateTimesData
                                                                      AndYData: simulationDataDictionary 
                                                                 AndSampleRate: timeStep];
        [newSimulation setSimulationDataSeries:simulationDataSeries];
        [self summariseSimulation:newSimulation];
    }

    if(![self cancelProcedure])
    {
        userMessage = @"Analysing The Simulation";
        if([self doThreads]){
            [self performSelectorOnMainThread:@selector(updateStatus:) withObject:userMessage waitUntilDone:NO];
        }
        [self analyseSimulation:newSimulation
      withOptionalPreloadedData:fullDataLoaded];
        
    }

    if([self cancelProcedure]){
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
    [[self dataController] removeDerivedFromDataStore] ;
    [self setSimulationRunning:NO];
    [self simulationEnded];
    
    NSDate *calculationEndTime = [NSDate date];
    userMessage = [NSString stringWithFormat:@"Simulation took %3.0lf seconds \n",[calculationEndTime timeIntervalSinceDate:calculationStartTime]];
    [[[newSimulation simulationRunOutput] mutableString] appendString:userMessage];
    if([self doThreads]){
        [self performSelectorOnMainThread:@selector(outputSimulationMessage:) withObject:userMessage waitUntilDone:NO];
    }else{
        [self outputSimulationMessage:userMessage];
    }
}

-(void)analyseSimulation: (Simulation *) simulation
       withOptionalPreloadedData: (BOOL) preloadedData;
{
    NSString *userMessage;
    DataSeries *positionDataSeries;
    //DataSeries *simulationDataSeries;
    NSDictionary *currentDataValues;
    NSArray *simDataFieldNames;
    
    NSMutableData *dateTimesData;
    long *dateTimesArray;
    NSMutableDictionary *simulationDataDictionary;
    NSMutableData *simulationDataArrayData;
    double **simulationDataArray;
    //NSMutableData *signalData;
    //double *signalArray;
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
    NSMutableData *spreadCostData;
    double *spreadCostArray;
    NSMutableData *drawDownData;
    double *drawDownArray;
    NSMutableData *positionAvePriceData;
    double *positionAvePriceArray;
    
    
    long dataStoreIndex = 0, dataRate = 0;
    
    NSUInteger timeStep = 0, tradeIndex, cashMoveIndex;
    //double signal, currentSignal;
    long startDateTime, endDateTime, stepDateTime, nextTradeDateTime;
    BOOL allTradesFinished, allCashMovesFinished;
    long dataRequestTruncated = 1;
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
    
    int currentPosition = 0, currentPositionSign = 0, nextTradeAmount = 0;
    double wgtPositionClosePrice;
    int exposureAfterTrade;
    long currentDateTime,previousDateTime;
    double currentBid = 0.0,currentAsk = 0.0;
    double nextTradePrice, currentCashBalance, tradePnl, interestCosts;
    double largestDrawdown;
    long largestDrawdownDateTime;
    double currentMaximumNav, spreadCost= 0.0;
    NSUInteger arraySize;
    long dataRequestMinDateTime, dataRequestMaxDateTime;
    
    BOOL doDatabaseProgress;
    doDatabaseProgress= [[self dataController] databaseSamplingRate] < 3600;
    
    userMessage = @"Performing Analysis of Simulation\n";
    [[[simulation simulationRunOutput] mutableString] appendString:userMessage];
    if([self doThreads]){
        [self performSelectorOnMainThread:@selector(outputSimulationMessage:) withObject:userMessage waitUntilDone:NO];
    }
    
    simDataFieldNames = [[simulation simulationDataSeries] getFieldNames];
    
    startDateTime = [simulation startDate];
    endDateTime = [simulation endDate];
    timeStep = [simulation samplingRate];
    dataRate = [simulation dataRate];
    
    long activityDateTime;
    int activityIndex = 0;
    BOOL allActivityFinished;
    NSMutableArray *activityDates;
    
    if([self doThreads]){
        [self performSelectorOnMainThread:@selector(progressBarOn) withObject:nil waitUntilDone:NO];
        [self performSelectorOnMainThread:@selector(progressAsFraction:)
                               withObject:[NSNumber numberWithDouble:0.02 ] waitUntilDone:NO];
    }
     
    if([simulation numberOfTrades] >0){
        
        // First get some details about all the trades
        long currentExposure = 0;
        double totalLosers = 0.0, totalWins = 0.0;
        long minExposureLength = 0, maxExposureLength = 0, medianExposureLength = 0, medianLoserExposureLength = 0, medianWinnerExposureLength = 0;
        NSMutableArray *exposureLengths = [[NSMutableArray alloc] init];
        NSMutableArray *winnerExposureLengths = [[NSMutableArray alloc] init];
        NSMutableArray *loserExposureLengths = [[NSMutableArray alloc] init];
        
        long numberOfGrossWiningTrades = 0, numberOfGrossLosingTrades = 0,  tradeAmount = 0, tradeToCloseAmount = 0, tradeToOpenAmount = 0;
        double tradeCashFlowOfExposure = 0.0, bestWinner = 0.0, biggestLoser = 0.0;
        long exposureStartTime;
        for(int iTrade = 0; iTrade < [simulation numberOfTrades]; iTrade++){
            tradeDetails = [simulation detailsOfTradeAtIndex:iTrade];
            tradeAmount = [[tradeDetails objectForKey:@"AMOUNT"] intValue];
            if(currentExposure == 0){
                exposureStartTime = [[tradeDetails objectForKey:@"DATETIME"] longValue];
                tradeCashFlowOfExposure =  - [[tradeDetails objectForKey:@"AMOUNT"] intValue] * [[tradeDetails objectForKey:@"PRICE"] doubleValue];
            }else{
                if([UtilityFunctions signOfLong:currentExposure] != [UtilityFunctions signOfLong:tradeAmount]){
                    tradeToOpenAmount = MAX(0,ABS(tradeAmount) - ABS(currentExposure))*[UtilityFunctions signOfLong:tradeAmount];
                    tradeToCloseAmount = tradeAmount - tradeToOpenAmount;
                }
                if([UtilityFunctions signOfLong:currentExposure] == [UtilityFunctions signOfLong:tradeAmount]){
                    //tradeToOpenAmount = tradeAmount;
                    tradeToCloseAmount = 0;
                }
            
                if(currentExposure + tradeToCloseAmount == 0){//End of exposure
                    long exposureLength = [[tradeDetails objectForKey:@"DATETIME"] longValue] - exposureStartTime;
                    double interestCosts = [simulation getInterestCostsFrom:exposureStartTime
                                                                          To:[[tradeDetails objectForKey:@"DATETIME"] longValue]];
                    [exposureLengths addObject:[NSNumber numberWithLong:exposureLength]];
                    tradeCashFlowOfExposure = tradeCashFlowOfExposure - tradeToCloseAmount * [[tradeDetails objectForKey:@"PRICE"] doubleValue];
                    if([[simulation quoteCode] isNotEqualTo:[simulation accCode]]){
                        tradeCashFlowOfExposure = tradeCashFlowOfExposure/[[tradeDetails objectForKey:@"PRICE"] doubleValue];
                    }
                    tradeCashFlowOfExposure = tradeCashFlowOfExposure + interestCosts;
                    
                    if(tradeCashFlowOfExposure > 0){
                        numberOfGrossWiningTrades++;
                        totalWins = totalWins + tradeCashFlowOfExposure;
                        bestWinner = MAX(bestWinner, tradeCashFlowOfExposure);
                        [winnerExposureLengths addObject:[NSNumber numberWithLong:exposureLength]];
                    }
                    if(tradeCashFlowOfExposure <= 0){
                        numberOfGrossLosingTrades++;
                        totalLosers = totalLosers + tradeCashFlowOfExposure;
                        biggestLoser = MIN(biggestLoser, tradeCashFlowOfExposure);
                        [loserExposureLengths addObject:[NSNumber numberWithLong:exposureLength]];
                    }
                    //totalInterestCosts = totalInterestCosts + interestCosts;
                }else{
                    if(tradeToCloseAmount != 0){
                        tradeCashFlowOfExposure = tradeCashFlowOfExposure - tradeToCloseAmount * [[tradeDetails objectForKey:@"PRICE"] doubleValue];
                        
                    }
                }
            }
            currentExposure = currentExposure + tradeAmount;
        }
        
        double meanLoser = totalLosers/numberOfGrossLosingTrades;
        double meanWinner = totalWins/numberOfGrossWiningTrades;
        
        long numberOfExposures = [exposureLengths count];
        NSSortDescriptor *lowestToHighest = [NSSortDescriptor sortDescriptorWithKey:@"self" ascending:YES];
        [exposureLengths sortUsingDescriptors:[NSArray arrayWithObject:lowestToHighest]];
        [loserExposureLengths sortUsingDescriptors:[NSArray arrayWithObject:lowestToHighest]];
        [winnerExposureLengths sortUsingDescriptors:[NSArray arrayWithObject:lowestToHighest]];
        
        minExposureLength = [[exposureLengths objectAtIndex:0] longValue];
        maxExposureLength = [[exposureLengths objectAtIndex:(numberOfExposures-1)] longValue];
        
        if(numberOfExposures % 2 ){
            medianExposureLength = ([[exposureLengths objectAtIndex:floor((numberOfExposures)/2.0)-1] longValue] + [[exposureLengths objectAtIndex:ceil((numberOfExposures)/2.0)-1] longValue])/2;
        }else{
            medianExposureLength = [[exposureLengths objectAtIndex:numberOfExposures/2-1] longValue];
        }
        
        if([loserExposureLengths count] > 1 && [loserExposureLengths count] % 2 ){
            medianLoserExposureLength = ([[loserExposureLengths objectAtIndex:floor(([loserExposureLengths count])/2.0)-1] longValue] + [[loserExposureLengths objectAtIndex:ceil(([loserExposureLengths count])/2.0)-1] longValue])/2;
        }else{
            if([loserExposureLengths count] == 0){
                medianLoserExposureLength = 0;
            }else{
                if([loserExposureLengths count] == 1){
                    medianLoserExposureLength = [[loserExposureLengths objectAtIndex:0] longValue];
                }else{
                    medianLoserExposureLength =  [[loserExposureLengths objectAtIndex:[loserExposureLengths count]/2-1] longValue];
                }
            }
        }
        
        if([winnerExposureLengths count] > 1 && [winnerExposureLengths count] % 2){
            medianWinnerExposureLength = ([[winnerExposureLengths objectAtIndex:floor(([winnerExposureLengths count])/2.0)-1] longValue] + [[winnerExposureLengths objectAtIndex:ceil(([winnerExposureLengths count])/2.0)-1] longValue])/2;
        }else{
            if([winnerExposureLengths count] == 0){
                medianWinnerExposureLength = 0;
            }else{
                if([winnerExposureLengths count] == 1){
                    medianWinnerExposureLength = [[winnerExposureLengths objectAtIndex:0] longValue];
                }else{
                    medianWinnerExposureLength = [[winnerExposureLengths objectAtIndex:[winnerExposureLengths count]/2-1] longValue];
                }
            }
        }
        
        [simulation addObjectToSimulationResults:[NSNumber numberWithLong:numberOfExposures]
                                          ForKey:@"EXP NUMBER"];
        [simulation addObjectToSimulationResults:[NSNumber numberWithLong:numberOfGrossLosingTrades]
                                          ForKey:@"EXP N LOSS"];
        [simulation addObjectToSimulationResults:[NSNumber numberWithLong:numberOfGrossWiningTrades]
                                          ForKey:@"EXP N WIN"];
        [simulation addObjectToSimulationResults:[NSNumber numberWithDouble:meanLoser]
                                          ForKey:@"EXP MEAN LOSS"];
        [simulation addObjectToSimulationResults:[NSNumber numberWithDouble:meanWinner]
                                          ForKey:@"EXP MEAN WIN"];
        [simulation addObjectToSimulationResults:[NSNumber numberWithLong:minExposureLength]
                                          ForKey:@"EXP MIN LEN"];
        [simulation addObjectToSimulationResults:[NSNumber numberWithLong:maxExposureLength]
                                          ForKey:@"EXP MAX LEN"];
        [simulation addObjectToSimulationResults:[NSNumber numberWithLong:medianExposureLength]
                                          ForKey:@"EXP MED LEN"];
        [simulation addObjectToSimulationResults:[NSNumber numberWithLong:medianLoserExposureLength]
                                          ForKey:@"EXP LOSS MED LEN"];
        [simulation addObjectToSimulationResults:[NSNumber numberWithLong:medianWinnerExposureLength]
                                          ForKey:@"EXP WIN MED LEN"];
        [simulation addObjectToSimulationResults:[NSNumber numberWithDouble:biggestLoser]
                                          ForKey:@"EXP BIG LOSS"];
        [simulation addObjectToSimulationResults:[NSNumber numberWithDouble:bestWinner]
                                          ForKey:@"EXP BIG WIN"];
        
        [simulation addObjectToSimulationResults:[NSNumber numberWithDouble:totalLosers]
                                          ForKey:@"TOTAL LOSS"];
        [simulation addObjectToSimulationResults:[NSNumber numberWithDouble:totalWins]
                                          ForKey:@"TOTAL WIN"];
        
        cashMoveIndex = 0;
        allCashMovesFinished = NO;
        nextCashMoveDateTime = [simulation getDateTimeForBalanceAdjustmentAtIndex:cashMoveIndex];
        
        tradeIndex = 0;
        allTradesFinished = NO;
        nextTradeDateTime = [simulation getDateTimeForTradeAtIndex:tradeIndex];
        
        activityDates = [[NSMutableArray alloc] init];
        
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
    }
    
    if([self doThreads]){
        [self performSelectorOnMainThread:@selector(progressBarOn) withObject:nil waitUntilDone:NO];
        [self performSelectorOnMainThread:@selector(progressAsFraction:)
                               withObject:[NSNumber numberWithDouble:0.04 ] waitUntilDone:NO];
    }

     
    NSMutableArray *dateTimesOfAnalysis = [[NSMutableArray alloc] init];
    
    activityIndex = 0;
    if([activityDates count] > 0){
        activityDateTime = [[activityDates objectAtIndex:activityIndex] longValue];
        allActivityFinished = NO;
    }else{
        allActivityFinished = YES;
    }
    
    BOOL isTradingTime;
    NSString *dayOfWeek;
    long timeOfDayInSeconds;
    
    stepDateTime = startDateTime;
    do{
        //Dont normally collect samples out of hours
        isTradingTime = YES;
        dayOfWeek = [[NSDate dateWithTimeIntervalSince1970:stepDateTime] descriptionWithCalendarFormat:@"%w" timeZone:[NSTimeZone timeZoneWithName:@"GMT"] locale:nil];
        timeOfDayInSeconds = stepDateTime - [EpochTime epochTimeAtZeroHour:stepDateTime];
        if([dayOfWeek isEqualToString:@"5"]){
            if(timeOfDayInSeconds > (FRI_MARKET_CLOSE *60 * 60)){
                isTradingTime = NO;
            }
        }
        if([dayOfWeek isEqualToString:@"6"]){
            isTradingTime = NO;
        }
        if([dayOfWeek isEqualToString:@"0"]){
            if(timeOfDayInSeconds < (SUN_MARKET_OPEN *60 * 60)){
                isTradingTime = NO;
            }
        }
        
        if(activityIndex < [activityDates count]){
            if(stepDateTime >= activityDateTime){
                isTradingTime = YES;
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
            if(isTradingTime){
                [dateTimesOfAnalysis addObject:[NSNumber numberWithLong:stepDateTime]];
            }
        }else{
            if(isTradingTime){
                [dateTimesOfAnalysis addObject:[NSNumber numberWithLong:stepDateTime]];
            }
        }
        stepDateTime = stepDateTime + timeStep;
    }while((stepDateTime <= endDateTime || !allActivityFinished) && ![self cancelProcedure]);
    
    arraySize = [dateTimesOfAnalysis count] - 1;
    
    if(![self cancelProcedure]){
        dateTimesData = [[NSMutableData alloc] initWithLength:arraySize * sizeof(long)];
        dateTimesArray = (long *)[dateTimesData mutableBytes];
        
        //signalData = [[NSMutableData alloc] initWithLength:arraySize * sizeof(double)];
        //signalArray = (double *)[signalData mutableBytes];
        
        marketPositionData = [[NSMutableData alloc] initWithLength:arraySize * sizeof(double)];
        marketPositionArray = (double *)[marketPositionData mutableBytes];
        
        shortIndicatorData = [[NSMutableData alloc] initWithLength:arraySize * sizeof(double)];
        shortIndicatorArray = (double *)[shortIndicatorData mutableBytes];
        
        longIndicatorData = [[NSMutableData alloc] initWithLength:arraySize * sizeof(double)];
        longIndicatorArray = (double *)[longIndicatorData mutableBytes];
        
        marginUsedData = [[NSMutableData alloc] initWithLength:arraySize * sizeof(double)];
        marginUsedArray = (double *)[marginUsedData mutableBytes];
        
        marginAvailableData = [[NSMutableData alloc] initWithLength:arraySize * sizeof(double)];
        marginAvailableArray = (double *)[marginAvailableData mutableBytes];
        
        marginCloseOutData = [[NSMutableData alloc] initWithLength:arraySize * sizeof(double)];
        marginCloseOutArray = (double *)[marginCloseOutData mutableBytes];
        
        cashPositionData = [[NSMutableData alloc] initWithLength:arraySize * sizeof(double)];
        cashPositionArray = (double *)[cashPositionData mutableBytes];
        
        navData = [[NSMutableData alloc] initWithLength:arraySize * sizeof(double)];
        navArray = (double *)[navData mutableBytes];
        
        spreadCostData = [[NSMutableData alloc] initWithLength:arraySize * sizeof(double)];
        spreadCostArray = (double *)[spreadCostData mutableBytes];
        
        drawDownData = [[NSMutableData alloc] initWithLength:arraySize * sizeof(double)];
        drawDownArray = (double *)[drawDownData mutableBytes];
        
        positionAvePriceData = [[NSMutableData alloc] initWithLength:arraySize * sizeof(double)];
        positionAvePriceArray = (double *)[positionAvePriceData mutableBytes];
        //
        
        
        
        simulationDataDictionary = [[NSMutableDictionary alloc] initWithCapacity:[simDataFieldNames count]];
        simulationDataArrayData = [[NSMutableData alloc] initWithLength:[simDataFieldNames count] * sizeof(double*)];
        simulationDataArray = (double **)[simulationDataArrayData mutableBytes];
        for(int fieldIndex = 0; fieldIndex < [simDataFieldNames count]; fieldIndex++){
            [simulationDataDictionary setObject:[[NSMutableData alloc] initWithLength:arraySize * sizeof(double)] forKey:[simDataFieldNames objectAtIndex:fieldIndex]];
            simulationDataArray[fieldIndex] = [[simulationDataDictionary objectForKey:[simDataFieldNames objectAtIndex:fieldIndex]] mutableBytes];
        }
    }
    
    if(![self cancelProcedure]){
        if(!preloadedData){
            //This ensures that ac variables are similar and there is no problems
            // due to not getting the first price, which may be slightly older
            // than the start time of the simulation
            dataRequestMinDateTime = [simulation dataStartDateTime] - 3 * timeStep;
            dataRequestMaxDateTime = endDateTime;
            extraRequiredVariables = [SimulationController getNamesOfRequiredVariablesForSignal: [simulation signalSystem]
                                                                                 AndPositioning: [simulation positionSystem]
                                                                                       AndRules: [simulation rulesSystem]];
            dataStoreIndex--;
            if([self doThreads] && dataStoreIndex >= 0 && doDatabaseProgress){
                [self performSelectorOnMainThread:@selector(readingDatabaseOn) withObject:nil waitUntilDone:NO];
            }
            
            if(![[self dataController] getDataForStartDateTime: dataRequestMinDateTime
                                                AndEndDateTime: dataRequestMaxDateTime
                                             AndExtraVariables: extraRequiredVariables
                                               AndSignalSystem: [simulation signalSystem]
                                                   AndDataRate: dataRate
                                                 WithStoreCode: dataStoreIndex
                                      WithRequestTruncatedFlag: &dataRequestTruncated]){
                [NSException raise:@"Database problem"
                            format:nil];
            }
            
            if([self doThreads] && doDatabaseProgress){
                [self performSelectorOnMainThread:@selector(readingDatabaseOff) withObject:nil waitUntilDone:NO];
            }
        }
    }
    
    currentPosition = 0;
    currentPositionSign = 0;
    currentCashBalance = 0.0;
    currentMaximumNav = 0.0;
    
    if([[[simulation basicParameters] accCode] isEqualToString:[[simulation basicParameters] quoteCode]]){
        accountCurrencyIsQuoteCurrency = YES;
    }else{
        accountCurrencyIsQuoteCurrency = NO;
    }
    
    if([simulation numberOfBalanceAdjustments]>0){
        cashMoveIndex = 0;
        allCashMovesFinished = NO;
        cashMoveDetails = [simulation detailsOfBalanceAdjustmentIndex:cashMoveIndex];
        nextCashMoveDateTime = [[cashMoveDetails objectForKey:@"DATETIME"] longValue];
        nextCashMoveAmount = [[cashMoveDetails objectForKey:@"AMOUNT"] doubleValue];
        nextCashMoveReason = [cashMoveDetails objectForKey:@"REASON"];
    }else{
        nextCashMoveDateTime = 0;
        allCashMovesFinished = YES;
    }
    
    if([self doThreads]){
        [self performSelectorOnMainThread:@selector(progressBarOn) withObject:nil waitUntilDone:NO];
        [self performSelectorOnMainThread:@selector(progressAsFraction:)
                               withObject:[NSNumber numberWithDouble:0.06 ] waitUntilDone:NO];
    }
   
    if([simulation numberOfTrades] >0){
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
        //signal = exposureAfterTrade < 0 ? -1 : 1;
    }else{
        nextTradeDateTime = 0;
        allTradesFinished = YES;
    }
    
    tradePnl = 0.0;
    interestCosts = 0.0;
    largestDrawdown = 0.0;
    
    double signal, signalLowerThreshold, signalUpperThreshold;
    NSInteger positiveSignalTime = 0.0, totalSignalTime = 0.0, negativeSignalTime = 0.0;
    currentDateTime = 0;
    // Main loop
    for(int dateIndex = 0; dateIndex < [dateTimesOfAnalysis count]; dateIndex++)
    {
        previousDateTime = currentDateTime;
        currentDateTime = [[dateTimesOfAnalysis objectAtIndex:dateIndex] longValue];
        
        
            
        
        // Update the database if needed
        if(currentDateTime > [[self dataController] getMaxDateTimeForLoadedData])
        {
            if([self doThreads] && dataStoreIndex >= 0 && doDatabaseProgress){
                [self performSelectorOnMainThread:@selector(readingDatabaseOn) withObject:nil waitUntilDone:NO];
            }
            dataRequestMinDateTime = [[self dataController] getMaxDateTimeForLoadedData] - 3*timeStep;
            dataRequestMaxDateTime = MAX(currentDateTime,endDateTime);
            dataStoreIndex--;
            [[self dataController] getDataForStartDateTime: dataRequestMinDateTime
                                            AndEndDateTime: dataRequestMaxDateTime
                                         AndExtraVariables: extraRequiredVariables
                                           AndSignalSystem: [simulation signalSystem]
                                               AndDataRate: dataRate
                                             WithStoreCode: dataStoreIndex
                                  WithRequestTruncatedFlag: &dataRequestTruncated];
            if([self doThreads] && doDatabaseProgress){
                [self performSelectorOnMainThread:@selector(readingDatabaseOff)
                                       withObject:nil
                                    waitUntilDone:NO];
            }
        }
        
        // Get the price data values for today
        currentDataValues = [[self dataController] getValues:simDataFieldNames
                                                  AtDateTime:currentDateTime];
        
        for(int fieldIndex = 0; fieldIndex < [simDataFieldNames count]; fieldIndex++){
            simulationDataArray[fieldIndex][dateIndex] = [[currentDataValues objectForKey:[simDataFieldNames objectAtIndex:fieldIndex]] doubleValue];
        }
        
        currentBid = [[currentDataValues objectForKey:@"BID"] doubleValue];
        currentAsk = [[currentDataValues objectForKey:@"ASK"] doubleValue];
        
        signal = [[currentDataValues objectForKey:@"SIGNAL"] doubleValue];
        signalLowerThreshold = [[currentDataValues objectForKey:@"SIGLTHRES"] doubleValue];
        signalUpperThreshold = [[currentDataValues objectForKey:@"SIGUTHRES"] doubleValue];
        
        if(dateIndex > 0 ){
   
            totalSignalTime = totalSignalTime + MIN(timeStep, currentDateTime- previousDateTime);
            
            if(signal < signalLowerThreshold)
            {
                negativeSignalTime = negativeSignalTime+ MIN(timeStep, currentDateTime- previousDateTime);
            }
            if(signal > signalUpperThreshold)
            {
                positiveSignalTime = positiveSignalTime+ MIN(timeStep, currentDateTime- previousDateTime);
            }
 
        }
        
        
        //Add in the trades and any cash moves
        if(currentDateTime == nextTradeDateTime){
            //                if([UtilityFunctions signOfInt:currentPosition] != [UtilityFunctions signOfInt:currentPosition + nextTradeAmount]){
            //                    NSLog(@"Trading from %d to %d",currentPosition, currentPosition + nextTradeAmount);
            //                }
            
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
                //signal = exposureAfterTrade < 0 ? -1 : 1;
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
        
//        if(currentDateTime >= signalStartDateTime && currentDateTime < signalEndDateTime){
//            currentSignal = signal;
//        }else{
//            currentSignal = 0.0;
//        }
        
        dateTimesArray[dateIndex] = currentDateTime;
        //signalArray[dateIndex] = currentSignal;
        marketPositionArray[dateIndex] = (double)currentPosition;
        
        shortIndicatorArray[dateIndex] = ([UtilityFunctions signOfInt:currentPosition] < 0)? (double) -currentPosition: 0.0;
        longIndicatorArray[dateIndex] =  ([UtilityFunctions signOfInt:currentPosition] > 0)? (double) currentPosition: 0.0;
        
        // If there has been a trade one indicator will stop at t-1 and another start at time t
        // as these indictors are for plots better to join up the indicator for better visuals
        if(dateIndex > 0 ){
            //There has been a trade at this time
            if(marketPositionArray[dateIndex] != marketPositionArray[dateIndex-1] ){
                if(marketPositionArray[dateIndex] > 0){
                    shortIndicatorArray[dateIndex] = shortIndicatorArray[dateIndex-1];
                    //Going from 0 to a position
                    if(fabs(marketPositionArray[dateIndex-1])<1){
                        longIndicatorArray[dateIndex] = 0.0;
                    }
                }
                if(marketPositionArray[dateIndex] < 0){
                    longIndicatorArray[dateIndex] = longIndicatorArray[dateIndex-1];
                    //Going from 0 to a position
                    if(fabs(marketPositionArray[dateIndex-1])<1){
                        shortIndicatorArray[dateIndex] = 0.0;
                    }
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
        spreadCostArray[dateIndex] = spreadCost;
        
        currentMaximumNav = ( navArray[dateIndex] > currentMaximumNav ) ? navArray[dateIndex] : currentMaximumNav;
        
        drawDownArray[dateIndex] = MIN(0,navArray[dateIndex]-currentMaximumNav);
        if(drawDownArray[dateIndex] < largestDrawdown){
            largestDrawdown = drawDownArray[dateIndex];
            largestDrawdownDateTime = currentDateTime;
        }
        if([self doThreads]){
            [self performSelectorOnMainThread:@selector(progressAsFraction:) withObject:[NSNumber   numberWithDouble:MAX(0.08,(double)(currentDateTime-startDateTime)/(endDateTime-startDateTime))  ] waitUntilDone:NO];
        }
        int checkPosition =  0 ;
        for(int i = 0; i < [positionAmount count]; i++){
            checkPosition = checkPosition + [[positionAmount objectAtIndex:i] intValue];
        }
        if(checkPosition != currentPosition){
            NSLog(@"Check: %ld - %d - %d",currentDateTime, currentPosition, checkPosition);
        }
    }//end of main sim
    
    
   
    
    NSMutableArray *monthlyNavChange = [[NSMutableArray alloc] init];
    BOOL fullMonth = NO;
    double oldNav = 0.0, monthReturn = 0.0, monthReturnSumForCalc = 0.0, monthReturnMeanForCalc = 0.0;
    long nextDateTime = [[dateTimesOfAnalysis objectAtIndex:0] longValue];
    int nextDateTimeMonth = [EpochTime monthNumberOfDateTime:nextDateTime];
    int currentDateTimeMonth;
    long numberOfDates = [dateTimesOfAnalysis count];
    long longestDrawdown = 0, drawDownStartTime = 0, longestDrawdownDateTime;
    
    for(int dateIndex = 0; dateIndex < (numberOfDates -1); dateIndex++)
    {
        //Calmar Ratio
        //Downside Deviation
        //Efficiency Index
        //Sharpe Ratio
        //Sortino Ratio
        //Standard Deviation
        //Sterling Ratio
        currentDateTime = nextDateTime;
        currentDateTimeMonth = nextDateTimeMonth;
        nextDateTime = dateTimesArray[dateIndex + 1];
        nextDateTimeMonth = [EpochTime monthNumberOfDateTime:nextDateTime];
        
        if(currentDateTimeMonth != nextDateTimeMonth){
            if(!fullMonth){
                // if hte first month is not full but at least 21 calendar days, its ok to use
                if(((nextDateTime - dateTimesArray[0]))/(24 * 60 * 60) > 20){
                    fullMonth = YES;
                }
            }
            if(fullMonth){
                monthReturn = navArray[dateIndex+1]-oldNav;
                [monthlyNavChange addObject:[NSNumber numberWithDouble:monthReturn]];
                monthReturnSumForCalc = monthReturnSumForCalc + monthReturn;
            }else{
                fullMonth = YES;
            }
            oldNav = navArray[dateIndex];
        }
        if(drawDownArray[dateIndex] < 0){
            if(dateIndex == 0){
                drawDownStartTime = drawDownArray[0];
            }else{
                if(drawDownArray[dateIndex-1]>=0){
                    drawDownStartTime = dateTimesArray[dateIndex];
                }
            }
        }else{
            if(dateIndex > 0 && drawDownStartTime > 0){
                if(drawDownArray[dateIndex-1] < 0){
                    if( dateTimesArray[dateIndex-1] - drawDownStartTime > longestDrawdown){
                        longestDrawdown = dateTimesArray[dateIndex-1] - drawDownStartTime;
                        longestDrawdownDateTime = dateTimesArray[dateIndex-1];
                    }
                }
            }
        }
    }
    
    double returnsSD = 0.0, downsideSD = 0.0;
    long returnsCount, downsideCount = 0;
    double proportionPositive = 0;
    double drawDownInMeanMonthRet = 0.0;
    double sharpeRatio = 0.0, sortinoRatio = 0.0;
    
    returnsCount = [monthlyNavChange count];
    if(returnsCount>2){
        monthReturnMeanForCalc = monthReturnSumForCalc/[monthlyNavChange count];
        for(int i = 0;i < [monthlyNavChange count];i++){
            returnsSD = returnsSD + pow([[monthlyNavChange objectAtIndex:i] doubleValue] - monthReturnMeanForCalc,2.0);
            if([[monthlyNavChange objectAtIndex:i] doubleValue] < 0){
                downsideSD = downsideSD + pow([[monthlyNavChange objectAtIndex:i] doubleValue] - monthReturnMeanForCalc,2.0);
                downsideCount++;
            }else{
                proportionPositive++;
            }
        }
        proportionPositive = proportionPositive /returnsCount;
        returnsSD = sqrt(returnsSD/(returnsCount-1));
        downsideSD = sqrt(downsideSD/(downsideCount-1));
    
        drawDownInMeanMonthRet = largestDrawdown/ monthReturnMeanForCalc;
    
        sharpeRatio = sqrt(12.0)*(monthReturnSumForCalc/returnsCount)/returnsSD;
        sortinoRatio = sqrt(12.0)*(monthReturnSumForCalc/returnsCount)/downsideSD;
    }
    
    NSDictionary *signalDetails;
    int startIndex = 0, endIndex = 0;
    long startTime, endTime;
    double estimatedPnl = 0.0;
    for(NSUInteger signalIndex = 0; signalIndex < [simulation numberOfSignals]; signalIndex++){
        signalDetails = [simulation detailsOfSignalAtIndex:signalIndex];
        startTime = [[signalDetails objectForKey:@"ENTRYTIME"] longValue];
        endTime = [[signalDetails objectForKey:@"EXITTIME"] longValue];
        while([[dateTimesOfAnalysis objectAtIndex:startIndex] longValue] < startTime){
            startIndex++;
        }
        while([[dateTimesOfAnalysis objectAtIndex:endIndex] longValue] < endTime){
            endIndex++;
        }
        estimatedPnl = navArray[endIndex]-navArray[startIndex];
        [simulation addToSignalInfoAtIndex:signalIndex EstimatedPnl:estimatedPnl];
    }
    
    [self performSelectorOnMainThread:@selector(progressBarOff) withObject:nil waitUntilDone:NO];
    
    if(![self cancelProcedure])
    {
        if(!allTradesFinished ){
            [NSException raise:@"All trades were not included for some reason!" format:nil];
        }
        if(!allCashMovesFinished ){
            [NSException raise:@"All cash transactions were not included for some reason!" format:nil];
        }
        
        [simulationDataDictionary setObject:marketPositionData forKey:@"POSITION"];
        [simulationDataDictionary setObject:cashPositionData forKey:@"CASHBALANCE"];
        [simulationDataDictionary setObject:navData forKey:@"NAV"];
        [simulationDataDictionary setObject:spreadCostData forKey:@"SPREADCOST"];
        [simulationDataDictionary setObject:drawDownData forKey:@"DRAWDOWN"];
        [simulationDataDictionary setObject:marginUsedData forKey:@"MARGINUSED"];
        [simulationDataDictionary setObject:marginAvailableData forKey:@"MARGINAVAIL"];
        [simulationDataDictionary setObject:marginCloseOutData forKey:@"CLOSEOUT"];
        [simulationDataDictionary setObject:shortIndicatorData forKey:@"SHORT"];
        [simulationDataDictionary setObject:longIndicatorData forKey:@"LONG"];
        [simulationDataDictionary setObject:positionAvePriceData forKey:@"POSAVEPRICE"];
        
        positionDataSeries = [[self dataController] createNewDataSeriesWithXData: dateTimesData
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
                                          ForKey:@"DEEPESTDRAWDOWN"];
        [simulation addObjectToSimulationResults:[NSNumber numberWithLong:largestDrawdownDateTime]
                                          ForKey:@"DEEPESTDRAWDOWNTIME"];
        [simulation addObjectToSimulationResults:[NSNumber numberWithLong:longestDrawdown]
                                          ForKey:@"LONGESTDRAWDOWN"];
        [simulation addObjectToSimulationResults:[NSNumber numberWithLong:longestDrawdownDateTime]
                                          ForKey:@"LONGESTDRAWDOWNTIME"];
        [simulation addObjectToSimulationResults:[NSNumber numberWithLong:drawDownInMeanMonthRet]
                                          ForKey:@"DRAWDOWN AS AVE MONTH"];
        [simulation addObjectToSimulationResults:[NSNumber numberWithDouble:proportionPositive]
                                          ForKey:@"MONTHS POSITIVE"];
        if(returnsCount > 2){
            [simulation addObjectToSimulationResults:[NSNumber numberWithDouble:sharpeRatio]
                                             ForKey:@"SHARPE RATIO"];
        }
        if(downsideCount > 2){
            [simulation addObjectToSimulationResults:[NSNumber numberWithDouble:sortinoRatio]
                                              ForKey:@"SORTINO RATIO"];
        }
        [simulation addObjectToSimulationResults:[NSNumber numberWithDouble:(double)negativeSignalTime/totalSignalTime]
                                          ForKey:@"TIME SIG NEG"];
        [simulation addObjectToSimulationResults:[NSNumber numberWithDouble:(double)positiveSignalTime/totalSignalTime]
                                          ForKey:@"TIME SIG POS"];

        
    }
    
    if(![self cancelProcedure])
    {
        [simulation setAnalysisDataSeries:positionDataSeries];
        [simulation setIsAnalysed:YES];
        
        [self performSelectorOnMainThread:@selector(registerSimulation:) withObject:simulation waitUntilDone:YES];
        
        
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
}


- (BOOL) checkSignalAndAdjustPositionAtTime: (long) simulationDateTime
                              ForSimulation: (Simulation *) simulation
                      doNotIncreasePosition: (BOOL) doNotIncrease
                                 doCloseout: (BOOL) doCloseOut
{
    double  bid, ask;
    NSDictionary *values;
    double unrealisedPnl = 0.0;
    double marginUsed = 0.0;
    BOOL accountCurrencyIsQuoteCurrency;
    double nav, debits;
    double marginAvailable = 0.0;
    int requiredPositionSize = 0;
    BOOL marginCloseOut = NO;
    
    
//    if(simulationDateTime == 1076050800 || simulationDateTime == 1076058000){
//        NSLog(@"Check");
//    }
    
    if([[[simulation basicParameters] accCode] isEqualToString:[[simulation basicParameters] quoteCode]]){
        accountCurrencyIsQuoteCurrency = YES;
    }else{
        accountCurrencyIsQuoteCurrency = NO;
    }
    
    values = [[self dataController] getValues: [NSArray arrayWithObjects:@"BID", @"ASK", nil]
                               AtDateTime: simulationDateTime ];
    
    if(![[values objectForKey:@"SUCCESS"] boolValue])
    {
        [NSException raise: @"Data Problem in getValuesForFields" format:@"datetime %ld",simulationDateTime];
    }
    
    if(doCloseOut){
        debits = [self setExposureToUnits: 0
                               AtTimeDate: simulationDateTime + [simulation tradingLag]
                            ForSimulation: simulation
                          ForSignalAtTime: simulationDateTime];
        [self setCashPosition:[self cashPosition] + debits];
        nav = [self cashPosition];
        NSString *userMessage = [NSString stringWithFormat:@"%@ Closeout of position  -- NAV: %5.2f %@ \n",[EpochTime stringDateWithTime:simulationDateTime + [simulation tradingLag]], nav,[simulation accCode]];
        [[[simulation simulationRunOutput] mutableString] appendString:userMessage];
        if([self doThreads]){
            [self performSelectorOnMainThread:@selector(outputSimulationMessage:) withObject:userMessage waitUntilDone:NO];
        }else{
            [self outputSimulationMessage:userMessage];
        }

    }else{
        bid = [[values objectForKey:@"BID"] doubleValue];
        ask =  [[values objectForKey:@"ASK"] doubleValue];
        
        //This part deals with turning signal in a position
      
        // Check our margin available before we can trade
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
        nav = [self cashPosition] + unrealisedPnl;
        marginAvailable = nav - marginUsed;
            
        requiredPositionSize = [self getRequiredExposureForSimulation: simulation
                                                               AtTime: simulationDateTime
                                                              WithNav: nav];
       
        if(doNotIncrease){
            if([simulation currentExposure] == 0){
                requiredPositionSize = 0;
            }
            if([simulation currentExposure] > 0)
            {
                if(requiredPositionSize > [simulation currentExposure])
                {
                    requiredPositionSize = [simulation currentExposure];
                }
                if(requiredPositionSize < 0)
                {
                    requiredPositionSize = 0;
                }
            }
            if([simulation currentExposure] < 0)
            {
                if(requiredPositionSize < [simulation currentExposure])
                {
                    requiredPositionSize = [simulation currentExposure];
                }
                if(requiredPositionSize > 0)
                {
                    requiredPositionSize = 0;
                }
            }
        }
        
        if(requiredPositionSize != [simulation currentExposure]){
            int keepCurrentExposure = [simulation currentExposure];
            
            debits = [self setExposureToUnits: requiredPositionSize
                                   AtTimeDate: simulationDateTime + [simulation tradingLag]
                                ForSimulation: simulation
                              ForSignalAtTime: simulationDateTime];
            
            [self setCashPosition:[self cashPosition] + debits];
            nav = [self cashPosition];
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
            nav = [self cashPosition] + unrealisedPnl;
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
        
        if((marginUsed/2) >= nav && ![simulation unfunded]){
            marginCloseOut = YES;
        }
    }        
    return !marginCloseOut;            
            
}
      
-(int)getRequiredExposureForSimulation: (Simulation *) simulation
                                AtTime: (long) currentDateTime
                               WithNav: (double) nav
{
    int requiredExposure = 0;
    NSString *userMessage;
    PositioningSystem *posSys = [simulation positionSystem];
    NSArray *fieldNames = [[self dataController] getFieldNames];
    NSDictionary *values = [[self dataController] getValues: fieldNames
                                                 AtDateTime:currentDateTime ];
    
    double bid, ask, mid, dataSignal;
    bid = [[values objectForKey:@"BID"] doubleValue];
    ask =  [[values objectForKey:@"ASK"] doubleValue];
    mid =  [[values objectForKey:@"MID"] doubleValue];
    dataSignal = [[values objectForKey:@"SIGNAL"] doubleValue];
    BOOL zeroPositionRequired = NO;
    
    
    if([posSys exitOnBrem]){
        if([simulation currentExposure] != 0){
            double threshold =[posSys exitOnBremThreshold] * [[[self dataController] dataSeries] pipSize];
            long entryTime = [simulation dateTimeOfEarliestPosition];
            NSDictionary *trailingValues = [[self dataController] getValues: fieldNames
                                                                 AtDateTime: entryTime];
            
            double startOfExposureBrem = [[trailingValues objectForKey:[posSys bremString]] doubleValue];
            double currentBrem = [[values objectForKey:[posSys bremString]] doubleValue];
            if([simulation currentExposure] > 0 && currentBrem-startOfExposureBrem < -threshold){
                requiredExposure = 0;
                zeroPositionRequired = YES;
            }
            if([simulation currentExposure] < 0 && currentBrem-startOfExposureBrem > threshold){
                requiredExposure = 0;
                zeroPositionRequired = YES;
            }
        
        }
    }
    
    
    if([posSys exitOnWeakeningPrice]){
        if([simulation currentExposure] != 0){
            double entryPrice = [simulation wgtAverageCostOfPosition];
            if([simulation currentExposure] > 0 && bid - entryPrice < -[posSys exitOnWeakeningPriceThreshold]){
                requiredExposure = 0;
                zeroPositionRequired = YES;
                userMessage = [NSString stringWithFormat:@"%@ Closing position; Price weakening \n",[EpochTime stringDateWithTime:currentDateTime]];
                [[[simulation simulationRunOutput] mutableString] appendString:userMessage];
                if([self doThreads]){
                    [self performSelectorOnMainThread:@selector(outputSimulationMessage:) withObject:userMessage waitUntilDone:NO];
                }
            }
            if([simulation currentExposure] < 0 && ask - entryPrice >  [posSys exitOnWeakeningPriceThreshold]){
                requiredExposure = 0;
                zeroPositionRequired = YES;
                userMessage = [NSString stringWithFormat:@"%@ Closing position; Price weakening \n",[EpochTime stringDateWithTime:currentDateTime]];
                [[[simulation simulationRunOutput] mutableString] appendString:userMessage];
                if([self doThreads]){
                    [self performSelectorOnMainThread:@selector(outputSimulationMessage:) withObject:userMessage waitUntilDone:NO];
                }

            }
        }
    }
    
    if((!zeroPositionRequired) &&  [posSys stopEntryOnWeakeningPrice]){
        BOOL weakeningPriceOverride = NO;
        long lagTime = [posSys stopEntryOnWeakeningPriceLagTime];
        double threshold = [posSys stopEntryOnWeakeningPriceThreshold];
        
        NSDictionary *trailingValues = [[self dataController] getValues: fieldNames
                                                             AtDateTime: currentDateTime - lagTime ];
        double trailingPrice = [[trailingValues objectForKey:@"MID"] doubleValue];
        
        threshold = [posSys stopEntryOnWeakeningPriceThreshold] * [[[self dataController] dataSeries] pipSize];
        if(dataSignal > 0){
            if(mid < (trailingPrice - threshold)){
                weakeningPriceOverride = YES;
                //NSLog(@"Weakening Price Override");
            }
        }
        if(dataSignal < 0){
            if(mid > (trailingPrice + threshold)){
                weakeningPriceOverride = YES;
                //NSLog(@"Weakening Price Override");
            }
        }
        if(weakeningPriceOverride && [simulation currentExposure]==0){
            requiredExposure = 0;
            zeroPositionRequired = YES;
            userMessage = [NSString stringWithFormat:@"%@ Preventing position opening; Price weakening \n",[EpochTime stringDateWithTime:currentDateTime]];
            [[[simulation simulationRunOutput] mutableString] appendString:userMessage];
            if([self doThreads]){
                [self performSelectorOnMainThread:@selector(outputSimulationMessage:) withObject:userMessage waitUntilDone:NO];
            }
        }
     }
    
    
    if((!zeroPositionRequired) &&  [posSys stopEntryOnWeakeningSignal]){
        BOOL weakeningSignalOverride = NO;
        long lagTime = [posSys stopEntryOnWeakeningSignalLagTime];
        double adjustedThreshold;
        
        NSDictionary *trailingValues = [[self dataController] getValues: fieldNames
                                                             AtDateTime:currentDateTime - lagTime ];
        double trailingDataSignal = [[trailingValues objectForKey:@"SIGNAL"] doubleValue];
        
        adjustedThreshold = [posSys stopEntryOnWeakeningSignalThreshold] * [[[self dataController] dataSeries] pipSize];
        if(dataSignal > 0){
            if(dataSignal < (trailingDataSignal - adjustedThreshold)){
                weakeningSignalOverride = YES;
                //NSLog(@"weakening Signal Override");
            }
        }
        if(dataSignal < 0){
            if(dataSignal > (trailingDataSignal + adjustedThreshold)){
                weakeningSignalOverride = YES;
                //NSLog(@"weakening Signal Override");
            }
        }
        if(weakeningSignalOverride && [simulation currentExposure]==0){
            requiredExposure = 0;
            zeroPositionRequired = YES;
            userMessage = [NSString stringWithFormat:@"%@ Preventing position opening; Signal weakening \n",[EpochTime stringDateWithTime:currentDateTime]];
            [[[simulation simulationRunOutput] mutableString] appendString:userMessage];
            if([self doThreads]){
                [self performSelectorOnMainThread:@selector(outputSimulationMessage:) withObject:userMessage waitUntilDone:NO];
            }
        }
    }
     
    if(!zeroPositionRequired){
        if([[posSys type] isEqualToString:@"STP"] || [[posSys type] isEqualToString:@"STAT"] || [[posSys type] isEqualToString:@"ASTAT"] || [[posSys type] isEqualToString:@"SEMAD"]){
            //double adjustedThreshold;
            double adjustedThresholdIn, adjustedThresholdOut;
            int targetAbsolutePositionSize = 0;
            BOOL accountCurrencyIsQuoteCurrency;
            double pipSize = [[[self dataController] dataSeries] pipSize];
            if([[posSys type] isEqualToString:@"ASTAT"]){
                adjustedThresholdIn = [posSys signalInThreshold] * pipSize;
                adjustedThresholdOut = [posSys signalOutThreshold] * pipSize;
            }else{
                adjustedThresholdIn = [posSys signalThreshold] * pipSize;
                adjustedThresholdOut = adjustedThresholdIn;
            }
            
            
            
            //Get a handle on an target position size
            if([[[simulation basicParameters] accCode] isEqualToString:[[simulation basicParameters] quoteCode]]){
                accountCurrencyIsQuoteCurrency = YES;
            }else{
                accountCurrencyIsQuoteCurrency = NO;
            }
            
            if([[posSys type] isEqualToString:@"STP"]){
                if(accountCurrencyIsQuoteCurrency){
                    targetAbsolutePositionSize =  (int)floor((1-[posSys positionCushion]) * nav/ask * [[simulation basicParameters] maxLeverage]);
                }else{
                    targetAbsolutePositionSize =  (int)floor((1-[posSys positionCushion]) * nav * [[simulation basicParameters] maxLeverage]);
                }
            }
            
            if( [[posSys type] isEqualToString:@"STAT"] ||  [[posSys type] isEqualToString:@"SEMAD"] ||  [[posSys type] isEqualToString:@"ASTAT"] ){
                if([simulation unfunded]){
                    targetAbsolutePositionSize = [posSys maxPos];
                }else{
                    if(accountCurrencyIsQuoteCurrency){
                        targetAbsolutePositionSize =  (int)floor(nav/ask * [[simulation basicParameters] maxLeverage]);
                    }else{
                        targetAbsolutePositionSize =  (int)floor(nav * [[simulation basicParameters] maxLeverage]);
                    }
                    targetAbsolutePositionSize = MIN(targetAbsolutePositionSize,[posSys maxPos]);
                }
            }
            
            if([simulation currentExposure] == 0){
                requiredExposure = 0;
                if( dataSignal > adjustedThresholdIn){
                    requiredExposure = targetAbsolutePositionSize;
                }
                if(dataSignal < -adjustedThresholdIn){
                    requiredExposure = -targetAbsolutePositionSize;
                }
            }else{
                if([simulation currentExposure] > 0 && dataSignal < adjustedThresholdOut){
                    requiredExposure = 0;
                }else if([simulation currentExposure] < 0 && dataSignal > -adjustedThresholdOut){
                    requiredExposure = 0;
                }else{
                    requiredExposure = [simulation currentExposure];
                }
            }
           
            if( [[posSys type] isEqualToString:@"SEMAD"]){
                NSString *filterSeries = [NSString stringWithFormat:@"EMAD/%ld/%ld",[posSys emadFilterParam1],[posSys emadFilterParam2]];
                ;
                NSDictionary *filterValueDict = [[self dataController] getValues: [NSArray arrayWithObject:filterSeries]
                                                                     AtDateTime: currentDateTime
                                                                  WithTicOffset: 0];
                double filterValue = [[filterValueDict objectForKey:filterSeries] doubleValue];
                
                
                if([simulation currentExposure] >= 0 && requiredExposure < 0){
                    if(filterValue > ([posSys shortInFilterThreshold]*pipSize)){
                        requiredExposure = 0;
                        userMessage = [NSString stringWithFormat:@"%@ Preventing Short position opening because of Short Term Filter \n",[EpochTime stringDateWithTime:currentDateTime]];
                        [[[simulation simulationRunOutput] mutableString] appendString:userMessage];
                        if([self doThreads]){
                            [self performSelectorOnMainThread:@selector(outputSimulationMessage:) withObject:userMessage waitUntilDone:NO];
                        }
                    }
                }else if([simulation currentExposure] < 0 && requiredExposure < 0){
                    if(filterValue > ([posSys shortOutFilterThreshold]*pipSize)){
                        requiredExposure = 0;
                        userMessage = [NSString stringWithFormat:@"%@ Closing Short position because of Short Term Filter \n",[EpochTime stringDateWithTime:currentDateTime]];
                        [[[simulation simulationRunOutput] mutableString] appendString:userMessage];
                        if([self doThreads]){
                            [self performSelectorOnMainThread:@selector(outputSimulationMessage:) withObject:userMessage waitUntilDone:NO];
                        }

                    }
                }else if([simulation currentExposure] <= 0 && requiredExposure > 0){
                    if(filterValue < ([posSys longInFilterThreshold]*pipSize)){
                        requiredExposure = 0;
                        userMessage = [NSString stringWithFormat:@"%@ Preventing Long position opening because of Short Term Filter \n",[EpochTime stringDateWithTime:currentDateTime]];
                        [[[simulation simulationRunOutput] mutableString] appendString:userMessage];
                        if([self doThreads]){
                            [self performSelectorOnMainThread:@selector(outputSimulationMessage:) withObject:userMessage waitUntilDone:NO];
                        }
                    }
                }else if([simulation currentExposure] > 0 && requiredExposure > 0){
                    if(filterValue < ([posSys longOutFilterThreshold]*pipSize)){
                        requiredExposure = 0;
                        userMessage = [NSString stringWithFormat:@"%@ Closing Long position because of Short Term Filter \n",[EpochTime stringDateWithTime:currentDateTime]];
                        [[[simulation simulationRunOutput] mutableString] appendString:userMessage];
                        if([self doThreads]){
                            [self performSelectorOnMainThread:@selector(outputSimulationMessage:) withObject:userMessage waitUntilDone:NO];
                        }
                    }
                }
            }
        }
        
        
        if([[posSys type] isEqualToString:@"SFP"]){
            double adjustedThreshold = [posSys signalThreshold] * [[[self dataController] dataSeries] pipSize];;
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
            
            NSString *signalPerfField = [NSString stringWithFormat:@"EMA/%d",perfSmoothParam];
            
            
            int targetAbsolutePositionSize;
            BOOL accountCurrencyIsQuoteCurrency;

            fieldNames = [NSArray arrayWithObjects:signalPerfField, nil];
            NSDictionary *trailingValues = [[self dataController] getValues: fieldNames
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
    double amount;
    NSString *reason;
    performanceAttribution = [simulation getPerformanceAttribution];
    if([performanceAttribution objectForKey:@"LASTBALANCE"] != nil){
        amount = [[performanceAttribution objectForKey:@"LASTBALANCE"] doubleValue];
        perfAttribMessage = [NSString stringWithFormat:@"Final balance is: %5.2f     \n",amount];
        [[[simulation simulationRunOutput] mutableString] appendString:perfAttribMessage];
        if([self doThreads]){
            [self performSelectorOnMainThread:@selector(outputSimulationMessage:) withObject:perfAttribMessage waitUntilDone:NO];
        }

    }
    
    perfAttribKeys = [performanceAttribution allKeys];
    for(int i = 0; i < [perfAttribKeys count]; i++){
        if(![[perfAttribKeys objectAtIndex:i] isEqualToString:@"LASTBALANCE"]){
            amount = [[performanceAttribution objectForKey:[perfAttribKeys objectAtIndex:i]] doubleValue];
            reason = [perfAttribKeys objectAtIndex:i];
            perfAttribMessage = [NSString stringWithFormat:@"Final balance component: %5.2f     due to: %@ \n",amount,reason];
            [[[simulation simulationRunOutput] mutableString] appendString:perfAttribMessage];
            if([self doThreads]){
                [self performSelectorOnMainThread:@selector(outputSimulationMessage:) withObject:perfAttribMessage waitUntilDone:NO];
            }
        }
    }
}
        
        
- (NSArray *) getInterestRateDataFor:(NSString *) baseCode And: (NSString *) quoteCode
{
    NSArray *interestRateSeries; 
    if([[self interestRates] objectForKey:[NSString stringWithFormat:@"%@IRBID",baseCode]] == nil){
        interestRateSeries = [[self dataController] getAllInterestRatesForCurrency:baseCode 
                                                                      AndField:@"BID"];
        [[self interestRates] setValue:interestRateSeries forKey:[NSString stringWithFormat:@"%@IRBID",baseCode]];
    }
    if([[self interestRates] objectForKey:[NSString stringWithFormat:@"%@IRASK",baseCode]] == nil){
        interestRateSeries = [[self dataController] getAllInterestRatesForCurrency:baseCode 
                                                                      AndField:@"ASK"];
        [[self interestRates] setValue:interestRateSeries forKey:[NSString stringWithFormat:@"%@IRASK",baseCode]];
    }    
    if([[self interestRates] objectForKey:[NSString stringWithFormat:@"%@IRBID",quoteCode]] == nil){
        interestRateSeries = [[self dataController] getAllInterestRatesForCurrency:quoteCode 
                                                                      AndField:@"BID"];
        [[self interestRates] setValue:interestRateSeries forKey:[NSString stringWithFormat:@"%@IRBID",quoteCode]];
    }
    if([[self interestRates] objectForKey:[NSString stringWithFormat:@"%@IRASK",quoteCode]] == nil){
        interestRateSeries = [[self dataController] getAllInterestRatesForCurrency:quoteCode
                                                                      AndField:@"ASK"];
        [[self interestRates] setValue:interestRateSeries forKey:[NSString stringWithFormat:@"%@IRASK",quoteCode]];
    } 
    return interestRateSeries;
}
        
        
- (double) calculateInterestForSimulation: (Simulation *) simulation 
                               ToDateTime: (long) endDateTime
{
    NSArray *borrowingInterestRates;
    NSArray *lendingInterestRates;
    
    NSString *borrowingCode;
    NSString *lendingCode; 
    NSString *accBaseCode, *accQuoteCode;
    double accBaseAskPrice,accQuoteAskPrice;
    double interestAccrued = 0.0;
    
    if([simulation currentExposure] !=0)
    {
        NSArray *fieldNames = [NSArray arrayWithObjects:@"BID",@"ASK",nil];
        NSDictionary *dataBaseValues = [[self dataController] getValues: fieldNames
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
        
        if([simulation currentExposure] >0)
        {
            borrowingCode = [[simulation basicParameters] baseCode];
            lendingCode = [[simulation basicParameters] quoteCode];
        }else{
            borrowingCode = [[simulation basicParameters] quoteCode];
            lendingCode = [[simulation basicParameters] baseCode];
        }
    
        borrowingInterestRates = [[self interestRates] objectForKey:[NSString stringWithFormat:@"%@IRASK",borrowingCode]];
        lendingInterestRates = [[self interestRates] objectForKey:[NSString stringWithFormat:@"%@IRBID",lendingCode]];
    
        long positionInterestDateTime;
        double positionEntryPrice;
        int positionSize;
        double interestRate = 0.0;
        long interestRateStart  = 0.0, interestRateEnd  = 0.0;
    
    
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
    NSDictionary *dataBaseValues = [[self dataController] getValues: fieldNames
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
            [derivedVariables addObject:[variablesForPositioning objectAtIndex:i]];
        }
    }
    if(rulesSystem != Nil){
        for(int j = 0; j < [rulesSystem count]; j++)
        {
            NSString *singleRule = [rulesSystem objectAtIndex:j];
            variablesForRules = [RulesSystem variablesNeeded:singleRule];
            for(int i = 0; i < [variablesForRules count]; i++){
                [derivedVariables addObject:[variablesForRules objectAtIndex:i]];
            }
        }
    }
    
    NSArray *sortedDerivedVariables = [derivedVariables sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
    NSMutableArray *uniqueSortedDerivedVariables = [[NSMutableArray alloc] init];
    [uniqueSortedDerivedVariables addObject:[sortedDerivedVariables objectAtIndex:0]];
    int endIndex = 0;
    for(int i = 1; i < [sortedDerivedVariables count];i++){
        if(![[sortedDerivedVariables objectAtIndex:i] isEqualToString:[uniqueSortedDerivedVariables objectAtIndex:endIndex]]){
            [uniqueSortedDerivedVariables addObject:[sortedDerivedVariables objectAtIndex:i]];
            endIndex++;
        }
    }
    
    return uniqueSortedDerivedVariables;
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
    NSDictionary *dataBaseValues = [[self dataController] getValues: fieldNames
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
     
-(BOOL)exportWorkingSimulation: (Simulation *) sim
                    DataToFile: (NSURL *) urlOfFile
{
    BOOL allOk;
    DataSeries* analysisData = [sim analysisDataSeries];
    allOk = [analysisData writeDataSeriesToFile:urlOfFile];
    return allOk;
}

- (BOOL) exportWorkingSimulationTrades: (Simulation *) sim
                                ToFile: (NSURL *) urlOfFile
{
    BOOL allOk;
    allOk = [sim writeTradesToFile:urlOfFile];
    return allOk;
}

- (BOOL) exportWorkingSimulationBalAdjmts: (Simulation *) sim
                                   ToFile: (NSURL *) urlOfFile
{
    BOOL allOk;
    allOk = [sim writeBalanceAdjustmentsToFile:urlOfFile];
    return allOk;
    
}

- (BOOL) exportWorkingSimulationReport:(Simulation *) sim
                                ToFile:(NSURL *) urlOfFile
{
    NSArray *dataFieldNames = [sim reportDataFieldsArray];
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
                lineOfFile = [NSString stringWithFormat:@"%@ , %@\r\n",[dataFieldNames objectAtIndex:fieldIndex],[sim getReportDataFieldAtIndex:fieldIndex]];
            }
            [outFile writeData:[lineOfFile dataUsingEncoding:NSUTF8StringEncoding]];
        }
        [outFile closeFile];
        
    }
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

- (void) readingRecordSetProgress: (NSNumber *) progressFraction
{
    if([[self delegate] respondsToSelector:@selector(readingRecordSetProgress:)])
    {
        [[self delegate] readingRecordSetProgress:progressFraction]; 
    }else{
        NSLog(@"Delegate doesn't respond to \'readingRecordSetProgress\'");
    }
}

- (void) readingRecordSetMessage: (NSString *) progressMessage
{
    if([[self delegate] respondsToSelector:@selector(readingRecordSetMessage:)])
    {
        [[self delegate] readingRecordSetMessage:progressMessage];
    }else{
        NSLog(@"Delegate doesn't respond to \'readingRecordSetMessage\'");
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


#pragma mark -
#pragma mark Variables 

@synthesize cancelProcedure = _cancelProcedure;
//@synthesize workingSimulation = _workingSimulation;
@synthesize doThreads = _doThreads;
@synthesize dataController = _dataController;
@synthesize cashPosition = _cashPosition;
@synthesize interestRates = _interestRates;
@synthesize loadAllData = _loadAllData;
@synthesize simulationRunning = _simulationRunning;
@end
