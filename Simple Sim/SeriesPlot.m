//
//  SimpleScatterPlot.m
//  CorePlotGallery
//

#import "SeriesPlot.h"
#import "DataView.h"
#import "EpochTime.h"
#import "TimeSeriesLine.h"
#import "SeriesPlotDataWrapper.h"

@interface SeriesPlot() 
- (BOOL) fixUpXAxisLabelsFrom: (long) minX
                           To: (long) maxX;
//- (BOOL) fixUpXAxisLabels;
- (void) fixUpYAxisForLayerIndex: (int) layerIndex;
//- (void) zoomInAndFitYAxis:(BOOL) fitYAxis;
- (void) zoomIn;
- (void) zoomOut;
- (void) addHorizontalLineAt:(double) yValue 
                ForPlotspace:(CPTXYPlotSpace *) plotSpace;
- (double) niceNumber: (double) x withRounding:(BOOL) doRounding;

@property (retain) CPTXYGraph *graph;
@property double minYrangeForPlot0;
@property double maxYrangeForPlot0;
@property double minYrangeForPlot1;
@property double maxYrangeForPlot1;
@property double minYrangeForPlot2;
@property double maxYrangeForPlot2;
@property BOOL plot1AxisVisible;
@property BOOL plot2AxisVisible;
@property (retain) CPTXYPlotSpace *plotSpace0;
@property (retain) CPTXYPlotSpace *plotSpace1;
@property (retain) CPTXYPlotSpace *plotSpace2;
@property (retain) CPTXYPlotSpace *shortLongPlotSpace;
@property (retain) CPTXYAxis *xAxis0;
@property (retain) CPTXYAxis *yAxis0;
@property (retain) CPTXYAxis *yAxis1;
@property (retain) CPTXYAxis *yAxis2;
@property (retain) CPTPlotSpaceAnnotation *clickDateAnnotation;
@property (retain) CPTPlotSpaceAnnotation *dragDateAnnotation;
@property (retain) CPTPlotSpaceAnnotation *zoomAnnotation;
@property (retain) CPTPlotSpaceAnnotation *lineAnnotation;
@property (retain) NSMutableArray *lineAnnotationArray;
@property (retain) NSMutableArray *lineAnnotationLevelArray;
@property (retain) CPTLayer *interactionLayer;
@property (retain) NSMutableArray *dateAnnotationArray;
@property CGPoint dragStart;
@property CGPoint dragEnd;
@end

@implementation SeriesPlot

-(id)init
{
    return [self initWithIdentifier:@"No identifier"];
}

-(id)initWithIdentifier:(NSString*) identifierString
{
	if ( (self = [super init]) ) {
		_identifier = identifierString;
        _dateAnnotationArray = [[NSMutableArray alloc] init];
        _lineAnnotationArray = [[NSMutableArray alloc] init];
        _lineAnnotationLevelArray = [[NSMutableArray alloc] init];
	}
 	return self;
}

//-(void)setData: (SimDataCombi *) newData
//  WithViewName: (NSString *) viewName;
//{
//    [self setPlotData:newData];
//    [self setDataView:[newData getDataViewForKey:viewName]];
//}

-(void)initialGraphAndAddAnnotation: (BOOL) doAnnotation
{
   	CGRect bounds = NSRectToCGRect([[self hostingView] bounds]);
    [self setGraph:[[CPTXYGraph alloc] initWithFrame:bounds]];
	[[self hostingView] setHostedGraph:[self graph]];
    
    [[self graph] applyTheme:[CPTTheme themeNamed:kCPTDarkGradientTheme]];
   
    [[self graph] setPaddingLeft:0.0];
	[[self graph] setPaddingTop:0.0];
	[[self graph] setPaddingRight:0.0];
    [[self graph] setPaddingBottom:0.0];
    
	[[[[self graph] plotAreaFrame] plotArea] setFill:[[[self graph] plotAreaFrame] fill]];
    [[[self graph] plotAreaFrame] setFill:nil];
    
    [[[self graph] plotAreaFrame] setBorderLineStyle:nil];
    [[[self graph] plotAreaFrame] setCornerRadius:0.0];
    
    CPTMutableLineStyle *majorGridLineStyle = [CPTMutableLineStyle lineStyle];
    majorGridLineStyle.lineWidth = 0.75;
    majorGridLineStyle.lineColor = [[CPTColor colorWithGenericGray:0.2] colorWithAlphaComponent:0.75];
    
    CPTMutableLineStyle *minorGridLineStyle = [CPTMutableLineStyle lineStyle];
    minorGridLineStyle.lineWidth = 0.25;
    minorGridLineStyle.lineColor = [[CPTColor whiteColor] colorWithAlphaComponent:0.1];

    CPTXYAxisSet *axisSet = (CPTXYAxisSet *)[[self graph] axisSet];
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
        CPTPlotSpaceAnnotation *mainTitleAnnotation = [[CPTPlotSpaceAnnotation alloc] initWithPlotSpace:[[self graph] defaultPlotSpace] anchorPlotPoint:anchorPoint];
        mainTitleAnnotation.contentLayer = textLayer;
        mainTitleAnnotation.displacement =  CGPointMake( 0.0f, round(bounds.size.height / (CGFloat)8.0) ); //CGPointMake(0.0f, 20.0f);
        [[[[self graph] plotAreaFrame] plotArea] addAnnotation:mainTitleAnnotation];
    
    
        NSString *subString = @"2012, O'Connor Research";
        CPTMutableTextStyle *subStringStyle = [CPTMutableTextStyle textStyle];
        subStringStyle.color	= [CPTColor grayColor];
        subStringStyle.fontSize = 12.0f;
        subStringStyle.fontName = @"Courier";
    
        textLayer = [[CPTTextLayer alloc] initWithText:subString style:subStringStyle];
        CPTPlotSpaceAnnotation *subTitleAnnotation = [[CPTPlotSpaceAnnotation alloc] initWithPlotSpace:[[self graph] defaultPlotSpace] anchorPlotPoint:anchorPoint];
        subTitleAnnotation.contentLayer = textLayer;
        [[[[self graph] plotAreaFrame] plotArea] addAnnotation:subTitleAnnotation];
    }else{
        axisSet.xAxis.majorGridLineStyle = majorGridLineStyle;
        axisSet.yAxis.majorGridLineStyle = majorGridLineStyle;
        axisSet.xAxis.minorGridLineStyle = minorGridLineStyle;
        axisSet.yAxis.minorGridLineStyle = minorGridLineStyle;
    }
}

-(void)leftSideExpand
{
    [[[self graph] plotAreaFrame] setPaddingLeft:[[[self graph] plotAreaFrame] paddingLeft] + 5];

}

-(void)leftSideContract
{
    [[[self graph] plotAreaFrame] setPaddingLeft:[[[self graph] plotAreaFrame] paddingLeft] - 5];
    
}

-(void)bottomExpand
{
    [[[self graph] plotAreaFrame ] setPaddingBottom:[[[self graph] plotAreaFrame] paddingBottom] + 5];
}

-(void)bottomContract
{
    [[[self graph] plotAreaFrame] setPaddingBottom:[[[self graph] plotAreaFrame] paddingBottom] - 5];
}


-(void)rightSideExpand
{
    [[[self graph] plotAreaFrame] setPaddingRight:[[[self graph] plotAreaFrame] paddingRight] + 5];
    
}

-(void)rightSideContract
{
    [[[self graph ] plotAreaFrame] setPaddingRight:[[[self graph] plotAreaFrame] paddingRight] - 5];
    
}

-(void)topExpand
{
    [[[self graph] plotAreaFrame] setPaddingTop:[[[self graph] plotAreaFrame] paddingTop] + 5];
}

-(void)topContract
{
    [[[self graph] plotAreaFrame] setPaddingTop:[[[self graph] plotAreaFrame] paddingTop] - 5];
}

-(void)removeLineAnnotation
{
    while([[self lineAnnotationArray] count] > 0){
        [[[[self graph] plotAreaFrame  ]plotArea] removeAnnotation:[[self lineAnnotationArray] objectAtIndex:0]];
        [[self lineAnnotationArray] removeObjectAtIndex:0];
        [[self lineAnnotationLevelArray] removeObjectAtIndex:0];
    }
}


