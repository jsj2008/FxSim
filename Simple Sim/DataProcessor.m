//
//  DataProcessor.m
//  Simple Sim
//
//  Created by Martin O'Connor on 26/04/2012.
//  Copyright (c) 2012 OCONNOR RESEARCH. All rights reserved.
//

#import "DataProcessor.h"
#import "UtilityFunctions.h"
#import "SignalStats.h"
#import "PositioningSystem.h"
#import "SignalSystem.h"
#import "DataSeries.h"
#import "EpochTime.h"

@interface DataProcessor()
+ (NSDictionary *) calcEMAForCode: (NSString *) seriesCode
                         WithData: (NSDictionary *) dataDictionary
                       AndOldData: (NSDictionary *) oldDataDictionary;

+ (NSDictionary *) calcSpreadWithData: (NSDictionary *) dataDictionary
                           AndOldData: (NSDictionary *) oldDataDictionary;

+ (NSDictionary *) calcATRForCode: (NSString *) seriesCode
                         WithData: (NSDictionary *) dataDictionary
                       AndOldData: (NSDictionary *) oldDataDictionary;

+ (NSDictionary *) calcHLOCWithData: (NSDictionary *) dataDictionary
                         AndOldData: (NSDictionary *) oldDataDictionary;

+ (NSDictionary *) calcTR2ForCode: (NSString *) seriesCode
                      WithHLCData: (NSDictionary *) dataDictionary
                    AndOldData: (NSDictionary *) oldDataDictionary
                   AndTicDateTime: (NSData *) dateTime;



@end


@implementation DataProcessor

+(BOOL)strategyUnderstood:(NSString *) strategyString
{
    BOOL understood = NO;
    understood = [SignalSystem basicCheck:strategyString];
    return understood;
}

+(long)leadTimeRequired:(NSString *) strategyString
{
    long leadTimeRequired = 0;
    return leadTimeRequired;
}


+(long)leadTicsRequired:(NSString *) strategyString
{
    long leadTicsRequired = 0;
    return leadTicsRequired;
}

