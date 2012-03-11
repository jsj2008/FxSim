//
//  AppController.m
//  Simple Sim
//
//  Created by O'Connor Martin on 19/12/2011.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "AppController.h"
#import "PlotController.h"
#import "SimulationController.h"
#import "Simulation.h"
//#import "IdNamePair.h"
#import "EpochTime.h"
#import "DataSeries.h"
#import "SeriesPlot.h"
#import "TimeSeriesLine.h"


#define START_TIME_FOR_ID_PLOT 2

#define DATA_NAME @"DATANAME"
#define LT_DAYS @"LTDAYS"
#define ST_DAYS @"STDAYS"
#define LT_SAMPLE_SECS @"LTSAMPLESECS"
#define ST_SAMPLE_SECS @"STSAMPLESECS"
#define ID_SAMPLE_SECS @"IDSAMPLESECS"
#define SELECTED_DAY @"SELECTEDDAY"    
#define STATUS_TEXTFIELD @"STATUSTEXTFIELD"
#define DATA_SHIFT_SECONDS @"DATASHIFTSECONDS"

#define THREADS YES

#define DAY_SECONDS 24*60*60


@interface AppController()
-(int)fib:(int)n;
-(bool)setupData;
-(void)setupPlots;
-(void)setupDataAndPlots;
-(void)setStatusLabel:(NSTextField *) statusLabel WithMessage: (NSString *) newMessage;
-(void)endSetupSheet;
-(void)shiftData;
-(void)endDataShift;
-(void)simulationPlotZoom;
//-(NSString *)getNameForID:(NSInteger)dbid;
//-(long)getMinDateTimeForID:(NSInteger)dbid;
//-(long)getMaxDateTimeForID:(NSInteger)dbid;
@end


@implementation AppController
@synthesize simZoomToDatePicker;
@synthesize simZoomFromDatePicker;
@synthesize simZoomResetButton;
@synthesize simZoomButton;
@synthesize simZoomOnOffButtons;
@synthesize simAnalysisDataTable;
@synthesize test;
@synthesize plotPositionsButton;
@synthesize shiftDataDaysLabel;
@synthesize shiftDataRangeForward;
@synthesize shiftDataRangeBack;
@synthesize dataRangeMoveValue;
@synthesize setupDataButton;
@synthesize intraDayLeftSideTab;
@synthesize sideTabs;
@synthesize intraDayTimeLabel;
@synthesize setUpStatusLabel;
@synthesize leftPanelStatusLabel;
@synthesize sumulationDetails;
@synthesize intraDayTimeSlider;
@synthesize intraDaySamplingUnit;
@synthesize longTermTimeSeriesTableView;
@synthesize shortTermTimeSeriesTableView;
@synthesize intraDayTimeSeriesTableView;
@synthesize simulationTimeSeriesTableView;
@synthesize intraDaySamplingValue;
@synthesize longTermTimeSeries;
@synthesize shortTermTimeSeries;
@synthesize intraDayTimeSeries;
@synthesize hostingView2;
@synthesize longTermSamplingUnit;
@synthesize shortTermSamplingUnit;
@synthesize hostingView3;
@synthesize hostingView4;
@synthesize longTermSamplingValue;
@synthesize shortTermSamplingValue;
@synthesize hostingView1;
@synthesize mainTabs;
@synthesize currentDateLabel;
@synthesize fxPairLabel;
@synthesize pairPicker;
@synthesize toDateLabel;
@synthesize fromDateLabel;
@synthesize dayOfWeekLabel;
@synthesize datePicker;
@synthesize minAvailableDate;
@synthesize maxAvailableDate;
@synthesize longTermTimeSeriesScrollView;
@synthesize intraDayTimeSeriesScrollView;
@synthesize shortTermTimeSeriesScrollView;
@synthesize setupSheet;
@synthesize dataSetupProgressBar;
@synthesize leftSideProgressBar;
@synthesize shortTermHistory;
@synthesize longTermHistory;
@synthesize colorsForPlots;
@synthesize currentDay;

NSTimer *timer;
int timerCount;
bool cancelProcedure = NO;
bool doingSetup = NO;
bool initialSetupComplete = NO;


DataSeries *simData;
BOOL simDataZoomSelectFrom = YES;

-(id)init
{
    self = [super init];
    if(self){
        longTermTimeSeries = [[NSMutableArray alloc] init];
        shortTermTimeSeries = [[NSMutableArray alloc] init];
        intraDayTimeSeries = [[NSMutableArray alloc] init];
        simulationTimeSeries = [[NSMutableArray alloc] init]; 
        formData = [[NSMutableDictionary alloc] init];
    }
    return self;
}

-(void)awakeFromNib
{
    NSString *selectedItem;
    dataController = [[DataController alloc] init];
    accountsController = [[SimulationController alloc] init];
    [accountsController setDelegate:self];
    
    long initialMinDateTime;
    long initialMaxDateTime;
    
    [simAnalysisDataTable setDataSource:accountsController];
    
    NSTableColumn *colourColumnLT =  [longTermTimeSeriesTableView tableColumnWithIdentifier:@"colourId"];
    NSTableColumn *colourColumnST =  [shortTermTimeSeriesTableView tableColumnWithIdentifier:@"colourId"];
    NSTableColumn *colourColumnID =  [intraDayTimeSeriesTableView tableColumnWithIdentifier:@"colourId"];
    NSTableColumn *colourColumnSP =  [simulationTimeSeriesTableView tableColumnWithIdentifier:@"colourId"];
    
    NSPopUpButtonCell *colourDropDownCellLT = [[NSPopUpButtonCell alloc] init];
    NSPopUpButtonCell *colourDropDownCellST = [[NSPopUpButtonCell alloc] init];
    NSPopUpButtonCell *colourDropDownCellID = [[NSPopUpButtonCell alloc] init];
    NSPopUpButtonCell *colourDropDownCellSP = [[NSPopUpButtonCell alloc] init];
    
    [colourDropDownCellLT setBordered:NO];
    [colourDropDownCellLT setEditable:YES];
    [colourDropDownCellST setBordered:NO];
    [colourDropDownCellST setEditable:YES];    
    [colourDropDownCellID setBordered:NO];
    [colourDropDownCellID setEditable:YES]; 
    [colourDropDownCellSP setBordered:NO];
    [colourDropDownCellSP setEditable:YES]; 
    
    colorsForPlots = [NSArray arrayWithObjects:
                      @"Red",
                      @"Green",
                      @"Blue",
                      @"Cyan",
                      @"Yellow",
                      @"Magenta",
                      @"Orange",
                      @"Purple",
                      @"Brown", 
                      @"White", 
                      @"LightGray", 
                      @"Gray",
                      @"DarkGray",
                      @"Black",
                      nil];
    
    [colourDropDownCellLT addItemsWithTitles:colorsForPlots];
    [colourColumnLT setDataCell:colourDropDownCellLT];
    [colourDropDownCellST addItemsWithTitles:colorsForPlots];
    [colourColumnST setDataCell:colourDropDownCellST];
    [colourDropDownCellID addItemsWithTitles:colorsForPlots];
    [colourColumnID setDataCell:colourDropDownCellID];
    [colourDropDownCellSP addItemsWithTitles:colorsForPlots];
    [colourColumnSP setDataCell:colourDropDownCellSP];
    
    //dataTypeListWithId = [dataController getListofDataTypes];
    NSDictionary *pairListWithId;
    pairListWithId = [dataController fxPairs];
    NSArray *pairNames = [pairListWithId allKeys];
    
    [pairPicker removeAllItems];
    for (int i = 0; i < [pairNames count];i++) {
        [pairPicker addItemWithTitle:[pairNames objectAtIndex:i]];
        //[[pairPicker itemWithTitle:[pairNames objectAtIndex:i]] setTag:[pairListWithId objectForKey:[pairNames objectAtIndex:i]]];
    }
    
    [pairPicker selectItemAtIndex:0];
    
    selectedItem = [[pairPicker selectedItem] title];
    initialMinDateTime = [dataController getMinDataDateTimeForPair:selectedItem];
    initialMaxDateTime = [dataController getMaxDataDateTimeForPair:selectedItem];
    
    [fromDateLabel setStringValue:[[NSDate dateWithTimeIntervalSince1970:(NSTimeInterval) initialMinDateTime] descriptionWithCalendarFormat:@"%Y-%m-%d" timeZone:[NSTimeZone timeZoneWithName:@"GMT"] locale:nil]];
    [toDateLabel setStringValue:[[NSDate dateWithTimeIntervalSince1970:(NSTimeInterval) initialMaxDateTime] descriptionWithCalendarFormat:@"%Y-%m-%d" timeZone:[NSTimeZone timeZoneWithName:@"GMT"] locale:nil]];
    
    NSCalendar *gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
    [datePicker setTimeZone:[NSTimeZone timeZoneWithName:@"GMT"]];
    [datePicker setCalendar:gregorian];
    
    [datePicker setMinDate:[NSDate dateWithTimeIntervalSince1970:(NSTimeInterval) initialMinDateTime]];
    [datePicker setMaxDate:[NSDate dateWithTimeIntervalSince1970:(NSTimeInterval) initialMaxDateTime]];
    [datePicker setDateValue:[NSDate dateWithTimeIntervalSince1970:(NSTimeInterval) ((initialMinDateTime+initialMaxDateTime )/2)]]; 
    [dayOfWeekLabel setStringValue:[[datePicker dateValue] descriptionWithCalendarFormat:@"%a" timeZone:[NSTimeZone timeZoneWithName:@"GMT"] locale:nil]]; 
    
    plot1 = [[SeriesPlot alloc] init];
    [plot1 setHostingView:hostingView1];
    [plot1 initialGraph];
    
    plot2 = [[SeriesPlot alloc] init];
    [plot2 setHostingView:hostingView2];
    [plot2 initialGraph];
    
    plot3 = [[SeriesPlot alloc] init];
    [plot3 setHostingView:hostingView3];
    [plot3 initialGraph];
   
    plot4 = [[SeriesPlot alloc] init];
    [plot4 setHostingView:hostingView4];
    [plot4 initialGraph];
    
    [leftPanelStatusLabel setHidden:NO];
    [leftPanelStatusLabel setStringValue:@"Enter ⌘U to setup"];
    [mainTabs selectTabViewItemWithIdentifier:@"ID"]; 
}

