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


#define START_TIME_FOR_ID_PLOT 2

#define FX_PAIR @"FXPAIR"
#define LT_DAYS @"LTDAYS"
#define ST_DAYS @"STDAYS"
#define LT_SAMPLE_SECS @"LTSAMPLESECS"
#define ST_SAMPLE_SECS @"STSAMPLESECS"
#define ID_SAMPLE_SECS @"IDSAMPLESECS"
#define SELECTED_DAY @"SELECTEDDAY"    
#define STATUS_TEXTFIELD @"STATUSTEXTFIELD"
#define DATA_SHIFT_SECONDS @"DATASHIFTSECONDS"
#define FIELDS_REQUESTED @"DATAFIELDSREQUESTED"


@interface InteractiveTradeViewController ()
-(bool) setupData;
-(void) setupPlots;
-(void) setupDataAndPlots;
-(NSArray *)getFieldNamesInCorrectOrdering:(NSArray *) fieldNamesFromData;
-(void)gettingDataIndicatorSwitchOn;
-(void)gettingDataIndicatorSwitchOff;
@end

@implementation InteractiveTradeViewController
@synthesize fxPairsAndDbIds;
@synthesize showSetupSheetButton;
@synthesize intraDayMoveForwardBox;
@synthesize intraDayMoveForwardButton;
@synthesize intraDayEndTimeGMTLabel;
@synthesize intraDayMoveForwardMinutesLabel;
@synthesize longTermDataSeriesSamplingRate;
@synthesize shortTermDataSeriesSamplingRate;
@synthesize rightSideTabView;
@synthesize intraDayDataSeriesSamplingRate;
@synthesize doThreads;
//@synthesize setUpProgressIndicator;
@synthesize intraDayFXPairLabel;
@synthesize shortTermFXPairLabel;
@synthesize longTermFXPairLabel;
@synthesize intraDayTimeSeriesScrollView;
@synthesize shortTermTimeSeriesScrollView;
@synthesize longTermTimeSeriesScrollView;
@synthesize setUpStatusLabel;
@synthesize centreTabs;
@synthesize setupSheet;
@synthesize dataSeriesTextField;
@synthesize setupDataButton;
@synthesize longTermSamplingUnit;
@synthesize longTermSamplingValue;
@synthesize longTermHistoryLength;
@synthesize shortTermSamplingUnit;
@synthesize shortTermSamplingValue;
@synthesize shortTermHistoryLength;
@synthesize intraDaySamplingUnit;
@synthesize intraDaySamplingValue;

@synthesize intraDayDayOfWeekLabel;
@synthesize intraDayDatePicker;
@synthesize dataAvailabilityToLabel;
@synthesize dataAvailabilityFromLabel;
@synthesize fxPairPopUp;

@synthesize intraDayTimeSeries;
@synthesize shortTermTimeSeries;
@synthesize longTermTimeSeries;

@synthesize intraDayDateTimeLabel;
@synthesize intraDayMoveForwardTextField;

@synthesize intraDayTimeSeriesTableView;
@synthesize shortTermTimeSeriesTableView;
@synthesize longTermTimeSeriesTableView;


@synthesize intraDayGraphHostingView;
@synthesize shortTermGraphHostingView;
@synthesize longTermGraphHostingView;


@synthesize coloursForPlots;
@synthesize fieldNameOrdering;

//NSTimer *timer;
//int timerCount;

-(id)init{
    self = [super initWithNibName:@"InteractiveTrade" bundle:nil];
    if(self){
        [self setTitle:@"Interactive"];
        
        [self setDoThreads:NO];
        doingSetup = NO;
        cancelProcedure = NO;
        initialSetupComplete = NO;
  
        dataController = [[DataController alloc] init];
        
    }
    return self;
}

