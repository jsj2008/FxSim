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


-(void)showSeries:(NSString *)seriesName;
{
    if([seriesName isEqual:[NSString stringWithString:@"ALL"]])
    {
        for(CPTGraph *graph in graphs) {
            for(CPTPlot *plot in [graph allPlots]){
                plot.hidden = NO;
            }
        }
    }else{
        for(CPTGraph *graph in graphs) {
            for(CPTPlot *plot in [graph allPlots]){
                if([[plot identifier] isEqual:seriesName]){
                    plot.hidden = NO;
                }else{
                    plot.hidden = YES;
                }
            }
        }
    }
}





-(void)renderInLayer:(CPTGraphHostingView *)layerHostingView withTheme:(CPTTheme *)theme
{
	CGRect bounds = NSRectToCGRect(layerHostingView.bounds);
    
	CPTGraph *graph = [[CPTXYGraph alloc] initWithFrame:bounds];
	[self addGraph:graph toHostingView:layerHostingView];
	[self applyTheme:theme toGraph:graph withDefault:[CPTTheme themeNamed:kCPTDarkGradientTheme]];
    
	[self setTitleDefaultsForGraph:graph withBounds:bounds];
    
    [graph setPaddingLeft:0];
	[graph setPaddingTop:0];
	[graph setPaddingRight:0];
	[graph setPaddingBottom:0];
    
    
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
   
    //[graph setTitle:[plotData name]];

	// Axes
    double minYdataForPlot, maxYdataForPlot;
    NSArray *fieldnames = [plotData.yData allKeys];
    minYdataForPlot = [[plotData.minYdataForPlot valueForKey:[fieldnames objectAtIndex:0]] doubleValue];
    maxYdataForPlot = [[plotData.maxYdataForPlot valueForKey:[fieldnames objectAtIndex:0]] doubleValue]; 
    for (NSString *fieldname in fieldnames) {
        minYdataForPlot = fmin(minYdataForPlot,[[plotData.minYdataForPlot valueForKey:fieldname] doubleValue]); 
        maxYdataForPlot = fmax(maxYdataForPlot,[[plotData.maxYdataForPlot valueForKey:fieldname] doubleValue]); 
    }
        
    
    double majorIntervalY = 10 * [plotData pipSize];
    while(((maxYdataForPlot-minYdataForPlot)/majorIntervalY)>10){
        majorIntervalY = majorIntervalY * 2;
    }
    
        
        
    double xAxisYValue = majorIntervalY*floor(minYdataForPlot/majorIntervalY);
    double yAxisLength = (maxYdataForPlot - xAxisYValue) * 1.4;
    double yAxisMin = xAxisYValue - ((maxYdataForPlot - xAxisYValue) * 0.2);
    
	// Label x axis with a fixed interval policy
	CPTXYAxisSet *axisSet = (CPTXYAxisSet *)graph.axisSet;
	CPTXYAxis *x		  = axisSet.xAxis;
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init] ;
    // If it more than 3 days, major tic is 1 day, otherwise a major tic is 6 hours
    long minXdataForPlot, maxXdataForPlot;
    minXdataForPlot = [[[plotData xData] sampleValue:[plotData startIndexForPlot]] longValue];
    maxXdataForPlot = [[[plotData xData] sampleValue:([plotData startIndexForPlot] + [plotData countForPlot]-1) ] longValue];
    
    if(((maxXdataForPlot - minXdataForPlot)/(3*60 * 60 * 24))>1){
        x.majorIntervalLength		  = CPTDecimalFromInt(24 * 60 * 60);
        //dateFormatter.dateStyle = kCFDateFormatterShortStyle;
        [dateFormatter setDateFormat:@"MM/dd"];
    }else{
        x.majorIntervalLength		  = CPTDecimalFromInt(4 * 60 * 60); // 4 hours
        
        dateFormatter.dateStyle = kCFDateFormatterNoStyle;
        dateFormatter.timeStyle = kCFDateFormatterShortStyle;
        dateFormatter.timeZone = [NSTimeZone timeZoneWithName:@"GMT"];
        
        // America/New_York
        // Europe/London
        // Europe/Paris
        // Asia/Tokyo
    }
    x.orthogonalCoordinateDecimal = CPTDecimalFromDouble(xAxisYValue);
	x.minorTicksPerInterval		  = 3;
	x.majorGridLineStyle		  = majorGridLineStyle;
	x.minorGridLineStyle		  = minorGridLineStyle;
    x.axisLineStyle = axisLineStyle;
   
    CPTTimeFormatter *timeFormatter = [[CPTTimeFormatter alloc] initWithDateFormatter:dateFormatter] ;
    NSDate *refDate = [NSDate dateWithTimeIntervalSince1970:0];
    timeFormatter.referenceDate = refDate;
 	x.labelFormatter			= timeFormatter;
	x.labelRotation				= M_PI / 4;
    
    
            
    CPTXYAxis *y = axisSet.yAxis;
    y.majorIntervalLength		  = CPTDecimalFromDouble(majorIntervalY);
    y.orthogonalCoordinateDecimal = CPTDecimalFromDouble((double)minXdataForPlot);
    y.minorTicksPerInterval		  = 1;
    y.majorGridLineStyle		  = majorGridLineStyle;
    y.minorGridLineStyle		  = minorGridLineStyle;
    y.axisLineStyle               = axisLineStyle;
   
	NSNumberFormatter *numberFormatter = [[NSNumberFormatter alloc] init];
    [numberFormatter setNumberStyle:NSNumberFormatterDecimalStyle];
    if([plotData pipSize] <= 0.001){
        [numberFormatter setMinimumFractionDigits:3];
    }else{
        [numberFormatter setMinimumFractionDigits:1];
    }
    y.labelFormatter              = numberFormatter;
    
    // Set axes
	graph.axisSet.axes = [NSArray arrayWithObjects:x, y, nil];
    
    
	// Create a plot that uses the data source method
	CPTScatterPlot *dataSourceLinePlot = [[CPTScatterPlot alloc] init];
	dataSourceLinePlot.identifier = @"ASK";
    
	CPTMutableLineStyle *lineStyle = [dataSourceLinePlot.dataLineStyle mutableCopy];
	lineStyle.lineWidth				 = 1.0;
	lineStyle.lineColor				 = [CPTColor greenColor];
	dataSourceLinePlot.dataLineStyle = lineStyle;
    
    if([plotData countForPlot] > 1){
    
        dataSourceLinePlot.dataSource =  plotData;
        [graph addPlot:dataSourceLinePlot];
    
        // Create a plot that uses the data source method
        CPTScatterPlot *dataSourceLinePlot2 = [[CPTScatterPlot alloc] init];
        dataSourceLinePlot2.identifier = @"BID";
    
        lineStyle = [dataSourceLinePlot.dataLineStyle mutableCopy];
        lineStyle.lineWidth				 = 1.0;
        lineStyle.lineColor				 = [CPTColor redColor];
        dataSourceLinePlot2.dataLineStyle = lineStyle;
    
        dataSourceLinePlot2.dataSource =  plotData;
        [graph addPlot:dataSourceLinePlot2];

        
        // Create a plot that uses the data source method
        CPTScatterPlot *dataSourceLinePlot3 = [[CPTScatterPlot alloc] init];
        dataSourceLinePlot3.identifier = @"EWMA";
        
        lineStyle = [dataSourceLinePlot.dataLineStyle mutableCopy];
        lineStyle.lineWidth				 = 1.0;
        lineStyle.lineColor				 = [CPTColor yellowColor];
        dataSourceLinePlot3.dataLineStyle = lineStyle;
        
        dataSourceLinePlot3.dataSource =  plotData;
        [graph addPlot:dataSourceLinePlot3];
         
        
        // Auto scale the plot space to fit the plot data
        // Extend the ranges for neatness
        [plotSpace scaleToFitPlots:[NSArray arrayWithObjects:dataSourceLinePlot, nil]];
        CPTMutablePlotRange *xRange = [plotSpace.xRange mutableCopy];
        CPTMutablePlotRange *yRange = [plotSpace.yRange mutableCopy];
        [xRange expandRangeByFactor:CPTDecimalFromDouble(1.2)];
        [yRange expandRangeByFactor:CPTDecimalFromDouble(1.2)];

        CPTPlotRange *plotRangeForY  = [CPTPlotRange plotRangeWithLocation:CPTDecimalFromDouble(yAxisMin) length:CPTDecimalFromDouble(yAxisLength)];
       
        plotSpace.xRange = xRange;
        plotSpace.yRange = plotRangeForY;
    
        // Restrict y range to a global range
        //CPTPlotRange *globalYRange = [CPTPlotRange plotRangeWithLocation:CPTDecimalFromDouble([plotData minYdata]-(1.2*majorIntervalY))
        //														  length:CPTDecimalFromDouble(([plotData maxYdata]-[plotData minYdata])+(2*majorIntervalY))];
        //plotSpace.globalYRange = globalYRange;
        plotSpace.globalYRange = 0;
    }else{
        if([[plotData name] isEqualToString:@"OCR"])
        {
            graph.title = @"OCR";
            
            
            
            CPTMutableTextStyle *textStyle = [CPTMutableTextStyle textStyle];
            textStyle.color				   = [CPTColor grayColor];
            textStyle.fontName			   = @"Courier";
            textStyle.fontSize			   = round(bounds.size.height / (CGFloat)4.0);
            graph.titleTextStyle		   = textStyle;
            graph.titleDisplacement		   = CGPointMake( 0.0f, round(bounds.size.height / (CGFloat)8.0) ); 
            
            CPTMutableTextStyle *subStringStyle = [CPTMutableTextStyle textStyle];
            subStringStyle.color	= [CPTColor grayColor];
            subStringStyle.fontSize = 12.0f;
            subStringStyle.fontName = @"Courier";
            
            // Determine point of symbol in plot coordinates
            NSArray *anchorPoint = [NSArray arrayWithObjects:[NSDecimalNumber numberWithFloat:0.5],[NSDecimalNumber numberWithFloat:0.4], nil];
            
            // Add annotation
            NSString *subString = [NSString stringWithString:@"2012, O'Connor Research"];
            
            // Now add the annotation to the plot area
            CPTTextLayer *textLayer = [[CPTTextLayer alloc] initWithText:subString style:subStringStyle];
            CPTPlotSpaceAnnotation *subTitleAnnotation = [[CPTPlotSpaceAnnotation alloc] initWithPlotSpace:graph.defaultPlotSpace anchorPlotPoint:anchorPoint];
            subTitleAnnotation.contentLayer = textLayer;
            //subTitleAnnotation.displacement = graph.titleDisplacement; //CGPointMake(0.0f, 20.0f);
            [graph.plotAreaFrame.plotArea addAnnotation:subTitleAnnotation];
        }else{
            graph.title = @"No Data";
            CPTMutableTextStyle *textStyle = [CPTMutableTextStyle textStyle];
            textStyle.color				   = [CPTColor grayColor];
            textStyle.fontName			   = @"Helvetica-Bold";
            textStyle.fontSize			   = round(bounds.size.height / (CGFloat)12.0);
            graph.titleTextStyle		   = textStyle;
            graph.titleDisplacement		   = CGPointMake( 0.0f, round(bounds.size.height / (CGFloat)18.0) ); 
            // Ensure that title displacement falls on an integral pixel
            
        }
        
       graph.titlePlotAreaFrameAnchor = CPTRectAnchorCenter;
        
    }
    
}

