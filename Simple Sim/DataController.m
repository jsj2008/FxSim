//
//  DataController.m
//  Simple Sim
//
//  Created by Martin O'Connor on 14/01/2012.
//  Copyright (c) 2012 OCONNOR RESEARCH. All rights reserved.
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

#define DATABASE_GRANULARITY_SECONDS 1
//30*24*60*60 
#define MAX_DATA_CHUNK  2592000 
//360*24*60*60 
//#define MAX_DATA_CHUNK 31104000

//24*60*60
#define DAY_SECONDS 86400

@interface DataController()
- (void) setupListofPairs;
- (void) setupListofDataFields;
- (void) readingRecordSetsProgress:(NSNumber *) progressFraction;
- (void) progressAsFraction:(NSNumber *) progressValue;
@end

@implementation DataController

NSString *dbPath = @"/Users/Martin/Projects/Databases/timeseries.db";
FMDatabase *db;

-(id)init
{  
    self = [super init];
    if(self){
        db = [FMDatabase databaseWithPath:dbPath];
        delegate = nil;
        doThreads = NO;
        adhocDataAdded = NO;
        _fileDataAdded = NO;
        if (![db open]) {
            db = nil;
            connected = NO;
        }else{
            connected = YES;
            [self setupListofPairs];
            [self setupListofDataFields];
        }
    }
    return self;
}

-(void)dealloc
{
    if(db)
    {
        if([db close]){
            NSLog(@"Database successfully closed");
            
        }else{
            NSLog(@"Problem closing database");
        }
    }
}

