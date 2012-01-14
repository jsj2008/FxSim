//
//  DataIO.h
//  Simple Sim
//
//  Created by O'Connor Martin on 22/12/2011.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
@class DataSeries;

@interface DataIO : NSObject{
    BOOL connected;
}
@property(readonly, assign) BOOL connected;

-(id)init;
-(NSArray *)getListofPairs;
-(NSArray *)getListofDataTypes;
-(long *)getDateRangeForSeries:(NSInteger) seriesId;
-(DataSeries *)getDataSeriesForId: (int) dbid AndType: (int) dataTypeId AndStartTime: (long) startTime AndEndTime: (long) endTime;
//-(DataSeries *)getDataSeriesForId: (int) dbid AndType: (int) dataTypeId AndStartTime: (long) startTime AndEndTime: (long) endTime AndGranularity: (int) inSeconds;


@end
