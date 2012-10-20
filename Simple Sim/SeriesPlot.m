//
//  SimpleScatterPlot.m
//  CorePlotGallery
//

#import "SeriesPlot.h"
#import "DataSeries.h"
#import "DataView.h"
#import "EpochTime.h"
#import "TimeSeriesLine.h"

@interface SeriesPlot() 
- (BOOL) fixUpXAxisLabelsForLayerIndex: (int) layerIndex
                           AndDataView: (DataView *) currentDataView;
- (void) fixUpYAxisForLayerIndex: (int) layerIndex;
- (void) zoomInAndFitYAxis:(BOOL) fitYAxis;
- (void) zoomOut;
- (void) addHorizontalLineAt:(double) yValue 
                ForPlotspace:(CPTXYPlotSpace *) plotSpace;
- (double) niceNumber: (double) x withRounding:(BOOL) doRounding;
@end

@implementation SeriesPlot

-(id)init
{
    return [self initWithIdentifier:@"No identifier"];
}

-(id)initWithIdentifier:(NSString*) identifierString
{
	if ( (self = [super init]) ) {
		identifier = identifierString;
        dateAnnotationArray = [[NSMutableArray alloc] init];
        lineAnnotationArray = [[NSMutableArray alloc] init];
        lineAnnotationLevelArray = [[NSMutableArray alloc] init];
	}
 	return self;
}

-(void)setData:(DataSeries  *) newData WithViewName: (NSString *) viewName;
{
    plotData = newData ; 
    dataView = [[newData dataViews] objectForKey:viewName];
}

-(void)initialGraphAndAddAnnotation: (BOOL) doAnnotation
{
   	CGRect bounds = NSRectToCGRect(hostingView.bounds);
    graph = [[CPTXYGraph alloc] initWithFrame:bounds];
	hostingView.hostedGraph = graph;
    
    [graph applyTheme:[CPTTheme themeNamed:kCPTDarkGradientTheme]];
   
    graph.paddingLeft	= 0.0;
	graph.paddingTop	= 0.0;
	graph.paddingRight	= 0.0;
    graph.paddingBottom = 0.0;
    
	graph.plotAreaFrame.plotArea.fill = graph.plotAreaFrame.fill;
	graph.plotAreaFrame.fill		  = nil;
    
	graph.plotAreaFrame.borderLineStyle = nil;
	graph.plotAreaFrame.cornerRadius	= 0.0;
    
    CPTMutableLineStyle *majorGridLineStyle = [CPTMutableLineStyle lineStyle];
    majorGridLineStyle.lineWidth = 0.75;
    majorGridLineStyle.lineColor = [[CPTColor colorWithGenericGray:0.2] colorWithAlphaComponent:0.75];
    
    CPTMutableLineStyle *minorGridLineStyle = [CPTMutableLineStyle lineStyle];
    minorGridLineStyle.lineWidth = 0.25;
    minorGridLineStyle.lineColor = [[CPTColor whiteColor] colorWithAlphaComponent:0.1];

    CPTXYAxisSet *axisSet = (CPTXYAxisSet *)graph.axisSet;
    axisSet.xAxis.hidden = YES; 
    axisSet.yAxis.hidden = YES; 
    
    if(doAnnotation){
        // Determine point of symbol in plot coordinates
        NSArray *anchorPoint = [NSArray arrayWithObjects:[NSDecimalNumber numberWithFloat:0.5],[NSDecimalNumber numberWithFloat:0.45], nil];
    
        // Add annotation
        NSString *mainString = @"OCR";
        CPTMutableTextStyle *mainStringStyle = [CPTMutableTextStyle textStyle];
        mainStringStyle.color	= [CPTColor grayColor];
        mainStringStyle.fontSize = round(bounds.size.height / (CGFloat)5.0);
        mainStringStyle.fontName = @"Courier";
    
        CPTTextLayer *textLayer = [[CPTTextLayer alloc] initWithText:mainString style:mainStringStyle];
        CPTPlotSpaceAnnotation *mainTitleAnnotation = [[CPTPlotSpaceAnnotation alloc] initWithPlotSpace:graph.defaultPlotSpace anchorPlotPoint:anchorPoint];
        mainTitleAnnotation.contentLayer = textLayer;
        mainTitleAnnotation.displacement =  CGPointMake( 0.0f, round(bounds.size.height / (CGFloat)8.0) ); //CGPointMake(0.0f, 20.0f);
        [graph.plotAreaFrame.plotArea addAnnotation:mainTitleAnnotation];
    
    
        NSString *subString = @"2012, O'Connor Research";
        CPTMutableTextStyle *subStringStyle = [CPTMutableTextStyle textStyle];
        subStringStyle.color	= [CPTColor grayColor];
        subStringStyle.fontSize = 12.0f;
        subStringStyle.fontName = @"Courier";
    
        textLayer = [[CPTTextLayer alloc] initWithText:subString style:subStringStyle];
        CPTPlotSpaceAnnotation *subTitleAnnotation = [[CPTPlotSpaceAnnotation alloc] initWithPlotSpace:graph.defaultPlotSpace anchorPlotPoint:anchorPoint];
        subTitleAnnotation.contentLayer = textLayer;
        [graph.plotAreaFrame.plotArea addAnnotation:subTitleAnnotation];
    }else{
        axisSet.xAxis.majorGridLineStyle = majorGridLineStyle;
        axisSet.yAxis.majorGridLineStyle = majorGridLineStyle;
        axisSet.xAxis.minorGridLineStyle = minorGridLineStyle;
        axisSet.yAxis.minorGridLineStyle = minorGridLineStyle;
    }
}

-(void)leftSideExpand
{
    graph.plotAreaFrame.paddingLeft = graph.plotAreaFrame.paddingLeft + 5;

}

-(void)leftSideContract
{
    graph.plotAreaFrame.paddingLeft = graph.plotAreaFrame.paddingLeft - 5;
    
}

-(void)bottomExpand
{
    graph.plotAreaFrame.paddingBottom = graph.plotAreaFrame.paddingBottom + 5;
}

-(void)bottomContract
{
    graph.plotAreaFrame.paddingBottom = graph.plotAreaFrame.paddingBottom - 5;
}


-(void)rightSideExpand
{
    graph.plotAreaFrame.paddingRight = graph.plotAreaFrame.paddingRight + 5;
    
}

-(void)rightSideContract
{
    graph.plotAreaFrame.paddingRight = graph.plotAreaFrame.paddingRight - 5;
    
}

-(void)topExpand
{
    graph.plotAreaFrame.paddingTop = graph.plotAreaFrame.paddingTop + 5;
}

-(void)topContract
{
    graph.plotAreaFrame.paddingTop = graph.plotAreaFrame.paddingTop - 5;
}


