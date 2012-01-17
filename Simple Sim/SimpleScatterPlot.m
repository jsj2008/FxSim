//
//  SimpleScatterPlot.m
//  CorePlotGallery
//
//  Created by Jeff Buck on 7/31/10.
//  Copyright 2010 Jeff Buck. All rights reserved.
//

#import "SimpleScatterPlot.h"
#import "DataSeries.h"

@implementation SimpleScatterPlot

+(void)load
{
	[super registerPlotItem:self];
}

-(id)init
{
	if ( (self = [super init]) ) {
		title = @"Simple Scatter Plot";
	}
    
	return self;
}

-(void)killGraph
{
	if ( [graphs count] ) {
		CPTGraph *graph = [graphs objectAtIndex:0];
        
		if ( symbolTextAnnotation ) {
			[graph.plotAreaFrame.plotArea removeAnnotation:symbolTextAnnotation];
//			[symbolTextAnnotation release];
			symbolTextAnnotation = nil;
		}
	}
    
	[super killGraph];
}

-(void)setData:(DataSeries *) newData
{
    plotData = newData ; 
}


-(void)generateData
{
//	if ( plotData == nil ) {
//		NSMutableArray *contentArray = [NSMutableArray array];
//		for ( NSUInteger i = 0; i < 10; i++ ) {
//			id x = [NSDecimalNumber numberWithDouble:1.0 + i * 0.05];
//			id y = [NSDecimalNumber numberWithDouble:1.2 * rand() / (double)RAND_MAX + 0.5];
//			[contentArray addObject:[NSMutableDictionary dictionaryWithObjectsAndKeys:x, @"x", y, @"y", nil]];
//		}
//		plotData = contentArray;
//	}
}

