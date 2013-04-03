//
//  DataProcessor.h
//  Simple Sim
//
//  Created by Martin O'Connor on 26/04/2012.
//  Copyright (c) 2012 OCONNOR RESEARCH. All rights reserved.
//

#import <Foundation/Foundation.h>
@class PositioningSystem;
@class SignalSystem;
@class DataSeries;

@interface DataProcessor : NSObject

+ (NSDictionary *) addToDataSeries: (NSDictionary *) dataDictionary
                  DerivedVariables: (NSArray *) derivedVariables
                  WithTrailingData: (NSDictionary *) previousDataDetails
                   AndSignalSystem: (SignalSystem *) signalSystem;
//+ (BOOL)strategyUnderstood:(NSString *) strategyString;
+ (long)leadTimeRequired:(NSString *) strategyString;
+ (long)leadTicsRequired:(NSString *) strategyString;
@end
