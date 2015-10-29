//
//  DataProcessor.m
//  Simple Sim
//
//  Created by Martin O'Connor on 26/04/2012.
//  Copyright (c) 2015 MARTIN OCONNOR. All rights reserved.
//

#import "DataProcessor.h"
#import "UtilityFunctions.h"
#import "PositioningSystem.h"
#import "SignalSystem.h"
#import "EpochTime.h"
#import "math.h"

@interface DataProcessor()
+ (NSDictionary *) calcEMAForCode: (NSString *) seriesCode
                         WithData: (NSDictionary *) dataDictionary
                       AndOldData: (NSDictionary *) oldDataDictionary;

+ (NSDictionary *) calcREMAForCode: (NSString *) remaCode
                          WithData: (NSDictionary *) dataDictionary
                        AndOldData: (NSDictionary *) oldDataDictionary;

+ (NSDictionary *) calcSpreadWithData: (NSDictionary *) dataDictionary
                           AndOldData: (NSDictionary *) oldDataDictionary;

+ (NSDictionary *) calcATRForCode: (NSString *) seriesCode
                         WithData: (NSDictionary *) dataDictionary
                       AndOldData: (NSDictionary *) oldDataDictionary;

+ (NSDictionary *) calcOHLCWithData: (NSDictionary *) dataDictionary
                         AndOldData: (NSDictionary *) oldDataDictionary;

+ (NSDictionary *) calcTR2ForCode: (NSString *) seriesCode
                     WithOHLCData: (NSDictionary *) dataDictionary
                       AndOldData: (NSDictionary *) oldDataDictionary
                   AndTicDateTime: (NSData *) dateTime;

+ (NSDictionary *) calcFDIMWithOHLCData: (NSDictionary *) ohlcDataDictionary
                             AndTicData: (NSDictionary *) dataDictionary
                          AndOldTicData: (NSDictionary *) oldDataDictionary;

+ (NSDictionary *) calcMacdForCode: (NSString *) macdCode
                          WithData: (NSDictionary *) emaData
                        AndOldData: (NSDictionary *) oldDataDictionary
                        AndMidData: (NSData * ) midData;

+ (NSDictionary *) calcEmadForCode: (NSString *) macdCode
                          WithData: (NSDictionary *) dataDictionary
                        AndOldData: (NSDictionary *) oldDataDictionary
                       AndDoPickup: (BOOL) doPerf
                     WithThreshold: (double) threshold;

+ (NSDictionary *) calcTicNumberWithData: (NSDictionary *) dataDictionary
                              AndOldData: (NSDictionary *) oldDataDictionary;

+ (NSDictionary *) calcGridStatsWithDerivedData: (NSDictionary *) dataDictionary
                              AndOldDerivedData: (NSDictionary *) oldDataDictionary
                                   AndPriceData: (NSDictionary *) priceDataDictionary
                                        ForCode: (NSString *) gridStatsCode
                                AndSignalSystem: (SignalSystem *) signalSystem;

+ (NSDictionary *) calcAemadForCode: (NSString *) aemadCode
                           WithData: (NSDictionary *) emadData
                         AndOldData: (NSDictionary *) oldDataDictionary
                         AndPipSize: (double) pipSize;

+ (NSDictionary *) calcPACSForCode: (NSString *) pacsCode
                   WithDerivedData: (NSDictionary *) dataDictionary
                 AndOldDerivedData: (NSDictionary *) oldDataDictionary
                        AndPipSize: (double) pipSize
                   AndSignalSystem: (SignalSystem *) signalSystem;



@end


@implementation DataProcessor


