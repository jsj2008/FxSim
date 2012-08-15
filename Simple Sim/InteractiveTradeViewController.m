//
//  InteractiveTradeViewController.m
//  Simple Sim
//
//  Created by Martin O'Connor on 19/03/2012.
//  Copyright (c) 2012 OCONNOR RESEARCH. All rights reserved.
//

#import "InteractiveTradeViewController.h"
#import "SeriesPlot.h"
#import "EpochTime.h"
#import "DataSeries.h"
#import "DataView.h"
#import "TimeSeriesLine.h"
#import "SignalStats.h"
#import "UtilityFunctions.h"


#define START_TIME_FOR_ID_PLOT 2

#define FX_PAIR @"FXPAIR"
#define START_TIME @"STARTTIME"
#define END_TIME @"ENDTIME"
#define SAMPLE_SECS @"SAMPLERATE"
#define SAMPLE_SECS_INPUT @"SAMPLERATEASSTRING"
#define STRATEGY_FIELDS @"STRAT_FIELDS"
#define UPDATE_UI @"UPDATE_UI"

@interface InteractiveTradeViewController ()
- (void) setupDataAndPlotsAccordingToParameters:(NSDictionary *) userInput;
- (void) putFieldNamesInCorrectOrdering:(NSMutableArray *) fieldNamesFromData;
- (void) gettingDataIndicatorSwitchOn;
- (void) gettingDataIndicatorSwitchOff;
- (void) updateZoom;
- (void) switchSignalToZoom;
- (void) initialiseSignalTableView;
- (void) updatePlotDescription:(NSDictionary *)userInput;
- (void) resampleDataForZoomPlot:(NSDictionary *) parameters;
- (void) updateZoomPlotWithResampledData;
- (BOOL) writeSignalStatsToFile: (NSURL *) fileNameAndPath;
- (void) enableMainButtons;
- (void) disableMainButtons;
@end

@implementation InteractiveTradeViewController

#pragma mark -
#pragma mark General Methods

-(id)init{
    self = [super initWithNibName:@"InteractiveTrade" bundle:nil];
    if(self){
        [self setTitle:@"Interactive"];
        
        [self setDoThreads:NO];
        doingSetup = NO;
        cancelProcedure = NO;
        initialSetupComplete = YES;
        signalStatsAvailable = NO;
  
        panel1DataController = [[DataController alloc] init];
        panel2DataController = [[DataController alloc] init];
        [panel1DataController setDelegate:self];
        [panel2DataController setDelegate:self];
        
        signalTableViewSortedAscending = YES;
    }
    return self;
}

-(void)awakeFromNib
{
    NSString *selectedFXPair;
    long initialMinDateTime;
    long initialMaxDateTime;
    
    panel1Plot = [[SeriesPlot alloc] initWithIdentifier:@"Panel1"];
    [panel1Plot setHostingView:panel1GraphHostingView];
    [panel1Plot initialGraphAndAddAnnotation:NO];
   
    panel2Plot = [[SeriesPlot alloc] initWithIdentifier:@"Panel2"];
    [panel2Plot setHostingView:panel2GraphHostingView];
    [panel2Plot initialGraphAndAddAnnotation:NO];
    
    panel3Plot = [[SeriesPlot alloc] initWithIdentifier:@"Panel3"];
    [panel3Plot setHostingView:panel3GraphHostingView];
    [panel3Plot initialGraphAndAddAnnotation:NO];
    
    NSTableColumn *panel1ColourColumn =  [panel1TimeSeriesTableView tableColumnWithIdentifier:@"colourId"];
    NSTableColumn *panel2ColourColumn =  [panel2TimeSeriesTableView tableColumnWithIdentifier:@"colourId"];
    NSTableColumn *panel3ColourColumn =  [panel3TimeSeriesTableView tableColumnWithIdentifier:@"colourId"];
    
    NSPopUpButtonCell *panel1ColourDropDownCell = [[NSPopUpButtonCell alloc] init];
    NSPopUpButtonCell *panel2ColourDropDownCell = [[NSPopUpButtonCell alloc] init];
    NSPopUpButtonCell *panel3ColourDropDownCell = [[NSPopUpButtonCell alloc] init];

    
    [panel1ColourDropDownCell setBordered:NO];
    [panel1ColourDropDownCell setEditable:YES];
    [panel2ColourDropDownCell setBordered:NO];
    [panel2ColourDropDownCell setEditable:YES];    
    [panel3ColourDropDownCell setBordered:NO];
    [panel3ColourDropDownCell setEditable:YES]; 
    
    [panel1ColourDropDownCell addItemsWithTitles:coloursForPlots];
    [panel1ColourColumn setDataCell:panel1ColourDropDownCell];
    [panel2ColourDropDownCell addItemsWithTitles:coloursForPlots];
    [panel2ColourColumn setDataCell:panel2ColourDropDownCell];
    [panel3ColourDropDownCell addItemsWithTitles:coloursForPlots];
    [panel3ColourColumn setDataCell:panel3ColourDropDownCell];
    
    [panel1TimeSeriesTableView setDataSource:self];
    [panel2TimeSeriesTableView setDataSource:self];
    [panel3TimeSeriesTableView setDataSource:self];
   
    [panel1TimeSeriesTableView setDelegate:self];
    [panel2TimeSeriesTableView setDelegate:self];
    [panel3TimeSeriesTableView setDelegate:self];

    
    panel1TimeSeries = [[NSMutableArray alloc] init];
    panel2TimeSeries = [[NSMutableArray alloc] init];
    panel3TimeSeries = [[NSMutableArray alloc] init];
    
    NSArray *pairNames = [fxPairsAndDbIds allKeys];
    
    [panel1PairPopUp removeAllItems];
    for (int i = 0; i < [pairNames count];i++) {
        [panel1PairPopUp addItemWithTitle:[pairNames objectAtIndex:i]];
    }
    
    [panel1PairPopUp selectItemAtIndex:0];
    
    selectedFXPair = [[panel1PairPopUp selectedItem] title];
    initialMinDateTime = [panel1DataController getMinDataDateTimeForPair:selectedFXPair];
    initialMaxDateTime = [panel1DataController getMaxDataDateTimeForPair:selectedFXPair];
    
    NSCalendar *gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
    [panel1FromPicker setTimeZone:[NSTimeZone timeZoneWithName:@"GMT"]];
    [panel1FromPicker setCalendar:gregorian];
    
    [panel1ToPicker setTimeZone:[NSTimeZone timeZoneWithName:@"GMT"]];
    [panel1ToPicker setCalendar:gregorian];
    
    [panel1ZoomBoxFromDatePicker setTimeZone:[NSTimeZone timeZoneWithName:@"GMT"]];
    [panel1ZoomBoxFromDatePicker setCalendar:gregorian];
    
    
    [panel1ZoomBoxToDatePicker setTimeZone:[NSTimeZone timeZoneWithName:@"GMT"]];
    [panel1ZoomBoxToDatePicker setCalendar:gregorian];
    
    [panel1FromPicker setMinDate:[NSDate dateWithTimeIntervalSince1970:(NSTimeInterval) initialMinDateTime]];
    [panel1FromPicker setMaxDate:[NSDate dateWithTimeIntervalSince1970:(NSTimeInterval) initialMaxDateTime]];
    [panel1FromPicker setDateValue:[NSDate dateWithTimeIntervalSince1970:(NSTimeInterval) initialMinDateTime]]; 
    
    [panel1ToPicker setMinDate:[NSDate dateWithTimeIntervalSince1970:(NSTimeInterval) initialMinDateTime]];
    [panel1ToPicker setMaxDate:[NSDate dateWithTimeIntervalSince1970:(NSTimeInterval) initialMaxDateTime]];
    [panel1ToPicker setDateValue:[NSDate dateWithTimeIntervalSince1970:(NSTimeInterval) initialMinDateTime+(2*30*24*60*60)]]; 
    
    [panel1FromDayOfWeekLabel setStringValue:[[panel1FromPicker dateValue] descriptionWithCalendarFormat:@"%a" timeZone:[NSTimeZone timeZoneWithName:@"GMT"] locale:nil]]; 
    
    [panel1ToDayOfWeekLabel setStringValue:[[panel1ToPicker dateValue] descriptionWithCalendarFormat:@"%a" timeZone:[NSTimeZone timeZoneWithName:@"GMT"] locale:nil]];  
    
    userInputFormData = [[NSMutableDictionary alloc] init];
        
    int nColumns = 9;
    NSArray *sigTableHeaders = [NSArray arrayWithObjects:@"Entry Time", @"Exit Time", @"Signal", @"Entry Price", @"Exit Price", @"Signal Gain", @"Time Up", @"Potential Loss", @"Potential Gain", nil];
    NSArray *sigTableIds = [NSArray arrayWithObjects:@"ENTRYTIME", @"EXITTIME",@"SIGNAL" , @"ENTRYPRICE", @"EXITPRICE",  @"SIGNAL GAIN", @"UPTIME", @"POTLOSS", @"POTGAIN", nil];
    
    float columnWidths[9] = {120.0, 50.0, 50.0, 75.0, 75.0, 75.0, 70.0, 70.0, 70.0}; 
    
    for (int i = 0; i < nColumns; i++)
    {
        NSTableColumn *newColumn = [[NSTableColumn alloc] initWithIdentifier:[sigTableIds objectAtIndex:i]];
        [newColumn setWidth:columnWidths[i]];
    
        [[newColumn headerCell] setStringValue:[sigTableHeaders objectAtIndex:i]];
        [panel3SignalTableView addTableColumn:newColumn];
    }
    [panel3SignalTableView setDataSource:self];
    [panel3SignalTableView setDelegate:self];
    
    [panel4SampledDataTableView setDataSource:self];
    [panel4ResampledDataTableView setDataSource:self];
    
    hideObjectsOnStartup = [NSArray arrayWithObjects:panel1TimeSeriesScrollView,panel2TimeSeriesScrollView,panel3TimeSeriesScrollView,panel1PairLabel, panel1ToLabel, panel1FromLabel,panel1ExtraFieldsLabel, panel1SamplingRateLabel, fromLabel, toLabel, extraFieldsLabel, samplingRateLabel, panel1ZoomBoxTo, panel1ZoomBoxFromDatePicker, panel1ZoomBoxToDatePicker, panel1ZoomBoxButton, panel1ZoomBox, panel1ZoomBoxFrom, nil];
    
    for(int i =0; i < [hideObjectsOnStartup count];i++){
        [[hideObjectsOnStartup objectAtIndex:i] setHidden:YES];
    }
 
    [centreTabs selectTabViewItemWithIdentifier:@"P1"];
    [rightSideTabView selectTabViewItemWithIdentifier:@"P1"];
    
    int tabIndex;
    tabIndex = [centreTabs indexOfTabViewItemWithIdentifier:@"P4"];
    dataTab = [centreTabs tabViewItemAtIndex:tabIndex];
    [centreTabs removeTabViewItem:dataTab];
    tabIndex = [centreTabs indexOfTabViewItemWithIdentifier:@"P3"];
    signalsTab = [centreTabs tabViewItemAtIndex:tabIndex];
    [centreTabs removeTabViewItem:signalsTab];
    tabIndex = [centreTabs indexOfTabViewItemWithIdentifier:@"P2"];
    zoomTab = [centreTabs tabViewItemAtIndex:tabIndex];
    [centreTabs removeTabViewItem:zoomTab];
    tabIndex = [centreTabs indexOfTabViewItemWithIdentifier:@"P1"];
    mainTab = [centreTabs tabViewItemAtIndex:tabIndex];
    [mainTab setLabel:@"Setup"];    
    
    [centreTabs setDelegate:self];
    [panel1ImportDataTableView setDataSource:self];
    
    initialSetupComplete = NO;
}