-(void)renderInLayer:(CPTGraphHostingView *)layerHostingView withTheme:(CPTTheme *)theme
{
	CGRect bounds = NSRectToCGRect(layerHostingView.bounds);
    
	CPTGraph *graph = [[CPTXYGraph alloc] initWithFrame:bounds];
	[self addGraph:graph toHostingView:layerHostingView];
	[self applyTheme:theme toGraph:graph withDefault:[CPTTheme themeNamed:kCPTDarkGradientTheme]];
    
	[self setTitleDefaultsForGraph:graph withBounds:bounds];
	[self setPaddingDefaultsForGraph:graph withBounds:bounds];
    
	// Setup scatter plot space
	CPTXYPlotSpace *plotSpace = (CPTXYPlotSpace *)graph.defaultPlotSpace;
	plotSpace.allowsUserInteraction = YES;
	plotSpace.delegate				= self;
    
	// Grid line styles
	CPTMutableLineStyle *majorGridLineStyle = [CPTMutableLineStyle lineStyle];
	majorGridLineStyle.lineWidth = 0.75;
	majorGridLineStyle.lineColor = [[CPTColor colorWithGenericGray:0.2] colorWithAlphaComponent:0.75];
    
	CPTMutableLineStyle *minorGridLineStyle = [CPTMutableLineStyle lineStyle];
	minorGridLineStyle.lineWidth = 0.25;
	minorGridLineStyle.lineColor = [[CPTColor whiteColor] colorWithAlphaComponent:0.1];
    
    CPTMutableLineStyle *axisLineStyle =  [CPTMutableLineStyle lineStyle];
    axisLineStyle.lineWidth = 0.5;
    axisLineStyle.lineColor = [[CPTColor whiteColor] colorWithAlphaComponent:0.5];
   
    
    
//	CPTMutableLineStyle *redLineStyle = [CPTMutableLineStyle lineStyle];
//	redLineStyle.lineWidth = 10.0;
//	redLineStyle.lineColor = [[CPTColor redColor] colorWithAlphaComponent:0.5];
    
    [graph setTitle:[plotData name]];
    
    
    
	// Axes
    double majorIntervalY = 10 * [plotData pipSize];
    while((([plotData maxYdata]-[plotData minYdata])/majorIntervalY)>10){
        majorIntervalY = majorIntervalY * 2;
    }
    
    double xAxisYValue = majorIntervalY*floor([plotData minYdata]/majorIntervalY);
    double yAxisLength = ([plotData maxYdata] - xAxisYValue) * 1.4;
    double yAxisMin = xAxisYValue - (([plotData maxYdata] - xAxisYValue) * 0.2);
    
	// Label x axis with a fixed interval policy
	CPTXYAxisSet *axisSet = (CPTXYAxisSet *)graph.axisSet;
	CPTXYAxis *x		  = axisSet.xAxis;
    
    
	x.majorIntervalLength		  = CPTDecimalFromString(@"14400"); // 4 hours
    x.orthogonalCoordinateDecimal = CPTDecimalFromDouble(xAxisYValue);
	x.minorTicksPerInterval		  = 3;
	x.majorGridLineStyle		  = majorGridLineStyle;
	x.minorGridLineStyle		  = minorGridLineStyle;
    
	x.title			= @"X Axis";
	x.titleOffset	= 30.0;
	x.titleLocation = CPTDecimalFromString(@"1.25");
    
    x.axisLineStyle = axisLineStyle;
   
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init] ;
	dateFormatter.dateStyle = kCFDateFormatterNoStyle;
    dateFormatter.timeStyle = kCFDateFormatterShortStyle;
    dateFormatter.timeZone = [NSTimeZone timeZoneWithName:@"GMT"];
    
    // America/New_York
    // Europe/London
    // Europe/Paris
    // Asia/Tokyo
    
	CPTTimeFormatter *timeFormatter = [[CPTTimeFormatter alloc] initWithDateFormatter:dateFormatter] ;
    NSDate *refDate = [NSDate dateWithTimeIntervalSince1970:0];
	timeFormatter.referenceDate = refDate;
	x.labelFormatter			= timeFormatter;
	x.labelRotation				= M_PI / 4;
    
    
    NSNumberFormatter *numberFormatter = [[NSNumberFormatter alloc] init];
    [numberFormatter setNumberStyle:NSNumberFormatterDecimalStyle];
    if([plotData pipSize] <= 0.001){
        [numberFormatter setMinimumFractionDigits:3];
    }else{
        [numberFormatter setMinimumFractionDigits:1];
    }
        
    CPTXYAxis *y = axisSet.yAxis;
    y.majorIntervalLength		  = CPTDecimalFromDouble(majorIntervalY);
    y.orthogonalCoordinateDecimal = CPTDecimalFromDouble((double)[plotData minXdata]);
    y.minorTicksPerInterval		  = 1;
    y.majorGridLineStyle		  = majorGridLineStyle;
    y.minorGridLineStyle		  = minorGridLineStyle;
    y.labelFormatter              = numberFormatter;
    
    y.axisLineStyle               = axisLineStyle;
    
	// Label y with an automatic label policy.
//	CPTXYAxis *y = axisSet.yAxis;
//	y.labelingPolicy			  = CPTAxisLabelingPolicyAutomatic;
//	y.orthogonalCoordinateDecimal = CPTDecimalFromDouble((double)[plotData minXdata]);
//	y.minorTicksPerInterval		  = 2;
//	y.preferredNumberOfMajorTicks = 8;
//	y.majorGridLineStyle		  = majorGridLineStyle;
//	y.minorGridLineStyle		  = minorGridLineStyle;
//	y.labelOffset				  = 10.0;
    
