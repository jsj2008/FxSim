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
}


- (id) init;
- (id) initWithString: (NSString *) signalString;
+ (BOOL) basicCheck: (NSString *) signalString;
- (NSArray *) variablesNeeded;

@property (readonly) NSString *signalString;
@property (readonly) NSString *type;
@property (readonly) int fastCode;
@property (readonly) int slowCode;
@property (readonly) int signalSmooth;
@property (readonly) NSArray *extras;
@end
