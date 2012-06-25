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

@interface DataProcessor()

+(NSDictionary *) secoWithDataSeries: (NSDictionary *) dataSeries
                         AndStrategy: (NSString *) strategyString
                      AndProcessInfo: (NSDictionary *) parameters
                       AndStatsArray: (NSMutableArray *) statistics;

+(NSDictionary *) ewmaWithDataSeries: (NSDictionary *) dataSeries
                         AndStrategy: (NSString *) strategyString
                      AndProcessInfo: (NSDictionary *) parameters;

@end


@implementation DataProcessor

+(BOOL)strategyUnderstood:(NSString *) strategyString
{
    BOOL understood = NO;
    NSArray *strategyComponents = [strategyString componentsSeparatedByString:@"/"];
    if([[strategyComponents objectAtIndex:0] isEqualToString:@"SECO"]){

        understood = YES;
    }
    if([[strategyComponents objectAtIndex:0] isEqualToString:@"EMA"]){
        
        understood = YES;
    } 
    return understood;
}


+(NSDictionary *)processWithDataSeries: (NSDictionary *) dataSeries
                           AndStrategy: (NSString *) strategyString
                        AndProcessInfo: (NSDictionary *) parameters
                     AndReturningStats: (NSMutableArray *) statsArray;
{
    //NSDictionary *resultingData = [[NSMutableDictionary alloc] init ];
    BOOL strategyRecognised = NO;
    NSDictionary *resultingData;
    
    NSArray *strategyComponents = [strategyString componentsSeparatedByString:@"/"];
    
    
    
    if([[strategyComponents objectAtIndex:0] isEqualToString:@"SECO"]){
        resultingData = [self secoWithDataSeries: dataSeries
                                     AndStrategy: strategyString
                                  AndProcessInfo: parameters
                                   AndStatsArray:statsArray];
        strategyRecognised = YES;
    }
    
    if([[strategyComponents objectAtIndex:0] isEqualToString:@"EMA"]){
        resultingData = [self ewmaWithDataSeries: dataSeries
                                     AndStrategy: strategyString
                                  AndProcessInfo: parameters];
        strategyRecognised = YES;
        
    }
    
    
    if(!strategyRecognised){
        NSMutableDictionary *returnData = [[NSMutableDictionary alloc] initWithCapacity:1];
        [returnData setObject:[NSNumber numberWithBool:NO] forKey:@"SUCCESS"];
        resultingData = returnData;
    }
    
    return resultingData;
}

