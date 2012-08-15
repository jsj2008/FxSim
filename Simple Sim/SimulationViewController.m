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

#define DAY_SECONDS 24*60*60

@interface SimulationViewController ()
- (void) putFieldNamesInCorrectOrdering:(NSMutableArray *) fieldNamesFromData;
- (void) endSetupSheet;
- (void) updateStatus:(NSString *) statusMessage;
- (void) showAlertPanelWithInfo: (NSDictionary *) alertInfo;
- (NSArray *) csvDataFromURL: (NSURL *)absoluteURL;
- (void) addPlotToFullScreenWindow: (NSView *) fullScreenView;
@end

@implementation SimulationViewController
@synthesize simPlotBox;
@synthesize signalAnalysisPlotBox;
@synthesize fullScreenBox;
@synthesize setupPositioningTextField;


- (id)init{
    self = [super initWithNibName:@"SimulationView" bundle:nil];
    if(self){
        [self setTitle:@"Simulation"];
        [self setDoThreads:NO];
        initialSetupComplete = YES;
        doingSetup = NO;
        cancelProcedure = NO;
        [self setDoThreads:NO];
        simulationTimeSeries = [[NSMutableArray alloc] init];
        simulationSignalTimeSeries = [[NSMutableArray alloc] init]; 
        signalTableViewSortedAscending = YES;
        
    }
    return self;
}

- (void) awakeFromNib
{
    fullScreenWindowController = [[NSWindowController alloc] initWithWindow:fullScreenWindow];
    [fullScreenWindow setDelegate:self];
        
    simulationController = [[SimulationController alloc] init];
    [simulationController setDelegate:self];
    [simulationController setDoThreads:doThreads];
    
    simulationResultsPlot = [[SeriesPlot alloc] initWithIdentifier:@"SIMRESULTS"];
    [simulationResultsPlot setHostingView:simulationResultGraphHostingView];
    [simulationResultsPlot initialGraphAndAddAnnotation:NO];
    
    [simulationResultsPlot initialGraphAndAddAnnotation:NO];
   
    signalAnalysisPlot = [[SeriesPlot alloc] initWithIdentifier:@"SIGNALS"];
    [signalAnalysisPlot setHostingView:simulationSignalGraphHostingView];
    
    NSTableColumn *simulationColourColumn =  [simulationTimeSeriesTableView tableColumnWithIdentifier:@"colourId"];
    NSTableColumn *signalAnalysisColourColumn =  [simulationSignalTimeSeriesTableView tableColumnWithIdentifier:@"colourId"];
    
    NSPopUpButtonCell *simulationColourDropDownCell = [[NSPopUpButtonCell alloc] init];
    NSPopUpButtonCell *signalAnalysisColourDropDownCell = [[NSPopUpButtonCell alloc] init];
    
    [simulationColourDropDownCell setBordered:NO];
    [simulationColourDropDownCell setEditable:YES];
    
    [signalAnalysisColourDropDownCell setBordered:NO];
    [signalAnalysisColourDropDownCell setEditable:YES];
    
    [simulationColourDropDownCell addItemsWithTitles:coloursForPlots];
    [simulationColourColumn setDataCell:simulationColourDropDownCell];
    [simulationTimeSeriesTableView setDataSource:self];
    
    [signalAnalysisColourDropDownCell addItemsWithTitles:coloursForPlots];
    [signalAnalysisColourColumn setDataCell:simulationColourDropDownCell];
    [simulationSignalTimeSeriesTableView setDataSource:self];
    
    //Popup sheet stuff
    [setupTradingPairPopup removeAllItems];
    NSArray *fxPairs = [fxPairsAndDbIds allKeys];
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
    
    long minDataDateTime = [dataControllerForUI getMinDateTimeForFullData];
    long maxDataDateTime = [dataControllerForUI getMaxDateTimeForFullData];
    
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
    
    [setupSheetImportDataTableView setDataSource:self];
    
    int tabIndex;
    tabIndex = [centreTabView indexOfTabViewItemWithIdentifier:@"SETUP"];
    setupTab = [centreTabView tabViewItemAtIndex:tabIndex];
    tabIndex = [centreTabView indexOfTabViewItemWithIdentifier:@"PLOT"];
    plotTab = [centreTabView tabViewItemAtIndex:tabIndex];
    tabIndex = [centreTabView indexOfTabViewItemWithIdentifier:@"NUMBERS"];
    dataTab = [centreTabView tabViewItemAtIndex:tabIndex];
    tabIndex = [centreTabView indexOfTabViewItemWithIdentifier:@"REPORT"];
    reportTab = [centreTabView tabViewItemAtIndex:tabIndex];
    tabIndex = [centreTabView indexOfTabViewItemWithIdentifier:@"SIGNAL"];
    signalsTab = [centreTabView tabViewItemAtIndex:tabIndex];
    tabIndex = [centreTabView indexOfTabViewItemWithIdentifier:@"ZOOM"];
    
    [centreTabView removeTabViewItem:plotTab];
    [centreTabView removeTabViewItem:dataTab];
    [centreTabView removeTabViewItem:reportTab];
    [centreTabView removeTabViewItem:signalsTab];
    
    hideObjectsOnStartup = [NSArray arrayWithObjects: aboutSimNameLabel, aboutTradingPairLabel, aboutAccountCurrencyLabel, aboutSimStartTimeLabel,aboutSimEndTimeLabel, aboutSimSamplingRateLabel, aboutSimTradingLagLabel, aboutSimTradingWindowStartLabel, aboutSimTradingWindowEndLabel, aboutSimParametersLabel, tradingPairLabel, accountCurrencyLabel, startLabel, endLabel, samplingRateLabel, tradingLagLabel, tradingDayStartLabel, tradingDayEndLabel,descriptionLabel, nil];
    
    
    for(int i =0; i < [hideObjectsOnStartup count];i++){
        [[hideObjectsOnStartup objectAtIndex:i] setHidden:YES];
    }
    
    [simulationRunScrollView setFrame:CGRectMake(18.0f, 59.0f, 650.0f, 417.0f)];
    [centreTabView selectTabViewItemWithIdentifier:@"SETUP"];
    [rightSideTabView selectTabViewItemWithIdentifier:@"SETUP"];
    
    [simulationSignalTimeSeriesTableView setDelegate:self];
    [simulationTimeSeriesTableView setDelegate:self];
    initialSetupComplete = NO;
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
    return [self doThreads];
}

