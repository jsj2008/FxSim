//
//  RulesSystem.m
//  Simple Sim
//
//  Created by Martin O'Connor on 20/09/2012.
//  Copyright (c) 2012 OCONNOR RESEARCH. All rights reserved.
//

#import "RulesSystem.h"

@implementation RulesSystem

+(BOOL)basicCheck: (NSString *) rulesString
{
    BOOL understood = NO;
    NSArray *separatedRules = [rulesString componentsSeparatedByString:@";"];
    NSArray *ruleComponents;
    NSString *singleRule;
    NSString *ruleName;
    for(int i = 0; i < [separatedRules count]; i ++){
        singleRule = [separatedRules objectAtIndex:i];
        ruleComponents = [singleRule componentsSeparatedByString:@"/"];
        ruleName = [ruleComponents objectAtIndex:0];
        
        if([ruleName isEqualToString:@"HSF"]){
            understood = YES;
            break;
        }
        
        //Don't enter a trade after a certain time on Friday
        if([ruleName isEqualToString:@"FRI"]){
            understood = YES;
            break;
        }
        
        // Close position,, even if not in core trading hours is the position is losing a lot
        if([ruleName isEqualToString:@"OHC"]){
            understood = YES;
            break;
        }

        
        // Don't open a position if the signal is weakening
        if([ruleName isEqualToString:@"WSO"]){
            understood = YES;
            break;
        }

    }
    return understood;
}

+ (NSString *) combinedRulesString: (NSArray *)rulesArray
{
    NSString *combinedRulesString = [[NSString alloc] init];
    for(int i = 0; i < [rulesArray count]; i++){
        if(i==0){
            combinedRulesString = [rulesArray objectAtIndex:i];
        }else{
            combinedRulesString = [NSString stringWithFormat:@"%@;%@",combinedRulesString,[rulesArray objectAtIndex:i]];
        }
    }
    return combinedRulesString;
}

+ (double) fridayRule: (NSArray *)rulesArray
{
    double fridayRuleTime = 0.0;
    NSArray *singleRule;
    
    for(int iRule = 0; iRule < [rulesArray count]; iRule++){
        singleRule = [rulesArray objectAtIndex:iRule];
        singleRule = [[rulesArray objectAtIndex:iRule] componentsSeparatedByString:@"/"];
        if([[singleRule objectAtIndex:0] isEqualToString:@"FRI"]){
            fridayRuleTime = [[singleRule objectAtIndex:1] doubleValue];
                break;
        }
    }
    return fridayRuleTime;
}

+ (BOOL) outOfHoursCloseRule: (NSArray *)rulesArray
{
    BOOL ruleIncluded = NO;
    NSArray *singleRule;
    
    for(int iRule = 0; iRule < [rulesArray count]; iRule++){
        singleRule = [rulesArray objectAtIndex:iRule];
        singleRule = [[rulesArray objectAtIndex:iRule] componentsSeparatedByString:@"/"];
        if([[singleRule objectAtIndex:0] isEqualToString:@"OHC"]){
            ruleIncluded = YES;
            break;
        }
    }
    return ruleIncluded;
}

//+ (BOOL) weakSignalOverride: (NSArray *)rulesArray
//{
//    BOOL signalEntryOverride = NO;
//    NSArray *singleRule;
//    
//    for(int iRule = 0; iRule < [rulesArray count]; iRule++){
//        singleRule = [rulesArray objectAtIndex:iRule];
//        singleRule = [[rulesArray objectAtIndex:iRule] componentsSeparatedByString:@"/"];
//        if([[singleRule objectAtIndex:0] isEqualToString:@"WSO"]){
//            signalEntryOverride = YES;
//            break;
//        }
//    }
//    return signalEntryOverride;
//}
//-(id) initWithString: (NSString *) ruleString
//{
//    if ( (self = [super init]) ) {
//        BOOL initStringUnderstood = NO;
//        
//        _ruleString = ruleString;
//        NSArray *signalComponents = [ruleString componentsSeparatedByString:@"/"];
//        if([[signalComponents objectAtIndex:0] isEqualToString:@"HSF"] && [signalComponents count]==3){
//            _type = @"HSF";
//            _historyDays = [[signalComponents objectAtIndex:1] intValue];
//            _cutoff = [[signalComponents objectAtIndex:2] doubleValue];
//            initStringUnderstood = YES;
//        }
//        if([[signalComponents objectAtIndex:0] isEqualToString:@"FRI"] && [signalComponents count]==2){
//            _type = @"HSF";
//            _cutoff = [[signalComponents objectAtIndex:1] doubleValue];
//            initStringUnderstood = YES;
//        }
//        
//        if(!initStringUnderstood){
//            [NSException raise:@"Don't understand rules specification:" format:@"%@", ruleString];
//        }
//    }
//    return self;   
//}


+(NSArray *) variablesNeeded: (NSString *) rulesString;
{
    NSMutableArray *varsNeeded = [[NSMutableArray alloc] init];
    NSArray *ruleComponents = [rulesString componentsSeparatedByString:@"/"];
    if([[ruleComponents objectAtIndex:0] isEqualToString:@"HSF"])
    {
        [varsNeeded addObject:[NSString stringWithFormat:@"SPREAD"]];
    }

    return varsNeeded;
}

@end