-(void)renderPlotWithFields: (NSArray *) linesToPlot 
{
    // Make sure there 
    clickDateAnnotation = nil;
    dragDateAnnotation = nil;
    zoomAnnotation = nil;
    [dateAnnotationArray removeAllObjects];
    [lineAnnotationArray removeAllObjects];
    [lineAnnotationLevelArray removeAllObjects];
    
    BOOL dateAnnotateRequired;
    timeSeriesLines = linesToPlot; 
    CGRect bounds = NSRectToCGRect(hostingView.bounds);
    graph = [[CPTXYGraph alloc] initWithFrame:bounds];
    
	CPTTheme *theme = [CPTTheme themeNamed:kCPTDarkGradientTheme];
	[graph applyTheme:theme];
	hostingView.hostedGraph = graph;
    
	graph.paddingLeft	= 0.0;
	graph.paddingTop	= 0.0;
	graph.paddingRight	= 0.0;
    graph.paddingBottom = 0.0;
    
	graph.plotAreaFrame.paddingLeft	  = 60.0;
	graph.plotAreaFrame.paddingTop	  = 30.0;
	graph.plotAreaFrame.paddingRight  = 30.0;
	graph.plotAreaFrame.paddingBottom = 60.0;
    
	graph.plotAreaFrame.plotArea.fill = graph.plotAreaFrame.fill;
	graph.plotAreaFrame.fill		  = nil;
    
	graph.plotAreaFrame.borderLineStyle = nil;
	graph.plotAreaFrame.cornerRadius	= 0.0;

    BOOL plot0LineFound = NO; 
    BOOL plot1LineFound = NO;
    BOOL plot2LineFound = NO;
    
    NSMutableArray *fieldNames = [[NSMutableArray alloc] init];
    NSMutableArray *colors = [[NSMutableArray alloc] init];
    NSMutableArray *layerIndexes = [[NSMutableArray alloc] init];
    minYrangeForPlot0 = 0.0;
    maxYrangeForPlot0 = 1.0;
    minYrangeForPlot1 = 0.0;
    maxYrangeForPlot1 = 1.0;
    minYrangeForPlot2 = 0.0;
    maxYrangeForPlot2 = 1.0;
    
    for(TimeSeriesLine *tsLine in timeSeriesLines)
    {
        switch ([tsLine layerIndex])
        {
                
            case 0:
                [fieldNames addObject:[tsLine name]];
                [colors addObject:[tsLine cpColour]];
                [layerIndexes addObject:[NSNumber numberWithInt:[tsLine layerIndex]]];
                if(plot0LineFound){
                    minYrangeForPlot0 = fmin(minYrangeForPlot0,[[[dataView minYvalues] valueForKey:[tsLine name]] doubleValue]); 
                    maxYrangeForPlot0 = fmax(maxYrangeForPlot0,[[[dataView maxYvalues] valueForKey:[tsLine name]] doubleValue]);
                }else{
                    minYrangeForPlot0 = [[[dataView minYvalues] valueForKey:[tsLine name]] doubleValue]; 
                    maxYrangeForPlot0 = [[[dataView maxYvalues] valueForKey:[tsLine name]] doubleValue];
                    plot0LineFound =YES;
                }
                if(maxYrangeForPlot0 < minYrangeForPlot0){
                    [NSException raise:@"Problem with Plot Range" format:@"min = %f, max = %f", minYrangeForPlot0, maxYrangeForPlot0];
                }
                break;
            case 1:
                [fieldNames addObject:[tsLine name]];
                [colors addObject:[tsLine cpColour]];
                [layerIndexes addObject:[NSNumber numberWithInt:[tsLine layerIndex]]];
                if(plot1LineFound == NO){
                    minYrangeForPlot1 = [[[dataView minYvalues] valueForKey:[tsLine name]] doubleValue]; 
                    maxYrangeForPlot1 = [[[dataView maxYvalues] valueForKey:[tsLine name]] doubleValue];
                }else{
                    minYrangeForPlot1 = fmin(minYrangeForPlot1,[[[dataView minYvalues] valueForKey:[tsLine name]] doubleValue]); 
                    maxYrangeForPlot1 = fmax(maxYrangeForPlot1,[[[dataView maxYvalues] valueForKey:[tsLine name]] doubleValue]);
                    
                }
                plot1LineFound = YES;
                if(maxYrangeForPlot1 < minYrangeForPlot1){
                    [NSException raise:@"Problem with Plot Range" format:@"min = %f, max = %f", minYrangeForPlot1, maxYrangeForPlot1];
                }
                
                break;
            case 2:
                [fieldNames addObject:[tsLine name]];
                [colors addObject:[tsLine cpColour]];
                [layerIndexes addObject:[NSNumber numberWithInt:[tsLine layerIndex]]];
                if(plot2LineFound == NO){
                    minYrangeForPlot2 = [[[dataView minYvalues] valueForKey:[tsLine name]] doubleValue]; 
                    maxYrangeForPlot2 = [[[dataView maxYvalues] valueForKey:[tsLine name]] doubleValue];
                }else{
                    minYrangeForPlot2 = fmin(minYrangeForPlot2,[[[dataView minYvalues] valueForKey:[tsLine name]] doubleValue]); 
                    maxYrangeForPlot2 = fmax(maxYrangeForPlot2,[[[dataView maxYvalues] valueForKey:[tsLine name]] doubleValue]);
                    
                }
                plot2LineFound = YES;
                if(maxYrangeForPlot2 < minYrangeForPlot2){
                    [NSException raise:@"Problem with Plot Range" format:@"min = %f, max = %f", minYrangeForPlot2, maxYrangeForPlot2];
                }
                break;
            default:
                [fieldNames addObject:[tsLine name]];
                [colors addObject:[CPTColor clearColor]];
                [layerIndexes addObject:[NSNumber numberWithInt:[tsLine layerIndex]]];
                break;
        }
    }
   
    CPTXYAxisSet *axisSet = (CPTXYAxisSet *)graph.axisSet;
    xAxis0 = [axisSet xAxis];
    yAxis0 = [axisSet yAxis];
    plotSpace0 = (CPTXYPlotSpace *)graph.defaultPlotSpace;
    dateAnnotateRequired = [self fixUpXAxisLabelsForLayerIndex:0 
                                      AndDataView:dataView];
       
    [self fixUpYAxisForLayerIndex:0];
    
    plot1AxisVisible = NO;
    plotSpace1 = [[CPTXYPlotSpace alloc] init];
    yAxis1 = [[CPTXYAxis alloc] init];
    [yAxis1 setCoordinate:CPTCoordinateY];
    [yAxis1 setPlotSpace:plotSpace1];
    [yAxis1 setMinorTickLineStyle:nil];
    NSNumberFormatter *axisFormatter = [[NSNumberFormatter alloc] init];
    [axisFormatter setMaximumFractionDigits:2];                                    
    CPTMutableTextStyle *yAxisTextStyle = [[CPTMutableTextStyle alloc] init];
    [yAxisTextStyle setColor:[CPTColor whiteColor]];
    [yAxis1 setLabelTextStyle:yAxisTextStyle];
    [yAxis1 setLabelFormatter:axisFormatter];
    [graph addPlotSpace:plotSpace1];
    if(plot1LineFound){
        [self fixUpYAxisForLayerIndex:1];
        plot1AxisVisible = YES;
    }else{
        [plotSpace1 setYRange:[[plotSpace0 yRange] copy]];
        yRange1ZoomOut = [[plotSpace0 yRange] copy];
        plot1AxisVisible = NO;
    }
    
    plot2AxisVisible = NO;
    plotSpace2 = [[CPTXYPlotSpace alloc] init];
    yAxis2 = [[CPTXYAxis alloc] init];
    [yAxis2 setCoordinate:CPTCoordinateY];
    [yAxis2 setPlotSpace:plotSpace2];
    [yAxis2 setMinorTickLineStyle:nil];
    axisFormatter = [[NSNumberFormatter alloc] init];
    [axisFormatter setMaximumFractionDigits:2];   
    yAxisTextStyle = [[CPTMutableTextStyle alloc] init];
    [yAxisTextStyle setColor:[CPTColor whiteColor]];
    [yAxis2 setLabelTextStyle:yAxisTextStyle];
    [yAxis2 setLabelFormatter:axisFormatter];
    [graph addPlotSpace:plotSpace2];
    if(plot2LineFound){
        [self fixUpYAxisForLayerIndex:2];
        plot2AxisVisible = YES;
    }else{
        [plotSpace2 setYRange:[[plotSpace0 yRange] copy]];
        yRange2ZoomOut = [[plotSpace0 yRange] copy];
        plot2AxisVisible = NO;
    }
     
    double niceXrange = (ceil( (double)(maxXrangeForPlot - minXrangeForPlot) / majorIntervalForX ) * majorIntervalForX);
    CPTMutablePlotRange *xRange;
    if((niceXrange/(maxXrangeForPlot - minXrangeForPlot))>1.1){
        xRange = [CPTMutablePlotRange plotRangeWithLocation:CPTDecimalFromDouble(minXrangeForPlot)
                                                     length:CPTDecimalFromDouble(maxXrangeForPlot - minXrangeForPlot)];
    }else{
        xRange = [CPTMutablePlotRange plotRangeWithLocation:CPTDecimalFromDouble(minXrangeForPlot)
                                                     length:CPTDecimalFromDouble(niceXrange)];
        
    }
    
    [xRange expandRangeByFactor:CPTDecimalFromDouble(1.1)];
    [plotSpace0 setXRange:xRange];
    [plotSpace1 setXRange:[[plotSpace0 xRange] copy]];
    [plotSpace2 setXRange:[[plotSpace0 xRange] copy]];
    
    xRangeZoomOut = xRange;
    
    if(dateAnnotateRequired){
        long firstMidnight = [EpochTime epochTimeAtZeroHour:minXrangeForPlot];
        long lastMidnight = [EpochTime epochTimeNextDayAtZeroHour:maxXrangeForPlot];
        
        CPTPlotRange *xRange  = plotSpace0.xRange;
        CPTPlotRange *yRange = plotSpace0.yRange;
        double minXrange = [[NSDecimalNumber decimalNumberWithDecimal:xRange.location] doubleValue];
        double maxXrange = [[NSDecimalNumber decimalNumberWithDecimal:xRange.location] doubleValue] + [[NSDecimalNumber decimalNumberWithDecimal:xRange.length] doubleValue];
        
        CGRect bounds = NSRectToCGRect(hostingView.bounds);
        
        NSString *stringFromDate;
        CPTMutableTextStyle *dateStringStyle;
        NSArray *dateAnnotationPoint;
        CPTTextLayer *textLayer;
        NSDateFormatter *labelFormatter = [[NSDateFormatter alloc] init] ;
        [labelFormatter setDateFormat:@"MM/dd"];
        labelFormatter.timeZone = [NSTimeZone timeZoneWithName:@"GMT"];
        CPTPlotSpaceAnnotation *dateAnnotation;
        for(long labelDate = firstMidnight; labelDate <= lastMidnight; labelDate = labelDate + (60*60*24))
        {
            if((double)labelDate >= minXrange && labelDate <= (double)(maxXrange)){
                stringFromDate = [labelFormatter stringFromDate:[NSDate dateWithTimeIntervalSince1970:labelDate]];
                dateStringStyle = [CPTMutableTextStyle textStyle];
                dateStringStyle.color	= [CPTColor redColor];
                dateStringStyle.fontSize = round(bounds.size.height / (CGFloat)30.0);
                dateStringStyle.fontName = @"Courier";
                
                // Determine point of symbol in plot coordinates
                dateAnnotationPoint = [NSArray arrayWithObjects:[NSDecimalNumber numberWithLong:labelDate],[NSDecimalNumber decimalNumberWithDecimal: yRange.location], nil];
                
                textLayer = [[CPTTextLayer alloc] initWithText:stringFromDate style:dateStringStyle];
                dateAnnotation = [[CPTPlotSpaceAnnotation alloc] initWithPlotSpace:graph.defaultPlotSpace   anchorPlotPoint:dateAnnotationPoint];
                dateAnnotation.contentLayer = textLayer;
                dateAnnotation.displacement =  CGPointMake( 0.0f,(CGFloat)10.0 );     
                [graph.plotAreaFrame.plotArea addAnnotation:dateAnnotation];
                [dateAnnotationArray addObject:dateAnnotation];
            }
        }
    }
    
	// this allows the plot to respond to mouse events
	[plotSpace0 setDelegate:self];
	[plotSpace0 setAllowsUserInteraction:YES];
    
    // Create a plot that uses the data source method
    CPTScatterPlot *dataSourceLinePlot;
    CPTMutableLineStyle *lineStyle;
    BOOL overlayAdded = NO;
    
    if([fieldNames count] > 0)
    {
        for(int i =0; i < [fieldNames count]; i++){
            if([[fieldNames objectAtIndex:i] isEqualToString:@"LONG"] || [[fieldNames objectAtIndex:i] isEqualToString:@"SHORT"]){
                if(!overlayAdded)
                {
                    overlayPlotSpace = [[CPTXYPlotSpace alloc] init];
                    [overlayPlotSpace setIdentifier:@"SHORTLONG"];
                    [graph addPlotSpace:overlayPlotSpace ];
                    overlayAdded = YES;
                }
             
                if([[fieldNames objectAtIndex:i] isEqualToString:@"SHORT"])
                {
                    dataSourceLinePlot = [[CPTScatterPlot alloc] init];
                    dataSourceLinePlot.identifier = @"P9_SHORT";
                    lineStyle = [dataSourceLinePlot.dataLineStyle mutableCopy];
                    lineStyle.lineWidth				 = 1.0;
                    lineStyle.lineColor				 = [CPTColor clearColor] ;
                    
                    CPTColor *areaColor = [CPTColor colorWithComponentRed:1.0 green:0.0 blue:0.0 alpha:0.3];
                      
                    dataSourceLinePlot.areaFill		 = [CPTFill fillWithColor:areaColor];
                    dataSourceLinePlot.areaBaseValue = CPTDecimalFromDouble(0.0);
                    
                    dataSourceLinePlot.dataLineStyle = lineStyle;
                    dataSourceLinePlot.dataSource =  dataView;
                    [graph addPlot:dataSourceLinePlot toPlotSpace:overlayPlotSpace];
                    
                }
                if([[fieldNames objectAtIndex:i] isEqualToString:@"LONG"])
                {
                    dataSourceLinePlot = [[CPTScatterPlot alloc] init];
                    dataSourceLinePlot.identifier = @"P9_LONG";
                    lineStyle = [dataSourceLinePlot.dataLineStyle mutableCopy];
                    lineStyle.lineWidth				 = 1.0;
                    lineStyle.lineColor				 = [CPTColor clearColor] ;
                    
                    CPTColor *areaColor		  = [CPTColor colorWithComponentRed:0.0 green:1.0 blue:0.0 alpha:0.3];
                    dataSourceLinePlot.areaFill		 = [CPTFill fillWithColor:areaColor];
                    dataSourceLinePlot.areaBaseValue = CPTDecimalFromDouble(0.0);
                    dataSourceLinePlot.dataLineStyle = lineStyle;
                    dataSourceLinePlot.dataSource =  dataView;
                    [graph addPlot:dataSourceLinePlot toPlotSpace:overlayPlotSpace];
                }
            }else{
                
                dataSourceLinePlot = [[CPTScatterPlot alloc] init];
                dataSourceLinePlot.identifier = [NSString stringWithFormat:@"P0_%@",[fieldNames objectAtIndex:i]];
                lineStyle = [dataSourceLinePlot.dataLineStyle mutableCopy];
                lineStyle.lineWidth				 = 1.0;
                if([[layerIndexes objectAtIndex:i] intValue] == 0){
                    lineStyle.lineColor = [colors objectAtIndex:(i%[colors count])] ;
                }else{
                    lineStyle.lineColor = [CPTColor clearColor];
                }
                dataSourceLinePlot.dataLineStyle = lineStyle;
                dataSourceLinePlot.dataSource =  dataView;
                [graph addPlot:dataSourceLinePlot
                 toPlotSpace:plotSpace0];
                
                dataSourceLinePlot = [[CPTScatterPlot alloc] init];
                dataSourceLinePlot.identifier = [NSString stringWithFormat:@"P1_%@",[fieldNames objectAtIndex:i]];
                lineStyle = [dataSourceLinePlot.dataLineStyle mutableCopy];
                lineStyle.lineWidth				 = 1.0;
                if([[layerIndexes objectAtIndex:i] intValue] == 1){
                    lineStyle.lineColor = [colors objectAtIndex:(i%[colors count])] ;
                }else{
                    lineStyle.lineColor = [CPTColor clearColor];
                }
                dataSourceLinePlot.dataLineStyle = lineStyle;
                dataSourceLinePlot.dataSource =  dataView;
                [graph addPlot:dataSourceLinePlot
                   toPlotSpace:plotSpace1];
                
                dataSourceLinePlot = [[CPTScatterPlot alloc] init];
                dataSourceLinePlot.identifier = [NSString stringWithFormat:@"P2_%@",[fieldNames objectAtIndex:i]];
                lineStyle = [dataSourceLinePlot.dataLineStyle mutableCopy];
                lineStyle.lineWidth				 = 1.0;
                if([[layerIndexes objectAtIndex:i] intValue] == 2){
                    lineStyle.lineColor = [colors objectAtIndex:(i%[colors count])] ;
                }else{
                    lineStyle.lineColor = [CPTColor clearColor];
                }
                dataSourceLinePlot.dataLineStyle = lineStyle;
                dataSourceLinePlot.dataSource =  dataView;
                [graph addPlot:dataSourceLinePlot
                   toPlotSpace:plotSpace2];
            }
        }
    }
    
    if(overlayAdded){
        CPTPlotRange *overlayPlotYRange;
        overlayPlotYRange = [[CPTPlotRange alloc] initWithLocation:[[NSDecimalNumber numberWithInt:0] decimalValue]  length:[[NSDecimalNumber numberWithInt:1] decimalValue]];
        CPTMutablePlotRange *xRange =[[plotSpace0 xRange] copy];
        overlayPlotSpace.xRange = xRange;
        overlayPlotSpace.yRange = overlayPlotYRange;
    }
 
    graph.axisSet.axes = [NSArray arrayWithObjects:xAxis0, yAxis0, yAxis1, yAxis2, nil];
    
	// create the zoom rectangle
	// first a bordered layer to draw the zoomrect
	CPTBorderedLayer *zoomRectangleLayer = [[CPTBorderedLayer alloc] initWithFrame:CGRectNull];
    
	lineStyle.lineColor				   = [CPTColor darkGrayColor];
	lineStyle.lineWidth				   = 1.f;
	zoomRectangleLayer.borderLineStyle = lineStyle;
    
	CPTColor *transparentFillColor = [[CPTColor blueColor] colorWithAlphaComponent:0.2];
	[zoomRectangleLayer setFill:[CPTFill fillWithColor:transparentFillColor]];
    
	// now create the annotation layers 
	zoomAnnotation = [[CPTPlotSpaceAnnotation alloc] initWithPlotSpace:plotSpace0 anchorPlotPoint:nil];
	zoomAnnotation.contentLayer = zoomRectangleLayer;
	[graph.plotAreaFrame.plotArea addAnnotation:zoomAnnotation];
    
	//[graph reloadData];
    zoomedOut = YES;
}

