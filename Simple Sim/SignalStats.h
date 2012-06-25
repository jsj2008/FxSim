//
//  SignalStats.h
//  Simple Sim
//
//  Created by Martin O'Connor on 14/05/2012.
//  Copyright (c) 2012 OCONNOR RESEARCH. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SignalStats : NSObject
@property (readonly) double signal;
@property (readonly) long startTime;
@property (readonly) long endTime;
@property (readonly) double entryPrice;
@property (readonly) double exitPrice;
@property (readonly) long samplesInProfit;
@property (readonly) long totalSamples;
@property (readonly) double maxPrice;
@property (readonly) double minPrice;
//if the statistic is not completed to exit
//endtime will be zero and the last sample's time
//should be in update time
@property (readonly) long updateTime;

- (id) init;

- (id) initWithSignal: (double) sigSignal
         AndStartTime: (long)   sigStartTime
           AndEndTime: (long)   sigEndTime
        AndEntryPrice: (double) sigEntryPrice
         AndExitPrice: (double) sigExitPrice
   AndSamplesInProfit: (long)   sigSamplesInProfit
      AndTotalSamples: (long)   sigTotalSamples
          AndMaxPrice: (double) sigMaxPrice
          AndMinPrice: (double) sigMinPrice;

- (id) initWithSignal: (double) sigSignal
         AndStartTime: (long)   sigStartTime
        AndUpdateTime: (long)   lastUpdateTime
        AndEntryPrice: (double) sigEntryPrice
       AndLatestPrice: (double) sigLatestPrice
   AndSamplesInProfit: (long)   sigSamplesInProfit
      AndTotalSamples: (long)   sigTotalSamples
          AndMaxPrice: (double) sigMaxPrice
          AndMinPrice: (double) sigMinPrice;

- (NSString *)description;
- (id) getStat:(NSString *)identifier;
- (double) getStatAsDouble:(NSString *)identifier;
- (long) getStartDateTime;
- (long) getEndDateTime;

@end
