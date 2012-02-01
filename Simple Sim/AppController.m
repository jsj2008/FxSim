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



@implementation AppController
@synthesize intraDaySamplingUnit;
@synthesize timeSeriesTableView;
@synthesize intraDaySamplingValue;
@synthesize timeSeries;
@synthesize hostingView2;
@synthesize longTermSamplingUnit;
@synthesize shortTermSamplingUnit;
@synthesize hostingView3;
@synthesize longTermSamplingValue;
@synthesize shortTermSamplingValue;
@synthesize hostingView1;
@synthesize startupMessageLabel;
@synthesize startupLabel;
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
@synthesize timeSeriesPicker;
@synthesize plot1;
@synthesize plot2;
@synthesize plot3;
@synthesize shortTermHistory;
@synthesize longTermHistory;
@synthesize colorsForPlots;

NSArray *pairListWithId;
NSArray *dataTypeListWithId;
long *pairListMinDates;
long *pairListMaxDates;

-(id)init
{
    self = [super init];
    if(self){
        timeSeries = [[NSMutableArray alloc] init];
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
    
    NSTableColumn *colourColumn =  [timeSeriesTableView tableColumnWithIdentifier:@"colourId"];
    
    NSPopUpButtonCell *colourDropDownCell = [[NSPopUpButtonCell alloc] init];
    [colourDropDownCell setBordered:NO];
    [colourDropDownCell setEditable:YES];
    
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
    
    [colourDropDownCell addItemsWithTitles:colorsForPlots];
    [colourColumn setDataCell:colourDropDownCell];
    
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
    
    NSLog(@"Select Item %ld",selectedItem);    
    initialDateRange = [dataController getDateRangeForSeries:selectedItem];
    
    [fromDateLabel setStringValue:[dateFormatter stringFromDate:[NSDate dateWithTimeIntervalSince1970:(NSTimeInterval) initialDateRange[0]]]];
    [toDateLabel setStringValue:[dateFormatter stringFromDate:[NSDate dateWithTimeIntervalSince1970:(NSTimeInterval) initialDateRange[1]]]];
    for(int i = 0; i < [pairListWithId count]; i++)
    {
        if(selectedItem== [[pairListWithId objectAtIndex:i] dbid]){
            NSLog(@"Adding mins and max for item %@", [[pairListWithId objectAtIndex:i] description]);
            pairListMinDates[i] = initialDateRange[0]; 
            pairListMaxDates[i] = initialDateRange[1];
        }
    }
    
    [datePicker setMinDate:[NSDate dateWithTimeIntervalSince1970:(NSTimeInterval) initialDateRange[0]]];
    [datePicker setMaxDate:[NSDate dateWithTimeIntervalSince1970:(NSTimeInterval) initialDateRange[1]]];
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
    
    [mainTabs selectTabViewItemAtIndex:0];
}

- (IBAction)setUp:(id)sender
{
    int selectedItem = (int) [[pairPicker selectedItem] tag];
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateStyle:NSDateFormatterMediumStyle];
    NSDate *datePicked = [datePicker  dateValue];
    
    NSString *filterValueRequested = filterValue.stringValue; 
    NSString *filterValueUnit = [[filterUnit selectedCell] title];
    
    DataSeries *dataForLongTermPlot, *dataForShortTermPlot, *dataForIntraDayPlot;
    long dateStartTimeLongTerm, dateEndTimeLongTerm;
    long dateStartTimeShortTerm, dateEndTimeShortTerm;
    long dateStartTimeIntraDay, dateEndTimeIntraDay;
    
    int daysForLTHistory = [longTermHistory intValue];
    int daysForSTHistory = [shortTermHistory intValue];
    int longTermDataSampleSeconds, shortTermDataSampleSeconds, intraDayDataSampleSeconds;
    
    longTermDataSampleSeconds = [shortTermSamplingValue intValue];
    shortTermDataSampleSeconds = [longTermSamplingValue intValue];
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
    
    //Long term data
    [components setDay:-daysForLTHistory];
    dateStartTimeLongTerm = [EpochTime epochTimeAtZeroHour:[[gregorian dateByAddingComponents:components toDate:datePicked options:0]  timeIntervalSince1970]];
    dateEndTimeLongTerm = [EpochTime epochTimeAtZeroHour:[datePicked timeIntervalSince1970]];
    // Get the data for the Long term Plot
    dataForLongTermPlot = [dataController getBidAskSeriesForId:selectedItem  
                                        AndStartTime:dateStartTimeLongTerm 
                                          AndEndTime:dateEndTimeLongTerm
                                     ToSampledSeconds:longTermDataSampleSeconds];
    [dataController addMidToBidAskSeries:dataForLongTermPlot]; 
    
    //Short term data
    [components setDay:-daysForSTHistory];
    dateStartTimeShortTerm = [EpochTime epochTimeAtZeroHour:[[gregorian dateByAddingComponents:components toDate:datePicked options:0]  timeIntervalSince1970]];
    dateEndTimeShortTerm = [EpochTime epochTimeAtZeroHour:[datePicked timeIntervalSince1970]];
    // Get the data for the Short term Plot
    dataForShortTermPlot = [dataController getBidAskSeriesForId:selectedItem  
                                                   AndStartTime:dateStartTimeShortTerm 
                                                     AndEndTime:dateEndTimeShortTerm
                                               ToSampledSeconds:shortTermDataSampleSeconds];
    [dataController addMidToBidAskSeries:dataForShortTermPlot];
    
    //Intraday data
    dateStartTimeIntraDay = [EpochTime epochTimeAtZeroHour:[datePicked timeIntervalSince1970]];
    dateEndTimeIntraDay = [EpochTime epochTimeNextDayAtZeroHour:[datePicked timeIntervalSince1970]]; 
    dataForIntraDayPlot = [dataController getBidAskSeriesForId:selectedItem  
                                                  AndStartTime:dateStartTimeIntraDay 
                                                    AndEndTime:dateEndTimeIntraDay
                                              ToSampledSeconds:intraDayDataSampleSeconds];
    [dataController addMidToBidAskSeries:dataForIntraDayPlot];
    
    [self clearTSTableView];
    TimeSeriesLine *tsl;
    tsl = [[TimeSeriesLine alloc] initWithVisibility:NO AndName:@"BID" AndColour:@"Red"];
    [self addToTSTableView:tsl];
    tsl = [[TimeSeriesLine alloc] initWithVisibility:NO AndName:@"ASK" AndColour:@"Green"];
    [self addToTSTableView:tsl];
    tsl = [[TimeSeriesLine alloc] initWithVisibility:YES AndName:@"MID" AndColour:@"LightGray"];
    [self addToTSTableView:tsl];
    
    
    //dataForPlot = [dataForPlot sampleDataAtInterval:(5*60)];
    //PlotItem *item = [[SimpleScatterPlot alloc] init];
    plot3 = [[SeriesPlot alloc] init];
    [plot3 setHostingView:hostingView3];
    [plot3 setData:dataForLongTermPlot WithViewName:@"ALL"];
    [plot3 renderPlotWithFields:timeSeries] ;
    //[plot3 showSeries:[[bidAskPicker selectedCell] title]];
    
    plot2 = [[SeriesPlot alloc] init];
    [plot2 setHostingView:hostingView2];
    [plot2 setData:dataForShortTermPlot WithViewName:@"ALL"];
    [plot2 renderPlotWithFields:timeSeries];
 
    
    plot1 = [[SeriesPlot alloc] init];
    [plot1 setHostingView:hostingView1];
    [plot1 setData:dataForIntraDayPlot WithViewName:@"ALL"];
    [plot1 renderPlotWithFields:timeSeries];
    
    [fxPairLabel setStringValue:[[pairPicker selectedItem] title]];
     
    [dataGranularityLabel setStringValue:[NSString stringWithFormat:@"Sampling every\n%@ %@",filterValueRequested,filterValueUnit]];
    [currentDateLabel setStringValue:[datePicked descriptionWithCalendarFormat:@"%Y-%m-%d" timeZone:nil locale:nil]];
    [mainTabs selectTabViewItemAtIndex:0];
    
    
    
    
    [startupMessageLabel setHidden:YES];
    [fxPairLabel setHidden:NO];
    [dataGranularityLabel setHidden:NO];
    [currentDateLabel setHidden:NO];
    [timeSeriesPicker setHidden:NO];
    
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
    
    NSLog(@"Date is now %@",datePicked);
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
    return [timeSeries count]; 
    
}
- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    TimeSeriesLine *tsa = [timeSeries objectAtIndex:row];
    NSString *column = [tableColumn identifier];
    return [tsa valueForKey:column];
    
}

- (void)tableView:(NSTableView *)tableView setObjectValue:(id) obj forTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    TimeSeriesLine *tsl = [timeSeries objectAtIndex:row];
    NSString *column = [tableColumn identifier];
    [tsl setValue:obj forKey:column]; 
    [plot1 renderPlotWithFields:timeSeries];
    [plot2 renderPlotWithFields:timeSeries];
    [plot3 renderPlotWithFields:timeSeries];
}

-(void)clearTSTableView
{
    [timeSeries removeAllObjects];
    [timeSeriesTableView reloadData];
}

-(void)addToTSTableView:(TimeSeriesLine *)TSLine
{
    [timeSeries addObject:TSLine];
    [timeSeriesTableView reloadData];
}



@end
