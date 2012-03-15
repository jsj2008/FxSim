//
//  SimpleScatterPlot.m
//  CorePlotGallery
//
//  Created by Jeff Buck on 7/31/10.
//  Copyright 2010 Jeff Buck. All rights reserved.
//

#import "SeriesPlot.h"
#import "DataSeries.h"
#import "DataView.h"
#import "EpochTime.h"
#import "TimeSeriesLine.h"

@interface SeriesPlot() 
-(void)fixUpAxes:(CPTXYAxisSet *) axisSet;
@end

@implementation SeriesPlot

@synthesize hostingView;
@synthesize graphs;
@synthesize title;

//+(void)load
//{
////	[super registerPlotItem:self];
//}

-(id)init
{
	if ( (self = [super init]) ) {
		title = @"Simple Scatter Plot";
	}
    
	return self;
}

//-(void)setDelegate:(id)del
//{
//    delegate = del;
//}
//
//-(id)delegate 
//{ 
//    return delegate;
//};

//-(void)killGraph
//{
//	if ( [graphs count] ) {
//		CPTGraph *graph = [graphs objectAtIndex:0];
//        
//		if ( symbolTextAnnotation ) {
//			[graph.plotAreaFrame.plotArea removeAnnotation:symbolTextAnnotation];
////			[symbolTextAnnotation release];
//			symbolTextAnnotation = nil;
//		}
//	}
//    
//	[super killGraph];
//}

-(void)setData:(DataSeries  *) newData WithViewName: (NSString *) viewName;
{
    plotData = newData ; 
    dataView = [[newData dataViews] objectForKey:viewName];
}


-(void)showSeries:(NSString *)seriesName;
{
    if([seriesName isEqual:[NSString stringWithString:@"ALL"]])
    {
        for(CPTPlot *plot in [graph allPlots]){
            plot.hidden = NO;
        }
    }else{
        for(CPTPlot *plot in [graph allPlots]){
            if([[plot identifier] isEqual:seriesName]){
                plot.hidden = NO;
            }else{
                plot.hidden = YES;
            }
        }
    }
}


-(void)initialGraph
{
   	CGRect bounds = NSRectToCGRect(hostingView.bounds);
    graph = [[CPTXYGraph alloc] initWithFrame:bounds];
	hostingView.hostedGraph = graph;
    [graph applyTheme:[CPTTheme themeNamed:kCPTDarkGradientTheme]];
    [graph setPaddingLeft:0];
	[graph setPaddingTop:0];
	[graph setPaddingRight:0];
	[graph setPaddingBottom:0];
    
    // Determine point of symbol in plot coordinates
    NSArray *anchorPoint = [NSArray arrayWithObjects:[NSDecimalNumber numberWithFloat:0.5],[NSDecimalNumber numberWithFloat:0.4], nil];
    
    // Add annotation
    NSString *mainString = [NSString stringWithString:@"OCR"];
    CPTMutableTextStyle *mainStringStyle = [CPTMutableTextStyle textStyle];
    mainStringStyle.color	= [CPTColor grayColor];
    mainStringStyle.fontSize = round(bounds.size.height / (CGFloat)5.0);
    mainStringStyle.fontName = @"Courier";
    
    CPTTextLayer *textLayer = [[CPTTextLayer alloc] initWithText:mainString style:mainStringStyle];
    CPTPlotSpaceAnnotation *mainTitleAnnotation = [[CPTPlotSpaceAnnotation alloc] initWithPlotSpace:graph.defaultPlotSpace anchorPlotPoint:anchorPoint];
    mainTitleAnnotation.contentLayer = textLayer;
    mainTitleAnnotation.displacement =  CGPointMake( 0.0f, round(bounds.size.height / (CGFloat)5.0) ); //CGPointMake(0.0f, 20.0f);
    [graph.plotAreaFrame.plotArea addAnnotation:mainTitleAnnotation];
    
    
    NSString *subString = [NSString stringWithString:@"2012, O'Connor Research"];
    CPTMutableTextStyle *subStringStyle = [CPTMutableTextStyle textStyle];
    subStringStyle.color	= [CPTColor grayColor];
    subStringStyle.fontSize = 12.0f;
    subStringStyle.fontName = @"Courier";
    
    textLayer = [[CPTTextLayer alloc] initWithText:subString style:subStringStyle];
    CPTPlotSpaceAnnotation *subTitleAnnotation = [[CPTPlotSpaceAnnotation alloc] initWithPlotSpace:graph.defaultPlotSpace anchorPlotPoint:anchorPoint];
    subTitleAnnotation.contentLayer = textLayer;
    [graph.plotAreaFrame.plotArea addAnnotation:subTitleAnnotation];
}

