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
#import "TimeSeriesLine.h"
#import "EpochTime.h"
#import "UtilityFunctions.h"

#define DAY_SECONDS 24*60*60

@interface SimulationViewController ()
-(NSArray *)getFieldNamesInCorrectOrdering:(NSArray *) fieldNamesFromData;
-(void)endSetupSheet;
-(void)updateStatus:(NSString *) statusMessage;
@end

@implementation SimulationViewController
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
@synthesize doThreads;
@synthesize coloursForPlots;
@synthesize fieldNameOrdering;

NSMutableArray *signalTableViewOrdering;
BOOL signalTableViewSortedAscending = YES;
NSString *signalTableViewSortColumn;


- (id)init{
    self = [super initWithNibName:@"SimulationView" bundle:nil];
    if(self){
        [self setTitle:@"Simulation"];
        [self setDoThreads:NO];
        
        doingSetup = NO;
        cancelProcedure = NO;
        initialSetupComplete = NO;    
        [self setDoThreads:NO];
        simulationTimeSeries = [[NSMutableArray alloc] init];
        simulationSignalTimeSeries = [[NSMutableArray alloc] init]; 
        signalTableViewOrdering = [[NSMutableArray alloc] init];

    }
    return self;
}

- (IBAction)plotLeftSideContract:(id)sender {
    [simulationResultsPlot leftSideContract];
}

- (IBAction)plotBottomExpand:(id)sender {
    [simulationResultsPlot bottomExpand];
}

