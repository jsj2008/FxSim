//
//  DataController.h
//  Simple Sim
//
//  Created by Martin O'Connor on 14/01/2012.
//  Copyright (c) 2012 OCR. All rights reserved.
//

#import <Foundation/Foundation.h>
@class DataSeries;


@interface DataController : NSObject{
    BOOL connected;
    NSMutableDictionary *dataSeriesKeeper;
}
@property(readonly, assign) BOOL connected;

-(id)init;
-(NSArray *)getListofPairs;
-(NSArray *)getListofDataTypes;

-(long *)getDateRangeForSeries:(NSInteger) seriesId;

-(DataSeries *)getDataSeriesForId: (int) dbid 
                          AndType: (int) dataTypeId 
                     AndStartTime: (long) startTime 
                       AndEndTime: (long) endTime;

-(BOOL) addDataSeriesTo: (DataSeries *) dataSeries 
                ForType: (int) dataTypeId;

-(DataSeries *)getBidAskAndStuffForId: (int) dbid 
                         AndStartTime: (long) startTime 
                           AndEndTime: (long) endTime 
                     ToSampledSeconds:(int) numberOfSeconds;

-(DataSeries *)getBidAskSeriesForId: (int) dbid 
                         AndStartTime: (long) startTime 
                           AndEndTime: (long) endTime 
                     ToSampledSeconds:(int) numberOfSeconds;



//-(DataSeries *)getDataSeriesForId: (int) dbid  
//                          AndType: (int) dataTypeId 
//                     AndStartTime: (long) startTime 
//                       AndEndTime: (long) endTime 
//                 ToSampledSeconds: (int) numberOfSeconds;

-(void)addMidToBidAskSeries: (DataSeries *) dataSeries;
-(void)addEWMAToSeries:(DataSeries *) dataSeries WithParam: (int) param;

@end