-(void)renderPlotWithFields: (NSArray *) linesToPlot 
{
    
    timeSeriesLines = linesToPlot; 
    CGRect bounds = NSRectToCGRect(hostingView.bounds);
    graph = [[CPTXYGraph alloc] initWithFrame:bounds];
    
    //graph = [(CPTXYGraph *)[CPTXYGraph alloc] initWithFrame:CGRectZero];
	CPTTheme *theme = [CPTTheme themeNamed:kCPTDarkGradientTheme];
	[graph applyTheme:theme];
	hostingView.hostedGraph = graph;
    
	graph.paddingLeft	= 0.0;
	graph.paddingTop	= 0.0;
	graph.paddingRight	= 0.0;
    graph.paddingBottom = 0.0;
    
	graph.plotAreaFrame.paddingLeft	  = 60.0;
	graph.plotAreaFrame.paddingTop	  = 40.0;
	graph.plotAreaFrame.paddingRight  = 40.0;
	graph.plotAreaFrame.paddingBottom = 60.0;
    
	graph.plotAreaFrame.plotArea.fill = graph.plotAreaFrame.fill;
	graph.plotAreaFrame.fill		  = nil;
    
	graph.plotAreaFrame.borderLineStyle = nil;
	graph.plotAreaFrame.cornerRadius	= 0.0;

    minYrangeForPlot = [[[dataView minYvalues] valueForKey:[[timeSeriesLines objectAtIndex:0] name]] doubleValue];
    maxYrangeForPlot = [[[dataView maxYvalues] valueForKey:[[timeSeriesLines objectAtIndex:0] name]] doubleValue]; 
    
    NSMutableArray *fieldNames = [[NSMutableArray alloc] init];
    NSMutableArray *colors = [[NSMutableArray alloc] init];
    for(TimeSeriesLine *tsLine in timeSeriesLines)
    {
        if([tsLine visible]){
            [fieldNames addObject:[tsLine name]];
            [colors addObject:[tsLine cpColour]];
            minYrangeForPlot = fmin(minYrangeForPlot,[[[dataView minYvalues] valueForKey:[tsLine name]] doubleValue]); 
            maxYrangeForPlot = fmax(maxYrangeForPlot,[[[dataView maxYvalues] valueForKey:[tsLine name]] doubleValue]);
            
        }else{
            [fieldNames addObject:[tsLine name]];
            [colors addObject:[CPTColor clearColor]];
        }
    }
      
    CPTXYAxisSet *axisSet = (CPTXYAxisSet *)graph.axisSet;
    [self fixUpAxes:axisSet];
    
    
    // Setup plot space
	CPTXYPlotSpace *plotSpace = (CPTXYPlotSpace *)graph.defaultPlotSpace;
    
    // Extend the ranges for neatness
    
    CPTMutablePlotRange *xRange = [CPTMutablePlotRange plotRangeWithLocation:CPTDecimalFromDouble(minXrangeForPlot)
                                                               length:CPTDecimalFromDouble(ceil( (maxXrangeForPlot - minXrangeForPlot) / majorIntervalForX ) * majorIntervalForX)];
    CPTMutablePlotRange *yRange = [CPTMutablePlotRange plotRangeWithLocation:CPTDecimalFromDouble(minYrangeForPlot)
                                                              length:CPTDecimalFromDouble(ceil( (maxYrangeForPlot - minYrangeForPlot) / majorIntervalForY ) * majorIntervalForY)];
    
    
    
    [xRange expandRangeByFactor:CPTDecimalFromDouble(1.1)];
    [yRange expandRangeByFactor:CPTDecimalFromDouble(1.2)];
    
    plotSpace.xRange = xRange;
	plotSpace.yRange = yRange;
    
    
	// this allows the plot to respond to mouse events
	[plotSpace setDelegate:self];
	[plotSpace setAllowsUserInteraction:YES];
    
    
    // Create a plot that uses the data source method
    CPTScatterPlot *dataSourceLinePlot = [[CPTScatterPlot alloc] init];
    dataSourceLinePlot.identifier = [fieldNames objectAtIndex:0];
    //    
    CPTMutableLineStyle *lineStyle = [dataSourceLinePlot.dataLineStyle mutableCopy];
    lineStyle.lineWidth				 = 1.0;
    lineStyle.lineColor				 = [colors objectAtIndex:0];
    dataSourceLinePlot.dataLineStyle = lineStyle;
    dataSourceLinePlot.dataSource =  dataView;
    
    BOOL overlayAdded = NO;
    CPTXYPlotSpace *secondPlotSpace;
    [graph addPlot:dataSourceLinePlot];
    //    
    if([fieldNames count] > 1)
    {
        for(int i =1; i < [fieldNames count]; i++){
            if([[fieldNames objectAtIndex:i] isEqualToString:@"LONG"] || [[fieldNames objectAtIndex:i] isEqualToString:@"SHORT"]){
                if(!overlayAdded)
                {
                    secondPlotSpace = [[CPTXYPlotSpace alloc] init];
                    [secondPlotSpace setIdentifier:@"SHORTLONG"];
                    [graph addPlotSpace:secondPlotSpace ];
                    overlayAdded = YES;
                }
                //                        
//                dataSourceLinePlot = [[CPTScatterPlot alloc] init];
//                dataSourceLinePlot.identifier = @"SHORT";
//                lineStyle = [dataSourceLinePlot.dataLineStyle mutableCopy];
//                lineStyle.lineWidth				 = 1.0;
//                lineStyle.lineColor				 = [CPTColor redColor] ;
//                dataSourceLinePlot.dataLineStyle = lineStyle;
//                 dataSourceLinePlot.dataSource =  dataView;
//                [graph addPlot:dataSourceLinePlot toPlotSpace:secondPlotSpace];
//                
                
                
                //            //[secondPlotSpace scaleToFitPlots:[NSArray arrayWithObjects:dataSourceLinePlot, nil]];
                //            //CPTMutablePlotRange *yRange = [secondPlotSpace.yRange mutableCopy];
                //           //[yRange expandRangeByFactor:CPTDecimalFromDouble(1.2)];
                //            
                //            secondPlotSpace.xRange = [plotSpace.xRange copy];
                //
                //            long minY = [[[dataView minYvalues] objectForKey:@"POSITION"] longValue];
                //            long maxY = [[[dataView maxYvalues] objectForKey:@"POSITION"] longValue];
                //            long span = maxY-minY;
                //            secondPlotSpace.yRange = [CPTPlotRange plotRangeWithLocation:[[NSNumber numberWithDouble:minY-10000] decimalValue] length:[[NSNumber numberWithDouble:span+(2*10000) ] decimalValue]];

                
                
                
                if([[fieldNames objectAtIndex:i] isEqualToString:@"SHORT"])
                {
                    dataSourceLinePlot = [[CPTScatterPlot alloc] init];
                    dataSourceLinePlot.identifier = @"SHORT";
                    lineStyle = [dataSourceLinePlot.dataLineStyle mutableCopy];
                    lineStyle.lineWidth				 = 1.0;
                    lineStyle.lineColor				 = [CPTColor clearColor] ;
                    
                    CPTColor *areaColor = [CPTColor colorWithComponentRed:1.0 green:0.0 blue:0.0 alpha:0.3];
                    //CPTColor *endColor		   = [CPTColor colorWithGenericGray:0.1];
                    //CPTGradient *areaGradient = [CPTGradient gradientWithBeginningColor:areaColor endingColor:areaColor];
                    
                    //areaGradient = [areaGradient addColorStop:[CPTColor colorWithComponentRed:1.0 green:0.0 blue:0.0 alpha:0.3] atPosition:0.5];
                    // areaGradient.angle = 90.0;
                    //CPTFill *areaGradientFill = 
                    dataSourceLinePlot.areaFill		 = [CPTFill fillWithColor:areaColor];
                    dataSourceLinePlot.areaBaseValue = CPTDecimalFromDouble(0.0);
                    
                    dataSourceLinePlot.dataLineStyle = lineStyle;
                    dataSourceLinePlot.dataSource =  dataView;
                    [graph addPlot:dataSourceLinePlot toPlotSpace:secondPlotSpace];
                    
                }
                if([[fieldNames objectAtIndex:i] isEqualToString:@"LONG"])
                {
                    dataSourceLinePlot = [[CPTScatterPlot alloc] init];
                    dataSourceLinePlot.identifier = @"LONG";
                    lineStyle = [dataSourceLinePlot.dataLineStyle mutableCopy];
                    lineStyle.lineWidth				 = 1.0;
                    lineStyle.lineColor				 = [CPTColor clearColor] ;
                    
                    CPTColor *areaColor		  = [CPTColor colorWithComponentRed:0.0 green:1.0 blue:0.0 alpha:0.3];
//                    CPTGradient *areaGradient = [CPTGradient gradientWithBeginningColor:areaColor endingColor:areaColor];
//                    areaGradient = [areaGradient addColorStop:[CPTColor colorWithComponentRed:0.0 green:1.0 blue:0.0 alpha:0.3] atPosition:0.5];
//                    areaGradient.angle = 90.0f;
//                    CPTFill *areaGradientFill = [CPTFill fillWithGradient:areaGradient];
                    dataSourceLinePlot.areaFill		 = [CPTFill fillWithColor:areaColor];
                    dataSourceLinePlot.areaBaseValue = CPTDecimalFromDouble(0.0);
                    dataSourceLinePlot.dataLineStyle = lineStyle;
                    dataSourceLinePlot.dataSource =  dataView;
                    [graph addPlot:dataSourceLinePlot toPlotSpace:secondPlotSpace];
                }
            }else{
                dataSourceLinePlot = [[CPTScatterPlot alloc] init];
                dataSourceLinePlot.identifier = [fieldNames objectAtIndex:i];
                lineStyle = [dataSourceLinePlot.dataLineStyle mutableCopy];
                lineStyle.lineWidth				 = 1.0;
                lineStyle.lineColor				 = [colors objectAtIndex:(i%[colors count])] ;
                dataSourceLinePlot.dataLineStyle = lineStyle;
                dataSourceLinePlot.dataSource =  dataView;
                [graph addPlot:dataSourceLinePlot];
            }
        }
    }
    if(overlayAdded){
        [secondPlotSpace scaleToFitPlots:[NSArray arrayWithObjects:dataSourceLinePlot, nil]];
        CPTMutablePlotRange *yRange = [secondPlotSpace.yRange mutableCopy];
        [yRange expandRangeByFactor:CPTDecimalFromDouble(1.2)];
        CPTMutablePlotRange *xRange =[plotSpace.xRange copy];
        secondPlotSpace.xRange = xRange;
        secondPlotSpace.yRange = yRange;
    }

	// create the zoom rectangle
	// first a bordered layer to draw the zoomrect
	CPTBorderedLayer *zoomRectangleLayer = [[CPTBorderedLayer alloc] initWithFrame:CGRectNull];
    
	lineStyle.lineColor				   = [CPTColor darkGrayColor];
	lineStyle.lineWidth				   = 1.f;
	zoomRectangleLayer.borderLineStyle = lineStyle;
    
	CPTColor *transparentFillColor = [[CPTColor blueColor] colorWithAlphaComponent:0.2];
	zoomRectangleLayer.fill = [CPTFill fillWithColor:transparentFillColor];
    
	// now create the annotation
	zoomAnnotation = [[CPTPlotSpaceAnnotation alloc] initWithPlotSpace:[graph defaultPlotSpace] anchorPlotPoint:nil];
	zoomAnnotation.contentLayer = zoomRectangleLayer;
    
	[graph.plotAreaFrame.plotArea addAnnotation:zoomAnnotation];
    
	[graph reloadData];
    
    zoomedOut = YES;
    
}

