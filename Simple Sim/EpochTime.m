//
//  EpochTime.m
//  Simple Sim
//
//  Created by Martin O'Connor on 06/01/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "EpochTime.h"

@implementation EpochTime

-(id)init
{
    self = [super init];
    if(self){
        
    }
    return self;
}

+(long)epochTimeAtZeroHour:(long) epochDate
{
    long epochDateZeroHour;
    NSDate *nsDate = [[NSDate alloc] initWithTimeIntervalSince1970:epochDate];
     
    NSCalendar *calendar= [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar]; 
    [calendar setTimeZone:[NSTimeZone timeZoneWithAbbreviation:@"UTC"]];
    NSCalendarUnit unitFlags = NSHourCalendarUnit | NSMinuteCalendarUnit | NSSecondCalendarUnit; 
    NSDateComponents *dateComponents = [calendar components:unitFlags fromDate:nsDate]; 
     //NSInteger day = [weekdayComponents day];
    //NSInteger weekday = [weekdayComponents weekday];
    //NSInteger month = [weekdayComponents month];
    //NSInteger year = [weekdayComponents year];
    NSInteger hour = [dateComponents hour];
    NSInteger minute = [dateComponents minute];
    NSInteger second = [dateComponents second];
    epochDateZeroHour = epochDate -((hour*60*60)+(minute*60)+second);
    
    NSLog(@"From %lu with get %lu",epochDate,epochDateZeroHour);
    return epochDateZeroHour;
}

+(long)epochTimeNextDayAtZeroHour:(long) epochDate
{
    long epochDay;
    NSDate *nsDate = [[NSDate alloc] initWithTimeIntervalSince1970:epochDate];
    
    NSCalendar *calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
    NSDateComponents *offsetComponents = [[NSDateComponents alloc] init];
    [offsetComponents setDay:1];
    nsDate = [calendar dateByAddingComponents:offsetComponents
                                                       toDate:nsDate options:0];
    
    epochDay = [nsDate timeIntervalSince1970];
    return [self epochTimeAtZeroHour:epochDay];

}



@end


