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

-(void)setDelegate:(id)del
{
    delegate = del;
}

-(id)delegate 
{ 
    return delegate;
};

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


-(void)initialGraph
{
   	CGRect bounds = NSRectToCGRect(hostingView.bounds);
    CPTGraph *graph = [[CPTXYGraph alloc] initWithFrame:bounds];
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


-(void)renderPlotWithFields: (NSArray *) timeSeriesLines 
{
	CGRect bounds = NSRectToCGRect(hostingView.bounds);
    
	CPTGraph *graph = [[CPTXYGraph alloc] initWithFrame:bounds];

    hostingView.hostedGraph = graph;
    [graph applyTheme:[CPTTheme themeNamed:kCPTDarkGradientTheme]];
    [graph setPaddingLeft:0];
	[graph setPaddingTop:0];
	[graph setPaddingRight:0];
	[graph setPaddingBottom:0];
    graph.plotAreaFrame.borderLineStyle = nil;
    
    graph.cornerRadius = 0.0; 
    //graph.shadowRadius = 0.0; 
    
    NSMutableArray *fieldNames = [[NSMutableArray alloc] init];
    NSMutableArray *colors = [[NSMutableArray alloc] init];
    for(TimeSeriesLine *tsLine in timeSeriesLines)
    {
        if([tsLine visible]){
            [fieldNames addObject:[tsLine name]];
            [colors addObject:[tsLine cpColour]];
        }
    }
    

    if(([dataView countForPlot] < 3) || ([fieldNames count]==0) ){
        if([dataView countForPlot] < 3)
        {
            graph.title = @"No Data";
        }else{
            graph.title = @"No Timeseries";
        }
        CPTMutableTextStyle *textStyle = [CPTMutableTextStyle textStyle];
        textStyle.color				   = [CPTColor grayColor];
        textStyle.fontName			   = @"Helvetica-Bold";
        textStyle.fontSize			   = round(bounds.size.height / (CGFloat)12.0);
        graph.titleTextStyle		   = textStyle;
        graph.titleDisplacement		   = CGPointMake( 0.0f, round(bounds.size.height / (CGFloat)18.0) ); 
        graph.titlePlotAreaFrameAnchor = CPTRectAnchorCenter;
    }else{
        
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

        // Axes
        double minYdataForPlot, maxYdataForPlot;
               minYdataForPlot = [[[dataView minYvalues] valueForKey:[fieldNames objectAtIndex:0]] doubleValue];
        maxYdataForPlot = [[[dataView maxYvalues] valueForKey:[fieldNames objectAtIndex:0]] doubleValue]; 
        for (NSString *fieldname in fieldNames) {
            minYdataForPlot = fmin(minYdataForPlot,[[[dataView minYvalues] valueForKey:fieldname] doubleValue]); 
            maxYdataForPlot = fmax(maxYdataForPlot,[[[dataView maxYvalues] valueForKey:fieldname] doubleValue]); 
        }
    
        double majorIntervalY;
        if(((maxYdataForPlot-minYdataForPlot)/[plotData pipSize])>10000)
        {
            // Then forget about pipsize related Y axis just go for about 10
            //This needs to be fixed
            majorIntervalY = ((int)(maxYdataForPlot-minYdataForPlot))/10;  
        }else{
            majorIntervalY = 10 * [plotData pipSize];
        }
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
        dateFormatter.timeZone = [NSTimeZone timeZoneWithName:@"GMT"];
        // If it more than 3 days, major tic is 1 day, otherwise a major tic is 6 hours
        long minXdataForPlot, maxXdataForPlot;
        BOOL dateIsSpecifiedInAxis = NO;
        minXdataForPlot = [dataView firstX];
        maxXdataForPlot = [dataView lastX];;
        
        if(((float)(maxXdataForPlot - minXdataForPlot)/(21*60 * 60 * 24))>1){
            x.majorIntervalLength		  = CPTDecimalFromInt(7 * 24 * 60 * 60); // 7 Day
            x.minorTicksPerInterval		  = 6;
            //dateFormatter.dateStyle = kCFDateFormatterShortStyle;
            [dateFormatter setDateFormat:@"MM/dd"];
            dateIsSpecifiedInAxis = TRUE;
        }else{
            //If greater than 3 days
            if(((float)(maxXdataForPlot - minXdataForPlot)/(3*60 * 60 * 24))>1){
                x.majorIntervalLength		  = CPTDecimalFromInt(24 * 60 * 60); // 1 Day
                x.minorTicksPerInterval		  = 5;
                //dateFormatter.dateStyle = kCFDateFormatterShortStyle;
                [dateFormatter setDateFormat:@"MM/dd"];
                dateIsSpecifiedInAxis = TRUE;
            }else{
                //If greater than 12 hours
                if(((float)(maxXdataForPlot - minXdataForPlot)/(60 * 60 * 12))>1){
                    x.majorIntervalLength		  = CPTDecimalFromInt(4 * 60 * 60); // 4 hours
                    x.minorTicksPerInterval		  = 3;
                    dateFormatter.dateStyle = kCFDateFormatterNoStyle;
                    dateFormatter.timeStyle = kCFDateFormatterShortStyle;
                }else{
                    //If less than 12 hours
                    if(((float)(maxXdataForPlot - minXdataForPlot)/(60 * 60 * 12))<=1){
                        x.majorIntervalLength = CPTDecimalFromInt(60 * 60); // 1 hours
                        x.minorTicksPerInterval = 5;
                        dateFormatter.dateStyle = kCFDateFormatterNoStyle;
                        dateFormatter.timeStyle = kCFDateFormatterShortStyle;
                    }
                }   
            }
        }
            // America/New_York
            // Europe/London
            // Europe/Paris
            // Asia/Tokyo
        
        x.orthogonalCoordinateDecimal = CPTDecimalFromDouble(xAxisYValue);
        //x.minorTicksPerInterval		  = 3;
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
    
    
        //Annotation of dates ///////////////////////////////////////////
        if(!dateIsSpecifiedInAxis)
        {
            long firstMidnight = [EpochTime epochTimeAtZeroHour:minXdataForPlot];
            long lastMidnight = [EpochTime epochTimeNextDayAtZeroHour:maxXdataForPlot];
    
            NSString *stringFromDate;
            CPTMutableTextStyle *dateStringStyle;
            NSArray *dateAnnotationPoint;
            CPTTextLayer *textLayer;
            CPTPlotSpaceAnnotation *dateAnnotation;
            NSDateFormatter *labelFormatter = [[NSDateFormatter alloc] init] ;
            [labelFormatter setDateFormat:@"MM/dd"];
            labelFormatter.timeZone = [NSTimeZone timeZoneWithName:@"GMT"];
            for(long labelDate = firstMidnight; labelDate <= lastMidnight; labelDate = labelDate + (60*60*24))
            {
                stringFromDate = [labelFormatter stringFromDate:[NSDate dateWithTimeIntervalSince1970:labelDate]];
                dateStringStyle = [CPTMutableTextStyle textStyle];
                dateStringStyle.color	= [CPTColor redColor];
                dateStringStyle.fontSize = round(bounds.size.height / (CGFloat)30.0);
                dateStringStyle.fontName = @"Courier";
            
                // Determine point of symbol in plot coordinates
                dateAnnotationPoint = [NSArray arrayWithObjects:[NSDecimalNumber numberWithLong:labelDate],[NSDecimalNumber numberWithDouble:xAxisYValue], nil];
    
                textLayer = [[CPTTextLayer alloc] initWithText:stringFromDate style:dateStringStyle];
                dateAnnotation = [[CPTPlotSpaceAnnotation alloc] initWithPlotSpace:graph.defaultPlotSpace anchorPlotPoint:dateAnnotationPoint];
                dateAnnotation.contentLayer = textLayer;
                dateAnnotation.displacement =  CGPointMake( 0.0f,(CGFloat)10.0 );     
                [graph.plotAreaFrame.plotArea addAnnotation:dateAnnotation];
            }
        }
        //////////////////////////////////////////////////////////////////////
    
    
        // Set axes
        graph.axisSet.axes = [NSArray arrayWithObjects:x, y, nil];
    
        // Create a plot that uses the data source method
        CPTScatterPlot *dataSourceLinePlot = [[CPTScatterPlot alloc] init];
        dataSourceLinePlot.identifier = [fieldNames objectAtIndex:0];
    
        CPTMutableLineStyle *lineStyle = [dataSourceLinePlot.dataLineStyle mutableCopy];
        lineStyle.lineWidth				 = 1.0;
        lineStyle.lineColor				 = [colors objectAtIndex:0];
        dataSourceLinePlot.dataLineStyle = lineStyle;
        dataSourceLinePlot.dataSource =  dataView;
        [graph addPlot:dataSourceLinePlot];
    
        if([fieldNames count] > 1)
        {
            for(int i =1; i < [fieldNames count]; i++){
                // Create a plot that uses the data source method
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
        
        // Extend the ranges for neatness
        [plotSpace scaleToFitPlots:[NSArray arrayWithObjects:dataSourceLinePlot, nil]];
        CPTMutablePlotRange *xRange = [plotSpace.xRange mutableCopy];
        CPTMutablePlotRange *yRange = [plotSpace.yRange mutableCopy];
        [xRange expandRangeByFactor:CPTDecimalFromDouble(1.2)];
        [yRange expandRangeByFactor:CPTDecimalFromDouble(1.2)];

        CPTPlotRange *plotRangeForY  = [CPTPlotRange plotRangeWithLocation:CPTDecimalFromDouble(yAxisMin) length:CPTDecimalFromDouble(yAxisLength)];
       
        plotSpace.xRange = xRange;
        plotSpace.yRange = plotRangeForY;
        plotSpace.globalYRange = 0;
        
        if([timeSeriesLines count] > 5){
            CPTXYPlotSpace *secondPlotSpace = [[CPTXYPlotSpace alloc] init];
            [graph addPlotSpace:secondPlotSpace];
                        
            dataSourceLinePlot = [[CPTScatterPlot alloc] init];
            dataSourceLinePlot.identifier = @"POSITION";
            lineStyle = [dataSourceLinePlot.dataLineStyle mutableCopy];
            lineStyle.lineWidth				 = 1.0;
            lineStyle.lineColor				 = [CPTColor redColor] ;
            dataSourceLinePlot.dataLineStyle = lineStyle;
            dataSourceLinePlot.dataSource =  dataView;
            [graph addPlot:dataSourceLinePlot toPlotSpace:secondPlotSpace];
            //[secondPlotSpace scaleToFitPlots:[NSArray arrayWithObjects:dataSourceLinePlot, nil]];
            //CPTMutablePlotRange *yRange = [secondPlotSpace.yRange mutableCopy];
           //[yRange expandRangeByFactor:CPTDecimalFromDouble(1.2)];
            
            secondPlotSpace.xRange = [plotSpace.xRange copy];

            long minY = [[[dataView minYvalues] objectForKey:@"POSITION"] longValue];
            long maxY = [[[dataView maxYvalues] objectForKey:@"POSITION"] longValue];
            long span = maxY-minY;
            secondPlotSpace.yRange = [CPTPlotRange plotRangeWithLocation:[[NSNumber numberWithDouble:minY-10000] decimalValue] length:[[NSNumber numberWithDouble:span+(2*10000) ] decimalValue]];
            
                                
                                //            CPTPlotRange *plotRangeForY  = [CPTPlotRange plotRangeWithLocation:CPTDecimalFromDouble(yAxisMin) length:CPTDecimalFromDouble(yAxisLength)];
        }
    }
}

#pragma mark -
#pragma mark Plot Space Delegate Methods

-(CPTPlotRange *)plotSpace:(CPTPlotSpace *)space willChangePlotRangeTo:(CPTPlotRange *)newRange forCoordinate:(CPTCoordinate)coordinate
{
	// Impose a limit on how far user can scroll in x
	if ( coordinate == CPTCoordinateX ) {
        long minXdataForPlot, maxXdataForPlot;
        minXdataForPlot = [dataView firstX];
        maxXdataForPlot = [dataView lastX];
        
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
        minYdataForPlot = [dataView firstX];
        maxYdataForPlot = [dataView lastX]; 
        for (NSString *fieldname in fieldnames) {
            minYdataForPlot = fmin(minYdataForPlot,[[[dataView minYvalues] valueForKey:fieldname] doubleValue]); 
            maxYdataForPlot = fmax(maxYdataForPlot,[[[dataView maxYvalues] valueForKey:fieldname] doubleValue]); 
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



//-(BOOL)plotSpace:(CPTXYPlotSpace *)space shouldHandlePointingDeviceUpEvent:(id)event atPoint:(CGPoint)point{
//    NSLog(@"point.x=%lf,point.y=%lf",point.x,point.y);
//    return YES;
//}
//
//-(BOOL)plotSpace:(CPTXYPlotSpace *)space shouldHandlePointingDeviceCancelledEvent:(id)event{
//    //NSLog(@"point.x=%lf,point.y=%lf",point.x,point.y);
//    return YES;
//}

-(BOOL)plotSpace:(CPTXYPlotSpace *)space shouldHandlePointingDeviceDownEvent:(id)event atPoint:(CGPoint)point{
    NSLog(@"point.x=%lf,point.y=%lf",point.x,point.y);
    NSDecimal dataCoordinates[2];
    
    [space plotPoint:dataCoordinates forPlotAreaViewPoint:point];
    
    NSDecimalNumber *dateTimeNumber = [NSDecimalNumber decimalNumberWithDecimal:dataCoordinates[0]];
    long dateTime = [dateTimeNumber longValue];                                     
 
    NSDecimalNumber *dataNumber = [NSDecimalNumber decimalNumberWithDecimal:dataCoordinates[1]];
    double dataValue = [dataNumber doubleValue];

    NSLog(@"point.x=%ld,point.y=%5.2f",dateTime,dataValue);
    
    
    if([[self delegate] respondsToSelector:@selector(sendGraphClickDateTimeValue:)])
    {
        [[self delegate] sendGraphClickDateTimeValue:dateTime]; 
    }else{
        NSLog(@"Delegate not responding to \'addSimulationDataToResultsTableView\'"); 
    }

    
    
    return YES;
}


//-(BOOL)plotSpace:(CPTXYPlotSpace *)space shouldHandlePointingDeviceDraggedEvent:(id)event atPoint:(CGPoint)point{
//    NSLog(@"point.x=%lf,point.y=%lf",point.x,point.y);
//    return YES;
//}

@end
