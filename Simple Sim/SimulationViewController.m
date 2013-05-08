//
//  SimulationViewController.m
//  Simple Sim
//
//  Created by Martin O'Connor on 19/03/2012.
//  Copyright (c) 2012 OCONNOR RESEARCH. All rights reserved.
//

#import "SimulationViewController.h"
#import "SimulationController.h"
#import "Simulation.h"
#import "DataController.h"
#import "DataSeries.h"
#import "DataView.h"
#import "TimeSeriesLine.h"
#import "EpochTime.h"
#import "UtilityFunctions.h"
#import "SeriesPlotDataWrapper.h"

#define DAY_SECONDS (24*60*60)

@interface SimulationViewController ()
@property (retain) SimulationController *simulationController;
@property (retain) NSMutableArray *allSimulations;
@property (retain) NSMutableArray *simulationTimeSeries;
@property (retain) NSMutableArray *simulationSignalTimeSeries;
@property (retain) NSMutableArray *simulationCompareSimATimeSeries;
@property (retain) NSMutableArray *simulationCompareSimBTimeSeries;
@property (retain) NSMutableDictionary *simulationCompareSelectedTimeSeries;
@property (retain) NSMutableDictionary *simulationSignalSelectedTimeSeries;
@property (retain) NSMutableDictionary *simulationSelectedTimeSeries;
@property (retain) NSMutableArray *signalTableViewOrdering;
@property (retain) NSArray *hideObjectsOnStartup;
@property (retain) NSArray *importDataArray;
@property (retain) NSString *importDataFilename;
@property (retain) NSString *signalTableViewSortColumn;
@property BOOL doingSetup;
@property BOOL cancelProcedure;
@property BOOL initialSetupComplete;
@property BOOL signalTableViewSortedAscending;
@property BOOL longShortIndicatorOn;
//@property (retain) DataSeries *simulationDataSeries;
@property (retain) SeriesPlot *simulationResultsPlot;
@property (retain) SeriesPlot *signalAnalysisPlot;
@property (retain) SeriesPlot *simulationComparePlot;
@property (retain) Simulation *workingSimulation;
@property (retain) Simulation *compareSimulation;
@property BOOL compareSimulationLoaded;
@property (retain) SeriesPlotDataWrapper *comparePlotInfo;
@property (retain) SeriesPlotDataWrapper *simulationPlotInfo;
@property (retain) SeriesPlotDataWrapper *signalPlotInfo;

- (void) putFieldNamesInCorrectOrdering:(NSMutableArray *) fieldNamesFromData;
- (void) endSetupSheet;
- (void) updateStatus:(NSString *) statusMessage;
- (void) showAlertPanelWithInfo: (NSDictionary *) alertInfo;
- (NSArray *) csvDataFromURL: (NSURL *)absoluteURL;
- (void) addPlotToFullScreenWindow: (NSView *) fullScreenView;
- (void)makeSignalAnalysisPlot;


- (void) clearSimulationMessage;
- (void) outputSimulationMessage:(NSString *) message;
- (void) gettingDataIndicatorSwitchOn;
- (void) gettingDataIndicatorSwitchOff;
- (void) readingRecordSetProgress: (NSNumber *) progressFraction;
- (void) readingRecordSetMessage: (NSString *) progressMessage;
- (void) progressAsFraction:(NSNumber *) progressValue;
- (void) progressBarOn;
- (void) progressBarOff;
- (void) initialiseSignalTableView;
- (void) setupResultsReport;
- (void) addSimInfoToAboutPanel;
- (void) plotSimulationData;
- (void) prepareSimCompareSheet;
- (void) addSimulationDataToResultsTableView;
- (void) prepareForSimulationReport;
- (void) displayWorkingSim;
- (void) disableSimulationBrowser;
- (void) fillSetupSheet:(NSDictionary *) parameters;
- (void) updateSelectedSimCompareTimeseries;
- (void) updateSimulationSelectedTimeSeries;
- (void) updateSimulationSignalSelectedTimeSeries;
- (void) leftPanelTopMessage:(NSString *) message;
@end

@implementation SimulationViewController



- (id)init{
    self = [super initWithNibName:@"SimulationView" bundle:nil];
    if(self){
        [self setTitle:@"Simulation"];
        _initialSetupComplete = YES;
        _doingSetup = NO;
        _cancelProcedure = NO;
        _firstTimeSetup = YES;
        [self setDoThreads:NO];
        _simulationTimeSeries = [[NSMutableArray alloc] init];
        _simulationCompareSimATimeSeries = [[NSMutableArray alloc] init];
        _simulationCompareSimBTimeSeries = [[NSMutableArray alloc] init];
        _simulationCompareSelectedTimeSeries = [[NSMutableDictionary alloc] init];
        _simulationSignalSelectedTimeSeries = [[NSMutableDictionary alloc] init];
        _simulationSelectedTimeSeries = [[NSMutableDictionary alloc] init];
        _simulationSignalTimeSeries = [[NSMutableArray alloc] init]; 
        _signalTableViewSortedAscending = YES;
        _allSimulations = [[NSMutableArray alloc] init];
        _simulationController = [[SimulationController alloc] init];
        [_simulationController setDelegate:self];
        [_simulationController setDoThreads:_doThreads];
        _compareSimulationLoaded = NO;
        _workingSimulation = nil;
        
    }
    return self;
}

- (void) awakeFromNib
{
    fullScreenWindowController = [[NSWindowController alloc] initWithWindow:fullScreenWindow];
    [fullScreenWindow setDelegate:self];
    
    NSTableColumn *simulationColourColumn =  [simulationTimeSeriesTableView tableColumnWithIdentifier:@"colourId"];
    NSTableColumn *signalAnalysisColourColumn =  [simulationSignalTimeSeriesTableView tableColumnWithIdentifier:@"colourId"];
    NSTableColumn *simulationCompareColourColumn =  [_simulationCompareTimeSeriesTableView tableColumnWithIdentifier:@"colourId"];
    
    
    NSPopUpButtonCell *simulationColourDropDownCell = [[NSPopUpButtonCell alloc] init];
    NSPopUpButtonCell *signalAnalysisColourDropDownCell = [[NSPopUpButtonCell alloc] init];
    NSPopUpButtonCell *simulationCompareColourDropDownCell = [[NSPopUpButtonCell alloc] init];
    
    [simulationColourDropDownCell setBordered:NO];
    [simulationColourDropDownCell setEditable:YES];
    
     
    [signalAnalysisColourDropDownCell setBordered:NO];
    [signalAnalysisColourDropDownCell setEditable:YES];
    
    [simulationCompareColourDropDownCell setBordered:NO];
    [simulationCompareColourDropDownCell setEditable:YES];
     
    [simulationColourDropDownCell addItemsWithTitles:[self coloursForPlots]];
    [simulationColourColumn setDataCell:simulationColourDropDownCell];
    [simulationTimeSeriesTableView setDataSource:self];
    
    [simulationTimeSeriesSelectedTableView setDataSource:self];
    [simulationTimeSeriesSelectedTableView setDelegate:self];
    
    [signalAnalysisColourDropDownCell addItemsWithTitles:[self coloursForPlots]];
    [signalAnalysisColourColumn setDataCell:simulationColourDropDownCell];
    [simulationSignalTimeSeriesTableView setDataSource:self];
    
    [simulationSignalSelectedTimeSeriesTableView setDataSource:self];
    [simulationSignalSelectedTimeSeriesTableView setDelegate:self];
    
    [simulationCompareColourDropDownCell addItemsWithTitles:[self coloursForPlots]];
    [simulationCompareColourColumn setDataCell:simulationColourDropDownCell];
    [_simulationCompareTimeSeriesTableView setDataSource:self];
    [_simulationCompareTimeSeriesTableView setDelegate:self];
    
    
    [registeredSimsTableView1 setDataSource:self];
    [registeredSimsTableView1 setDelegate:self];
    
    [registeredSimsTableView2 setDataSource:self];
    [registeredSimsTableView2 setDelegate:self];
    
    [registeredSimsTableView3 setDataSource:self];
    [registeredSimsTableView3 setDelegate:self];
    
    [registeredSimsTableView setDataSource:self];
    [registeredSimsTableView setDelegate:self];
    
    [registeredSimsTableView5 setDataSource:self];
    [registeredSimsTableView5 setDelegate:self];
    
    
    [_simulationCompareOtherSimTableView setDataSource:self];
    [_simulationCompareOtherSimTableView setDelegate:self];
     
    [_simulationCompareSelectedTSTableView setDataSource:self];
    [_simulationCompareSelectedTSTableView setDelegate:self];
    
    //Popup sheet stuff
    [setupTradingPairPopup removeAllItems];
    NSArray *fxPairs = [[self fxPairsAndDbIds] allKeys];
    for (int i = 0; i < [fxPairs count];i++) {
        [setupTradingPairPopup addItemWithTitle:[fxPairs objectAtIndex:i]];
    }
    
    [setupTradingPairPopup selectItemAtIndex:0];
    NSString *selectedPair = [[setupTradingPairPopup selectedItem] title];
    [setupAccountCurrencyPopup removeAllItems];
    [setupAccountCurrencyPopup addItemWithTitle:[selectedPair substringFromIndex:3]];
    [setupAccountCurrencyPopup addItemWithTitle:[selectedPair substringToIndex:3]];
    [setupAccountCurrencyPopup selectItemAtIndex:0];
    [setupAccountCurrencyLabel setStringValue:[[setupAccountCurrencyPopup selectedItem] title]];
    
    double pipsize = [[self dataControllerForUI] getPipsizeForSeriesName:selectedPair] ;
    [setupTradingPairPipSizeLabel setStringValue:[NSString stringWithFormat:@"%6.4f",pipsize]];
    
    long minDataDateTime = [[self dataControllerForUI] getMinDateTimeForFullData];
    long maxDataDateTime = [[self dataControllerForUI] getMaxDateTimeForFullData];
    
    [dataAvailabilityFromLabel setStringValue:[[NSDate dateWithTimeIntervalSince1970:(NSTimeInterval) minDataDateTime] descriptionWithCalendarFormat:@"%Y-%m-%d" timeZone:[NSTimeZone timeZoneWithName:@"GMT"] locale:nil]];
    [dataAvailabilityToLabel setStringValue:[[NSDate dateWithTimeIntervalSince1970:(NSTimeInterval) maxDataDateTime] descriptionWithCalendarFormat:@"%Y-%m-%d" timeZone:[NSTimeZone timeZoneWithName:@"GMT"] locale:nil]];
    
    NSCalendar *gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
    [setupStartTimePicker setTimeZone:[NSTimeZone timeZoneWithName:@"GMT"]];
    [setupStartTimePicker setCalendar:gregorian];
    
    [setupEndTimePicker setTimeZone:[NSTimeZone timeZoneWithName:@"GMT"]];
    [setupEndTimePicker setCalendar:gregorian];
    
    
    [setupStartTimePicker setMinDate:[NSDate dateWithTimeIntervalSince1970:(NSTimeInterval) minDataDateTime]];
    [setupStartTimePicker setMaxDate:[NSDate dateWithTimeIntervalSince1970:(NSTimeInterval) maxDataDateTime]];
    
    [setupEndTimePicker setMinDate:[NSDate dateWithTimeIntervalSince1970:(NSTimeInterval) minDataDateTime]];
    [setupEndTimePicker setMaxDate:[NSDate dateWithTimeIntervalSince1970:(NSTimeInterval) maxDataDateTime]];
    
    [setupStartTimePicker setTimeZone:[NSTimeZone timeZoneWithName:@"GMT"]];
    [setupStartTimePicker setDateValue:[NSDate dateWithTimeIntervalSince1970:(NSTimeInterval) minDataDateTime]]; 
    [startDateDoWLabel setStringValue:[[setupStartTimePicker dateValue] descriptionWithCalendarFormat:@"%a" timeZone:[NSTimeZone timeZoneWithName:@"GMT"] locale:nil]]; 
    
    [setupEndTimePicker setTimeZone:[NSTimeZone timeZoneWithName:@"GMT"]];
    [setupEndTimePicker setDateValue:[NSDate dateWithTimeIntervalSince1970:(NSTimeInterval) minDataDateTime+(50*DAY_SECONDS)]]; 
    [endDateDoWLabel setStringValue:[[setupEndTimePicker dateValue] descriptionWithCalendarFormat:@"%a" timeZone:[NSTimeZone timeZoneWithName:@"GMT"] locale:nil]]; 
    
    [setupTradingStartTimePicker setTimeZone:[NSTimeZone timeZoneWithName:@"GMT"]];
    [setupTradingEndTimePicker setTimeZone:[NSTimeZone timeZoneWithName:@"GMT"]];
    [setupTradingStartTimePicker setDateValue:[NSDate dateWithTimeIntervalSince1970:(6*60*60)+(30*60)]];
    [setupTradingEndTimePicker setDateValue:[NSDate dateWithTimeIntervalSince1970:(16*60*60)+(30*60)]];
    
    [zoomFromDatePicker setTimeZone:[NSTimeZone timeZoneWithName:@"GMT"]];
    [zoomFromDatePicker setCalendar:gregorian];
    
    [zoomToDatePicker setTimeZone:[NSTimeZone timeZoneWithName:@"GMT"]];
    [zoomToDatePicker setCalendar:gregorian];
    
    [[self simulationCompareFromDatePicker] setTimeZone:[NSTimeZone timeZoneWithName:@"GMT"]];
    [[self simulationCompareFromDatePicker] setCalendar:gregorian];
    
    [[self simulationCompareToDatePicker] setTimeZone:[NSTimeZone timeZoneWithName:@"GMT"]];
    [[self simulationCompareToDatePicker] setCalendar:gregorian];
    
    
    [setupSheetImportDataTableView setDataSource:self];
    
    NSUInteger tabIndex;
    tabIndex = [centreTabView indexOfTabViewItemWithIdentifier:@"SIMRUN"];
    setupTab = [centreTabView tabViewItemAtIndex:tabIndex];
    tabIndex = [centreTabView indexOfTabViewItemWithIdentifier:@"PLOT"];
    plotTab = [centreTabView tabViewItemAtIndex:tabIndex];
    tabIndex = [centreTabView indexOfTabViewItemWithIdentifier:@"NUMBERS"];
    dataTab = [centreTabView tabViewItemAtIndex:tabIndex];
    tabIndex = [centreTabView indexOfTabViewItemWithIdentifier:@"REPORT"];
    reportTab = [centreTabView tabViewItemAtIndex:tabIndex];
    tabIndex = [centreTabView indexOfTabViewItemWithIdentifier:@"SIGNAL"];
    signalsTab = [centreTabView tabViewItemAtIndex:tabIndex];
    tabIndex = [centreTabView indexOfTabViewItemWithIdentifier:@"COMPARE"];
    compareTab = [centreTabView tabViewItemAtIndex:tabIndex];
    
    //tabIndex = [centreTabView indexOfTabViewItemWithIdentifier:@"ZOOM"];
    
    [centreTabView removeTabViewItem:plotTab];
    [centreTabView removeTabViewItem:dataTab];
    [centreTabView removeTabViewItem:reportTab];
    [centreTabView removeTabViewItem:signalsTab];
    [centreTabView removeTabViewItem:compareTab];
    
    [self setHideObjectsOnStartup:[NSArray arrayWithObjects: aboutSimNameLabel, aboutTradingPairLabel, aboutAccountCurrencyLabel, aboutSimStartTimeLabel,aboutSimEndTimeLabel, tradingPairLabel, accountCurrencyLabel, simulationNameLabel, startLabel, endLabel, samplingRateLabel, tradingLagLabel, tradingDayStartLabel, tradingDayEndLabel,descriptionLabel, registeredSimsScrollView1, removeSimulationButton, importSimulationButton, nil]];
    
    
    for(int i =0; i < [[self hideObjectsOnStartup] count];i++){
        [[[self hideObjectsOnStartup] objectAtIndex:i] setHidden:YES];
    }
    
    int nColumns = 7;
    NSArray *sigTableHeaders = [NSArray arrayWithObjects:@"Entry Time", @"Exit Time", @"Signal", @"Entry Price", @"Exit Price", @"Signal Gain", @"Nav Change", nil];
    
    NSArray *sigTableIds = [NSArray arrayWithObjects:@"ENTRYTIME", @"EXITTIME",@"SIGNAL" , @"ENTRYPRICE", @"EXITPRICE",  @"SIGNALGAIN", @"PNL", nil];
    
    float columnWidths[7] = {150.0, 150.0, 75.0, 75.0, 75.0, 75.0, 75.0};
    
    for (int i = 0; i < nColumns; i++)
    {
        NSTableColumn *newColumn = [[NSTableColumn alloc] initWithIdentifier:[sigTableIds objectAtIndex:i]];
        [newColumn setWidth:columnWidths[i]];
        
        [[newColumn headerCell] setStringValue:[sigTableHeaders objectAtIndex:i]];
        if(i > 1){
            NSCell *dataCell = [newColumn dataCell];
                [dataCell setAlignment:NSRightTextAlignment];
         }
        [simulationSignalTableView addTableColumn:newColumn];
    }
    
    [simulationRunScrollView setFrame:CGRectMake(18.0f, 59.0f, 650.0f, 417.0f)];
    [centreTabView selectTabViewItemWithIdentifier:@"SIMRUN"];
    [rightSideTabView selectTabViewItemWithIdentifier:@"SIMRUN"];
    
    [simulationSignalTimeSeriesTableView setDelegate:self];
    
    [simulationTimeSeriesTableView setDelegate:self];
    [self setInitialSetupComplete:NO];
    
    _simulationResultsPlot = [[SeriesPlot alloc] initWithIdentifier:@"SIMRESULTS"];
    [_simulationResultsPlot setHostingView:simulationResultGraphHostingView];
    [_simulationResultsPlot initialGraphAndAddAnnotation:NO];
    
    _signalAnalysisPlot = [[SeriesPlot alloc] initWithIdentifier:@"SIGNALS"];
    [_signalAnalysisPlot setHostingView:simulationSignalGraphHostingView];
    
    _simulationComparePlot = [[SeriesPlot alloc] initWithIdentifier:@"SIMCOMPARE"];
    [_simulationComparePlot setHostingView:_simulationCompareGraphHostingView];
    [_simulationComparePlot initialGraphAndAddAnnotation:NO];
   
}

