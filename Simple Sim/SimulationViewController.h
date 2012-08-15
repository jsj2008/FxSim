//
//  SimulationViewController.h
//  Simple Sim
//
//  Created by Martin O'Connor on 19/03/2012.
//  Copyright (c) 2012 OCONNOR RESEARCH. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "SeriesPlot.h"

@class DataController;
@class SimulationController;

@interface SimulationViewController : NSViewController<SimulationOutput, NSTableViewDataSource, NSTableViewDelegate, NSTabViewDelegate, NSWindowDelegate>{
    __weak id delegate;
    NSWindowController *fullScreenWindowController;
    NSMutableArray *simulationTimeSeries;
    NSMutableArray *simulationSignalTimeSeries;
    NSArray *importDataArray;
    NSString *importDataFilename;
    DataSeries *simulationDataSeries;
    SeriesPlot *simulationResultsPlot;
    SeriesPlot *signalAnalysisPlot;
    SimulationController *simulationController;
    NSArray *hideObjectsOnStartup;
    NSTabViewItem *setupTab;
    NSTabViewItem *plotTab;
    NSTabViewItem *dataTab;
    NSTabViewItem *reportTab;
    NSTabViewItem *signalsTab;
    BOOL doingSetup;
    BOOL cancelProcedure;
    BOOL initialSetupComplete;
    BOOL doThreads;
    NSMutableArray *signalTableViewOrdering;
    BOOL signalTableViewSortedAscending;
    NSString *signalTableViewSortColumn;
    
    BOOL longShortIndicatorOn;
       
    __weak NSScrollView *simulationRunScrollView;
    __weak NSButton *performSimulationButton;
    __weak NSTableView *simulationTimeSeriesTableView;
    __weak NSTextField *performSimulationStatusLabel;
    __weak NSProgressIndicator *performSimulationProgressBar;
    __weak NSProgressIndicator *currentProgressIndicator;

    __weak NSTableView *simulationNumbersTableView;
    __weak NSTableView *simulationTradesTableView;
    __weak NSTableView *simulationCashFlowsTableView;
    __weak NSTableView *simulationSignalTableView;
    __weak NSTableView *simulationSignalTimeSeriesTableView;
    __weak CPTGraphHostingView *simulationSignalGraphHostingView;
    __weak CPTGraphHostingView *simulationResultGraphHostingView;
    __weak NSTabView *centreTabView;
    __weak NSTabView *rightSideTabView;
    
    //Relating to setup sheet
    IBOutlet NSWindow *setupSheet;
    IBOutlet NSPanel *fullScreenWindow;
    
    __weak NSPopUpButton *setupTradingPairPopup;
    __weak NSPopUpButton *setupAccountCurrencyPopup;
    __weak NSTextField *setupAccountBalanceTextField;
    __weak NSTextField *setupAccountCurrencyLabel;
    
    __weak NSDatePicker *setupStartTimePicker;
    __weak NSDatePicker *setupEndTimePicker;
    __weak NSTextField *setupParameterTextField;
    __weak NSTextField *setupPositioningTextField;
    
    __weak NSTextField *setupMaxLeverageTextField;
    __weak NSDatePicker *setupTradingStartTimePicker;
    __weak NSDatePicker *setupTradingEndTimePicker;
    __weak NSButton *setupTradingWeekendYesNo;
    __weak NSTextField *setupSamplingMinutesTextField;
    __weak NSTextField *setupTradingLagTextField;
    
    __weak NSTextField *dataAvailabilityFromLabel;
    __weak NSTextField *dataAvailabilityToLabel;
    __weak NSTextField *startDateDoWLabel;
    __weak NSTextField *endDateDoWLabel;
    __weak NSButton *setUpSheetCancelButton;
    __weak NSButton *setupSheetShowButton;
   
    __weak NSScrollView *setupSheetImportDataScrollView;
    __weak NSTableView *setupSheetImportDataTableView;
    
    __weak NSButton *setupSheetImportDataButton;
    // Relating to simulation description panel 
    
    __weak NSTextField *aboutSimNameLabel;
    __weak NSTextField *aboutTradingPairLabel;
    __weak NSTextField *aboutAccountCurrencyLabel;
    __weak NSTextField *aboutSimStartTimeLabel;
    __weak NSTextField *aboutSimEndTimeLabel;
    __weak NSTextField *aboutSimSamplingRateLabel;
    __weak NSTextField *aboutSimTradingLagLabel;
    __weak NSTextField *aboutSimTradingWindowStartLabel;
    __weak NSTextField *aboutSimTradingWindowEndLabel;
    __weak NSTextField *aboutSimParametersLabel;
   