-(void)togglePositionIndicator
{
    CPTPlot * plot;
    plot = [graph plotWithIdentifier:@"P9_SHORT"]; 
    if(plot.dataSource == nil){
        plot.dataSource = dataView;
    }else {
        plot.dataSource = nil;
    }
    [plot dataNeedsReloading];

    plot = [graph plotWithIdentifier:@"P9_LONG"]; 
    if(plot.dataSource == nil){
        plot.dataSource = dataView;
    }else {
        plot.dataSource = nil;
    }
    [plot dataNeedsReloading];
}


- (BOOL) fixUpXAxisLabelsForLayerIndex: (int) layerIndex
              AndDataView: (DataView *) currentDataView;
{
    CPTXYPlotSpace *plotSpace;
    if(layerIndex == 0){
        plotSpace = plotSpace0;
        
    }
    if(layerIndex == 1){
        plotSpace = plotSpace1;
    }
    
    
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
    
    //    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init] ;
    dateFormatter.timeZone = [NSTimeZone timeZoneWithName:@"GMT"];
    // If it more than 3 days, major tic is 1 day, otherwise a major tic is 6 hours
    
    BOOL dateIsSpecifiedInAxis = NO;
    
    minXrangeForPlot = [currentDataView minDateTime];
    maxXrangeForPlot = [currentDataView maxDateTime];
    //    
    
    if(((float)(maxXrangeForPlot - minXrangeForPlot)/(4*30*60 * 60 * 24))>1){
        majorIntervalForX = 14 * 24 * 60 * 60;
        xAxis0.majorIntervalLength		  = CPTDecimalFromInt(majorIntervalForX); // 14 Day
        xAxis0.minorTicksPerInterval		  = 13;
        [dateFormatter setDateFormat:@"MM/dd"];
        dateIsSpecifiedInAxis = TRUE; 
    }else{
        if(((float)(maxXrangeForPlot - minXrangeForPlot)/(21*60 * 60 * 24))>1){
            majorIntervalForX = 7 * 24 * 60 * 60;
            xAxis0.majorIntervalLength		  = CPTDecimalFromInt(majorIntervalForX); // 7 Day
            xAxis0.minorTicksPerInterval		  = 6;
            [dateFormatter setDateFormat:@"MM/dd"];
            dateIsSpecifiedInAxis = TRUE;
        }else{
            //If greater than 3 days
            if(((float)(maxXrangeForPlot - minXrangeForPlot)/(3*60 * 60 * 24))>1){
                majorIntervalForX = 24 * 60 * 60;
                xAxis0.majorIntervalLength		  = CPTDecimalFromInt(majorIntervalForX); // 1 Day
                xAxis0.minorTicksPerInterval		  = 5;
                [dateFormatter setDateFormat:@"MM/dd"];
                dateIsSpecifiedInAxis = TRUE;
            }else{
                //If greater than 12 hours
                if(((float)(maxXrangeForPlot - minXrangeForPlot)/(60 * 60 * 12))>1){
                    majorIntervalForX = 4 * 60 * 60;
                    xAxis0.majorIntervalLength		  = CPTDecimalFromInt(majorIntervalForX); // 4 hours
                    xAxis0.minorTicksPerInterval		  = 3;
                    dateFormatter.dateStyle = kCFDateFormatterNoStyle;
                    dateFormatter.timeStyle = kCFDateFormatterShortStyle;
                }else{
                    //If less than 12 hours
                    if(((float)(maxXrangeForPlot - minXrangeForPlot)/(60 * 60 * 12))<=1){
                        majorIntervalForX = 60 * 60;
                        xAxis0.majorIntervalLength = CPTDecimalFromInt(majorIntervalForX); // 1 hours
                        xAxis0.minorTicksPerInterval = 5;
                        dateFormatter.dateStyle = kCFDateFormatterNoStyle;
                        dateFormatter.timeStyle = kCFDateFormatterShortStyle;
                    }
                }
            }   
        }
    }
    
    xAxis0.majorGridLineStyle		  = majorGridLineStyle;
    xAxis0.minorGridLineStyle		  = minorGridLineStyle;

    CPTTimeFormatter *timeFormatter = [[CPTTimeFormatter alloc] initWithDateFormatter:dateFormatter] ;
    NSDate *refDate = [NSDate dateWithTimeIntervalSince1970:0];
    timeFormatter.referenceDate = refDate;
    xAxis0.labelFormatter			= timeFormatter;
    xAxis0.labelRotation				= M_PI / 4;
    
    // From dropplot
    xAxis0.labelOffset			= 5.0;
	xAxis0.axisConstraints		= [CPTConstraints constraintWithLowerOffset:0.0];
    
    return !dateIsSpecifiedInAxis;
}