-(void)setDelegate:(id)del
{
    delegate = del;
}

-(id)delegate 
{ 
    return delegate;
}

- (BOOL) doThreads
{
    return [self doThreads];
}

- (void) setDoThreads:(BOOL)doThreadedProcedures
{
    doThreads = doThreadedProcedures;
    [panel1DataController setDoThreads:doThreadedProcedures];
    [panel2DataController setDoThreads:doThreadedProcedures];
}

#pragma mark -
#pragma mark IBAction Methods


- (IBAction)panel1PairPopupChange:(id)sender {
    NSString *selectedItem = [[panel1PairPopUp selectedItem] title]; 
    long startDate = 0;
    long endDate = 0;
    
    startDate = [panel1DataController getMinDataDateTimeForPair:selectedItem];
    endDate = [panel1DataController getMaxDataDateTimeForPair:selectedItem];
    
//    [dataAvailabilityFromLabel setStringValue:[[NSDate dateWithTimeIntervalSince1970:(NSTimeInterval) startDate] descriptionWithCalendarFormat:@"%Y-%m-%d" timeZone:[NSTimeZone timeZoneWithName:@"GMT"] locale:nil]];
//    [dataAvailabilityToLabel setStringValue:[[NSDate dateWithTimeIntervalSince1970:(NSTimeInterval) endDate] descriptionWithCalendarFormat:@"%Y-%m-%d" timeZone:[NSTimeZone timeZoneWithName:@"GMT"] locale:nil]];
    
    [panel1FromPicker setMinDate:[NSDate dateWithTimeIntervalSince1970:(NSTimeInterval) startDate]];
    [panel1FromPicker setMaxDate:[NSDate dateWithTimeIntervalSince1970:(NSTimeInterval) endDate]];
   
    [panel1ToPicker setMinDate:[NSDate dateWithTimeIntervalSince1970:(NSTimeInterval) startDate]];
    [panel1ToPicker setMaxDate:[NSDate dateWithTimeIntervalSince1970:(NSTimeInterval) endDate]];
    
    [panel1FromDayOfWeekLabel setStringValue:[[panel1FromPicker dateValue] descriptionWithCalendarFormat:@"%a" timeZone:[NSTimeZone timeZoneWithName:@"GMT"] locale:nil]]; 
    [panel1ToDayOfWeekLabel setStringValue:[[panel1ToPicker dateValue] descriptionWithCalendarFormat:@"%a" timeZone:[NSTimeZone timeZoneWithName:@"GMT"] locale:nil]]; 
    
}

- (IBAction)panel1FromDateChange:(id)sender {
    [panel1FromDayOfWeekLabel setStringValue:[[panel1FromPicker  dateValue] descriptionWithCalendarFormat:@"%a" timeZone:[NSTimeZone timeZoneWithName:@"GMT"] locale:nil]];
}

- (IBAction)panel1ToDateChange:(id)sender {
    [panel1ToDayOfWeekLabel setStringValue:[[panel1ToPicker  dateValue] descriptionWithCalendarFormat:@"%a" timeZone:[NSTimeZone timeZoneWithName:@"GMT"] locale:nil]];
}

- (IBAction)panel2ResampleButtonPress:(id)sender {
    [self resamplePanel2Plot];
}

- (IBAction)panel1SetupButtonPress:(id)sender {
    //Not yet, this is to show cancel that the setup button has been pressed
    doingSetup = NO;
    
    [panel1PlotButton setEnabled:YES];
    [panel1SetupButton setEnabled:NO];
    [self disableMainButtons];
    for(int i =0; i < [hideObjectsOnStartup count];i++){
        [[hideObjectsOnStartup objectAtIndex:i] setHidden:YES];
    }
    
    [NSApp beginSheet:setupSheet modalForWindow:[centreTabs window] modalDelegate:nil didEndSelector:NULL contextInfo:NULL];
}

- (IBAction)panel1CancelSetupPress:(id)sender {
    cancelProcedure = YES;
    if(doingSetup == NO){
        [self endSetupSheet];
    }
    
}

- (IBAction)panel1ZoomPress:(id)sender {
    long zoomStartDateTime, zoomEndDateTime;
    zoomStartDateTime = [[panel1ZoomBoxFromDatePicker dateValue] timeIntervalSince1970];
    zoomEndDateTime = [[panel1ZoomBoxToDatePicker dateValue] timeIntervalSince1970];
    
    [panel1Plot setZoomDataViewFrom:zoomStartDateTime To:zoomEndDateTime];
    
}

