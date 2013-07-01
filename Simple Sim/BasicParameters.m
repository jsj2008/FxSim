//
//  BasicParameters.m
//  Simple Sim
//
//  Created by Martin O'Connor on 01/10/2012.
//  Copyright (c) 2012 OCONNOR RESEARCH. All rights reserved.
//

#import "BasicParameters.h"
#import "EpochTime.h"

@implementation BasicParameters
 


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
{
    self = [super init];
    if(self){
        _name = name;
        _accCode = accCode;
        _baseCode = baseCode;
        _quoteCode = quoteCode;
        _startDate = startDate;
        _endDate = endDate;
        _maxLeverage = maxLeverage;
        _samplingRate = samplingRate;
        _tradingLag = tradingLag;
        _tradingDayStart = tradingDayStart;
        _tradingDayEnd = tradingDayEnd;
        _dataRate = dataRate;
        _weekendTrading = weekendTrading;
        _warmupTime = warmupInSeconds;
    }
    return self;
}

- (void) encodeWithCoder:(NSCoder*)encoder{
    [encoder encodeObject:_name forKey:@"NAME"];
    [encoder encodeObject:_accCode forKey:@"ACCCODE"];
    [encoder encodeObject:_baseCode forKey:@"BASECODE"];
    [encoder encodeObject:_quoteCode forKey:@"QUOTECODE"];
    [encoder encodeObject:[NSNumber numberWithLong:_startDate]  forKey:@"STARTDATE"];
    [encoder encodeObject:[NSNumber numberWithLong:_endDate]  forKey:@"ENDDATE"];
    [encoder encodeObject:[NSNumber numberWithLong:_maxLeverage]  forKey:@"MAXLEVERAGE"];
    [encoder encodeObject:[NSNumber numberWithLong:_samplingRate]  forKey:@"SAMPLINGRATE"];
    [encoder encodeObject:[NSNumber numberWithLong:_tradingLag]  forKey:@"TRADINGLAG"];
    [encoder encodeObject:[NSNumber numberWithLong:_tradingDayStart]  forKey:@"TRADINGDAYSTART"];
    [encoder encodeObject:[NSNumber numberWithLong:_tradingDayEnd]  forKey:@"TRADINGDAYEND"];
    [encoder encodeObject:[NSNumber numberWithLong:_dataRate]  forKey:@"DATARATE"];
    [encoder encodeObject:[NSNumber numberWithBool:_weekendTrading]  forKey:@"WEEKENDTRADING"];
    [encoder encodeObject:[NSNumber numberWithLong:_warmupTime]  forKey:@"WARMUPTIME"];
    
}

- (id) initWithCoder:(NSCoder*)decoder{
    self = [super init];
    if(self){
        _name = [decoder decodeObjectForKey:@"NAME"];   
        _accCode = [decoder decodeObjectForKey:@"ACCCODE"]; 
        _baseCode = [decoder decodeObjectForKey:@"BASECODE"]; 
        _quoteCode = [decoder decodeObjectForKey:@"QUOTECODE"]; 
        _startDate = [[decoder decodeObjectForKey:@"STARTDATE"] longValue]; 
        _endDate = [[decoder decodeObjectForKey:@"ENDDATE"] longValue]; 
        _maxLeverage = [[decoder decodeObjectForKey:@"MAXLEVERAGE"] longValue];
        _samplingRate = [[decoder decodeObjectForKey:@"SAMPLINGRATE"] longValue];
        _tradingLag = [[decoder decodeObjectForKey:@"TRADINGLAG"] longValue];
        _tradingDayStart = [[decoder decodeObjectForKey:@"TRADINGDAYSTART"] longValue];
        _tradingDayEnd = [[decoder decodeObjectForKey:@"TRADINGDAYEND"] longValue];
        _dataRate = [[decoder decodeObjectForKey:@"DATARATE"] longValue];
        _weekendTrading = [[decoder decodeObjectForKey:@"WEEKENDTRADING"] boolValue];
        _warmupTime = [[decoder decodeObjectForKey:@"WARMUPTIME"] longValue];
    }
    return self;
}

- (NSString *)description
{
    NSString *descriptionString;
    descriptionString = [NSString stringWithFormat:@"Name: %@\n Account Code: %@\n BaseCode: %@\nQuoteCode: %@\n StartDate: %@\n EndDate: %@\n Max Leverage: %5.2f\nSampling Rate: %lu \nTrading Lag: %lu \nTrading Day Start: %@ \nTrading Day End:%@\nWarm up Time %ld\n",[self name],[self accCode],[self baseCode],[self quoteCode],[EpochTime stringDate:[self startDate]],[EpochTime stringDate:[self endDate]], [self maxLeverage], [self samplingRate], [self tradingLag], [EpochTime stringOfDateTime:[self tradingDayStart] WithFormat:@"%H:%M"], [EpochTime stringOfDateTime:[self tradingDayEnd] WithFormat:@"%H:%M"], [self warmupTime]];
    return descriptionString;
    
}

@end
