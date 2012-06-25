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

typedef enum {
    BID = -1,
    MID = 0,
    ASK = 1
} PriceType;
    
@interface SimulationController : NSObject {
    BOOL doThreads;
    DataController *simData;
    NSMutableDictionary *interestRates;
    NSMutableDictionary *allSimulations;
    BOOL simulationDone;

    //long controllerDateTime;
    id<SimulationOutput> delegate;
}


@property BOOL cancelProcedure;
@property (retain) Simulation* currentSimulation;

+ (BOOL) positioningUnderstood:(NSString *) positioningString;

- (id) init;
- (void) setDelegate:(id)del;
- (BOOL) doThreads;
- (void) setDoThreads:(BOOL)doThreadedProcedures;
- (void) tradingSimulation:(NSDictionary *) parameters;
- (Simulation *)getSimulationForName: (NSString *) name;
- (double) getPrice:(PriceType) priceType 
             AtTime:(long) dateTime 
        WithSuccess:(BOOL *) success;

-(double) setExposureToUnits:(int) exposureAmount 
                  AtTimeDate:(long) currentDateTime
               ForSimulation: (Simulation *) simulation
              AndSignalIndex: (int) signalIndex;

-(double) calculateInterestForSimulation: (Simulation *) simulation 
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
