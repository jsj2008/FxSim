//
//  AppController.h
//  Simple Sim
//
//  Created by O'Connor Martin on 19/12/2011.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CorePlot/CorePlot.h>
#import <Quartz/Quartz.h>
#import "SeriesPlot.h"
#import "DataController.h"
#import "SimulationController.h"
#import "SimulationOutput.h"

@class TimeSeriesLine;


@interface AppController : NSObject <NSTableViewDataSource, NSTabViewDelegate, NSTableViewDelegate, SimulationOutput>{
    @private
    __weak NSTextField *shortTermSamplingValue;
    __weak NSTextField *longTermSamplingValue;
    __weak NSTextField *intraDaySamplingValue;
    __weak NSMatrix *shortTermSamplingUnit;
    __weak NSMatrix *longTermSamplingUnit;
    __weak NSMatrix *intraDaySamplingUnit;
    __weak NSTextField *fromDateLabel;
    __weak NSTextField *toDateLabel;
    __weak NSPopUpButton *pairPicker;
    __weak NSDatePicker *datePicker;
    __weak NSTextField *dayOfWeekLabel;
//    __weak CPTGraphHostingView *hostingView1;
//    __weak CPTGraphHostingView *hostingView2;
//    __weak CPTGraphHostingView *hostingView3;
    __weak NSTabView *mainTabs;
    __weak NSTabView *sideTabs;
    __weak NSTextFieldCell *startupLabel;
    __weak NSTextField *currentDateLabel;
    __weak NSSlider *intraDayTimeSlider;
    __weak NSTextField *intraDayTimeLabel;
    __weak NSTextField *fxPairLabel;
    __weak NSBox *intraDayLeftSideTab;
    __weak NSButton *setupDataButton;
    __weak NSTextField *dataRangeMoveValue;
    __weak NSButton *shiftDataRangeBack;
    __weak NSButton *shiftDataRangeForward;
    __weak NSTextField *shiftDataDaysLabel;
    __weak NSButton *setupButton;
    __weak NSButton *test;
    __weak NSTableView *simAnalysisDataTable;
    
    __weak NSMatrix *simZoomOnOffButtons;
    __weak NSButton *simZoomButton;
    __weak NSButton *simZoomResetButton;
    __weak NSDatePicker *simZoomFromDatePicker;
    __weak NSDatePicker *simZoomToDatePicker;
    
    
    

    NSDate *minAvailableDate;
    NSDate *maxAvailableDate;
    SeriesPlot *plot1;
    SeriesPlot *plot2;
    SeriesPlot *plot3;
    SeriesPlot *plot4;
    DataController *dataController;
    SimulationController *accountsController;
    NSMutableArray *longTermTimeSeries;
    NSMutableArray *shortTermTimeSeries;
    NSMutableArray *intraDayTimeSeries;
    NSMutableArray *simulationTimeSeries;
    NSMutableDictionary *formData;
    //DataSeries *baseData;
    NSArray *colorsForPlots;
    
}
- (IBAction)changePair:(id)sender;
- (IBAction)changeDate:(id)sender;
- (IBAction)setUp:(id)sender;
- (IBAction)intraDayTimeSlider:(id)sender;
- (IBAction)cancelSetupSheet:(id)sender;
- (IBAction)test:(id)sender;
- (IBAction)dataRangeMoveBack:(id)sender;
- (IBAction)dataRangeMoveForward:(id)sender;
- (IBAction)setupViaMenu:(id)sender;
- (IBAction)plotPositions:(id)sender;
- (IBAction)simZoomRadioChange:(id)sender;
- (IBAction)simZoomButtonDown:(id)sender;
- (IBAction)simZoomResetButtonDown:(id)sender;



//@property (nonatomic, retain) SeriesPlot *plot1;
//@property (nonatomic, retain) SeriesPlot *plot2;
//@property (nonatomic, retain) SeriesPlot *plot3;
@property (retain) NSDate *currentDay; 
//@property (retain) DataSeries *baseData;
@property (retain, readonly) NSDate *minAvailableDate;
@property (retain, readonly) NSDate *maxAvailableDate;
@property (retain) NSMutableArray *longTermTimeSeries; 
@property (retain) NSMutableArray *shortTermTimeSeries; 
@property (retain) NSMutableArray *intraDayTimeSeries; 
@property (retain) NSArray *colorsForPlots;

