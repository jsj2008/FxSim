//
//  CashFlowRecord.m
//  Simple Sim
//
//  Created by Martin O'Connor on 17/06/2012.
//  Copyright (c) 2012 OCONNOR RESEARCH. All rights reserved.
//

#import "CashFlowRecord.h"
#import "EpochTime.h"

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

- (void) encodeWithCoder:(NSCoder*)encoder
{
    [encoder encodeObject:[NSNumber numberWithDouble:_amount] forKey:@"AMOUNT"];
    [encoder encodeObject:[NSNumber numberWithDouble:_resultingBalance] forKey:@"RESULTINGBALANCE"];
    [encoder encodeObject:[NSNumber numberWithLong:_dateTime] forKey:@"DATETIME"];
    [encoder encodeObject:[NSNumber numberWithInt:_reason] forKey:@"REASON"];
}

- (id) initWithCoder:(NSCoder*)decoder
{
    if (self = [super init]) {
        // If parent class also adopts NSCoding, replace [super init]
        // with [super initWithCoder:decoder] to properly initialize.
        
        // NOTE: Decoded objects are auto-released and must be retained
        _amount = [[decoder decodeObjectForKey:@"AMOUNT"] doubleValue];
        _resultingBalance = [[decoder decodeObjectForKey:@"RESULTINGBALANCE"] doubleValue];
        _dateTime = [[decoder decodeObjectForKey:@"DATETIME"] longValue];
        _reason = [[decoder decodeObjectForKey:@"REASON"] intValue];
    }
    return self;   
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"Time:%@ \nAmount:%5.2f \nReason:%d \nResulting:%5.2f",[EpochTime stringDateWithTime:[self dateTime]],[self amount],[self reason],[self resultingBalance]];
}

//@synthesize  amount = _amount;
//@synthesize  resultingBalance = _resultingBalance;
//@synthesize  dateTime = _dateTime;
//@synthesize  reason = _reason;

@end
