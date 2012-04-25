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
    DataController *marketData;
    NSMutableDictionary *interestRates;
    NSMutableDictionary *allSimulations;
    BOOL simulationDone;

    //long controllerDateTime;
    id<SimulationOutput> delegate;
}

@property BOOL doThreads;
@property BOOL cancelProcedure;
@property (retain) Simulation* currentSimulation;



-(id)init;
-(void)setDelegate:(id)del;

-(void)tradingSimulation:(NSDictionary *) parameters;
-(Simulation *)getSimulationForName: (NSString *) name;


-(double)getPrice:(PriceType) priceType 
           AtTime:(long) dateTime 
      WithSuccess:(BOOL *) success;

-(float) setExposureToUnits:(int) exposureAmount 
                AtTimeDate:(long) currentDateTime
            ForSimulation: (Simulation *) simulation
             AndSignalIndex: (int) signalIndex;

-(float)calculateInterestForSimulation: (Simulation *) simulation 
                        ToDateTime: (long) endDateTime;
//-(double) getMarginUsedForSimulation: (Simulation *) simulation 
//                              AtTime: (long) currentTime;
//-(double) getNAVForSimulation: (Simulation *) simulation AtTime: (long) currentTime;
-(void) askSimulationToCancel;
-(BOOL)exportData: (NSURL *) urlOfFile;
-(BOOL)exportTrades: (NSURL *) urlOfFile;
-(BOOL)exportBalAdjmts: (NSURL *) urlOfFile;
-(BOOL)writeReportToCsvFile:(NSURL *) urlOfFile;

-(void) populateAboutPane: (Simulation *) simulation;
-(void) initialiseSignalTableView;
-(void) setupResultsReport;
//-(double) getBalanceForSimulation: (Simulation *) simulation;
//-(int) getExposureForSimulation: (Simulation *) simulation;
-(void) clearUserInterfaceMessages;
-(void) sendMessageToUserInterface:(NSString *) message;
-(void)analyseSimulation: (Simulation *) simulation;



@end