- (void) setDoThreads:(BOOL)doThreadedProcedures
{
    doThreads = doThreadedProcedures;
}

- (void) initialiseSignalTableView{
    signalTableViewOrdering = [[NSMutableArray alloc] initWithCapacity:[[simulationController currentSimulation] numberOfSignals]];
    
    if( [[simulationController currentSimulation] numberOfSignals]>0){
        [signalTableViewOrdering removeAllObjects];
        for(int i = 0; i < [[simulationController currentSimulation] numberOfSignals]; i++){
            [signalTableViewOrdering addObject:[NSNumber numberWithInt:i]];  
        }
        signalTableViewSortColumn = @"ENTRYTIME";
        
        NSDictionary *signalInfo;
        signalInfo = [[simulationController currentSimulation] detailsOfSignalAtIndex:0];
        int tradingLag = [[simulationController currentSimulation] tradingLag];
        
        long startDateTime = [[signalInfo objectForKey:@"ENTRYTIME"] longValue];
        startDateTime = startDateTime - ([signalAnalysisPlotLeadHours intValue] * 60*60);
        long endDateTime = [[signalInfo objectForKey:@"EXITTIME"] longValue] + 2*tradingLag;
        
        DataSeries *analysisDataSeries = [[simulationController currentSimulation] analysisDataSeries]; 
        TimeSeriesLine *tsl;
        NSMutableArray *fieldNames;
        
        fieldNames = [[[analysisDataSeries yData] allKeys] mutableCopy];
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
            lineColour = [coloursForPlots objectAtIndex:i%[coloursForPlots count]];
            tsl = [[TimeSeriesLine alloc] initWithLayerIndex:plotLayerIndex 
                                                     AndName:[fieldNames objectAtIndex:i] 
                                                   AndColour:lineColour];
            [self addToTableView:simulationSignalTimeSeriesTableView 
                  TimeSeriesLine:tsl];
        }
        startDateTime = startDateTime - ([signalAnalysisPlotLeadHours intValue] * 60*60);
        longShortIndicatorOn = YES;
        [self plotSignalDataFrom:startDateTime 
                              To:endDateTime];
    }
    
}

-(void)setupResultsReport
{
    [reportTableView reloadData];
}

-(void)simulationEnded
{
    initialSetupComplete = YES;
    [setUpSheetCancelButton setEnabled:NO];
    [setupSheetShowButton setEnabled:YES];
}


-(void)plotSimulationData: (DataSeries *) analysisDataSeries
{
    TimeSeriesLine *tsl;
    NSMutableArray *fieldNames;
    fieldNames = [[[analysisDataSeries yData] allKeys] mutableCopy];
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
        lineColour = [coloursForPlots objectAtIndex:i%[coloursForPlots count]];
        tsl = [[TimeSeriesLine alloc] initWithLayerIndex:plotLayerIndex
                                                 AndName:[fieldNames objectAtIndex:i] 
                                               AndColour:lineColour];
        [self addToTableView:simulationTimeSeriesTableView   TimeSeriesLine:tsl];
    }
    [simulationResultsPlot setHostingView:simulationResultGraphHostingView];
    [simulationResultsPlot setData:analysisDataSeries WithViewName:@"ALL"];
    [simulationResultsPlot renderPlotWithFields:simulationTimeSeries];
    
    long minDataTime = [analysisDataSeries minDateTime];
    long maxDateTime = [analysisDataSeries maxDateTime];
    
    [zoomFromDatePicker setMinDate:[NSDate dateWithTimeIntervalSince1970:minDataTime]];
    [zoomFromDatePicker setMaxDate:[NSDate dateWithTimeIntervalSince1970:maxDateTime]];
    [zoomFromDatePicker setDateValue:[NSDate dateWithTimeIntervalSince1970:minDataTime]];
    [zoomToDatePicker setMinDate:[NSDate dateWithTimeIntervalSince1970:minDataTime]];
    [zoomToDatePicker setMaxDate:[NSDate dateWithTimeIntervalSince1970:maxDateTime]];
    [zoomToDatePicker setDateValue:[NSDate dateWithTimeIntervalSince1970:maxDateTime]];
    
    simulationDataSeries = analysisDataSeries;
    
}

