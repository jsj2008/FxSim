//
//  AppController.m
//  Simple Sim
//
//  Created by O'Connor Martin on 19/12/2011.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "AppController.h"
//#import "DataIO.h"
//#import "IdNamePair.h"
//#import "EpochTime.h"
//#import "DataSeries.h"
//#import "PlotController.h"


//NSString *ocrMinStr = @"min";
//NSString *ocrMaxStr = @"max";
//NSString *ocrIdStr = @"Id";
//NSString *ocrDescriptionStr = @"description";


@implementation AppController
//@synthesize mainGraph;
//@synthesize dayOfWeekLabel;
//@synthesize datePicker;
//@synthesize minAvailableDate;
//@synthesize maxAvailableDate;
//@synthesize plotController;


//NSArray *pairListWithId;
//NSArray *dataTypeListWithId;
//long *pairListMinDates;
//long *pairListMaxDates;

-(id)init
{
    self = [super init];
    return self;
}


-(void)awakeFromNib
{
//    NSInteger selectedItem;
//    DataIO *database = [[DataIO alloc]init];
//    long *initialDateRange;
//    NSMutableArray *pairList = [[NSMutableArray alloc]init ];
//    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
//    [dateFormatter setDateStyle:NSDateFormatterMediumStyle];
//    
//    dataTypeListWithId = [database getListofDataTypes];
//    pairListWithId = [database getListofPairs];
//    if([pairListWithId count] > 0)
//    {
//        pairListMinDates = calloc(sizeof(long),[pairListWithId count]);
//        pairListMaxDates = calloc(sizeof(long),[pairListWithId count]);
//    }
//    
//    for (IdNamePair *myArrayElement in pairListWithId) {
//        [pairList addObject:[myArrayElement description]];
//    }
//    
//    [pairPicker removeAllItems];
//    [pairPicker addItemsWithTitles:pairList];
//    [pairPicker selectItemAtIndex:0];
//    
//    for (IdNamePair *myArrayElement in pairListWithId) {
//        [[pairPicker itemWithTitle:[myArrayElement description]] setTag:[myArrayElement dbid]];
//    }
//    
//    selectedItem = [[pairPicker selectedItem] tag];
//       
//    NSLog(@"Select Item %ld",selectedItem);    
//    initialDateRange = [database getDateRangeForSeries:selectedItem];
//    
//    [fromDateLabel setStringValue:[dateFormatter stringFromDate:[NSDate dateWithTimeIntervalSince1970:(NSTimeInterval) initialDateRange[0]]]];
//    [toDateLabel setStringValue:[dateFormatter stringFromDate:[NSDate dateWithTimeIntervalSince1970:(NSTimeInterval) initialDateRange[1]]]];
//    for(int i = 0; i < [pairListWithId count]; i++)
//    {
//        if(selectedItem== [[pairListWithId objectAtIndex:i] dbid]){
//            NSLog(@"Adding mins and max for item %@", [[pairListWithId objectAtIndex:i] description]);
//            pairListMinDates[i] = initialDateRange[0]; 
//            pairListMaxDates[i] = initialDateRange[1];
//        }
//        
//    }
//    
//    [datePicker setMinDate:[NSDate dateWithTimeIntervalSince1970:(NSTimeInterval) initialDateRange[0]]];
//    [datePicker setMaxDate:[NSDate dateWithTimeIntervalSince1970:(NSTimeInterval) initialDateRange[1]]];
//    NSDate *initialDate = [datePicker dateValue];
//    //NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
//    [dateFormatter setDateFormat:@"EEE"];
//    NSString *dayName = [dateFormatter stringFromDate:initialDate];
//    [dayOfWeekLabel setStringValue:[dayName substringToIndex:3]]; 
//    //plotController = [[PlotController alloc] init]; 
//
    
}