- (IBAction)exportSignalDataPress:(id)sender {
    // Create a File Save Dialog class.
    BOOL allOk;
    NSString *suggestedFileName;
    NSSavePanel *saveDlg = [NSSavePanel savePanel];
    suggestedFileName = @"signals";
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
        allOk = [self writeSignalStatsToFile:fileToSaveTo];
        if(!allOk){
            NSMutableDictionary *alertInfo = [[NSMutableDictionary alloc] init];
            [alertInfo setValue: @"Problem exporting the data" forKey:@"TITLE"];
            [alertInfo setValue: @"It didn't work, not sure why" forKey:@"MSGFORMAT"];
            [alertInfo setValue: @"OK" forKey:@"DEFAULTBUTTON"];
            [self showAlertPanelWithInfo:alertInfo];
        }
    }
   
}

- (IBAction)exportSampledDataPress:(id)sender {
    // Create a File Save Dialog class.
    BOOL allOk;
    NSString *userMessage;
    
    NSString *suggestedFileName;
    NSSavePanel *saveDlg = [NSSavePanel savePanel];
    DataSeries *dataToExport = [panel1DataController dataSeries];
    if(dataToExport){
        if([dataToExport length] > 0){
        suggestedFileName = [NSString stringWithFormat:@"%@data",[dataToExport name]];
        [saveDlg setNameFieldStringValue:suggestedFileName];                     
        // Set array of file types
        NSArray *fileTypesArray;
        fileTypesArray = [NSArray arrayWithObjects:@"csv", nil];
    
        // Enable options in the dialog.
        [saveDlg setAllowedFileTypes:fileTypesArray];
        
        // Display the dialog box.  If the OK pressed,
        // process the files.
    
        if ( [saveDlg runModal] == NSOKButton ) {
            // Gets list of all files selected
            NSURL *fileToSaveTo = [saveDlg URL];
            allOk = [dataToExport writeDataSeriesToFile:fileToSaveTo];
            if(!allOk){
                userMessage = @"Problem trying to write data to file";
            }
        }
        }else {
            allOk = NO;
            userMessage = @"Data source is of length 0, giving up";
        }
    }else{
        allOk = NO;
        userMessage = @"Data source does not seem to be initialialised";
    }
    
    if(!allOk){
        NSMutableDictionary *alertInfo = [[NSMutableDictionary alloc] init];
        [alertInfo setValue: @"Problem exporting the data" forKey:@"TITLE"];
        [alertInfo setValue: userMessage forKey:@"MSGFORMAT"];
        [alertInfo setValue: @"OK" forKey:@"DEFAULTBUTTON"];
        [self showAlertPanelWithInfo:alertInfo];
    }
}

- (IBAction)exportZoomResampledDataPress:(id)sender {
    // Create a File Save Dialog class.
    BOOL allOk;
    NSString *userMessage;
    
    NSString *suggestedFileName;
    NSSavePanel *saveDlg = [NSSavePanel savePanel];
    DataSeries *dataToExport = [panel2DataController dataSeries];
    if(dataToExport){
        if([dataToExport length] > 0){
            suggestedFileName = [NSString stringWithFormat:@"%@dataFromZoom",[dataToExport name]];
            [saveDlg setNameFieldStringValue:suggestedFileName];                     
            // Set array of file types
            NSArray *fileTypesArray;
            fileTypesArray = [NSArray arrayWithObjects:@"csv", nil];
            
            // Enable options in the dialog.
            [saveDlg setAllowedFileTypes:fileTypesArray];
            
            // Display the dialog box.  If the OK pressed,
            // process the files.
            
            if ( [saveDlg runModal] == NSOKButton ) {
                // Gets list of all files selected
                NSURL *fileToSaveTo = [saveDlg URL];
                allOk = [dataToExport writeDataSeriesToFile:fileToSaveTo];
                if(!allOk){
                    userMessage = @"Problem trying to write data to file";
                }
            }
        }else {
            allOk = NO;
            userMessage = @"Data source is of length 0, giving up";
        }
    }else{
        allOk = NO;
        userMessage = @"Data source does not seem to be initialialised";
    }
    
    if(!allOk){
        NSMutableDictionary *alertInfo = [[NSMutableDictionary alloc] init];
        [alertInfo setValue: @"Problem setting up the data" forKey:@"TITLE"];
        [alertInfo setValue: @"Extra fields not understood" forKey:@"MSGFORMAT"];
        [alertInfo setValue: @"OK" forKey:@"DEFAULTBUTTON"];
        if(doThreads){
            [self performSelectorOnMainThread:@selector(showAlertPanelWithInfo:) withObject:alertInfo waitUntilDone:YES];
        }else{
            [self showAlertPanelWithInfo:alertInfo];
        }
    }
}

- (IBAction)sendSignalRangeToZoom:(id)sender {
    
    NSInteger selectedRow = [signalAnalysisTableView selectedRow];
    if(selectedRow > -1){
        selectedRow = [[signalTableViewOrdering objectAtIndex:selectedRow] intValue];
        SignalStats *signalStats;
        signalStats = [[panel1DataController signalStats] objectAtIndex:selectedRow];
        
        long startDateTime = [signalStats getStartDateTime];
        startDateTime = startDateTime - ([panel3SignalPlotLeadTimeTextField intValue] * 60 * 60);
        long endDateTime = [signalStats getEndDateTime];
        [panel1Plot setZoomDataViewFrom:startDateTime To:endDateTime];
    }
}

- (IBAction)panel2DataMovePress:(id)sender {
    
    [panel2DataMoveButton setEnabled:NO];
    DataSeries *plotCurrentData = [panel2Plot plotData];
    DataView *plotCurrentDataView = [panel2Plot dataView]; 
    long startDateTime, endDateTime;
    startDateTime = [plotCurrentDataView minDateTime];
    endDateTime = [plotCurrentDataView maxDateTime];
    
    int dataMoveAmount = [panel2DataMoveAmount intValue];
    if([panel2DataMoveUnits selectedColumn] == 0){
        dataMoveAmount = dataMoveAmount*60*60*24;
    }
    if([panel2DataMoveUnits selectedColumn] == 1){
        dataMoveAmount = dataMoveAmount*60*60;
    }
    if([panel2DataMoveUnits selectedColumn] == 2){
        dataMoveAmount = dataMoveAmount*60;
    } 
    if([panel2DataMoveType selectedColumn] == 0){
        startDateTime = startDateTime + dataMoveAmount;
        endDateTime = endDateTime + dataMoveAmount;
    }
    if([panel2DataMoveType selectedColumn] == 1){
        endDateTime = endDateTime + dataMoveAmount;
    }
  
    if(plotCurrentData == [panel1DataController dataSeries]){
                [panel2Plot setZoomDataViewFrom:startDateTime To:endDateTime];
        [self updateZoom];
    }
    
    if(plotCurrentData == [panel2DataController dataSeries]){
        long samplingRate = [[panel2DataController dataSeries] sampleRate];
        if([plotCurrentData minDateTime] > startDateTime || [plotCurrentData maxDateTime] < endDateTime){
            NSMutableDictionary *parameters = [[NSMutableDictionary alloc] init];
            [parameters setObject:[NSNumber numberWithLong:startDateTime] forKey:START_TIME];
            [parameters setObject:[NSNumber numberWithLong:endDateTime] forKey:END_TIME];
            [parameters setObject:[NSNumber numberWithLong:samplingRate] forKey:SAMPLE_SECS];
            
            if(doThreads){
                [parameters setObject:[NSNumber numberWithBool:YES ] forKey:UPDATE_UI];
                [self performSelectorInBackground:@selector(resampleDataForZoomPlot:) withObject:parameters];
            }else{
                [parameters setObject:[NSNumber numberWithBool:NO ] forKey:UPDATE_UI];
                [self resampleDataForZoomPlot:parameters];
            }
        }
    }
    
}

- (IBAction)signalAnalysisPlotReload:(id)sender {
    NSInteger selectedRow = [signalAnalysisTableView selectedRow];
    if(selectedRow > -1){
        selectedRow = [[signalTableViewOrdering objectAtIndex:selectedRow] intValue];
        SignalStats *signalStats;
        signalStats = [[panel1DataController signalStats] objectAtIndex:selectedRow];
        
        long startDateTime = [signalStats getStartDateTime];
        startDateTime = startDateTime - ([panel3SignalPlotLeadTimeTextField intValue] * 60 * 60);
        long endDateTime = [signalStats getEndDateTime];
        [self plotSignalDataFrom:startDateTime To:endDateTime];
    }
}