- (void) setDelegate:(id)del
{
    delegate = del;
}

- (id) delegate 
{ 
    return delegate;
};

- (BOOL) doThreads
{
    return _doThreads;
}

- (void) setDoThreads:(BOOL)doThreadedProcedures
{
    _doThreads = doThreadedProcedures;
    [[self simulationController] setDoThreads:doThreadedProcedures];
}

- (void) initialiseSignalTableView
{
    [self setSignalTableViewOrdering:[[NSMutableArray alloc] initWithCapacity:[[self workingSimulation] numberOfSignals]]];
    
    if( [[self workingSimulation] numberOfSignals]>0){
        [[self signalTableViewOrdering] removeAllObjects];
        for(int i = 0; i < [[self workingSimulation] numberOfSignals]; i++){
            [[self signalTableViewOrdering] addObject:[NSNumber numberWithInt:i]];  
        }
        [self setSignalTableViewSortColumn:@"ENTRYTIME"];
        
        NSDictionary *signalInfo;
        signalInfo = [[self workingSimulation] detailsOfSignalAtIndex:0];
        NSUInteger tradingLag = [[self workingSimulation] tradingLag];
        
        long startDateTime = [[signalInfo objectForKey:@"ENTRYTIME"] longValue];
        startDateTime = startDateTime - ([signalAnalysisPlotLeadHours intValue] * 60*60);
        long endDateTime = [[signalInfo objectForKey:@"EXITTIME"] longValue] + 2*tradingLag;
        
        DataSeries *analysisDataSeries = [[self workingSimulation] analysisDataSeries]; 
        TimeSeriesLine *tsl;
        
        NSMutableArray *fieldNames = [[[analysisDataSeries yData] allKeys] mutableCopy];
        for(int i = 0; i < [fieldNames count]; i++){
            if([[fieldNames objectAtIndex:i] isEqualToString:@"SHORT"]){
                [fieldNames removeObjectAtIndex:i];
                break;
            }
        }
        for(int i = 0; i < [fieldNames count]; i++){
            if([[fieldNames objectAtIndex:i] isEqualToString:@"LONG"]){
                [fieldNames removeObjectAtIndex:i];
                break;
            }
        }
      
        [self putFieldNamesInCorrectOrdering:fieldNames];
        [self clearTSTableView:simulationSignalTimeSeriesTableView];
        int plotLayerIndex;
        NSString *lineColour;
        for(int i = 0; i < [fieldNames count]; i++){
            switch (i) {
                case 0:
                    plotLayerIndex = 0;
                    break;
                default:
                    plotLayerIndex = -1;
                    break;
            }
            lineColour = [[self coloursForPlots] objectAtIndex:i%[[self coloursForPlots] count]];
            tsl = [[TimeSeriesLine alloc] initWithLayerIndex:plotLayerIndex 
                                                     AndName:[fieldNames objectAtIndex:i] 
                                                   AndColour:lineColour];
            [self addToTableView:simulationSignalTimeSeriesTableView 
                  TimeSeriesLine:tsl];
        }
        startDateTime = startDateTime - ([signalAnalysisPlotLeadHours intValue] * 60*60);
        [self setLongShortIndicatorOn:YES];
        [self updateSimulationSignalSelectedTimeSeries];
        SeriesPlotDataWrapper *signalPlotDataSource = [[SeriesPlotDataWrapper alloc] initWithTargetPlotName: @"SIG"
                                                                                              AndSimulation:[self workingSimulation]
                                                                                            AndTSDictionary:[self simulationSignalSelectedTimeSeries]
                                                                                    AndDoShortLongIndicator:YES];
        [signalPlotDataSource setDataViewWithStartDateTime:startDateTime
                                            AndEndDateTime:endDateTime
                                                    AsZoom:NO];
        
        [[self signalAnalysisPlot] setBasicParametersForPlot];
        [[self signalAnalysisPlot] updateLines:signalPlotDataSource];
        [self setSignalPlotInfo:signalPlotDataSource];
        
        
        [simulationSignalSelectedTimeSeriesTableView reloadData];
        [simulationSignalTableView reloadData];
    }
    
}

-(void)setupResultsReport
{
    [reportTableView reloadData];
}

-(void)simulationEnded
{
    [self setInitialSetupComplete:YES];
    [setUpSheetCancelButton setEnabled:NO];
    [setupSheetShowButton setEnabled:YES];
    [importSimulationButton setHidden:NO];
    [removeSimulationButton setHidden:NO];
    [exportSimulationButton setHidden:NO];
    [registeredSimsScrollView1 setHidden:NO];
    [[NSSound soundNamed:@"Purr"] play];
}


-(void)plotSimulationData
{
    DataSeries *analysisDataSeries = [[self workingSimulation] analysisDataSeries];
    TimeSeriesLine *tsl;
    
    NSMutableArray *fieldNames = [[[analysisDataSeries yData] allKeys] mutableCopy];
    for(int i = 0; i < [fieldNames count]; i++){
        if([[fieldNames objectAtIndex:i] isEqualToString:@"SHORT"]){
            [fieldNames removeObjectAtIndex:i];
            break;
        }
    }
    for(int i = 0; i < [fieldNames count]; i++){
        if([[fieldNames objectAtIndex:i] isEqualToString:@"LONG"]){
            [fieldNames removeObjectAtIndex:i];
            break;
        }
    }
    
    [self putFieldNamesInCorrectOrdering:fieldNames];
    
    // Simulation results plot
    [self clearTSTableView:simulationTimeSeriesTableView];
    int plotLayerIndex;
    NSString *lineColour;
    for(int i = 0; i < [fieldNames count]; i++){
        switch (i) {
            case 0:
                plotLayerIndex = 0;
                break;
            default:
                plotLayerIndex = -1;
                break;
        }
        lineColour = [[self coloursForPlots] objectAtIndex:i%[[self coloursForPlots] count]];
        tsl = [[TimeSeriesLine alloc] initWithLayerIndex:plotLayerIndex
                                                 AndName:[fieldNames objectAtIndex:i] 
                                               AndColour:lineColour];
        [self addToTableView:simulationTimeSeriesTableView   TimeSeriesLine:tsl];
    }
    [self updateSimulationSelectedTimeSeries];
    [simulationTimeSeriesTableView reloadData];
    [simulationTimeSeriesSelectedTableView reloadData];
    
    SeriesPlotDataWrapper *plotDataSource = [[SeriesPlotDataWrapper alloc] initWithTargetPlotName: @"SIM"
                                                                                    AndSimulation:[self workingSimulation]
                                                                                  AndTSDictionary:[self simulationSelectedTimeSeries]
                                                                          AndDoShortLongIndicator:YES];
    
    [plotDataSource setDataViewWithStartDateTime:[analysisDataSeries minDateTime]
                                  AndEndDateTime:[analysisDataSeries maxDateTime]
                                          AsZoom:NO];
    [self setSimulationPlotInfo:plotDataSource];
    [[self simulationResultsPlot] setBasicParametersForPlot];
    [[self simulationResultsPlot] updateLines:plotDataSource];
    
    [zoomFromDatePicker setMinDate:[NSDate dateWithTimeIntervalSince1970:[analysisDataSeries minDateTime]]];
    [zoomFromDatePicker setMaxDate:[NSDate dateWithTimeIntervalSince1970:[analysisDataSeries maxDateTime]]];
    [zoomFromDatePicker setDateValue:[NSDate dateWithTimeIntervalSince1970:[analysisDataSeries minDateTime]]];
    [zoomToDatePicker setMinDate:[NSDate dateWithTimeIntervalSince1970:[analysisDataSeries minDateTime]]];
    [zoomToDatePicker setMaxDate:[NSDate dateWithTimeIntervalSince1970:[analysisDataSeries maxDateTime]]];
}

-(void) prepareSimCompareSheet
{
    [[self simulationCompareSimRadio] selectCellAtRow:0 column:0];
    NSArray *radioCells = [[self simulationCompareSimRadio] cells];
    for(int i = 0; i < [radioCells count]; i++){
        [[radioCells objectAtIndex:i] setEnabled:NO];
    }
    [[self simulationCompareSimATimeSeries] removeAllObjects];
    TimeSeriesLine *tsl, *tsl2;
    for(int i = 0; i < [[self simulationTimeSeries] count]; i++){
        tsl = [[self simulationTimeSeries] objectAtIndex:i];
        if(i == 0){
            tsl2 = [[TimeSeriesLine alloc] initWithLayerIndex:0
                                                      AndName:[tsl name]
                                                    AndColour:[tsl colour]
                                                     AndSimId:0];

        }else{
            tsl2 = [[TimeSeriesLine alloc] initWithLayerIndex:-1
                                                      AndName:[tsl name]
                                                    AndColour:[tsl colour]
                                                     AndSimId:0];
        }
        [[self simulationCompareSimATimeSeries] addObject:tsl2];
    }
    [[self simulationCompareSimBTimeSeries] removeAllObjects];
    [self updateSelectedSimCompareTimeseries];
    [[self simulationCompareTimeSeriesTableView] reloadData];
    
    [[self simulationCompareFromDatePicker] setDateValue:[NSDate dateWithTimeIntervalSince1970:[[self workingSimulation] startDate]]];
    [[self simulationCompareFromDatePicker] setMinDate:[NSDate dateWithTimeIntervalSince1970:[[self workingSimulation] startDate]]];
    [[self simulationCompareFromDatePicker] setMaxDate:[NSDate dateWithTimeIntervalSince1970:[[self workingSimulation] endDate]]];
    [[self simulationCompareToDatePicker] setDateValue:[NSDate dateWithTimeIntervalSince1970:[[self workingSimulation] startDate] + (30*24*60*60)]];
    [[self simulationCompareToDatePicker] setMinDate:[NSDate dateWithTimeIntervalSince1970:[[self workingSimulation] startDate]]];
    [[self simulationCompareToDatePicker] setMaxDate:[NSDate dateWithTimeIntervalSince1970:[[self workingSimulation] endDate]]];
    
    
    SeriesPlotDataWrapper *plotDataSource = [[SeriesPlotDataWrapper alloc] initWithTargetPlotName: @"COM"
                                                                                    AndSimulation:[self workingSimulation]
                                                                                  AndTSDictionary:[self simulationCompareSelectedTimeSeries]
                                                                          AndDoShortLongIndicator:NO];
    [plotDataSource setDataViewWithStartDateTime:[[self workingSimulation] startDate]
                                  AndEndDateTime:[[self workingSimulation] endDate] + (30*24*60*60)
                                          AsZoom:NO];
    [[self simulationComparePlot] setBasicParametersForPlot];
    [self setComparePlotInfo:plotDataSource];
    [[self simulationComparePlot] updateLines:[self comparePlotInfo]];
}

- (void) addSimulationDataToResultsTableView
{
    DataSeries *analysisDataSeries = [[self workingSimulation] analysisDataSeries];
    [self clearTSTableView:simulationNumbersTableView];
    
    NSTableColumn *newTableColumn;
    NSArray *tableColumns;
    NSMutableArray *fieldNames;
    NSMutableArray *isAvailable;
    NSArray *fieldNamesFromData;
    float tableViewWidth = 0.0;
    
    fieldNames = [[[analysisDataSeries yData] allKeys] mutableCopy];
    for(int i = 0; i < [fieldNames count]; i++){
        if([[fieldNames objectAtIndex:i] isEqualToString:@"SHORT"]){
            [fieldNames removeObjectAtIndex:i];
            break;
        }
    }
    for(int i = 0; i < [fieldNames count]; i++){
        if([[fieldNames objectAtIndex:i] isEqualToString:@"LONG"]){
            [fieldNames removeObjectAtIndex:i];
            break;
        }
    }
    [self putFieldNamesInCorrectOrdering:fieldNames];
    
    isAvailable = [[NSMutableArray alloc] init];
    
    fieldNamesFromData = [[analysisDataSeries yData] allKeys];
    for(int i = 0; i < [fieldNames count]; i ++){
        BOOL found = NO;
        for(int j = 0; j < [fieldNamesFromData count]; j++){
            if([[fieldNames objectAtIndex:i] isEqualToString:[fieldNamesFromData objectAtIndex:j]])
            {
                found = YES;
                break;
            }
        }
        if(found){
            [isAvailable addObject:[NSNumber numberWithBool:YES]];
        }else{
            [isAvailable addObject:[NSNumber numberWithBool:NO]];
        }
    }
    for(long i = [fieldNames count] - 1; i >= 0; i--){
        if(![[isAvailable objectAtIndex:i] boolValue]){
            [fieldNames removeObjectAtIndex:i];
        }
    }
    
    tableColumns = [simulationNumbersTableView tableColumns];
    //int numberOfColumns = [tableColumns count];
    while([tableColumns count] > 0)
    {
        [simulationNumbersTableView removeTableColumn:[tableColumns objectAtIndex:0]];
        tableColumns = [simulationNumbersTableView tableColumns];
    }
    
    newTableColumn = [[NSTableColumn alloc] initWithIdentifier:@"DATETIME"];
    [[newTableColumn headerCell] setStringValue:@"DATETIME"];
    [newTableColumn setWidth:150];
    tableViewWidth = [newTableColumn width];
    [simulationNumbersTableView addTableColumn:newTableColumn];
    
    NSCell *columnsCell;
    for(int newColumnIndex = 0; newColumnIndex < [fieldNames count]; newColumnIndex++){
        newTableColumn = [[NSTableColumn alloc] initWithIdentifier:[fieldNames objectAtIndex:newColumnIndex]];
        [[newTableColumn headerCell] setStringValue:[fieldNames objectAtIndex:newColumnIndex]];
        [newTableColumn setWidth:70];
        tableViewWidth = tableViewWidth + [newTableColumn width];
        columnsCell = [newTableColumn dataCell];
        [columnsCell setAlignment:NSRightTextAlignment];
        [simulationNumbersTableView addTableColumn:newTableColumn];
        
    }
    [simulationNumbersTableView widthAdjustLimit];
    [simulationNumbersTableView reloadData];
}

