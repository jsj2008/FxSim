//
//  SignalStats.m
//  Simple Sim
//
//  Created by Martin O'Connor on 14/05/2012.
//  Copyright (c) 2012 OCONNOR RESEARCH. All rights reserved.
//

#import "SignalStats.h"
#import "EpochTime.h"

@implementation SignalStats

@synthesize signal;
@synthesize startTime;
@synthesize endTime;
@synthesize entryPrice;
@synthesize exitPrice;
@synthesize samplesInProfit;
@synthesize totalSamples;
@synthesize maxPrice;
@synthesize minPrice;
@synthesize updateTime;

-(id)init
{
    self = [super init];
    if(self){
        signal = 0;
        startTime = 0;
        endTime = 0;
        entryPrice = 0.0;
        exitPrice = 0.0;
        samplesInProfit = 0;
        totalSamples = 0;
        maxPrice = 0.0;
        minPrice = 0.0;
        updateTime = 0;
    }
    return self;
}

- (id) initWithSignal: (double) sigSignal
         AndStartTime: (long) sigStartTime
           AndEndTime: (long) sigEndTime
        AndEntryPrice: (double) sigEntryPrice
         AndExitPrice: (double) sigExitPrice
   AndSamplesInProfit: (long) sigSamplesInProfit
      AndTotalSamples: (long) sigTotalSamples
          AndMaxPrice: (double) sigMaxPrice
          AndMinPrice: (double) sigMinPrice
{
    self = [super init];
    if(self){
        signal = sigSignal;
        startTime = sigStartTime;
        endTime = sigEndTime;
        entryPrice = sigEntryPrice;
        exitPrice = sigExitPrice;
        samplesInProfit = sigSamplesInProfit;
        totalSamples = sigTotalSamples;
        maxPrice = sigMaxPrice;
        minPrice = sigMinPrice;
        updateTime = 0;
    }
    return self;
}
//
//- (id) initWithSignal: (double) sigSignal
//         AndStartTime: (long)sigStartTime
//        AndUpdateTime: (long) lastUpdateTime
//        AndEntryPrice: (double) sigEntryPrice
//       AndLatestPrice: (double) sigLatestPrice
//   AndSamplesInProfit: (long) sigSamplesInProfit
//      AndTotalSamples: (long) sigTotalSamples
//          AndMaxPrice: (double) sigMaxPrice
//          AndMinPrice: (double) sigMinPrice
//{
//    self = [super init];
//    if(self){
//        signal = sigSignal;
//        startTime = sigStartTime;
//        updateTime = lastUpdateTime;
//        entryPrice = sigEntryPrice;
//        exitPrice = sigLatestPrice;
//        samplesInProfit = sigSamplesInProfit;
//        totalSamples = sigTotalSamples;
//        maxPrice = sigMaxPrice;
//        minPrice = sigMinPrice;
//        endTime = 0;
//    }
//    return self;
//}

- (NSString *)description
{
    NSString *description;
    description = [NSString stringWithFormat:@"Signal       :%5.2f\n",signal]; 
    description = [NSString stringWithFormat:@"%@Start      :%@\n",description, [EpochTime stringDateWithTime:[self startTime]]];
    if(endTime !=0){
    description = [NSString stringWithFormat:@"%@End        :%@\n",description, [EpochTime stringDateWithTime:[self endTime]]];
    }else{
    description = [NSString stringWithFormat:@"%@Last update:%@\n",description, [EpochTime stringDateWithTime:[self updateTime]]];    
    }
    return description;
}

- (id) getStat:(NSString *)identifier{
    double pnl;
    if([identifier isEqualToString:@"ENTRYTIME"]){
        return [EpochTime stringDateWithTime:startTime];
    }
    if([identifier isEqualToString:@"EXITTIME"]){
        if(endTime == 0){
            return [EpochTime stringDateWithTime:updateTime];
        }else{
            return [EpochTime stringDateWithTime:endTime];
        }
    }
    if([identifier isEqualToString:@"SIGNAL"]){
        return [NSNumber numberWithDouble:signal];
    }
    if([identifier isEqualToString:@"ENTRYPRICE"]){
        return [NSNumber numberWithDouble:entryPrice];
    }
    if([identifier isEqualToString: @"EXITPRICE"]){
        return [NSNumber numberWithDouble:exitPrice];
    }
    if([identifier isEqualToString:@"SIGNAL GAIN"]){
        pnl = 0.0;
        if(signal > 0){
            pnl = (exitPrice/entryPrice)-1; 
        }
        if(signal < 0){
            pnl = (entryPrice/exitPrice)-1; 
        }
        return [NSNumber numberWithDouble:pnl];    
    }
    if([identifier isEqualToString:@"UPTIME"]){
        return [NSNumber numberWithDouble:(double)samplesInProfit/totalSamples];
    }
    if([identifier isEqualToString:@"POTLOSS"]){
        pnl = 0.0;
        if(signal > 0){
            pnl = (minPrice/entryPrice)-1;
        }
        if(signal < 0){
            pnl = (maxPrice/entryPrice)-1; 
        }
        return [NSNumber numberWithDouble:pnl];    
    }
    if([identifier isEqualToString:@"POTGAIN"]){
        pnl = 0.0;
        if(signal > 0){
            pnl = (maxPrice/entryPrice)-1;
        }
        if(signal < 0){
            pnl = (minPrice/entryPrice)-1; 
        }
        return [NSNumber numberWithDouble:pnl];
    }
    return nil;
}

- (double) getStatAsDouble:(NSString *)identifier{
    double pnl;
    if([identifier isEqualToString:@"ENTRYTIME"]){
        return (double)startTime;
    }
    if([identifier isEqualToString:@"EXITTIME"]){
        return (double)endTime;
    }
    if([identifier isEqualToString:@"SIGNAL"]){
        return signal;
    }
    if([identifier isEqualToString:@"ENTRYPRICE"]){
        return entryPrice;
    }
    if([identifier isEqualToString: @"EXITPRICE"]){
        return exitPrice;
    }
    if([identifier isEqualToString:@"SIGNAL GAIN"]){
        pnl = 0.0;
        if(signal > 0){
            pnl = (exitPrice/entryPrice)-1; 
        }
        if(signal < 0){
            pnl = (entryPrice/exitPrice)-1; 
        }
        return pnl;    
    }
    if([identifier isEqualToString:@"UPTIME"]){
        return (double)samplesInProfit/totalSamples;
    }
    if([identifier isEqualToString:@"POTLOSS"]){
        pnl = 0.0;
        if(signal > 0){
            pnl = (minPrice/entryPrice)-1;
        }
        if(signal < 0){
            pnl = (maxPrice/entryPrice)-1; 
        }
        return pnl;    
    }
    if([identifier isEqualToString:@"POTGAIN"]){
        pnl = 0.0;
        if(signal > 0){
            pnl = (maxPrice/entryPrice)-1;
        }
        if(signal < 0){
            pnl = (minPrice/entryPrice)-1; 
        }
        return pnl;
    }
    return 0.0;
}

- (long) getStartDateTime
{
    return startTime;
}

-(long) getEndDateTime
{
    if(endTime == 0){
        return updateTime;
    }else{
        return endTime;
    }
}


@end
