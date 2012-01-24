//
//  PlotGalleryController.m
//  CorePlotGallery
//
//  Created by Jeff Buck on 9/5/10.
//  Copyright 2010 Jeff Buck. All rights reserved.
//

#import "PlotController.h"
//#import "DataIO.h"
#import "IdNamePair.h"
#import "EpochTime.h"
#import "DataSeries.h"
#import "PlotController.h"
#import "SimpleScatterPlot.h"


//const float CPT_SPLIT_VIEW_MIN_LHS_WIDTH = 150.0f;
//#define kThemeTableViewControllerNoTheme	  @"None"
//#define kThemeTableViewControllerDefaultTheme @"Default"

@implementation PlotController
@synthesize bidAskPicker;
@synthesize filterValue;

@synthesize filterUnit;
@synthesize pairPicker;
@synthesize toDateLabel;
@synthesize fromDateLabel;
@synthesize dayOfWeekLabel;
@synthesize datePicker;
@synthesize minAvailableDate;
@synthesize maxAvailableDate;
@dynamic plotItem;


NSArray *pairListWithId;
NSArray *dataTypeListWithId;
long *pairListMinDates;
long *pairListMaxDates;

-(void)awakeFromNib
{
    NSInteger selectedItem;
    dataController = [[DataController alloc]init];
    long *initialDateRange;
    NSMutableArray *pairList = [[NSMutableArray alloc]init ];
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateStyle:NSDateFormatterMediumStyle];
    
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
     
    PlotItem *item = [[SimpleScatterPlot alloc] init];
    [item setData:[[DataSeries alloc] initWithName:@"OCR"]];
    [self setPlotItem:item];
}

-(void)dealloc
{
	[self setPlotItem:nil];
}

- (IBAction)plotData:(id)sender
{
    int selectedItem = (int) [[pairPicker selectedItem] tag];
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateStyle:NSDateFormatterMediumStyle];
    NSDate *datePicked = [datePicker  dateValue];
    DataSeries *dataForPlot;
    
    NSString *filterValueRequested = filterValue.stringValue; 
    NSString *filterValueUnit = [[filterUnit selectedCell] title];
    
    int dataSampledToSeconds = 0;
    
    if([filterValueUnit isEqualToString:@"Seconds"]){
        if([filterValueRequested intValue]>1){
//            NSLog(@"Filter value is %@ second(s)", filterValueRequested);
//            dataToPlot = [dataController getBidAskSeriesForId:selectedItem 
//                                                       AndDay:datePicked 
//                                             ToSampledSeconds:[filterValueRequested intValue]];
            dataSampledToSeconds = [filterValueRequested intValue];
        }else{
            //dataToPlot = [dataController getBidAskSeriesForId: selectedItem AndDay:datePicked];
            dataSampledToSeconds = 0;
        }
    }else{
        NSLog(@"Filter value is %@ minute(s)", filterValueRequested);
//        dataToPlot = [dataController getBidAskSeriesForId:selectedItem 
//                                                   AndDay:datePicked 
//                                         ToSampledSeconds:([filterValueRequested intValue]*60)];
        dataSampledToSeconds = [filterValueRequested intValue]*60;
    }
    dataForPlot = [dataController getBidAskSeriesForId:selectedItem 
                                               AndDay:datePicked 
                                     ToSampledSeconds:dataSampledToSeconds];
    
    
    PlotItem *item = [[SimpleScatterPlot alloc] init];
    [item setData:dataForPlot];
    [self setPlotItem:item];
    [plotItem showSeries:[[bidAskPicker selectedCell] title]];
   
}

- (IBAction)changeSeriesType:(id)sender {
    //PlotItem *item = [[PlotGallery sharedPlotGallery] objectAtIndex:0];
    NSString *seriesType = [[bidAskPicker selectedCell] title];
    [plotItem showSeries:seriesType];
}

- (IBAction)changePair:(id)sender {
    //DataIO *database;
    long *initialDateRange;
    NSInteger selectedItem = [[pairPicker selectedItem] tag]; 
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateStyle:NSDateFormatterMediumStyle];
    BOOL rangeAlreadyStored;
    long startDate;
    long endDate;
    
    NSLog(@"New Choice is %@",[[pairPicker selectedItem] title] );
    
    for(int i = 0; i < [pairListWithId count];i++){
        if(([[pairListWithId objectAtIndex:i] dbid] == selectedItem) ){
            if((pairListMaxDates[i] != 0)){
                rangeAlreadyStored = YES;
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
#pragma mark PlotItem Property

-(PlotItem *)plotItem
{
	return plotItem;
}

-(void)setPlotItem:(PlotItem *)item
{
    plotItem = item;
    [plotItem renderInView:hostingView withTheme:[CPTTheme themeNamed:kCPTDarkGradientTheme]];	
}

@end