- (IBAction)plotBottomContract:(id)sender {
    [simulationResultsPlot bottomContract];
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

//-(BOOL)makeSimReport: (NSURL *) fileNameAndPath
//{
//    //    NSPrintInfo *pdfDisplayInfo = [[NSPrintInfo alloc] initWithDictionary:[NSDictionary dictionaryWithObjectsAndKeys:@"YES",NSPrintHeaderAndFooter,nil]];
//    //    [pdfDisplayInfo setVerticalPagination:NSAutoPagination];
//    //    [pdfDisplayInfo setHorizontalPagination:NSAutoPagination];
//    //    [pdfDisplayInfo setVerticallyCentered:NO];
//    //    NSFileManager *filemanager = [NSFileManager defaultManager];
//    //    NSMutableData *dataObtained = [[NSMutableData alloc] init];
//    //    NSPrintOperation *printOperation = [NSPrintOperation PDFOperationWithView: insideRect:[contentView frame] toData:dataObtained printInfo:pdfDisplayInfo];
//    //    [printOperation runOperation];
//    //    [filemanager createFileAtPath:[@"~/Documents/SamplePrint.pdf" stringByExpandingTildeInPath] contents:dataObtained attributes:nil];
//    
//    
//    
//    NSPrintInfo *printInfo;
//    NSPrintInfo *sharedInfo;
//    NSPrintOperation *printOp;
//    NSMutableDictionary *printInfoDict;
//    NSMutableDictionary *sharedDict;
//    
//    sharedInfo = [NSPrintInfo sharedPrintInfo];
//    sharedDict = [sharedInfo dictionary];
//    printInfoDict = [NSMutableDictionary dictionaryWithDictionary:
//                     sharedDict];
//    
//    [printInfoDict setObject:NSPrintSaveJob 
//                      forKey:NSPrintJobDisposition];
//    [printInfoDict setObject:@"~/Documents/SamplePrint.pdf" forKey:NSPrintSavePath];
//    
//    
//    printInfo = [[NSPrintInfo alloc] initWithDictionary: printInfoDict];
//    [printInfo setHorizontalPagination: NSAutoPagination];
//    [printInfo setVerticalPagination: NSAutoPagination];
//    [printInfo setVerticallyCentered:NO];
//    
//    printOp = [NSPrintOperation printOperationWithView:reportTableView 
//                                             printInfo:printInfo];
//    [printOp setShowsProgressPanel:YES];
//    [printOp setShowsPrintPanel:NO];
//    [printOp runOperation];
//    
//    
//    return NO;
//}

-(void)setDelegate:(id)del
{
    delegate = del;
}

-(id)delegate 
{ 
    return delegate;
};


-(void)awakeFromNib
{
    
    //dataController = [[DataController alloc] init];
    simulationController = [[SimulationController alloc] init];
    [simulationController setDelegate:self];
    [simulationController setDoThreads:doThreads];
    //[simulationNumbersTableView setDataSource:simulationController];
    
    simulationResultsPlot = [[SeriesPlot alloc] init];
    [simulationResultsPlot setHostingView:simulationResultGraphHostingView];
    [simulationResultsPlot initialGraphAndAddAnnotation:NO];
    
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
    
//    NSMutableArray *listOfCurrencies = [[NSMutableArray alloc] init];
//    for(int i = 0; i < [fxPairs count]; i++){
//        NSString *base =  [[fxPairs objectAtIndex:i] substringToIndex:3];
//        NSString *quote = [[fxPairs objectAtIndex:i] substringFromIndex:3];
//        BOOL baseAdded = NO;
//        BOOL quoteAdded = NO;
//        for( int j= 0; j <[listOfCurrencies count];j++){
//            if([base isEqualToString:[listOfCurrencies objectAtIndex:j]]){
//                baseAdded = YES;
//            }
//            if([quote isEqualToString:[listOfCurrencies objectAtIndex:j]]){
//                quoteAdded = YES;
//            } 
//        }
//        if(!baseAdded){
//            [listOfCurrencies addObject:base];
//        }
//        if(!quoteAdded){
//            [listOfCurrencies addObject:quote];
//        }
//    }
    
//    [setupAccountCurrencyPopup removeAllItems];
//    for(int i = 0; i < [listOfCurrencies count]; i++){
//        [setupAccountCurrencyPopup addItemWithTitle:[listOfCurrencies objectAtIndex:i]];
//    }
    
    [setupTradingPairPopup selectItemAtIndex:0];
    NSString *selectedPair = [[setupTradingPairPopup selectedItem] title];
    [setupAccountCurrencyPopup removeAllItems];
    [setupAccountCurrencyPopup addItemWithTitle:[selectedPair substringFromIndex:3]];
    [setupAccountCurrencyPopup addItemWithTitle:[selectedPair substringToIndex:3]];
    [setupAccountCurrencyPopup selectItemAtIndex:0];
    
    
    
    long minDataDateTime = [dataControllerForUI getMinDateTimeForFullData];
    long maxDataDateTime = [dataControllerForUI getMaxDateTimeForFullData];
    
    [dataAvailabilityFromLabel setStringValue:[[NSDate dateWithTimeIntervalSince1970:(NSTimeInterval) minDataDateTime] descriptionWithCalendarFormat:@"%Y-%m-%d" timeZone:[NSTimeZone timeZoneWithName:@"GMT"] locale:nil]];
    [dataAvailabilityToLabel setStringValue:[[NSDate dateWithTimeIntervalSince1970:(NSTimeInterval) maxDataDateTime] descriptionWithCalendarFormat:@"%Y-%m-%d" timeZone:[NSTimeZone timeZoneWithName:@"GMT"] locale:nil]];
    
    NSCalendar *gregStart = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
    [setupStartTimePicker setTimeZone:[NSTimeZone timeZoneWithName:@"GMT"]];
    [setupStartTimePicker setCalendar:gregStart];

    NSCalendar *gregEnd = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
    [setupEndTimePicker setTimeZone:[NSTimeZone timeZoneWithName:@"GMT"]];
    [setupEndTimePicker setCalendar:gregEnd];

    
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
    [setupTradingStartTimePicker setDateValue:[NSDate dateWithTimeIntervalSince1970:0]];
    [setupTradingEndTimePicker setDateValue:[NSDate dateWithTimeIntervalSince1970:0]];
    
    [centreTabView selectTabViewItemWithIdentifier:@"SETUP"];
    [rightSideTabView selectTabViewItemWithIdentifier:@"SETUP"];
}

- (IBAction)changeSelectedTradingPair:(id)sender {
    NSString *selectedPair = [[setupTradingPairPopup selectedItem] title];
    [setupAccountCurrencyPopup removeAllItems];
    [setupAccountCurrencyPopup addItemWithTitle:[selectedPair substringFromIndex:3]];
    [setupAccountCurrencyPopup addItemWithTitle:[selectedPair substringToIndex:3]];
    [setupAccountCurrencyPopup selectItemAtIndex:0];
}

- (IBAction)showSetupSheet:(id)sender
{
    //Not yet, this is to show cancel that the setup button has been pressed
    doingSetup = NO;
    
    [NSApp beginSheet:setupSheet modalForWindow:[centreTabView window] modalDelegate:nil didEndSelector:NULL contextInfo:NULL];
}
- (IBAction)cancelSetupSheet:(id)sender{
    cancelProcedure = YES;
    if(doingSetup == NO){
        [self endSetupSheet];
    }

}

- (IBAction)cancelSimulation:(id)sender{
    NSString *userMessage = @"Trying to cancel...";
    if(doThreads){
        [self performSelectorInBackground:@selector(updateStatus:) withObject:userMessage];
        [simulationController performSelectorInBackground:@selector(askSimulationToCancel) withObject:nil];

    }else{
        [simulationController askSimulationToCancel];
    }
    [setUpSheetCancelButton setEnabled:NO];
}

-(void)endSetupSheet
{
    if(cancelProcedure == NO)
    {
        [NSApp endSheet:setupSheet returnCode: NSOKButton];
    }else{
        [NSApp endSheet:setupSheet returnCode: NSCancelButton];
    }

    [setupSheet orderOut:nil];
}


- (IBAction)performSimulation:(id)sender {
    [performSimulationButton setEnabled:NO];
    [self clearSimulationMessage];
    
    NSMutableDictionary *parameters = [[NSMutableDictionary alloc] init]; 
    
    //setupSimulationName
//    __weak NSPopUpButton *setupTradingPairPopup;
//    __weak NSPopUpButton *setupAccountCurrencyPopup;
//    __weak NSTextField *setupAccountBalanceTextField;
//    __weak NSDatePicker *setupStartTimePicker;
//    __weak NSDatePicker *setupEndTimePicker;
//    __weak NSTextField *setupParameterTextField;
//    __weak NSTextField *setupMaxLeverageTextField;
//    __weak NSDatePicker *setupTradingStartTimePicker;
//    __weak NSDatePicker *setTradingEndTimePicker;
//    __weak NSTextField *setupSamplingMinutesTextField;

    
    NSString *tradingPair;
    tradingPair = [[setupTradingPairPopup selectedItem] title];
    
    long startDateTime = [[setupStartTimePicker dateValue] timeIntervalSince1970];
    long endDateTime = [[setupEndTimePicker dateValue] timeIntervalSince1970];
    
    long tradingDayStartTime = [[setupTradingStartTimePicker dateValue] timeIntervalSince1970];
    tradingDayStartTime = tradingDayStartTime - [EpochTime epochTimeAtZeroHour:tradingDayStartTime];
    
    long tradingDayEndTime = [[setupTradingEndTimePicker dateValue] timeIntervalSince1970];
    tradingDayEndTime = tradingDayEndTime - [EpochTime epochTimeAtZeroHour:tradingDayEndTime];
    
    if(tradingDayEndTime == 0){
        tradingDayEndTime = DAY_SECONDS - 1;
    }
    
    long tradingStartDateTime = [EpochTime epochTimeAtZeroHour:startDateTime] + tradingDayStartTime;
    long tradingEndDateTime = [EpochTime epochTimeAtZeroHour:endDateTime] + tradingDayEndTime;
    
    [parameters setObject:[setupSimulationName stringValue] forKey:@"SIMNAME"];
    [parameters setObject:[setupParameterTextField stringValue] forKey:@"SIMTYPE"];
    [parameters setObject:[tradingPair substringToIndex:3] forKey:@"BASECODE"];
    [parameters setObject:[tradingPair substringFromIndex:3] forKey:@"QUOTECODE"];
    [parameters setObject:[[setupAccountCurrencyPopup selectedItem] title] forKey:@"ACCOUNTCODE"];
    [parameters setObject:[NSNumber numberWithFloat:[setupAccountBalanceTextField floatValue]] forKey:@"STARTBALANCE"];
    [parameters setObject:[NSNumber numberWithFloat:[setupMaxLeverageTextField floatValue]] forKey:@"MAXLEVERAGE"];
    
    
    
    [parameters setObject:[NSNumber numberWithLong:tradingStartDateTime] forKey:@"STARTTIME"];
    [parameters setObject:[NSNumber numberWithLong:tradingEndDateTime] forKey:@"ENDTIME"];
    //[parameters setObject:[NSNumber numberWithLong:(50*DAY_SECONDS)] forKey:@"SIMLENGTH"];
    [parameters setObject:[NSNumber numberWithInt:[setupSamplingMinutesTextField intValue]*60] forKey:@"TIMESTEP"];
    //[parameters setObject:[NSNumber numberWithLong:20*DAY_SECONDS] forKey:@"DATACHUNK"];
    
    [parameters setObject:[NSNumber numberWithLong:tradingDayStartTime]  forKey:@"TRADINGDAYSTART"];
    [parameters setObject:[NSNumber numberWithLong:tradingDayEndTime] forKey:@"TRADINGDAYEND"];
    
    BOOL weekendTrading = [setupTradingWeekendYesNo state] == NSOnState;
    [parameters setObject:[NSNumber numberWithBool:weekendTrading] forKey:@"WEEKENDTRADING"]; 
    
    
    [parameters setObject:[NSNumber numberWithInt:[setupTradingLagTextField intValue]*60] forKey:@"TRADINGLAG"];
    
    [parameters setObject:[NSNumber numberWithLong:(28*DAY_SECONDS)] forKey:@"WARMUPDATA"];
    //[parameters setObject:@"EWMA20" forKey:@"FASTSIG"];
    //[parameters setObject:@"EWMA24" forKey:@"SLOWSIG"];
    
    [setUpSheetCancelButton setEnabled:YES];
    
    if(doThreads){
        [simulationController performSelectorInBackground:@selector(tradingSimulation:) withObject:parameters];
    }else{
        [simulationController tradingSimulation:parameters];
    }
    
    [performSimulationButton setEnabled:YES];
    [self endSetupSheet];
}

-(void)initialiseSignalTableView{
    
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
    
        [self plotSignalDataFrom:startDateTime To:endDateTime];
    }
    
}