- (void) fixUpYAxisForLayerIndex: (int) layerIndex;
{
    double minYrangeForPlot, maxYrangeForPlot;
    //double majorIntervalForY;
    CPTXYPlotSpace *plotSpace;
    CPTXYAxis *yAxis;
    switch(layerIndex){
        case 0:
            minYrangeForPlot = minYrangeForPlot0;
            maxYrangeForPlot = maxYrangeForPlot0;
            plotSpace = plotSpace0;
            yAxis = yAxis0;
            break;
        case 1:
            minYrangeForPlot = minYrangeForPlot1;
            maxYrangeForPlot = maxYrangeForPlot1;
            plotSpace = plotSpace1;
            yAxis = yAxis1;
            break;
        case 2:
            minYrangeForPlot = minYrangeForPlot2;
            maxYrangeForPlot = maxYrangeForPlot2;
            plotSpace = plotSpace2;
            yAxis = yAxis2;
            break;
    }
    
    int nTicks = 10;
    double range = [self niceNumber:  maxYrangeForPlot-minYrangeForPlot
                       withRounding:NO];
    double d = [self niceNumber:range/(nTicks - 1) 
                   withRounding:YES];
    double axisMin = floor(minYrangeForPlot/d)*d;
    double axisMax = ceil(maxYrangeForPlot/d)*d;
    int nfrac = -floor(log10(d));
    if(nfrac < 0){
        nfrac = 0;
    }
    
    
    
    
    if(layerIndex==0){
         // Grid line styles
        CPTMutableLineStyle *majorGridLineStyle = [CPTMutableLineStyle lineStyle];
        majorGridLineStyle.lineWidth = 0.75;
        majorGridLineStyle.lineColor = [[CPTColor colorWithGenericGray:0.2] colorWithAlphaComponent:0.75];
     
        CPTMutableLineStyle *minorGridLineStyle = [CPTMutableLineStyle lineStyle];
        minorGridLineStyle.lineWidth = 0.25;
        minorGridLineStyle.lineColor = [[CPTColor whiteColor] colorWithAlphaComponent:0.1];
    
        yAxis.majorGridLineStyle		  = majorGridLineStyle;
        yAxis.minorGridLineStyle		  = minorGridLineStyle;
    }     
    
    CPTMutableLineStyle *axisLineStyle =  [CPTMutableLineStyle lineStyle];
    axisLineStyle.lineWidth = 0.5;
    axisLineStyle.lineColor = [[CPTColor whiteColor] colorWithAlphaComponent:0.5];
//     
//    if(((maxYrangeForPlot-minYrangeForPlot)/[plotData pipSize])>10000)
//    {
//        // If the range of the data is not related to pipsize then forget about pipsize 
//        // just go for about 10 intervals
//        //This needs to be fixed
//        int yRangeAsInt = (int)(maxYrangeForPlot-minYrangeForPlot);
//        int factor = 1;
//        while(yRangeAsInt < 10){
//            yRangeAsInt = yRangeAsInt * 10;
//            factor++;
//        }
//        majorIntervalForY = (yRangeAsInt)/pow(10,factor);
//        
//    }else{
//        majorIntervalForY = 10 * [plotData pipSize];
//    }
//    while(((maxYrangeForPlot-minYrangeForPlot)/majorIntervalForY)>10){
//        majorIntervalForY = majorIntervalForY * 2;
//    }
//    
    [yAxis setLabelOffset:5.0];
    
    //[yAxis setMajorIntervalLength:CPTDecimalFromDouble(majorIntervalForY)];
    [yAxis setMajorIntervalLength:CPTDecimalFromDouble(d)];
    [yAxis setMinorTicksPerInterval:1];
     
    [yAxis setAxisLineStyle:axisLineStyle];
    switch(layerIndex){
        case 0:
            [yAxis setTickDirection:CPTSignNegative]; 
            [yAxis setAxisConstraints:[CPTConstraints constraintWithLowerOffset:0.0]];
            break;
        case 1:
            [yAxis setTickDirection:CPTSignPositive]; 
            [yAxis setAxisConstraints:[CPTConstraints constraintWithLowerOffset:0.0]];
            break;
        case 2:
            [yAxis setTickDirection:CPTSignNegative]; 
            [yAxis setAxisConstraints:[CPTConstraints constraintWithUpperOffset:0.0]];
            break;
    }
     
    NSNumberFormatter *numberFormatter = [[NSNumberFormatter alloc] init];
    [numberFormatter setNumberStyle:NSNumberFormatterDecimalStyle];
//    if([plotData pipSize] <= 0.001){
//        [numberFormatter setMinimumFractionDigits:3];
//    }else{
//        [numberFormatter setMinimumFractionDigits:1];
//    }
    [numberFormatter setMinimumFractionDigits:nfrac];
    yAxis.labelFormatter = numberFormatter;
    
//    CPTMutablePlotRange *yRange = [CPTMutablePlotRange plotRangeWithLocation:CPTDecimalFromDouble(minYrangeForPlot)
//                                                                      length:CPTDecimalFromDouble(ceil( (maxYrangeForPlot - minYrangeForPlot) / majorIntervalForY ) * majorIntervalForY)];
    CPTMutablePlotRange *yRange = [CPTMutablePlotRange plotRangeWithLocation:CPTDecimalFromDouble(axisMin)
                                                                      length:CPTDecimalFromDouble((axisMax-axisMin)+(0.5*d))];
    [yRange expandRangeByFactor:CPTDecimalFromDouble(1.2)];
    
    [plotSpace setYRange:yRange];
    switch(layerIndex){
        case 0:
            yRange0ZoomOut = yRange;
            break;
        case 1:
            yRange1ZoomOut = yRange;
            break;
        case 2:
            yRange2ZoomOut = yRange;
            break;
    }
}

//- (void) fixUpYAxisForLayerIndex: (int) layerIndex;
//{
//    double minYrangeForPlot, maxYrangeForPlot;
//    double majorIntervalForY;
//    CPTXYPlotSpace *plotSpace;
//    CPTXYAxis *yAxis;
//    switch(layerIndex){
//        case 0:
//            minYrangeForPlot = minYrangeForPlot0;
//            maxYrangeForPlot = maxYrangeForPlot0;
//            plotSpace = plotSpace0;
//            yAxis = yAxis0;
//            break;
//        case 1:
//            minYrangeForPlot = minYrangeForPlot1;
//            maxYrangeForPlot = maxYrangeForPlot1;
//            plotSpace = plotSpace1;
//            yAxis = yAxis1;
//            break;
//        case 2:
//            minYrangeForPlot = minYrangeForPlot2;
//            maxYrangeForPlot = maxYrangeForPlot2;
//            plotSpace = plotSpace2;
//            yAxis = yAxis2;
//            break;
//    }
//    
//    if(layerIndex==0){
//        // Grid line styles
//        CPTMutableLineStyle *majorGridLineStyle = [CPTMutableLineStyle lineStyle];
//        majorGridLineStyle.lineWidth = 0.75;
//        majorGridLineStyle.lineColor = [[CPTColor colorWithGenericGray:0.2] colorWithAlphaComponent:0.75];
//        
//        CPTMutableLineStyle *minorGridLineStyle = [CPTMutableLineStyle lineStyle];
//        minorGridLineStyle.lineWidth = 0.25;
//        minorGridLineStyle.lineColor = [[CPTColor whiteColor] colorWithAlphaComponent:0.1];
//        
//        yAxis.majorGridLineStyle		  = majorGridLineStyle;
//        yAxis.minorGridLineStyle		  = minorGridLineStyle;
//    }     
//    
//    CPTMutableLineStyle *axisLineStyle =  [CPTMutableLineStyle lineStyle];
//    axisLineStyle.lineWidth = 0.5;
//    axisLineStyle.lineColor = [[CPTColor whiteColor] colorWithAlphaComponent:0.5];
//    
//    if(((maxYrangeForPlot-minYrangeForPlot)/[plotData pipSize])>10000)
//    {
//        // If the range of the data is not related to pipsize then forget about pipsize 
//        // just go for about 10 intervals
//        //This needs to be fixed
//        int yRangeAsInt = (int)(maxYrangeForPlot-minYrangeForPlot);
//        int factor = 1;
//        while(yRangeAsInt < 10){
//            yRangeAsInt = yRangeAsInt * 10;
//            factor++;
//        }
//        majorIntervalForY = (yRangeAsInt)/pow(10,factor);
//        
//    }else{
//        majorIntervalForY = 10 * [plotData pipSize];
//    }
//    while(((maxYrangeForPlot-minYrangeForPlot)/majorIntervalForY)>10){
//        majorIntervalForY = majorIntervalForY * 2;
//    }
//    
//    [yAxis setLabelOffset:5.0];
//    
//    [yAxis setMajorIntervalLength:CPTDecimalFromDouble(majorIntervalForY)];
//    [yAxis setMinorTicksPerInterval:1];
//    
//    [yAxis setAxisLineStyle:axisLineStyle];
//    switch(layerIndex){
//        case 0:
//            [yAxis setTickDirection:CPTSignNegative]; 
//            [yAxis setAxisConstraints:[CPTConstraints constraintWithLowerOffset:0.0]];
//            break;
//        case 1:
//            [yAxis setTickDirection:CPTSignPositive]; 
//            [yAxis setAxisConstraints:[CPTConstraints constraintWithLowerOffset:0.0]];
//            break;
//        case 2:
//            [yAxis setTickDirection:CPTSignNegative]; 
//            [yAxis setAxisConstraints:[CPTConstraints constraintWithUpperOffset:0.0]];
//            break;
//    }
//    
//    NSNumberFormatter *numberFormatter = [[NSNumberFormatter alloc] init];
//    [numberFormatter setNumberStyle:NSNumberFormatterDecimalStyle];
//    if([plotData pipSize] <= 0.001){
//        [numberFormatter setMinimumFractionDigits:3];
//    }else{
//        [numberFormatter setMinimumFractionDigits:1];
//    }
//    yAxis.labelFormatter = numberFormatter;
//    
//    CPTMutablePlotRange *yRange = [CPTMutablePlotRange plotRangeWithLocation:CPTDecimalFromDouble(minYrangeForPlot)
//                                                                      length:CPTDecimalFromDouble(ceil( (maxYrangeForPlot - minYrangeForPlot) / majorIntervalForY ) * majorIntervalForY)];
//    [yRange expandRangeByFactor:CPTDecimalFromDouble(1.2)];
//    
//    [plotSpace setYRange:yRange];
//    switch(layerIndex){
//        case 0:
//            yRange0ZoomOut = yRange;
//            break;
//        case 1:
//            yRange1ZoomOut = yRange;
//            break;
//        case 2:
//            yRange2ZoomOut = yRange;
//            break;
//    }
//}


