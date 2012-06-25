//
//  TransactionRecord.m
//  Simple Sim
//
//  Created by Martin O'Connor on 17/06/2012.
//  Copyright (c) 2012 OCONNOR RESEARCH. All rights reserved.
//

#import "TransactionRecord.h"

@implementation TransactionRecord


- (id) initWithAmount:(int) amount
          AndDateTime:(long)dateTime 
             AndPrice:(double)price 
 AndResultingExposure: (int) resultingExposure
            AndSpread: (double) spread
AndSpreadInAccCurrency: (double) spreadInAccCurrency
    AndSignalDateTime: (long) signalDateTime
       AndSignalIndex: (int) signalIndex{
    self = [super init];
    if(self){
        _amount = amount;
        _dateTime = dateTime;
        _price = price;
        _resultingMarketExposure = resultingExposure;
        _spread = spread;
        _spreadInAccCurrency = spreadInAccCurrency;
        _signalDateTime = signalDateTime;
        _signalIndex = signalIndex;
    }
    return self;
}

@synthesize amount = _amount;        
@synthesize dateTime = _dateTime;
@synthesize price = _price;
@synthesize resultingMarketExposure = _resultingMarketExposure;
@synthesize spread = _spread;
@synthesize spreadInAccCurrency = _spreadInAccCurrency;
@synthesize signalDateTime = _signalDateTime;
@synthesize signalIndex = _signalIndex; 

@end
