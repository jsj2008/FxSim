//
//  DataIO.m
//  Simple Sim
//
//  Created by O'Connor Martin on 22/12/2011.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "DataIO.h"
#import "IdNamePair.h"
#import "FMDatabase.h"
#import "FMDatabaseAdditions.h"
#import "DataSeries.h"
#import "EpochTime.h"

@implementation DataIO
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
    if(resultCount == [dataSeries count]){
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
                [dataSeries setMinYdata:fmin(minValue,[dataSeries minYdata])];
                [dataSeries setMaxYdata:fmax(maxValue,[dataSeries maxYdata])];
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


@end
