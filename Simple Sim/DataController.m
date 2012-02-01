//
//  DataController.m
//  Simple Sim
//
//  Created by Martin O'Connor on 14/01/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "DataController.h"
#import "FMDatabase.h"
#import "IdNamePair.h"
#import "FMDatabaseAdditions.h"
#import "DataSeries.h"
#import "EpochTime.h"
#import "DataView.h"

@implementation DataController
@synthesize connected;
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


-(NSArray *)getListofPairs{
    NSMutableArray *listOfPairs = [[NSMutableArray alloc]init];
    
    int seriesId;
    NSString *seriesName;
    IdNamePair *fxIdNamePair;
    
    if([self connected] == YES){
        FMResultSet *s = [db executeQuery:@"SELECT SeriesId, SeriesName FROM SeriesName WHERE Type='FX'"];
        while ([s next]) {
            //retrieve values for each record
            seriesId = [s intForColumnIndex:0];
            seriesName = [s stringForColumnIndex:1];
            fxIdNamePair = [[IdNamePair alloc] initWithId: seriesId AndName:seriesName];
            [listOfPairs addObject:fxIdNamePair];
        }
    }else{
        [listOfPairs addObject:[NSString stringWithString:@"DB Error!"]];
    }
    return listOfPairs;
}

-(NSArray *)getListofDataTypes
{
    NSMutableArray *listOfDataTypes = [[NSMutableArray alloc]init];
    
    int seriesId;
    NSString *seriesName;
    IdNamePair *fxIdNamePair;
    
    if([self connected] == YES){
        FMResultSet *s = [db executeQuery:@"SELECT SeriesId, SeriesName FROM SeriesName WHERE Type='FX'"];
        while ([s next]) {
            //retrieve values for each record
            seriesId = [s intForColumnIndex:0];
            seriesName = [s stringForColumnIndex:1];
            fxIdNamePair = [[IdNamePair alloc] initWithId: seriesId AndName:seriesName];
            [listOfDataTypes addObject:fxIdNamePair];
        }   
    }else{
        [listOfDataTypes addObject:[NSString stringWithString:@"DB Error!"]];
    }
    return listOfDataTypes;
}

-(long *)getDateRangeForSeries:(NSInteger) seriesId
{
    long *myArray  = malloc(sizeof(long)*2);
    myArray[0] = 0;
    myArray[1] = 0;
    @try{
        if([self connected] == YES)
        {
            FMResultSet *s = [db executeQuery:[NSString stringWithFormat:@"SELECT Mindate, Maxdate FROM DataDateRange WHERE SeriesID = %d", seriesId]];
            [s next];
            myArray[0] = [s intForColumnIndex:0];
            myArray[1] = [s intForColumnIndex:1];
        }else{
            NSLog(@"Database error");
        }
    }
    @catch (NSException *exception) {
        NSLog(@"main: Caught %@: %@", [exception name], [exception reason]);
    }
    return myArray;
}

//More general version of what is above
-(DataSeries *)getBidAskAndStuffForId: (int) dbid AndStartTime: (long) startTime AndEndTime: (long) endTime  ToSampledSeconds:(int) numberOfSeconds;
{
    DataSeries *returnData;
//    returnData = [self getBidAskSeriesForId:dbid  
//                               AndStartTime:startTime 
//                                 AndEndTime:endTime 
//                           ToSampledSeconds:numberOfSeconds];
//    
//    returnData = [self getDataSeriesForId:dbid  
//                                  AndType:1 
//                             AndStartTime:startTime 
//                               AndEndTime:endTime];
//    [self addDataSeriesTo: returnData ForType:2];
//    [self addMidToBidAskSeries: returnData];
//    [self addEWMAToSeries:returnData WithParam: 2584];
//    if(numberOfSeconds > 0){
//        [returnData reduceDataSeriesToSampledSeconds:numberOfSeconds];
//    }
    returnData =[self getBidAskSeriesForId:dbid  
                              AndStartTime:startTime 
                                AndEndTime:endTime 
                          ToSampledSeconds:numberOfSeconds];
    [self addMidToBidAskSeries: returnData];
    [self addEWMAToSeries:returnData WithParam: 2584];
    [returnData setPlotViewWithName:@"ALL" AndStartDateTime:startTime AndEndDateTime:endTime];
    return returnData; 
}

