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
    DataController *panel1DataController;
    DataController *panel2DataController;
    SeriesPlot *panel1Plot;
    SeriesPlot *panel2Plot;
    SeriesPlot *panel3Plot;
    NSArray *importDataArray;
    NSString *importDataFilename;
    
    BOOL doingSetup;
    BOOL doThreads;
    BOOL cancelProcedure;
    BOOL initialSetupComplete;
    BOOL signalStatsAvailable;
    NSArray *disableObjectsOnSetup;
    NSArray *hideObjectsOnStartup;
    
    NSTabViewItem *signalsTab;
    NSTabViewItem *zoomTab;
    NSTabViewItem *mainTab;
    NSTabViewItem *dataTab;
    
    __weak NSTabView *centreTabs;
    
    __weak CPTGraphHostingView *panel1GraphHostingView;
    __weak CPTGraphHostingView *panel3GraphHostingView;
    __weak CPTGraphHostingView *panel2GraphHostingView;
    
    __weak NSTableView *panel3SignalTableView;
    //Panel 1 right side
    
    __weak NSTableView *panel1TimeSeriesTableView;
    __weak NSScrollView *panel1TimeSeriesScrollView;
    __weak NSBox *panel1ZoomBox;
    __weak NSTextField *panel1ZoomBoxFrom;
    
    __weak NSTextField *panel1ZoomBoxTo;
    __weak NSDatePicker *panel1ZoomBoxFromDatePicker;
    __weak NSDatePicker *panel1ZoomBoxToDatePicker;
    __weak NSButton *panel1ZoomBoxButton;
    
    //Relating to setup sheet of panel1
    IBOutlet NSWindow *setupSheet;
    __weak NSPopUpButton *panel1PairPopUp;
    __weak NSDatePicker *panel1FromPicker;
    __weak NSDatePicker *panel1ToPicker;
    __weak NSTextField *panel1SamplingRateField;
    __weak NSMatrix *panel1SamplingUnitRadio;
    __weak NSTextField *panel1StrategyField;
    __weak NSTextField *panel1FromDayOfWeekLabel;
    __weak NSTextField *panel1ToDayOfWeekLabel;
    __weak NSButton *panel1SetupButton;
    __weak NSButton *panel1SetupCancelButton;
    __weak NSButton *panel1PlotButton;
    
    __weak NSTextField *panel1PairLabel;
    __weak NSTextField *panel1ToLabel;
    __weak NSTextField *panel1FromLabel;
    __weak NSTextField *panel1ExtraFieldsLabel;
    __weak NSTextField *panel1SamplingRateLabel;
    __weak NSButton *panel1ImportDataButton;
    
    __weak NSScrollView *panel1ImportDataScrollView;
    __weak NSTableView *panel1ImportDataTableView;
    
    __weak NSTextField *fromLabel;
    __weak NSTextField *toLabel;
    __weak NSTextField *extraFieldsLabel;
    __weak NSTextField *samplingRateLabel;
    
    
    // End Panel 1 right side
    
    // Panel 2 right side
    __weak NSTextField *panel2SamplingRateField;
    __weak NSMatrix *panel2SamplingUnitRadio;
    __weak NSScrollView *panel2TimeSeriesScrollView;
    __weak NSTableView *panel2TimeSeriesTableView;
    __weak NSTextField *panel2DateTimeLabel;
    __weak NSTextField *panel2DateTimeTZLabel;
    __weak NSTextField *panel2BurnInAmountField;
    __weak NSMatrix *panel2BurnInUnitsRadio;
    __weak NSTextField *panel2PairLabel;
    __weak NSProgressIndicator *panel2ProgressBar;
    __weak NSProgressIndicator *panel1ProgressBar;
    __weak NSProgressIndicator *currentProgressIndicator;

    __weak NSTextField *panel2DataMoveAmount;
    __weak NSMatrix *panel2DataMoveUnits;
    __weak NSMatrix *panel2DataMoveType;
    
    
    __weak NSButton *panel2DataMoveButton;
    
    //End Panel 2 right side
    
    //Panel 3 right side
    
    __weak NSTableView *panel3TimeSeriesTableView;
    __weak NSTabView *rightSideTabView;
    __weak NSScrollView *panel3TimeSeriesScrollView;
    __weak NSTextField *panel3SignalPlotLeadTimeTextField;
    __weak NSTextField *panel3PairLabel;
    __weak NSTableView *signalAnalysisTableView;
    
    // Panel 4
    __weak NSTableView *panel4SampledDataTableView;
    __weak NSTableView *panel4ResampledDataTableView;
    __weak NSTextField *panel4PairLabel;
    NSMutableArray *signalTableViewOrdering;
    BOOL signalTableViewSortedAscending;
    NSString *signalTableViewSortColumn;
}

- (IBAction)panel1PlotButtonPress:(id)sender;
- (IBAction)panel1ImportDataPress:(id)sender;
- (void)setDelegate:(id)del;
- (IBAction)panel1PairPopupChange:(id)sender;
- (IBAction)panel1FromDateChange:(id)sender;
- (IBAction)panel1ToDateChange:(id)sender;
- (IBAction)panel2ResampleButtonPress:(id)sender;
- (IBAction)panel1SetupButtonPress:(id)sender;
- (IBAction)panel1CancelSetupPress:(id)sender;
- (IBAction)panel1ZoomPress:(id)sender;
- (IBAction)exportSignalDataPress:(id)sender;
- (IBAction)exportSampledDataPress:(id)sender;
- (IBAction)exportZoomResampledDataPress:(id)sender;
- (IBAction)sendSignalRangeToZoom:(id)sender;
- (IBAction)panel2DataMovePress:(id)sender;
- (IBAction)signalAnalysisPlotReload:(id)sender;