//- (void) plotSignalDataFrom: (long) startDateTime 
//                         To:(long) endDateTime
//{
////    DataSeries *analysisDataSeries = [[self workingSimulation] analysisDataSeries]; 
////    
////    [analysisDataSeries setDataViewWithName:@"SIGNAL"
////                           AndStartDateTime:startDateTime
////                             AndEndDateTime:endDateTime];
//    
//    //[[self signalAnalysisPlot] setData:analysisDataSeries WithViewName:@"SIGNAL"];
//    [[self signalAnalysisPlot] updateLines:[self signalPlotInfo]];
//}

- (void) addSimInfoToAboutPanel
{   
    [aboutSimNameLabel setStringValue:[[self workingSimulation] name]];
    [aboutTradingPairLabel setStringValue: [NSString stringWithFormat:@"%@%@",[[self workingSimulation]  baseCode],[[self workingSimulation]  quoteCode]]];
    [aboutAccountCurrencyLabel setStringValue: [[self workingSimulation] accCode]];
    [aboutSimStartTimeLabel setStringValue: [EpochTime stringDateWithTime:[[self workingSimulation] startDate]]];
    [aboutSimEndTimeLabel setStringValue: [EpochTime stringDateWithTime:[[self workingSimulation] endDate]]];
}

- (void) viewChosenFromMainMenu
{
    if(![self initialSetupComplete]){
        //Not yet, this is to sh]ow cancel that the setup button has been pressed
        [self setDoingSetup:NO];
        [self disableMainButtons];
        [setupSheetShowButton setEnabled:NO];
        [NSApp beginSheet:setupSheet modalForWindow:[centreTabView window] modalDelegate:nil didEndSelector:NULL contextInfo:NULL];
    }
}

- (void) endSetupSheet
{
    if([self cancelProcedure] == NO)
    {
        [NSApp endSheet:setupSheet returnCode: NSOKButton];
    }else{
        [NSApp endSheet:setupSheet returnCode: NSCancelButton];
        [setupSheetShowButton setEnabled:YES];
        [importSimulationButton setHidden:NO];
        [removeSimulationButton setHidden:NO];
        [exportSimulationButton setHidden:NO];
        [registeredSimsScrollView1 setHidden:NO];
    }
    [self enableMainButtons];
    [setupSheet orderOut:nil];
    
}

- (NSArray *) csvDataFromURL:(NSURL *)absoluteURL{
   
    NSString *fileString = [NSString stringWithContentsOfURL:absoluteURL 
                                                        encoding:NSUTF8StringEncoding error:nil];
    if (fileString == nil ) return nil;
    
    NSMutableArray *rows = [NSMutableArray array];
    
    // Get newline character set
    NSMutableCharacterSet *newlineCharacterSet = (id)[NSMutableCharacterSet whitespaceAndNewlineCharacterSet];
    [newlineCharacterSet formIntersectionWithCharacterSet:[[NSCharacterSet whitespaceCharacterSet] invertedSet]];
    
    // Characters that are important to the parser
    NSMutableCharacterSet *importantCharactersSet = (id)[NSMutableCharacterSet characterSetWithCharactersInString:@",\""];
    [importantCharactersSet formUnionWithCharacterSet:newlineCharacterSet];
    
    // Create scanner, and scan string
    NSScanner *scanner = [NSScanner scannerWithString:fileString];
    [scanner setCharactersToBeSkipped:nil];
    while ( ![scanner isAtEnd] ) {        
        BOOL insideQuotes = NO;
        BOOL finishedRow = NO;
        NSMutableArray *columns = [NSMutableArray arrayWithCapacity:10];
        NSMutableString *currentColumn = [NSMutableString string];
        while ( !finishedRow ) {
            NSString *tempString;
            if ( [scanner scanUpToCharactersFromSet:importantCharactersSet intoString:&tempString] ) {
                [currentColumn appendString:tempString];
            }
            
            if ( [scanner isAtEnd] ) {
                if ( ![currentColumn isEqualToString:@""] ) [columns addObject:currentColumn];
                finishedRow = YES;
            }
            else if ( [scanner scanCharactersFromSet:newlineCharacterSet intoString:&tempString] ) {
                if ( insideQuotes ) {
                    // Add line break to column text
                    [currentColumn appendString:tempString];
                }
                else {
                    // End of row
                    if ( ![currentColumn isEqualToString:@""] ) [columns addObject:currentColumn];
                    finishedRow = YES;
                }
            }
            else if ( [scanner scanString:@"\"" intoString:NULL] ) {
                if ( insideQuotes && [scanner scanString:@"\"" intoString:NULL] ) {
                    // Replace double quotes with a single quote in the column string.
                    [currentColumn appendString:@"\""]; 
                }
                else {
                    // Start or end of a quoted string.
                    insideQuotes = !insideQuotes;
                }
            }
            else if ( [scanner scanString:@"," intoString:NULL] ) {  
                if ( insideQuotes ) {
                    [currentColumn appendString:@","];
                }
                else {
                    // This is a column separating comma
                    [columns addObject:currentColumn];
                    currentColumn = [NSMutableString string];
                    [scanner scanCharactersFromSet:[NSCharacterSet whitespaceCharacterSet] intoString:NULL];
                }
            }
        }
        if ( [columns count] > 0 ) [rows addObject:columns];
    }
    
    return rows;
}

- (void) addPlotToFullScreenWindow: (NSView *) fullScreenView {
     
    //NSRect screenSizeRect = [[fullScreenWindow screen] frame];
    NSRect usableScreenSizeRect = [[fullScreenWindow screen] visibleFrame];
    //NSRect windowSizeRect = [fullScreenWindow frameRectForContentRect:screenSizeRect];
    [fullScreenWindow setFrame:usableScreenSizeRect
                       display:YES
                       animate:NO];
    
    NSWindow *w = [fullScreenBox window];
    BOOL ended = [w makeFirstResponder:w];
    if(!ended){
        NSBeep();
        return;
    }
    
    [fullScreenBox setContentView:fullScreenView];
    
    //Compute the new window frame
    NSSize currentSize = [[fullScreenBox contentView] frame].size;
    NSSize newSize = [fullScreenView frame].size;
    float deltaWidth = newSize.width - currentSize.width;
    float deltaHeight = newSize.height - currentSize.height;
    NSRect windowFrame = [w frame];
    windowFrame.size.height += deltaHeight;
    windowFrame.origin.y -= deltaHeight;
    windowFrame.size.width += deltaWidth;
    
    //Clear the box for resizing
    [fullScreenBox setContentView:nil];
    [w setFrame:windowFrame display:YES animate:YES];
    [fullScreenBox setContentView:fullScreenView];
    //[fullScreenWindowController showWindow:self];
    [NSApp runModalForWindow:fullScreenWindow];
}

-(void)makeSignalAnalysisPlot
{
    NSInteger selectedRow = [simulationSignalTableView selectedRow];
    
    if(selectedRow > -1){
        NSDictionary *signalInfo;
        long startDateTime, endDateTime;
        NSUInteger tradingLag = [[self workingSimulation] tradingLag];
        
        if([simulationSignalTableView numberOfSelectedRows] > 1){
            NSIndexSet *selectedIndexes = [simulationSignalTableView selectedRowIndexes];
            NSUInteger minSelected, maxSelected;
            if([selectedIndexes firstIndex] < [selectedIndexes lastIndex])
            {
                minSelected = [selectedIndexes firstIndex];
                maxSelected = [selectedIndexes lastIndex];
            }else{
                minSelected = [selectedIndexes lastIndex];
                maxSelected = [selectedIndexes firstIndex]; 
            }
            
            selectedRow = [[[self signalTableViewOrdering] objectAtIndex:minSelected] intValue];
            signalInfo = [[self workingSimulation] detailsOfSignalAtIndex:selectedRow];
            startDateTime = [[signalInfo objectForKey:@"ENTRYTIME"] longValue];
            endDateTime = [[signalInfo objectForKey:@"EXITTIME"] longValue];
            
            for(NSUInteger iRow = minSelected + 1; iRow <= maxSelected; iRow++){
                selectedRow = [[[self signalTableViewOrdering] objectAtIndex:iRow] intValue];
                signalInfo = [[self workingSimulation] detailsOfSignalAtIndex:selectedRow];
                startDateTime = MIN(startDateTime,[[signalInfo objectForKey:@"ENTRYTIME"] longValue]);
                
                endDateTime = MAX(endDateTime,[[signalInfo objectForKey:@"EXITTIME"] longValue]);
                
                //            selectedRow = [[[self signalTableViewOrdering] objectAtIndex:maxSelected] intValue];
                //            signalInfo = [[self workingSimulation] detailsOfSignalAtIndex:selectedRow];
                //            endDateTime = [[signalInfo objectForKey:@"EXITTIME"] longValue] + 2*tradingLag;
                
            }
            startDateTime = startDateTime - ([signalAnalysisPlotLeadHours intValue] * 60*60);
            endDateTime = endDateTime + 2*tradingLag;
        }else{
            selectedRow = [[[self signalTableViewOrdering] objectAtIndex:selectedRow] intValue];
            signalInfo = [[self workingSimulation] detailsOfSignalAtIndex:selectedRow];
            startDateTime = [[signalInfo objectForKey:@"ENTRYTIME"] longValue];
            startDateTime = startDateTime - ([signalAnalysisPlotLeadHours intValue] * 60*60);
            endDateTime = [[signalInfo objectForKey:@"EXITTIME"] longValue] + 2*tradingLag;
        }
        if(startDateTime >= endDateTime){
            NSLog(@"Error making signal plot, start time is after end time");
        }
        //[self plotSignalDataFrom:startDateTime To:endDateTime];
        [[self signalPlotInfo] setDataViewWithStartDateTime:startDateTime
                                             AndEndDateTime:endDateTime
                                                     AsZoom:NO];
        [self updateSimulationSignalSelectedTimeSeries];
        [[self signalAnalysisPlot] updateLines:[self signalPlotInfo]];
    }
}

-(void)updateStatus:(NSString *) statusMessage
{
    [performSimulationStatusLabel setHidden:NO];
    [performSimulationStatusLabel setStringValue:statusMessage];
}

-(void) progressAsFraction:(NSNumber *) progressValue
{
    [currentProgressIndicator setDoubleValue:[progressValue doubleValue]];
}

-(void) progressBarOn
{
    [currentProgressIndicator setMinValue:0.0];
    [currentProgressIndicator setMaxValue:1.0];
    [currentProgressIndicator setDoubleValue:0.1];
    [currentProgressIndicator startAnimation:nil];
    [currentProgressIndicator setHidden:NO];
}

-(void) progressBarOff
{
    [currentProgressIndicator stopAnimation:nil];
    [currentProgressIndicator setHidden:YES];
}

-(void) prepareForSimulationReport
{
    for(int i =0; i < [[self hideObjectsOnStartup] count];i++){
        [[[self hideObjectsOnStartup] objectAtIndex:i] setHidden:NO];
    }
    if([centreTabView numberOfTabViewItems] == 1){
        [centreTabView addTabViewItem:plotTab];
        [centreTabView addTabViewItem:dataTab];
        [centreTabView addTabViewItem:reportTab];
        [centreTabView addTabViewItem:signalsTab];
        [centreTabView addTabViewItem:compareTab];
    }
    [simulationRunScrollView setFrame:CGRectMake(18.0f, 59.0f, 650.0f, 306.0f)];
}

-(void)showAlertPanelWithInfo: (NSDictionary *) alertInfo
{
    if([[self delegate] respondsToSelector:@selector(showAlertPanelWithInfo:)])
    {
        [[self delegate] showAlertPanelWithInfo:alertInfo];
    }else{
        NSLog(@"Delegate not responding to \'showAlertPanelWithInfo\'"); 
    } 
}

-(void) registerSimulation: (Simulation *) sim
{
    [[self allSimulations] addObject:sim];
    [registeredSimsTableView1 reloadData];
    [registeredSimsTableView2 reloadData];
    [registeredSimsTableView3 reloadData];
    [registeredSimsTableView reloadData];
    [registeredSimsTableView5 reloadData];
    [[self simulationCompareOtherSimTableView] reloadData];
    
    NSIndexSet *indexSet = [NSIndexSet indexSetWithIndex:[[self allSimulations] count]-1];
    [registeredSimsTableView1 selectRowIndexes:indexSet byExtendingSelection:NO];
    [registeredSimsTableView2 selectRowIndexes:indexSet byExtendingSelection:NO];
    [registeredSimsTableView3 selectRowIndexes:indexSet byExtendingSelection:NO];
    [registeredSimsTableView selectRowIndexes:indexSet byExtendingSelection:NO];
    [registeredSimsTableView5 selectRowIndexes:indexSet byExtendingSelection:NO];
    [[self simulationCompareOtherSimTableView] selectRowIndexes:indexSet byExtendingSelection:NO];
    
    [removeSimulationButton setEnabled:YES];
    [exportSimulationButton setEnabled:YES];
    }

- (void) displayWorkingSim
{
    [self prepareForSimulationReport];
    [self addSimulationDataToResultsTableView];
    [self plotSimulationData];
    [self addSimInfoToAboutPanel];
    [self initialiseSignalTableView];
    [self setupResultsReport];
    [self prepareSimCompareSheet];
    [self leftPanelTopMessage:[[self workingSimulation] name]];
}

-(void)fillSetupSheet:(NSDictionary *) parameters
{
    NSString *simName = [parameters objectForKey:@"SIMNAME"];
    NSString *baseCode = [parameters objectForKey:@"BASECODE"];
    NSString *quoteCode = [parameters objectForKey:@"QUOTECODE"];
    NSString *accCode = [parameters objectForKey:@"ACCOUNTCODE"];
    long startDateTime = [[parameters objectForKey:@"STARTTIME"] longValue];
    long endDateTime = [[parameters objectForKey:@"ENDTIME"] longValue];
    int maxLeverage = (int)[[parameters objectForKey:@"MAXLEVERAGE"] doubleValue];
    double startingBalance = [[parameters objectForKey:@"STARTBALANCE"] doubleValue];
    long initialDataBeforeStart = [[parameters objectForKey:@"WARMUPDATA"] longValue];
    int timeStep = [[parameters objectForKey:@"TIMESTEP"] intValue];
    int tradingLag = [[parameters objectForKey:@"TRADINGLAG"] intValue];
    NSString *simDescription = [parameters objectForKey:@"SIMTYPE"];
    NSString *positioningString = [parameters objectForKey:@"POSTYPE"];
    NSString *rulesString = [parameters objectForKey:@"RULES"];
    long tradingDayStart = [[parameters objectForKey:@"TRADINGDAYSTART"] longValue];
    long tradingDayEnd = [[parameters objectForKey:@"TRADINGDAYEND"] longValue];
    BOOL weekendTrading =   [[parameters objectForKey:@"WEEKENDTRADING"] boolValue];
    
    NSArray *simulationDescriptionComponents = [simDescription componentsSeparatedByString:@";"];
    NSString *simType, *extraSeries;
    if([simulationDescriptionComponents count] > 1){
       simType = [simulationDescriptionComponents objectAtIndex:0];
        extraSeries = [simDescription substringFromIndex:[simType length]+1];
        
        [setupExtraSeriesTextField setStringValue:extraSeries];
    }else{
        simType = simDescription;
    }
    
    
    NSString *tradingPair = [NSString stringWithFormat:@"%@%@",baseCode,quoteCode];
    
    [setupSimulationName setStringValue:simName];
    [setupTradingPairPopup selectItem:[setupTradingPairPopup itemWithTitle:tradingPair]];
    double pipsize = [[self dataControllerForUI] getPipsizeForSeriesName:tradingPair] ;
    [setupTradingPairPipSizeLabel setStringValue:[NSString stringWithFormat:@"%6.4f",pipsize]];
    [setupAccountCurrencyPopup removeAllItems];
    [setupAccountCurrencyPopup addItemWithTitle:baseCode];
    [setupAccountCurrencyPopup addItemWithTitle:quoteCode];
    [setupAccountCurrencyPopup selectItem:[setupAccountCurrencyPopup itemWithTitle:accCode]];
    [setupStartTimePicker setDateValue:[NSDate dateWithTimeIntervalSince1970:startDateTime] ];
    [setupEndTimePicker setDateValue:[NSDate dateWithTimeIntervalSince1970:endDateTime]];
    
    
    
    [setupAccountCurrencyLabel setStringValue:accCode];
    [setupMaxLeverageTextField setStringValue:[NSString stringWithFormat:@"%d",maxLeverage]];
    [setupAccountBalanceTextField setStringValue:[NSString stringWithFormat:@"%5.2f",startingBalance]];
    [setupTradingStartTimePicker setDateValue:[NSDate dateWithTimeIntervalSince1970:tradingDayStart]];
    [setupTradingEndTimePicker setDateValue:[NSDate dateWithTimeIntervalSince1970:tradingDayEnd]];
    [setupDataWarmUpTextField setStringValue:[NSString stringWithFormat:@"%ld",initialDataBeforeStart/DAY_SECONDS]];
    [setupSamplingMinutesTextField setStringValue:[NSString stringWithFormat:@"%d",timeStep/60]];
    [setupTradingLagTextField setStringValue:[NSString stringWithFormat:@"%d",tradingLag/60]];
    [setupParameterTextField setStringValue:simType];
    [setupPositioningTextField setStringValue:positioningString];
    [setupRulesTextField setStringValue:rulesString];
    
    if(weekendTrading){
        [setupTradingWeekendYesNo setState:NSOnState];
    }else{
        [setupTradingWeekendYesNo setState:NSOffState];
    }
}