- (IBAction)panel1PlotButtonPress:(id)sender {
    BOOL inputOk = YES;
    NSString *userMessage;
    
    if([[sender window] makeFirstResponder:[sender window]]){
        //Try end editing this way
    }else{
        [[sender window] endEditingFor:nil];   
    }

    [panel1PlotButton setEnabled:NO];
    
    NSString *selectedPair = [[panel1PairPopUp selectedItem] title];
    NSDate *startDate = [panel1FromPicker  dateValue];
    NSDate *endDate = [panel1ToPicker dateValue];
    NSString *extraFields = [panel1StrategyField stringValue];
    NSString *samplingRateAsString =  [panel1SamplingRateField stringValue];
    long samplingRate = (long)[panel1SamplingRateField intValue]; 
    
    if(samplingRate <= 0){
        inputOk = NO;
        userMessage = @"Something wrong with sampling rate"; 
    }
    
    //Unit is hours
    if([panel1SamplingUnitRadio selectedColumn] == 0){
        samplingRate = samplingRate * 60 * 60;
        samplingRateAsString = [NSString stringWithFormat:@"%@ %@",samplingRateAsString,@"H"];
    }
    //Unit is minutes
    if([panel1SamplingUnitRadio selectedColumn] == 1){
        samplingRate = samplingRate * 60;
        samplingRateAsString = [NSString stringWithFormat:@"%@ %@",samplingRateAsString,@"M"];
    }
    //Unit is seconds
    if([panel1SamplingUnitRadio selectedColumn] == 1){
        samplingRateAsString = [NSString stringWithFormat:@"%@ %@",samplingRateAsString,@"S"];
    }
    
    long startDateTime = [EpochTime epochTimeAtZeroHour:[startDate timeIntervalSince1970]];
    long endDateTime = [EpochTime epochTimeNextDayAtZeroHour:[endDate timeIntervalSince1970]];
    
    
    if((endDateTime - startDateTime) < (24*60*60)){
        inputOk = NO;
        if((endDateTime - startDateTime)<0){
            userMessage = @"Start date should be before end date";
        }else{
            userMessage = @"Dates should be at least 1 day apart";
        }
    }
    
    if(inputOk){
        userInputFormData = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                            selectedPair,FX_PAIR,
                             [NSNumber numberWithLong:startDateTime],START_TIME,
                             [NSNumber numberWithLong:endDateTime],END_TIME,
                             [NSNumber numberWithLong:samplingRate], SAMPLE_SECS,
                             samplingRateAsString, SAMPLE_SECS_INPUT,
                             extraFields, STRATEGY_FIELDS,
                             nil];
        
        if(importDataArray == nil){
            [userInputFormData setObject:[NSNumber numberWithBool:NO] 
                           forKey:@"USERDATAGIVEN"];
            [userInputFormData setObject:[NSNull null] 
                                  forKey:@"USERDATA"];
            [userInputFormData setObject:[NSNull null]  
                                  forKey:@"USERDATAFILE"];
        }else{
            [userInputFormData setObject:[NSNumber numberWithBool:YES] 
                           forKey:@"USERDATAGIVEN"];
            [userInputFormData setObject:importDataArray 
                           forKey:@"USERDATA"];
            [userInputFormData setObject:importDataFilename 
                           forKey:@"USERDATAFILE"];
        }

        if(doThreads){
            [self performSelectorInBackground:@selector(setupDataAndPlotsAccordingToParameters:) 
                                   withObject:userInputFormData];
        }else{
                [self setupDataAndPlotsAccordingToParameters:userInputFormData];
        }
        
    }else{
        NSRunAlertPanel(@"Bad Parameters", userMessage, @"OK", nil, nil);
        [panel1PlotButton setEnabled:YES];
    }
}

- (IBAction)panel1ImportDataPress:(id)sender {
    NSArray *importedData;
    NSArray *fileTypesArray;
    
    if([[panel1ImportDataButton title] isEqualToString:@"Import Data"]){
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
                [panel1ImportDataScrollView setHidden:NO];
                NSArray *tableColumns;
                tableColumns = [panel1ImportDataTableView tableColumns];
                //int numberOfColumns = [tableColumns count];
                while([tableColumns count] > 0)
                {
                    [panel1ImportDataTableView removeTableColumn:[tableColumns objectAtIndex:0]];
                    tableColumns = [panel1ImportDataTableView tableColumns];
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
                    [panel1ImportDataTableView addTableColumn:newTableColumn];
                }
                [panel1ImportDataTableView widthAdjustLimit];
                [panel1ImportDataTableView reloadData];
                [panel1ImportDataButton setTitle:@"Remove Data"];
            }else{
                importDataArray = nil;
                importDataFilename = nil;
                [panel1ImportDataScrollView setHidden:YES];
                [panel1ImportDataButton setTitle:@"Import Data"];
            }
        }else{
            importDataArray = nil;
            importDataFilename = nil;
            [panel1ImportDataScrollView setHidden:YES];
            [panel1ImportDataButton setTitle:@"Import Data"];
        }
    }else{
        importDataArray = nil;
        importDataFilename = nil;
        [panel1ImportDataScrollView setHidden:YES];
        [panel1ImportDataButton setTitle:@"Import Data"];
    }
}

#pragma mark -
#pragma mark Other Methods

