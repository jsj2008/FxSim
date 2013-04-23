//
//  SignalSystem.h
//  Simple Sim
//
//  Created by Martin O'Connor on 28/08/2012.
//  Copyright (c) 2012 OCONNOR RESEARCH. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SignalSystem : NSObject
{
    NSString *_signalString;
    NSString *_type;
    int _fastCode;
    int _slowCode;
    int _signalSmooth;
    NSArray *_extras;
    NSMutableDictionary *_miscStoredInfoDictionary;
}


- (id) init;
- (id) initWithString: (NSString *) signalString;
+ (BOOL) basicSignalCheck: (NSString *) signalString;
+ (BOOL) basicSeriesCheck: (NSString *) signalString;
- (NSArray *) variablesNeeded;
- (long) leadTimeRequired;
- (long) leadTicsRequired;

@property (readonly) NSString *signalString;
@property (readonly) NSString *type;
@property (readonly) int fastCode;
@property (readonly) int slowCode;
@property (readonly) int signalSmooth;
@property (readonly) NSArray *extras;
@property (readonly) NSMutableDictionary *miscStoredInfoDictionary;
@end
