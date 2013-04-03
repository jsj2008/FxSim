//
//  PositioningSystem.m
//  Simple Sim
//
//  Created by Martin O'Connor on 17/08/2012.
//  Copyright (c) 2012 OCONNOR RESEARCH. All rights reserved.
//

#import "PositioningSystem.h"
#define POSITION_CUSHION 0.25

@implementation PositioningSystem

-(id)init
{
    return [self initWithString:@""];
    
}

-(id)initWithString: (NSString *) initString
{
    if ( (self = [super init]) ) {
        BOOL initStringUnderstood = NO;
        _positioningString = initString;
        _stopEntryOnWeakening = NO;
        NSArray *positioningComponents = [initString componentsSeparatedByString:@"/"];
        
        // Simple Trinary Positioning
        if([[positioningComponents objectAtIndex:0] isEqualToString:@"STP"]  && [positioningComponents count] == 2){
            _type = @"STP";
            // this converts signal into 1 of three possible 
            //            // with parameter for threshold of zero
            _signalThreshold = [[positioningComponents objectAtIndex:1] doubleValue];
            initStringUnderstood = YES;
        }
        if([[positioningComponents objectAtIndex:0] isEqualToString:@"STP"]  && [positioningComponents count] == 3){
            _type = @"STP";
            // this converts signal into 1 of three possible
            //            // with parameter for threshold of zero
            _signalThreshold = [[positioningComponents objectAtIndex:1] doubleValue];
            if([[positioningComponents objectAtIndex:2] isEqualToString:@"WSO"]){
                _stopEntryOnWeakening = YES;
            }
            initStringUnderstood = YES;
        }
        
        // Signal Feedback Proportional
        if([[positioningComponents objectAtIndex:0] isEqualToString:@"SFP"] && [positioningComponents count] == 6){
            _type = @"SFP";
            _signalThreshold = [[positioningComponents objectAtIndex:1] doubleValue];
            _stepProportion = [[positioningComponents objectAtIndex:2] doubleValue];
            _stepLength = [[positioningComponents objectAtIndex:3] doubleValue];
            _stepUnit = [positioningComponents objectAtIndex:4];
            _perfSmoothParam = [[positioningComponents objectAtIndex:5] intValue];
            // Seconds Ticks
            if([_stepUnit isEqualToString:@"S"] || [_stepUnit isEqualToString:@"M"] || [_stepUnit isEqualToString:@"H"] || [_stepUnit isEqualToString:@"D"] || [_stepUnit isEqualToString:@"T"] || [_stepUnit isEqualToString:@"P"]){
                initStringUnderstood = YES;
            }
        }
        // Signal Strength Positioning
        if([[positioningComponents objectAtIndex:0] isEqualToString:@"SSP"] && [positioningComponents count] == 4){
            _type = @"SSP";
        }
        // Static Positioning
        // If you 
        if([[positioningComponents objectAtIndex:0] isEqualToString:@"STAT"] && [positioningComponents count] == 3){
            _type = @"STAT";
            _signalThreshold = [[positioningComponents objectAtIndex:1] doubleValue];
            _maxPos = [[positioningComponents objectAtIndex:2] doubleValue];
            initStringUnderstood = YES;
        }
      if([[positioningComponents objectAtIndex:0] isEqualToString:@"STAT"] && [positioningComponents count] == 4){
            _type = @"STAT";
            _signalThreshold = [[positioningComponents objectAtIndex:1] doubleValue];
            _maxPos = [[positioningComponents objectAtIndex:2] doubleValue];
            if([[positioningComponents objectAtIndex:3] isEqualToString:@"WSO"]){
                _stopEntryOnWeakening = YES;
            }
            initStringUnderstood = YES;
        }
           
        if(!initStringUnderstood){
            [NSException raise:@"Don't understand positioning:" format:@"%@", initString];
        }
    }
    return self;
}

-(double)positionCushion
{
    return POSITION_CUSHION;
}

-(long)leadTimeRequired
{
    long leadTimeRequired = 0;
    if([[self stepUnit] isEqualToString:@"S"]){
        leadTimeRequired = [self stepLength];
    }
    if([[self stepUnit] isEqualToString:@"M"]){
        leadTimeRequired = [self stepLength] * 60;
    }
    if([[self stepUnit] isEqualToString:@"H"]){
        leadTimeRequired = [self stepLength] * 60 * 60;
    }
    if([[self stepUnit] isEqualToString:@"D"]){
        leadTimeRequired = [self stepLength]  * 24 * 60 * 60;
    }
    return leadTimeRequired;
}

-(long)leadTicsRequired
{
    long leadTicsRequired = 0;
    if([[self stepUnit] isEqualToString:@"T"]){
        leadTicsRequired = [self stepLength];
    }
    return leadTicsRequired;
}


+(BOOL)basicCheck: (NSString *) positioningString
{
    BOOL understood = NO;
    NSArray *positioningComponents = [positioningString componentsSeparatedByString:@"/"];
    // Simple Trinary Positioning
    if([[positioningComponents objectAtIndex:0] isEqualToString:@"STP"]){
        understood = YES;
    }
    // Signal Feedback Proportional
    if([[positioningComponents objectAtIndex:0] isEqualToString:@"SFP"]){
        understood = YES;
    }
    // Signal Strength Positioning
    if([[positioningComponents objectAtIndex:0] isEqualToString:@"SSP"]){
        understood = YES;
    }
    // Static Positioning
    if([[positioningComponents objectAtIndex:0] isEqualToString:@"STAT"]){
        understood = YES;
    }
    return understood;
}

-(NSArray *) variablesNeeded
{
    NSMutableArray *varsNeeded = [[NSMutableArray alloc] init];
    if([[self type] isEqualToString:@""])
    {
        
    }else{
        if([[self type] isEqualToString:@"SFP"])
        {
            [varsNeeded addObject:[NSString stringWithFormat:@"EMA/%d",[self perfSmoothParam]]];
        }
    }
    return varsNeeded;
}


@synthesize positioningString = _positioningString;
@synthesize type = _type;
@synthesize signalThreshold = _signalThreshold;
@synthesize stepProportion = _stepProportion;
@synthesize stepLength = _stepLength;
@synthesize stepUnit = _stepUnit;
@synthesize perfSmoothParam = _perfSmoothParam;
@synthesize maxPos = _maxPos;
@synthesize stopEntryOnWeakening = _stopEntryOnWeakening;
@end
