//
//  SignalRecord.m
//  Simple Sim
//
//  Created by Martin O'Connor on 18/06/2012.
//  Copyright (c) 2012 OCONNOR RESEARCH. All rights reserved.
//

#import "SignalRecord.h"

@implementation SignalRecord

- (id) initWithSignal:(double) signal
         AndStartTime: (long) startTime
           AndEndTime: (long) endTime
        AndEntryPrice: (double) entryPrice
         AndExitPrice: (double) exitPrice
      AndTimeInProfit: (double) timeInProfit
AndMaxPotentialProfit: (double) maxPotentialProfit
  AndMaxPotentialLoss: (double) maxPotentialLoss
{
    self = [super init];
    if(self){
        _signal = signal;
        _startTime = startTime;
        _endTime = endTime;
        _entryPrice = entryPrice;
        _exitPrice = exitPrice;
        _timeInProfit = timeInProfit;
        _maxPotentialProfit = maxPotentialProfit;
        _maxPotentialLoss = maxPotentialLoss;
    }
    return self;
}

@synthesize signal = _signal;
@synthesize startTime = _startTime;
@synthesize endTime = _endTime;
@synthesize entryPrice = _entryPrice;
@synthesize exitPrice = _exitPrice;
@synthesize timeInProfit = _timeInProfit;
@synthesize maxPotentialProfit = _maxPotentialProfit;
@synthesize maxPotentialLoss = _maxPotentialLoss;

@end