-(void)setupResultsReport
{
    [reportTableView reloadData];
}

-(void)simulationEnded
{
    [setUpSheetCancelButton setEnabled:NO];
}

- (IBAction)toggleLongShortIndicator:(id)sender {
    [simulationResultsPlot togglePositionIndicator];
}

- (IBAction)plotLeftSideExpand:(id)sender {
    [simulationResultsPlot leftSideExpand];
}

-(void)plotSimulationData: (DataSeries *) analysisDataSeries
{
    //BOOL added;
    TimeSeriesLine *tsl;
    NSArray *fieldNames;
    //NSMutableArray *isAvailable;
    //NSArray *fieldNamesFromData;
    //NSString *fieldName;
    
    
//    fieldNames = [fieldNameOrdering mutableCopy];
    
//    isAvailable = [[NSMutableArray alloc] init];
    
//    fieldNamesFromData = [[analysisDataSeries yData] allKeys];
//    for(int i = 0; i < [fieldNames count]; i ++){
//        BOOL found = NO;
//        for(int j = 0; j < [fieldNamesFromData count]; j++){
//            if([[fieldNames objectAtIndex:i] isEqualToString:[fieldNamesFromData objectAtIndex:j]])
//            {
//                found = YES;
//                break;
//            }
//        }
//        if(found){
//            [isAvailable addObject:[NSNumber numberWithBool:YES]];
//        }else{
//            [isAvailable addObject:[NSNumber numberWithBool:NO]];
//        }
//    }
//    for(int i = [fieldNames count] - 1; i >= 0; i--){
//        if(![[isAvailable objectAtIndex:i] boolValue]){
//            [fieldNames removeObjectAtIndex:i];
//        }
//    }
    
    
    
//    
//    NSArray *fieldNames = [self getFieldNamesInCorrectOrdering:[[dataForLongTermPlot yData] allKeys]];
//    NSString *lineColour;
//    BOOL isVisible = NO;
//    for(int i = 0; i < [fieldNames count];i++){
//        switch (i) {
//            case 0:
//                isVisible = YES;
//                break;
//            default:
//                isVisible = NO;
//                break;
//        }
//        lineColour = [coloursForPlots objectAtIndex:i%[coloursForPlots count]];
//    
//    
//    
//    
//    
    fieldNames = [self getFieldNamesInCorrectOrdering:[[analysisDataSeries yData] allKeys]];
    [self clearTSTableView:simulationTimeSeriesTableView];
    BOOL isVisible;
    NSString *lineColour;
    for(int i = 0; i < [fieldNames count]; i++){
        switch (i) {
            case 0:
                isVisible = YES;
                break;
            default:
                isVisible = NO;
                break;
        }
        lineColour = [coloursForPlots objectAtIndex:i%[coloursForPlots count]];
        tsl = [[TimeSeriesLine alloc] initWithVisibility:isVisible AndName:[fieldNames objectAtIndex:i] AndColour:lineColour];
        [self addToTableView:simulationTimeSeriesTableView   TimeSeriesLine:tsl];
    }
        
        
//        fieldName = [fieldNames objectAtIndex:i];
//        added = NO;
//        if([fieldName isEqualToString:@"BID"])
//        {
//            tsl = [[TimeSeriesLine alloc] initWithVisibility:YES AndName:@"BID" AndColour:@"Red"];
//            [self addToTableView:simulationTimeSeriesTableView   TimeSeriesLine:tsl];
//            added = YES;
//        }
//        if([fieldName isEqualToString:@"ASK"])
//        {
//            tsl = [[TimeSeriesLine alloc] initWithVisibility:NO AndName:@"ASK" AndColour:@"Green"];
//            [self addToTableView:simulationTimeSeriesTableView   TimeSeriesLine:tsl];
//            added = YES;
//        }
//        if([fieldName isEqualToString:@"MID"])
//        {
//            tsl = [[TimeSeriesLine alloc] initWithVisibility:YES AndName:@"MID" AndColour:@"LightGray"];
//            [self addToTableView:simulationTimeSeriesTableView   TimeSeriesLine:tsl];
//            added = YES;
//        }
//        
//        if(added == NO){
//            tsl = [[TimeSeriesLine alloc] initWithVisibility:NO AndName:fieldName AndColour:[coloursForPlots objectAtIndex:i%[coloursForPlots count]]];
//            [self addToTableView:simulationTimeSeriesTableView   TimeSeriesLine:tsl];
//        }
//    }    
    
    //Zoom stuff
    //    [simZoomFromDatePicker setMinDate:[NSDate dateWithTimeIntervalSince1970:(NSTimeInterval) [dataToPlot minDateTime]]]; 
    //    [simZoomFromDatePicker setMaxDate:[NSDate dateWithTimeIntervalSince1970:(NSTimeInterval) [dataToPlot maxDateTime]]]; 
    //    [simZoomFromDatePicker setDateValue:[NSDate dateWithTimeIntervalSince1970:(NSTimeInterval) [dataToPlot minDateTime]]];
    //    
    //    [simZoomToDatePicker setMinDate:[NSDate dateWithTimeIntervalSince1970:(NSTimeInterval) [dataToPlot minDateTime]]]; 
    //    [simZoomToDatePicker setMaxDate:[NSDate dateWithTimeIntervalSince1970:(NSTimeInterval) [dataToPlot maxDateTime]]]; 
    //    [simZoomToDatePicker setDateValue:[NSDate dateWithTimeIntervalSince1970:(NSTimeInterval) [dataToPlot maxDateTime]]];
    
    simulationResultsPlot = [[SeriesPlot alloc] init];
    //[plot4 setDelegate:self];
    [simulationResultsPlot setHostingView:simulationResultGraphHostingView];
    [simulationResultsPlot setData:analysisDataSeries WithViewName:@"ALL"];
    [simulationResultsPlot renderPlotWithFields:simulationTimeSeries];
    
    simulationDataSeries = analysisDataSeries;
    
}
-(void)plotSignalDataFrom: (long) startDateTime To:(long) endDateTime
{
    
    DataSeries *analysisDataSeries = [[simulationController currentSimulation] analysisDataSeries]; 
    TimeSeriesLine *tsl;
    NSArray *fieldNames;
 
    fieldNames = [self getFieldNamesInCorrectOrdering:[[analysisDataSeries yData] allKeys]];
    [self clearTSTableView:simulationSignalTimeSeriesTableView];
    BOOL isVisible;
    NSString *lineColour;
    for(int i = 0; i < [fieldNames count]; i++){
        switch (i) {
            case 0:
                isVisible = YES;
                break;
            default:
                isVisible = NO;
                break;
        }
        lineColour = [coloursForPlots objectAtIndex:i%[coloursForPlots count]];
        tsl = [[TimeSeriesLine alloc] initWithVisibility:isVisible AndName:[fieldNames objectAtIndex:i] AndColour:lineColour];
        [self addToTableView:simulationSignalTimeSeriesTableView   TimeSeriesLine:tsl];
    }
    
    [analysisDataSeries setPlotViewWithName:@"SIGANAL" AndStartDateTime:startDateTime AndEndDateTime:endDateTime];
    
    signalAnalysisPlot = [[SeriesPlot alloc] init];
    //[plot4 setDelegate:self];
    [signalAnalysisPlot setHostingView:simulationSignalGraphHostingView];
    [signalAnalysisPlot setData:analysisDataSeries WithViewName:@"SIGANAL"];
    [signalAnalysisPlot renderPlotWithFields:simulationSignalTimeSeries];
    
    simulationDataSeries = analysisDataSeries;
    
}