//-(long)getMinDateTimeForID:(NSInteger)dbid
//{
//    for (IdNamePair *fxPairInfo in pairListWithId)
//    {
//        if([fxPairInfo dbid] == dbid){
//            return [fxPairInfo minDateTime]; 
//        }
//    }
//    return 0;
//}
//-(long)getMaxDateTimeForID:(NSInteger)dbid
//{
//    for (IdNamePair *fxPairInfo in pairListWithId)
//    {
//        if([fxPairInfo dbid] == dbid){
//            return [fxPairInfo maxDateTime]; 
//        }
//    }
//    return 0;
//}
//-(NSString *)getNameForID:(NSInteger)dbid
//{
//    for (IdNamePair *fxPairInfo in pairListWithId)
//    {
//        if([fxPairInfo dbid] == dbid){
//            return [fxPairInfo name]; 
//        }
//    }
//    return @"Error";
//}

- (IBAction)cancelSetupSheet:(id)sender {
    cancelProcedure = YES;
    [self setStatusLabel:setUpStatusLabel WithMessage:@"Trying to cancel..."];
    if(doingSetup == NO){
        [self endSetupSheet];
    }
}

- (IBAction)test:(id)sender {
    Simulation *acc;
    [test setEnabled:NO];
    [self clearSimulationMessage];
    [accountsController addAndTestAcc];
    acc = [accountsController getAccountForName:@"test"];
    [test setEnabled:YES];
}
-(void)setStatusLabel:(NSTextField *) statusLabel WithMessage:(NSString *) newMessage 
{
    [statusLabel setStringValue:newMessage];
}

- (IBAction)setUp:(id)sender
{
    NSString *selectedItem = [[pairPicker selectedItem] title];
    //NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    //[dateFormatter setDateStyle:NSDateFormatterMediumStyle];
    NSDate *selectedDay = [datePicker  dateValue];
    
    int daysForLTHistory = [longTermHistory intValue];
    int daysForSTHistory = [shortTermHistory intValue];
    int longTermDataSampleSeconds, shortTermDataSampleSeconds, intraDayDataSampleSeconds;

    // Got this code at www.red-sweater.com/blog/229/stay-responsive
    if([[sender window] makeFirstResponder:[sender window]]){
        //Try end editing this way
    }else{
        [[sender window] endEditingFor:nil];   
    }
    
    [setupDataButton setEnabled:NO];
    [pairPicker setEnabled:NO];
    [datePicker setEnabled:NO];
    [shortTermHistory setEnabled:NO];
    [longTermHistory setEnabled:NO];
    [intraDaySamplingValue setEnabled:NO];
    [intraDaySamplingUnit setEnabled:NO];
    [shortTermSamplingValue setEnabled:NO];
    [shortTermSamplingUnit setEnabled:NO];
    [longTermSamplingValue setEnabled:NO];
    [longTermSamplingUnit setEnabled:NO];
    
    cancelProcedure = NO;
    doingSetup = YES;
    
    [dataSetupProgressBar setHidden:NO];
    [dataSetupProgressBar startAnimation:sender];
    [setUpStatusLabel setStringValue:@"Loading data"];
    [setUpStatusLabel setHidden:NO];
    
    longTermDataSampleSeconds = [longTermSamplingValue intValue];
    shortTermDataSampleSeconds = [shortTermSamplingValue intValue];
    intraDayDataSampleSeconds = [intraDaySamplingValue intValue];
    
    //Column 0 is for minutes, column 1 for hours
    if([longTermSamplingUnit selectedColumn]==0){
        longTermDataSampleSeconds = longTermDataSampleSeconds * 60;
    }else{
        longTermDataSampleSeconds = longTermDataSampleSeconds * 60 * 60;
    }
    
    //Column 0 is for minutes, column 1 for hours
    if([shortTermSamplingUnit selectedColumn]==0){
        shortTermDataSampleSeconds = shortTermDataSampleSeconds * 60;
    }else{
        shortTermDataSampleSeconds = shortTermDataSampleSeconds * 60 * 60;
    }
    
    //Column 0 is for seconds, column 1 for minutes
    if([intraDaySamplingUnit selectedColumn]==1){
        intraDayDataSampleSeconds = intraDayDataSampleSeconds * 60;
    }    
    
    formData = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                selectedItem,DATA_NAME,
                                [NSNumber numberWithInt:daysForLTHistory],LT_DAYS,
                                [NSNumber numberWithInt:daysForSTHistory],ST_DAYS,
                                [NSNumber numberWithInt:longTermDataSampleSeconds],LT_SAMPLE_SECS,
                                [NSNumber numberWithInt:shortTermDataSampleSeconds], ST_SAMPLE_SECS,
                                [NSNumber numberWithInt:intraDayDataSampleSeconds], ID_SAMPLE_SECS,
                                setUpStatusLabel, STATUS_TEXTFIELD,
                                //[NSString stringWithString:[[pairPicker selectedItem] title]],SELECTED_PAIR,
                                selectedDay,SELECTED_DAY,    
                                nil];
    
    //[self performSelectorInBackground:@selector(setupDataAndPlots) withObject:formInfo];
    //[self setupDataAndPlots:formInfo];
    //[self performSelectorInBackground:@selector(setupData) withObject:nil];
    if(THREADS){
        [self performSelectorInBackground:@selector(setupDataAndPlots) withObject:nil];
    }else{
        [self setupDataAndPlots];
    }
    
}

