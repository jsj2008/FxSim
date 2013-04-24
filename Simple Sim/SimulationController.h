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
    DataController *_dataController;
    NSMutableDictionary *_interestRates;
    BOOL _simulationDone;
    BOOL _cancelProcedure;
    BOOL _loadAllData;
    double _cashPosition;
    BOOL _simulationRunning;

    //Simulation *_workingSimulation;
    id _delegate;
}

@property double cashPosition;
@property BOOL cancelProcedure;
@property BOOL doThreads;
@property BOOL loadAllData;
@property (retain) DataController *dataController;
@property (retain) NSMutableDictionary *interestRates;
@property BOOL simulationRunning;

+ (BOOL) positioningUnderstood:(NSString *) positioningString;
+ (BOOL) simulationUnderstood: (NSString *) signalString;
+ (BOOL) seriesUnderstood:(NSString *) seriesString;
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

- (BOOL) exportWorkingSimulation: (Simulation *) sim
                     DataToFile: (NSURL *) urlOfFile;
- (BOOL) exportWorkingSimulationTrades:(Simulation *) sim
                                ToFile: (NSURL *) urlOfFile;
- (BOOL) exportWorkingSimulationBalAdjmts:(Simulation *) sim
                                   ToFile:  (NSURL *) urlOfFile;
- (BOOL) exportWorkingSimulationReport:(Simulation *) sim
                                ToFile:(NSURL *) urlOfFile;

@end