//-(void)renderPlotWithFields: (NSArray *) linesToPlot
//{
//    // Make sure there are no annotations 
//    [self setClickDateAnnotation:nil];
//    [self setDragDateAnnotation:nil];
//    [self setZoomAnnotation:nil];
//    [[self dateAnnotationArray] removeAllObjects];
//    [[self lineAnnotationArray] removeAllObjects];
//    [[self lineAnnotationLevelArray] removeAllObjects];
//    
//    BOOL dateAnnotateRequired;
//    [self setTimeSeriesLines:linesToPlot];
//    CGRect bounds = NSRectToCGRect([[self hostingView] bounds]);
//    [self setGraph:[[CPTXYGraph alloc] initWithFrame:bounds]];
//    
//	CPTTheme *theme = [CPTTheme themeNamed:kCPTDarkGradientTheme];
//	[[self graph] applyTheme:theme];
//    [[self hostingView] setHostedGraph:[self graph]];
//    
//	[[self graph] setPaddingLeft:0.0];
//	[[self graph] setPaddingTop:0.0];
//    [[self graph] setPaddingRight:0.0];
//    [[self graph] setPaddingBottom:0.0];
//    
//	[[[self graph] plotAreaFrame] setPaddingLeft:60.0];
//	[[[self graph] plotAreaFrame  ] setPaddingTop:30.0];
//	[[[self graph] plotAreaFrame] setPaddingRight:30.0];
//	[[[self graph] plotAreaFrame] setPaddingBottom:60.0];
//    
//	[[[[self graph] plotAreaFrame ] plotArea] setFill:[[[self graph] plotAreaFrame] fill]];
//	[[[self graph] plotAreaFrame] setFill:nil];
//    
//	[[[self graph] plotAreaFrame] setBorderLineStyle:nil];
//    [[[self graph] plotAreaFrame] setCornerRadius:0.0];
//
//    BOOL plot0LineFound = NO; 
//    BOOL plot1LineFound = NO;
//    BOOL plot2LineFound = NO;
//    
//    NSMutableArray *fieldNames = [[NSMutableArray alloc] init];
//    NSMutableArray *colors = [[NSMutableArray alloc] init];
//    NSMutableArray *layerIndexes = [[NSMutableArray alloc] init];
//    [self setMinYrangeForPlot0:0.0];
//    [self setMaxYrangeForPlot0:1.0];
//    [self setMinYrangeForPlot1:0.0];
//    [self setMaxYrangeForPlot1:1.0];
//    [self setMinYrangeForPlot2:0.0];
//    [self setMaxYrangeForPlot2:1.0];
//    
//    for(TimeSeriesLine *tsLine in [self timeSeriesLines])
//    {
//        switch ([tsLine layerIndex])
//        {
//                
//            case 0:
//                [fieldNames addObject:[tsLine name]];
//                [colors addObject:[tsLine cpColour]];
//                [layerIndexes addObject:[NSNumber numberWithInt:[tsLine layerIndex]]];
//                if(plot0LineFound){
//                    [self setMinYrangeForPlot0:fmin([self minYrangeForPlot0],[[[[self dataView] minYvalues] valueForKey:[tsLine name]] doubleValue])];
//                    [self setMaxYrangeForPlot0:fmax([self maxYrangeForPlot0],[[[[self dataView] maxYvalues] valueForKey:[tsLine name]] doubleValue])];
//                }else{
//                    [self setMinYrangeForPlot0:[[[[self dataView] minYvalues] valueForKey:[tsLine name]] doubleValue]];
//                     [self setMaxYrangeForPlot0:[[[[self dataView] maxYvalues] valueForKey:[tsLine name]] doubleValue]];
//                    plot0LineFound =YES;
//                }
//                if([self maxYrangeForPlot0] < [self minYrangeForPlot0]){
//                    [NSException raise:@"Problem with Plot Range" format:@"min = %f, max = %f", [self minYrangeForPlot0], [self maxYrangeForPlot0]];
//                }
//                break;
//            case 1:
//                [fieldNames addObject:[tsLine name]];
//                [colors addObject:[tsLine cpColour]];
//                [layerIndexes addObject:[NSNumber numberWithInt:[tsLine layerIndex]]];
//                if(plot1LineFound == NO){
//                    [self setMinYrangeForPlot1:[[[[self dataView] minYvalues] valueForKey:[tsLine name]] doubleValue]];
//                     [self setMaxYrangeForPlot1:[[[[self dataView] maxYvalues] valueForKey:[tsLine name]] doubleValue]];
//                }else{
//                    [self setMinYrangeForPlot1:fmin([self minYrangeForPlot1],[[[[self dataView] minYvalues] valueForKey:[tsLine name]] doubleValue])];
//                    [self setMaxYrangeForPlot1:fmax([self maxYrangeForPlot1],[[[[self dataView] maxYvalues] valueForKey:[tsLine name]] doubleValue])];
//                    
//                }
//                plot1LineFound = YES;
//                if([self maxYrangeForPlot1] < [self minYrangeForPlot1]){
//                    [NSException raise:@"Problem with Plot Range" format:@"min = %f, max = %f", [self minYrangeForPlot1], [self maxYrangeForPlot1]];
//                }
//                
//                break;
//            case 2:
//                [fieldNames addObject:[tsLine name]];
//                [colors addObject:[tsLine cpColour]];
//                [layerIndexes addObject:[NSNumber numberWithInt:[tsLine layerIndex]]];
//                if(plot2LineFound == NO){
//                    [self setMinYrangeForPlot2:[[[[self dataView] minYvalues] valueForKey:[tsLine name]] doubleValue]];
//                     [self setMaxYrangeForPlot2:[[[[self dataView] maxYvalues] valueForKey:[tsLine name]] doubleValue]];
//                }else{
//                    [self setMinYrangeForPlot2:fmin([self minYrangeForPlot2],[[[[self dataView] minYvalues] valueForKey:[tsLine name]] doubleValue])];
//                    [self setMaxYrangeForPlot2:fmax([self maxYrangeForPlot2],[[[[self dataView] maxYvalues] valueForKey:[tsLine name]] doubleValue])];
//                    
//                }
//                plot2LineFound = YES;
//                if([self maxYrangeForPlot2] < [self minYrangeForPlot2]){
//                    [NSException raise:@"Problem with Plot Range" format:@"min = %f, max = %f", [self minYrangeForPlot2], [self maxYrangeForPlot2]];
//                }
//                break;
//            default:
//                [fieldNames addObject:[tsLine name]];
//                [colors addObject:[CPTColor clearColor]];
//                [layerIndexes addObject:[NSNumber numberWithInt:[tsLine layerIndex]]];
//                break;
//        }
//    }
//   
//    CPTXYAxisSet *axisSet = (CPTXYAxisSet *)[[self graph] axisSet];
//    [self setXAxis0:[axisSet xAxis]];
//    [self setYAxis0:[axisSet yAxis]];
//    [self setPlotSpace0:(CPTXYPlotSpace *)[[self graph] defaultPlotSpace]];
//    dateAnnotateRequired = [self fixUpXAxisLabelsFrom: [[self dataView] minDateTime]
//                                                   To: [[self dataView] maxDateTime]];
//       
//    [self fixUpYAxisForLayerIndex:0];
//    
//    [self setPlot1AxisVisible:NO];
//    [self setPlotSpace1:[[CPTXYPlotSpace alloc] init]];
//    [self setYAxis1:[[CPTXYAxis alloc] init]];
//    [[self yAxis1] setCoordinate:CPTCoordinateY];
//    [[self yAxis1] setPlotSpace:[self plotSpace1]];
//    [[self yAxis1] setMinorTickLineStyle:nil];
//    NSNumberFormatter *axisFormatter = [[NSNumberFormatter alloc] init];
//    [axisFormatter setMaximumFractionDigits:2];                                    
//    CPTMutableTextStyle *yAxisTextStyle = [[CPTMutableTextStyle alloc] init];
//    [yAxisTextStyle setColor:[CPTColor whiteColor]];
//    [[self yAxis1] setLabelTextStyle:yAxisTextStyle];
//    [[self yAxis1] setLabelFormatter:axisFormatter];
//    [[self graph] addPlotSpace:[self plotSpace1]];
//    if(plot1LineFound){
//        [self fixUpYAxisForLayerIndex:1];
//        [self setPlot1AxisVisible:YES];
//    }else{
//        [[self plotSpace1] setYRange:[[[self plotSpace0] yRange] copy]];
//        [self setYRange1ZoomOut:[[[self plotSpace0] yRange] copy]];
//        [self setPlot1AxisVisible:NO];
//    }
//    
//    [self setPlot2AxisVisible:NO];
//    [self setPlotSpace2:[[CPTXYPlotSpace alloc] init]];
//    [self setYAxis2:[[CPTXYAxis alloc] init]];
//    [[self yAxis2] setCoordinate:CPTCoordinateY];
//    [[self yAxis2] setPlotSpace:[self plotSpace2]];
//    [[self yAxis2] setMinorTickLineStyle:nil];
//    axisFormatter = [[NSNumberFormatter alloc] init];
//    [axisFormatter setMaximumFractionDigits:2];   
//    yAxisTextStyle = [[CPTMutableTextStyle alloc] init];
//    [yAxisTextStyle setColor:[CPTColor whiteColor]];
//    [[self yAxis2] setLabelTextStyle:yAxisTextStyle];
//    [[self yAxis2] setLabelFormatter:axisFormatter];
//    [[self graph] addPlotSpace:[self plotSpace2]];
//    if(plot2LineFound){
//        [self fixUpYAxisForLayerIndex:2];
//        [self setPlot2AxisVisible:YES];
//    }else{
//        [[self plotSpace2] setYRange:[[[self plotSpace0] yRange] copy]];
//        [self setYRange2ZoomOut:[[[self plotSpace0] yRange] copy]];
//        [self setPlot2AxisVisible:NO];
//    }
//     
//    double niceXrange = (ceil( (double)([self maxXrangeForPlot] - [self minXrangeForPlot]) / majorIntervalForX ) * majorIntervalForX);
//    CPTMutablePlotRange *xRange;
//    if((niceXrange/([self maxXrangeForPlot] - [self minXrangeForPlot]))>1.1){
//        xRange = [CPTMutablePlotRange plotRangeWithLocation:CPTDecimalFromDouble((double)[self minXrangeForPlot])
//                                                     length:CPTDecimalFromDouble((double)[self maxXrangeForPlot] - [self minXrangeForPlot])];
//    }else{
//        xRange = [CPTMutablePlotRange plotRangeWithLocation:CPTDecimalFromDouble((double)[self minXrangeForPlot])
//                                                     length:CPTDecimalFromDouble(niceXrange)];
//        
//    }
//    
//    [xRange expandRangeByFactor:CPTDecimalFromDouble(1.1)];
//    [[self plotSpace0] setXRange:xRange];
//    [[self plotSpace1] setXRange:[[[self plotSpace0] xRange] copy]];
//    [[self plotSpace2] setXRange:[[[self plotSpace0] xRange] copy]];
//    
//    [self setXRangeZoomOut:xRange];
//    
//    if(dateAnnotateRequired){
//        long firstMidnight = [EpochTime epochTimeAtZeroHour:[self minXrangeForPlot]];
//        long lastMidnight = [EpochTime epochTimeNextDayAtZeroHour:[self maxXrangeForPlot]];
//        
//        CPTPlotRange *xRange  = [[self plotSpace0] xRange];
//        CPTPlotRange *yRange = [[self plotSpace0] yRange];
//        double minXrange = [[NSDecimalNumber decimalNumberWithDecimal:[xRange location]] doubleValue];
//        double maxXrange = [[NSDecimalNumber decimalNumberWithDecimal:[xRange location]] doubleValue] + [[NSDecimalNumber decimalNumberWithDecimal:[xRange length]] doubleValue];
//        
//        CGRect bounds = NSRectToCGRect([[self hostingView] bounds]);
//        
//        NSString *stringFromDate;
//        CPTMutableTextStyle *dateStringStyle;
//        NSArray *dateAnnotationPoint;
//        CPTTextLayer *textLayer;
//        NSDateFormatter *labelFormatter = [[NSDateFormatter alloc] init] ;
//        [labelFormatter setDateFormat:@"MM/dd"];
//        labelFormatter.timeZone = [NSTimeZone timeZoneWithName:@"GMT"];
//        CPTPlotSpaceAnnotation *dateAnnotation;
//        for(long labelDate = firstMidnight; labelDate <= lastMidnight; labelDate = labelDate + (60*60*24))
//        {
//            if((double)labelDate >= minXrange && labelDate <= (double)(maxXrange)){
//                stringFromDate = [labelFormatter stringFromDate:[NSDate dateWithTimeIntervalSince1970:labelDate]];
//                dateStringStyle = [CPTMutableTextStyle textStyle];
//                dateStringStyle.color	= [CPTColor redColor];
//                dateStringStyle.fontSize = round(bounds.size.height / (CGFloat)30.0);
//                dateStringStyle.fontName = @"Courier";
//                
//                // Determine point of symbol in plot coordinates
//                dateAnnotationPoint = [NSArray arrayWithObjects:[NSDecimalNumber numberWithLong:labelDate],[NSDecimalNumber decimalNumberWithDecimal: yRange.location], nil];
//                
//                textLayer = [[CPTTextLayer alloc] initWithText:stringFromDate style:dateStringStyle];
//                dateAnnotation = [[CPTPlotSpaceAnnotation alloc] initWithPlotSpace:[[self graph] defaultPlotSpace]   anchorPlotPoint:dateAnnotationPoint];
//                dateAnnotation.contentLayer = textLayer;
//                dateAnnotation.displacement =  CGPointMake( 0.0f,(CGFloat)10.0 );     
//                [[[[self graph] plotAreaFrame] plotArea] addAnnotation:dateAnnotation];
//                [[self dateAnnotationArray] addObject:dateAnnotation];
//            }
//        }
//    }
//    
//	// this allows the plot to respond to mouse events
//	[[self plotSpace0] setDelegate:self];
//	[[self plotSpace0] setAllowsUserInteraction:YES];
//    
//    // Create a plot that uses the data source method
//    CPTScatterPlot *dataSourceLinePlot;
//    CPTMutableLineStyle *lineStyle;
//    BOOL overlayAdded = NO;
//    
//    if([fieldNames count] > 0)
//    {
//        for(int i =0; i < [fieldNames count]; i++){
//            if([[fieldNames objectAtIndex:i] isEqualToString:@"LONG"] || [[fieldNames objectAtIndex:i] isEqualToString:@"SHORT"]){
//                if(!overlayAdded)
//                {
//                    [self setOverlayPlotSpace:[[CPTXYPlotSpace alloc] init]];
//                    [[self overlayPlotSpace] setIdentifier:@"SHORTLONG"];
//                    [[self graph] addPlotSpace:[self overlayPlotSpace]];
//                    overlayAdded = YES;
//                }
//             
//                if([[fieldNames objectAtIndex:i] isEqualToString:@"SHORT"])
//                {
//                    dataSourceLinePlot = [[CPTScatterPlot alloc] init];
//                    dataSourceLinePlot.identifier = @"P9_SHORT";
//                    lineStyle = [[dataSourceLinePlot dataLineStyle] mutableCopy];
//                    [lineStyle setLineWidth:1.0];
//                    [lineStyle setLineColor:[CPTColor clearColor]];
//                    
//                    CPTColor *areaColor = [CPTColor colorWithComponentRed:1.0 green:0.0 blue:0.0 alpha:0.3];
//                      
//                    [dataSourceLinePlot setAreaFill	:[CPTFill fillWithColor:areaColor]];
//                    [dataSourceLinePlot setAreaBaseValue:CPTDecimalFromDouble(0.0)];
//                    
//                    [dataSourceLinePlot setDataLineStyle:lineStyle];
//                    [dataSourceLinePlot setDataSource:[self dataView]];
//                    [[self graph] addPlot:dataSourceLinePlot toPlotSpace:[self overlayPlotSpace]];
//                    
//                }
//                if([[fieldNames objectAtIndex:i] isEqualToString:@"LONG"])
//                {
//                    dataSourceLinePlot = [[CPTScatterPlot alloc] init];
//                    dataSourceLinePlot.identifier = @"P9_LONG";
//                    lineStyle = [dataSourceLinePlot.dataLineStyle mutableCopy];
//                    [lineStyle setLineWidth:1.0];
//                    [lineStyle setLineColor:[CPTColor clearColor]];
//                    
//                    CPTColor *areaColor		  = [CPTColor colorWithComponentRed:0.0 green:1.0 blue:0.0 alpha:0.3];
//                    [dataSourceLinePlot setAreaFill:[CPTFill fillWithColor:areaColor]];
//                    [dataSourceLinePlot setAreaBaseValue :CPTDecimalFromDouble(0.0)];
//                    [dataSourceLinePlot setDataLineStyle:lineStyle];
//                    [dataSourceLinePlot setDataSource:[self dataView]];
//                    [[self graph] addPlot:dataSourceLinePlot toPlotSpace:[self overlayPlotSpace]];
//                }
//            }else{
//                
//                dataSourceLinePlot = [[CPTScatterPlot alloc] init];
//                dataSourceLinePlot.identifier = [NSString stringWithFormat:@"P0_%@",[fieldNames objectAtIndex:i]];
//                lineStyle = [dataSourceLinePlot.dataLineStyle mutableCopy];
//                lineStyle.lineWidth				 = 1.0;
//                if([[layerIndexes objectAtIndex:i] intValue] == 0){
//                    lineStyle.lineColor = [colors objectAtIndex:(i%[colors count])] ;
//                }else{
//                    lineStyle.lineColor = [CPTColor clearColor];
//                }
//                dataSourceLinePlot.dataLineStyle = lineStyle;
//                dataSourceLinePlot.dataSource =  [self dataView];
//                [[self graph] addPlot:dataSourceLinePlot
//                 toPlotSpace:[self plotSpace0]];
//                
//                dataSourceLinePlot = [[CPTScatterPlot alloc] init];
//                dataSourceLinePlot.identifier = [NSString stringWithFormat:@"P1_%@",[fieldNames objectAtIndex:i]];
//                lineStyle = [dataSourceLinePlot.dataLineStyle mutableCopy];
//                lineStyle.lineWidth				 = 1.0;
//                if([[layerIndexes objectAtIndex:i] intValue] == 1){
//                    lineStyle.lineColor = [colors objectAtIndex:(i%[colors count])] ;
//                }else{
//                    lineStyle.lineColor = [CPTColor clearColor];
//                }
//                [dataSourceLinePlot setDataLineStyle:lineStyle];
//                [dataSourceLinePlot setDataSource:[self dataView]];
//                [[self graph] addPlot:dataSourceLinePlot
//                   toPlotSpace:[self plotSpace1]];
//                
//                dataSourceLinePlot = [[CPTScatterPlot alloc] init];
//                dataSourceLinePlot.identifier = [NSString stringWithFormat:@"P2_%@",[fieldNames objectAtIndex:i]];
//                lineStyle = [dataSourceLinePlot.dataLineStyle mutableCopy];
//                lineStyle.lineWidth				 = 1.0;
//                if([[layerIndexes objectAtIndex:i] intValue] == 2){
//                    lineStyle.lineColor = [colors objectAtIndex:(i%[colors count])] ;
//                }else{
//                    lineStyle.lineColor = [CPTColor clearColor];
//                }
//                dataSourceLinePlot.dataLineStyle = lineStyle;
//                [dataSourceLinePlot setDataSource:[self dataView]];
//                [[self graph] addPlot:dataSourceLinePlot
//                   toPlotSpace:[self plotSpace2]];
//            }
//        }
//    }
//    
//    if(overlayAdded){
//        CPTPlotRange *overlayPlotYRange;
//        overlayPlotYRange = [[CPTPlotRange alloc] initWithLocation:[[NSDecimalNumber numberWithInt:0] decimalValue]  length:[[NSDecimalNumber numberWithInt:1] decimalValue]];
//        CPTMutablePlotRange *xRange =[[[self plotSpace0] xRange] copy];
//        [[self overlayPlotSpace] setXRange:xRange];
//        [[self overlayPlotSpace] setYRange:overlayPlotYRange];
//    }
// 
//    [[[self graph  ] axisSet] setAxes:[NSArray arrayWithObjects:[self xAxis0],[self yAxis0],[self yAxis1],[self yAxis2], nil]];
//    
//	// create the zoom rectangle
//	// first a bordered layer to draw the zoomrect
//	CPTBorderedLayer *zoomRectangleLayer = [[CPTBorderedLayer alloc] initWithFrame:CGRectNull];
//    
//	[lineStyle setLineColor:[CPTColor darkGrayColor]];
//    [lineStyle setLineWidth:1.f];
//    [zoomRectangleLayer setBorderLineStyle:lineStyle];
//    
//	CPTColor *transparentFillColor = [[CPTColor blueColor] colorWithAlphaComponent:0.2];
//	[zoomRectangleLayer setFill:[CPTFill fillWithColor:transparentFillColor]];
//    
//	// now create the annotation layers 
//	[self setZoomAnnotation:[[CPTPlotSpaceAnnotation alloc] initWithPlotSpace:[self plotSpace0] anchorPlotPoint:nil]];
//	[[self zoomAnnotation] setContentLayer:zoomRectangleLayer];
//	[[[[self graph] plotAreaFrame] plotArea] addAnnotation:[self zoomAnnotation]];
//    
//    [self setZoomedOut:YES];
//}