-(void)setupDataAndPlots
{
    if([self setupData]){
            [self setupPlots];
    }
}

-(void)endSetupSheet
{
    // Don't change this stuff if you are cancelling
    if(cancelProcedure == NO)
    {
        [fxPairLabel setHidden:NO];
        [currentDateLabel setHidden:NO];
        [longTermTimeSeriesScrollView setHidden:NO];
        [shortTermTimeSeriesScrollView setHidden:NO];
        [intraDayTimeSeriesScrollView setHidden:NO];
        [intraDayLeftSideTab setHidden:NO];
        [fxPairLabel setStringValue:[[pairPicker selectedItem] title]];
        [currentDateLabel setStringValue:[currentDay descriptionWithCalendarFormat:@"%a %Y-%m-%d" timeZone:[NSTimeZone timeZoneWithName:@"GMT"] locale:nil]];
        [mainTabs selectTabViewItemAtIndex:2];
        
        
        [dataRangeMoveValue setHidden:NO];
        [shiftDataRangeBack setHidden:NO];
        [shiftDataRangeForward setHidden:NO];
        [shiftDataDaysLabel setHidden:NO];
        
        initialSetupComplete = YES;
    }
    
    [dataSetupProgressBar setHidden:YES];
    [dataSetupProgressBar stopAnimation:nil];
    [setUpStatusLabel setHidden:YES];
    [leftPanelStatusLabel setHidden:YES];
    
    if(cancelProcedure == NO)
    {
        [NSApp endSheet:setupSheet returnCode: NSOKButton];
    }else{
        [NSApp endSheet:setupSheet returnCode: NSCancelButton];
    }
        
    [setupDataButton setEnabled:YES];
    [pairPicker setEnabled:YES];
    [datePicker setEnabled:YES];
    [shortTermHistory setEnabled:YES];
    [longTermHistory setEnabled:YES];
    [intraDaySamplingValue setEnabled:YES];
    [intraDaySamplingUnit setEnabled:YES];
    [shortTermSamplingValue setEnabled:YES];
    [shortTermSamplingUnit setEnabled:YES];
    [longTermSamplingValue setEnabled:YES];
    [longTermSamplingUnit setEnabled:YES];

    [setupSheet orderOut:nil];
    

}
-(bool)setupData
{
    bool success; 
    NSTextField *statusTextField;
    long dateStartTimeFullData, dateEndTimeFullData;
    int daysLT;
    NSString *pairName;
    NSDate *selectedDay;
    // create a calendar to use for date ranges
    NSCalendar *gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
    // set up date components
    NSDateComponents *components = [[NSDateComponents alloc] init];

    @synchronized (formData)
    {
        pairName = [formData objectForKey:DATA_NAME];
        daysLT = [[formData objectForKey:LT_DAYS] intValue]; 
        selectedDay = [formData objectForKey:SELECTED_DAY];
        statusTextField = [formData objectForKey:STATUS_TEXTFIELD];
    }    
    [self setStatusLabel:statusTextField WithMessage:@"Requesting from database"];
    //Full data 
    [components setDay:-(2*daysLT)];
    dateStartTimeFullData = [EpochTime epochTimeAtZeroHour:[[gregorian dateByAddingComponents:components toDate:selectedDay options:0]  timeIntervalSince1970]];
    dateEndTimeFullData = [EpochTime epochTimeNextDayAtZeroHour:[selectedDay timeIntervalSince1970]];
    // Get the data for the Long term Plot
    success = [dataController setupDataSeriesForName:pairName];
    if(success){
        success = [dataController setBidAskMidForStartDateTime:dateStartTimeFullData 
                                                AndEndDateTime: dateEndTimeFullData];
    }
    if(success){
        [self setStatusLabel:statusTextField WithMessage:[NSString stringWithFormat:@"Retrieved %d data",[[dataController currentData] length]]];
    }else{
        [self setStatusLabel:statusTextField WithMessage:[NSString stringWithFormat:@"Problem retrieving data"]];
        return success;
    }
    [self setStatusLabel:statusTextField WithMessage:@"Calculating EWMA"];
    for(int i = 18; i <= 26; i= i + 2){
        int param = [self fib:i];
        [self setStatusLabel:statusTextField WithMessage:[NSString stringWithFormat:@"Calculating EWMA%d",param]];
        [dataController addEWMAWithParameter:[self fib:i]];
    }
    return success;
}

