//
//  BasicParameters.h
//  Simple Sim
//
//  Created by Martin O'Connor on 01/10/2012.
//  Copyright (c) 2012 OCONNOR RESEARCH. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface BasicParameters : NSObject<NSCoding>
{
}

-(id)initWithName: (NSString *)name
       AndAccCode: (NSString *) accCode
      AndBaseCode: (NSString *) baseCode
     AndQuoteCode: (NSString *) quoteCode
     AndStartDate: (long) startDate
       AndEndDate: (long) endDate
      AndDataRate: (long) dataRate
   AndMaxLeverage: (float) maxLeverage
  AndSamplingRate: (NSUInteger) samplingRate
    AndTradingLag: (NSUInteger) tradingLag
AndTradingDayStart: (NSUInteger) tradingDayStart
 AndTradingDayEnd: (NSUInteger) tradingDayEnd
AndWeekendTrading: (BOOL) weekendTrading
    AndWarmupTime: (long) warmupInSeconds;

- (void) encodeWithCoder:(NSCoder*)encoder;
- (id) initWithCoder:(NSCoder*)decoder;

- (NSString *)description;

@property (retain) NSString *name;
@property (readonly, retain) NSString *accCode;
@property (readonly, retain) NSString *baseCode;
@property (readonly, retain) NSString *quoteCode;
@property long startDate;
@property long endDate;
@property long dataRate;
@property (readonly) float maxLeverage;
@property NSUInteger samplingRate;
@property NSUInteger tradingLag;
@property NSUInteger tradingDayStart;
@property NSUInteger tradingDayEnd;
@property BOOL weekendTrading;
@property long warmupTime;
@end