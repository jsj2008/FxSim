//
//  PlotGalleryController.m
//  CorePlotGallery
//
//  Created by Jeff Buck on 9/5/10.
//  Copyright 2010 Jeff Buck. All rights reserved.
//



//#import "dlfcn.h"
//#define EMBED_NU	1

#import "PlotController.h"
#import "DataIO.h"
#import "IdNamePair.h"
#import "EpochTime.h"
#import "DataSeries.h"
#import "PlotController.h"


const float CPT_SPLIT_VIEW_MIN_LHS_WIDTH = 150.0f;

#define kThemeTableViewControllerNoTheme	  @"None"
#define kThemeTableViewControllerDefaultTheme @"Default"


@implementation PlotController
@synthesize pairPicker;
@synthesize toDateLabel;
@synthesize fromDateLabel;
@synthesize dayOfWeekLabel;
@synthesize mainGraph;
@synthesize datePicker;
@synthesize minAvailableDate;
@synthesize maxAvailableDate;
@dynamic plotItem;
//@synthesize currentThemeName;

NSArray *pairListWithId;
NSArray *dataTypeListWithId;
long *pairListMinDates;
long *pairListMaxDates;


//-(void)setupThemes
//{
//	[themePopUpButton addItemWithTitle:kThemeTableViewControllerDefaultTheme];
//	[themePopUpButton addItemWithTitle:kThemeTableViewControllerNoTheme];
//    
//	for ( Class c in [CPTTheme themeClasses] ) {
//		[themePopUpButton addItemWithTitle:[c name]];
//	}
//    
//	self.currentThemeName = kThemeTableViewControllerDefaultTheme;
//	[themePopUpButton selectItemWithTitle:kThemeTableViewControllerDefaultTheme];
//}

-(void)awakeFromNib
{
//	[[PlotGallery sharedPlotGallery] sortByTitle];
    
//	[splitView setDelegate:self];
    
//	[imageBrowser setDelegate:self];
//	[imageBrowser setDataSource:self];
//	[imageBrowser setCellsStyleMask:IKCellsStyleShadowed | IKCellsStyleTitled]; //| IKCellsStyleSubtitled];
//    
//	[imageBrowser reloadData];
    NSInteger selectedItem;
    DataIO *database = [[DataIO alloc]init];
    long *initialDateRange;
    NSMutableArray *pairList = [[NSMutableArray alloc]init ];
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateStyle:NSDateFormatterMediumStyle];
    
    dataTypeListWithId = [database getListofDataTypes];
    pairListWithId = [database getListofPairs];
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
    initialDateRange = [database getDateRangeForSeries:selectedItem];
    
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
    //NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"EEE"];
    NSString *dayName = [dateFormatter stringFromDate:initialDate];
    [dayOfWeekLabel setStringValue:[dayName substringToIndex:3]]; 
    //plotController = [[PlotController alloc] init]; 
     
	[hostingView setDelegate:self];
    
    //theme = kCPTPlainBlackTheme;
	//[self setupThemes];
    
    //PlotItem *item = [[PlotGallery sharedPlotGallery] objectAtIndex:1];
    //[self setPlotItem:item];

    
}


-(void)setFrameSize:(NSSize)newSize
{
	if ( [plotItem respondsToSelector:@selector(setFrameSize:)] ) {
		[plotItem setFrameSize:newSize];
	}
}


-(void)dealloc
{
	[self setPlotItem:nil];
}