-(void)setupPlots
{
//    long dateStartTimeFullData, dateEndTimeFullData;
    long dateStartTimeLongTerm, dateEndTimeLongTerm;
    long dateStartTimeShortTerm, dateEndTimeShortTerm;
    long dateStartTimeIntraDay, dateEndTimeIntraDay;
    DataSeries *dataForLongTermPlot, *dataForShortTermPlot, *dataForIntraDayPlot;
    
    // create a calendar to use for date ranges
    NSCalendar *gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
    // set up date components
    NSDateComponents *components = [[NSDateComponents alloc] init];

    int daysLT,daysST,sampleLT,sampleST,sampleID;
    long lastDayOfDataDateTime;
    NSDate *lastDayOfData;
    NSString *selectedPair; 
    NSTextField *statusTextField;
    
    @synchronized (formData)
    {
        selectedPair = [formData objectForKey:DATA_NAME];
        daysLT = [[formData objectForKey:LT_DAYS] intValue]; 
        daysST = [[formData objectForKey:ST_DAYS] intValue];
        sampleLT = [[formData objectForKey:LT_SAMPLE_SECS] intValue];
        sampleST = [[formData objectForKey:ST_SAMPLE_SECS] intValue];
        sampleID = [[formData objectForKey:ID_SAMPLE_SECS] intValue];
        //selectedDay = [formData objectForKey:SELECTED_DAY];
        statusTextField = [formData objectForKey:STATUS_TEXTFIELD];
    }
    [statusTextField setHidden:NO];
    lastDayOfDataDateTime = [[dataController currentData] maxDateTime];
    lastDayOfData = [NSDate dateWithTimeIntervalSince1970:lastDayOfDataDateTime];
    if(cancelProcedure == NO)
    {
        [self setStatusLabel:statusTextField WithMessage:@"Creating Long Term Plot"];
        //Long term data
        [components setDay:-daysLT];
        dateStartTimeLongTerm = [EpochTime epochTimeAtZeroHour:[[gregorian dateByAddingComponents:components toDate:lastDayOfData options:0]  timeIntervalSince1970]];
        dateEndTimeLongTerm = [EpochTime epochTimeAtZeroHour:[lastDayOfData timeIntervalSince1970]];
        dataForLongTermPlot = [[dataController currentData] sampleDataAtInterval:sampleLT];
        [dataForLongTermPlot  setPlotViewWithName: @"LongTerm" AndStartDateTime: dateStartTimeLongTerm AndEndDateTime: dateEndTimeLongTerm];
    }

    if(cancelProcedure == NO)
    {
        [self setStatusLabel:statusTextField WithMessage:@"Creating Short Term Plot"];
        //Short term data
        [components setDay:-daysST];
        dateStartTimeShortTerm = [EpochTime epochTimeAtZeroHour:[[gregorian dateByAddingComponents:components toDate:lastDayOfData options:0]  timeIntervalSince1970]];
        dateEndTimeShortTerm = [EpochTime epochTimeAtZeroHour:[lastDayOfData timeIntervalSince1970]];
        dataForShortTermPlot = [[dataController currentData] sampleDataAtInterval:sampleST];
        [dataForShortTermPlot  setPlotViewWithName: @"ShortTerm" AndStartDateTime: dateStartTimeShortTerm AndEndDateTime: dateEndTimeShortTerm];
    }
    
    //Intraday data
    if(cancelProcedure == NO)
    {
        [self setStatusLabel:statusTextField WithMessage:@"Creating Intra-day Plot"];
        dateStartTimeIntraDay = [EpochTime epochTimeAtZeroHour:[lastDayOfData timeIntervalSince1970]];
        dateEndTimeIntraDay = dateStartTimeIntraDay + START_TIME_FOR_ID_PLOT*60*60;
        int hours = (int)START_TIME_FOR_ID_PLOT;
        int minutes = (int)((START_TIME_FOR_ID_PLOT - hours) * 60);
        [intraDayTimeSlider setDoubleValue:START_TIME_FOR_ID_PLOT];
        [intraDayTimeLabel setStringValue:[NSString stringWithFormat:@"%02d:%02d",hours, minutes]];
        
        if(sampleID <= [dataController dataGranularity]){
            [[dataController currentData]  setPlotViewWithName: @"IntraDay" AndStartDateTime: dateStartTimeIntraDay AndEndDateTime: dateEndTimeIntraDay];
        }else{
            
            dataForIntraDayPlot = [[dataController currentData] sampleDataAtInterval:sampleID];
            [dataForIntraDayPlot  setPlotViewWithName: @"IntraDay" AndStartDateTime: dateStartTimeIntraDay AndEndDateTime: dateEndTimeIntraDay];
        }
    } 
    
    if(cancelProcedure == NO)
    {    
        [self clearTSTableView:longTermTimeSeriesTableView];
        [self clearTSTableView:shortTermTimeSeriesTableView];
        [self clearTSTableView:intraDayTimeSeriesTableView];
        TimeSeriesLine *tsl;
    
        tsl = [[TimeSeriesLine alloc] initWithVisibility:NO AndName:@"BID" AndColour:@"Red"];
        [self addToTableView:longTermTimeSeriesTableView   TimeSeriesLine:tsl];
        tsl = [[TimeSeriesLine alloc] initWithVisibility:NO AndName:@"ASK" AndColour:@"Green"];
        [self addToTableView:longTermTimeSeriesTableView   TimeSeriesLine:tsl];
        tsl = [[TimeSeriesLine alloc] initWithVisibility:YES AndName:@"MID" AndColour:@"LightGray"];
        [self addToTableView:longTermTimeSeriesTableView   TimeSeriesLine:tsl];
        for(int i = 18; i <= 26; i= i + 2){
            if(i == 18 || i == 26){
            tsl = [[TimeSeriesLine alloc] initWithVisibility:YES AndName:[NSString stringWithFormat:@"EWMA%d",[self fib:i]] AndColour:[colorsForPlots objectAtIndex:i%[colorsForPlots count]]];
            }else{
                tsl = [[TimeSeriesLine alloc] initWithVisibility:NO AndName:[NSString stringWithFormat:@"EWMA%d",[self fib:i]] AndColour:[colorsForPlots objectAtIndex:i%[colorsForPlots count]]];
            }
            [self addToTableView:longTermTimeSeriesTableView   TimeSeriesLine:tsl];
        }
    
    
        tsl = [[TimeSeriesLine alloc] initWithVisibility:NO AndName:@"BID" AndColour:@"Red"];
        [self addToTableView:shortTermTimeSeriesTableView   TimeSeriesLine:tsl];
        tsl = [[TimeSeriesLine alloc] initWithVisibility:NO AndName:@"ASK" AndColour:@"Green"];
        [self addToTableView:shortTermTimeSeriesTableView   TimeSeriesLine:tsl];
        tsl = [[TimeSeriesLine alloc] initWithVisibility:YES AndName:@"MID" AndColour:@"LightGray"];
        [self addToTableView:shortTermTimeSeriesTableView   TimeSeriesLine:tsl];
        for(int i = 18; i <= 26; i= i + 2){
            if(i == 18 || i == 26){
                tsl = [[TimeSeriesLine alloc] initWithVisibility:YES AndName:[NSString stringWithFormat:@"EWMA%d",[self fib:i]] AndColour:[colorsForPlots objectAtIndex:i%[colorsForPlots count]]];
            }else{
                tsl = [[TimeSeriesLine alloc] initWithVisibility:NO AndName:[NSString stringWithFormat:@"EWMA%d",[self fib:i]] AndColour:[colorsForPlots objectAtIndex:i%[colorsForPlots count]]]; 
            }
            [self addToTableView:shortTermTimeSeriesTableView   TimeSeriesLine:tsl];
        }
    
        tsl = [[TimeSeriesLine alloc] initWithVisibility:NO AndName:@"BID" AndColour:@"Red"];
        [self addToTableView:intraDayTimeSeriesTableView   TimeSeriesLine:tsl];
        tsl = [[TimeSeriesLine alloc] initWithVisibility:NO AndName:@"ASK" AndColour:@"Green"];
        [self addToTableView:intraDayTimeSeriesTableView   TimeSeriesLine:tsl];
        tsl = [[TimeSeriesLine alloc] initWithVisibility:YES AndName:@"MID" AndColour:@"LightGray"];
        [self addToTableView:intraDayTimeSeriesTableView   TimeSeriesLine:tsl];
    
        for(int i = 18; i <= 26; i= i + 2){
            if(i == 18 || i == 26){
                tsl = [[TimeSeriesLine alloc] initWithVisibility:YES AndName:[NSString stringWithFormat:@"EWMA%d",[self fib:i]] AndColour:[colorsForPlots objectAtIndex:i%[colorsForPlots count]]];
            }else{
                tsl = [[TimeSeriesLine alloc] initWithVisibility:NO AndName:[NSString stringWithFormat:@"EWMA%d",[self fib:i]] AndColour:[colorsForPlots objectAtIndex:i%[colorsForPlots count]]];
            }
            [self addToTableView:intraDayTimeSeriesTableView   TimeSeriesLine:tsl];
        }
    }
    
    if(cancelProcedure == NO)
    {
        plot3 = [[SeriesPlot alloc] init];
        [plot3 setHostingView:hostingView3];
        [plot3 setData:dataForLongTermPlot WithViewName:@"LongTerm"];
        [plot3 renderPlotWithFields:longTermTimeSeries] ;
    
        plot2 = [[SeriesPlot alloc] init];
        [plot2 setHostingView:hostingView2];
        [plot2 setData:dataForShortTermPlot WithViewName:@"ShortTerm"];
        [plot2 renderPlotWithFields:shortTermTimeSeries];
    
        plot1 = [[SeriesPlot alloc] init];
        [plot1 setHostingView:hostingView1];
        if(sampleID <= [dataController dataGranularity]){
            [plot1 setData:[dataController currentData] WithViewName:@"IntraDay"];
        }else{
            [plot1 setData:dataForIntraDayPlot WithViewName:@"IntraDay"];
        }
        [plot1 renderPlotWithFields:intraDayTimeSeries];
    }
    if(cancelProcedure == NO)
    {
        [fxPairLabel setStringValue:selectedPair];
        [currentDateLabel setStringValue:[lastDayOfData descriptionWithCalendarFormat:@"%a %Y-%m-%d" timeZone:[NSTimeZone timeZoneWithName:@"GMT"] locale:nil]];
        currentDay = lastDayOfData;
        
    }
    [statusTextField setHidden:YES];
    if(THREADS){
        [self performSelectorOnMainThread:@selector(endSetupSheet) withObject:nil waitUntilDone:NO];
    }else{
        [self endSetupSheet];
    }
}

