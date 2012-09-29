//
//  RulesSystem.m
//  Simple Sim
//
//  Created by Martin O'Connor on 20/09/2012.
//  Copyright (c) 2012 OCONNOR RESEARCH. All rights reserved.
//

#import "RulesSystem.h"

@implementation RulesSystem

-(id) initWithString: (NSString *) ruleString
{
    if ( (self = [super init]) ) {
        BOOL initStringUnderstood = NO;
        
        _ruleString = ruleString;
        NSArray *signalComponents = [ruleString componentsSeparatedByString:@"/"];
        if([[signalComponents objectAtIndex:0] isEqualToString:@"HSF"] && [signalComponents count]==3){
            _type = @"HSF";
            _historyDays = [[signalComponents objectAtIndex:1] intValue];
            _cutoff = [[signalComponents objectAtIndex:2] doubleValue];
            initStringUnderstood = YES;
        }
        if(!initStringUnderstood){
            [NSException raise:@"Don't understand rules specification:" format:@"%@", ruleString];
        }
    }
    return self;   
}

+(BOOL)basicCheck: (NSString *) rulesString
{
    BOOL understood = YES;
    NSArray *separatedRules = [rulesString componentsSeparatedByString:@";"];
    NSArray *ruleComponents;
    NSString *singleRule;
    NSString *ruleName;
    for(int i = 0; i < [separatedRules count]; i ++){
        singleRule = [separatedRules objectAtIndex:i];
        ruleComponents = [singleRule componentsSeparatedByString:@"/"];
        if([ruleComponents count] == 3){
            ruleName = [ruleComponents objectAtIndex:0];
            if(![ruleName isEqualToString:@"HSF"]){
                understood = NO;
                break;
            }
        }else{
            understood = NO;
            break;
        }
    }
    return understood;
}

-(NSArray *) variablesNeeded
{
    NSMutableArray *varsNeeded = [[NSMutableArray alloc] init];
    if([[self type] isEqualToString:@"HSF"])
    {
        [varsNeeded addObject:[NSString stringWithFormat:@"SPREAD"]];
    }
    return varsNeeded;
    
}

@synthesize cutoff = _cutoff;
@synthesize historyDays = _historyDays;
@synthesize ruleString = _ruleString;
@synthesize type = _type;
@end
