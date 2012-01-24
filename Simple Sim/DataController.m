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
            //retrieve values for each record
            //[myArray addObject:[NSNumber numberWithInt:[s intForColumnIndex:0]]];
            //[myArray addObject:[NSNumber numberWithInt:[s intForColumnIndex:1]]];
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

// This is a placeholder function for something more genaral 
-(DataSeries *)getBidAskSeriesForId: (int) dbid AndDay:(NSDate *) day
{
    long seriesStartTime;
    long seriesEndTime;
    DataSeries *returnData;
    
    int daysForward = 3;  // or 60 :-)
    int daysBackward = -5;
    
    // create a calendar
    NSCalendar *gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
    // set up date components
    NSDateComponents *components = [[NSDateComponents alloc] init];
    [components setDay:daysBackward];
    seriesStartTime = [EpochTime epochTimeAtZeroHour:[[gregorian dateByAddingComponents:components toDate:day options:0]  timeIntervalSince1970]];
    
    [components setDay:daysForward];
    
    seriesEndTime = [EpochTime epochTimeNextDayAtZeroHour:[[gregorian dateByAddingComponents:components toDate:day options:0] timeIntervalSince1970]];
    
    //Stretch the times to zero hour of the first day and zero hour of (last day plus one)
    seriesStartTime = [EpochTime epochTimeAtZeroHour:seriesStartTime];
    seriesEndTime = [EpochTime epochTimeNextDayAtZeroHour:seriesEndTime];
    
    returnData = [self getDataSeriesForId:dbid  AndType:1 AndStartTime:seriesStartTime AndEndTime:seriesEndTime];
    [self addDataSeriesTo: returnData ForType:2];
    [self addMidToBidAskSeries: returnData];
    [self addEWMAToSeries:returnData WithParam: 2584];
    return returnData; 
}

-(DataSeries *)getBidAskSeriesForId: (int) dbid AndDay:(NSDate *) day ToSampledSeconds:(int) numberOfSeconds
{
    //long dateStartTime;
    //long dateEndTime;
    DataSeries *returnData;
    //dateStartTime = [day timeIntervalSince1970];
    //dateEndTime = [EpochTime epochTimeNextDayAtZeroHour:dateStartTime];
    //dateStartTime = [EpochTime epochTimeAtZeroHour:dateStartTime];
    //returnData = [self getDataSeriesForId:dbid  AndType:1 AndStartTime:dateStartTime AndEndTime:dateEndTime];
    returnData = [self getBidAskSeriesForId:dbid AndDay:day];
    //[self addDataSeriesTo: returnData ForType:2];
    
    if(numberOfSeconds > 0){
        [returnData reduceDataSeriesToSampledSeconds:numberOfSeconds];
    }
    
    // Set the plotting data to the start of the day and end of the day
    long dateStartTime = [day timeIntervalSince1970];
    long dateEndTime = [EpochTime epochTimeNextDayAtZeroHour:dateStartTime];
    dateStartTime = [EpochTime epochTimeAtZeroHour:dateStartTime];
    
    long plotDataStartIndex = [returnData nearestXBelowOrEqualTo:dateStartTime];
    long plotDataEndIndex = [returnData nearestXBelowOrEqualTo:dateEndTime];
    [returnData setPlottingSubsetFromStartIndex:plotDataStartIndex ToEndIndex:plotDataEndIndex];
    
    return returnData; 
}


