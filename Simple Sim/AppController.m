//
//  AppController.m
//  Simple Sim
//
//  Created by O'Connor Martin on 19/12/2011.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "AppController.h"
#import "IdNamePair.h"
#import "EpochTime.h"
#import "DataSeries.h"
#import "PlotController.h"
#import "SeriesPlot.h"
#import "TimeSeriesLine.h"
#define START_TIME_FOR_ID_PLOT 4


@interface AppController()




@end


@implementation AppController
@synthesize intraDayLeftSideTab;
@synthesize sideTabs;
@synthesize intraDayTimeLabel;
@synthesize intraDayDateLabel;
@synthesize intraDayTimeSlider;
@synthesize intraDaySamplingUnit;
@synthesize longTermTimeSeriesTableView;
@synthesize shortTermTimeSeriesTableView;
@synthesize intraDayTimeSeriesTableView;
@synthesize intraDaySamplingValue;
@synthesize longTermTimeSeries;
@synthesize shortTermTimeSeries;
@synthesize intraDayTimeSeries;
@synthesize hostingView2;
@synthesize longTermSamplingUnit;
@synthesize shortTermSamplingUnit;
@synthesize hostingView3;
@synthesize longTermSamplingValue;
@synthesize shortTermSamplingValue;
@synthesize hostingView1;
@synthesize mainTabs;
@synthesize dataGranularityLabel;
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
@synthesize plot1;
@synthesize plot2;
@synthesize plot3;
@synthesize shortTermHistory;
@synthesize longTermHistory;
@synthesize colorsForPlots;
@synthesize currentDay;
@synthesize retrievedData;

NSArray *pairListWithId;
NSArray *dataTypeListWithId;
long *pairListMinDates;
long *pairListMaxDates;

-(id)init
{
    self = [super init];
    if(self){
        longTermTimeSeries = [[NSMutableArray alloc] init];
        shortTermTimeSeries = [[NSMutableArray alloc] init];
        intraDayTimeSeries = [[NSMutableArray alloc] init];
    }
    return self;
}

