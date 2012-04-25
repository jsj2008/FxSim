//
//  InteractiveTradeViewController.h
//  Simple Sim
//
//  Created by Martin O'Connor on 19/03/2012.
//  Copyright (c) 2012 OCONNOR RESEARCH. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "SeriesPlot.h"
#import "DataController.h"

@interface InteractiveTradeViewController : NSViewController<NSTableViewDataSource, NSTableViewDelegate, NSTabViewDelegate>{
    id delegate;
    
    NSMutableDictionary *userInputFormData;
    //NSDictionary *listOfFxPairs;
    
    DataController *dataController;
    SeriesPlot *intraDayPlot;
    SeriesPlot *shortTermPlot;
    SeriesPlot *longTermPlot;
    
    BOOL doingSetup;
    BOOL cancelProcedure;
    BOOL initialSetupComplete;
    NSArray *disableObjectsOnSetup;
    NSArray *hideObjectsOnStartup;

    
    
    __weak NSTabView *centreTabs;
    
    // Right Side
    __weak NSTableView *longTermTimeSeriesTableView;
    __weak NSTableView *shortTermTimeSeriesTableView;
    __weak NSTableView *intraDayTimeSeriesTableView;
    
    __weak NSScrollView *intraDayTimeSeriesScrollView;
    __weak NSScrollView *shortTermTimeSeriesScrollView;
    __weak NSScrollView *longTermTimeSeriesScrollView;
    
    __weak NSTextField *intraDayMoveForwardTextField;
    __weak NSTextField *intraDayDateTimeLabel;
    
    
    __weak NSTextField *intraDayDataSeriesSamplingRate;
    __weak NSTextField *shortTermDataSeriesSamplingRate;
    __weak NSTextField *longTermDataSeriesSamplingRate;
    
    __weak NSTextField *intraDayFXPairLabel;
    __weak NSTextField *shortTermFXPairLabel;
    __weak NSTextField *longTermFXPairLabel;
    __weak NSTextField *intraDayMoveForwardMinutesLabel;
    __weak NSTextField *intraDayEndTimeGMTLabel;
    __weak NSButton *intraDayMoveForwardButton;
    __weak NSBox *intraDayMoveForwardBox;
    
    __weak NSButton *showSetupSheetButton;
    
    
    //Setup Sheet 
    __weak NSPopUpButton *fxPairPopUp;
    __weak NSTextField *dataAvailabilityFromLabel;
    __weak NSTextField *dataAvailabilityToLabel;
    __weak NSTextField *intraDayDayOfWeekLabel;
    __weak NSDatePicker *intraDayDatePicker;
    
    __weak NSTextField *intraDaySamplingValue;
    __weak NSMatrix *intraDaySamplingUnit;
    __weak NSTextField *shortTermHistoryLength;
    __weak NSTextField *shortTermSamplingValue;
    __weak NSMatrix *shortTermSamplingUnit;

    __weak NSTextField *longTermHistoryValue;
    __weak NSTextField *longTermSamplingValue;
    __weak NSMatrix *longTermSamplingUnit;
    __weak NSTextField *dataSeriesTextField;
    __weak NSButton *setupDataButton;
    
    __weak NSTextField *setUpStatusLabel;
    //__weak NSProgressIndicator *setUpProgressIndicator;
    __weak NSTabView *rightSideTabView;
}

@property (retain) NSDictionary *fxPairsAndDbIds;

@property BOOL doThreads;
@property (retain) NSArray *coloursForPlots;
@property (retain) NSArray *fieldNameOrdering;

@property (retain) NSMutableArray *intraDayTimeSeries;
@property (retain) NSMutableArray *shortTermTimeSeries; 
@property (retain) NSMutableArray *longTermTimeSeries; 

@property (weak) IBOutlet NSTabView *centreTabs;
@property (strong) IBOutlet NSWindow *setupSheet;

@property (weak) IBOutlet NSTextField *intraDayMoveForwardTextField;
@property (weak) IBOutlet NSTextField *intraDayDateTimeLabel;

@property (weak) IBOutlet NSTableView *intraDayTimeSeriesTableView;
@property (weak) IBOutlet NSTableView *shortTermTimeSeriesTableView;
@property (weak) IBOutlet NSTableView *longTermTimeSeriesTableView;

@property (weak) IBOutlet CPTGraphHostingView *intraDayGraphHostingView;
@property (weak) IBOutlet CPTGraphHostingView *shortTermGraphHostingView;
@property (weak) IBOutlet CPTGraphHostingView *longTermGraphHostingView;

- (IBAction)intraDayMoveForwardButtonPress:(id)sender;


//Setup sheet related

- (IBAction)setupViaMenu:(id)sender;
- (IBAction)setUp:(id)sender;
- (IBAction)cancelSetupSheet:(id)sender;
- (IBAction)changeFxPair:(id)sender;
- (IBAction)changeDate:(id)sender;

-(void)setDelegate:(id)del;

@property (weak) IBOutlet NSTextField *dataAvailabilityFromLabel;
@property (weak) IBOutlet NSTextField *dataAvailabilityToLabel;
@property (weak) IBOutlet NSTextField *intraDayDayOfWeekLabel;

@property (weak) IBOutlet NSDatePicker *intraDayDatePicker;
@property (weak) IBOutlet NSPopUpButton *fxPairPopUp;
@property (weak) IBOutlet NSTextField *intraDaySamplingValue;
@property (weak) IBOutlet NSTextField *shortTermSamplingValue;
@property (weak) IBOutlet NSTextField *longTermSamplingValue;
@property (weak) IBOutlet NSTextField *shortTermHistoryLength;
@property (weak) IBOutlet NSTextField *longTermHistoryLength;
@property (weak) IBOutlet NSMatrix *intraDaySamplingUnit;
@property (weak) IBOutlet NSMatrix *shortTermSamplingUnit;
@property (weak) IBOutlet NSMatrix *longTermSamplingUnit;
@property (weak) IBOutlet NSButton *setupDataButton;
@property (weak) IBOutlet NSTextField *dataSeriesTextField;
@property (weak) IBOutlet NSTextField *setUpStatusLabel;
@property (weak) IBOutlet NSScrollView *longTermTimeSeriesScrollView;
@property (weak) IBOutlet NSScrollView *shortTermTimeSeriesScrollView;
@property (weak) IBOutlet NSScrollView *intraDayTimeSeriesScrollView;
@property (weak) IBOutlet NSTextField *longTermFXPairLabel;
@property (weak) IBOutlet NSTextField *shortTermFXPairLabel;
@property (weak) IBOutlet NSTextField *intraDayFXPairLabel;
//@property (weak) IBOutlet NSProgressIndicator *setUpProgressIndicator;
@property (weak) IBOutlet NSTextField *intraDayDataSeriesSamplingRate;
@property (weak) IBOutlet NSTabView *rightSideTabView;
@property (weak) IBOutlet NSTextField *shortTermDataSeriesSamplingRate;
@property (weak) IBOutlet NSTextField *longTermDataSeriesSamplingRate;
@property (weak) IBOutlet NSTextField *intraDayMoveForwardMinutesLabel;
@property (weak) IBOutlet NSTextField *intraDayEndTimeGMTLabel;
@property (weak) IBOutlet NSButton *intraDayMoveForwardButton;
@property (weak) IBOutlet NSBox *intraDayMoveForwardBox;
@property (weak) IBOutlet NSButton *showSetupSheetButton;
@end