+(NSDictionary *) addToDataSeries: (NSDictionary *) dataDictionary
                 DerivedVariables: (NSArray *) derivedVariables
                 WithTrailingData: (NSDictionary *)trailingData
                  AndSignalSystem: (SignalSystem *) signalSystem 
{
    BOOL success = YES, useAllNewData;
    NSMutableDictionary *returnData = [[NSMutableDictionary alloc] init];
    //NSMutableArray *seriesCodes = [[NSMutableArray alloc] init];
    int dataLength;
    NSData *dateTimeData, *oldDateTimeData;
    long *dateTimeArray;
    //NSString *varName;
    BOOL doSignal= NO;
    NSDictionary *oldDataDictionary;
    
    //If needed
    NSDictionary *hlocDataSeries;
    NSMutableData *expansionIndexData;
    NSData *dayNumberData, *dataCountData;
    long *dataCountArray, *dayNumberArray, dayArrayLength, *expansionIndexArray;
    
    BOOL highLowCloseNeeded = NO, highLowCloseCalced = NO;
    for(int i = 0; i < [derivedVariables count]; i ++){
        if([[[derivedVariables objectAtIndex:i] substringToIndex:3]  isEqualToString:@"TR2"]){
            highLowCloseNeeded = YES;
        }
    }
    
    if(signalSystem != Nil){
        doSignal = TRUE;
    }
    
    if([trailingData objectForKey:@"ALLNEWDATA"] != Nil){
        useAllNewData = [[trailingData objectForKey:@"ALLNEWDATA"] boolValue];
    }else{
        success = NO;
    }
    
    if(success){
        dateTimeData =  [dataDictionary objectForKey:@"DATETIME"];
        dateTimeArray = (long *)[dateTimeData bytes];
        dataLength = [dateTimeData length]/sizeof(long);
        
        long *oldDataTimeArray;
        long oldDataLength;
        long dataOverlapIndex;
        
        NSString  *currentSeriesName, *currentSeriesType;
        int seriesIndex = 0;
        while(seriesIndex < [derivedVariables count] && success){
            currentSeriesName = [derivedVariables objectAtIndex:seriesIndex];
            NSArray *seriesComponents = [currentSeriesName componentsSeparatedByString:@"/"];
            currentSeriesType = [seriesComponents objectAtIndex:0];
            
            if(!useAllNewData){
                if([trailingData objectForKey:@"OLDDATA"] == nil || [trailingData objectForKey: @"OVERLAPINDEX"] == nil || [trailingData objectForKey:@"OLDDATETIME"] == nil){
                    success = NO;
                }else{
                    oldDataDictionary = [trailingData objectForKey:@"OLDDATA"];
                    dataOverlapIndex = [[trailingData objectForKey:@"OVERLAPINDEX"] intValue];
                    oldDateTimeData = [trailingData objectForKey:@"OLDDATETIME"];
                    oldDataTimeArray = (long *) [oldDateTimeData bytes];
                    oldDataLength = [oldDateTimeData length]/sizeof(long);
                    
                    for(long i = dataOverlapIndex ; i < oldDataLength; i++){
                        if(dateTimeArray[i-dataOverlapIndex] != oldDataTimeArray[i]){
                            success = NO;
                            NSLog(@"Problem with overlapping periods, times don't match");
                        }
                    }
                }
            }
            
            if(highLowCloseNeeded && !highLowCloseCalced){
                // Get the daily basis data and then map it to the data
                hlocDataSeries = [self calcHLOCWithData:dataDictionary
                                             AndOldData:trailingData];
                
                success = [[hlocDataSeries objectForKey:@"SUCCESS"] boolValue];
                
                if(success){
                    NSMutableData *expandedData, *dataCountExpandedData;
                    NSData  *dayData;
                    double *expandedArray, *dayArray, *dataCountExpandedArray;
                    
                    // The expansion index is the mapping from daily to tic
                    
                    expansionIndexData = [[NSMutableData alloc] initWithLength:dataLength * sizeof(long)];
                    expansionIndexArray = (long *)[expansionIndexData mutableBytes];
                    
                    dataCountExpandedData = [[NSMutableData alloc] initWithLength:dataLength * sizeof(double)];
                    dataCountExpandedArray = (double *)[dataCountExpandedData mutableBytes];
                    
                    dayNumberData = [hlocDataSeries objectForKey:@"DAYNUMBER"];
                    dayNumberArray = (long *)[dayNumberData bytes];
                    dayArrayLength = [dayNumberData length]/sizeof(long);
                    
                    dataCountData = [hlocDataSeries objectForKey:@"DAYDATACOUNT"];
                    dataCountArray = (long *)[dataCountData bytes];
                    
                    int dayIndex = 0;
                    
                    for(int i  = 0 ; i < dataLength; i++){
                        dataCountExpandedArray[i] = 0.0;
                        while(([EpochTime daysSinceEpoch:dateTimeArray[i]] > dayNumberArray[dayIndex]) && dayIndex < dayArrayLength)
                        {
                            dayIndex++;
                        }
                        if([EpochTime daysSinceEpoch:dateTimeArray[i]] != dayNumberArray[dayIndex]){
                            [NSException raise:@"Array overflow searching for day:" format:nil, nil];
                        }else{
                            expansionIndexArray[i] = dayIndex;
                            dataCountExpandedArray[i] = (double)dataCountArray[dayIndex];
                        }
                    }
                    // This was expand simultaneously as the index for expansion was created
                    [returnData setObject:dataCountExpandedData
                                   forKey:@"DAYDATACOUNT"];
                    
                    NSArray *dataKeys = [hlocDataSeries allKeys];
                    for( int i = 0; i < [dataKeys count]; i++){
                        if([[dataKeys objectAtIndex:i] isNotEqualTo:@"SUCCESS"] && [[dataKeys objectAtIndex:i] isNotEqualTo:@"DAYNUMBER"] && [[dataKeys objectAtIndex:i] isNotEqualTo:@"DAYDATACOUNT"])
                        {
                            dayData = [hlocDataSeries objectForKey:[dataKeys objectAtIndex:i]];
                            dayArray = (double *)[dayData bytes];
                            expandedData = [[NSMutableData alloc] initWithLength:dataLength * sizeof(double)];
                            expandedArray = [expandedData mutableBytes];
                            for(int j = 0; j < dataLength; j++){
                                expandedArray[j] = dayArray[expansionIndexArray[j]];
                            }
                            
                            [returnData setObject: expandedData
                                           forKey: [dataKeys objectAtIndex:i]];
                        }
                    }
                }
                highLowCloseCalced = YES;
            }
            
            //Variable: EMA
            if([currentSeriesType  isEqualToString:@"EMA"])
            {
                NSDictionary *emaDataSeries = [self calcEMAForCode:currentSeriesName
                                                          WithData:dataDictionary
                                                        AndOldData:trailingData];
                
                success = [[emaDataSeries objectForKey:@"SUCCESS"] boolValue];
                
                if(success){
                    NSData *emaData = [emaDataSeries objectForKey:currentSeriesName];
                    [returnData setObject:emaData forKey:currentSeriesName];
                }
            }
         
            // Variable: SPREAD
            if([currentSeriesType isEqualToString:@"SPREAD"] || [[currentSeriesType substringToIndex:3]  isEqualToString:@"SPD"])
            {
                NSDictionary *spdDataSeries = [self calcSpreadWithData:dataDictionary
                                                            AndOldData:trailingData];
                
                success = [[spdDataSeries objectForKey:@"SUCCESS"] boolValue];
                
                if(success){
                    NSData *spreadData = [spdDataSeries objectForKey:@"SPREAD"];
                    [returnData setObject:spreadData forKey:@"SPREAD"];
                }
            }
            
            if([currentSeriesType  isEqualToString:@"TR2"])
            {
//                NSDictionary *tr2DataSeries = [self calcTR2WithHLCData:hlocDataSeries
//                                                            AndOldData:trailingData
//                                               ];
                
                NSDictionary *tr2DataSeries = [self calcTR2ForCode:currentSeriesName
                                                       WithHLCData:hlocDataSeries
                                                        AndOldData:trailingData
                                                    AndTicDateTime:dateTimeData];
                
                success = [[tr2DataSeries objectForKey:@"SUCCESS"] boolValue];
                
                if(success){
                    NSData *spreadData = [tr2DataSeries objectForKey:@"TR2"];
                    [returnData setObject:spreadData forKey:@"TR2"];
                }
            }
           
            // Variable: ATR
            if([[currentSeriesName substringToIndex:3]  isEqualToString:@"ATR"])
            {
                NSDictionary *atrDataSeries = [self calcATRForCode:currentSeriesName
                                                          WithData:dataDictionary
                                                        AndOldData:trailingData];
                
                success = [[atrDataSeries objectForKey:@"SUCCESS"] boolValue];
                if(success){
                    NSArray *dataKeys = [atrDataSeries allKeys];
                    for( int i = 0; i < [dataKeys count]; i++){
                        if([[dataKeys objectAtIndex:i] isNotEqualTo:@"SUCCESS"])
                        {
                            [returnData setObject:[atrDataSeries objectForKey:[dataKeys objectAtIndex:i]]
                                           forKey:[dataKeys objectAtIndex:i]];
                        }
                    }
                }
            }
            seriesIndex++;
        }
        
        //Here is where we do make the signals, prerequisite variables should be already created
        if(success && doSignal){
            NSMutableData *signalData, *oldSignalData;
            double *signalArray, *oldSignalArray;
            signalData = [[NSMutableData alloc] initWithLength:dataLength * sizeof(double)];
            signalArray = [signalData mutableBytes];
            
            if([[signalSystem type] isEqualToString:@"SECO"]){
                double *fastArray, *slowArray;
                NSData *variableData;
                variableData =  [returnData objectForKey:[NSString stringWithFormat:@"EMA/%d",[signalSystem fastCode]]];
                fastArray = (double *)[variableData bytes];
                variableData =  [returnData objectForKey:[NSString stringWithFormat:@"EMA/%d",[signalSystem slowCode]]];
                slowArray = (double *)[variableData bytes];
                
                if(!useAllNewData){
                    oldSignalData = [oldDataDictionary objectForKey:@"SIGNAL"];
                    oldSignalArray = (double *)[oldSignalData bytes];
                    for(long i = dataOverlapIndex ; i < oldDataLength; i++){
                        signalArray[i-dataOverlapIndex] = oldSignalArray[i];
                    }
                    for(long i = oldDataLength - dataOverlapIndex; i < dataLength; i++){
                        signalArray[i] = fastArray[i] - slowArray[i];
                    }
                }else{
                    for(int i = 0; i < dataLength; i++){
                        signalArray[i] = fastArray[i] - slowArray[i];
                    }
                }
            }
            if([[signalSystem type] isEqualToString:@"MACD"]){
                double *fastArray, *slowArray, *diffArray, *oldDiffArray, *sdiffArray, *oldSdiffArray;
                double *signalArray, *oldSignalArray;
                signalData = [[NSMutableData alloc] initWithLength:dataLength * sizeof(double)];
                signalArray = [signalData mutableBytes];
                
                int signalSmooth = [signalSystem signalSmooth];
                double parameter = 2.0/(1.0+[UtilityFunctions fib:signalSmooth]);
                
                
                NSMutableData *diffData, *sdiffData;
                NSData *variableData, *oldDiffData, *oldSdiffData;
                
                diffData = [[NSMutableData alloc] initWithLength:dataLength * sizeof(double)];
                diffArray = (double *)[diffData mutableBytes];
                
                sdiffData = [[NSMutableData alloc] initWithLength:dataLength * sizeof(double)];
                sdiffArray = (double *)[sdiffData mutableBytes];
                
                
                
                variableData =  [returnData objectForKey:[NSString stringWithFormat:@"EMA/%d",[signalSystem fastCode]]];
                fastArray = (double *)[variableData bytes];
                variableData =  [returnData objectForKey:[NSString stringWithFormat:@"EMA/%d",[signalSystem slowCode]]];
                slowArray = (double *)[variableData bytes];
                
                
                if(!useAllNewData){
                    oldSignalData = [oldDataDictionary objectForKey:@"SIGNAL"];
                    oldSignalArray = (double *)[oldSignalData bytes];
                    oldDiffData = [oldDataDictionary objectForKey:@"SMACD"];
                    oldDiffArray = (double *)[oldDiffData bytes];
                    oldSdiffData = [oldDataDictionary objectForKey:@"SDIFF"];
                    oldSdiffArray = (double *)[oldDiffData bytes];

                    for(long i = dataOverlapIndex ; i < oldDataLength; i++){
                        signalArray[i-dataOverlapIndex] = oldSignalArray[i];
                        diffArray[i-dataOverlapIndex] = oldDiffArray[i];
                        sdiffArray[i-dataOverlapIndex] = oldSdiffArray[i];
                        
                    }
                    for(long i = oldDataLength - dataOverlapIndex; i < dataLength; i++){
                        diffArray[i] = fastArray[i] - slowArray[i];
                        sdiffArray[i] = (parameter*diffArray[i]) + ((1-parameter) * signalArray[i-1]);
                        signalArray[i] = diffArray[i] - sdiffArray[i];
                    }
                }else{
                    for(int i = 0; i < dataLength; i++){
                        diffArray[i] = fastArray[i] - slowArray[i];
                        if(i > 0){
                            sdiffArray[i] = (parameter*diffArray[i]) + ((1-parameter) * signalArray[i-1]);
                        }else{
                            sdiffArray[i] = diffArray[i];
                        }
                        signalArray[i] = diffArray[i] - sdiffArray[i];
                    }
                }
                [returnData setObject:diffData forKey:@"MACD"];
                [returnData setObject:sdiffData forKey:@"SMACD"];
            }
            [returnData setObject:signalData forKey:@"SIGNAL"];
        }
    }
    [returnData setObject:[NSNumber numberWithBool:success] forKey:@"SUCCESS"];
    return returnData;
}