-(void)addSimulationDataToResultsTableView: (DataSeries *) analysisDataSeries
{
    [self clearTSTableView:simulationNumbersTableView];
    NSTableColumn *newTableColumn;
    NSArray *tableColumns;
    NSMutableArray *fieldNames;
    NSMutableArray *isAvailable;
    NSArray *fieldNamesFromData;
    float tableViewWidth = 0.0;
    
    fieldNames = [fieldNameOrdering mutableCopy];
    
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


-(void)addSimInfoToAboutPanelWithName:(NSString *) simName
                            AndFxPair:(NSString *) fxPair
                   AndAccountCurrency:(NSString *) accCurrency
                      AndSimStartTime: (NSString *) simStartTime
                        AndSimEndTime: (NSString *) simEndTime
                      AndSamplingRate: (NSString *) samplingRate
                        AndTradingLag: (NSString *) tradingLag
                AndTradingWindowStart:(NSString *) tradingStartTime
                  AndTradingWindowEnd:(NSString *) tradingEndTime
                     AndSimParameters:(NSString *) parameters
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


-(NSArray *)getFieldNamesInCorrectOrdering:(NSArray *) fieldNamesFromData
{      
    
    NSMutableArray *fieldNames = [fieldNameOrdering mutableCopy];
    NSMutableArray *isAvailable = [[NSMutableArray alloc] init];
    
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
    return fieldNames;
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
#pragma mark Simulation Output Methods


//-(void)gettingDataIndicatorSwitchOn
//{
//    [leftPanelStatusLabel setHidden:NO];
//    [leftPanelStatusLabel setStringValue:@"Retrieving from database"];
//    [leftSideProgressBar setHidden:NO];
//    [leftSideProgressBar startAnimation:nil];
//}

//-(void)gettingDataIndicatorSwitchOff
//{
//    [leftSideProgressBar stopAnimation:nil];
//    [leftPanelStatusLabel setStringValue:@""];
//    [leftSideProgressBar setHidden:YES];
//    [leftPanelStatusLabel setHidden:YES];
//}

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
    
    return 0;
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    TimeSeriesLine *tsl;
    if([[tableView identifier] isEqualToString:@"SIMTSTV"]){
        tsl = [simulationTimeSeries objectAtIndex:row];
        NSString *column = [tableColumn identifier];
        return [tsl valueForKey:column];
    }
    if([[tableView identifier] isEqualToString:@"SIGTSTV"]){
        tsl = [simulationSignalTimeSeries objectAtIndex:row];
        NSString *column = [tableColumn identifier];
        return [tsl valueForKey:column];
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
        if([[tableColumn identifier] isEqualToString:@"SIGNALGAIN"]){
           
            int signalSide = [UtilityFunctions signum:[[signalAnalysisDetails objectForKey:@"SIGNAL"] intValue]];
                          
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
        if([[tableColumn identifier] isEqualToString:@"NAME"])
        {
            return [[simulationController currentSimulation] getReportNameFieldAtIndex:row];
        }
        if([[tableColumn identifier] isEqualToString:@"DATA1"])
        {
            return [[simulationController currentSimulation] getReportDataFieldAtIndex:row];
        }
    }
    
    return nil;
}

- (void)tableView:(NSTableView *)tableView setObjectValue:(id) obj forTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    TimeSeriesLine *tsl;
    SeriesPlot *plot;
   if([[tableView identifier] isEqualToString:@"SIMTSTV"]){
        tsl = [simulationTimeSeries objectAtIndex:row];
        plot = simulationResultsPlot;
        //timeSeries = simulationTimeSeries;
    }
    
    if([[tableView identifier] isEqualToString:@"SIGTSTV"]){
        tsl = [simulationSignalTimeSeries objectAtIndex:row];
        plot = signalAnalysisPlot;

        
    }
    NSString *column = [tableColumn identifier];
    [tsl setValue:obj forKey:column]; 
    [plot visibilityOfLineUpdated];
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
                int signalSide = [UtilityFunctions signum:[[signalAnalysisDetails objectForKey:@"SIGNAL"] intValue]];
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
    }
}