-(DataSeries *)getDataSeriesForId: (int) dbid  AndType: (int) dataTypeId AndStartTime: (long) startTime AndEndTime: (long) endTime 
{
    BOOL success = YES;
    NSString *seriesName; 
    NSString *fieldName;
    NSUInteger resultCount;
    NSUInteger rowCount;
    DataSeries *returnData;
    double pipSize;
    
    @try{
        if([self connected] == YES)
        {
            seriesName = [db stringForQuery:[NSString stringWithFormat:@"SELECT SeriesName FROM SeriesName WHERE SeriesId = %d", dbid]];
            fieldName = [db stringForQuery:[NSString stringWithFormat:@"SELECT Description FROM DataType WHERE DataTypeId = %d", dataTypeId]];
            pipSize = [db doubleForQuery:[NSString stringWithFormat:@"SELECT PipSize FROM SeriesName WHERE SeriesId = %d", dbid]];
            resultCount = [db intForQuery:[NSString stringWithFormat:@"SELECT COUNT(*) FROM DataSeries WHERE SeriesId = %d AND DataTypeId = %d AND TimeDate >= %ld AND TimeDate <= %ld",dbid,dataTypeId,startTime,endTime]];
            
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
        returnData = [[DataSeries alloc] initWithName:seriesName AndDbTag:dbid];
        [returnData setPipSize:pipSize];
        //long minDate, maxDate;
        //double minValue, maxValue;
        NSMutableData * newXData = [NSMutableData dataWithLength:resultCount * sizeof(long)]; 
        NSMutableData * newYData = [NSMutableData dataWithLength:resultCount * sizeof(double)]; 
        long *newXLongs = [newXData mutableBytes]; 
        double *newYDoubles = [newYData mutableBytes]; 
        @try{
            if([self connected] == YES)
            {
                FMResultSet *rs = [db executeQuery:[NSString stringWithFormat:@"SELECT TimeDate, Value FROM DataSeries WHERE SeriesId = %d AND DataTypeId = %d AND TimeDate >= %ld AND TimeDate <= %ld ORDER BY TimeDate ASC", dbid,1,startTime,endTime]];
                rowCount = 0;
                while ([rs next ] && (rowCount < resultCount)) 
                {
                    newXLongs[rowCount] = [rs longForColumnIndex:0];
                    newYDoubles[rowCount] = [rs doubleForColumnIndex:1];
                    rowCount = rowCount + 1;
                }
                if(rowCount != resultCount){
                    NSLog(@"****The result count didn't seem to be added in full, check!!!!!!");
                }
                //maxDate = newXLongs[rowCount - 1];                       
                CPTNumericData * xData = [CPTNumericData numericDataWithData:newXData 
                                                                    dataType:CPTDataType(CPTIntegerDataType, 
                                                                                         sizeof(long), 
                                                                                         CFByteOrderGetCurrent()) 
                                                                       shape:nil]; 
                CPTNumericData * yData = [CPTNumericData numericDataWithData:newYData 
                                                                    dataType:CPTDataType(CPTFloatingPointDataType, 
                                                                                         sizeof(double), 
                                                                                         CFByteOrderGetCurrent()) 
                                                                       shape:nil]; 
                [returnData setDataSeriesWithFieldName:fieldName 
                                                 AndDates:xData 
                                                 AndData:yData];
            }else{
                NSLog(@"Database error");
            }
        }
        @catch (NSException *exception) {
            NSLog(@"main: Caught %@: %@", [exception name], [exception reason]);
        }
    }
    NSLog(@"Returning %lu data for %@",rowCount-1,seriesName);
    return returnData;
}

-(DataSeries *)getBidAskSeriesForId: (int) dbid  AndStartTime: (long) startTime AndEndTime: (long) endTime ToSampledSeconds: (int) numberOfSeconds 
{
    BOOL success = YES;
    NSString *seriesName; 
    //NSString *fieldName;
    NSUInteger sampleCount;
    DataSeries *returnData;
    double pipSize;
    
    
    @try{
        if([self connected] == YES)
        {
            seriesName = [db stringForQuery:[NSString stringWithFormat:@"SELECT SeriesName FROM SeriesName WHERE SeriesId = %d", dbid]];
            //fieldName = [db stringForQuery:[NSString stringWithFormat:@"SELECT Description FROM DataType WHERE DataTypeId = %d", dataTypeId]];
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
        long dataCountMax = (endTime - startTime + 1)/numberOfSeconds;
        long *intermediateDateData = malloc(dataCountMax * sizeof(long));
        double *intermediateBidData = malloc(dataCountMax * sizeof(double)); 
        double *intermediateAskData = malloc(dataCountMax * sizeof(double));
        long currentDateTime;
        double previousBidValue, previousAskValue, currentBidValue, currentAskValue;
        previousBidValue = 0;
        previousAskValue = 0;
        
        long anchorDateTime = [EpochTime epochTimeAtZeroHour:startTime];
        long currentSampleDateTime;
        currentSampleDateTime = anchorDateTime + numberOfSeconds * ((startTime-anchorDateTime)/numberOfSeconds);
        
        bool dataForInterval = NO;
        @try{
            if([self connected] == YES)
            {
                NSString *queryString = [NSString stringWithFormat:@"SELECT DS1.TimeDate, DS1.Value, DS2.Value FROM DataSeries DS1 INNER JOIN DataSeries DS2 ON DS1.TimeDate = DS2.TimeDate AND DS1.SeriesId = DS2.SeriesId  WHERE DS1.SeriesId = %d AND DS1.DataTypeId = %d AND DS2.DataTypeId = %d AND DS1.TimeDate >= %ld AND DS1.TimeDate <= %ld ORDER BY DS1.TimeDate ASC", dbid,1,2,startTime,endTime];
                
                FMResultSet *rs = [db executeQuery:queryString];
                sampleCount = 0;
                while ([rs next ]) 
                {
                    currentDateTime = [rs longForColumnIndex:0];
                    previousBidValue = currentBidValue;
                    previousAskValue = currentAskValue;
                    
                    currentBidValue = [rs doubleForColumnIndex:1];
                    currentAskValue = [rs doubleForColumnIndex:2];
                    
                    if(currentDateTime < currentSampleDateTime)
                    {
                        dataForInterval = YES;
                    }
                    else
                    {    
                        if(dataForInterval == YES)
                        {
                            if(currentDateTime == currentSampleDateTime){
                                intermediateDateData[sampleCount] = currentSampleDateTime;
                                intermediateBidData[sampleCount] = currentBidValue;
                                intermediateAskData[sampleCount] = currentAskValue;

                                currentSampleDateTime = currentSampleDateTime + numberOfSeconds;
                                sampleCount = sampleCount + 1;
                                dataForInterval = NO;
                            }
                            if(currentDateTime > currentSampleDateTime & index > 0){
                                intermediateDateData[sampleCount] = currentSampleDateTime;
                                intermediateBidData[sampleCount] = previousBidValue;
                                intermediateAskData[sampleCount] = previousAskValue;

                                currentSampleDateTime = currentSampleDateTime + numberOfSeconds;
                                sampleCount = sampleCount + 1;
                                dataForInterval = NO;
                            }
                        }
                        else
                        {
                            while(currentSampleDateTime < currentDateTime){
                                currentSampleDateTime = currentSampleDateTime + numberOfSeconds;
                            }
                            dataForInterval = YES;
                        }
                    }
                }   
            }else{
                NSLog(@"Database error");
            }   
        }
        @catch (NSException *exception) {
            NSLog(@"main: Caught %@: %@", [exception name], [exception reason]);
            success = NO;
        }
        if(success){
            returnData = [[DataSeries alloc] initWithName:seriesName AndDbTag:dbid];
            [returnData setPipSize:pipSize];
            NSMutableData * newDateData = [NSMutableData dataWithLength:sampleCount * sizeof(long)]; 
            NSMutableData * newBidData = [NSMutableData dataWithLength:sampleCount * sizeof(double)]; 
            NSMutableData * newAskData = [NSMutableData dataWithLength:sampleCount * sizeof(double)]; 
            
            long *newDateLongs = [newDateData mutableBytes]; 
            double *newBidDoubles = [newBidData mutableBytes]; 
            double *newAskDoubles = [newAskData mutableBytes];
            
            for(int i = 0; i < sampleCount; i++){
                newDateLongs[i] = intermediateDateData[i]; 
                newBidDoubles[i] = intermediateBidData[i];
                newAskDoubles[i] = intermediateAskData[i];
            }
            CPTNumericData * dateData = [CPTNumericData numericDataWithData:newDateData 
                                                                dataType:CPTDataType(CPTIntegerDataType, 
                                                                                     sizeof(long), 
                                                                                         CFByteOrderGetCurrent()) 
                                                                   shape:nil]; 
            CPTNumericData * bidData = [CPTNumericData numericDataWithData:newBidData 
                                                                dataType:CPTDataType(CPTFloatingPointDataType, 
                                                                                         sizeof(double), 
                                                                                         CFByteOrderGetCurrent()) 
                                                                    shape:nil]; 
            CPTNumericData * askData = [CPTNumericData numericDataWithData:newAskData 
                                                                  dataType:CPTDataType(CPTFloatingPointDataType, 
                                                                                       sizeof(double), 
                                                                                       CFByteOrderGetCurrent()) 
                                                                     shape:nil]; 
            [returnData setXData:dateData];
            [returnData setYData:[[NSMutableDictionary alloc] init]];
            [[returnData yData] setObject:bidData forKey:@"BID"];
            [[returnData yData] setObject:askData forKey:@"ASK"];
            [returnData setPlotViewWithName:@"ALL" AndStartDateTime:newDateLongs[0] AndEndDateTime:newDateLongs[sampleCount-1]];
        }
    NSLog(@"Returning %lu data for %@",sampleCount,seriesName);
    }
    return returnData;
}

-(BOOL)addDataSeriesTo:(DataSeries *) dataSeries ForType: (int) dataTypeId 
{
    BOOL success = YES;
    NSString *fieldName;
    NSUInteger resultCount;
    NSUInteger rowCount;
    
    @try{
        if([self connected] == YES)
        {
            resultCount = [db intForQuery:[NSString stringWithFormat:@"SELECT COUNT(*) FROM DataSeries WHERE SeriesId = %d AND DataTypeId = %d AND TimeDate >= %ld AND TimeDate <= %ld",[dataSeries dbId],dataTypeId,[dataSeries minDateTime],[dataSeries maxDateTime]]];
            fieldName = [db stringForQuery:[NSString stringWithFormat:@"SELECT Description FROM DataType WHERE DataTypeId = %d", dataTypeId]];
        }else{
            success = NO;
            NSLog(@"Database error");
        }
    }
    @catch (NSException *exception) {
        NSLog(@"main: Caught %@: %@", [exception name], [exception reason]);
        success = NO;
    }
    if(resultCount == [dataSeries length]){
        success = YES;
    }else{
        success = NO;
    }
    if(success){
        double minValue, maxValue;
        //NSMutableData * newXData = [NSMutableData dataWithLength:resultCount * sizeof(long)]; 
        NSMutableData * newYData = [NSMutableData dataWithLength:resultCount * sizeof(double)]; 
        //long *newXLongs = [newXData mutableBytes]; 
        double *newYDoubles = [newYData mutableBytes]; 
        @try{
            if([self connected] == YES)
            {
                FMResultSet *rs = [db executeQuery:[NSString stringWithFormat:@"SELECT TimeDate, Value FROM DataSeries WHERE SeriesId = %d AND DataTypeId = %d AND TimeDate >= %ld AND TimeDate <= %ld ORDER BY TimeDate ASC", [dataSeries dbId],dataTypeId,[dataSeries minDateTime],[dataSeries maxDateTime]]];
                rowCount = 0;
                while ([rs next ] && (rowCount < resultCount)) 
                {
                    //newXLongs[rowCount] = [rs longForColumnIndex:0];
                    newYDoubles[rowCount] = [rs doubleForColumnIndex:1];
                    if(rowCount == 0){
                        minValue = newYDoubles[rowCount];
                        maxValue = newYDoubles[rowCount];
                    }else{
                        minValue = fmin(newYDoubles[rowCount], minValue); 
                        maxValue = fmax(newYDoubles[rowCount], maxValue); 
                    }
                    rowCount = rowCount + 1;
                }
                if(rowCount != resultCount){
                    NSLog(@"****The result count didn't seem to be added in full, check!!!!!!");
                }
                //Need to fully check the equality of the xData. BUT WE DON'T DO IT. 
                CPTNumericData * yData = [CPTNumericData numericDataWithData:newYData 
                                                                    dataType:CPTDataType(CPTFloatingPointDataType, 
                                                                                         sizeof(double), 
                                                                                         CFByteOrderGetCurrent()) 
                                                                       shape:nil]; 
                [[dataSeries yData] setObject:yData forKey:fieldName];
                
            }else{
                NSLog(@"Database error");
            }
        }
        @catch (NSException *exception) {
            NSLog(@"main: Caught %@: %@", [exception name], [exception reason]);
        }
    }
    NSLog(@"added %@",fieldName);
}

-(void)addMidToBidAskSeries:(DataSeries *) dataSeries
{
    NSMutableData *newMidData = [NSMutableData dataWithLength:([dataSeries length] * sizeof(double))]; 
    double *mid = [newMidData mutableBytes]; 
    CPTNumericData *bid =  [[dataSeries yData] objectForKey:@"BID"];
    CPTNumericData *ask =  [[dataSeries yData] objectForKey:@"ASK"];
    double minMidValue, maxMidValue;
    NSString *fieldName = @"MID";
    
    minMidValue = ([[bid sampleValue:0] doubleValue] + [[ask sampleValue:0] doubleValue])/2.0;
    maxMidValue = minMidValue;
    for(long i = 0; i < [dataSeries length]; i++){
        mid[i] = ([[bid sampleValue:i] doubleValue] + [[ask sampleValue:i] doubleValue])/2.0;
        minMidValue = fmin(minMidValue, mid[i]);
        maxMidValue = fmax(maxMidValue, mid[i]);
    }
    CPTNumericData * midData = [CPTNumericData numericDataWithData:newMidData 
                                                        dataType:CPTDataType(CPTFloatingPointDataType, 
                                                                             sizeof(double), 
                                                                             CFByteOrderGetCurrent()) 
                                                           shape:nil]; 
    [[dataSeries yData] setObject:midData forKey:fieldName];
    DataView *dataViewAll = [[dataSeries dataViews] objectForKey:@"ALL"];
    [dataViewAll addMin:minMidValue AndMax:maxMidValue ForKey:@"MID"];
    
    NSLog(@"Added Mid");
}

-(void)addEWMAToSeries:(DataSeries *) dataSeries WithParam: (int) param
{
    NSString *fieldNameMid = @"MID";
    NSString *fieldNameEWMA = @"EWMA";
    double lambda = 2.0/(1.0+param);
    double minValue, maxValue;
    
    NSMutableData *newData = [NSMutableData dataWithLength:([dataSeries length] * sizeof(double))]; 
    double *ewma = [newData mutableBytes]; 
    CPTNumericData *mid =  [[dataSeries yData] objectForKey:fieldNameMid];
    
    ewma[0] = [[mid sampleValue:0] doubleValue];
    minValue = ewma[0];
    maxValue = ewma[0];
    for(long i = 1; i < [dataSeries length]; i++){
        ewma[i] = (lambda * [[mid sampleValue:i] doubleValue]) + ((1-lambda) * ewma[i-1]);
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
}



@end

