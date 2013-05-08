//
//  AppController.h
//  Simple Sim
//
//  Created by O'Connor Martin on 19/12/2011.
//  Copyright (c) 2011 OCONNOR RESEARCH. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DataController.h"

@interface AppController : NSObject <NSTableViewDataSource, NSTabViewDelegate, NSTableViewDelegate>{
    @private
    __weak NSBox *box;
    __weak NSButton *interactiveViewButton;
    __weak NSButton *simulationViewButton;
    __weak NSButton *realtimeButton;
    DataController *dataControllerForUI;
    NSArray *coloursForPlots;
    NSArray *fieldNameOrdering;
    NSDictionary *listOfFxPairs;
    NSDictionary *buttonStates;
    NSMutableDictionary *viewControllers;

}
@property (retain) NSDate *currentDay; 
@property (retain, readonly) NSDate *minAvailableDate;
@property (retain, readonly) NSDate *maxAvailableDate;
@property (retain) NSArray *colorsForPlots;


- (void) showAlertPanelWithInfo: (NSDictionary *) alertInfo;
- (void) gettingDataIndicatorSwitchOn;
- (void) gettingDataIndicatorSwitchOff;
- (void) readingRecordSetProgress: (NSNumber *) progressFraction;
- (void) readingRecordSetMessage:(NSString *) progressMessage;
- (void) leftPanelTopMessage:(NSString *) message;
- (void) putFieldNamesInCorrectOrdering:(NSMutableArray *) fieldNamesFromData;
- (void) disableMainButtons;
- (void) enableMainButtons;
- (IBAction)changeToSimulationView:(id)sender;
- (IBAction)changeToInteractiveView:(id)sender;

@property (weak) IBOutlet NSTextField *leftSideTopLabel;
@property (weak) IBOutlet NSProgressIndicator *leftSideProgressBar;
@property (weak) IBOutlet NSProgressIndicator *leftSideProgressBar2;
@property (weak) IBOutlet NSTextField *leftPanelStatusLabel;
@property (weak) IBOutlet NSBox *box;
@property (weak) IBOutlet NSButton *interactiveViewButton;
@property (weak) IBOutlet NSButton *simulationViewButton;
@property (weak) IBOutlet NSButton *realtimeButton;
@end
