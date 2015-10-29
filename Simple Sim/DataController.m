//
//  DataController.m
//  Simple Sim
//
//  Created by Martin O'Connor on 14/01/2012.
//  Copyright (c) 2015 MARTIN OCONNOR. All rights reserved.
//

#import "DataController.h"
#import "FMDatabase.h"
#import "FMDatabaseAdditions.h"
#import "DataSeries.h"
#import "EpochTime.h"
#import "DataView.h"
#import "DataSeriesValue.h"
#import "UtilityFunctions.h"
#import "DataProcessor.h"
#import "SignalSystem.h"

//#define DATABASE_GRANULARITY_SECONDS 1
#define MAX_DATA_CHUNK 5000000
#define DAY_SECONDS 86400

@interface DataController()
- (void) setupListofPairs;
- (void) setupListofDataFields;
- (void) readingRecordSetProgress:(NSNumber *) progressFraction;
- (void) readingRecordSetMessage:(NSString *) progressMessage;
- (void) progressAsFraction:(NSNumber *) progressValue;
- (NSDictionary *) getBidAskMidDataFrom: (long) startDateTime
                                     To: (long) endDateTime
                           WithDataRate: (long) dataRate;
- (NSDictionary *) resampleData: (NSDictionary *) dataDictionary
                 DownToDataRate: (long) dataRate
                   FromDateTime: (long) startDateTime;

@property (retain) FMDatabase *db;
@property (retain) NSMutableDictionary *dataStore;
@property (retain) NSString *databaseTableName;

@end

@implementation DataController

//NSString *dbPath = @"/Users/Martin/Projects/Databases/timeseries.db";
NSString *dbPath = @"/Users/Martin/Projects/Databases/tsSampled.db";

-(id)init
{  
    self = [super init];
    if(self){
        _db = [FMDatabase databaseWithPath:dbPath];
        _delegate = nil;
        _doThreads = NO;
        _adhocDataAdded = NO;
        _fileDataAdded = NO;
        _dataStore = [[NSMutableDictionary alloc] init];
        if (![_db open]) {
            _db = nil;
            _connected = NO;
        }else{
            _connected = YES;
            [_db executeUpdate:@"PRAGMA page_size=8192"];
            //FMDBQuickCheck(![_db hadError]);
            [self setupListofPairs];
            [self setupListofDataFields];
        }
    }
    return self;
}

-(void)dealloc
{
    if([self db])
    {
        if([[self db] close]){
            NSLog(@"Database successfully closed");
            
        }else{
            NSLog(@"Problem closing database");
        }
    }
}

+ (long) getMaxDataLength
{
    return MAX_DATA_CHUNK;
}


- (BOOL) setupDataSeriesForName: (NSString *) dataSeriesName 
{
    BOOL success = YES;
    double pipSize;
    NSString *seriesName; 
    int dbid = [[[self fxPairs] objectForKey:dataSeriesName] intValue];
    @try
    {
        if([self connected] == YES)
        {
            seriesName = [[self db] stringForQuery:[NSString stringWithFormat:@"SELECT SeriesName FROM SeriesName WHERE SeriesId = %d", dbid]];
            pipSize = [[self db] doubleForQuery:[NSString stringWithFormat:@"SELECT PipSize FROM PipSize WHERE SeriesId = %d", dbid]];
        }else{
            success = NO;
            NSLog(@"Database error");
        }
    }
    @catch (NSException *exception) {
        NSLog(@"main: Caught %@: %@", [exception name], [exception reason]);
        success = NO;
    }
    if(success){
        
        [self setDataSeries:[[DataSeries alloc] initWithName: seriesName 
                                                    AndDbTag: dbid 
                                                  AndPipSize: pipSize]];
    }
    return success;
}

- (double) getPipsizeForSeriesName: (NSString *) dataSeriesName
{
    BOOL success = YES;
    double pipSize = 0.0;
    //NSString *seriesName;
    int dbid = [[[self fxPairs] objectForKey:dataSeriesName] intValue];
    @try
    {
        if([self connected] == YES)
        {
            //seriesName = [[self db] stringForQuery:[NSString stringWithFormat:@"SELECT SeriesName FROM SeriesName WHERE SeriesId = %d", dbid]];
            pipSize = [[self db] doubleForQuery:[NSString stringWithFormat:@"SELECT PipSize FROM PipSize WHERE SeriesId = %d", dbid]];
        }else{
            success = NO;
            NSLog(@"Database error");
        }
    }
    @catch (NSException *exception) {
        NSLog(@"main: Caught %@: %@", [exception name], [exception reason]);
        success = NO;
    }
      return pipSize;
}

- (int) databaseSamplingRate
{
    BOOL success = YES;
    int dataRate = -1;
    @try
    {
        if([self connected] == YES)
        {
            dataRate = [[self db] intForQuery:@"SELECT SamplingRate FROM SamplingRate"];
         
        }else{
            success = NO;
            NSLog(@"Database error");
        }
    }
    @catch (NSException *exception) {
        NSLog(@"main: Caught %@: %@", [exception name], [exception reason]);
        success = NO;
        
    }
    return dataRate;
    
}


//-(int)dataGranularity
//{
//    return DATABASE_GRANULARITY_SECONDS;
//}

- (BOOL) doThreads
{
    return  _doThreads;
}

- (void) setDoThreads:(BOOL)doThreadedProcedures
{
    _doThreads = doThreadedProcedures;
}

- (void) readingRecordSetProgress:(NSNumber *) progressFraction;
{
    if([self delegate] != nil){
        if([[self delegate] respondsToSelector:@selector(readingRecordSetProgress:)])
        {
            [[self delegate] readingRecordSetProgress:progressFraction];
        }else{
            NSLog(@"Delegate does not respond to \'readingRecordSetProgress:\'");
        }
    }
}

