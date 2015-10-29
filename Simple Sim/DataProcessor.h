//
//  DataProcessor.h
//  Simple Sim
//
//  Created by Martin O'Connor on 26/04/2012.
//  Copyright (c) 2015 MARTIN OCONNOR. All rights reserved.
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
@end
