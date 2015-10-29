//
//  SignalRecord.m
//  Simple Sim
//
//  Created by Martin O'Connor on 18/06/2012.
//  Copyright (c) 2015 MARTIN OCONNOR. All rights reserved.
//

#import "SignalRecord.h"

@implementation SignalRecord


- (id) initWithSignal:(double) signal
         AndStartTime: (long) startTime
           AndEndTime: (long) endTime
        AndEntryPrice: (double) entryPrice
         AndExitPrice: (double) exitPrice
{
    self = [super init];
    if(self){
        _signal = signal;
        _startTime = startTime;
        _endTime = endTime;
        _entryPrice = entryPrice;
        _exitPrice = exitPrice;
        _pnl = 0.0;
    }
    return self;
}

- (void) encodeWithCoder:(NSCoder*)encoder
{
    [encoder encodeObject:[NSNumber numberWithDouble:_signal] forKey:@"SIGNAL"];
    [encoder encodeObject:[NSNumber numberWithLong:_startTime] forKey:@"STARTTIME"];
    [encoder encodeObject:[NSNumber numberWithLong:_endTime] forKey:@"ENDTIME"];
    [encoder encodeObject:[NSNumber numberWithDouble:_entryPrice] forKey:@"ENTRYPRICE"];
    [encoder encodeObject:[NSNumber numberWithDouble:_exitPrice] forKey:@"EXITPRICE"];
    [encoder encodeObject:[NSNumber numberWithDouble:_pnl] forKey:@"PNL"];
}

- (id) initWithCoder:(NSCoder*)decoder
{
    if (self = [super init]) {
        // If parent class also adopts NSCoding, replace [super init]
        // with [super initWithCoder:decoder] to properly initialize.
        
        // NOTE: Decoded objects are auto-released and must be retained
        _signal = [[decoder decodeObjectForKey:@"SIGNAL"] doubleValue];
        _startTime = [[decoder decodeObjectForKey:@"STARTTIME"] longValue];
        _endTime = [[decoder decodeObjectForKey:@"ENDTIME"] longValue];
        _entryPrice = [[decoder decodeObjectForKey:@"ENTRYPRICE"] doubleValue];
        _exitPrice = [[decoder decodeObjectForKey:@"EXITPRICE"] doubleValue];
        _pnl = [[decoder decodeObjectForKey:@"PNL"] doubleValue];
    }
    return self;   
}


@synthesize signal = _signal;
@synthesize startTime = _startTime;
@synthesize endTime = _endTime;
@synthesize entryPrice = _entryPrice;
@synthesize exitPrice = _exitPrice;
@synthesize pnl = _pnl;
@end