+(NSDictionary *) addToDataSeries: (NSDictionary *) dataDictionary
                 DerivedVariables: (NSArray *) derivedVariables
                 WithTrailingData: (NSDictionary *)trailingData
                  AndSignalSystem: (SignalSystem *) signalSystem
{
    BOOL success = YES, useAllNewData;
    NSMutableDictionary *returnData = [[NSMutableDictionary alloc] init];
    long dataLength;
    NSData *dateTimeData, *oldDateTimeData;
    long *dateTimeArray;
    BOOL doSignal= NO;
    NSDictionary *oldDataDictionary;
    double pipSize = 0.0;
    
    //If needed
    NSDictionary *hlocDataSeries;
    NSMutableData *expansionIndexData;
    NSData *dayNumberData, *dataCountData;
    long *dataCountArray, *dayNumberArray, dayArrayLength, *expansionIndexArray;
    
    BOOL highLowCloseNeeded = NO, highLowCloseCalced = NO;
    for(int i = 0; i < [derivedVariables count]; i ++){
        NSArray *variableComponents = [[derivedVariables objectAtIndex:i] componentsSeparatedByString:@"/"];
        if([[variableComponents objectAtIndex:0]  isEqualToString:@"TR2"] ||
           [[variableComponents objectAtIndex:0]  isEqualToString:@"OHLC"] ||
           [[variableComponents objectAtIndex:0]  isEqualToString:@"FDIM"]){
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
        pipSize = [[dataDictionary objectForKey:@"PIPSIZE"] doubleValue];
        
        long *oldDataTimeArray;
        long oldDataLength;
        long dataOverlapIndex;
        
        NSMutableArray *orderedDerivedVariables = [[NSMutableArray alloc] init];
        
        for(int i = 0; i < [derivedVariables count];i++){
            if([[[derivedVariables objectAtIndex:i] substringToIndex:4] isEqualToString:@"EMA/"]){
                [orderedDerivedVariables addObject:[derivedVariables objectAtIndex:i]];
            }
        }
        for(int i = 0; i < [derivedVariables count];i++){
            if([[[derivedVariables objectAtIndex:i] substringToIndex:5] isEqualToString:@"EMAD/"]){
                [orderedDerivedVariables addObject:[derivedVariables objectAtIndex:i]];
            }
        }
        for(int i = 0; i < [derivedVariables count];i++){
            if([[[derivedVariables objectAtIndex:i] substringToIndex:5] isEqualToString:@"EMAG/"]){
                [orderedDerivedVariables addObject:[derivedVariables objectAtIndex:i]];
            }
        }
        for(int i = 0; i < [derivedVariables count];i++){
            if([[[derivedVariables objectAtIndex:i] substringToIndex:6] isEqualToString:@"AEMAD/"]){
                [orderedDerivedVariables addObject:[derivedVariables objectAtIndex:i]];
            }
        }
        for(int i = 0; i < [derivedVariables count];i++){
            if([[[derivedVariables objectAtIndex:i] substringToIndex:5] isEqualToString:@"PACS/"]){
                [orderedDerivedVariables addObject:[derivedVariables objectAtIndex:i]];
            }
        }
        for(int i = 0; i < [derivedVariables count];i++){
            if([[[derivedVariables objectAtIndex:i] substringToIndex:4] isEqualToString:@"EMB/"]){
                [orderedDerivedVariables addObject:[derivedVariables objectAtIndex:i]];
            }
        }
        for(int i = 0; i < [derivedVariables count];i++){
            if([[[derivedVariables objectAtIndex:i] substringToIndex:5] isEqualToString:@"EMBD/"]){
                [orderedDerivedVariables addObject:[derivedVariables objectAtIndex:i]];
            }
        }
        for(int i = 0; i < [derivedVariables count];i++){
            if([[[derivedVariables objectAtIndex:i] substringToIndex:6] isEqualToString:@"AEMBD/"]){
                [orderedDerivedVariables addObject:[derivedVariables objectAtIndex:i]];
            }
        }

        
        for(int i = 0; i < [derivedVariables count];i++){
            if(!([[[derivedVariables objectAtIndex:i] substringToIndex:4] isEqualToString:@"EMA/"] ||
                 [[[derivedVariables objectAtIndex:i] substringToIndex:5] isEqualToString:@"EMAD/"] ||
                 [[[derivedVariables objectAtIndex:i] substringToIndex:5] isEqualToString:@"EMAG/"] ||
                 [[[derivedVariables objectAtIndex:i] substringToIndex:6] isEqualToString:@"AEMAD/"] ||
                 [[[derivedVariables objectAtIndex:i] substringToIndex:5] isEqualToString:@"PACS/"] ||
                 [[[derivedVariables objectAtIndex:i] substringToIndex:4] isEqualToString:@"EMB/"] ||
                 [[[derivedVariables objectAtIndex:i] substringToIndex:6] isEqualToString:@"EMBD/"] ||
                 [[[derivedVariables objectAtIndex:i] substringToIndex:6] isEqualToString:@"AEMBD/"] )){
                [orderedDerivedVariables addObject:[derivedVariables objectAtIndex:i]];
            }
        }
        
        NSString  *currentSeriesName, *currentSeriesType;
        int seriesIndex = 0;
        while(seriesIndex < [orderedDerivedVariables count] && success){
            currentSeriesName = [orderedDerivedVariables objectAtIndex:seriesIndex];
            NSArray *seriesComponents = [currentSeriesName componentsSeparatedByString:@"/"];
            currentSeriesType = [seriesComponents objectAtIndex:0];
            
            if(!useAllNewData){
                if([trailingData objectForKey:@"OLDDATA"] == nil ||
                   [trailingData objectForKey: @"OVERLAPINDEX"] == nil ||
                   [trailingData objectForKey:@"OLDDATETIME"] == nil){
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
                hlocDataSeries = [self calcOHLCWithData:dataDictionary
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
            //Variable: EMB
            if([currentSeriesType  isEqualToString:@"EMB"])
            {
                NSDictionary *embDataSeries = [self calcEMAForCode:currentSeriesName
                                                          WithData:returnData
                                                        AndOldData:trailingData];
                
                success = [[embDataSeries objectForKey:@"SUCCESS"] boolValue];
                
                if(success){
                    NSData *embData = [embDataSeries objectForKey:currentSeriesName];
                    [returnData setObject:embData forKey:currentSeriesName];
                }
            }
            
            

            //Variable: REMA
            if([currentSeriesType  isEqualToString:@"REMA"])
            {
                NSDictionary *remaDataSeries = [self calcREMAForCode:currentSeriesName
                                                           WithData:dataDictionary
                                                         AndOldData:trailingData];
                
                success = [[remaDataSeries objectForKey:@"SUCCESS"] boolValue];
                
                if(success){
                    NSData *remaData = [remaDataSeries objectForKey:currentSeriesName];
                    NSData *remarvar = [remaDataSeries objectForKey:[NSString stringWithFormat:@"%@rvar",currentSeriesName]];
                    [returnData setObject:remaData forKey:currentSeriesName];
                    [returnData setObject:remarvar forKey:[NSString stringWithFormat:@"%@rvar",currentSeriesName]];
                }
            }

            //Variable: BUT
            if([currentSeriesType  isEqualToString:@"BUT"] || [currentSeriesType  isEqualToString:@"BUT3"])
            {
                NSDictionary *butDataSeries = [self calcBUTForCode:currentSeriesName
                                                          WithData:dataDictionary
                                                        AndOldData:trailingData];
                
                success = [[butDataSeries objectForKey:@"SUCCESS"] boolValue];
                
                if(success){
                    NSData *butData = [butDataSeries objectForKey:currentSeriesName];
                    [returnData setObject:butData forKey:currentSeriesName];
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
                NSDictionary *tr2DataSeries = [self calcTR2ForCode:currentSeriesName
                                                      WithOHLCData:hlocDataSeries
                                                        AndOldData:trailingData
                                                    AndTicDateTime:dateTimeData];
                
                success = [[tr2DataSeries objectForKey:@"SUCCESS"] boolValue];
                
                if(success){
                    NSData *spreadData = [tr2DataSeries objectForKey:@"TR2"];
                    [returnData setObject:spreadData forKey:@"TR2"];
                }
            }
           
            if([currentSeriesType  isEqualToString:@"FDIM"])
            {
                NSDictionary *fdimDataSeries = [self calcFDIMWithOHLCData:hlocDataSeries
                                                              AndTicData: dataDictionary
                                                            AndOldTicData:trailingData];
                
                success = [[fdimDataSeries objectForKey:@"SUCCESS"] boolValue];
                
                if(success){
                    NSData *fdimData = [fdimDataSeries objectForKey:@"FDIM"];
                    [returnData setObject:fdimData forKey:@"FDIM"];
                    fdimData = [fdimDataSeries objectForKey:@"FDIM2"];
                    [returnData setObject:fdimData forKey:@"FDIM2"];
                }
            }
            
            // Variable: ATR
            if([currentSeriesType  isEqualToString:@"ATR"])
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
            // Variable: MACD
            if([currentSeriesType isEqualToString:@"MACD"])
            {
                NSData *midData = [dataDictionary objectForKey:@"MID"];
                NSDictionary *macdDataSeries = [self calcMacdForCode:currentSeriesName
                                                            WithData:returnData
                                                          AndOldData:trailingData
                                                          AndMidData:midData];
                
                success = [[macdDataSeries objectForKey:@"SUCCESS"] boolValue];
                if(success){
                    NSArray *dataKeys = [macdDataSeries allKeys];
                    for( int i = 0; i < [dataKeys count]; i++){
                        if([[dataKeys objectAtIndex:i] isNotEqualTo:@"SUCCESS"])
                        {
                            [returnData setObject:[macdDataSeries objectForKey:[dataKeys objectAtIndex:i]]
                                           forKey:[dataKeys objectAtIndex:i]];
                        }
                    }
                }
            }
            // Variable: EMAD
            if([currentSeriesType isEqualToString:@"EMAD"] || [currentSeriesType isEqualToString:@"EMBD"])
            {
                NSDictionary *emadDataSeries = [self calcEmadForCode:currentSeriesName
                                                            WithData:returnData
                                                          AndOldData:trailingData
                                                         AndDoPickup:NO
                                                       WithThreshold:0.0];
                
                success = [[emadDataSeries objectForKey:@"SUCCESS"] boolValue];
                if(success){
                    NSArray *dataKeys = [emadDataSeries allKeys];
                    for( int i = 0; i < [dataKeys count]; i++){
                        if([[dataKeys objectAtIndex:i] isNotEqualTo:@"SUCCESS"])
                        {
                            [returnData setObject:[emadDataSeries objectForKey:[dataKeys objectAtIndex:i]]
                                           forKey:[dataKeys objectAtIndex:i]];
                        }
                    }
                }
            }
            // Variable: AEMAD
            if([currentSeriesType isEqualToString:@"AEMAD"] || [currentSeriesType isEqualToString:@"AEMBD"])
            {
                NSDictionary *aemadDataSeries = [self calcAemadForCode:currentSeriesName
                                                              WithData:returnData
                                                            AndOldData:trailingData
                                                            AndPipSize:pipSize];
                
                success = [[aemadDataSeries objectForKey:@"SUCCESS"] boolValue];
                if(success){
                    NSArray *dataKeys = [aemadDataSeries allKeys];
                    for( int i = 0; i < [dataKeys count]; i++){
                        if([[dataKeys objectAtIndex:i] isNotEqualTo:@"SUCCESS"])
                        {
                            [returnData setObject:[aemadDataSeries objectForKey:[dataKeys objectAtIndex:i]]
                                           forKey:[dataKeys objectAtIndex:i]];
                        }
                    }
                }
            }
           
            // Variable: EMAG
            if([currentSeriesType isEqualToString:@"EMAG"])
            {
                NSDictionary *emagDataSeries = [self calcEmagForCode:currentSeriesName
                                                            WithData:returnData
                                                          AndOldData:trailingData];
                
                success = [[emagDataSeries objectForKey:@"SUCCESS"] boolValue];
                if(success){
                    NSArray *dataKeys = [emagDataSeries allKeys];
                    for( int i = 0; i < [dataKeys count]; i++){
                        if([[dataKeys objectAtIndex:i] isNotEqualTo:@"SUCCESS"])
                        {
                            [returnData setObject:[emagDataSeries objectForKey:[dataKeys objectAtIndex:i]]
                                           forKey:[dataKeys objectAtIndex:i]];
                        }
                    }
                }
            }
            
            // Variable: EDPU
            if([currentSeriesType isEqualToString:@"EDPU"])
            {
                [returnData setObject:[dataDictionary objectForKey:@"MID"] forKey:@"MID"];
                
                NSDictionary *edpuDataSeries = [self calcEmadForCode:currentSeriesName
                                                            WithData:returnData
                                                          AndOldData:trailingData
                                                         AndDoPickup:YES
                                                       WithThreshold:[signalSystem threshold]];
                [returnData removeObjectForKey:@"MID"];
                success = [[edpuDataSeries objectForKey:@"SUCCESS"] boolValue];
                if(success){
                    NSArray *dataKeys = [edpuDataSeries allKeys];
                    for( int i = 0; i < [dataKeys count]; i++){
                        if([[dataKeys objectAtIndex:i] isNotEqualTo:@"SUCCESS"])
                        {
                            [returnData setObject:[edpuDataSeries objectForKey:[dataKeys objectAtIndex:i]]
                                           forKey:[dataKeys objectAtIndex:i]];
                        }
                    }
                }
            }

            //Variable: TICN
            if([currentSeriesType  isEqualToString:@"TICN"])
            {
                NSDictionary *ticnDataSeries = [self calcTicNumberWithData:dataDictionary
                                                        AndOldData:trailingData];
                
                success = [[ticnDataSeries objectForKey:@"SUCCESS"] boolValue];
                
                if(success){
                    NSData *ticnData = [ticnDataSeries objectForKey:currentSeriesName];
                    [returnData setObject:ticnData forKey:currentSeriesName];
                }
            }

            //Variable: GRDPOS
            if([currentSeriesType  isEqualToString:@"GRDPOS"])
            {
                NSDictionary *gridDataSeries = [self calcGridStatsWithDerivedData:returnData 
                                                                AndOldDerivedData:trailingData
                                                                     AndPriceData:dataDictionary
                                                                          ForCode:currentSeriesName
                                                                  AndSignalSystem:signalSystem];
                
                success = [[gridDataSeries objectForKey:@"SUCCESS"] boolValue];
                
                if(success){
                    NSArray *dataKeys = [gridDataSeries allKeys];
                    for( int i = 0; i < [dataKeys count]; i++){
                        if([[dataKeys objectAtIndex:i] isNotEqualTo:@"SUCCESS"])
                        {
                            [returnData setObject:[gridDataSeries objectForKey:[dataKeys objectAtIndex:i]]
                                           forKey:[dataKeys objectAtIndex:i]];
                        }
                    }                }
            }
            
            //Variable: PACS
            if([currentSeriesType  isEqualToString:@"PACS"])
            {
                [returnData setObject:[dataDictionary objectForKey:@"MID"] forKey:@"MID"];
                [returnData setObject:[dataDictionary objectForKey:@"DATETIME"] forKey:@"DATETIME"];
                NSDictionary *pacsDataSeries = [self calcPACSForCode:currentSeriesName
                                                     WithDerivedData:returnData
                                                   AndOldDerivedData:trailingData
                                                          AndPipSize:pipSize
                                                     AndSignalSystem:signalSystem];
                [returnData removeObjectForKey:@"MID"];
                [returnData removeObjectForKey:@"DATETIME"];
                
                success = [[pacsDataSeries objectForKey:@"SUCCESS"] boolValue];
                
                if(success){
                    NSArray *dataKeys = [pacsDataSeries allKeys];
                    for( int i = 0; i < [dataKeys count]; i++){
                        if([[dataKeys objectAtIndex:i] isNotEqualTo:@"SUCCESS"])
                        {
                            [returnData setObject:[pacsDataSeries objectForKey:[dataKeys objectAtIndex:i]]
                                           forKey:[dataKeys objectAtIndex:i]];
                        }
                    }
                }
            }
            
            
            
            seriesIndex++;
        }
        
        // SIGNALS
        //Here is where we do make the signals, prerequisite variables should be already created
        if(success && doSignal){
            NSMutableData *signalData, *oldSignalData;
            double *signalArray, *oldSignalArray;
            
            if([[signalSystem type] isEqualToString:@"SECO"]){
                signalData = [[NSMutableData alloc] initWithLength:dataLength * sizeof(double)];
                signalArray = [signalData mutableBytes];

                double *fastArray, *slowArray;
                NSData *variableData;
                NSString *fastCode = [NSString stringWithFormat:@"EMA/%d",[signalSystem fastCode]];
                NSString *slowCode = [NSString stringWithFormat:@"EMA/%d",[signalSystem slowCode]];
                
                if([returnData objectForKey:fastCode]){
                    variableData =  [returnData objectForKey:fastCode];
                }else{
                    variableData =  [dataDictionary objectForKey:fastCode];
                }
                fastArray = (double *)[variableData bytes];
                
                if([returnData objectForKey:slowCode]){
                    variableData =  [returnData objectForKey:slowCode];
                }else{
                    variableData =  [dataDictionary objectForKey:slowCode];
                }
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
                NSString *macdSigString = [NSString stringWithFormat:@"S%@",[signalSystem signalString]];
                macdSigString = [[macdSigString componentsSeparatedByString:@";"] objectAtIndex:0];
                if([returnData objectForKey:macdSigString]){
                    signalData = [returnData objectForKey:macdSigString];
                }else{
                    signalData = [dataDictionary objectForKey:macdSigString];

                }
            }
            
            if([[signalSystem type] isEqualToString:@"EMAD"] || [[signalSystem type] isEqualToString:@"EMBD"]){
                NSString *emadSigString = [[[signalSystem signalString] componentsSeparatedByString:@";"] objectAtIndex:0];
                if([returnData objectForKey:emadSigString]){
                    signalData = [returnData objectForKey:emadSigString];
                }else{
                    signalData = [dataDictionary objectForKey:emadSigString];
                }
            }
            
            if([[signalSystem type] isEqualToString:@"AEMAD"]){
                NSString *aemadSigString = [[[signalSystem signalString] componentsSeparatedByString:@";"] objectAtIndex:0];
                if([returnData objectForKey:aemadSigString]){
                    signalData = [returnData objectForKey:aemadSigString];
                }else{
                    signalData = [dataDictionary objectForKey:aemadSigString];
                }
            }
           
            if([[signalSystem type] isEqualToString:@"AEMBD"]){
                NSString *aembdSigString = [[[signalSystem signalString] componentsSeparatedByString:@";"] objectAtIndex:0];
                if([returnData objectForKey:aembdSigString]){
                    signalData = [returnData objectForKey:aembdSigString];
                }else{
                    signalData = [dataDictionary objectForKey:aembdSigString];
                }
            }
            
            if([[signalSystem type] isEqualToString:@"MCD2"]){
                signalData = [[NSMutableData alloc] initWithLength:dataLength * sizeof(double)];
                signalArray = [signalData mutableBytes];
                NSString *macdSigString = [NSString stringWithFormat:@"SMACD/%@",[[signalSystem signalString] substringFromIndex:5]];
                macdSigString = [[macdSigString componentsSeparatedByString:@";"] objectAtIndex:0];
                
                NSString *macdHistDeltaString = [NSString stringWithFormat:@"MACDHISTD%@",[macdSigString substringFromIndex:5]];
                NSData *macdSigData, *macdHistDeltaData;
                if([returnData objectForKey:macdSigString]){
                    macdSigData = [returnData objectForKey:macdSigString];
                }else{
                    macdSigData = [dataDictionary objectForKey:macdSigString];
                }
                double *macdSigArray = (double *)[macdSigData bytes];
                
                if([returnData objectForKey:macdHistDeltaString]){
                    macdHistDeltaData = [returnData objectForKey:macdHistDeltaString];
                }else{
                    macdHistDeltaData = [dataDictionary objectForKey:macdHistDeltaString];
                }
                double *macdHistDeltaArray = (double *)[macdHistDeltaData bytes];
                
                for(int i = 0; i < dataLength; i++){
                    if([UtilityFunctions signOfDouble:macdSigArray[i]] == [UtilityFunctions signOfDouble:macdHistDeltaArray[i]]){
                        signalArray[i] = macdSigArray[i];
                    }else{
                        signalArray[i] = 0.0;
                    }
                }
            }
            
            NSMutableData *signalthresholdDataL = [[NSMutableData alloc] initWithLength:dataLength * sizeof(double)];
            NSMutableData *signalthresholdDataU = [[NSMutableData alloc] initWithLength:dataLength * sizeof(double)];
            double *signalthresholdArrayL = (double *)[signalthresholdDataL mutableBytes];
            double *signalthresholdArrayU = (double *)[signalthresholdDataU mutableBytes];
            //signalArray = (double *)[signalData mutableBytes];
            for(int i = 0; i < dataLength; i++){
                signalthresholdArrayL[i] = -[signalSystem threshold];
                signalthresholdArrayU[i] = [signalSystem threshold];
            }
            [returnData setObject:signalthresholdDataL forKey:@"SIGLTHRES"];
            [returnData setObject:signalthresholdDataU forKey:@"SIGUTHRES"];
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
    NSString *baseSeriesString;
    
    double *emaArray, parameter;
    NSArray *codeComponents = [emaCode componentsSeparatedByString:@"/"];
    int emaCodeParam;
    
    if([[codeComponents objectAtIndex:0] isEqualToString:@"EMA"]){
        baseSeriesString = @"MID";
        emaCodeParam = [[codeComponents objectAtIndex:1] intValue];
        
    }
    if([[codeComponents objectAtIndex:0] isEqualToString:@"EMB"]){
        NSRange firstBracket = [emaCode rangeOfString:@"/"];
        NSString *subString = [emaCode substringFromIndex:firstBracket.location];
        NSRange lastBracket = [subString rangeOfString:@"/"
                                               options:NSBackwardsSearch];
        baseSeriesString = [NSString stringWithFormat:@"BMID%@",[subString substringToIndex:lastBracket.location]];
        emaCodeParam = [[codeComponents objectAtIndex:4] intValue];
    }
    
    BOOL includeOldData = NO, success = YES;
    includeOldData = ![[oldDataDictionary objectForKey:@"ALLNEWDATA"] boolValue];
     
    int dataOverlapIndex;
    NSDictionary *trailingSeriesDictionary;
    long oldDataLength, dataLength, *oldDataTimeArray, *dateTimeArray;
    
    NSData *midData,  *dateTimeData, *oldDateTimeData, *oldEmaData;
    double *midArray, *oldEmaArray;
    
    midData = [dataDictionary objectForKey:baseSeriesString];
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

+ (NSDictionary *) calcREMAForCode: (NSString *) remaCode
                          WithData: (NSDictionary *) dataDictionary
                        AndOldData: (NSDictionary *) oldDataDictionary
{
    double rho = 0.0;
    double sdelta = 0.0;
    const double k = 2;
    const double ck = 2.52;
    NSString *deviationString = [NSString stringWithFormat:@"%@rvar",remaCode];
    
    NSMutableDictionary *returnData = [[NSMutableDictionary alloc] init];
    NSMutableData *remaData, *deviationData;
    
    double *remaArray, *deviationArray, parameter;
    NSArray *codeComponents = [remaCode componentsSeparatedByString:@"/"];
    int remaCodeParam = [[codeComponents objectAtIndex:1] intValue];
    
    BOOL includeOldData = NO, success = YES;
    includeOldData = ![[oldDataDictionary objectForKey:@"ALLNEWDATA"] boolValue];
    
    int dataOverlapIndex;
    NSDictionary *trailingSeriesDictionary;
    long oldDataLength, dataLength, *oldDataTimeArray, *dateTimeArray;
    
    NSData *midData,  *dateTimeData, *oldDateTimeData, *oldRemaData, *oldDeviationData;
    double *midArray, *oldRemaArray, *oldDeviationArray;
    
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
        parameter = 2.0/(1.0+[UtilityFunctions fib:remaCodeParam]);
        remaData = [[NSMutableData alloc] initWithLength:dataLength * sizeof(double)];
        remaArray = [remaData mutableBytes];
        deviationData = [[NSMutableData alloc] initWithLength:dataLength * sizeof(double)];
        deviationArray = [deviationData mutableBytes];
        
        if(includeOldData){
            oldRemaData = [trailingSeriesDictionary objectForKey:remaCode];
            oldRemaArray = (double *)[oldRemaData bytes];
            oldDeviationData = [trailingSeriesDictionary objectForKey:deviationString];
            oldDeviationArray = (double *)[oldDeviationData bytes];
            for(long i = dataOverlapIndex ; i <= oldDataLength; i++){
                remaArray[i-dataOverlapIndex] = oldRemaArray[i];
                deviationArray[i-dataOverlapIndex] = oldDeviationArray[i];
            }
            for(long i = oldDataLength - dataOverlapIndex; i < dataLength; i++){
                remaArray[i] = (parameter*midArray[i]) + ((1-parameter) * remaArray[i-1]);
                sdelta = (remaArray[i] - remaArray[i-1])/deviationArray[i-1];
                if(fabs(sdelta) < k){
                    rho = ck * (1- pow(1- pow(sdelta/k,2.0),3));
                }else{
                    rho = ck;
                }
                deviationArray[i] = (parameter * rho *deviationArray[i-1]*deviationArray[i-1]) + (1- parameter)*deviationArray[i-1];
            }
        }else{
            remaArray[0] = midArray[0];
            deviationArray[0] =0;
            for(int i = 1; i < dataLength; i++){
                remaArray[i] = (parameter*midArray[i]) + ((1-parameter) * remaArray[i-1]);
                sdelta = (remaArray[i] - remaArray[i-1])/deviationArray[i-1];
                if(fabs(sdelta) < k){
                    rho = ck * (1- pow(1- pow(sdelta/k,2.0),3));
                }else{
                    rho = ck;
                }
                deviationArray[i] = (parameter * rho *deviationArray[i-1]*deviationArray[i-1]) + (1- parameter)*deviationArray[i-1];
            }
            
        }
        [returnData setObject:remaData forKey:remaCode];
        [returnData setObject:deviationData forKey:deviationString];
    }
    
    if(success){
        [returnData setObject:[NSNumber numberWithBool:YES] forKey:@"SUCCESS"];
    }else{
        [returnData setObject:[NSNumber numberWithBool:NO] forKey:@"SUCCESS"];
        
    }
    
    return returnData;
}




+ (NSDictionary *) calcMacdForCode: (NSString *) macdCode
                         WithData: (NSDictionary *) emaData
                        AndOldData: (NSDictionary *) oldDataDictionary
                        AndMidData: (NSData * ) midData
{
    double *fastArray, *slowArray;
    long dataLength;
    
    NSMutableDictionary *returnData = [[NSMutableDictionary alloc] init];
    
    NSArray *macdComponents = [macdCode componentsSeparatedByString:@"/"];
    int fastCode = [[macdComponents objectAtIndex:1] intValue];
    int slowCode = [[macdComponents objectAtIndex:2] intValue];
    int smoothCode = [[macdComponents objectAtIndex:3] intValue];
    
    
    NSString *fastString = [NSString stringWithFormat:@"EMA/%d",fastCode];
    NSString *slowString = [NSString stringWithFormat:@"EMA/%d",slowCode];
    NSString *macdString = [NSString stringWithFormat:@"MACD/%d/%d",fastCode,slowCode];
    NSString *macdHistString = [NSString stringWithFormat:@"MACDHIST/%d/%d/%d",fastCode,slowCode,smoothCode];
    NSString *macdHistDeltaString = [NSString stringWithFormat:@"MACDHISTD/%d/%d/%d",fastCode,slowCode,smoothCode];
    NSString *macdSigString = [NSString stringWithFormat:@"SMACD/%d/%d/%d",fastCode,slowCode,smoothCode];
    //NSString *macdAccString = [NSString stringWithFormat:@"ACCMACD/%d/%d/%d",fastCode,slowCode,smoothCode];
    NSData *fastData, *slowData;
    
    NSArray *dataKeys = [emaData allKeys];
    
    BOOL foundFast = NO, foundSlow = NO;
    for(int i = 0; i < [dataKeys count]; i++){
        if([[dataKeys objectAtIndex:i] isEqualToString:fastString]){
            foundFast = YES;
            fastData = [emaData objectForKey:fastString];
            fastArray = (double *)[fastData bytes];
            dataLength = [fastData length]/sizeof(double);
        }
        if([[dataKeys objectAtIndex:i] isEqualToString:slowString]){
            foundSlow = YES;
            slowData = [emaData objectForKey:slowString];
            slowArray = (double *)[slowData bytes];
        }
    }
    
    if(foundFast && foundSlow){
        BOOL includeOldData = NO;
        includeOldData = ![[oldDataDictionary objectForKey:@"ALLNEWDATA"] boolValue];
        
        
        NSMutableData *macdData = [[NSMutableData alloc] initWithLength:dataLength * sizeof(double)];
        double *macdArray = (double *)[macdData mutableBytes];
        
        NSMutableData *macdHistData = [[NSMutableData alloc] initWithLength:dataLength * sizeof(double)];
        double *macdHistArray = (double *)[macdHistData mutableBytes];
        
        NSMutableData *macdHistDeltaData = [[NSMutableData alloc] initWithLength:dataLength * sizeof(double)];
        double *macdHistDeltaArray = (double *)[macdHistDeltaData mutableBytes];
        
        NSMutableData *macdSigData = [[NSMutableData alloc] initWithLength:dataLength * sizeof(double)];
        double *macdSigArray = (double *)[macdSigData mutableBytes];
        
        double parameter = 2.0/(1.0+[UtilityFunctions fib:smoothCode]);
        
        long lagLengthForHistDelta = [UtilityFunctions fib:(slowCode - fastCode)];
        
        if(includeOldData){
            int dataOverlapIndex;
            NSDictionary *trailingSeriesDictionary;
            long oldDataLength;
            
            trailingSeriesDictionary = [oldDataDictionary objectForKey:@"OLDDATA"];
            dataOverlapIndex = [[oldDataDictionary objectForKey:@"OVERLAPINDEX"] intValue];
            
            NSData *oldMacdData = [trailingSeriesDictionary objectForKey:macdString];
            double *oldMacdArray = (double *)[oldMacdData bytes];
            NSData *oldMacdSigData = [trailingSeriesDictionary objectForKey:macdSigString];
            double *oldMacdSigArray = (double *)[oldMacdSigData bytes];
            NSData *oldMacdHistData = [trailingSeriesDictionary objectForKey:macdHistString];
            double *oldMacdHistArray = (double *)[oldMacdHistData bytes];
            NSData *oldMacdHistDeltaData = [trailingSeriesDictionary objectForKey:macdHistDeltaString];
            double *oldMacdHistDeltaArray = (double *)[oldMacdHistDeltaData bytes];
            
            
            long lagIndexForOldData = -1;
            
            oldDataLength = [oldMacdData length]/sizeof(long);
            
            for(long i = dataOverlapIndex ; i < oldDataLength; i++){
                macdArray[i-dataOverlapIndex] = oldMacdArray[i];
                macdSigArray[i-dataOverlapIndex] = oldMacdSigArray[i];
                macdHistArray[i-dataOverlapIndex] = oldMacdHistArray[i];
                macdHistDeltaArray[i-dataOverlapIndex] = oldMacdHistDeltaArray[i];
                if(i - lagLengthForHistDelta > 0){
                    lagIndexForOldData = i - lagLengthForHistDelta;
                }
            }
            for(long i = oldDataLength - dataOverlapIndex; i < dataLength; i++){
                macdArray[i] = fastArray[i] - slowArray[i];
                macdSigArray[i] = (parameter*macdArray[i]) + ((1-parameter) * macdSigArray[i-1]);
                macdHistArray[i] = macdArray[i] - macdSigArray[i];
                
                if(i - lagLengthForHistDelta >= 0){
                    macdHistDeltaArray[i] = macdHistArray[i] - macdHistArray[i- lagLengthForHistDelta];
                }else{
                    if(lagIndexForOldData > -1 && lagIndexForOldData < oldDataLength){
                        macdHistDeltaArray[i] = macdHistArray[i] - oldMacdHistArray[lagIndexForOldData];
                        lagIndexForOldData++;
                    }
                }
            }
        }else{
            for(int i = 0; i < dataLength; i++){
                macdArray[i] = fastArray[i] - slowArray[i];
                if(i > 0){
                    macdSigArray[i] = (parameter*macdArray[i]) + ((1-parameter) * macdSigArray[i-1]);
                }else{
                    macdSigArray[i] = macdArray[i];
                }
                macdHistArray[i] = macdArray[i] - macdSigArray[i];
                if(i - lagLengthForHistDelta >= 0){
                    macdHistDeltaArray[i] = macdHistArray[i] - macdHistArray[i- lagLengthForHistDelta];
                }
            }
        }
        [returnData setObject:macdData
                       forKey:macdString];
        [returnData setObject:macdSigData
                       forKey:macdSigString];
        [returnData setObject:macdHistData
                       forKey:macdHistString];
        [returnData setObject:macdHistDeltaData
                       forKey:macdHistDeltaString];
        [returnData setObject:[NSNumber numberWithBool:YES]
                       forKey:@"SUCCESS"];
    }else{
        [returnData setObject:[NSNumber numberWithBool:NO]
                       forKey:@"SUCCESS"];
    }
    return returnData;
}

+ (NSDictionary *) calcEmadForCode: (NSString *) emadString
                          WithData: (NSDictionary *) dataDictionary
                        AndOldData: (NSDictionary *) oldDataDictionary
                       AndDoPickup: (BOOL) doPickup
                     WithThreshold: (double) threshold
{
    NSData *emaData;
    double *emaArray;
    long dataLength;
    
    NSMutableDictionary *returnData = [[NSMutableDictionary alloc] init];
    
    NSArray *emadComponents = [emadString componentsSeparatedByString:@"/"];
     NSMutableData *emadPickupData, *midData;
    double *emadPickupArray, *midArray;
    
    NSString *emaString, *emadPickupString;
    int emaCode, emadCode;
    if([[emadComponents objectAtIndex:0] isEqualToString:@"EMAD"]){
        emaCode = [[emadComponents objectAtIndex:1] intValue];
        emadCode = [[emadComponents objectAtIndex:2] intValue];
        
        emaString = [NSString stringWithFormat:@"EMA/%d",emaCode];
        //emadString = [NSString stringWithFormat:@"EMAD/%d/%d",emaCode,smoothCode];
        if(doPickup){
            emadPickupString = [NSString stringWithFormat:@"EDPU/%d/%d",emaCode,emadCode];
        }
        
    }
    if([[emadComponents objectAtIndex:0] isEqualToString:@"EMBD"]){
        NSRange firstBracket = [emadString rangeOfString:@"/"];
        NSString *pacsString = [emadString substringFromIndex:firstBracket.location+1];
        NSRange lastBracket = [pacsString rangeOfString:@"/"
                                                options:NSBackwardsSearch];
        emadCode = [[pacsString substringFromIndex:lastBracket.location+1] intValue];
        pacsString = [pacsString substringToIndex:lastBracket.location];
        lastBracket = [pacsString rangeOfString:@"/"
                                        options:NSBackwardsSearch];
        int emaCode = [[pacsString substringFromIndex:(lastBracket.location+1)] intValue];
        lastBracket = [pacsString rangeOfString:@"/"
                                        options:NSBackwardsSearch];
        pacsString = [pacsString substringToIndex:lastBracket.location];
        emaString = [NSString stringWithFormat:@"EMB/%@/%d",pacsString, emaCode];
        if(doPickup){
            emadPickupString = [NSString stringWithFormat:@"EBDPU/%d/%d",emaCode,emadCode];
        }
    }
    
    BOOL requiredDataFound = NO;
    if([dataDictionary objectForKey:emaString] != nil){
        requiredDataFound = YES;
        emaData = [dataDictionary objectForKey:emaString];
        emaArray = (double *)[emaData bytes];
        dataLength = [emaData length]/sizeof(double);
    }
    if(requiredDataFound){
        if(doPickup){
            if([dataDictionary objectForKey:@"MID"] != nil){
                requiredDataFound = YES;
                midData = [dataDictionary objectForKey:@"MID"];
                midArray = (double *)[midData bytes];
            }else{
                requiredDataFound = NO;
            }
        }
    }
    
    if(requiredDataFound){
        BOOL includeOldData = NO;
        includeOldData = ![[oldDataDictionary objectForKey:@"ALLNEWDATA"] boolValue];
        
        NSMutableData *emadData = [[NSMutableData alloc] initWithLength:dataLength * sizeof(double)];
        double *emadArray = (double *)[emadData mutableBytes];
        
         
        if(doPickup){
            emadPickupData = [[NSMutableData alloc] initWithLength:dataLength * sizeof(double)];
            emadPickupArray = (double *)[emadPickupData mutableBytes];
        }
        
        long lagLengthForDelta = [UtilityFunctions fib:(emadCode)];
        
        if(includeOldData){
            int dataOverlapIndex;
            NSDictionary *trailingSeriesDictionary;
            long oldDataLength;
            
            trailingSeriesDictionary = [oldDataDictionary objectForKey:@"OLDDATA"];
            dataOverlapIndex = [[oldDataDictionary objectForKey:@"OVERLAPINDEX"] intValue];
            
            NSData *oldEmaData = [trailingSeriesDictionary objectForKey:emaString];
            double *oldEmaArray = (double *)[oldEmaData bytes];
            NSData *oldEmadData = [trailingSeriesDictionary objectForKey:emadString];
            double *oldEmadArray = (double *)[oldEmadData bytes];
            
            
            NSData *oldEmadPickupData;
            double *oldEmadPickupArray;
            if(doPickup){
                oldEmadPickupData = [trailingSeriesDictionary objectForKey:emadPickupString];
                oldEmadPickupArray = (double *)[oldEmadPickupData bytes];
            }
            
            long lagIndexForOldData = -1;
            
            oldDataLength = [oldEmadData length]/sizeof(long);
            
            for(long i = dataOverlapIndex ; i < oldDataLength; i++){
                emadArray[i-dataOverlapIndex] = oldEmadArray[i];
                if(doPickup){
                    emadPickupArray[i-dataOverlapIndex] = oldEmadPickupArray[i];
                }
            }
            
            lagIndexForOldData = oldDataLength - lagLengthForDelta;
            
            for(long i = oldDataLength - dataOverlapIndex; i < dataLength; i++){
                if(i - lagLengthForDelta >= 0){
                    emadArray[i] = emaArray[i] - emaArray[i- lagLengthForDelta];
                }else{
                    if(lagIndexForOldData > -1 && lagIndexForOldData < oldDataLength){
                        emadArray[i] = emaArray[i] - oldEmaArray[lagIndexForOldData];
                    }else{
                        emadArray[i] = 0.0;
                    }
                    lagIndexForOldData++;
                }
                if(doPickup){
                    //ignore hte case when i == 0, it should be taken care of by calulation overlap and doesn't matter much anyway for tick data
                    if(i > 0){
                        if((emadArray[i-1] >= threshold) ){
                            emadPickupArray[i] = emadPickupArray[i-1] + midArray[i] - midArray[i-1] ;
                        }else if (emadArray[i-1] <= -threshold)
                        {
                            emadPickupArray[i] = emadPickupArray[i-1]  + midArray[i-1] - midArray[i];
                        }else{
                            emadPickupArray[i] = emadPickupArray[i-1];
                        }
                    }
                }
            }
        }else{
            for(int i = 0; i < dataLength; i++){
                if(i - lagLengthForDelta >= 0){
                    emadArray[i] = emaArray[i] - emaArray[i- lagLengthForDelta];
                    if(doPickup){
                        if(i > 0){
                            if((emadArray[i-1] >= threshold) ){
                                emadPickupArray[i] = emadPickupArray[i-1] + midArray[i] - midArray[i-1] ;
                            }else if (emadArray[i-1] <= -threshold)
                            {
                                emadPickupArray[i] = emadPickupArray[i-1]  + midArray[i-1] - midArray[i];
                            }else{
                                emadPickupArray[i] = emadPickupArray[i-1];
                            }
                        }
                    }
                }
            }
        }
        [returnData setObject:emadData
                       forKey:emadString];
        if(doPickup){
            [returnData setObject:emadPickupData
                           forKey:emadPickupString];
        }
        [returnData setObject:[NSNumber numberWithBool:YES]
                       forKey:@"SUCCESS"];
    }else{
        [returnData setObject:[NSNumber numberWithBool:NO]
                       forKey:@"SUCCESS"];
    }
return returnData;
}

+ (NSDictionary *) calcEmagForCode: (NSString *) emagCode
                          WithData: (NSDictionary *) dataDictionary
                        AndOldData: (NSDictionary *) oldDataDictionary
{
    NSData *emadData;
    double *emadArray;
    long dataLength = 0;
    
    NSMutableDictionary *returnData = [[NSMutableDictionary alloc] init];

    NSArray *emagComponents = [emagCode componentsSeparatedByString:@"/"];
    int emaCode = [[emagComponents objectAtIndex:1] intValue];
    int smoothCode = [[emagComponents objectAtIndex:2] intValue];
    int gammaCode = [[emagComponents objectAtIndex:3] intValue];
    NSString *emadString = [NSString stringWithFormat:@"EMAD/%d/%d",emaCode,smoothCode];
    
    BOOL requiredDataFound = NO;
    if([dataDictionary objectForKey:emadString] != nil){
        requiredDataFound = YES;
        emadData = [dataDictionary objectForKey:emadString];
        emadArray = (double *)[emadData bytes];
        dataLength = [emadData length]/sizeof(double);
    }
    
    NSMutableData *emagData = [[NSMutableData alloc] initWithLength:dataLength * sizeof(double)];
    double *emagArray = (double *)[emagData mutableBytes];
    
    if(requiredDataFound){
        BOOL includeOldData = NO;
        includeOldData = ![[oldDataDictionary objectForKey:@"ALLNEWDATA"] boolValue];
        long lagLengthForGamma = [UtilityFunctions fib:(gammaCode)];
        
        if(includeOldData){
            int dataOverlapIndex;
            NSDictionary *trailingSeriesDictionary;
            long oldDataLength;
            
            trailingSeriesDictionary = [oldDataDictionary objectForKey:@"OLDDATA"];
            dataOverlapIndex = [[oldDataDictionary objectForKey:@"OVERLAPINDEX"] intValue];
            
            NSData *oldEmadData = [trailingSeriesDictionary objectForKey:emadString];
            double *oldEmadArray = (double *)[oldEmadData bytes];
            NSData *oldEmagData = [trailingSeriesDictionary objectForKey:emagCode];
            double *oldEmagArray = (double *)[oldEmagData bytes];
            
            long lagIndexForOldData = -1;
            
            oldDataLength = [oldEmadData length]/sizeof(long);
            
            for(long i = dataOverlapIndex ; i < oldDataLength; i++){
                emagArray[i-dataOverlapIndex] = oldEmagArray[i];
            }
            
            if(oldDataLength - lagLengthForGamma > 0){
                lagIndexForOldData = oldDataLength - lagLengthForGamma;
            }
            
            for(long i = oldDataLength - dataOverlapIndex; i < dataLength; i++){
                if(i - lagLengthForGamma >= 0){
                    emagArray[i] = emadArray[i] - emadArray[i- lagLengthForGamma];
                }else{
                    if(lagIndexForOldData > -1 && lagIndexForOldData < oldDataLength){
                        emagArray[i] = emadArray[i] - oldEmadArray[lagIndexForOldData];
                        lagIndexForOldData++;
                    }
                }
            }
        }else{
            for(int i = 0; i < dataLength; i++){
                if(i - lagLengthForGamma >= 0){
                    emagArray[i] = emadArray[i] - emadArray[i- lagLengthForGamma];
                    
                }
            }
        }
        [returnData setObject:emagData
                       forKey:emagCode];
        
        [returnData setObject:[NSNumber numberWithBool:YES]
                       forKey:@"SUCCESS"];
    }else{
        [returnData setObject:[NSNumber numberWithBool:NO]
                       forKey:@"SUCCESS"];
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

+ (NSDictionary *) calcGridStatsWithDerivedData: (NSDictionary *) dataDictionary
                              AndOldDerivedData: (NSDictionary *) oldDataDictionary
                                   AndPriceData: (NSDictionary *) priceDataDictionary
                                        ForCode: (NSString *) gridStatsCode
                                AndSignalSystem: (SignalSystem *) signalSystem
{
    long dataLength;
    NSString *seriesString;
    
    //GRDPOS/26/0.025/26/0.2
    
    NSArray *gridStatsCodeComponents = [gridStatsCode componentsSeparatedByString:@"/"];
    int seriesCode = [[gridStatsCodeComponents objectAtIndex:1] intValue];
    double gridStep = [[gridStatsCodeComponents objectAtIndex:2] doubleValue];
    int smoothCode = [[gridStatsCodeComponents objectAtIndex:3] intValue];
    double gridThreshold = [[gridStatsCodeComponents objectAtIndex:4] doubleValue];
    
    if(seriesCode == 0){
        seriesString = @"MID";
    }else{
        seriesString = [NSString stringWithFormat:@"EMA/%d",seriesCode];
    }
    
    NSString *gridWidthString = [NSString stringWithFormat:@"GRIDWIDTH/%d/%f/%d/%f",seriesCode,gridStep,smoothCode,gridThreshold];
    NSString *gridQuantileString = [NSString stringWithFormat:@"GRIDQUANT/%d/%f/%d/%f",seriesCode,gridStep,smoothCode,gridThreshold];
   
    NSString *gridMinString = [NSString stringWithFormat:@"GRIDMIN/%d/%f/%d/%f",seriesCode,gridStep,smoothCode,gridThreshold];
    NSString *gridMaxString = [NSString stringWithFormat:@"GRIDMAX/%d/%f/%d/%f",seriesCode,gridStep,smoothCode,gridThreshold];
    NSString *gridSumString = [NSString stringWithFormat:@"GRIDSUM/%d/%f/%d/%f",seriesCode,gridStep,smoothCode,gridThreshold];

    
    NSMutableDictionary *returnData = [[NSMutableDictionary alloc] init];
    NSData *seriesData;
    double *seriesArray;
    NSData *dateTimeData;
    long *dateTimeArray;
    NSArray *dataKeys = [dataDictionary allKeys];
    
    dateTimeData  = [priceDataDictionary objectForKey:@"DATETIME"];
    dateTimeArray = (long *)[dateTimeData bytes];
    BOOL success = YES;
    
    BOOL foundSeries = NO;
    if(seriesCode == 0){
        seriesData = [priceDataDictionary objectForKey:@"MID"];
        foundSeries = YES;
    }else
    {
        for(int i = 0; i < [dataKeys count]; i++){
            if([[dataKeys objectAtIndex:i] isEqualToString:seriesString]){
                seriesData = [dataDictionary objectForKey:seriesString];
                seriesArray = (double *)[seriesData bytes];
                dataLength = [seriesData length]/sizeof(double);
                foundSeries = YES;
                break;
            }
        }
    }
    long arrayStartIndex = 0;
    
    if(foundSeries){
        BOOL includeOldData = NO;
        includeOldData = ![[oldDataDictionary objectForKey:@"ALLNEWDATA"] boolValue];
        
        
        NSMutableData *gridWidthData = [[NSMutableData alloc] initWithLength:dataLength * sizeof(double)];
        double *gridWidthArray = (double *)[gridWidthData mutableBytes];
        
        NSMutableData *gridQuantileData = [[NSMutableData alloc] initWithLength:dataLength * sizeof(double)];
        double *gridQuantileArray = (double *)[gridQuantileData mutableBytes];
        
        NSMutableData *gridMinData = [[NSMutableData alloc] initWithLength:dataLength * sizeof(double)];
        double *gridMinArray = (double *)[gridMinData mutableBytes];
        
        NSMutableData *gridMaxData = [[NSMutableData alloc] initWithLength:dataLength * sizeof(double)];
        double *gridMaxArray = (double *)[gridMaxData mutableBytes];
        
        NSMutableData *gridSumData = [[NSMutableData alloc] initWithLength:dataLength * sizeof(double)];
        double *gridSumArray = (double *)[gridSumData mutableBytes];
        
        double alphaParameter = 2.0/(1.0+[UtilityFunctions fib:smoothCode]);
        
        double gridLowerBound, gridUpperBound;
        
        NSMutableData *gridLevelsData;
        double *gridLevelsArray;
        int gridLength;
        
        if(includeOldData){
            NSDictionary *trailingSeriesDictionary = [oldDataDictionary objectForKey:@"OLDDATA"];
            int dataOverlapIndex = [[oldDataDictionary objectForKey:@"OVERLAPINDEX"] intValue];
            NSData *oldDateTimeData = [oldDataDictionary objectForKey:@"OLDDATETIME"];
            long *oldDateTimeArray = (long *) [oldDateTimeData bytes];
            long oldDataLength = [oldDateTimeData length]/sizeof(long);

            
            NSData *oldGridQuantileData = [trailingSeriesDictionary objectForKey:gridQuantileString];
            double *oldGridQuantileArray = (double *)[oldGridQuantileData bytes];
            NSData *oldGridWidthData = [trailingSeriesDictionary objectForKey:gridWidthString];
            double *oldGridWidthArray = (double *)[oldGridWidthData bytes];
            
            NSData *oldGridMinData = [trailingSeriesDictionary objectForKey:gridMinString];
            double *oldGridMinArray = (double *)[oldGridMinData bytes];
            NSData *oldGridMaxData = [trailingSeriesDictionary objectForKey:gridMaxString];
            double *oldGridMaxArray = (double *)[oldGridMaxData bytes];
            NSData *oldGridSumData = [trailingSeriesDictionary objectForKey:gridSumString];
            double *oldGridSumArray = (double *)[oldGridSumData bytes];
            
            gridLevelsData = [[signalSystem miscStoredInfoDictionary] objectForKey:@"GRIDLEVELS"];
            gridLevelsArray = (double *)[gridLevelsData bytes];
            
            gridLowerBound = [[[signalSystem miscStoredInfoDictionary] objectForKey:@"GRIDLOWERBOUND"] doubleValue];
            gridUpperBound = [[[signalSystem miscStoredInfoDictionary] objectForKey:@"GRIDUPPERBOUND"] doubleValue];
            
            for(long i = dataOverlapIndex ; i < oldDataLength; i++){
                if(dateTimeArray[i-dataOverlapIndex] != oldDateTimeArray[i]){
                    success = NO;
                    NSLog(@"Problem with overlapping periods, times don't match");
                }
                gridQuantileArray[i-dataOverlapIndex] = oldGridQuantileArray[i];
                gridWidthArray[i-dataOverlapIndex] = oldGridWidthArray[i];
                gridMinArray[i-dataOverlapIndex] = oldGridMinArray[i];
                gridMaxArray[i-dataOverlapIndex] = oldGridMaxArray[i];
                gridSumArray[i-dataOverlapIndex] = oldGridSumArray[i];
            }
            arrayStartIndex = oldDataLength - dataOverlapIndex + 1;
            
        }else{
            //For the first ever datapoint the grid array is set up and the grid with is set to 1 and and the data's quantile set to 0.5
            
            gridLowerBound = gridStep*floor(seriesArray[0]/gridStep);
            gridUpperBound = gridLowerBound + gridStep;
            
            gridLevelsData = [NSMutableData dataWithLength:1];
            gridLevelsArray = (double *)[gridLevelsData mutableBytes];
            gridLevelsArray[0] = alphaParameter;
            gridWidthArray[0] = 1;
            gridQuantileArray[0] = (seriesArray[0]-gridLowerBound)/(gridUpperBound - gridLowerBound);
            arrayStartIndex = 1;
            gridMinArray[0] = gridLowerBound;
            gridMaxArray[0] = gridUpperBound;
            gridSumArray[0] = alphaParameter;
        }
        
        
        
        for(long iData = arrayStartIndex; iData < dataLength; iData++){
//
            
             //Check if the datapoint is below the lowerbound, if so increase the range of the grid
            if(seriesArray[iData] < gridLowerBound){
                double newLowerBound = gridStep*floor(seriesArray[iData]/gridStep);
                int newNumberOfBins = round((gridUpperBound - newLowerBound)/gridStep);
                int numberOfExtraBins = newNumberOfBins - round((gridUpperBound - gridLowerBound)/gridStep);
                gridLowerBound = newLowerBound;
                
                NSMutableData *newGridLevelsData = [NSMutableData dataWithLength:sizeof(double)*newNumberOfBins];
                double *newGridLevelsArray = (double *)[newGridLevelsData mutableBytes];
                for(int iBin = 0; iBin < newNumberOfBins;iBin++){
                    if(iBin < numberOfExtraBins){
                        newGridLevelsArray[iBin] = 0.0;
                    }else{
                        newGridLevelsArray[iBin] = gridLevelsArray[iBin-numberOfExtraBins];
                    }
                }
                gridLevelsData = newGridLevelsData;
                gridLevelsArray = newGridLevelsArray;
            }
            //Check if the datapoint is above the upperbound, if so increase the range of the grid
            if(seriesArray[iData] >= gridUpperBound){
                double newUpperBound = gridStep*(floor(seriesArray[iData]/gridStep)+1);
                int newNumberOfBins = round((newUpperBound - gridLowerBound)/gridStep);
                int numberOfExtraBins = newNumberOfBins - round((gridUpperBound - gridLowerBound)/gridStep);
                gridUpperBound = newUpperBound;
                
                NSMutableData *newGridLevelsData = [NSMutableData dataWithLength:sizeof(double)*newNumberOfBins];
                double *newGridLevelsArray = (double *)[newGridLevelsData mutableBytes];
                for(int iBin = 0; iBin < newNumberOfBins;iBin++){
                    if(iBin < numberOfExtraBins){
                        newGridLevelsArray[iBin] = 0.0;
                    }else{
                        newGridLevelsArray[iBin] = gridLevelsArray[iBin-numberOfExtraBins];
                    }
                }
                gridLevelsData = newGridLevelsData;
                gridLevelsArray = newGridLevelsArray;
                
            }
            gridLength = round((gridUpperBound - gridLowerBound)/gridStep);
            
            //Gather the statistics
            double levelsSumTotal = 0.0;
            double levelsSumLessThan = 0.0;
            
            
            for(int iBin = 0; iBin < gridLength; iBin++){
                levelsSumTotal = levelsSumTotal + gridLevelsArray[iBin];
                if(seriesArray[iData] > (gridLowerBound + iBin*gridStep)){
                    if(seriesArray[iData] < (gridLowerBound + (iBin+1)*gridStep)){
                        levelsSumLessThan = levelsSumLessThan + gridLevelsArray[iBin]*((seriesArray[iData]- (gridLowerBound + iBin*gridStep))/gridStep) ;
                    }else{
                        levelsSumLessThan = levelsSumLessThan + gridLevelsArray[iBin];
                    }
                }
            }
            
            double levelsSumRunning = 0.0;
            double lowerQuantile = gridThreshold*levelsSumTotal;
            double upperQuantile = (1-gridThreshold)*levelsSumTotal;
            for(int iBin = 0; iBin < gridLength; iBin++){
            
                if((levelsSumRunning < lowerQuantile) && (levelsSumRunning + gridLevelsArray[iBin]) > lowerQuantile){
                    double overage = (lowerQuantile-levelsSumRunning)/gridLevelsArray[iBin];
                    gridMinArray[iData] = (gridLowerBound + iBin*gridStep) + gridStep *overage;
                }
                if((levelsSumRunning < upperQuantile) && (levelsSumRunning + gridLevelsArray[iBin]) > upperQuantile){
                    double overage = (upperQuantile-levelsSumRunning)/gridLevelsArray[iBin];
                    gridMaxArray[iData] = (gridLowerBound + iBin*gridStep) + gridStep *overage;
                }
                levelsSumRunning = levelsSumRunning + gridLevelsArray[iBin];
                
                gridLevelsArray[iBin] = gridLevelsArray[iBin] * (1-alphaParameter);
                if((seriesArray[iData] > (gridLowerBound + iBin*gridStep)) && (seriesArray[iData] <= (gridLowerBound + (iBin+1)*gridStep))){
                    gridLevelsArray[iBin] = gridLevelsArray[iBin] + alphaParameter;
                }
            }
     
            if(levelsSumTotal > 0.0){
                gridQuantileArray[iData] = levelsSumLessThan/levelsSumTotal;
            }else{
                gridQuantileArray[iData] = 0.5;
            }
            gridWidthArray[iData] = gridMaxArray[iData] - gridMinArray[iData];
            gridSumArray[iData] = levelsSumTotal;
        }
        [[signalSystem miscStoredInfoDictionary] setObject:gridLevelsData forKey:@"GRIDLEVELS"];
        [[signalSystem miscStoredInfoDictionary] setObject:[NSNumber numberWithDouble:gridLowerBound]  forKey:@"GRIDLOWERBOUND"];
        [[signalSystem miscStoredInfoDictionary] setObject:[NSNumber numberWithDouble:gridUpperBound]  forKey:@"GRIDUPPERBOUND"];
        
   
        [returnData setObject:gridWidthData
                       forKey:gridWidthString];
        [returnData setObject:gridQuantileData
                       forKey:gridQuantileString];
        [returnData setObject:gridMinData
                       forKey:gridMinString];
        [returnData setObject:gridMaxData
                       forKey:gridMaxString];
        [returnData setObject:gridSumData
                       forKey:gridSumString];
        
               [returnData setObject:[NSNumber numberWithBool:YES]
                       forKey:@"SUCCESS"];
    }else{
        [returnData setObject:[NSNumber numberWithBool:NO]
                       forKey:@"SUCCESS"];
    }
    return returnData;
}



+ (NSDictionary *) calcTicNumberWithData: (NSDictionary *) dataDictionary
                              AndOldData: (NSDictionary *) oldDataDictionary
{
    NSMutableDictionary *returnData = [[NSMutableDictionary alloc] init];
    NSDictionary *trailingSeriesDictionary;
    
    BOOL includeOldData = NO, success = YES;
    includeOldData = ![[oldDataDictionary objectForKey:@"ALLNEWDATA"] boolValue];
    
    int dataOverlapIndex;
    
    long oldDataLength, dataLength, *oldDataTimeArray, *dateTimeArray;
    
    NSData  *dateTimeData, *oldDateTimeData;
    
    dateTimeData =  [dataDictionary objectForKey:@"DATETIME"];
    dateTimeArray = (long *)[dateTimeData bytes];
    dataLength = [dateTimeData length]/sizeof(double);
    
    if(includeOldData){
        if([oldDataDictionary objectForKey:@"OLDDATA"] == nil ||
           [oldDataDictionary objectForKey: @"OVERLAPINDEX"] == nil ||
           [oldDataDictionary objectForKey:@"OLDDATETIME"] == nil){
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
        NSMutableData *ticNumberData;
        NSData *oldticNumberData;
        double *ticNumberArray, *oldTicNumberArray;
        
        ticNumberData = [[NSMutableData alloc] initWithLength:dataLength * sizeof(double)];
        ticNumberArray = [ticNumberData mutableBytes];
        if(includeOldData){
            oldticNumberData = [trailingSeriesDictionary objectForKey:@"TICN"];
            oldTicNumberArray = (double *)[oldticNumberData bytes];
            for(long i = dataOverlapIndex ; i <= oldDataLength; i++){
                ticNumberArray[i-dataOverlapIndex] = oldTicNumberArray[i];
            }
            for(long i = oldDataLength - dataOverlapIndex; i < dataLength; i++){
                ticNumberArray[i] = ticNumberArray[i-1]+1;
            }
            [returnData setObject:ticNumberData forKey:@"TICN"];
        }else{
            for(int i = 0; i < dataLength; i++){
                ticNumberArray[i] = i;
            }
            [returnData setObject:ticNumberData forKey:@"TICN"];
        }
    }
    
    if(success){
        [returnData setObject:[NSNumber numberWithBool:YES] forKey:@"SUCCESS"];
    }else{
        [returnData setObject:[NSNumber numberWithBool:NO] forKey:@"SUCCESS"];
        
    }
    return returnData;
}


+ (NSDictionary *) calcOHLCWithData: (NSDictionary *) dataDictionary
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
        if([oldDataDictionary objectForKey:@"OLDDATA"] == nil ||
           [oldDataDictionary objectForKey: @"OVERLAPINDEX"] == nil ||
           [oldDataDictionary objectForKey:@"OLDDATETIME"] == nil){
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
                // New day
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
                    NSLog(@"Check1");
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
                     WithOHLCData: (NSDictionary *) dataDictionary
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
    
    long dataLength = [closeData length]/sizeof(double);
    
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
    
    
    double *atrArray;
    
    NSArray *codeComponents = [seriesCode componentsSeparatedByString:@"/"];
    if([codeComponents count] == 1){
        success = NO;
    }else{
        int daysForAveraging = [[codeComponents objectAtIndex:1] intValue];
        includeOldData = ![[oldDataDictionary objectForKey:@"ALLNEWDATA"] boolValue];
        
        NSData  *oldAtrData, *oldCloseData, *oldDateTimeData;
        
        double *oldAtrArray, *oldCloseArray;
        long *oldDateTimeArray;
        long dataOverlapIndex, oldDataLength;
        
        
        
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
                while([EpochTime daysSinceEpoch:oldDateTimeArray[dataOverlapIndex]] > dayNumberArray[0] && dataOverlapIndex > 0){
                        dataOverlapIndex--;
                }
             
                if((dataOverlapIndex == 0 && [EpochTime daysSinceEpoch:oldDateTimeArray[dataOverlapIndex]] >= dayNumberArray[0])){
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
                    trueRange  = MAX(highArray[i]-lowArray[i],MAX(highArray[i]-closeArray[i-1],closeArray[i-1]-lowArray[i]));
                    atrArray[i] = ((daysForAveraging - 1) * atrArray[i-1] + trueRange)/ daysForAveraging;
                }
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
                        NSLog(@"Check4");
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
        long *lastDateTimeForDayArray = 0;
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
                double trueRange;
                dataIndex = 0;
                while(dataIndex < dataLength){
                    if([EpochTime daysSinceEpoch:dateTimeArray[dataIndex]] != dayNumber){
                        trueRange  = MAX(highForDayArray[dayDataIndex]-lowForDayArray[dayDataIndex],MAX(highForDayArray[dayDataIndex]-closeForDayArray[dayDataIndex-1],closeForDayArray[dayDataIndex-1])-lowForDayArray[dayDataIndex]);
                        
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
                // Last days ATR
                trueRange  = MAX(highForDayArray[dayDataIndex]-lowForDayArray[dayDataIndex],MAX(highForDayArray[dayDataIndex]-closeForDayArray[dayDataIndex],closeForDayArray[dayDataIndex]-lowForDayArray[dayDataIndex]));
                atrForDayArray[dayDataIndex] = ((daysForAveraging - 1) * atrForDayArray[dayDataIndex-1] + trueRange)/ daysForAveraging;
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

+ (NSDictionary *) calcFDIMWithOHLCData: (NSDictionary *) ohlcDataDictionary
                             AndTicData: (NSDictionary *) dataDictionary
                          AndOldTicData: (NSDictionary *) oldDataDictionary;
{
    NSMutableDictionary *returnData = [[NSMutableDictionary alloc] init];
    
    
    NSData *closeData = [ohlcDataDictionary objectForKey:@"CLOSE"];
    double *closeArray = (double *)[closeData bytes];
    NSData *highData = [ohlcDataDictionary objectForKey:@"HIGH"];
    double *highArray = (double *)[highData bytes];
    NSData *lowData = [ohlcDataDictionary objectForKey:@"LOW"];
    double *lowArray = (double *)[lowData bytes];
    NSData *dayNumberData = [ohlcDataDictionary objectForKey:@"DAYNUMBER"];
    long *dayNumberArray = (long *)[dayNumberData bytes];
    NSData *dataCountData = [ohlcDataDictionary objectForKey:@"DAYDATACOUNT"];
    long *dataCountArray = (long *)[dataCountData bytes];
    NSData *lastDateTimeForDayData = [ohlcDataDictionary objectForKey:@"LASTTIME"];
    long *lastDateTimeForDayArray = (long *)[lastDateTimeForDayData bytes];
    NSMutableData *fdimExpandedData, *fdim2ExpandedData;
    
    // This holds the last value of the old data so if new data starts on a weekend we can fill forward the old data
    double oldDataLastFdimValue, oldDataLastFdim2Value;
    
    BOOL includeOldData = NO, success = YES;
    includeOldData = ![[oldDataDictionary objectForKey:@"ALLNEWDATA"] boolValue];
    
    int dataOverlapIndex;
    NSDictionary *trailingSeriesDictionary;
    
    if(includeOldData){
        if([oldDataDictionary objectForKey:@"OLDDATA"] == nil ||
           [oldDataDictionary objectForKey: @"OVERLAPINDEX"] == nil ||
           [oldDataDictionary objectForKey:@"OLDDATETIME"] == nil){
            success = NO;
        }else{
            trailingSeriesDictionary = [oldDataDictionary objectForKey:@"OLDDATA"];
            dataOverlapIndex = [[oldDataDictionary objectForKey:@"OVERLAPINDEX"] intValue];
            NSData *oldFdimData = [trailingSeriesDictionary objectForKey:@"FDIM"];
            double *oldFdimArray = (double *)[oldFdimData bytes];
            NSData *oldFdim2Data = [trailingSeriesDictionary objectForKey:@"FDIM2"];
            double *oldFdim2Array = (double *)[oldFdim2Data bytes];
            oldDataLastFdimValue = oldFdimArray[dataOverlapIndex];
            oldDataLastFdim2Value = oldFdim2Array[dataOverlapIndex];
        }
    }
    if(success){
        
        long dayDataLength = [closeData length]/sizeof(double);
        
        // Get rid of any weekend days
        
        NSMutableData  *closeData2, *highData2, *lowData2, *dataCountData2,*dayNumberData2, *lastDateTimeData2;
        
        long  *dataCountArray2, *dayNumberArray2 , *lastDateTimeArray2;
        double *closeArray2, *highArray2, *lowArray2 ;
        
        int reducedNumberOfDays = 0;
        for(int i = 0; i < dayDataLength; i++){
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
        closeArray2 = (double *)[closeData2 bytes];
        highArray2 = (double *)[highData2 bytes];
        lowArray2 = (double *)[lowData2 bytes];
        dataCountArray2 = (long *)[dataCountData2 bytes];
        dayNumberArray2 = (long *)[dayNumberData2 bytes];
        
        int arrayIndex = 0;
        for(int i = 0; i < dayDataLength; i++){
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
        dataCountArray = dataCountArray2;
        dayNumberArray = dayNumberArray2;
        lastDateTimeForDayArray = lastDateTimeArray2;
        dayDataLength = reducedNumberOfDays;
        // Finished excluding weekend days
        
        NSData *midData, *dateTimeData;
        
        double *midArray;
        
        long *dateTimeArray;
        
        midData = [dataDictionary objectForKey:@"MID"];
        long dataLength = [midData length]/sizeof(double);
        midArray = (double *)[midData bytes];
        dateTimeData =  [dataDictionary objectForKey:@"DATETIME"];
        dateTimeArray = (long *)[dateTimeData bytes];
        
        NSMutableData *fdimDayData = [[NSMutableData alloc] initWithLength:(dayDataLength * sizeof(double))];
        double *fdimDayArray = (double *)[fdimDayData bytes];
        NSMutableData *fdim2DayData = [[NSMutableData alloc] initWithLength:(dayDataLength * sizeof(double))];
        double *fdim2DayArray = (double *)[fdim2DayData bytes];

        
        int dayIndex = 0;
        long ticDataIndex = 0;
        long dayStartDateTime, dayEndDateTime;
        double rebasedFdimValue,previousRebasedFdimValue, rebasedTimeDateValue ,previousRebasedDateTimeValue;
        while(dayIndex <= dayDataLength){
            
            
            fdimDayArray[dayIndex] = 0.0;
            fdim2DayArray[dayIndex] = 0.0;
            while(([EpochTime daysSinceEpoch:dateTimeArray[ticDataIndex]] < dayNumberArray[dayIndex]) && ticDataIndex < dataLength){
                ticDataIndex++;
            }
            dayStartDateTime = dateTimeArray[ticDataIndex];
            dayEndDateTime = lastDateTimeForDayArray[dayIndex];
            if(ticDataIndex < dataLength){
                previousRebasedFdimValue = (midArray[ticDataIndex] - lowArray[dayIndex])/(highArray[dayIndex]-lowArray[dayIndex]);
                previousRebasedDateTimeValue = ((double)dateTimeArray[ticDataIndex] - dayStartDateTime)/((double)dayEndDateTime-dayStartDateTime);
            }
            //Start with the second tic of the day as we reach back for the first
            ticDataIndex++;
            while([EpochTime daysSinceEpoch:dateTimeArray[ticDataIndex]] == dayNumberArray[dayIndex] && ticDataIndex < dataLength)
            {
                rebasedFdimValue = (midArray[ticDataIndex] - lowArray[dayIndex])/(highArray[dayIndex]-lowArray[dayIndex]);
                rebasedTimeDateValue = (midArray[ticDataIndex] - lowArray[dayIndex])/(highArray[dayIndex]-lowArray[dayIndex]);
                fdimDayArray[dayIndex] = fdimDayArray[dayIndex] + sqrt(pow(rebasedFdimValue -  previousRebasedFdimValue,2) + pow(1/dataCountArray[dayIndex],2));
                fdim2DayArray[dayIndex] = fdim2DayArray[dayIndex] + sqrt(pow(rebasedFdimValue -  previousRebasedFdimValue,2) + pow(rebasedTimeDateValue-previousRebasedDateTimeValue,2));
                
                previousRebasedFdimValue = rebasedFdimValue;
                previousRebasedDateTimeValue = rebasedTimeDateValue;
                ticDataIndex++;
            }
            fdimDayArray[dayIndex] = 1+(log(fdimDayArray[dayIndex])/log(2*(dataCountArray[dayIndex]-1)));
            fdim2DayArray[dayIndex] = 1+(log(fdim2DayArray[dayIndex])/log(2*(dataCountArray[dayIndex]-1)));
            dayIndex++;
        }
        
        fdimExpandedData = [[NSMutableData alloc] initWithLength:(dataLength* sizeof(double))];
        double *fdimExpandedArray = (double *)[fdimExpandedData bytes];
        fdim2ExpandedData = [[NSMutableData alloc] initWithLength:(dataLength* sizeof(double))];
        double *fdim2ExpandedArray = (double *)[fdim2ExpandedData bytes];
        dayIndex = 0;
        
        ticDataIndex = 0;
        
        while([EpochTime daysSinceEpoch:dateTimeArray[ticDataIndex]] < dayNumberArray[dayIndex]){
            if(includeOldData){
                fdimExpandedArray[ticDataIndex] = oldDataLastFdimValue;
                fdim2ExpandedArray[ticDataIndex] = oldDataLastFdim2Value;
            }else{
                //This will indicate that the data is not available, giving fdim a value of 1.5
                fdimExpandedArray[ticDataIndex] = 1.5;
                fdim2ExpandedArray[ticDataIndex] = 1.5;
            }
            ticDataIndex++;
        }
        
        while(ticDataIndex < dataLength){
                       
            while(dayNumberArray[dayIndex] < [EpochTime daysSinceEpoch:dateTimeArray[ticDataIndex]] && [EpochTime isWeekday:dateTimeArray[ticDataIndex]] && (dayIndex < dayDataLength - 1))
            {
                dayIndex ++;
            }
            fdimExpandedArray[ticDataIndex] = fdimDayArray[dayIndex];
            fdim2ExpandedArray[ticDataIndex] = fdim2DayArray[dayIndex];
            ticDataIndex++;
        }
    }
    
    if(success){
        [returnData setObject:[NSNumber numberWithBool:YES] forKey:@"SUCCESS"];
        [returnData setObject:fdimExpandedData forKey:@"FDIM"];
        [returnData setObject:fdim2ExpandedData forKey:@"FDIM2"];
    }else{
        [returnData setObject:[NSNumber numberWithBool:NO] forKey:@"SUCCESS"];
        
    }
    return returnData;
}

+ (NSDictionary *) calcAemadForCode: (NSString *) aemadCode
                           WithData: (NSDictionary *) emadData
                         AndOldData: (NSDictionary *) oldDataDictionary
                         AndPipSize: (double) pipSize
{
    double *fastArray, *slowArray;
    long dataLength;
    
    NSMutableDictionary *returnData = [[NSMutableDictionary alloc] init];
    
    NSArray *aemadComponents = [aemadCode componentsSeparatedByString:@"/"];
    
    NSString *fastString, *slowString;
    double slowThreshold, fastThreshold, stepAdjust;
    int slowCode, fastCode;
    if([[aemadComponents objectAtIndex:0] isEqualToString:@"AEMAD"]){
        slowCode = [[aemadComponents objectAtIndex:1] intValue];
        slowThreshold = [[aemadComponents objectAtIndex:2] doubleValue];
        slowThreshold = slowThreshold * pipSize;
        fastCode = [[aemadComponents objectAtIndex:3] intValue];
        stepAdjust = [[aemadComponents objectAtIndex:4] doubleValue];
        
        fastString = [NSString stringWithFormat:@"EMAD/%d/%d",fastCode,fastCode];
        slowString = [NSString stringWithFormat:@"EMAD/%d/%d",slowCode,slowCode];
    }
    
    if([[aemadComponents objectAtIndex:0] isEqualToString:@"AEMBD"]){
        NSRange firstBracket = [aemadCode rangeOfString:@"/"];
        NSString *pacsString = [aemadCode substringFromIndex:firstBracket.location+1];
        NSRange lastBracket = [pacsString rangeOfString:@"/"
                                                options:NSBackwardsSearch];
        
        stepAdjust = [[pacsString substringFromIndex:lastBracket.location+1] doubleValue];
        pacsString = [pacsString substringToIndex:lastBracket.location];
        lastBracket = [pacsString rangeOfString:@"/"
                                        options:NSBackwardsSearch];
        
        fastCode = [[pacsString substringFromIndex:lastBracket.location+1] intValue];
        pacsString = [pacsString substringToIndex:lastBracket.location];
        lastBracket = [pacsString rangeOfString:@"/"
                                        options:NSBackwardsSearch];
        
        slowThreshold = [[pacsString substringFromIndex:lastBracket.location+1] doubleValue];
        pacsString = [pacsString substringToIndex:lastBracket.location];
        lastBracket = [pacsString rangeOfString:@"/"
                                        options:NSBackwardsSearch];
        
        slowCode = [[pacsString substringFromIndex:lastBracket.location+1] intValue];
        pacsString = [pacsString substringToIndex:lastBracket.location];
        
        fastString = [NSString stringWithFormat:@"EMBD/%@/%d/%d",pacsString,fastCode,fastCode];
        slowString = [NSString stringWithFormat:@"EMBD/%@/%d/%d",pacsString,slowCode,slowCode];
     }
    fastThreshold = slowThreshold * pow(stepAdjust,(slowCode - fastCode));
    slowThreshold = slowThreshold * pipSize;
    fastThreshold = fastThreshold * pipSize;
    
    
    //NSString *aemadString = [NSString stringWithFormat:@"AEMAD/%d/%f/%d/%f",fastCode,slowThreshold,slowCode,stepAdjust];
    
    NSData *fastData, *slowData;
    
    NSArray *dataKeys = [emadData allKeys];
    
    BOOL foundFast = NO, foundSlow = NO;
    for(int i = 0; i < [dataKeys count]; i++){
        if([[dataKeys objectAtIndex:i] isEqualToString:fastString]){
            foundFast = YES;
            fastData = [emadData objectForKey:fastString];
            fastArray = (double *)[fastData bytes];
            dataLength = [fastData length]/sizeof(double);
        }
        if([[dataKeys objectAtIndex:i] isEqualToString:slowString]){
            foundSlow = YES;
            slowData = [emadData objectForKey:slowString];
            slowArray = (double *)[slowData bytes];
        }
    }
    
    if(foundFast && foundSlow){
        BOOL includeOldData = NO;
        includeOldData = ![[oldDataDictionary objectForKey:@"ALLNEWDATA"] boolValue];
        
        
        NSMutableData *aemadData = [[NSMutableData alloc] initWithLength:dataLength * sizeof(double)];
        double *aemadArray = (double *)[aemadData mutableBytes];
        
//        NSMutableData *macdHistData = [[NSMutableData alloc] initWithLength:dataLength * sizeof(double)];
//        double *macdHistArray = (double *)[macdHistData mutableBytes];
//        
//        NSMutableData *macdHistDeltaData = [[NSMutableData alloc] initWithLength:dataLength * sizeof(double)];
//        double *macdHistDeltaArray = (double *)[macdHistDeltaData mutableBytes];
//        
//        NSMutableData *macdSigData = [[NSMutableData alloc] initWithLength:dataLength * sizeof(double)];
//        double *macdSigArray = (double *)[macdSigData mutableBytes];
//        
        
        
//        long lagLengthForHistDelta = [UtilityFunctions fib:(slowCode - fastCode)];
        
        if(includeOldData){
            int dataOverlapIndex;
            NSDictionary *trailingSeriesDictionary;
            long oldDataLength;
            
            trailingSeriesDictionary = [oldDataDictionary objectForKey:@"OLDDATA"];
            dataOverlapIndex = [[oldDataDictionary objectForKey:@"OVERLAPINDEX"] intValue];
            
            NSData *oldAemadData = [trailingSeriesDictionary objectForKey:aemadCode];
            double *oldAemadArray = (double *)[oldAemadData bytes];
            oldDataLength = [oldAemadData length]/sizeof(long);
            for(long i = dataOverlapIndex ; i < oldDataLength; i++){
                aemadArray[i-dataOverlapIndex] = oldAemadArray[i];
            }
            for(long i = oldDataLength - dataOverlapIndex; i < dataLength; i++){
                if(slowArray[i] >= slowThreshold & fastArray[i] >= fastThreshold){
                    aemadArray[i] = 1;
                }
                if(slowArray[i] <= -slowThreshold & fastArray[i] <= -fastThreshold){
                    aemadArray[i] = -1;
                }
             }
        }else{
            for(int i = 0; i < dataLength; i++){
                if(slowArray[i] >= slowThreshold & fastArray[i] >= fastThreshold){
                    aemadArray[i] = 1;
                }
                if(slowArray[i] <= -slowThreshold & fastArray[i] <= -fastThreshold){
                    aemadArray[i] = -1;
                }

            }
        }
        [returnData setObject:aemadData
                       forKey:aemadCode];
        [returnData setObject:[NSNumber numberWithBool:YES]
                       forKey:@"SUCCESS"];
    }else{
        [returnData setObject:[NSNumber numberWithBool:NO]
                       forKey:@"SUCCESS"];
    }
    return returnData;
}



+ (NSDictionary *) calcPACSForCode: (NSString *) pacsCode
                   WithDerivedData: (NSDictionary *) dataDictionary
                 AndOldDerivedData: (NSDictionary *) oldDataDictionary
                        AndPipSize: (double) pipSize
                   AndSignalSystem: (SignalSystem *) signalSystem
{
    long dataLength;
    BOOL success = YES;
    
    NSArray *pacsCodeComponents = [pacsCode componentsSeparatedByString:@"/"];
    int minimumStep = [[pacsCodeComponents objectAtIndex:1] intValue];
    int maximumStep = [[pacsCodeComponents objectAtIndex:2] intValue];
    double quantile = [[pacsCodeComponents objectAtIndex:3] doubleValue];
    
    if(quantile > 1 || quantile < 0.5){
        success = NO;
    }
    
    int numberOfSeries = (maximumStep - minimumStep) + 1;
    
    NSMutableDictionary *returnData = [[NSMutableDictionary alloc] init];
    NSData *midData = [dataDictionary objectForKey:@"MID"];
    double *midArray = (double *)[midData bytes];
    NSData *dateTimeData  = [dataDictionary objectForKey:@"DATETIME"];
    long *dateTimeArray = (long *)[dateTimeData bytes];
    dataLength = [midData length]/sizeof(double);
    
    NSRange firstBracket = [pacsCode rangeOfString:@"/"];
    NSString *subString = [pacsCode substringFromIndex:firstBracket.location];
    NSString *bmidString = [NSString stringWithFormat:@"BMID%@",subString];
    NSString *bremString = [NSString stringWithFormat:@"BREM%@",subString];
    
    //NSMutableArray *pacsSeriesNames = [[NSMutableArray alloc] initWithCapacity:numberOfSeries];
    NSMutableArray *pathSeriesNames = [[NSMutableArray alloc] initWithCapacity:numberOfSeries];
    for(int i = minimumStep; i <= maximumStep; i++){
        //[pacsSeriesNames addObject:[NSString stringWithFormat:@"PACS%d",i]];
        [pathSeriesNames addObject:[NSString stringWithFormat:@"PATH%d",i]];
    }
    
    BOOL includeOldData = NO;
    includeOldData = ![[oldDataDictionary objectForKey:@"ALLNEWDATA"] boolValue];
    
    NSMutableData *pacsGridData, *newPacsGridData;
    long *pacsGridArray; 
    
    long gridWidth, newGridWidth;
    long *newPacsGridArray;
    //long countOfSmallerMoves;
    long midAbsMove, midMove, criticalMidMove, seriesIndex, moveCount, newDataIndex = 0, moveSign;
    //long bmidAbsMove, bmidMove, bmoveSign;
    // This is an array of data totals we need for calculation
    
    NSMutableData *pacsDivisorData = [[NSMutableData alloc] initWithLength:sizeof(long)*numberOfSeries];
    long *pacsDivisorArray = (long *)[pacsDivisorData bytes];
    
    //Create the data series structures for which we will need to calculate data
    //NSMutableArray *pacsSeriesTempHolder = [[NSMutableArray alloc] initWithCapacity:numberOfSeries];
    NSMutableArray *pathSeriesTempHolder = [[NSMutableArray alloc] initWithCapacity:numberOfSeries];
    
    NSMutableData *pathSeriesTempHolderData  = [[NSMutableData alloc] initWithLength:sizeof(double *) * numberOfSeries];
     double **pathSeriesTempHolderArray = (double **)[pathSeriesTempHolderData bytes];
    NSMutableData *pathSeriesData;
    
    for(int i = minimumStep; i <= maximumStep; i++){
        seriesIndex = i - minimumStep;
        
        pathSeriesData = [[NSMutableData alloc] initWithLength:sizeof(double) * dataLength];
        [pathSeriesTempHolder addObject:pathSeriesData];
        pathSeriesTempHolderArray[seriesIndex] = (double *)[pathSeriesData bytes];
    }
    NSMutableData *bmidData = [[NSMutableData alloc] initWithLength:sizeof(double) * dataLength];
    double *bmidArray = (double *)[bmidData bytes];
    NSMutableData *bremData = [[NSMutableData alloc] initWithLength:sizeof(double) * dataLength];
    double *bremArray = (double *)[bremData bytes];
    
    if(includeOldData){
        NSDictionary *trailingSeriesDictionary = [oldDataDictionary objectForKey:@"OLDDATA"];
        int dataOverlapIndex = [[oldDataDictionary objectForKey:@"OVERLAPINDEX"] intValue];
        NSData *oldDateTimeData = [oldDataDictionary objectForKey:@"OLDDATETIME"];
        long *oldDateTimeArray = (long *) [oldDateTimeData bytes];
        long oldDataLength = [oldDateTimeData length]/sizeof(long);
        NSData *oldMidData = [trailingSeriesDictionary objectForKey:@"MID"];
        double *oldMidArray = (double *)[oldMidData bytes];
        NSData *oldBmidData = [trailingSeriesDictionary objectForKey:bmidString];
        double *oldBmidArray = (double *)[oldBmidData bytes];
        NSData *oldBremData = [trailingSeriesDictionary objectForKey:bremString];
        double *oldBremArray = (double *)[oldBremData bytes];
        
        
        NSMutableArray *oldPathSeriesTempHolder ;
        NSData *oldPathSeriesTempHolderData = [[NSMutableData alloc] initWithLength:sizeof(double *) * numberOfSeries];
        double **oldPathSeriesTempHolderArray = (double **)[oldPathSeriesTempHolderData bytes];
        
        
        
        for(int i = 0; i < numberOfSeries; i++){
            pathSeriesData = [trailingSeriesDictionary objectForKey:[pathSeriesNames objectAtIndex:i]];
            [oldPathSeriesTempHolder addObject:pathSeriesData];
            oldPathSeriesTempHolderArray[seriesIndex] = (double *)[pathSeriesData bytes];
        }
        
        int oldDataIndex = dataOverlapIndex;
        
        if(oldDateTimeArray[oldDataIndex] == dateTimeArray[newDataIndex]){
            for(int i = 0; i < numberOfSeries; i++){
                //pacsSeriesTempHolderArray[i][newDataIndex] = oldPacsSeriesTempHolderArray[i][oldDataIndex];
                pathSeriesTempHolderArray[i][newDataIndex] = oldPathSeriesTempHolderArray[i][oldDataIndex];
                oldDataIndex++;
                newDataIndex++;
            }
            bmidArray[newDataIndex] = oldBmidArray[oldDataIndex];
            bremArray[newDataIndex] = oldBremArray[oldDataIndex];
            if(oldDataIndex != oldDataLength){
                NSLog(@"CHECK");
            }
        }else{
            NSLog(@"CHECK!");
        }
        
        pacsGridData = [[signalSystem miscStoredInfoDictionary] objectForKey:@"PACSGRID"];
        pacsGridArray = (long *)[pacsGridData mutableBytes];
        //pacsGridUseData = [[signalSystem miscStoredInfoDictionary] objectForKey:@"PACSGRIDUSE"];
        //pacsGridUseArray = (long *)[pacsGridUseData mutableBytes];
        
        gridWidth = [[[signalSystem miscStoredInfoDictionary] objectForKey:@"PACSGRIDWIDTH"] longValue];
         
        for(int iSeries = 0; iSeries < numberOfSeries; iSeries++){
            pacsDivisorArray[iSeries] = 0;
            for(int j = 0; j < gridWidth; j++){
                pacsDivisorArray[iSeries] = pacsDivisorArray[iSeries] + pacsGridArray[(iSeries*gridWidth)+j];
            }
        }
       
        // Do up to position maximumStep
        while(newDataIndex <= maximumStep){
            // This is the initial value of the new mid data,
            //it will be adjusted if required later
            bmidArray[newDataIndex] = bmidArray[newDataIndex-1] + (midArray[newDataIndex] - midArray[newDataIndex-1]) ;
            bremArray[newDataIndex] = midArray[newDataIndex] - bmidArray[newDataIndex];
            
            for(int iLookback = minimumStep; iLookback <= maximumStep; iLookback++){
                seriesIndex = iLookback - minimumStep;
                
                if(newDataIndex-iLookback<0 && dataOverlapIndex-iLookback >= 0 ){
                    midMove = (int)((midArray[newDataIndex] - oldMidArray[dataOverlapIndex-iLookback])/pipSize);
                    midAbsMove = labs(midMove);
                    moveSign = midMove == midAbsMove? 1: -1;
                    
//                    bmidMove = (int)((bmidArray[newDataIndex] - oldBmidArray[dataOverlapIndex-iLookback])/pipSize);
//                    bmidAbsMove = labs(bmidMove);
//                    bmoveSign = bmidMove == bmidAbsMove? 1: -1;
//                    
                    
                    
                }else{
                    midMove = (int)((midArray[newDataIndex] - midArray[newDataIndex-iLookback])/pipSize);
                    midAbsMove = labs(midMove);
                    moveSign = midMove == midAbsMove? 1: -1;
    
//                    bmidMove = (int)((bmidArray[newDataIndex] - bmidArray[newDataIndex-iLookback])/pipSize);
//                    bmidAbsMove = labs(bmidMove);
//                    bmoveSign = bmidMove == bmidAbsMove? 1: -1;
                }
                
                // Do the winsorising
                moveCount = 0;
                criticalMidMove = 0;
                while((double)moveCount/pacsDivisorArray[seriesIndex] < quantile && criticalMidMove < gridWidth){
                    moveCount = moveCount +  pacsGridArray[(seriesIndex*gridWidth)+criticalMidMove];
                    criticalMidMove++;
                }
                if(criticalMidMove>0)criticalMidMove--;
                
                pathSeriesTempHolderArray[seriesIndex][newDataIndex] = criticalMidMove;
                
                if((double)moveCount/pacsDivisorArray[seriesIndex] >= quantile)
                {
                    if(fabs(bmidArray[newDataIndex]-bmidArray[newDataIndex-iLookback])/pipSize > criticalMidMove){
                        bmidArray[newDataIndex] = bmidArray[newDataIndex-iLookback] + criticalMidMove*pipSize*moveSign;
                        //NSLog(@"Adjusting lookback %ld %@, %d from %ld to %ld", dateTimeArray[newDataIndex], [EpochTime stringDateWithTime:dateTimeArray[newDataIndex]], iLookback,midMove,criticalMidMove);
                        bremArray[newDataIndex] = midArray[newDataIndex] - bmidArray[newDataIndex];
                        //pacsGridUseArray[seriesIndex]++;
                    }
                }
                
                if(midAbsMove >= gridWidth){
                    //pacsSeriesTempHolderArray[seriesIndex][newDataIndex] = 1.0;
                    
                    //Expand the grid width
                    newGridWidth = gridWidth + MAX(20,midAbsMove-gridWidth+1);
                    newPacsGridData = [NSMutableData dataWithLength:sizeof(long) * numberOfSeries * newGridWidth];
                    newPacsGridArray = (long *)[newPacsGridData mutableBytes];
                    //Fill it in
                    for(int iSeries = 0; iSeries < numberOfSeries; iSeries++){
                        for(int iWidth = 0; iWidth < gridWidth; iWidth++){
                            newPacsGridArray[(iSeries*newGridWidth) + iWidth] = pacsGridArray[(iSeries*gridWidth) + iWidth];
                        }
                    }
                    //pacsGridData = newPacsGridData;
                    pacsGridArray = newPacsGridArray;
                    gridWidth = newGridWidth;
                }
                newPacsGridArray[(seriesIndex*gridWidth)+midAbsMove]++;
                ///else{
                //                    countOfSmallerMoves = 0;
                //                    for(int iLower = 0;iLower <midAbsMove; iLower++){
                //                        countOfSmallerMoves = countOfSmallerMoves +  pacsGridArray[(seriesIndex*gridWidth) + iLower];
                //                    }
                //                    if(pacsDivisorArray[seriesIndex] > 0){
                //                        pacsSeriesTempHolderArray[seriesIndex][newDataIndex] = (double)countOfSmallerMoves/pacsDivisorArray[seriesIndex];
                //
                //                    }else{
                //                        pacsSeriesTempHolderArray[seriesIndex][newDataIndex] = 0.0;
                //                    }
                 pacsDivisorArray[seriesIndex]++;
            }
            newDataIndex++;
        }
    }else{
        gridWidth = 20;
        pacsGridData = [NSMutableData dataWithLength:sizeof(long) * numberOfSeries * gridWidth];
        pacsGridArray = (long *)[pacsGridData mutableBytes];
        //pacsGridUseData = [NSMutableData dataWithLength:sizeof(long) * numberOfSeries];
        //pacsGridUseArray = (long *)[pacsGridUseData mutableBytes];
        
        for(newDataIndex = 0; newDataIndex < maximumStep; newDataIndex++){
            bmidArray[newDataIndex] = midArray[newDataIndex];
            bremArray[newDataIndex] = 0;
            if(newDataIndex >0){
                for(int iLookback = minimumStep; iLookback <= maximumStep; iLookback++){
                    seriesIndex = iLookback - minimumStep;
                    if(newDataIndex-iLookback >= 0){
                        midMove = (int)((midArray[newDataIndex] - midArray[newDataIndex-iLookback])/pipSize);
                        midAbsMove = labs(midMove);
                        if(midAbsMove >= gridWidth){
                            //pacsSeriesTempHolderArray[seriesIndex][newDataIndex] = 1.0;
                            
                            //Expand the grid width
                            newGridWidth = gridWidth + MAX(20,midAbsMove-gridWidth+1);
                            newPacsGridData = [NSMutableData dataWithLength:sizeof(long) * numberOfSeries * newGridWidth];
                            newPacsGridArray = (long *)[newPacsGridData mutableBytes];
                            //Fill it in
                            for(int iSeries = 0; iSeries < numberOfSeries; iSeries++){
                                for(int iWidth = 0; iWidth < gridWidth; iWidth++){
                                    newPacsGridArray[(iSeries*newGridWidth) + iWidth] = pacsGridArray[(iSeries*gridWidth) + iWidth];
                                }
                            }
                            pacsGridData = newPacsGridData;
                            pacsGridArray = newPacsGridArray;
                            gridWidth = newGridWidth;
                            pacsGridArray[(seriesIndex*gridWidth)+midAbsMove]++;
                        }else{
                            pacsGridArray[(seriesIndex*gridWidth)+midAbsMove]++;
                        }
                        pacsDivisorArray[seriesIndex]++;
                    }
                }
            }
        }
    }
             
    while(newDataIndex < dataLength){
        bmidArray[newDataIndex] = bmidArray[newDataIndex-1] + (midArray[newDataIndex] - midArray[newDataIndex-1]);
        bremArray[newDataIndex] = midArray[newDataIndex] - bmidArray[newDataIndex];
         
        for(int iLookback = minimumStep; iLookback <= maximumStep; iLookback++){
            seriesIndex = iLookback - minimumStep;
            
            midMove = (int)((midArray[newDataIndex] - midArray[newDataIndex-iLookback])/pipSize);
            midAbsMove = labs(midMove);
            moveSign = midMove == midAbsMove? 1: -1;
            
            if(newDataIndex > 100){
                // Do the winsorising
                moveCount = 0;
                criticalMidMove = 0;
                while((double)moveCount/pacsDivisorArray[seriesIndex] < quantile && criticalMidMove < gridWidth){
                    moveCount = moveCount +  pacsGridArray[(seriesIndex*gridWidth)+criticalMidMove];
                    criticalMidMove++;
                }
                if(criticalMidMove>0)criticalMidMove--;
                
                pathSeriesTempHolderArray[seriesIndex][newDataIndex] = criticalMidMove;
                
                if((double)moveCount/pacsDivisorArray[seriesIndex] >= quantile)
                {
                    if(fabs(bmidArray[newDataIndex]-bmidArray[newDataIndex-iLookback])/pipSize > criticalMidMove){
                        bmidArray[newDataIndex] = bmidArray[newDataIndex-iLookback] + criticalMidMove*pipSize*moveSign;
                        //NSLog(@"Adjusting lookback %ld %@, %d from %ld to %ld", dateTimeArray[newDataIndex], [EpochTime stringDateWithTime:dateTimeArray[newDataIndex]], iLookback,midMove,criticalMidMove);
                        bremArray[newDataIndex] = midArray[newDataIndex] - bmidArray[newDataIndex];
                        //pacsGridUseArray[seriesIndex]++;
                    }
                }
            }
            
            if(midAbsMove >= gridWidth){
                //pacsSeriesTempHolderArray[seriesIndex][newDataIndex] = 1.0;
                
                //Expand the grid width
                newGridWidth = gridWidth + MAX(20,midAbsMove-gridWidth+1);
                newPacsGridData = [NSMutableData dataWithLength:sizeof(long) * numberOfSeries * newGridWidth];
                newPacsGridArray = (long *)[newPacsGridData mutableBytes];
                //Fill it in
                for(int iSeries = 0; iSeries < numberOfSeries; iSeries++){
                    for(int iWidth = 0; iWidth < gridWidth; iWidth++){
                        newPacsGridArray[(iSeries*newGridWidth) + iWidth] = pacsGridArray[(iSeries*gridWidth) + iWidth];
                    }
                }
                pacsGridData = newPacsGridData;
                pacsGridArray = newPacsGridArray;
                gridWidth = newGridWidth;
                
            }
            //            else{
            //                countOfSmallerMoves = 0;
            //                for(int iLower = 0;iLower <midAbsMove; iLower++){
            //                    countOfSmallerMoves = countOfSmallerMoves +  pacsGridArray[(seriesIndex*gridWidth) + iLower];
            //                }
            //                if(pacsDivisorArray[seriesIndex]>0){
            //                    pacsSeriesTempHolderArray[seriesIndex][newDataIndex] = (double)countOfSmallerMoves/pacsDivisorArray[seriesIndex];
            //                }else{
            //                    pacsSeriesTempHolderArray[seriesIndex][newDataIndex] = 0.0;
            //                }
            //pacsGridArray[(seriesIndex*gridWidth)+midAbsMove]++;
            //            }
            pacsGridArray[(seriesIndex*gridWidth)+midAbsMove]++;
            pacsDivisorArray[seriesIndex]++;
        }
        newDataIndex++;
    }
//    [[signalSystem miscStoredInfoDictionary] setObject:pacsGridData forKey:@"PACSGRID"];
//    [[signalSystem miscStoredInfoDictionary] setObject:pacsGridUseData forKey:@"PACSGRIDUSE"];
//    [[signalSystem miscStoredInfoDictionary] setObject:[NSNumber numberWithLong:gridWidth]  forKey:@"PACSGRIDWIDTH"];
    
    for(int i = minimumStep; i <= maximumStep; i++){
        seriesIndex = i - minimumStep;
        //[returnData setObject:[pacsSeriesTempHolder objectAtIndex:seriesIndex] forKey:[pacsSeriesNames objectAtIndex:seriesIndex]];
        [returnData setObject:[pathSeriesTempHolder objectAtIndex:seriesIndex] forKey:[pathSeriesNames objectAtIndex:seriesIndex]];
    }
    [returnData setObject:bmidData
                   forKey:bmidString];
    [returnData setObject:bremData
                   forKey:bremString];
    [returnData setObject:[NSNumber numberWithBool:success]
                   forKey:@"SUCCESS"];

    return returnData;
}

+ (NSDictionary *) calcBUTForCode: (NSString *) butCode
                         WithData: (NSDictionary *) dataDictionary
                       AndOldData: (NSDictionary *) oldDataDictionary
{
    NSMutableDictionary *returnData = [[NSMutableDictionary alloc] init];
    NSMutableData *butData;
    NSString *baseSeriesString;
    
    double *butArray, parameter;
    NSArray *codeComponents = [butCode componentsSeparatedByString:@"/"];
    double butCodeParam;
    
    double numberOfPoles = 2.0;
    
    if([[codeComponents objectAtIndex:0] isEqualToString:@"BUT"] || [[codeComponents objectAtIndex:0] isEqualToString:@"BUT3"]){
        baseSeriesString = @"MID";
        butCodeParam = [[codeComponents objectAtIndex:1] doubleValue];
        
    }
    if([[codeComponents objectAtIndex:0] isEqualToString:@"BUT3"]){
        numberOfPoles = 3.0;
        
    }
    
    if([[codeComponents objectAtIndex:0] isEqualToString:@"BUTB"]){
        NSRange firstBracket = [butCode rangeOfString:@"/"];
        NSString *subString = [butCode substringFromIndex:firstBracket.location];
        NSRange lastBracket = [subString rangeOfString:@"/"
                                               options:NSBackwardsSearch];
        baseSeriesString = [NSString stringWithFormat:@"BMID%@",[subString substringToIndex:lastBracket.location]];
        butCodeParam = [[codeComponents objectAtIndex:4] intValue];
    }
    
    BOOL includeOldData = NO, success = YES;
    includeOldData = ![[oldDataDictionary objectForKey:@"ALLNEWDATA"] boolValue];
    
    int dataOverlapIndex;
    NSDictionary *trailingSeriesDictionary;
    long oldDataLength, dataLength, *oldDataTimeArray, *dateTimeArray;
    
    NSData *midData,  *dateTimeData, *oldDateTimeData, *oldButData;
    double *midArray, *oldButArray;
    
    midData = [dataDictionary objectForKey:baseSeriesString];
    dataLength = [midData length]/sizeof(double);
    midArray = (double *)[midData bytes];
    dateTimeData =  [dataDictionary objectForKey:@"DATETIME"];
    dateTimeArray = (long *)[dateTimeData bytes];
    
    parameter = [UtilityFunctions fib:butCodeParam];
    
    double a, b, c;
    
    
    double c1 = 0.0, c2 = 0.0, c3 = 0.0, c4 = 0.0;
    if(numberOfPoles < 2.5){
        a = exp(-sqrt(2.0)*M_PI/parameter);
        b = 2*a*cos(sqrt(2.0)*M_PI/parameter);
        c1 = (1-b+a*a)/4;
        c2 = b;
        c3 = -a*a;
    }
    
    if(numberOfPoles > 2.5 ){
        a = exp(-M_PI/parameter);
        b = 2*a*cos(sqrt(3.0)*M_PI/parameter);
        c = a*a;
        c1 = (1-b+c)*(1-c)/8;
        c2 = b+c;
        c3 = -(c+b*c);
        c4 = c * c;
    }
    
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
        
        butData = [[NSMutableData alloc] initWithLength:dataLength * sizeof(double)];
        butArray = [butData mutableBytes];
        
        if(includeOldData){
            oldButData = [trailingSeriesDictionary objectForKey:butCode];
            oldButArray = (double *)[oldButData bytes];
            
            for(long i = dataOverlapIndex ; i <= oldDataLength; i++){
                butArray[i-dataOverlapIndex] = oldButArray[i];
            }
            for(long i = oldDataLength - dataOverlapIndex; i < dataLength; i++){
                if(numberOfPoles < 2.5){
                    butArray[i] = c1*(midArray[i] + 2*midArray[i-1] + midArray[i-2]) + c2 * butArray[i-1] +c3*butArray[i-2];
                }
                if(numberOfPoles > 2.5){
                    butArray[i] = c1*(midArray[i]+3*midArray[i-1]+3*midArray[i-2]+midArray[i-3])+c2*butArray[i-1]+c3*butArray[i-2]+c4*butArray[i-3];
                }
            }
            [returnData setObject:butData forKey:butCode];
        }else{
            butArray[0] = midArray[0];
            butArray[1] = midArray[1];
            butArray[2] = midArray[2];
            for(int i = 3; i < dataLength; i++){
                if(numberOfPoles < 2.5){
                    butArray[i] = c1*(midArray[i] + 2*midArray[i-1] + midArray[i-2]) + c2 * butArray[i-1] +c3*butArray[i-2];
                }
                if(numberOfPoles > 2.5){
                    butArray[i] = c1*(midArray[i]+3*midArray[i-1]+3*midArray[i-2]+midArray[i-3])+c2*butArray[i-1]+c3*butArray[i-2]+c4*butArray[i-3];
                }
            }
            [returnData setObject:butData forKey:butCode];
            
        }
    }
    
    if(success){
        [returnData setObject:[NSNumber numberWithBool:YES] forKey:@"SUCCESS"];
    }else{
        [returnData setObject:[NSNumber numberWithBool:NO] forKey:@"SUCCESS"];
        
    }
    
    return returnData;
}



//+ (NSDictionary *) calcFRAMAForCode: (NSString *) seriesCode
//                            WithData: (NSDictionary *) dataDictionary
//                          AndOldData: (NSDictionary *) oldDataDictionary
//{
//    NSArray *codeComponents = [seriesCode componentsSeparatedByString:@"/"];
//    int daysForAveraging = [[codeComponents objectAtIndex:1] intValue];
//
//    NSMutableData  *lastDateTimeForDayData, *closeForDayData, *highForDayData, *lowForDayData, *atrForDayData;
//    NSMutableDictionary *returnData = [[NSMutableDictionary alloc] init];
//
//    long *lastDateTimeForDayArray;
//
//    double  *closeForDayArray, *highForDayArray, *lowForDayArray, *atrForDayArray;
//    
//    BOOL includeOldData = NO, success = YES;
//    includeOldData = ![[oldDataDictionary objectForKey:@"ALLNEWDATA"] boolValue];
//    
//    int dataOverlapIndex;
//    NSDictionary *trailingSeriesDictionary;
//    long oldDataLength, dataLength, *oldDataTimeArray, *dateTimeArray;
//    
//    NSData *midData,  *dateTimeData, *oldDateTimeData;
//    double *midArray;
//    
//    midData = [dataDictionary objectForKey:@"MID"];
//    dataLength = [midData length]/sizeof(double);
//    midArray = (double *)[midData bytes];
//    dateTimeData =  [dataDictionary objectForKey:@"DATETIME"];
//    dateTimeArray = (long *)[dateTimeData bytes];
//    
//    if(includeOldData){
//        if([oldDataDictionary objectForKey:@"OLDDATA"] == nil || [oldDataDictionary objectForKey: @"OVERLAPINDEX"] == nil || [oldDataDictionary objectForKey:@"OLDDATETIME"] == nil){
//            success = NO;
//        }else{
//            trailingSeriesDictionary = [oldDataDictionary objectForKey:@"OLDDATA"];
//            dataOverlapIndex = [[oldDataDictionary objectForKey:@"OVERLAPINDEX"] intValue];
//            oldDateTimeData = [oldDataDictionary objectForKey:@"OLDDATETIME"];
//            oldDataTimeArray = (long *) [oldDateTimeData bytes];
//            oldDataLength = [oldDateTimeData length]/sizeof(long);
//            
//            for(long i = dataOverlapIndex ; i < oldDataLength; i++){
//                if(dateTimeArray[i-dataOverlapIndex] != oldDataTimeArray[i]){
//                    success = NO;
//                    NSLog(@"Problem with overlapping periods, times don't match");
//                }
//            }
//        }
//    }
//    if(success){
//        if(includeOldData){
//            NSData *oldMidData = [trailingSeriesDictionary objectForKey:@"MID"];
//            double *oldMidArray = (double *)[oldMidData bytes];
//            NSData *oldAtrData = [trailingSeriesDictionary objectForKey:seriesCode];
//            double *oldAtrArray = (double *)[oldAtrData bytes];
//            
//            long dataIndex = 0, dayNumber;
//            //Go forward to the first weekday
//            while(dataIndex < dataLength && ![EpochTime isWeekday:dateTimeArray[dataIndex]])
//                dataIndex++;
//            
//            if(dataIndex < dataLength){
//                dayNumber = [EpochTime daysSinceEpoch:dateTimeArray[dataIndex]];
//                
//                //Go backwards to include at least 1 weekday days
//                int dayCount = 0;
//                dataIndex = oldDataLength;
//                while((dayCount < 3) && (dataIndex > 0)){
//                    dataIndex--;
//                    if([EpochTime isWeekday:oldDataTimeArray[dataIndex]] &&
//                       ([EpochTime daysSinceEpoch:oldDataTimeArray[dataIndex]] != [EpochTime daysSinceEpoch:oldDataTimeArray[dataIndex+1]])){
//                        dayCount++;
//                    }
//                }
//                dataIndex++;
//                
//                // This is the number of days for which we do calculations. It coveres all the new data, plus at least 1 weekday of old
//                int maxNumberOfDays = [EpochTime daysSinceEpoch:dateTimeArray[dataLength-1]] - [EpochTime daysSinceEpoch:oldDataTimeArray[dataIndex]] + 1;
//                
//                lastDateTimeForDayData = [NSMutableData dataWithLength:sizeof(long) * maxNumberOfDays];
//                closeForDayData = [NSMutableData dataWithLength:sizeof(double) * maxNumberOfDays];
//                highForDayData = [NSMutableData dataWithLength:sizeof(double) * maxNumberOfDays];
//                lowForDayData = [NSMutableData dataWithLength:sizeof(double) * maxNumberOfDays];
//                atrForDayData = [NSMutableData dataWithLength:sizeof(double) * maxNumberOfDays];
//                
//                lastDateTimeForDayArray = (long *)[lastDateTimeForDayData mutableBytes];
//                closeForDayArray = (double *)[closeForDayData mutableBytes];
//                highForDayArray = (double *)[highForDayData mutableBytes];
//                lowForDayArray = (double *)[lowForDayData mutableBytes];
//                atrForDayArray = (double *)[atrForDayData mutableBytes];
//                
//                int dayDataIndex = 0;
//                if(dataIndex < oldDataLength){
//                    lastDateTimeForDayArray[dayDataIndex] = oldDataTimeArray[dataIndex];
//                    closeForDayArray[dayDataIndex] = oldMidArray[dataIndex];
//                    highForDayArray[dayDataIndex] = oldMidArray[dataIndex];
//                    lowForDayArray[dayDataIndex] = oldMidArray[dataIndex];
//                    atrForDayArray[dayDataIndex] = oldAtrArray[dataIndex];
//                    
//                    dayNumber =  [EpochTime daysSinceEpoch:oldDataTimeArray[dataIndex]];
//                    while(dataIndex < oldDataLength){
//                        if([EpochTime daysSinceEpoch:oldDataTimeArray[dataIndex]] != dayNumber){
//                            dayNumber =  [EpochTime daysSinceEpoch:oldDataTimeArray[dataIndex]];
//                            //                                    double trueRange  = MAX(highForDayArray[dayDataIndex]-lowForDayArray[dayDataIndex],MAX(highForDayArray[dayDataIndex]-closeForDayArray[dayDataIndex-1],closeForDayArray[dayDataIndex-1])-lowForDayArray[dayDataIndex]);
//                            //
//                            //                                    atrForDayArray[dayDataIndex] = ((daysForAveraging - 1) * atrForDayArray[dayDataIndex-1] + trueRange)/ daysForAveraging;
//                            dayDataIndex++;
//                            highForDayArray[dayDataIndex] = oldMidArray[dataIndex];
//                            lowForDayArray[dayDataIndex] = oldMidArray[dataIndex];
//                            atrForDayArray[dayDataIndex] = oldAtrArray[dataIndex];
//                        }else{
//                            highForDayArray[dayDataIndex] = MAX(highForDayArray[dayDataIndex], oldMidArray[dataIndex]);
//                            lowForDayArray[dayDataIndex] = MIN(lowForDayArray[dayDataIndex], oldMidArray[dataIndex]);
//                        }
//                        lastDateTimeForDayArray[dayDataIndex] = oldDataTimeArray[dataIndex];
//                        closeForDayArray[dayDataIndex] = oldMidArray[dataIndex];
//                        
//                        dataIndex++;
//                        
//                    }
//                }
//                
//                dataIndex = 0;
//                while(dataIndex < dataLength){
//                    if([EpochTime daysSinceEpoch:dateTimeArray[dataIndex]] != dayNumber){
//                        double trueRange  = MAX(highForDayArray[dayDataIndex]-lowForDayArray[dayDataIndex],MAX(highForDayArray[dayDataIndex]-closeForDayArray[dayDataIndex-1],closeForDayArray[dayDataIndex-1])-lowForDayArray[dayDataIndex]);
//                        
//                        atrForDayArray[dayDataIndex] = ((daysForAveraging - 1) * atrForDayArray[dayDataIndex-1] + trueRange)/ daysForAveraging;
//                        dayDataIndex++;
//                        highForDayArray[dayDataIndex] = midArray[dataIndex];
//                        lowForDayArray[dayDataIndex] = midArray[dataIndex];
//                        dayNumber = [EpochTime daysSinceEpoch:dateTimeArray[dataIndex]];
//                    }else{
//                        highForDayArray[dayDataIndex] = MAX(highForDayArray[dayDataIndex], midArray[dataIndex]);
//                        lowForDayArray[dayDataIndex] = MIN(lowForDayArray[dayDataIndex], midArray[dataIndex]);
//                    }
//                    closeForDayArray[dayDataIndex] = midArray[dataIndex];
//                    lastDateTimeForDayArray[dayDataIndex] = dateTimeArray[dataIndex];
//                    dataIndex++;
//                }
//            }else{
//                success = NO;
//            }
//        }else{
//            int maxNumberOfDays = [EpochTime daysSinceEpoch:dateTimeArray[dataLength-1]] - [EpochTime daysSinceEpoch:dateTimeArray[0]]+ 1;
//            
//            lastDateTimeForDayData = [NSMutableData dataWithLength:sizeof(long) * maxNumberOfDays];
//            closeForDayData = [NSMutableData dataWithLength:sizeof(double) * maxNumberOfDays];
//            highForDayData = [NSMutableData dataWithLength:sizeof(double) * maxNumberOfDays];
//            lowForDayData = [NSMutableData dataWithLength:sizeof(double) * maxNumberOfDays];
//            atrForDayData = [NSMutableData dataWithLength:sizeof(double) * maxNumberOfDays];
//            
//            lastDateTimeForDayArray = (long *)[lastDateTimeForDayData mutableBytes];
//            closeForDayArray = (double *)[closeForDayData mutableBytes];
//            highForDayArray = (double *)[highForDayData mutableBytes];
//            lowForDayArray = (double *)[lowForDayData mutableBytes];
//            atrForDayArray = (double *)[atrForDayData mutableBytes];
//            
//            long dataIndex = 0;
//            int dayDataIndex = 0;
//            int dayNumber;
//            double trueRange;
//            dayNumber = [EpochTime daysSinceEpoch:dateTimeArray[dataIndex]];
//            
//            // Put in initial values
//            highForDayArray[dayDataIndex] = midArray[dataIndex];
//            lowForDayArray[dayDataIndex] = midArray[dataIndex];
//            closeForDayArray[dayDataIndex] = midArray[dataIndex];
//            lastDateTimeForDayArray[dayDataIndex] = dateTimeArray[dataIndex];
//            
//            while(dataIndex < dataLength){
//                if([EpochTime daysSinceEpoch:dateTimeArray[dataIndex]] != dayNumber){
//                    dayNumber =  [EpochTime daysSinceEpoch:dateTimeArray[dataIndex]];
//                    
//                    if(dayDataIndex == 0){
//                        atrForDayArray[dayDataIndex] =  highForDayArray[dayDataIndex]-lowForDayArray[dayDataIndex];
//                    }
//                    if(dayDataIndex > 0 && dayDataIndex < (daysForAveraging - 1) ){
//                        atrForDayArray[dayDataIndex] =  MAX(highForDayArray[dayDataIndex]-lowForDayArray[dayDataIndex],MAX(highForDayArray[dayDataIndex]-closeForDayArray[dayDataIndex-1],closeForDayArray[dayDataIndex-1]-lowForDayArray[dayDataIndex]));
//                    }
//                    
//                    if(dayDataIndex == daysForAveraging - 1){
//                        trueRange = 0.0;
//                        for(int i = 0; i < daysForAveraging; i++){
//                            trueRange = trueRange + atrForDayArray[i];
//                            atrForDayArray[i] = 0.0;
//                        }
//                        atrForDayArray[dayDataIndex] =  trueRange/daysForAveraging;
//                    }
//                    
//                    if(dayDataIndex > daysForAveraging - 1){
//                        trueRange  = MAX(highForDayArray[dayDataIndex]-lowForDayArray[dayDataIndex],MAX(highForDayArray[dayDataIndex]-closeForDayArray[dayDataIndex-1],closeForDayArray[dayDataIndex-1]-lowForDayArray[dayDataIndex]));
//                        atrForDayArray[dayDataIndex] = ((daysForAveraging - 1) * atrForDayArray[dayDataIndex-1] + trueRange)/ daysForAveraging;
//                    }
//                    dayDataIndex++;
//                    highForDayArray[dayDataIndex] = midArray[dataIndex];
//                    lowForDayArray[dayDataIndex] = midArray[dataIndex];
//                    
//                }else{
//                    highForDayArray[dayDataIndex] = MAX(highForDayArray[dayDataIndex], midArray[dataIndex]);
//                    lowForDayArray[dayDataIndex] = MIN(lowForDayArray[dayDataIndex], midArray[dataIndex]);
//                }
//                closeForDayArray[dayDataIndex] = midArray[dataIndex];
//                lastDateTimeForDayArray[dayDataIndex] = dateTimeArray[dataIndex];
//                
//                dataIndex++;
//            }
//            // Last days ATR
//            trueRange  = MAX(highForDayArray[dayDataIndex]-lowForDayArray[dayDataIndex],MAX(highForDayArray[dayDataIndex]-closeForDayArray[dayDataIndex],closeForDayArray[dayDataIndex]-lowForDayArray[dayDataIndex]));
//            atrForDayArray[dayDataIndex] = ((daysForAveraging - 1) * atrForDayArray[dayDataIndex-1] + trueRange)/ daysForAveraging;
//        }
//        
//        NSMutableData *atrData = [[NSMutableData alloc] initWithLength:dataLength * sizeof(double)];
//        double *atrArray = [atrData mutableBytes];
//        NSMutableData *highData = [[NSMutableData alloc] initWithLength:dataLength * sizeof(double)];
//        double *highArray = [highData mutableBytes];
//        NSMutableData *lowData = [[NSMutableData alloc] initWithLength:dataLength * sizeof(double)];
//        double *lowArray = [lowData mutableBytes];
//        NSMutableData *closeData = [[NSMutableData alloc] initWithLength:dataLength * sizeof(double)];
//        double *closeArray = [closeData mutableBytes];
//        
//        int indexByDay  = 0;
//        while([EpochTime daysSinceEpoch:dateTimeArray[0]] > [EpochTime daysSinceEpoch:lastDateTimeForDayArray[indexByDay]]){
//            indexByDay++;
//        }
//        
//        for(int i = 0; i < dataLength; i++){
//            while([EpochTime daysSinceEpoch:dateTimeArray[i]] > [EpochTime daysSinceEpoch:lastDateTimeForDayArray[indexByDay]]){
//                indexByDay++;
//            }
//            
//            atrArray[i] = atrForDayArray[indexByDay];
//            highArray[i] = highForDayArray[indexByDay];
//            lowArray[i] = lowForDayArray[indexByDay];
//            closeArray[i] = closeForDayArray[indexByDay];
//        }
//        [returnData setObject:atrData forKey:seriesCode];
//        [returnData setObject:closeData forKey:@"CLOSE"];
//        [returnData setObject:highData forKey:@"HIGH"];
//        [returnData setObject:lowData forKey:@"LOW"];
//    }
//    
//    if(success){
//        [returnData setObject:[NSNumber numberWithBool:YES] forKey:@"SUCCESS"];
//    }else{
//        [returnData setObject:[NSNumber numberWithBool:NO] forKey:@"SUCCESS"];
//        
//    }
//    return returnData;
//    
//    
//}


//+ (NSDictionary *) calcEmadForCode: (NSString *) emadCode
//                          WithData: (NSDictionary *) dataDictionary
//                        AndOldData: (NSDictionary *) oldDataDictionary
//                       AndDoPickup: (BOOL) doPickup
//                     WithThreshold: (double) threshold
//{
//    NSData *emaData;
//    double *emaArray;
//    int dataLength;
//    
//    NSMutableDictionary *returnData = [[NSMutableDictionary alloc] init];
//    
//    NSArray *emadComponents = [emadCode componentsSeparatedByString:@"/"];
//    int emaCode = [[emadComponents objectAtIndex:1] intValue];
//    int smoothCode = [[emadComponents objectAtIndex:2] intValue];
//    NSMutableData *emadPickupData, *midData;
//    double *emadPickupArray, *midArray;
//    
//    NSString *emaString = [NSString stringWithFormat:@"EMA/%d",emaCode];
//    NSString *emadString = [NSString stringWithFormat:@"EMAD/%d/%d",emaCode,smoothCode];
//    NSString *emadPickupString;
//    if(doPickup){
//        emadPickupString = [NSString stringWithFormat:@"EDPU/%d/%d",emaCode,smoothCode];
//    }
//    
//    
//    //NSArray *dataKeys = [dataDictionary allKeys];
//    
//    BOOL requiredDataFound = NO;
//    if([dataDictionary objectForKey:emaString] != nil){
//        requiredDataFound = YES;
//        emaData = [dataDictionary objectForKey:emaString];
//        emaArray = (double *)[emaData bytes];
//        dataLength = [emaData length]/sizeof(double);
//    }
//    if(requiredDataFound){
//        if(doPickup){
//            if([dataDictionary objectForKey:@"MID"] != nil){
//                requiredDataFound = YES;
//                midData = [dataDictionary objectForKey:@"MID"];
//                midArray = (double *)[midData bytes];
//            }else{
//                requiredDataFound = NO;
//            }
//        }
//    }
//    
//    if(requiredDataFound){
//        BOOL includeOldData = NO;
//        includeOldData = ![[oldDataDictionary objectForKey:@"ALLNEWDATA"] boolValue];
//        
//        NSMutableData *emadData = [[NSMutableData alloc] initWithLength:dataLength * sizeof(double)];
//        double *emadArray = (double *)[emadData mutableBytes];
//        
//        
//        if(doPickup){
//            emadPickupData = [[NSMutableData alloc] initWithLength:dataLength * sizeof(double)];
//            emadPickupArray = (double *)[emadPickupData mutableBytes];
//        }
//        
//        long lagLengthForDelta = [UtilityFunctions fib:(smoothCode)];
//        
//        if(includeOldData){
//            int dataOverlapIndex;
//            NSDictionary *trailingSeriesDictionary;
//            long oldDataLength;
//            
//            trailingSeriesDictionary = [oldDataDictionary objectForKey:@"OLDDATA"];
//            dataOverlapIndex = [[oldDataDictionary objectForKey:@"OVERLAPINDEX"] intValue];
//            
//            NSData *oldEmaData = [trailingSeriesDictionary objectForKey:emaString];
//            double *oldEmaArray = (double *)[oldEmaData bytes];
//            NSData *oldEmadData = [trailingSeriesDictionary objectForKey:emadString];
//            double *oldEmadArray = (double *)[oldEmadData bytes];
//            
//            
//            NSData *oldEmadPickupData;
//            double *oldEmadPickupArray;
//            if(doPickup){
//                oldEmadPickupData = [trailingSeriesDictionary objectForKey:emadPickupString];
//                oldEmadPickupArray = (double *)[oldEmadPickupData bytes];
//            }
//            
//            long lagIndexForOldData = -1;
//            
//            oldDataLength = [oldEmadData length]/sizeof(long);
//            
//            for(long i = dataOverlapIndex ; i < oldDataLength; i++){
//                emadArray[i-dataOverlapIndex] = oldEmadArray[i];
//                if(doPickup){
//                    emadPickupArray[i-dataOverlapIndex] = oldEmadPickupArray[i];
//                }
//            }
//            
//            lagIndexForOldData = oldDataLength - lagLengthForDelta;
//            
//            for(long i = oldDataLength - dataOverlapIndex; i < dataLength; i++){
//                if(i - lagLengthForDelta >= 0){
//                    emadArray[i] = emaArray[i] - emaArray[i- lagLengthForDelta];
//                }else{
//                    if(lagIndexForOldData > -1 && lagIndexForOldData < oldDataLength){
//                        emadArray[i] = emaArray[i] - oldEmaArray[lagIndexForOldData];
//                    }else{
//                        emadArray[i] = 0.0;
//                    }
//                    lagIndexForOldData++;
//                }
//                if(doPickup){
//                    //ignore hte case when i == 0, it should be taken care of by calulation overlap and doesn't matter much anyway for tick data
//                    if(i > 0){
//                        if((emadArray[i-1] >= threshold) ){
//                            emadPickupArray[i] = emadPickupArray[i-1] + midArray[i] - midArray[i-1] ;
//                        }else if (emadArray[i-1] <= -threshold)
//                        {
//                            emadPickupArray[i] = emadPickupArray[i-1]  + midArray[i-1] - midArray[i];
//                        }else{
//                            emadPickupArray[i] = emadPickupArray[i-1];
//                        }
//                    }
//                }
//            }
//        }else{
//            for(int i = 0; i < dataLength; i++){
//                if(i - lagLengthForDelta >= 0){
//                    emadArray[i] = emaArray[i] - emaArray[i- lagLengthForDelta];
//                    if(doPickup){
//                        if(i > 0){
//                            if((emadArray[i-1] >= threshold) ){
//                                emadPickupArray[i] = emadPickupArray[i-1] + midArray[i] - midArray[i-1] ;
//                            }else if (emadArray[i-1] <= -threshold)
//                            {
//                                emadPickupArray[i] = emadPickupArray[i-1]  + midArray[i-1] - midArray[i];
//                            }else{
//                                emadPickupArray[i] = emadPickupArray[i-1];
//                            }
//                        }
//                    }
//                }
//            }
//        }
//        [returnData setObject:emadData
//                       forKey:emadString];
//        if(doPickup){
//            [returnData setObject:emadPickupData
//                           forKey:emadPickupString];
//        }
//        [returnData setObject:[NSNumber numberWithBool:YES]
//                       forKey:@"SUCCESS"];
//    }else{
//        [returnData setObject:[NSNumber numberWithBool:NO]
//                       forKey:@"SUCCESS"];
//    }
//    return returnData;
//}


@end