-(void)awakeFromNib
{
    NSInteger selectedItem;
    dataController = [[DataController alloc]init];
    long *initialDateRange;
    NSMutableArray *pairList = [[NSMutableArray alloc]init ];
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateStyle:NSDateFormatterMediumStyle];
    
    NSTableColumn *colourColumnLT =  [longTermTimeSeriesTableView tableColumnWithIdentifier:@"colourId"];
    NSTableColumn *colourColumnST =  [shortTermTimeSeriesTableView tableColumnWithIdentifier:@"colourId"];
    NSTableColumn *colourColumnID =  [intraDayTimeSeriesTableView tableColumnWithIdentifier:@"colourId"];
    
    NSPopUpButtonCell *colourDropDownCellLT = [[NSPopUpButtonCell alloc] init];
    NSPopUpButtonCell *colourDropDownCellST = [[NSPopUpButtonCell alloc] init];
    NSPopUpButtonCell *colourDropDownCellID = [[NSPopUpButtonCell alloc] init];
    
    
    [colourDropDownCellLT setBordered:NO];
    [colourDropDownCellLT setEditable:YES];
    [colourDropDownCellST setBordered:NO];
    [colourDropDownCellST setEditable:YES];    
    [colourDropDownCellID setBordered:NO];
    [colourDropDownCellID setEditable:YES];    
    
    colorsForPlots = [NSArray arrayWithObjects:
                      @"Clear",
                      @"White", 
                      @"LightGray", 
                      @"Gray",
                      @"DarkGray",
                      @"Black",
                      @"Red",
                      @"Green",
                      @"Blue",
                      @"Cyan",
                      @"Yellow",
                      @"Magenta",
                      @"Orange",
                      @"Purple",
                      @"Brown", 
                      nil];
    
    [colourDropDownCellLT addItemsWithTitles:colorsForPlots];
    [colourColumnLT setDataCell:colourDropDownCellLT];
    [colourDropDownCellST addItemsWithTitles:colorsForPlots];
    [colourColumnST setDataCell:colourDropDownCellST];
    [colourDropDownCellID addItemsWithTitles:colorsForPlots];
    [colourColumnID setDataCell:colourDropDownCellID];

    dataTypeListWithId = [dataController getListofDataTypes];
    pairListWithId = [dataController getListofPairs];
    if([pairListWithId count] > 0)
    {
        pairListMinDates = calloc(sizeof(long),[pairListWithId count]);
        pairListMaxDates = calloc(sizeof(long),[pairListWithId count]);
    }
    
    for (IdNamePair *myArrayElement in pairListWithId) {
        [pairList addObject:[myArrayElement description]];
    }
    
    [pairPicker removeAllItems];
    [pairPicker addItemsWithTitles:pairList];
    [pairPicker selectItemAtIndex:0];
    
    for (IdNamePair *myArrayElement in pairListWithId) {
        [[pairPicker itemWithTitle:[myArrayElement description]] setTag:[myArrayElement dbid]];
    }
    
    selectedItem = [[pairPicker selectedItem] tag];
    
    //NSLog(@"Select Item %ld",selectedItem);    
    initialDateRange = [dataController getDateRangeForSeries:selectedItem];
    
    [fromDateLabel setStringValue:[dateFormatter stringFromDate:[NSDate dateWithTimeIntervalSince1970:(NSTimeInterval) initialDateRange[0]]]];
    [toDateLabel setStringValue:[dateFormatter stringFromDate:[NSDate dateWithTimeIntervalSince1970:(NSTimeInterval) initialDateRange[1]]]];
    for(int i = 0; i < [pairListWithId count]; i++)
    {
        if(selectedItem== [[pairListWithId objectAtIndex:i] dbid]){
            //NSLog(@"Adding mins and max for item %@", [[pairListWithId objectAtIndex:i] description]);
            pairListMinDates[i] = initialDateRange[0]; 
            pairListMaxDates[i] = initialDateRange[1];
        }
    }
    
    [datePicker setMinDate:[NSDate dateWithTimeIntervalSince1970:(NSTimeInterval) initialDateRange[0]]];
    [datePicker setMaxDate:[NSDate dateWithTimeIntervalSince1970:(NSTimeInterval) initialDateRange[1]]];
    [datePicker setDateValue:[NSDate dateWithTimeIntervalSince1970:(NSTimeInterval) initialDateRange[1]]]; 
    NSDate *initialDate = [datePicker dateValue];
    [dateFormatter setDateFormat:@"EEE"];
    NSString *dayName = [dateFormatter stringFromDate:initialDate];
    [dayOfWeekLabel setStringValue:[dayName substringToIndex:3]]; 
    
    plot1 = [[SeriesPlot alloc] init];
    [plot1 setHostingView:hostingView1];
    [plot1 initialGraph];
    
    plot2 = [[SeriesPlot alloc] init];
    [plot2 setHostingView:hostingView2];
    [plot2 initialGraph];
    
    plot3 = [[SeriesPlot alloc] init];
    [plot3 setHostingView:hostingView3];
    [plot3 initialGraph];
}

- (IBAction)showSetupSheet:(id)sender {
    [NSApp beginSheet:setupSheet modalForWindow:[mainTabs window] modalDelegate:nil didEndSelector:NULL contextInfo:NULL];
}

- (IBAction)cancelSetupSheet:(id)sender {
    [NSApp endSheet:setupSheet returnCode: NSCancelButton];
    [setupSheet orderOut:sender];
}

//- (void)sheetDidEnd:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo
//{
//	if (returnCode == NSCancelButton)
//		NSBeep();
//}



