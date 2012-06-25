//
//  CashFlowRecord.m
//  Simple Sim
//
//  Created by Martin O'Connor on 17/06/2012.
//  Copyright (c) 2012 OCONNOR RESEARCH. All rights reserved.
//

#import "CashFlowRecord.h"

@implementation CashFlowRecord

- (id) initWithAmount: (double) amount
  AndResultingBalance: (double) resultingBalance
          AndDateTime: (long) datetime
            AndReason: (int) reason
{
    self = [super init];
    if(self){
        _amount = amount;
        _resultingBalance = resultingBalance;
        _dateTime = datetime;
        _reason = reason;
    }
    return self;
}

@synthesize  amount = _amount;
@synthesize  resultingBalance = _resultingBalance;
@synthesize  dateTime = _dateTime;
@synthesize  reason = _reason;

@end