- (void) plotLineUpdated
{
    for(int layerIndex = 0; layerIndex < 3; layerIndex++)
    {
    
        CPTXYAxis *yAxis;
        switch(layerIndex){
            case 0:
                yAxis = yAxis0;
                break;
            case 1:
                yAxis = yAxis1;
                break;
            case 2:
                yAxis = yAxis2;
        }
     
        TimeSeriesLine *tsLine;
        BOOL visiblePlotLineFound = NO;
   
        NSString *lineIdentifier;
        double minYrangeForPlot = 0, maxYrangeForPlot = 0; 
    
        for(int i = 0; i < [timeSeriesLines count]; i++)
        {
            tsLine = [timeSeriesLines objectAtIndex:i]; 
            lineIdentifier = [NSString stringWithFormat:@"P%d_%@",layerIndex,[tsLine name]];
            CPTScatterPlot *plot = (CPTScatterPlot *)[graph plotWithIdentifier:lineIdentifier];
            CPTMutableLineStyle *lineStyle = [plot.dataLineStyle mutableCopy];
        
            if([tsLine layerIndex]==layerIndex){
                lineStyle.lineColor = [tsLine cpColour];
                if(!visiblePlotLineFound){
                    minYrangeForPlot = [[[dataView minYvalues] valueForKey:[tsLine name]] doubleValue];
                    maxYrangeForPlot = [[[dataView maxYvalues] valueForKey:[tsLine name]] doubleValue];
                    visiblePlotLineFound = YES;
                }else{
                    minYrangeForPlot = fmin(minYrangeForPlot,[[[dataView minYvalues] valueForKey:[tsLine name]] doubleValue]); 
                    maxYrangeForPlot = fmax(maxYrangeForPlot,[[[dataView maxYvalues] valueForKey:[tsLine name]] doubleValue]);
                }
            }else{
                lineStyle.lineColor = [CPTColor clearColor];
            }
            plot.dataLineStyle = lineStyle;
        }
        
        if(visiblePlotLineFound){
            switch(layerIndex){
                case 0:
                    minYrangeForPlot0 = minYrangeForPlot;
                    maxYrangeForPlot0 = maxYrangeForPlot;
                    break;
                case 1:
                    minYrangeForPlot1 = minYrangeForPlot;
                    maxYrangeForPlot1 = maxYrangeForPlot;
                    if(!plot1AxisVisible){
                        CPTMutableTextStyle *newTextStyle = [[yAxis labelTextStyle] mutableCopy];
                        [newTextStyle setColor:[CPTColor whiteColor]];
                        [yAxis setLabelTextStyle:newTextStyle];
                        CPTMutableLineStyle *axisLineStyle =  [CPTMutableLineStyle lineStyle];
                        axisLineStyle.lineWidth = 0.5;
                        axisLineStyle.lineColor = [[CPTColor whiteColor] colorWithAlphaComponent:0.5];
                        [yAxis setMajorTickLineStyle:axisLineStyle];
                        plot1AxisVisible = YES;
                    }
                    break;
                case 2:
                    minYrangeForPlot2 = minYrangeForPlot;
                    maxYrangeForPlot2 = maxYrangeForPlot;
                    if(!plot2AxisVisible){
                        CPTMutableTextStyle *newTextStyle = [[yAxis labelTextStyle] mutableCopy];
                        [newTextStyle setColor:[CPTColor whiteColor]];
                        [yAxis setLabelTextStyle:newTextStyle];
                        CPTMutableLineStyle *axisLineStyle =  [CPTMutableLineStyle lineStyle];
                        axisLineStyle.lineWidth = 0.5;
                        axisLineStyle.lineColor = [[CPTColor whiteColor] colorWithAlphaComponent:0.5];
                        [yAxis setMajorTickLineStyle:axisLineStyle];
                        
//                        CPTPlotRange *xRange  = plotSpace0.xRange;
//                        double maxX = [[NSDecimalNumber decimalNumberWithDecimal:xRange.location] doubleValue] + [[NSDecimalNumber decimalNumberWithDecimal:xRange.length] doubleValue];
//                                        
//                        [yAxis setOrthogonalCoordinateDecimal:CPTDecimalFromDouble(maxX)]; 
                        plot2AxisVisible = YES;
                    }
                    break;
            }
            //Fix the axes
            [self fixUpYAxisForLayerIndex:layerIndex];
        }else {
            switch(layerIndex){
                case 1:
                    if(plot1AxisVisible){
                        CPTMutableTextStyle *newTextStyle = [[yAxis labelTextStyle] mutableCopy];
                        [newTextStyle setColor:[CPTColor clearColor]];
                        [yAxis setLabelTextStyle:newTextStyle];
                        yAxis.majorTickLineStyle = nil;
                        plot1AxisVisible = NO;
                    }
                    break;
                case 2:
                    if(plot2AxisVisible){
                        CPTMutableTextStyle *newTextStyle = [[yAxis labelTextStyle] mutableCopy];
                        [newTextStyle setColor:[CPTColor clearColor]];
                        [yAxis setLabelTextStyle:newTextStyle];
                        yAxis.majorTickLineStyle = nil;
                        plot2AxisVisible = NO;
                    }
                    break;  
                default:
                    //Do nothing
                    break;
            }
        }
    }
    if(zoomedOut){
        //Get to the fully zoomed out position after a change in content of graph
        [self zoomOut];
    }
    //[graph reloadData];
}

- (void) toggleAxisLabelsForLayer: (int) layerIndex
{
    CPTMutableTextStyle *newTextStyle;
    switch(layerIndex){
        case 1:
            if(plot1AxisVisible){
                newTextStyle = [[yAxis1 labelTextStyle] mutableCopy];
                [newTextStyle setColor:[CPTColor clearColor]];
                [yAxis1 setLabelTextStyle:newTextStyle];
                [yAxis1 setMajorTickLineStyle:nil];
                plot1AxisVisible = NO;
            }else{
                newTextStyle = [[yAxis1 labelTextStyle] mutableCopy];
                [newTextStyle setColor:[CPTColor whiteColor]];
                [yAxis1 setLabelTextStyle:newTextStyle];
                CPTMutableLineStyle *axisLineStyle =  [CPTMutableLineStyle lineStyle];
                axisLineStyle.lineWidth = 0.5;
                axisLineStyle.lineColor = [[CPTColor blackColor] colorWithAlphaComponent:0.5];
                [yAxis1 setMajorTickLineStyle:axisLineStyle];
                plot1AxisVisible = YES;
            }
            break;
        case 2:
            if(plot2AxisVisible){
                newTextStyle = [[yAxis2 labelTextStyle] mutableCopy];
                [newTextStyle setColor:[CPTColor clearColor]];
                [yAxis2 setLabelTextStyle:newTextStyle];
                [yAxis2 setMajorTickLineStyle:nil];
                plot2AxisVisible = NO;
            }else{
                newTextStyle = [[yAxis2 labelTextStyle] mutableCopy];
                [newTextStyle setColor:[CPTColor whiteColor]];
                [yAxis2 setLabelTextStyle:newTextStyle];
                CPTMutableLineStyle *axisLineStyle =  [CPTMutableLineStyle lineStyle];
                axisLineStyle.lineWidth = 0.5;
                axisLineStyle.lineColor = [[CPTColor blackColor] colorWithAlphaComponent:0.5];
                [yAxis2 setMajorTickLineStyle:axisLineStyle];
                plot2AxisVisible = YES;
            }
            break;
        default:
        break;
    }
}


