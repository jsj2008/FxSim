//
//  PositionRecord.m
//  Simple Sim
//
//  Created by Martin O'Connor on 17/06/2012.
//  Copyright (c) 2015 MARTIN OCONNOR. All rights reserved.
//

#import "PositionRecord.h"
#import "EpochTime.h"

//@interface PositionRecord()
//    @property NSMutableDictionary *adhocInfoArray;
//@end

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
//        _adhocInfoArray = [[NSMutableDictionary alloc] init];
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
//    [encoder encodeObject:_adhocInfoArray forKey:@"ADHOCINFOARRAY"];
    
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
//        _adhocInfoArray = [decoder decodeObjectForKey:@"ADHOCINFOARRAY"];
    }
    return self;   
}

- (NSString *)description
{
    NSString *description;
    description = [NSString stringWithFormat:@"%@   ", [EpochTime stringDateWithTime:[self dateTime]]];
    description = [NSString stringWithFormat:@"%@Amount   :%d   ",description, [self amount]];
    description = [NSString stringWithFormat:@"%@Price    :%5.2f\n",description,[self price]];
    return description;
}

//-(id) valueStoredForKey: (NSString *) key
//{
//    if([[self adhocInfoArray] objectForKey:key] != nil){
//        return [[self adhocInfoArray] objectForKey:key];
//    }else{
//        return nil;
//    }
//    return nil;
//}

@end
