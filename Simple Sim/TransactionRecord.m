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
      {
    self = [super init];
    if(self){
        _amount = amount;
        _dateTime = dateTime;
        _price = price;
        _resultingMarketExposure = resultingExposure;
        _spread = spread;
        _spreadInAccCurrency = spreadInAccCurrency;
        _signalDateTime = signalDateTime;
    }
    return self;
}


- (void) encodeWithCoder:(NSCoder*)encoder
{
    [encoder encodeObject:[NSNumber numberWithDouble:_amount] forKey:@"AMOUNT"];
    [encoder encodeObject:[NSNumber numberWithLong:_dateTime] forKey:@"DATETIME"];
    [encoder encodeObject:[NSNumber numberWithDouble:_price] forKey:@"PRICE"];
    [encoder encodeObject:[NSNumber numberWithInt:_resultingMarketExposure] forKey:@"MKTEXPOSURE"];
    [encoder encodeObject:[NSNumber numberWithDouble:_spread] forKey:@"SPREAD"];
    [encoder encodeObject:[NSNumber numberWithDouble:_spreadInAccCurrency] forKey:@"SPREADINACCCURRENCY"];
     [encoder encodeObject:[NSNumber numberWithLong:_signalDateTime] forKey:@"SIGNALDATETIME"];
    
}
- (id) initWithCoder:(NSCoder*)decoder
{
    if (self = [super init]) {
        // If parent class also adopts NSCoding, replace [super init]
        // with [super initWithCoder:decoder] to properly initialize.
        
        // NOTE: Decoded objects are auto-released and must be retained
        _amount = [[decoder decodeObjectForKey:@"AMOUNT"] doubleValue];
        _dateTime = [[decoder decodeObjectForKey:@"DATETIME"] longValue];
        _price = [[decoder decodeObjectForKey:@"PRICE"] doubleValue];
        _resultingMarketExposure = [[decoder decodeObjectForKey:@"MKTEXPOSURE"] intValue];
        _spread = [[decoder decodeObjectForKey:@"SPREAD"] doubleValue];
        _spreadInAccCurrency  = [[decoder decodeObjectForKey:@"SPREADINACCCURRENCY"] doubleValue];
        _signalDateTime =  [[decoder decodeObjectForKey:@"SIGNALDATETIME"] longValue];
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
