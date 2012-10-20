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

- (void) encodeWithCoder:(NSCoder*)encoder
{
    [encoder encodeObject:[NSNumber numberWithInt:_amount] forKey:@"AMOUNT"];
    [encoder encodeObject:[NSNumber numberWithLong:_dateTime] forKey:@"DATETIME"];
    [encoder encodeObject:[NSNumber numberWithDouble:_price] forKey:@"PRICE"];
    [encoder encodeObject:[NSNumber numberWithLong:_interestAccruedDateTime] forKey:@"INTERESTACCRUEDDATETIME"];
    [encoder encodeObject:[NSNumber numberWithDouble:_interestAccrued] forKey:@"INTERESTACCRUED"];
    
    
}
- (id) initWithCoder:(NSCoder*)decoder
{
    if (self = [super init]) {
        // If parent class also adopts NSCoding, replace [super init]
        // with [super initWithCoder:decoder] to properly initialize.
        
        // NOTE: Decoded objects are auto-released and must be retained
        _amount = [[decoder decodeObjectForKey:@"AMOUNT"] intValue];
        _dateTime = [[decoder decodeObjectForKey:@"DATETIME"] longValue];
        _price = [[decoder decodeObjectForKey:@"PRICE"] doubleValue];
        _interestAccruedDateTime = [[decoder decodeObjectForKey:@"INTERESTACCRUEDDATETIME"] longValue];
        _interestAccrued = [[decoder decodeObjectForKey:@"INTERESTACCRUED"] doubleValue];
    }
    return self;   
}





@synthesize amount = _amount;        
@synthesize dateTime = _dateTime;
@synthesize price = _price;
@synthesize interestAccruedDateTime = _interestAccruedDateTime;
@synthesize interestAccrued = _interestAccrued;
@end
