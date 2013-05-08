//
//  SignalSystem.m
//  Simple Sim
//
//  Created by Martin O'Connor on 28/08/2012.
//  Copyright (c) 2012 OCONNOR RESEARCH. All rights reserved.
//

#import "SignalSystem.h"
#import "UtilityFunctions.h"

@implementation SignalSystem

-(id)init
{
    return [self initWithString:@""];
    
}

-(id)initWithString: (NSString *) signalString
{
    if ( (self = [super init]) ) {
        BOOL initStringUnderstood = NO;
        _miscStoredInfoDictionary = [[NSMutableDictionary alloc] init];
        _signalString = signalString;
        _threshold = 0.0;
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
        
        if([[signalComponents objectAtIndex:0] isEqualToString:@"EMAD"] && [signalComponents count]==3){
            _type = @"EMAD";
            _slowCode = [[signalComponents objectAtIndex:1] intValue];
            _signalSmooth = [[signalComponents objectAtIndex:2] intValue];
            initStringUnderstood = YES;
        }
        if([[signalComponents objectAtIndex:0] isEqualToString:@"MCD2"] && [signalComponents count]==4){
            _type = @"MCD2";
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
//        if([[signalComponents objectAtIndex:0] isEqualToString:@"GRIDPOS"]  && [signalComponents count]==5){
//            _type = @"GRIDPOS";
//            _slowCode = [[signalComponents objectAtIndex:1] intValue];
//            initStringUnderstood = YES;
//        }
        
        if([signalComponentsPlusExtras count] > 1){
            for( int i = 1; i < [signalComponentsPlusExtras count];i++ )
            {
                NSString *extra = [signalComponentsPlusExtras objectAtIndex:i];
                NSArray *components = [extra componentsSeparatedByString:@"/"];
                NSString *typeOfExtra = [components objectAtIndex:0];
                if(!([typeOfExtra isEqualToString:@"EMA"] ||
                     [typeOfExtra isEqualToString:@"ATR"] ||
                     [typeOfExtra isEqualToString:@"OHLC"] ||
                     [typeOfExtra isEqualToString:@"TR2"] ||
                     [typeOfExtra isEqualToString:@"FDIM"] ||
                     [typeOfExtra isEqualToString:@"MACD"] ||
                     [typeOfExtra isEqualToString:@"EMAD"] ||
                     [typeOfExtra isEqualToString:@"TICN"] ||
                     [typeOfExtra isEqualToString:@"GRDPOS"])){
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

+(BOOL)basicSignalCheck: (NSString *) signalString
{
    BOOL understood = NO;
    NSArray *signalComponents = [signalString componentsSeparatedByString:@"/"];
    if([[signalComponents objectAtIndex:0] isEqualToString:@"SECO"]  && [signalComponents count] == 3){
        understood = YES;
    }
    if([[signalComponents objectAtIndex:0] isEqualToString:@"MACD"]  && [signalComponents count] == 4){
        understood = YES;
    }
    if([[signalComponents objectAtIndex:0] isEqualToString:@"EMAD"]  && [signalComponents count] == 3){
        understood = YES;
    }
    if([[signalComponents objectAtIndex:0] isEqualToString:@"MCD2"]  && [signalComponents count] == 4){
        understood = YES;
    }
    if([[signalComponents objectAtIndex:0] isEqualToString:@"EMA"] && [signalComponents count] == 3){
        understood = YES;
    }
    
       return understood;
}
+(BOOL)basicSeriesCheck: (NSString *) seriesString
{
    BOOL understood = YES;
    NSArray *seriesArray = [seriesString componentsSeparatedByString:@";"];
    
    if([seriesArray count] > 0){
        for( int i = 1; i < [seriesArray count];i++ )
        {
            NSString *singleSeries = [seriesArray objectAtIndex:i];
            NSArray *components = [singleSeries componentsSeparatedByString:@"/"];
            NSString *typeOfSeries = [components objectAtIndex:0];
            if(!([typeOfSeries isEqualToString:@"EMA"] ||
                 [typeOfSeries isEqualToString:@"ATR" ] ||
                 [typeOfSeries isEqualToString:@"OHLC"] ||
                 [typeOfSeries isEqualToString:@"TR2" ] ||
                 [typeOfSeries isEqualToString:@"FDIM" ] ||
                 [typeOfSeries isEqualToString:@"MACD" ] ||
                 [typeOfSeries isEqualToString:@"EMAD" ] ||
                 [typeOfSeries isEqualToString:@"MCD2" ] ||
                 [typeOfSeries isEqualToString:@"TICN" ] ||
                 [typeOfSeries isEqualToString:@"GRDPOS" ])){
                understood = NO;
            }
        }
    }
    
    return understood;
}

-(NSArray *) variablesNeeded
{
    NSMutableArray *varsNeeded = [[NSMutableArray alloc] init];
    if([[self type] isEqualToString:@"SECO"] ||
       [[self type] isEqualToString:@"MACD"] ||
       [[self type] isEqualToString:@"MCD2"])
    {
        [varsNeeded addObject:[NSString stringWithFormat:@"EMA/%d",[self fastCode]]];
        [varsNeeded addObject:[NSString stringWithFormat:@"EMA/%d",[self slowCode]]];
    }
    if([[self type] isEqualToString:@"EMAD"]){
        [varsNeeded addObject:[NSString stringWithFormat:@"EMA/%d",[self slowCode]]];
        [varsNeeded addObject:[NSString stringWithFormat:@"EMAD/%d/%d",[self slowCode],[self signalSmooth]]];
    }
    if([[self type] isEqualToString:@"MACD"] || [[self type] isEqualToString:@"MCD2"]){
        [varsNeeded addObject:[NSString stringWithFormat:@"MACD/%d/%d/%d",[self fastCode],[self slowCode],[self signalSmooth]]];
    }
//    if([[self type] isEqualToString:@"GRDPOS"]){
//        [varsNeeded addObject:[NSString stringWithFormat:@"EMA/%d",[self slowCode]]];
//    }
    
    if([self extras] != Nil){
        for( int i = 0; i < [[self extras] count];i++ )
        {
            NSString *extra = [[self extras] objectAtIndex:i];
            [varsNeeded addObject:extra];
            NSArray *components = [extra componentsSeparatedByString:@"/"];
            if([[components objectAtIndex:0] isEqualToString:@"MACD"] ||
               [[components objectAtIndex:0] isEqualToString:@"MCD2"] ||
               [[components objectAtIndex:0] isEqualToString:@"EMAD"])
            {
                [varsNeeded addObject:[NSString stringWithFormat:@"EMA/%@",[components objectAtIndex:1]]];
                [varsNeeded addObject:[NSString stringWithFormat:@"EMA/%@",[components objectAtIndex:2]]];
            }
            if([[components objectAtIndex:0] isEqualToString:@"GRDPOS"]){
                [varsNeeded addObject:[NSString stringWithFormat:@"EMA/%@",[components objectAtIndex:1]]];
            }
        }
    }
    return varsNeeded;
}

- (long) leadTimeRequired
{
    long timeRequired = 0;
    return timeRequired;
}

- (long) leadTicsRequired
{
    long ticsRequired = 0;
    if([[self type] isEqualToString:@"EMAD"]){
        ticsRequired = [UtilityFunctions  fib:[self signalSmooth]];
    }
    return ticsRequired;
}


@synthesize signalString = _signalString;
@synthesize type = _type;    
@synthesize fastCode = _fastCode;
@synthesize slowCode = _slowCode;
@synthesize signalSmooth = _signalSmooth;
@synthesize extras = _extras;
@synthesize miscStoredInfoDictionary = _miscStoredInfoDictionary;
@end