@property (weak) IBOutlet NSScrollView *longTermTimeSeriesScrollView;
@property (weak) IBOutlet NSScrollView *intraDayTimeSeriesScrollView;
@property (weak) IBOutlet NSScrollView *shortTermTimeSeriesScrollView;
@property (strong) IBOutlet NSWindow *setupSheet;
@property (weak) IBOutlet NSProgressIndicator *dataSetupProgressBar;
@property (weak) IBOutlet NSProgressIndicator *leftSideProgressBar;
@property (weak) IBOutlet NSTextField *shortTermHistory;
@property (weak) IBOutlet NSTextField *longTermHistory;
@property (weak) IBOutlet NSDatePicker *datePicker;
@property (weak) IBOutlet NSTextField *dayOfWeekLabel;
@property (weak) IBOutlet NSTextField *fromDateLabel;
@property (weak) IBOutlet NSTextField *toDateLabel;
@property (weak) IBOutlet NSPopUpButton *pairPicker;
@property (weak) IBOutlet NSTextField *fxPairLabel;
@property (weak) IBOutlet NSTextField *currentDateLabel;
@property (weak) IBOutlet NSTabView *mainTabs;
@property (weak) IBOutlet CPTGraphHostingView *hostingView1;
@property (weak) IBOutlet NSTextField *shortTermSamplingValue;
@property (weak) IBOutlet NSTextField *longTermSamplingValue;
@property (weak) IBOutlet NSMatrix *shortTermSamplingUnit;
@property (weak) IBOutlet CPTGraphHostingView *hostingView3;
@property (weak) IBOutlet CPTGraphHostingView *hostingView4;

@property (weak) IBOutlet NSMatrix *longTermSamplingUnit;
@property (weak) IBOutlet CPTGraphHostingView *hostingView2;
@property (weak) IBOutlet NSTextField *intraDaySamplingValue;
@property (weak) IBOutlet NSMatrix *intraDaySamplingUnit;
@property (weak) IBOutlet NSTableView *longTermTimeSeriesTableView;
@property (weak) IBOutlet NSTableView *shortTermTimeSeriesTableView;
@property (weak) IBOutlet NSTableView *intraDayTimeSeriesTableView;
@property (weak) IBOutlet NSTableView *simulationTimeSeriesTableView;


@property (weak) IBOutlet NSSlider *intraDayTimeSlider;
//@property (weak) IBOutlet NSTextField *intraDayDateLabel;
@property (weak) IBOutlet NSTextField *intraDayTimeLabel;
@property (weak) IBOutlet NSTextField *setUpStatusLabel;
@property (weak) IBOutlet NSTextField *leftPanelStatusLabel;
@property (unsafe_unretained) IBOutlet NSTextView *sumulationDetails;

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView;
- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row;
- (void)tableView:(NSTableView *)tableView setObjectValue:(id) obj forTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row;
- (void)addToTableView:(NSTableView *)tableView TimeSeriesLine: (TimeSeriesLine *)TSLine;
- (void)clearTSTableView:(NSTableView *)tableView;
- (void)tableView:(NSTableView *)tableView didClickTableColumn:(NSTableColumn *)tableColumn;
- (void)outputSimulationMessage:(NSString *) message;
- (void)gettingDataIndicatorSwitchOn;
- (void)gettingDataIndicatorSwitchOff;
- (void)clearSimulationMessage;
- (void)plotSimulationData: (DataSeries *) dataToPlot;

@property (weak) IBOutlet NSTabView *sideTabs;
@property (weak) IBOutlet NSBox *intraDayLeftSideTab;
@property (weak) IBOutlet NSButton *setupDataButton;
@property (weak) IBOutlet NSTextField *dataRangeMoveValue;
@property (weak) IBOutlet NSButton *shiftDataRangeBack;
@property (weak) IBOutlet NSButton *shiftDataRangeForward;
@property (weak) IBOutlet NSTextField *shiftDataDaysLabel;
@property (weak) IBOutlet NSButton *test;
@property (weak) IBOutlet NSButton *plotPositionsButton;

@property (weak) IBOutlet NSTableView *simAnalysisDataTable;
@property (weak) IBOutlet NSMatrix *simZoomOnOffButtons;
@property (weak) IBOutlet NSButton *simZoomButton;
@property (weak) IBOutlet NSButton *simZoomResetButton;
@property (weak) IBOutlet NSDatePicker *simZoomFromDatePicker;
@property (weak) IBOutlet NSDatePicker *simZoomToDatePicker;
@end