- (void) addSimulationDataToResultsTableView: (DataSeries *) analysisDataSeries
{
    [self clearTSTableView:simulationNumbersTableView];
    NSTableColumn *newTableColumn;
    NSArray *tableColumns;
    NSMutableArray *fieldNames;
    NSMutableArray *isAvailable;
    NSArray *fieldNamesFromData;
    float tableViewWidth = 0.0;
    
    fieldNames = [[[analysisDataSeries yData] allKeys] mutableCopy];
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
    for(int i = [fieldNames count] - 1; i >= 0; i--){
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
    //    newTableColumn = [[NSTableColumn alloc] initWithIdentifier:@"MID"];
    //    NSCell *columnsCell = [newTableColumn dataCell];
    //    [columnsCell setAlignment:NSRightTextAlignment];
    //    [[newTableColumn headerCell] setStringValue:@"MID"];
    //    [simAnalysisDataTable addTableColumn:newTableColumn];
    
    NSCell *columnsCell;
    //NSArray *newColumnIdentifiers = [[analysisDataSeries yData] allKeys];
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

- (void) plotSignalDataFrom: (long) startDateTime 
                         To:(long) endDateTime
{
    DataSeries *analysisDataSeries = [[simulationController currentSimulation] analysisDataSeries]; 
    
    [analysisDataSeries setPlotViewWithName:@"SIGNAL" AndStartDateTime:startDateTime AndEndDateTime:endDateTime];
    
    [signalAnalysisPlot setData:analysisDataSeries WithViewName:@"SIGNAL"];
    [signalAnalysisPlot renderPlotWithFields:simulationSignalTimeSeries];
    simulationDataSeries = analysisDataSeries;
    
}

- (void) addSimInfoToAboutPanelWithName: (NSString *) simName
                              AndFxPair: (NSString *) fxPair
                     AndAccountCurrency: (NSString *) accCurrency
                        AndSimStartTime: (NSString *) simStartTime
                          AndSimEndTime: (NSString *) simEndTime
                        AndSamplingRate: (NSString *) samplingRate
                          AndTradingLag: (NSString *) tradingLag
                  AndTradingWindowStart: (NSString *) tradingStartTime
                    AndTradingWindowEnd: (NSString *) tradingEndTime
                       AndSimParameters: (NSString *) parameters
{   
    [aboutSimNameLabel setStringValue:simName];
    [aboutTradingPairLabel setStringValue:fxPair];
    [aboutAccountCurrencyLabel setStringValue:accCurrency];
    [aboutSimStartTimeLabel setStringValue:simStartTime];
    [aboutSimEndTimeLabel setStringValue:simEndTime];
    [aboutSimSamplingRateLabel setStringValue:samplingRate];
    [aboutSimTradingLagLabel setStringValue:tradingLag];
    [aboutSimTradingWindowStartLabel setStringValue:tradingStartTime];
    [aboutSimTradingWindowEndLabel setStringValue:tradingEndTime];
    [aboutSimParametersLabel setStringValue:parameters];
}

- (void) viewChosenFromMainMenu
{
    if(!initialSetupComplete){
        //Not yet, this is to show cancel that the setup button has been pressed
        doingSetup = NO;
        [self disableMainButtons];
        [setupSheetShowButton setEnabled:NO];
        [NSApp beginSheet:setupSheet modalForWindow:[centreTabView window] modalDelegate:nil didEndSelector:NULL contextInfo:NULL];
    }
}

- (void) endSetupSheet
{
    if(cancelProcedure == NO)
    {
        [NSApp endSheet:setupSheet returnCode: NSOKButton];
    }else{
        [NSApp endSheet:setupSheet returnCode: NSCancelButton];
        [setupSheetShowButton setEnabled:YES];
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

#pragma mark -
#pragma mark IBActions Methods

- (IBAction)plotLeftSideContract:(id)sender {
    NSString *senderIdentifer = [sender identifier];
    if (([[NSApp currentEvent] modifierFlags] & NSAlternateKeyMask) != 0){
        if([[senderIdentifer substringToIndex:7] isEqualToString:@"BIGPLOT"]){
            [simulationResultsPlot rightSideExpand];
        }
        
        if([[senderIdentifer substringToIndex:7] isEqualToString:@"SIGPLOT"]){
            [signalAnalysisPlot rightSideExpand];
        } 
    }else{
        if([[senderIdentifer substringToIndex:7] isEqualToString:@"BIGPLOT"]){
            [simulationResultsPlot leftSideContract];
        }
    
        if([[senderIdentifer substringToIndex:7] isEqualToString:@"SIGPLOT"]){
            [signalAnalysisPlot leftSideContract];
        }
    }
 
}

- (IBAction)plotLeftSideExpand:(id)sender {
    NSString *senderIdentifer = [sender identifier];
    if (([[NSApp currentEvent] modifierFlags] & NSAlternateKeyMask) != 0){
        if([[senderIdentifer substringToIndex:7] isEqualToString:@"BIGPLOT"]){
            [simulationResultsPlot rightSideContract];
        }
        
        if([[senderIdentifer substringToIndex:7] isEqualToString:@"SIGPLOT"]){
            [signalAnalysisPlot rightSideContract];
        }
        
    }else{
        if([[senderIdentifer substringToIndex:7] isEqualToString:@"BIGPLOT"]){
            [simulationResultsPlot leftSideExpand];
        }
    
        if([[senderIdentifer substringToIndex:7] isEqualToString:@"SIGPLOT"]){
            [signalAnalysisPlot leftSideExpand];
        }
    }
}

- (IBAction)plotBottomExpand:(id)sender {
    NSString *senderIdentifer = [sender identifier];
    if (([[NSApp currentEvent] modifierFlags] & NSAlternateKeyMask) != 0){
        // do alternate action
        if([[senderIdentifer substringToIndex:7] isEqualToString:@"BIGPLOT"]){
            [simulationResultsPlot topContract];
        }
        
        if([[senderIdentifer substringToIndex:7] isEqualToString:@"SIGPLOT"]){
            [signalAnalysisPlot topContract];
        } 
        
    }else{
            // do normal action
        if([[senderIdentifer substringToIndex:7] isEqualToString:@"BIGPLOT"]){
            [simulationResultsPlot bottomExpand];
        }
    
        if([[senderIdentifer substringToIndex:7] isEqualToString:@"SIGPLOT"]){
            [signalAnalysisPlot bottomExpand];
        }
    }
}

- (IBAction)plotBottomContract:(id)sender {
    NSString *senderIdentifer = [sender identifier];
    if (([[NSApp currentEvent] modifierFlags] & NSAlternateKeyMask) != 0){
        if([[senderIdentifer substringToIndex:7] isEqualToString:@"BIGPLOT"]){
            [simulationResultsPlot topExpand];
        }
        
        if([[senderIdentifer substringToIndex:7] isEqualToString:@"SIGPLOT"]){
            [signalAnalysisPlot topExpand];
        }

    }else{
        if([[senderIdentifer substringToIndex:7] isEqualToString:@"BIGPLOT"]){
            [simulationResultsPlot bottomContract];
        }
    
        if([[senderIdentifer substringToIndex:7] isEqualToString:@"SIGPLOT"]){
            [signalAnalysisPlot bottomContract];
        }
    }
}

- (IBAction)exportData:(id)sender {
    // Create a File Save Dialog class.
    BOOL allOk;
    NSString *suggestedFileName;
    NSSavePanel *saveDlg = [NSSavePanel savePanel];
    suggestedFileName = [NSString stringWithFormat:@"%@dataTS",[[simulationController currentSimulation] name]];
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
        allOk = [simulationController exportData:fileToSaveTo];
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
    suggestedFileName = [NSString stringWithFormat:@"%@trades",[[simulationController currentSimulation] name]];
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
        allOk = [simulationController exportTrades:fileToSaveTo];
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
    suggestedFileName = [NSString stringWithFormat:@"%@balAdjs",[[simulationController currentSimulation] name]];
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
        allOk = [simulationController exportBalAdjmts:fileToSaveTo];
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
    suggestedFileName = [NSString stringWithFormat:@"%@report",[[simulationController currentSimulation] name]];
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
        allOk = [simulationController writeReportToCsvFile:fileToSaveTo];
        if(!allOk){
            [self updateStatus:@"Problem trying to write data to file"];
        }
    }
}

- (IBAction)zoomButtonPress:(id)sender {
    long zoomStartDateTime, zoomEndDateTime;
    zoomStartDateTime = [[zoomFromDatePicker dateValue] timeIntervalSince1970];
    zoomEndDateTime = [[zoomToDatePicker dateValue] timeIntervalSince1970];
    
    [simulationResultsPlot setZoomDataViewFrom:zoomStartDateTime To:zoomEndDateTime];
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
                importDataArray = importedData;
                importDataFilename = [fileToRead absoluteString];
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
                int tableViewWidth;
                NSArray *dataRow = [importDataArray objectAtIndex:0];
                for(int i = 0; i < [dataRow count]; i++){
                    newTableColumn = [[NSTableColumn alloc] initWithIdentifier:[NSString stringWithFormat:@"Col%d",i]];
                    [[newTableColumn headerCell] setStringValue:[dataRow objectAtIndex:i]];
                    if(i ==0){
                        [newTableColumn setWidth:150];
                    }else{
                        int width;
                        width = MAX(50, (280-150)/([dataRow count]-1));
                        [newTableColumn setWidth:width];
                    }
                    tableViewWidth = tableViewWidth + [newTableColumn width];
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
                importDataArray = nil;
                importDataFilename = nil;
                [setupSheetImportDataScrollView setHidden:YES];
                [setupSheetImportDataButton setTitle:@"Import Data"];
            }
        }else{
            importDataArray = nil;
            importDataFilename = nil;
            [setupSheetImportDataScrollView setHidden:YES];
            [setupSheetImportDataButton setTitle:@"Import Data"];
        }
    }else{
        importDataArray = nil;
        importDataFilename = nil;
        [setupSheetImportDataScrollView setHidden:YES];
        [setupSheetImportDataButton setTitle:@"Import Data"];
    }
}

- (IBAction)signalAnalysisPlotReload:(id)sender {
    NSInteger selectedRow = [simulationSignalTableView selectedRow];
    if(selectedRow > -1){
        selectedRow = [[signalTableViewOrdering objectAtIndex:selectedRow] intValue];
        NSDictionary *signalInfo;
        signalInfo = [[simulationController currentSimulation] detailsOfSignalAtIndex:selectedRow];
        int tradingLag = [[simulationController currentSimulation] tradingLag];
        
        long startDateTime = [[signalInfo objectForKey:@"ENTRYTIME"] longValue];
        startDateTime = startDateTime - ([signalAnalysisPlotLeadHours intValue] * 60*60);
        long endDateTime = [[signalInfo objectForKey:@"EXITTIME"] longValue] + 2*tradingLag;
        
        [self plotSignalDataFrom:startDateTime To:endDateTime];
    }
}

- (IBAction)signalAnalysisPlotFullScreen:(id)sender {
    [self addPlotToFullScreenWindow:simulationSignalGraphHostingView];
}

- (IBAction)simPlotFullScreen:(id)sender {
    [self addPlotToFullScreenWindow:simulationResultGraphHostingView];
}

- (IBAction)changeSelectedTradingPair:(id)sender {
    NSString *selectedPair = [[setupTradingPairPopup selectedItem] title];
    [setupAccountCurrencyPopup removeAllItems];
    [setupAccountCurrencyPopup addItemWithTitle:[selectedPair substringFromIndex:3]];
    [setupAccountCurrencyPopup addItemWithTitle:[selectedPair substringToIndex:3]];
    [setupAccountCurrencyPopup selectItemAtIndex:0];
    [setupAccountCurrencyLabel setStringValue:[[setupAccountCurrencyPopup selectedItem] title]];
}

- (IBAction)showSetupSheet:(id)sender
{
    //Not yet, this is to show cancel that the setup button has been pressed
    doingSetup = NO;
    cancelProcedure = NO;
    [setupSheetShowButton setEnabled:NO];
    [self disableMainButtons];
    [NSApp beginSheet:setupSheet modalForWindow:[centreTabView window] modalDelegate:nil didEndSelector:NULL contextInfo:NULL];
}

- (IBAction)cancelSetupSheet:(id)sender{
    cancelProcedure = YES;
    if(doingSetup == NO){
        [self endSetupSheet];
    }
    [setupSheetShowButton setEnabled:YES];
}

- (IBAction)cancelSimulation:(id)sender{
    NSString *userMessage = @"Trying to cancel...";
    if(doThreads){
        [self performSelectorOnMainThread:@selector(updateStatus:) withObject:userMessage waitUntilDone:NO];
        [simulationController performSelectorInBackground:@selector(askSimulationToCancel) withObject:nil];

    }else{
        [simulationController askSimulationToCancel];
    }
    [setUpSheetCancelButton setEnabled:NO];
}

- (IBAction)toggleLongShortIndicator:(id)sender {
    
    [simulationResultsPlot togglePositionIndicator];
}

- (IBAction)sigPlotLongShortIndicatorToggle:(id)sender {
    longShortIndicatorOn = !longShortIndicatorOn;
    [signalAnalysisPlot togglePositionIndicator];
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
    
    if(![SimulationController positioningUnderstood:[setupPositioningTextField stringValue]])
    {
        basicCheckOk = NO;
        userMessage = @"Positioning not understood";
    }
    
    long tradingStartDateTime = [EpochTime epochTimeAtZeroHour:startDateTime] + tradingDayStartTime;
    long tradingEndDateTime = [EpochTime epochTimeAtZeroHour:endDateTime] + tradingDayEndTime;
    BOOL weekendTrading = [setupTradingWeekendYesNo state] == NSOnState;
    
    if(basicCheckOk)
    {
        [parameters setObject:[setupSimulationName stringValue] 
                       forKey:@"SIMNAME"];
        [parameters setObject:[setupParameterTextField stringValue] 
                       forKey:@"SIMTYPE"];
        [parameters setObject:[setupPositioningTextField stringValue] 
                       forKey:@"POSTYPE"];
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
        [parameters setObject:[NSNumber numberWithLong:(28*DAY_SECONDS)] 
                       forKey:@"WARMUPDATA"];
        
        
        if(importDataArray == nil){
            [parameters setObject:[NSNumber numberWithBool:NO] 
                           forKey:@"USERDATAGIVEN"];
        }else{
            [parameters setObject:[NSNumber numberWithBool:YES] 
                           forKey:@"USERDATAGIVEN"];
            [parameters setObject:importDataArray 
                           forKey:@"USERDATA"];
            [parameters setObject:importDataFilename 
                           forKey:@"USERDATAFILE"];
        }
    }
    
    if(basicCheckOk)
    {
        [setUpSheetCancelButton setEnabled:YES];
    
        currentProgressIndicator = performSimulationProgressBar;
        if(doThreads){
            [simulationController performSelectorInBackground:@selector(tradingSimulation:) withObject:parameters];
        }else{
            [simulationController tradingSimulation:parameters];
        }
    
        [performSimulationButton setEnabled:YES];
        [self endSetupSheet];
    }else{
        NSRunAlertPanel(@"Bad Parameters", userMessage, @"OK", nil, nil);
        [performSimulationButton setEnabled:YES];
    }
    
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
    [[[simulationMessagesTextView textStorage] mutableString] appendString:@"\n"];
}

#pragma mark -
#pragma mark TableView Methods

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView{
   if([[tableView identifier] isEqualToString:@"SIMTSTV"]){
        return [simulationTimeSeries count]; 
    }
    
    if([[tableView identifier] isEqualToString:@"SIGTSTV"]){
        return [simulationSignalTimeSeries count]; 
    } 
    
    if([[tableView identifier] isEqualToString:@"TRADESTV"]){
        return [[simulationController currentSimulation] numberOfTrades]; 
    }
    
    if([[tableView identifier] isEqualToString:@"CASHTRANSTV"]){
        return [[simulationController currentSimulation] numberOfBalanceAdjustments]; 
    }
    
    if([[tableView identifier] isEqualToString:@"SIMDATATV"]){
        return [[[simulationController currentSimulation] analysisDataSeries] length]; 
    }
    
    if([[tableView identifier] isEqualToString:@"SIGANALTV"]){
        return [[simulationController currentSimulation] numberOfSignals]; 
    }

    if([[tableView identifier] isEqualToString:@"SIMREPORTTV"])
    {
        return [[simulationController currentSimulation] getNumberOfReportDataFields];
    }
    if([[tableView identifier] isEqualToString:@"IMPORTDATATV"])
    {
        if(importDataArray !=0){
            return [importDataArray count]-1;
        }else{
            return 0;
        }
    }
    return 0;
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    TimeSeriesLine *tsl;
    NSString *columnId = [tableColumn identifier];
    
    if([[tableView identifier] isEqualToString:@"SIMTSTV"]){
        tsl = [simulationTimeSeries objectAtIndex:row];
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
    
    if([[tableView identifier] isEqualToString:@"SIGTSTV"]){
        tsl = [simulationSignalTimeSeries objectAtIndex:row];
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
            return [EpochTime stringDateWithTime:[[simulationController currentSimulation] getDateTimeForTradeAtIndex:row]];
        }
        if([[tableColumn identifier] isEqualToString:@"AMOUNT"])
        {
            return [NSString stringWithFormat:@"%d",[[simulationController currentSimulation] getAmountForTradeAtIndex:row]];
        }
        if([[tableColumn identifier] isEqualToString:@"PRICE"])
        {
            return [NSString stringWithFormat:@"%5.3f",[[simulationController currentSimulation] getPriceForTradeAtIndex:row]];
        }
        if([[tableColumn identifier] isEqualToString:@"ENDEXP"])
        {
            return [NSString stringWithFormat:@"%d",[[simulationController currentSimulation] getResultingMarketExposureForTradeAtIndex:row]];
        }
    }
    
    if([[tableView identifier] isEqualToString:@"CASHTRANSTV"])
    {
        if([[tableColumn identifier] isEqualToString:@"DATETIME"])
        {
            return [EpochTime stringDateWithTime:[[simulationController currentSimulation] getDateTimeForBalanceAdjustmentAtIndex:row]];
        }
        if([[tableColumn identifier] isEqualToString:@"AMOUNT"])
        {
            return [NSString stringWithFormat:@"%5.3f",[[simulationController currentSimulation] getAmountForBalanceAdjustmentAtIndex:row]];
        }
        if([[tableColumn identifier] isEqualToString:@"REASON"])
        {
            return [[simulationController currentSimulation] getReasonForBalanceAdjustmentAtIndex:row]; 
        }
        if([[tableColumn identifier] isEqualToString:@"ENDBALANCE"])
        {
            return [NSString stringWithFormat:@"%5.3f",[[simulationController currentSimulation] getResultingBalanceForBalanceAdjustmentAtIndex:row]];
        }
    }
     
    if([[tableView identifier] isEqualToString:@"SIMDATATV"]){
        DataSeries* simData = [[simulationController currentSimulation] analysisDataSeries];
        if([[tableColumn identifier] isEqualToString:@"DATETIME"]){
            long dateTimeNumber = [[[simData xData] sampleValue:row] longValue];
            NSString *dateTime = [EpochTime stringDateWithTime:dateTimeNumber];
            return dateTime;
        }else{
            NSString *identiferString = [tableColumn identifier];
            if([identiferString isEqualToString:@"DATETIME"] || [identiferString isEqualToString:@"POS_PNL"] || [identiferString isEqualToString:@"NAV"] )
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
        int sortedIndex =  [[signalTableViewOrdering objectAtIndex:row] intValue];
        NSDictionary *signalAnalysisDetails = [[simulationController currentSimulation] detailsOfSignalAtIndex:sortedIndex];
        
        if([[tableColumn identifier] isEqualToString:@"SIGNAL"]){
            int signalSide =  [UtilityFunctions signOfDouble:[[signalAnalysisDetails objectForKey:@"SIGNAL"] doubleValue]];
            return [NSNumber numberWithFloat:signalSide];
        }
        if([[tableColumn identifier] isEqualToString:@"SIGNALGAIN"]){
           
            int signalSide = [UtilityFunctions signOfDouble:[[signalAnalysisDetails objectForKey:@"SIGNAL"] doubleValue]];
                          
            float priceChange = ([[signalAnalysisDetails objectForKey:@"EXITPRICE"] floatValue] - [[signalAnalysisDetails objectForKey:@"ENTRYPRICE"] floatValue]);
            return [NSNumber numberWithFloat:signalSide * priceChange];
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
             returnValue = [[simulationController currentSimulation] getReportNameFieldAtIndex:row];
        }
        if([[tableColumn identifier] isEqualToString:@"DATA1"])
        {
            returnValue = [[simulationController currentSimulation] getReportDataFieldAtIndex:row];
        }
        if([returnValue isKindOfClass:[NSString class]]){
            if([returnValue length] > 25){
                NSString *truncated =    [returnValue substringWithRange:NSMakeRange([returnValue length]-37, 37)];
                returnValue = [NSString stringWithFormat:@"...%@",truncated];
            }
        }
        return returnValue;
//            id returnValue = [[simulationController currentSimulation] getReportDataFieldAtIndex:row];
//            if([returnValue isKindOfClass:[NSString class]]){
//                return returnValue;
//            }else{
//                return [NSString stringWithFormat:@"%5.2f",returnValue];
//            }
//                 
//        }
    }
    if([[tableView identifier] isEqualToString:@"IMPORTDATATV"])
    {
        if(importDataArray !=0){
            NSString *columnId = [tableColumn identifier];
            int columnNumber = [[columnId substringFromIndex:3] intValue];
            if(columnNumber == 0){
                long dateTime =  (long)[[[importDataArray objectAtIndex:row+1] objectAtIndex:0] longLongValue];
                return [EpochTime stringDateWithTime:dateTime];
            }else{
                return [[importDataArray objectAtIndex:row+1] objectAtIndex:columnNumber];
            }
        }else{
            return 0;
        }
    }

    return nil;
}

- (void)tableView:(NSTableView *)tableView setObjectValue:(id) obj forTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    TimeSeriesLine *tsl;
    SeriesPlot *plot;
    //int layerIndex = 0;
    
    if([[tableView identifier] isEqualToString:@"SIMTSTV"]){
        tsl = [simulationTimeSeries objectAtIndex:row];
        plot = simulationResultsPlot;
    }
    
    if([[tableView identifier] isEqualToString:@"SIGTSTV"]){
        tsl = [simulationSignalTimeSeries objectAtIndex:row];
        plot = signalAnalysisPlot;
    }
    
    NSString *column = [tableColumn identifier];
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
        [tsl setValue:obj forKey:column];
    }
    [plot plotLineUpdated];
    [tableView reloadData];
}