//- (IBAction)changePair:(id)sender {
//    DataIO *database;
//    long *initialDateRange;
//    NSInteger selectedItem = [[pairPicker selectedItem] tag]; 
//    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
//    [dateFormatter setDateStyle:NSDateFormatterMediumStyle];
//    BOOL rangeAlreadyStored;
//    long startDate;
//    long endDate;
//    
//    NSLog(@"New Choice is %@",[[pairPicker selectedItem] title] );
//    
//    for(int i = 0; i < [pairListWithId count];i++){
//        if(([[pairListWithId objectAtIndex:i] dbid] == selectedItem) ){
//            if((pairListMaxDates[i] != 0)){
//                rangeAlreadyStored = YES;
//                startDate = pairListMinDates[i];
//                endDate = pairListMaxDates[i];
//                NSLog(@"Already had range for %@", [[pairListWithId objectAtIndex:i] description]);
//            }else{
//                database = [[DataIO alloc]init];
//                initialDateRange = [database getDateRangeForSeries:selectedItem];
//                startDate = initialDateRange[0];
//                endDate = initialDateRange[1];
//                pairListMinDates[i] = startDate;
//                pairListMaxDates[i] = endDate;
//                NSLog(@"Added mins and max for item %@", [[pairListWithId objectAtIndex:i] description]);
//            }
//        }
//    }
//    
//    [fromDateLabel setStringValue:[dateFormatter stringFromDate:[NSDate dateWithTimeIntervalSince1970:(NSTimeInterval) startDate]]];
//    [toDateLabel setStringValue:[dateFormatter stringFromDate:[NSDate dateWithTimeIntervalSince1970:(NSTimeInterval) endDate]]];
//   
//    [datePicker setMinDate:[NSDate dateWithTimeIntervalSince1970:(NSTimeInterval) startDate]];
//    [datePicker setMaxDate:[NSDate dateWithTimeIntervalSince1970:(NSTimeInterval) endDate]];
//    
//    //NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
//    [dateFormatter setDateFormat:@"EEE"];
//    NSString *dayName = [dateFormatter stringFromDate:[datePicker dateValue]];
//    //Optional - get first 3 letters of days name
//    //dayName = [dayName substringToIndex:3];
//    [dayOfWeekLabel setStringValue:[dayName substringToIndex:3]]; 
//
//  }

//- (IBAction)plotData:(id)sender
//{
//    //EpochTime *timeConverter = [[EpochTime alloc] init ];
//    int selectedItem = (int) [[pairPicker selectedItem] tag];
//    NSString *selectedItemName = [pairPicker titleOfSelectedItem];
//    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
//    [dateFormatter setDateStyle:NSDateFormatterMediumStyle];
//    NSDate *datePicked = [datePicker  dateValue];
//    long dateStartTime;
//    long dateEndTime;
//    DataSeries *dataToPlot;
//    DataIO *getData = [[DataIO alloc] init];
//    
//  
//    dateStartTime = [datePicked timeIntervalSince1970];
//    dateEndTime = [EpochTime epochTimeNextDayAtZeroHour:dateStartTime];
//    dateStartTime = [EpochTime epochTimeAtZeroHour:dateStartTime];
//    
//    NSLog(@"PLotting data for %d %@ on %@ from %lu to %lu",selectedItem, selectedItemName,[dateFormatter stringFromDate:datePicked],dateStartTime,dateEndTime);
//    dataToPlot = [getData getDataSeriesForId:selectedItem  AndType:1 AndStartTime:dateStartTime AndEndTime:dateEndTime];
//    NSLog(@"Plotting %lu values of %@",[dataToPlot count],[dataToPlot name]);
////    dataToPlot = [getData getDataSeriesForId:selectedItem  AndType:1 AndStartTime:dateStartTime AndEndTime:dateEndTime AndGranularity:60];
////    NSLog(@"Plotting %d values of %@",[dataToPlot length],[dataToPlot name]); 
//    
//    
//    // Add some data
//    
////    NSMutableArray *newData = [NSMutableArray array];
////    NSUInteger i;
////    for ( i = 0; i < 7; i++ ) {
////        NSTimeInterval x = 60 * 60 * 24 * i * 0.5f;
////        id y			 = [NSDecimalNumber numberWithFloat:1.2 * rand() / (float)RAND_MAX + 1.2];
////        [newData addObject:
////         [NSDictionary dictionaryWithObjectsAndKeys:
////          [NSDecimalNumber numberWithFloat:x], [NSNumber numberWithInt:CPTScatterPlotFieldX], y, [NSNumber numberWithInt:CPTScatterPlotFieldY], nil]];
////     }
//    //PlotController *appDelegate = (AppDelegate *)[NSApp delegate];
//    //[PlotController setPlotData:newData]; 
//    //[[PlotController graph] reloadData];
//    
//    [plotController plotFirstPlotInGallery];
//    NSLog(@"Set the plot data");
//}


//- (IBAction)changeDate:(id)sender {
//    NSDate *datePicked = [datePicker  dateValue];
//    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
//    [dateFormatter setDateFormat:@"EEE"];
//    NSString *dayName = [dateFormatter stringFromDate:datePicked];
//    //Optional - get first 3 letters of days name
//    //dayName = [dayName substringToIndex:3];
//    [dayOfWeekLabel setStringValue:[dayName substringToIndex:3]]; 
//    
//    NSLog(@"Date is now %@",datePicked);
//}





@end