-(void)addHorizontalLineAt:(double) yValue ForPlotspace:(CPTXYPlotSpace *) plotSpace
{
    double dataValues[2];
    double minXRange = [[NSDecimalNumber decimalNumberWithDecimal:[[plotSpace xRange] location]] doubleValue];
    double maxXRange =  minXRange + [[NSDecimalNumber decimalNumberWithDecimal:[[plotSpace xRange] length]] doubleValue];
    
    dataValues[0] = minXRange;
    dataValues[1] = yValue;
    
    CPTMutableLineStyle *lineStyle = [[CPTMutableLineStyle alloc] init];
    CPTBorderedLayer *lineLayer = [[CPTBorderedLayer alloc] initWithFrame:CGRectNull];
    lineStyle.lineColor				   = [CPTColor lightGrayColor];
	lineStyle.lineWidth				   = 1.f;
	[lineLayer setBorderLineStyle:lineStyle];
    
    //transparentFillColor = [[CPTColor lightGrayColor] colorWithAlphaComponent:0.2];
	[lineLayer setFill:[CPTFill fillWithColor:[CPTColor clearColor]]];
    lineAnnotation = [[CPTPlotSpaceAnnotation alloc] initWithPlotSpace:plotSpace anchorPlotPoint:nil];
	lineAnnotation.contentLayer = lineLayer;
    
    CGPoint startPoint =  [plotSpace plotAreaViewPointForDoublePrecisionPlotPoint:dataValues];
    dataValues[0] = maxXRange;
    CGPoint endPoint =  [plotSpace plotAreaViewPointForDoublePrecisionPlotPoint:dataValues];
    
    CGRect borderRect;
    borderRect = CGRectMake(startPoint.x, startPoint.y ,
                            (endPoint.x - startPoint.x),
                            1);  
    lineAnnotation.contentLayer.frame = borderRect;
	[graph.plotAreaFrame.plotArea addAnnotation:lineAnnotation];
    [lineAnnotationArray addObject:lineAnnotation];
    [lineAnnotationLevelArray addObject:[NSNumber numberWithDouble:yValue]];
}

#pragma mark -
#pragma mark Nice numbers Methods

-(double) niceNumber: (double) x withRounding:(BOOL) doRounding
{
    double niceNumber, f, nf;
    int exp;
    exp = floor(log10(x));
    f = x/pow(10.0,exp);
    if(doRounding){
        if(f < 1.5)
            nf = 1;
        else if(f < 3)
            nf  = 2;
        else if(f < 7)
            nf = 5;
        else
            nf = 10;
    }else{
        if(f <= 1)
            nf = 1;
        else if(f <= 2)
            nf = 2;
        else if(f <= 5)
            nf = 5;
        else {
            nf = 10;
        }
    }
    niceNumber = nf*pow(10, exp);
    return niceNumber;
}


#pragma mark -
#pragma mark Plot Space Delegate Methods

-(BOOL)plotSpace:(CPTPlotSpace *)plotSpace shouldHandlePointingDeviceDraggedEvent:(id)event 
         atPoint:(CGPoint)interactionPoint
{
    TimeSeriesLine *tsLine = [timeSeriesLines objectAtIndex:0];
    NSString *plotIdentifier = [NSString stringWithFormat:@"P0_%@",[tsLine name]];
    CPTScatterPlot *plot = (CPTScatterPlot *)[graph plotWithIdentifier:plotIdentifier];
    
	// convert the dragStart and dragEnd values to plot coordinates
	CGPoint dragStartInPlotArea = [graph convertPoint:dragStart toLayer:plot];
	CGPoint dragEndInPlotArea	= [graph convertPoint:interactionPoint toLayer:plot];
    
	// create the dragrect from dragStart to the current location
    CGRect borderRect;
    if([NSEvent modifierFlags] == NSAlternateKeyMask){
        borderRect = CGRectMake(dragStartInPlotArea.x, dragStartInPlotArea.y,
                                (dragEndInPlotArea.x - dragStartInPlotArea.x),
                                (dragEndInPlotArea.y - dragStartInPlotArea.y));
    }else{
        double getValues[2];
        double minYRange = [[NSDecimalNumber decimalNumberWithDecimal:[[plotSpace0 yRange] location]] doubleValue];
        double maxYRange =  minYRange + [[NSDecimalNumber decimalNumberWithDecimal:[[plotSpace0 yRange] length]] doubleValue];
        
        getValues[0] = 0.0;
        getValues[1] = minYRange;

        CGPoint getMinY =  [plotSpace0 plotAreaViewPointForDoublePrecisionPlotPoint:getValues];
        getValues[1] = maxYRange;
        CGPoint getMaxY =  [plotSpace0 plotAreaViewPointForDoublePrecisionPlotPoint:getValues];
        borderRect = CGRectMake(dragStartInPlotArea.x, getMinY.y ,
                                (dragEndInPlotArea.x - dragStartInPlotArea.x),
                                getMaxY.y);
        
    }
  
	// force the drawing of the zoomRect
	zoomAnnotation.contentLayer.frame = borderRect;
	[zoomAnnotation.contentLayer setNeedsDisplay];
    
    // Add a date
    //CPTXYPlotSpace *plotSpace = (CPTXYPlotSpace *)graph.defaultPlotSpace;
    CGPoint dragInPlotArea = [graph convertPoint:interactionPoint toLayer:plot];
    double dataCoords[2];
    [plotSpace0 doublePrecisionPlotPoint:dataCoords forPlotAreaViewPoint:dragInPlotArea];
    
    NSString *currentValue;
    if([NSEvent modifierFlags] == NSAlternateKeyMask){
        currentValue = [NSString stringWithFormat:@"%5.3f",dataCoords[CPTCoordinateY]];
    }else{
        currentValue = [EpochTime stringOfDateTimeForTime:(long)dataCoords[CPTCoordinateX] 
                                                     WithFormat: @"%a %Y-%m-%d %H:%M:%S"];
    }
    NSNumber *x            = [NSNumber numberWithDouble:dataCoords[CPTCoordinateX]];
    NSNumber *y            = [NSNumber numberWithDouble:dataCoords[CPTCoordinateY]];
    NSArray *anchorPoint = [NSArray arrayWithObjects: x,y, nil];
    //    
    if (dragDateAnnotation) {
		[graph.plotAreaFrame.plotArea removeAnnotation:dragDateAnnotation];
		dragDateAnnotation = nil;
	}
    
	// Setup a style for the annotation
	CPTMutableTextStyle *hitAnnotationTextStyle = [CPTMutableTextStyle textStyle];
	hitAnnotationTextStyle.color	= [CPTColor grayColor];
	hitAnnotationTextStyle.fontSize = 12.0f;
	hitAnnotationTextStyle.fontName = @"Courier";
    
	// Now add the annotation to the plot area
	CPTTextLayer *textLayer = [[CPTTextLayer alloc] initWithText:currentValue style:hitAnnotationTextStyle];
	dragDateAnnotation			  = [[CPTPlotSpaceAnnotation alloc] initWithPlotSpace:graph.defaultPlotSpace anchorPlotPoint:anchorPoint];
	dragDateAnnotation.contentLayer = textLayer;
	dragDateAnnotation.displacement = CGPointMake(0.0f, 10.0f);
	[graph.plotAreaFrame.plotArea addAnnotation:dragDateAnnotation];
    
	return NO;
}

-(BOOL)plotSpace:(CPTPlotSpace *)plotSpace shouldHandlePointingDeviceDownEvent:(id)event atPoint:(CGPoint)interactionPoint
{
  	
    if([NSEvent modifierFlags] == NSCommandKeyMask){
        TimeSeriesLine *tsLine = [timeSeriesLines objectAtIndex:0];
        NSString *plotIdentifier = [NSString stringWithFormat:@"P0_%@",[tsLine name]];
        CPTScatterPlot *plot = (CPTScatterPlot *)[graph plotWithIdentifier:plotIdentifier];
        CGPoint clickInPlotArea = [graph convertPoint:interactionPoint 
                                              toLayer:plot];
        double dataCoords[2];
        
        [plotSpace doublePrecisionPlotPoint:dataCoords 
                       forPlotAreaViewPoint:clickInPlotArea];
        [self addHorizontalLineAt:dataCoords[CPTCoordinateY] ForPlotspace:plotSpace0];
        
    }else{    
    dragStart = interactionPoint;

    //CPTXYPlotSpace *plotSpace = (CPTXYPlotSpace *)graph.defaultPlotSpace;
    TimeSeriesLine *tsLine = [timeSeriesLines objectAtIndex:0];
    NSString *plotIdentifier = [NSString stringWithFormat:@"P0_%@",[tsLine name]];
    CPTScatterPlot *plot = (CPTScatterPlot *)[graph plotWithIdentifier:plotIdentifier];
    //CPTPlotSpaceAnnotation *test;
    
    CGPoint clickInPlotArea = [graph convertPoint:interactionPoint 
                                          toLayer:plot];
    double dataCoords[2];
    [plotSpace doublePrecisionPlotPoint:dataCoords 
                    forPlotAreaViewPoint:clickInPlotArea];
    
    // Add annotation
    // First make a string for the y value
    NSString *currentValue;
    if([NSEvent modifierFlags] == NSAlternateKeyMask){
        currentValue = [NSString stringWithFormat:@"%5.4f",dataCoords[CPTCoordinateY]];
    }else{
        currentValue = [EpochTime stringOfDateTimeForTime:(long)dataCoords[CPTCoordinateX] 
                                               WithFormat: @"%a %Y-%m-%d %H:%M:%S"];
    }
    //    
    NSNumber *x            = [NSNumber numberWithDouble:dataCoords[CPTCoordinateX]];
    NSNumber *y            = [NSNumber numberWithDouble:dataCoords[CPTCoordinateY]];
    NSArray *anchorPoint = [NSArray arrayWithObjects: x,y, nil];
    //    
    if ( clickDateAnnotation ) {
		[graph.plotAreaFrame.plotArea removeAnnotation:clickDateAnnotation];
		clickDateAnnotation = nil;
	}
    
	// Setup a style for the annotation
	CPTMutableTextStyle *hitAnnotationTextStyle = [CPTMutableTextStyle textStyle];
	hitAnnotationTextStyle.color	= [CPTColor grayColor];
	hitAnnotationTextStyle.fontSize = 12.0f;
	hitAnnotationTextStyle.fontName = @"Courier";
   
	// Now add the annotation to the plot area
	CPTTextLayer *textLayer = [[CPTTextLayer alloc] initWithText:currentValue style:hitAnnotationTextStyle];
	clickDateAnnotation			  = [[CPTPlotSpaceAnnotation alloc] initWithPlotSpace:graph.defaultPlotSpace anchorPlotPoint:anchorPoint];
	clickDateAnnotation.contentLayer = textLayer;
	clickDateAnnotation.displacement = CGPointMake(0.0f, 10.0f);
	[graph.plotAreaFrame.plotArea addAnnotation:clickDateAnnotation];
    }
	return NO;
}

