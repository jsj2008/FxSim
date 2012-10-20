//
//  SimulationController.h
//  Simple Sim
//
//  Created by Martin O'Connor on 09/02/2012.
//  Copyright (c) 2012 OCONNOR RESEARCH. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SimulationOutput.h"
@class Simulation;
@class DataController;
@class SignalSystem;
@class PositioningSystem;
@class RulesSystem;

typedef enum {
    BID = -1,
    MID = 0,
    ASK = 1
} PriceType;
    
@interface SimulationController : NSObject {
    BOOL _doThreads;
    DataController *simDataController;
    NSMutableDictionary *interestRates;
    BOOL simulationDone;
    double cashPosition;

    Simulation *_workingSimulation;
    id<SimulationOutput> delegate;
}

@property BOOL cancelProcedure;
@property (retain) Simulation* workingSimulation;
@property BOOL doThreads;

+ (BOOL) positioningUnderstood:(NSString *) positioningString;
+ (BOOL) signalingUnderstood: (NSString *) signalString;
+ (BOOL) rulesUnderstood:(NSString *) rulesString;
+ (NSArray *) getNamesOfRequiredVariablesForSignal: (SignalSystem *) signalSystem
                                    AndPositioning: (PositioningSystem *) positionSystem
                                          AndRules: (NSArray *) rulesSystem;
- (id) init;
- (void) setDelegate:(id)del;
- (BOOL) doThreads;
- (void) setDoThreads:(BOOL)doThreadedProcedures;

- (void) tradingSimulation:(NSDictionary *) parameters;

- (void) askSimulationToCancel;

- (BOOL) exportWorkingSimulationDataToFile: (NSURL *) urlOfFile;
- (BOOL) exportWorkingSimulationTradesToFile: (NSURL *) urlOfFile;
- (BOOL) exportWorkingSimulationBalAdjmtsToFile:  (NSURL *) urlOfFile;
- (BOOL) exportWorkingSimulationReportToFile:(NSURL *) urlOfFile;

@end
