//
//  PositioningSystem.h
//  Simple Sim
//
//  Created by Martin O'Connor on 17/08/2012.
//  Copyright (c) 2012 OCONNOR RESEARCH. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface PositioningSystem : NSObject{
//    NSString *_positioningString;
//    NSString *_type;
//    double _signalThreshold;
//    double _stepProportion;
//    double _stepLength;
//    int _perfSmoothParam;
//    int _maxPos;
//    BOOL _stopEntryOnWeakeningSignal;
//    BOOL _stopEntryOnWeakeningPrice;
//    BOOL _exitOnWeakeningPrice;
//    double _stopEntryOnWeakeningPriceThreshold;
//    long _stopEntryOnWeakeningSignalThreshold;
//    
//    long _stopEntryOnWeakeningPriceLagTime;
//    
//    double _exitOnWeakeningPriceThreshold;
//    NSString *_stepUnit;
//    long _laggedSignalInterval;
//    long _laggedPriceInterval;
}

@property (retain, readonly) NSString *positioningString;
@property (retain, readonly) NSString *type;
@property (readonly) BOOL staticThreshold;
@property (readonly) double signalThreshold;
@property (readonly) double signalInThreshold;
@property (readonly) double signalOutThreshold;
@property (readonly) long emadFilterParam1;
@property (readonly) long emadFilterParam2;
@property (readonly) double shortInFilterThreshold;
@property (readonly) double shortOutFilterThreshold;
@property (readonly) double longInFilterThreshold;
@property (readonly) double longOutFilterThreshold;

@property (readonly) double stepProportion;
@property (readonly) double stepLength;
@property (retain, readonly) NSString *stepUnit;
@property (readonly) double positionCushion;
@property (readonly) int perfSmoothParam;
@property (readonly) int maxPos;
@property (readonly) BOOL stopEntryOnWeakeningSignal;
@property (readonly) BOOL stopEntryOnWeakeningPrice;
@property (readonly) BOOL exitOnWeakeningPrice;
@property (readonly) BOOL exitOnBrem;
@property (readonly) double exitOnWeakeningPriceThreshold;
@property (readonly) int exitOnBremThreshold;
@property (readonly) NSString *bremString;
@property (readonly) double stopEntryOnWeakeningPriceThreshold;
@property (readonly) long stopEntryOnWeakeningSignalThreshold;
@property (readonly) long stopEntryOnWeakeningPriceLagTime;
@property (readonly) long stopEntryOnWeakeningSignalLagTime;

- (id) init;
- (id) initWithString: (NSString *) initString;
- (long) leadTimeRequired;
- (long) leadTicsRequired;
+ (BOOL) basicCheck: (NSString *) positioningString;
- (NSArray *) variablesNeeded;
@end