- (void) readingRecordSetMessage:(NSString *) progressMessage;
{
    if([self delegate] != nil){
        if([[self delegate] respondsToSelector:@selector(readingRecordSetMessage:)])
        {
            [[self delegate] readingRecordSetMessage:progressMessage];
        }else{
            NSLog(@"Delegate does not respond to \'readingRecordSetMessage:\'");
        }
    }
}


-(void) progressAsFraction:(NSNumber *) progressValue
{
    if([self delegate] != nil){
        if([[self delegate] respondsToSelector:@selector(progressAsFraction:)])
        {
            [[self delegate] progressAsFraction:progressValue];
        }else{
            NSLog(@"Delegate does not respond to \'progressAsFraction:\'");
        }
    }
}

-(long)getDataSeriesLength
{
    return [[self dataSeries] length];
}

-(long)getMinDateTimeForLoadedData
{
    long minDateTime = 0;
    if([self dataSeries] != nil)
    {
        minDateTime = [[self dataSeries] minDateTime];
    }
    return minDateTime; 
}

-(long) getMaxDateTimeForLoadedData
{
    long maxDateTime = 0;
    if([self dataSeries] != nil)
    {
        maxDateTime = [[self dataSeries] maxDateTime];
    }
    return maxDateTime; 
}

-(NSArray *)getFieldNames
{
    return [[self dataSeries] getFieldNames];
}

+(NSString *)getSignalListAsString
{
    return [SignalSystem signalListAsString];
}

+(NSString *)getSeriesListAsString
{
    return [SignalSystem seriesListAsString];
}

- (void) setupListofPairs{
    NSMutableDictionary *retrievedPairs = [[NSMutableDictionary alloc]init];
    NSMutableDictionary *dataMinDateTimes = [[NSMutableDictionary alloc]init];
    NSMutableDictionary *dataMaxDateTimes = [[NSMutableDictionary alloc]init];
    
    NSString *seriesName;
    if([self connected] == YES){
        FMResultSet *s = [[self db] executeQuery:@"SELECT SN.SeriesId, SN.SeriesName, DDR.MinDate, DDR.MaxDate FROM SeriesName SN INNER JOIN DataDateRange DDR ON SN.SeriesId = DDR.SeriesId  WHERE SN.Type='FX'"];
        while ([s next]) {
            
            //retrieve values for each record
            seriesName = [s stringForColumnIndex:1]; 
            
            [retrievedPairs setObject:[NSNumber numberWithInt:[s intForColumnIndex:0]]  forKey:seriesName];
            [dataMinDateTimes setObject:[NSNumber numberWithLong:[s longForColumnIndex:2]] forKey:seriesName];
            [dataMaxDateTimes setObject:[NSNumber numberWithLong:[s longForColumnIndex:3]] forKey:seriesName];
        }
    }
    [self setFxPairs:retrievedPairs];
    [self setMinDateTimes:dataMinDateTimes];
    [self setMaxDateTimes:dataMaxDateTimes];
}

- (NSDictionary *) getValues:(NSArray *) fieldNames 
                  AtDateTime: (long) dateTime
{
    return [[self dataSeries] getValues:fieldNames 
                             AtDateTime:dateTime];
}

-(NSDictionary *)getValues:(NSArray *) fieldNames 
                AtDateTime: (long) dateTime 
             WithTicOffset: (long) numberOfTics
{
    return [[self dataSeries] getValues:fieldNames 
                             AtDateTime:dateTime 
                          WithTicOffset:numberOfTics];
    
}

- (void) setupListofDataFields
{
    NSMutableDictionary *listOfDataFields = [[NSMutableDictionary alloc]init];
    if([self connected] == YES){
        FMResultSet *s = [[self db] executeQuery:@"SELECT DataTypeId, Description FROM DataType"];
        while ([s next]) {
            //retrieve values for each record
            [listOfDataFields setObject:[NSNumber numberWithInt:[s intForColumnIndex:0]] forKey:[s stringForColumnIndex:1]];
        }   
    }
    [self setDataFields:listOfDataFields];
}

- (NSArray *) getAllInterestRatesForCurrency: (NSString *) currencyCode 
                                   AndField: (NSString *) bidOrAsk
{
    int codeForInterestRate, fieldId;
    FMResultSet *rs;
    NSString *queryString;
    NSMutableArray *interestRateSeries = [[NSMutableArray alloc] init];
    
    codeForInterestRate = [[self db] intForQuery:[NSString stringWithFormat:@"SELECT SeriesId FROM SeriesName WHERE SeriesName = \'%@IR\'",currencyCode]];
    
    fieldId = [[[self dataFields] objectForKey:bidOrAsk] intValue];
    
    queryString = [NSString stringWithFormat:@"SELECT TimeDate, Value FROM DataSeries WHERE SeriesId = %d AND DataTypeId = %d ORDER BY TimeDate ASC",codeForInterestRate,fieldId]; 
    rs = [[self db] executeQuery:queryString];
    DataSeriesValue *entry;
    while ([rs next ]) 
    {
        entry = [[DataSeriesValue alloc] init];
        [entry setDateTime:[rs longForColumnIndex:0]];
        [entry setValue:[rs doubleForColumnIndex:1]/100];
        [entry setFieldName:bidOrAsk];
        [interestRateSeries addObject:entry];
    }
    return interestRateSeries;
}


-(long)getMinDataDateTimeForPair:(NSString *) fxPairName
{
    return [[[self minDateTimes] objectForKey:fxPairName] longValue];
}

-(long)getMaxDataDateTimeForPair:(NSString *) fxPairName
{
    return [[[self maxDateTimes] objectForKey:fxPairName] longValue];
}

