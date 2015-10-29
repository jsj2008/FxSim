//
//  EpochTime.m
//  Simple Sim
//
//  Created by Martin O'Connor on 06/01/2012.
//  Copyright (c) 2015 MARTIN OCONNOR. All rights reserved.
//

#import "EpochTime.h"

@implementation EpochTime

+ (long) epochTimeAtZeroHour:(long) epochDate
{
    long epochDateZeroHour;
    NSDate *nsDate = [[NSDate alloc] initWithTimeIntervalSince1970:epochDate];
     
    NSCalendar *calendar= [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar]; 
    [calendar setTimeZone:[NSTimeZone timeZoneWithAbbreviation:@"UTC"]];
    NSCalendarUnit unitFlags = NSHourCalendarUnit | NSMinuteCalendarUnit | NSSecondCalendarUnit; 
    NSDateComponents *dateComponents = [calendar components:unitFlags fromDate:nsDate]; 
    NSInteger hour = [dateComponents hour];
    NSInteger minute = [dateComponents minute];
    NSInteger second = [dateComponents second];
    epochDateZeroHour = epochDate -((hour*60*60)+(minute*60)+second);
    
    return epochDateZeroHour;
}

+ (long) epochTimeNextDayAtZeroHour:(long) epochDate
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

+ (long) epochTimeAtZeroHourJan1NextYear:(long) epochDate
{
    NSDate *nsDate = [[NSDate alloc] initWithTimeIntervalSince1970:epochDate];
    
    NSCalendar *calendar= [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
    [calendar setTimeZone:[NSTimeZone timeZoneWithAbbreviation:@"UTC"]];
    NSCalendarUnit unitFlags = NSYearCalendarUnit;
    
    NSDateComponents *dateComponents = [calendar components:unitFlags fromDate:nsDate];
    NSInteger year = [dateComponents year];
    
    NSString *formatString = @"%Y-%m-%d %H:%M:%S";
    NSDateFormatter *formatter = [[NSDateFormatter alloc] initWithDateFormat:formatString allowNaturalLanguage:NO];
    [formatter setTimeZone:[NSTimeZone timeZoneWithAbbreviation:@"UTC"]];
    NSString *dateString = [NSString stringWithFormat:@"%ld-01-01 00:00:00",year+1];
    NSDate *startOfYear = [formatter dateFromString:dateString];
    
    return [startOfYear timeIntervalSince1970];
}





+ (NSString *) stringDateWithDayOfWeek:(long) epochDate
{
    NSString *returnString;
    returnString = [[NSDate dateWithTimeIntervalSince1970:(NSTimeInterval) epochDate] descriptionWithCalendarFormat:@"%a %Y-%m-%d" timeZone:[NSTimeZone timeZoneWithName:@"GMT"] locale:nil];
    return returnString;
}

+ (NSString *) stringDateWithTime:(long) epochDate
{
    NSString *returnString;
    returnString = [[NSDate dateWithTimeIntervalSince1970:(NSTimeInterval) epochDate] descriptionWithCalendarFormat:@"%Y-%m-%d %H:%M:%S" timeZone:[NSTimeZone timeZoneWithName:@"GMT"] locale:nil];
    return returnString;    
}

+ (NSString *) stringHoursMinutesSeconds:(long) epochDate
{
    NSString *returnString;
    returnString = [[NSDate dateWithTimeIntervalSince1970:(NSTimeInterval) epochDate] descriptionWithCalendarFormat:@"%H:%M:%S" timeZone:[NSTimeZone timeZoneWithName:@"GMT"] locale:nil];
    return returnString;    
}

+ (NSString *) stringDate:(long) epochDate
{
    NSString *returnString;
    returnString = [[NSDate dateWithTimeIntervalSince1970:(NSTimeInterval) epochDate] descriptionWithCalendarFormat:@"%Y-%m-%d" timeZone:[NSTimeZone timeZoneWithName:@"GMT"] locale:nil];
    return returnString;
}

+ (NSString *) stringOfDateTime:(long) epochDate
                     WithFormat:(NSString *)formatString
{
    NSString *returnString;
    returnString = [[NSDate dateWithTimeIntervalSince1970:(NSTimeInterval) epochDate] descriptionWithCalendarFormat:formatString timeZone:[NSTimeZone timeZoneWithName:@"GMT"] locale:nil];
    return returnString;
}

+ (int) monthNumberOfDateTime:(long) epochDate
{
    NSString *returnString;
    returnString = [[NSDate dateWithTimeIntervalSince1970:(NSTimeInterval) epochDate] descriptionWithCalendarFormat:@"%m" timeZone:[NSTimeZone timeZoneWithName:@"GMT"] locale:nil];
    return [returnString intValue];
}


+ (int) daysSinceEpoch:(long) epochDate
{
    int daysSinceZero;
    daysSinceZero = (int) epochDate / (24*60*60);
    
    return daysSinceZero;
}

+ (int) dayOfWeek:(long) epochDate
{
    int dayOfWeek;
    
    dayOfWeek = [[[NSDate dateWithTimeIntervalSince1970:(NSTimeInterval) epochDate] descriptionWithCalendarFormat:@"%w" timeZone:[NSTimeZone timeZoneWithName:@"GMT"] locale:nil] intValue];
    
    return dayOfWeek;
}

+ (BOOL) isWeekday:(long) epochDate
{
    BOOL isMonToFri = YES;
    int dayOfWeek;
    
    dayOfWeek = [[[NSDate dateWithTimeIntervalSince1970:(NSTimeInterval) epochDate] descriptionWithCalendarFormat:@"%w" timeZone:[NSTimeZone timeZoneWithName:@"GMT"] locale:nil] intValue];
    
    if(dayOfWeek==0){
        isMonToFri = NO;
    }
    if(dayOfWeek==6){
        isMonToFri = NO;
    }
    
    return isMonToFri;
}

+ (int) daysBetweenInclusiveFrom: (long) startDateTime
                              To: (long) endDateTime
                CountingWeekends: (BOOL) countWeekendDays
{
    startDateTime = [self epochTimeAtZeroHour:startDateTime];
    endDateTime = [self epochTimeAtZeroHour:endDateTime];
    int count = 0;
    for(long currentDateTime = startDateTime; currentDateTime <= endDateTime; currentDateTime = currentDateTime + (24*60*60))
    {
        if(countWeekendDays){
            count++;
        }else{
            if(![self isWeekday:currentDateTime]){
                count++;
            }
        }
    }
    return count;
}

@end