-(void)plotSimulationData: (DataSeries *) dataToPlot
{
    BOOL added;
    TimeSeriesLine *tsl;
    NSArray *fieldNames; 
    NSString *fieldName;
    
    fieldNames = [[dataToPlot yData] allKeys];
    
    [self clearTSTableView:simulationTimeSeriesTableView];
    
    for(int i = 0; i < [fieldNames count]; i++){
        fieldName = [fieldNames objectAtIndex:i];
        added = NO;
        if([fieldName isEqualToString:@"BID"])
        {
            tsl = [[TimeSeriesLine alloc] initWithVisibility:YES AndName:@"BID" AndColour:@"Red"];
            [self addToTableView:simulationTimeSeriesTableView   TimeSeriesLine:tsl];
            added = YES;
        }
        if([fieldName isEqualToString:@"ASK"])
        {
            tsl = [[TimeSeriesLine alloc] initWithVisibility:NO AndName:@"ASK" AndColour:@"Green"];
            [self addToTableView:simulationTimeSeriesTableView   TimeSeriesLine:tsl];
            added = YES;
        }
        if([fieldName isEqualToString:@"MID"])
        {
            tsl = [[TimeSeriesLine alloc] initWithVisibility:YES AndName:@"MID" AndColour:@"LightGray"];
            [self addToTableView:simulationTimeSeriesTableView   TimeSeriesLine:tsl];
            added = YES;
        }
        if(added == NO){
            tsl = [[TimeSeriesLine alloc] initWithVisibility:NO AndName:fieldName AndColour:[colorsForPlots objectAtIndex:i%[colorsForPlots count]]];
            [self addToTableView:simulationTimeSeriesTableView   TimeSeriesLine:tsl];
        }
    }    
    
    //Zoom stuff
    [simZoomOnOffButtons selectCellAtRow:0 column:0];
    [simZoomFromDatePicker setMinDate:[NSDate dateWithTimeIntervalSince1970:(NSTimeInterval) [dataToPlot minDateTime]]]; 
    [simZoomFromDatePicker setMaxDate:[NSDate dateWithTimeIntervalSince1970:(NSTimeInterval) [dataToPlot maxDateTime]]]; 
    [simZoomFromDatePicker setDateValue:[NSDate dateWithTimeIntervalSince1970:(NSTimeInterval) [dataToPlot minDateTime]]];
    
    [simZoomToDatePicker setMinDate:[NSDate dateWithTimeIntervalSince1970:(NSTimeInterval) [dataToPlot minDateTime]]]; 
    [simZoomToDatePicker setMaxDate:[NSDate dateWithTimeIntervalSince1970:(NSTimeInterval) [dataToPlot maxDateTime]]]; 
    [simZoomToDatePicker setDateValue:[NSDate dateWithTimeIntervalSince1970:(NSTimeInterval) [dataToPlot maxDateTime]]];
     
    plot4 = [[SeriesPlot alloc] init];
    [plot4 setDelegate:self];
    [plot4 setHostingView:hostingView4];
    [plot4 setData:dataToPlot WithViewName:@"ALL"];
    [plot4 renderPlotWithFields:simulationTimeSeries];
    
    simData = dataToPlot;
    
}

-(void)addSimulationDataToResultsTableView: (DataSeries *) analysisDataSeries
{
    [self clearTSTableView:simAnalysisDataTable];
    NSTableColumn *newTableColumn;
    NSArray *tableColumns;
    tableColumns = [simAnalysisDataTable tableColumns];
    //int numberOfColumns = [tableColumns count];
    while([tableColumns count] > 0)
    {
        [simAnalysisDataTable removeTableColumn:[tableColumns objectAtIndex:0]];
        tableColumns = [simAnalysisDataTable tableColumns];
    }
    newTableColumn = [[NSTableColumn alloc] initWithIdentifier:@"DATETIME"];
    [[newTableColumn headerCell] setStringValue:@"DATETIME"];
    [simAnalysisDataTable addTableColumn:newTableColumn];
    newTableColumn = [[NSTableColumn alloc] initWithIdentifier:@"MID"];
    NSCell *columnsCell = [newTableColumn dataCell];
    [columnsCell setAlignment:NSRightTextAlignment];
    [[newTableColumn headerCell] setStringValue:@"MID"];
    [simAnalysisDataTable addTableColumn:newTableColumn];
    
    NSArray *newColumnIdentifiers = [[analysisDataSeries yData] allKeys];
    for(int newColumnIndex = 0; newColumnIndex < [newColumnIdentifiers count]; newColumnIndex++){
        if(!([[newColumnIdentifiers objectAtIndex:newColumnIndex] isEqualToString:@"DATETIME"] || [[newColumnIdentifiers objectAtIndex:newColumnIndex] isEqualToString:@"MID"])){
            
            newTableColumn = [[NSTableColumn alloc] initWithIdentifier:[newColumnIdentifiers objectAtIndex:newColumnIndex]];
            [[newTableColumn headerCell] setStringValue:[newColumnIdentifiers objectAtIndex:newColumnIndex]];
            columnsCell = [newTableColumn dataCell];
            [columnsCell setAlignment:NSRightTextAlignment];
            [simAnalysisDataTable addTableColumn:newTableColumn];
        }
    }
    
 
    
    
    [simAnalysisDataTable reloadData];
}

-(void)simulationPlotZoom
{
    long fromDateTime, toDateTime;
    fromDateTime = [[simZoomFromDatePicker dateValue] timeIntervalSince1970];
    toDateTime = [[simZoomToDatePicker dateValue] timeIntervalSince1970];
    if(fromDateTime < toDateTime){
        if(fromDateTime == [simData minDateTime] && toDateTime == [simData maxDateTime]){
            [plot4 setData:simData WithViewName:@"ALL"];
            [plot4 renderPlotWithFields:simulationTimeSeries];
        }else{
            [simData setPlotViewWithName:@"ZOOM" AndStartDateTime:fromDateTime AndEndDateTime:toDateTime];
            [plot4 setData:simData WithViewName:@"ZOOM"];
            [plot4 renderPlotWithFields:simulationTimeSeries];
        }
    }
    [simZoomOnOffButtons selectCellAtRow:0 column:0];
}



