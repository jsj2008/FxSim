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
}
@property(readonly, assign) BOOL connected;

-(id)init;
-(NSArray *)getListofPairs;
-(NSArray *)getListofDataTypes;

-(long *)getDateRangeForSeries:(NSInteger) seriesId;

-(DataSeries *)getDataSeriesForId: (int) dbid AndType: (int) dataTypeId AndStartTime: (long) startTime AndEndTime: (long) endTime;

-(BOOL) addDataSeriesTo: (DataSeries *) dataSeries ForType: (int) dataTypeId;

//-(DataSeries *)getBidAskSeriesForId: (int) dbid AndDay:(NSDate *) day;
-(DataSeries *)getBidAskSeriesForId: (int) dbid AndDay:(NSDate *) day ToSampledSeconds:(int) numberOfSeconds;
-(void)addMidToBidAskSeries: (DataSeries *) dataSeries;
-(void)addEWMAToSeries:(DataSeries *) dataSeries WithParam: (int) param;

@end
