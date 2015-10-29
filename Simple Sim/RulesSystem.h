//
//  RulesSystem.h
//  Simple Sim
//
//  Created by Martin O'Connor on 20/09/2012.
//  Copyright (c) 2015 MARTIN OCONNOR. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface RulesSystem : NSObject
{
//    NSString *_ruleString;
//    NSString *_type;
//    int _historyDays;
//    double _cutoff;
}

//- (id) initWithString: (NSString *) ruleString;
+ (BOOL) basicCheck: (NSString *) rulesString;
+ (NSString *) combinedRulesString: (NSArray *)rulesArray;
+ (double) fridayRule: (NSArray *)rulesArray;
+ (BOOL) outOfHoursCloseRule: (NSArray *)rulesArray;
+ (NSArray *) variablesNeeded: (NSString *) rulesString;
//+ (BOOL) weakSignalOverride: (NSArray *)rulesArray;
@end