-(void)togglePositionIndicator
{
    CPTPlot * plot;
    plot = [[self graph] plotWithIdentifier:@"S0_L0_SHORT"];
    if([plot dataSource] == nil){
        [plot setDataSource:[self dataSource]];
    }else {
        [plot setDataSource:nil];
    }
    [plot dataNeedsReloading];

    plot = [[plot graph] plotWithIdentifier:@"S0_L0_LONG"];
    if(plot.dataSource == nil){
        [plot setDataSource:[self dataSource]];
    }else {
        plot.dataSource = nil;
    }
    [plot dataNeedsReloading];
}



-(void)setBasicParametersForPlot
{
    // Make sure there are no annotations
    [self setClickDateAnnotation:nil];
    [self setDragDateAnnotation:nil];
    [self setZoomAnnotation:nil];
    [[self dateAnnotationArray] removeAllObjects];
    [[self lineAnnotationArray] removeAllObjects];
    [[self lineAnnotationLevelArray] removeAllObjects];
    [self setInteractionLayer:nil];
    BOOL dateAnnotateRequired;
    
    
    //[self setTimeSeriesLines:linesToPlot];
    CGRect bounds = NSRectToCGRect([[self hostingView] bounds]);
    [self setGraph:[[CPTXYGraph alloc] initWithFrame:bounds]];
    
	CPTTheme *theme = [CPTTheme themeNamed:kCPTDarkGradientTheme];
	[[self graph] applyTheme:theme];
    [[self hostingView] setHostedGraph:[self graph]];
    
	[[self graph] setPaddingLeft:0.0];
	[[self graph] setPaddingTop:0.0];
    [[self graph] setPaddingRight:0.0];
    [[self graph] setPaddingBottom:0.0];
    
	[[[self graph] plotAreaFrame] setPaddingLeft:60.0];
	[[[self graph] plotAreaFrame  ] setPaddingTop:30.0];
	[[[self graph] plotAreaFrame] setPaddingRight:30.0];
	[[[self graph] plotAreaFrame] setPaddingBottom:60.0];
    
	[[[[self graph] plotAreaFrame ] plotArea] setFill:[[[self graph] plotAreaFrame] fill]];
	[[[self graph] plotAreaFrame] setFill:nil];
    
	[[[self graph] plotAreaFrame] setBorderLineStyle:nil];
    [[[self graph] plotAreaFrame] setCornerRadius:0.0];
    
//    BOOL plot0LineFound = NO;
//    BOOL plot1LineFound = NO;
//    BOOL plot2LineFound = NO;
    
//    NSMutableArray *fieldNames = [[NSMutableArray alloc] init];
//    NSMutableArray *colors = [[NSMutableArray alloc] init];
//    NSMutableArray *layerIndexes = [[NSMutableArray alloc] init];
    [self setMinXrangeForPlot:0];
    [self setMaxXrangeForPlot:(31 * 24 * 60 * 60)];
    [self setMinYrangeForPlot0:0.0];
    [self setMaxYrangeForPlot0:1.0];
    [self setMinYrangeForPlot1:0.0];
    [self setMaxYrangeForPlot1:1.0];
    [self setMinYrangeForPlot2:0.0];
    [self setMaxYrangeForPlot2:1.0];
    
       
    CPTXYAxisSet *axisSet = (CPTXYAxisSet *)[[self graph] axisSet];
    [self setXAxis0:[axisSet xAxis]];
    [self setYAxis0:[axisSet yAxis]];
    [self setPlotSpace0:(CPTXYPlotSpace *)[[self graph] defaultPlotSpace]];
    dateAnnotateRequired = [self fixUpXAxisLabels];
    
    [self fixUpYAxisForLayerIndex:0];
    
    [self setPlot1AxisVisible:NO];
    [self setPlotSpace1:[[CPTXYPlotSpace alloc] init]];
    [self setYAxis1:[[CPTXYAxis alloc] init]];
    [[self yAxis1] setCoordinate:CPTCoordinateY];
    [[self yAxis1] setPlotSpace:[self plotSpace1]];
    [[self yAxis1] setMinorTickLineStyle:nil];
    NSNumberFormatter *axisFormatter = [[NSNumberFormatter alloc] init];
    [axisFormatter setMaximumFractionDigits:2];
    CPTMutableTextStyle *yAxisTextStyle = [[CPTMutableTextStyle alloc] init];
    [yAxisTextStyle setColor:[CPTColor whiteColor]];
    [[self yAxis1] setLabelTextStyle:yAxisTextStyle];
    [[self yAxis1] setLabelFormatter:axisFormatter];
    [[self graph] addPlotSpace:[self plotSpace1]];
    
    [[self plotSpace1] setYRange:[[[self plotSpace0] yRange] copy]];
    //[self setYRange1ZoomOut:[[[self plotSpace0] yRange] copy]];
    [self setPlot1AxisVisible:NO];
    
    [self setPlot2AxisVisible: NO];
    [self setPlotSpace2:[[CPTXYPlotSpace alloc] init]];
    [self setYAxis2:[[CPTXYAxis alloc] init]];
    [[self yAxis2] setCoordinate:CPTCoordinateY];
    [[self yAxis2] setPlotSpace:[self plotSpace2]];
    [[self yAxis2] setMinorTickLineStyle:nil];
    axisFormatter = [[NSNumberFormatter alloc] init];
    [axisFormatter setMaximumFractionDigits:2];
    yAxisTextStyle = [[CPTMutableTextStyle alloc] init];
    [yAxisTextStyle setColor:[CPTColor whiteColor]];
    [[self yAxis2] setLabelTextStyle:yAxisTextStyle];
    [[self yAxis2] setLabelFormatter:axisFormatter];
    [[self graph] addPlotSpace:[self plotSpace2]];
    [[self plotSpace2] setYRange:[[[self plotSpace0] yRange] copy]];
    //[self setYRange2ZoomOut:[[[self plotSpace0] yRange] copy]];
    [self setPlot2AxisVisible:NO];
    
    
	// this allows the plot to respond to mouse events
	[[self plotSpace0] setDelegate:self];
	[[self plotSpace0] setAllowsUserInteraction:YES];
    
    [[[self graph] axisSet] setAxes:[NSArray arrayWithObjects:[self xAxis0], [self yAxis0], [self yAxis1], [self yAxis2], nil]];
    
	// create the zoom rectangle
	// first a bordered layer to draw the zoomrect
	CPTBorderedLayer *zoomRectangleLayer = [[CPTBorderedLayer alloc] initWithFrame:CGRectNull];
    
    CPTMutableLineStyle *lineStyle;
    [lineStyle setLineColor:[CPTColor darkGrayColor]];
    [lineStyle setLineWidth:1.f];
    [zoomRectangleLayer setBorderLineStyle:lineStyle];
    
	CPTColor *transparentFillColor = [[CPTColor blueColor] colorWithAlphaComponent:0.2];
	[zoomRectangleLayer setFill:[CPTFill fillWithColor:transparentFillColor]];
    
	// now create the annotation layers
	[self setZoomAnnotation:[[CPTPlotSpaceAnnotation alloc] initWithPlotSpace:[[self graph] defaultPlotSpace] anchorPlotPoint:nil]];
    [[self zoomAnnotation] setContentLayer:zoomRectangleLayer];
	[[[[self graph] plotAreaFrame] plotArea] addAnnotation:[self zoomAnnotation]];
    
    //[self setZoomedOut:YES];
    // Layer to indicate long or short
    [self setShortLongPlotSpace:[[CPTXYPlotSpace alloc] init]];
    [[self shortLongPlotSpace] setIdentifier:@"SHORTLONG"];
    [[self graph] addPlotSpace:[self shortLongPlotSpace]];
}


