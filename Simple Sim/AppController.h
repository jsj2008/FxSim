//
//  AppController.h
//  Simple Sim
//
//  Created by O'Connor Martin on 19/12/2011.
//  Copyright (c) 2011 OCONNOR RESEARCH. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CorePlot/CorePlot.h>
#import <Quartz/Quartz.h>
#import "SeriesPlot.h"
#import "DataController.h"
#import "SimulationController.h"
#import "SimulationOutput.h"


@class TimeSeriesLine;


@interface AppController : NSObject <NSTableViewDataSource, NSTabViewDelegate, NSTableViewDelegate>{
    @private
    //__weak NSTextField *shortTermSamplingValue;
    //__weak NSTextField *longTermSamplingValue;
    //__weak NSTextField *intraDaySamplingValue;
    //__weak NSMatrix *shortTermSamplingUnit;
    //__weak NSMatrix *longTermSamplingUnit;
    //__weak NSMatrix *intraDaySamplingUnit;
    //__weak NSTextField *fromDateLabel;
    //__weak NSTextField *toDateLabel;
    //__weak NSPopUpButton *pairPicker;
    //__weak NSDatePicker *datePicker;
    //__weak NSTextField *dayOfWeekLabel;
    //__weak NSTabView *mainTabs;
    //__weak NSTabView *sideTabs;
    //__weak NSTextFieldCell *startupLabel;
    //__weak NSTextField *currentDateLabel;
    //__weak NSSlider *intraDayTimeSlider;
    //__weak NSTextField *intraDayTimeLabel;
    //__weak NSTextField *fxPairLabel;
    //__weak NSBox *intraDayLeftSideTab;
    //__weak NSButton *setupDataButton;
    //__weak NSTextField *dataRangeMoveValue;
    //__weak NSButton *shiftDataRangeBack;
    //__weak NSButton *shiftDataRangeForward;
    //__weak NSTextField *shiftDataDaysLabel;
    //__weak NSButton *setupButton;
    //__weak NSButton *testButton;
    //__weak NSTableView *simAnalysisDataTable;
    //__weak NSTextField *intraDayDataSeriesSamplingSeconds;
    //__weak NSTextField *DataViewFields;
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
- (void) readingRecordSetsProgress: (NSNumber *) progressFraction;
- (void) putFieldNamesInCorrectOrdering:(NSMutableArray *) fieldNamesFromData;
- (void) disableMainButtons;
- (void) enableMainButtons;
- (IBAction)changeToSimulationView:(id)sender;
- (IBAction)changeToInteractiveView:(id)sender;


@property (weak) IBOutlet NSProgressIndicator *leftSideProgressBar;
@property (weak) IBOutlet NSProgressIndicator *leftSideProgressBar2;
@property (weak) IBOutlet NSTextField *leftPanelStatusLabel;
@property (weak) IBOutlet NSBox *box;
@property (weak) IBOutlet NSButton *interactiveViewButton;
@property (weak) IBOutlet NSButton *simulationViewButton;
@property (weak) IBOutlet NSButton *realtimeButton;
@end