-(NSArray *)csvDataFromURL:(NSURL *)absoluteURL{
    
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

- (void) viewChosenFromMainMenu
{
    if(!initialSetupComplete){
        //Not yet, this is to show cancel that the setup button has been pressed
        doingSetup = NO;
        [self disableMainButtons];
        [panel1SetupButton setHidden:YES];
        
        [NSApp beginSheet:setupSheet modalForWindow:[centreTabs window] modalDelegate:nil didEndSelector:NULL contextInfo:NULL];
    }
}

-(void)endSetupSheet
{
    if(cancelProcedure == NO)
    {
        [NSApp endSheet:setupSheet returnCode: NSOKButton];
    }else{
        [NSApp endSheet:setupSheet returnCode: NSCancelButton];
    }
    if(initialSetupComplete){
        for(int i =0; i < [hideObjectsOnStartup count];i++){
            [[hideObjectsOnStartup objectAtIndex:i] setHidden:NO];
        }
    }
    [setupSheet orderOut:nil];
    [panel1SetupButton setEnabled:YES];
    [panel1SetupButton setHidden:NO];
    [self enableMainButtons];
}

-(void)updateZoom{
    BOOL zoomDataViewFound = NO;
    BOOL needToUpdate = YES;
    DataSeries *panel1PlotData = [panel1Plot plotData];
    DataSeries *panel2PlotData = [panel2Plot plotData];
    DataView *panel1ZoomView;
    DataView *panel2AllView;
    long minZoomDateTime, maxZoomDateTime;
    
    panel2AllView = [[panel2PlotData dataViews] objectForKey:@"ALL"];
    
    zoomDataViewFound = [[panel1PlotData dataViews] objectForKey:@"ZOOM"]!=nil;
    if(zoomDataViewFound){
        panel1ZoomView = [[panel1PlotData dataViews] objectForKey:@"ZOOM"];
        minZoomDateTime = [panel1ZoomView minDateTime];
        maxZoomDateTime = [panel1ZoomView maxDateTime];
        
        if((minZoomDateTime == [panel2AllView minDateTime]) && (maxZoomDateTime == [panel2AllView maxDateTime])){
            needToUpdate = NO;
        }
        if(needToUpdate){
            [self clearTSTableView:panel2TimeSeriesTableView];
            
            TimeSeriesLine *panel1Tsl, *panel2Tsl;
            for(int i = 0; i < [panel1TimeSeries count]; i++){
                panel1Tsl = [panel1TimeSeries objectAtIndex:i];
                panel2Tsl =  [[TimeSeriesLine alloc] initWithLayerIndex:[panel1Tsl layerIndex] 
                                                                AndName:[panel1Tsl name] 
                                                              AndColour:[panel1Tsl colour]];
                [self addToTableView:panel2TimeSeriesTableView   TimeSeriesLine:panel2Tsl];
            }
            
            [panel2Plot setData:panel1PlotData WithViewName:@"ZOOM"];
            [panel2Plot renderPlotWithFields:panel2TimeSeries] ;
        }
    }
}

-(void)switchSignalToZoom
{
   
    DataSeries *dataForPanel1Plot = [panel1DataController dataSeries];
    DataView *signalDataView;
    long minDateTime, maxDateTime;
    
    if([[dataForPanel1Plot dataViews] objectForKey:@"SIGNAL"] != 0){
        signalDataView =  [[dataForPanel1Plot dataViews] objectForKey:@"SIGNAL"];   
        minDateTime = [signalDataView minDateTime];
        maxDateTime = [signalDataView maxDateTime];
        
        [self clearTSTableView:panel2TimeSeriesTableView];
            
        TimeSeriesLine *panel2Tsl, *panel3Tsl;
        for(int i = 0; i < [panel1TimeSeries count]; i++){
            panel3Tsl = [panel3TimeSeries objectAtIndex:i];
            panel2Tsl =  [[TimeSeriesLine alloc] initWithLayerIndex:[panel3Tsl layerIndex] 
                                                            AndName:[panel3Tsl name] 
                                                          AndColour:[panel3Tsl colour]];
            [self addToTableView:panel2TimeSeriesTableView   TimeSeriesLine:panel2Tsl];
        }
        
        [dataForPanel1Plot setPlotViewWithName:@"ZOOM" 
                     AndStartDateTime:(long)minDateTime 
                       AndEndDateTime:(long)maxDateTime];
        
        [panel2Plot setData:dataForPanel1Plot WithViewName:@"ZOOM"];
        [panel2Plot renderPlotWithFields:panel2TimeSeries] ;
    }
}


-(void)setupDataAndPlotsAccordingToParameters:(NSDictionary *)userInput
{
    BOOL success = YES;
    NSString *selectedPair = [userInput objectForKey:FX_PAIR];
    long startDateTime = [[userInput objectForKey:START_TIME] longValue];
    long endDateTime = [[userInput objectForKey:END_TIME] longValue];
    long samplingRate = [[userInput objectForKey:SAMPLE_SECS] longValue];
    NSString *extraFields = [userInput objectForKey:STRATEGY_FIELDS];
    BOOL userDataGiven = [[userInput objectForKey:@"USERDATAGIVEN"] boolValue];
    NSArray *userData = [userInput objectForKey:@"USERDATA"];
    NSString *userDataFilename = [userInput objectForKey:@"USERDATAFILE"];
    
    
    //DataSeries *dataForPanel1Plot;
    
    if(![extraFields isEqualToString:@""]){
        success = [panel1DataController strategyUnderstood:extraFields];
        if(!success){
            NSMutableDictionary *alertInfo = [[NSMutableDictionary alloc] init];
            [alertInfo setValue: @"Problem setting up the data" forKey:@"TITLE"];
            [alertInfo setValue: @"Extra fields not understood" forKey:@"MSGFORMAT"];
            [alertInfo setValue: @"OK" forKey:@"DEFAULTBUTTON"];
            if(doThreads){
                [self performSelectorOnMainThread:@selector(showAlertPanelWithInfo:) withObject:alertInfo waitUntilDone:YES];
            }else{
                [self showAlertPanelWithInfo:alertInfo];
            }
        }
    }
    
    if(success){
        if(doThreads){
            [self performSelectorOnMainThread:@selector(gettingDataIndicatorSwitchOn) withObject:nil waitUntilDone:NO];
            currentProgressIndicator = panel1ProgressBar;
            [self performSelectorOnMainThread:@selector(progressBarOn) withObject:nil waitUntilDone:YES];
        }
        success = [panel1DataController setupDataSeriesForName:selectedPair 
                                         AndStrategy:extraFields];
    }
    
    if(success){
        [panel1DataController setSignalStats:nil];
        signalStatsAvailable = NO;

        if(userDataGiven){
            [panel1DataController setData:userData 
                                 FromFile:userDataFilename];
        }
        
        int successAsInt = 1;
        if(doThreads){
            [panel1DataController setDataForStartDateTime: startDateTime 
                                           AndEndDateTime: endDateTime 
                                          AndSamplingRate: samplingRate
                                              WithSuccess:&successAsInt
                                               AndUpdateUI:YES];
        }else{
            [panel1DataController setDataForStartDateTime: startDateTime 
                                           AndEndDateTime: endDateTime 
                                          AndSamplingRate: samplingRate
                                              WithSuccess:&successAsInt
                                               AndUpdateUI:NO];
        }
        
        if(successAsInt == 0){
            success = NO;
        }
        
        if(!success){
            NSMutableDictionary *alertInfo = [[NSMutableDictionary alloc] init];
            [alertInfo setValue: @"Problem setting up the data" forKey:@"TITLE"];
            [alertInfo setValue: @"Check your parameters!" forKey:@"MSGFORMAT"];
            [alertInfo setValue: @"OK" forKey:@"DEFAULTBUTTON"];
            if(doThreads){
                [self performSelectorOnMainThread:@selector(showAlertPanelWithInfo:) withObject:alertInfo waitUntilDone:YES];
            }else{
                [self showAlertPanelWithInfo:alertInfo];
            }
        }else{
            
        }
    }
    
    if(doThreads){
        [self performSelectorOnMainThread:@selector(gettingDataIndicatorSwitchOff) withObject:nil waitUntilDone:NO];
        [self performSelectorOnMainThread:@selector(progressBarOff) withObject:nil waitUntilDone:NO];
    }
    
    if(success){
        TimeSeriesLine *tsl;
        NSMutableArray *fieldNames = [[[[panel1DataController dataSeries] yData] allKeys] mutableCopy];
        NSString *lineColour;
        int plotLayerIndex = -1;
        
        [self putFieldNamesInCorrectOrdering:fieldNames];
     
        //Panel 1
        
        [self clearTSTableView:panel1TimeSeriesTableView];
        for(int i = 0; i < [fieldNames count];i++){
            plotLayerIndex = (i==0) ? 0 : -1;
            lineColour = [coloursForPlots objectAtIndex:i%[coloursForPlots count]];
            tsl = [[TimeSeriesLine alloc] initWithLayerIndex:plotLayerIndex 
                                                     AndName:[fieldNames objectAtIndex:i] 
                                                   AndColour:lineColour];
            [self addToTableView:panel1TimeSeriesTableView   TimeSeriesLine:tsl];
        }
        [panel1Plot setData:[panel1DataController dataSeries] WithViewName:@"ALL"];
        [panel1Plot renderPlotWithFields:panel1TimeSeries] ;
        
        //Panel 2
        [self clearTSTableView:panel2TimeSeriesTableView];
        plotLayerIndex = -1;
        for(int i = 0; i < [fieldNames count];i++){
            plotLayerIndex = (i==0) ? 0 : -1;
            lineColour = [coloursForPlots objectAtIndex:i%[coloursForPlots count]];
            tsl = [[TimeSeriesLine alloc] initWithLayerIndex:plotLayerIndex
                                                     AndName:[fieldNames objectAtIndex:i] 
                                                   AndColour:lineColour];
            [self addToTableView:panel2TimeSeriesTableView   TimeSeriesLine:tsl];
        }
        [panel2Plot setData:[panel1DataController dataSeries] WithViewName:@"ALL"];
        [panel2Plot renderPlotWithFields:panel2TimeSeries];
        
        
        //Panel 3
        [self clearTSTableView:panel3TimeSeriesTableView];
        plotLayerIndex = -1;
        for(int i = 0; i < [fieldNames count];i++){
            plotLayerIndex = (i==0) ? 0 : -1;
            lineColour = [coloursForPlots objectAtIndex:i%[coloursForPlots count]];
            tsl = [[TimeSeriesLine alloc] initWithLayerIndex:plotLayerIndex 
                                                     AndName:[fieldNames objectAtIndex:i] 
                                                   AndColour:lineColour];
            [self addToTableView:panel3TimeSeriesTableView   TimeSeriesLine:tsl];
        }

        [panel3Plot setData:[panel1DataController dataSeries] WithViewName:@"ALL"];
        [panel3Plot renderPlotWithFields:panel3TimeSeries] ; 
        
        if([panel1DataController signalStats] != nil){
            signalStatsAvailable = YES;
            [self initialiseSignalTableView];
            
        }
        
        [mainTab setLabel:@"Main Plot"];
        
        if([centreTabs numberOfTabViewItems] == 1){
            [centreTabs addTabViewItem:zoomTab];
            [centreTabs addTabViewItem:dataTab];
        }
        
        if([panel1DataController signalStats] == nil){
            if([centreTabs numberOfTabViewItems] == 4)
            {
                [centreTabs removeTabViewItem:signalsTab];
            }
        }else{
            if([centreTabs numberOfTabViewItems] == 3)
            {
                [centreTabs addTabViewItem:signalsTab];
            }
        }
        
        if(doThreads){
            [self performSelectorOnMainThread:@selector(updatePlotDescription:) withObject:userInput waitUntilDone:NO];
        }
        
        initialSetupComplete = YES;
    }
    [self endSetupSheet];
    
}

-(void)updatePlotDescription:(NSDictionary *)userInput
{
    NSString *selectedPair = [userInput objectForKey:FX_PAIR];
    long startDateTime = [[userInput objectForKey:START_TIME] longValue];
    long endDateTime = [[userInput objectForKey:END_TIME] longValue];
    NSString *samplingRate = [userInput objectForKey:SAMPLE_SECS_INPUT];
    NSString *extraFields = [userInput objectForKey:STRATEGY_FIELDS];
    
    [panel1PairLabel setStringValue:selectedPair];
    [panel2PairLabel setStringValue:selectedPair];
    [panel3PairLabel setStringValue:selectedPair];
    [panel4PairLabel setStringValue:selectedPair];
    
    [panel1FromLabel setStringValue:[EpochTime stringDateWithTime:startDateTime]];
    [panel1ToLabel setStringValue:[EpochTime stringDateWithTime:endDateTime]];
    [panel1ExtraFieldsLabel setStringValue:extraFields];
    [panel1SamplingRateLabel setStringValue:samplingRate];
    
    for(int i =0; i < [hideObjectsOnStartup count];i++){
        [[hideObjectsOnStartup objectAtIndex:i] setHidden:NO];
    }
}

-(void)resamplePanel2Plot
{
    BOOL success = YES; 
    DataSeries *plot1Data, *plot2Data;
    DataView *plot1ZoomView;
    
    long minDateTime, maxDateTime;
    long samplingRate;
    
    samplingRate = (long)[panel2SamplingRateField intValue];
    if([panel2SamplingUnitRadio selectedColumn] == 0){
        samplingRate = samplingRate * 60 * 60;
    }
    if([panel2SamplingUnitRadio selectedColumn] == 1){
        samplingRate = samplingRate * 60;
    }
    
    plot1Data = [panel1Plot plotData];
    
    if([[plot1Data dataViews] objectForKey:@"ZOOM"] != 0){
        plot1ZoomView =  [[plot1Data dataViews] objectForKey:@"ZOOM"];   
        minDateTime = [plot1ZoomView minDateTime];
        maxDateTime = [plot1ZoomView maxDateTime];
        
        int dataBaseSuccess;
        
        if(doThreads){
            [self performSelectorOnMainThread:@selector(gettingDataIndicatorSwitchOn) withObject:nil waitUntilDone:YES];
            currentProgressIndicator = panel2ProgressBar;
            [self performSelectorOnMainThread:@selector(progressBarOn) withObject:nil waitUntilDone:YES];
        }
        
        success = [panel2DataController setupDataSeriesForName:[plot1Data name] 
                                                   AndStrategy:[plot1Data strategy]];
        
        if([panel1DataController fileDataAdded])
        {
            [panel2DataController setData:[panel1DataController fileData] 
                                 FromFile:[panel1DataController fileDataFileName]];
        }
        
        if(success){
            if(doThreads){
                [panel2DataController setDataForStartDateTime:minDateTime 
                                               AndEndDateTime:maxDateTime 
                                              AndSamplingRate:samplingRate
                                                  WithSuccess:&dataBaseSuccess
                                                  AndUpdateUI:YES];
            }else{
                [panel2DataController setDataForStartDateTime:minDateTime 
                                                AndEndDateTime:maxDateTime 
                                              AndSamplingRate:samplingRate
                                                  WithSuccess:&dataBaseSuccess
                                                  AndUpdateUI:NO];
            }
            if(dataBaseSuccess == 0){
                success = NO;
            }else{
                plot2Data = [panel2DataController dataSeries];
                
            }
        }
        
        if(doThreads){
            [self performSelectorOnMainThread:@selector(gettingDataIndicatorSwitchOff) withObject:nil waitUntilDone:NO];
            [self performSelectorOnMainThread:@selector(progressBarOff) withObject:nil waitUntilDone:NO];
        }
        
        if(success){
            [panel2Plot setData:plot2Data WithViewName:@"ALL"];
            [panel2Plot renderPlotWithFields:panel2TimeSeries] ;
        }else{
            NSMutableDictionary *alertInfo = [[NSMutableDictionary alloc] init];
            [alertInfo setValue: @"Problem setting up the data" forKey:@"TITLE"];
            [alertInfo setValue: @"Check your parameters!" forKey:@"MSGFORMAT"];
            [alertInfo setValue: @"OK" forKey:@"DEFAULTBUTTON"];
            
            if(doThreads){
                [self performSelectorOnMainThread:@selector(showAlertPanelWithInfo:) withObject:alertInfo waitUntilDone:YES];
            }else{
                [self showAlertPanelWithInfo:alertInfo];
            }
        }
    }
}

-(void)initialiseSignalTableView{
    int numberOfSignals = [[panel1DataController signalStats] count];
    
    signalTableViewOrdering = [[NSMutableArray alloc] initWithCapacity:numberOfSignals];
    
    if(numberOfSignals>0){
        [signalTableViewOrdering removeAllObjects];
        for(int i = 0; i < numberOfSignals; i++){
            [signalTableViewOrdering addObject:[NSNumber numberWithInt:i]];  
        }
        signalTableViewSortColumn = @"ENTRYTIME";
        
        SignalStats *signalInfo;
        signalInfo = [[panel1DataController signalStats] objectAtIndex:0];
        
        long startDateTime = [signalInfo startTime];
        startDateTime = startDateTime - ([panel3SignalPlotLeadTimeTextField intValue] * 60 * 60);
        long endDateTime = [signalInfo endTime];
        
        [self plotSignalDataFrom:startDateTime To:endDateTime];
    }
    
    long minDataTime = [[panel1DataController dataSeries] minDateTime];
    long maxDateTime = [[panel1DataController dataSeries] maxDateTime];
    
    [panel1ZoomBoxFromDatePicker setMinDate:[NSDate dateWithTimeIntervalSince1970:minDataTime]];
    [panel1ZoomBoxFromDatePicker setMaxDate:[NSDate dateWithTimeIntervalSince1970:maxDateTime]];
    [panel1ZoomBoxFromDatePicker setDateValue:[NSDate dateWithTimeIntervalSince1970:minDataTime]];
    [panel1ZoomBoxToDatePicker setMinDate:[NSDate dateWithTimeIntervalSince1970:minDataTime]];
    [panel1ZoomBoxToDatePicker setMaxDate:[NSDate dateWithTimeIntervalSince1970:maxDateTime]];
    [panel1ZoomBoxToDatePicker setDateValue:[NSDate dateWithTimeIntervalSince1970:maxDateTime]];
}

- (void) plotSignalDataFrom: (long) startDateTime To:(long) endDateTime 
{
    DataSeries *dataForPanel1Plot = [panel1DataController dataSeries];
    [dataForPanel1Plot setPlotViewWithName:@"SIGNAL" AndStartDateTime:startDateTime AndEndDateTime:endDateTime];
    
    [panel3Plot setData:[panel1DataController dataSeries] WithViewName:@"SIGNAL"];
    [panel3Plot renderPlotWithFields:panel3TimeSeries] ; 
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

-(BOOL)writeSignalStatsToFile: (NSURL *) fileNameAndPath
{
    BOOL allOk = YES;
    NSFileHandle *outFile;
    NSArray *signalStatsArray = [panel1DataController signalStats];
    SignalStats *signalStats;
    
    if(signalStatsArray){
        // Create the output file first if necessary
        // Need to remove file: //localhost for some reason
        NSString *filePathString = [fileNameAndPath path];//[[fileNameAndPath absoluteString] substringFromIndex:16];
        allOk = [[NSFileManager defaultManager] createFileAtPath: filePathString
                                                        contents: nil 
                                                      attributes: nil];
        //[fileNameAndPath absoluteString]
        if(allOk){
            outFile = [NSFileHandle fileHandleForWritingAtPath:filePathString];
            [outFile truncateFileAtOffset:0];
            NSString *lineOfDataAsString;
            lineOfDataAsString = @"StartTime, endTime, Signal, entryPrice, exitPrice, samplesInProfit, totalSamples, maxPrice, minPrice \r\n"; 
            [outFile writeData:[lineOfDataAsString dataUsingEncoding:NSUTF8StringEncoding]];

            for(int i = 0;i < [signalStatsArray count] ; i++)
            {
                signalStats = [signalStatsArray objectAtIndex:i];
                lineOfDataAsString = [NSString stringWithFormat:@"%@, %@, %5.4f, %5.4f, %5.4f, %ld, %ld, %5.4f, %5.4f \r\n",  [EpochTime stringDateWithTime:[signalStats startTime]],[EpochTime stringDateWithTime:[signalStats endTime]], [signalStats signal], [signalStats entryPrice], [signalStats exitPrice], [signalStats samplesInProfit], [signalStats totalSamples], [signalStats maxPrice], [signalStats minPrice]]; 
                [outFile writeData:[lineOfDataAsString dataUsingEncoding:NSUTF8StringEncoding]];
            }
        }else{
            allOk = NO;
        }
    }
    return allOk;
}

-(void)resampleDataForZoomPlot:(NSDictionary *) parameters
{
    long startDateTime = [[parameters objectForKey:START_TIME] longValue];
    long endDateTime  = [[parameters objectForKey:END_TIME] longValue];
    long samplingRate = [[parameters objectForKey:SAMPLE_SECS] longValue];
    BOOL updateUI = [[parameters objectForKey:UPDATE_UI] boolValue];
    int success; 
    [panel2DataController setDataForStartDateTime:startDateTime 
                                   AndEndDateTime:endDateTime 
                                  AndSamplingRate:samplingRate 
                                      WithSuccess:&success 
                                      AndUpdateUI:updateUI];
    [panel2Plot setData:[panel2DataController dataSeries]  WithViewName:@"ALL"];
    if(doThreads){
        [self performSelectorOnMainThread:@selector(updateZoomPlotWithResampledData) withObject:nil waitUntilDone:YES];
    }else{
        [self updateZoomPlotWithResampledData];
    }
}

-(void)updateZoomPlotWithResampledData
{
    
    [panel2Plot renderPlotWithFields:panel2TimeSeries];
    [panel2DataMoveButton setEnabled:YES];
}

#pragma mark -
#pragma mark Delegate Methods

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
#pragma mark TableView Methods

- (void)tableView:(NSTableView *)tableView didClickTableColumn:(NSTableColumn *)tableColumn
{
    //SeriesPlot *plot;
    //NSMutableArray *timeSeries;
    
    if([[tableView identifier] isEqualToString:@"P1TSTV"]){
        if([[tableColumn identifier] isEqualToString:@"plot1"]){
            [panel1Plot toggleAxisLabelsForLayer:1];
        }
        if([[tableColumn identifier] isEqualToString:@"plot2"]){
            [panel1Plot toggleAxisLabelsForLayer:2];
        }
        [tableView deselectColumn:[tableView selectedColumn]];
    }
    
    if([[tableView identifier] isEqualToString:@"P2TSTV"]){
        if([[tableColumn identifier] isEqualToString:@"plot1"]){
            [panel2Plot toggleAxisLabelsForLayer:1];
        }
        if([[tableColumn identifier] isEqualToString:@"plot2"]){
            [panel2Plot toggleAxisLabelsForLayer:2];
        }
        [tableView deselectColumn:[tableView selectedColumn]];
    }

    if([[tableView identifier] isEqualToString:@"P3TSTV"]){
        if([[tableColumn identifier] isEqualToString:@"plot1"]){
            [panel3Plot toggleAxisLabelsForLayer:1];
        }
        if([[tableColumn identifier] isEqualToString:@"plot2"]){
            [panel3Plot toggleAxisLabelsForLayer:2];
        }
        [tableView deselectColumn:[tableView selectedColumn]];
    }
    
//    if([[tableColumn identifier] isEqualToString:@"plot0"]){
//        if([[tableView identifier] isEqualToString:@"P1TSTV"]){
//            TimeSeriesLine *tsl;
//            for(tsl in panel1TimeSeries)
//            {
//                [tsl setLayerIndex:-1];
//            }
//            plot = panel1Plot;
//        }
//        if([[tableView identifier] isEqualToString:@"P2TSTV"]){
//            TimeSeriesLine *tsl;
//            for(tsl in panel2TimeSeries)
//            {
//                [tsl setLayerIndex:-1];
//            }
//            //timeSeries = shortTermTimeSeries;
//            plot = panel2Plot;
//        }
//        if([[tableView identifier] isEqualToString:@"P3TSTV"]){
//            TimeSeriesLine *tsl;
//            for(tsl in panel3TimeSeries)
//            {
//                [tsl setLayerIndex:-1];
//            }
//            //timeSeries = shortTermTimeSeries;
//            plot = panel3Plot;
//        }
//        [plot plotLineUpdated];
        
//    }
    
    
    if([[tableView identifier] isEqualToString:@"SIGNALTV"])
    {
        SignalStats *signalStats;
        int numberOfData = [[panel1DataController signalStats] count];
        [signalTableViewOrdering removeAllObjects];

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
        
        for(int i = 0; i < numberOfData;i++){
            signalStats = [[panel1DataController signalStats] objectAtIndex:i];
                //signalAnalysisDetails = [[simulationController currentSimulation] detailsOfSignalAtIndex:i];
               
            columnData[i] = sortSwitch * [signalStats getStatAsDouble:[tableColumn identifier]];
            sortOrderIndex[i] = i;
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

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView{
    if([[tableView identifier] isEqualToString:@"P1TSTV"]){
        return [panel1TimeSeries count]; 
    }
    if([[tableView identifier] isEqualToString:@"P2TSTV"]){
        return [panel2TimeSeries count]; 
    }
    if([[tableView identifier] isEqualToString:@"P3TSTV"]){
        return [panel3TimeSeries count]; 
    }
    if([[tableView identifier] isEqualToString:@"SIGNALTV"]){
        if(signalStatsAvailable){
            if([panel1DataController signalStats] != nil){
                return [[panel1DataController signalStats] count];
            }else{
                NSLog(@"Problem with signal statistics");
            }
        }
    }
    if([[tableView identifier] isEqualToString:@"P1DATATV"]){
        return [[panel1DataController dataSeries] length]; 
    }
    if([[tableView identifier] isEqualToString:@"P2DATATV"]){
        return [[panel2DataController dataSeries] length]; 
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
    
    if([[tableView identifier] isEqualToString:@"P1TSTV"]){
        tsl = [panel1TimeSeries objectAtIndex:row];
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
    if([[tableView identifier] isEqualToString:@"P2TSTV"]){
        tsl = [panel2TimeSeries objectAtIndex:row];
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
    if([[tableView identifier] isEqualToString:@"P3TSTV"]){
        tsl = [panel3TimeSeries objectAtIndex:row];
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
    if([[tableView identifier] isEqualToString:@"SIGNALTV"]){
        if(signalStatsAvailable){
            SignalStats *signalStats;
            int sortedIndex =  [[signalTableViewOrdering objectAtIndex:row] intValue];
            signalStats = [[panel1DataController signalStats] objectAtIndex:sortedIndex];
            return [signalStats getStat:columnId];
        }
    }
    
    if([[tableView identifier] isEqualToString:@"P1DATATV"]){
        DataSeries *p1Series = [panel1DataController dataSeries];
        if([columnId isEqualToString:@"DATETIME"]){
            return [EpochTime stringDateWithTime:[[p1Series getDateTimeAtIndex:row] longValue]];
        }else{
            return [p1Series getDataFor:columnId AtIndex:row];            
        }
    }
    
    if([[tableView identifier] isEqualToString:@"P2DATATV"]){
        DataSeries *p2Series = [panel2DataController dataSeries];
        if([columnId isEqualToString:@"DATETIME"]){
            return [EpochTime stringDateWithTime:[[p2Series getDateTimeAtIndex:row] longValue]];
        }else{
            return [p2Series getDataFor:columnId AtIndex:row];            
        }
    }
    if([[tableView identifier] isEqualToString:@"IMPORTDATATV"])
    {
        if(importDataArray !=0){
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
    if([[tableView identifier] isEqualToString:@"P1TSTV"]){
        tsl = [panel1TimeSeries objectAtIndex:row];
        plot = panel1Plot;
    }
    if([[tableView identifier] isEqualToString:@"P2TSTV"]){
        tsl = [panel2TimeSeries objectAtIndex:row];
        plot = panel2Plot;
    }
    if([[tableView identifier] isEqualToString:@"P3TSTV"]){
        tsl = [panel3TimeSeries objectAtIndex:row];
        plot = panel3Plot;
    }
    
    //int layerIndex = 0;
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
    }else{
        [tsl setValue:obj forKey:column];
    }
    
    [plot plotLineUpdated];
    [tableView reloadData];
}

- (void) clearTSTableView:(NSTableView *)tableView
{
    if([[tableView identifier] isEqualToString:@"P1TSTV"]){
        [panel1TimeSeries removeAllObjects];
        [panel1TimeSeriesTableView reloadData];
    }
    if([[tableView identifier] isEqualToString:@"P2TSTV"]){
        [panel2TimeSeries removeAllObjects];
        [panel2TimeSeriesTableView reloadData];
    }
    if([[tableView identifier] isEqualToString:@"P3TSTV"]){
        [panel3TimeSeries removeAllObjects];
        [panel3TimeSeriesTableView reloadData];
    }
}

- (void) addToTableView:(NSTableView *)tableView TimeSeriesLine: (TimeSeriesLine *)TSLine
{
    if([[tableView identifier] isEqualToString:@"P1TSTV"]){
        [panel1TimeSeries addObject:TSLine];
    }
    if([[tableView identifier] isEqualToString:@"P2TSTV"]){
        [panel2TimeSeries addObject:TSLine];
    }
    if([[tableView identifier] isEqualToString:@"P3TSTV"]){
        [panel3TimeSeries addObject:TSLine];
    }
   [tableView reloadData];
}

-(void)tableViewSelectionDidChange:(NSNotification *)notification
{
    NSTableView *tableView = [notification object];
    if([[tableView identifier] isEqualToString:@"SIGNALTV"]){
        NSInteger selectedRow = [tableView selectedRow];
        if(selectedRow > -1){
            selectedRow = [[signalTableViewOrdering objectAtIndex:selectedRow] intValue];
            SignalStats *signalStats;
            signalStats = [[panel1DataController signalStats] objectAtIndex:selectedRow];
            
            long startDateTime = [signalStats getStartDateTime];
            startDateTime = startDateTime - ([panel3SignalPlotLeadTimeTextField intValue] * 60 * 60);
            long endDateTime = [signalStats getEndDateTime];
            [self plotSignalDataFrom:startDateTime To:endDateTime];
        }
    }
    return;
}

//- (IBAction)intraDayMoveForwardButtonPress:(id)sender {
//    //long dateStartTimeIntraDay; 
//    long dateEndTimeIntraDay;
//    int extendByMinutes;
//    DataView *intraDayDataView;
//    extendByMinutes = [intraDayMoveForwardTextField integerValue]*60;
//    intraDayDataView = [[[dataController dataSeries] dataViews] objectForKey:@"IntraDay"];
//    
//    //dateStartTimeIntraDay = [EpochTime epochTimeAtZeroHour:[currentDay timeIntervalSince1970]];
//    dateEndTimeIntraDay = [intraDayDataView lastX] + extendByMinutes;
//    [[dataController dataSeries]  setPlotViewWithName: @"IntraDay" AndStartDateTime: [intraDayDataView firstX] AndEndDateTime: dateEndTimeIntraDay];
//    [panel2Plot setData:[dataController dataSeries] WithViewName:@"IntraDay"];
//    [panel2Plot renderPlotWithFields:intraDayTimeSeries];
//    [intraDayDateTimeLabel setStringValue:[EpochTime stringOfDateTimeForTime:dateEndTimeIntraDay WithFormat:@"%Y%m%d %H:%M:%S"]];
//    
//}

#pragma mark -
#pragma mark Interface Update Methods

//-(void) setProgressMinAndMax: (NSArray *) minAndMax 
//{
//    
//    [currentProgressIndicator setMinValue:[[minAndMax objectAtIndex:0] doubleValue]];
//    [currentProgressIndicator setMaxValue:[[minAndMax objectAtIndex:1] doubleValue]];
//}  

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


-(void)gettingDataIndicatorSwitchOn
{
    if([[self delegate] respondsToSelector:@selector(gettingDataIndicatorSwitchOn)])
    {
        [[self delegate] gettingDataIndicatorSwitchOn];
    }else{
        NSLog(@"Delegate does not respond to \'gettingDataIndicatorSwitchOn\'");
    }
}

-(void)gettingDataIndicatorSwitchOff
{
    if([[self delegate] respondsToSelector:@selector(gettingDataIndicatorSwitchOff)])
    {
        [[self delegate] gettingDataIndicatorSwitchOff];
    }else{
        NSLog(@"Delegate does not respond to \'gettingDataIndicatorSwitchOff\'");
    }
}

-(void)readingRecordSetsProgress: (NSNumber *) progressFraction
{
    if([[self delegate] respondsToSelector:@selector(readingRecordSetsProgress:)])
    {
        [[self delegate] readingRecordSetsProgress:progressFraction];
    }else{
        NSLog(@"Delegate does not respond to \'readingRecordSetsProgress:\'");
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
    if([[[tabView selectedTabViewItem] identifier] isEqualToString:@"P1"] && [[tabViewItem identifier] isEqualToString:@"P2"]){
        [self updateZoom];
    }
    if([[[tabView selectedTabViewItem] identifier] isEqualToString:@"P3"] && [[tabViewItem identifier] isEqualToString:@"P2"]){
        [self switchSignalToZoom];
    }
    return YES;
}

#pragma mark -
#pragma mark Properties

@synthesize panel1PlotButton;
@synthesize panel1SetupButton;
@synthesize panel1ImportDataTableView;
@synthesize panel1ImportDataScrollView;
@synthesize panel1ImportDataButton;
@synthesize panel3TimeSeriesTableView;
@synthesize panel1ProgressBar;
@synthesize panel2ProgressBar;
@synthesize panel3SignalTableView;
@synthesize panel3GraphHostingView;
@synthesize panel1ToDayOfWeekLabel;
@synthesize panel1FromDayOfWeekLabel;
@synthesize panel2SamplingUnitRadio;
@synthesize panel2SamplingRateField;
@synthesize panel2TimeSeriesTableView;
@synthesize panel2TimeSeriesScrollView;
@synthesize panel1TimeSeriesScrollView;
@synthesize panel1TimeSeriesTableView;
@synthesize panel1StrategyField;
@synthesize panel1SamplingUnitRadio;
@synthesize panel1SamplingRateField;
@synthesize panel1ToPicker;
@synthesize panel1FromPicker;
@synthesize panel1PairLabel;
@synthesize panel1PairPopUp;
@synthesize fxPairsAndDbIds;
@synthesize rightSideTabView;
@synthesize centreTabs;
@synthesize panel1TimeSeries;
@synthesize panel2TimeSeries;
@synthesize panel3TimeSeries;
@synthesize panel1GraphHostingView;
@synthesize panel2GraphHostingView;
@synthesize coloursForPlots;
@synthesize samplingRateLabel;
@synthesize extraFieldsLabel;
@synthesize toLabel;
@synthesize fromLabel;
@synthesize panel3TimeSeriesScrollView;
@synthesize panel1SamplingRateLabel;
@synthesize panel1ExtraFieldsLabel;
@synthesize panel1ToLabel;
@synthesize panel1FromLabel;
@synthesize panel1SetupCancelButton;
@synthesize panel3SignalPlotLeadTimeTextField;
@synthesize panel1ZoomBoxButton;
@synthesize panel1ZoomBoxToDatePicker;
@synthesize panel1ZoomBoxFromDatePicker;
@synthesize panel1ZoomBoxTo;
@synthesize panel1ZoomBoxFrom;
@synthesize panel1ZoomBox;
@synthesize panel4ResampledDataTableView;
@synthesize panel4SampledDataTableView;
@synthesize signalAnalysisTableView;
@synthesize panel4PairLabel;
@synthesize panel3PairLabel;
@synthesize panel2PairLabel;
@synthesize panel2DataMoveType;
@synthesize panel2DataMoveButton;
@synthesize panel2DataMoveAmount;
@synthesize panel2DataMoveUnits;
@end