-(DataSeries *)getDataSeriesForId: (int) dbid  AndType: (int) dataTypeId AndStartTime: (long) startTime AndEndTime: (long) endTime 
{
    BOOL success = YES;
    NSString *seriesName; 
    NSString *fieldName;
    NSUInteger resultCount;
    NSUInteger rowCount;
    DataSeries *returnedData;
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
        returnedData = [[DataSeries alloc] initWithName:seriesName AndDbTag:dbid];
        [returnedData setPipSize:pipSize];
        long minDate, maxDate;
        double minValue, maxValue;
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
                    if(rowCount == 0){
                        minDate = newXLongs[rowCount];
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
                maxDate = newXLongs[rowCount - 1];                       
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
                [returnedData setDataSeriesWithFieldName:fieldName AndLength:rowCount AndMinDate:minDate AndMaxDate:maxDate AndDates:xData AndData:yData AndMinDataValue:minValue AndMaxDataValue: maxValue];
            }else{
                NSLog(@"Database error");
            }
        }
        @catch (NSException *exception) {
            NSLog(@"main: Caught %@: %@", [exception name], [exception reason]);
        }
    }
    NSLog(@"Returning %lu data for %@",rowCount-1,seriesName);
    return returnedData;
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
            resultCount = [db intForQuery:[NSString stringWithFormat:@"SELECT COUNT(*) FROM DataSeries WHERE SeriesId = %d AND DataTypeId = %d AND TimeDate >= %ld AND TimeDate <= %ld",[dataSeries idtag],dataTypeId,[dataSeries minXdata],[dataSeries maxXdata]]];
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
    if(resultCount == [dataSeries countForPlot]){
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
                FMResultSet *rs = [db executeQuery:[NSString stringWithFormat:@"SELECT TimeDate, Value FROM DataSeries WHERE SeriesId = %d AND DataTypeId = %d AND TimeDate >= %ld AND TimeDate <= %ld ORDER BY TimeDate ASC", [dataSeries idtag],dataTypeId,[dataSeries minXdata],[dataSeries maxXdata]]];
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
                
                [[dataSeries minYdataForPlot] setObject:[NSNumber numberWithDouble:minValue] forKey:fieldName];
                [[dataSeries maxYdataForPlot] setObject:[NSNumber numberWithDouble:maxValue] forKey:fieldName];
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
    NSMutableData *newMidData = [NSMutableData dataWithLength:([dataSeries count] * sizeof(double))]; 
    double *mid = [newMidData mutableBytes]; 
    CPTNumericData *bid =  [[dataSeries yData] objectForKey:@"BID"];
    CPTNumericData *ask =  [[dataSeries yData] objectForKey:@"ASK"];
    double minMidValue, maxMidValue;
    NSString *fieldName = @"MID";
    
    minMidValue = ([[bid sampleValue:0] doubleValue] + [[ask sampleValue:0] doubleValue])/2.0;
    maxMidValue = minMidValue;
    for(long i = 0; i < [dataSeries count]; i++){
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
    [[dataSeries minYdataForPlot] setObject:[NSNumber numberWithDouble:minMidValue] forKey:fieldName];
    [[dataSeries maxYdataForPlot] setObject:[NSNumber numberWithDouble:maxMidValue] forKey:fieldName];
    NSLog(@"Added Mid");
}

-(void)addEWMAToSeries:(DataSeries *) dataSeries WithParam: (int) param
{
    NSString *fieldName = @"MID";
    double lambda = 2.0/(1.0+param);
    double minValue, maxValue;
    
    NSMutableData *newData = [NSMutableData dataWithLength:([dataSeries count] * sizeof(double))]; 
    double *ewma = [newData mutableBytes]; 
    CPTNumericData *mid =  [[dataSeries yData] objectForKey:fieldName];
    
    ewma[0] = [[mid sampleValue:0] doubleValue];
    minValue = ewma[0];
    maxValue = ewma[0];
    for(long i = 1; i < [dataSeries count]; i++){
        ewma[i] = (lambda * [[mid sampleValue:i] doubleValue]) + ((1-lambda) * ewma[i-1]);
        minValue = fmin(minValue,ewma[i]);
        maxValue = fmax(maxValue,ewma[i]);
    }
    //NSString *newFieldName = [NSString stringWithFormat:@"EWMA%d",param];
    NSString *newFieldName = [NSString stringWithString:@"EWMA"];
    CPTNumericData * ewmaData = [CPTNumericData numericDataWithData:newData 
                                                          dataType:CPTDataType(CPTFloatingPointDataType, 
                                                                               sizeof(double), 
                                                                               CFByteOrderGetCurrent()) 
                                                            shape:nil];
    [[dataSeries yData] setObject:ewmaData forKey:newFieldName];
    [[dataSeries minYdataForPlot] setObject:[NSNumber numberWithDouble:minValue] forKey:fieldName];
    [[dataSeries maxYdataForPlot] setObject:[NSNumber numberWithDouble:maxValue] forKey:fieldName];                                                         
    
}



@end