-(void)togglePositionIndicator
{
    CPTPlot * plot;
    plot = [graph plotWithIdentifier:@"SHORT"]; 
    if(plot.dataSource == nil){
        plot.dataSource = dataView;
    }else {
        plot.dataSource = nil;
    }
    [plot dataNeedsReloading];

    plot = [graph plotWithIdentifier:@"LONG"]; 
    if(plot.dataSource == nil){
        plot.dataSource = dataView;
    }else {
        plot.dataSource = nil;
    }
    [plot dataNeedsReloading];
}


-(void)fixUpAxes:(CPTXYAxisSet *) axisSet
{
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
    
    CPTXYAxis *x		  = axisSet.xAxis;
    //    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init] ;
    dateFormatter.timeZone = [NSTimeZone timeZoneWithName:@"GMT"];
    // If it more than 3 days, major tic is 1 day, otherwise a major tic is 6 hours
    
    BOOL dateIsSpecifiedInAxis = NO;
    
    minXrangeForPlot = [dataView firstX];
    maxXrangeForPlot = [dataView lastX];
    //        
    if(((float)(maxXrangeForPlot - minXrangeForPlot)/(21*60 * 60 * 24))>1){
        majorIntervalForX = 7 * 24 * 60 * 60;
        x.majorIntervalLength		  = CPTDecimalFromInt(majorIntervalForX); // 7 Day
        x.minorTicksPerInterval		  = 6;
        [dateFormatter setDateFormat:@"MM/dd"];
        dateIsSpecifiedInAxis = TRUE;
    }else{
        //If greater than 3 days
        if(((float)(maxXrangeForPlot - minXrangeForPlot)/(3*60 * 60 * 24))>1){
            majorIntervalForX = 24 * 60 * 60;
            x.majorIntervalLength		  = CPTDecimalFromInt(majorIntervalForX); // 1 Day
            x.minorTicksPerInterval		  = 5;
            [dateFormatter setDateFormat:@"MM/dd"];
            dateIsSpecifiedInAxis = TRUE;
        }else{
            //If greater than 12 hours
            if(((float)(maxXrangeForPlot - minXrangeForPlot)/(60 * 60 * 12))>1){
                majorIntervalForX = 4 * 60 * 60;
                x.majorIntervalLength		  = CPTDecimalFromInt(majorIntervalForX); // 4 hours
                x.minorTicksPerInterval		  = 3;
                dateFormatter.dateStyle = kCFDateFormatterNoStyle;
                dateFormatter.timeStyle = kCFDateFormatterShortStyle;
            }else{
                //If less than 12 hours
                if(((float)(maxXrangeForPlot - minXrangeForPlot)/(60 * 60 * 12))<=1){
                    majorIntervalForX = 60 * 60;
                    x.majorIntervalLength = CPTDecimalFromInt(majorIntervalForX); // 1 hours
                    x.minorTicksPerInterval = 5;
                    dateFormatter.dateStyle = kCFDateFormatterNoStyle;
                    dateFormatter.timeStyle = kCFDateFormatterShortStyle;
                }
            }   
        }
    }
    
    
    //        //x.minorTicksPerInterval		  = 3;
    x.majorGridLineStyle		  = majorGridLineStyle;
    x.minorGridLineStyle		  = minorGridLineStyle;
    //x.axisLineStyle = axisLineStyle;
    //   
    CPTTimeFormatter *timeFormatter = [[CPTTimeFormatter alloc] initWithDateFormatter:dateFormatter] ;
    NSDate *refDate = [NSDate dateWithTimeIntervalSince1970:0];
    timeFormatter.referenceDate = refDate;
    x.labelFormatter			= timeFormatter;
    x.labelRotation				= M_PI / 4;
    
    // From dropplot
    x.labelOffset			= 5.0;
	x.axisConstraints		= [CPTConstraints constraintWithLowerOffset:0.0];
    
    
    // Y axis stuff 
    
    CPTXYAxis *y = axisSet.yAxis;
    
    if(((maxYrangeForPlot-minYrangeForPlot)/[plotData pipSize])>10000)
    {
        // If the range of the data is not related to pipsize then forget about pipsize 
        // just go for about 10 intervals
        //This needs to be fixed
        majorIntervalForY = ((int)(maxYrangeForPlot-minYrangeForPlot))/10;  
    }else{
        majorIntervalForY = 10 * [plotData pipSize];
    }
    while(((maxYrangeForPlot-minYrangeForPlot)/majorIntervalForY)>10){
        majorIntervalForY = majorIntervalForY * 2;
    }
    
    y.labelOffset			= 5.0;
	y.axisConstraints		= [CPTConstraints constraintWithLowerOffset:0.0];
    
    
    y.majorIntervalLength		  = CPTDecimalFromDouble(majorIntervalForY);
    y.orthogonalCoordinateDecimal = CPTDecimalFromDouble((double)minXrangeForPlot);
    y.minorTicksPerInterval		  = 1;
    y.majorGridLineStyle		  = majorGridLineStyle;
    y.minorGridLineStyle		  = minorGridLineStyle;
    y.axisLineStyle               = axisLineStyle;
    //   
    NSNumberFormatter *numberFormatter = [[NSNumberFormatter alloc] init];
    [numberFormatter setNumberStyle:NSNumberFormatterDecimalStyle];
    if([plotData pipSize] <= 0.001){
        [numberFormatter setMinimumFractionDigits:3];
    }else{
        [numberFormatter setMinimumFractionDigits:1];
    }
    y.labelFormatter = numberFormatter;
    
    // X and Y axes stuff
    double xAxisYValue = majorIntervalForY*floor(minYrangeForPlot/majorIntervalForY);
    //double yAxisLength = (maxYrangeForPlot - xAxisYValue) * 1.4;
    //double yAxisMin = xAxisYValue - ((maxYrangeForPlot - xAxisYValue) * 0.2);
    
    x.orthogonalCoordinateDecimal = CPTDecimalFromDouble(xAxisYValue);

   


}