- (IBAction)plotData:(id)sender
{
    //EpochTime *timeConverter = [[EpochTime alloc] init ];
    int selectedItem = (int) [[pairPicker selectedItem] tag];
    NSString *selectedItemName = [pairPicker titleOfSelectedItem];
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateStyle:NSDateFormatterMediumStyle];
    NSDate *datePicked = [datePicker  dateValue];
    long dateStartTime;
    long dateEndTime;
    DataSeries *dataToPlot;
    DataIO *getData = [[DataIO alloc] init];
  
    dateStartTime = [datePicked timeIntervalSince1970];
    dateEndTime = [EpochTime epochTimeNextDayAtZeroHour:dateStartTime];
    dateStartTime = [EpochTime epochTimeAtZeroHour:dateStartTime];
    
    NSLog(@"PLotting data for %d %@ on %@ from %lu to %lu",selectedItem, selectedItemName,[dateFormatter stringFromDate:datePicked],dateStartTime,dateEndTime);
    dataToPlot = [getData getDataSeriesForId:selectedItem  AndType:1 AndStartTime:dateStartTime AndEndTime:dateEndTime];
    NSLog(@"Plotting %lu values of %@",[dataToPlot count],[dataToPlot name]);
    
    PlotItem *item = [[PlotGallery sharedPlotGallery] objectAtIndex:0];
    [item setData:dataToPlot];
    [self setPlotItem:item];
//    PlotItem *item = [[PlotGallery sharedPlotGallery] objectAtIndex:1];
//    [self setPlotItem:item];

    NSLog(@"Set the plot data");
}

- (IBAction)changePair:(id)sender {
    DataIO *database;
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
                database = [[DataIO alloc]init];
                initialDateRange = [database getDateRangeForSeries:selectedItem];
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
    
    //NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"EEE"];
    NSString *dayName = [dateFormatter stringFromDate:[datePicker dateValue]];
    //Optional - get first 3 letters of days name
    //dayName = [dayName substringToIndex:3];
    [dayOfWeekLabel setStringValue:[dayName substringToIndex:3]]; 
    
}

- (IBAction)changeDate:(id)sender {
    NSDate *datePicked = [datePicker  dateValue];
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"EEE"];
    NSString *dayName = [dateFormatter stringFromDate:datePicked];
    //Optional - get first 3 letters of days name
    //dayName = [dayName substringToIndex:3];
    [dayOfWeekLabel setStringValue:[dayName substringToIndex:3]]; 
    
    NSLog(@"Date is now %@",datePicked);
}

//#pragma mark -
//#pragma mark Theme Selection

//-(CPTTheme *)currentTheme
//{
//	CPTTheme *theme;
//    
//	if ( currentThemeName == kThemeTableViewControllerNoTheme ) {
//		theme = (id)[NSNull null];
//	}
//	else if ( currentThemeName == kThemeTableViewControllerDefaultTheme ) {
//		theme = nil;
//	}
//	else {
//		theme = [CPTTheme themeNamed:currentThemeName];
//	}
//    //theme = (id)[NSNull null];
//	return theme;
//}
//
//-(IBAction)themeSelectionDidChange:(id)sender
//{
//	self.currentThemeName = [sender titleOfSelectedItem];
//	[plotItem renderInView:hostingView withTheme:[self currentTheme]];
//}

#pragma mark -
#pragma mark PlotItem Property

-(PlotItem *)plotItem
{
	return plotItem;
}

-(void)setPlotItem:(PlotItem *)item
{
//	if ( plotItem != item ) {
//		[plotItem killGraph];
//        
		plotItem = item;
//    }    
		[plotItem renderInView:hostingView withTheme:[CPTTheme themeNamed:kCPTPlainBlackTheme]];
	
}




//
//#pragma mark IKImageBrowserViewDataSource methods
//
//-(NSUInteger)numberOfItemsInImageBrowser:(IKImageBrowserView *)browser
//{
//	return [[PlotGallery sharedPlotGallery] count];
//}
//
//-(id)imageBrowser:(IKImageBrowserView *)browser itemAtIndex:(NSUInteger)index
//{
//	return [[PlotGallery sharedPlotGallery] objectAtIndex:index];
//}

//#pragma mark IKImageBrowserViewDelegate methods
//
//-(void)imageBrowserSelectionDidChange:(IKImageBrowserView *)browser
//{
//	NSUInteger index = [[browser selectionIndexes] firstIndex];
//    
//	if ( index != NSNotFound ) {
//		PlotItem *item = [[PlotGallery sharedPlotGallery] objectAtIndex:index];
//		self.plotItem = item;
//	}
//}