-(void)awakeFromNib
{
    NSString *selectedFXPair;
    long initialMinDateTime;
    long initialMaxDateTime;

    
    
    intraDayPlot = [[SeriesPlot alloc] init];
    [intraDayPlot setHostingView:intraDayGraphHostingView];
    [intraDayPlot initialGraphAndAddAnnotation:NO];
    
    shortTermPlot = [[SeriesPlot alloc] init];
    [shortTermPlot setHostingView:shortTermGraphHostingView];
    [shortTermPlot initialGraphAndAddAnnotation:NO];
    
    longTermPlot = [[SeriesPlot alloc] init];
    [longTermPlot setHostingView:longTermGraphHostingView];
    [longTermPlot initialGraphAndAddAnnotation:NO];
    
    
    NSTableColumn *intraDayColourColumn =  [intraDayTimeSeriesTableView tableColumnWithIdentifier:@"colourId"];
    NSTableColumn *shortTermColourColumn =  [shortTermTimeSeriesTableView tableColumnWithIdentifier:@"colourId"];
    NSTableColumn *longTermColourColumn =  [longTermTimeSeriesTableView tableColumnWithIdentifier:@"colourId"];
    
    
    
    NSPopUpButtonCell *intraDayColourDropDownCell = [[NSPopUpButtonCell alloc] init];
    NSPopUpButtonCell *shortTermColourDropDownCell = [[NSPopUpButtonCell alloc] init];
    NSPopUpButtonCell *longTermColourDropDownCell = [[NSPopUpButtonCell alloc] init];
    
    [intraDayColourDropDownCell setBordered:NO];
    [intraDayColourDropDownCell setEditable:YES];
    [shortTermColourDropDownCell setBordered:NO];
    [shortTermColourDropDownCell setEditable:YES];    
    [longTermColourDropDownCell setBordered:NO];
    [longTermColourDropDownCell setEditable:YES]; 
    
    
    
    [intraDayColourDropDownCell addItemsWithTitles:coloursForPlots];
    [intraDayColourColumn setDataCell:intraDayColourDropDownCell];
    [shortTermColourDropDownCell addItemsWithTitles:coloursForPlots];
    [shortTermColourColumn setDataCell:shortTermColourDropDownCell];
    [longTermColourDropDownCell addItemsWithTitles:coloursForPlots];
    [longTermColourColumn setDataCell:longTermColourDropDownCell];
    
    [intraDayTimeSeriesTableView setDataSource:self];
    [shortTermTimeSeriesTableView setDataSource:self];
    [longTermTimeSeriesTableView setDataSource:self];
    
    intraDayTimeSeries = [[NSMutableArray alloc] init];
    shortTermTimeSeries = [[NSMutableArray alloc] init];
    longTermTimeSeries = [[NSMutableArray alloc] init];
    
    //NSDictionary *listOfFXPairs;
    //listOfFXPairs = [dataController fxPairs];
    NSArray *pairNames = [fxPairsAndDbIds allKeys];
    
    [fxPairPopUp removeAllItems];
    for (int i = 0; i < [pairNames count];i++) {
        [fxPairPopUp addItemWithTitle:[pairNames objectAtIndex:i]];
    }
    
    [fxPairPopUp selectItemAtIndex:0];
    
    selectedFXPair = [[fxPairPopUp selectedItem] title];
    initialMinDateTime = [dataController getMinDataDateTimeForPair:selectedFXPair];
    initialMaxDateTime = [dataController getMaxDataDateTimeForPair:selectedFXPair];
    
    [dataAvailabilityFromLabel setStringValue:[[NSDate dateWithTimeIntervalSince1970:(NSTimeInterval) initialMinDateTime] descriptionWithCalendarFormat:@"%Y-%m-%d" timeZone:[NSTimeZone timeZoneWithName:@"GMT"] locale:nil]];
    [dataAvailabilityToLabel setStringValue:[[NSDate dateWithTimeIntervalSince1970:(NSTimeInterval) initialMaxDateTime] descriptionWithCalendarFormat:@"%Y-%m-%d" timeZone:[NSTimeZone timeZoneWithName:@"GMT"] locale:nil]];
    
    NSCalendar *gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
    [intraDayDatePicker setTimeZone:[NSTimeZone timeZoneWithName:@"GMT"]];
    [intraDayDatePicker setCalendar:gregorian];
    
    [intraDayDatePicker setMinDate:[NSDate dateWithTimeIntervalSince1970:(NSTimeInterval) initialMinDateTime]];
    [intraDayDatePicker setMaxDate:[NSDate dateWithTimeIntervalSince1970:(NSTimeInterval) initialMaxDateTime]];
    [intraDayDatePicker setDateValue:[NSDate dateWithTimeIntervalSince1970:(NSTimeInterval) ((initialMinDateTime+initialMaxDateTime )/2)]]; 
    [intraDayDayOfWeekLabel setStringValue:[[intraDayDatePicker dateValue] descriptionWithCalendarFormat:@"%a" timeZone:[NSTimeZone timeZoneWithName:@"GMT"] locale:nil]]; 
    
    userInputFormData = [[NSMutableDictionary alloc] init];
    [centreTabs selectTabViewItemWithIdentifier:@"ID"];
    
    hideObjectsOnStartup = [NSArray arrayWithObjects:intraDayTimeSeriesScrollView, shortTermTimeSeriesScrollView, longTermTimeSeriesScrollView, intraDayMoveForwardTextField, intraDayDateTimeLabel, intraDayDataSeriesSamplingRate, shortTermDataSeriesSamplingRate,longTermDataSeriesSamplingRate, intraDayFXPairLabel, shortTermFXPairLabel, longTermFXPairLabel, intraDayMoveForwardMinutesLabel,intraDayEndTimeGMTLabel,intraDayMoveForwardButton,intraDayMoveForwardBox, nil];
    
    
    for(int i =0; i < [hideObjectsOnStartup count];i++){
        [[hideObjectsOnStartup objectAtIndex:i] setHidden:YES];
    }
    
    
    disableObjectsOnSetup = [NSArray arrayWithObjects:setupDataButton, fxPairPopUp, intraDayDatePicker, shortTermHistoryLength, longTermHistoryLength, intraDaySamplingValue, intraDaySamplingUnit, shortTermSamplingValue, shortTermSamplingUnit, longTermSamplingValue, longTermSamplingUnit, dataSeriesTextField, nil];

    [centreTabs selectTabViewItemWithIdentifier:@"ID"];
    [rightSideTabView selectTabViewItemWithIdentifier:@"ID"];
    
    [centreTabs setDelegate:self];
}