-(void) visibilityOfLineUpdated
{
    TimeSeriesLine *tsLine;
    BOOL visibleLineFound = NO;
    for(int i = 0; i < [timeSeriesLines count]; i++)
    {
        tsLine = [timeSeriesLines objectAtIndex:i]; 
        CPTScatterPlot *plot = (CPTScatterPlot *)[graph plotWithIdentifier:[tsLine name]];
        CPTMutableLineStyle *lineStyle = [plot.dataLineStyle mutableCopy];
        
        if([tsLine visible]){
            lineStyle.lineColor = [tsLine cpColour];
            if(!visibleLineFound){
                minYrangeForPlot = [[[dataView minYvalues] valueForKey:[tsLine name]] doubleValue];
                maxYrangeForPlot = [[[dataView maxYvalues] valueForKey:[tsLine name]] doubleValue];
                visibleLineFound = YES;
            }else{
                minYrangeForPlot = fmin(minYrangeForPlot,[[[dataView minYvalues] valueForKey:[tsLine name]] doubleValue]); 
                maxYrangeForPlot = fmax(maxYrangeForPlot,[[[dataView maxYvalues] valueForKey:[tsLine name]] doubleValue]);
            }
        }else{
            lineStyle.lineColor = [CPTColor clearColor];
        }
        plot.dataLineStyle = lineStyle;
    }
    //Fix the axes
    CPTXYAxisSet *axisSet = (CPTXYAxisSet *)graph.axisSet;
    [self fixUpAxes:axisSet];
    if(zoomedOut){
        //Get to the fully zoomed out position after a change in content of graph
        [self zoomOut];
    }
}