- (BOOL) doThreads;
- (void) setDoThreads:(BOOL)doThreadedProcedures;
- (void) readingRecordSetsProgress: (NSNumber *) progressFraction;
- (void) progressAsFraction:(NSNumber *) progressValue;
- (void) progressBarOn;
- (void) progressBarOff;
- (void) viewChosenFromMainMenu;



@property (retain) NSDictionary *fxPairsAndDbIds;
@property (retain) NSArray *coloursForPlots;
@property (retain) NSMutableArray *panel1TimeSeries; 
@property (retain) NSMutableArray *panel2TimeSeries;
@property (retain) NSMutableArray *panel3TimeSeries;


@property (weak) IBOutlet NSTabView *centreTabs;
@property (weak) IBOutlet CPTGraphHostingView *panel1GraphHostingView;
@property (weak) IBOutlet CPTGraphHostingView *panel2GraphHostingView;

@property (weak) IBOutlet NSTabView *rightSideTabView;

@property (weak) IBOutlet NSPopUpButton *panel1PairPopUp;
@property (weak) IBOutlet NSTextField *panel1PairLabel;
@property (weak) IBOutlet NSDatePicker *panel1FromPicker;
@property (weak) IBOutlet NSDatePicker *panel1ToPicker;
@property (weak) IBOutlet NSTextField *panel1SamplingRateField;
@property (weak) IBOutlet NSMatrix *panel1SamplingUnitRadio;
@property (weak) IBOutlet NSTextField *panel1StrategyField;
@property (weak) IBOutlet NSTableView *panel1TimeSeriesTableView;
@property (weak) IBOutlet NSScrollView *panel1TimeSeriesScrollView;
@property (weak) IBOutlet NSScrollView *panel2TimeSeriesScrollView;
@property (weak) IBOutlet NSTableView *panel2TimeSeriesTableView;
@property (weak) IBOutlet NSTextField *panel2SamplingRateField;
@property (weak) IBOutlet NSMatrix *panel2SamplingUnitRadio;
@property (weak) IBOutlet NSTextField *panel1FromDayOfWeekLabel;
@property (weak) IBOutlet NSTextField *panel1ToDayOfWeekLabel;
@property (weak) IBOutlet CPTGraphHostingView *panel3GraphHostingView;
@property (weak) IBOutlet NSTableView *panel3SignalTableView;
@property (weak) IBOutlet NSProgressIndicator *panel2ProgressBar;
@property (weak) IBOutlet NSProgressIndicator *panel1ProgressBar;
@property (weak) IBOutlet NSTableView *panel3TimeSeriesTableView;
@property (weak) IBOutlet NSButton *panel1SetupCancelButton;
@property (weak) IBOutlet NSTextField *panel1FromLabel;
@property (weak) IBOutlet NSTextField *panel1ToLabel;
@property (weak) IBOutlet NSTextField *panel1ExtraFieldsLabel;
@property (weak) IBOutlet NSTextField *panel1SamplingRateLabel;
@property (weak) IBOutlet NSScrollView *panel3TimeSeriesScrollView;
@property (weak) IBOutlet NSTextField *fromLabel;
@property (weak) IBOutlet NSTextField *toLabel;
@property (weak) IBOutlet NSTextField *extraFieldsLabel;
@property (weak) IBOutlet NSTextField *samplingRateLabel;
@property (weak) IBOutlet NSTextField *panel3SignalPlotLeadTimeTextField;
@property (weak) IBOutlet NSTableView *panel4SampledDataTableView;
@property (weak) IBOutlet NSTableView *panel4ResampledDataTableView;
@property (weak) IBOutlet NSBox *panel1ZoomBox;
@property (weak) IBOutlet NSTextField *panel1ZoomBoxFrom;
@property (weak) IBOutlet NSTextField *panel1ZoomBoxTo;
@property (weak) IBOutlet NSDatePicker *panel1ZoomBoxFromDatePicker;
@property (weak) IBOutlet NSDatePicker *panel1ZoomBoxToDatePicker;
@property (weak) IBOutlet NSButton *panel1ZoomBoxButton;
@property (weak) IBOutlet NSTableView *signalAnalysisTableView;
@property (weak) IBOutlet NSTextField *panel2PairLabel;
@property (weak) IBOutlet NSTextField *panel3PairLabel;
@property (weak) IBOutlet NSTextField *panel4PairLabel;
@property (weak) IBOutlet NSMatrix *panel2DataMoveUnits;
@property (weak) IBOutlet NSTextField *panel2DataMoveAmount;
@property (weak) IBOutlet NSButton *panel2DataMoveButton;
@property (weak) IBOutlet NSMatrix *panel2DataMoveType;
@property (weak) IBOutlet NSButton *panel1ImportDataButton;
@property (weak) IBOutlet NSScrollView *panel1ImportDataScrollView;
@property (weak) IBOutlet NSTableView *panel1ImportDataTableView;
@property (weak) IBOutlet NSButton *panel1SetupButton;
@property (weak) IBOutlet NSButton *panel1PlotButton;
@end