-(void)setDelegate:(id)del
{
    delegate = del;
}

-(id)delegate 
{ 
    return delegate;
};

- (IBAction)setupViaMenu:(id)sender {
    
    for(int i = 0; i < [disableObjectsOnSetup count]; i++)
    {
        [[disableObjectsOnSetup objectAtIndex:i] setEnabled:YES];
    }
    
   //Not yet, this is to show cancel that the setup button has been pressed
    doingSetup = NO;
    
    [NSApp beginSheet:setupSheet modalForWindow:[centreTabs window] modalDelegate:nil didEndSelector:NULL contextInfo:NULL];
}

- (IBAction)cancelSetupSheet:(id)sender {
    cancelProcedure = YES;
    [setUpStatusLabel setStringValue:@"Trying to cancel..."];
    //[self setStatusLabel:setUpStatusLabel WithMessage:@"Trying to cancel..."];
    if(doingSetup == NO){
        [self endSetupSheet];
    }
}

-(void)endSetupSheet
{
    // Don't change this stuff if you are cancelling
    if(cancelProcedure == NO)
    {
        [intraDayFXPairLabel setHidden:NO];
        [shortTermFXPairLabel setHidden:NO];
        [longTermFXPairLabel setHidden:NO];
        
        [longTermTimeSeriesScrollView setHidden:NO];
        [shortTermTimeSeriesScrollView setHidden:NO];
        [intraDayTimeSeriesScrollView setHidden:NO];
        [intraDayFXPairLabel setStringValue:[[fxPairPopUp selectedItem] title]];
        [shortTermFXPairLabel setStringValue:[[fxPairPopUp selectedItem] title]];
        [longTermFXPairLabel setStringValue:[[fxPairPopUp selectedItem] title]];
        
        for(int i =0; i < [hideObjectsOnStartup count];i++){
            [[hideObjectsOnStartup objectAtIndex:i] setHidden:NO];
        }

        
//        [intraDayCurrentDayLabel setStringValue:[currentDay descriptionWithCalendarFormat:@"%a %Y-%m-%d" timeZone:[NSTimeZone timeZoneWithName:@"GMT"] locale:nil]];
        [centreTabs selectTabViewItemWithIdentifier:@"ID"];
        
        //[dataRangeMoveValue setHidden:NO];
        //[shiftDataRangeBack setHidden:NO];
        //[shiftDataRangeForward setHidden:NO];
        //[shiftDataDaysLabel setHidden:NO];
        
        initialSetupComplete = YES;
    }
    
    //[setUpProgressIndicator setHidden:YES];
    //[setUpProgressIndicator stopAnimation:nil];
    [setUpStatusLabel setHidden:YES];
    //[leftPanelStatusLabel setHidden:YES];
    
    if(cancelProcedure == NO)
    {
        [NSApp endSheet:setupSheet returnCode: NSOKButton];
    }else{
        [NSApp endSheet:setupSheet returnCode: NSCancelButton];
    }
    
    for(int i = 0; i < [disableObjectsOnSetup count]; i++)
    {
        [[disableObjectsOnSetup objectAtIndex:i] setEnabled:YES];
    }
    [setupSheet orderOut:nil];
}