//-(void)renderPlotWithFields: (NSArray *) timeSeriesLines 
//{
//	CGRect bounds = NSRectToCGRect(hostingView.bounds);
//    
//	CPTGraph *graph = [[CPTXYGraph alloc] initWithFrame:bounds];
//
//    hostingView.hostedGraph = graph;
//    [graph applyTheme:[CPTTheme themeNamed:kCPTDarkGradientTheme]];
//    [graph setPaddingLeft:0];
//	[graph setPaddingTop:0];
//	[graph setPaddingRight:0];
//	[graph setPaddingBottom:0];
//    graph.plotAreaFrame.borderLineStyle = nil;
//    
//    graph.cornerRadius = 0.0; 
//    //graph.shadowRadius = 0.0; 
//    
//    NSMutableArray *fieldNames = [[NSMutableArray alloc] init];
//    NSMutableArray *colors = [[NSMutableArray alloc] init];
//    for(TimeSeriesLine *tsLine in timeSeriesLines)
//    {
//        if([tsLine visible]){
//            [fieldNames addObject:[tsLine name]];
//            [colors addObject:[tsLine cpColour]];
//        }
//    }
//    
//
//    if(([dataView countForPlot] < 3) || ([fieldNames count]==0) ){
//        if([dataView countForPlot] < 3)
//        {
//            graph.title = @"No Data";
//        }else{
//            graph.title = @"No Timeseries";
//        }
//        CPTMutableTextStyle *textStyle = [CPTMutableTextStyle textStyle];
//        textStyle.color				   = [CPTColor grayColor];
//        textStyle.fontName			   = @"Helvetica-Bold";
//        textStyle.fontSize			   = round(bounds.size.height / (CGFloat)12.0);
//        graph.titleTextStyle		   = textStyle;
//        graph.titleDisplacement		   = CGPointMake( 0.0f, round(bounds.size.height / (CGFloat)18.0) ); 
//        graph.titlePlotAreaFrameAnchor = CPTRectAnchorCenter;
//    }else{
//        
//        // Setup scatter plot space
//        CPTXYPlotSpace *plotSpace = (CPTXYPlotSpace *)graph.defaultPlotSpace;
//        plotSpace.allowsUserInteraction = YES;
//        plotSpace.delegate				= self;
//    
//        // Grid line styles
//        CPTMutableLineStyle *majorGridLineStyle = [CPTMutableLineStyle lineStyle];
//        majorGridLineStyle.lineWidth = 0.75;
//        majorGridLineStyle.lineColor = [[CPTColor colorWithGenericGray:0.2] colorWithAlphaComponent:0.75];
//    
//        CPTMutableLineStyle *minorGridLineStyle = [CPTMutableLineStyle lineStyle];
//        minorGridLineStyle.lineWidth = 0.25;
//        minorGridLineStyle.lineColor = [[CPTColor whiteColor] colorWithAlphaComponent:0.1];
//    
//        CPTMutableLineStyle *axisLineStyle =  [CPTMutableLineStyle lineStyle];
//        axisLineStyle.lineWidth = 0.5;
//        axisLineStyle.lineColor = [[CPTColor whiteColor] colorWithAlphaComponent:0.5];
//
//        // Axes
//        double minYdataForPlot, maxYdataForPlot;
//               minYdataForPlot = [[[dataView minYvalues] valueForKey:[fieldNames objectAtIndex:0]] doubleValue];
//        maxYdataForPlot = [[[dataView maxYvalues] valueForKey:[fieldNames objectAtIndex:0]] doubleValue]; 
//        for (NSString *fieldname in fieldNames) {
//            minYdataForPlot = fmin(minYdataForPlot,[[[dataView minYvalues] valueForKey:fieldname] doubleValue]); 
//            maxYdataForPlot = fmax(maxYdataForPlot,[[[dataView maxYvalues] valueForKey:fieldname] doubleValue]); 
//        }
//    
//        double majorIntervalY;
//        if(((maxYdataForPlot-minYdataForPlot)/[plotData pipSize])>10000)
//        {
//            // Then forget about pipsize related Y axis just go for about 10
//            //This needs to be fixed
//            majorIntervalY = ((int)(maxYdataForPlot-minYdataForPlot))/10;  
//        }else{
//            majorIntervalY = 10 * [plotData pipSize];
//        }
//        while(((maxYdataForPlot-minYdataForPlot)/majorIntervalY)>10){
//            majorIntervalY = majorIntervalY * 2;
//        }
//        
//        double xAxisYValue = majorIntervalY*floor(minYdataForPlot/majorIntervalY);
//        double yAxisLength = (maxYdataForPlot - xAxisYValue) * 1.4;
//        double yAxisMin = xAxisYValue - ((maxYdataForPlot - xAxisYValue) * 0.2);
//    
//        // Label x axis with a fixed interval policy
//        CPTXYAxisSet *axisSet = (CPTXYAxisSet *)graph.axisSet;
//        CPTXYAxis *x		  = axisSet.xAxis;
//    
//        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init] ;
//        dateFormatter.timeZone = [NSTimeZone timeZoneWithName:@"GMT"];
//        // If it more than 3 days, major tic is 1 day, otherwise a major tic is 6 hours
//        long minXdataForPlot, maxXdataForPlot;
//        BOOL dateIsSpecifiedInAxis = NO;
//        minXdataForPlot = [dataView firstX];
//        maxXdataForPlot = [dataView lastX];;
//        
//        if(((float)(maxXdataForPlot - minXdataForPlot)/(21*60 * 60 * 24))>1){
//            x.majorIntervalLength		  = CPTDecimalFromInt(7 * 24 * 60 * 60); // 7 Day
//            x.minorTicksPerInterval		  = 6;
//            //dateFormatter.dateStyle = kCFDateFormatterShortStyle;
//            [dateFormatter setDateFormat:@"MM/dd"];
//            dateIsSpecifiedInAxis = TRUE;
//        }else{
//            //If greater than 3 days
//            if(((float)(maxXdataForPlot - minXdataForPlot)/(3*60 * 60 * 24))>1){
//                x.majorIntervalLength		  = CPTDecimalFromInt(24 * 60 * 60); // 1 Day
//                x.minorTicksPerInterval		  = 5;
//                //dateFormatter.dateStyle = kCFDateFormatterShortStyle;
//                [dateFormatter setDateFormat:@"MM/dd"];
//                dateIsSpecifiedInAxis = TRUE;
//            }else{
//                //If greater than 12 hours
//                if(((float)(maxXdataForPlot - minXdataForPlot)/(60 * 60 * 12))>1){
//                    x.majorIntervalLength		  = CPTDecimalFromInt(4 * 60 * 60); // 4 hours
//                    x.minorTicksPerInterval		  = 3;
//                    dateFormatter.dateStyle = kCFDateFormatterNoStyle;
//                    dateFormatter.timeStyle = kCFDateFormatterShortStyle;
//                }else{
//                    //If less than 12 hours
//                    if(((float)(maxXdataForPlot - minXdataForPlot)/(60 * 60 * 12))<=1){
//                        x.majorIntervalLength = CPTDecimalFromInt(60 * 60); // 1 hours
//                        x.minorTicksPerInterval = 5;
//                        dateFormatter.dateStyle = kCFDateFormatterNoStyle;
//                        dateFormatter.timeStyle = kCFDateFormatterShortStyle;
//                    }
//                }   
//            }
//        }
//            // America/New_York
//            // Europe/London
//            // Europe/Paris
//            // Asia/Tokyo
//        
//        x.orthogonalCoordinateDecimal = CPTDecimalFromDouble(xAxisYValue);
//        //x.minorTicksPerInterval		  = 3;
//        x.majorGridLineStyle		  = majorGridLineStyle;
//        x.minorGridLineStyle		  = minorGridLineStyle;
//        x.axisLineStyle = axisLineStyle;
//   
//        CPTTimeFormatter *timeFormatter = [[CPTTimeFormatter alloc] initWithDateFormatter:dateFormatter] ;
//        NSDate *refDate = [NSDate dateWithTimeIntervalSince1970:0];
//        timeFormatter.referenceDate = refDate;
//        x.labelFormatter			= timeFormatter;
//        x.labelRotation				= M_PI / 4;
//            
//        CPTXYAxis *y = axisSet.yAxis;
//        y.majorIntervalLength		  = CPTDecimalFromDouble(majorIntervalY);
//        y.orthogonalCoordinateDecimal = CPTDecimalFromDouble((double)minXdataForPlot);
//        y.minorTicksPerInterval		  = 1;
//        y.majorGridLineStyle		  = majorGridLineStyle;
//        y.minorGridLineStyle		  = minorGridLineStyle;
//        y.axisLineStyle               = axisLineStyle;
//   
//        NSNumberFormatter *numberFormatter = [[NSNumberFormatter alloc] init];
//        [numberFormatter setNumberStyle:NSNumberFormatterDecimalStyle];
//        if([plotData pipSize] <= 0.001){
//            [numberFormatter setMinimumFractionDigits:3];
//        }else{
//            [numberFormatter setMinimumFractionDigits:1];
//        }
//        y.labelFormatter              = numberFormatter;
//    
//    
//        //Annotation of dates ///////////////////////////////////////////
//        if(!dateIsSpecifiedInAxis)
//        {
//            long firstMidnight = [EpochTime epochTimeAtZeroHour:minXdataForPlot];
//            long lastMidnight = [EpochTime epochTimeNextDayAtZeroHour:maxXdataForPlot];
//    
//            NSString *stringFromDate;
//            CPTMutableTextStyle *dateStringStyle;
//            NSArray *dateAnnotationPoint;
//            CPTTextLayer *textLayer;
//            CPTPlotSpaceAnnotation *dateAnnotation;
//            NSDateFormatter *labelFormatter = [[NSDateFormatter alloc] init] ;
//            [labelFormatter setDateFormat:@"MM/dd"];
//            labelFormatter.timeZone = [NSTimeZone timeZoneWithName:@"GMT"];
//            for(long labelDate = firstMidnight; labelDate <= lastMidnight; labelDate = labelDate + (60*60*24))
//            {
//                stringFromDate = [labelFormatter stringFromDate:[NSDate dateWithTimeIntervalSince1970:labelDate]];
//                dateStringStyle = [CPTMutableTextStyle textStyle];
//                dateStringStyle.color	= [CPTColor redColor];
//                dateStringStyle.fontSize = round(bounds.size.height / (CGFloat)30.0);
//                dateStringStyle.fontName = @"Courier";
//            
//                // Determine point of symbol in plot coordinates
//                dateAnnotationPoint = [NSArray arrayWithObjects:[NSDecimalNumber numberWithLong:labelDate],[NSDecimalNumber numberWithDouble:xAxisYValue], nil];
//    
//                textLayer = [[CPTTextLayer alloc] initWithText:stringFromDate style:dateStringStyle];
//                dateAnnotation = [[CPTPlotSpaceAnnotation alloc] initWithPlotSpace:graph.defaultPlotSpace anchorPlotPoint:dateAnnotationPoint];
//                dateAnnotation.contentLayer = textLayer;
//                dateAnnotation.displacement =  CGPointMake( 0.0f,(CGFloat)10.0 );     
//                [graph.plotAreaFrame.plotArea addAnnotation:dateAnnotation];
//            }
//        }
//        //////////////////////////////////////////////////////////////////////
//    
//    
//        // Set axes
//        graph.axisSet.axes = [NSArray arrayWithObjects:x, y, nil];
//    
//        // Create a plot that uses the data source method
//        CPTScatterPlot *dataSourceLinePlot = [[CPTScatterPlot alloc] init];
//        dataSourceLinePlot.identifier = [fieldNames objectAtIndex:0];
//    
//        CPTMutableLineStyle *lineStyle = [dataSourceLinePlot.dataLineStyle mutableCopy];
//        lineStyle.lineWidth				 = 1.0;
//        lineStyle.lineColor				 = [colors objectAtIndex:0];
//        dataSourceLinePlot.dataLineStyle = lineStyle;
//        dataSourceLinePlot.dataSource =  dataView;
//        [graph addPlot:dataSourceLinePlot];
//    
//        if([fieldNames count] > 1)
//        {
//            for(int i =1; i < [fieldNames count]; i++){
//                // Create a plot that uses the data source method
//                dataSourceLinePlot = [[CPTScatterPlot alloc] init];
//                dataSourceLinePlot.identifier = [fieldNames objectAtIndex:i];
//                lineStyle = [dataSourceLinePlot.dataLineStyle mutableCopy];
//                lineStyle.lineWidth				 = 1.0;
//                lineStyle.lineColor				 = [colors objectAtIndex:(i%[colors count])] ;
//                dataSourceLinePlot.dataLineStyle = lineStyle;
//                dataSourceLinePlot.dataSource =  dataView;
//                [graph addPlot:dataSourceLinePlot];
//            }
//        }
//        
//        // Extend the ranges for neatness
//        [plotSpace scaleToFitPlots:[NSArray arrayWithObjects:dataSourceLinePlot, nil]];
//        CPTMutablePlotRange *xRange = [plotSpace.xRange mutableCopy];
//        CPTMutablePlotRange *yRange = [plotSpace.yRange mutableCopy];
//        [xRange expandRangeByFactor:CPTDecimalFromDouble(1.2)];
//        [yRange expandRangeByFactor:CPTDecimalFromDouble(1.2)];
//
//        CPTPlotRange *plotRangeForY  = [CPTPlotRange plotRangeWithLocation:CPTDecimalFromDouble(yAxisMin) length:CPTDecimalFromDouble(yAxisLength)];
//       
//        plotSpace.xRange = xRange;
//        plotSpace.yRange = plotRangeForY;
//        plotSpace.globalYRange = 0;
//        
//        if([timeSeriesLines count] > 5){
//            CPTXYPlotSpace *secondPlotSpace = [[CPTXYPlotSpace alloc] init];
//            [graph addPlotSpace:secondPlotSpace];
//                        
//            dataSourceLinePlot = [[CPTScatterPlot alloc] init];
//            dataSourceLinePlot.identifier = @"POSITION";
//            lineStyle = [dataSourceLinePlot.dataLineStyle mutableCopy];
//            lineStyle.lineWidth				 = 1.0;
//            lineStyle.lineColor				 = [CPTColor redColor] ;
//            dataSourceLinePlot.dataLineStyle = lineStyle;
//            dataSourceLinePlot.dataSource =  dataView;
//            [graph addPlot:dataSourceLinePlot toPlotSpace:secondPlotSpace];
//            //[secondPlotSpace scaleToFitPlots:[NSArray arrayWithObjects:dataSourceLinePlot, nil]];
//            //CPTMutablePlotRange *yRange = [secondPlotSpace.yRange mutableCopy];
//           //[yRange expandRangeByFactor:CPTDecimalFromDouble(1.2)];
//            
//            secondPlotSpace.xRange = [plotSpace.xRange copy];
//
//            long minY = [[[dataView minYvalues] objectForKey:@"POSITION"] longValue];
//            long maxY = [[[dataView maxYvalues] objectForKey:@"POSITION"] longValue];
//            long span = maxY-minY;
//            secondPlotSpace.yRange = [CPTPlotRange plotRangeWithLocation:[[NSNumber numberWithDouble:minY-10000] decimalValue] length:[[NSNumber numberWithDouble:span+(2*10000) ] decimalValue]];
//            
//                                
//                                //            CPTPlotRange *plotRangeForY  = [CPTPlotRange plotRangeWithLocation:CPTDecimalFromDouble(yAxisMin) length:CPTDecimalFromDouble(yAxisLength)];
//        }
//    }
//}

