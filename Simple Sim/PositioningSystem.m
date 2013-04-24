//
//  PositioningSystem.m
//  Simple Sim
//
//  Created by Martin O'Connor on 17/08/2012.
//  Copyright (c) 2012 OCONNOR RESEARCH. All rights reserved.
//

#import "PositioningSystem.h"
#define POSITION_CUSHION 0.25
#define SIGNAL_LAG_INTERVAL 1800

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
        _stopEntryOnWeakeningSignal = NO;
        _stopEntryOnWeakeningPrice = NO;
//        _laggedSignalInterval = 0;
//        _laggedPriceInterval = 0;
        _stopEntryOnWeakeningPriceLagTime = 0;
        _stopEntryOnWeakeningSignalLagTime = 0;
        _exitOnWeakeningPrice = NO;
        _exitOnWeakeningPriceThreshold = 0.0;
        _stopEntryOnWeakeningPriceThreshold = 0.0;
        _stopEntryOnWeakeningSignalThreshold = 0;
      
        
        NSArray *positioningInstructions = [initString componentsSeparatedByString:@";"];
        //Hack for backward compatibility
        if([positioningInstructions count] == 1 && [[initString substringFromIndex:[initString length]-3] isEqualToString:@"WSO"]){
            initString = [NSString stringWithFormat:@"%@;WSO",[initString substringToIndex:[initString length]-4]];
            positioningInstructions = [initString componentsSeparatedByString:@";"];
        }
        
        NSArray *mainCompenent = [[positioningInstructions objectAtIndex:0] componentsSeparatedByString:@"/"];
        
        // Simple Trinary Positioning
        if([[mainCompenent objectAtIndex:0] isEqualToString:@"STP"]  && [mainCompenent count] == 2){
            _type = @"STP";
            // this converts signal into 1 of three possible 
            //            // with parameter for threshold of zero
            _signalThreshold = [[mainCompenent objectAtIndex:1] doubleValue];
            initStringUnderstood = YES;
        }
 
        // Signal Feedback Proportional
        if([[mainCompenent objectAtIndex:0] isEqualToString:@"SFP"] && [mainCompenent count] == 6){
            _type = @"SFP";
            _signalThreshold = [[mainCompenent objectAtIndex:1] doubleValue];
            _stepProportion = [[mainCompenent objectAtIndex:2] doubleValue];
            _stepLength = [[mainCompenent objectAtIndex:3] doubleValue];
            _stepUnit = [mainCompenent objectAtIndex:4];
            _perfSmoothParam = [[mainCompenent objectAtIndex:5] intValue];
            // Seconds Ticks
            if([_stepUnit isEqualToString:@"S"] || [_stepUnit isEqualToString:@"M"] || [_stepUnit isEqualToString:@"H"] || [_stepUnit isEqualToString:@"D"] || [_stepUnit isEqualToString:@"T"] || [_stepUnit isEqualToString:@"P"]){
                initStringUnderstood = YES;
            }
        }
        // Signal Strength Positioning
        if([[mainCompenent objectAtIndex:0] isEqualToString:@"SSP"] && [mainCompenent count] == 4){
            _type = @"SSP";
        }
        // Static Positioning
        if([[mainCompenent objectAtIndex:0] isEqualToString:@"STAT"] && [mainCompenent count] == 3){
            _type = @"STAT";
            _signalThreshold = [[mainCompenent objectAtIndex:1] doubleValue];
            _maxPos = [[mainCompenent objectAtIndex:2] doubleValue];
            initStringUnderstood = YES;
        }
        
        //WSO weak Signal Override
        //PMO weak Price Override
        //WPE weak Price Exit
        BOOL extrasUnderstood = YES;
        for(int i = 1; i < [positioningInstructions count]; i++){
            NSArray *instructionDetails = [[positioningInstructions objectAtIndex:i] componentsSeparatedByString:@"/"];
            
            if(!([[instructionDetails objectAtIndex:0] isEqualToString:@"WSO"] ||
               [[instructionDetails objectAtIndex:0] isEqualToString:@"WPO"] ||
               [[instructionDetails objectAtIndex:0] isEqualToString:@"WPE"])){
                extrasUnderstood = NO;
            }
            if([[instructionDetails objectAtIndex:0] isEqualToString:@"WSO"]){
                _stopEntryOnWeakeningSignal = YES;
                //Backward compatibility 
                if([instructionDetails count] ==2){
                    _stopEntryOnWeakeningSignalLagTime = SIGNAL_LAG_INTERVAL;
                    _stopEntryOnWeakeningSignalThreshold = 10;
                }else{
                    _stopEntryOnWeakeningSignalLagTime = 60*[[instructionDetails objectAtIndex:1] intValue];
                    _stopEntryOnWeakeningSignalThreshold = [[instructionDetails objectAtIndex:2] intValue];
                }
                //_laggedSignalInterval = SIGNAL_LAG_INTERVAL;
            }
            if([[instructionDetails objectAtIndex:0] isEqualToString:@"WPO"]){
                _stopEntryOnWeakeningPrice = YES;
                _stopEntryOnWeakeningPriceLagTime = 60*[[instructionDetails objectAtIndex:1] intValue];
                _stopEntryOnWeakeningPriceThreshold = [[instructionDetails objectAtIndex:2] doubleValue];
            }
            if([[instructionDetails objectAtIndex:0] isEqualToString:@"WPE"]){
                _exitOnWeakeningPrice = YES;
                _exitOnWeakeningPriceThreshold = [[instructionDetails objectAtIndex:1] doubleValue];
            }
        }
        
        initStringUnderstood = initStringUnderstood && extrasUnderstood;
        
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
    if([self stopEntryOnWeakeningPrice] > leadTimeRequired){
        leadTimeRequired = [self stopEntryOnWeakeningPrice];
    }
    if([self stopEntryOnWeakeningSignal] > leadTimeRequired){
        leadTimeRequired = [self stopEntryOnWeakeningSignal];
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
@synthesize stopEntryOnWeakeningSignal = _stopEntryOnWeakeningSignal;
@synthesize stopEntryOnWeakeningPrice = _stopEntryOnWeakeningPrice;
//@synthesize laggedSignalInterval = _laggedSignalInterval;
//@synthesize laggedPriceInterval = _laggedPriceInterval;
@synthesize exitOnWeakeningPrice = _exitOnWeakeningPrice;
@synthesize exitOnWeakeningPriceThreshold = _exitOnWeakeningPriceThreshold;
@synthesize stopEntryOnWeakeningPriceThreshold = _stopEntryOnWeakeningPriceThreshold;
@synthesize stopEntryOnWeakeningPriceLagTime = _stopEntryOnWeakeningPriceLagTime;
@synthesize stopEntryOnWeakeningSignalLagTime = _stopEntryOnWeakeningSignalLagTime;
@synthesize stopEntryOnWeakeningSignalThreshold = _stopEntryOnWeakeningSignalThreshold;
@end