+(NSDictionary *) ewmaWithDataSeries: (NSDictionary *) dataSeries
                         AndStrategy: (NSString *) strategyString
                      AndProcessInfo: (NSDictionary *) parameters
{
    BOOL allNewData, success = YES;
    NSMutableDictionary *returnData = [[NSMutableDictionary alloc] init];
    NSArray *strategyComponents = [strategyString componentsSeparatedByString:@"/"];
    NSMutableArray *emaCodes = [[NSMutableArray alloc] init];
    int dataLength; 
    NSData *midData, *dateTimeData;
    double *midArray; 
    long *dateTimeArray;
    
    if([strategyComponents count] == 1){
        success = NO;
    }
    
    if([strategyComponents count] == 2){
        NSString *param = [strategyComponents objectAtIndex:1];
        NSArray *splitParam = [param componentsSeparatedByString:@":"];
        
        if([splitParam count] == 3){
            if([[splitParam objectAtIndex:0] intValue] < [[splitParam objectAtIndex:2] intValue]){
                for(int i = [[splitParam objectAtIndex:0] intValue]; i <= [[splitParam objectAtIndex:2] intValue]; i = i +[[splitParam objectAtIndex:1] intValue])
                {
                    [emaCodes addObject:[NSNumber numberWithInt:i]];
                }
            }else{
                success = NO;
            }
        }else{
            if([splitParam count] == 1){
                [emaCodes addObject:param];
            }
            
        }
    }
    
    if([strategyComponents count] > 2){
        for(int i = 1; i < [strategyComponents count]; i++){
            [emaCodes addObject:[strategyComponents objectAtIndex:i]];
        }
    }
       
    if([parameters objectForKey:@"ALLNEWDATA"] != nil){
        allNewData = [[parameters objectForKey:@"ALLNEWDATA"] boolValue];
    }else{
        success = NO;
    }
    
    if(success){
        midData = [dataSeries objectForKey:@"MID"];
        dataLength = [midData length]/sizeof(double);
        midArray = (double *)[midData bytes];
        dateTimeData =  [dataSeries objectForKey:@"DATETIME"];
        dateTimeArray = (long *)[dateTimeData bytes];
        
        NSMutableData *emaData;
        NSData *oldData, *oldDateTimeData;
        NSDictionary *oldDataDictionary;
        double *emaArray, *oldArray;
        long *oldDataTimeArray;
        long oldDataLength;
        int dataOverlapIndex;
        
        for(int seriesIndex = 0; seriesIndex < [emaCodes count]; seriesIndex++){
            float parameter;
            NSString *seriesName =  [NSString stringWithFormat:@"EWMA%d",[[emaCodes objectAtIndex:seriesIndex] intValue]];
            parameter = 2.0/(1.0+[UtilityFunctions fib:[[emaCodes objectAtIndex:seriesIndex] intValue]]);
            emaData = [[NSMutableData alloc] initWithLength:dataLength * sizeof(double)];
            emaArray = [emaData mutableBytes];
            
            if(!allNewData){
                if([parameters objectForKey:@"OLDDATA"] == nil || [parameters objectForKey:@"OVERLAPINDEX"] == nil || [parameters objectForKey:@"OLDDATETIME"] == nil){
                    success = NO;
                }else{
                    oldDataDictionary = [parameters objectForKey:@"OLDDATA"];
                    dataOverlapIndex = [[parameters objectForKey:@"OVERLAPINDEX"] intValue];
                    oldDateTimeData = [parameters objectForKey:@"OLDDATETIME"];
                    oldDataTimeArray = (long *) [oldDateTimeData bytes];
                    oldDataLength = [oldDateTimeData length]/sizeof(long);
                    
                    if([oldDataDictionary objectForKey:seriesName] == nil){
                        success = NO;
                    }else{
                        for(int i = dataOverlapIndex ; i < oldDataLength; i++){
                            if(dateTimeArray[i-dataOverlapIndex] != oldDataTimeArray[i]){
                                success = NO;
                                NSLog(@"Problem with overlapping periods, times don't match");
                            }
                        }
                        
                        
                        oldData = [oldDataDictionary objectForKey:seriesName];
                        oldArray = (double *)[oldData bytes];
                        for(int i = dataOverlapIndex ; i <= oldDataLength; i++){
                            emaArray[i-dataOverlapIndex] = oldArray[i];
                        }
                        for(int i = oldDataLength - dataOverlapIndex; i < dataLength; i++){
                            emaArray[i] = (parameter*midArray[i]) + ((1-parameter) * emaArray[i-1]);
                        }
                        [returnData setObject:emaData forKey:seriesName];
                    }
                }
            }else{
                emaArray[0] = midArray[0];
                for(int i = 1; i < dataLength; i++){
                    emaArray[i] = (parameter*midArray[i]) + ((1-parameter) * emaArray[i-1]);
                }
                [returnData setObject:emaData forKey:seriesName];
            }
            if(!success){
                break;
            }
        }
    }else{
        NSLog(@"Didn't work out trying to add EWMA");
    }
    [returnData setObject:[NSNumber numberWithBool:success] forKey:@"SUCCESS"];
    return returnData;
}