- (IBAction)intraDayTimeSlider:(id)sender {
    double sliderValue = [intraDayTimeSlider doubleValue];
    int hours;
    int minutes;
    long dateStartTimeIntraDay, dateEndTimeIntraDay;
    
    //dateEndTimeIntraDay = [EpochTime epochTimeNextDayAtZeroHour:[datePicked timeIntervalSince1970]]; 
    //    dataForIntraDayPlot = [dataController getBidAskSeriesForId:selectedItem  
    //                                                  AndStartTime:dateStartTimeIntraDay 
    //                                                    AndEndTime:dateEndTimeIntraDay
    //                                              ToSampledSeconds:intraDayDataSampleSeconds];
    
    hours = (int)sliderValue;
    minutes = (int)((sliderValue - hours) * 60);
    dateStartTimeIntraDay = [EpochTime epochTimeAtZeroHour:[currentDay timeIntervalSince1970]];
    dateEndTimeIntraDay = dateStartTimeIntraDay + (hours*(60*60)) + (minutes*60);
    
    [[dataController currentData]  setPlotViewWithName: @"IntraDay" AndStartDateTime: dateStartTimeIntraDay AndEndDateTime: dateEndTimeIntraDay];
    [plot1 setData:[dataController currentData] WithViewName:@"IntraDay"];
    [plot1 renderPlotWithFields:intraDayTimeSeries];
    
    [intraDayTimeLabel setStringValue:[NSString stringWithFormat:@"%02d:%02d",hours, minutes]];
}


- (IBAction)changePair:(id)sender {
    //DataIO *database;
    //long *initialDateRange;
    NSString *selectedItem = [[pairPicker selectedItem] title]; 
    //NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    //[dateFormatter setDateStyle:NSDateFormatterMediumStyle];
    long startDate = 0;
    long endDate = 0;
    
    NSLog(@"New Choice is %@",[[pairPicker selectedItem] title] );
    
    startDate = [dataController getMinDataDateTimeForPair:selectedItem];
    endDate = [dataController getMaxDataDateTimeForPair:selectedItem];
    
//    [fromDateLabel setStringValue:[dateFormatter stringFromDate:[NSDate dateWithTimeIntervalSince1970:(NSTimeInterval) startDate]]];
//    [toDateLabel setStringValue:[dateFormatter stringFromDate:[NSDate dateWithTimeIntervalSince1970:(NSTimeInterval) endDate]]];
    
    [fromDateLabel setStringValue:[[NSDate dateWithTimeIntervalSince1970:(NSTimeInterval) startDate] descriptionWithCalendarFormat:@"%Y-%m-%d" timeZone:[NSTimeZone timeZoneWithName:@"GMT"] locale:nil]];
    [toDateLabel setStringValue:[[NSDate dateWithTimeIntervalSince1970:(NSTimeInterval) endDate] descriptionWithCalendarFormat:@"%Y-%m-%d" timeZone:[NSTimeZone timeZoneWithName:@"GMT"] locale:nil]];
    
    
    [datePicker setMinDate:[NSDate dateWithTimeIntervalSince1970:(NSTimeInterval) startDate]];
    [datePicker setMaxDate:[NSDate dateWithTimeIntervalSince1970:(NSTimeInterval) endDate]];
    //[datePicker setDateValue:[NSDate dateWithTimeIntervalSince1970:(NSTimeInterval) (startDate + endDate)/2]]; 
    //[dateFormatter setDateFormat:@"EEE"];
    //NSString *dayName = [dateFormatter stringFromDate:[datePicker dateValue]];
    [dayOfWeekLabel setStringValue:[[datePicker dateValue] descriptionWithCalendarFormat:@"%a" timeZone:[NSTimeZone timeZoneWithName:@"GMT"] locale:nil]]; 
    //[fxPairLabel setStringValue:[dayName substringToIndex:3]]; 
}

- (IBAction)changeDate:(id)sender {
    [dayOfWeekLabel setStringValue:[[datePicker  dateValue] descriptionWithCalendarFormat:@"%a" timeZone:[NSTimeZone timeZoneWithName:@"GMT"] locale:nil]]; 
}


- (IBAction)dataRangeMoveBack:(id)sender {
    int dayShift = -abs([dataRangeMoveValue intValue]);
    long newDayAsDateTime =  [EpochTime epochTimeAtZeroHour:[[dataController currentData] maxDateTime]]+(dayShift * DAY_SECONDS);
    long earliestDayAsDateTime = [EpochTime epochTimeAtZeroHour:[dataController getMinDataDateTimeForPair:[[dataController currentData] name]]];
    //long earliestDayAsDateTime = [EpochTime epochTimeAtZeroHour:[self getMinDateTimeForID:[[dataController currentData] dbId]]];
    if(newDayAsDateTime >= earliestDayAsDateTime){
        [dataRangeMoveValue setEnabled:NO];
        [shiftDataRangeForward setEnabled:NO];
        [shiftDataRangeBack setEnabled:NO];
        [setupButton  setEnabled:NO];
        [leftSideProgressBar setHidden:NO];
        [leftSideProgressBar startAnimation:nil];
        [formData  setObject:[NSNumber numberWithInt:(dayShift * DAY_SECONDS)] forKey:DATA_SHIFT_SECONDS];
        [formData setObject:leftPanelStatusLabel forKey:STATUS_TEXTFIELD]; 
        if(THREADS){
            [self performSelectorInBackground:@selector(shiftData) withObject:nil];
        }else{
            [self shiftData];
        }
    }
}

- (IBAction)dataRangeMoveForward:(id)sender {
    int dayShift = [dataRangeMoveValue intValue];
    long newDayAsDateTime =  [EpochTime epochTimeAtZeroHour:[[dataController currentData] maxDateTime]]+ (dayShift * DAY_SECONDS);
    long latestDayAsDateTime = [EpochTime epochTimeAtZeroHour:[dataController getMaxDataDateTimeForPair:[[dataController currentData] name]]];    if(newDayAsDateTime <= latestDayAsDateTime){
        [dataRangeMoveValue setEnabled:NO];
        [shiftDataRangeForward setEnabled:NO];
        [shiftDataRangeBack setEnabled:NO];
        [setupButton  setEnabled:NO];
        [leftSideProgressBar setHidden:NO];
        [leftSideProgressBar startAnimation:nil];
        [formData  setObject:[NSNumber numberWithInt:(dayShift * DAY_SECONDS)] forKey:DATA_SHIFT_SECONDS];
        [formData setObject:leftPanelStatusLabel forKey:STATUS_TEXTFIELD]; 
        if(THREADS){
            [self performSelectorInBackground:@selector(shiftData) withObject:nil];
        }else{
            [self shiftData];
        }

    }
}

- (IBAction)setupViaMenu:(id)sender {
    [setupDataButton setEnabled:YES];
    [pairPicker setEnabled:YES];
    [datePicker setEnabled:YES];
    [shortTermHistory setEnabled:YES];
    [longTermHistory setEnabled:YES];
    [intraDaySamplingValue setEnabled:YES];
    [intraDaySamplingUnit setEnabled:YES];
    [shortTermSamplingValue setEnabled:YES];
    [shortTermSamplingUnit setEnabled:YES];
    [longTermSamplingValue setEnabled:YES];
    [longTermSamplingUnit setEnabled:YES];
    
    //Not yet, this is to show cancel that the setup button has been pressed
    doingSetup = NO;
    
    [NSApp beginSheet:setupSheet modalForWindow:[mainTabs window] modalDelegate:nil didEndSelector:NULL contextInfo:NULL];
}

- (IBAction)plotPositions:(id)sender {
    [plotPositionsButton setEnabled:NO];
    [accountsController createDataSeriesWithAccountInformation:@"TEST"];
    [plotPositionsButton setEnabled:YES];
}

- (IBAction)simZoomRadioChange:(id)sender {
    if([sender selectedColumn] == 0)
    {
        [simZoomButton setEnabled:NO];
    }else{
        [simZoomButton setEnabled:YES];
        simDataZoomSelectFrom = YES;
    }
}