#pragma mark -
#pragma mark Simulation Output Methods


-(void)gettingDataIndicatorSwitchOn
{
    if([[self delegate] respondsToSelector:@selector(gettingDataIndicatorSwitchOn)])
    {
        [[self delegate] gettingDataIndicatorSwitchOn];
    }
}

-(void)gettingDataIndicatorSwitchOff
{
    if([[self delegate] respondsToSelector:@selector(gettingDataIndicatorSwitchOff)])
    {
        [[self delegate] gettingDataIndicatorSwitchOff];
    }
}

-(void)updateStatus:(NSString *) statusMessage
{
    [performSimulationStatusLabel setHidden:NO];
    [performSimulationStatusLabel setStringValue:statusMessage];
}

-(void) setProgressMinAndMax: (NSArray *) minAndMax 
{
    [performSimulationProgressBar setMinValue:[[minAndMax objectAtIndex:0] doubleValue]];
    [performSimulationProgressBar setMaxValue:[[minAndMax objectAtIndex:1] doubleValue]];
}  

-(void) incrementProgressBarBy:(NSNumber *) increment
{
    [performSimulationProgressBar incrementBy:[increment doubleValue]];
}

-(void) progressBarOn
{
    [performSimulationProgressBar setDoubleValue:[performSimulationProgressBar minValue]];
    [performSimulationProgressBar startAnimation:nil];
    [performSimulationProgressBar setHidden:NO];
}

-(void) progressBarOff
{
    [performSimulationProgressBar stopAnimation:nil];
    [performSimulationProgressBar setHidden:YES];
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


//- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
//{
//    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
//    if (self) {
//        // Initialization code here.
//    }
//    
//    return self;
//}

@end