-(long)getMinDateTimeForFullData
{
    NSArray *arrayOfFxPairs = [[self minDateTimes] allKeys];
    if([[self fxPairs] count] == 0){
        return 0;
    }else{
        long minDateTime = [[[self minDateTimes] objectForKey:[arrayOfFxPairs objectAtIndex:0]] longValue];
        for(int i = 1; i < [[self fxPairs] count]; i++){
            minDateTime = MAX(minDateTime, [[[self minDateTimes] objectForKey:[arrayOfFxPairs objectAtIndex:i]] longValue]);
        }
        return minDateTime;
    } 
}

-(long)getMaxDateTimeForFullData
{
    NSArray *arrayOfFxPairs = [[self maxDateTimes] allKeys];
    if([[self fxPairs] count] == 0){
        return 0;
    }else{
        long minDateTime = [[[self maxDateTimes] objectForKey:[arrayOfFxPairs objectAtIndex:0]] longValue];
        for(int i = 1; i < [[self fxPairs] count]; i++){
            minDateTime = MIN(minDateTime, [[[self maxDateTimes] objectForKey:[arrayOfFxPairs objectAtIndex:i]] longValue]);
        }
        return minDateTime;
    } 
}

- (void) clearDataStore
{
    [[self dataStore] removeAllObjects];
}

- (void) removeDerivedFromDataStore
{
    NSArray *fieldNames = [[self dataStore] allKeys];
    NSArray *dataFieldNames;
    NSString *fieldName;
    NSMutableDictionary  *dataDictionary;
    for(int i = 0; i < [fieldNames count]; i++){
        fieldName = [fieldNames objectAtIndex:i];
        if([[fieldName substringToIndex:4] isEqualToString:@"ARCH"]){
            dataDictionary = [[self dataStore] objectForKey:fieldName];
            dataFieldNames = [dataDictionary allKeys];
            for(int j = 0; j < [dataFieldNames count]; j++){
                if([[dataFieldNames objectAtIndex:j] isEqualToString:@"SIGNAL"]){
                    [dataDictionary removeObjectForKey:[dataFieldNames objectAtIndex:j]];
                }
                if([[dataFieldNames objectAtIndex:j] isEqualToString:@"SIGLTHRES"]){
                    [dataDictionary removeObjectForKey:[dataFieldNames objectAtIndex:j]];
                }
                if([[dataFieldNames objectAtIndex:j] isEqualToString:@"SIGUTHRES"]){
                    [dataDictionary removeObjectForKey:[dataFieldNames objectAtIndex:j]];
                }
            }
        }
    }
}

- (NSString *) dataStoreCode
{
    NSString *code;
    if([[self dataStore] objectForKey:@"CODE"]){
        code = [[self dataStore] objectForKey:@"CODE"];
    }
    return code;
}

- (long) dataStoreStart
{
    long startDateTime = 0;
    if([[self dataStore] objectForKey:@"STARTDATETIME"]){
        startDateTime = [[[self dataStore] objectForKey:@"STARTDATETIME"] longValue];
    }
    return startDateTime;
}

- (long) dataStoreEnd
{
    long endDateTime = 0;
    if([[self dataStore] objectForKey:@"ENDDATETIME"]){
        endDateTime = [[[self dataStore] objectForKey:@"ENDDATETIME"] longValue];
    }
    return endDateTime;
}

- (BOOL) okToUseDataStoreFrom: (long) startDateTime
                           To: (long) endDateTime
                 WithDataRate: (long) dataRate
                      ForCode: (NSString *) dataCode
{
    BOOL ok = YES;
    long start, end;
    NSString *code;
    if([[self dataStore] objectForKey:@"CODE"]){
        code = [[self dataStore] objectForKey:@"CODE"];
    }else{
        ok = NO;
    }
    if([[self dataStore] objectForKey:@"STARTDATETIME"]){
        start = [[[self dataStore] objectForKey:@"STARTDATETIME"] longValue];
        if(startDateTime < start){
            ok = NO;
        }
    }else{
        ok = NO;
    }
    if([[self dataStore] objectForKey:@"ENDDATETIME"]){
        end = [[[self dataStore] objectForKey:@"ENDDATETIME"] longValue];
        if(endDateTime > end){
            ok = NO;
        }
    }else{
        ok = NO;
    }
    if([[self dataStore] objectForKey:@"DATARATE"]){
        if(dataRate != [[[self dataStore] objectForKey:@"DATARATE"] longValue]){
            ok = NO;
        }
    }else{
        ok = NO;
    }
    return ok;
}


- (NSDictionary *) getDataFromStoreForCode: (long) archiveCode;
{
    BOOL success = NO;
    NSMutableDictionary *returnData;
    if([self dataStore]){
        if([[self dataStore] objectForKey:[NSString stringWithFormat:@"ARCH%d",abs((int)archiveCode)]]){
            returnData = [[self dataStore] objectForKey:[NSString stringWithFormat:@"ARCH%d",abs((int)archiveCode)]];
            success = YES;
            
        }
    }
    if(!success){
        returnData = [[NSMutableDictionary alloc] init];
    }
    [returnData setObject:[NSNumber numberWithBool:success] forKey:@"SUCCESS"];
    return returnData;
}