//#pragma mark -
//#pragma mark Plot Space Delegate Methods

//-(CPTPlotRange *)plotSpace:(CPTPlotSpace *)space willChangePlotRangeTo:(CPTPlotRange *)newRange forCoordinate:(CPTCoordinate)coordinate
//{
//	// Impose a limit on how far user can scroll in x
//	if ( coordinate == CPTCoordinateX ) {
//        long minXdataForPlot, maxXdataForPlot;
//        minXdataForPlot = [dataView firstX];
//        maxXdataForPlot = [dataView lastX];
//        
//        int allowedXoffset = (int)(maxXdataForPlot - minXdataForPlot)/5;
//		CPTPlotRange *maxRange			  = [CPTPlotRange plotRangeWithLocation:CPTDecimalFromInt((int)minXdataForPlot-allowedXoffset) length:CPTDecimalFromInt((allowedXoffset * 7))];
//		CPTMutablePlotRange *changedRange = [newRange mutableCopy];
//		[changedRange shiftEndToFitInRange:maxRange];
//		[changedRange shiftLocationToFitInRange:maxRange];
//		newRange = changedRange;
//	}
//    
//    if ( coordinate == CPTCoordinateY ) {
//        double minYdataForPlot, maxYdataForPlot;
//        NSArray *fieldnames = [plotData.yData allKeys];
//        minYdataForPlot = [dataView firstX];
//        maxYdataForPlot = [dataView lastX]; 
//        for (NSString *fieldname in fieldnames) {
//            minYdataForPlot = fmin(minYdataForPlot,[[[dataView minYvalues] valueForKey:fieldname] doubleValue]); 
//            maxYdataForPlot = fmax(maxYdataForPlot,[[[dataView maxYvalues] valueForKey:fieldname] doubleValue]); 
//        }
//        
//        double allowedYoffset = (maxYdataForPlot - minYdataForPlot);
//		CPTPlotRange *maxRange = [CPTPlotRange plotRangeWithLocation:CPTDecimalFromDouble(minYdataForPlot-(allowedYoffset)) length:CPTDecimalFromDouble(allowedYoffset*3)];
//		CPTMutablePlotRange *changedRange = [newRange mutableCopy];
//		[changedRange shiftEndToFitInRange:maxRange];
//		[changedRange shiftLocationToFitInRange:maxRange];
//		newRange = changedRange;
//	}
//    
//	return newRange;
//}