+ (NSDictionary *) calcEMAForCode: (NSString *) emaCode
    WithData: (NSDictionary *) dataDictionary
    AndOldData: (NSDictionary *) oldDataDictionary
{
    NSMutableDictionary *returnData = [[NSMutableDictionary alloc] init];
    NSMutableData *emaData;
    
    double *emaArray, parameter;
    NSArray *codeComponents = [emaCode componentsSeparatedByString:@"/"];
    int emaCodeParam = [[codeComponents objectAtIndex:1] intValue];
    
    BOOL includeOldData = NO, success = YES;
    includeOldData = ![[oldDataDictionary objectForKey:@"ALLNEWDATA"] boolValue];
    
    int dataOverlapIndex;
    NSDictionary *trailingSeriesDictionary;
    long oldDataLength, dataLength, *oldDataTimeArray, *dateTimeArray;
    
    NSData *midData,  *dateTimeData, *oldDateTimeData, *oldEmaData;
    double *midArray, *oldEmaArray;
    
    midData = [dataDictionary objectForKey:@"MID"];
    dataLength = [midData length]/sizeof(double);
    midArray = (double *)[midData bytes];
    dateTimeData =  [dataDictionary objectForKey:@"DATETIME"];
    dateTimeArray = (long *)[dateTimeData bytes];
    
    if(includeOldData){
        if([oldDataDictionary objectForKey:@"OLDDATA"] == nil || [oldDataDictionary objectForKey: @"OVERLAPINDEX"] == nil || [oldDataDictionary objectForKey:@"OLDDATETIME"] == nil){
            success = NO;
        }else{
            trailingSeriesDictionary = [oldDataDictionary objectForKey:@"OLDDATA"];
            dataOverlapIndex = [[oldDataDictionary objectForKey:@"OVERLAPINDEX"] intValue];
            oldDateTimeData = [oldDataDictionary objectForKey:@"OLDDATETIME"];
            oldDataTimeArray = (long *) [oldDateTimeData bytes];
            oldDataLength = [oldDateTimeData length]/sizeof(long);
            
            for(long i = dataOverlapIndex ; i < oldDataLength; i++){
                if(dateTimeArray[i-dataOverlapIndex] != oldDataTimeArray[i]){
                    success = NO;
                    NSLog(@"Problem with overlapping periods, times don't match");
                }
            }
        }
    }
    
    if(success){
        parameter = 2.0/(1.0+[UtilityFunctions fib:emaCodeParam]);
        emaData = [[NSMutableData alloc] initWithLength:dataLength * sizeof(double)];
        emaArray = [emaData mutableBytes];
        
        if(includeOldData){
            oldEmaData = [trailingSeriesDictionary objectForKey:emaCode];
            oldEmaArray = (double *)[oldEmaData bytes];
            
            for(long i = dataOverlapIndex ; i <= oldDataLength; i++){
                emaArray[i-dataOverlapIndex] = oldEmaArray[i];
            }
            for(long i = oldDataLength - dataOverlapIndex; i < dataLength; i++){
                emaArray[i] = (parameter*midArray[i]) + ((1-parameter) * emaArray[i-1]);
            }
            [returnData setObject:emaData forKey:emaCode];
        }else{
            emaArray[0] = midArray[0];
            for(int i = 1; i < dataLength; i++){
                emaArray[i] = (parameter*midArray[i]) + ((1-parameter) * emaArray[i-1]);
            }
            [returnData setObject:emaData forKey:emaCode];
        }
    }
    
    if(success){
        [returnData setObject:[NSNumber numberWithBool:YES] forKey:@"SUCCESS"];
    }else{
        [returnData setObject:[NSNumber numberWithBool:NO] forKey:@"SUCCESS"];
        
    }

    return returnData;
}

+ (NSDictionary *) calcSpreadWithData: (NSDictionary *) dataDictionary
                          AndOldData: (NSDictionary *) oldDataDictionary
{
    NSMutableDictionary *returnData = [[NSMutableDictionary alloc] init];
    NSDictionary *trailingSeriesDictionary;
    
    BOOL includeOldData = NO, success = YES;
    includeOldData = ![[oldDataDictionary objectForKey:@"ALLNEWDATA"] boolValue];
    
    int dataOverlapIndex;
    
    long oldDataLength, dataLength, *oldDataTimeArray, *dateTimeArray;
    
    NSData *bidData, *askData, *dateTimeData, *oldDateTimeData;
    double *bidArray, *askArray;
    
    bidData = [dataDictionary objectForKey:@"BID"];
    askData = [dataDictionary objectForKey:@"ASK"];
    dataLength = [bidData length]/sizeof(double);
    bidArray = (double *)[bidData bytes];
    askArray = (double *)[askData bytes];
    dateTimeData =  [dataDictionary objectForKey:@"DATETIME"];
    dateTimeArray = (long *)[dateTimeData bytes];
    
    if(includeOldData){
        if([oldDataDictionary objectForKey:@"OLDDATA"] == nil || [oldDataDictionary objectForKey: @"OVERLAPINDEX"] == nil || [oldDataDictionary objectForKey:@"OLDDATETIME"] == nil){
            success = NO;
        }else{
            trailingSeriesDictionary = [oldDataDictionary objectForKey:@"OLDDATA"];
            dataOverlapIndex = [[oldDataDictionary objectForKey:@"OVERLAPINDEX"] intValue];
            oldDateTimeData = [oldDataDictionary objectForKey:@"OLDDATETIME"];
            oldDataTimeArray = (long *) [oldDateTimeData bytes];
            oldDataLength = [oldDateTimeData length]/sizeof(long);
            
            for(long i = dataOverlapIndex ; i < oldDataLength; i++){
                if(dateTimeArray[i-dataOverlapIndex] != oldDataTimeArray[i]){
                    success = NO;
                    NSLog(@"Problem with overlapping periods, times don't match");
                }
            }
        }
    }

    if(success){
        NSMutableData *spreadData;
        NSData *oldSpreadData;
        double *spreadArray, *oldSpreadArray;
        
        spreadData = [[NSMutableData alloc] initWithLength:dataLength * sizeof(double)];
        spreadArray = [spreadData mutableBytes];
        if(includeOldData){
            oldSpreadData = [trailingSeriesDictionary objectForKey:@"SPREAD"];
            oldSpreadArray = (double *)[oldSpreadData bytes];
            for(long i = dataOverlapIndex ; i <= oldDataLength; i++){
                spreadArray[i-dataOverlapIndex] = oldSpreadArray[i];
            }
            for(long i = oldDataLength - dataOverlapIndex; i < dataLength; i++){
                spreadArray[i] = askArray[i] - bidArray[i];
            }
            [returnData setObject:spreadData forKey:@"SPREAD"];
        }else{
            for(int i = 0; i < dataLength; i++){
                spreadArray[i] = askArray[i] - bidArray[i];
            }
            [returnData setObject:spreadData forKey:@"SPREAD"];
        }
    }
    
    if(success){
        [returnData setObject:[NSNumber numberWithBool:YES] forKey:@"SUCCESS"];
    }else{
        [returnData setObject:[NSNumber numberWithBool:NO] forKey:@"SUCCESS"];
        
    }
    return returnData;
}