//	y.title			= @"Y Axis";
//	y.titleOffset	= 30.0;
//	y.titleLocation = CPTDecimalFromString(@"1.0");
    
	// Set axes
	//graph.axisSet.axes = [NSArray arrayWithObjects:x, y, y2, nil];
	graph.axisSet.axes = [NSArray arrayWithObjects:x, y, nil];
    
    
	// Create a plot that uses the data source method
	CPTScatterPlot *dataSourceLinePlot = [[CPTScatterPlot alloc] init];
	dataSourceLinePlot.identifier = @"BID";
    
	CPTMutableLineStyle *lineStyle = [dataSourceLinePlot.dataLineStyle mutableCopy];
	lineStyle.lineWidth				 = 1.0;
	lineStyle.lineColor				 = [CPTColor greenColor];
	dataSourceLinePlot.dataLineStyle = lineStyle;
    
	dataSourceLinePlot.dataSource = self;
	[graph addPlot:dataSourceLinePlot];
    
	// Auto scale the plot space to fit the plot data
	// Extend the ranges by 30% for neatness
	[plotSpace scaleToFitPlots:[NSArray arrayWithObjects:dataSourceLinePlot, nil]];
	CPTMutablePlotRange *xRange = [plotSpace.xRange mutableCopy];
	CPTMutablePlotRange *yRange = [plotSpace.yRange mutableCopy];
	[xRange expandRangeByFactor:CPTDecimalFromDouble(1.2)];
	[yRange expandRangeByFactor:CPTDecimalFromDouble(1.5)];
    
//    if(CPDecimalFloatValue([yRange location] >= xAxisYValue ){
//       [yRange setLocation:xAxisYValue] 
//    }
//       
//       CPTDecimalFromDouble
//    
       
    CPTPlotRange *plotRangeForY  = [CPTPlotRange plotRangeWithLocation:CPTDecimalFromDouble(yAxisMin) length:CPTDecimalFromDouble(yAxisLength)];
       
	plotSpace.xRange = xRange;
	plotSpace.yRange = plotRangeForY;
    
    
    
    
	// Restrict y range to a global range
	//CPTPlotRange *globalYRange = [CPTPlotRange plotRangeWithLocation:CPTDecimalFromDouble([plotData minYdata]-(1.2*majorIntervalY))
	//														  length:CPTDecimalFromDouble(([plotData maxYdata]-[plotData minYdata])+(2*majorIntervalY))];
    
	//plotSpace.globalYRange = globalYRange;
    plotSpace.globalYRange = 0;
	// Add plot symbols
	//CPTMutableLineStyle *symbolLineStyle = [CPTMutableLineStyle lineStyle];
	//symbolLineStyle.lineColor = [CPTColor blackColor];
	//CPTPlotSymbol *plotSymbol = [CPTPlotSymbol ellipsePlotSymbol];
	//plotSymbol.fill				  = [CPTFill fillWithColor:[CPTColor blueColor]];
	//plotSymbol.lineStyle		  = symbolLineStyle;
	//plotSymbol.size				  = CGSizeMake(10.0, 10.0);
	//dataSourceLinePlot.plotSymbol = plotSymbol;
    
	// Set plot delegate, to know when symbols have been touched
	// We will display an annotation when a symbol is touched
	//dataSourceLinePlot.delegate						   = self;
	//dataSourceLinePlot.plotSymbolMarginForHitDetection = 5.0f;
    
//	// Add legend
//	graph.legend				 = [CPTLegend legendWithGraph:graph];
//	graph.legend.textStyle		 = x.titleTextStyle;
//	graph.legend.fill			 = [CPTFill fillWithColor:[CPTColor darkGrayColor]];
//	graph.legend.borderLineStyle = x.axisLineStyle;
//	graph.legend.cornerRadius	 = 5.0;
//	graph.legend.swatchSize		 = CGSizeMake(25.0, 25.0);
//	graph.legendAnchor			 = CPTRectAnchorBottom;
//	graph.legendDisplacement	 = CGPointMake(0.0, 12.0);
}

#pragma mark -
#pragma mark Plot Data Source Methods

-(NSUInteger)numberOfRecordsForPlot:(CPTPlot *)plot
{
	return [plotData count];
}

- (CPTNumericData *)dataForPlot:(CPTPlot  *)plot 
                          field:(NSUInteger)field 
               recordIndexRange:(NSRange   )indexRange 
{
    return [plotData dataForPlot:plot field:field recordIndexRange:indexRange];
    
}

//-(NSNumber *)numberForPlot:(CPTPlot *)plot field:(NSUInteger)fieldEnum recordIndex:(NSUInteger)index
//{
//	NSString *key = (fieldEnum == CPTScatterPlotFieldX ? @"x" : @"y");
//	NSNumber *num = [[plotData objectAtIndex:index] valueForKey:key];
//    
//	if ( fieldEnum == CPTScatterPlotFieldY ) {
//		num = [NSNumber numberWithDouble:[num doubleValue]];
//	}
//	return num;
//}