- (void) updateSimulationSelectedTimeSeries
{
    [[self simulationSelectedTimeSeries] removeAllObjects];
    TimeSeriesLine *tsl, *newTsl;
    NSString *lineName;
    
    for(int i = 0; i < [[self simulationTimeSeries] count]; i++){
        tsl = [[self simulationTimeSeries] objectAtIndex:i];
        if([tsl layerIndex] > -1){
            newTsl = [[TimeSeriesLine alloc] initWithLayerIndex:[tsl layerIndex]
                                                        AndName:[tsl name]
                                                      AndColour:[tsl colour]
                                                       AndSimId:0];
            lineName = [NSString stringWithFormat:@"S%ld_L%d_%@",[tsl simId],[tsl layerIndex],[tsl name]];
            [[self simulationSelectedTimeSeries] setObject:newTsl forKey:lineName];
        }
    }
}

- (void) updateSimulationSignalSelectedTimeSeries
{
    [[self simulationSignalSelectedTimeSeries] removeAllObjects];
    TimeSeriesLine *tsl, *newTsl;
    NSString *lineName;
    
    for(int i = 0; i < [[self simulationSignalTimeSeries] count]; i++){
        tsl = [[self simulationSignalTimeSeries] objectAtIndex:i];
        if([tsl layerIndex] > -1){
            newTsl = [[TimeSeriesLine alloc] initWithLayerIndex:[tsl layerIndex]
                                                        AndName:[tsl name]
                                                      AndColour:[tsl colour]
                                                       AndSimId:0];
            lineName = [NSString stringWithFormat:@"S%ld_L%d_%@",[tsl simId],[tsl layerIndex],[tsl name]];
            [[self simulationSignalSelectedTimeSeries] setObject:newTsl forKey:lineName];
        }
    }
}


- (void) updateSelectedSimCompareTimeseries
{
    [[self simulationCompareSelectedTimeSeries] removeAllObjects];
    TimeSeriesLine *tsl, *newTsl;
    NSString *lineName;
    
    for(int i = 0; i < [[self simulationCompareSimATimeSeries] count]; i++){
        tsl = [[self simulationCompareSimATimeSeries] objectAtIndex:i];
        if([tsl layerIndex] > -1){
            newTsl = [[TimeSeriesLine alloc] initWithLayerIndex:[tsl layerIndex]
                                                        AndName:[tsl name]
                                                      AndColour:[tsl colour]
                                                       AndSimId:0];
            lineName = [NSString stringWithFormat:@"S%ld_L%d_%@",[tsl simId],[tsl layerIndex],[tsl name]];
            [[self simulationCompareSelectedTimeSeries] setObject:newTsl forKey:lineName];
        }
    }
    for(int i = 0; i < [[self simulationCompareSimBTimeSeries] count]; i++){
        tsl = [[self simulationCompareSimBTimeSeries] objectAtIndex:i];
        if([tsl layerIndex] > -1){
            newTsl = [[TimeSeriesLine alloc] initWithLayerIndex:[tsl layerIndex]
                                                        AndName:[tsl name]
                                                      AndColour:[tsl colour]
                                                       AndSimId:1];
            lineName = [NSString stringWithFormat:@"S%ld_L%d_%@",[tsl simId],[tsl layerIndex],[tsl name]];
            [[self simulationCompareSelectedTimeSeries] setObject:newTsl forKey:lineName];
        }
    }
}

#pragma mark -
#pragma mark IBActions Methods

- (IBAction)plotLeftSideContract:(id)sender {
    NSString *senderIdentifer = [sender identifier];
    if (([[NSApp currentEvent] modifierFlags] & NSAlternateKeyMask) != 0){
        if([[senderIdentifer substringToIndex:7] isEqualToString:@"BIGPLOT"]){
            [[self simulationResultsPlot] rightSideExpand];
        }
        if([[senderIdentifer substringToIndex:7] isEqualToString:@"SIGPLOT"]){
            [[self signalAnalysisPlot] rightSideExpand];
        }
        if([[senderIdentifer substringToIndex:7] isEqualToString:@"COMPLOT"]){
            [[self simulationComparePlot] rightSideExpand];
        }
    }else{
        if([[senderIdentifer substringToIndex:7] isEqualToString:@"BIGPLOT"]){
            [[self simulationResultsPlot] leftSideContract];
        }
        if([[senderIdentifer substringToIndex:7] isEqualToString:@"SIGPLOT"]){
            [[self signalAnalysisPlot] leftSideContract];
        }
        if([[senderIdentifer substringToIndex:7] isEqualToString:@"COMPLOT"]){
            [[self simulationComparePlot] leftSideContract];
        }
    }
 
}

- (IBAction)plotLeftSideExpand:(id)sender {
    NSString *senderIdentifer = [sender identifier];
    if (([[NSApp currentEvent] modifierFlags] & NSAlternateKeyMask) != 0){
        if([[senderIdentifer substringToIndex:7] isEqualToString:@"BIGPLOT"]){
            [[self simulationResultsPlot] rightSideContract];
        }
        if([[senderIdentifer substringToIndex:7] isEqualToString:@"SIGPLOT"]){
            [[self signalAnalysisPlot] rightSideContract];
        }
        if([[senderIdentifer substringToIndex:7] isEqualToString:@"COMPLOT"]){
            [[self simulationComparePlot] rightSideContract];
        }
    }else{
        if([[senderIdentifer substringToIndex:7] isEqualToString:@"BIGPLOT"]){
            [[self simulationResultsPlot] leftSideExpand];
        }
        if([[senderIdentifer substringToIndex:7] isEqualToString:@"SIGPLOT"]){
            [[self signalAnalysisPlot] leftSideExpand];
        }
        if([[senderIdentifer substringToIndex:7] isEqualToString:@"COMPLOT"]){
            [[self simulationComparePlot] leftSideExpand];
        }
    }
}

- (IBAction)plotBottomExpand:(id)sender {
    NSString *senderIdentifer = [sender identifier];
    if (([[NSApp currentEvent] modifierFlags] & NSAlternateKeyMask) != 0){
        // do alternate action
        if([[senderIdentifer substringToIndex:7] isEqualToString:@"BIGPLOT"]){
            [[self simulationResultsPlot] topContract];
        }
        if([[senderIdentifer substringToIndex:7] isEqualToString:@"SIGPLOT"]){
            [[self signalAnalysisPlot] topContract];
        }
        if([[senderIdentifer substringToIndex:7] isEqualToString:@"COMPLOT"]){
            [[self simulationComparePlot] topContract];
        }
    }else{
            // do normal action
        if([[senderIdentifer substringToIndex:7] isEqualToString:@"BIGPLOT"]){
            [[self simulationResultsPlot] bottomExpand];
        }
        if([[senderIdentifer substringToIndex:7] isEqualToString:@"SIGPLOT"]){
            [[self signalAnalysisPlot] bottomExpand];
        }
        if([[senderIdentifer substringToIndex:7] isEqualToString:@"COMPLOT"]){
            [[self simulationComparePlot] bottomExpand];
        }
    }
}

- (IBAction)plotBottomContract:(id)sender {
    NSString *senderIdentifer = [sender identifier];
    if (([[NSApp currentEvent] modifierFlags] & NSAlternateKeyMask) != 0){
        if([[senderIdentifer substringToIndex:7] isEqualToString:@"BIGPLOT"]){
            [[self simulationResultsPlot] topExpand];
        }
        if([[senderIdentifer substringToIndex:7] isEqualToString:@"SIGPLOT"]){
            [[self signalAnalysisPlot] topExpand];
        }
        if([[senderIdentifer substringToIndex:7] isEqualToString:@"COMPLOT"]){
            [[self simulationComparePlot] topExpand];
        }
    }else{
        if([[senderIdentifer substringToIndex:7] isEqualToString:@"BIGPLOT"]){
            [[self simulationResultsPlot] bottomContract];
        }
        if([[senderIdentifer substringToIndex:7] isEqualToString:@"SIGPLOT"]){
            [[self signalAnalysisPlot] bottomContract];
        }
        if([[senderIdentifer substringToIndex:7] isEqualToString:@"COMPLOT"]){
            [[self simulationComparePlot] bottomContract];
        }

    }
}

- (IBAction)exportData:(id)sender {
    // Create a File Save Dialog class.
    BOOL allOk;
    NSString *suggestedFileName;
    NSSavePanel *saveDlg = [NSSavePanel savePanel];
    suggestedFileName = [NSString stringWithFormat:@"%@dataTS",[[self workingSimulation]  name]];
    [saveDlg setNameFieldStringValue:suggestedFileName];                     
    // Set array of file types
    NSArray *fileTypesArray;
    fileTypesArray = [NSArray arrayWithObjects:@"csv", nil];

    // Enable options in the dialog.
    //[saveDlg setCanChooseFiles:YES];
    [saveDlg setAllowedFileTypes:fileTypesArray];
    //[saveDlg setAllowsMultipleSelection:NO];

    // Display the dialog box.  If the OK pressed,
    // process the files.
 
    if ( [saveDlg runModal] == NSOKButton ) {
        // Gets list of all files selected
        NSURL *fileToSaveTo = [saveDlg URL];
        allOk = [[self simulationController] exportWorkingSimulation: [self workingSimulation]
                                                          DataToFile: fileToSaveTo];
        if(!allOk){
            [self updateStatus:@"Problem trying to write data to file"]; 
        }
    }
}

- (IBAction)exportTrades:(id)sender {
    // Create a File Save Dialog class.
    BOOL allOk;
    NSString *suggestedFileName;
    NSSavePanel *saveDlg = [NSSavePanel savePanel];
    suggestedFileName = [NSString stringWithFormat:@"%@trades",[[self workingSimulation] name]];
    [saveDlg setNameFieldStringValue:suggestedFileName]; 
    // Set array of file types
    NSArray *fileTypesArray;
    fileTypesArray = [NSArray arrayWithObjects:@"csv", nil];
    
    // Enable options in the dialog.
    //[saveDlg setCanChooseFiles:YES];
    [saveDlg setAllowedFileTypes:fileTypesArray];
    //[saveDlg setAllowsMultipleSelection:NO];
    
    // Display the dialog box.  If the OK pressed,
    // process the files.
    
    if ( [saveDlg runModal] == NSOKButton ) {
        // Gets list of all files selected
        NSURL *fileToSaveTo = [saveDlg URL];
        allOk = [[self simulationController] exportWorkingSimulationTrades: [self workingSimulation]
                                                                    ToFile:fileToSaveTo];
        if(!allOk){
            [self updateStatus:@"Problem trying to write data to file"];
        }
    }
}

- (IBAction)exportBalanceAdjustments:(id)sender {
    // Create a File Save Dialog class.
    BOOL allOk;
    NSString *suggestedFileName;
    NSSavePanel *saveDlg = [NSSavePanel savePanel];
    suggestedFileName = [NSString stringWithFormat:@"%@balAdjs",[[self workingSimulation] name]];
    [saveDlg setNameFieldStringValue:suggestedFileName]; 
    
    // Set array of file types
    NSArray *fileTypesArray;
    fileTypesArray = [NSArray arrayWithObjects:@"csv", nil];
    
    // Enable options in the dialog.
    //[saveDlg setCanChooseFiles:YES];
    [saveDlg setAllowedFileTypes:fileTypesArray];
    //[saveDlg setAllowsMultipleSelection:NO];
    
    // Display the dialog box.  If the OK pressed,
    // process the files.
    
    if ( [saveDlg runModal] == NSOKButton ) {
        // Gets list of all files selected
        NSURL *fileToSaveTo = [saveDlg URL];
        allOk = [[self simulationController] exportWorkingSimulationBalAdjmts: [self workingSimulation]
                                                                       ToFile: fileToSaveTo];
        if(!allOk){
            [self updateStatus:@"Problem trying to write data to file"];
        }
    }

}

- (IBAction)setupStartTimeChange:(id)sender {
    [startDateDoWLabel setStringValue:[[setupStartTimePicker dateValue] descriptionWithCalendarFormat:@"%a" timeZone:[NSTimeZone timeZoneWithName:@"GMT"] locale:nil]]; 
}

- (IBAction)setupEndTimeChange:(id)sender {
    [endDateDoWLabel setStringValue:[[setupEndTimePicker dateValue] descriptionWithCalendarFormat:@"%a" timeZone:[NSTimeZone timeZoneWithName:@"GMT"] locale:nil]]; 
}


- (IBAction)makeSimulationReport:(id)sender {
    // Create a File Open Dialog class.
    BOOL allOk;
    NSString *suggestedFileName;
    NSSavePanel *saveDlg = [NSSavePanel savePanel];
    suggestedFileName = [NSString stringWithFormat:@"%@report",[[self workingSimulation] name]];
    [saveDlg setNameFieldStringValue:suggestedFileName]; 
    // Set array of file types
    NSArray *fileTypesArray;
    fileTypesArray = [NSArray arrayWithObjects:@"csv", nil];
    
    // Enable options in the dialog.
    //[saveDlg setCanChooseFiles:YES];
    [saveDlg setAllowedFileTypes:fileTypesArray];
    //[saveDlg setAllowsMultipleSelection:NO];
    
    // Display the dialog box.  If the OK pressed,
    // process the files.
    
    if ( [saveDlg runModal] == NSOKButton ) {
        // Gets list of all files selected
        NSURL *fileToSaveTo = [saveDlg URL];
        allOk = [[self simulationController] exportWorkingSimulationReport: [self workingSimulation]
                                                                    ToFile:fileToSaveTo];
        if(!allOk){
            [self updateStatus:@"Problem trying to write data to file"];
        }
    }
}

