//
//  SignalSystem.m
//  Simple Sim
//
//  Created by Martin O'Connor on 28/08/2012.
//  Copyright (c) 2015 MARTIN OCONNOR. All rights reserved.
//

#import "SignalSystem.h"
#import "UtilityFunctions.h"


@implementation SignalSystem

static NSArray *seriesNames;
static NSArray *signalNames;



+(void)load {
    [super load];
    seriesNames = [[NSArray alloc] initWithObjects:
                   @"EMA",[NSNumber numberWithInt:1],
                   @"EMA2",[NSNumber numberWithInt:2],
                   @"REMA",[NSNumber numberWithInt:1],
                   @"EMB",[NSNumber numberWithInt:3],
                   @"ATR",[NSNumber numberWithInt:1],
                   @"OHLC",[NSNumber numberWithInt:0],
                   @"TR2",[NSNumber numberWithInt:1],
                   @"FDIM",[NSNumber numberWithInt:0],
                   @"MACD",[NSNumber numberWithInt:3],
                   @"EMAD",[NSNumber numberWithInt:2],
                   @"EMBD",[NSNumber numberWithInt:5],
                   @"AEMAD",[NSNumber numberWithInt:4],
                   @"AEMBD",[NSNumber numberWithInt:7],
                   @"EMAG",[NSNumber numberWithInt:3],
                   @"TICN",[NSNumber numberWithInt:0],
                   @"GRDPOS",[NSNumber numberWithInt:4],
                   @"EDPU",[NSNumber numberWithInt:2],
                   @"PACS",[NSNumber numberWithInt:3],
                   @"BUT",[NSNumber numberWithInt:1],
                   @"BUT3",[NSNumber numberWithInt:1], nil];
     
    
    signalNames = [[NSArray alloc] initWithObjects:
                   @"SECO", [NSNumber numberWithInt:2],
                   @"MACD", [NSNumber numberWithInt:3],
                   @"EMAD", [NSNumber numberWithInt:2],
                   @"MCD2", [NSNumber numberWithInt:3],
                   @"EMA", [NSNumber numberWithInt:2],
                   @"REMA", [NSNumber numberWithInt:2],
                   @"AEMAD", [NSNumber numberWithInt:4],
                   @"AEMBD", [NSNumber numberWithInt:7],
                   @"PACS", [NSNumber numberWithInt:3],
                   @"EMB", [NSNumber numberWithInt:4],
                   @"EMBD", [NSNumber numberWithInt:5], nil];
   }

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
 
        if([[signalComponents objectAtIndex:0] isEqualToString:@"AEMBD"] && [signalComponents count]==8){
            _type = @"AEMBD";
            
            NSRange firstBracket = [signalStripped rangeOfString:@"/"];
            NSString *pacsString = [signalStripped substringFromIndex:firstBracket.location+1];
            NSRange lastBracket = [pacsString rangeOfString:@"/"
                                                    options:NSBackwardsSearch];
            
            _stepAdjustment = [[pacsString substringFromIndex:lastBracket.location+1] doubleValue];
            _pacsString = [pacsString substringToIndex:lastBracket.location];
            lastBracket = [pacsString rangeOfString:@"/"
                                            options:NSBackwardsSearch];
            
            _fastCode = [[pacsString substringFromIndex:lastBracket.location+1] intValue];
            _pacsString = [pacsString substringToIndex:lastBracket.location];
            lastBracket = [pacsString rangeOfString:@"/"
                                            options:NSBackwardsSearch];
            
            _threshold = [[pacsString substringFromIndex:lastBracket.location+1] doubleValue];
            _pacsString = [pacsString substringToIndex:lastBracket.location];
            lastBracket = [pacsString rangeOfString:@"/"
                                            options:NSBackwardsSearch];

            _slowCode = [[pacsString substringFromIndex:lastBracket.location+1] intValue];
            _pacsString = [pacsString substringToIndex:lastBracket.location];
            lastBracket = [pacsString rangeOfString:@"/"
                                            options:NSBackwardsSearch];
            
            initStringUnderstood = YES;
        }
        
        if([[signalComponents objectAtIndex:0] isEqualToString:@"EMBD"] && [signalComponents count]==6){
            _type = @"EMBD";
            
            NSRange firstBracket = [signalStripped rangeOfString:@"/"];
            NSString *pacsString = [signalStripped substringFromIndex:firstBracket.location+1];
            NSRange lastBracket = [pacsString rangeOfString:@"/"
                                                    options:NSBackwardsSearch];
            
            _pacsString = [pacsString substringToIndex:lastBracket.location];
            lastBracket = [pacsString rangeOfString:@"/"
                                            options:NSBackwardsSearch];
            
            _pacsString = [pacsString substringToIndex:lastBracket.location];
            lastBracket = [pacsString rangeOfString:@"/"
                                            options:NSBackwardsSearch];
            
            _slowCode = [[signalComponents objectAtIndex:4] intValue];
            _signalSmooth = [[signalComponents objectAtIndex:5] intValue];
            initStringUnderstood = YES;
        }

        
        
        
        if([[signalComponents objectAtIndex:0] isEqualToString:@"AEMAD"] && [signalComponents count]==5){
            _type = @"AEMAD";
            _slowCode = [[signalComponents objectAtIndex:1] intValue];
            _threshold = [[signalComponents objectAtIndex:2] doubleValue];
            _fastCode = [[signalComponents objectAtIndex:3] intValue];
            _stepAdjustment = [[signalComponents objectAtIndex:4] doubleValue];
            initStringUnderstood = YES;
        }

        if([[signalComponents objectAtIndex:0] isEqualToString:@"MCD2"] && [signalComponents count]==4){
            _type = @"MCD2";
            _fastCode = [[signalComponents objectAtIndex:1] intValue];
            _slowCode = [[signalComponents objectAtIndex:2] intValue];
            _signalSmooth = [[signalComponents objectAtIndex:3] intValue];
            initStringUnderstood = YES;
        }
        
        if([signalComponentsPlusExtras count] > 1){
            for( int i = 1; i < [signalComponentsPlusExtras count];i++ )
            {
                NSString *extra = [signalComponentsPlusExtras objectAtIndex:i];
                NSArray *components = [extra componentsSeparatedByString:@"/"];
                NSString *typeOfExtra = [components objectAtIndex:0];
                
                BOOL nameUnderstood = NO;
                for(int j = 0; j < [seriesNames count]; j = j+2){
                    if([typeOfExtra isEqualToString:[seriesNames objectAtIndex:j]]){
                        nameUnderstood = YES;
                        break;
                    }
                }
                
                if(!nameUnderstood){
                    initStringUnderstood = NO;
                    break;
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


+ (NSString *) signalListAsString
{
    NSString *signalList, *oneSignal;
    NSArray *alphabet = [NSArray arrayWithObjects:@"A",@"B",@"C",@"D",@"E",@"F",@"G",@"H",@"I",@"J",@"K",@"L", nil];
    int nParams = 0;
    for(int i = 0; i < [signalNames count]; i = i+2){
        oneSignal = [signalNames objectAtIndex:i];
        nParams = [[signalNames objectAtIndex:i+1] intValue];
        for(int j = 0; j < nParams; j++){
            oneSignal = [NSString stringWithFormat:@"%@/%@",oneSignal,[alphabet objectAtIndex:j]];
        }
        if(i > 0 ){
            signalList =  [NSString stringWithFormat:@"%@\n%@",signalList,oneSignal];
        }else{
            signalList = oneSignal;
        }
    }
    return signalList;
}

+ (NSString *) seriesListAsString
{
    NSString *seriesList, *oneSeries;
    NSArray *alphabet = [NSArray arrayWithObjects:@"A",@"B",@"C",@"D",@"E",@"F",@"G",@"H",@"I",@"J",@"K",@"L", nil];
    int nParams = 0;
    for(int i = 0; i < [seriesNames count]; i = i+2){
        oneSeries = [seriesNames objectAtIndex:i];
        nParams = [[seriesNames objectAtIndex:i+1] intValue];
        for(int j = 0; j < nParams; j++){
            oneSeries = [NSString stringWithFormat:@"%@/%@",oneSeries,[alphabet objectAtIndex:j]];
        }
        if(i > 0 ){
            seriesList =  [NSString stringWithFormat:@"%@\n%@",seriesList,oneSeries];
        }else{
            seriesList = oneSeries;
        }
    }
    return seriesList;
}

+(BOOL)basicSignalCheck: (NSString *) signalString
{
    BOOL understood = YES;
    NSArray *signalArray = [signalString componentsSeparatedByString:@";"];
    
    if([signalArray count] > 0){
        for( int i = 0; i < [signalArray count];i++)
        {
            NSString *singleSignal = [signalArray objectAtIndex:i];
            NSArray *components = [singleSignal componentsSeparatedByString:@"/"];
            NSString *typeOfSignal = [components objectAtIndex:0];
            
            BOOL nameUnderstood = NO;
            for(int j = 0; j < [signalNames count]; j = j+2){
                if([typeOfSignal isEqualToString:[signalNames objectAtIndex:j]]){
                    if(([components count] -1) == [[signalNames objectAtIndex:j+1] intValue]){
                        nameUnderstood = YES;
                        break;
                    }
                }
            }
            if(!nameUnderstood){
                understood = NO;
                break;
            }
        }
    }
    
    return understood;
//    BOOL understood = NO;
//    NSArray *signalComponents = [signalString componentsSeparatedByString:@"/"];
//    if([[signalComponents objectAtIndex:0] isEqualToString:@"SECO"]  && [signalComponents count] == 3){
//        understood = YES;
//    }
//    if([[signalComponents objectAtIndex:0] isEqualToString:@"MACD"]  && [signalComponents count] == 4){
//        understood = YES;
//    }
//    if([[signalComponents objectAtIndex:0] isEqualToString:@"EMAD"]  && [signalComponents count] == 3){
//        understood = YES;
//    }
//    if([[signalComponents objectAtIndex:0] isEqualToString:@"MCD2"]  && [signalComponents count] == 4){
//        understood = YES;
//    }
//    if([[signalComponents objectAtIndex:0] isEqualToString:@"EMA"] && [signalComponents count] == 3){
//        understood = YES;
//    }
//    if([[signalComponents objectAtIndex:0] isEqualToString:@"REMA"] && [signalComponents count] == 3){
//        understood = YES;
//    }
//    if([[signalComponents objectAtIndex:0] isEqualToString:@"AEMAD"] && [signalComponents count] == 5){
//        understood = YES;
//    }
//    if([[signalComponents objectAtIndex:0] isEqualToString:@"AEMBD"] && [signalComponents count] == 8){
//        understood = YES;
//    }
//    if([[signalComponents objectAtIndex:0] isEqualToString:@"PACS"] && [signalComponents count] == 4){
//        understood = YES;
//    }
//    if([[signalComponents objectAtIndex:0] isEqualToString:@"EMB"] && [signalComponents count] == 5){
//        understood = YES;
//    }
//    if([[signalComponents objectAtIndex:0] isEqualToString:@"EMBD"] && [signalComponents count] == 6){
//        understood = YES;
//    }
//    return understood;
}
+(BOOL)basicSeriesCheck: (NSString *) seriesString
{
    BOOL understood = YES;
    NSArray *seriesArray = [seriesString componentsSeparatedByString:@";"];
    
    
    if([seriesString length] > 0 && [seriesArray count] > 0){
        for( int i = 0; i < [seriesArray count];i++)
        {
            NSString *singleSeries = [seriesArray objectAtIndex:i];
            NSArray *components = [singleSeries componentsSeparatedByString:@"/"];
            NSString *typeOfSeries = [components objectAtIndex:0];
            
            BOOL nameUnderstood = NO;
            for(int j = 0; j < [seriesNames count]; j = j+2){
                if([typeOfSeries isEqualToString:[seriesNames objectAtIndex:j]]){
                    if(([components count] -1) == [[seriesNames objectAtIndex:j+1] intValue]){
                        nameUnderstood = YES;
                        break;
                    }
                }
            }
            if(!nameUnderstood){
                understood = NO;
                break;
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
    if([[self type] isEqualToString:@"AEMAD"]){
        [varsNeeded addObject:[NSString stringWithFormat:@"EMA/%d",[self fastCode]]];
        [varsNeeded addObject:[NSString stringWithFormat:@"EMA/%d",[self slowCode]]];
        [varsNeeded addObject:[NSString stringWithFormat:@"EMAD/%d/%d",[self fastCode],[self fastCode]]];
        [varsNeeded addObject:[NSString stringWithFormat:@"EMAD/%d/%d",[self slowCode],[self slowCode]]];
        [varsNeeded addObject:[[[self signalString] componentsSeparatedByString:@";"]  objectAtIndex:0]];
    }
    
    if([[self type] isEqualToString:@"AEMBD"]){
        NSString *signalDescription = [[[self signalString] componentsSeparatedByString:@";"]  objectAtIndex:0];
        NSRange firstBracket = [signalDescription rangeOfString:@"/"];
        
        NSString *pacsString = [signalDescription substringFromIndex:firstBracket.location+1];
        NSRange lastBracket = [pacsString rangeOfString:@"/"
                                                options:NSBackwardsSearch];
        pacsString = [pacsString substringToIndex:lastBracket.location];
        lastBracket = [pacsString rangeOfString:@"/"
                                        options:NSBackwardsSearch];
        
        int fastCode = [[pacsString substringFromIndex:lastBracket.location+1] intValue];
        
        
        pacsString = [pacsString substringToIndex:lastBracket.location];
        lastBracket = [pacsString rangeOfString:@"/"
                                        options:NSBackwardsSearch];
        pacsString = [pacsString substringToIndex:lastBracket.location];
        lastBracket = [pacsString rangeOfString:@"/"
                                        options:NSBackwardsSearch];
        
        int slowCode =  [[pacsString substringFromIndex:lastBracket.location+1] intValue];
        pacsString = [pacsString substringToIndex:lastBracket.location];
        
        [varsNeeded addObject:[NSString stringWithFormat:@"PACS/%@",[pacsString substringToIndex:lastBracket.location]]];
        [varsNeeded addObject:[NSString stringWithFormat:@"EMB/%@/%d",pacsString, fastCode]];
        [varsNeeded addObject:[NSString stringWithFormat:@"EMB/%@/%d",pacsString, slowCode]];
        [varsNeeded addObject:[NSString stringWithFormat:@"EMBD/%@/%d/%d",pacsString, fastCode,fastCode]];
        [varsNeeded addObject:[NSString stringWithFormat:@"EMBD/%@/%d/%d",pacsString, slowCode,slowCode]];
        [varsNeeded addObject:signalDescription];
    }
    
    if([[self type] isEqualToString:@"EMBD"]){
        NSString *signalDescription = [[[self signalString] componentsSeparatedByString:@";"]  objectAtIndex:0];
        NSRange firstBracket = [signalDescription rangeOfString:@"/"];
        
        NSString *pacsString = [signalDescription substringFromIndex:firstBracket.location+1];
        NSRange lastBracket = [pacsString rangeOfString:@"/"
                                                options:NSBackwardsSearch];
        
        
        int deltaCode = [[pacsString substringFromIndex:lastBracket.location+1] intValue];
        
        pacsString = [pacsString substringToIndex:lastBracket.location];
        lastBracket = [pacsString rangeOfString:@"/"
                                        options:NSBackwardsSearch];
        
        int emaCode =  [[pacsString substringFromIndex:lastBracket.location+1] intValue];
         
        pacsString = [pacsString substringToIndex:lastBracket.location];
            
        [varsNeeded addObject:[NSString stringWithFormat:@"PACS/%@",[pacsString substringToIndex:lastBracket.location]]];
        [varsNeeded addObject:[NSString stringWithFormat:@"EMB/%@/%d",pacsString, emaCode]];
        [varsNeeded addObject:[NSString stringWithFormat:@"EMBD/%@/%d/%d",pacsString, emaCode,deltaCode]];
    }
   
    if([[self type] isEqualToString:@"EMAD"]){
        [varsNeeded addObject:[NSString stringWithFormat:@"EMA/%d",[self slowCode]]];
        [varsNeeded addObject:[NSString stringWithFormat:@"EMAD/%d/%d",[self slowCode],[self signalSmooth]]];
        if([self extras] != nil){
            BOOL doEDPU = NO;
            for( int i = 0; i < [[self extras] count];i++ )
            {
                if([[[self extras] objectAtIndex:i] isEqualToString:[NSString stringWithFormat:@"EDPU/%d/%d",[self slowCode],[self signalSmooth]]]){
                    doEDPU = YES;
                    
                }
            }
        }
    }
      
    if([[self type] isEqualToString:@"MACD"] || [[self type] isEqualToString:@"MCD2"]){
        [varsNeeded addObject:[NSString stringWithFormat:@"MACD/%d/%d/%d",[self fastCode],[self slowCode],[self signalSmooth]]];
    }
   
    if([self extras] != Nil){
        for( int i = 0; i < [[self extras] count];i++ )
        {
            NSString *extra = [[self extras] objectAtIndex:i];
            [varsNeeded addObject:extra];
            NSArray *components = [extra componentsSeparatedByString:@"/"];
            
            if([[components objectAtIndex:0] isEqualToString:@"MACD"] ||
               [[components objectAtIndex:0] isEqualToString:@"MCD2"]  ||
               [[components objectAtIndex:0] isEqualToString:@"EDPU"])
            {
                [varsNeeded addObject:[NSString stringWithFormat:@"EMA/%@",[components objectAtIndex:1]]];
                [varsNeeded addObject:[NSString stringWithFormat:@"EMA/%@",[components objectAtIndex:3]]];
            }
            
            if([[components objectAtIndex:0] isEqualToString:@"AEMAD"]){
                [varsNeeded addObject:[NSString stringWithFormat:@"EMA/%@",[components objectAtIndex:1]]];
                [varsNeeded addObject:[NSString stringWithFormat:@"EMA/%@",[components objectAtIndex:3]]];
                [varsNeeded addObject:[NSString stringWithFormat:@"EMAD/%@/%@",[components objectAtIndex:1],[components objectAtIndex:1]]];
                [varsNeeded addObject:[NSString stringWithFormat:@"EMAD/%@/%@",[components objectAtIndex:3],[components objectAtIndex:3]]];
            }
            
            if([[components objectAtIndex:0] isEqualToString:@"AEMBD"]){
                NSRange firstBracket = [extra rangeOfString:@"/"];
                NSString *pacsString = [extra substringFromIndex:firstBracket.location+1];
                NSRange lastBracket = [pacsString rangeOfString:@"/"
                                                       options:NSBackwardsSearch];
                int fastCode = [[pacsString substringFromIndex:lastBracket.location] intValue];
                pacsString = [pacsString substringToIndex:lastBracket.location];
                lastBracket = [pacsString rangeOfString:@"/"
                                               options:NSBackwardsSearch];
                int slowCode =  [[pacsString substringFromIndex:lastBracket.location] intValue];
                [varsNeeded addObject:[NSString stringWithFormat:@"PACS%@",[pacsString substringToIndex:lastBracket.location]]];
                [varsNeeded addObject:[NSString stringWithFormat:@"EMB/%@/%d",pacsString, fastCode]];
                [varsNeeded addObject:[NSString stringWithFormat:@"EMB/%@/%d",pacsString, slowCode]];
                [varsNeeded addObject:[NSString stringWithFormat:@"EMBD/%@/%d",pacsString, fastCode]];
                [varsNeeded addObject:[NSString stringWithFormat:@"EMBD/%@/%d",pacsString, slowCode]];
                [varsNeeded addObject:[[[self signalString] componentsSeparatedByString:@";"]  objectAtIndex:0]];
            }
            
            if([[components objectAtIndex:0] isEqualToString:@"GRDPOS"] ||
               [[components objectAtIndex:0] isEqualToString:@"EMAD"] ||
               [[components objectAtIndex:0] isEqualToString:@"EMADG"]){
                [varsNeeded addObject:[NSString stringWithFormat:@"EMA/%@",[components objectAtIndex:1]]];
            }
            
            if([[components objectAtIndex:0] isEqualToString:@"EMADG"]){
                [varsNeeded addObject:[NSString stringWithFormat:@"EMAD/%@/%@",[components objectAtIndex:1],[components objectAtIndex:2]]];
            }
            
            if([[components objectAtIndex:0] isEqualToString:@"EMBD"]){
                NSRange firstBracket = [extra rangeOfString:@"/"];
                NSString *pacsString = [extra substringFromIndex:firstBracket.location];
                NSRange lastBracket = [pacsString rangeOfString:@"/"
                                                        options:NSBackwardsSearch];
                //int emadCode = [[pacsString substringFromIndex:lastBracket.location+1] intValue];
                pacsString = [pacsString substringToIndex:lastBracket.location];
                lastBracket = [pacsString rangeOfString:@"/"
                                                options:NSBackwardsSearch];
                int emaCode = [[pacsString substringFromIndex:(lastBracket.location+1)] intValue];
                pacsString = [pacsString substringToIndex:lastBracket.location];
                [varsNeeded addObject:[NSString stringWithFormat:@"PACS%@",[pacsString substringToIndex:lastBracket.location]]];
                [varsNeeded addObject:[NSString stringWithFormat:@"EMB%@/%d",pacsString, emaCode]];
            }
            
            if([[components objectAtIndex:0] isEqualToString:@"EMB"]){
                NSRange firstBracket = [extra rangeOfString:@"/"];
                NSString *subString = [extra substringFromIndex:firstBracket.location];
                NSRange lastBracket = [subString rangeOfString:@"/"
                                                       options:NSBackwardsSearch];
                [varsNeeded addObject:[NSString stringWithFormat:@"PACS%@",[subString substringToIndex:lastBracket.location]]];
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


//@synthesize signalString = _signalString;
//@synthesize type = _type;    
//@synthesize fastCode = _fastCode;
//@synthesize slowCode = _slowCode;
//@synthesize signalSmooth = _signalSmooth;
//@synthesize extras = _extras;
//@synthesize miscStoredInfoDictionary = _miscStoredInfoDictionary;
@end