-(DataSeries *)createNewDataSeriesWithXData:(NSMutableData *) dateTimes 
                                   AndYData:(NSDictionary *) dataValues 
                              AndSampleRate:(long)newDataRate
{
    DataSeries *newDataSeries;
    newDataSeries = [[self dataSeries] getCopyOfStaticData];
    NSArray *fieldNames = [dataValues allKeys];
    
    CPTNumericData *dateTimeData; 
    dateTimeData = [CPTNumericData numericDataWithData:dateTimes dataType:CPTDataType(CPTIntegerDataType, 
                                                                                sizeof(long), 
                                                                                      CFByteOrderGetCurrent()) shape:nil];
    [newDataSeries setXData:dateTimeData];
    NSMutableData *newYData;
    CPTNumericData *newYDataForPlot;
    
    //[newDataSeries setYData:[[NSMutableDictionary alloc] init]];
    [[newDataSeries yData] removeAllObjects];
    for(int fieldIndex = 0; fieldIndex < [fieldNames count]; fieldIndex++){
        newYData = [dataValues  objectForKey:[fieldNames objectAtIndex:fieldIndex]];
        newYDataForPlot = [CPTNumericData numericDataWithData:newYData 
                                                     dataType:CPTDataType(CPTFloatingPointDataType, 
                                                                                        sizeof(double), 
                                                                                        CFByteOrderGetCurrent()) shape:nil];
        [[newDataSeries yData] setObject:newYDataForPlot forKey:[fieldNames objectAtIndex:fieldIndex]];
    }
    [newDataSeries setDataRate:newDataRate];
    [[newDataSeries dataViews] removeAllObjects];
    [newDataSeries setDataViewWithName:@"ALL"
                      AndStartDateTime:[[dateTimeData sampleValue:0] longValue]  
                        AndEndDateTime:[[dateTimeData sampleValue:([dateTimeData length]/[dateTimeData sampleBytes])-1] longValue]];
    return newDataSeries;
}

- (void) setData: (NSArray *) userData 
        FromFile: (NSString *) userDataFilename
{
    [self setFileDataAdded:YES];
    [self setFileDataFileName:userDataFilename];
    [self setFileData:userData];
}


