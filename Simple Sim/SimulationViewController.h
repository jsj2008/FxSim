//
//  SimulationViewController.h
//  Simple Sim
//
//  Created by Martin O'Connor on 19/03/2012.
//  Copyright (c) 2015 MARTIN OCONNOR. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "SeriesPlot.h"

@class DataController;
@class SimulationController;
@class Simulation;


@interface SimulationViewController : NSViewController<NSTableViewDataSource, NSTableViewDelegate, NSTabViewDelegate, NSWindowDelegate>{
    __weak id delegate;
    NSWindowController *fullScreenWindowController;
    
    BOOL _doThreads;
    BOOL _firstTimeSetup;
    NSArray *_coloursForPlots;
    
    NSTabViewItem *setupTab;
    NSTabViewItem *plotTab;
    NSTabViewItem *dataTab;
    NSTabViewItem *reportTab;
    NSTabViewItem *signalsTab;
    NSTabViewItem *compareTab;
    NSTabViewItem *histTab;
    
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
    
    __weak NSTableView *simulationSignalSelectedTimeSeriesTableView;
    __weak NSTableView *simulationTimeSeriesSelectedTableView;
        
//    __weak CPTGraphHostingView *simulationSignalGraphHostingView;
//    __weak CPTGraphHostingView *simulationResultGraphHostingView;
    
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
    
    __weak NSTextField *setupRulesTextField;
    __weak NSTextField *setupMaxLeverageTextField;
    __weak NSDatePicker *setupTradingStartTimePicker;
    __weak NSDatePicker *setupTradingEndTimePicker;
    __weak NSButton *setupTradingWeekendYesNo;
    __weak NSTextField *setupSamplingMinutesTextField;
    __weak NSTextField *setupTradingLagTextField;
    __weak NSTextField *setupDataWarmUpTextField;
    
    
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
    __weak NSBox *_simCompareBox;
    
    //Simulation Comparison Tableview
    __weak CPTGraphHostingView *_simulationCompareGraphHostingView;
    __weak NSTableView *_simulationCompareTimeSeriesTableView;
    __weak NSTableView *_simulationCompareOtherSimTableView;
    __weak NSTableView *_simulationCompareSelectedTSTableView;
    
 
    __weak NSDatePicker *_simulationCompareFromDatePicker;
    __weak NSDatePicker *_simulationCompareToDatePicker;
    __weak NSButton *_simulationComparePlotRangeButton;
    __weak NSMatrix *_simulationCompareSimRadio;
    __weak NSMatrix *_simulationCompareLSIndicatorRadio;
    
    __weak NSButton *_comparePlotDotsCheck;
    

}

- (void) setDelegate:(id)del;
- (void) simulationEnded;
- (void) setupResultsReport;
- (void) readingRecordSetProgress: (NSNumber *) progressFraction;
- (void) progressAsFraction:(NSNumber *) progressValue;
- (void) progressBarOn;
- (void) progressBarOff;
- (void) viewChosenFromMainMenu;



@property (retain) NSArray *coloursForPlots;
@property (retain) NSDictionary *fxPairsAndDbIds;
@property (retain) DataController *dataControllerForUI;
@property BOOL doThreads;
@property BOOL firstTimeSetup;

@property (weak) IBOutlet NSButton *performSimulationButton;
@property (weak) IBOutlet NSTableView *simulationTimeSeriesTableView;
@property (weak) IBOutlet CPTGraphHostingView *simulationResultGraphHostingView;
@property (weak) IBOutlet CPTGraphHostingView *simulationSignalGraphHostingView;
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
@property (weak) IBOutlet NSTextField *setupTradingPairPipSizeLabel;
@property (weak) IBOutlet NSTextField *startDateDoWLabel;
@property (weak) IBOutlet NSTextField *endDateDoWLabel;
@property (weak) IBOutlet NSTextField *setupTradingLagTextField;
@property (weak) IBOutlet NSTableView *reportTableView;
@property (weak) IBOutlet NSTableView *registeredSimsTableView;
@property (weak) IBOutlet NSTableView *registeredSimsTableView1;
@property (weak) IBOutlet NSTableView *registeredSimsTableView2;
@property (weak) IBOutlet NSTableView *registeredSimsTableView3;
@property (weak) IBOutlet NSTableView *registeredSimsTableView5;
@property (weak) IBOutlet NSTableView *registeredSimsTableView6;

@property (weak) IBOutlet NSButton *importSimulationButton;
@property (weak) IBOutlet NSButton *removeSimulationButton;
@property (weak) IBOutlet NSScrollView *registeredSimsScrollView1;
@property (weak) IBOutlet NSButton *exportSimulationButton;
@property (weak) IBOutlet NSTextField *returnsHistogramNBins;
@property (weak) IBOutlet NSStepper *returnsHistogramBinsStepper;
@property (weak) IBOutlet NSTextField *returnsHistogramCompareSimName;
@property (weak) IBOutlet NSButton *returnsHistogramCompareToggleButton;


- (IBAction)changeSelectedTradingPair:(id)sender;
- (IBAction)showSetupSheet:(id)sender;
- (IBAction)cancelSimulation:(id)sender;
- (IBAction)cancelSetupSheet:(id)sender;
- (IBAction)performSimulation:(id)sender;
- (IBAction)toggleLongShortIndicator:(id)sender;
- (IBAction)sigPlotLongShortIndicatorToggle:(id)sender;
- (IBAction)compPlotLongShortIndicatorToggle:(id)sender;
- (IBAction)simPlotMoveForward:(id)sender;