- (BOOL) setupDataSeriesForName: (NSString *) dataSeriesName 
                    AndStrategy: (NSString *) strategyString
{
    BOOL success = YES;
    double pipSize;
    NSString *seriesName; 
    int dbid = [[fxPairs objectForKey:dataSeriesName] intValue]; 
    @try
    {
        if([self connected] == YES)
        {
            seriesName = [db stringForQuery:[NSString stringWithFormat:@"SELECT SeriesName FROM SeriesName WHERE SeriesId = %d", dbid]];
            pipSize = [db doubleForQuery:[NSString stringWithFormat:@"SELECT PipSize FROM SeriesName WHERE SeriesId = %d", dbid]];
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
        
        dataSeries = [[DataSeries alloc] initWithName:seriesName 
                                             AndDbTag:dbid 
                                           AndPipSize:pipSize 
                                          AndStrategy:strategyString];
    }
    return success;
}


-(int)dataGranularity
{
    return DATABASE_GRANULARITY_SECONDS;
}

-(void)setDelegate:(id)del
{
    delegate = del;
}

-(id)delegate 
{ 
    return delegate;
}

- (BOOL) doThreads
{
    return [self doThreads];
}

- (void) setDoThreads:(BOOL)doThreadedProcedures
{
    doThreads = doThreadedProcedures;
}

- (void) readingRecordSetsProgress:(NSNumber *) progressFraction;
{
    if(delegate != nil){
        if([delegate respondsToSelector:@selector(readingRecordSetsProgress:)])
        {
            [delegate readingRecordSetsProgress:progressFraction];
        }else{
            NSLog(@"Delegate does not respond to \'readingRecordSetsProgress:\'");
        }
    }
}

-(void) progressAsFraction:(NSNumber *) progressValue
{
    if(delegate != nil){
        if([delegate respondsToSelector:@selector(progressAsFraction:)])
        {
            [delegate progressAsFraction:progressValue];
        }else{
            NSLog(@"Delegate does not respond to \'progressAsFraction:\'");
        }
    }
}

-(long)getDataSeriesLength
{
    return [dataSeries length];
}

-(long)getMinDateTimeForLoadedData
{
    long minDateTime = 0;
    if(dataSeries != nil)
    {
        minDateTime = [dataSeries minDateTime];
    }
    return minDateTime; 
}

-(long)getMaxDateTimeForLoadedData
{
    long maxDateTime = 0;
    if(dataSeries != nil)
    {
        maxDateTime = [dataSeries maxDateTime];
    }
    return maxDateTime; 
}

-(NSArray *)getFieldNames
{
    return [dataSeries getFieldNames];
}

- (BOOL) strategyUnderstood:(NSString *) strategyString
{
    return [DataProcessor strategyUnderstood:strategyString];
}

- (void) setupListofPairs{
    NSMutableDictionary *retrievedPairs = [[NSMutableDictionary alloc]init];
    NSMutableDictionary *dataMinDateTimes = [[NSMutableDictionary alloc]init];
    NSMutableDictionary *dataMaxDateTimes = [[NSMutableDictionary alloc]init];
    
    NSString *seriesName;
    if([self connected] == YES){
        FMResultSet *s = [db executeQuery:@"SELECT SN.SeriesId, SN.SeriesName, DDR.MinDate, DDR.MaxDate FROM SeriesName SN INNER JOIN DataDateRange DDR ON SN.SeriesId = DDR.SeriesId  WHERE SN.Type='FX'"];
        while ([s next]) {
            
            //retrieve values for each record
            seriesName = [s stringForColumnIndex:1]; 
            
            [retrievedPairs setObject:[NSNumber numberWithInt:[s intForColumnIndex:0]]  forKey:seriesName];
            [dataMinDateTimes setObject:[NSNumber numberWithLong:[s longForColumnIndex:2]] forKey:seriesName];
            [dataMaxDateTimes setObject:[NSNumber numberWithLong:[s longForColumnIndex:3]] forKey:seriesName];
        }
    }
    fxPairs = retrievedPairs;
    minDateTimes = dataMinDateTimes;
    maxDateTimes = dataMaxDateTimes;
}

- (NSDictionary *) getValuesForFields:(NSArray *) fieldNames 
                           AtDateTime: (long) dateTime
{
    return [dataSeries getValues:fieldNames 
                       AtDateTime:dateTime];
}

- (void) setupListofDataFields
{
    NSMutableDictionary *listOfDataFields = [[NSMutableDictionary alloc]init];
    if([self connected] == YES){
        FMResultSet *s = [db executeQuery:@"SELECT DataTypeId, Description FROM DataType"];
        while ([s next]) {
            //retrieve values for each record
            [listOfDataFields setObject:[NSNumber numberWithInt:[s intForColumnIndex:0]] forKey:[s stringForColumnIndex:1]];
        }   
    }
    dataFields = listOfDataFields;
}

- (DataSeriesValue *) valueFromDataBaseForName: (NSString *) name 
                                   AndDateTime: (long) dateTime 
                                      AndField: (NSString *) field
{
    DataSeriesValue *returnObject = [[DataSeriesValue alloc] init];
    
    int fieldId;
    int seriesId;
    BOOL invert = NO;
    
    if([[name substringFromIndex:3] isEqualToString:[name substringToIndex:3]]){
        [returnObject setValue:1.0];
        [returnObject setDateTime:dateTime];
        [returnObject setFieldName:field];
    }else{
        if([fxPairs objectForKey:name]==nil)
        {
            seriesId = [[fxPairs objectForKey:
                         [NSString stringWithFormat:@"%@%@",[name substringFromIndex:3],[name substringToIndex:3]]] 
                        intValue];
            invert = YES;
        }else{
            seriesId = [[fxPairs objectForKey:name] intValue]; 
        }
        
        NSString *queryString;
        FMResultSet *rs;
        fieldId = [[dataFields objectForKey:field] intValue];
        queryString = [NSString stringWithFormat:@"SELECT TimeDate, Value FROM DataSeries WHERE SeriesId = %d AND DataTypeId = %d AND TimeDate <= %lu ORDER BY TimeDate DESC LIMIT 1",seriesId,fieldId, dateTime]; 
        rs = [db executeQuery:queryString];
        [rs next ]; 
        [returnObject  setDateTime:[rs longForColumnIndex:0]];
        if(invert){
            [returnObject setValue:1/[rs doubleForColumnIndex:1]];
        }else{
            [returnObject setValue:[rs doubleForColumnIndex:1]];
        }
        [returnObject setFieldName:field];
    }
    return returnObject;
}

- (DataSeriesValue *) valueFromDataBaseForFxPair: (NSString *) name 
                                     AndDateTime: (long) dateTime 
                                        AndField: (NSString *) field
{
    DataSeriesValue *returnObject = [[DataSeriesValue alloc] init];
    
    int fieldId;
    int seriesId;
    BOOL invert = NO;
    
    if([[name substringFromIndex:3] isEqualToString:[name substringToIndex:3]]){
        [returnObject setValue:1.0];
        [returnObject setDateTime:dateTime];
        [returnObject setFieldName:field];
    }else{
        if([fxPairs objectForKey:name]==nil)
        {
            seriesId = [[fxPairs objectForKey:
                     [NSString stringWithFormat:@"%@%@",[name substringFromIndex:3],[name substringToIndex:3]]] 
                    intValue];
            invert = YES;
        }else{
            seriesId = [[fxPairs objectForKey:name] intValue]; 
        }
    
        NSString *queryString;
        FMResultSet *rs;

        fieldId = [[dataFields objectForKey:field] intValue];
        
        queryString = [NSString stringWithFormat:@"SELECT TimeDate, Value FROM DataSeries WHERE SeriesId = %d AND DataTypeId = %d AND TimeDate <= %lu ORDER BY TimeDate DESC LIMIT 1",seriesId,fieldId, dateTime]; 
        rs = [db executeQuery:queryString];
        [rs next ]; 
        [returnObject  setDateTime:[rs longForColumnIndex:0]];
        if(invert){
            [returnObject setValue:1/[rs doubleForColumnIndex:1]];
        }else{
            [returnObject setValue:[rs doubleForColumnIndex:1]];
        }
        [returnObject setFieldName:field];
    }
    return returnObject;
}

- (NSArray *) getAllInterestRatesForCurrency: (NSString *) currencyCode 
                                   AndField: (NSString *) bidOrAsk
{
    int codeForInterestRate, fieldId;
    FMResultSet *rs;
    NSString *queryString;
    NSMutableArray *interestRateSeries = [[NSMutableArray alloc] init];
    
    codeForInterestRate = [db intForQuery:[NSString stringWithFormat:@"SELECT SeriesId FROM SeriesName WHERE SeriesName = \'%@IR\'",currencyCode]];
    
    fieldId = [[dataFields objectForKey:bidOrAsk] intValue];
    
    queryString = [NSString stringWithFormat:@"SELECT TimeDate, Value FROM DataSeries WHERE SeriesId = %d AND DataTypeId = %d ORDER BY TimeDate ASC",codeForInterestRate,fieldId]; 
    rs = [db executeQuery:queryString];
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


- (void) setDataForStartDateTime: (long) requestedStartDate 
                  AndEndDateTime: (long) requestedEndDate 
                 AndSamplingRate: (long) samplingRate
                     WithSuccess: (int *) successAsInt
                     AndUpdateUI: (BOOL) doUpdateUI
                  
{
    DataSeries *retrievedData;
    retrievedData = [self retrieveDataForStartDateTime: requestedStartDate 
                                        AndEndDateTime: requestedEndDate 
                                       AndSamplingRate: samplingRate
                                           WithSuccess: successAsInt
                                           AndUpdateUI: doUpdateUI];
    dataSeries = retrievedData;
}


- (DataSeries *) retrieveDataForStartDateTime: (long) requestedStartDate 
                               AndEndDateTime: (long) requestedEndDate 
                              AndSamplingRate: (long) samplingRate
                                  WithSuccess: (int *) successAsInt
                                  AndUpdateUI: (BOOL) doUpdateUI
{
    BOOL success = YES;
    long sampleDateTime;
    long *dateTimeArray;
    NSMutableData *arrayOfDataArraysData;
    double **arrayOfDataArrays;
    
    CPTNumericData *dataArray;
    long oldDataIndex, newDataIndex;
    long oldDataLength;
    NSArray *fieldNames;
    int numberOfFields;
    long maxData;
    int dataFieldIndex;
    
    NSMutableData *intermediateSampledDateTimesData;
    NSMutableData *intermediateMappedDateTimesData;
    NSMutableData *intermediateDataValuesArray;
    
    NSMutableArray *intermediateDataArray;
    
    long *intermediateSampledDateTimesArray  = NULL;
    long *intermediateMappedDateTimesArray  = NULL;
    double **intermediateDataValuesPointerArray = NULL;
    
    NSNumber *progressAmount;
    NSString *userMessage;
    DataSeries *newDataSeries;
    int requestTruncated = 0;
    
    
    NSMutableArray *statsArray = [[NSMutableArray alloc] init];
    
    success = [self getMoreDataForStartDateTime: requestedStartDate 
                                 AndEndDateTime: requestedEndDate
                         AndReturningStatsArray: statsArray
                       WithRequestTruncatedFlag: &requestTruncated]; 
    
    if(success && !cancelProcedure){
        if(doUpdateUI){
            progressAmount = [NSNumber numberWithDouble:(double)([dataSeries maxDateTime]-requestedStartDate)/(requestedEndDate-requestedStartDate)];
            [self performSelectorOnMainThread:@selector(progressAsFraction:) 
                                   withObject:progressAmount 
                                waitUntilDone:NO];
        }
    }else{
        NSLog(@"Data request failed, something wrong");
    }
    
    if(success && !cancelProcedure){
        oldDataLength = [dataSeries length];
    
        fieldNames = [dataSeries getFieldNames];
        numberOfFields = [fieldNames count];
    
        maxData = (requestedEndDate- requestedStartDate)/samplingRate;
    
        if(maxData > 0 ){
            //NSMutableData *tempData;
            intermediateSampledDateTimesData = [[NSMutableData alloc] initWithLength:maxData * sizeof(long)];
            intermediateSampledDateTimesArray = (long *)[intermediateSampledDateTimesData mutableBytes];
            
            intermediateMappedDateTimesData = [[NSMutableData alloc] initWithLength:maxData * sizeof(long)];
            intermediateMappedDateTimesArray = (long *)[intermediateMappedDateTimesData mutableBytes];
            
            intermediateDataValuesArray = [[NSMutableData alloc] initWithLength:numberOfFields * sizeof(double*)];
            intermediateDataValuesPointerArray = (double **)[intermediateDataValuesArray mutableBytes];
            
            intermediateDataArray = [[NSMutableArray alloc] initWithCapacity:numberOfFields];
            
            for(dataFieldIndex = 0; dataFieldIndex < numberOfFields; dataFieldIndex++){
                NSMutableData *temp = [[NSMutableData alloc] initWithLength:maxData * sizeof(double*)];
                [intermediateDataArray addObject:temp];
                intermediateDataValuesPointerArray[dataFieldIndex] = (double *)[temp mutableBytes];
            }
            
            arrayOfDataArraysData = [[NSMutableData alloc] initWithLength:numberOfFields * sizeof(double*)];
            arrayOfDataArrays = (double **)[arrayOfDataArraysData mutableBytes];
    
            dateTimeArray = (long *)[[dataSeries xData] bytes]; 
            for(dataFieldIndex = 0; dataFieldIndex < numberOfFields; dataFieldIndex++){
                dataArray =  [[dataSeries yData] objectForKey:[fieldNames objectAtIndex:dataFieldIndex]];
                arrayOfDataArrays[dataFieldIndex] = (double *)[dataArray bytes];
            }
        }else{
            success = NO;
            [NSException raise:@"Unknown error" format:@"Zero data returned, something wrong"];
        }
    }
    
    if(success && !cancelProcedure){        
        oldDataIndex = 0;
        newDataIndex = 0;
        sampleDateTime = requestedStartDate;
        while(sampleDateTime < dateTimeArray[oldDataIndex]){
            sampleDateTime = sampleDateTime + samplingRate;
        }
        while(dateTimeArray[oldDataIndex] < requestedStartDate){
            oldDataIndex++;
        }
        if(oldDataIndex >= oldDataLength){
            userMessage = @"Something wrong couldn't find >= startdate in the data";
            success = NO;
        }
    }
    
    if(success && !cancelProcedure){
        BOOL keepGoing = YES;
        int requestTruncated = 1;
        while(keepGoing){
            //While the data time is less than or equal to sample time keep going
            //But if we have got to the end of the data and the data time is equal to sample time
            // then we need to stop as this is our sample 
            while(dateTimeArray[oldDataIndex] <= sampleDateTime && keepGoing){
                
                if(oldDataIndex == oldDataLength -1){
                    if(dateTimeArray[oldDataIndex] == sampleDateTime){
                        intermediateSampledDateTimesArray[newDataIndex] = dateTimeArray[oldDataIndex];
                        intermediateMappedDateTimesArray[newDataIndex] = sampleDateTime;
                        
                        for(dataFieldIndex = 0; dataFieldIndex < numberOfFields; dataFieldIndex++){
                            intermediateDataValuesPointerArray[dataFieldIndex][newDataIndex] = arrayOfDataArrays[dataFieldIndex][oldDataIndex];
                        }
                        sampleDateTime = sampleDateTime + samplingRate;
                        if(sampleDateTime > requestedEndDate){
                            keepGoing = NO;
                        }
                        newDataIndex++;
                    }
                    if(keepGoing){
                        //This ensures that hte first date in the new array is from the last array
                        //so there is no sampling gaps 
                        requestedStartDate = dateTimeArray[oldDataIndex]; 
                        success = [self getMoreDataForStartDateTime: requestedStartDate 
                                                     AndEndDateTime: requestedEndDate
                                             AndReturningStatsArray: statsArray
                                           WithRequestTruncatedFlag: &requestTruncated]; 
                        
                        if(!success || cancelProcedure){
                            keepGoing = NO;
                            if(!success){
                                NSLog(@"Problem retrieving data, stopping");
                            }
                        }else{
                            if(doUpdateUI){
                                progressAmount = [NSNumber numberWithDouble:(double)([dataSeries maxDateTime]-requestedStartDate)/(requestedEndDate - requestedStartDate)];
                            
                                [self performSelectorOnMainThread:@selector(progressAsFraction:) 
                                                       withObject:progressAmount 
                                                    waitUntilDone:NO];
                            }
                            dateTimeArray = (long *)[[dataSeries xData] bytes]; 
                            for(dataFieldIndex = 0; dataFieldIndex < numberOfFields; dataFieldIndex++){
                                dataArray =  [[dataSeries yData] objectForKey:[fieldNames objectAtIndex: dataFieldIndex]];
                                arrayOfDataArrays[dataFieldIndex] = (double *)[dataArray bytes];
                            }
                            oldDataLength = [dataSeries length];
                            oldDataIndex = 0;
                        }
                    }
                }else{
                    oldDataIndex = oldDataIndex + 1;
                }
            }
            
            if(keepGoing){
                if(oldDataIndex > 0){
                    if(dateTimeArray[oldDataIndex-1] > (sampleDateTime - samplingRate)){
                        intermediateSampledDateTimesArray[newDataIndex] = dateTimeArray[oldDataIndex-1];
                        intermediateMappedDateTimesArray[newDataIndex] = sampleDateTime;
                
                        for(dataFieldIndex = 0; dataFieldIndex < numberOfFields; dataFieldIndex++){
                            intermediateDataValuesPointerArray[dataFieldIndex][newDataIndex] = arrayOfDataArrays[dataFieldIndex][oldDataIndex-1];
                        }
                        newDataIndex++;
                    }
                }
                sampleDateTime = sampleDateTime + samplingRate;
                if(sampleDateTime > requestedEndDate){
                    keepGoing = NO;
                }
            }
        }
    }
    
    if(success && !cancelProcedure){
        long newDataLength = newDataIndex;
        NSMutableData *dateTimesData;
        NSMutableDictionary *newDataDictionary = [[NSMutableDictionary alloc] init];
        NSMutableData *newData;
        long *dateTimesArray;
        NSMutableData *arrayOfNewDataArraysData;
        double **arrayOfNewDataArrays;
        
        dateTimesData = [[NSMutableData alloc] initWithLength:newDataLength * sizeof(long)]; 
        dateTimesArray = (long *)[dateTimesData mutableBytes];
        
        arrayOfNewDataArraysData = [[NSMutableData alloc] initWithLength:numberOfFields * sizeof(double*)];
        arrayOfNewDataArrays = (double **)[arrayOfNewDataArraysData mutableBytes];
    
        for(dataFieldIndex = 0; dataFieldIndex < numberOfFields; dataFieldIndex++){
            newData = [[NSMutableData alloc] initWithLength:newDataLength * sizeof(double)]; 
            [newDataDictionary setObject:newData forKey:[fieldNames objectAtIndex:dataFieldIndex]];
            arrayOfNewDataArrays[dataFieldIndex] = (double *)[newData mutableBytes];
        }
    
        for(newDataIndex= 0; newDataIndex < newDataLength; newDataIndex++){
            dateTimesArray[newDataIndex] = intermediateMappedDateTimesArray[newDataIndex];
            if(newDataIndex > 0){
                if(dateTimesArray[newDataIndex]==dateTimesArray[newDataIndex-1]){
                    [NSException raise:@"Date problem in sampling" format:nil];
                }
            }
            
            for(dataFieldIndex = 0; dataFieldIndex < numberOfFields; dataFieldIndex++){
                arrayOfNewDataArrays[dataFieldIndex][newDataIndex] = intermediateDataValuesPointerArray[dataFieldIndex][newDataIndex];
            }
        }
        
        if(!cancelProcedure){
            newDataSeries = [dataSeries getCopyOfStaticData];
            CPTNumericData *dateTimeCPTData; 
            dateTimeCPTData = [CPTNumericData numericDataWithData:dateTimesData 
                                                         dataType:CPTDataType(CPTIntegerDataType,sizeof(long),CFByteOrderGetCurrent()) shape:nil];
            [newDataSeries setXData:dateTimeCPTData];
    
            CPTNumericData *dataArrayCPTData;
            //[newDataSeries setYData:[[NSMutableDictionary alloc] init]];
            [[newDataSeries  yData] removeAllObjects];
            for(dataFieldIndex = 0; dataFieldIndex < numberOfFields; dataFieldIndex++){
                newData = [newDataDictionary  objectForKey:[fieldNames objectAtIndex:dataFieldIndex]];
                dataArrayCPTData = [CPTNumericData numericDataWithData:newData 
                                                              dataType:CPTDataType(CPTFloatingPointDataType, 
                                                                          sizeof(double), 
                                                                          CFByteOrderGetCurrent()) shape:nil];
                [[newDataSeries yData] setObject:dataArrayCPTData forKey:[fieldNames objectAtIndex:dataFieldIndex]];
            }
            [newDataSeries setSampleRate:samplingRate];
            [[newDataSeries dataViews] removeAllObjects];
            if([dateTimeCPTData length] > 0 ){
                [newDataSeries setPlotViewWithName:@"ALL" 
                              AndStartDateTime:[[dateTimeCPTData sampleValue:0] longValue]  
                                AndEndDateTime:[[dateTimeCPTData sampleValue:([dateTimeCPTData length]/[dateTimeCPTData sampleBytes])-1] longValue]];
                signalStats = statsArray;
            }
        }
    }
    
    *successAsInt = (success) ? 1 : 0;
    return newDataSeries;
}    


-(BOOL) getMoreDataForStartDateTime: (long) requestedStartDate 
                     AndEndDateTime: (long) requestedEndDate
             AndReturningStatsArray: (NSMutableArray *) statsArray
           WithRequestTruncatedFlag: (int *) requestTrucated   
{
    //We always get the BID and ASK and calculate a MID, other options added as per strategy requirements
    BOOL success = YES;
    BOOL useOldData, useNewData, strategyVariables;
    //int newStartSampleCount, newEndSampleCount;
    long oldStart, oldEnd;
    NSMutableData *newDateLongsTempData;
    long *newDateLongsTemp;
    long adjustedStartDate, adjustedEndDate;
    NSMutableData *newBidDoublesTempData, *newAskDoublesTempData;
    double *newBidDoublesTemp, *newAskDoublesTemp;
    double progress = 0.0, progressUpdate = 0.0;
    
    if([[dataSeries strategy] isEqualToString:@""] || [[dataSeries strategy] isEqualToString:@"BAM"]){
        strategyVariables = NO;
    }else{
        strategyVariables = YES;
    }
    
    adjustedStartDate = requestedStartDate;
    adjustedEndDate = requestedEndDate;
    
    if([dataSeries length] != 0){
        oldStart = [dataSeries minDateTime];
        oldEnd = [dataSeries maxDateTime];
        //If the day is nearly overlapping make it overlap
        if(adjustedStartDate > oldEnd && (adjustedStartDate - oldEnd) <= (7 * DAY_SECONDS)){
            adjustedStartDate = oldEnd;
        }
    }

    //If the amount of data requested is more than 20% longer than our rule of thumb max data
    //then lessen the amount of data the function will return
    if((((double)adjustedEndDate-adjustedStartDate)/MAX_DATA_CHUNK) > 1.2){
        adjustedEndDate = adjustedStartDate + MAX_DATA_CHUNK;
        *requestTrucated = 1;
    }else{
        *requestTrucated = 0;
    }
    
    if([dataSeries length]==0 ){
        useOldData = NO;
        useNewData = YES;
    }else{
        if(!([dataSeries sampleRate]== 0 || [dataSeries sampleRate] != DATABASE_GRANULARITY_SECONDS)){
            useOldData = NO;
            useNewData = YES;
        }else{
            if((adjustedStartDate < oldStart) || (adjustedStartDate > oldEnd)){
                useOldData = NO;
                useNewData = YES;
            }else{
                if(adjustedStartDate >= oldStart && adjustedEndDate <= oldEnd){
                    useOldData = YES;
                    useNewData = NO;     
                }else {
                    useOldData = YES;
                    useNewData = YES;  
                }
            }
        }
    }
    
    CPTNumericData *oldDateData;
    CPTNumericData *oldBidData;
    CPTNumericData *oldAskData;
    CPTNumericData *midData;
    long *oldDateLongs; 
    double *oldBidDoubles; 
    double *oldAskDoubles;
    double *oldMidDoubles;
    
    if(useOldData){
        //Get a handle on the original data
        oldDateData = [dataSeries xData];
        oldBidData = [[dataSeries yData] objectForKey:@"BID"];
        oldAskData = [[dataSeries yData] objectForKey:@"ASK"];
        midData = [[dataSeries yData] objectForKey:@"MID"];
        oldDateLongs = (long *)[oldDateData bytes];
        oldBidDoubles = (double *)[oldBidData bytes];
        oldAskDoubles = (double *)[oldAskData bytes];
        oldMidDoubles = (double *)[midData bytes];
    }
    
    long oldDataStartIndex = [dataSeries length] - 1;
    if(useOldData){
        while(oldDateLongs[oldDataStartIndex] > adjustedStartDate && oldDataStartIndex > 0){ 
            oldDataStartIndex--;
        }
        if(oldDateLongs[oldDataStartIndex] < adjustedStartDate && oldDataStartIndex < [dataSeries length] - 1 ){
            oldDataStartIndex++;
        }
        if(oldDataStartIndex >= [dataSeries length]){
            useOldData = NO;
        }
    }
      
    FMResultSet *rs;
    //If we need all new data 
    long resultCount, queryStart, queryEnd, recordsetIndex;
    if(useNewData){
        @try{
            NSString *queryString;
            if(useOldData){
                // Differnce when using old data is that startdate is not included in new data
                // as it is part of the old data 
                queryStart = oldEnd;
                
                queryEnd = [db longForQuery:[NSString stringWithFormat:@"SELECT TimeDate FROM DataSeries WHERE SeriesId = %d AND DataTypeId = %d AND TimeDate >= %ld ORDER BY TimeDate ASC LIMIT 1",[dataSeries dbId],1,adjustedEndDate]];
                
                resultCount = [db intForQuery:[NSString stringWithFormat:@"SELECT COUNT(*) FROM DataSeries WHERE SeriesId = %d AND DataTypeId = %d AND TimeDate > %ld AND TimeDate <= %ld",[dataSeries dbId],1,queryStart,queryEnd]];
                
                queryString = [NSString stringWithFormat:@"SELECT DS1.TimeDate, DS1.Value, DS2.Value FROM DataSeries DS1 INNER JOIN DataSeries DS2 ON DS1.TimeDate = DS2.TimeDate AND DS1.SeriesId = DS2.SeriesId  WHERE DS1.SeriesId = %d AND DS1.DataTypeId = %d AND DS2.DataTypeId = %d AND DS1.TimeDate > %ld AND DS1.TimeDate <= %ld ORDER BY DS1.TimeDate ASC", [dataSeries dbId],1,2,queryStart,queryEnd];
            }else{
                queryStart = [db longForQuery:[NSString stringWithFormat:@"SELECT TimeDate FROM DataSeries WHERE SeriesId = %d AND DataTypeId = %d AND TimeDate <= %ld ORDER BY TimeDate DESC LIMIT 1",[dataSeries dbId],1,adjustedStartDate]];
                
                queryEnd = [db longForQuery:[NSString stringWithFormat:@"SELECT TimeDate FROM DataSeries WHERE SeriesId = %d AND DataTypeId = %d AND TimeDate >= %ld ORDER BY TimeDate ASC LIMIT 1",[dataSeries dbId],1,adjustedEndDate]];
                
                resultCount = [db intForQuery:[NSString stringWithFormat:@"SELECT COUNT(*) FROM DataSeries WHERE SeriesId = %d AND DataTypeId = %d AND TimeDate >= %ld AND TimeDate <= %ld",[dataSeries dbId],1,queryStart,queryEnd]];
                
                queryString = [NSString stringWithFormat:@"SELECT DS1.TimeDate, DS1.Value, DS2.Value FROM DataSeries DS1 INNER JOIN DataSeries DS2 ON DS1.TimeDate = DS2.TimeDate AND DS1.SeriesId = DS2.SeriesId  WHERE DS1.SeriesId = %d AND DS1.DataTypeId = %d AND DS2.DataTypeId = %d AND DS1.TimeDate >= %ld AND DS1.TimeDate <= %ld ORDER BY DS1.TimeDate ASC", [dataSeries dbId],1,2,queryStart,queryEnd];
                
            }
            newDateLongsTempData = [[NSMutableData alloc] initWithLength:resultCount * sizeof(long)];
            newDateLongsTemp = (long *)[newDateLongsTempData mutableBytes];
            
            newBidDoublesTempData = [[NSMutableData alloc] initWithLength:resultCount * sizeof(double)]; 
            newBidDoublesTemp = (double *)[newBidDoublesTempData mutableBytes];
            
            newAskDoublesTempData = [[NSMutableData alloc] initWithLength:resultCount * sizeof(double)];
            newAskDoublesTemp = (double *)[newAskDoublesTempData mutableBytes];
            
            rs = [db executeQuery:queryString];
            
        }
        @catch (NSException *exception) {
            NSLog(@"main: Caught %@: %@", [exception name], [exception reason]);
            success = NO;
        }                
        if(success && !cancelProcedure)
        {
            recordsetIndex = 0;
            while ([rs next ]) 
            {
                newDateLongsTemp[recordsetIndex] = [rs longForColumnIndex:0];
                newBidDoublesTemp[recordsetIndex] = [rs doubleForColumnIndex:1];
                newAskDoublesTemp[recordsetIndex] = [rs doubleForColumnIndex:2];
                
                progress = (double)(newDateLongsTemp[recordsetIndex]-requestedStartDate)/(queryEnd-requestedStartDate);
                recordsetIndex ++; 
                if(progress - progressUpdate > 0.1){
                    progressUpdate = progress;
                    if(doThreads){
                        [self performSelectorOnMainThread:@selector(readingRecordSetsProgress:) withObject:[NSNumber numberWithDouble:progressUpdate] waitUntilDone:NO];
                        
                    }
                }
            }
        }
    }
    
    NSMutableData *newDateData; 
    NSMutableData *newBidData; 
    NSMutableData *newAskData; 
    NSMutableData *newMidData;
    long *newDateLongs; 
    double *newBidDoubles; 
    double *newAskDoubles;
    double *newMidDoubles;
    NSUInteger newDataLength = 0;
    int indexOnNew = 0;
    
    if(success && !cancelProcedure){
        if(useOldData){
            //One of which will be zero
            newDataLength = [dataSeries length] - oldDataStartIndex;
        }
        if(useNewData){
            newDataLength = newDataLength + resultCount;
        }
        
        newDateData = [[NSMutableData alloc] initWithLength:newDataLength * sizeof(long)]; 
        newBidData = [[NSMutableData alloc] initWithLength:newDataLength * sizeof(double)]; 
        newAskData = [[NSMutableData alloc] initWithLength:newDataLength * sizeof(double)]; 
        newMidData = [[NSMutableData alloc] initWithLength:newDataLength * sizeof(double)]; 
        
        newDateLongs = [newDateData mutableBytes]; 
        newBidDoubles = [newBidData mutableBytes]; 
        newAskDoubles = [newAskData mutableBytes];
        newMidDoubles = [newMidData mutableBytes];
    
        if(useOldData){
            for(int i = oldDataStartIndex; i < [dataSeries length];i++){
                newDateLongs[indexOnNew] =  oldDateLongs[i];
                newBidDoubles[indexOnNew] = oldBidDoubles[i];
                newAskDoubles[indexOnNew] = oldAskDoubles[i];
                newMidDoubles[indexOnNew] = (oldBidDoubles[i] + oldAskDoubles[i])/2;
                indexOnNew++;
            }
        }
            
        if(useNewData){    
            for(int i = 0; i < resultCount;i++){
                newDateLongs[indexOnNew] =  newDateLongsTemp[i];
                newBidDoubles[indexOnNew] = newBidDoublesTemp[i];
                newAskDoubles[indexOnNew] = newAskDoublesTemp[i];
                newMidDoubles[indexOnNew] = (newBidDoubles[indexOnNew]+newAskDoubles[indexOnNew])/2;
                indexOnNew++;
            }
        }
    }
    
    NSMutableDictionary *fileDataDictionary;     
    NSMutableData *fileDataSeries;
    NSMutableData *fileDataDoubleArrayData;
    double **fileDataDoubleArrays;
    NSArray *fileDataFieldNames;
    if([self fileDataAdded]){
        fileDataDictionary = [[NSMutableDictionary alloc] init ];
        fileDataFieldNames = [fileData objectAtIndex:0];
        
        fileDataDoubleArrayData = [[NSMutableData alloc] initWithLength:([fileDataFieldNames count]-1) * sizeof(double *)];
        fileDataDoubleArrays = (double **)[fileDataDoubleArrayData mutableBytes];
        
        for(int i = 0; i < [fileDataFieldNames count]-1;i++){
            fileDataSeries = [[NSMutableData alloc] initWithLength:newDataLength * sizeof(double)];
            fileDataDoubleArrays[i] = [fileDataSeries mutableBytes];
            [fileDataDictionary setObject:fileDataSeries forKey:[fileDataFieldNames objectAtIndex:(i+1)]];
        }

        long indexOnFileData, indexOnDbData = 0;
        long validFromInc, validToEx;
        if([fileData count] > 2){
            for(indexOnFileData = 1; indexOnFileData<[fileData count]; indexOnFileData++){
                NSArray *lineOfData = [fileData objectAtIndex:indexOnFileData];
                validFromInc = (long)[[lineOfData objectAtIndex:0] longLongValue];
                if(indexOnFileData < [fileData count]-1){
                    validToEx =  (long)[[[fileData objectAtIndex:indexOnFileData+1] objectAtIndex:0] longLongValue];
                }else{
                    validToEx = newDateLongs[newDataLength-1] +1; 
                }
                
                if(indexOnFileData==1){
                    while(validFromInc > newDateLongs[indexOnDbData] && indexOnDbData < newDataLength ){
                        for(int fieldIndex = 0; fieldIndex < [fileDataFieldNames count]-1; fieldIndex++){
                            fileDataDoubleArrays[fieldIndex][indexOnDbData] =  0.0;
                        }
                        indexOnDbData++;
                    }
                }
                
                while(newDateLongs[indexOnDbData] >= validFromInc && newDateLongs[indexOnDbData] < validToEx && indexOnDbData < newDataLength){
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
    NSMutableArray *overriddenNames = [[NSMutableArray alloc] init];
    if(success && !cancelProcedure){    
        // If we need extra dervied data fields get them here.
        if(strategyVariables){
            NSMutableDictionary *newData = [[NSMutableDictionary alloc] init];
            NSMutableDictionary *parameters = [[NSMutableDictionary alloc] init];
            
            if(useOldData){
                [parameters setObject:[NSNumber numberWithBool:NO] forKey:@"ALLNEWDATA"];
            }else{
                [parameters setObject:[NSNumber numberWithBool:YES] forKey:@"ALLNEWDATA"];
            }
            
            [newData setObject:newDateData forKey:@"DATETIME"];
            [newData setObject:newBidData forKey:@"BID"];
            [newData setObject:newAskData forKey:@"ASK"];
            [newData setObject:newMidData forKey:@"MID"];
            
            if(useOldData){
                [parameters setObject:[dataSeries yData] forKey:@"OLDDATA"];
                [parameters setObject:[dataSeries xData] forKey:@"OLDDATETIME"];
                [parameters setObject:[NSNumber numberWithInt:oldDataStartIndex] forKey:@"OVERLAPINDEX"];
            }
            
            derivedDataDictionary = [DataProcessor processWithDataSeries: newData
                                                             AndStrategy: [dataSeries strategy]
                                                          AndProcessInfo: parameters
                                                       AndReturningStats: statsArray];
            
            if([derivedDataDictionary objectForKey:@"SUCCESS"] != nil){
                if(![[derivedDataDictionary objectForKey:@"SUCCESS"] boolValue]){
                    success = NO; 
                    NSLog(@"No success in creating derived data");
                }
            }else{
                success = NO;
                NSLog(@"Something wrong creating derived data, cannot find the success variable");
            }
        }
        
        derivedDataNames = [derivedDataDictionary allKeys];
        if([self fileDataAdded]){
            for(int i = 0; i < [derivedDataNames count];i++){
                for(int j = 0; j < [fileDataFieldNames count]; j++){
                    if([[derivedDataNames objectAtIndex:i] isEqualToString:[fileDataFieldNames objectAtIndex:j]]){
                        [overriddenNames addObject:[derivedDataNames objectAtIndex:i]];
                    }
                }
            }
        }
    }
    
    if(success && !cancelProcedure){
        CPTNumericData *dateCPTData, *bidCPTData, *askCPTData, *midCPTData;
        
        dateCPTData = [CPTNumericData numericDataWithData:newDateData 
                                                     dataType:CPTDataType(CPTIntegerDataType, 
                                                                   sizeof(long), 
                                                                   CFByteOrderGetCurrent()) 
                                                        shape:nil]; 
        bidCPTData = [CPTNumericData numericDataWithData:newBidData 
                                                    dataType:CPTDataType(CPTFloatingPointDataType, 
                                                                  sizeof(double), 
                                                                  CFByteOrderGetCurrent()) 
                                                       shape:nil]; 
        askCPTData = [CPTNumericData numericDataWithData:newAskData 
                                                    dataType:CPTDataType(CPTFloatingPointDataType, 
                                                                  sizeof(double), 
                                                                  CFByteOrderGetCurrent()) 
                                                shape:nil]; 
        midCPTData = [CPTNumericData numericDataWithData:newMidData 
                                             dataType:CPTDataType(CPTFloatingPointDataType, 
                                                                  sizeof(double), 
                                                                  CFByteOrderGetCurrent()) 
                                                       shape:nil]; 
        
        [dataSeries setXData:dateCPTData];
        [[dataSeries yData] removeAllObjects];
        [[dataSeries yData] setObject:bidCPTData forKey:@"BID"];
        [[dataSeries yData] setObject:askCPTData forKey:@"ASK"];
        [[dataSeries yData] setObject:midCPTData forKey:@"MID"];
            
        for(int i = 0; i < [derivedDataNames count]; i++){
            if(![[derivedDataNames objectAtIndex:i] isEqualToString:@"SUCCESS"]){
                derivedData = [derivedDataDictionary objectForKey: [derivedDataNames objectAtIndex:i]];
                
                derivedCPTData = [CPTNumericData numericDataWithData:derivedData 
                                                            dataType:CPTDataType(CPTFloatingPointDataType, 
                                                                              sizeof(double), 
                                                                              CFByteOrderGetCurrent()) 
                                                                shape:nil];
                 if([self fileDataAdded ] && [overriddenNames count] > 0){
                     NSString *crossCheckedKey = [derivedDataNames objectAtIndex:i];
                     for(int j = 0; j < [overriddenNames count]; j++){
                         if([[overriddenNames objectAtIndex:j] isEqualToString:crossCheckedKey]){
                             crossCheckedKey = [NSString stringWithFormat:@"%@**",crossCheckedKey];
                         }
                     }
                     [[dataSeries yData] setObject:derivedCPTData forKey:crossCheckedKey];
                 }else{
                     [[dataSeries yData] setObject:derivedCPTData forKey:[derivedDataNames objectAtIndex:i]];
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
                [[dataSeries yData] setObject:fileCPTData forKey:[fileDataFieldNames objectAtIndex:fileDataIndex+1]];               
            }
        }
        
        [[dataSeries dataViews] removeAllObjects];
        [dataSeries setPlotViewWithName:@"ALL" AndStartDateTime:newDateLongs[0] AndEndDateTime:newDateLongs[indexOnNew-1]];
    }
    
    return success;
}

-(long)getMinDataDateTimeForPair:(NSString *) fxPairName
{
    return [[minDateTimes objectForKey:fxPairName] longValue];
}

-(long)getMaxDataDateTimeForPair:(NSString *) fxPairName
{
    return [[maxDateTimes objectForKey:fxPairName] longValue];
}

-(long)getMinDateTimeForFullData
{
    NSArray *arrayOfFxPairs = [minDateTimes allKeys];
    if([fxPairs count] == 0){
        return 0;
    }else{
        long minDateTime = [[minDateTimes objectForKey:[arrayOfFxPairs objectAtIndex:0]] longValue];
        for(int i = 1; i < [fxPairs count]; i++){
            minDateTime = MAX(minDateTime, [[minDateTimes objectForKey:[arrayOfFxPairs objectAtIndex:i]] longValue]);
        }
        return minDateTime;
    } 
}

-(long)getMaxDateTimeForFullData
{
    NSArray *arrayOfFxPairs = [maxDateTimes allKeys];
    if([fxPairs count] == 0){
        return 0;
    }else{
        long minDateTime = [[maxDateTimes objectForKey:[arrayOfFxPairs objectAtIndex:0]] longValue];
        for(int i = 1; i < [fxPairs count]; i++){
            minDateTime = MIN(minDateTime, [[maxDateTimes objectForKey:[arrayOfFxPairs objectAtIndex:i]] longValue]);
        }
        return minDateTime;
    } 
}

-(DataSeries *)createNewDataSeriesWithXData:(NSMutableData *) dateTimes 
                                   AndYData:(NSDictionary *) dataValues 
                              AndSampleRate:(long)newSampleRate
{
    DataSeries *newDataSeries;
    newDataSeries = [dataSeries getCopyOfStaticData];
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
    [newDataSeries setSampleRate:newSampleRate];
    [[newDataSeries dataViews] removeAllObjects];
    [newDataSeries setPlotViewWithName:@"ALL" 
                      AndStartDateTime:[[dateTimeData sampleValue:0] longValue]  
                        AndEndDateTime:[[dateTimeData sampleValue:([dateTimeData length]/[dateTimeData sampleBytes])-1] longValue]];
    return newDataSeries;
}

- (void) setData: (NSArray *) userData 
        FromFile: (NSString *) userDataFilename
{
    [self setFileDataAdded:YES];
    fileDataFileName = userDataFilename;
    fileData = userData;
}


#pragma mark -
#pragma mark Properties

@synthesize connected;
@synthesize dataSeries;
@synthesize fxPairs;
@synthesize dataFields;
@synthesize minDateTimes;
@synthesize maxDateTimes;
@synthesize signalStats;
@synthesize fileData;
@synthesize fileDataFileName;
@synthesize fileDataAdded = _fileDataAdded;
@end

