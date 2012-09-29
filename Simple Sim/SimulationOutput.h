//
//  SimulationOutput.h
//  Simple Sim
//
//  Created by Martin O'Connor on 22/02/2012.
//  Copyright (c) 2012 OCONNOR RESEARCH. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol SimulationOutput <NSObject>
- (void) clearSimulationMessage;
- (void) outputSimulationMessage:(NSString *) message;
- (void) gettingDataIndicatorSwitchOn;
- (void) gettingDataIndicatorSwitchOff;
- (void) readingRecordSetsProgress: (NSNumber *) progressFraction;
- (void) progressAsFraction:(NSNumber *) progressValue;
- (void) progressBarOn;
- (void) progressBarOff;
- (void) initialiseSignalTableView;
- (void) setupResultsReport;
- (void) addSimInfoToAboutPanelWithName:(NSString *) simName
                            AndFxPair:(NSString *) fxPair
                   AndAccountCurrency:(NSString *) accCurrency
                      AndSimStartTime: (NSString *) simStartTime
                        AndSimEndTime: (NSString *) simEndTime;
@end