- (void) updateLines: (SeriesPlotDataWrapper *) dataSource
{
    //Create a plot that uses the data source method
    CPTScatterPlot *dataSourceLinePlot;
    CPTLineStyle *ls;
    CPTMutableLineStyle *lineStyle;
    [self setDataSource:dataSource];
    
    NSDictionary *xyRanges = [dataSource xyRanges];
    
    [self setMinXrangeForPlot: [[xyRanges objectForKey:@"MINX"] longValue]];
    [self setMaxXrangeForPlot: [[xyRanges objectForKey:@"MAXX"] longValue]];
    if([[xyRanges objectForKey:@"PLOT0"] boolValue]){
        [self setMinYrangeForPlot0: [[xyRanges objectForKey:@"MINY0"] doubleValue]];
        [self setMaxYrangeForPlot0: [[xyRanges objectForKey:@"MAXY0"] doubleValue]];
    }
    if([[xyRanges objectForKey:@"PLOT1"] boolValue]){
        [self setMinYrangeForPlot1: [[xyRanges objectForKey:@"MINY1"] doubleValue]];
        [self setMaxYrangeForPlot1: [[xyRanges objectForKey:@"MAXY1"] doubleValue]];
    }
    if([[xyRanges objectForKey:@"PLOT2"] boolValue]){
        [self setMinYrangeForPlot2: [[xyRanges objectForKey:@"MINY2"] doubleValue]];
        [self setMaxYrangeForPlot2: [[xyRanges objectForKey:@"MAXY2"] doubleValue]];
    }
   
    while([[self dateAnnotationArray] count] > 0){
        [[[[self graph] plotAreaFrame  ]plotArea] removeAnnotation:[[self dateAnnotationArray] objectAtIndex:0]];
        [[self dateAnnotationArray] removeObjectAtIndex:0];
    }
    
    
    
    NSDictionary *timeSeriesLinesDictionary = [dataSource timeSeriesLinesDictionary];
    NSArray *lineNames = [timeSeriesLinesDictionary allKeys];
    TimeSeriesLine *tsl;
    NSString *lineName;
    BOOL lineFound = NO, lineDisplayedOK = NO, layer1 = NO, layer2 = NO;
    if([timeSeriesLinesDictionary count] > 0)
    {
        NSMutableArray *linesToRemove = [[NSMutableArray alloc] init];
        if([[[self graph] allPlots] count] > 0){
            for(int i= 0; i < [[[self graph] allPlots] count]; i++){
                if([timeSeriesLinesDictionary objectForKey:[[[[self graph] allPlots] objectAtIndex:i] identifier]] == nil){
                    [linesToRemove addObject:[[[[self graph] allPlots] objectAtIndex:i] identifier]];
                }
            }
            for(int i = 0; i < [linesToRemove count]; i++){
                [[self graph] removePlotWithIdentifier:[linesToRemove objectAtIndex:i]];
            }
        }
        
        for(int i = 0; i < [lineNames count]; i++){
            lineFound = NO;
            lineDisplayedOK = YES;
            lineName = [lineNames objectAtIndex:i];
            tsl = [timeSeriesLinesDictionary objectForKey:lineName];
            //lineName = [NSString stringWithFormat:@"S%ld_L%d_%@",[tsl simId],[tsl layerIndex],[tsl name]];
            
            if([[[self graph] allPlots] count] > 0){
                dataSourceLinePlot = (CPTScatterPlot *)[[self graph] plotWithIdentifier:lineName];
                if(dataSourceLinePlot){
                    lineFound = YES;
                    ls = [dataSourceLinePlot dataLineStyle];
                    switch ([tsl layerIndex]) {
                        case 0:
                            if([dataSourceLinePlot plotSpace] != [self plotSpace0]){
                                lineDisplayedOK = NO;
                            }
                            [self setInteractionLayer:dataSourceLinePlot];
                            break;
                        case 1:
                            if([dataSourceLinePlot plotSpace] != [self plotSpace1]){
                                lineDisplayedOK = NO;
                            }
                            layer1 = YES;
                            break;
                        case 2:
                            if([dataSourceLinePlot plotSpace] != [self plotSpace2]){
                                lineDisplayedOK = NO;
                            }
                            layer2 = YES;
                            break;
                        default:
                            break;
                    }
                    if(lineDisplayedOK){
                        if([tsl cpColour] != [[dataSourceLinePlot dataLineStyle] lineColor])
                        {
                            lineDisplayedOK = NO;
                        }
                    }
                    if(!lineDisplayedOK){
                        [[self graph] removePlot:dataSourceLinePlot];
                    }
                }
            }
            if(!lineFound || !lineDisplayedOK){
                dataSourceLinePlot = [[CPTScatterPlot alloc] init];
                dataSourceLinePlot.identifier = lineName;
                lineStyle = [[dataSourceLinePlot dataLineStyle] mutableCopy];
                [lineStyle setLineWidth:1.0];
                [lineStyle setLineColor:[tsl cpColour]];
                
                if([tsl simId]==1){
                    [lineStyle setDashPattern:[NSArray arrayWithObjects:[NSDecimalNumber numberWithInt:2],[NSDecimalNumber numberWithInt:2],nil]];
                }
                
                [dataSourceLinePlot setDataLineStyle:lineStyle];
                [dataSourceLinePlot setDataSource:dataSource];
                switch ([tsl layerIndex]) {
                    case 0:
                        [[self graph] addPlot:dataSourceLinePlot
                                  toPlotSpace:[self plotSpace0]];
                        [self setInteractionLayer:dataSourceLinePlot];
                        break;
                    case 1:
                        [[self graph] addPlot:dataSourceLinePlot
                                  toPlotSpace:[self plotSpace1]];
                        layer1 = YES;
                        break;
                        
                    case 2:
                        [[self graph] addPlot:dataSourceLinePlot
                                  toPlotSpace:[self plotSpace2]];
                        layer2 = YES;
                        break;
                    default:
                        break;
                }
            }
        }
        
        if([dataSource shortLongIndicator]){
            //Short Indicator
            dataSourceLinePlot = [[CPTScatterPlot alloc] init];
            dataSourceLinePlot.identifier = @"S0_L0_SHORT";
            lineStyle = [[dataSourceLinePlot dataLineStyle] mutableCopy];
            [lineStyle setLineWidth:1.0];
            [lineStyle setLineColor:[CPTColor clearColor]];
            
            CPTColor *areaColor = [CPTColor colorWithComponentRed:1.0 green:0.0 blue:0.0 alpha:0.3];
            
            [dataSourceLinePlot setAreaFill	:[CPTFill fillWithColor:areaColor]];
            [dataSourceLinePlot setAreaBaseValue:CPTDecimalFromDouble(0.0)];
            
            [dataSourceLinePlot setDataLineStyle:lineStyle];
            [dataSourceLinePlot setDataSource:dataSource];
            [[self graph] addPlot:dataSourceLinePlot toPlotSpace:[self shortLongPlotSpace]];
            // Long indicator
            dataSourceLinePlot = [[CPTScatterPlot alloc] init];
            dataSourceLinePlot.identifier = @"S0_L0_LONG";
            lineStyle = [dataSourceLinePlot.dataLineStyle mutableCopy];
            [lineStyle setLineWidth:1.0];
            [lineStyle setLineColor:[CPTColor clearColor]];
            
            areaColor		  = [CPTColor colorWithComponentRed:0.0 green:1.0 blue:0.0 alpha:0.3];
            [dataSourceLinePlot setAreaFill:[CPTFill fillWithColor:areaColor]];
            [dataSourceLinePlot setAreaBaseValue :CPTDecimalFromDouble(0.0)];
            [dataSourceLinePlot setDataLineStyle:lineStyle];
            [dataSourceLinePlot setDataSource:dataSource];
            [[self graph] addPlot:dataSourceLinePlot toPlotSpace:[self shortLongPlotSpace]];
        }
        // Find a good range for the X axis
        double niceXrange = (ceil( (double)([self maxXrangeForPlot] - [self minXrangeForPlot]) / majorIntervalForX ) * majorIntervalForX);
        CPTMutablePlotRange *xRange;
        if((niceXrange/([self maxXrangeForPlot] - [self minXrangeForPlot]))>1.1){
            xRange = [CPTMutablePlotRange plotRangeWithLocation:CPTDecimalFromDouble((double)[self minXrangeForPlot])
                                                         length:CPTDecimalFromDouble((double)[self maxXrangeForPlot] - [self minXrangeForPlot])];
        }else{
            xRange = [CPTMutablePlotRange plotRangeWithLocation:CPTDecimalFromDouble((double)[self minXrangeForPlot])
                                                         length:CPTDecimalFromDouble(niceXrange)];
            
        }
        
        [xRange expandRangeByFactor:CPTDecimalFromDouble(1.1)];
        [[self plotSpace0] setXRange:xRange];
        [[self plotSpace1] setXRange:[[[self plotSpace0] xRange] copy]];
        [[self plotSpace2] setXRange:[[[self plotSpace0] xRange] copy]];
        
        [self fixUpYAxisForLayerIndex:0];
        
        if(layer1){
            [self fixUpYAxisForLayerIndex:1];
            [self setPlot1AxisVisible:YES];
        }else{
            CPTMutableTextStyle *newTextStyle;
            newTextStyle = [[[self yAxis1] labelTextStyle] mutableCopy];
            [newTextStyle setColor:[CPTColor clearColor]];
            [[self yAxis1] setLabelTextStyle:newTextStyle];
            [[self yAxis1] setMajorTickLineStyle:nil];
            [self setPlot1AxisVisible:NO];
        }
        if(layer2){
            [self fixUpYAxisForLayerIndex:2];
            [self setPlot2AxisVisible:YES];
        }else{
            CPTMutableTextStyle *newTextStyle;
            newTextStyle = [[[self yAxis2] labelTextStyle] mutableCopy];
            [newTextStyle setColor:[CPTColor clearColor]];
            [[self yAxis2] setLabelTextStyle:newTextStyle];
            [[self yAxis2] setMajorTickLineStyle:nil];
            [self setPlot2AxisVisible:NO];
        }

        if([dataSource shortLongIndicator]){
            CPTPlotRange *shortLongPlotYRange;
            shortLongPlotYRange = [[CPTPlotRange alloc] initWithLocation:[[NSDecimalNumber numberWithInt:0] decimalValue]  length:[[NSDecimalNumber numberWithInt:1] decimalValue]];
            CPTMutablePlotRange *shortLongPlotXRange =[[[self plotSpace0] xRange] copy];
            [[self shortLongPlotSpace] setXRange:shortLongPlotXRange];
            [[self shortLongPlotSpace] setYRange:shortLongPlotYRange];
        }
//        [self setXRangeZoomOut:xRange];
        
        BOOL dateAnnotateRequired = [self fixUpXAxisLabels];
        if(dateAnnotateRequired){
            long firstMidnight = [EpochTime epochTimeAtZeroHour:[self minXrangeForPlot]];
            long lastMidnight = [EpochTime epochTimeNextDayAtZeroHour:[self maxXrangeForPlot]];
            
            CPTPlotRange *xRange  = [[self plotSpace0] xRange];
            CPTPlotRange *yRange = [[self plotSpace0] yRange];
            double minXrange = [[NSDecimalNumber decimalNumberWithDecimal:[xRange location]] doubleValue];
            double maxXrange = [[NSDecimalNumber decimalNumberWithDecimal:[xRange location]] doubleValue] + [[NSDecimalNumber decimalNumberWithDecimal:[xRange length]] doubleValue];
            
            CGRect bounds = NSRectToCGRect([[self hostingView] bounds]);
            
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
                    
                    dateAnnotation = [[CPTPlotSpaceAnnotation alloc] initWithPlotSpace:[[self graph] defaultPlotSpace] anchorPlotPoint:dateAnnotationPoint];
                    dateAnnotation.contentLayer = textLayer;
                    dateAnnotation.displacement =  CGPointMake( 0.0f,10.0f);
                    [[[[self graph] plotAreaFrame] plotArea] addAnnotation:dateAnnotation];
                    [[self dateAnnotationArray] addObject:dateAnnotation];
                    
                }
            }
        }
    }else{
        while([[[self graph] allPlots] count] > 0){
            [[self graph] removePlot:[[[self graph] allPlots] objectAtIndex:0]];
        }
    }

}

//-(void)togglePositionIndicator
//{
//    CPTPlot * plot;
//    plot = [[self graph] plotWithIdentifier:@"P9_SHORT"];
//    if([plot dataSource] == nil){
//        [plot setDataSource:[self dataView]];
//    }else {
//        [plot setDataSource:nil];
//    }
//    [plot dataNeedsReloading];
//    
//    plot = [[plot graph] plotWithIdentifier:@"P9_LONG"];
//    if(plot.dataSource == nil){
//        [plot setDataSource:[self dataView]];
//    }else {
//        plot.dataSource = nil;
//    }
//    [plot dataNeedsReloading];
//}

