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
        NSMutableArray *signalComponentsPlusExtras = [[signalString componentsSeparatedByString:@";"] mutableCopy];
        NSString *signalStripped = [signalComponentsPlusExtras objectAtIndex:0];
        
        NSArray *signalComponents = [signalStripped componentsSeparatedByString:@"/"];
        if([[signalComponents objectAtIndex:0] isEqualToString:@"SECO"] && [signalComponents count]==3){
            _type = @"SECO";
            _fastCode = [[signalComponents objectAtIndex:1] intValue];
            _slowCode = [[signalComponents objectAtIndex:2] intValue];
            initStringUnderstood = YES;
        }
        
        if([[signalComponents objectAtIndex:0] isEqualToString:@"MACD"] && [signalComponents count]==4){
            _type = @"MACD";
            _fastCode = [[signalComponents objectAtIndex:1] intValue];
            _slowCode = [[signalComponents objectAtIndex:2] intValue];
            _signalSmooth = [[signalComponents objectAtIndex:3] intValue];
            initStringUnderstood = YES;
        }
        
        if([[signalComponents objectAtIndex:0] isEqualToString:@"EMA"]  && [signalComponents count]==3){
            _type = @"EMA";
            _fastCode = [[signalComponents objectAtIndex:1] intValue];
            _slowCode = [[signalComponents objectAtIndex:2] intValue];
            initStringUnderstood = YES;
            
        }
        
        if([signalComponentsPlusExtras count] > 1){
            for( int i = 1; i < [signalComponentsPlusExtras count];i++ )
            {
                NSString *extra = [signalComponentsPlusExtras objectAtIndex:i];
                NSArray *components = [extra componentsSeparatedByString:@"/"];
                NSString *typeOfExtra = [components objectAtIndex:0];
                if(!([typeOfExtra isEqualToString:@"EMA"] || [typeOfExtra isEqualToString:@"ATR"] || [typeOfExtra isEqualToString:@"HLC"] || [typeOfExtra isEqualToString:@"TR2"])){
                    initStringUnderstood = NO;
                }
            }
            if(initStringUnderstood){
                [signalComponentsPlusExtras removeObjectAtIndex:0];
                _extras = signalComponentsPlusExtras;
            }
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
    NSArray *signalComponentsPlusExtras = [signalString componentsSeparatedByString:@";"];
    NSString *signalStripped = [signalComponentsPlusExtras objectAtIndex:0];
    
    NSArray *signalComponents = [signalStripped componentsSeparatedByString:@"/"];
    if([[signalComponents objectAtIndex:0] isEqualToString:@"SECO"]  && [signalComponents count] == 3){
        understood = YES;
    }
    if([[signalComponents objectAtIndex:0] isEqualToString:@"MACD"]  && [signalComponents count] == 4){
        understood = YES;
    }
    if([[signalComponents objectAtIndex:0] isEqualToString:@"EMA"] && [signalComponents count] == 3){
        understood = YES;
    }
    
    if([signalComponentsPlusExtras count] > 1){
        for( int i = 1; i < [signalComponentsPlusExtras count];i++ )
        {
            NSString *extra = [signalComponentsPlusExtras objectAtIndex:i];
            NSArray *components = [extra componentsSeparatedByString:@"/"];
            NSString *typeOfExtra = [components objectAtIndex:0];
            if(!([typeOfExtra isEqualToString:@"EMA"] || [typeOfExtra isEqualToString:@"ATR" ] || [typeOfExtra isEqualToString:@"HLC"] || [typeOfExtra isEqualToString:@"TR2" ] )){
                understood = NO;
            }
        }
    }
    
    return understood;
}

-(NSArray *) variablesNeeded
{
    NSMutableArray *varsNeeded = [[NSMutableArray alloc] init];
    if([[self type] isEqualToString:@"SECO"] || [[self type] isEqualToString:@"MACD"])
    {
        [varsNeeded addObject:[NSString stringWithFormat:@"EMA/%d",[self fastCode]]];
        [varsNeeded addObject:[NSString stringWithFormat:@"EMA/%d",[self slowCode]]];
    }
    
    if([self extras] != Nil){
        for( int i = 0; i < [[self extras] count];i++ )
        {
            NSString *extra = [[self extras] objectAtIndex:i];
            [varsNeeded addObject:extra];
        }
    }
    return varsNeeded;
}

@synthesize signalString = _signalString;
@synthesize type = _type;    
@synthesize fastCode = _fastCode;
@synthesize slowCode = _slowCode;
@synthesize signalSmooth = _signalSmooth;
@synthesize extras = _extras;
@end