#pragma mark -
#pragma mark Plot Space Delegate Methods

-(CPTPlotRange *)plotSpace:(CPTPlotSpace *)space willChangePlotRangeTo:(CPTPlotRange *)newRange forCoordinate:(CPTCoordinate)coordinate
{
	// Impose a limit on how far user can scroll in x
	if ( coordinate == CPTCoordinateX ) {
		CPTPlotRange *maxRange			  = [CPTPlotRange plotRangeWithLocation:CPTDecimalFromInt((int)[plotData minXdata]-(60*60*3)) length:CPTDecimalFromInt((int)(60*60*30))];
		CPTMutablePlotRange *changedRange = [newRange mutableCopy];
		[changedRange shiftEndToFitInRange:maxRange];
		[changedRange shiftLocationToFitInRange:maxRange];
		newRange = changedRange;
	}
    
    if ( coordinate == CPTCoordinateY ) {
		CPTPlotRange *maxRange = [CPTPlotRange plotRangeWithLocation:CPTDecimalFromDouble([plotData minYdata]-(0.5*([plotData maxYdata]-[plotData minYdata]))) length:CPTDecimalFromDouble(((2*([plotData maxYdata]-[plotData minYdata]))))];
		CPTMutablePlotRange *changedRange = [newRange mutableCopy];
		[changedRange shiftEndToFitInRange:maxRange];
		[changedRange shiftLocationToFitInRange:maxRange];
		newRange = changedRange;
	}
    
	return newRange;
}

-(BOOL)plotSpace:(CPTPlotSpace *)space shouldHandlePointingDeviceDraggedEvent:(id)event atPoint:(CGPoint)point
{
    NSLog(@"Drag Event");
    return NO;
}


//#pragma mark -
//#pragma mark CPTScatterPlot delegate method

//-(void)scatterPlot:(CPTScatterPlot *)plot plotSymbolWasSelectedAtRecordIndex:(NSUInteger)index
//{
//	CPTXYGraph *graph = [graphs objectAtIndex:0];
//    
//	if ( symbolTextAnnotation ) {
//		[graph.plotAreaFrame.plotArea removeAnnotation:symbolTextAnnotation];
////		[symbolTextAnnotation release];
//		symbolTextAnnotation = nil;
//	}
//    
//	// Setup a style for the annotation
//	CPTMutableTextStyle *hitAnnotationTextStyle = [CPTMutableTextStyle textStyle];
//	hitAnnotationTextStyle.color	= [CPTColor whiteColor];
//	hitAnnotationTextStyle.fontSize = 16.0f;
//	hitAnnotationTextStyle.fontName = @"Helvetica-Bold";
//    
//	// Determine point of symbol in plot coordinates
//	NSNumber *x			 = [[plotData objectAtIndex:index] valueForKey:@"x"];
//	NSNumber *y			 = [[plotData objectAtIndex:index] valueForKey:@"y"];
//	NSArray *anchorPoint = [NSArray arrayWithObjects:x, y, nil];
//    
//	// Add annotation
//	// First make a string for the y value
//	NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
//	[formatter setMaximumFractionDigits:2];
//	NSString *yString = [formatter stringFromNumber:y];
//    
//	// Now add the annotation to the plot area
//	CPTTextLayer *textLayer = [[CPTTextLayer alloc] initWithText:yString style:hitAnnotationTextStyle];
//	symbolTextAnnotation			  = [[CPTPlotSpaceAnnotation alloc] initWithPlotSpace:graph.defaultPlotSpace anchorPlotPoint:anchorPoint];
//	symbolTextAnnotation.contentLayer = textLayer;
//	symbolTextAnnotation.displacement = CGPointMake(0.0f, 20.0f);
//	[graph.plotAreaFrame.plotArea addAnnotation:symbolTextAnnotation];
//}

@end