- (IBAction)setUp:(id)sender
{
    int selectedItem = (int) [[pairPicker selectedItem] tag];
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateStyle:NSDateFormatterMediumStyle];
    currentDay = [datePicker  dateValue];
    [intraDayDateLabel setStringValue:[currentDay description]];
    
    NSString *filterValueRequested = filterValue.stringValue; 
    NSString *filterValueUnit = [[filterUnit selectedCell] title];
    
    DataSeries *dataForLongTermPlot, *dataForShortTermPlot;
    long dateStartTimeFullData, dateEndTimeFullData;
    long dateStartTimeLongTerm, dateEndTimeLongTerm;
    long dateStartTimeShortTerm, dateEndTimeShortTerm;
    long dateStartTimeIntraDay, dateEndTimeIntraDay;
    
    int daysForLTHistory = [longTermHistory intValue];
    int daysForSTHistory = [shortTermHistory intValue];
    int longTermDataSampleSeconds, shortTermDataSampleSeconds, intraDayDataSampleSeconds;
    
    [dataSetupProgressBar setHidden:NO];
    [dataSetupProgressBar startAnimation:sender];
    
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
    
    // create a calendar to use for date ranges
    NSCalendar *gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
    // set up date components
    NSDateComponents *components = [[NSDateComponents alloc] init];
    
    //Full data 
    [components setDay:-(2*daysForLTHistory)];
    dateStartTimeFullData = [EpochTime epochTimeAtZeroHour:[[gregorian dateByAddingComponents:components toDate:currentDay options:0]  timeIntervalSince1970]];
    dateEndTimeFullData = [EpochTime epochTimeNextDayAtZeroHour:[currentDay timeIntervalSince1970]];
    // Get the data for the Long term Plot
    retrievedData = [dataController getBidAskSeriesForId:selectedItem  
                                                  AndStartTime:dateStartTimeFullData 
                                                    AndEndTime:dateEndTimeFullData
                                              ToSampledSeconds:0];
    [dataController addMidToBidAskSeries:retrievedData]; 
    
        [dataController addEWMAToSeries:retrievedData WithParam: 89];
        [dataController addEWMAToSeries:retrievedData WithParam: 233];
        [dataController addEWMAToSeries:retrievedData WithParam: 610];
        [dataController addEWMAToSeries:retrievedData WithParam: 1597];
        [dataController addEWMAToSeries:retrievedData WithParam: 4181];
        [dataController addEWMAToSeries:retrievedData WithParam: 10946];
        [dataController addEWMAToSeries:retrievedData WithParam: 28657];
    
    //Long term data
    [components setDay:-daysForLTHistory];
    dateStartTimeLongTerm = [EpochTime epochTimeAtZeroHour:[[gregorian dateByAddingComponents:components toDate:currentDay options:0]  timeIntervalSince1970]];
    dateEndTimeLongTerm = [EpochTime epochTimeAtZeroHour:[currentDay timeIntervalSince1970]];
    dataForLongTermPlot = [retrievedData sampleDataAtInterval:longTermDataSampleSeconds];
    [dataForLongTermPlot  setPlotViewWithName: @"LongTerm" AndStartDateTime: dateStartTimeLongTerm AndEndDateTime: dateEndTimeLongTerm];
    
    //Short term data
    [components setDay:-daysForSTHistory];
    dateStartTimeShortTerm = [EpochTime epochTimeAtZeroHour:[[gregorian dateByAddingComponents:components toDate:currentDay options:0]  timeIntervalSince1970]];
    dateEndTimeShortTerm = [EpochTime epochTimeAtZeroHour:[currentDay timeIntervalSince1970]];
    dataForShortTermPlot = [retrievedData sampleDataAtInterval:shortTermDataSampleSeconds];
    [dataForShortTermPlot  setPlotViewWithName: @"ShortTerm" AndStartDateTime: dateStartTimeShortTerm AndEndDateTime: dateEndTimeShortTerm];
    
    
    //Intraday data
    dateStartTimeIntraDay = [EpochTime epochTimeAtZeroHour:[currentDay timeIntervalSince1970]];
    dateEndTimeIntraDay = dateStartTimeIntraDay + START_TIME_FOR_ID_PLOT*60*60;
    [intraDayTimeSlider setDoubleValue:START_TIME_FOR_ID_PLOT];
    [retrievedData  setPlotViewWithName: @"IntraDay" AndStartDateTime: dateStartTimeIntraDay AndEndDateTime: dateEndTimeIntraDay];
    
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
    tsl = [[TimeSeriesLine alloc] initWithVisibility:YES AndName:@"EWMA89" AndColour:@"Blue"];
    [self addToTableView:longTermTimeSeriesTableView   TimeSeriesLine:tsl];
    tsl = [[TimeSeriesLine alloc] initWithVisibility:YES AndName:@"EWMA233" AndColour:@"Magenta"];
    [self addToTableView:longTermTimeSeriesTableView   TimeSeriesLine:tsl];
    tsl = [[TimeSeriesLine alloc] initWithVisibility:YES AndName:@"EWMA610" AndColour:@"Yellow"];
    [self addToTableView:longTermTimeSeriesTableView   TimeSeriesLine:tsl];
    tsl = [[TimeSeriesLine alloc] initWithVisibility:YES AndName:@"EWMA1597" AndColour:@"Cyan"];
    [self addToTableView:longTermTimeSeriesTableView   TimeSeriesLine:tsl];
    tsl = [[TimeSeriesLine alloc] initWithVisibility:YES AndName:@"EWMA4181" AndColour:@"Brown"];
    [self addToTableView:longTermTimeSeriesTableView   TimeSeriesLine:tsl];
    tsl = [[TimeSeriesLine alloc] initWithVisibility:YES AndName:@"EWMA10946" AndColour:@"Orange"];
    [self addToTableView:longTermTimeSeriesTableView   TimeSeriesLine:tsl];
    tsl = [[TimeSeriesLine alloc] initWithVisibility:YES AndName:@"EWMA28657" AndColour:@"Purple"];
    [self addToTableView:longTermTimeSeriesTableView   TimeSeriesLine:tsl];
    
    tsl = [[TimeSeriesLine alloc] initWithVisibility:NO AndName:@"BID" AndColour:@"Red"];
    [self addToTableView:shortTermTimeSeriesTableView   TimeSeriesLine:tsl];
    tsl = [[TimeSeriesLine alloc] initWithVisibility:NO AndName:@"ASK" AndColour:@"Green"];
    [self addToTableView:shortTermTimeSeriesTableView   TimeSeriesLine:tsl];
    tsl = [[TimeSeriesLine alloc] initWithVisibility:YES AndName:@"MID" AndColour:@"LightGray"];
    [self addToTableView:shortTermTimeSeriesTableView   TimeSeriesLine:tsl];
    tsl = [[TimeSeriesLine alloc] initWithVisibility:YES AndName:@"EWMA89" AndColour:@"Blue"];
    [self addToTableView:shortTermTimeSeriesTableView   TimeSeriesLine:tsl];
    tsl = [[TimeSeriesLine alloc] initWithVisibility:YES AndName:@"EWMA233" AndColour:@"Magenta"];
    [self addToTableView:shortTermTimeSeriesTableView   TimeSeriesLine:tsl]; 
    tsl = [[TimeSeriesLine alloc] initWithVisibility:YES AndName:@"EWMA610" AndColour:@"Yellow"];
    [self addToTableView:shortTermTimeSeriesTableView   TimeSeriesLine:tsl]; 
    tsl = [[TimeSeriesLine alloc] initWithVisibility:YES AndName:@"EWMA1597" AndColour:@"Cyan"];
    [self addToTableView:shortTermTimeSeriesTableView   TimeSeriesLine:tsl];
    tsl = [[TimeSeriesLine alloc] initWithVisibility:YES AndName:@"EWMA4181" AndColour:@"Brown"];
    [self addToTableView:shortTermTimeSeriesTableView   TimeSeriesLine:tsl];

    
    tsl = [[TimeSeriesLine alloc] initWithVisibility:NO AndName:@"BID" AndColour:@"Red"];
    [self addToTableView:intraDayTimeSeriesTableView   TimeSeriesLine:tsl];
    tsl = [[TimeSeriesLine alloc] initWithVisibility:NO AndName:@"ASK" AndColour:@"Green"];
    [self addToTableView:intraDayTimeSeriesTableView   TimeSeriesLine:tsl];
    tsl = [[TimeSeriesLine alloc] initWithVisibility:YES AndName:@"MID" AndColour:@"LightGray"];
    [self addToTableView:intraDayTimeSeriesTableView   TimeSeriesLine:tsl];
    tsl = [[TimeSeriesLine alloc] initWithVisibility:YES AndName:@"EWMA89" AndColour:@"Blue"];
    [self addToTableView:intraDayTimeSeriesTableView   TimeSeriesLine:tsl];
    tsl = [[TimeSeriesLine alloc] initWithVisibility:YES AndName:@"EWMA233" AndColour:@"Magenta"];
    [self addToTableView:intraDayTimeSeriesTableView   TimeSeriesLine:tsl];
    tsl = [[TimeSeriesLine alloc] initWithVisibility:YES AndName:@"EWMA610" AndColour:@"Yellow"];
    [self addToTableView:intraDayTimeSeriesTableView   TimeSeriesLine:tsl];
    tsl = [[TimeSeriesLine alloc] initWithVisibility:YES AndName:@"EWMA1597" AndColour:@"Cyan"];
    [self addToTableView:intraDayTimeSeriesTableView   TimeSeriesLine:tsl];
    tsl = [[TimeSeriesLine alloc] initWithVisibility:YES AndName:@"EWMA4181" AndColour:@"Brown"];
    [self addToTableView:intraDayTimeSeriesTableView   TimeSeriesLine:tsl];
    
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
    [plot1 setData:retrievedData WithViewName:@"IntraDay"];
    [plot1 renderPlotWithFields:intraDayTimeSeries];
    
    [fxPairLabel setStringValue:[[pairPicker selectedItem] title]];
     
    [dataGranularityLabel setStringValue:[NSString stringWithFormat:@"Sampling every\n%@ %@",filterValueRequested,filterValueUnit]];
    [currentDateLabel setStringValue:[currentDay descriptionWithCalendarFormat:@"%Y-%m-%d" timeZone:nil locale:nil]];
    [mainTabs selectTabViewItemAtIndex:2];
    
    [fxPairLabel setHidden:NO];
    [dataGranularityLabel setHidden:NO];
    [currentDateLabel setHidden:NO];
    [longTermTimeSeriesScrollView setHidden:NO];
    [shortTermTimeSeriesScrollView setHidden:NO];
    [intraDayTimeSeriesScrollView setHidden:NO];
    
    [intraDayLeftSideTab setHidden:NO];
    
    [dataSetupProgressBar setHidden:YES];
    [dataSetupProgressBar stopAnimation:sender];
    
    [NSApp endSheet:setupSheet returnCode: NSOKButton];
    [setupSheet orderOut:sender];
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
    
    [retrievedData  setPlotViewWithName: @"IntraDay" AndStartDateTime: dateStartTimeIntraDay AndEndDateTime: dateEndTimeIntraDay];
    [plot1 setData:retrievedData WithViewName:@"IntraDay"];
    [plot1 renderPlotWithFields:intraDayTimeSeries];
    
    [intraDayTimeLabel setStringValue:[NSString stringWithFormat:@"%02d:%02d",hours, minutes]];
}