+(NSDictionary *)secoWithDataSeries: (NSDictionary *) dataSeries
                        AndStrategy: (NSString *) strategyString
                     AndProcessInfo: (NSDictionary *) parameters
                      AndStatsArray: (NSMutableArray *) statistics
{
    NSMutableDictionary *returnData = [[NSMutableDictionary alloc] init];
    
    NSArray *strategyComponents = [strategyString componentsSeparatedByString:@"/"];
    int dataLength; 
    
    BOOL allNewData, success = YES, doStats;
    NSData *midData, *dateTimeData, *bidData, *askData; //
    NSMutableData *fastData, *slowData, *signalData, *levelData;
    double *midArray, *fastArray, *slowArray, *signalArray, *bidArray, *askArray, *levelArray; //
    long *dateTimeArray;
    
    int fastCode, slowCode;
    float fastParameter, slowParameter;
    
    //Relating to signal stats 
    int trailingSignal = 0;
    int currentSignal = 0;
    long currentSignalEntryTime = 0;
    double currentSignalEntryPrice = 0;
    double currentSignalExitPrice = 0;
    long currentSignalSamplesInProfit = 0;
    long currentSignalTotalSamples = 0;
    double currentSignalMaxPrice = 0.0;
    double currentSignalMinPrice = 0.0;
    BOOL newSignal = NO;
    SignalStats *signalStats;
    
    if(statistics != nil){
        doStats = YES;
    }else{
        doStats = NO;
    }
    
    fastCode = [[strategyComponents objectAtIndex:1] intValue];
    slowCode = [[strategyComponents objectAtIndex:2] intValue];
    
    NSString *fastName = [NSString stringWithFormat:@"EWMA%d", fastCode];
    NSString *slowName = [NSString stringWithFormat:@"EWMA%d", slowCode];
    
    fastParameter = 2.0/(1.0+[UtilityFunctions fib:fastCode]);
    slowParameter = 2.0/(1.0+[UtilityFunctions fib:slowCode]);
        
    if([parameters objectForKey:@"ALLNEWDATA"] != nil){
        allNewData = [[parameters objectForKey:@"ALLNEWDATA"] boolValue];
    }else{
        success = NO;
        NSLog(@"Can't find the key value for ALLNEWDATA");
    }
    
    if(success){
        midData = [dataSeries objectForKey:@"MID"];
        bidData = [dataSeries objectForKey:@"BID"];
        askData = [dataSeries objectForKey:@"ASK"];
        dateTimeData = [dataSeries objectForKey:@"DATETIME"];
        dataLength = [midData length]/sizeof(double);
        midArray = (double *)[midData bytes];
        bidArray = (double *)[bidData bytes];
        askArray = (double *)[askData bytes];
        dateTimeArray = (long *)[dateTimeData bytes];
        
        fastData = [[NSMutableData alloc] initWithLength:dataLength * sizeof(double)]; 
        slowData = [[NSMutableData alloc] initWithLength:dataLength * sizeof(double)]; 
        signalData = [[NSMutableData alloc] initWithLength:dataLength * sizeof(double)];
        levelData = [[NSMutableData alloc] initWithLength:dataLength * sizeof(double)];
        
        fastArray = [fastData mutableBytes];
        slowArray = [slowData mutableBytes];
        signalArray = [signalData mutableBytes];
        levelArray = [levelData mutableBytes];
    }
    
    if(success){
        if(!allNewData){
            if(doStats){
                if([statistics count] == 0){
                    doStats = NO;
                }
            }
            
            NSDictionary *oldDataDictionary;
            NSData *oldFastData, *oldSlowData, *oldSignalData, *oldDateTimeData, *oldLevelData;
            double *oldFastArray, *oldSlowArray, *oldSignalArray, *oldLevelArray;
            long *oldDateTimeArray;
            long oldDataLength;
            int dataOverlapIndex;
        
            if([parameters objectForKey:@"OLDDATA"] == nil || [parameters objectForKey:@"OVERLAPINDEX"] == nil || [parameters objectForKey:@"OLDDATETIME"] == nil){
                success = NO;
                NSLog(@"Can't find the key value for one of: OLDDATA, OVERLAPINDEX, OLDDATETIME");
            }else{
                oldDataDictionary = [parameters objectForKey:@"OLDDATA"];
                dataOverlapIndex = [[parameters objectForKey:@"OVERLAPINDEX"] intValue];
            }
            if(success){
                oldFastData = [oldDataDictionary objectForKey:fastName];
                oldFastArray = (double *)[oldFastData bytes];
                oldSlowData = [oldDataDictionary objectForKey:slowName];
                oldSlowArray = (double *)[oldSlowData bytes];
                oldSignalData = [oldDataDictionary objectForKey:@"SIGNAL"];
                oldSignalArray = (double *)[oldSignalData bytes];
                oldLevelData = [oldDataDictionary objectForKey:@"KEYPRICE"];
                oldLevelArray =  (double *)[oldLevelData bytes];
                oldDateTimeData = [parameters objectForKey:@"OLDDATETIME"];
                oldDateTimeArray = (long *)[oldDateTimeData bytes];
                oldDataLength = [oldDateTimeData length] / sizeof(long);
            
                for(int i = dataOverlapIndex ; i < oldDataLength; i++){
                    fastArray[i-dataOverlapIndex] = oldFastArray[i];
                    slowArray[i- dataOverlapIndex] = oldSlowArray[i];
                    signalArray[i-dataOverlapIndex] = oldSignalArray[i];
                    levelArray[i-dataOverlapIndex] = oldLevelArray[i];
                    if(dateTimeArray[i-dataOverlapIndex] != oldDateTimeArray[i]){
                        success = NO;
                        NSLog(@"Problem with overlapping periods, times don't match");
                    }
                }
            }
            
            if(success){
                long lastStatUpdateTime;
                SignalStats *lastUpdateStats;
                if(doStats){
                    lastUpdateStats = [statistics objectAtIndex:[statistics count]-1];
                    if([lastUpdateStats updateTime] != 0){
                        lastStatUpdateTime = [lastUpdateStats updateTime];
                        trailingSignal = [lastUpdateStats signal] ;
                        currentSignalEntryTime = [lastUpdateStats startTime];
                        currentSignalEntryPrice = [lastUpdateStats entryPrice];
                        currentSignalExitPrice = 0;
                        currentSignalSamplesInProfit = [lastUpdateStats samplesInProfit];
                        currentSignalTotalSamples = [lastUpdateStats totalSamples];
                        currentSignalMaxPrice = [lastUpdateStats maxPrice];
                        currentSignalMinPrice = [lastUpdateStats minPrice];
                        newSignal = NO;
                        [statistics removeObject:lastUpdateStats];
                    }
                }
                for(int i = oldDataLength - dataOverlapIndex ; i < dataLength; i++){
                    fastArray[i] = (fastParameter*midArray[i]) + ((1-fastParameter) * fastArray[i-1]);
                    slowArray[i] = (slowParameter*midArray[i]) + ((1-slowParameter) * slowArray[i-1]);
                    signalArray[i] = fastArray[i] - slowArray[i];
                    
                    if(dateTimeArray[i] >= lastStatUpdateTime){
                        currentSignal = 0;
                        if(signalArray[i] > 0){
                            currentSignal = 1;
                        }
                        if(signalArray[i] < 0){
                            currentSignal = -1;
                        }
                    
                        if(currentSignalTotalSamples > 0 && ((currentSignal != trailingSignal)|| i == dataLength -1)){
                        
                            if(trailingSignal >0){
                                if(bidArray[i] > currentSignalEntryPrice){
                                    currentSignalSamplesInProfit++;
                                }
                                currentSignalMinPrice = fmin(currentSignalMinPrice, bidArray[i]);
                                currentSignalMaxPrice = fmax(currentSignalMaxPrice, bidArray[i]);
                            }else{
                                if(askArray[i] < currentSignalEntryPrice){
                                    currentSignalSamplesInProfit++;
                                }
                                currentSignalMinPrice = fmin(currentSignalMinPrice, askArray[i]);
                                currentSignalMaxPrice = fmax(currentSignalMaxPrice, askArray[i]);
                            }
                            currentSignalTotalSamples++;
                        
                            if(currentSignal == trailingSignal){
                                if(trailingSignal > 0){
                                    currentSignalExitPrice = bidArray[i];
                                }else{
                                    currentSignalExitPrice = askArray[i];
                                }
                                signalStats = [[SignalStats alloc] initWithSignal: (double) currentSignal
                                                                     AndStartTime: currentSignalEntryTime
                                                                    AndUpdateTime: dateTimeArray[i]
                                                                    AndEntryPrice: currentSignalEntryPrice
                                                                   AndLatestPrice: currentSignalExitPrice
                                                               AndSamplesInProfit: currentSignalSamplesInProfit
                                                                  AndTotalSamples: currentSignalTotalSamples
                                                                      AndMaxPrice: currentSignalMaxPrice
                                                                      AndMinPrice: currentSignalMinPrice];
                                currentSignalExitPrice = 0.0;
                            }else{
                                if(trailingSignal > 0){
                                    currentSignalExitPrice = bidArray[i];
                                }else{
                                    currentSignalExitPrice = askArray[i];
                                }
                                signalStats = [[SignalStats alloc]initWithSignal: (double) trailingSignal
                                                                    AndStartTime: currentSignalEntryTime
                                                                      AndEndTime: dateTimeArray[i]
                                                                   AndEntryPrice: currentSignalEntryPrice
                                                                    AndExitPrice: currentSignalExitPrice
                                                              AndSamplesInProfit: currentSignalSamplesInProfit
                                                                 AndTotalSamples: currentSignalTotalSamples
                                                                     AndMaxPrice: currentSignalMaxPrice
                                                                     AndMinPrice: currentSignalMinPrice];
                            }
                            if(doStats){
                                [statistics addObject:signalStats];
                            }
                            newSignal = YES;
                        }
                    
                        if(newSignal){
                            trailingSignal = 0;
                            if(signalArray[i] > 0){
                                trailingSignal = 1;
                            }
                            if(signalArray[i] < 0){
                                trailingSignal = -1;
                            }
                            currentSignalExitPrice = 0.0;
                        
                            currentSignalEntryTime = dateTimeArray[i];
                            if(trailingSignal >0){
                                currentSignalEntryPrice = askArray[i];
                                currentSignalMinPrice = bidArray[i];
                                currentSignalMaxPrice = bidArray[i];
                            }else{
                                currentSignalMinPrice = askArray[i];
                                currentSignalMaxPrice = askArray[i];
                            }
                            currentSignalSamplesInProfit = 0;
                            currentSignalTotalSamples = 1;
                            newSignal = NO;
                        }else{
                            if(trailingSignal >0){
                                if(bidArray[i] > currentSignalEntryPrice){
                                    currentSignalSamplesInProfit++;
                                }
                                currentSignalMinPrice = fmin(currentSignalMinPrice, bidArray[i]);
                                currentSignalMaxPrice = fmax(currentSignalMaxPrice, bidArray[i]);
                            }else{
                                if(askArray[i] < currentSignalEntryPrice){
                                    currentSignalSamplesInProfit++;
                                }
                                currentSignalMinPrice = fmin(currentSignalMinPrice, askArray[i]);
                                currentSignalMaxPrice = fmax(currentSignalMaxPrice, askArray[i]);
                            }
                            currentSignalTotalSamples++;
                        }
                    }
                    trailingSignal = currentSignal;
                    levelArray[i] = currentSignalEntryPrice;
                }
            }
        }else{
            // All new data means start a new set of statistics;
            fastArray[0] = midArray[0];
            slowArray[0] = midArray[0];
            signalArray[0] = 0;
            levelArray[0] = midArray[0];
            trailingSignal = 0;
            newSignal = YES;
            for(int i = 1; i < dataLength; i++){
                fastArray[i] = (fastParameter*midArray[i]) + ((1-fastParameter) * fastArray[i-1]);
                slowArray[i] = (slowParameter*midArray[i]) + ((1-slowParameter) * slowArray[i-1]);
                signalArray[i] = fastArray[i] - slowArray[i];
                
                currentSignal = 0;
                if(signalArray[i] > 0){
                    currentSignal = 1;
                }
                if(signalArray[i] < 0){
                    currentSignal = -1;
                }
                
                if(currentSignalTotalSamples > 0 && ((currentSignal != trailingSignal)|| i == dataLength -1)){
                    if(trailingSignal >0){
                        if(bidArray[i] > currentSignalEntryPrice){
                            currentSignalSamplesInProfit++;
                        }
                        currentSignalMinPrice = fmin(currentSignalMinPrice, bidArray[i]);
                        currentSignalMaxPrice = fmax(currentSignalMaxPrice, bidArray[i]);
                    }else{
                        if(askArray[i] < currentSignalEntryPrice){
                            currentSignalSamplesInProfit++;
                        }
                        currentSignalMinPrice = fmin(currentSignalMinPrice, askArray[i]);
                        currentSignalMaxPrice = fmax(currentSignalMaxPrice, askArray[i]);
                    }
                    currentSignalTotalSamples++;
                    
                    //If this is true then we are ending the stats because we are at the end of data 
                    if(currentSignal == trailingSignal){
                        if(trailingSignal > 0){
                            currentSignalExitPrice = bidArray[i];
                        }else{
                            currentSignalExitPrice = askArray[i];
                        }

                        signalStats = [[SignalStats alloc] initWithSignal: (double) currentSignal
                                                             AndStartTime: currentSignalEntryTime
                                                            AndUpdateTime: dateTimeArray[i]
                                                            AndEntryPrice: currentSignalEntryPrice
                                                           AndLatestPrice: currentSignalExitPrice
                                                       AndSamplesInProfit: currentSignalSamplesInProfit
                                                          AndTotalSamples: currentSignalTotalSamples
                                                              AndMaxPrice: currentSignalMaxPrice
                                                              AndMinPrice: currentSignalMinPrice];
                        currentSignalExitPrice = 0.0;
                    }else{
                        if(trailingSignal > 0){
                            currentSignalExitPrice = bidArray[i];
                        }else{
                            currentSignalExitPrice = askArray[i];
                        }
                        
                        signalStats = [[SignalStats alloc]initWithSignal: (double) trailingSignal
                                                            AndStartTime: currentSignalEntryTime
                                                              AndEndTime: dateTimeArray[i]
                                                           AndEntryPrice: currentSignalEntryPrice
                                                            AndExitPrice: currentSignalExitPrice
                                                      AndSamplesInProfit: currentSignalSamplesInProfit
                                                         AndTotalSamples: currentSignalTotalSamples
                                                             AndMaxPrice: currentSignalMaxPrice
                                                             AndMinPrice: currentSignalMinPrice];
                    }
                    if(doStats){
                        [statistics addObject:signalStats];
                    }
                    newSignal = YES;
                }
            
                if(newSignal){
                    trailingSignal = 0;
                    if(signalArray[i] > 0){
                        trailingSignal = 1;
                    }
                    if(signalArray[i] < 0){
                        trailingSignal = -1;
                    }
                    
                    currentSignalExitPrice = 0.0;
                
                    currentSignalEntryTime = dateTimeArray[i];
                    if(trailingSignal >0){
                        currentSignalEntryPrice = askArray[i];
                        currentSignalMinPrice = bidArray[i];
                        currentSignalMaxPrice = bidArray[i];
                    }else{
                        currentSignalEntryPrice = bidArray[i];
                        currentSignalMinPrice = askArray[i];
                        currentSignalMaxPrice = askArray[i];
                    }
                    currentSignalSamplesInProfit = 0;
                    currentSignalTotalSamples = 1;
                    newSignal = NO;
                }else{
                    if(trailingSignal >0){
                        if(bidArray[i] > currentSignalEntryPrice){
                            currentSignalSamplesInProfit++;
                        }
                        currentSignalMinPrice = fmin(currentSignalMinPrice, bidArray[i]);
                        currentSignalMaxPrice = fmax(currentSignalMaxPrice, bidArray[i]);
                    }else{
                        if(askArray[i] < currentSignalEntryPrice){
                            currentSignalSamplesInProfit++;
                        }
                        currentSignalMinPrice = fmin(currentSignalMinPrice, askArray[i]);
                        currentSignalMaxPrice = fmax(currentSignalMaxPrice, askArray[i]);
                    }
                    currentSignalTotalSamples++;
                }
                levelArray[i] = currentSignalEntryPrice;
                trailingSignal = currentSignal;
            }
        }
    }
    if(success){
        [returnData setObject:fastData forKey:fastName];
        [returnData setObject:slowData forKey:slowName];
        [returnData setObject:levelData forKey:@"KEYPRICE"];
        [returnData setObject:signalData forKey:@"SIGNAL"];
        [returnData setObject:[NSNumber numberWithBool:YES] forKey:@"SUCCESS"];
    }
    return returnData;
}





@end