//-(BOOL)plotSpace:(CPTXYPlotSpace *)space shouldHandlePointingDeviceUpEvent:(id)event atPoint:(CGPoint)point{
//    NSLog(@"point.x=%lf,point.y=%lf",point.x,point.y);
//    return YES;
//}
//
//-(BOOL)plotSpace:(CPTXYPlotSpace *)space shouldHandlePointingDeviceCancelledEvent:(id)event{
//    //NSLog(@"point.x=%lf,point.y=%lf",point.x,point.y);
//    return YES;
//}

//-(BOOL)plotSpace:(CPTXYPlotSpace *)space shouldHandlePointingDeviceDownEvent:(id)event atPoint:(CGPoint)point{
//    NSLog(@"point.x=%lf,point.y=%lf",point.x,point.y);
//    NSDecimal dataCoordinates[2];
//    
//    [space plotPoint:dataCoordinates forPlotAreaViewPoint:point];
//    
//    NSDecimalNumber *dateTimeNumber = [NSDecimalNumber decimalNumberWithDecimal:dataCoordinates[0]];
//    long dateTime = [dateTimeNumber longValue];                                     
// 
//    NSDecimalNumber *dataNumber = [NSDecimalNumber decimalNumberWithDecimal:dataCoordinates[1]];
//    double dataValue = [dataNumber doubleValue];
//
//    NSLog(@"point.x=%ld,point.y=%5.2f",dateTime,dataValue);
//    
//    
//    if([[self delegate] respondsToSelector:@selector(sendGraphClickDateTimeValue:)])
//    {
//        [[self delegate] sendGraphClickDateTimeValue:dateTime]; 
//    }else{
//        NSLog(@"Delegate not responding to \'addSimulationDataToResultsTableView\'"); 
//    }
//
//    
//    
//    return YES;
//}


//-(BOOL)plotSpace:(CPTXYPlotSpace *)space shouldHandlePointingDeviceDraggedEvent:(id)event atPoint:(CGPoint)point{
//    NSLog(@"point.x=%lf,point.y=%lf",point.x,point.y);
//    return YES;
//}

#pragma mark -
#pragma mark Plot Space Delegate Methods

-(BOOL)plotSpace:(CPTPlotSpace *)space shouldHandlePointingDeviceDraggedEvent:(id)event atPoint:(CGPoint)interactionPoint
{
//	NSDecimal startPoint[2], endPoint[2];
//        
//    [space plotPoint:startPoint forPlotAreaViewPoint:dragStart];
//    NSDecimalNumber *dateTimeStartNumber = [NSDecimalNumber decimalNumberWithDecimal:startPoint[0]];
//    double startDateTime = [dateTimeStartNumber doubleValue];                                     
//    
//    [space plotPoint:endPoint forPlotAreaViewPoint:interactionPoint];
//    
//    NSDecimalNumber *dateTimeEndNumber = [NSDecimalNumber decimalNumberWithDecimal:endPoint[0]];
//    double endDateTime = [dateTimeEndNumber doubleValue];                                     
//    
    
    TimeSeriesLine *tsLine = [timeSeriesLines objectAtIndex:0];
    CPTScatterPlot *plot = (CPTScatterPlot *)[graph plotWithIdentifier:[tsLine name]];
    
	// convert the dragStart and dragEnd values to plot coordinates
	CGPoint dragStartInPlotArea = [graph convertPoint:dragStart toLayer:plot];
	CGPoint dragEndInPlotArea	= [graph convertPoint:interactionPoint toLayer:plot];
    
	// create the dragrect from dragStart to the current location
	CGRect borderRect = CGRectMake( dragStartInPlotArea.x, dragStartInPlotArea.y,
                                   (dragEndInPlotArea.x - dragStartInPlotArea.x),
                                   (dragEndInPlotArea.y - dragStartInPlotArea.y) );
    
   
  
	// force the drawing of the zoomRect
	zoomAnnotation.contentLayer.frame = borderRect;
	[zoomAnnotation.contentLayer setNeedsDisplay];
    
	return NO;
}