//#pragma mark NSSplitViewDelegate methods
//
//-(CGFloat)splitView:(NSSplitView *)sv constrainMinCoordinate:(CGFloat)coord ofSubviewAt:(NSInteger)index
//{
//	return coord + CPT_SPLIT_VIEW_MIN_LHS_WIDTH;
//}
//
//-(CGFloat)splitView:(NSSplitView *)sv constrainMaxCoordinate:(CGFloat)coord ofSubviewAt:(NSInteger)index
//{
//	return coord - CPT_SPLIT_VIEW_MIN_LHS_WIDTH;
//}
//
//-(void)splitView:(NSSplitView *)sender resizeSubviewsWithOldSize:(NSSize)oldSize
//{
//	// Lock the LHS width
//	NSRect frame   = [sender frame];
//	NSView *lhs	   = [[sender subviews] objectAtIndex:0];
//	NSRect lhsRect = [lhs frame];
//	NSView *rhs	   = [[sender subviews] objectAtIndex:1];
//	NSRect rhsRect = [rhs frame];
//    
//	CGFloat dividerThickness = [sender dividerThickness];
//    
//	lhsRect.size.height = frame.size.height;
//    
//	rhsRect.size.width	= frame.size.width - lhsRect.size.width - dividerThickness;
//	rhsRect.size.height = frame.size.height;
//	rhsRect.origin.x	= lhsRect.size.width + dividerThickness;
//    
//	[lhs setFrame:lhsRect];
//	[rhs setFrame:rhsRect];
//}

@end








//#import "PlotController.h"
//#import <CorePlot/CorePlot.h>
//
//@implementation PlotController
//
//@synthesize plotData;
//@synthesize graph;
//
//-(void)awakeFromNib{
//    
//  	// If you make sure your dates are calculated at noon, you shouldn't have to
//	// worry about daylight savings. If you use midnight, you will have to adjust
//	// for daylight savings time.
//	NSDate *refDate		  = [NSDate dateWithTimeIntervalSinceNow:0];
//	NSTimeInterval oneDay = 24 * 60 * 60;
//    
//	// Create graph from theme
//	graph = [(CPTXYGraph *)[CPTXYGraph alloc] initWithFrame:CGRectZero];
//	CPTTheme *theme = [CPTTheme themeNamed:kCPTPlainBlackTheme];
//	[graph applyTheme:theme];
//	hostView.hostedGraph = graph;
//    
//	// Setup scatter plot space
//	CPTXYPlotSpace *plotSpace = (CPTXYPlotSpace *)graph.defaultPlotSpace;
//	NSTimeInterval xLow		  = 0.0f;
//	plotSpace.xRange = [CPTPlotRange plotRangeWithLocation:CPTDecimalFromFloat(xLow) length:CPTDecimalFromFloat(oneDay)];
//	plotSpace.yRange = [CPTPlotRange plotRangeWithLocation:CPTDecimalFromFloat(0.0) length:CPTDecimalFromFloat(3.0)];
//    
//	// Axes
//	CPTXYAxisSet *axisSet = (CPTXYAxisSet *)graph.axisSet;
//	CPTXYAxis *x		  = axisSet.xAxis;
//	x.majorIntervalLength		  = CPTDecimalFromFloat(oneDay);
//	x.orthogonalCoordinateDecimal = CPTDecimalFromString(@"0");
//	x.minorTicksPerInterval		  = 3;
//    
//	NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
//	dateFormatter.dateStyle = kCFDateFormatterShortStyle;
//	CPTTimeFormatter *myDateFormatter = [[CPTTimeFormatter alloc] initWithDateFormatter:dateFormatter];
//	myDateFormatter.referenceDate = refDate;
//	x.labelFormatter			  = myDateFormatter;
//    
//	NSDateFormatter *timeFormatter = [[NSDateFormatter alloc] init];
//	timeFormatter.timeStyle = kCFDateFormatterShortStyle;
//	CPTTimeFormatter *myTimeFormatter = [[CPTTimeFormatter alloc] initWithDateFormatter:timeFormatter];
//	myTimeFormatter.referenceDate = refDate;
//	x.minorTickLabelFormatter	  = myTimeFormatter;
//    //	x.minorTickLabelRotation = M_PI/2;
//    
//	CPTXYAxis *y = axisSet.yAxis;
//	y.majorIntervalLength		  = CPTDecimalFromString(@"0.5");
//	y.minorTicksPerInterval		  = 5;
//	y.orthogonalCoordinateDecimal = CPTDecimalFromFloat(0.0);
//    
//	// Create a plot that uses the data source method
//	CPTScatterPlot *dataSourceLinePlot = [[CPTScatterPlot alloc] init];
//	dataSourceLinePlot.identifier = @"Date Plot";
//    
//	CPTMutableLineStyle *lineStyle = [dataSourceLinePlot.dataLineStyle mutableCopy];
//	lineStyle.lineWidth				 = 1.f;
//	lineStyle.lineColor				 = [CPTColor greenColor];
//	dataSourceLinePlot.dataLineStyle = lineStyle;
//    
//	dataSourceLinePlot.dataSource = self;
//	[graph addPlot:dataSourceLinePlot];
//    
//    
//	// Add some data
//    
////     NSMutableArray *newData = [NSMutableArray array];
////     NSUInteger i;
////     for ( i = 0; i < 7; i++ ) {
////         NSTimeInterval x = oneDay * i * 0.5f;
////         id y			 = [NSDecimalNumber numberWithFloat:1.2 * rand() / (float)RAND_MAX + 1.2];
////         [newData addObject:
////          [NSDictionary dictionaryWithObjectsAndKeys:
////           [NSDecimalNumber numberWithFloat:x], [NSNumber numberWithInt:CPTScatterPlotFieldX],  y, [NSNumber numberWithInt:CPTScatterPlotFieldY], nil]];
////     }
////     plotData = newData; 
     