-(BOOL) getDataForStartDateTime: (long) requestedStartDate
                 AndEndDateTime: (long) requestedEndDate
              AndExtraVariables: (NSArray *) extraVariables
                AndSignalSystem: (SignalSystem *) signalSystem
                    AndDataRate: (long) dataRate
                  WithStoreCode: (long) archiveCode
       WithRequestTruncatedFlag: (long *) requestTrucated
{
    BOOL success = YES;
    long adjustedStartDate, adjustedEndDate;
    long oldStartDateTime, oldEndDateTime;
    
    double databaseRateInSeconds =  [self databaseSamplingRate];
    
    if(archiveCode >= 0){
    
        adjustedStartDate = requestedStartDate;
        adjustedEndDate = requestedEndDate;
        
        if([[self dataSeries] length] != 0){
            oldStartDateTime = [[self dataSeries] minDateTime];
            oldEndDateTime = [[self dataSeries] maxDateTime];
            //If the day is nearly overlapping make it overlap
            if(adjustedStartDate > oldEndDateTime && (adjustedStartDate - oldEndDateTime) <= (7 * DAY_SECONDS)){
                adjustedStartDate = oldEndDateTime;
            }
        }
        
        //If the amount of data requested is more than 20% longer than our rule of thumb max data
        //then lessen the amount of data the function will return
        
        
        if(databaseRateInSeconds==0){
            databaseRateInSeconds = 1;
        }
        if((((double)adjustedEndDate-adjustedStartDate)/(MAX_DATA_CHUNK *databaseRateInSeconds)) > 1){
            adjustedEndDate = adjustedStartDate + (MAX_DATA_CHUNK* databaseRateInSeconds);
            *requestTrucated = 1;
        }else{
            *requestTrucated = 0;
        }
        
        adjustedStartDate = [EpochTime epochTimeAtZeroHour:adjustedStartDate];
        adjustedEndDate = [EpochTime epochTimeNextDayAtZeroHour:adjustedEndDate];
        
    }
    
    NSData *dateTimeData, *bidData, *askData, *midData;
    NSDictionary *bidAskMidDictionary, *dataFromStore;
    BOOL needToCalcDerivedVariables = NO;
    BOOL needToCalcSignal = NO;
    
    if(archiveCode < 0){
        dataFromStore =  [self getDataFromStoreForCode:archiveCode];
        dateTimeData = [dataFromStore objectForKey:@"DATETIME"];
        bidData = [dataFromStore objectForKey:@"BID"];
        askData = [dataFromStore objectForKey:@"ASK"];
        midData = [dataFromStore objectForKey:@"MID"];
  
        for(int i = 0; i < [extraVariables count]; i++){
            if([dataFromStore objectForKey:[extraVariables objectAtIndex:i]] == nil){
                needToCalcDerivedVariables = YES;
            }
        }
        if(signalSystem != nil && [dataFromStore objectForKey:@"SIGNAL"] == nil){
            needToCalcSignal = YES;
        }
    }else{
        bidAskMidDictionary = [self getBidAskMidDataFrom:adjustedStartDate
                                                      To:adjustedEndDate
                                            WithDataRate:dataRate];
    
        if(dataRate==databaseRateInSeconds){
            dateTimeData = [bidAskMidDictionary objectForKey:@"DATETIME"];
            bidData = [bidAskMidDictionary objectForKey:@"BID"];
            askData = [bidAskMidDictionary objectForKey:@"ASK"];
            midData = [bidAskMidDictionary objectForKey:@"MID"];
        }else{
            NSDictionary *resampledDataDictionary = [self resampleData:bidAskMidDictionary
                                                        DownToDataRate:dataRate
                                                          FromDateTime:requestedStartDate];
            dateTimeData = [resampledDataDictionary objectForKey:@"DATETIME"];
            bidData = [resampledDataDictionary objectForKey:@"BID"];
            askData = [resampledDataDictionary objectForKey:@"ASK"];
            midData = [resampledDataDictionary objectForKey:@"MID"];
        }
    }
    long *dateTimeArray = (long *) [dateTimeData bytes];
    long newDataLength = [dateTimeData length]/(sizeof(long));
    
    NSMutableDictionary *fileDataDictionary;
    NSMutableData *fileDataSeries;
    NSMutableData *fileDataDoubleArrayData;
    double **fileDataDoubleArrays;
    NSArray *fileDataFieldNames;
    if([self fileDataAdded]){
        fileDataDictionary = [[NSMutableDictionary alloc] init ];
        fileDataFieldNames = [[self fileData] objectAtIndex:0];
        
        fileDataDoubleArrayData = [[NSMutableData alloc] initWithLength:([fileDataFieldNames count]-1) * sizeof(double *)];
        fileDataDoubleArrays = (double **)[fileDataDoubleArrayData mutableBytes];
        
        for(int i = 0; i < [fileDataFieldNames count]-1;i++){
            fileDataSeries = [[NSMutableData alloc] initWithLength:newDataLength * sizeof(double)];
            fileDataDoubleArrays[i] = [fileDataSeries mutableBytes];
            [fileDataDictionary setObject:fileDataSeries forKey:[fileDataFieldNames objectAtIndex:(i+1)]];
        }
        
        long indexOnFileData, indexOnDbData = 0;
        long validFromInc, validToEx;
        if([[self fileData] count] > 2){
            for(indexOnFileData = 1; indexOnFileData<[[self fileData] count]; indexOnFileData++){
                NSArray *lineOfData = [[self fileData] objectAtIndex:indexOnFileData];
                validFromInc = (long)[[lineOfData objectAtIndex:0] longLongValue];
                if(indexOnFileData < [[self fileData] count]-1){
                    validToEx =  (long)[[[[self fileData] objectAtIndex:indexOnFileData+1] objectAtIndex:0] longLongValue];
                }else{
                    validToEx = dateTimeArray[newDataLength-1] +1;
                }
                
                if(indexOnFileData==1){
                    while(validFromInc > dateTimeArray[indexOnDbData] && indexOnDbData < newDataLength ){
                        for(int fieldIndex = 0; fieldIndex < [fileDataFieldNames count]-1; fieldIndex++){
                            fileDataDoubleArrays[fieldIndex][indexOnDbData] =  0.0;
                        }
                        indexOnDbData++;
                    }
                }
                
                while(dateTimeArray[indexOnDbData] >= validFromInc && dateTimeArray[indexOnDbData] < validToEx && indexOnDbData < newDataLength){
                    for(int fieldIndex = 0; fieldIndex < [fileDataFieldNames count]-1; fieldIndex++){
                        fileDataDoubleArrays[fieldIndex][indexOnDbData] =  [[lineOfData objectAtIndex:fieldIndex+1] doubleValue];
                    }
                    indexOnDbData++;
                }
                if(indexOnDbData >= newDataLength)
                {
                    break;
                }
            }
        }
    }
    

    NSDictionary *derivedDataDictionary;
    NSArray *derivedDataNames;
    NSData *derivedData;
    CPTNumericData *derivedCPTData;
    
    BOOL useOldData;
    NSInteger oldDataStartIndex;
    CPTNumericData *oldDateTimeData;
    if(archiveCode >= 0){
        if([[self dataSeries] length]==0 ){
            useOldData = NO;
        }else{
            if([[self dataSeries] dataRate] != dataRate){
                useOldData = NO;
            }else{
                if(dateTimeArray[0] > oldEndDateTime){
                    useOldData = NO;
                }else {
                    useOldData = YES;
                }
            }
        }
        if(useOldData){
            oldDataStartIndex = [[self dataSeries] length] - 1;
            long *oldDateTimeArray;
            oldDateTimeData =  [[self dataSeries] xData];
            oldDateTimeArray = (long *)[oldDateTimeData bytes];
            while(oldDateTimeArray[oldDataStartIndex] > dateTimeArray[0] && oldDataStartIndex > 0){
                oldDataStartIndex--;
            }
            
            if(oldDateTimeArray[oldDataStartIndex] != dateTimeArray[0]){
                useOldData = NO;
            }
        }
    }
    
    NSMutableArray *overriddenNames = [[NSMutableArray alloc] init];
    if(success && ![self cancelProcedure]){
        // If we need extra dervied data fields get them here.
        if([extraVariables count]>0){
            if(archiveCode > 0 || needToCalcDerivedVariables || needToCalcSignal){
                NSMutableDictionary *newDataDictionary = [[NSMutableDictionary alloc] init];
                NSMutableDictionary *parameters = [[NSMutableDictionary alloc] init];
                
                if(useOldData){
                    [parameters setObject:[NSNumber numberWithBool:NO] forKey:@"ALLNEWDATA"];
                }else{
                    [parameters setObject:[NSNumber numberWithBool:YES] forKey:@"ALLNEWDATA"];
                }
                
                [newDataDictionary setObject:dateTimeData forKey:@"DATETIME"];
                [newDataDictionary setObject:bidData forKey:@"BID"];
                [newDataDictionary setObject:askData forKey:@"ASK"];
                [newDataDictionary setObject:midData forKey:@"MID"];
                [newDataDictionary setObject:[NSNumber numberWithDouble:[[self dataSeries] pipSize]] forKey:@"PIPSIZE"]
                ;
                if(useOldData){
                    [parameters setObject:[[self dataSeries] yData] forKey:@"OLDDATA"];
                    [parameters setObject:[[self dataSeries] xData] forKey:@"OLDDATETIME"];
                    [parameters setObject:[NSNumber numberWithInteger:oldDataStartIndex] forKey:@"OVERLAPINDEX"];
                }
                if(needToCalcSignal && !needToCalcDerivedVariables){
                    derivedDataDictionary =  [DataProcessor addToDataSeries: dataFromStore
                                                           DerivedVariables: [[NSArray alloc] init]
                                                           WithTrailingData: parameters
                                                            AndSignalSystem: signalSystem];
                }else{
                    derivedDataDictionary =  [DataProcessor addToDataSeries: newDataDictionary
                                                           DerivedVariables: extraVariables
                                                           WithTrailingData: parameters
                                                            AndSignalSystem: signalSystem];
                }
                
                if([derivedDataDictionary objectForKey:@"SUCCESS"] != nil){
                    if(![[derivedDataDictionary objectForKey:@"SUCCESS"] boolValue]){
                        success = NO;
                        [NSException raise:@"No success in creating derived data"
                                    format:@""];
                    }else{
                        derivedDataNames = [derivedDataDictionary allKeys];
                    }
                }else{
                    success = NO;
                    [NSException raise:@"Something wrong creating derived data, cannot find the success variable"           format:@""];
                }
            }
        }
    }
    
    if(success && ![self cancelProcedure]){
        
        CPTNumericData *dateCPTData, *bidCPTData, *askCPTData, *midCPTData;
        
        dateCPTData = [CPTNumericData numericDataWithData:dateTimeData
                                                 dataType:CPTDataType(CPTIntegerDataType,
                                                                      sizeof(long),
                                                                      CFByteOrderGetCurrent())
                                                    shape:nil];
        bidCPTData = [CPTNumericData numericDataWithData:bidData
                                                dataType:CPTDataType(CPTFloatingPointDataType,
                                                                     sizeof(double),
                                                                     CFByteOrderGetCurrent())
                                                   shape:nil];
        askCPTData = [CPTNumericData numericDataWithData:askData
                                                dataType:CPTDataType(CPTFloatingPointDataType,
                                                                     sizeof(double),
                                                                     CFByteOrderGetCurrent())
                                                   shape:nil];
        midCPTData = [CPTNumericData numericDataWithData:midData
                                                dataType:CPTDataType(CPTFloatingPointDataType,
                                                                     sizeof(double),
                                                                     CFByteOrderGetCurrent())
                                                   shape:nil];
       
        
        [[self dataSeries] setXData:dateCPTData];
        [[[self dataSeries] yData] removeAllObjects];
        [[[self dataSeries] yData] setObject:bidCPTData forKey:@"BID"];
        [[[self dataSeries] yData] setObject:askCPTData forKey:@"ASK"];
        [[[self dataSeries] yData] setObject:midCPTData forKey:@"MID"];
        [[self dataSeries] setDataRate:dataRate];
        
        
       
           
        NSMutableDictionary *dataSource;
        if(archiveCode < 0){
            dataSource = [dataFromStore mutableCopy];
            if(needToCalcDerivedVariables || needToCalcSignal){
                for(int i = 0; i < [derivedDataNames count]; i++){
                    [dataSource setObject:[derivedDataDictionary objectForKey:[derivedDataNames objectAtIndex:i]]
                                   forKey:[derivedDataNames objectAtIndex:i]];
                }
             }
        }else{
            dataSource = [derivedDataDictionary mutableCopy];
        }
    
        
        NSArray *dataSourceDataNames = [dataSource allKeys];
        
        if(success){
            if(archiveCode > 0 || needToCalcDerivedVariables){
                if(archiveCode==1){
                    [self clearDataStore];
                }
                
                NSMutableDictionary *dataArchive = [[NSMutableDictionary alloc] init];
                [dataArchive setObject:dateTimeData forKey:@"DATETIME"];
                [dataArchive setObject:bidData forKey:@"BID"];
                [dataArchive setObject:askData forKey:@"ASK"];
                [dataArchive setObject:midData forKey:@"MID"];
                if([extraVariables count]>0){
                    for(int i = 0; i <[derivedDataNames count];i++){
                        [dataArchive setObject:[derivedDataDictionary objectForKey:[derivedDataNames objectAtIndex:i]]
                                        forKey:[derivedDataNames objectAtIndex:i]];
                    }
                }
                [[self dataStore] setObject:dataArchive
                                     forKey:[NSString stringWithFormat:@"ARCH%ld",archiveCode]];
                if(archiveCode == 1){
                    [[self dataStore] setObject:[[self dataSeries] name]
                                         forKey:[NSString stringWithFormat:@"CODE"]];
                    [[self dataStore] setObject:[NSNumber numberWithLong:dateTimeArray[0]]
                                         forKey:[NSString stringWithFormat:@"STARTDATETIME"]];
                    [[self dataStore] setObject:[NSNumber numberWithLong:requestedEndDate]
                                         forKey:[NSString stringWithFormat:@"ENDDATETIME"]];
                }
            }
        }
         
        
//        for(int i = 0; i < [derivedDataNames count]; i++){
//            if([self fileDataAdded ] && [overriddenNames count] > 0){
//                NSString *crossCheckedKey = [derivedDataNames objectAtIndex:i];
//                for(int j = 0; j < [overriddenNames count]; j++){
//                    if([[overriddenNames objectAtIndex:j] isEqualToString:crossCheckedKey]){
//                        crossCheckedKey = [NSString stringWithFormat:@"%@**",crossCheckedKey];
//                    }
//                }
//                [[[self dataSeries] yData] setObject:derivedCPTData forKey:crossCheckedKey];
//            }else{
//                [[[self dataSeries] yData] setObject:derivedCPTData forKey:[derivedDataNames objectAtIndex:i]];
//            }
//        }
        
        if([self fileDataAdded]){
            for(int i = 0; i < [dataSourceDataNames count];i++){
                for(int j = 0; j < [fileDataFieldNames count]; j++){
                    if([[dataSourceDataNames objectAtIndex:i] isEqualToString:[fileDataFieldNames objectAtIndex:j]]){
                        [overriddenNames addObject:[dataSourceDataNames objectAtIndex:i]];
                    }
                }
            }
        }
        
        for(int i = 0; i < [dataSourceDataNames count]; i++){
            if(![[dataSourceDataNames objectAtIndex:i] isEqualToString:@"SUCCESS"]){
                derivedData = [dataSource objectForKey: [dataSourceDataNames objectAtIndex:i]];
                
                derivedCPTData = [CPTNumericData numericDataWithData:derivedData
                                                            dataType:CPTDataType(CPTFloatingPointDataType,
                                                                                 sizeof(double),
                                                                                 CFByteOrderGetCurrent())
                                                               shape:nil];
               
                if([self fileDataAdded ] && [overriddenNames count] > 0){
                    NSString *substituteKey = [dataSourceDataNames objectAtIndex:i];
                    for(int j = 0; j < [overriddenNames count]; j++){
                        if([[overriddenNames objectAtIndex:j] isEqualToString:substituteKey]){
                            substituteKey = [NSString stringWithFormat:@"%@**",substituteKey];
                        }
                    }
                    [[[self dataSeries] yData] setObject:derivedCPTData forKey:substituteKey];
                }else{
                    [[[self dataSeries] yData] setObject:derivedCPTData
                                                  forKey:[dataSourceDataNames objectAtIndex:i]];
                }
            }
        }
        
        
        if([self fileDataAdded]){
            NSData *fileDataExpanded;
            CPTNumericData *fileCPTData;
            for(int fileDataIndex = 0; fileDataIndex < [fileDataFieldNames count]-1; fileDataIndex++){
                fileDataExpanded = [fileDataDictionary objectForKey:[fileDataFieldNames objectAtIndex:fileDataIndex+1]];
                fileCPTData = [CPTNumericData numericDataWithData:fileDataExpanded
                                                         dataType:CPTDataType(CPTFloatingPointDataType,
                                                                              sizeof(double),
                                                                              CFByteOrderGetCurrent())
                                                            shape:nil];
                [[[self dataSeries] yData] setObject:fileCPTData forKey:[fileDataFieldNames objectAtIndex:fileDataIndex+1]];
            }
        }

        
        
        [[[self dataSeries] dataViews] removeAllObjects];
        [[self dataSeries] setDataViewWithName:@"ALL"
                              AndStartDateTime:dateTimeArray[0]
                                AndEndDateTime:dateTimeArray[newDataLength-1]];
    }
    
    return success;
}


