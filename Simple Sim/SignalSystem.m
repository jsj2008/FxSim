//
//  SignalSystem.m
//  Simple Sim
//
//  Created by Martin O'Connor on 28/08/2012.
//  Copyright (c) 2012 OCONNOR RESEARCH. All rights reserved.
//

#import "SignalSystem.h"

@implementation SignalSystem

-(id)init
{
    return [self initWithString:@""];
    
}

-(id)initWithString: (NSString *) signalString
{
    if ( (self = [super init]) ) {
        BOOL initStringUnderstood = NO;
        
        _signalString = signalString;
        NSArray *signalComponents = [signalString componentsSeparatedByString:@"/"];
        if([[signalComponents objectAtIndex:0] isEqualToString:@"SECO"] && [signalComponents count]==3){
            _type = @"SECO";
            _fastCode = [[signalComponents objectAtIndex:1] intValue];
            _slowCode = [[signalComponents objectAtIndex:2] intValue];
            initStringUnderstood = YES;
        }
        
        if([[signalComponents objectAtIndex:0] isEqualToString:@"EMA"]  && [signalComponents count]==3){
            _type = @"EMA";
            _fastCode = [[signalComponents objectAtIndex:1] intValue];
            _slowCode = [[signalComponents objectAtIndex:2] intValue];
            initStringUnderstood = YES;
            
        }
        
        
        if(!initStringUnderstood){
            [NSException raise:@"Don't understand signal specification:" format:@"%@", signalString];
        }
    }
    return self;
}

+(BOOL)basicCheck: (NSString *) signalString
{
    BOOL understood = NO;
    NSArray *signalComponents = [signalString componentsSeparatedByString:@"/"];
    if([[signalComponents objectAtIndex:0] isEqualToString:@"SECO"]  && [signalComponents count] == 3){
        understood = YES;
    }
    if([[signalComponents objectAtIndex:0] isEqualToString:@"EMA"] && [signalComponents count] == 3){
        understood = YES;
    }
    return understood;
}

-(NSArray *) variablesNeeded
{
    NSMutableArray *varsNeeded = [[NSMutableArray alloc] init];
    if([[self type] isEqualToString:@"SECO"])
    {
        [varsNeeded addObject:[NSString stringWithFormat:@"EMA%d",[self fastCode]]];
        [varsNeeded addObject:[NSString stringWithFormat:@"EMA%d",[self slowCode]]];
    }
    return varsNeeded;
}

@synthesize signalString = _signalString;
@synthesize type = _type;    
@synthesize fastCode = _fastCode;
@synthesize slowCode = _slowCode;    
    
@end