//}


// If the requested range is the same as our field range, then return 
// the corresponding field range, otherwise return a subrange. 
//- (CPTNumericData *)dataForField:(CPTScatterPlotField)field 
//                           range:(NSRange)range 
//{ 
//    CPTNumericData * data; 
//    if (field == CPTScatterPlotFieldX) data = self.xData; 
//    else                               data = self.yData; 
//    if (NSEqualRanges(range, NSMakeRange(0, self.count))) 
//    { 
//        return data; 
//    } 
//    else 
//    { 
//        CPTNumericDataType dataType = data.dataType; 
//        NSRange            subRange = NSMakeRange(range.location * dataType.sampleBytes, 
//                                                  range.length   * dataType.sampleBytes); 
//        return [CPTNumericData numericDataWithData:[data.data subdataWithRange:subRange] 
//                                          dataType:dataType 
//                                             shape:nil]; 
//    } 
//} 







//#pragma mark -
//#pragma mark Plot Data Source Methods


// Core plot plot provisioning callback; return the number of records 
// in the requested plot. 
//- (NSUInteger)numberOfRecordsForPlot:(CPTPlot *)plot 
//{ 
//    return [plotData count]; 
//} 

// Core plot data provisioning; return data for the requested range 
// on the requested axis. 
//- (CPTNumericData *)dataForPlot:(CPTPlot  *)plot 
//                          field:(NSUInteger)field 
//               recordIndexRange:(NSRange   )indexRange 
//{ 
//    return [plotData dataForField:field range:indexRange]; 
//} 


//-(NSUInteger)numberOfRecordsForPlot:(CPTPlot *)plot
//{
//    return plotData.count;
//}
//
//-(NSNumber *)numberForPlot:(CPTPlot *)plot field:(NSUInteger)fieldEnum recordIndex:(NSUInteger)index
//{
//    NSDecimalNumber *num = [[plotData objectAtIndex:index] objectForKey:[NSNumber numberWithInt:(int)fieldEnum]];
//    return num;
//}







//@end
