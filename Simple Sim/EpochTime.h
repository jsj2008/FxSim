//
//  EpochTime.h
//  Simple Sim
//
//  Created by Martin O'Connor on 06/01/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface EpochTime : NSObject

+(long)epochTimeAtZeroHour:(long) epochDate;
+(long)epochTimeNextDayAtZeroHour:(long) epochDate;
+(NSString *)stringDateWithDayOfWeek:(long) epochDate;
+(NSString *)stringDateWithTime:(long) epochDate;
+(NSString *)stringDate:(long) epochDate;
-(id)init;

@end
