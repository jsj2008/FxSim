//
//  DataController.m
//  Simple Sim
//
//  Created by Martin O'Connor on 14/01/2012.
//  Copyright (c) 2012 OCONNOR RESEARCH. All rights reserved.
//

#import "DataController.h"
#import "FMDatabase.h"
//#import "IdNamePair.h"
#import "FMDatabaseAdditions.h"
#import "DataSeries.h"
#import "EpochTime.h"
#import "DataView.h"
#import "DataSeriesValue.h"
#import "UtilityFunctions.h"

#define DATABASE_GRANULARITY_SECONDS 1
#define MAX_DATA_CHUNK 30*24*60*60
#define DAY_SECONDS 24*60*60

@interface DataController()
-(void)setupListofPairs;
-(void)setupListofDataFields;
@end

@implementation DataController
@synthesize connected;
@synthesize dataSeries;
@synthesize fxPairs;
@synthesize dataFields;
@synthesize minDateTimes;
@synthesize maxDateTimes;


//NSString *dbPath = @"/Users/Martin/Documents/dev/db1/timeseries.db";
NSString *dbPath = @"/Users/Martin/Projects/Databases/timeseries.db";
FMDatabase *db;

-(id)init
{  
    self = [super init];
    if(self){
        db = [FMDatabase databaseWithPath:dbPath];
        if (![db open]) {
            db = nil;
            connected = NO;
        }else
        {
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

-(int)dataGranularity
{
    return DATABASE_GRANULARITY_SECONDS;
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


-(void)setupListofPairs{
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

-(NSDictionary *)getValuesForFields:(NSArray *) fieldNames AtDateTime: (long) dateTime
{
    return [dataSeries getValues:fieldNames 
                       AtDateTime:dateTime];
}


-(void)setupListofDataFields
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

//-(long *)getDateRangeForSeries:(NSInteger) seriesId
//{
//    long *myArray  = malloc(sizeof(long)*2);
//    myArray[0] = 0;
//    myArray[1] = 0;
//    @try{
//        if([self connected] == YES)
//        {
//            FMResultSet *s = [db executeQuery:[NSString stringWithFormat:@"SELECT Mindate, Maxdate FROM DataDateRange WHERE SeriesID = %d", seriesId]];
//            [s next];
//            myArray[0] = [s intForColumnIndex:0];
//            myArray[1] = [s intForColumnIndex:1];
//        }else{
//            NSLog(@"Database error");
//        }
//    }
//    @catch (NSException *exception) {
//        NSLog(@"main: Caught %@: %@", [exception name], [exception reason]);
//    }
//    return myArray;
//}

-(DataSeriesValue *) valueFromDataBaseForName:(NSString *) name AndDateTime:(long) dateTime AndField: (NSString *) field
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

-(DataSeriesValue *) valueFromDataBaseForFxPair:(NSString *) name AndDateTime:(long) dateTime AndField: (NSString *) field
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

-(NSArray *) getAllInterestRatesForCurrency: (NSString *) currencyCode 
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



-(BOOL)setupDataSeriesForName: (NSString *) dataSeriesName
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
        dataSeries = [[DataSeries alloc] initWithName:seriesName AndDbTag:dbid AndPipSize:pipSize];
    }
    return success;
}

-(BOOL)moveDataToStartDateTime: (long) requestedStartDate 
          AndEndDateTime: (long) requestedEndDate;
{
    BOOL isOk;
    //NSArray *currentFieldNames = [[currentData yData] allKeys];
    isOk = [self getDataSeriesForStartDateTime: requestedStartDate 
                                AndEndDateTime: requestedEndDate];
    return isOk; 
}


-(BOOL)getDataSeriesForStartDateTime: (long) requestedStartDate 
                     AndEndDateTime: (long) requestedEndDate
{
    //We always get the BID and ASK and calculate a mid, other options can be coded in
    // EWMA is coded in already
    bool dbSuccess = YES;
    bool allNewData;
    int newStartSampleCount, newEndSampleCount;
    long oldStart, oldEnd, oldLength;
    long startAdjSecs, endAdjSecs;
    long *newStartDateLongs, *newEndDateLongs;
    double *newStartBidDoubles, *newStartAskDoubles;
    double *newEndBidDoubles, *newEndAskDoubles;
    
    NSMutableArray *extraFields;
    NSMutableArray *ewmaFields = [[NSMutableArray alloc] init];
    //NSArray *ewmaParams;
    
    //If the amount of data requested is more than 20% longer than our rule of thumb max data
    //then lessen the amount of data the function will return
    
    if(((requestedEndDate-requestedStartDate)/MAX_DATA_CHUNK) > 1.2){
        requestedEndDate = requestedStartDate + MAX_DATA_CHUNK;
    }
    
    
    bool doEwma;
    float *ewmaParams;
    FMResultSet *rs;
    
    oldLength = [dataSeries length]; 
    if(oldLength == 0)
    {
        allNewData = YES;
        startAdjSecs = 0;
        endAdjSecs = 0;
        
    }else{
        //Check for other data which we can calculate
        extraFields = [[[dataSeries yData] allKeys] mutableCopy];
        [extraFields removeObject:[NSString stringWithString:@"BID"]];
        [extraFields removeObject:[NSString stringWithString:@"ASK"]];
        [extraFields removeObject:[NSString stringWithString:@"MID"]];
        for(NSString *fieldname in extraFields){
           if([[fieldname substringToIndex:4] isEqualToString:@"EWMA"])
           {
               [ewmaFields addObject:fieldname];
           }
        }
        if([ewmaFields count] > 0){
            doEwma = YES;
         }else{
            doEwma = NO;
        }
        oldStart = [dataSeries minDateTime];
        oldEnd = [dataSeries maxDateTime];
        
        //If the day is nearly overlapping make it overlap
        if(requestedStartDate > oldEnd && (requestedStartDate - oldEnd) <= (7 * DAY_SECONDS)){
            requestedStartDate = oldEnd;
        }
        
        
        if((requestedEndDate < oldStart) || (requestedStartDate > oldEnd) ){
            allNewData = YES;
            startAdjSecs = 0;
            endAdjSecs = 0;
        }else{
            allNewData = NO;
            startAdjSecs = requestedStartDate - oldStart;
            endAdjSecs = requestedEndDate - oldEnd;
        }
        
    }
        
    
    //requestedStartDate = oldStart + startAdjSecs;
    //newEnd = oldEnd + endAdjSecs;
    
    newStartSampleCount = 0;
    newEndSampleCount = 0;
    CPTNumericData *dateData;
    CPTNumericData *bidData;
    CPTNumericData *askData;
    CPTNumericData *midData;
    CPTNumericData *ewmaData;
    long *oldDateLongs; 
    double *oldBidDoubles; 
    double *oldAskDoubles;
    double *oldMidDoubles;
    
    double **oldEwmaDoubles;
    
    oldEwmaDoubles = malloc([ewmaFields count]*sizeof(double*));
    
    if(doEwma){
        ewmaParams = malloc([ewmaFields count]*sizeof(int));
        for(int i =0;i<[ewmaFields count];i++)
        {
            oldEwmaDoubles[i] = (double *)[[[dataSeries yData] objectForKey:[ewmaFields objectAtIndex:i]] bytes];
            ewmaParams[i] = 2.0/(1.0+[UtilityFunctions fib:[[[ewmaFields objectAtIndex:i] substringFromIndex:4] intValue]]);
        }
    }

    
    
    if(!allNewData){
        //Get a handle on the original data
        dateData = [dataSeries xData];
        bidData = [[dataSeries yData] objectForKey:@"BID"];
        askData = [[dataSeries yData] objectForKey:@"ASK"];
        midData = [[dataSeries yData] objectForKey:@"MID"];
        oldDateLongs = (long *)[dateData bytes];
        oldBidDoubles = (double *)[bidData bytes];
        oldAskDoubles = (double *)[askData bytes];
        oldMidDoubles = (double *)[midData bytes];
    }
    
    
    //if we are asked to move the start of the data forwards
    int oldDataStartIndex = 0;
    if(!allNewData){ 
        if(startAdjSecs > 0){
            oldDataStartIndex--;
            do
            { 
                oldDataStartIndex++;
            }while(requestedStartDate > oldDateLongs[oldDataStartIndex] && oldDataStartIndex < [dataSeries length]);
            if(oldDataStartIndex>1){
                //Go back one to make sure we overlap the first time
                oldDataStartIndex--;
            }
        }
    }
   
    //if we are asked  to move the start of the data backwards
    //Or if there was no data to begin with
    int resultCount;
    if(startAdjSecs < 0 || allNewData){
        @try{
            long queryStart, queryEnd;
            if(allNewData){
                queryStart = requestedStartDate;
                queryEnd = requestedEndDate;
            }else{
                queryStart = requestedStartDate;
                queryEnd = oldStart;
            }
            resultCount = [db intForQuery:[NSString stringWithFormat:@"SELECT COUNT(*) FROM DataSeries WHERE SeriesId = %d AND DataTypeId = %d AND TimeDate >= %ld AND TimeDate < %ld",[dataSeries dbId],1,queryStart,queryEnd]];
            newStartDateLongs = malloc(resultCount * sizeof(long));
            newStartBidDoubles = malloc(resultCount * sizeof(double)); 
            newStartAskDoubles = malloc(resultCount * sizeof(double));
            
            NSString *queryString = [NSString stringWithFormat:@"SELECT DS1.TimeDate, DS1.Value, DS2.Value FROM DataSeries DS1 INNER JOIN DataSeries DS2 ON DS1.TimeDate = DS2.TimeDate AND DS1.SeriesId = DS2.SeriesId  WHERE DS1.SeriesId = %d AND DS1.DataTypeId = %d AND DS2.DataTypeId = %d AND DS1.TimeDate >= %ld AND DS1.TimeDate < %ld ORDER BY DS1.TimeDate ASC", [dataSeries dbId],1,2,queryStart,queryEnd];
            rs = [db executeQuery:queryString];
        }
        @catch (NSException *exception) {
            NSLog(@"main: Caught %@: %@", [exception name], [exception reason]);
            dbSuccess = NO;
        }                
        if(dbSuccess)
        {
            newStartSampleCount = 0;
            while ([rs next ]) 
            {
                newStartDateLongs[newStartSampleCount] = [rs longForColumnIndex:0];
                newStartBidDoubles[newStartSampleCount] = [rs doubleForColumnIndex:1];
                newStartAskDoubles[newStartSampleCount] = [rs doubleForColumnIndex:2];
                newStartSampleCount ++; 
            }
        }
    }
    
    //if we are asked to move the end of the data backwards
    int oldDataEndIndex = 0;
    if(!allNewData){
        oldDataEndIndex = (int)[dataSeries length]-1;
        if(endAdjSecs < 0){
            oldDataEndIndex++;
            do
            { 
                oldDataEndIndex--;
            }while(requestedEndDate < oldDateLongs[oldDataEndIndex] && oldDataEndIndex > 0);
        }
    }
    
    //if we are asked to move the end of the data forwards
    if(endAdjSecs > 0 && dbSuccess){
        @try{
            long queryStart, queryEnd;
            if(allNewData){
                queryStart = requestedStartDate;
                queryEnd = requestedEndDate;
            }else{
                queryStart = oldEnd;
                queryEnd = requestedEndDate;
            }
            resultCount = [db intForQuery:[NSString stringWithFormat:@"SELECT COUNT(*) FROM DataSeries WHERE SeriesId = %d AND DataTypeId = %d AND TimeDate >= %ld AND TimeDate <= %ld",[dataSeries dbId],1,queryStart,queryEnd]];
            newEndDateLongs = malloc(resultCount * sizeof(long));
            newEndBidDoubles = malloc(resultCount * sizeof(double)); 
            newEndAskDoubles = malloc(resultCount * sizeof(double));
            
            NSString *queryString = [NSString stringWithFormat:@"SELECT DS1.TimeDate, DS1.Value, DS2.Value FROM DataSeries DS1 INNER JOIN DataSeries DS2 ON DS1.TimeDate = DS2.TimeDate AND DS1.SeriesId = DS2.SeriesId  WHERE DS1.SeriesId = %d AND DS1.DataTypeId = %d AND DS2.DataTypeId = %d AND DS1.TimeDate >= %ld AND DS1.TimeDate <= %ld ORDER BY DS1.TimeDate ASC", [dataSeries dbId],1,2,queryStart,queryEnd];
            rs = [db executeQuery:queryString];
        }
        @catch (NSException *exception) {
            NSLog(@"main: Caught %@: %@", [exception name], [exception reason]);
            dbSuccess = NO;
        }                
        if(dbSuccess)
        {
            newEndSampleCount = 0;
            while ([rs next ]) 
            {
                newEndDateLongs[newEndSampleCount] = [rs longForColumnIndex:0];
                newEndBidDoubles[newEndSampleCount] = [rs doubleForColumnIndex:1];
                newEndAskDoubles[newEndSampleCount] = [rs doubleForColumnIndex:2];
                newEndSampleCount ++; 
            }
        }
    }
    if(dbSuccess){
        NSMutableData *newDateData; 
        NSMutableData *newBidData; 
        NSMutableData *newAskData; 
        NSMutableData *newMidData;
        long *newDateLongs; 
        double *newBidDoubles; 
        double *newAskDoubles;
        double *newMidDoubles;

        NSMutableData *newEWMAData[[ewmaFields count]];
        double **newEWMADoubles;
        newEWMADoubles = malloc([ewmaFields count]*sizeof(double*));
        
        NSUInteger newDataLength;
        //newDataLength = [currentData length];
        
        if(allNewData){
            //One of which will be zero
            newDataLength = newStartSampleCount;
        }else{
            newDataLength = newStartSampleCount + ((oldDataEndIndex-oldDataStartIndex)+1) + newEndSampleCount;
        }
        
        newDateData = [[NSMutableData alloc] initWithLength:newDataLength * sizeof(long)]; 
        newBidData = [[NSMutableData alloc] initWithLength:newDataLength * sizeof(double)]; 
        newAskData = [[NSMutableData alloc] initWithLength:newDataLength * sizeof(double)]; 
        newMidData = [[NSMutableData alloc] initWithLength:newDataLength * sizeof(double)]; 
        
        newDateLongs = [newDateData mutableBytes]; 
        newBidDoubles = [newBidData mutableBytes]; 
        newAskDoubles = [newAskData mutableBytes];
        newMidDoubles = [newMidData mutableBytes];
        
        if(doEwma){
            for(int i = 0;i<[ewmaFields count];i++)
            {
                newEWMAData[i] = [[NSMutableData alloc] initWithLength:newDataLength * sizeof(double)];
                newEWMADoubles[i] = [newEWMAData[i] mutableBytes];

            }
        }
        
        int indexOnNew = 0; 
        if(newStartSampleCount > 0){
            for(int i = 0; i < newStartSampleCount;i++){
                newDateLongs[indexOnNew] =  newStartDateLongs[i];
                newBidDoubles[indexOnNew] = newStartBidDoubles[i];
                newAskDoubles[indexOnNew] = newStartAskDoubles[i];
                newMidDoubles[indexOnNew] = (newStartBidDoubles[i] + newStartAskDoubles[i])/2;
                //If we are here we are using new start data so EWMA needs to be recalculated
                if(doEwma){
                    for(int fieldIndex = 0; fieldIndex <[ewmaFields count];fieldIndex++){
                        if(indexOnNew==0)
                        {
                            newEWMADoubles[fieldIndex][indexOnNew] = newMidDoubles[indexOnNew];
                        }else{
                            //(lambda * midDoubleArray[i]) + ((1-lambda) * ewma[i-1]);
                            newEWMADoubles[fieldIndex][indexOnNew] = (ewmaParams[fieldIndex]*newMidDoubles[indexOnNew]) + ((1-ewmaParams[fieldIndex]) * newEWMADoubles[fieldIndex][indexOnNew-1]);
                        }
                    }
                }
                
                indexOnNew++;
            }
        }
        if(!allNewData){
            for(int indexOnOld = oldDataStartIndex; indexOnOld <= oldDataEndIndex; indexOnOld++){
                newDateLongs[indexOnNew] =  oldDateLongs[indexOnOld];
                newBidDoubles[indexOnNew] = oldBidDoubles[indexOnOld];
                newAskDoubles[indexOnNew] = oldAskDoubles[indexOnOld];
                newMidDoubles[indexOnNew] = oldMidDoubles[indexOnOld];
                if(doEwma){
                    for(int fieldIndex = 0; fieldIndex <[ewmaFields count];fieldIndex++){
                        if(newStartSampleCount > 0){
                            newEWMADoubles[fieldIndex][indexOnNew] = (ewmaParams[fieldIndex]*newMidDoubles[indexOnNew]) + ((1-ewmaParams[fieldIndex]) * newEWMADoubles[fieldIndex][indexOnNew-1]);
                        }else{
                            newEWMADoubles[fieldIndex][indexOnNew] = oldEwmaDoubles[fieldIndex][indexOnOld];
                        }
                    }

                }
                
                indexOnNew++;
            }
        
            if(newEndSampleCount > 0){
                for(int i = 0; i < newEndSampleCount;i++){
                    newDateLongs[indexOnNew] =  newEndDateLongs[i];
                    newBidDoubles[indexOnNew] = newEndBidDoubles[i];
                    newAskDoubles[indexOnNew] = newEndAskDoubles[i];
                    newMidDoubles[indexOnNew] = (newBidDoubles[indexOnNew]+newAskDoubles[indexOnNew])/2;
                    if(doEwma){
                        for(int j = 0; j <[ewmaFields count];j++){
                            if(indexOnNew==0)
                            {
                                newEWMADoubles[j][indexOnNew] = newMidDoubles[indexOnNew];
                            }else{
                                //(lambda * midDoubleArray[i]) + ((1-lambda) * ewma[i-1]);
                                newEWMADoubles[j][indexOnNew] = (ewmaParams[j]*newMidDoubles[indexOnNew]) + ((1-ewmaParams[j]) * newEWMADoubles[j][indexOnNew-1]);
                            }
                        }
                    }
                    indexOnNew++;
                }
            }
        }
        
        dateData = [CPTNumericData numericDataWithData:newDateData 
                                              dataType:CPTDataType(CPTIntegerDataType, 
                                                                   sizeof(long), 
                                                                   CFByteOrderGetCurrent()) 
                                                 shape:nil]; 
        bidData = [CPTNumericData numericDataWithData:newBidData 
                                             dataType:CPTDataType(CPTFloatingPointDataType, 
                                                                  sizeof(double), 
                                                                  CFByteOrderGetCurrent()) 
                                                shape:nil]; 
        askData = [CPTNumericData numericDataWithData:newAskData 
                                             dataType:CPTDataType(CPTFloatingPointDataType, 
                                                                  sizeof(double), 
                                                                  CFByteOrderGetCurrent()) 
                                                shape:nil]; 
        midData = [CPTNumericData numericDataWithData:newMidData 
                                             dataType:CPTDataType(CPTFloatingPointDataType, 
                                                                  sizeof(double), 
                                                                  CFByteOrderGetCurrent()) 
                                                shape:nil]; 
        
        
        [dataSeries setXData:dateData];
        [dataSeries setYData:[[NSMutableDictionary alloc] init]];
        [[dataSeries yData] setObject:bidData forKey:@"BID"];
        [[dataSeries yData] setObject:askData forKey:@"ASK"];
        [[dataSeries yData] setObject:midData forKey:@"MID"];
        if(doEwma){
            for(int j = 0; j < [ewmaFields count]; j++)
            {
                ewmaData = [CPTNumericData numericDataWithData:newEWMAData[j] 
                                                      dataType:CPTDataType(CPTFloatingPointDataType, 
                                                                           sizeof(double), 
                                                                           CFByteOrderGetCurrent()) 
                                                         shape:nil];
                [[dataSeries yData] setObject:ewmaData forKey:[ewmaFields objectAtIndex:j]];
                
            }
        }
        
        [[dataSeries dataViews] removeAllObjects];
        [dataSeries setPlotViewWithName:@"ALL" AndStartDateTime:newDateLongs[0] AndEndDateTime:newDateLongs[indexOnNew-1]];
    }
    return dbSuccess;
}

-(long)getMinDataDateTimeForPair:(NSString *) fxPairName
{
    return [[minDateTimes objectForKey:fxPairName] longValue];
}
//
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


//-(DataSeries *)getDataSeriesForId: (int) dbid  AndType: (int) dataTypeId AndStartTime: (long) startTime AndEndTime: (long) endTime 
//{
//    BOOL success = YES;
//    NSString *seriesName; 
//    NSString *fieldName;
//    NSUInteger resultCount;
//    NSUInteger rowCount;
//    DataSeries *returnData;
//    double pipSize;
//    
//    @try{
//        if([self connected] == YES)
//        {
//            seriesName = [db stringForQuery:[NSString stringWithFormat:@"SELECT SeriesName FROM SeriesName WHERE SeriesId = %d", dbid]];
//            fieldName = [db stringForQuery:[NSString stringWithFormat:@"SELECT Description FROM DataType WHERE DataTypeId = %d", dataTypeId]];
//            pipSize = [db doubleForQuery:[NSString stringWithFormat:@"SELECT PipSize FROM SeriesName WHERE SeriesId = %d", dbid]];
//            resultCount = [db intForQuery:[NSString stringWithFormat:@"SELECT COUNT(*) FROM DataSeries WHERE SeriesId = %d AND DataTypeId = %d AND TimeDate >= %ld AND TimeDate <= %ld",dbid,dataTypeId,startTime,endTime]];
//            
//        }else{
//            success = NO;
//            NSLog(@"Database error");
//        }
//    }
//    @catch (NSException *exception) {
//        NSLog(@"main: Caught %@: %@", [exception name], [exception reason]);
//        success = NO;
//    }
//    
//    if(success){
//        returnData = [[DataSeries alloc] initWithName:seriesName AndDbTag:dbid AndPipSize:pipSize];
//        //[returnData setPipSize:pipSize];
//        //long minDate, maxDate;
//        //double minValue, maxValue;
//        NSMutableData * newXData = [NSMutableData dataWithLength:resultCount * sizeof(long)]; 
//        NSMutableData * newYData = [NSMutableData dataWithLength:resultCount * sizeof(double)]; 
//        long *newXLongs = [newXData mutableBytes]; 
//        double *newYDoubles = [newYData mutableBytes]; 
//        @try{
//            if([self connected] == YES)
//            {
//                FMResultSet *rs = [db executeQuery:[NSString stringWithFormat:@"SELECT TimeDate, Value FROM DataSeries WHERE SeriesId = %d AND DataTypeId = %d AND TimeDate >= %ld AND TimeDate <= %ld ORDER BY TimeDate ASC", dbid,1,startTime,endTime]];
//                rowCount = 0;
//                while ([rs next ] && (rowCount < resultCount)) 
//                {
//                    newXLongs[rowCount] = [rs longForColumnIndex:0];
//                    newYDoubles[rowCount] = [rs doubleForColumnIndex:1];
//                    rowCount = rowCount + 1;
//                }
//                if(rowCount != resultCount){
//                    NSLog(@"****The result count didn't seem to be added in full, check!!!!!!");
//                }
//                //maxDate = newXLongs[rowCount - 1];                       
//                CPTNumericData * xData = [CPTNumericData numericDataWithData:newXData 
//                                                                    dataType:CPTDataType(CPTIntegerDataType, 
//                                                                                         sizeof(long), 
//                                                                                         CFByteOrderGetCurrent()) 
//                                                                       shape:nil]; 
//                CPTNumericData * yData = [CPTNumericData numericDataWithData:newYData 
//                                                                    dataType:CPTDataType(CPTFloatingPointDataType, 
//                                                                                         sizeof(double), 
//                                                                                         CFByteOrderGetCurrent()) 
//                                                                       shape:nil]; 
//                [returnData setDataSeriesWithFieldName:fieldName 
//                                                 AndDates:xData 
//                                                 AndData:yData];
//            }else{
//                NSLog(@"Database error");
//            }
//        }
//        @catch (NSException *exception) {
//            NSLog(@"main: Caught %@: %@", [exception name], [exception reason]);
//        }
//    }
//    NSLog(@"Returning %lu data for %@",rowCount-1,seriesName);
//    return returnData;
//}

-(void)addEWMAWithParameter: (int) param
{
    NSString *fieldNameMid = @"MID";
    NSString *fieldNameEWMA = [NSString stringWithFormat:@"EWMA%d",param];
    double lambda = 2.0/(1.0+param);
    double minValue, maxValue;
    double *midDoubleArray;
    
    NSMutableData *newData = [NSMutableData dataWithLength:([dataSeries length] * sizeof(double))];
    
    double *ewma = [newData mutableBytes]; 
    CPTNumericData *mid =  [[dataSeries yData] objectForKey:fieldNameMid];
    midDoubleArray = (double *)[mid bytes];
    
    ewma[0] = midDoubleArray[0];
    minValue = ewma[0];
    maxValue = ewma[0];
    for(long i = 1; i < [dataSeries length]; i++){
        ewma[i] = (lambda * midDoubleArray[i]) + ((1-lambda) * ewma[i-1]);
        minValue = fmin(minValue,ewma[i]);
        maxValue = fmax(maxValue,ewma[i]);
    }
    NSString *newFieldName = [NSString stringWithString:fieldNameEWMA];
    CPTNumericData * ewmaData = [CPTNumericData numericDataWithData:newData 
                                                           dataType:CPTDataType(CPTFloatingPointDataType, 
                                                                                sizeof(double), 
                                                                                CFByteOrderGetCurrent()) 
                                                              shape:nil];
    [[dataSeries yData] setObject:ewmaData forKey:newFieldName];
    DataView *dataViewAll = [[dataSeries dataViews] objectForKey:@"ALL"];
    [dataViewAll addMin:minValue AndMax:maxValue ForKey:fieldNameEWMA];
}


-(void)addEWMAByIndex: (int) indexNumber
{
    NSString *fieldNameMid = @"MID";
    
    NSString *fieldNameEWMA = [NSString stringWithFormat:@"EWMA%d",indexNumber];
    double param = [UtilityFunctions fib:indexNumber];
    double lambda = 2.0/(1.0+param);
    double minValue, maxValue;
    double *midDoubleArray;
    
    NSMutableData *newData = [NSMutableData dataWithLength:([dataSeries length] * sizeof(double))];
    
    double *ewma = [newData mutableBytes]; 
    CPTNumericData *mid =  [[dataSeries yData] objectForKey:fieldNameMid];
    midDoubleArray = (double *)[mid bytes];
    
    ewma[0] = midDoubleArray[0];
    minValue = ewma[0];
    maxValue = ewma[0];
    for(long i = 1; i < [dataSeries length]; i++){
        ewma[i] = (lambda * midDoubleArray[i]) + ((1-lambda) * ewma[i-1]);
        minValue = fmin(minValue,ewma[i]);
        maxValue = fmax(maxValue,ewma[i]);
    }
    NSString *newFieldName = [NSString stringWithString:fieldNameEWMA];
    CPTNumericData * ewmaData = [CPTNumericData numericDataWithData:newData 
                                                           dataType:CPTDataType(CPTFloatingPointDataType, 
                                                                                sizeof(double), 
                                                                                CFByteOrderGetCurrent()) 
                                                              shape:nil];
    [[dataSeries yData] setObject:ewmaData forKey:newFieldName];
    DataView *dataViewAll = [[dataSeries dataViews] objectForKey:@"ALL"];
    [dataViewAll addMin:minValue AndMax:maxValue ForKey:fieldNameEWMA];
}

-(DataSeries *)newDataSeriesWithXData:(NSMutableData *) dateTimes AndYData:(NSDictionary *) dataValues AndSampleRate:(int)newSampleRate
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
    
    [newDataSeries setYData:[[NSMutableDictionary alloc] init]];
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

//-(DataSeries *)getBidAskSeriesForId: (int) dbid  AndStartTime: (long) startTime AndEndTime: (long) endTime ToSampledSeconds: (int) numberOfSeconds 
//{
//    BOOL success = YES;
//    NSString *seriesName; 
//    NSUInteger sampleCount;
//    DataSeries *returnData;
//    double pipSize;
//    
//    @try{
//        if([self connected] == YES)
//        {
//            seriesName = [db stringForQuery:[NSString stringWithFormat:@"SELECT SeriesName FROM SeriesName WHERE SeriesId = %d", dbid]];
//            //fieldName = [db stringForQuery:[NSString stringWithFormat:@"SELECT Description FROM DataType WHERE DataTypeId = %d", dataTypeId]];
//            pipSize = [db doubleForQuery:[NSString stringWithFormat:@"SELECT PipSize FROM SeriesName WHERE SeriesId = %d", dbid]];
//        }else{
//            success = NO;
//            NSLog(@"Database error");
//        }
//    }
//    @catch (NSException *exception) {
//        NSLog(@"main: Caught %@: %@", [exception name], [exception reason]);
//        success = NO;
//    }
//    
//    if(success){
//        @try{
//            NSString *queryString = [NSString stringWithFormat:@"SELECT DS1.TimeDate, DS1.Value, DS2.Value FROM DataSeries DS1 INNER JOIN DataSeries DS2 ON DS1.TimeDate = DS2.TimeDate AND DS1.SeriesId = DS2.SeriesId  WHERE DS1.SeriesId = %d AND DS1.DataTypeId = %d AND DS2.DataTypeId = %d AND DS1.TimeDate >= %ld AND DS1.TimeDate <= %ld ORDER BY DS1.TimeDate ASC", dbid,1,2,startTime,endTime];
//                
//            FMResultSet *rs = [db executeQuery:queryString];
//            NSMutableData *newDateData; 
//            NSMutableData *newBidData; 
//            NSMutableData *newAskData;
//            NSMutableData *newMidData;
//            long *newDateLongs; 
//            double *newBidDoubles; 
//            double *newAskDoubles;
//            double *newMidDoubles;
//            
//            sampleCount = 0;
//                
//            if(numberOfSeconds <= DATABASE_GRANULARITY_SECONDS){
//                sampleCount = [db intForQuery:[NSString stringWithFormat:@"SELECT COUNT(*) FROM DataSeries WHERE SeriesId = %d AND DataTypeId = %d AND TimeDate >= %ld AND TimeDate <= %ld",dbid,1,startTime,endTime]];
//                    
//                returnData = [[DataSeries alloc] initWithName:seriesName AndDbTag:dbid AndPipSize:pipSize];
//                //[returnData setPipSize:pipSize];
//                [returnData setSampleRate:numberOfSeconds];
//                newDateData = [[NSMutableData alloc] initWithLength:sampleCount * sizeof(long)]; 
//                newBidData = [[NSMutableData alloc] initWithLength:sampleCount * sizeof(double)]; 
//                newAskData = [[NSMutableData alloc] initWithLength:sampleCount * sizeof(double)];  
//                newMidData = [[NSMutableData alloc] initWithLength:sampleCount * sizeof(double)];
//                newDateLongs = [newDateData mutableBytes]; 
//                newBidDoubles = [newBidData mutableBytes]; 
//                newAskDoubles = [newAskData mutableBytes];
//                newMidDoubles = [newMidData mutableBytes];
//                    
//                for(int i = 0; i < sampleCount; i++){
//                    [rs next];
//                    newDateLongs[i] = [rs doubleForColumnIndex:0]; 
//                    newBidDoubles[i] = [rs doubleForColumnIndex:1];
//                    newAskDoubles[i] = [rs doubleForColumnIndex:2];
//                    newMidDoubles[i] = (newBidDoubles[i] + newAskDoubles[i])/2;
//                }
//            }
//            else
//            {
//                long dataCountMax = (endTime - startTime + 1)/numberOfSeconds;
//                long *intermediateDateData = malloc(dataCountMax * sizeof(long));
//                double *intermediateBidData = malloc(dataCountMax * sizeof(double)); 
//                double *intermediateAskData = malloc(dataCountMax * sizeof(double));
//                long currentDateTime;
//                double previousBidValue, previousAskValue, currentBidValue, currentAskValue;
//                bool dataForInterval = NO;
//                previousBidValue = 0;
//                previousAskValue = 0;
//                long anchorDateTime = [EpochTime epochTimeAtZeroHour:startTime];
//                long currentSampleDateTime;
//                currentSampleDateTime = anchorDateTime + numberOfSeconds * ((startTime-anchorDateTime)/numberOfSeconds);
//                while ([rs next ]) 
//                {
//                    currentDateTime = [rs longForColumnIndex:0];
//                    previousBidValue = currentBidValue;
//                    previousAskValue = currentAskValue;
//                    
//                    currentBidValue = [rs doubleForColumnIndex:1];
//                    currentAskValue = [rs doubleForColumnIndex:2];
//                    
//                    if(currentDateTime < currentSampleDateTime)
//                    {
//                        dataForInterval = YES;
//                    }
//                    else
//                    {    
//                        if(dataForInterval == YES)
//                        {
//                            if(currentDateTime == currentSampleDateTime){
//                                intermediateDateData[sampleCount] = currentSampleDateTime;
//                                intermediateBidData[sampleCount] = currentBidValue;
//                                intermediateAskData[sampleCount] = currentAskValue;
//
//                                currentSampleDateTime = currentSampleDateTime + numberOfSeconds;
//                                sampleCount = sampleCount + 1;
//                                dataForInterval = NO;
//                            }
//                            if(currentDateTime > currentSampleDateTime & index > 0){
//                                intermediateDateData[sampleCount] = currentSampleDateTime;
//                                intermediateBidData[sampleCount] = previousBidValue;
//                                intermediateAskData[sampleCount] = previousAskValue;
//
//                                currentSampleDateTime = currentSampleDateTime + numberOfSeconds;
//                                sampleCount = sampleCount + 1;
//                                dataForInterval = NO;
//                            }
//                        }
//                        else
//                        {
//                            while(currentSampleDateTime < currentDateTime){
//                                currentSampleDateTime = currentSampleDateTime + numberOfSeconds;
//                            }
//                            dataForInterval = YES;
//                        }
//                    }
//                }  
//                returnData = [[DataSeries alloc] initWithName:seriesName AndDbTag:dbid AndPipSize:pipSize];
//                //[returnData setPipSize:pipSize];
//                [returnData setSampleRate:numberOfSeconds];
//                newDateData = [[NSMutableData alloc] initWithLength:sampleCount * sizeof(long)]; 
//                newBidData = [[NSMutableData alloc] initWithLength:sampleCount * sizeof(double)]; 
//                newAskData = [[NSMutableData alloc] initWithLength:sampleCount * sizeof(double)]; 
//                newMidData = [[NSMutableData alloc] initWithLength:sampleCount * sizeof(double)]; 
//                
//                newDateLongs = [newDateData mutableBytes]; 
//                newBidDoubles = [newBidData mutableBytes]; 
//                newAskDoubles = [newAskData mutableBytes];
//                newMidDoubles = [newMidData mutableBytes];
//            
//                for(int i = 0; i < sampleCount; i++){
//                    newDateLongs[i] = intermediateDateData[i]; 
//                    newBidDoubles[i] = intermediateBidData[i];
//                    newAskDoubles[i] = intermediateAskData[i];
//                    newMidDoubles[i] = (intermediateBidData[i] + intermediateAskData[i])/2;
//                }
//            }
//            CPTNumericData * dateData = [CPTNumericData numericDataWithData:newDateData 
//                                                                dataType:CPTDataType(CPTIntegerDataType, 
//                                                                                     sizeof(long), 
//                                                                                         CFByteOrderGetCurrent()) 
//                                                                   shape:nil]; 
//            CPTNumericData * bidData = [CPTNumericData numericDataWithData:newBidData 
//                                                                dataType:CPTDataType(CPTFloatingPointDataType, 
//                                                                                         sizeof(double), 
//                                                                                         CFByteOrderGetCurrent()) 
//                                                                    shape:nil]; 
//            CPTNumericData * askData = [CPTNumericData numericDataWithData:newAskData 
//                                                                  dataType:CPTDataType(CPTFloatingPointDataType, 
//                                                                                       sizeof(double), 
//                                                                                       CFByteOrderGetCurrent()) 
//                                                                     shape:nil]; 
//            CPTNumericData * midData = [CPTNumericData numericDataWithData:newMidData 
//                                                                  dataType:CPTDataType(CPTFloatingPointDataType, 
//                                                                                       sizeof(double), 
//                                                                                       CFByteOrderGetCurrent()) 
//                                                                     shape:nil]; 
//            [returnData setXData:dateData];
//            [returnData setYData:[[NSMutableDictionary alloc] init]];
//            [[returnData yData] setObject:bidData forKey:@"BID"];
//            [[returnData yData] setObject:askData forKey:@"ASK"];
//            [[returnData yData] setObject:midData forKey:@"MID"];
//            [returnData setPlotViewWithName:@"ALL" AndStartDateTime:newDateLongs[0] AndEndDateTime:newDateLongs[sampleCount-1]];
//        }
//        @catch (NSException *exception) {
//            NSLog(@"main: Caught %@: %@", [exception name], [exception reason]);
//            success = NO;
//        }
//    NSLog(@"Returning %lu data for %@",sampleCount,seriesName);
//    }
//    return returnData;
//}

//-(bool)addDataSeriesTo:(DataSeries *) dataSeries ForType: (int) dataTypeId 
//{
//    bool success = YES;
//    NSString *fieldName;
//    NSUInteger resultCount;
//    NSUInteger rowCount;
//    
//    @try{
//        if([self connected] == YES)
//        {
//            resultCount = [db intForQuery:[NSString stringWithFormat:@"SELECT COUNT(*) FROM DataSeries WHERE SeriesId = %d AND DataTypeId = %d AND TimeDate >= %ld AND TimeDate <= %ld",[dataSeries dbId],dataTypeId,[dataSeries minDateTime],[dataSeries maxDateTime]]];
//            fieldName = [db stringForQuery:[NSString stringWithFormat:@"SELECT Description FROM DataType WHERE DataTypeId = %d", dataTypeId]];
//        }else{
//            success = NO;
//            NSLog(@"Database error");
//        }
//    }
//    @catch (NSException *exception) {
//        NSLog(@"main: Caught %@: %@", [exception name], [exception reason]);
//        success = NO;
//    }
//    if(resultCount == [dataSeries length]){
//        success = YES;
//    }else{
//        success = NO;
//    }
//    if(success){
//        double minValue, maxValue;
//        //NSMutableData * newXData = [NSMutableData dataWithLength:resultCount * sizeof(long)]; 
//        NSMutableData * newYData = [NSMutableData dataWithLength:resultCount * sizeof(double)]; 
//        //long *newXLongs = [newXData mutableBytes]; 
//        double *newYDoubles = [newYData mutableBytes]; 
//        @try{
//            if([self connected] == YES)
//            {
//                FMResultSet *rs = [db executeQuery:[NSString stringWithFormat:@"SELECT TimeDate, Value FROM DataSeries WHERE SeriesId = %d AND DataTypeId = %d AND TimeDate >= %ld AND TimeDate <= %ld ORDER BY TimeDate ASC", [dataSeries dbId],dataTypeId,[dataSeries minDateTime],[dataSeries maxDateTime]]];
//                rowCount = 0;
//                while ([rs next ] && (rowCount < resultCount)) 
//                {
//                    //newXLongs[rowCount] = [rs longForColumnIndex:0];
//                    newYDoubles[rowCount] = [rs doubleForColumnIndex:1];
//                    if(rowCount == 0){
//                        minValue = newYDoubles[rowCount];
//                        maxValue = newYDoubles[rowCount];
//                    }else{
//                        minValue = fmin(newYDoubles[rowCount], minValue); 
//                        maxValue = fmax(newYDoubles[rowCount], maxValue); 
//                    }
//                    rowCount = rowCount + 1;
//                }
//                if(rowCount != resultCount){
//                    NSLog(@"****The result count didn't seem to be added in full, check!!!!!!");
//                }
//                //Need to fully check the equality of the xData. BUT WE DON'T DO IT. 
//                CPTNumericData * yData = [CPTNumericData numericDataWithData:newYData 
//                                                                    dataType:CPTDataType(CPTFloatingPointDataType, 
//                                                                                         sizeof(double), 
//                                                                                         CFByteOrderGetCurrent()) 
//                                                                       shape:nil]; 
//                [[dataSeries yData] setObject:yData forKey:fieldName];
//                
//            }else{
//                NSLog(@"Database error");
//            }
//        }
//        @catch (NSException *exception) {
//            NSLog(@"main: Caught %@: %@", [exception name], [exception reason]);
//        }
//    }
//    NSLog(@"added %@",fieldName);
//}

//-(void)addMidToBidAskSeries:(DataSeries *) dataSeries
//{
//    NSMutableData *newMidData = [NSMutableData dataWithLength:([dataSeries length] * sizeof(double))]; 
//    double *mid = [newMidData mutableBytes]; 
//    CPTNumericData *bid =  [[dataSeries yData] objectForKey:@"BID"];
//    CPTNumericData *ask =  [[dataSeries yData] objectForKey:@"ASK"];
//    double minMidValue, maxMidValue;
//    NSString *fieldName = @"MID";
//    
//    minMidValue = ([[bid sampleValue:0] doubleValue] + [[ask sampleValue:0] doubleValue])/2.0;
//    maxMidValue = minMidValue;
//    for(long i = 0; i < [dataSeries length]; i++){
//        mid[i] = ([[bid sampleValue:i] doubleValue] + [[ask sampleValue:i] doubleValue])/2.0;
//        minMidValue = fmin(minMidValue, mid[i]);
//        maxMidValue = fmax(maxMidValue, mid[i]);
//    }
//    CPTNumericData * midData = [CPTNumericData numericDataWithData:newMidData 
//                                                        dataType:CPTDataType(CPTFloatingPointDataType, 
//                                                                             sizeof(double), 
//                                                                             CFByteOrderGetCurrent()) 
//                                                           shape:nil]; 
//    [[dataSeries yData] setObject:midData forKey:fieldName];
//    DataView *dataViewAll = [[dataSeries dataViews] objectForKey:@"ALL"];
//    [dataViewAll addMin:minMidValue AndMax:maxMidValue ForKey:@"MID"];
//    
//    NSLog(@"Added Mid");
//}

//-(bool)adjustRangeOfDataSeries: (DataSeries *) dataSeries AtStart: (int) startAdjSecs AndEnd: (int) endAdjSecs
//{
//    
//    bool dbSuccess = YES;
//    bool updateData;
//    int newStartSampleCount, newEndSampleCount;
//    long oldStart, oldEnd, oldLength, newStart, newEnd;
//    oldLength = [dataSeries length]; 
//    oldStart = [dataSeries minDateTime];
//    oldEnd = [dataSeries maxDateTime];
//    long *newStartDateLongs, *newEndDateLongs;
//    double *newStartBidDoubles, *newStartAskDoubles;
//    double *newEndBidDoubles, *newEndAskDoubles;
//    FMResultSet *rs;
// 
//    updateData = YES;
//    
//    
//    //newStart = oldStart + startAdjSecs;
//    //newEnd = oldEnd + endAdjSecs;
//    
//    newStartSampleCount = 0;
//    newEndSampleCount = 0;
//    newStart = oldStart + startAdjSecs;
//    newEnd = oldEnd + endAdjSecs;
//    
//    if((newEnd < oldStart) || (newStart > oldEnd) ){
//        updateData = NO;
//    }
//    //Get a handle on the original data
//    CPTNumericData * dateData = [dataSeries xData];
//    CPTNumericData * bidData = [[dataSeries yData] objectForKey:@"BID"];
//    CPTNumericData * askData = [[dataSeries yData] objectForKey:@"ASK"];
//    CPTNumericData * midData = [[dataSeries yData] objectForKey:@"MID"];
//
//    //if we are asked to move the start of the data forwards
//    int oldDataStartIndex = 0;
//    if(updateData){ 
//        if(startAdjSecs > 0){
//            oldDataStartIndex--;
//            do
//            { 
//                oldDataStartIndex++;
//            }while(newStart > [[dateData sampleValue:oldDataStartIndex] longValue] && oldDataStartIndex < [dataSeries length]);
//        }
//    }
//  
//    
//    //if we are asked  to move the start of the data backwards  
//    int resultCount;
//    if(startAdjSecs < 0){
//        @try{
//            long queryStart, queryEnd;
//            if(updateData){
//                queryStart = newStart;
//                queryEnd = oldStart;
//            }else{
//                queryStart = newStart;
//                queryEnd = newEnd;
//            }
//            resultCount = [db intForQuery:[NSString stringWithFormat:@"SELECT COUNT(*) FROM DataSeries WHERE SeriesId = %d AND DataTypeId = %d AND TimeDate >= %ld AND TimeDate < %ld",[dataSeries dbId],1,queryStart,queryEnd]];
//            newStartDateLongs = malloc(resultCount * sizeof(long));
//            newStartBidDoubles = malloc(resultCount * sizeof(double)); 
//            newStartAskDoubles = malloc(resultCount * sizeof(double));
//            
//            NSString *queryString = [NSString stringWithFormat:@"SELECT DS1.TimeDate, DS1.Value, DS2.Value FROM DataSeries DS1 INNER JOIN DataSeries DS2 ON DS1.TimeDate = DS2.TimeDate AND DS1.SeriesId = DS2.SeriesId  WHERE DS1.SeriesId = %d AND DS1.DataTypeId = %d AND DS2.DataTypeId = %d AND DS1.TimeDate >= %ld AND DS1.TimeDate < %ld ORDER BY DS1.TimeDate ASC", [dataSeries dbId],1,2,queryStart,queryEnd];
//                rs = [db executeQuery:queryString];
//        }
//        @catch (NSException *exception) {
//                NSLog(@"main: Caught %@: %@", [exception name], [exception reason]);
//                dbSuccess = NO;
//        }                
//        if(dbSuccess)
//        {
//            newStartSampleCount = 0;
//            while ([rs next ]) 
//            {
//                newStartDateLongs[newStartSampleCount] = [rs longForColumnIndex:0];
//                newStartBidDoubles[newStartSampleCount] = [rs doubleForColumnIndex:1];
//                newStartAskDoubles[newStartSampleCount] = [rs doubleForColumnIndex:2];
//                newStartSampleCount ++; 
//            }
//        }
//    }
//    
//    //if we are asked to move the end of the data backwards
//    int oldDataEndIndex = 0;
//    if(updateData){
//        oldDataEndIndex = (int)[dataSeries length]-1;
//        if(endAdjSecs < 0){
//            oldDataEndIndex++;
//            do
//            { 
//                oldDataEndIndex--;
//            }while(newEnd < [[dateData sampleValue:oldDataEndIndex] longValue] && oldDataEndIndex > 0);
//        }
//    }
//    
//    //if we are asked to move the end of the data forwards
//    if(endAdjSecs > 0 && dbSuccess){
//        @try{
//            long queryStart, queryEnd;
//            if(updateData){
//                queryStart = oldEnd;
//                queryEnd = newEnd;
//            }else{
//                queryStart = newStart;
//                queryEnd = newEnd;
//            }
//            resultCount = [db intForQuery:[NSString stringWithFormat:@"SELECT COUNT(*) FROM DataSeries WHERE SeriesId = %d AND DataTypeId = %d AND TimeDate >= %ld AND TimeDate <= %ld",[dataSeries dbId],1,queryStart,queryEnd]];
//            newEndDateLongs = malloc(resultCount * sizeof(long));
//            newEndBidDoubles = malloc(resultCount * sizeof(double)); 
//            newEndAskDoubles = malloc(resultCount * sizeof(double));
//                
//            NSString *queryString = [NSString stringWithFormat:@"SELECT DS1.TimeDate, DS1.Value, DS2.Value FROM DataSeries DS1 INNER JOIN DataSeries DS2 ON DS1.TimeDate = DS2.TimeDate AND DS1.SeriesId = DS2.SeriesId  WHERE DS1.SeriesId = %d AND DS1.DataTypeId = %d AND DS2.DataTypeId = %d AND DS1.TimeDate >= %ld AND DS1.TimeDate <= %ld ORDER BY DS1.TimeDate ASC", [dataSeries dbId],1,2,queryStart,queryEnd];
//            rs = [db executeQuery:queryString];
//        }
//        @catch (NSException *exception) {
//            NSLog(@"main: Caught %@: %@", [exception name], [exception reason]);
//            dbSuccess = NO;
//        }                
//        if(dbSuccess)
//        {
//            newEndSampleCount = 0;
//            while ([rs next ]) 
//            {
//                newEndDateLongs[newEndSampleCount] = [rs longForColumnIndex:0];
//                newEndBidDoubles[newEndSampleCount] = [rs doubleForColumnIndex:1];
//                    newEndAskDoubles[newEndSampleCount] = [rs doubleForColumnIndex:2];
//                    newEndSampleCount ++; 
//            }
//        }
//    }
//    if(dbSuccess){
//        NSMutableData *newDateData; 
//        NSMutableData *newBidData; 
//        NSMutableData *newAskData; 
//        NSMutableData *newMidData;
//        long *newDateLongs; 
//        double *newBidDoubles; 
//        double *newAskDoubles;
//        double *newMidDoubles;
//    
//        NSUInteger newDataLength;
//        newDataLength = [dataSeries length];
//    
//        if(updateData){
//            newDataLength = newStartSampleCount + ((oldDataEndIndex-oldDataStartIndex)+1) + newEndSampleCount;
//        }else{
//            //One of which will be zero
//            newDataLength = newStartSampleCount + newEndSampleCount;
//        }
//
//        newDateData = [[NSMutableData alloc] initWithLength:newDataLength * sizeof(long)]; 
//        newBidData = [[NSMutableData alloc] initWithLength:newDataLength * sizeof(double)]; 
//        newAskData = [[NSMutableData alloc] initWithLength:newDataLength * sizeof(double)]; 
//        newMidData = [[NSMutableData alloc] initWithLength:newDataLength * sizeof(double)]; 
//    
//        newDateLongs = [newDateData mutableBytes]; 
//        newBidDoubles = [newBidData mutableBytes]; 
//        newAskDoubles = [newAskData mutableBytes];
//        newMidDoubles = [newMidData mutableBytes];
//    
//        int index = 0; 
//        if(newStartSampleCount > 0){
//            for(int i = 0; i < newStartSampleCount;i++){
//                newDateLongs[index] =  newStartDateLongs[i];
//                newBidDoubles[index] = newStartBidDoubles[i];
//                newAskDoubles[index] = newStartAskDoubles[i];
//                newMidDoubles[index] = (newStartBidDoubles[i] + newStartAskDoubles[i])/2;
//                index++;
//            }
//        }
//        if(updateData){
//            for(int i = oldDataStartIndex; i <= oldDataEndIndex;i++){
//                newDateLongs[index] =  [[dateData sampleValue:i] longValue];
//                newBidDoubles[index] = [[bidData sampleValue:i] doubleValue];
//                newAskDoubles[index] = [[askData sampleValue:i] doubleValue];
//                newMidDoubles[index] = (newBidDoubles[index] + newAskDoubles[index])/2;
//                index++;
//            }
//        }
//        if(newEndSampleCount > 0){
//            for(int i = 0; i < newEndSampleCount;i++){
//                newDateLongs[index] =  newEndDateLongs[i];
//                newBidDoubles[index] = newEndBidDoubles[i];
//                newAskDoubles[index] = newEndAskDoubles[i];
//                newMidDoubles[index] = (newBidDoubles[index]+newAskDoubles[index])/2;
//                index++;
//            }
//        }
//    
//        dateData = [CPTNumericData numericDataWithData:newDateData 
//                                                           dataType:CPTDataType(CPTIntegerDataType, 
//                                                                                sizeof(long), 
//                                                                                CFByteOrderGetCurrent()) 
//                                                              shape:nil]; 
//        bidData = [CPTNumericData numericDataWithData:newBidData 
//                                                          dataType:CPTDataType(CPTFloatingPointDataType, 
//                                                                               sizeof(double), 
//                                                                               CFByteOrderGetCurrent()) 
//                                                             shape:nil]; 
//        askData = [CPTNumericData numericDataWithData:newAskData 
//                                                          dataType:CPTDataType(CPTFloatingPointDataType, 
//                                                                               sizeof(double), 
//                                                                               CFByteOrderGetCurrent()) 
//                                                             shape:nil]; 
//        midData = [CPTNumericData numericDataWithData:newMidData 
//                                         dataType:CPTDataType(CPTFloatingPointDataType, 
//                                                              sizeof(double), 
//                                                              CFByteOrderGetCurrent()) 
//                                            shape:nil]; 
//     
//    
//        [dataSeries setXData:dateData];
//        [dataSeries setYData:[[NSMutableDictionary alloc] init]];
//        [[dataSeries yData] setObject:bidData forKey:@"BID"];
//        [[dataSeries yData] setObject:askData forKey:@"ASK"];
//        [[dataSeries yData] setObject:midData forKey:@"MID"];
//        [[dataSeries dataViews] removeAllObjects];
//        [dataSeries setPlotViewWithName:@"ALL" AndStartDateTime:newDateLongs[0] AndEndDateTime:newDateLongs[index-1]];
//    }
//    return dbSuccess;
//}








@end