- (IBAction)simZoomButtonDown:(id)sender {
    long fromDateTime, toDateTime;
    fromDateTime = [[simZoomFromDatePicker dateValue] timeIntervalSince1970];
    toDateTime = [[simZoomToDatePicker dateValue] timeIntervalSince1970];
    if(fromDateTime < toDateTime){
        if(fromDateTime == [simData minDateTime] && toDateTime == [simData maxDateTime]){
            [plot4 setData:simData WithViewName:@"ALL"];
            [plot4 renderPlotWithFields:simulationTimeSeries];
        }else{
            [simData setPlotViewWithName:@"ZOOM" AndStartDateTime:fromDateTime AndEndDateTime:toDateTime];
            [plot4 setData:simData WithViewName:@"ZOOM"];
            [plot4 renderPlotWithFields:simulationTimeSeries];
        }
    }
    [simZoomOnOffButtons selectCellAtRow:0 column:0];
}

- (IBAction)simZoomResetButtonDown:(id)sender {
    if(simData != nil){
        [simZoomOnOffButtons selectCellAtRow:0 column:0];
        [simZoomButton setEnabled:NO];
        [simZoomFromDatePicker setMinDate:[NSDate dateWithTimeIntervalSince1970:(NSTimeInterval) [simData minDateTime]]]; 
        [simZoomFromDatePicker setMaxDate:[NSDate dateWithTimeIntervalSince1970:(NSTimeInterval) [simData maxDateTime]]]; 
        [simZoomFromDatePicker setDateValue:[NSDate dateWithTimeIntervalSince1970:(NSTimeInterval) [simData minDateTime]]];
    
        [simZoomToDatePicker setMinDate:[NSDate dateWithTimeIntervalSince1970:(NSTimeInterval) [simData minDateTime]]]; 
        [simZoomToDatePicker setMaxDate:[NSDate dateWithTimeIntervalSince1970:(NSTimeInterval) [simData maxDateTime]]]; 
        [simZoomToDatePicker setDateValue:[NSDate dateWithTimeIntervalSince1970:(NSTimeInterval) [simData maxDateTime]]];
        
        [self simulationPlotZoom];
    }
}


#pragma mark -
#pragma mark Simulation Output Methods


-(void)gettingDataIndicatorSwitchOn
{
    [leftPanelStatusLabel setHidden:NO];
    [leftPanelStatusLabel setStringValue:@"Retrieving from database"];
    [leftSideProgressBar setHidden:NO];
    [leftSideProgressBar startAnimation:nil];
}

-(void)gettingDataIndicatorSwitchOff
{
    [leftSideProgressBar stopAnimation:nil];
    [leftPanelStatusLabel setStringValue:@""];
    [leftSideProgressBar setHidden:YES];
    [leftPanelStatusLabel setHidden:YES];
}

-(void) sendGraphClickDateTimeValue: (long) dateTime
{
    if([simZoomOnOffButtons selectedColumn]==1){
        if(simDataZoomSelectFrom){
            if((double)dateTime < [[simZoomToDatePicker dateValue] timeIntervalSince1970]){
                [simZoomFromDatePicker setDateValue:[NSDate dateWithTimeIntervalSince1970:(NSTimeInterval) dateTime]];
                simDataZoomSelectFrom = NO;
            }
        }else{
            if((double)dateTime > [[simZoomFromDatePicker dateValue] timeIntervalSince1970])
            {
                [simZoomToDatePicker setDateValue:[NSDate dateWithTimeIntervalSince1970:(NSTimeInterval) dateTime]];
                simDataZoomSelectFrom = YES;
            }
        }
    }
}


//This function is redundant

//-(void)changeBaseDataRange:(int)dayShift
//{
//    //NSDate *newCurrentDay;
//    
//    
//    
//    // create a calendar to use for date ranges
//    //NSCalendar *gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
//    // set up date components
//    //NSDateComponents *components = [[NSDateComponents alloc] init];
//    
//    //[components setDay:dayShift];
//    //newCurrentDay = [gregorian dateByAddingComponents:components toDate:currentDay options:0];
//    //NSNumber *startShift;
//    //NSNumber *endShift;
//    
//    //endShift = [NSNumber numberWithInt:dayShift*24*60*60];
//    
//    //[formData  setObject:dayShiftInSeconds forKey:@"DATASHIFT"];
//    //[formData setObject:leftPanelStatusLabel forKey:@"STATUSTEXTFIELD"];   
//    if(THREADS){
//        [self performSelectorInBackground:@selector(shiftData) withObject:nil];
//    }else{
//        [self shiftData:dayShift*DAY_SECONDS];
//    }
//        
//}

-(void)shiftData;
{
    int dataShiftInSeconds = [[formData  objectForKey:DATA_SHIFT_SECONDS] intValue];
    NSTextField *statusTextField =  [formData  objectForKey:STATUS_TEXTFIELD];
    cancelProcedure = NO;
    [statusTextField setHidden:NO];
    [self setStatusLabel:statusTextField WithMessage:@"Requesting from database"];
    
    long newStartDateTime, newEndDateTime; 
    newStartDateTime = [EpochTime epochTimeAtZeroHour:[[dataController currentData] minDateTime]] + dataShiftInSeconds;
    newEndDateTime = [EpochTime epochTimeNextDayAtZeroHour:[[dataController currentData] maxDateTime]] -1 + dataShiftInSeconds;
    [dataController setBidAskMidForStartDateTime: newStartDateTime 
                            AndEndDateTime: newEndDateTime];
    //[dataController adjustRangeOfDataSeries:baseData AtStart:startAdjust AndEnd:endAdjust];
    
//    [self setStatusLabel:statusTextField WithMessage:@"Calculating EWMA"];
//    for(int i = 12; i <= 24; i= i + 2){
//        int param = [self fib:i];
//        [self setStatusLabel:statusTextField WithMessage:[NSString stringWithFormat:@"Calculating EWMA%d",param]];
//        [dataController addEWMAWithParameter:[self fib:i]];
//    }

    
    [self setupPlots];
    
    [self setCurrentDay:[NSDate dateWithTimeIntervalSince1970:[[dataController currentData] maxDateTime]]];
    if(THREADS){
        [self performSelectorOnMainThread:@selector(endDataShift) withObject:nil waitUntilDone:YES];
    }else{
        [self endDataShift];
        
    }
}

-(void)endDataShift
{
    [dataRangeMoveValue setEnabled:YES];
    [shiftDataRangeForward setEnabled:YES];
    [shiftDataRangeBack setEnabled:YES];
    [setupButton  setEnabled:YES];
    [leftSideProgressBar stopAnimation:nil];
    [leftSideProgressBar setHidden:YES];
    [leftPanelStatusLabel setHidden:YES];

    [currentDateLabel setStringValue:[currentDay descriptionWithCalendarFormat:@"%a %Y-%m-%d" timeZone:[NSTimeZone timeZoneWithName:@"GMT"] locale:nil]];
}





//- (void)controlTextDidChange:(NSNotification *)obj
//{
//    NSLog(@"Check");
//    if([filterValue intValue] >= 1)
//    {
//        [filterValue setStringValue:[NSString stringWithFormat:@"%d",[filterValue intValue]]];
//    }else{
//        [filterValue setStringValue:@"1"];
//    }
//}  


#pragma mark -
#pragma mark TableView Methods