    __weak NSTextField *tradingPairLabel;
    __weak NSTextField *accountCurrencyLabel;
    __weak NSTextField *startLabel;
    __weak NSTextField *endLabel;
    __weak NSTextField *samplingRateLabel;
    __weak NSTextField *tradingLagLabel;
    __weak NSTextField *tradingDayStartLabel;
    __weak NSTextField *tradingDayEndLabel;
    __weak NSTextField *descriptionLabel;
    
    __weak NSDatePicker *zoomFromDatePicker;
    __weak NSDatePicker *zoomToDatePicker;
    
    // Signal Analysis Sheet
    __weak NSTextField *signalAnalysisPlotLeadHours;
    
    __weak NSBox *fullScreenBox;
    __weak NSBox *simPlotBox;
    __weak NSBox *signalAnalysisPlotBox;
}

@property (retain) NSArray *coloursForPlots;
@property (retain) NSDictionary *fxPairsAndDbIds;
@property (retain) DataController *dataControllerForUI;

@property (weak) IBOutlet NSButton *performSimulationButton;
@property (weak) IBOutlet NSTableView *simulationTimeSeriesTableView;
@property (weak) IBOutlet CPTGraphHostingView *simulationResultGraphHostingView;
@property (weak) IBOutlet NSTableView *simulationNumbersTableView;
@property (unsafe_unretained) IBOutlet NSTextView *simulationMessagesTextView;
@property (weak) IBOutlet NSTextField *performSimulationStatusLabel;
@property (weak) IBOutlet NSTabView *rightSideTabView;
@property (weak) IBOutlet NSTabView *centreTabView;
@property (weak) IBOutlet NSTextField *setupSimulationName;
@property (weak) IBOutlet NSPopUpButton *setupTradingPairPopup;
@property (weak) IBOutlet NSPopUpButton *setupAccountCurrencyPopup;
@property (weak) IBOutlet NSTextField *setupAccountBalanceTextField;
@property (weak) IBOutlet NSDatePicker *setupStartTimePicker;
@property (weak) IBOutlet NSDatePicker *setupEndTimePicker;
@property (weak) IBOutlet NSTextField *setupParameterTextField;
@property (weak) IBOutlet NSTextField *setupMaxLeverageTextField;
@property (weak) IBOutlet NSDatePicker *setupTradingStartTimePicker;
@property (weak) IBOutlet NSDatePicker *setupTradingEndTimePicker;
@property (weak) IBOutlet NSTextField *setupSamplingMinutesTextField;
@property (weak) IBOutlet NSTextField *dataAvailabilityFromLabel;
@property (weak) IBOutlet NSTextField *dataAvailabilityToLabel;
@property (weak) IBOutlet NSTextField *startDateDoWLabel;
@property (weak) IBOutlet NSTextField *endDateDoWLabel;
@property (weak) IBOutlet NSTextField *setupTradingLagTextField;
@property (weak) IBOutlet NSTableView *reportTableView;

- (IBAction)changeSelectedTradingPair:(id)sender;
- (IBAction)showSetupSheet:(id)sender;
- (IBAction)cancelSimulation:(id)sender;
- (IBAction)cancelSetupSheet:(id)sender;
- (IBAction)performSimulation:(id)sender;
- (IBAction)toggleLongShortIndicator:(id)sender;
- (IBAction)sigPlotLongShortIndicatorToggle:(id)sender;
- (IBAction)plotLeftSideExpand:(id)sender;
- (IBAction)plotLeftSideContract:(id)sender;
- (IBAction)plotBottomExpand:(id)sender;
- (IBAction)plotBottomContract:(id)sender;
- (IBAction)exportData:(id)sender;
- (IBAction)exportTrades:(id)sender;
- (IBAction)exportBalanceAdjustments:(id)sender;
- (IBAction)setupStartTimeChange:(id)sender;
- (IBAction)setupEndTimeChange:(id)sender;
- (IBAction)makeSimulationReport:(id)sender;
- (IBAction)zoomButtonPress:(id)sender;
- (IBAction)accountCurrencyChange:(id)sender;
- (IBAction)importCsvData:(id)sender;
- (IBAction)signalAnalysisPlotReload:(id)sender;
- (IBAction)signalAnalysisPlotFullScreen:(id)sender;
- (IBAction)simPlotFullScreen:(id)sender;