-(BOOL)plotSpace:(CPTPlotSpace *)plotSpace shouldHandlePointingDeviceUpEvent:(id)event atPoint:(CGPoint)point
{
    if([NSEvent modifierFlags] == NSCommandKeyMask){
        if([event clickCount] == 2){
            while([lineAnnotationArray count] > 0){
                [graph.plotAreaFrame.plotArea removeAnnotation:[lineAnnotationArray objectAtIndex:0]];
                [lineAnnotationArray removeObjectAtIndex:0];
                [lineAnnotationLevelArray removeObjectAtIndex:0];
            }
        }
    }else{
        
	if ( clickDateAnnotation ) {
		[graph.plotAreaFrame.plotArea removeAnnotation:clickDateAnnotation];
		clickDateAnnotation = nil;
	}
    
    if ( dragDateAnnotation ) {
		[graph.plotAreaFrame.plotArea removeAnnotation:dragDateAnnotation];
		dragDateAnnotation = nil;
	}
    
    dragEnd = point;
    
	// double-click to completely zoom out
	if ( [event clickCount] == 2 ) {
		[self zoomOut];
        
	}
	else if ( !CGPointEqualToPoint(dragStart, dragEnd) ) {
        
		// no accidental drag, so zoom in
		if([NSEvent modifierFlags] == NSAlternateKeyMask){
            [self zoomInAndFitYAxis:YES];
        }else{
            [self zoomInAndFitYAxis:NO];
        }
        
		// and we're done with the drag
		zoomAnnotation.contentLayer.frame = CGRectNull;
		[zoomAnnotation.contentLayer setNeedsDisplay];
	}
    }
	return NO;
}

#pragma mark -
#pragma mark Zoom Methods

-(void)setZoomDataViewFrom:(long)startDateTime To:(long) endDateTime
{
    //CPTXYPlotSpace *plotSpace = (CPTXYPlotSpace *)graph.defaultPlotSpace;
    //TimeSeriesLine *tsLine = [timeSeriesLines objectAtIndex:0];
    //CPTScatterPlot *plot = (CPTScatterPlot *)[graph plotWithIdentifier:[tsLine name]];
    
    double minXzoomForPlot;
	double maxXzoomForPlot;
	//double minYzoomForPlot;
	//double maxYzoomForPlot;
    
	// recalculate the min and max values
	minXzoomForPlot = startDateTime;
	maxXzoomForPlot = endDateTime;
    
    DataView *zoomView = [plotData setPlotViewWithName:@"ZOOM" 
                                      AndStartDateTime:(long)minXzoomForPlot 
                                        AndEndDateTime:(long)maxXzoomForPlot];
    
    plotSpace0.xRange = [CPTPlotRange plotRangeWithLocation:CPTDecimalFromDouble(minXzoomForPlot)
													length:CPTDecimalFromDouble(maxXzoomForPlot - minXzoomForPlot)];
    
    [plotSpace1 setXRange:[[plotSpace0 xRange] copy]];
    [plotSpace2 setXRange:[[plotSpace0 xRange] copy]];
    zoomedOut = NO;
    
    overlayPlotSpace.xRange = [plotSpace0.xRange copy];
    
    BOOL dateAnnotateRequired = [self fixUpXAxisLabelsForLayerIndex:0  
                                                        AndDataView:zoomView];
    
    while([dateAnnotationArray count] > 0){
        [graph.plotAreaFrame.plotArea removeAnnotation:[dateAnnotationArray objectAtIndex:0]];
        [dateAnnotationArray removeObjectAtIndex:0];
    }
    
    if(dateAnnotateRequired){
        long firstMidnight = [EpochTime epochTimeAtZeroHour:minXrangeForPlot];
        long lastMidnight = [EpochTime epochTimeNextDayAtZeroHour:maxXrangeForPlot];
        
        CPTPlotRange *xRange  = plotSpace0.xRange;
        CPTPlotRange *yRange = plotSpace0.yRange;
        double minXrange = [[NSDecimalNumber decimalNumberWithDecimal:xRange.location] doubleValue];
        double maxXrange = [[NSDecimalNumber decimalNumberWithDecimal:xRange.location] doubleValue] + [[NSDecimalNumber decimalNumberWithDecimal:xRange.length] doubleValue];
        
        CGRect bounds = NSRectToCGRect(hostingView.bounds);
        
        NSString *stringFromDate;
        CPTMutableTextStyle *dateStringStyle;
        NSArray *dateAnnotationPoint;
        CPTTextLayer *textLayer;
        NSDateFormatter *labelFormatter = [[NSDateFormatter alloc] init] ;
        [labelFormatter setDateFormat:@"MM/dd"];
        labelFormatter.timeZone = [NSTimeZone timeZoneWithName:@"GMT"];
        CPTPlotSpaceAnnotation *dateAnnotation;
        for(long labelDate = firstMidnight; labelDate <= lastMidnight; labelDate = labelDate + (60*60*24))
        {
            if((double)labelDate >= minXrange && labelDate <= (double)(maxXrange)){
                stringFromDate = [labelFormatter stringFromDate:[NSDate dateWithTimeIntervalSince1970:labelDate]];
                dateStringStyle = [CPTMutableTextStyle textStyle];
                dateStringStyle.color	= [CPTColor redColor];
                dateStringStyle.fontSize = round(bounds.size.height / (CGFloat)30.0);
                dateStringStyle.fontName = @"Courier";
                
                // Determine point of symbol in plot coordinates
                dateAnnotationPoint = [NSArray arrayWithObjects:[NSDecimalNumber numberWithLong:labelDate],[NSDecimalNumber decimalNumberWithDecimal: yRange.location], nil];
                
                textLayer = [[CPTTextLayer alloc] initWithText:stringFromDate style:dateStringStyle];
                dateAnnotation = [[CPTPlotSpaceAnnotation alloc] initWithPlotSpace:graph.defaultPlotSpace   anchorPlotPoint:dateAnnotationPoint];
                dateAnnotation.contentLayer = textLayer;
                dateAnnotation.displacement =  CGPointMake( 0.0f,(CGFloat)10.0 );     
                [graph.plotAreaFrame.plotArea addAnnotation:dateAnnotation];
                [dateAnnotationArray addObject:dateAnnotation];
            }
        }
    }
    
}