+ (NSDictionary *) calcHLOCWithData: (NSDictionary *) dataDictionary
                        AndOldData: (NSDictionary *) oldDataDictionary
{
    
    NSMutableData  *lastDateTimeForDayData, *closeForDayData, *highForDayData, *lowForDayData, *openForDayData, *dataCountData, *dayNumberData;
       NSMutableDictionary *returnData = [[NSMutableDictionary alloc] init];
    
    long *lastDateTimeForDayArray, *dataCountArray, *dayNumberArray;
    
    double  *closeForDayArray, *highForDayArray, *lowForDayArray, *openForDayArray;
    
    BOOL includeOldData = NO, success = YES;
    includeOldData = ![[oldDataDictionary objectForKey:@"ALLNEWDATA"] boolValue];
    
    int dataOverlapIndex, maxNumberOfDays;
    NSDictionary *trailingSeriesDictionary;
    long oldDataLength, dataLength, *oldDataTimeArray, *dateTimeArray;
    
    NSData *midData,  *dateTimeData, *oldDateTimeData;
    double *midArray;
    
    midData = [dataDictionary objectForKey:@"MID"];
    dataLength = [midData length]/sizeof(double);
    midArray = (double *)[midData bytes];
    dateTimeData =  [dataDictionary objectForKey:@"DATETIME"];
    dateTimeArray = (long *)[dateTimeData bytes];
    
    if(includeOldData){
        if([oldDataDictionary objectForKey:@"OLDDATA"] == nil || [oldDataDictionary objectForKey: @"OVERLAPINDEX"] == nil || [oldDataDictionary objectForKey:@"OLDDATETIME"] == nil){
            success = NO;
        }else{
            trailingSeriesDictionary = [oldDataDictionary objectForKey:@"OLDDATA"];
            dataOverlapIndex = [[oldDataDictionary objectForKey:@"OVERLAPINDEX"] intValue];
            oldDateTimeData = [oldDataDictionary objectForKey:@"OLDDATETIME"];
            oldDataTimeArray = (long *) [oldDateTimeData bytes];
            oldDataLength = [oldDateTimeData length]/sizeof(long);
            
            for(long i = dataOverlapIndex ; i < oldDataLength; i++){
                if(dateTimeArray[i-dataOverlapIndex] != oldDataTimeArray[i]){
                    success = NO;
                    NSLog(@"Problem with overlapping periods, times don't match");
                }
            }
        }
    }
    if(success){
        if(includeOldData){
            NSData *oldMidData = [trailingSeriesDictionary objectForKey:@"MID"];
            double *oldMidArray = (double *)[oldMidData bytes];
            
            long dataIndex = 0, dayNumber;
            //Go forward to the first weekday
            while(dataIndex < dataLength && ![EpochTime isWeekday:dateTimeArray[dataIndex]])
            {
                dataIndex++;
            }
            
            if(dataIndex < dataLength){
                dayNumber = [EpochTime daysSinceEpoch:dateTimeArray[dataIndex]];
                
                //Go backwards to include at least 1 weekday day
                int dayCount = 0;
                dataIndex = oldDataLength;
                while((dayCount < 3) && (dataIndex > 0)){
                    dataIndex--;
                    if([EpochTime isWeekday:oldDataTimeArray[dataIndex]] &&
                       ([EpochTime daysSinceEpoch:oldDataTimeArray[dataIndex]] != [EpochTime daysSinceEpoch:oldDataTimeArray[dataIndex+1]])){
                        dayCount++;
                    }
                }
                dataIndex++;
                
                // This is the number of days for which we do calculations. It coveres all the new data, plus at least 1 weekday of old
                maxNumberOfDays = [EpochTime daysSinceEpoch:dateTimeArray[dataLength-1]] - [EpochTime daysSinceEpoch:oldDataTimeArray[dataIndex]] + 1;
                
                
                
                
                lastDateTimeForDayData = [NSMutableData dataWithLength:sizeof(long) * maxNumberOfDays];
                closeForDayData = [NSMutableData dataWithLength:sizeof(double) * maxNumberOfDays];
                highForDayData = [NSMutableData dataWithLength:sizeof(double) * maxNumberOfDays];
                lowForDayData = [NSMutableData dataWithLength:sizeof(double) * maxNumberOfDays];
                openForDayData = [NSMutableData dataWithLength:sizeof(double) * maxNumberOfDays];
                dataCountData = [NSMutableData dataWithLength:sizeof(long) * maxNumberOfDays];
                dayNumberData = [NSMutableData dataWithLength:sizeof(long) * maxNumberOfDays];
                
                lastDateTimeForDayArray = (long *)[lastDateTimeForDayData mutableBytes];
                closeForDayArray = (double *)[closeForDayData mutableBytes];
                highForDayArray = (double *)[highForDayData mutableBytes];
                lowForDayArray = (double *)[lowForDayData mutableBytes];
                openForDayArray = (double *)[openForDayData mutableBytes];
                dataCountArray = (long *)[dataCountData mutableBytes];
                dayNumberArray = (long *)[dayNumberData mutableBytes];
                
                for(int i = 0; i < maxNumberOfDays; i++){
                    dataCountArray[i] = 0;
                }
                
                for(int i = 0; i < maxNumberOfDays; i++){
                    dayNumberArray[i] = [EpochTime daysSinceEpoch:oldDataTimeArray[dataIndex]] + i;
                }
                
                int dayDataIndex = 0;
                if(dataIndex < oldDataLength){
                    lastDateTimeForDayArray[dayDataIndex] = oldDataTimeArray[dataIndex];
                    closeForDayArray[dayDataIndex] = oldMidArray[dataIndex];
                    highForDayArray[dayDataIndex] = oldMidArray[dataIndex];
                    lowForDayArray[dayDataIndex] = oldMidArray[dataIndex];
                    openForDayArray[dayDataIndex] = oldMidArray[dataIndex];
                    dataCountArray[dayDataIndex]--;
                    dayNumber =  [EpochTime daysSinceEpoch:oldDataTimeArray[dataIndex]];
                    
                    while(dataIndex < oldDataLength){
                        if([EpochTime daysSinceEpoch:oldDataTimeArray[dataIndex]] >= dayNumber){
                            dayNumber =  [EpochTime daysSinceEpoch:oldDataTimeArray[dataIndex]];
                            while(dayNumber != dayNumberArray[dayDataIndex] && dayDataIndex < maxNumberOfDays)
                            {
                                dataCountArray[dayDataIndex] = -dataCountArray[dayDataIndex];
                                dayDataIndex++;
                            }
                            if(dayNumber != dayNumberArray[dayDataIndex])
                            {
                                [NSException raise:@"Array overflow searching for day:" format:nil, nil];
                            }
                            highForDayArray[dayDataIndex] = oldMidArray[dataIndex];
                            lowForDayArray[dayDataIndex] = oldMidArray[dataIndex];
                            openForDayArray[dayDataIndex] = oldMidArray[dataIndex];
                            
                        }else{
                            highForDayArray[dayDataIndex] = MAX(highForDayArray[dayDataIndex], oldMidArray[dataIndex]);
                            lowForDayArray[dayDataIndex] = MIN(lowForDayArray[dayDataIndex], oldMidArray[dataIndex]);
                        }
                        lastDateTimeForDayArray[dayDataIndex] = oldDataTimeArray[dataIndex];
                        closeForDayArray[dayDataIndex] = oldMidArray[dataIndex];
                        dataCountArray[dayDataIndex]--;
                        dataIndex++;
                    }
                }
                
                dataIndex = 0;
                while(dayNumberArray[dayDataIndex] > [EpochTime daysSinceEpoch:dateTimeArray[0]] && dayDataIndex > 0){
                    dayDataIndex--;
                }
                
                while(dataIndex < dataLength){
                    if([EpochTime daysSinceEpoch:dateTimeArray[dataIndex]] != dayNumber){
                        dayNumber = [EpochTime daysSinceEpoch:dateTimeArray[dataIndex]];
                        //                        if(dayNumber == 13378){
                        //                            NSLog(@"Check");
                        //                        }
                        while(dayNumber != dayNumberArray[dayDataIndex] && dayDataIndex < maxNumberOfDays)
                        {
                            dataCountArray[dayDataIndex] = -dataCountArray[dayDataIndex];
                            dayDataIndex++;
                        }
                        if(dayNumber != dayNumberArray[dayDataIndex])
                        {
                            [NSException raise:@"Array overflow searching for day:" format:nil, nil];
                        }
                        highForDayArray[dayDataIndex] = midArray[dataIndex];
                        lowForDayArray[dayDataIndex] = midArray[dataIndex];
                        openForDayArray[dayDataIndex] = midArray[dataIndex];
                        
                    }else{
                        highForDayArray[dayDataIndex] = MAX(highForDayArray[dayDataIndex], midArray[dataIndex]);
                        lowForDayArray[dayDataIndex] = MIN(lowForDayArray[dayDataIndex], midArray[dataIndex]);
                    }
                    closeForDayArray[dayDataIndex] = midArray[dataIndex];
                    lastDateTimeForDayArray[dayDataIndex] = dateTimeArray[dataIndex];
                    dataCountArray[dayDataIndex]--;
                    dataIndex++;
                    // NSLog([NSString stringWithFormat:@"%ld %ld",dataIndex,dayNumberArray[0]]);
                }
            }else{
                success = NO;
            }
        }else{
            maxNumberOfDays = [EpochTime daysSinceEpoch:dateTimeArray[dataLength-1]] - [EpochTime daysSinceEpoch:dateTimeArray[0]]+ 1;
            
            lastDateTimeForDayData = [NSMutableData dataWithLength:sizeof(long) * maxNumberOfDays];
            closeForDayData = [NSMutableData dataWithLength:sizeof(double) * maxNumberOfDays];
            highForDayData = [NSMutableData dataWithLength:sizeof(double) * maxNumberOfDays];
            lowForDayData = [NSMutableData dataWithLength:sizeof(double) * maxNumberOfDays];
            openForDayData = [NSMutableData dataWithLength:sizeof(double) * maxNumberOfDays];
            dataCountData = [NSMutableData dataWithLength:sizeof(long) * maxNumberOfDays];
            dayNumberData = [NSMutableData dataWithLength:sizeof(long) * maxNumberOfDays];
            
            lastDateTimeForDayArray = (long *)[lastDateTimeForDayData mutableBytes];
            closeForDayArray = (double *)[closeForDayData mutableBytes];
            highForDayArray = (double *)[highForDayData mutableBytes];
            lowForDayArray = (double *)[lowForDayData mutableBytes];
            openForDayArray = (double *)[openForDayData mutableBytes];
            dataCountArray = (long *)[dataCountData mutableBytes];
            dayNumberArray = (long *)[dayNumberData mutableBytes];
            
            for(int i = 0; i < maxNumberOfDays; i++){
                dataCountArray[i] = 0;
            }
            
            for(int i = 0; i < maxNumberOfDays; i++){
                dayNumberArray[i] = [EpochTime daysSinceEpoch:dateTimeArray[0]] + i;
            }
            
            long dataIndex = 0;
            int dayDataIndex = 0;
            int dayNumber;
            dayNumber = [EpochTime daysSinceEpoch:dateTimeArray[dataIndex]];
            
            // Put in initial values
            highForDayArray[dayDataIndex] = midArray[dataIndex];
            lowForDayArray[dayDataIndex] = midArray[dataIndex];
            openForDayArray[dayDataIndex] = midArray[dataIndex];
            closeForDayArray[dayDataIndex] = midArray[dataIndex];
            lastDateTimeForDayArray[dayDataIndex] = dateTimeArray[dataIndex];
            
            while(dataIndex < dataLength){
                if([EpochTime daysSinceEpoch:dateTimeArray[dataIndex]] != dayNumber){
                    dayNumber =  [EpochTime daysSinceEpoch:dateTimeArray[dataIndex]];
                    while(dayNumber != dayNumberArray[dayDataIndex] && dayDataIndex < maxNumberOfDays)
                    {
                        dataCountArray[dayDataIndex] = -dataCountArray[dayDataIndex];
                        dayDataIndex++;
                    }
                    if(dayNumber != dayNumberArray[dayDataIndex])
                    {
                        [NSException raise:@"Array overflow searching for day:" format:nil, nil];
                    }
                    highForDayArray[dayDataIndex] = midArray[dataIndex];
                    lowForDayArray[dayDataIndex] = midArray[dataIndex];
                    openForDayArray[dayDataIndex] = midArray[dataIndex];
                    
                }else{
                    highForDayArray[dayDataIndex] = MAX(highForDayArray[dayDataIndex], midArray[dataIndex]);
                    lowForDayArray[dayDataIndex] = MIN(lowForDayArray[dayDataIndex], midArray[dataIndex]);
                }
                closeForDayArray[dayDataIndex] = midArray[dataIndex];
                lastDateTimeForDayArray[dayDataIndex] = dateTimeArray[dataIndex];
                if(lastDateTimeForDayArray[dayDataIndex]/(24*60*60) != dayNumberArray[dayDataIndex]){
                    NSLog(@"Check");
                }
                dataCountArray[dayDataIndex]--;
                dataIndex++;
                //NSLog([NSString stringWithFormat:@"%ld %ld",dataIndex,dayNumberArray[0]]);
            }
        }
    }
    
    if(success){
        [returnData setObject:[NSNumber numberWithBool:YES] forKey:@"SUCCESS"];
        [returnData setObject:dataCountData forKey:@"DAYDATACOUNT"];
        [returnData setObject:openForDayData forKey:@"OPEN"];
        [returnData setObject:closeForDayData forKey:@"CLOSE"];
        [returnData setObject:highForDayData forKey:@"HIGH"];
        [returnData setObject:lowForDayData forKey:@"LOW"];
        [returnData setObject:lastDateTimeForDayData forKey:@"LASTTIME"];
        [returnData setObject:dayNumberData forKey:@"DAYNUMBER"];
    }else{
        [returnData setObject:[NSNumber numberWithBool:NO] forKey:@"SUCCESS"];
        
    }
    
    return returnData;
    
}