- (BOOL) fixUpXAxisLabelsFrom: (long)   minXaxis To: (long) maxXaxis
{
    
    if((minXaxis == -1) && (maxXaxis == -1))
    {
        minXaxis = [self minXrangeForPlot];
        maxXaxis = [self maxXrangeForPlot];
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
    
    [self setMinXrangeForPlot:minXaxis];
    [self setMaxXrangeForPlot:maxXaxis];
    //    
    if(((float)([self maxXrangeForPlot] - [self minXrangeForPlot])/(4*30*60 * 60 * 24))>1){
        majorIntervalForX = 28 * 24 * 60 * 60;
        [[self xAxis0] setMajorIntervalLength:CPTDecimalFromInt(majorIntervalForX)]; // 14 Day
        [[self xAxis0] setMinorTicksPerInterval:13];
        [dateFormatter setDateFormat:@"MM/dd"];
        dateIsSpecifiedInAxis = TRUE;
    }else{
        if(((float)([self maxXrangeForPlot] - [self minXrangeForPlot])/(4*30*60 * 60 * 24))>1){
            majorIntervalForX = 14 * 24 * 60 * 60;
            [[self xAxis0] setMajorIntervalLength:CPTDecimalFromInt(majorIntervalForX)]; // 14 Day
            [[self xAxis0] setMinorTicksPerInterval:13];
            [dateFormatter setDateFormat:@"MM/dd"];
            dateIsSpecifiedInAxis = TRUE;
        }else{
            if(((float)([self maxXrangeForPlot] - [self minXrangeForPlot])/(21*60 * 60 * 24))>1){
                majorIntervalForX = 7 * 24 * 60 * 60;
                [[self xAxis0] setMajorIntervalLength:CPTDecimalFromInt(majorIntervalForX)]; // 7 Day
                [[self xAxis0] setMinorTicksPerInterval:6];
                [dateFormatter setDateFormat:@"MM/dd"];
                dateIsSpecifiedInAxis = TRUE;
            }else{
                //If greater than 3 days
                if(((float)([self maxXrangeForPlot] - [self minXrangeForPlot])/(3*60 * 60 * 24))>1){
                    majorIntervalForX = 24 * 60 * 60;
                    [[self xAxis0] setMajorIntervalLength:CPTDecimalFromInt(majorIntervalForX)]; // 1 Day
                    [[self xAxis0] setMinorTicksPerInterval:5];
                    [dateFormatter setDateFormat:@"MM/dd"];
                    dateIsSpecifiedInAxis = TRUE;
                }else{
                    //If greater than 12 hours
                    if(((float)([self maxXrangeForPlot] - [self minXrangeForPlot])/(60 * 60 * 12))>1){
                        majorIntervalForX = 4 * 60 * 60;
                        [[self xAxis0] setMajorIntervalLength:CPTDecimalFromInt(majorIntervalForX)]; // 4 hours
                        [[self xAxis0] setMinorTicksPerInterval:3];
                        [dateFormatter setDateStyle:kCFDateFormatterNoStyle];
                        [dateFormatter setTimeStyle:kCFDateFormatterShortStyle];
                    }else{
                        //If less than 12 hours
                        if(((float)([self maxXrangeForPlot] - [self minXrangeForPlot])/(60 * 60 * 12))<=1){
                            majorIntervalForX = 60 * 60;
                            [[self xAxis0] setMajorIntervalLength:CPTDecimalFromInt(majorIntervalForX)]; // 1 hours
                            [[self xAxis0] setMinorTicksPerInterval:5];
                            [dateFormatter setDateStyle:kCFDateFormatterNoStyle];
                            [dateFormatter setTimeStyle:kCFDateFormatterShortStyle];
                        }
                    }
                }   
            }
        }
    }
    
    [[self xAxis0] setMajorGridLineStyle:majorGridLineStyle];
    [[self xAxis0] setMinorGridLineStyle:minorGridLineStyle];

    CPTTimeFormatter *timeFormatter = [[CPTTimeFormatter alloc] initWithDateFormatter:dateFormatter] ;
    NSDate *refDate = [NSDate dateWithTimeIntervalSince1970:0];
    timeFormatter.referenceDate = refDate;
    [[self xAxis0] setLabelFormatter:timeFormatter];
    [[self xAxis0] setLabelRotation:M_PI / 4];
    
    // From dropplot
    [[self xAxis0] setLabelOffset:5.0];
    [[self xAxis0] setAxisConstraints:[CPTConstraints constraintWithLowerOffset:0.0]];
    
    return !dateIsSpecifiedInAxis;
}

- (BOOL) fixUpXAxisLabels
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
    
    //
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init] ;
    dateFormatter.timeZone = [NSTimeZone timeZoneWithName:@"GMT"];
    // If it more than 3 days, major tic is 1 day, otherwise a major tic is 6 hours
    
    BOOL dateIsSpecifiedInAxis = NO;
    
    //
    if(((float)([self maxXrangeForPlot] - [self minXrangeForPlot])/(4*30*60 * 60 * 24))>1){
        majorIntervalForX = 28 * 24 * 60 * 60;
        [[self xAxis0] setMajorIntervalLength:CPTDecimalFromInt(majorIntervalForX)]; // 14 Day
        [[self xAxis0] setMinorTicksPerInterval:13];
        [dateFormatter setDateFormat:@"MM/dd"];
        dateIsSpecifiedInAxis = TRUE;
    }else{
        if(((float)([self maxXrangeForPlot] - [self minXrangeForPlot])/(4*30*60 * 60 * 24))>1){
            majorIntervalForX = 14 * 24 * 60 * 60;
            [[self xAxis0] setMajorIntervalLength:CPTDecimalFromInt(majorIntervalForX)]; // 14 Day
            [[self xAxis0] setMinorTicksPerInterval:13];
            [dateFormatter setDateFormat:@"MM/dd"];
            dateIsSpecifiedInAxis = TRUE;
        }else{
            if(((float)([self maxXrangeForPlot] - [self minXrangeForPlot])/(21*60 * 60 * 24))>1){
                majorIntervalForX = 7 * 24 * 60 * 60;
                [[self xAxis0] setMajorIntervalLength:CPTDecimalFromInt(majorIntervalForX)]; // 7 Day
                [[self xAxis0] setMinorTicksPerInterval:6];
                [dateFormatter setDateFormat:@"MM/dd"];
                dateIsSpecifiedInAxis = TRUE;
            }else{
                //If greater than 3 days
                if(((float)([self maxXrangeForPlot] - [self minXrangeForPlot])/(3*60 * 60 * 24))>1){
                    majorIntervalForX = 24 * 60 * 60;
                    [[self xAxis0] setMajorIntervalLength:CPTDecimalFromInt(majorIntervalForX)]; // 1 Day
                    [[self xAxis0] setMinorTicksPerInterval:5];
                    [dateFormatter setDateFormat:@"MM/dd"];
                    dateIsSpecifiedInAxis = TRUE;
                }else{
                    //If greater than 12 hours
                    if(((float)([self maxXrangeForPlot] - [self minXrangeForPlot])/(60 * 60 * 12))>1){
                        majorIntervalForX = 4 * 60 * 60;
                        [[self xAxis0] setMajorIntervalLength:CPTDecimalFromInt(majorIntervalForX)]; // 4 hours
                        [[self xAxis0] setMinorTicksPerInterval:3];
                        [dateFormatter setDateStyle:kCFDateFormatterNoStyle];
                        [dateFormatter setTimeStyle:kCFDateFormatterShortStyle];
                    }else{
                        //If less than 12 hours
                        if(((float)([self maxXrangeForPlot] - [self minXrangeForPlot])/(60 * 60 * 12))<=1){
                            majorIntervalForX = 60 * 60;
                            [[self xAxis0] setMajorIntervalLength:CPTDecimalFromInt(majorIntervalForX)]; // 1 hours
                            [[self xAxis0] setMinorTicksPerInterval:5];
                            [dateFormatter setDateStyle:kCFDateFormatterNoStyle];
                            [dateFormatter setTimeStyle:kCFDateFormatterShortStyle];
                        }
                    }
                }
            }
        }
    }
    
    [[self xAxis0] setMajorGridLineStyle:majorGridLineStyle];
    [[self xAxis0] setMinorGridLineStyle:minorGridLineStyle];
    
    CPTTimeFormatter *timeFormatter = [[CPTTimeFormatter alloc] initWithDateFormatter:dateFormatter] ;
    NSDate *refDate = [NSDate dateWithTimeIntervalSince1970:0];
    timeFormatter.referenceDate = refDate;
    [[self xAxis0] setLabelFormatter:timeFormatter];
    [[self xAxis0] setLabelRotation:M_PI / 4];
    
    // From dropplot
    [[self xAxis0] setLabelOffset:5.0];
    [[self xAxis0] setAxisConstraints:[CPTConstraints constraintWithLowerOffset:0.0]];
    
    return !dateIsSpecifiedInAxis;
}




- (void) fixUpYAxisForLayerIndex: (int) layerIndex;
{
    double minYrangeForPlot, maxYrangeForPlot;
    BOOL ok = YES;
    CPTXYPlotSpace *plotSpace;
    CPTXYAxis *yAxis;
    switch(layerIndex){
        case 0:
            minYrangeForPlot = [self minYrangeForPlot0];
            maxYrangeForPlot = [self maxYrangeForPlot0];
            plotSpace = [self plotSpace0];
            yAxis = [self yAxis0];
            break;
        case 1:
            minYrangeForPlot = [self minYrangeForPlot1];
            maxYrangeForPlot = [self maxYrangeForPlot1];
            plotSpace = [self plotSpace1];
            yAxis = [self yAxis1];
            break;
        case 2:
            minYrangeForPlot = [self minYrangeForPlot2];
            maxYrangeForPlot = [self maxYrangeForPlot2];
            plotSpace = [self plotSpace2];
            yAxis = [self yAxis2];
            break;
        default:
            ok = NO;
            break;
    }
    if(ok){
        int nTicks = 10;
        double d;
        double axisMin = 0.0;
        double axisMax = 0.0;
        double range = [self niceNumber:  maxYrangeForPlot-minYrangeForPlot
                           withRounding:NO];
        if(range > 0){
            d = [self niceNumber:range/(nTicks - 1)
                           withRounding:YES];
            axisMin = floor(minYrangeForPlot/d)*d;
            axisMax = ceil(maxYrangeForPlot/d)*d;
        }else{
            d = [self niceNumber:2.0/(nTicks - 1)
                           withRounding:YES];
            axisMin = minYrangeForPlot - 1;
            axisMax = maxYrangeForPlot + 1;
        }
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
        [yAxis setLabelOffset:5.0];
        
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
        [numberFormatter setMinimumFractionDigits:nfrac];
        yAxis.labelFormatter = numberFormatter;
        CPTMutablePlotRange *yRange = [CPTMutablePlotRange plotRangeWithLocation:CPTDecimalFromDouble(axisMin)
                                                                          length:CPTDecimalFromDouble((axisMax-axisMin)+(0.5*d))];
        [yRange expandRangeByFactor:CPTDecimalFromDouble(1.2)];
        
        [plotSpace setYRange:yRange];
        
        CPTMutableTextStyle *newTextStyle;
        newTextStyle = [[yAxis labelTextStyle] mutableCopy];
        [newTextStyle setColor:[CPTColor whiteColor]];
        [yAxis setLabelTextStyle:newTextStyle];
        
//        switch(layerIndex){
//            case 0:
//                [self setYRange0ZoomOut:yRange];
//                break;
//            case 1:
//                [self setYRange1ZoomOut:yRange];
//                break;
//            case 2:
//                [self setYRange2ZoomOut:yRange];
//                break;
//        }
    }
}