- (IBAction)setUp:(id)sender
{
    //NSString *selectedItem = [[pairPicker selectedItem] title];
    //NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    //[dateFormatter setDateStyle:NSDateFormatterMediumStyle];
    NSDate *selectedDay = [intraDayDatePicker  dateValue];
    NSString *selectedFXPair = [[fxPairPopUp selectedItem] title];
    int daysForLTHistory = [longTermHistoryLength intValue];
    int daysForSTHistory = [shortTermHistoryLength intValue];
    int longTermDataSampleSeconds, shortTermDataSampleSeconds, intraDayDataSampleSeconds;
    NSString *fieldsRequestedString;
    NSArray *fieldsRequestedCodes;
    NSMutableArray *fieldsRequested;
    
    // Got this code at www.red-sweater.com/blog/229/stay-responsive
    if([[sender window] makeFirstResponder:[sender window]]){
        //Try end editing this way
    }else{
        [[sender window] endEditingFor:nil];   
    }
    
    for(int i = 0; i < [disableObjectsOnSetup count]; i++)
    {
        [[disableObjectsOnSetup objectAtIndex:i] setEnabled:NO];
    }
    
    cancelProcedure = NO;
    doingSetup = YES;
    
    //[setUpProgressIndicator setHidden:NO];
    //[setUpProgressIndicator startAnimation:sender];
    //[setUpStatusLabel setStringValue:@"Loading data"];
    //[setUpStatusLabel setHidden:NO];
    
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
    fieldsRequestedString = [NSString stringWithString:[dataSeriesTextField stringValue]];
    fieldsRequestedCodes = [fieldsRequestedString componentsSeparatedByString:@"/"];
    fieldsRequested = [[NSMutableArray alloc] init];
    NSString *stringToInterpret;
    BOOL found = NO;
    for(int i = 0; i < [fieldsRequestedCodes count]; i++){
        stringToInterpret = [fieldsRequestedCodes objectAtIndex:i];
        if([stringToInterpret length] == 1){
            if([stringToInterpret isEqualToString:@"B"]){
                [fieldsRequested addObject:@"BID"];
                found = YES;
            }
            if([stringToInterpret isEqualToString:@"A"]){
                [fieldsRequested addObject:@"ASK"];
                found = YES;
            }
            if([stringToInterpret isEqualToString:@"M"]){
                [fieldsRequested addObject:@"MID"];
                found = YES;
            }
        }
        if([stringToInterpret length] > 3){
            NSString *firstThree = [stringToInterpret substringToIndex:3];
            if([firstThree isEqualToString:@"EMA"]){
                NSString *emaParamString = [stringToInterpret substringFromIndex:3];
                NSArray *emaParamArray = [emaParamString componentsSeparatedByString:@":"];
                if([emaParamArray count]==3 && ([[emaParamArray objectAtIndex:1] intValue] < [[emaParamArray objectAtIndex:0] intValue])){
                    for(int j = [[emaParamArray objectAtIndex:0] intValue]; j <= [[emaParamArray objectAtIndex:2] intValue];j = j + [[emaParamArray objectAtIndex:1] intValue]){
                        [fieldsRequested addObject:[NSString stringWithFormat:@"EWMA%d",j]];
                    }
                    
                }
                if([emaParamArray count]==2 && ([[emaParamArray objectAtIndex:0] intValue] < [[emaParamArray objectAtIndex:1] intValue])){
                    for(int j = [[emaParamArray objectAtIndex:0] intValue]; j <= [[emaParamArray objectAtIndex:1] intValue];j = j++){
                        [fieldsRequested addObject:[NSString stringWithFormat:@"EWMA%d",j]];
                    }
                }
                if([emaParamArray count]==1){
                    [fieldsRequested addObject:[NSString stringWithFormat:@"EWMA%d",[[emaParamArray objectAtIndex:0] intValue]]];
                }
            }
        }
    }
    
    userInputFormData = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                         selectedFXPair,FX_PAIR,
                         [NSNumber numberWithInt:daysForLTHistory],LT_DAYS,
                         [NSNumber numberWithInt:daysForSTHistory],ST_DAYS,
                         [NSNumber numberWithInt:longTermDataSampleSeconds],LT_SAMPLE_SECS,
                         [NSNumber numberWithInt:shortTermDataSampleSeconds], ST_SAMPLE_SECS,
                         [NSNumber numberWithInt:intraDayDataSampleSeconds], ID_SAMPLE_SECS,
                         setUpStatusLabel, STATUS_TEXTFIELD,
                         fieldsRequested, FIELDS_REQUESTED,
                         selectedDay,SELECTED_DAY,    
                nil];
    
    //[self performSelectorInBackground:@selector(setupDataAndPlots) withObject:formInfo];
    //[self setupDataAndPlots:formInfo];
    //[self performSelectorInBackground:@selector(setupData) withObject:nil];
    if(doThreads){
        [self performSelectorInBackground:@selector(setupDataAndPlots) withObject:nil];
    }else{
        [self setupDataAndPlots];
    }
    
}

-(void)setupDataAndPlots
{
    if([self setupData]){
        [self setupPlots];
    }else{
        //[setUpProgressIndicator setHidden:YES];
        //[setUpProgressIndicator stopAnimation:nil];
        [setUpStatusLabel setHidden:YES];
    }
    
}