+ (NSDictionary *) calcTR2ForCode: (NSString *) seriesCode
                      WithHLCData: (NSDictionary *) dataDictionary
                       AndOldData: (NSDictionary *) oldDataDictionary
                   AndTicDateTime: (NSData *) ticDateTime;
{
    BOOL includeOldData = NO, success = YES;
    NSMutableDictionary *returnData = [[NSMutableDictionary alloc] init];
    
    double *highArray, *lowArray, *closeArray;
    long *dayNumberArray, *lastDateTimeForDayArray, *dataCountArray;
    
    NSData *closeData = [dataDictionary objectForKey:@"CLOSE"];
    closeArray = (double *)[closeData bytes];
    NSData *highData = [dataDictionary objectForKey:@"HIGH"];
    highArray = (double *)[highData bytes];
    NSData *lowData = [dataDictionary objectForKey:@"LOW"];
    lowArray = (double *)[lowData bytes];
    NSData *dayNumberData = [dataDictionary objectForKey:@"DAYNUMBER"];
    dayNumberArray = (long *)[dayNumberData bytes];
    NSData *lastDateTimeForDayData = [dataDictionary objectForKey:@"LASTTIME"];
    lastDateTimeForDayArray = (long *)[lastDateTimeForDayData bytes];
    NSData *dataCountData = [dataDictionary objectForKey:@"DAYDATACOUNT"];
    dataCountArray = (long *)[dataCountData bytes];
    NSMutableData *atrData;
    
    int dataLength = [closeData length]/sizeof(double);
    
    // Get rid of any weekend days
    
    NSMutableData  *lastDateTimeData2, *closeData2, *highData2, *lowData2, *dataCountData2,*dayNumberData2;
    
    long *lastDateTimeArray2, *dataCountArray2, *dayNumberArray2;
    double *closeArray2, *highArray2, *lowArray2;
    
    int reducedNumberOfDays = 0;
    for(int i = 0; i < dataLength; i++){
        if(dataCountArray[i]>0 && [EpochTime isWeekday:lastDateTimeForDayArray[i]]){
            reducedNumberOfDays++;
        }
    }

    lastDateTimeData2 = [NSMutableData dataWithLength:sizeof(long) * reducedNumberOfDays];
    closeData2 = [NSMutableData dataWithLength:sizeof(double) * reducedNumberOfDays];
    highData2 = [NSMutableData dataWithLength:sizeof(double) * reducedNumberOfDays];
    lowData2 = [NSMutableData dataWithLength:sizeof(double) * reducedNumberOfDays];
    dataCountData2 = [NSMutableData dataWithLength:sizeof(long) * reducedNumberOfDays];
    dayNumberData2 = [NSMutableData dataWithLength:sizeof(long) * reducedNumberOfDays];
    
    lastDateTimeArray2 = (long *)[lastDateTimeData2 mutableBytes];
    closeArray2 = (double *)[closeData2 mutableBytes];
    highArray2 = (double *)[highData2 mutableBytes];
    lowArray2 = (double *)[lowData2 mutableBytes];
    dataCountArray2 = (long *)[dataCountData2 mutableBytes];
    dayNumberArray2 = (long *)[dayNumberData2 mutableBytes];
    
    int arrayIndex = 0;
    for(int i = 0; i < dataLength; i++){
        if(dataCountArray[i]>0 && [EpochTime isWeekday:lastDateTimeForDayArray[i]]){
            lastDateTimeArray2[arrayIndex] = lastDateTimeForDayArray[i];
            closeArray2[arrayIndex] = closeArray[i];
            highArray2[arrayIndex] = highArray[i];
            lowArray2[arrayIndex] = lowArray[i];
            dataCountArray2[arrayIndex] = dataCountArray[i];
            dayNumberArray2[arrayIndex] = dayNumberArray[i];
            arrayIndex++;
        }
    }
    
    closeArray = closeArray2;
    lowArray = lowArray2;
    highArray = highArray2;
    //dataCountArray = dataCountArray2;
    dayNumberArray = dayNumberArray2;
    lastDateTimeForDayArray = lastDateTimeArray2;
    dataLength = reducedNumberOfDays;
    // Finished excluding weekend days
    
    NSArray *codeComponents = [seriesCode componentsSeparatedByString:@"/"];
    int daysForAveraging = [[codeComponents objectAtIndex:1] intValue];
    includeOldData = ![[oldDataDictionary objectForKey:@"ALLNEWDATA"] boolValue];
    
    NSData  *oldAtrData, *oldCloseData, *oldDateTimeData;

    double *atrArray, *oldAtrArray, *oldCloseArray;
    long *oldDateTimeArray;
    int dataOverlapIndex, oldDataLength;
    
    
    
    if(includeOldData){
        if([oldDataDictionary objectForKey:@"OLDDATA"] == nil || [oldDataDictionary objectForKey: @"OVERLAPINDEX"] == nil || [oldDataDictionary objectForKey:@"OLDDATETIME"] == nil){
            success = NO;
        }else{
            NSDictionary *trailingSeriesDictionary = [oldDataDictionary objectForKey:@"OLDDATA"];
            oldAtrData =  [trailingSeriesDictionary objectForKey:@"TR2"];
            oldAtrArray = (double *)[oldAtrData bytes];
            oldCloseData = [trailingSeriesDictionary objectForKey:@"CLOSE"];
            oldCloseArray = (double *)[oldCloseData bytes];
            oldDateTimeData = [oldDataDictionary objectForKey:@"OLDDATETIME"];
            oldDateTimeArray = (long *)[oldDateTimeData bytes];
            oldDataLength = [oldAtrData length]/sizeof(double);
            
            dataOverlapIndex = oldDataLength-1;
            while([EpochTime daysSinceEpoch:oldDateTimeArray[dataOverlapIndex]] >= dayNumberArray[1] && dataOverlapIndex > 0){
                dataOverlapIndex--;
            }
            
            if((dataOverlapIndex == 0 && [EpochTime daysSinceEpoch:oldDateTimeArray[dataOverlapIndex]] >= dayNumberArray[1])){
                includeOldData = NO;
                NSLog(@"Don't seem to have overlapping for ATR calculation using previous data");
            }else{
                double trueRange;
                atrData = [[NSMutableData alloc] initWithLength:sizeof(double) * dataLength ];
                atrArray = (double *)[atrData bytes];
                
                atrArray[0] = oldAtrArray[dataOverlapIndex];
                if(dataOverlapIndex > 0){
                    trueRange  = MAX(highArray[1]-lowArray[1],MAX(highArray[1]-oldCloseArray[dataOverlapIndex],oldCloseArray[dataOverlapIndex]-lowArray[1]));
                }else{
                    trueRange  = highArray[0]-lowArray[0];
                }
                if(dataLength > 1){
                    atrArray[1] = ((daysForAveraging - 1) * oldAtrArray[dataOverlapIndex] + trueRange)/daysForAveraging;
                }
                if(dataLength > 2){
                    for(int i = 2; i < dataLength; i++){
                        trueRange  = MAX(highArray[i]-lowArray[i],MAX(highArray[i]-closeArray[i-1],closeArray[i-1]-lowArray[i]));
                        atrArray[i] = ((daysForAveraging - 1) * atrArray[i-1] + trueRange)/ daysForAveraging;
                    }
                }
            }
        }
    }
    if(!includeOldData){
        double trueRange;
        atrData = [[NSMutableData alloc] initWithLength:(dataLength * sizeof(double))];
        atrArray = (double *)[atrData bytes];
        
        //atrArray[0] = highArray[0]-lowArray[0];
        int nData;
        for(int i = 0; i < daysForAveraging && i < dataLength; i++){
            trueRange = 0.0;
            nData = 0;
            for(int j = 0; j <= i; j++){
                if(j==0){
                    trueRange = highArray[0]-lowArray[0];
                }else{
                    trueRange = trueRange + MAX(highArray[j]-lowArray[j],MAX(highArray[j]-closeArray[j-1],closeArray[j-1]-lowArray[j]));
                }
                nData++;
            }
            atrArray[i] = trueRange/nData;
        }
        if(dataLength >= daysForAveraging){
            for(int i = daysForAveraging; i < dataLength; i++){
                if(lastDateTimeForDayArray[i] >= 1074708000){
                    NSLog(@"Check");
                }
                
                trueRange  = MAX(highArray[i]-lowArray[i],MAX(highArray[i]-closeArray[i-1],closeArray[i-1]-lowArray[i]));
                if(trueRange > 1){
                    NSLog(@"Check");
                }
                atrArray[i] = ((daysForAveraging - 1) * atrArray[i-1] + trueRange)/ daysForAveraging;
            }
        }
    }
    
    if(success){
        long ticDataLength = [ticDateTime length] / sizeof(long);
        long *ticDateTimeArray = (long *)[ticDateTime bytes];
        NSMutableData *atrExpandedData = [[NSMutableData alloc] initWithLength:ticDataLength * sizeof(double)];
        double *atrExpandedArray = (double *)[atrExpandedData bytes];
        
        int indexByDay  = 0;
        while([EpochTime daysSinceEpoch:ticDateTimeArray[0]] > dayNumberArray[indexByDay]){
            indexByDay++;
        }
        
        for(int i = 0; i < ticDataLength; i++){
            while([EpochTime daysSinceEpoch:ticDateTimeArray[i]] > dayNumberArray[indexByDay]){
                indexByDay++;
            }
            if(indexByDay > (dataLength-1)){
                atrExpandedArray[i] = atrArray[dataLength-1];
            }else{
                if([EpochTime daysSinceEpoch:ticDateTimeArray[i]] == dayNumberArray[indexByDay]){
                    atrExpandedArray[i] = atrArray[indexByDay];
                }else{
                    //Carry forward for weekend, don't calc these
                    if(![EpochTime isWeekday:ticDateTimeArray[i]]){
                        if(indexByDay > 0){
                            atrExpandedArray[i] = atrArray[indexByDay-1];
                        }
                    }else{
                        NSLog(@"Check");
                    }
                }
            }
        }
        
        [returnData setObject:[NSNumber numberWithBool:YES] forKey:@"SUCCESS"];
        [returnData setObject:atrExpandedData forKey:@"TR2"];
    }else{
        [returnData setObject:[NSNumber numberWithBool:NO] forKey:@"SUCCESS"];
        
    }
    return returnData;
}

