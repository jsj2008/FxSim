//
//  SimulationController.m
//  Simple Sim
//
//  Created by Martin O'Connor on 09/02/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "SimulationController.h"
#import "Simulation.h"
#import "DataController.h"
#import "DataSeriesValue.h"
#import "DataSeries.h"
#import "EpochTime.h"


#define DAY_SECONDS 24*60*60
#define THREADS YES
#define MAX_DATA_CHUNK 30*24*60*60
//6 Minutes to trade
#define STATIC_LAG 6*60
@interface SimulationController()
-(void)tradingSimulation:(NSDictionary *) parameters;
-(void) plotSimulationData:(DataSeries *) dataToPlot;
-(void) addSimulationDataToResultsTableView: (DataSeries *) analysisDataSeries;
@end




@implementation SimulationController
@synthesize currentSimulation;

-(id)init
{
    self = [super init];
    if(self){
        accounts = [[NSMutableDictionary alloc] init];
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

-(void)addAndTestAcc
{
    NSMutableDictionary *parameters = [[NSMutableDictionary alloc] init];
    NSString *baseCode = @"USD";
    NSString *quoteCode = @"JPY";
    //NSString *accCode = @"USD"; 
    
    NSString *tradingPair = [NSString stringWithFormat:@"%@%@",baseCode,quoteCode];
    long minDateTime = [marketData getMinDataDateTimeForPair:tradingPair];
    //long maxDateTime = [marketData getMaxDataDateTimeForPair:tradingPair];
   
    
    [parameters setObject:@"TEST" forKey:@"SIMNAME"];
    [parameters setObject:@"USD" forKey:@"BASECODE"];
    [parameters setObject:@"JPY" forKey:@"QUOTECODE"];
    [parameters setObject:@"USD" forKey:@"ACCOUNTCODE"];
    [parameters setObject:[NSNumber numberWithFloat:5000.0] forKey:@"STARTBALANCE"];
    [parameters setObject:[NSNumber numberWithFloat:20.0] forKey:@"MAXLEVERAGE"];
    [parameters setObject:[NSNumber numberWithLong:minDateTime] forKey:@"STARTTIME"];
    [parameters setObject:[NSNumber numberWithLong:(50*DAY_SECONDS)] forKey:@"SIMLENGTH"];
    [parameters setObject:[NSNumber numberWithLong:(28*DAY_SECONDS)] forKey:@"INITIALDATA"];
    [parameters setObject:[NSNumber numberWithInt:(30*60)] forKey:@"TIMESTEP"];
    //[parameters setObject:[NSNumber numberWithLong:20*DAY_SECONDS] forKey:@"DATACHUNK"];
    [parameters setObject:[NSNumber numberWithInt:(10*60)] forKey:@"TRADINGLAG"];
    
    if(THREADS){
        [self performSelectorInBackground:@selector(tradingSimulation:) withObject:parameters];
    }else{
        [self tradingSimulation:parameters];
    }
    
}

-(void)tradingSimulation:(NSDictionary *) parameters
{
    NSString *tradingPair;
    long minDateTime, maxDateTime;
    long currentDataMinDateTime, currentDataMaxDateTime;
    BOOL allOk = YES;
    NSString *userMessage;
    
    NSString *simName = [parameters objectForKey:@"SIMNAME"];
    NSString *baseCode = [parameters objectForKey:@"BASECODE"];
    NSString *quoteCode = [parameters objectForKey:@"QUOTECODE"];
    NSString *accCode = [parameters objectForKey:@"ACCOUNTCODE"];
    long startDateTime = [[parameters objectForKey:@"STARTTIME"] longValue];
    int leverage = [[parameters objectForKey:@"MAXLEVERAGE"] intValue];
    float startingBalance = [[parameters objectForKey:@"STARTBALANCE"] floatValue];  
    long initialDataBeforeStart = [[parameters objectForKey:@"INITIALDATA"] longValue]; 
    long simulationLength = [[parameters objectForKey:@"SIMLENGTH"] longValue];
    int timeStep = [[parameters objectForKey:@"TIMESTEP"] intValue];
    //long dataChunkLength = [[parameters objectForKey:@"DATACHUNK"] longValue];
    int tradingLag = [[parameters objectForKey:@"TRADINGLAG"] intValue];
    
    [self setCurrentSimulation:simName];
    
    tradingPair = [NSString stringWithFormat:@"%@%@",baseCode,quoteCode];
    minDateTime = [marketData getMinDataDateTimeForPair:tradingPair];
    maxDateTime = [marketData getMaxDataDateTimeForPair:tradingPair];
    
    if(startDateTime < (minDateTime + initialDataBeforeStart))
    {
        startDateTime =  minDateTime + initialDataBeforeStart;
    }
    startDateTime = [EpochTime epochTimeAtZeroHour:startDateTime] + timeStep  * ((startDateTime-[EpochTime epochTimeAtZeroHour:startDateTime])/timeStep);
    startDateTime = startDateTime + timeStep;
    long endDateTime = startDateTime + simulationLength;
    if(endDateTime > maxDateTime){
        endDateTime = maxDateTime; 
    }
    
    
    [self clearUserInterfaceMessages];
    userMessage = [NSString stringWithFormat:@"Starting %@",simName];
    if(THREADS){
        [self performSelectorOnMainThread:@selector(sendMessageToUserInterface:) withObject:userMessage waitUntilDone:YES];
    }else{
        [self sendMessageToUserInterface:userMessage];
    }
    
    controllerDateTime = minDateTime; 
    Simulation *newAccount = [[Simulation alloc] initWithName:simName 
                                                AndDate:controllerDateTime 
                                             AndBalance:startingBalance 
                                            AndCurrency:accCode
                                         AndTradingPair:tradingPair
                                         AndMaxLeverage: leverage];
    [newAccount setStartDate:startDateTime];
    [newAccount setEndDate:endDateTime];
    [accounts setObject:newAccount forKey:simName];
    
    userMessage = @"Getting Interest Rate data";
    if(THREADS){
        [self performSelectorOnMainThread:@selector(sendMessageToUserInterface:) withObject:userMessage waitUntilDone:YES];
        [self performSelectorOnMainThread:@selector(readingDatabaseOn) withObject:nil waitUntilDone:YES]; 
    }else{
        [self sendMessageToUserInterface:userMessage];
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
    
    if(THREADS){
        [self performSelectorOnMainThread:@selector(readingDatabaseOff) withObject:nil waitUntilDone:YES]; 
    }

    controllerDateTime = startDateTime;
    
    //[self sendMessageToUserInterface:@"Setting up the data"];
    userMessage = @"Setting up the data";
    if(THREADS){
        [self performSelectorOnMainThread:@selector(sendMessageToUserInterface:) withObject:userMessage waitUntilDone:YES];
        [self performSelectorOnMainThread:@selector(readingDatabaseOn) withObject:nil waitUntilDone:YES]; 
    }else{
        [self sendMessageToUserInterface:userMessage];
    }

    
    
    currentDataMinDateTime = startDateTime - initialDataBeforeStart;
    currentDataMaxDateTime = startDateTime + MAX_DATA_CHUNK;
    
    allOk = [marketData setupDataSeriesForName:tradingPair];
   
    
    if(allOk){
        allOk = [marketData setBidAskMidForStartDateTime:currentDataMinDateTime
                                    AndEndDateTime:currentDataMaxDateTime];
        userMessage = @"Data set up";
        if(THREADS){
            [self performSelectorOnMainThread:@selector(sendMessageToUserInterface:) withObject:userMessage waitUntilDone:YES];
            
        }else{
            [self sendMessageToUserInterface:userMessage];
        }
        //[self sendMessageToUserInterface:@"Data set up"];
    }else{
        userMessage = @"***Problem setting up database***";
        if(THREADS){
            [self performSelectorOnMainThread:@selector(sendMessageToUserInterface:) withObject:userMessage waitUntilDone:YES];
        }else{
            [self sendMessageToUserInterface:userMessage];
        }
        //[self sendMessageToUserInterface:@"***Problem setting up database"];
    }
    
    userMessage = @"Adding indicators";
    if(THREADS){
        [self performSelectorOnMainThread:@selector(sendMessageToUserInterface:) withObject:userMessage waitUntilDone:YES];
        [self performSelectorOnMainThread:@selector(readingDatabaseOff) withObject:nil waitUntilDone:YES];
    }else{
        [self sendMessageToUserInterface:userMessage];
    }
    
    [marketData addEWMAWithParameter:6765];
    [marketData addEWMAWithParameter:46368];
    
    userMessage = @"Indicators added";
    if(THREADS){
        [self performSelectorOnMainThread:@selector(sendMessageToUserInterface:) withObject:userMessage waitUntilDone:YES];
    }else{
        [self sendMessageToUserInterface:userMessage];
    }
    
    NSArray *fieldNames = [NSArray arrayWithObjects:@"MID",@"EWMA6765",@"EWMA46368", nil];
    int fieldIndex;
    NSDictionary *values;
    //double currentMarketExposure;
    
    
    NSString *formattedDataDate;
 
    
    long numberOfSimulationSteps = (endDateTime -startDateTime)/timeStep;
    
    NSMutableData *newXData;
    newXData = [[NSMutableData alloc] initWithLength:numberOfSimulationSteps * sizeof(long)]; 
    long *simDateTimes = [newXData mutableBytes];
    
    NSMutableDictionary *newYData = [[NSMutableDictionary alloc] initWithCapacity:[fieldNames count]];
    double **simulationData = malloc([fieldNames count] * sizeof(double*));
    for(fieldIndex = 0; fieldIndex < [fieldNames count]; fieldIndex++){
        [newYData setObject:[[NSMutableData alloc] initWithLength:numberOfSimulationSteps * sizeof(double)] forKey:[fieldNames objectAtIndex:fieldIndex]];
        simulationData[fieldIndex] = [[newYData objectForKey:[fieldNames objectAtIndex:fieldIndex]] mutableBytes];
    }
    
    NSString *currentDateAsString;
    //****ACTUAL START OF THE SIMULATION****//
    int simStepIndex = 0;
    controllerDateTime = startDateTime;
    do{
        double slow, fast;
        currentDateAsString = [EpochTime stringDateWithTime:controllerDateTime];
        if(controllerDateTime > [marketData getMaxDateTimeForLoadedData] )
        {
            currentDataMinDateTime = currentDataMaxDateTime;
            if(endDateTime < currentDataMaxDateTime + MAX_DATA_CHUNK)
            {
                currentDataMaxDateTime = endDateTime + (3 * DAY_SECONDS);
            }else{
                currentDataMaxDateTime = currentDataMaxDateTime + MAX_DATA_CHUNK;
            }
                
            userMessage =  [NSString stringWithFormat:@"%@ Getting More Data %@ to %@",currentDateAsString,[EpochTime stringDateWithTime:currentDataMinDateTime],[EpochTime stringDateWithTime:currentDataMaxDateTime]];
            if(THREADS){
                [self performSelectorOnMainThread:@selector(sendMessageToUserInterface:) withObject:userMessage waitUntilDone:YES];
                [self performSelectorOnMainThread:@selector(readingDatabaseOn) withObject:nil waitUntilDone:YES]; 
            }else{
                [self sendMessageToUserInterface:userMessage];
            }
            
            [marketData setBidAskMidForStartDateTime:currentDataMinDateTime
                                      AndEndDateTime:currentDataMaxDateTime];
            if(THREADS){
                [self performSelectorOnMainThread:@selector(readingDatabaseOff) withObject:nil waitUntilDone:YES];
            }
        }
        
        if(controllerDateTime > [marketData getMaxDateTimeForLoadedData]){
             
            NSLog(@"CHECK!");
        }
        
        formattedDataDate = [[NSDate dateWithTimeIntervalSince1970:controllerDateTime] descriptionWithCalendarFormat:@"%a %Y-%m-%d %H:%M" timeZone:[NSTimeZone timeZoneWithName:@"GMT"] locale:nil];
    
        values = [marketData getValuesForFields: fieldNames AtDateTime:controllerDateTime ];
        
        if(![[values objectForKey:@"SUCCESS"] boolValue])
        {
            userMessage = @"Data Problem, Stopping....";
            if(THREADS){
                [self performSelectorOnMainThread:@selector(sendMessageToUserInterface:) withObject:userMessage waitUntilDone:YES];
            }else{
                [self sendMessageToUserInterface:userMessage];
            }
            allOk = NO;
            break;
        }
        simDateTimes[simStepIndex] = [[values objectForKey:@"DATETIME"] longValue];
        for(fieldIndex=0;fieldIndex<[fieldNames count];fieldIndex++){
            simulationData[fieldIndex][simStepIndex] = [[values objectForKey:[fieldNames objectAtIndex:fieldIndex]] doubleValue];
        }
        
        
        fast = [[values objectForKey:@"EWMA6765"] doubleValue];
        slow = [[values objectForKey:@"EWMA46368"] doubleValue];
        if(fast > slow){
            if([newAccount currentExposure] <= 0)
            {
                userMessage = [NSString stringWithFormat:@"%@ Setting exposure level to 100000",currentDateAsString];
                if(THREADS){
                    [self performSelectorOnMainThread:@selector(sendMessageToUserInterface:) withObject:userMessage waitUntilDone:YES];
                }else{
                    [self sendMessageToUserInterface:userMessage];
                }
                
                allOk = [self setExposureToUnits:100000 
                                      AtTimeDate:controllerDateTime + tradingLag
                                      ForAccount: newAccount
                                   AndSignalTime:controllerDateTime];
                if(!allOk)
                {
                    userMessage = @"Problem setting exposure";
                    if(THREADS){
                        [self performSelectorOnMainThread:@selector(sendMessageToUserInterface:) withObject:userMessage waitUntilDone:YES];
                    }else{
                        [self sendMessageToUserInterface:userMessage];
                    }
                }
            }
        }else{
            if([newAccount currentExposure] >= 0)
            {
                userMessage = [NSString stringWithFormat:@"%@ Setting exposure level to -100000",currentDateAsString];
                if(THREADS){
                    [self performSelectorOnMainThread:@selector(sendMessageToUserInterface:) withObject:userMessage waitUntilDone:YES];
                }else{
                    [self sendMessageToUserInterface:userMessage];
                }                
                
                
                allOk = [self setExposureToUnits:-100000 
                                      AtTimeDate:controllerDateTime + tradingLag
                                      ForAccount: newAccount
                                   AndSignalTime:controllerDateTime];
                if(!allOk)
                {
                    userMessage = @"Problem setting exposure";
                    if(THREADS){
                        [self performSelectorOnMainThread:@selector(sendMessageToUserInterface:) withObject:userMessage waitUntilDone:YES];
                    }else{
                        [self sendMessageToUserInterface:userMessage];
                    }
                }
            }
        }
        controllerDateTime= controllerDateTime+timeStep;
        simStepIndex++;
    }while(controllerDateTime < endDateTime && allOk);
    

    userMessage = [NSString stringWithFormat:@"%@ Finished Simulation",currentDateAsString];
    if(THREADS){
        [self performSelectorOnMainThread:@selector(sendMessageToUserInterface:) withObject:userMessage waitUntilDone:YES];
    }else{
        [self sendMessageToUserInterface:userMessage];
    }     
    
    if(allOk)
    {
       
        [self setExposureToUnits:0 
                      AtTimeDate:controllerDateTime + tradingLag
                      ForAccount: newAccount
                   AndSignalTime:controllerDateTime];
    }
    //***END OF THE SIMULATION****//
    
    
    if(allOk)
    {
        
        DataSeries *simulationDataSeries;
        simulationDataSeries = [marketData newDataSeriesWithXData: newXData
            AndYData: newYData AndSampleRate: timeStep];
        [newAccount setSimulationDataSeries:simulationDataSeries];
        [self plotSimulationData:simulationDataSeries];
    }
    
    userMessage = @"----In Summary----";
    if(THREADS){
        [self performSelectorOnMainThread:@selector(sendMessageToUserInterface:) withObject:userMessage waitUntilDone:YES];
    }else{
        [self sendMessageToUserInterface:userMessage];
    }
    
    int numberOfTrades = [newAccount numberOfTrades];
    userMessage = [NSString stringWithFormat:@"There were %ld transactions",numberOfTrades];
    if(THREADS){
        [self performSelectorOnMainThread:@selector(sendMessageToUserInterface:) withObject:userMessage waitUntilDone:YES];
    }else{
        [self sendMessageToUserInterface:userMessage];
    }     
    
    for(int iTrade = 0; iTrade < numberOfTrades; iTrade++){
        userMessage = [newAccount getTradeDetailToPrint:iTrade];
        if(THREADS){
            [self performSelectorOnMainThread:@selector(sendMessageToUserInterface:) withObject:userMessage waitUntilDone:YES];
        }else{
            [self sendMessageToUserInterface:userMessage];
        }
    }
    int numberOfBalanceAdjustments = [newAccount numberOfBalanceAdjustments];
    userMessage = [NSString stringWithFormat:@"There were %ld balance Adjustments",numberOfBalanceAdjustments];
    if(THREADS){
        [self performSelectorOnMainThread:@selector(sendMessageToUserInterface:) withObject:userMessage waitUntilDone:YES];
    }else{
        [self sendMessageToUserInterface:userMessage];
    }  

    for(int iBalAdj = 0; iBalAdj < numberOfBalanceAdjustments; iBalAdj++)
    {
        userMessage = [newAccount getBalanceDetailToPrint:iBalAdj];
        if(THREADS){
            [self performSelectorOnMainThread:@selector(sendMessageToUserInterface:) withObject:userMessage waitUntilDone:YES];
        }else{
            [self sendMessageToUserInterface:userMessage];
        }

    }
    NSDictionary *performanceAttribution;
    NSArray *perfAttribKeys;
    NSString *perfAttribMessage;
    performanceAttribution = [newAccount getPerformanceAttribution];
    perfAttribKeys = [performanceAttribution allKeys];
    for(int i = 0; i < [perfAttribKeys count]; i++){
        double amount = [[performanceAttribution objectForKey:[perfAttribKeys objectAtIndex:i]] doubleValue];
        NSString *reason = [perfAttribKeys objectAtIndex:i];                 
        perfAttribMessage = [NSString stringWithFormat:@"%@     :%5.2f",reason,amount];
        if(THREADS){
            [self performSelectorOnMainThread:@selector(sendMessageToUserInterface:) withObject:perfAttribMessage waitUntilDone:YES];
        }else{
            [self sendMessageToUserInterface:perfAttribMessage];
        }
    }
    
    double spreadCrossCost;
    spreadCrossCost = [newAccount getSpreadCrossingCostInBaseCurrency];
    userMessage = [NSString stringWithFormat:@"Estimated %5.2f %@ used crossing the spread",[newAccount baseCode],spreadCrossCost];
    if(THREADS){
        [self performSelectorOnMainThread:@selector(sendMessageToUserInterface:) withObject:userMessage waitUntilDone:YES];
    }else{
        [self sendMessageToUserInterface:userMessage];
    }

}

-(void)createDataSeriesWithAccountInformation:(NSString *) accountName
{
    NSString *userMessage;
    Simulation *accountToPlot;
    long startDateTime, endDateTime;
    int timeStep = 60*30;
    long nextTradeDateTime;
    int nextTradeAmount;
    long nextBalAdjDateTime;
    int nextBalAdjAmount;
    
    
    float nextTradePrice;
    int currentPosition;
    BOOL noMoreTrades, noMoreBalanceAdjustments, allOk;
    int tradeIndex = 0;
    int balAdjIndex = 0;
    int dateCount = 0;
    
    
    //double *mtmTradingPnlData;
    long dateTime;
    NSString *currentDateAsString;
    NSMutableData *newXData;
    long *simDateTimes;
    NSMutableDictionary *newYData;
    double **simulationData;
    NSMutableData *newPositionData;
    double *positionData;
    NSMutableData *newShortIndicatorData;
    double *shortIndicatorData;
    NSMutableData *newLongIndicatorData;
    double *longIndicatorData;
    NSMutableData *newMtmPositionalPnl;
    double *mtmPositionalPnl;
    NSMutableData *newMtmPositionalPnlInBase;
    double *mtmPositionalPnlInBase;
    NSMutableData *newTradeCashFlow;
    double *tradeCashFlow;
    NSMutableData *newAccountBalance;
    double *accountBalance;
    NSMutableData *newNAV;
    double *nav;
    
    
    NSMutableArray *positionDateTime = [[NSMutableArray alloc] init];
    NSMutableArray *positionAmount = [[NSMutableArray alloc] init];
    NSMutableArray *positionPrice = [[NSMutableArray alloc] init];
    //NSMutableArray *unRealisedPnl = [[NSMutableArray alloc] init];
    int currentPositionSign = 0;
    
    double maxSoFar;
    double largestDrawdown;
    long largestDrawdownDateTime;
    long positiveTime, negativeTime;
    
    NSArray *fieldNames;
    DataSeries *positionDataSeries;
    
    accountToPlot = [accounts objectForKey:accountName];
    userMessage = [NSString stringWithFormat:@"There were %d trades",[accountToPlot numberOfTrades]];
    if(THREADS){
        [self performSelectorOnMainThread:@selector(sendMessageToUserInterface:) withObject:userMessage waitUntilDone:YES];
    }else{
        [self sendMessageToUserInterface:userMessage];
    }
    startDateTime = [accountToPlot startDate];
    endDateTime = [accountToPlot endDate];
    nextTradeDateTime = [accountToPlot getDateTimeForTradeAtIndex:0];
    
    //nextTradeAmount = [accountToPlot getAmountForTradeAtIndex:0];
    currentPosition = 0;
    noMoreTrades = NO;
    
    dateTime = startDateTime;
    do{
        if(!noMoreTrades){
            if(dateTime >= nextTradeDateTime){
                //If the nextTradeDate doesn't fall on the sample time add in an extra 
                if(dateTime > nextTradeDateTime){
                    dateCount++; 
                }
                tradeIndex++;
                if(tradeIndex<[accountToPlot numberOfTrades]){
                    nextTradeDateTime = [accountToPlot getDateTimeForTradeAtIndex:tradeIndex];
                    //nextTradeAmount = [accountToPlot getAmountForTradeAtIndex:tradeIndex];
                    if(nextTradeDateTime > endDateTime)
                    {
                        endDateTime = nextTradeDateTime;
                    }
                }else{
                    noMoreTrades = YES;
                }
            }
        }
        dateCount++;
        dateTime = dateTime + timeStep;
    }while(dateTime <= endDateTime || !noMoreTrades);
        
    newXData = [[NSMutableData alloc] initWithLength:dateCount * sizeof(long)]; 
    simDateTimes = [newXData mutableBytes];
        
    newPositionData = [[NSMutableData alloc] initWithLength:dateCount * sizeof(double)]; 
    positionData = [newPositionData mutableBytes];
    
    newShortIndicatorData = [[NSMutableData alloc] initWithLength:dateCount * sizeof(double)]; 
    shortIndicatorData = [newShortIndicatorData mutableBytes];

    newLongIndicatorData = [[NSMutableData alloc] initWithLength:dateCount * sizeof(double)]; 
    longIndicatorData = [newLongIndicatorData mutableBytes];
    
    
    newMtmPositionalPnl = [[NSMutableData alloc] initWithLength:dateCount * sizeof(double)]; 
    mtmPositionalPnl = [newMtmPositionalPnl mutableBytes];
    
    newMtmPositionalPnlInBase = [[NSMutableData alloc] initWithLength:dateCount * sizeof(double)]; 
    mtmPositionalPnlInBase = [newMtmPositionalPnl mutableBytes];
    
    newTradeCashFlow = [[NSMutableData alloc] initWithLength:dateCount * sizeof(double)]; 
    tradeCashFlow = [newTradeCashFlow mutableBytes];

    newAccountBalance = [[NSMutableData alloc] initWithLength:dateCount * sizeof(double)]; 
    accountBalance = [newAccountBalance mutableBytes]; 
    
    newNAV = [[NSMutableData alloc] initWithLength:dateCount * sizeof(double)]; 
    nav = [newNAV mutableBytes]; 
    
    //newMtmTradingPnlData = [[NSMutableData alloc] initWithLength:dateCount * sizeof(double)]; 
    //mtmTradingPnlData = [newMtmTradingPnlData mutableBytes];
    
    DataSeries *simulationDataSeries;
    simulationDataSeries = [accountToPlot simulationDataSeries];
        
    fieldNames = [simulationDataSeries getFieldNames];
    
    newYData = [[NSMutableDictionary alloc] initWithCapacity:[fieldNames count]];
    simulationData = malloc([fieldNames count] * sizeof(double*));
    for(int fieldIndex = 0; fieldIndex < [fieldNames count]; fieldIndex++){
        [newYData setObject:[[NSMutableData alloc] initWithLength:dateCount * sizeof(double)] forKey:[fieldNames objectAtIndex:fieldIndex]];
        simulationData[fieldIndex] = [[newYData objectForKey:[fieldNames objectAtIndex:fieldIndex]] mutableBytes];
    }
        
    long currentDataMinDateTime, currentDataMaxDateTime;
    allOk = [marketData setBidAskMidForStartDateTime:startDateTime
                                          AndEndDateTime:startDateTime+MAX_DATA_CHUNK];
    
    double cummulativeTradeCashFlow = 0.0;
    double cumulativeMtmPositionalPnl = 0.0;
    //double cumulativeMtmPositionalPnlInBase = 0.0;
    double currentAccountBalance = 0.0;
    if(allOk){
        [marketData addEWMAWithParameter:6765];
        [marketData addEWMAWithParameter:46368];
        currentDataMinDateTime = [marketData getMinDateTimeForLoadedData];
        currentDataMaxDateTime = [marketData getMaxDateTimeForLoadedData];
      
        double previousBid = 0.0,previousAsk = 0.0,currentBid = 0.0,currentAsk = 0.0;
        BOOL tradeAtThisTime;
        positiveTime = 0; 
        negativeTime = 0;
        long previousDateTime;
        float unrealisedPnl;
        NSArray *bidAskFields = [NSArray arrayWithObjects:@"BID",@"ASK", nil];
        NSDictionary *valuesAtDate;
        
        tradeIndex = 0;
        dateCount = 0;
        startDateTime = [accountToPlot startDate];
        endDateTime = [accountToPlot endDate];
        
        nextTradeDateTime = [accountToPlot getDateTimeForTradeAtIndex:tradeIndex];
        nextTradeAmount = [accountToPlot getAmountForTradeAtIndex:tradeIndex];
        nextTradePrice = [accountToPlot getPriceForTradeAtIndex:tradeIndex];
        
        nextBalAdjDateTime = [accountToPlot getDateTimeForBalanceAdjustmentAtIndex:balAdjIndex];
        nextBalAdjAmount = [accountToPlot getAmountForBalanceAdjustmentAtIndex:balAdjIndex];
        
        currentPosition = 0;
        noMoreTrades = NO;
        noMoreBalanceAdjustments = NO;
        
        dateTime = startDateTime;
        
        do{
            tradeAtThisTime = NO;
                      
            if(!noMoreTrades){
                currentDateAsString = [EpochTime stringDateWithTime:dateTime];
                
                if(MIN(nextTradeDateTime,dateTime) > [marketData getMaxDateTimeForLoadedData])
                {
                    currentDataMinDateTime = currentDataMaxDateTime;
                    if(endDateTime < currentDataMaxDateTime + MAX_DATA_CHUNK)
                    {
                        currentDataMaxDateTime = endDateTime + (3 * DAY_SECONDS);
                    }else{
                        currentDataMaxDateTime = currentDataMaxDateTime + MAX_DATA_CHUNK;
                    }
                    
                    [marketData setBidAskMidForStartDateTime:currentDataMinDateTime
                                              AndEndDateTime:currentDataMaxDateTime];
                    if(THREADS){
                        [self performSelectorOnMainThread:@selector(readingDatabaseOff) withObject:nil waitUntilDone:YES];
                    }
                }
                //Get all the data and fill it in. This is an extra day to the to days the 
                // samples fall on
                 
               
                
                if(dateTime >= nextTradeDateTime){
                    tradeAtThisTime = YES;
                    cummulativeTradeCashFlow = cummulativeTradeCashFlow - nextTradeAmount*nextTradePrice;
                    
                    //mtmTradingPnlData[dateCount] = tradingPnl;
                    if(currentPosition > 0){
                        currentPositionSign = 1;
                    }
                    if(currentPosition < 0){
                        currentPositionSign = -1;
                    }
                    
                    if(currentPosition !=0 && (currentPositionSign * nextTradeAmount) < 0)
                    {
                        int remainingTrade = nextTradeAmount;
                        int numberOfTradesToRemove = 0;
                        while(remainingTrade != 0){
                        if([positionDateTime count] ==0){
                            [positionDateTime addObject:[NSNumber numberWithLong:nextTradeDateTime]]; 
                            [positionAmount addObject:[NSNumber numberWithInt:remainingTrade]];
                            [positionPrice addObject:[NSNumber numberWithFloat:nextTradePrice]];     
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
                                    remainingTrade = 0;
                                }
                            }
                        }
                        if(numberOfTradesToRemove > 0){
                            for(int i = 0;i < numberOfTradesToRemove; i++){
                                [positionDateTime removeObjectAtIndex:0];
                                [positionAmount removeObjectAtIndex:0];
                                [positionPrice removeObjectAtIndex:0];
                            }
                        }
                   
                    }else{
                        [positionDateTime addObject:[NSNumber numberWithLong:nextTradeDateTime]]; 
                        [positionAmount addObject:[NSNumber numberWithInt:nextTradeAmount]];
                        [positionPrice addObject:[NSNumber numberWithFloat:nextTradePrice]];
                    }
                    //If the nextTradeDate doesn't fall on the sample time add in an extra 
                    if(dateTime > nextTradeDateTime){
                        //Get all the data and fill it in. This is an extra day to the to days the 
                        // samples fall on
                        valuesAtDate = [marketData getValuesForFields:fieldNames 
                                                                         AtDateTime:nextTradeDateTime];
                        
                        for(int fieldIndex = 0; fieldIndex < [fieldNames count]; fieldIndex++){
                            simulationData[fieldIndex][dateCount] = [[valuesAtDate objectForKey:[fieldNames objectAtIndex:fieldIndex]] doubleValue];
                        }
                        
                        valuesAtDate = [marketData getValuesForFields:bidAskFields 
                                                           AtDateTime:nextTradeDateTime];
                        previousBid = currentBid;
                        previousAsk = currentAsk;
                        currentBid = [[valuesAtDate objectForKey:@"BID"] doubleValue];
                        currentAsk = [[valuesAtDate objectForKey:@"ASK"] doubleValue];
                        
                        if(currentPosition > 0){
                            cumulativeMtmPositionalPnl = cumulativeMtmPositionalPnl  + currentPosition *(currentBid - previousBid);
                            if((currentBid - previousBid)>=0){
                                positiveTime = positiveTime + (nextTradeDateTime - previousDateTime);
                            }else{
                                negativeTime = negativeTime + (nextTradeDateTime - previousDateTime);
                            }
                        }
                        if(currentPosition < 0){
                            cumulativeMtmPositionalPnl = cumulativeMtmPositionalPnl + currentPosition *(currentAsk - previousAsk);
                            if((currentAsk - previousAsk)<0){
                                positiveTime = positiveTime + (nextTradeDateTime - previousDateTime);
                            }else{
                                negativeTime = negativeTime + (nextTradeDateTime - previousDateTime);
                            }
                        }
                        
                        //cummulativeTradingPnl = cummulativeTradingPnl - nextTradeAmount*nextTradePrice;
                                                //mtmTradingPnlData[dateCount] = nextTradeAmount*;
                           
                        currentPosition = currentPosition + nextTradeAmount;   
                        simDateTimes[dateCount] = nextTradeDateTime;
                        positionData[dateCount] = (double)currentPosition; 
                        
                        if(currentPosition < 0){
                            shortIndicatorData[dateCount] = -positionData[dateCount];
                            longIndicatorData[dateCount] = 0.0;
                        }
                        if(currentPosition > 0){
                            shortIndicatorData[dateCount] = 0.0;
                            longIndicatorData[dateCount] = positionData[dateCount];
                        }
                        if(currentPosition == 0){
                            shortIndicatorData[dateCount] = 0.0;
                            longIndicatorData[dateCount] = 0.0;
                        }
                        
                        mtmPositionalPnl[dateCount] = cumulativeMtmPositionalPnl;   
                        tradeCashFlow[dateCount] = cummulativeTradeCashFlow;
                        
                        previousDateTime = nextTradeDateTime;
                        
                        while(nextBalAdjDateTime <= nextTradeDateTime && !noMoreBalanceAdjustments){
                            currentAccountBalance = currentAccountBalance + nextBalAdjAmount;
                            if(balAdjIndex < ([accountToPlot numberOfBalanceAdjustments]-1)){
                                balAdjIndex++;
                                nextBalAdjDateTime = [accountToPlot getDateTimeForBalanceAdjustmentAtIndex:balAdjIndex];
                                nextBalAdjAmount = [accountToPlot getAmountForBalanceAdjustmentAtIndex:balAdjIndex];
                            }else{
                                noMoreBalanceAdjustments = YES;
                            }
                        }
                        accountBalance[dateCount] = currentAccountBalance;
                        
                        unrealisedPnl = 0.0;
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
                        if(currentPosition == 0){
                            nav[dateCount] = accountBalance[dateCount];
                        }else{
                            if(unrealisedPnl > 0){
                                float accBaseAsk = currentAsk;
                                nav[dateCount] = accountBalance[dateCount] + (unrealisedPnl/accBaseAsk);
                            }else{
                                float accBaseBid = currentBid;
                                nav[dateCount] = accountBalance[dateCount] + (unrealisedPnl/accBaseBid);
                            }
                        }
                        
                        
                        dateCount++;
                        previousBid = currentBid;
                        previousAsk = currentAsk;
                        //Done with this trade
                        tradeAtThisTime = NO;
                    }   
                    tradeIndex++;
                    if(tradeIndex<[accountToPlot numberOfTrades]){
                        nextTradeDateTime = [accountToPlot getDateTimeForTradeAtIndex:tradeIndex];
                        nextTradeAmount = [accountToPlot getAmountForTradeAtIndex:tradeIndex];
                        nextTradePrice = [accountToPlot getPriceForTradeAtIndex:tradeIndex];
                        if(nextTradeDateTime > endDateTime)
                        {
                            endDateTime = nextTradeDateTime;
                        }
                    }else{
                        noMoreTrades = YES;
                    }
                }
            }
            
            //NSDictionary *valuesAtDate = [marketData getValuesForFields:fieldNames 
            //                                           AtDateTime:dateTime];
            
            
            valuesAtDate = [marketData getValuesForFields:bidAskFields 
                                                             AtDateTime:dateTime];
            previousBid = currentBid;
            previousAsk = currentAsk;
            currentBid = [[valuesAtDate objectForKey:@"BID"] doubleValue];
            currentAsk = [[valuesAtDate objectForKey:@"ASK"] doubleValue];
            if(currentPosition > 0){
                cumulativeMtmPositionalPnl = cumulativeMtmPositionalPnl  + currentPosition *(currentBid - previousBid);
                if((currentBid - previousBid)>=0){
                    positiveTime = positiveTime + (dateTime - previousDateTime);
                }else{
                    negativeTime = negativeTime + (dateTime - previousDateTime);
                }
            }
            if(currentPosition < 0){
                cumulativeMtmPositionalPnl = cumulativeMtmPositionalPnl + currentPosition *(currentAsk - previousAsk);
                if((currentAsk - previousAsk)<0){
                    positiveTime = positiveTime + (dateTime - previousDateTime);
                }else{
                    negativeTime = negativeTime + (dateTime - previousDateTime);
                }
            }
          
            valuesAtDate = [marketData getValuesForFields:fieldNames 
                                               AtDateTime:dateTime];
            for(int fieldIndex = 0; fieldIndex < [fieldNames count]; fieldIndex++){
                simulationData[fieldIndex][dateCount] = [[valuesAtDate objectForKey:[fieldNames objectAtIndex:fieldIndex]] doubleValue];
            }
            if(tradeAtThisTime){
                currentPosition = currentPosition + nextTradeAmount;
            }
            
            simDateTimes[dateCount] = dateTime;
            positionData[dateCount] = (double)currentPosition;
            
            if(currentPosition < 0){
                shortIndicatorData[dateCount] = -positionData[dateCount];
                longIndicatorData[dateCount] = 0.0;
            }
            if(currentPosition > 0){
                shortIndicatorData[dateCount] = 0.0;
                longIndicatorData[dateCount] = positionData[dateCount];
            }
            if(currentPosition == 0){
                shortIndicatorData[dateCount] = 0.0;
                longIndicatorData[dateCount] = 0.0;
            }
            
            mtmPositionalPnl[dateCount] = cumulativeMtmPositionalPnl; 
            tradeCashFlow[dateCount] = cummulativeTradeCashFlow;
            
            while(nextBalAdjDateTime <= dateTime && !noMoreBalanceAdjustments){
                currentAccountBalance = currentAccountBalance + nextBalAdjAmount;
                if(balAdjIndex < ([accountToPlot numberOfBalanceAdjustments]-1)){
                    balAdjIndex++;
                    nextBalAdjDateTime = [accountToPlot getDateTimeForBalanceAdjustmentAtIndex:balAdjIndex];
                    nextBalAdjAmount = [accountToPlot getAmountForBalanceAdjustmentAtIndex:balAdjIndex];
                }else{
                    noMoreBalanceAdjustments = YES;
                }
            }
            accountBalance[dateCount] = currentAccountBalance;
            unrealisedPnl = 0.0;
            if(currentPosition > 0){
                for(int positionIndex = 0; positionIndex < [positionAmount count]; positionIndex++){
                    unrealisedPnl = unrealisedPnl + [[positionAmount objectAtIndex:positionIndex] intValue] * ((currentBid-[[positionPrice objectAtIndex:positionIndex] floatValue]));
                }
            }
            if(currentPosition < 0){
                for(int positionIndex = 0; positionIndex < [positionAmount count]; positionIndex++){
                    unrealisedPnl = unrealisedPnl + [[positionAmount objectAtIndex:positionIndex] intValue] * ((currentAsk - [[positionPrice objectAtIndex:positionIndex] floatValue]));
                }
                
            }
            if(currentPosition == 0){
                nav[dateCount] = accountBalance[dateCount];
            }else{
                if(unrealisedPnl > 0){
                    float accBaseAsk = currentAsk;
                    nav[dateCount] = accountBalance[dateCount] + (unrealisedPnl/accBaseAsk);
                }else{
                    float accBaseBid = currentBid;
                    nav[dateCount] = accountBalance[dateCount] + (unrealisedPnl/accBaseBid);
                }
            }
 
            dateCount++;
            //previousBid = [[valuesAtDate objectForKey:@"BID"] doubleValue];
            //previousAsk = [[valuesAtDate objectForKey:@"ASK"] doubleValue];
            previousDateTime = dateTime;
            dateTime = dateTime + timeStep;
        }while(dateTime <= endDateTime || !noMoreTrades);
    }
    if(allOk){
        NSString *userMessage;
       
        largestDrawdown = 0.0;
        maxSoFar = mtmPositionalPnl[0];
        for(int i = 0; i < dateCount; i++){
           if(mtmPositionalPnl[i] > maxSoFar){
               maxSoFar = mtmPositionalPnl[i];
           }else{
               if( (maxSoFar-mtmPositionalPnl[i]) > largestDrawdown){
                   largestDrawdown = maxSoFar-mtmPositionalPnl[i];
                   largestDrawdownDateTime = simDateTimes[i];
               }
           }
        } 
        userMessage = [NSString stringWithFormat:@"Largest Drawdown of: %5.2f on %@", largestDrawdown,[EpochTime stringDateWithTime:largestDrawdownDateTime]];
        [self sendMessageToUserInterface:userMessage];
        userMessage = [NSString stringWithFormat:@"P&L due to Exposure: %5.2f",cumulativeMtmPositionalPnl];
        [self sendMessageToUserInterface:userMessage];
        userMessage = [NSString stringWithFormat:@"Trading Cash Flow: %5.2f",cummulativeTradeCashFlow];
        [self sendMessageToUserInterface:userMessage];
        userMessage = [NSString stringWithFormat:@"P&L went up about %5.2f and down %5.2f days, out of %5.2f",(double)positiveTime/(24*60*60),(double)negativeTime/(24*60*60),(double)(simDateTimes[dateCount-1]-simDateTimes[0])/(24*60*60)] ; 
        [self sendMessageToUserInterface:userMessage];
    }else{
        NSLog(@"Database Problem; quitting"); 
    }
    
    //Get arrays of the long and short periods
    
    NSMutableArray *shortPeriods = [[NSMutableArray alloc] init];
    NSMutableArray *longPeriods = [[NSMutableArray alloc] init];
    
    currentPosition = 0;
    long positionStartTime = 0;
    for(int tradeIndex = 0; tradeIndex < [accountToPlot numberOfTrades]; tradeIndex++){
        if(currentPosition == 0){
            positionStartTime = [accountToPlot getDateTimeForTradeAtIndex:tradeIndex];
        }else{
            if(currentPosition > 0){
                if(currentPosition + [accountToPlot getAmountForTradeAtIndex:tradeIndex] <=0){
                    [longPeriods addObject:[NSNumber numberWithLong:positionStartTime]];
                    [longPeriods addObject:[NSNumber numberWithLong:[accountToPlot getDateTimeForTradeAtIndex:tradeIndex]]];
                }
                if(currentPosition + [accountToPlot getAmountForTradeAtIndex:tradeIndex] <0){
                    positionStartTime = [accountToPlot getDateTimeForTradeAtIndex:tradeIndex];
                }else{
                    positionStartTime = 0;
                }
            }
            if(currentPosition < 0){
                if(currentPosition + [accountToPlot getAmountForTradeAtIndex:tradeIndex] >=0){
                    [shortPeriods addObject:[NSNumber numberWithLong:positionStartTime]];
                    [shortPeriods addObject:[NSNumber numberWithLong:[accountToPlot getDateTimeForTradeAtIndex:tradeIndex]]];
                }
                if(currentPosition + [accountToPlot getAmountForTradeAtIndex:tradeIndex] >0){
                    positionStartTime = [accountToPlot getDateTimeForTradeAtIndex:tradeIndex];
                }else{
                    positionStartTime = 0;
                }
            }
        }
        currentPosition = currentPosition + [accountToPlot getAmountForTradeAtIndex:tradeIndex];
    }

    [accountToPlot setShortPeriods:shortPeriods];
    [accountToPlot setLongPeriods:longPeriods];
    //Get arrays of the long and short periods DONE

    
    if(allOk)
    {
        [newYData setObject:newPositionData forKey:@"POSITION"];
        [newYData setObject:newMtmPositionalPnl forKey:@"POS_PNL"];
        [newYData setObject:newTradeCashFlow forKey:@"TRADE_PNL"];
        [newYData setObject:newAccountBalance forKey:@"BALANCE"]; 
        [newYData setObject:newNAV forKey:@"NAV"];
        [newYData setObject:newShortIndicatorData forKey:@"SHORT"];
        [newYData setObject:newLongIndicatorData forKey:@"LONG"];
        positionDataSeries = [marketData newDataSeriesWithXData: newXData
                                                       AndYData: newYData 
                                                  AndSampleRate: timeStep];
        [accountToPlot setAnalysisDataSeries:positionDataSeries];
        [self addSimulationDataToResultsTableView:positionDataSeries];
        [self plotSimulationData:positionDataSeries];
    }
    
    
}

-(void)calculateInterestForAccount: (Simulation *) account ToDateTime: (long) endDateTime
{
    long earliestPositionDateTime;
    earliestPositionDateTime = [account timeDateOfEarliestPosition];
    
    NSArray *borrowingInterestRates;
    NSArray *lendingInterestRates;
    
    NSString *borrowingCode;
    NSString *lendingCode; 
    NSString *accBaseCode, *accQuoteCode;
    DataSeriesValue *accBaseAskPrice;
    DataSeriesValue *accQuoteAskPrice;
    
    if([account currentExposure] !=0)
    {
        accBaseCode = [NSString stringWithFormat:@"%@%@",[account accCode],[account baseCode]];
        accQuoteCode = [NSString stringWithFormat:@"%@%@",[account accCode],[account quoteCode]];
        
        accBaseAskPrice = [marketData valueFromDataBaseForFxPair:accBaseCode 
                                                       AndDateTime:controllerDateTime 
                                                          AndField:@"ASK"];                                         
        
        accQuoteAskPrice = [marketData valueFromDataBaseForFxPair:accQuoteCode 
                                                      AndDateTime:controllerDateTime 
                                                         AndField:@"ASK"]; 
        
        if([account currentExposure] >0)
        {
            borrowingCode = [account baseCode];
            lendingCode = [account quoteCode];
        }else{
            borrowingCode = [account quoteCode];
            lendingCode = [account baseCode];
        }
    
        borrowingInterestRates = [interestRates objectForKey:[NSString stringWithFormat:@"%@IRASK",borrowingCode]];
        lendingInterestRates = [interestRates objectForKey:[NSString stringWithFormat:@"%@IRBID",lendingCode]];
    
        long positionInterestDateTime;
        float positionEntryPrice;
        int positionSize;
        float interestRate;
        long interestRateStart, interestRateEnd;
    
    
        for(int iPos = 0; iPos < [account numberOfPositions]; iPos++)
        {
            //Borrowing
            positionInterestDateTime = [account dateTimeOfInterestForPositionAtIndex:iPos];
            positionSize = [account sizeOfPositionAtIndex:iPos];
            positionEntryPrice = [account entryPriceOfPositionAtIndex:iPos];
            long interestUpToDateDateTime = positionInterestDateTime;
        
            int iRateUpdate, iRateUpdateIndex;
            iRateUpdateIndex = 0;
        
            float interestAccrued = 0.0;
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
                    DataSeriesValue *interestRateDSV = [borrowingInterestRates objectAtIndex:(iRateUpdate + 1)];
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
            [account addInterestToPosition:iPos
                                WithAmount:interestAccrued 
                                    AtTime:endDateTime];
        }
    }
}

-(BOOL) setExposureToUnits:(int) exposureAmount 
                AtTimeDate:(long) currentDateTime
                ForAccount: (Simulation *) account
             AndSignalTime: (long) signalDateTime
{
    int currentExposure = [account currentExposure];
    int exposureAdjustment = exposureAmount-currentExposure;
    double tradePrice;
    BOOL success;
    
    NSString *accQuoteCode, *baseQuoteCode;
    DataSeriesValue *accQuoteBidPrice, *accQuoteAskPrice;
    DataSeriesValue *baseQuoteBidPrice, *baseQuoteAskPrice;
    
    //First make sure interest calculations are up-to-date
    [self calculateInterestForAccount:account 
                           ToDateTime:currentDateTime];
    
    
    accQuoteCode = [NSString stringWithFormat:@"%@%@",[account accCode],[account quoteCode]];
    
    baseQuoteCode = [NSString stringWithFormat:@"%@%@",[account baseCode],[account quoteCode]]; 
    
    
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
            [account addTradeWithAmount:exposureAdjustment 
                                 AtTime:currentDateTime 
                              WithPrice:tradePrice
                    AndAccQuoteBidPrice:[accQuoteBidPrice value]
                    AndAccQuoteAskPrice:[accQuoteAskPrice value]
                    AndBaseQuoteBidPrice:[baseQuoteBidPrice value]
                    AndBaseQuoteAskPrice:[baseQuoteAskPrice value]
                      AndSignalDateTime: signalDateTime];    
        }
    }
    return success;
}
 
         
-(double)getPrice:(PriceType) priceType AtTime:(long) dateTime WithSuccess:(BOOL *) success
{
    long laggedTime;
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
    
    laggedTime = dateTime + STATIC_LAG;
    NSDictionary *dataBaseValues = [marketData getValuesForFields: fieldNames AtDateTime:laggedTime];
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


-(Simulation *)getAccountForName: (NSString *) name;
{
    Simulation *acc = nil;
    acc = [accounts objectForKey:name];
    return acc;
}

-(double) getBalanceForAccount: (Simulation *) account
{
    return [account currentBalance];
}

-(int) getExposureForAccount: (Simulation *) account
{
    return [account currentExposure];
}
     
     
-(double) getMarginUsedForAccount: (Simulation *) account
{
    NSString *accBaseCode;
    DataSeriesValue *accBaseBidPrice, *accBaseAskPrice;
    float marginUsed;
    
    
    accBaseCode = [NSString stringWithFormat:@"%@%@",[account accCode],[account baseCode]];
    
    
    accBaseBidPrice = [marketData valueFromDataBaseForFxPair:accBaseCode 
                                                  AndDateTime:controllerDateTime 
                                                     AndField:@"BID"];
    accBaseAskPrice = [marketData valueFromDataBaseForFxPair:accBaseCode 
                                                  AndDateTime:controllerDateTime 
                                                     AndField:@"ASK"]; 
    
    marginUsed = [account getMarginUsedWithAccBaseBidPrice: [accBaseBidPrice value]
                                        AndAccBaseAskPrice: [accBaseAskPrice value]];
    
    return marginUsed;
}

-(double) getNAVForAccount: (Simulation *) account
{
    NSString *baseQuoteCode;
    NSString *accQuoteCode;
    DataSeriesValue *baseQuoteBidPrice, *baseQuoteAskPrice;
    DataSeriesValue *accQuoteBidPrice, *accQuoteAskPrice;
    float nav;
    
    baseQuoteCode = [NSString stringWithFormat:@"%@%@",[account baseCode],[account quoteCode]];
    accQuoteCode = [NSString stringWithFormat:@"%@%@",[account accCode],[account quoteCode]];
    
    baseQuoteBidPrice = [marketData valueFromDataBaseForFxPair:baseQuoteCode 
                                                   AndDateTime:controllerDateTime 
                                                      AndField:@"BID"];
    baseQuoteAskPrice = [marketData valueFromDataBaseForFxPair:baseQuoteCode 
                                                   AndDateTime:controllerDateTime 
                                                      AndField:@"ASK"];                                         
                                                           
    accQuoteBidPrice = [marketData valueFromDataBaseForFxPair:accQuoteCode 
                                                  AndDateTime:controllerDateTime 
                                                     AndField:@"BID"];
    accQuoteAskPrice = [marketData valueFromDataBaseForFxPair:accQuoteCode 
                                                  AndDateTime:controllerDateTime 
                                                     AndField:@"ASK"]; 
    
    nav = [account getNAVWithBaseQuoteBidPrice: [baseQuoteBidPrice  value] 
                              AndBaseQuoteAskPrice: [baseQuoteAskPrice value]
                               AndAccQuoteBidPrice: [accQuoteBidPrice value]
                               AndAccQuoteAskPrice: [accQuoteAskPrice value]];
   
    return nav;
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
-(void) plotSimulationData:(DataSeries *) dataToPlot
{
    if([[self delegate] respondsToSelector:@selector(plotSimulationData:)])
    {
        [[self delegate] plotSimulationData:dataToPlot]; 
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

#pragma mark -
#pragma mark TableView Methods

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView{
    
    Simulation* sim = [accounts objectForKey:currentSimulation];
    DataSeries* simData = [sim analysisDataSeries];
    
    if([[tableView identifier] isEqualToString:@"SIMDATATV"]){
        return [simData length]; 
    }
    return 0;
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    Simulation* sim = [accounts objectForKey:currentSimulation];
    DataSeries* simData = [sim analysisDataSeries];
    if([[tableColumn identifier] isEqualToString:@"DATETIME"]){
        long dateTimeNumber = [[[simData xData] sampleValue:row] longValue];
        NSString *dateTime = [EpochTime stringDateWithTime:dateTimeNumber];
        return dateTime;
    }else{
        NSString *identiferString = [tableColumn identifier];
        if([identiferString isEqualToString:@"DATETIME"] || [identiferString isEqualToString:@"POS_PNL"] || [identiferString isEqualToString:@"NAV"] )
        {
            double dataValue = [[[[simData yData] objectForKey:identiferString] sampleValue:row] doubleValue];
            return [NSString stringWithFormat:@"%5.2f",dataValue];
        }else{
            return [[[simData yData] objectForKey:identiferString] sampleValue:row];
        }
    }
    return nil;
}

@end