#pragma mark -
#pragma mark Plot Space Delegate Methods

-(CPTPlotRange *)plotSpace:(CPTPlotSpace *)space willChangePlotRangeTo:(CPTPlotRange *)newRange forCoordinate:(CPTCoordinate)coordinate
{
	// Impose a limit on how far user can scroll in x
	if ( coordinate == CPTCoordinateX ) {
        long minXdataForPlot, maxXdataForPlot;
        minXdataForPlot = [[[plotData xData] sampleValue:[plotData startIndexForPlot]] longValue];
        maxXdataForPlot = [[[plotData xData] sampleValue:([plotData startIndexForPlot] + [plotData countForPlot]-1) ] longValue];
        
        int allowedXoffset = (int)(maxXdataForPlot - minXdataForPlot)/5;
		CPTPlotRange *maxRange			  = [CPTPlotRange plotRangeWithLocation:CPTDecimalFromInt((int)minXdataForPlot-allowedXoffset) length:CPTDecimalFromInt((allowedXoffset * 7))];
		CPTMutablePlotRange *changedRange = [newRange mutableCopy];
		[changedRange shiftEndToFitInRange:maxRange];
		[changedRange shiftLocationToFitInRange:maxRange];
		newRange = changedRange;
	}
    
    if ( coordinate == CPTCoordinateY ) {
        double minYdataForPlot, maxYdataForPlot;
        NSArray *fieldnames = [plotData.yData allKeys];
        minYdataForPlot = [[plotData.minYdataForPlot valueForKey:[fieldnames objectAtIndex:0]] doubleValue];
        maxYdataForPlot = [[plotData.maxYdataForPlot valueForKey:[fieldnames objectAtIndex:0]] doubleValue]; 
        for (NSString *fieldname in fieldnames) {
            minYdataForPlot = fmin(minYdataForPlot,[[plotData.minYdataForPlot valueForKey:fieldname] doubleValue]); 
            maxYdataForPlot = fmax(maxYdataForPlot,[[plotData.maxYdataForPlot valueForKey:fieldname] doubleValue]); 
        }
        
        double allowedYoffset = (maxYdataForPlot - minYdataForPlot);
		CPTPlotRange *maxRange = [CPTPlotRange plotRangeWithLocation:CPTDecimalFromDouble(minYdataForPlot-(allowedYoffset)) length:CPTDecimalFromDouble(allowedYoffset*3)];
		CPTMutablePlotRange *changedRange = [newRange mutableCopy];
		[changedRange shiftEndToFitInRange:maxRange];
		[changedRange shiftLocationToFitInRange:maxRange];
		newRange = changedRange;
	}
    
	return newRange;
}

@end
