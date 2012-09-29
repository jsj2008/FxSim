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
    BOOL doThreads;
    DataController *simDataController;
    NSMutableDictionary *interestRates;
    NSMutableDictionary *allSimulations;
    BOOL simulationDone;
    //int signalIndex;
    double cashPosition;

    //long controllerDateTime;
    id<SimulationOutput> delegate;
}

@property BOOL cancelProcedure;
@property (retain) Simulation* currentSimulation;

+ (BOOL) positioningUnderstood:(NSString *) positioningString;
+ (BOOL) signalingUnderstood: (NSString *) signalString;
+ (BOOL) rulesUnderstood:(NSString *) rulesString;
+ (NSArray *) derivedVariablesForSignal: (SignalSystem *) signalSystem
                        AndPositioning: (PositioningSystem *) positionSystem
                              AndRules: (NSArray *) rulesSystem;
- (id) init;
- (void) setDelegate:(id)del;
- (BOOL) doThreads;
- (void) setDoThreads:(BOOL)doThreadedProcedures;
- (void) tradingSimulation:(NSDictionary *) parameters;
- (Simulation *)getSimulationForName: (NSString *) name;
- (double) getPrice:(PriceType) priceType 
             AtTime:(long) dateTime 
        WithSuccess:(BOOL *) success;

- (double) setExposureToUnits:(int) exposureAmount 
                  AtTimeDate:(long) currentDateTime
               ForSimulation: (Simulation *) simulation
               ForSignalAtTime: (long) timeOfSignal;

- (double) calculateInterestForSimulation: (Simulation *) simulation 
                              ToDateTime: (long) endDateTime;

- (void) askSimulationToCancel;
- (BOOL) exportData: (NSURL *) urlOfFile;
- (BOOL) exportTrades: (NSURL *) urlOfFile;
- (BOOL) exportBalAdjmts: (NSURL *) urlOfFile;
- (BOOL) writeReportToCsvFile:(NSURL *) urlOfFile;

- (void) populateAboutPane: (Simulation *) simulation;
- (void) initialiseSignalTableView;
- (void) setupResultsReport;
- (void) clearUserInterfaceMessages;
- (void) sendMessageToUserInterface:(NSString *) message;
- (void) analyseSimulation: (Simulation *) simulation;
- (void) progressBarOn;
- (void) progressBarOff;
- (void) progressAsFraction:(NSNumber *) progressValue;
- (void) readingRecordSetsProgress: (NSNumber *) progressFraction;
@end
