//
//  PositionRecord.m
//  Simple Sim
//
//  Created by Martin O'Connor on 17/06/2012.
//  Copyright (c) 2012 OCONNOR RESEARCH. All rights reserved.
//

#import "PositionRecord.h"
@implementation PositionRecord

- (id) initWithAmount: (int) amount
          AndDateTime: (long) dateTime
             AndPrice: (double) price
  AndInterestDateTime: (long) interestDateTime
   AndInterestAccrued: (double) interestAccrued
{
    self = [super init];
    if(self){
        _amount = amount;
        _dateTime = dateTime;
        _price = price;
        _interestAccruedDateTime = interestDateTime;
        _interestAccrued = interestAccrued;
    }
    return self;
}

@synthesize amount = _amount;        
@synthesize dateTime = _dateTime;
@synthesize price = _price;
@synthesize interestAccruedDateTime = _interestAccruedDateTime;
@synthesize interestAccrued = _interestAccrued;
@end