-(void)clearTSTableView:(NSTableView *)tableView
{
    if([[tableView identifier] isEqualToString:@"SIMTSTV"]){
        [simulationTimeSeries removeAllObjects];
        [simulationTimeSeriesTableView reloadData];
    }
    
    if([[tableView identifier] isEqualToString:@"SIMDATATV"]){
         [simulationTimeSeriesTableView reloadData];
    } 
    
    if([[tableView identifier] isEqualToString:@"SIGTSTV"]){
        [simulationSignalTimeSeries removeAllObjects];
        [simulationSignalTimeSeriesTableView reloadData];
    }

}

-(void)addToTableView:(NSTableView *)tableView TimeSeriesLine: (TimeSeriesLine *)TSLine
{
   if([[tableView identifier] isEqualToString:@"SIMTSTV"]){
        [simulationTimeSeries addObject:TSLine];
    }
    
    if([[tableView identifier] isEqualToString:@"SIGTSTV"]){
        [simulationSignalTimeSeries addObject:TSLine];
    }
    [tableView reloadData];
}

-(void)tableViewSelectionDidChange:(NSNotification *)notification
{
    NSTableView *signalAnalysisTableView = [notification object];
    
    if([[signalAnalysisTableView identifier] isEqualToString:@"SIGANALTV"]){
        NSInteger selectedRow = [signalAnalysisTableView selectedRow];
        if(selectedRow > -1){
            selectedRow = [[signalTableViewOrdering objectAtIndex:selectedRow] intValue];
            NSDictionary *signalInfo;
            signalInfo = [[simulationController currentSimulation] detailsOfSignalAtIndex:selectedRow];
            int tradingLag = [[simulationController currentSimulation] tradingLag];
            
            long startDateTime = [[signalInfo objectForKey:@"ENTRYTIME"] longValue];
            startDateTime = startDateTime - ([signalAnalysisPlotLeadHours intValue] * 60*60);
            long endDateTime = [[signalInfo objectForKey:@"EXITTIME"] longValue] + 2*tradingLag;
        
            [self plotSignalDataFrom:startDateTime To:endDateTime];
        }
    }
    return;
}