-(BOOL)plotSpace:(CPTPlotSpace *)space shouldHandlePointingDeviceDownEvent:(id)event atPoint:(CGPoint)interactionPoint
{
	dragStart = interactionPoint;
    
	return NO;
}

-(BOOL)plotSpace:(CPTPlotSpace *)space shouldHandlePointingDeviceUpEvent:(id)event atPoint:(CGPoint)point
{
	dragEnd = point;
    
	// double-click to completely zoom out
	if ( [event clickCount] == 2 ) {
		[self zoomOut];
	}
	else if ( !CGPointEqualToPoint(dragStart, dragEnd) ) {
		// no accidental drag, so zoom in
		[self zoomIn];
        
		// and we're done with the drag
		zoomAnnotation.contentLayer.frame = CGRectNull;
		[zoomAnnotation.contentLayer setNeedsDisplay];
	}
    
	return NO;
}




#pragma mark -
#pragma mark Zoom Methods

-(IBAction)zoomIn
{
	CPTXYPlotSpace *plotSpace = (CPTXYPlotSpace *)graph.defaultPlotSpace;
    TimeSeriesLine *tsLine = [timeSeriesLines objectAtIndex:0];
    CPTScatterPlot *plot = (CPTScatterPlot *)[graph plotWithIdentifier:[tsLine name]];
    
    double minXzoomForPlot;
	double maxXzoomForPlot;
	double minYzoomForPlot;
	double maxYzoomForPlot;
    
	// convert the dragStart and dragEnd values to plot coordinates
	CGPoint dragStartInPlotArea = [graph convertPoint:dragStart toLayer:plot];
	CGPoint dragEndInPlotArea	= [graph convertPoint:dragEnd toLayer:plot];
    
	double start[2], end[2];
    
	// obtain the datapoints for the drag start and end
	[plotSpace doublePrecisionPlotPoint:start forPlotAreaViewPoint:dragStartInPlotArea];
	[plotSpace doublePrecisionPlotPoint:end forPlotAreaViewPoint:dragEndInPlotArea];
    
	// recalculate the min and max values
	minXzoomForPlot = MIN(start[CPTCoordinateX], end[CPTCoordinateX]);
	maxXzoomForPlot = MAX(start[CPTCoordinateX], end[CPTCoordinateX]);
	minYzoomForPlot = MIN(start[CPTCoordinateY], end[CPTCoordinateY]);
	maxYzoomForPlot = MAX(start[CPTCoordinateY], end[CPTCoordinateY]);
    
	// now adjust the plot range and axes
	plotSpace.xRange = [CPTPlotRange plotRangeWithLocation:CPTDecimalFromDouble(minXzoomForPlot)
													length:CPTDecimalFromDouble(maxXzoomForPlot - minXzoomForPlot)];
	plotSpace.yRange = [CPTPlotRange plotRangeWithLocation:CPTDecimalFromDouble(minYzoomForPlot)
													length:CPTDecimalFromDouble(maxYzoomForPlot - minYzoomForPlot)];
    
    zoomedOut = NO;
    
    CPTXYPlotSpace *secondPlotSpace = (CPTXYPlotSpace *)[graph plotSpaceWithIdentifier:@"SHORTLONG"];
    secondPlotSpace.xRange = [plotSpace.xRange copy];
    
    
	//CPTXYAxisSet *axisSet = (CPTXYAxisSet *)graph.axisSet;
    //[self fixUpAxes:axisSet];
	//axisSet.xAxis.labelingPolicy = CPTAxisLabelingPolicyAutomatic;
	//axisSet.yAxis.labelingPolicy = CPTAxisLabelingPolicyAutomatic;
}

-(IBAction)zoomOut
{
   

    
	// now adjust the plot range
	CPTXYPlotSpace *plotSpace = (CPTXYPlotSpace *)graph.defaultPlotSpace;
    
    CPTMutablePlotRange *xRange = [CPTMutablePlotRange plotRangeWithLocation:CPTDecimalFromDouble(minXrangeForPlot)
                                                                      length:CPTDecimalFromDouble(ceil( (maxXrangeForPlot - minXrangeForPlot) / majorIntervalForX ) * majorIntervalForX)];
    CPTMutablePlotRange *yRange = [CPTMutablePlotRange plotRangeWithLocation:CPTDecimalFromDouble(minYrangeForPlot)
                                                                      length:CPTDecimalFromDouble(ceil( (maxYrangeForPlot - minYrangeForPlot) / majorIntervalForY ) * majorIntervalForY)];
    
    
    
    [xRange expandRangeByFactor:CPTDecimalFromDouble(1.1)];
    [yRange expandRangeByFactor:CPTDecimalFromDouble(1.2)];
    
    plotSpace.xRange = xRange;
	plotSpace.yRange = yRange;

    CPTXYPlotSpace *secondPlotSpace = (CPTXYPlotSpace *)[graph plotSpaceWithIdentifier:@"SHORTLONG"];
    secondPlotSpace.xRange = [xRange copy];

        
    zoomedOut = YES;
//	plotSpace.xRange = [CPTPlotRange plotRangeWithLocation:CPTDecimalFromDouble(minXrangeForPlot)
//													length:CPTDecimalFromDouble(ceil( (maxXrangeForPlot - minXrangeForPlot) / majorIntervalForX ) * majorIntervalForX)];
//	plotSpace.yRange = [CPTPlotRange plotRangeWithLocation:CPTDecimalFromDouble(minYrangeForPlot)
//													length:CPTDecimalFromDouble(ceil( (maxYrangeForPlot - minYrangeForPlot) / majorIntervalForY ) * majorIntervalForY)];
    //CPTXYAxisSet *axisSet = (CPTXYAxisSet *)graph.axisSet;
    //[self fixUpAxes:axisSet];
}


@end