//- (void) updatePlotWithUpdateAxes: (BOOL) updateAxes
//{
//    for(int layerIndex = 0; layerIndex < 3; layerIndex++)
//    {
//        CPTXYAxis *yAxis;
//        switch(layerIndex){
//            case 0:
//                yAxis = [self yAxis0];
//                break;
//            case 1:
//                yAxis = [self yAxis1];
//                break;
//            case 2:
//                yAxis = [self yAxis2];
//        }
//        
//        TimeSeriesLine *tsLine;
//        BOOL visiblePlotLineFound = NO;
//        
//        NSString *lineIdentifier;
//        double minYrangeForPlot = 0, maxYrangeForPlot = 0;
//        
//        for(int i = 0; i < [[self timeSeriesLines] count]; i++)
//        {
//            tsLine = [[self timeSeriesLines] objectAtIndex:i];
//            lineIdentifier = [NSString stringWithFormat:@"P%d_%@",layerIndex,[tsLine name]];
//            CPTScatterPlot *plot = (CPTScatterPlot *)[[self graph] plotWithIdentifier:lineIdentifier];
//            CPTMutableLineStyle *lineStyle = [[plot dataLineStyle] mutableCopy];
//            
//            if([tsLine layerIndex]==layerIndex){
//                lineStyle.lineColor = [tsLine cpColour];
//                if(!visiblePlotLineFound){
//                    minYrangeForPlot = [[[[self dataView] minYvalues] valueForKey:[tsLine name]] doubleValue];
//                    maxYrangeForPlot = [[[[self dataView] maxYvalues] valueForKey:[tsLine name]] doubleValue];
//                    visiblePlotLineFound = YES;
//                }else{
//                    minYrangeForPlot = fmin(minYrangeForPlot,[[[[self dataView] minYvalues] valueForKey:[tsLine name]] doubleValue]);
//                    maxYrangeForPlot = fmax(maxYrangeForPlot,[[[[self dataView] maxYvalues] valueForKey:[tsLine name]] doubleValue]);
//                }
//            }else{
//                lineStyle.lineColor = [CPTColor clearColor];
//            }
//            plot.dataLineStyle = lineStyle;
//        }
//        
//        if(visiblePlotLineFound){
//            switch(layerIndex){
//                case 0:
//                    [self setMinYrangeForPlot0:minYrangeForPlot];
//                    [self setMaxYrangeForPlot0:maxYrangeForPlot];
//                    break;
//                case 1:
//                    [self setMinYrangeForPlot1:minYrangeForPlot];
//                    [self setMaxYrangeForPlot1:maxYrangeForPlot];
//                    if(![self plot1AxisVisible]){
//                        CPTMutableTextStyle *newTextStyle = [[yAxis labelTextStyle] mutableCopy];
//                        [newTextStyle setColor:[CPTColor whiteColor]];
//                        [yAxis setLabelTextStyle:newTextStyle];
//                        CPTMutableLineStyle *axisLineStyle =  [CPTMutableLineStyle lineStyle];
//                        axisLineStyle.lineWidth = 0.5;
//                        axisLineStyle.lineColor = [[CPTColor whiteColor] colorWithAlphaComponent:0.5];
//                        [yAxis setMajorTickLineStyle:axisLineStyle];
//                        [self setPlot1AxisVisible:YES];
//                    }
//                    break;
//                case 2:
//                    [self setMinYrangeForPlot2:minYrangeForPlot];
//                    [self setMaxYrangeForPlot2:maxYrangeForPlot];
//                    if(![self plot2AxisVisible]){
//                        CPTMutableTextStyle *newTextStyle = [[yAxis labelTextStyle] mutableCopy];
//                        [newTextStyle setColor:[CPTColor whiteColor]];
//                        [yAxis setLabelTextStyle:newTextStyle];
//                        CPTMutableLineStyle *axisLineStyle =  [CPTMutableLineStyle lineStyle];
//                        axisLineStyle.lineWidth = 0.5;
//                        axisLineStyle.lineColor = [[CPTColor whiteColor] colorWithAlphaComponent:0.5];
//                        [yAxis setMajorTickLineStyle:axisLineStyle];
//                        [self setPlot2AxisVisible:YES];
//                    }
//                    break;
//            }
//            if(updateAxes){
//                //Fix the axes
//                [self fixUpYAxisForLayerIndex:layerIndex];
//            }
//        }else {
//            switch(layerIndex){
//                case 1:
//                    if([self plot1AxisVisible]){
//                        CPTMutableTextStyle *newTextStyle = [[yAxis labelTextStyle] mutableCopy];
//                        [newTextStyle setColor:[CPTColor clearColor]];
//                        [yAxis setLabelTextStyle:newTextStyle];
//                        [yAxis setMajorTickLineStyle:nil];
//                        [self setPlot1AxisVisible:NO];
//                    }
//                    break;
//                case 2:
//                    if([self plot2AxisVisible]){
//                        CPTMutableTextStyle *newTextStyle = [[yAxis labelTextStyle] mutableCopy];
//                        [newTextStyle setColor:[CPTColor clearColor]];
//                        [yAxis setLabelTextStyle:newTextStyle];
//                        [yAxis setMajorTickLineStyle:nil];
//                        [self setPlot2AxisVisible:NO];
//                    }
//                    break;
//                default:
//                    //Do nothing
//                    break;
//            }
//        }
//    }
//    
//    if([self zoomedOut]){
//        //Get to the fully zoomed out position after a change in content of graph
//        [self zoomOut];
//    }
//    [[self graph] reloadData];
//}