- (IBAction)zoomButtonPress:(id)sender {
    long zoomStartDateTime, zoomEndDateTime;
    zoomStartDateTime = [[zoomFromDatePicker dateValue] timeIntervalSince1970];
    zoomEndDateTime = [[zoomToDatePicker dateValue] timeIntervalSince1970];
    
    [[self simulationPlotInfo] setDataViewWithStartDateTime:zoomStartDateTime
                                             AndEndDateTime:zoomEndDateTime
                                                     AsZoom:YES];
    [[self simulationResultsPlot] updateLines:[self simulationPlotInfo]];
}

- (IBAction)simCompareDateRangeButtonPress:(id)sender {
    if([self comparePlotInfo]){
        long minDataTime = [[[self simulationCompareFromDatePicker] dateValue] timeIntervalSince1970];
        long maxDateTime = [[[self simulationCompareToDatePicker] dateValue] timeIntervalSince1970];
        
        [[self comparePlotInfo] setDataViewWithStartDateTime: minDataTime
                                              AndEndDateTime: maxDateTime
                                                      AsZoom:YES];
    }
     [[self simulationComparePlot] updateLines:[self comparePlotInfo]];
}

- (IBAction)accountCurrencyChange:(id)sender {
    [setupAccountCurrencyLabel setStringValue:[[setupAccountCurrencyPopup selectedItem] title]];
}

- (IBAction)importCsvData:(id)sender {
    NSArray *importedData;
    NSArray *fileTypesArray;
    
    if([[setupSheetImportDataButton title] isEqualToString:@"Import Data"]){
        fileTypesArray = [NSArray arrayWithObjects:@"csv", nil];
        NSOpenPanel *openDlg = [NSOpenPanel openPanel];
        NSURL *fileToRead;
        [openDlg setAllowsMultipleSelection:NO];
        [openDlg setAllowedFileTypes:fileTypesArray];
        if ([openDlg runModal] == NSOKButton)
        {
            fileToRead =  [openDlg URL];
            importedData = [self csvDataFromURL:fileToRead];
        }
        if(importedData != nil){
            if([importedData count] > 0){
                [self setImportDataArray:importedData];
                [self setImportDataFilename:[fileToRead absoluteString]];
                [setupSheetImportDataScrollView setHidden:NO];
                NSArray *tableColumns;
                tableColumns = [setupSheetImportDataTableView tableColumns];
            //int numberOfColumns = [tableColumns count];
                while([tableColumns count] > 0)
                {
                    [setupSheetImportDataTableView removeTableColumn:[tableColumns objectAtIndex:0]];
                    tableColumns = [setupSheetImportDataTableView tableColumns];
                }
                NSTableColumn *newTableColumn;
                NSCell *newColumnCell;
               // int tableViewWidth = 0;
                NSArray *dataRow = [[self importDataArray] objectAtIndex:0];
                for(int i = 0; i < [dataRow count]; i++){
                    newTableColumn = [[NSTableColumn alloc] initWithIdentifier:[NSString stringWithFormat:@"Col%d",i]];
                    [[newTableColumn headerCell] setStringValue:[dataRow objectAtIndex:i]];
                    if(i ==0){
                        [newTableColumn setWidth:150];
                    }else{
                        NSUInteger width;
                        width = MAX(50, (280-150)/([dataRow count]-1));
                        [newTableColumn setWidth:width];
                    }
                //    tableViewWidth = tableViewWidth + [newTableColumn width];
                    newColumnCell = [newTableColumn dataCell];
                    if(i == 0){
                        [newColumnCell setAlignment:NSLeftTextAlignment];
                    }else{
                        [newColumnCell setAlignment:NSRightTextAlignment];
                    }
                    [setupSheetImportDataTableView addTableColumn:newTableColumn];
                }
                [setupSheetImportDataTableView widthAdjustLimit];
                [setupSheetImportDataTableView reloadData];
                [setupSheetImportDataButton setTitle:@"Remove Data"];
            }else{
                [self setImportDataArray:Nil];
                [self setImportDataFilename:Nil];
                [setupSheetImportDataScrollView setHidden:YES];
                [setupSheetImportDataButton setTitle:@"Import Data"];
            }
        }else{
            [self setImportDataArray:Nil];
            [self setImportDataFilename:Nil];
            [setupSheetImportDataScrollView setHidden:YES];
            [setupSheetImportDataButton setTitle:@"Import Data"];
        }
    }else{
        [self setImportDataArray:Nil];
        [self setImportDataFilename:Nil];
        [setupSheetImportDataScrollView setHidden:YES];
        [setupSheetImportDataButton setTitle:@"Import Data"];
    }
}

- (IBAction)signalAnalysisPlotReload:(id)sender {
    [self makeSignalAnalysisPlot];
}

- (IBAction)signalAnalysisPlotFullScreen:(id)sender {
    [self addPlotToFullScreenWindow:simulationSignalGraphHostingView];
}

- (IBAction)simPlotFullScreen:(id)sender {
    
    [self addPlotToFullScreenWindow:simulationResultGraphHostingView];
}

- (IBAction)comparePlotFullScreen:(id)sender {
       [self addPlotToFullScreenWindow:[self simulationCompareGraphHostingView]];
}

- (IBAction)saveWorkingSimulation:(id)sender {
    BOOL allOk;
    NSString *suggestedFileName;
    NSSavePanel *saveDlg = [NSSavePanel savePanel];
    suggestedFileName = [NSString stringWithFormat:@"%@report",[[self workingSimulation] name]];
    [saveDlg setNameFieldStringValue:suggestedFileName]; 
    // Set array of file types
    NSArray *fileTypesArray;
    fileTypesArray = [NSArray arrayWithObjects:@"sss", nil];
    
    // Enable options in the dialog.
    [saveDlg setAllowedFileTypes:fileTypesArray];
    
    // Display the dialog box.  If the OK pressed,
    // process the files.
    if ( [saveDlg runModal] == NSOKButton ) {
        NSData *encodedObject = [NSKeyedArchiver archivedDataWithRootObject:[self workingSimulation]];
        //simulation = [NSKeyedUnarchiver unarchiveObjectWithData:encodedObject];
        
        NSURL *fileToSaveTo = [saveDlg URL];
        allOk = [encodedObject writeToURL:fileToSaveTo atomically:YES];
       
        if(!allOk){
            [self updateStatus:@"Problem trying to write data to file"];
        }
    }
}

- (IBAction) importSimulation:(id)sender {
    NSData *importedData;
    NSArray *fileTypesArray;
    Simulation *importedSimulation;
    
    fileTypesArray = [NSArray arrayWithObjects:@"sss", nil];
    NSOpenPanel *openDlg = [NSOpenPanel openPanel];
    NSURL *fileToRead;
    [openDlg setAllowsMultipleSelection:NO];
    [openDlg setAllowedFileTypes:fileTypesArray];
    if ([openDlg runModal] == NSOKButton)
    {
        fileToRead =  [openDlg URL];
        importedData = [NSData  dataWithContentsOfURL:fileToRead]; 
        importedSimulation =  [NSKeyedUnarchiver unarchiveObjectWithData:importedData];
        [self registerSimulation:importedSimulation]; 
    }
}

- (IBAction) removeWorkingSimulation:(id)sender {
    NSMutableArray *allSims = [self allSimulations];
    
    if([allSims count] == 1){
         NSRunAlertPanel(@"Action failed!", @"Can't remove last simulation", @"OK", nil, nil);
    }else{
        if([allSims count] > 1)
        {
            [allSims removeObject:[self workingSimulation]];
        }
    
        if(([allSims count] > 0) && ([registeredSimsTableView selectedRow] > -1)){
            [removeSimulationButton setEnabled:YES];
            [exportSimulationButton setEnabled:YES];
        }else{
            [removeSimulationButton setEnabled:NO];
            [exportSimulationButton setEnabled:NO];
        }
        if([allSims count] > 0){
            [self setWorkingSimulation:[allSims objectAtIndex:0]];
        }
        
        if([self workingSimulation] != Nil)
        {
            [self displayWorkingSim];
        }
        [registeredSimsTableView reloadData];
        [registeredSimsTableView1 reloadData];
        [registeredSimsTableView2 reloadData];
        [registeredSimsTableView3 reloadData];
        [registeredSimsTableView5 reloadData];
        [self prepareSimCompareSheet];
    }
}

//- (IBAction)simulationCompareMakePlot:(id)sender {
//    
//    [self plotSimulationCompare];
//}

- (IBAction)simulationCompareChooseSimTimeSeries:(id)sender {
//    if([[[[self simulationCompareSimRadio] selectedCell] identifier] isEqualToString:@"SIMA"]){
//        [self setSimulationCompareSelectTimeSeries:[self simulationCompareSimATimeSeries]];
//        [[self simulationCompareTimeSeriesTableView] reloadData];
//    }
//    if([[[[self simulationCompareSimRadio] selectedCell] identifier] isEqualToString:@"SIMB"]){
//        if([self compareSimulationLoaded]){
//            [self setSimulationCompareSelectTimeSeries:[self simulationCompareSimBTimeSeries]];
//            [[self simulationCompareTimeSeriesTableView] reloadData];
//        }
//    }
    [[self simulationCompareTimeSeriesTableView] reloadData];
}

- (IBAction) changeSelectedTradingPair:(id)sender {
    NSString *selectedPair = [[setupTradingPairPopup selectedItem] title];
    [setupAccountCurrencyPopup removeAllItems];
    [setupAccountCurrencyPopup addItemWithTitle:[selectedPair substringFromIndex:3]];
    [setupAccountCurrencyPopup addItemWithTitle:[selectedPair substringToIndex:3]];
    [setupAccountCurrencyPopup selectItemAtIndex:0];
    [setupAccountCurrencyLabel setStringValue:[[setupAccountCurrencyPopup selectedItem] title]];
    double pipsize = [[self dataControllerForUI] getPipsizeForSeriesName:selectedPair] ;
    [setupTradingPairPipSizeLabel setStringValue:[NSString stringWithFormat:@"%6.4f",pipsize]];
}

- (IBAction)showSetupSheet:(id)sender
{
    //Not yet, this is to show cancel that the setup button has been pressed
    [self setDoingSetup: NO];
    [self setCancelProcedure: NO];
    [self disableSimulationBrowser];
    [setupSheetShowButton setEnabled: NO];
    
    
    [self disableMainButtons];
    [NSApp beginSheet:setupSheet modalForWindow:[centreTabView window] modalDelegate:nil didEndSelector:NULL contextInfo:NULL];
}

- (IBAction)cancelSetupSheet:(id)sender{
    [self setCancelProcedure:YES];
    if([self doingSetup] == NO){
        [self endSetupSheet];
    }
    [setupSheetShowButton setEnabled:YES];
    [importSimulationButton setHidden:NO];
    [removeSimulationButton setHidden:NO];
    [exportSimulationButton setHidden:NO];
    [registeredSimsScrollView1 setHidden:NO];
}

- (IBAction)cancelSimulation:(id)sender{
    NSString *userMessage = @"Trying to cancel...";
    if([self doThreads]){
        [self performSelectorOnMainThread:@selector(updateStatus:) withObject:userMessage waitUntilDone:NO];
        [[self simulationController] performSelectorInBackground:@selector(askSimulationToCancel) withObject:nil];

    }else{
        [[self simulationController] askSimulationToCancel];
    }
    [setUpSheetCancelButton setEnabled:NO];
}

- (IBAction)toggleLongShortIndicator:(id)sender {
    
    [[self simulationResultsPlot] togglePositionIndicator];
}

- (IBAction)sigPlotLongShortIndicatorToggle:(id)sender {
    [self setLongShortIndicatorOn:![self longShortIndicatorOn]];
    [[self signalAnalysisPlot] togglePositionIndicator];
}