-(void)zoomInAndFitYAxis:(BOOL) fitYAxis;
{
	//CPTXYPlotSpace *plotSpace = (CPTXYPlotSpace *)graph.defaultPlotSpace;
    TimeSeriesLine *tsLine = [timeSeriesLines objectAtIndex:0];
    NSString *plotIdentifier = [NSString stringWithFormat:@"P0_%@",[tsLine name]];
    CPTScatterPlot *plot = (CPTScatterPlot *)[graph plotWithIdentifier:plotIdentifier];
    
    double minXzoomForPlot;
	double maxXzoomForPlot;
	double minYzoomForPlot0;
	double maxYzoomForPlot0;
    double minYzoomForPlot1;
	double maxYzoomForPlot1;
    double minYzoomForPlot2;
	double maxYzoomForPlot2;

	// convert the dragStart and dragEnd values to plot coordinates
	CGPoint dragStartInPlotArea = [graph convertPoint:dragStart toLayer:plot];
	CGPoint dragEndInPlotArea	= [graph convertPoint:dragEnd toLayer:plot];
    
	double start0[2], end0[2], start1[2], end1[2], start2[2], end2[2];
    
	// obtain the datapoints for the drag start and end
	[plotSpace0 doublePrecisionPlotPoint:start0 forPlotAreaViewPoint:dragStartInPlotArea];
	[plotSpace0 doublePrecisionPlotPoint:end0 forPlotAreaViewPoint:dragEndInPlotArea];
    
    [plotSpace1 doublePrecisionPlotPoint:start1 forPlotAreaViewPoint:dragStartInPlotArea];
    [plotSpace1 doublePrecisionPlotPoint:end1 forPlotAreaViewPoint:dragEndInPlotArea];
    
    [plotSpace2 doublePrecisionPlotPoint:start2 forPlotAreaViewPoint:dragStartInPlotArea];
    [plotSpace2 doublePrecisionPlotPoint:end2 forPlotAreaViewPoint:dragEndInPlotArea];
    
	// recalculate the min and max values
	minXzoomForPlot = MIN(start0[CPTCoordinateX], end0[CPTCoordinateX]);
	maxXzoomForPlot = MAX(start0[CPTCoordinateX], end0[CPTCoordinateX]);
    
    DataView *zoomView = [plotData setPlotViewWithName:@"ZOOM" 
                                      AndStartDateTime:(long)minXzoomForPlot 
                                        AndEndDateTime:(long)maxXzoomForPlot];
    
    [plotSpace0 setXRange:[CPTPlotRange plotRangeWithLocation:CPTDecimalFromDouble(minXzoomForPlot)
                                                      length:CPTDecimalFromDouble(maxXzoomForPlot - minXzoomForPlot)]];
    [overlayPlotSpace setXRange:[[plotSpace0 xRange] copy]];
    
    [plotSpace1 setXRange:[[plotSpace0 xRange] copy]];
    [plotSpace2 setXRange:[[plotSpace0 xRange] copy]];
    
    if(fitYAxis){
        minYzoomForPlot0 = MIN(start0[CPTCoordinateY], end0[CPTCoordinateY]);
        maxYzoomForPlot0 = MAX(start0[CPTCoordinateY], end0[CPTCoordinateY]);
        [plotSpace0 setYRange:[CPTPlotRange plotRangeWithLocation:CPTDecimalFromDouble(minYzoomForPlot0)
                                                           length:CPTDecimalFromDouble(maxYzoomForPlot0 - minYzoomForPlot0)]];
        
        minYzoomForPlot1 = MIN(start1[CPTCoordinateY], end1[CPTCoordinateY]);
        maxYzoomForPlot1 = MAX(start1[CPTCoordinateY], end1[CPTCoordinateY]);
        [plotSpace1 setYRange:[CPTPlotRange plotRangeWithLocation:CPTDecimalFromDouble(minYzoomForPlot1)
                                                           length:CPTDecimalFromDouble(maxYzoomForPlot1 - minYzoomForPlot1)]];
        
        minYzoomForPlot2 = MIN(start2[CPTCoordinateY], end2[CPTCoordinateY]);
        maxYzoomForPlot2 = MAX(start2[CPTCoordinateY], end2[CPTCoordinateY]);
        [plotSpace2 setYRange:[CPTPlotRange plotRangeWithLocation:CPTDecimalFromDouble(minYzoomForPlot2)
                                                           length:CPTDecimalFromDouble(maxYzoomForPlot2 - minYzoomForPlot2)]];
        
        //This is for any horizontal lines that have been added
        if([lineAnnotationArray count] > 0){
        NSMutableArray *tempArray = [[NSMutableArray alloc] init];
            for(int i = 0; i < [lineAnnotationLevelArray count]; i++){
                [graph.plotAreaFrame.plotArea removeAnnotation:[lineAnnotationArray objectAtIndex:i]];
                [tempArray addObject:[NSNumber numberWithDouble:[[lineAnnotationLevelArray objectAtIndex:i] doubleValue]]];
            }
            [lineAnnotationArray removeAllObjects];
            [lineAnnotationLevelArray removeAllObjects];
            for(int i = 0; i < [tempArray count]; i++){
                [self addHorizontalLineAt:[[tempArray objectAtIndex:i] doubleValue] ForPlotspace:plotSpace0];
            }
            [tempArray removeAllObjects];
        }
    }
    zoomedOut = NO;

    BOOL dateAnnotateRequired = [self fixUpXAxisLabelsForLayerIndex:0 
                                                        AndDataView:zoomView];
    
    while([dateAnnotationArray count] > 0){
        [graph.plotAreaFrame.plotArea removeAnnotation:[dateAnnotationArray objectAtIndex:0]];
        [dateAnnotationArray removeObjectAtIndex:0];
    }
    
    if(dateAnnotateRequired){
        long firstMidnight = [EpochTime epochTimeAtZeroHour:minXrangeForPlot];
        long lastMidnight = [EpochTime epochTimeNextDayAtZeroHour:maxXrangeForPlot];
        
        CPTPlotRange *xRange  = [plotSpace0 xRange];
        CPTPlotRange *yRange = [plotSpace0 yRange];
        double minXrange = [[NSDecimalNumber decimalNumberWithDecimal:xRange.location] doubleValue];
        double maxXrange = [[NSDecimalNumber decimalNumberWithDecimal:xRange.location] doubleValue] + [[NSDecimalNumber decimalNumberWithDecimal:xRange.length] doubleValue];
        
        CGRect bounds = NSRectToCGRect(hostingView.bounds);
        
        NSString *stringFromDate;
        CPTMutableTextStyle *dateStringStyle;
        NSArray *dateAnnotationPoint;
        CPTTextLayer *textLayer;
        NSDateFormatter *labelFormatter = [[NSDateFormatter alloc] init] ;
        [labelFormatter setDateFormat:@"MM/dd"];
        labelFormatter.timeZone = [NSTimeZone timeZoneWithName:@"GMT"];
        CPTPlotSpaceAnnotation *dateAnnotation;
        for(long labelDate = firstMidnight; labelDate <= lastMidnight; labelDate = labelDate + (60*60*24))
        {
            if((double)labelDate >= minXrange && labelDate <= (double)(maxXrange)){
                stringFromDate = [labelFormatter stringFromDate:[NSDate dateWithTimeIntervalSince1970:labelDate]];
                dateStringStyle = [CPTMutableTextStyle textStyle];
                dateStringStyle.color	= [CPTColor redColor];
                dateStringStyle.fontSize = round(bounds.size.height / (CGFloat)30.0);
                dateStringStyle.fontName = @"Courier";
            
                // Determine point of symbol in plot coordinates
                dateAnnotationPoint = [NSArray arrayWithObjects:[NSDecimalNumber numberWithLong:labelDate],[NSDecimalNumber decimalNumberWithDecimal: yRange.location], nil];
            
                textLayer = [[CPTTextLayer alloc] initWithText:stringFromDate style:dateStringStyle];
                dateAnnotation = [[CPTPlotSpaceAnnotation alloc] initWithPlotSpace:graph.defaultPlotSpace   anchorPlotPoint:dateAnnotationPoint];
                dateAnnotation.contentLayer = textLayer;
                dateAnnotation.displacement =  CGPointMake( 0.0f,(CGFloat)10.0 );     
                [graph.plotAreaFrame.plotArea addAnnotation:dateAnnotation];
                [dateAnnotationArray addObject:dateAnnotation];
            }
        }
    }
}

-(void)zoomOut
{
	// now adjust the plot range
    [plotSpace0 setXRange:xRangeZoomOut];
	[plotSpace0 setYRange:yRange0ZoomOut];

    [overlayPlotSpace setXRange:[xRangeZoomOut copy]];
    
    [plotSpace1 setXRange:xRangeZoomOut];
    [plotSpace1 setYRange:yRange1ZoomOut];
    
    [plotSpace2 setXRange:xRangeZoomOut];
    [plotSpace2 setYRange:yRange2ZoomOut]; 
    
    BOOL dateAnnotateRequired = [self fixUpXAxisLabelsForLayerIndex:0 
                                           AndDataView:dataView];
 
    while([dateAnnotationArray count] > 0){
        [graph.plotAreaFrame.plotArea removeAnnotation:[dateAnnotationArray objectAtIndex:0]];
        [dateAnnotationArray removeObjectAtIndex:0];
    }
    if(dateAnnotateRequired){
        long firstMidnight = [EpochTime epochTimeAtZeroHour:minXrangeForPlot];
        long lastMidnight = [EpochTime epochTimeNextDayAtZeroHour:maxXrangeForPlot];
        
        CPTPlotRange *xRange  = [overlayPlotSpace xRange];
        CPTPlotRange *yRange = [overlayPlotSpace yRange];
        double minXrange = [[NSDecimalNumber decimalNumberWithDecimal:xRange.location] doubleValue];
        double maxXrange = [[NSDecimalNumber decimalNumberWithDecimal:xRange.location] doubleValue] + [[NSDecimalNumber decimalNumberWithDecimal:xRange.length] doubleValue];
        CGRect bounds = NSRectToCGRect(hostingView.bounds);
        
        NSString *stringFromDate;
        CPTMutableTextStyle *dateStringStyle;
        NSArray *dateAnnotationPoint;
        CPTTextLayer *textLayer;
        NSDateFormatter *labelFormatter = [[NSDateFormatter alloc] init] ;
        [labelFormatter setDateFormat:@"MM/dd"];
        labelFormatter.timeZone = [NSTimeZone timeZoneWithName:@"GMT"];
        CPTPlotSpaceAnnotation *dateAnnotation;
        for(long labelDate = firstMidnight; labelDate <= lastMidnight; labelDate = labelDate + (60*60*24))
        {
            if((double)labelDate >= minXrange && labelDate <= (double)(maxXrange)){
                stringFromDate = [labelFormatter stringFromDate:[NSDate dateWithTimeIntervalSince1970:labelDate]];
                dateStringStyle = [CPTMutableTextStyle textStyle];
                dateStringStyle.color	= [CPTColor redColor];
                dateStringStyle.fontSize = round(bounds.size.height / (CGFloat)30.0);
                dateStringStyle.fontName = @"Courier";
                
                // Determine point of symbol in plot coordinates
                dateAnnotationPoint = [NSArray arrayWithObjects:[NSDecimalNumber numberWithLong:labelDate],[NSDecimalNumber decimalNumberWithDecimal: yRange.location], nil];
                
                textLayer = [[CPTTextLayer alloc] initWithText:stringFromDate style:dateStringStyle];
                dateAnnotation = [[CPTPlotSpaceAnnotation alloc] initWithPlotSpace:graph.defaultPlotSpace   anchorPlotPoint:dateAnnotationPoint];
                dateAnnotation.contentLayer = textLayer;
                dateAnnotation.displacement =  CGPointMake( 0.0f,(CGFloat)10.0 );     
                [graph.plotAreaFrame.plotArea addAnnotation:dateAnnotation];
                [dateAnnotationArray addObject:dateAnnotation];
            }
        }
    }
    //This is for any horizontal lines that have been added
    if([lineAnnotationArray count] > 0){
        NSMutableArray *tempArray = [[NSMutableArray alloc] init];
        for(int i = 0; i < [lineAnnotationLevelArray count]; i++){
            [graph.plotAreaFrame.plotArea removeAnnotation:[lineAnnotationArray objectAtIndex:i]];
            [tempArray addObject:[NSNumber numberWithDouble:[[lineAnnotationLevelArray objectAtIndex:i] doubleValue]]];
        }
        [lineAnnotationArray removeAllObjects];
        [lineAnnotationLevelArray removeAllObjects];
        for(int i = 0; i < [tempArray count]; i++){
            [self addHorizontalLineAt:[[tempArray objectAtIndex:i] doubleValue] ForPlotspace:plotSpace0];
        }
        [tempArray removeAllObjects];
    }

        
    zoomedOut = YES;
}

@synthesize hostingView;
//@synthesize graphs;
@synthesize identifier;
@synthesize plotData;
@synthesize dataView;
@end