- (IBAction)plotLeftSideExpand:(id)sender;
- (IBAction)plotBottomExpand:(id)sender;
- (IBAction)exportData:(id)sender;
- (IBAction)exportTrades:(id)sender;
- (IBAction)exportBalanceAdjustments:(id)sender;
- (IBAction)setupStartTimeChange:(id)sender;
- (IBAction)setupEndTimeChange:(id)sender;


- (IBAction)makeSimulationReport:(id)sender;
- (IBAction)zoomButtonPress:(id)sender;
- (IBAction)simCompareDateRangeButtonPress:(id)sender;

- (IBAction)accountCurrencyChange:(id)sender;
- (IBAction)importCsvData:(id)sender;
- (IBAction)signalAnalysisPlotReload:(id)sender;
- (IBAction)signalAnalysisPlotFullScreen:(id)sender;
- (IBAction)simPlotFullScreen:(id)sender;
- (IBAction)comparePlotFullScreen:(id)sender;
- (IBAction)saveWorkingSimulation:(id)sender;
- (IBAction)importSimulation:(id)sender;
- (IBAction)removeWorkingSimulation:(id)sender;
- (IBAction)sigPlotMoveForward:(id)sender;
- (IBAction)signalAnalysisLeadTimeFinishedEdit:(id)sender;


//- (IBAction)simulationCompareMakePlot:(id)sender;
- (IBAction)simulationCompareChooseSimTimeSeries:(id)sender;
- (IBAction)simulationCompareToggleLSIndicatorSim:(id)sender;

- (IBAction)simulationCompareToggleDashed:(id)sender;
- (IBAction)simulationCompareGetRangeFromSigPlot:(id)sender;

- (IBAction)returnsHistogramStepperPressed:(id)sender;
//- (IBAction)returnsHistogramZeroCheckPressed:(id)sender;
- (IBAction)returnsHistogramNBinsTextEdit:(id)sender;
- (IBAction)returnsHistogramFullScreen:(id)sender;
- (IBAction)returnsHistogramCompareToggle:(id)sender;


@property (weak) IBOutlet NSProgressIndicator *performSimulationProgressBar;
@property (weak) IBOutlet NSTextField *aboutSimNameLabel;
@property (weak) IBOutlet NSTextField *aboutTradingPairLabel;
@property (weak) IBOutlet NSTextField *aboutAccountCurrencyLabel;
@property (weak) IBOutlet NSTextField *aboutSimStartTimeLabel;
@property (weak) IBOutlet NSTextField *aboutSimEndTimeLabel;
@property (weak) IBOutlet NSButton *setUpSheetCancelButton;
@property (weak) IBOutlet NSTableView *simulationTradesTableView;
@property (weak) IBOutlet NSTableView *simulationCashFlowsTableView;
@property (weak) IBOutlet NSTableView *simulationSignalTableView;

@property (weak) IBOutlet NSTextField *signalAnalysisPlotLeadHours;
@property (weak) IBOutlet NSTableView *simulationSignalTimeSeriesTableView;
@property (weak) IBOutlet NSButton *setupTradingWeekendYesNo;
@property (weak) IBOutlet NSTextField *tradingPairLabel;
@property (weak) IBOutlet NSTextField *simulationNameLabel;

@property (weak) IBOutlet NSTextField *startLabel;
@property (weak) IBOutlet NSTextField *endLabel;
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
@property (weak) IBOutlet NSTextField *setupExtraSeriesTextField;
@property (weak) IBOutlet NSTextField *setupDataRateAmount;
@property (weak) IBOutlet NSMatrix *setupDataRateUnit;

@property (weak) IBOutlet NSBox *fullScreenBox;
@property (weak) IBOutlet NSBox *signalAnalysisPlotBox;
@property (weak) IBOutlet NSBox *simPlotBox;
@property (weak) IBOutlet NSBox *returnsHistogramPlotBox;

@property (weak) IBOutlet NSTextField *setupDataWarmUpTextField;
@property (weak) IBOutlet NSTextField *setupRulesTextField;
@property (weak) IBOutlet NSTableView *simulationTimeSeriesSelectedTableView;
@property (weak) IBOutlet NSTableView *simulationSignalSelectedTimeSeriesTableView;
@property (weak) IBOutlet CPTGraphHostingView *returnsHistogramGraphHostingView;

@property (weak) IBOutlet CPTGraphHostingView *simulationCompareGraphHostingView;
@property (weak) IBOutlet NSBox *simCompareBox;
@property (weak) IBOutlet NSTableView *simulationCompareTimeSeriesTableView;
@property (weak) IBOutlet NSDatePicker *simulationCompareFromDatePicker;
@property (weak) IBOutlet NSDatePicker *simulationCompareToDatePicker;
@property (weak) IBOutlet NSButton *simulationComparePlotRangeButton;
@property (weak) IBOutlet NSTableView *simulationCompareOtherSimTableView;
@property (weak) IBOutlet NSTableView *simulationCompareSelectedTSTableView;
@property (weak) IBOutlet NSMatrix *simulationCompareSimRadio;

@property (weak) IBOutlet NSButton *comparePlotDotsCheck;
@property (weak) IBOutlet NSMatrix *simulationCompareLSIndicatorRadio;

@end