- (void)tableView:(NSTableView *)tableView didClickTableColumn:(NSTableColumn *)tableColumn
{
    
    if([[tableView identifier] isEqualToString:@"SIGTSTV"]){
        if([[tableColumn identifier] isEqualToString:@"plot1"]){
            [signalAnalysisPlot toggleAxisLabelsForLayer:1];
        }
        if([[tableColumn identifier] isEqualToString:@"plot2"]){
            [signalAnalysisPlot toggleAxisLabelsForLayer:2];
        }
        [tableView deselectColumn:[tableView selectedColumn]];
    }
    
    if([[tableView identifier] isEqualToString:@"SIMTSTV"]){
        if([[tableColumn identifier] isEqualToString:@"plot1"]){
            [simulationResultsPlot toggleAxisLabelsForLayer:1];
        }
        if([[tableColumn identifier] isEqualToString:@"plot2"]){
            [simulationResultsPlot toggleAxisLabelsForLayer:2];
        }
        [tableView deselectColumn:[tableView selectedColumn]];
    }
    
    if([[tableView identifier] isEqualToString:@"SIGANALTV"])
    {
        int numberOfData = [[simulationController currentSimulation] numberOfSignals];
        [signalTableViewOrdering removeAllObjects];
        
        
        NSDictionary *signalAnalysisDetails; 
        //NSMutableArray *columnData = [[NSMutableArray alloc] initWithCapacity:[tableView numberOfRows]];
        double *columnData = malloc(numberOfData * sizeof(double));
        int *sortOrderIndex = malloc(numberOfData * sizeof(int));
        
        int sortSwitch;
        if ([signalTableViewSortColumn isEqualToString:[tableColumn identifier]])
        {
            sortSwitch = (signalTableViewSortedAscending) ? -1: 1;  
            signalTableViewSortedAscending = !signalTableViewSortedAscending;
        }else{
            sortSwitch = 1;
        }
        signalTableViewSortColumn = [tableColumn identifier];
        if([signalTableViewSortColumn isEqualToString:@"SIGNALGAIN"]){
            for(int i = 0; i < numberOfData;i++){
                signalAnalysisDetails = [[simulationController currentSimulation] detailsOfSignalAtIndex:i];
                int signalSide = [UtilityFunctions signOfDouble:[[signalAnalysisDetails objectForKey:@"SIGNAL"] doubleValue]];
                float priceChange = ([[signalAnalysisDetails objectForKey:@"EXITPRICE"] floatValue] - [[signalAnalysisDetails objectForKey:@"ENTRYPRICE"] floatValue]);
                columnData[i] = sortSwitch * signalSide * priceChange;
                sortOrderIndex[i] = i;
            }
        }else{
            for(int i = 0; i < numberOfData;i++){
                signalAnalysisDetails = [[simulationController currentSimulation] detailsOfSignalAtIndex:i];
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
            [signalTableViewOrdering addObject:[NSNumber numberWithInt:sortOrderIndex[i]]];  
        }
        [tableView reloadData];
        free(columnData);
        free(sortOrderIndex);
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

- (void) readingRecordSetsProgress: (NSNumber *) progressFraction
{
    if([[self delegate] respondsToSelector:@selector(readingRecordSetsProgress:)])
    {
        [[self delegate] readingRecordSetsProgress:progressFraction];
    }else{
        NSLog(@"Delegate does not respond to \'readingRecordSetsProgress:\'");
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
    for(int i =0; i < [hideObjectsOnStartup count];i++){
        [[hideObjectsOnStartup objectAtIndex:i] setHidden:NO];
    }
    if([centreTabView numberOfTabViewItems] == 1){
        [centreTabView addTabViewItem:plotTab];
        [centreTabView addTabViewItem:dataTab];
        [centreTabView addTabViewItem:reportTab];
        [centreTabView addTabViewItem:signalsTab];
    }
    [simulationRunScrollView setFrame:CGRectMake(18.0f, 59.0f, 650.0f, 229.0f)];
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
    return YES;
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
@synthesize aboutSimTradingWindowEndLabel;
@synthesize aboutSimTradingWindowStartLabel;
@synthesize aboutSimParametersLabel;
@synthesize aboutSimTradingLagLabel;
@synthesize aboutSimSamplingRateLabel;
@synthesize aboutSimEndTimeLabel;
@synthesize aboutSimStartTimeLabel;
@synthesize aboutAccountCurrencyLabel;
@synthesize aboutTradingPairLabel;
@synthesize aboutSimNameLabel;
@synthesize performSimulationProgressBar;
@synthesize dataControllerForUI;
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
@synthesize fxPairsAndDbIds;
@synthesize centreTabView;
@synthesize rightSideTabView;
@synthesize performSimulationStatusLabel;
@synthesize simulationNumbersTableView;
@synthesize simulationMessagesTextView;
@synthesize simulationResultGraphHostingView;
@synthesize simulationTimeSeriesTableView;
@synthesize performSimulationButton;
@synthesize coloursForPlots;
@synthesize simulationRunScrollView;
@synthesize accountCurrencyLabel;
@synthesize samplingRateLabel;
@synthesize descriptionLabel;
@synthesize tradingDayEndLabel;
@synthesize tradingDayStartLabel;
@synthesize tradingLagLabel;
@synthesize endLabel;
@synthesize startLabel;
@synthesize tradingPairLabel;
@synthesize zoomToDatePicker;
@synthesize zoomFromDatePicker;
@end