- (NSDictionary *) getBidAskMidDataFrom: (long) startDateTime
                                     To: (long) endDateTime
                           WithDataRate: (long) dataRate
{
    NSString *queryString;
    
    // Differnce when using old data is that startdate is not included in new data
    // as it is part of the old data
    long queryStart, queryEnd, resultCount;
    
    queryStart = [[self db] longForQuery:[NSString stringWithFormat:@"SELECT TimeDate FROM DataSeries WHERE SeriesId = %ld AND DataTypeId = %d AND TimeDate <= %ld ORDER BY TimeDate DESC LIMIT 1",[[self dataSeries] dbId],1,startDateTime]];
    
    queryEnd = [[self db] longForQuery:[NSString stringWithFormat:@"SELECT TimeDate FROM DataSeries WHERE SeriesId = %ld AND DataTypeId = %d AND TimeDate >= %ld ORDER BY TimeDate ASC LIMIT 1",[[self dataSeries] dbId],1,endDateTime]];
    
    //This only works as we don't have data as early as this, 0 is a valid date around 1970
    if(queryStart < 1){
        queryStart = startDateTime;
    }
    
    if(queryEnd < 1){
        queryEnd = endDateTime;
    }
    
    resultCount = [[self db] intForQuery:[NSString stringWithFormat:@"SELECT COUNT(*) FROM DataSeries WHERE SeriesId = %ld AND DataTypeId = %d AND TimeDate > %ld AND TimeDate <= %ld",[[self dataSeries] dbId],1,queryStart,queryEnd]];
    
    queryString = [NSString stringWithFormat:@"SELECT DS1.TimeDate, DS1.Value, DS2.Value FROM DataSeries DS1 INNER JOIN DataSeries DS2 ON DS1.TimeDate = DS2.TimeDate AND DS1.SeriesId = DS2.SeriesId  WHERE DS1.SeriesId = %ld AND DS1.DataTypeId = %d AND DS2.DataTypeId = %d AND DS1.TimeDate >= %ld AND DS1.TimeDate <= %ld ORDER BY DS1.TimeDate ASC", [[self dataSeries] dbId],1,2,queryStart,queryEnd];
    
    
    
    NSMutableData *newDateLongsData, *newBidDoublesData, *newAskDoublesData,  *newMidDoublesData;
    double *newBidDoublesArray, *newAskDoublesArray, *newMidDoublesArray;
    long *newDateLongsArray;
    FMResultSet *rs;
    long recordsetIndex = 0;
    double progressMeasure = 0.0, progressMeasureUpdate = 0.0;
    
    newDateLongsData = [[NSMutableData alloc] initWithLength:resultCount * sizeof(long)];
    newDateLongsArray = (long *)[newDateLongsData mutableBytes];
    
    newBidDoublesData = [[NSMutableData alloc] initWithLength:resultCount * sizeof(double)];
    newBidDoublesArray = (double *)[newBidDoublesData mutableBytes];
    
    newAskDoublesData = [[NSMutableData alloc] initWithLength:resultCount * sizeof(double)];
    newAskDoublesArray = (double *)[newAskDoublesData mutableBytes];
   
    newMidDoublesData = [[NSMutableData alloc] initWithLength:resultCount * sizeof(double)];
    newMidDoublesArray = (double *)[newMidDoublesData mutableBytes];
    
    rs = [[self db] executeQuery:queryString];
    
    while ([rs next ])
    {
        newDateLongsArray[recordsetIndex] = [rs longForColumnIndex:0];
        newBidDoublesArray[recordsetIndex] = [rs doubleForColumnIndex:1];
        newAskDoublesArray[recordsetIndex] = [rs doubleForColumnIndex:2];
        newMidDoublesArray[recordsetIndex] = (newBidDoublesArray[recordsetIndex] + newAskDoublesArray[recordsetIndex])/2;
        progressMeasure = (double)(newDateLongsArray[recordsetIndex]-queryStart)/(queryEnd-queryStart);
        recordsetIndex ++;
        if(progressMeasure - progressMeasureUpdate > 0.05){
            progressMeasureUpdate = progressMeasure;
            if([self doThreads]){
                [self performSelectorOnMainThread:@selector(readingRecordSetProgress:) withObject:[NSNumber numberWithDouble:progressMeasureUpdate] waitUntilDone:NO];
                
                NSNumberFormatter *numberFormatter = [[NSNumberFormatter alloc] init];
                [numberFormatter setFormat:@"#,###"];
                NSNumber *numberOfRecords = [NSNumber numberWithLong:recordsetIndex];
                
                [self performSelectorOnMainThread:@selector(readingRecordSetMessage:) withObject:[NSString stringWithFormat:@"Data records read: %@",[numberFormatter stringForObjectValue:numberOfRecords]] waitUntilDone:NO];
            }
        }
    }
    NSDictionary *returnData = [[NSDictionary alloc] initWithObjectsAndKeys:newDateLongsData,@"DATETIME", newBidDoublesData, @"BID", newAskDoublesData, @"ASK", newMidDoublesData, @"MID", nil];
    return returnData;
}

