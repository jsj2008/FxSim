//
//  SimulationController.h
//  Simple Sim
//
//  Created by Martin O'Connor on 09/02/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
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
    
@interface SimulationController : NSObject <NSTableViewDataSource>{
    DataController *marketData;
    NSMutableDictionary *interestRates;
    NSMutableDictionary *accounts;
    BOOL simulationDone;
    long controllerDateTime;
    id<SimulationOutput> delegate;
}

@property (retain) NSString* currentSimulation;

-(id)init;
-(void)setDelegate:(id)del;

-(void)addAndTestAcc;
-(Simulation *)getAccountForName: (NSString *) name;


-(double)getPrice:(PriceType) priceType 
           AtTime:(long) dateTime 
      WithSuccess:(BOOL *) success;
-(BOOL) setExposureToUnits:(int) exposureAmount 
                AtTimeDate:(long) currentDateTime
                ForAccount: (Simulation *) account
             AndSignalTime: (long) signalDateTime;
-(void)calculateInterestForAccount: (Simulation *) account 
                        ToDateTime: (long) endDateTime;
-(double) getMarginUsedForAccount: (Simulation *) account;
-(double) getNAVForAccount: (Simulation *) account;
-(double) getBalanceForAccount: (Simulation *) account;
-(int) getExposureForAccount: (Simulation *) account;


-(void) clearUserInterfaceMessages;
-(void) sendMessageToUserInterface:(NSString *) message;
-(void) createDataSeriesWithAccountInformation:(NSString *) accountName;

@end
