//
//  PositioningSystem.h
//  Simple Sim
//
//  Created by Martin O'Connor on 17/08/2012.
//  Copyright (c) 2012 OCONNOR RESEARCH. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface PositioningSystem : NSObject{
    NSString *_positioningString;
    NSString *_type;
    double _signalThreshold;
    double _stepProportion;
    double _stepLength;
    int _perfSmoothParam;
    NSString *_stepUnit;
}

@property (retain, readonly) NSString *positioningString;
@property (retain, readonly) NSString *type;
@property (readonly) double signalThreshold;
@property (readonly) double stepProportion;
@property (readonly) double stepLength;
@property (retain, readonly) NSString *stepUnit;
@property (readonly) double positionCushion;
@property (readonly) int perfSmoothParam;

-(id) init;
-(id) initWithString: (NSString *) initString;
-(long) leadTimeRequired;
-(long) leadTicsRequired;
+(BOOL) basicCheck: (NSString *) positioningString;
-(NSArray *) variablesNeeded;
@end