- (IBAction)changePair:(id)sender {
    //DataIO *database;
    long *initialDateRange;
    NSInteger selectedItem = [[pairPicker selectedItem] tag]; 
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateStyle:NSDateFormatterMediumStyle];
    long startDate = 0;
    long endDate = 0;
    
    NSLog(@"New Choice is %@",[[pairPicker selectedItem] title] );
    
    for(int i = 0; i < [pairListWithId count];i++){
        if(([[pairListWithId objectAtIndex:i] dbid] == selectedItem) ){
            if((pairListMaxDates[i] != 0)){
                startDate = pairListMinDates[i];
                endDate = pairListMaxDates[i];
                NSLog(@"Already had range for %@", [[pairListWithId objectAtIndex:i] description]);
            }else{
                //database = [[DataIO alloc]init];
                initialDateRange = [dataController getDateRangeForSeries:selectedItem];
                startDate = initialDateRange[0];
                endDate = initialDateRange[1];
                pairListMinDates[i] = startDate;
                pairListMaxDates[i] = endDate;
                NSLog(@"Added mins and max for item %@", [[pairListWithId objectAtIndex:i] description]);
            }
        }
    }
    
    [fromDateLabel setStringValue:[dateFormatter stringFromDate:[NSDate dateWithTimeIntervalSince1970:(NSTimeInterval) startDate]]];
    [toDateLabel setStringValue:[dateFormatter stringFromDate:[NSDate dateWithTimeIntervalSince1970:(NSTimeInterval) endDate]]];
    
    [datePicker setMinDate:[NSDate dateWithTimeIntervalSince1970:(NSTimeInterval) startDate]];
    [datePicker setMaxDate:[NSDate dateWithTimeIntervalSince1970:(NSTimeInterval) endDate]];
    [datePicker setDateValue:[NSDate dateWithTimeIntervalSince1970:(NSTimeInterval) endDate]]; 
    [dateFormatter setDateFormat:@"EEE"];
    NSString *dayName = [dateFormatter stringFromDate:[datePicker dateValue]];
    [dayOfWeekLabel setStringValue:[dayName substringToIndex:3]]; 
    [fxPairLabel setStringValue:[dayName substringToIndex:3]]; 
}

- (IBAction)changeDate:(id)sender {
    NSDate *datePicked = [datePicker  dateValue];
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"EEE"];
    NSString *dayName = [dateFormatter stringFromDate:datePicked];
    [dayOfWeekLabel setStringValue:[dayName substringToIndex:3]]; 
    
    //NSLog(@"Date is now %@",datePicked);
}


- (void)controlTextDidChange:(NSNotification *)obj
{
    NSLog(@"Check");
    if([filterValue intValue] >= 1)
    {
        [filterValue setStringValue:[NSString stringWithFormat:@"%d",[filterValue intValue]]];
    }else{
        [filterValue setStringValue:@"1"];
    }
}  


#pragma mark -
#pragma mark TimeSeries TableView Methods

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
    NSString *column = [tableColumn identifier];
    [tsl setValue:obj forKey:column]; 
    [plot renderPlotWithFields:timeSeries];;
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

#pragma mark -
#pragma mark TabView Delegate Methods

-(void)tabView:(NSTabView *) tabView didSelectTabViewItem:(NSTabViewItem *) tabViewItem
{
    if([[tabView identifier] isEqual:@"mainTabs"])
    {
        [sideTabs selectTabViewItemWithIdentifier:[tabViewItem identifier]];  
    }
}



@end