- (void) setDelegate:(id)del;
- (void) addSimInfoToAboutPanelWithName:(NSString *) simName
                             AndFxPair:(NSString *) fxPair
                    AndAccountCurrency:(NSString *) accCurrency
                       AndSimStartTime: (NSString *) simStartTime
                         AndSimEndTime: (NSString *) simEndTime
                       AndSamplingRate: (NSString *) samplingRate
                         AndTradingLag: (NSString *) tradingLag
                 AndTradingWindowStart:(NSString *) tradingStartTime
                   AndTradingWindowEnd:(NSString *) tradingEndTime
                      AndSimParameters:(NSString *) parameters;
- (void) addSimulationDataToResultsTableView: (DataSeries *) analysisDataSeries;
- (void) simulationEnded;
- (void) initialiseSignalTableView;
- (void) prepareForSimulationReport;
- (void) setupResultsReport;
- (BOOL) doThreads;
- (void) setDoThreads:(BOOL)doThreadedProcedures;
- (void) readingRecordSetsProgress: (NSNumber *) progressFraction;
- (void) progressAsFraction:(NSNumber *) progressValue;
- (void) progressBarOn;
- (void) progressBarOff;
-(void)viewChosenFromMainMenu;

@property (weak) IBOutlet NSProgressIndicator *performSimulationProgressBar;
@property (weak) IBOutlet NSTextField *aboutSimNameLabel;
@property (weak) IBOutlet NSTextField *aboutTradingPairLabel;
@property (weak) IBOutlet NSTextField *aboutAccountCurrencyLabel;
@property (weak) IBOutlet NSTextField *aboutSimStartTimeLabel;
@property (weak) IBOutlet NSTextField *aboutSimEndTimeLabel;
@property (weak) IBOutlet NSTextField *aboutSimSamplingRateLabel;
@property (weak) IBOutlet NSTextField *aboutSimTradingLagLabel;
@property (weak) IBOutlet NSTextField *aboutSimTradingWindowStartLabel;
@property (weak) IBOutlet NSTextField *aboutSimParametersLabel;
@property (weak) IBOutlet NSTextField *aboutSimTradingWindowEndLabel;
@property (weak) IBOutlet NSButton *setUpSheetCancelButton;
@property (weak) IBOutlet NSTableView *simulationTradesTableView;
@property (weak) IBOutlet NSTableView *simulationCashFlowsTableView;
@property (weak) IBOutlet NSTableView *simulationSignalTableView;
@property (weak) IBOutlet CPTGraphHostingView *simulationSignalGraphHostingView;
@property (weak) IBOutlet NSTextField *signalAnalysisPlotLeadHours;
@property (weak) IBOutlet NSTableView *simulationSignalTimeSeriesTableView;
@property (weak) IBOutlet NSButton *setupTradingWeekendYesNo;
@property (weak) IBOutlet NSTextField *tradingPairLabel;
@property (weak) IBOutlet NSTextField *startLabel;
@property (weak) IBOutlet NSTextField *endLabel;
@property (weak) IBOutlet NSTextField *tradingLagLabel;
@property (weak) IBOutlet NSTextField *tradingDayStartLabel;
@property (weak) IBOutlet NSTextField *tradingDayEndLabel;
@property (weak) IBOutlet NSTextField *descriptionLabel;
@property (weak) IBOutlet NSTextField *samplingRateLabel;
@property (weak) IBOutlet NSTextField *accountCurrencyLabel;
@property (weak) IBOutlet NSScrollView *simulationRunScrollView;
@property (weak) IBOutlet NSDatePicker *zoomFromDatePicker;
@property (weak) IBOutlet NSDatePicker *zoomToDatePicker;
@property (weak) IBOutlet NSTextField *setupAccountCurrencyLabel;
@property (weak) IBOutlet NSScrollView *setupSheetImportDataScrollView;
@property (weak) IBOutlet NSTableView *setupSheetImportDataTableView;
@property (weak) IBOutlet NSButton *setupSheetImportDataButton;
@property (weak) IBOutlet NSButton *setupSheetShowButton;
@property (weak) IBOutlet NSTextField *setupPositioningTextField;
@property (weak) IBOutlet NSBox *fullScreenBox;
@property (weak) IBOutlet NSBox *signalAnalysisPlotBox;
@property (weak) IBOutlet NSBox *simPlotBox;
@end
