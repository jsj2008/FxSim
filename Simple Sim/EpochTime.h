//
//  EpochTime.h
//  Simple Sim
//
//  Created by Martin O'Connor on 06/01/2012.
//  Copyright (c) 2012 OCONNOR RESEARCH. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface EpochTime : NSObject

+ (long) epochTimeAtZeroHour:(long) epochDate;
+ (long) epochTimeNextDayAtZeroHour:(long) epochDate;
+ (NSString *) stringDateWithDayOfWeek:(long) epochDate;
+ (NSString *) stringDateWithTime:(long) epochDate;
+ (NSString *) stringHoursMinutesSeconds:(long) epochDate;
+ (NSString *) stringOfDateTime:(long) epochDate WithFormat:(NSString *)formatString;
+ (int) monthNumberOfDateTime:(long) epochDate;

+ (NSString *) stringDate:(long) epochDate;
+ (int) daysSinceEpoch:(long) epochDate;
+ (int) dayOfWeek:(long) epochDate;
+ (BOOL) isWeekday:(long) epochDate;
+ (int) daysBetweenInclusiveFrom: (long) startDateTime
                              To: (long) endDateTime
                CountingWeekends:(BOOL) countWeekendDays;
+ (long) epochTimeAtZeroHourJan1NextYear:(long) epochDate;

//-(id)init;

@end