+ (NSDictionary *) calcATRForCode: (NSString *) seriesCode
                         WithData: (NSDictionary *) dataDictionary
                       AndOldData: (NSDictionary *) oldDataDictionary
{
    NSArray *codeComponents = [seriesCode componentsSeparatedByString:@"/"];
    int daysForAveraging = [[codeComponents objectAtIndex:1] intValue];
    
    NSMutableData  *lastDateTimeForDayData, *closeForDayData, *highForDayData, *lowForDayData, *atrForDayData;
    NSMutableDictionary *returnData = [[NSMutableDictionary alloc] init];
    
    long *lastDateTimeForDayArray;
    
    double  *closeForDayArray, *highForDayArray, *lowForDayArray, *atrForDayArray;
    
    BOOL includeOldData = NO, success = YES;
    includeOldData = ![[oldDataDictionary objectForKey:@"ALLNEWDATA"] boolValue];
    
    int dataOverlapIndex;
    NSDictionary *trailingSeriesDictionary;
    long oldDataLength, dataLength, *oldDataTimeArray, *dateTimeArray;
 
    NSData *midData,  *dateTimeData, *oldDateTimeData;
    double *midArray;
    
    midData = [dataDictionary objectForKey:@"MID"];
    dataLength = [midData length]/sizeof(double);
    midArray = (double *)[midData bytes];
    dateTimeData =  [dataDictionary objectForKey:@"DATETIME"];
    dateTimeArray = (long *)[dateTimeData bytes];
 
    if(includeOldData){
        if([oldDataDictionary objectForKey:@"OLDDATA"] == nil || [oldDataDictionary objectForKey: @"OVERLAPINDEX"] == nil || [oldDataDictionary objectForKey:@"OLDDATETIME"] == nil){
            success = NO;
        }else{
            trailingSeriesDictionary = [oldDataDictionary objectForKey:@"OLDDATA"];
            dataOverlapIndex = [[oldDataDictionary objectForKey:@"OVERLAPINDEX"] intValue];
            oldDateTimeData = [oldDataDictionary objectForKey:@"OLDDATETIME"];
            oldDataTimeArray = (long *) [oldDateTimeData bytes];
            oldDataLength = [oldDateTimeData length]/sizeof(long);
            
            for(long i = dataOverlapIndex ; i < oldDataLength; i++){
                if(dateTimeArray[i-dataOverlapIndex] != oldDataTimeArray[i]){
                    success = NO;
                    NSLog(@"Problem with overlapping periods, times don't match");
                }
            }
        }
    }
    if(success){
        if(includeOldData){
            NSData *oldMidData = [trailingSeriesDictionary objectForKey:@"MID"];
            double *oldMidArray = (double *)[oldMidData bytes];
            NSData *oldAtrData = [trailingSeriesDictionary objectForKey:seriesCode];
            double *oldAtrArray = (double *)[oldAtrData bytes];
            
            long dataIndex = 0, dayNumber;
            //Go forward to the first weekday
            while(dataIndex < dataLength && ![EpochTime isWeekday:dateTimeArray[dataIndex]])
                dataIndex++;
            
            if(dataIndex < dataLength){
                dayNumber = [EpochTime daysSinceEpoch:dateTimeArray[dataIndex]];
                
                //Go backwards to include at least 1 weekday days
                int dayCount = 0;
                dataIndex = oldDataLength;
                while((dayCount < 3) && (dataIndex > 0)){
                    dataIndex--;
                    if([EpochTime isWeekday:oldDataTimeArray[dataIndex]] &&
                       ([EpochTime daysSinceEpoch:oldDataTimeArray[dataIndex]] != [EpochTime daysSinceEpoch:oldDataTimeArray[dataIndex+1]])){
                        dayCount++;
                    }
                }
                dataIndex++;
                
                // This is the number of days for which we do calculations. It coveres all the new data, plus at least 1 weekday of old
                int maxNumberOfDays = [EpochTime daysSinceEpoch:dateTimeArray[dataLength-1]] - [EpochTime daysSinceEpoch:oldDataTimeArray[dataIndex]] + 1;
                
                lastDateTimeForDayData = [NSMutableData dataWithLength:sizeof(long) * maxNumberOfDays];
                closeForDayData = [NSMutableData dataWithLength:sizeof(double) * maxNumberOfDays];
                highForDayData = [NSMutableData dataWithLength:sizeof(double) * maxNumberOfDays];
                lowForDayData = [NSMutableData dataWithLength:sizeof(double) * maxNumberOfDays];
                atrForDayData = [NSMutableData dataWithLength:sizeof(double) * maxNumberOfDays];
                
                lastDateTimeForDayArray = (long *)[lastDateTimeForDayData mutableBytes];
                closeForDayArray = (double *)[closeForDayData mutableBytes];
                highForDayArray = (double *)[highForDayData mutableBytes];
                lowForDayArray = (double *)[lowForDayData mutableBytes];
                atrForDayArray = (double *)[atrForDayData mutableBytes];
                
                int dayDataIndex = 0;
                if(dataIndex < oldDataLength){
                    lastDateTimeForDayArray[dayDataIndex] = oldDataTimeArray[dataIndex];
                    closeForDayArray[dayDataIndex] = oldMidArray[dataIndex];
                    highForDayArray[dayDataIndex] = oldMidArray[dataIndex];
                    lowForDayArray[dayDataIndex] = oldMidArray[dataIndex];
                    atrForDayArray[dayDataIndex] = oldAtrArray[dataIndex];
                    
                    dayNumber =  [EpochTime daysSinceEpoch:oldDataTimeArray[dataIndex]];
                    while(dataIndex < oldDataLength){
                        if([EpochTime daysSinceEpoch:oldDataTimeArray[dataIndex]] != dayNumber){
                            dayNumber =  [EpochTime daysSinceEpoch:oldDataTimeArray[dataIndex]];
                            //                                    double trueRange  = MAX(highForDayArray[dayDataIndex]-lowForDayArray[dayDataIndex],MAX(highForDayArray[dayDataIndex]-closeForDayArray[dayDataIndex-1],closeForDayArray[dayDataIndex-1])-lowForDayArray[dayDataIndex]);
                            //
                            //                                    atrForDayArray[dayDataIndex] = ((daysForAveraging - 1) * atrForDayArray[dayDataIndex-1] + trueRange)/ daysForAveraging;
                            dayDataIndex++;
                            highForDayArray[dayDataIndex] = oldMidArray[dataIndex];
                            lowForDayArray[dayDataIndex] = oldMidArray[dataIndex];
                            atrForDayArray[dayDataIndex] = oldAtrArray[dataIndex];
                        }else{
                            highForDayArray[dayDataIndex] = MAX(highForDayArray[dayDataIndex], oldMidArray[dataIndex]);
                            lowForDayArray[dayDataIndex] = MIN(lowForDayArray[dayDataIndex], oldMidArray[dataIndex]);
                        }
                        lastDateTimeForDayArray[dayDataIndex] = oldDataTimeArray[dataIndex];
                        closeForDayArray[dayDataIndex] = oldMidArray[dataIndex];
                        
                        dataIndex++;
                        
                    }
                }
                
                dataIndex = 0;
                while(dataIndex < dataLength){
                    if([EpochTime daysSinceEpoch:dateTimeArray[dataIndex]] != dayNumber){
                        double trueRange  = MAX(highForDayArray[dayDataIndex]-lowForDayArray[dayDataIndex],MAX(highForDayArray[dayDataIndex]-closeForDayArray[dayDataIndex-1],closeForDayArray[dayDataIndex-1])-lowForDayArray[dayDataIndex]);
                        
                        atrForDayArray[dayDataIndex] = ((daysForAveraging - 1) * atrForDayArray[dayDataIndex-1] + trueRange)/ daysForAveraging;
                        dayDataIndex++;
                        highForDayArray[dayDataIndex] = midArray[dataIndex];
                        lowForDayArray[dayDataIndex] = midArray[dataIndex];
                        dayNumber = [EpochTime daysSinceEpoch:dateTimeArray[dataIndex]];
                    }else{
                        highForDayArray[dayDataIndex] = MAX(highForDayArray[dayDataIndex], midArray[dataIndex]);
                        lowForDayArray[dayDataIndex] = MIN(lowForDayArray[dayDataIndex], midArray[dataIndex]);
                    }
                    closeForDayArray[dayDataIndex] = midArray[dataIndex];
                    lastDateTimeForDayArray[dayDataIndex] = dateTimeArray[dataIndex];
                    dataIndex++;
                }
            }else{
                success = NO;
            }
        }else{
            int maxNumberOfDays = [EpochTime daysSinceEpoch:dateTimeArray[dataLength-1]] - [EpochTime daysSinceEpoch:dateTimeArray[0]]+ 1;
            
            lastDateTimeForDayData = [NSMutableData dataWithLength:sizeof(long) * maxNumberOfDays];
            closeForDayData = [NSMutableData dataWithLength:sizeof(double) * maxNumberOfDays];
            highForDayData = [NSMutableData dataWithLength:sizeof(double) * maxNumberOfDays];
            lowForDayData = [NSMutableData dataWithLength:sizeof(double) * maxNumberOfDays];
            atrForDayData = [NSMutableData dataWithLength:sizeof(double) * maxNumberOfDays];
            
            lastDateTimeForDayArray = (long *)[lastDateTimeForDayData mutableBytes];
            closeForDayArray = (double *)[closeForDayData mutableBytes];
            highForDayArray = (double *)[highForDayData mutableBytes];
            lowForDayArray = (double *)[lowForDayData mutableBytes];
            atrForDayArray = (double *)[atrForDayData mutableBytes];
            
            long dataIndex = 0;
            int dayDataIndex = 0;
            int dayNumber;
            double trueRange;
            dayNumber = [EpochTime daysSinceEpoch:dateTimeArray[dataIndex]];
            
            // Put in initial values
            highForDayArray[dayDataIndex] = midArray[dataIndex];
            lowForDayArray[dayDataIndex] = midArray[dataIndex];
            closeForDayArray[dayDataIndex] = midArray[dataIndex];
            lastDateTimeForDayArray[dayDataIndex] = dateTimeArray[dataIndex];
            
            while(dataIndex < dataLength){
                if([EpochTime daysSinceEpoch:dateTimeArray[dataIndex]] != dayNumber){
                    dayNumber =  [EpochTime daysSinceEpoch:dateTimeArray[dataIndex]];
                    
                    if(dayDataIndex == 0){
                        atrForDayArray[dayDataIndex] =  highForDayArray[dayDataIndex]-lowForDayArray[dayDataIndex];
                    }
                    if(dayDataIndex > 0 && dayDataIndex < (daysForAveraging - 1) ){
                        atrForDayArray[dayDataIndex] =  MAX(highForDayArray[dayDataIndex]-lowForDayArray[dayDataIndex],MAX(highForDayArray[dayDataIndex]-closeForDayArray[dayDataIndex-1],closeForDayArray[dayDataIndex-1]-lowForDayArray[dayDataIndex]));
                    }
                    
                    if(dayDataIndex == daysForAveraging - 1){
                        trueRange = 0.0;
                        for(int i = 0; i < daysForAveraging; i++){
                            trueRange = trueRange + atrForDayArray[i];
                            atrForDayArray[i] = 0.0;
                        }
                        atrForDayArray[dayDataIndex] =  trueRange/daysForAveraging;
                    }
                    
                    if(dayDataIndex > daysForAveraging - 1){
                        trueRange  = MAX(highForDayArray[dayDataIndex]-lowForDayArray[dayDataIndex],MAX(highForDayArray[dayDataIndex]-closeForDayArray[dayDataIndex-1],closeForDayArray[dayDataIndex-1]-lowForDayArray[dayDataIndex]));
                        atrForDayArray[dayDataIndex] = ((daysForAveraging - 1) * atrForDayArray[dayDataIndex-1] + trueRange)/ daysForAveraging;
                    }
                    dayDataIndex++;
                    highForDayArray[dayDataIndex] = midArray[dataIndex];
                    lowForDayArray[dayDataIndex] = midArray[dataIndex];
                    
                }else{
                    highForDayArray[dayDataIndex] = MAX(highForDayArray[dayDataIndex], midArray[dataIndex]);
                    lowForDayArray[dayDataIndex] = MIN(lowForDayArray[dayDataIndex], midArray[dataIndex]);
                }
                closeForDayArray[dayDataIndex] = midArray[dataIndex];
                lastDateTimeForDayArray[dayDataIndex] = dateTimeArray[dataIndex];
                
                dataIndex++;
            }
            // Last days ATR
            trueRange  = MAX(highForDayArray[dayDataIndex]-lowForDayArray[dayDataIndex],MAX(highForDayArray[dayDataIndex]-closeForDayArray[dayDataIndex],closeForDayArray[dayDataIndex]-lowForDayArray[dayDataIndex]));
            atrForDayArray[dayDataIndex] = ((daysForAveraging - 1) * atrForDayArray[dayDataIndex-1] + trueRange)/ daysForAveraging;
        }
        
        NSMutableData *atrData = [[NSMutableData alloc] initWithLength:dataLength * sizeof(double)];
        double *atrArray = [atrData mutableBytes];
        NSMutableData *highData = [[NSMutableData alloc] initWithLength:dataLength * sizeof(double)];
        double *highArray = [highData mutableBytes];
        NSMutableData *lowData = [[NSMutableData alloc] initWithLength:dataLength * sizeof(double)];
        double *lowArray = [lowData mutableBytes];
        NSMutableData *closeData = [[NSMutableData alloc] initWithLength:dataLength * sizeof(double)];
        double *closeArray = [closeData mutableBytes];
        
        int indexByDay  = 0;
        while([EpochTime daysSinceEpoch:dateTimeArray[0]] > [EpochTime daysSinceEpoch:lastDateTimeForDayArray[indexByDay]]){
            indexByDay++;
        }
        
        for(int i = 0; i < dataLength; i++){
            while([EpochTime daysSinceEpoch:dateTimeArray[i]] > [EpochTime daysSinceEpoch:lastDateTimeForDayArray[indexByDay]]){
                indexByDay++;
            }
            
            atrArray[i] = atrForDayArray[indexByDay];
            highArray[i] = highForDayArray[indexByDay];
            lowArray[i] = lowForDayArray[indexByDay];
            closeArray[i] = closeForDayArray[indexByDay];
        }
        [returnData setObject:atrData forKey:seriesCode];
        [returnData setObject:closeData forKey:@"CLOSE"];
        [returnData setObject:highData forKey:@"HIGH"];
        [returnData setObject:lowData forKey:@"LOW"];
    }
    
    if(success){
        [returnData setObject:[NSNumber numberWithBool:YES] forKey:@"SUCCESS"];
    }else{
        [returnData setObject:[NSNumber numberWithBool:NO] forKey:@"SUCCESS"];
       
    }
    return returnData;
}








@end