-(bool)setupData
{
    bool success; 
    NSTextField *statusTextField;
    long dateStartTimeFullData, dateEndTimeFullData;
    int daysLT;
    NSString *pairName;
    NSDate *selectedDay;
    NSMutableArray *fieldsRequested;
    
    // create a calendar to use for date ranges
    NSCalendar *gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
    // set up date components
    NSDateComponents *components = [[NSDateComponents alloc] init];
    
    pairName = [userInputFormData objectForKey:FX_PAIR];
    daysLT = [[userInputFormData objectForKey:LT_DAYS] intValue]; 
    selectedDay = [userInputFormData objectForKey:SELECTED_DAY];
    statusTextField = [userInputFormData objectForKey:STATUS_TEXTFIELD];
    fieldsRequested = [userInputFormData objectForKey:FIELDS_REQUESTED];

    [setUpStatusLabel setStringValue:@"Requesting from database"];
    //Full data 
    [components setDay:-(2*daysLT)];
    dateStartTimeFullData = [EpochTime epochTimeAtZeroHour:[[gregorian dateByAddingComponents:components toDate:selectedDay options:0]  timeIntervalSince1970]];
    dateEndTimeFullData = [EpochTime epochTimeNextDayAtZeroHour:[selectedDay timeIntervalSince1970]];
    // Get the data for the Long term Plot
    
    if(doThreads){
        [self performSelectorInBackground:@selector(gettingDataIndicatorSwitchOn) withObject:nil];
    }
    
    success = [dataController setupDataSeriesForName:pairName];
    if(success){
        success = [dataController getDataSeriesForStartDateTime:dateStartTimeFullData 
                                                 AndEndDateTime: dateEndTimeFullData];
    }
    if(doThreads){
        [self performSelectorInBackground:@selector(gettingDataIndicatorSwitchOff) withObject:nil];
    }
    if(cancelProcedure == NO)
    {
        if(success){
            [setUpStatusLabel setStringValue:[NSString stringWithFormat:@"Retrieved %d data",[dataController getDataSeriesLength]]];
        }else{
            [setUpStatusLabel setStringValue:@"Problem retrieving data"];
            return success;
        }
    
        for(int i = 0; i < [fieldsRequested count];i++){
            NSString *fieldRequested = [fieldsRequested objectAtIndex:i]; 
            if([fieldRequested length] > 4){
                if([[fieldRequested substringToIndex:4] isEqualToString:@"EWMA"]){
                
                    int ewmaNumber = [[fieldRequested substringFromIndex:4] intValue];
                    [setUpStatusLabel setStringValue:[NSString stringWithFormat:@"Calculating EWMA%d",ewmaNumber]];
                    [dataController addEWMAByIndex:ewmaNumber];
                }
            }
        }
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
    
    selectedPair = [userInputFormData objectForKey:FX_PAIR];
    daysLT = [[userInputFormData objectForKey:LT_DAYS] intValue]; 
    daysST = [[userInputFormData objectForKey:ST_DAYS] intValue];
    sampleLT = [[userInputFormData objectForKey:LT_SAMPLE_SECS] intValue];
    sampleST = [[userInputFormData objectForKey:ST_SAMPLE_SECS] intValue];
    sampleID = [[userInputFormData objectForKey:ID_SAMPLE_SECS] intValue];
    statusTextField = [userInputFormData objectForKey:STATUS_TEXTFIELD];

    [statusTextField setHidden:NO];
    lastDayOfDataDateTime = [[dataController dataSeries] maxDateTime];
    lastDayOfData = [NSDate dateWithTimeIntervalSince1970:lastDayOfDataDateTime];
    if(cancelProcedure == NO)
    {
        [setUpStatusLabel setStringValue:@"Creating Long Term Plot"];
        //Long term data
        [components setDay:-daysLT];
        dateStartTimeLongTerm = [EpochTime epochTimeAtZeroHour:[[gregorian dateByAddingComponents:components toDate:lastDayOfData options:0]  timeIntervalSince1970]];
        dateEndTimeLongTerm = [EpochTime epochTimeAtZeroHour:[lastDayOfData timeIntervalSince1970]];
        dataForLongTermPlot = [[dataController dataSeries] sampleDataAtInterval:sampleLT];
        [dataForLongTermPlot  setPlotViewWithName: @"LongTerm" AndStartDateTime: dateStartTimeLongTerm AndEndDateTime: dateEndTimeLongTerm];
    }
    
    if(cancelProcedure == NO)
    {
        [setUpStatusLabel setStringValue:@"Creating Short Term Plot"];
        //Short term data
        [components setDay:-daysST];
        dateStartTimeShortTerm = [EpochTime epochTimeAtZeroHour:[[gregorian dateByAddingComponents:components toDate:lastDayOfData options:0]  timeIntervalSince1970]];
        dateEndTimeShortTerm = [EpochTime epochTimeAtZeroHour:[lastDayOfData timeIntervalSince1970]];
        dataForShortTermPlot = [[dataController dataSeries] sampleDataAtInterval:sampleST];
        [dataForShortTermPlot  setPlotViewWithName: @"ShortTerm" AndStartDateTime: dateStartTimeShortTerm AndEndDateTime: dateEndTimeShortTerm];
    }
    
    //Intraday data
    if(cancelProcedure == NO)
    {
        [setUpStatusLabel setStringValue:@"Creating Intra-day Plot"];
        dateStartTimeIntraDay = [EpochTime epochTimeAtZeroHour:[lastDayOfData timeIntervalSince1970]];
        dateEndTimeIntraDay = dateStartTimeIntraDay + START_TIME_FOR_ID_PLOT*60*60;
        //int hours = (int)START_TIME_FOR_ID_PLOT;
        //int minutes = (int)((START_TIME_FOR_ID_PLOT - hours) * 60);
        //[intraDayTimeSlider setDoubleValue:START_TIME_FOR_ID_PLOT];
        
        long dataViewLastDateTime;
        if(sampleID <= [dataController dataGranularity]){
            [[dataController dataSeries]  setPlotViewWithName: @"IntraDay" AndStartDateTime: dateStartTimeIntraDay AndEndDateTime: dateEndTimeIntraDay];
            dataViewLastDateTime = [[[[dataController dataSeries] dataViews] objectForKey:@"IntraDay"] lastX];
        }else{
            dataForIntraDayPlot = [[dataController dataSeries] sampleDataAtInterval:sampleID];
            [dataForIntraDayPlot  setPlotViewWithName: @"IntraDay" AndStartDateTime: dateStartTimeIntraDay AndEndDateTime: dateEndTimeIntraDay];
            dataViewLastDateTime = [[[[dataController dataSeries] dataViews] objectForKey:@"IntraDay"] lastX];
        }
        [intraDayDateTimeLabel setStringValue:[EpochTime stringOfDateTimeForTime:dataViewLastDateTime WithFormat:@"%Y%m%d %H:%M:%S"]];
    } 
    
    if(cancelProcedure == NO)
    {    
        [self clearTSTableView:longTermTimeSeriesTableView];
        [self clearTSTableView:shortTermTimeSeriesTableView];
        [self clearTSTableView:intraDayTimeSeriesTableView];
        TimeSeriesLine *tsl;
        
        NSArray *fieldNames = [self getFieldNamesInCorrectOrdering:[[dataForLongTermPlot yData] allKeys]];
        NSString *lineColour;
        BOOL isVisible = NO;
        for(int i = 0; i < [fieldNames count];i++){
            switch (i) {
                case 0:
                    isVisible = YES;
                    break;
                default:
                    isVisible = NO;
                    break;
            }
            lineColour = [coloursForPlots objectAtIndex:i%[coloursForPlots count]];
            //Long Term
            tsl = [[TimeSeriesLine alloc] initWithVisibility:isVisible AndName:[fieldNames objectAtIndex:i] AndColour:lineColour];
            [self addToTableView:longTermTimeSeriesTableView   TimeSeriesLine:tsl];
            //Short Term
            tsl = [[TimeSeriesLine alloc] initWithVisibility:isVisible AndName:[fieldNames objectAtIndex:i] AndColour:lineColour];
            [self addToTableView:shortTermTimeSeriesTableView   TimeSeriesLine:tsl];
            //Intraday
            tsl = [[TimeSeriesLine alloc] initWithVisibility:isVisible AndName:[fieldNames objectAtIndex:i] AndColour:lineColour];
            [self addToTableView:intraDayTimeSeriesTableView   TimeSeriesLine:tsl];
        }
    }
    
    
    if(cancelProcedure == NO)
    {
        intraDayPlot = [[SeriesPlot alloc] init];
        [intraDayPlot setHostingView:intraDayGraphHostingView];
        if(sampleID <= [dataController dataGranularity]){
            [intraDayPlot setData:[dataController dataSeries] WithViewName:@"IntraDay"];
        }else{
            [intraDayPlot setData:dataForIntraDayPlot WithViewName:@"IntraDay"];
        }
        [intraDayPlot renderPlotWithFields:intraDayTimeSeries];
        [intraDayDataSeriesSamplingRate setStringValue:[NSString stringWithFormat:@"Data is sampled every %d seconds",sampleID]];
        
        
        shortTermPlot = [[SeriesPlot alloc] init];
        [shortTermPlot setHostingView:shortTermGraphHostingView];
        [shortTermPlot setData:dataForShortTermPlot WithViewName:@"ShortTerm"];
        [shortTermPlot renderPlotWithFields:shortTermTimeSeries];
        [shortTermDataSeriesSamplingRate setStringValue:[NSString stringWithFormat:@"Data is sampled every %d seconds",sampleST]];
        
        longTermPlot = [[SeriesPlot alloc] init];
        [longTermPlot setHostingView:longTermGraphHostingView];
        [longTermPlot setData:dataForLongTermPlot WithViewName:@"LongTerm"];
        [longTermPlot renderPlotWithFields:longTermTimeSeries] ;
        [longTermDataSeriesSamplingRate setStringValue:[NSString stringWithFormat:@"Data is sampled every %d seconds",sampleLT]];
        
        
    }
    if(cancelProcedure == NO)
    {
        [intraDayFXPairLabel setStringValue:selectedPair];
        [shortTermFXPairLabel setStringValue:selectedPair];
        [longTermFXPairLabel setStringValue:selectedPair];
        
        
//        [currentDateLabel setStringValue:[lastDayOfData descriptionWithCalendarFormat:@"%a %Y-%m-%d" timeZone:[NSTimeZone timeZoneWithName:@"GMT"] locale:nil]];
//        currentDay = lastDayOfData;
        
    }
    [statusTextField setHidden:YES];

    if(doThreads){
        [self performSelectorOnMainThread:@selector(endSetupSheet) withObject:nil waitUntilDone:NO];
    }else{
        [self endSetupSheet];
    }
}

- (IBAction)changeFxPair:(id)sender {
    //DataIO *database;
    //long *initialDateRange;
    NSString *selectedItem = [[fxPairPopUp selectedItem] title]; 
    //NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    //[dateFormatter setDateStyle:NSDateFormatterMediumStyle];
    long startDate = 0;
    long endDate = 0;
    
    //NSLog(@"New Choice is %@",selectedItem );
    
    startDate = [dataController getMinDataDateTimeForPair:selectedItem];
    endDate = [dataController getMaxDataDateTimeForPair:selectedItem];
    
    //    [fromDateLabel setStringValue:[dateFormatter stringFromDate:[NSDate dateWithTimeIntervalSince1970:(NSTimeInterval) startDate]]];
    //    [toDateLabel setStringValue:[dateFormatter stringFromDate:[NSDate dateWithTimeIntervalSince1970:(NSTimeInterval) endDate]]];
    
    [dataAvailabilityFromLabel setStringValue:[[NSDate dateWithTimeIntervalSince1970:(NSTimeInterval) startDate] descriptionWithCalendarFormat:@"%Y-%m-%d" timeZone:[NSTimeZone timeZoneWithName:@"GMT"] locale:nil]];
    [dataAvailabilityToLabel setStringValue:[[NSDate dateWithTimeIntervalSince1970:(NSTimeInterval) endDate] descriptionWithCalendarFormat:@"%Y-%m-%d" timeZone:[NSTimeZone timeZoneWithName:@"GMT"] locale:nil]];
    
    
    [intraDayDatePicker setMinDate:[NSDate dateWithTimeIntervalSince1970:(NSTimeInterval) startDate]];
    [intraDayDatePicker setMaxDate:[NSDate dateWithTimeIntervalSince1970:(NSTimeInterval) endDate]];
    //[datePicker setDateValue:[NSDate dateWithTimeIntervalSince1970:(NSTimeInterval) (startDate + endDate)/2]]; 
    //[dateFormatter setDateFormat:@"EEE"];
    //NSString *dayName = [dateFormatter stringFromDate:[datePicker dateValue]];
    [intraDayDayOfWeekLabel setStringValue:[[intraDayDatePicker dateValue] descriptionWithCalendarFormat:@"%a" timeZone:[NSTimeZone timeZoneWithName:@"GMT"] locale:nil]]; 
    //[fxPairLabel setStringValue:[dayName substringToIndex:3]]; 
}

- (IBAction)changeDate:(id)sender {
    [intraDayDayOfWeekLabel setStringValue:[[intraDayDatePicker  dateValue] descriptionWithCalendarFormat:@"%a" timeZone:[NSTimeZone timeZoneWithName:@"GMT"] locale:nil]]; 
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

//-(void)flickrSetupMessage
//{
//    //NSArray *colorArray = [NSArray arrayWithObjects:[NSColor blackColor],[NSColor darkGrayColor],[NSColor grayColor],[NSColor lightGrayColor],[NSColor whiteColor],[NSColor lightGrayColor],[NSColor grayColor],[NSColor darkGrayColor], [NSColor blackColor] , nil];
//    if(timerCount < 11)
//    {
//        if(timerCount%4 ==0){
//            [showSetupSheetButton setTransparent:![showSetupSheetButton isTransparent]];
//        }
//        //[leftPanelStatusLabel setHidden:![leftPanelStatusLabel isHidden]];
//        //[leftPanelStatusLabel setTextColor:[colorArray objectAtIndex:timerCount%9]];
//        timerCount++;
//    }else{
//        //[leftPanelStatusLabel setHidden:NO];
//        //[leftPanelStatusLabel setTextColor:[NSColor blackColor]];
//        [showSetupSheetButton setTransparent:NO];
//        [timer invalidate];
//        timer = nil;
//    }
//}
//


#pragma mark -
#pragma mark TableView Methods

- (void)tableView:(NSTableView *)tableView didClickTableColumn:(NSTableColumn *)tableColumn
{
    SeriesPlot *plot;
    //NSMutableArray *timeSeries;
    if([[tableColumn identifier] isEqualToString:@"visible"]){
        if([[tableView identifier] isEqualToString:@"LTTSTV"]){
            TimeSeriesLine *tsl;
            for(tsl in longTermTimeSeries)
            {
                [tsl setVisible:NO];
            }
            
            plot = longTermPlot;
        }
        if([[tableView identifier] isEqualToString:@"STTSTV"]){
            TimeSeriesLine *tsl;
            for(tsl in shortTermTimeSeries)
            {
                [tsl setVisible:NO];
            }
            //timeSeries = shortTermTimeSeries;
            plot = shortTermPlot;
        }
        if([[tableView identifier] isEqualToString:@"IDTSTV"]){
            TimeSeriesLine *tsl;
            for(tsl in intraDayTimeSeries)
            {
                [tsl setVisible:NO];
            }
            //timeSeries = intraDayTimeSeries;
            plot = intraDayPlot;
        }
        [plot visibilityOfLineUpdated];
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
    
    NSString *column = [tableColumn identifier];
    return [tsl valueForKey:column];
    
}

- (void)tableView:(NSTableView *)tableView setObjectValue:(id) obj forTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    TimeSeriesLine *tsl;
    SeriesPlot *plot;
    if([[tableView identifier] isEqualToString:@"LTTSTV"]){
        tsl = [longTermTimeSeries objectAtIndex:row];
        plot = longTermPlot;
    }
    if([[tableView identifier] isEqualToString:@"STTSTV"]){
        tsl = [shortTermTimeSeries objectAtIndex:row];
        plot = shortTermPlot;
    }
    if([[tableView identifier] isEqualToString:@"IDTSTV"]){
        tsl = [intraDayTimeSeries objectAtIndex:row];
        plot = intraDayPlot;
    }
    NSString *column = [tableColumn identifier];
    [tsl setValue:obj forKey:column]; 
    [plot visibilityOfLineUpdated];
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
   [tableView reloadData];
}



- (IBAction)intraDayMoveForwardButtonPress:(id)sender {
    //long dateStartTimeIntraDay; 
    long dateEndTimeIntraDay;
    int extendByMinutes;
    DataView *intraDayDataView;
    extendByMinutes = [intraDayMoveForwardTextField integerValue]*60;
    intraDayDataView = [[[dataController dataSeries] dataViews] objectForKey:@"IntraDay"];
    
    //dateStartTimeIntraDay = [EpochTime epochTimeAtZeroHour:[currentDay timeIntervalSince1970]];
    dateEndTimeIntraDay = [intraDayDataView lastX] + extendByMinutes;
    [[dataController dataSeries]  setPlotViewWithName: @"IntraDay" AndStartDateTime: [intraDayDataView firstX] AndEndDateTime: dateEndTimeIntraDay];
    [intraDayPlot setData:[dataController dataSeries] WithViewName:@"IntraDay"];
    [intraDayPlot renderPlotWithFields:intraDayTimeSeries];
    [intraDayDateTimeLabel setStringValue:[EpochTime stringOfDateTimeForTime:dateEndTimeIntraDay WithFormat:@"%Y%m%d %H:%M:%S"]];
    
}

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
//    if(!initialSetupComplete){
//        timerCount = 0;
//        //[leftPanelStatusLabel setHidden:NO];
//        timer = [NSTimer scheduledTimerWithTimeInterval:0.15 
//                                                   target:self 
//                                                 selector:@selector(flickrSetupMessage)
//                                                 userInfo:nil
//                                                  repeats:YES];
//
//    }
    return initialSetupComplete;
    //return YES;
}


@end