- (NSDictionary *) resampleData: (NSMutableDictionary *) dataDictionary
                 DownToDataRate: (long) dataRate
                   FromDateTime: (long) startDateTime
{
    NSMutableDictionary *returnDataDictionary = [[NSMutableDictionary alloc] init];
    NSData *dateTimeData = [dataDictionary objectForKey:@"DATETIME"];
    NSData *bidData = [dataDictionary objectForKey:@"BID"];
    NSData *askData = [dataDictionary objectForKey:@"ASK"];
    long *dateTimeArray = (long *)[dateTimeData bytes];
    long dataLength = [dateTimeData length]/sizeof(long);
    double *bidArray = (double *)[bidData bytes];
    double *askArray = (double *)[askData bytes];
    
    long dataStartDateTime = dateTimeArray[0];
    long dataEndDateTime = dateTimeArray[dataLength-1];
    
    long maxData = (dataEndDateTime- dataStartDateTime)/dataRate;

    
    NSMutableData *intermediateDateTimeData,  *intermediateBidData, *intermediateAskData;
    long *intermediateDateTimeArray;
    double *intermediateBidArray, *intermediateAskArray;
    
    if(maxData > 0 ){
        //NSMutableData *tempData;
        intermediateDateTimeData = [[NSMutableData alloc] initWithLength:maxData * sizeof(long)];
        intermediateDateTimeArray = (long *)[intermediateDateTimeData mutableBytes];
        
        intermediateBidData = [[NSMutableData alloc] initWithLength:maxData * sizeof(double)];
        intermediateBidArray = (double *)[intermediateBidData mutableBytes];
        
        intermediateAskData = [[NSMutableData alloc] initWithLength:maxData * sizeof(double)];
        intermediateAskArray = (double *)[intermediateAskData mutableBytes];
        
        long currentDateTime = startDateTime;
        long sampleIndex = 0;
        
        int dataIndex = 0;
        while(dataIndex < dataLength && currentDateTime < dateTimeArray[dataLength-1]){
            while(currentDateTime < dateTimeArray[dataIndex]){
                currentDateTime = currentDateTime + dataRate;
            }
            while(dataIndex < (dataLength-2) && dateTimeArray[dataIndex+1] <= currentDateTime){
                dataIndex++;
            }
            
            if(dateTimeArray[dataIndex] == currentDateTime){
                intermediateDateTimeArray[sampleIndex] = currentDateTime;
                intermediateBidArray[sampleIndex] = bidArray[dataIndex];
                intermediateAskArray[sampleIndex] = askArray[dataIndex];
                 sampleIndex++;
                if(dateTimeArray[dataIndex] > currentDateTime){
                    NSLog(@"CHECK A");
                }
                if(currentDateTime- dateTimeArray[dataIndex] >= dataRate){
                    NSLog(@"CHECK B");
                }
            }
            if(dateTimeArray[dataIndex] > currentDateTime - dataRate && dateTimeArray[dataIndex] < currentDateTime){
                intermediateDateTimeArray[sampleIndex] = currentDateTime;
                intermediateBidArray[sampleIndex] = bidArray[dataIndex];
                intermediateAskArray[sampleIndex] = askArray[dataIndex];
                sampleIndex++;
                if(dateTimeArray[dataIndex] > currentDateTime){
                    NSLog(@"CHECK A");
                }
                if(currentDateTime - dateTimeArray[dataIndex] >= dataRate){
                    NSLog(@"CHECK B");
                }
            }
            currentDateTime = currentDateTime + dataRate;
        }
        
        long newDataLength = sampleIndex;
        
        NSMutableData *newDateTimeData, *newBidData, *newAskData, *newMidData;
        double *newBidArray, *newAskArray, *newMidArray;
        long *newDateTimeArray;
        
        newDateTimeData = [[NSMutableData alloc] initWithLength:newDataLength * sizeof(long)];
        newDateTimeArray = (long *)[newDateTimeData mutableBytes];
        
        newBidData = [[NSMutableData alloc] initWithLength:newDataLength * sizeof(double)];
        newBidArray = (double *)[newBidData mutableBytes];
        
        newAskData = [[NSMutableData alloc] initWithLength:newDataLength * sizeof(double)];
        newAskArray = (double *)[newAskData mutableBytes];
        
        newMidData = [[NSMutableData alloc] initWithLength:newDataLength * sizeof(double)];
        newMidArray = (double *)[newMidData mutableBytes];
        
        for(int i= 0 ; i < newDataLength; i++){
            newDateTimeArray[i] = intermediateDateTimeArray[i];
            newBidArray[i] = intermediateBidArray[i];
            newAskArray[i] = intermediateAskArray[i];
            newMidArray[i] = (intermediateBidArray[i] + intermediateAskArray[i])/2;
        }
        
        [returnDataDictionary setObject:newDateTimeData forKey:@"DATETIME"];
        [returnDataDictionary setObject:newBidData forKey:@"BID"];
        [returnDataDictionary setObject:newAskData forKey:@"ASK"];
        [returnDataDictionary setObject:newMidData forKey:@"MID"];
    }
    return returnDataDictionary;
}

@end