- (IBAction)performSimulation:(id)sender {
    BOOL basicCheckOk = YES;
    NSString *userMessage;
    
    if([[sender window] makeFirstResponder:[sender window]]){
        //Try end editing this way
    }else{
        [[sender window] endEditingFor:nil];   
    }
    
    [performSimulationButton setEnabled:NO];
    [self clearSimulationMessage];
    for(int i =0; i < [[self hideObjectsOnStartup] count];i++){
        [[[self hideObjectsOnStartup] objectAtIndex:i] setHidden:YES];
    }

    [simulationRunScrollView setFrame:CGRectMake(18.0f, 59.0f, 650.0f, 417.0f)];
    
    NSMutableDictionary *parameters = [[NSMutableDictionary alloc] init]; 
    
    //setupSimulationName
    
    NSString *tradingPair;
    tradingPair = [[setupTradingPairPopup selectedItem] title];
    
    long startDateTime = [[setupStartTimePicker dateValue] timeIntervalSince1970];
    long endDateTime = [[setupEndTimePicker dateValue] timeIntervalSince1970];
    
    if(startDateTime > endDateTime){
        basicCheckOk = NO;
    }
    
    long tradingDayStartTime = [[setupTradingStartTimePicker dateValue] timeIntervalSince1970];
    long tradingDayEndTime = [[setupTradingEndTimePicker dateValue] timeIntervalSince1970];
    tradingDayStartTime = tradingDayStartTime - [EpochTime epochTimeAtZeroHour:tradingDayStartTime];
    tradingDayEndTime = tradingDayEndTime - [EpochTime epochTimeAtZeroHour:tradingDayEndTime];
    
    if(tradingDayEndTime == 0){
        tradingDayEndTime = DAY_SECONDS - 1;
    }
    
    if(tradingDayEndTime <= tradingDayStartTime){
        basicCheckOk = NO;
        userMessage = @"trading day start is after trading day end";
    }
    if(basicCheckOk)
    {
        if(tradingDayStartTime >= tradingDayEndTime){
            basicCheckOk = NO;
            userMessage = @"trading time start is after trading time end";
        }
    }
    
    NSString *simDescription = [[setupParameterTextField stringValue] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    NSString *extraSeriesString = [[setupExtraSeriesTextField stringValue] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    NSString *positioningString = [[setupPositioningTextField stringValue] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    NSString *rulesString = [[setupRulesTextField stringValue] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    
    if(![SimulationController positioningUnderstood:positioningString])
    {
        basicCheckOk = NO;
        userMessage = @"Positioning not understood";
    }
    if(![SimulationController simulationUnderstood:simDescription])
    {
        basicCheckOk = NO;
        userMessage = @"Signal not understood";
    }
    if(![SimulationController seriesUnderstood:extraSeriesString])
    {
        basicCheckOk = NO;
        userMessage = @"Extra Series not understood";
    }
    if([rulesString length] > 0){
        if(![SimulationController rulesUnderstood:rulesString])
        {
            basicCheckOk = NO;
            userMessage = @"Rules not understood";
        }
    }
    if([extraSeriesString length] > 0){
        simDescription = [NSString stringWithFormat:@"%@;%@",simDescription,extraSeriesString];
    }
    
    long tradingStartDateTime = [EpochTime epochTimeAtZeroHour:startDateTime] + tradingDayStartTime;
    long tradingEndDateTime = [EpochTime epochTimeAtZeroHour:endDateTime] + tradingDayEndTime;
    BOOL weekendTrading = [setupTradingWeekendYesNo state] == NSOnState;
    
    if(basicCheckOk)
    {
        [parameters setObject:[setupSimulationName stringValue] 
                       forKey:@"SIMNAME"];
        [parameters setObject:simDescription
                       forKey:@"SIMTYPE"];
        [parameters setObject:positioningString
                       forKey:@"POSTYPE"];
        [parameters setObject:rulesString 
                       forKey:@"RULES"];
        [parameters setObject:[tradingPair substringToIndex:3] 
                       forKey:@"BASECODE"];
        [parameters setObject:[tradingPair substringFromIndex:3] 
                       forKey:@"QUOTECODE"];
        [parameters setObject:[[setupAccountCurrencyPopup selectedItem] title] 
                       forKey:@"ACCOUNTCODE"];
        [parameters setObject:[NSNumber numberWithDouble:[setupAccountBalanceTextField doubleValue]] 
                       forKey:@"STARTBALANCE"];
        [parameters setObject:[NSNumber numberWithDouble:[setupMaxLeverageTextField doubleValue]] 
                       forKey:@"MAXLEVERAGE"];
        [parameters setObject:[NSNumber numberWithLong:tradingStartDateTime] 
                       forKey:@"STARTTIME"];
        [parameters setObject:[NSNumber numberWithLong:tradingEndDateTime] 
                       forKey:@"ENDTIME"];
        [parameters setObject:[NSNumber numberWithInt:[setupSamplingMinutesTextField intValue]*60] 
                       forKey:@"TIMESTEP"];
        [parameters setObject:[NSNumber numberWithLong:tradingDayStartTime]  
                       forKey:@"TRADINGDAYSTART"];
        [parameters setObject:[NSNumber numberWithLong:tradingDayEndTime] 
                       forKey:@"TRADINGDAYEND"];
        [parameters setObject:[NSNumber numberWithBool:weekendTrading] 
                       forKey:@"WEEKENDTRADING"]; 
        [parameters setObject:[NSNumber numberWithInt:[setupTradingLagTextField intValue]*60] 
                       forKey:@"TRADINGLAG"];
        [parameters setObject:[NSNumber numberWithLong:[setupDataWarmUpTextField intValue]*DAY_SECONDS] 
                       forKey:@"WARMUPDATA"];
        
        
        if([self importDataArray] == Nil){
            [parameters setObject:[NSNumber numberWithBool:NO] 
                           forKey:@"USERDATAGIVEN"];
        }else{
            [parameters setObject:[NSNumber numberWithBool:YES] 
                           forKey:@"USERDATAGIVEN"];
            [parameters setObject:[self importDataArray] 
                           forKey:@"USERDATA"];
            [parameters setObject:[self importDataFilename] 
                           forKey:@"USERDATAFILE"];
        }
    }
    
    if(basicCheckOk)
    {
        NSData *encodedObject = [NSKeyedArchiver archivedDataWithRootObject:parameters];
        //simulation = [NSKeyedUnarchiver unarchiveObjectWithData:encodedObject];
        
        NSURL *fileToSaveTo = [NSURL URLWithString:@"file://localhost/Users/Martin/Documents/params.ssp"];
        [encodedObject writeToURL:fileToSaveTo atomically:YES];
        
        [setUpSheetCancelButton setEnabled:YES];
    
        currentProgressIndicator = performSimulationProgressBar;
        if([self doThreads]){
            [[self simulationController] performSelectorInBackground:@selector(tradingSimulation:) withObject:parameters];
        }else{
            [[self simulationController] tradingSimulation:parameters];
        }
    
        [performSimulationButton setEnabled:YES];
        [self endSetupSheet];
    }else{
        NSRunAlertPanel(@"Bad Parameters", userMessage, @"OK", nil, nil);
        [performSimulationButton setEnabled:YES];
    }
    
}

- (void) disableSimulationBrowser
{
    [registeredSimsScrollView1 setHidden: YES];
    [importSimulationButton setHidden: YES];
    [removeSimulationButton setHidden: YES];
    [exportSimulationButton setHidden:YES];
}

#pragma mark -
#pragma mark TextField Methods

-(void)clearSimulationMessage
{
    NSMutableString *message;
    message = [[simulationMessagesTextView textStorage] mutableString];
    if([message length]>0)
    {
        [message deleteCharactersInRange:NSMakeRange(0, [message length]-1)];
    }
}

- (void)outputSimulationMessage:(NSString *) message
{
    [[[simulationMessagesTextView textStorage] mutableString] appendString:message];
    [simulationMessagesTextView scrollRangeToVisible:NSMakeRange([[simulationMessagesTextView textStorage] length], 0)];
    //[simulationRunScrollView scrollRectToVisible:NSRect
    //[[[simulationMessagesTextView textStorage] mutableString] appendString:@"\n"];
}

#pragma mark -
#pragma mark TableView Methods

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView{
    if([[tableView identifier] isEqualToString:@"SIMTSTV"]){
        return [[self simulationTimeSeries] count]; 
    }
    
    if([[tableView identifier] isEqualToString:@"SIMSELTSTV"]){
        int numberSelected = 0;
        for(TimeSeriesLine *tsl in [self simulationTimeSeries])
        {
            if([tsl layerIndex] != -1){
                numberSelected++;
            }
        }
        return numberSelected; 
    }
    
    if([[tableView identifier] isEqualToString:@"SIGSELTSTV"]){
        int numberSelected = 0;
        for(TimeSeriesLine *tsl in [self simulationSignalTimeSeries])
        {
            if([tsl layerIndex] != -1){
                numberSelected++;
            }
        }
        return numberSelected; 
    }
    
    
    if([[tableView identifier] isEqualToString:@"SIGTSTV"]){
        return [[self simulationSignalTimeSeries] count]; 
    } 
    
    if([[tableView identifier] isEqualToString:@"TRADESTV"]){
        return [[self workingSimulation] numberOfTrades]; 
    }
    
    if([[tableView identifier] isEqualToString:@"CASHTRANSTV"]){
        return [[self workingSimulation] numberOfBalanceAdjustments]; 
    }
    
    if([[tableView identifier] isEqualToString:@"SIMDATATV"]){
        return [[[self workingSimulation] analysisDataSeries] length]; 
    }
    
    if([[tableView identifier] isEqualToString:@"SIGANALTV"]){
        return [[self workingSimulation] numberOfSignals]; 
    }

    if([[tableView identifier] isEqualToString:@"SIMREPORTTV"])
    {
        return [[self workingSimulation] getNumberOfReportDataFields];
    }
    if([[tableView identifier] isEqualToString:@"IMPORTDATATV"])
    {
        if([self importDataArray] !=0){
            return [[self importDataArray] count]-1;
        }else{
            return 0;
        }
    }
    if([[tableView identifier] isEqualToString:@"COMPARESIMTV"]){
        return MAX(0,[[self allSimulations] count]-1);
    }
    
    if([[tableView identifier] isEqualToString:@"SIMCOMPARETSTV"]){
        if([[[[self simulationCompareSimRadio] selectedCell] identifier] isEqualToString:@"SIMA"]){
            return [[self simulationCompareSimATimeSeries] count];
        }else{
            if([self compareSimulationLoaded]){
                return [[self simulationCompareSimBTimeSeries] count];
            }
        }
    }
    
    if([[tableView identifier] length] >= 10){
        if([[[tableView identifier] substringToIndex:10] isEqualToString:@"SAVEDSIMTV"])
        {
            return [[self allSimulations] count];
        }
    }
    if([[tableView identifier] isEqualToString:@"COMPARESELECTEDTSTV"]){
       
        return [[self simulationCompareSelectedTimeSeries] count];
    }
    
    return 0;
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    TimeSeriesLine *tsl;
    NSString *columnId = [tableColumn identifier];
    
    if([[tableView identifier] isEqualToString:@"SIMTSTV"]){
        tsl = [[self simulationTimeSeries] objectAtIndex:row];
        if([columnId isEqualToString:@"plot0"]){
            return [NSNumber numberWithBool:[tsl layerIndex] == 0];
        }else if([columnId isEqualToString:@"plot1"]){
            return [NSNumber numberWithBool:[tsl layerIndex] == 1];
        }else if([columnId isEqualToString:@"plot2"]){  
            return [NSNumber numberWithBool:[tsl layerIndex] == 2];
        }else{
            return [tsl valueForKey:columnId];
        }
    }
    
    
    if([[tableView identifier] isEqualToString:@"SIMSELTSTV"]){
        int numberSelected = 0;
        for(int tslIndex = 0; tslIndex < [[self simulationTimeSeries] count]; tslIndex++)
        {
            tsl = [[self simulationTimeSeries] objectAtIndex:tslIndex];
            if([tsl layerIndex] != -1){
                if(numberSelected == row){
                    if([columnId isEqualToString:@"axis"]){
                        return [NSNumber numberWithInt:[tsl layerIndex]+1]; 
                    }else{
                        return [tsl valueForKey:columnId];
                    }
                }else{
                    numberSelected++;
                }
            }
            
        }
        return @"Err"; 
    }
    
    if([[tableView identifier] isEqualToString:@"SIGSELTSTV"]){
        int numberSelected = 0;
        for(int tslIndex = 0; tslIndex < [[self simulationSignalTimeSeries] count]; tslIndex++)
        {
            tsl = [[self simulationSignalTimeSeries] objectAtIndex:tslIndex];
            if([tsl layerIndex] != -1){
                if(numberSelected == row){
                    if([columnId isEqualToString:@"axis"])
                    {
                        return [NSNumber numberWithInt:[tsl layerIndex]];
                    }else{
                        return [tsl valueForKey:columnId];
                    }
                }else{
                    numberSelected++;
                }
            }
        }
        return @"Err"; 
    }
    
    if([[tableView identifier] isEqualToString:@"SIGTSTV"]){
        tsl = [[self simulationSignalTimeSeries] objectAtIndex:row];
        if([columnId isEqualToString:@"plot0"]){
            return [NSNumber numberWithBool:[tsl layerIndex] == 0];
        }else if([columnId isEqualToString:@"plot1"]){
            return [NSNumber numberWithBool:[tsl layerIndex] == 1];
        }else if([columnId isEqualToString:@"plot2"]){
            return [NSNumber numberWithBool:[tsl layerIndex] == 2];
        }else{
            return [tsl valueForKey:columnId];
        }
    }
    
    if([[tableView identifier] isEqualToString:@"TRADESTV"]){
        if([[tableColumn identifier] isEqualToString:@"DATETIME"])
        {
            return [EpochTime stringDateWithTime:[[self workingSimulation] getDateTimeForTradeAtIndex:row]];
        }
        if([[tableColumn identifier] isEqualToString:@"AMOUNT"])
        {
            return [NSString stringWithFormat:@"%d",[[self workingSimulation] getAmountForTradeAtIndex:row]];
        }
        if([[tableColumn identifier] isEqualToString:@"PRICE"])
        {
            return [NSString stringWithFormat:@"%5.3f",[[self workingSimulation] getPriceForTradeAtIndex:row]];
        }
        if([[tableColumn identifier] isEqualToString:@"ENDEXP"])
        {
            return [NSString stringWithFormat:@"%d",[[self workingSimulation] getResultingMarketExposureForTradeAtIndex:row]];
        }
    }
    
    if([[tableView identifier] isEqualToString:@"CASHTRANSTV"])
    {
        if([[tableColumn identifier] isEqualToString:@"DATETIME"])
        {
            return [EpochTime stringDateWithTime:[[self workingSimulation] getDateTimeForBalanceAdjustmentAtIndex:row]];
        }
        if([[tableColumn identifier] isEqualToString:@"AMOUNT"])
        {
            return [NSString stringWithFormat:@"%5.3f",[[self workingSimulation] getAmountForBalanceAdjustmentAtIndex:row]];
        }
        if([[tableColumn identifier] isEqualToString:@"REASON"])
        {
            return [[self workingSimulation] getReasonForBalanceAdjustmentAtIndex:row]; 
        }
        if([[tableColumn identifier] isEqualToString:@"ENDBALANCE"])
        {
            return [NSString stringWithFormat:@"%5.3f",[[self workingSimulation] getResultingBalanceForBalanceAdjustmentAtIndex:row]];
        }
    }
     
    if([[tableView identifier] isEqualToString:@"SIMDATATV"]){
        DataSeries* simData = [[self workingSimulation] analysisDataSeries];
        if([[tableColumn identifier] isEqualToString:@"DATETIME"]){
            long dateTimeNumber = [[[simData xData] sampleValue:row] longValue];
            //NSString *dateTime = [EpochTime stringDateWithTime:dateTimeNumber];
            NSString *dateTime = [NSString stringWithFormat:@"%ld",dateTimeNumber];
            return dateTime;
        }else{
            NSString *identiferString = [tableColumn identifier];
            if([identiferString isEqualToString:@"POS_PNL"] || [identiferString isEqualToString:@"NAV"] )
            {
                double dataValue = [[[[simData yData] objectForKey:identiferString] sampleValue:row] doubleValue];
                return [NSString stringWithFormat:@"%5.2f",dataValue];
            }else{
                return [[[simData yData] objectForKey:identiferString] sampleValue:row];
            }
        }
    }
    
    if([[tableView identifier] isEqualToString:@"SIGANALTV"])
    {
        int sortedIndex =  [[[self signalTableViewOrdering] objectAtIndex:row] intValue];
        NSDictionary *signalAnalysisDetails = [[self workingSimulation] detailsOfSignalAtIndex:sortedIndex];
        
        if([[tableColumn identifier] isEqualToString:@"SIGNAL"]){
            int signalSide =  [UtilityFunctions signOfDouble:[[signalAnalysisDetails objectForKey:@"SIGNAL"] doubleValue]];
            return [NSNumber numberWithFloat:signalSide];
        }
        if([[tableColumn identifier] isEqualToString:@"SIGNALGAIN"]){
           
            int signalSide = [UtilityFunctions signOfDouble:[[signalAnalysisDetails objectForKey:@"SIGNAL"] doubleValue]];
                          
            float priceChange = ([[signalAnalysisDetails objectForKey:@"EXITPRICE"] floatValue] - [[signalAnalysisDetails objectForKey:@"ENTRYPRICE"] floatValue]);
            return [NSNumber numberWithFloat:signalSide * priceChange];
        }
        
        if([[tableColumn identifier] isEqualToString:@"PNL"]){
             return [signalAnalysisDetails objectForKey:@"PNL"];
        }
        
        
        if([[tableColumn identifier] isEqualToString:@"ENTRYTIME"] || [[tableColumn identifier] isEqualToString:@"EXITTIME"]){
            long dateTime = [[signalAnalysisDetails objectForKey:[tableColumn identifier]] longValue];
            return [EpochTime stringDateWithTime:dateTime];
        }else{
            if([[tableColumn identifier] isEqualToString:@"UPTIME"]){
                float upTime = [[signalAnalysisDetails objectForKey:[tableColumn identifier]] floatValue];
                return [NSString stringWithFormat:@"%5.2f",upTime];
            }else{
                return [signalAnalysisDetails objectForKey:[tableColumn identifier]];
            }
        }
    }
    
    if([[tableView identifier] isEqualToString:@"SIMREPORTTV"])
    {
        id returnValue;
        if([[tableColumn identifier] isEqualToString:@"NAME"])
        {
             returnValue = [[self workingSimulation] getReportNameFieldAtIndex:row];
        }
        if([[tableColumn identifier] isEqualToString:@"DATA1"])
        {
            returnValue = [[self workingSimulation] getReportDataFieldAtIndex:row];
        }
//        if([returnValue isKindOfClass:[NSString class]]){
//            if([returnValue length] > 25){
//                NSString *truncated =    [returnValue substringWithRange:NSMakeRange([returnValue length]-37, 37)];
//                returnValue = [NSString stringWithFormat:@"...%@",truncated];
//            }
//        }
        return returnValue;
    }
    if([[tableView identifier] isEqualToString:@"IMPORTDATATV"])
    {
        if([self importDataArray] !=0){
            NSString *columnId = [tableColumn identifier];
            int columnNumber = [[columnId substringFromIndex:3] intValue];
            if(columnNumber == 0){
                long dateTime =  (long)[[[[self importDataArray] objectAtIndex:row+1] objectAtIndex:0] longLongValue];
                return [EpochTime stringDateWithTime:dateTime];
            }else{
                return [[[self importDataArray] objectAtIndex:row+1] objectAtIndex:columnNumber];
            }
        }else{
            return 0;
        }
    }
    
    if([[tableView identifier] isEqualToString:@"COMPARESIMTV"]){
        Simulation *sim;
        int index = 0, indexLessWorkingSim = -1;
        for(index = 0; index < [[self allSimulations] count]; index++){
            if(!([[self allSimulations] objectAtIndex:index]==[self workingSimulation] ))
               {
                   indexLessWorkingSim++;
               }
            if(indexLessWorkingSim==row){
                sim = [[self allSimulations] objectAtIndex:index];
                break;
            }
        }
        
        return [sim name];
    }
    
    if([[tableView identifier] isEqualToString:@"SIMCOMPARETSTV"]){
        NSArray *timeSeriesArray;
        if([[[[self simulationCompareSimRadio] selectedCell] identifier] isEqualToString:@"SIMA"]){
            timeSeriesArray = [self simulationCompareSimATimeSeries];
        }else{
            timeSeriesArray = [self simulationCompareSimBTimeSeries];
        }
        
        tsl = [timeSeriesArray objectAtIndex:row];
        if([columnId isEqualToString:@"plot0"]){
            return [NSNumber numberWithBool:[tsl layerIndex] == 0];
        }else if([columnId isEqualToString:@"plot1"]){
            return [NSNumber numberWithBool:[tsl layerIndex] == 1];
        }else if([columnId isEqualToString:@"plot2"]){
            return [NSNumber numberWithBool:[tsl layerIndex] == 2];
        }else{
            return [tsl valueForKey:columnId];
        }
    }
    
    if([[tableView identifier] isEqualToString:@"COMPARESELECTEDTSTV"]){
        int numberSelected = 0;
        NSArray *lineNames = [[self simulationCompareSelectedTimeSeries] allKeys];
        for(int tslIndex = 0; tslIndex < [[self simulationCompareSelectedTimeSeries] count]; tslIndex++)
        {
            tsl = [[self simulationCompareSelectedTimeSeries]  objectForKey:[lineNames objectAtIndex:tslIndex]];
            if([tsl layerIndex] != -1){
                if(numberSelected == row){
                    if([columnId isEqualToString:@"axis"])
                    {
                        return [NSNumber numberWithInt:[tsl layerIndex]];
                    }else if([columnId isEqualToString:@"name"]){
                        if([tsl simId]==0){
                            return [NSString stringWithFormat:@"A_%@",[tsl name]];
                        }else{
                            return [NSString stringWithFormat:@"B_%@",[tsl name]];
                        }
                    }else{
                        return [tsl valueForKey:columnId];
                    }
                }else{
                    numberSelected++;
                }
            }
        }
        return @"Err";
    }
    
    if([[tableView identifier] length] >= 10){
        if([[[tableView identifier] substringToIndex:10] isEqualToString:@"SAVEDSIMTV"])
        {
            Simulation *sim = [[self allSimulations] objectAtIndex:row];
            return [sim name];
        }
    }

    return nil;
}

- (void)tableView: (NSTableView *)tableView
   setObjectValue: (id) obj
   forTableColumn: (NSTableColumn *)tableColumn
              row: (NSInteger)row
{
    if([[tableView  identifier] length] >= 10){
        if([[[tableView  identifier] substringToIndex:10] isEqualToString:@"SAVEDSIMTV"]){
            
            if(row > -1 && [obj isKindOfClass:[NSString class]]){
                NSString *oldSimName, *newSimName;
                
                Simulation *selectedSim=[[self allSimulations] objectAtIndex:[registeredSimsTableView selectedRow]];
                oldSimName = [selectedSim name];
                newSimName = obj;
                
                if(![newSimName isEqualToString:oldSimName]){
                    [selectedSim setSimName:newSimName];
                    [self setWorkingSimulation:selectedSim];
                    [self displayWorkingSim];
                    NSMutableString *outputTextField = [[simulationMessagesTextView textStorage] mutableString];
                    [outputTextField deleteCharactersInRange:NSMakeRange(0, [outputTextField length])];
                    [outputTextField appendString:[[[selectedSim simulationRunOutput] string] mutableCopy]];
                    [simulationTradesTableView reloadData];
                    [simulationCashFlowsTableView reloadData];
                    
                }
            }
        }
    }
   
    TimeSeriesLine *tsl;
    //SeriesPlot *plot;
    
    if([[tableView identifier] isEqualToString:@"SIMTSTV"]){
        tsl = [[self simulationTimeSeries] objectAtIndex:row];
        //plot = [self simulationResultsPlot];
    }
    
    if([[tableView identifier] isEqualToString:@"SIGTSTV"]){
        tsl = [[self simulationSignalTimeSeries] objectAtIndex:row];
        //plot = [self signalAnalysisPlot];
    }
    
    if([[tableView identifier] isEqualToString:@"SIMCOMPARETSTV"]){
        if([[[[self simulationCompareSimRadio] selectedCell] identifier] isEqualToString:@"SIMA"])
        {
            tsl = [[self simulationCompareSimATimeSeries] objectAtIndex:row];
        }else{
            tsl = [[self simulationCompareSimBTimeSeries] objectAtIndex:row];
                   }
        //plot = [self simulationComparePlot];
    }
    
    if([[tableColumn identifier] isEqualToString:@"plot0"]){
        if([obj boolValue]){
            [tsl setLayerIndex:0];
        }else{
            [tsl setLayerIndex:-1];
        }
    }else if([[tableColumn identifier] isEqualToString:@"plot1"]){
        if([obj boolValue]){
            [tsl setLayerIndex:1];
        }else{
            [tsl setLayerIndex:-1];
        }
    }else if([[tableColumn identifier] isEqualToString:@"plot2"]){
        if([obj boolValue]){
            [tsl setLayerIndex:2];
        }else{
            [tsl setLayerIndex:-1];
        }
    }else {
        [tsl setValue:obj forKey:[tableColumn identifier]];
    }
    
    if([[tableView identifier] isEqualToString:@"SIMTSTV"]){
        [self updateSimulationSelectedTimeSeries];
        [[self simulationResultsPlot] updateLines:[self simulationPlotInfo]];
    }
    if([[tableView identifier] isEqualToString:@"SIGTSTV"]){
        [self updateSimulationSignalSelectedTimeSeries];
        [[self signalAnalysisPlot] updateLines:[self signalPlotInfo]];
    }
    if([[tableView identifier] isEqualToString:@"SIMCOMPARETSTV"]){
        [self updateSelectedSimCompareTimeseries];
        [[self simulationComparePlot] updateLines:[self comparePlotInfo]];
//    }else{
//        if([[tableColumn identifier] isEqualToString:@"colourId"]){
//            [plot updatePlotWithUpdateAxes:NO];
//        }else{
//            [plot updatePlotWithUpdateAxes:YES];
//        }
    }
    [tableView reloadData];
    
    //the tableview which shows the selected is set up
    if([[tableView identifier] isEqualToString:@"SIMTSTV"]){
        [simulationTimeSeriesSelectedTableView reloadData];
    }
    if([[tableView identifier] isEqualToString:@"SIGTSTV"]){
        [simulationSignalSelectedTimeSeriesTableView reloadData];
    }
    if([[tableView identifier] isEqualToString:@"SIMCOMPARETSTV"]){
        [[self simulationCompareSelectedTSTableView] reloadData];
    }
}

-(void)clearTSTableView:(NSTableView *)tableView
{
    BOOL found = NO;
    if([[tableView identifier] isEqualToString:@"SIMTSTV"]){
        [[self simulationTimeSeries] removeAllObjects];
        [simulationTimeSeriesTableView reloadData];
        [simulationTimeSeriesSelectedTableView reloadData];
        found = YES;
    }
    
    
    if([[tableView identifier] isEqualToString:@"SIMDATATV"]){
         [simulationTimeSeriesTableView reloadData];
        [simulationTimeSeriesSelectedTableView reloadData];
        found = YES;
    } 
    
    if([[tableView identifier] isEqualToString:@"SIGTSTV"]){
        [[self simulationSignalTimeSeries] removeAllObjects];
        [simulationSignalTimeSeriesTableView reloadData];
        [simulationSignalSelectedTimeSeriesTableView reloadData];
        found = YES;
    }
   
    
    if(!found){
        [NSException raise:@"clearTSTableView failure" format:@"Parameter %@ not handled",[tableView identifier]];
    }
}

-(void)addToTableView:(NSTableView *)tableView 
       TimeSeriesLine: (TimeSeriesLine *)tsl
{
   if([[tableView identifier] isEqualToString:@"SIMTSTV"]){
    [[self simulationTimeSeries] addObject:tsl];
       [simulationTimeSeriesSelectedTableView reloadData];
    }
    
    if([[tableView identifier] isEqualToString:@"SIGTSTV"]){
        [[self simulationSignalTimeSeries] addObject:tsl];
    }
    if([[tableView identifier] isEqualToString:@"SIMCOMPARETSTV"]){
        NSString *lineName = [NSString stringWithFormat:@"S%ld_L%d_%@",[tsl simId],[tsl layerIndex],[tsl name]];
        [[self simulationCompareSelectedTimeSeries] setObject:tsl forKey:lineName];
        [[self simulationCompareSelectedTSTableView] reloadData];
    }
    [tableView reloadData];
}

-(void)tableViewSelectionDidChange:(NSNotification *)notification
{
    if([[[notification object] identifier] isEqualToString:@"SIGANALTV"]){
        [self makeSignalAnalysisPlot];
    }
    
    if([[[notification object] identifier] length] >= 10){
        if([[[[notification object] identifier] substringToIndex:10] isEqualToString:@"SAVEDSIMTV"]){
            
            if([registeredSimsTableView selectedRow] > -1){
                
                Simulation *selectedSim=[[self allSimulations] objectAtIndex:[registeredSimsTableView selectedRow]];
                if(selectedSim != [self workingSimulation] && [notification object] == registeredSimsTableView){
                    [self setWorkingSimulation:selectedSim];
                    [self displayWorkingSim];
                    NSMutableString *outputTextField = [[simulationMessagesTextView textStorage] mutableString];
                    [outputTextField deleteCharactersInRange:NSMakeRange(0, [outputTextField length])];
                    [outputTextField appendString:[[[selectedSim simulationRunOutput] string] mutableCopy]];
                    [simulationTradesTableView reloadData];
                    [simulationCashFlowsTableView reloadData];
                }
            }
            NSInteger selectedRow = [[notification object] selectedRow];
            NSIndexSet *indexSet = [NSIndexSet indexSetWithIndex:selectedRow];
            
            if([notification object] != registeredSimsTableView1){
                [registeredSimsTableView1 selectRowIndexes:indexSet byExtendingSelection:NO];
            }
            if([notification object] != registeredSimsTableView2){
                [registeredSimsTableView2 selectRowIndexes:indexSet byExtendingSelection:NO];
            }
            if([notification object] != registeredSimsTableView3)
            {
                [registeredSimsTableView3 selectRowIndexes:indexSet byExtendingSelection:NO];
            }
            if([notification object] != registeredSimsTableView)
            {
                [registeredSimsTableView selectRowIndexes:indexSet byExtendingSelection:NO];
            }
            if([notification object] != registeredSimsTableView5){
                [registeredSimsTableView5 selectRowIndexes:indexSet byExtendingSelection:NO];
            }
        }
    }
    
    if([[[notification object] identifier] isEqualToString:@"COMPARESIMTV"]){
        if([[self simulationCompareOtherSimTableView] numberOfSelectedRows] == 1){
            NSUInteger selectedSim = [[self simulationCompareOtherSimTableView] selectedRow];
            NSInteger simIndex = -1;
            NSArray *radioCells = [[self simulationCompareSimRadio] cells];
            for(int i = 0; i < [[self allSimulations] count]; i++){
                if([[self allSimulations] objectAtIndex:i] != [self workingSimulation]){
                    simIndex++;
                    if(simIndex==selectedSim){
                        [self setCompareSimulation:[[self allSimulations] objectAtIndex:i]];
                        [self setCompareSimulationLoaded:YES];
                        [[radioCells objectAtIndex:0] setEnabled:YES];
                        [[radioCells objectAtIndex:1] setEnabled:YES];
                        break;
                    }
                }
            }
            [[self simulationCompareSimRadio] selectCell:[radioCells objectAtIndex:1]];
            
            DataSeries *compareDataSeries = [[self compareSimulation] analysisDataSeries];
            
            NSMutableArray *fieldNames = [[[compareDataSeries yData] allKeys] mutableCopy];
            for(int i = 0; i < [fieldNames count]; i++){
                if([[fieldNames objectAtIndex:i] isEqualToString:@"SHORT"]){
                    [fieldNames removeObjectAtIndex:i];
                    break;
                }
            }
            for(int i = 0; i < [fieldNames count]; i++){
                if([[fieldNames objectAtIndex:i] isEqualToString:@"LONG"]){
                    [fieldNames removeObjectAtIndex:i];
                    break;
                }
            }
            [self putFieldNamesInCorrectOrdering:fieldNames];
            
            TimeSeriesLine *tsl;
            NSString *lineColour;
            
            [[self simulationCompareSimBTimeSeries] removeAllObjects];
            for(int i = 0; i < [fieldNames count]; i++){
                lineColour = [[self coloursForPlots] objectAtIndex:i%[[self coloursForPlots] count]];
                tsl = [[TimeSeriesLine alloc] initWithLayerIndex:-1
                                                         AndName:[fieldNames objectAtIndex:i]
                                                       AndColour:lineColour
                                                        AndSimId:1];
                [[self simulationCompareSimBTimeSeries] addObject:tsl];
                
            }
            
            long minDataTime = MIN([[self workingSimulation] startDate],[[self compareSimulation] startDate]);
            long maxDateTime = MAX([[self workingSimulation] endDate],[[self compareSimulation] endDate]);
            
            [[self simulationCompareFromDatePicker] setMinDate:[NSDate dateWithTimeIntervalSince1970:minDataTime]];
            [[self simulationCompareFromDatePicker] setMaxDate:[NSDate dateWithTimeIntervalSince1970:maxDateTime]];
            [[self simulationCompareFromDatePicker] setDateValue:[NSDate dateWithTimeIntervalSince1970:minDataTime]];
            [[self simulationCompareToDatePicker] setMinDate:[NSDate dateWithTimeIntervalSince1970:minDataTime]];
            [[self simulationCompareToDatePicker] setMaxDate:[NSDate dateWithTimeIntervalSince1970:maxDateTime]];
            [[self simulationCompareToDatePicker] setDateValue:[NSDate dateWithTimeIntervalSince1970:minDataTime + (30*24*60*60)]];
        }
        [[self simulationCompareTimeSeriesTableView] reloadData];
        SeriesPlotDataWrapper *plotDataSource = [[SeriesPlotDataWrapper alloc] initWithTargetPlotName:@"COM"
                                                                                       AndSimulationA: [self workingSimulation]
                                                                                       AndSimulationB: [self compareSimulation]
                                                                                      AndTSDictionary: [self simulationCompareSelectedTimeSeries]
                                                                              AndDoShortLongIndicator:NO];
        [self setComparePlotInfo:plotDataSource];
        
        long minDataTime = [[[self simulationCompareFromDatePicker] dateValue] timeIntervalSince1970];
        long maxDateTime = [[[self simulationCompareToDatePicker] dateValue] timeIntervalSince1970];
        
        [[self comparePlotInfo] setDataViewWithStartDateTime:minDataTime
                                              AndEndDateTime:maxDateTime AsZoom:[[self comparePlotInfo] isZoomed]];
        [[self simulationComparePlot] updateLines:plotDataSource];
        
    }
    return;
}


- (void)tableView:(NSTableView *)tableView didClickTableColumn:(NSTableColumn *)tableColumn
{
    
    if([[tableView identifier] isEqualToString:@"SIGTSTV"]){
        if([[tableColumn identifier] isEqualToString:@"plot1"]){
            [[self signalAnalysisPlot] toggleAxisLabelsForLayer:1];
        }
        if([[tableColumn identifier] isEqualToString:@"plot2"]){
            [[self signalAnalysisPlot] toggleAxisLabelsForLayer:2];
        }
        [tableView deselectColumn:[tableView selectedColumn]];
    }
    
    if([[tableView identifier] isEqualToString:@"SIMTSTV"]){
        if([[tableColumn identifier] isEqualToString:@"plot1"]){
            [[self simulationResultsPlot] toggleAxisLabelsForLayer:1];
        }
        if([[tableColumn identifier] isEqualToString:@"plot2"]){
            [[self simulationResultsPlot] toggleAxisLabelsForLayer:2];
        }
        [tableView deselectColumn:[tableView selectedColumn]];
    }
    
    if([[tableView identifier] isEqualToString:@"SIMCOMPARETSTV"]){
        if([[tableColumn identifier] isEqualToString:@"plot1"]){
            [[self simulationComparePlot] toggleAxisLabelsForLayer:1];
        }
        if([[tableColumn identifier] isEqualToString:@"plot2"]){
            [[self simulationComparePlot] toggleAxisLabelsForLayer:2];
        }
        [tableView deselectColumn:[tableView selectedColumn]];
    }
    
    if([[tableView identifier] isEqualToString:@"SIGANALTV"])
    {
  
        NSUInteger numberOfData = [[self workingSimulation] numberOfSignals];
        [[self signalTableViewOrdering] removeAllObjects];       
        NSDictionary *signalAnalysisDetails; 
        //NSMutableArray *columnData = [[NSMutableArray alloc] initWithCapacity:[tableView numberOfRows]];
        double *columnData = malloc(numberOfData * sizeof(double));
        int *sortOrderIndex = malloc(numberOfData * sizeof(int));
        
        int sortSwitch;
        if ([[self signalTableViewSortColumn] isEqualToString:[tableColumn identifier]])
        {
            sortSwitch = ([self signalTableViewSortedAscending]) ? -1: 1;  
            [self setSignalTableViewSortedAscending:![self signalTableViewSortedAscending]];
        }else{
            sortSwitch = 1;
        }
        [self setSignalTableViewSortColumn:[tableColumn identifier]];
        if([[self signalTableViewSortColumn] isEqualToString:@"SIGNALGAIN"]){
            for(int i = 0; i < numberOfData;i++){
                signalAnalysisDetails = [[self workingSimulation] detailsOfSignalAtIndex:i];
                int signalSide = [UtilityFunctions signOfDouble:[[ signalAnalysisDetails objectForKey:@"SIGNAL"] doubleValue]];
                float priceChange = ([[signalAnalysisDetails objectForKey:@"EXITPRICE"] floatValue] - [[signalAnalysisDetails objectForKey:@"ENTRYPRICE"] floatValue]);
                columnData[i] = sortSwitch * signalSide * priceChange;
                sortOrderIndex[i] = i;
            }
        }else{
            for(int i = 0; i < numberOfData;i++){
                signalAnalysisDetails = [[self workingSimulation] detailsOfSignalAtIndex:i];
                NSNumber *dataValue = [signalAnalysisDetails objectForKey:[tableColumn identifier]]; 
                columnData[i] = sortSwitch*[dataValue doubleValue];
                sortOrderIndex[i] = i;
            }
        }
        
        [UtilityFunctions calcSortIndexForDoubleArray:columnData 
                                       WithStartIndex:0 
                                          AndEndIndex:numberOfData-1 
                                AndReturningSortIndex:sortOrderIndex];
        
        for(int i = 0; i < numberOfData;i++){
            [[self signalTableViewOrdering] addObject:[NSNumber numberWithInt:sortOrderIndex[i]]];  
        }
        [tableView reloadData];
        free(columnData);
        free(sortOrderIndex);
    }
}

- (void)tableView:(NSTableView *)aTableView 
  willDisplayCell:(id)aCell 
   forTableColumn:(NSTableColumn *)aTableColumn 
              row:(NSInteger)rowIndex {
    NSDictionary *timeSeriesDictionary;
    NSTextFieldCell *cell = aCell;
    NSColor *lineColour = [NSColor blackColor];
    NSString *lineColourName = @"BLACK";
    BOOL found = NO, doColour = NO;
    TimeSeriesLine *tsl;
    
    if([[aTableView identifier] isEqualToString:@"SIMSELTSTV"]){
        timeSeriesDictionary = [self simulationSelectedTimeSeries];
            doColour = YES;
    }
    if([[aTableView identifier] isEqualToString:@"SIGSELTSTV"]){
        timeSeriesDictionary = [self simulationSignalSelectedTimeSeries];
            doColour = YES;
    }
    if([[aTableView identifier] isEqualToString:@"COMPARESELECTEDTSTV"]){
        timeSeriesDictionary = [self simulationCompareSelectedTimeSeries];
        doColour = YES;
    }
    
    if(doColour){

        NSTableColumn *nameColumn = [[aTableView tableColumns] objectAtIndex:[aTableView columnWithIdentifier:@"name"]];
        NSString *tableLineName = [[nameColumn dataCellForRow:rowIndex] stringValue];
    
        NSArray *lineNames = [timeSeriesDictionary allKeys];
        NSString *lineName;
        for(int iLine = 0; iLine < [lineNames count]; iLine++)
        {
            tsl = [timeSeriesDictionary objectForKey:[lineNames objectAtIndex:iLine]];
            lineName = [[lineNames objectAtIndex:iLine] substringFromIndex:6];
            
            if([[aTableView identifier] isEqualToString:@"COMPARESELECTEDTSTV"]){
                if(([tsl simId]==0 && [[tableLineName substringToIndex:1] isEqualToString:@"A"]) ||
                   ([tsl simId]==1 && [[tableLineName substringToIndex:1] isEqualToString:@"B"])){
                    if([[tableLineName substringFromIndex:2] isEqualToString:lineName]){
                        lineColour = [tsl nsColour];
                        lineColourName = [tsl colour];
                        found = YES;
                        break;
                    }
                }
            }else{
                if([tableLineName isEqualToString:lineName]){
                    lineColour = [tsl nsColour];
                    lineColourName = [tsl colour];
                    found = YES;
                    break;
                }
            }
        }
    
        if(found){
            if([lineColourName isEqualToString:@"White"]){
                [cell setDrawsBackground:YES];
                [cell setBackgroundColor:[NSColor grayColor]];
                
            }else{
                [cell setDrawsBackground:NO];
            }
            [cell setTextColor:lineColour];
        }
    }
}



#pragma mark -
#pragma mark Delegate Methods

-(void)gettingDataIndicatorSwitchOn
{
    if([[self delegate] respondsToSelector:@selector(gettingDataIndicatorSwitchOn)])
    {
        [[self delegate] gettingDataIndicatorSwitchOn];
    }else{
        NSLog(@"Delegate does not respond to \'gettingDataIndicatorSwitchOn:\'");
    }
}

-(void)gettingDataIndicatorSwitchOff
{
    if([[self delegate] respondsToSelector:@selector(gettingDataIndicatorSwitchOff)])
    {
        [[self delegate] gettingDataIndicatorSwitchOff];
    }else{
        NSLog(@"Delegate does not respond to \'gettingDataIndicatorSwitchOff:\'");
    }
}

- (void) readingRecordSetProgress: (NSNumber *) progressFraction
{
    if([[self delegate] respondsToSelector:@selector(readingRecordSetProgress:)])
    {
        [[self delegate] readingRecordSetProgress:progressFraction];
    }else{
        NSLog(@"Delegate does not respond to \'readingRecordSetProgress:\'");
    }
}

- (void) readingRecordSetMessage: (NSString *) progressMessage
{
    if([[self delegate] respondsToSelector:@selector(readingRecordSetMessage:)])
    {
        [[self delegate] readingRecordSetMessage:progressMessage];
    }else{
        NSLog(@"Delegate does not respond to \'readingRecordSetMessage:\'");
    }
}


- (void) disableMainButtons
{
    if([[self delegate] respondsToSelector:@selector(disableMainButtons)])
    {
        [[self delegate] disableMainButtons];
    }else{
        NSLog(@"Delegate not responding to \'disableMainButtons'"); 
    } 
}

- (void) enableMainButtons
{
    if([[self delegate] respondsToSelector:@selector(enableMainButtons)])
    {
        [[self delegate] enableMainButtons];
    }else{
        NSLog(@"Delegate not responding to \'enableMainButtons'"); 
    }
}

- (void) leftPanelTopMessage:(NSString *) message
{
    if([[self delegate] respondsToSelector:@selector(leftPanelTopMessage:)])
    {
        [[self delegate] leftPanelTopMessage:message];
    }else{
        NSLog(@"Delegate doesn't respond to \'leftPanelTopMessage\'");
    }
    
}


#pragma mark -
#pragma mark TabView Delegate Methods

-(void)tabView:(NSTabView *) tabView didSelectTabViewItem:(NSTabViewItem *) tabViewItem
{
    if([[tabView identifier] isEqual:@"CENTRETABS"])
    {
        [rightSideTabView selectTabViewItemWithIdentifier:[tabViewItem identifier]];  
    }
}

-(BOOL) tabView:(NSTabView *) tabView shouldSelectTabViewItem:(NSTabViewItem *)tabViewItem
{
    if([[self simulationController] simulationRunning]){
        return NO;
    }else{
        return YES;
    }
}

-(void)putFieldNamesInCorrectOrdering:(NSMutableArray *) fieldNamesFromData
{      
    if([[self delegate] respondsToSelector:@selector(putFieldNamesInCorrectOrdering:)])
    {
        [[self delegate] putFieldNamesInCorrectOrdering:fieldNamesFromData];
    }else{
        NSLog(@"Delegate not responding to \'putFieldNamesInCorrectOrdering\'"); 
    } 
}

#pragma mark -
#pragma mark Window Delegate Methods

//-(BOOL)windowShouldClose:(NSNotification *)notification{
//    if([notification object] == fullScreenWindow){
//                
//    }
//    return YES;
//}

-(void)windowWillClose:(NSNotification *)notification{
    
    if([notification object] == fullScreenWindow){
        [NSApp stopModal];
        [fullScreenWindow setIsVisible:NO];
        
        if([fullScreenBox contentView] == simulationSignalGraphHostingView){
            [signalAnalysisPlotBox setContentView:simulationSignalGraphHostingView];
        }
        if([fullScreenBox contentView] == simulationResultGraphHostingView){   
            [simPlotBox setContentView:simulationResultGraphHostingView];
        }
        if([fullScreenBox contentView] == [self simulationCompareGraphHostingView]){
            [[self simCompareBox] setContentView:[self simulationCompareGraphHostingView]];
        }
    }
}

-(void)windowDidBecomeKey:(NSNotification *)notification
{
    if([[[notification object] identifier] isEqualToString:@"SETUPWINDOW"]){
        if([self firstTimeSetup]){
            NSString *paramFilePath = @"file://localhost/Users/Martin/Documents/params.ssp";
            NSURL *previousParamsFile =  [NSURL URLWithString:paramFilePath];
            NSFileManager *fileManager = [NSFileManager defaultManager];

            if ([fileManager fileExistsAtPath:@"/Users/Martin/Documents/params.ssp"]){
                NSData *importedData = [NSData  dataWithContentsOfURL:previousParamsFile];
                NSDictionary *importedParameters =  [NSKeyedUnarchiver unarchiveObjectWithData:importedData];
                [self fillSetupSheet:importedParameters];
            }
            [self setFirstTimeSetup:NO];
        }
    }
}
#pragma mark -
#pragma mark Properties

@synthesize setupSheetShowButton;
@synthesize setupSheetImportDataButton;
@synthesize setupSheetImportDataTableView;
@synthesize setupSheetImportDataScrollView;
@synthesize setupAccountCurrencyLabel;
@synthesize setupTradingWeekendYesNo;
@synthesize reportTableView;
@synthesize simulationSignalTimeSeriesTableView;
@synthesize signalAnalysisPlotLeadHours;
@synthesize simulationSignalGraphHostingView;
@synthesize simulationSignalTableView;
@synthesize simulationCashFlowsTableView;
@synthesize simulationTradesTableView;
@synthesize setUpSheetCancelButton;
@synthesize aboutSimEndTimeLabel;
@synthesize aboutSimStartTimeLabel;
@synthesize aboutAccountCurrencyLabel;
@synthesize aboutTradingPairLabel;
@synthesize aboutSimNameLabel;
@synthesize performSimulationProgressBar;
@synthesize setupTradingLagTextField;
@synthesize endDateDoWLabel;
@synthesize startDateDoWLabel;
@synthesize dataAvailabilityToLabel;
@synthesize dataAvailabilityFromLabel;
@synthesize setupSamplingMinutesTextField;
@synthesize setupTradingEndTimePicker;
@synthesize setupTradingStartTimePicker;
@synthesize setupMaxLeverageTextField;
@synthesize setupParameterTextField;
@synthesize setupEndTimePicker;
@synthesize setupStartTimePicker;
@synthesize setupAccountBalanceTextField;
@synthesize setupAccountCurrencyPopup;
@synthesize setupSimulationName;
@synthesize setupTradingPairPopup;
@synthesize setupTradingPairPipSizeLabel;
@synthesize setupExtraSeriesTextField;
@synthesize centreTabView;
@synthesize rightSideTabView;
@synthesize performSimulationStatusLabel;
@synthesize simulationNumbersTableView;
@synthesize simulationMessagesTextView;
@synthesize simulationResultGraphHostingView;
@synthesize simulationTimeSeriesTableView;
@synthesize performSimulationButton;
@synthesize simulationRunScrollView;
@synthesize accountCurrencyLabel;
@synthesize endLabel;
@synthesize startLabel;
@synthesize tradingPairLabel;
@synthesize simulationNameLabel;
@synthesize zoomToDatePicker;
@synthesize zoomFromDatePicker;
@synthesize simulationSignalSelectedTimeSeriesTableView;
@synthesize simulationTimeSeriesSelectedTableView;
@synthesize setupRulesTextField;
@synthesize setupDataWarmUpTextField;
@synthesize simPlotBox;
@synthesize signalAnalysisPlotBox;
@synthesize fullScreenBox;
@synthesize setupPositioningTextField;
@synthesize registeredSimsTableView;
@synthesize registeredSimsTableView1;
@synthesize registeredSimsTableView2;
@synthesize registeredSimsTableView3;
@synthesize registeredSimsTableView5;
@synthesize importSimulationButton;
@synthesize removeSimulationButton;
@synthesize registeredSimsScrollView1;
@synthesize exportSimulationButton;
@synthesize allSimulations = _allSimulations;
@synthesize simulationTimeSeries = _simulationTimeSeries;
@synthesize simulationSignalTimeSeries = _simulationSignalTimeSeries;
@synthesize simulationCompareSimATimeSeries = _simulationCompareSimATimeSeries;
@synthesize simulationCompareSimBTimeSeries = _simulationCompareSimBTimeSeries;
//@synthesize simulationCompareSelectTimeSeries = _simulationCompareSelectTimeSeries;
@synthesize simulationCompareSelectedTimeSeries = _simulationCompareSelectedTimeSeries;
@synthesize signalTableViewSortedAscending = _signalTableViewSortedAscending;
@synthesize initialSetupComplete = _initialSetupComplete;
@synthesize doingSetup = _doingSetup;
@synthesize cancelProcedure = _cancelProcedure;
@synthesize signalTableViewSortColumn = _signalTableViewSortColumn;
@synthesize longShortIndicatorOn = _longShortIndicatorOn;
@synthesize importDataFilename = _importDataFilename;
@synthesize hideObjectsOnStartup = _hideObjectsOnStartup;
@synthesize simulationController = _simulationController;
@synthesize signalTableViewOrdering = _signalTableViewOrdering;
@synthesize simulationResultsPlot = _simulationResultsPlot;
@synthesize simulationComparePlot = _simulationComparePlot;
@synthesize signalAnalysisPlot = _signalAnalysisPlot;
//@synthesize simulationDataSeries = _simulationDataSeries;
@synthesize importDataArray = _importDataArray;
@synthesize fxPairsAndDbIds = _fxPairsAndDbIds;
@synthesize coloursForPlots = _coloursForPlots;
@synthesize dataControllerForUI = _dataControllerForUI;
@synthesize doThreads = _doThreads;
@synthesize firstTimeSetup = _firstTimeSetup;
@synthesize workingSimulation = _workingSimulation;
@synthesize compareSimulation = _compareSimulation;
@synthesize compareSimulationLoaded = _compareSimulationLoaded;

@end