- (void) toggleAxisLabelsForLayer: (int) layerIndex
{
    CPTMutableTextStyle *newTextStyle;
    switch(layerIndex){
        case 1:
            if([self plot1AxisVisible]){
                newTextStyle = [[[self yAxis1] labelTextStyle] mutableCopy];
                [newTextStyle setColor:[CPTColor clearColor]];
                [[self yAxis1] setLabelTextStyle:newTextStyle];
                [[self yAxis1] setMajorTickLineStyle:nil];
                [self setPlot1AxisVisible:NO];
            }else{
                newTextStyle = [[[self yAxis1] labelTextStyle] mutableCopy];
                [newTextStyle setColor:[CPTColor whiteColor]];
                [[self yAxis1] setLabelTextStyle:newTextStyle];
                CPTMutableLineStyle *axisLineStyle =  [CPTMutableLineStyle lineStyle];
                axisLineStyle.lineWidth = 0.5;
                axisLineStyle.lineColor = [[CPTColor blackColor] colorWithAlphaComponent:0.5];
                [[self yAxis1] setMajorTickLineStyle:axisLineStyle];
                [self setPlot1AxisVisible:YES];
            }
            break;
        case 2:
            if([self plot2AxisVisible]){
                newTextStyle = [[[self yAxis2] labelTextStyle] mutableCopy];
                [newTextStyle setColor:[CPTColor clearColor]];
                [[self yAxis2] setLabelTextStyle:newTextStyle];
                [[self yAxis2] setMajorTickLineStyle:nil];
                [self setPlot2AxisVisible:NO];
            }else{
                newTextStyle = [[[self yAxis2] labelTextStyle] mutableCopy];
                [newTextStyle setColor:[CPTColor whiteColor]];
                [[self yAxis2] setLabelTextStyle:newTextStyle];
                CPTMutableLineStyle *axisLineStyle =  [CPTMutableLineStyle lineStyle];
                axisLineStyle.lineWidth = 0.5;
                axisLineStyle.lineColor = [[CPTColor blackColor] colorWithAlphaComponent:0.5];
                [[self yAxis2] setMajorTickLineStyle:axisLineStyle];
                [self setPlot2AxisVisible:YES];
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
    [self setLineAnnotation:[[CPTPlotSpaceAnnotation alloc] initWithPlotSpace:plotSpace anchorPlotPoint:nil]];
	[[self lineAnnotation] setContentLayer:lineLayer];
    
    CGPoint startPoint =  [plotSpace plotAreaViewPointForDoublePrecisionPlotPoint:dataValues];
    dataValues[0] = maxXRange;
    CGPoint endPoint =  [plotSpace plotAreaViewPointForDoublePrecisionPlotPoint:dataValues];
    
    CGRect borderRect;
    borderRect = CGRectMake(startPoint.x, startPoint.y ,
                            (endPoint.x - startPoint.x),
                            1);  
    [[[self lineAnnotation] contentLayer] setFrame:borderRect];
	[[[[self graph] plotAreaFrame] plotArea] addAnnotation:[self lineAnnotation]];
    [[self lineAnnotationArray] addObject:[self lineAnnotation]];
    [[self lineAnnotationLevelArray] addObject:[NSNumber numberWithDouble:yValue]];
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
//    TimeSeriesLine *tsLine = [[self timeSeriesLines] objectAtIndex:0];
//    NSString *plotIdentifier = [NSString stringWithFormat:@"P0_%@",[tsLine name]];
//    CPTScatterPlot *plot = (CPTScatterPlot *)[[self graph] plotWithIdentifier:plotIdentifier];
    
	// convert the dragStart and dragEnd values to plot coordinates
	CGPoint dragStartInPlotArea = [[self graph] convertPoint:[self dragStart] toLayer:[self interactionLayer]];
	CGPoint dragEndInPlotArea	= [[self graph] convertPoint:interactionPoint toLayer:[self interactionLayer]];
    
	// create the dragrect from dragStart to the current location
    CGRect borderRect;
    
    if([self interactionLayer]){
//        if([NSEvent modifierFlags] == NSAlternateKeyMask){
//            borderRect = CGRectMake(dragStartInPlotArea.x, dragStartInPlotArea.y,
//                                    (dragEndInPlotArea.x - dragStartInPlotArea.x),
//                                    (dragEndInPlotArea.y - dragStartInPlotArea.y));
//        }else{
            double getValues[2];
            double minYRange = [[NSDecimalNumber decimalNumberWithDecimal:[[[self plotSpace0] yRange] location]] doubleValue];
            double maxYRange =  minYRange + [[NSDecimalNumber decimalNumberWithDecimal:[[[self plotSpace0] yRange] length]] doubleValue];
            
            getValues[0] = 0.0;
            getValues[1] = minYRange;
            
            CGPoint getMinY =  [[self plotSpace0] plotAreaViewPointForDoublePrecisionPlotPoint:getValues];
            getValues[1] = maxYRange;
            CGPoint getMaxY =  [[self plotSpace0] plotAreaViewPointForDoublePrecisionPlotPoint:getValues];
            borderRect = CGRectMake(dragStartInPlotArea.x, getMinY.y ,
                                    (dragEndInPlotArea.x - dragStartInPlotArea.x),
                                    getMaxY.y);
            
//        }
        
        // force the drawing of the zoomRect
        [[[self zoomAnnotation] contentLayer] setFrame:borderRect];
        [[[self zoomAnnotation] contentLayer] setNeedsDisplay];
        
        // Add a date
        //CPTXYPlotSpace *plotSpace = (CPTXYPlotSpace *)graph.defaultPlotSpace;
        CGPoint dragInPlotArea = [[self graph] convertPoint:interactionPoint toLayer:[self interactionLayer]];
        double dataCoords[2];
        [[self plotSpace0] doublePrecisionPlotPoint:dataCoords forPlotAreaViewPoint:dragInPlotArea];
        
        NSString *currentValue;
//        if([NSEvent modifierFlags] == NSAlternateKeyMask){
//            currentValue = [NSString stringWithFormat:@"%5.3f",dataCoords[CPTCoordinateY]];
//        }else{
            currentValue = [EpochTime stringOfDateTimeForTime:(long)dataCoords[CPTCoordinateX]
                                                   WithFormat: @"%a %Y-%m-%d %H:%M:%S"];
//        }
        NSNumber *x            = [NSNumber numberWithDouble:dataCoords[CPTCoordinateX]];
        NSNumber *y            = [NSNumber numberWithDouble:dataCoords[CPTCoordinateY]];
        NSArray *anchorPoint = [NSArray arrayWithObjects: x,y, nil];
        //
        if ([self dragDateAnnotation]) {
            [[[[self graph] plotAreaFrame] plotArea] removeAnnotation:[self dragDateAnnotation]];
            [self setDragDateAnnotation:nil];
        }
        
        // Setup a style for the annotation
        CPTMutableTextStyle *hitAnnotationTextStyle = [CPTMutableTextStyle textStyle];
        hitAnnotationTextStyle.color	= [CPTColor grayColor];
        hitAnnotationTextStyle.fontSize = 12.0f;
        hitAnnotationTextStyle.fontName = @"Courier";
        
        // Now add the annotation to the plot area
        CPTTextLayer *textLayer = [[CPTTextLayer alloc] initWithText:currentValue style:hitAnnotationTextStyle];
        [self setDragDateAnnotation:[[CPTPlotSpaceAnnotation alloc] initWithPlotSpace:[self plotSpace0] anchorPlotPoint:anchorPoint]];
        [[self dragDateAnnotation] setContentLayer:textLayer];
        [[self dragDateAnnotation] setDisplacement:CGPointMake(0.0f, 10.0f)];
        [[[[self graph] plotAreaFrame] plotArea] addAnnotation:[self dragDateAnnotation]];
    }
	return NO;
}

-(BOOL)plotSpace:(CPTPlotSpace *)plotSpace shouldHandlePointingDeviceDownEvent:(id)event
         atPoint:(CGPoint)interactionPoint
{
  	if([self interactionLayer]){
        if([NSEvent modifierFlags] == NSCommandKeyMask){
//            TimeSeriesLine *tsLine = [[self timeSeriesLines] objectAtIndex:0];
//            NSString *plotIdentifier = [NSString stringWithFormat:@"P0_%@",[tsLine name]];
//            CPTScatterPlot *plot = (CPTScatterPlot *)[[self graph] plotWithIdentifier:plotIdentifier];
            CGPoint clickInPlotArea = [[self graph] convertPoint:interactionPoint
                                                         toLayer:[self interactionLayer]];
            double dataCoords[2];
            
            [plotSpace doublePrecisionPlotPoint:dataCoords
                           forPlotAreaViewPoint:clickInPlotArea];
            [self addHorizontalLineAt:dataCoords[CPTCoordinateY] ForPlotspace:[self plotSpace0]];
            
        }else{
            [self setDragStart:interactionPoint];
            
            //CPTXYPlotSpace *plotSpace = (CPTXYPlotSpace *)graph.defaultPlotSpace;
            //        TimeSeriesLine *tsLine = [[self timeSeriesLines] objectAtIndex:0];
            //        NSString *plotIdentifier = [NSString stringWithFormat:@"P0_%@",[tsLine name]];
            //        CPTScatterPlot *plot = (CPTScatterPlot *)[[self graph] plotWithIdentifier:plotIdentifier];
            //CPTPlotSpaceAnnotation *test;
            
            
            CGPoint clickInPlotArea = [[self graph] convertPoint:interactionPoint
                                                         toLayer:[self interactionLayer]];
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
            if ( [self clickDateAnnotation]) {
                [[[[self graph] plotAreaFrame] plotArea] removeAnnotation:[self clickDateAnnotation]];
                [self setClickDateAnnotation:nil];
            }
            
            // Setup a style for the annotation
            CPTMutableTextStyle *hitAnnotationTextStyle = [CPTMutableTextStyle textStyle];
            hitAnnotationTextStyle.color	= [CPTColor grayColor];
            hitAnnotationTextStyle.fontSize = 12.0f;
            hitAnnotationTextStyle.fontName = @"Courier";
            
            // Now add the annotation to the plot area
            CPTTextLayer *textLayer = [[CPTTextLayer alloc] initWithText:currentValue style:hitAnnotationTextStyle];
            [self setClickDateAnnotation:[[CPTPlotSpaceAnnotation alloc] initWithPlotSpace:[[self graph] defaultPlotSpace] anchorPlotPoint:anchorPoint]];
            [[self clickDateAnnotation] setContentLayer:textLayer];
            [[self clickDateAnnotation] setDisplacement:CGPointMake(0.0f, 10.0f)];
            [[[[self graph] plotAreaFrame] plotArea] addAnnotation:[self clickDateAnnotation]];
        }
    }
	return NO;
}

-(BOOL)plotSpace:(CPTPlotSpace *)plotSpace shouldHandlePointingDeviceUpEvent:(id)event
         atPoint:(CGPoint)point
{
    if([self interactionLayer]){
        if([NSEvent modifierFlags] == NSCommandKeyMask){
            if([event clickCount] == 2){
                [self removeLineAnnotation];
                //            while([lineAnnotationArray count] > 0){
                //                [graph.plotAreaFrame.plotArea removeAnnotation:[lineAnnotationArray objectAtIndex:0]];
                //                [lineAnnotationArray removeObjectAtIndex:0];
                //                [lineAnnotationLevelArray removeObjectAtIndex:0];
                //            }
            }
        }else{
            
            if ( [self clickDateAnnotation] ) {
                [[[[self graph] plotAreaFrame] plotArea] removeAnnotation:[self clickDateAnnotation]];
                [self setClickDateAnnotation:nil];
            }
            
            if ( [self dragDateAnnotation] ) {
                [[[[self graph] plotAreaFrame] plotArea] removeAnnotation:[self dragDateAnnotation]];
                [self setDragDateAnnotation:nil];
            }
            
            [self setDragEnd:point];
            
            // double-click to completely zoom out
            if ( [event clickCount] == 2 ) {
                [self zoomOut];
                
            }
            else if ( !CGPointEqualToPoint([self dragStart], [self dragEnd]) ) {
                
                // no accidental drag, so zoom in
//                if([NSEvent modifierFlags] == NSAlternateKeyMask){
//                    [self zoomIn];
//                }else{
                    [self zoomIn];
//                }
                
                // and we're done with the drag
                [[[self zoomAnnotation] contentLayer] setFrame:CGRectNull];
                [[[self zoomAnnotation] contentLayer] setNeedsDisplay];
            }
        }
    }
	return NO;
}

#pragma mark -
#pragma mark Zoom Methods

//-(void)setZoomDataViewFrom:(long)startDateTime To:(long) endDateTime
//{
//    
//    double minXzoomForPlot;
//	double maxXzoomForPlot;
//    
//    if (startDateTime < endDateTime){
//        // recalculate the min and max values
//        minXzoomForPlot = startDateTime;
//        maxXzoomForPlot = endDateTime;
//        
//        NSDictionary *minMax = [[self plotData] setDataViewWithName:@"ZOOM"
//                                                   AndStartDateTime:(long)minXzoomForPlot
//                                                     AndEndDateTime:(long)maxXzoomForPlot];
//        
//        [[self plotSpace0] setXRange:[CPTPlotRange plotRangeWithLocation:CPTDecimalFromDouble(minXzoomForPlot)
//                                                         length:CPTDecimalFromDouble(maxXzoomForPlot - minXzoomForPlot)]];
//        
//        [[self plotSpace1] setXRange:[[[self plotSpace0] xRange] copy]];
//        [[self plotSpace2] setXRange:[[[self plotSpace0] xRange] copy]];
//        [self setZoomedOut:NO];
//        
//        [[self overlayPlotSpace] setXRange:[[[self plotSpace0] xRange] copy]];
//        
//        BOOL dateAnnotateRequired = [self fixUpXAxisLabelsFrom:[[minMax objectForKey:@"MIN"] longValue] To:[[minMax objectForKey:@"MAX"] longValue]];
//        
//        while([[self dateAnnotationArray] count] > 0){
//            [[[[self graph] plotAreaFrame  ]plotArea] removeAnnotation:[[self dateAnnotationArray] objectAtIndex:0]];
//            [[self dateAnnotationArray] removeObjectAtIndex:0];
//        }
//        
//        if(dateAnnotateRequired){
//            long firstMidnight = [EpochTime epochTimeAtZeroHour:[self minXrangeForPlot]];
//            long lastMidnight = [EpochTime epochTimeNextDayAtZeroHour:[self maxXrangeForPlot]];
//            
//            CPTPlotRange *xRange  = [[self plotSpace0] xRange];
//            CPTPlotRange *yRange = [[self plotSpace0] yRange ];
//            double minXrange = [[NSDecimalNumber decimalNumberWithDecimal:xRange.location] doubleValue];
//            double maxXrange = [[NSDecimalNumber decimalNumberWithDecimal:xRange.location] doubleValue] + [[NSDecimalNumber decimalNumberWithDecimal:xRange.length] doubleValue];
//            
//            CGRect bounds = NSRectToCGRect([[self hostingView] bounds]);
//            
//            NSString *stringFromDate;
//            CPTMutableTextStyle *dateStringStyle;
//            NSArray *dateAnnotationPoint;
//            CPTTextLayer *textLayer;
//            NSDateFormatter *labelFormatter = [[NSDateFormatter alloc] init] ;
//            [labelFormatter setDateFormat:@"MM/dd"];
//            [labelFormatter setTimeZone:[NSTimeZone timeZoneWithName:@"GMT"]];
//            CPTPlotSpaceAnnotation *dateAnnotation;
//            for(long labelDate = firstMidnight; labelDate <= lastMidnight; labelDate = labelDate + (60*60*24))
//            {
//                if((double)labelDate >= minXrange && labelDate <= (double)(maxXrange)){
//                    stringFromDate = [labelFormatter stringFromDate:[NSDate dateWithTimeIntervalSince1970:labelDate]];
//                    dateStringStyle = [CPTMutableTextStyle textStyle];
//                    dateStringStyle.color	= [CPTColor redColor];
//                    dateStringStyle.fontSize = round(bounds.size.height / (CGFloat)30.0);
//                    dateStringStyle.fontName = @"Courier";
//                    
//                    // Determine point of symbol in plot coordinates
//                    dateAnnotationPoint = [NSArray arrayWithObjects:[NSDecimalNumber numberWithLong:labelDate],[NSDecimalNumber decimalNumberWithDecimal: yRange.location], nil];
//                    
//                    textLayer = [[CPTTextLayer alloc] initWithText:stringFromDate style:dateStringStyle];
//                    dateAnnotation = [[CPTPlotSpaceAnnotation alloc] initWithPlotSpace:[[self graph] defaultPlotSpace]   anchorPlotPoint:dateAnnotationPoint];
//                    [dateAnnotation setContentLayer:textLayer];
//                    [dateAnnotation setDisplacement:CGPointMake( 0.0f,(CGFloat)10.0 )];
//                    [[[[self graph] plotAreaFrame] plotArea] addAnnotation:dateAnnotation];
//                    [[self dateAnnotationArray] addObject:dateAnnotation];
//                }
//            }
//        }
//    }
//}


-(void)zoomIn;
{
	//CPTXYPlotSpace *plotSpace = (CPTXYPlotSpace *)graph.defaultPlotSpace;
//    TimeSeriesLine *tsLine = [[self timeSeriesLines] objectAtIndex:0];
//    NSString *plotIdentifier = [NSString stringWithFormat:@"P0_%@",[tsLine name]];
//    CPTScatterPlot *plot = (CPTScatterPlot *)[[self graph] plotWithIdentifier:plotIdentifier];
//    
    double minXzoomForPlot;
	double maxXzoomForPlot;
//	double minYzoomForPlot0;
//	double maxYzoomForPlot0;
//    double minYzoomForPlot1;
//	double maxYzoomForPlot1;
//    double minYzoomForPlot2;
//	double maxYzoomForPlot2;
    
	// convert the dragStart and dragEnd values to plot coordinates
	CGPoint dragStartInPlotArea = [[self graph] convertPoint:[self dragStart] toLayer:[self interactionLayer]];
	CGPoint dragEndInPlotArea	= [[self graph] convertPoint:[self dragEnd] toLayer:[self interactionLayer]];
    
	double start0[2], end0[2]; //, start1[2], end1[2], start2[2], end2[2];
    
	// obtain the datapoints for the drag start and end
	[[self plotSpace0] doublePrecisionPlotPoint:start0 forPlotAreaViewPoint:dragStartInPlotArea];
	[[self plotSpace0] doublePrecisionPlotPoint:end0 forPlotAreaViewPoint:dragEndInPlotArea];
    
//    [[self plotSpace1] doublePrecisionPlotPoint:start1 forPlotAreaViewPoint:dragStartInPlotArea];
//    [[self plotSpace1] doublePrecisionPlotPoint:end1 forPlotAreaViewPoint:dragEndInPlotArea];
//    
//    [[self plotSpace2] doublePrecisionPlotPoint:start2 forPlotAreaViewPoint:dragStartInPlotArea];
//    [[self plotSpace2] doublePrecisionPlotPoint:end2 forPlotAreaViewPoint:dragEndInPlotArea];
    
	// recalculate the min and max values
	minXzoomForPlot = MIN(start0[CPTCoordinateX], end0[CPTCoordinateX]);
	maxXzoomForPlot = MAX(start0[CPTCoordinateX], end0[CPTCoordinateX]);
    
    [[self dataSource] setDataViewWithStartDateTime:(long)minXzoomForPlot
                                     AndEndDateTime:(long)maxXzoomForPlot
                                             AsZoom:YES];
    [self updateLines:[self dataSource]];
 
}

-(void)zoomOut
{
    [[self dataSource] unZoomDataView];
    [self updateLines:[self dataSource]];
}
//-(void)zoomInAndFitYAxis:(BOOL) fitYAxis;
//{
//	//CPTXYPlotSpace *plotSpace = (CPTXYPlotSpace *)graph.defaultPlotSpace;
//    TimeSeriesLine *tsLine = [[self timeSeriesLines] objectAtIndex:0];
//    NSString *plotIdentifier = [NSString stringWithFormat:@"P0_%@",[tsLine name]];
//    CPTScatterPlot *plot = (CPTScatterPlot *)[[self graph] plotWithIdentifier:plotIdentifier];
//    
//    double minXzoomForPlot;
//	double maxXzoomForPlot;
//	double minYzoomForPlot0;
//	double maxYzoomForPlot0;
//    double minYzoomForPlot1;
//	double maxYzoomForPlot1;
//    double minYzoomForPlot2;
//	double maxYzoomForPlot2;
//
//	// convert the dragStart and dragEnd values to plot coordinates
//	CGPoint dragStartInPlotArea = [[self graph] convertPoint:[self dragStart] toLayer:plot];
//	CGPoint dragEndInPlotArea	= [[self graph] convertPoint:[self dragEnd] toLayer:plot];
//    
//	double start0[2], end0[2], start1[2], end1[2], start2[2], end2[2];
//    
//	// obtain the datapoints for the drag start and end
//	[[self plotSpace0] doublePrecisionPlotPoint:start0 forPlotAreaViewPoint:dragStartInPlotArea];
//	[[self plotSpace0] doublePrecisionPlotPoint:end0 forPlotAreaViewPoint:dragEndInPlotArea];
//    
//    [[self plotSpace1] doublePrecisionPlotPoint:start1 forPlotAreaViewPoint:dragStartInPlotArea];
//    [[self plotSpace1] doublePrecisionPlotPoint:end1 forPlotAreaViewPoint:dragEndInPlotArea];
//    
//    [[self plotSpace2] doublePrecisionPlotPoint:start2 forPlotAreaViewPoint:dragStartInPlotArea];
//    [[self plotSpace2] doublePrecisionPlotPoint:end2 forPlotAreaViewPoint:dragEndInPlotArea];
//    
//	// recalculate the min and max values
//	minXzoomForPlot = MIN(start0[CPTCoordinateX], end0[CPTCoordinateX]);
//	maxXzoomForPlot = MAX(start0[CPTCoordinateX], end0[CPTCoordinateX]);
//    
//    NSDictionary *minMax = [[self plotData] setDataViewWithName:@"ZOOM"
//                                               AndStartDateTime:(long)minXzoomForPlot
//                                                 AndEndDateTime:(long)maxXzoomForPlot];
//    
//    [[self plotSpace0] setXRange:[CPTPlotRange plotRangeWithLocation:CPTDecimalFromDouble(minXzoomForPlot)
//                                                      length:CPTDecimalFromDouble(maxXzoomForPlot - minXzoomForPlot)]];
//    [[self overlayPlotSpace] setXRange:[[[self plotSpace0] xRange] copy]];
//    
//    [[self plotSpace1] setXRange:[[[self plotSpace0] xRange] copy]];
//    [[self plotSpace2] setXRange:[[[self plotSpace0] xRange] copy]];
//    
//    if(fitYAxis){
//        minYzoomForPlot0 = MIN(start0[CPTCoordinateY], end0[CPTCoordinateY]);
//        maxYzoomForPlot0 = MAX(start0[CPTCoordinateY], end0[CPTCoordinateY]);
//        [[self plotSpace0] setYRange:[CPTPlotRange plotRangeWithLocation:CPTDecimalFromDouble(minYzoomForPlot0)
//                                                           length:CPTDecimalFromDouble(maxYzoomForPlot0 - minYzoomForPlot0)]];
//        
//        minYzoomForPlot1 = MIN(start1[CPTCoordinateY], end1[CPTCoordinateY]);
//        maxYzoomForPlot1 = MAX(start1[CPTCoordinateY], end1[CPTCoordinateY]);
//        [[self plotSpace1] setYRange:[CPTPlotRange plotRangeWithLocation:CPTDecimalFromDouble(minYzoomForPlot1)
//                                                           length:CPTDecimalFromDouble(maxYzoomForPlot1 - minYzoomForPlot1)]];
//        
//        minYzoomForPlot2 = MIN(start2[CPTCoordinateY], end2[CPTCoordinateY]);
//        maxYzoomForPlot2 = MAX(start2[CPTCoordinateY], end2[CPTCoordinateY]);
//        [[self plotSpace2] setYRange:[CPTPlotRange plotRangeWithLocation:CPTDecimalFromDouble(minYzoomForPlot2)
//                                                           length:CPTDecimalFromDouble(maxYzoomForPlot2 - minYzoomForPlot2)]];
//        
//        //This is for any horizontal lines that have been added
//        if([[self lineAnnotationArray] count] > 0){
//        NSMutableArray *tempArray = [[NSMutableArray alloc] init];
//            for(int i = 0; i < [[self lineAnnotationLevelArray] count]; i++){
//                [[[[self graph] plotAreaFrame] plotArea] removeAnnotation:[[self lineAnnotationArray] objectAtIndex:i]];
//                [tempArray addObject:[NSNumber numberWithDouble:[[[self lineAnnotationLevelArray] objectAtIndex:i] doubleValue]]];
//            }
//            [[self lineAnnotationArray] removeAllObjects];
//            [[self lineAnnotationLevelArray] removeAllObjects];
//            for(int i = 0; i < [tempArray count]; i++){
//                [self addHorizontalLineAt:[[tempArray objectAtIndex:i] doubleValue] ForPlotspace:[self plotSpace0]];
//            }
//            [tempArray removeAllObjects];
//        }
//    }
//    [self setZoomedOut:NO];
//
//    BOOL dateAnnotateRequired = [self fixUpXAxisLabelsFrom:[[minMax objectForKey:@"MIN"] longValue]
//                                                        To:[[minMax objectForKey:@"MAX"] longValue]];
//    
//    while([[self dateAnnotationArray] count] > 0){
//        [[[[self graph] plotAreaFrame  ]plotArea] removeAnnotation:[[self dateAnnotationArray] objectAtIndex:0]];
//        [[self dateAnnotationArray] removeObjectAtIndex:0];
//    }
//    
//    if(dateAnnotateRequired){
//        long firstMidnight = [EpochTime epochTimeAtZeroHour:[self minXrangeForPlot]];
//        long lastMidnight = [EpochTime epochTimeNextDayAtZeroHour:[self maxXrangeForPlot]];
//        
//        CPTPlotRange *xRange  = [[self plotSpace0] xRange];
//        CPTPlotRange *yRange = [[self plotSpace0] yRange];
//        double minXrange = [[NSDecimalNumber decimalNumberWithDecimal:xRange.location] doubleValue];
//        double maxXrange = [[NSDecimalNumber decimalNumberWithDecimal:xRange.location] doubleValue] + [[NSDecimalNumber decimalNumberWithDecimal:xRange.length] doubleValue];
//        
//        CGRect bounds = NSRectToCGRect([[self hostingView]  bounds]);
//        
//        NSString *stringFromDate;
//        CPTMutableTextStyle *dateStringStyle;
//        NSArray *dateAnnotationPoint;
//        CPTTextLayer *textLayer;
//        NSDateFormatter *labelFormatter = [[NSDateFormatter alloc] init] ;
//        [labelFormatter setDateFormat:@"MM/dd"];
//        labelFormatter.timeZone = [NSTimeZone timeZoneWithName:@"GMT"];
//        CPTPlotSpaceAnnotation *dateAnnotation;
//        for(long labelDate = firstMidnight; labelDate <= lastMidnight; labelDate = labelDate + (60*60*24))
//        {
//            if((double)labelDate >= minXrange && labelDate <= (double)(maxXrange)){
//                stringFromDate = [labelFormatter stringFromDate:[NSDate dateWithTimeIntervalSince1970:labelDate]];
//                dateStringStyle = [CPTMutableTextStyle textStyle];
//                dateStringStyle.color	= [CPTColor redColor];
//                dateStringStyle.fontSize = round(bounds.size.height / (CGFloat)30.0);
//                dateStringStyle.fontName = @"Courier";
//            
//                // Determine point of symbol in plot coordinates
//                dateAnnotationPoint = [NSArray arrayWithObjects:[NSDecimalNumber numberWithLong:labelDate],[NSDecimalNumber decimalNumberWithDecimal: yRange.location], nil];
//            
//                textLayer = [[CPTTextLayer alloc] initWithText:stringFromDate style:dateStringStyle];
//                dateAnnotation = [[CPTPlotSpaceAnnotation alloc] initWithPlotSpace:[[self graph] defaultPlotSpace]   anchorPlotPoint:dateAnnotationPoint];
//                dateAnnotation.contentLayer = textLayer;
//                dateAnnotation.displacement =  CGPointMake( 0.0f,(CGFloat)10.0 );     
//                [[[[self graph] plotAreaFrame] plotArea] addAnnotation:dateAnnotation];
//                [[self dateAnnotationArray] addObject:dateAnnotation];
//            }
//        }
//    }
//}

//-(void)zoomOut
//{
//	// now adjust the plot range
//    [[self plotSpace0] setXRange:[self xRangeZoomOut]];
//	[[self plotSpace0] setYRange:[self yRange0ZoomOut]];
//
//    [[self overlayPlotSpace] setXRange:[[self xRangeZoomOut] copy]];
//    
//    [[self plotSpace1] setXRange:[self xRangeZoomOut]];
//    [[self plotSpace1] setYRange:[self yRange1ZoomOut]];
//    
//    [[self plotSpace2] setXRange:[self xRangeZoomOut]];
//    [[self plotSpace2] setYRange:[self yRange2ZoomOut]];
//    
//    BOOL dateAnnotateRequired = [self fixUpXAxisLabelsFrom:[[self dataView] minDateTime] To:[[self dataView] maxDateTime]];
// 
//    while([[self dateAnnotationArray] count] > 0){
//        [[[[self graph] plotAreaFrame] plotArea] removeAnnotation:[[self dateAnnotationArray] objectAtIndex:0]];
//        [[self dateAnnotationArray] removeObjectAtIndex:0];
//    }
//    if(dateAnnotateRequired){
//        long firstMidnight = [EpochTime epochTimeAtZeroHour:[self minXrangeForPlot]];
//        long lastMidnight = [EpochTime epochTimeNextDayAtZeroHour:[self maxXrangeForPlot]];
//        
//        CPTPlotRange *xRange  = [[self overlayPlotSpace] xRange];
//        CPTPlotRange *yRange = [[self overlayPlotSpace] yRange];
//        double minXrange = [[NSDecimalNumber decimalNumberWithDecimal:xRange.location] doubleValue];
//        double maxXrange = [[NSDecimalNumber decimalNumberWithDecimal:xRange.location] doubleValue] + [[NSDecimalNumber decimalNumberWithDecimal:xRange.length] doubleValue];
//        CGRect bounds = NSRectToCGRect([[self hostingView] bounds]);
//        
//        NSString *stringFromDate;
//        CPTMutableTextStyle *dateStringStyle;
//        NSArray *dateAnnotationPoint;
//        CPTTextLayer *textLayer;
//        NSDateFormatter *labelFormatter = [[NSDateFormatter alloc] init] ;
//        [labelFormatter setDateFormat:@"MM/dd"];
//        labelFormatter.timeZone = [NSTimeZone timeZoneWithName:@"GMT"];
//        CPTPlotSpaceAnnotation *dateAnnotation;
//        for(long labelDate = firstMidnight; labelDate <= lastMidnight; labelDate = labelDate + (60*60*24))
//        {
//            if((double)labelDate >= minXrange && labelDate <= (double)(maxXrange)){
//                stringFromDate = [labelFormatter stringFromDate:[NSDate dateWithTimeIntervalSince1970:labelDate]];
//                dateStringStyle = [CPTMutableTextStyle textStyle];
//                dateStringStyle.color	= [CPTColor redColor];
//                dateStringStyle.fontSize = round(bounds.size.height / (CGFloat)30.0);
//                dateStringStyle.fontName = @"Courier";
//                
//                // Determine point of symbol in plot coordinates
//                dateAnnotationPoint = [NSArray arrayWithObjects:[NSDecimalNumber numberWithLong:labelDate],[NSDecimalNumber decimalNumberWithDecimal: yRange.location], nil];
//                
//                textLayer = [[CPTTextLayer alloc] initWithText:stringFromDate style:dateStringStyle];
//                dateAnnotation = [[CPTPlotSpaceAnnotation alloc] initWithPlotSpace:[[self graph]defaultPlotSpace]   anchorPlotPoint:dateAnnotationPoint];
//                dateAnnotation.contentLayer = textLayer;
//                dateAnnotation.displacement =  CGPointMake( 0.0f,(CGFloat)10.0 );     
//                [[[[self graph] plotAreaFrame] plotArea] addAnnotation:dateAnnotation];
//                [[self dateAnnotationArray] addObject:dateAnnotation];
//            }
//        }
//    }
//    //This is for any horizontal lines that have been added
//    if([[self lineAnnotationArray] count] > 0){
//        NSMutableArray *tempArray = [[NSMutableArray alloc] init];
//        for(int i = 0; i < [[self lineAnnotationLevelArray] count]; i++){
//            [[[[self graph] plotAreaFrame] plotArea] removeAnnotation:[[self lineAnnotationArray] objectAtIndex:i]];
//            [tempArray addObject:[NSNumber numberWithDouble:[[[self lineAnnotationLevelArray] objectAtIndex:i] doubleValue]]];
//        }
//        [[self lineAnnotationArray] removeAllObjects];
//        [[self lineAnnotationLevelArray] removeAllObjects];
//        for(int i = 0; i < [tempArray count]; i++){
//            [self addHorizontalLineAt:[[tempArray objectAtIndex:i] doubleValue] ForPlotspace:[self plotSpace0]];
//        }
//        [tempArray removeAllObjects];
//    }
//
//    [self setZoomedOut:YES];
//}

//@synthesize hostingView = _hostingView;
//@synthesize identifier = _identifier;
//@synthesize plotData = _plotData;
//@synthesize dataView = _dataView;
//@synthesize graph = _graph;
//@synthesize timeSeriesLines = _timeSeriesLines;

@end