- (void)tableView:(NSTableView *)tableView didClickTableColumn:(NSTableColumn *)tableColumn
{
    SeriesPlot *plot;
    NSMutableArray *timeSeries;
    if([[tableColumn identifier] isEqualToString:@"visible"]){
        if([[tableView identifier] isEqualToString:@"LTTSTV"]){
            TimeSeriesLine *tsl;
            for(tsl in longTermTimeSeries)
            {
                [tsl setVisible:NO];
            }
            timeSeries = longTermTimeSeries;
            plot = plot3;
        }
        if([[tableView identifier] isEqualToString:@"STTSTV"]){
            TimeSeriesLine *tsl;
            for(tsl in shortTermTimeSeries)
            {
                [tsl setVisible:NO];
            }
            timeSeries = shortTermTimeSeries;
            plot = plot2;
        }
        if([[tableView identifier] isEqualToString:@"IDTSTV"]){
            TimeSeriesLine *tsl;
            for(tsl in intraDayTimeSeries)
            {
                [tsl setVisible:NO];
            }
            timeSeries = intraDayTimeSeries;
            plot = plot1;
        }
        [plot renderPlotWithFields:timeSeries];
        [tableView deselectColumn:[tableView selectedColumn]];
    }
}


- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView{
    if([[tableView identifier] isEqualToString:@"LTTSTV"]){
        return [longTermTimeSeries count]; 
    }
    if([[tableView identifier] isEqualToString:@"STTSTV"]){
        return [shortTermTimeSeries count]; 
    }
    if([[tableView identifier] isEqualToString:@"IDTSTV"]){
        return [intraDayTimeSeries count]; 
    }
    if([[tableView identifier] isEqualToString:@"SIMTV"]){
        return [simulationTimeSeries count]; 
    }
    return 0;
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    TimeSeriesLine *tsl;
    if([[tableView identifier] isEqualToString:@"LTTSTV"]){
        tsl = [longTermTimeSeries objectAtIndex:row];
    }
    if([[tableView identifier] isEqualToString:@"STTSTV"]){
        tsl = [shortTermTimeSeries objectAtIndex:row];
    }
    if([[tableView identifier] isEqualToString:@"IDTSTV"]){
        tsl = [intraDayTimeSeries objectAtIndex:row];
    }
    if([[tableView identifier] isEqualToString:@"SIMTV"]){
        tsl = [simulationTimeSeries objectAtIndex:row];
    }
    NSString *column = [tableColumn identifier];
    return [tsl valueForKey:column];
    
}

- (void)tableView:(NSTableView *)tableView setObjectValue:(id) obj forTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    TimeSeriesLine *tsl;
    SeriesPlot *plot;
    NSMutableArray *timeSeries;
    if([[tableView identifier] isEqualToString:@"LTTSTV"]){
        tsl = [longTermTimeSeries objectAtIndex:row];
        plot = plot3;
        timeSeries = longTermTimeSeries;
    }
    if([[tableView identifier] isEqualToString:@"STTSTV"]){
        tsl = [shortTermTimeSeries objectAtIndex:row];
        plot = plot2;
        timeSeries = shortTermTimeSeries;
    }
    if([[tableView identifier] isEqualToString:@"IDTSTV"]){
        tsl = [intraDayTimeSeries objectAtIndex:row];
        plot = plot1;
        timeSeries = intraDayTimeSeries;
    }
    if([[tableView identifier] isEqualToString:@"SIMTV"]){
        tsl = [simulationTimeSeries objectAtIndex:row];
        plot = plot4;
        timeSeries = simulationTimeSeries;
    }
    NSString *column = [tableColumn identifier];
    [tsl setValue:obj forKey:column]; 
    [plot renderPlotWithFields:timeSeries];
}

-(void)clearTSTableView:(NSTableView *)tableView
{
    if([[tableView identifier] isEqualToString:@"LTTSTV"]){
        [longTermTimeSeries removeAllObjects];
        [longTermTimeSeriesTableView reloadData];
    }
    if([[tableView identifier] isEqualToString:@"STTSTV"]){
        [shortTermTimeSeries removeAllObjects];
        [shortTermTimeSeriesTableView reloadData];
    }
    if([[tableView identifier] isEqualToString:@"IDTSTV"]){
        [intraDayTimeSeries removeAllObjects];
        [intraDayTimeSeriesTableView reloadData];
    }
    if([[tableView identifier] isEqualToString:@"SIMTV"]){
        [simulationTimeSeries removeAllObjects];
        [simulationTimeSeriesTableView reloadData];
    }
    if([[tableView identifier] isEqualToString:@"SIMDATATV"]){
        [simulationTimeSeries removeAllObjects];
        //[simulationTimeSeriesTableView reloadData];
    } 
}

-(void)addToTableView:(NSTableView *)tableView TimeSeriesLine: (TimeSeriesLine *)TSLine
{
    if([[tableView identifier] isEqualToString:@"LTTSTV"]){
        [longTermTimeSeries addObject:TSLine];
    }
    if([[tableView identifier] isEqualToString:@"STTSTV"]){
        [shortTermTimeSeries addObject:TSLine];
    }
    if([[tableView identifier] isEqualToString:@"IDTSTV"]){
        [intraDayTimeSeries addObject:TSLine];
    }   
    if([[tableView identifier] isEqualToString:@"SIMTV"]){
        [simulationTimeSeries addObject:TSLine];
    }
    [tableView reloadData];
}

-(void)flickrSetupMessage
{
    NSArray *colorArray = [NSArray arrayWithObjects:[NSColor blackColor],[NSColor darkGrayColor],[NSColor grayColor],[NSColor lightGrayColor],[NSColor whiteColor],[NSColor lightGrayColor],[NSColor grayColor],[NSColor darkGrayColor], [NSColor blackColor] , nil];
    if(timerCount < 27)
    {
        //[leftPanelStatusLabel setHidden:![leftPanelStatusLabel isHidden]];
        [leftPanelStatusLabel setTextColor:[colorArray objectAtIndex:timerCount%9]];
        timerCount++;
    }else{
        //[leftPanelStatusLabel setHidden:NO];
        [leftPanelStatusLabel setTextColor:[NSColor blackColor]];
        [timer invalidate];
        timer = nil;
    }
}

-(void)clearSimulationMessage
{
    NSMutableString *message;
    message = [[sumulationDetails textStorage] mutableString];
    if([message length]>0)
    {
        [message deleteCharactersInRange:NSMakeRange(0, [message length]-1)];
    }
}

- (void)outputSimulationMessage:(NSString *) message
{
    [[[sumulationDetails textStorage] mutableString] appendString:message];
    [[[sumulationDetails textStorage] mutableString] appendString:@"\n"];
}


#pragma mark -
#pragma mark TabView Delegate Methods

-(void)tabView:(NSTabView *) tabView didSelectTabViewItem:(NSTabViewItem *) tabViewItem
{
    if([[tabView identifier] isEqual:@"mainTabs"])
    {
        [sideTabs selectTabViewItemWithIdentifier:[tabViewItem identifier]];  
    }
}

-(BOOL) tabView:(NSTabView *) tabView shouldSelectTabViewItem:(NSTabViewItem *)tabViewItem
{
    if(!initialSetupComplete){
        timerCount = 0;
        [leftPanelStatusLabel setHidden:NO];
        timer = [NSTimer scheduledTimerWithTimeInterval:0.02 
                                                   target:self 
                                                 selector:@selector(flickrSetupMessage)
                                                 userInfo:nil
                                                  repeats:YES];

    }
    //return initialSetupComplete;
    return YES;
}

#pragma mark -
#pragma mark Private Class Methods


-(int)fib:(int)n
{
    int first = 1;
    int second = 1;
    int temp;
    if(n == 1){
        return first;
    }
    if(n == 2){
        return second;
    }
    for(int i = 3; i <= n; i++){
        if(i == n){
            return first + second;
        }else{
            temp = first;
            first = second;
            second = temp + second;
        }
        
    }
    return 0;
}



@end
