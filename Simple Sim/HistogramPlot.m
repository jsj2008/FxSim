//
//  HistogramPlot.m
//  Simple Sim
//
//  Created by Martin on 11/07/2013.
//  Copyright (c) 2015 MARTIN OCONNOR. All rights reserved.
//

#import "HistogramPlot.h"
#import "UtilityFunctions.h"
#import "Simulation.h"

#define X_RANGE_XPAN_FACTOR 1.0
#define Y_RANGE_XPAN_FACTOR 1.1



@interface HistogramPlot()

- (NSDictionary *) getPlotRange;
- (void) setupHistogramPlots;
- (void) setPlotAxesAndPlotSpace;

@property (retain) CPTXYGraph *graph;
@property (retain) CPTPlotSpaceAnnotation *symbolTextAnnotation;;

@property int majorIntervalForX;
@property double minXrange;
@property double maxXrange;

@property double minYrange;
@property double maxYrange;

@property BOOL plot1AxisVisible;
@property BOOL plot2AxisVisible;
@property (retain) CPTXYPlotSpace *plotSpace0;
@property (retain) CPTXYAxis *xAxis;
@property (retain) CPTXYAxis *yAxis;
@property (retain) CPTPlotSpaceAnnotation *zoomAnnotation;
@property (retain) CPTLayer *interactionLayer;
@property CGPoint dragStart;
@property CGPoint dragEnd;

@property (retain) NSArray *midpointsNegA;
@property (retain) NSArray *midpointsPosA;
@property (retain) NSArray *midpointsNegB;
@property (retain) NSArray *midpointsPosB;
@property (retain) NSArray *heightsPosA;
@property (retain) NSArray *heightsNegA;
@property (retain) NSArray *heightsPosB;
@property (retain) NSArray *heightsNegB;
@property (retain) NSArray *countsPosA;
@property (retain) NSArray *countsNegA;
@property (retain) NSArray *countsPosB;
@property (retain) NSArray *countsNegB;
@property (retain) NSArray *midpointsA;
@property (retain) NSArray *midpointsB;
@property (retain) NSArray *heightsA;
@property (retain) NSArray *heightsB;
@property (retain) NSArray *countsA;
@property (retain) NSArray *countsB;

@property BOOL simBIncluded;
@property double midpointsStep;
@property BOOL zeroCentered;
@end

@implementation HistogramPlot


-(id)initWithIdentifier:(NSString*) identifierString
{
    if ( (self = [super init]) ) {
        _identifier = identifierString;
        _numberOfBins = 10;
        _zeroCentered = YES;

        _simBIncluded = NO;
    }
    return self;
}


- (void)  setupHistogramPlots
{
    
    // Create a bar line style
    CPTMutableLineStyle *barLineStyle = [[CPTMutableLineStyle alloc] init];
    barLineStyle.lineWidth = 1.0;
    barLineStyle.lineColor = [CPTColor grayColor];

    [[self graph] removeAllAnnotations];
    
    NSArray *previousPlots = [[self graph] allPlots];
    for(int i = 0; i <[previousPlots count]; i++){
        CPTPlot *plot = [previousPlots objectAtIndex:i];
        [[self graph] removePlot:plot];
    }
    
    if([self zeroCentered]){
        
        // Create first bar plot
        CPTBarPlot *barPlot = [[CPTBarPlot alloc] init];
        barPlot.lineStyle = barLineStyle;
        barPlot.fill			= [CPTFill fillWithColor:[CPTColor colorWithComponentRed:1.0f green:0.0f blue:0.0f alpha:0.5f]];
        barPlot.barBasesVary	= YES;
        barPlot.barWidth		= CPTDecimalFromDouble([self midpointsStep]);
        barPlot.barCornerRadius = 0.0f;
        barPlot.barsAreHorizontal = NO;
        barPlot.labelTextStyle = nil;
        [barPlot setDataSource:self];
        [barPlot setDelegate:self];
        barPlot.identifier = @"NEGA";
        [[self graph] addPlot:barPlot toPlotSpace:[self plotSpace0]];
        
        
        // Create second bar plot
        barPlot = [[CPTBarPlot alloc] init];
        barPlot.lineStyle = barLineStyle;
        barPlot.fill			= [CPTFill fillWithColor:[CPTColor colorWithComponentRed:0.0f green:1.0f blue:0.0f alpha:0.5f]];
        barPlot.barBasesVary	= YES;
        barPlot.barWidth		= CPTDecimalFromFloat([self midpointsStep]); // bar is 50% of the available space
        barPlot.barCornerRadius = 0.0f;
        barPlot.barsAreHorizontal = NO;
        barPlot.labelTextStyle = nil;
        [barPlot setDataSource:self];
        [barPlot setDelegate:self];
        barPlot.identifier = @"POSA";
        [[self graph] addPlot:barPlot toPlotSpace:[self plotSpace0]];
        
        if([self simBIncluded]){
            // Create third bar plot
            barPlot = [[CPTBarPlot alloc] init];
            barPlot.lineStyle = barLineStyle;
            barPlot.fill			= [CPTFill fillWithColor:[CPTColor colorWithComponentRed:1.0f green:0.0f blue:0.0f alpha:0.25f]];
            barPlot.barBasesVary	= YES;
            barPlot.barWidth		= CPTDecimalFromFloat([self midpointsStep]); // bar is 50% of the available space
            barPlot.barCornerRadius = 0.0f;
            barPlot.barsAreHorizontal = NO;
            barPlot.labelTextStyle = nil;
            [barPlot setDataSource:self];
            [barPlot setDelegate:self];
            barPlot.identifier = @"NEGB";
            [[self graph] addPlot:barPlot toPlotSpace:[self plotSpace0]];
            
            // Create fourth bar plot
            barPlot = [[CPTBarPlot alloc] init];
            barPlot.lineStyle = barLineStyle;
            barPlot.fill			= [CPTFill fillWithColor:[CPTColor colorWithComponentRed:0.0f green:1.0f blue:0.0f alpha:0.25f]];
            barPlot.barBasesVary	= YES;
            barPlot.barWidth		= CPTDecimalFromFloat([self midpointsStep]); // bar is 50% of the available space
            barPlot.barCornerRadius = 0.0f;
            barPlot.barsAreHorizontal = NO;
            barPlot.labelTextStyle = nil;
            [barPlot setDataSource:self];
            [barPlot setDelegate:self];
            barPlot.identifier = @"POSB";
            [[self graph] addPlot:barPlot toPlotSpace:[self plotSpace0]];
        }
    }else{
         
        // Create first bar plot
        CPTBarPlot *barPlot = [[CPTBarPlot alloc] init];
        barPlot.lineStyle = barLineStyle;
        barPlot.fill			= [CPTFill fillWithColor:[CPTColor colorWithComponentRed:1.0f green:1.0f blue:1.0f alpha:0.75f]];
        barPlot.barBasesVary	= YES;
        barPlot.barWidth		= CPTDecimalFromDouble([self midpointsStep]);
        barPlot.barCornerRadius = 0.0f;
        barPlot.barsAreHorizontal = NO;
        barPlot.labelTextStyle = nil;
        [barPlot setDataSource:self];
        [barPlot setDelegate:self];
        barPlot.identifier = @"ALLA";
        [[self graph] addPlot:barPlot toPlotSpace:[self plotSpace0]];
        
        if([self simBIncluded]){
            // Create second bar plot
            barPlot = [[CPTBarPlot alloc] init];
            barPlot.lineStyle = barLineStyle;
            barPlot.fill			= [CPTFill fillWithColor:[CPTColor colorWithComponentRed:1.0f green:1.0f blue:1.0f alpha:0.5f]];
            barPlot.barBasesVary	= YES;
            barPlot.barWidth		= CPTDecimalFromFloat([self midpointsStep]); // bar is 50% of the available space
            barPlot.barCornerRadius = 0.0f;
            barPlot.barsAreHorizontal = NO;
            barPlot.labelTextStyle = nil;
            [barPlot setDataSource:self];
            [barPlot setDelegate:self];
            barPlot.identifier = @"ALLB";
            [[self graph] addPlot:barPlot toPlotSpace:[self plotSpace0]];
        }
    }
    
}

- (void) setPlotAxesAndPlotSpace
{
    NSDictionary *plotRangeDictionary = [self getPlotRange];
    double minX = [[plotRangeDictionary objectForKey:@"MINX"] doubleValue];
    double maxX = [[plotRangeDictionary objectForKey:@"MAXX"] doubleValue];
    double minY = [[plotRangeDictionary objectForKey:@"MINY"] doubleValue];
    double maxY = [[plotRangeDictionary objectForKey:@"MAXY"] doubleValue];
    
    BOOL plotB = ([[self midpointsPosB] count] > 0) || ([[self midpointsNegB] count] > 0);
    
  	CGRect bounds = NSRectToCGRect([[self hostingView] bounds]);
    [self setGraph:[[CPTXYGraph alloc] initWithFrame:bounds]];
    [[self hostingView] setHostedGraph:[self graph]];
	[[self graph] applyTheme:[CPTTheme themeNamed:kCPTDarkGradientTheme]];
    
    [[self graph] setPaddingLeft:0.0];
	[[self graph] setPaddingTop:0.0];
	[[self graph] setPaddingRight:0.0];
    [[self graph] setPaddingBottom:0.0];
    
    [[[self graph] plotAreaFrame] setPaddingLeft:60.0];
	[[[self graph] plotAreaFrame] setPaddingTop:30.0];
	[[[self graph] plotAreaFrame] setPaddingRight:30.0];
	[[[self graph] plotAreaFrame] setPaddingBottom:60.0];
    
	[[[[self graph] plotAreaFrame] plotArea] setFill:[[[self graph] plotAreaFrame] fill]];
    [[[self graph] plotAreaFrame] setFill:nil];
    
    [[[self graph] plotAreaFrame] setBorderLineStyle:nil];
    [[[self graph] plotAreaFrame] setCornerRadius:0.0];
    
    CPTMutablePlotRange *xRange;
    // Add plot space for bar charts
	CPTXYPlotSpace *barPlotSpace = [[CPTXYPlotSpace alloc] init];
    //CPTXYPlotSpace *barPlotSpace = [self plotSpace0];
    xRange = [CPTMutablePlotRange plotRangeWithLocation:CPTDecimalFromDouble(minX) length:CPTDecimalFromDouble(maxX-minX)];
    [xRange expandRangeByFactor:CPTDecimalFromDouble(X_RANGE_XPAN_FACTOR)];
	barPlotSpace.xRange = xRange;
    
    
    if(plotB){
        barPlotSpace.yRange = [CPTPlotRange plotRangeWithLocation:CPTDecimalFromDouble(minY) length:CPTDecimalFromDouble(maxY-minY)];
    }else{
        barPlotSpace.yRange = [CPTPlotRange plotRangeWithLocation:CPTDecimalFromDouble(0) length:CPTDecimalFromDouble(maxY)];
    }
    [barPlotSpace setDelegate:self];
	[[self graph] addPlotSpace:barPlotSpace];
    
	// Create axes
	CPTXYAxisSet *axisSet = (CPTXYAxisSet *)[[self graph] axisSet];
	CPTXYAxis *xAxis		  = axisSet.xAxis;
    [xAxis setLabelingPolicy:CPTAxisLabelingPolicyNone];
    
    CPTMutableLineStyle *majorGridLineStyle = [CPTMutableLineStyle lineStyle];
    majorGridLineStyle.lineWidth = 0.75;
    majorGridLineStyle.lineColor = [[CPTColor colorWithGenericGray:0.2] colorWithAlphaComponent:0.75];
    
    CPTMutableLineStyle *minorGridLineStyle = [CPTMutableLineStyle lineStyle];
    minorGridLineStyle.lineWidth = 0.25;
    minorGridLineStyle.lineColor = [[CPTColor whiteColor] colorWithAlphaComponent:0.1];
    
    CPTMutableLineStyle *axisLineStyle =  [CPTMutableLineStyle lineStyle];
    axisLineStyle.lineWidth = 0.5;
    axisLineStyle.lineColor = [[CPTColor whiteColor] colorWithAlphaComponent:0.5];
    
    
    NSSet *tickLocationSet = [[NSSet alloc] init];
    tickLocationSet = [tickLocationSet setByAddingObjectsFromArray:[self midpointsNegA]];
    tickLocationSet = [tickLocationSet setByAddingObjectsFromArray:[self midpointsNegB]];
    tickLocationSet = [tickLocationSet setByAddingObjectsFromArray:[self midpointsPosA]];
    tickLocationSet = [tickLocationSet setByAddingObjectsFromArray:[self midpointsPosB]];
    tickLocationSet = [tickLocationSet setByAddingObject:[NSNumber numberWithDouble:0.0]];
    
    NSArray *tickLocations = [tickLocationSet allObjects];
    
    NSUInteger labelLocation = 0;
    double tickLocationDouble;
    NSMutableArray *customLabels = [NSMutableArray arrayWithCapacity:[tickLocations count]];
    for (NSNumber *tickLocation in tickLocations) {
        tickLocationDouble = [[tickLocations objectAtIndex:labelLocation++] doubleValue];
        CPTAxisLabel *newLabel = [[CPTAxisLabel alloc] initWithText: [NSString stringWithFormat:@"%5.1f",tickLocationDouble] textStyle:[xAxis labelTextStyle]];
        newLabel.tickLocation = [tickLocation decimalValue];
        newLabel.offset = [xAxis labelOffset] + [xAxis majorTickLength];
        newLabel.rotation = M_PI/4;
        [customLabels addObject:newLabel];
    }
    
    [xAxis setMajorTickLocations:tickLocationSet];
    [xAxis setAxisLabels:[NSSet setWithArray:customLabels]];
    
    [xAxis setMajorGridLineStyle:majorGridLineStyle];
    [xAxis setMinorGridLineStyle:minorGridLineStyle];
    [xAxis setAxisLineStyle:axisLineStyle];
    [xAxis setTickDirection:CPTSignNegative];
    [xAxis setMajorTickLineStyle:nil];
    [xAxis setMinorTickLineStyle:nil];
    
    xRange = [CPTMutablePlotRange plotRangeWithLocation:CPTDecimalFromDouble(minX) length:CPTDecimalFromDouble(maxX-minX)];
    [xRange expandRangeByFactor:CPTDecimalFromDouble(X_RANGE_XPAN_FACTOR)];
    xAxis.visibleRange	 = xRange;
    xAxis.plotSpace = barPlotSpace;
    
	CPTXYAxis *yAxis = axisSet.yAxis;
	
    int nTicks = 10;
    double d;
    double yAxisMin = 0.0;
    double yAxisMax = 0.0;
    double range = [UtilityFunctions niceNumber: maxY-minY
                                   withRounding: NO];
    if(range > 0){
        d = [UtilityFunctions niceNumber:range/(nTicks - 1)
                            withRounding:YES];
        if(plotB){
            yAxisMin = floor(minY/d)*d;
        }
        yAxisMax = ceil(maxY/d)*d;
    }else{
        d = [UtilityFunctions niceNumber:2.0/(nTicks - 1)
                            withRounding:YES];
        if(plotB){
            yAxisMin = minY - 1;
        }
        yAxisMax = maxY + 1;
    }
    
    int nfrac = -floor(log10(d));
    if(nfrac < 0){
        nfrac = 0;
    }
    
    // Grid line styles
    majorGridLineStyle = [CPTMutableLineStyle lineStyle];
    majorGridLineStyle.lineWidth = 0.75;
    majorGridLineStyle.lineColor = [[CPTColor colorWithGenericGray:0.2] colorWithAlphaComponent:0.75];
    
    minorGridLineStyle = [CPTMutableLineStyle lineStyle];
    minorGridLineStyle.lineWidth = 0.25;
    minorGridLineStyle.lineColor = [[CPTColor whiteColor] colorWithAlphaComponent:0.1];
    
    yAxis.majorGridLineStyle		  = majorGridLineStyle;
    yAxis.minorGridLineStyle		  = minorGridLineStyle;
    
    
    axisLineStyle =  [CPTMutableLineStyle lineStyle];
    axisLineStyle.lineWidth = 0.5;
    axisLineStyle.lineColor = [[CPTColor whiteColor] colorWithAlphaComponent:0.5];
    [yAxis setLabelOffset:5.0];
    
    [yAxis setMajorIntervalLength:CPTDecimalFromDouble(d)];
    [yAxis setMinorTicksPerInterval:1];
    
    [yAxis setAxisLineStyle:axisLineStyle];
    [yAxis setTickDirection:CPTSignNegative];
    [yAxis setAxisConstraints:[CPTConstraints constraintWithLowerOffset:0.0]];
    
    NSNumberFormatter *numberFormatter = [[NSNumberFormatter alloc] init];
    [numberFormatter setNumberStyle:NSNumberFormatterDecimalStyle];
    [numberFormatter setMinimumFractionDigits:nfrac];
    yAxis.labelFormatter = numberFormatter;
    
    CPTMutablePlotRange *yRange;
    if(plotB){
        yRange = [CPTMutablePlotRange plotRangeWithLocation:CPTDecimalFromDouble(yAxisMin)
                                                     length:CPTDecimalFromDouble((yAxisMax-yAxisMin)+(0.5*d))];
        [yRange expandRangeByFactor:CPTDecimalFromDouble(Y_RANGE_XPAN_FACTOR)];
    }else{
        yRange = [CPTMutablePlotRange plotRangeWithLocation:CPTDecimalFromDouble(0.0)
                                                     length:CPTDecimalFromDouble((yAxisMax)+(0.5*d))];
    }
    
    [yAxis setPlotSpace:barPlotSpace];
    [barPlotSpace setYRange:yRange];
    
    xAxis.orthogonalCoordinateDecimal = yRange.location;
    yAxis.orthogonalCoordinateDecimal = xRange.location;
    
    
    CPTMutableTextStyle *newTextStyle;
    newTextStyle = [[yAxis labelTextStyle] mutableCopy];
    [newTextStyle setColor:[CPTColor whiteColor]];
    [yAxis setLabelTextStyle:newTextStyle];
    
	// Set axes
	[[[self graph] axisSet] setAxes:[NSArray arrayWithObjects:xAxis, yAxis, nil]];
    
    [self setPlotSpace0:barPlotSpace];
    
    [self  setupHistogramPlots];
}



//- (void)  setupHistogram
//{

//    NSDictionary *plotRangeDictionary = [self getPlotRange];
//    double minX = [[plotRangeDictionary objectForKey:@"MINX"] doubleValue];
//    double maxX = [[plotRangeDictionary objectForKey:@"MAXX"] doubleValue];
//    double minY = [[plotRangeDictionary objectForKey:@"MINY"] doubleValue];
//    double maxY = [[plotRangeDictionary objectForKey:@"MAXY"] doubleValue];
//
//    BOOL plotB = ([[self midpointsPosB] count] > 0) || ([[self midpointsNegB] count] > 0);
//    
//  	CGRect bounds = NSRectToCGRect([[self hostingView] bounds]);
//    [self setGraph:[[CPTXYGraph alloc] initWithFrame:bounds]];
//    [[self hostingView] setHostedGraph:[self graph]];
//	[[self graph] applyTheme:[CPTTheme themeNamed:kCPTDarkGradientTheme]];
//    
//    [[self graph] setPaddingLeft:0.0];
//	[[self graph] setPaddingTop:0.0];
//	[[self graph] setPaddingRight:0.0];
//    [[self graph] setPaddingBottom:0.0];
//    
//    [[[self graph] plotAreaFrame] setPaddingLeft:60.0];
//	[[[self graph] plotAreaFrame] setPaddingTop:30.0];
//	[[[self graph] plotAreaFrame] setPaddingRight:30.0];
//	[[[self graph] plotAreaFrame] setPaddingBottom:60.0];
//    
//	[[[[self graph] plotAreaFrame] plotArea] setFill:[[[self graph] plotAreaFrame] fill]];
//    [[[self graph] plotAreaFrame] setFill:nil];
//    
//    [[[self graph] plotAreaFrame] setBorderLineStyle:nil];
//    [[[self graph] plotAreaFrame] setCornerRadius:0.0];
//    
//    CPTMutablePlotRange *xRange;
//    // Add plot space for bar charts
//	CPTXYPlotSpace *barPlotSpace = [[CPTXYPlotSpace alloc] init];
//    xRange = [CPTMutablePlotRange plotRangeWithLocation:CPTDecimalFromDouble(minX) length:CPTDecimalFromDouble(maxX-minX)];
//    [xRange expandRangeByFactor:CPTDecimalFromDouble(X_RANGE_XPAN_FACTOR)];
//	barPlotSpace.xRange = xRange;
//    
//    
//    if(plotB){
//        barPlotSpace.yRange = [CPTPlotRange plotRangeWithLocation:CPTDecimalFromDouble(minY) length:CPTDecimalFromDouble(maxY-minY)];
//    }else{
//         barPlotSpace.yRange = [CPTPlotRange plotRangeWithLocation:CPTDecimalFromDouble(0) length:CPTDecimalFromDouble(maxY)];
//    }
//    [barPlotSpace setDelegate:self];
//	[[self graph] addPlotSpace:barPlotSpace];
//    
//	// Create axes
//	CPTXYAxisSet *axisSet = (CPTXYAxisSet *)[[self graph] axisSet];
//	CPTXYAxis *xAxis		  = axisSet.xAxis;
//    [xAxis setLabelingPolicy:CPTAxisLabelingPolicyNone];
//    
//    CPTMutableLineStyle *majorGridLineStyle = [CPTMutableLineStyle lineStyle];
//    majorGridLineStyle.lineWidth = 0.75;
//    majorGridLineStyle.lineColor = [[CPTColor colorWithGenericGray:0.2] colorWithAlphaComponent:0.75];
//    
//    CPTMutableLineStyle *minorGridLineStyle = [CPTMutableLineStyle lineStyle];
//    minorGridLineStyle.lineWidth = 0.25;
//    minorGridLineStyle.lineColor = [[CPTColor whiteColor] colorWithAlphaComponent:0.1];
//    
//    CPTMutableLineStyle *axisLineStyle =  [CPTMutableLineStyle lineStyle];
//    axisLineStyle.lineWidth = 0.5;
//    axisLineStyle.lineColor = [[CPTColor whiteColor] colorWithAlphaComponent:0.5];
//    
//    
//    NSSet *tickLocationSet = [[NSSet alloc] init];
//    tickLocationSet = [tickLocationSet setByAddingObjectsFromArray:[self midpointsNegA]];
//    tickLocationSet = [tickLocationSet setByAddingObjectsFromArray:[self midpointsNegB]];
//    tickLocationSet = [tickLocationSet setByAddingObjectsFromArray:[self midpointsPosA]];
//    tickLocationSet = [tickLocationSet setByAddingObjectsFromArray:[self midpointsPosB]];
//    tickLocationSet = [tickLocationSet setByAddingObject:[NSNumber numberWithDouble:0.0]];
//    
//    NSArray *tickLocations = [tickLocationSet allObjects];
//    
//    NSUInteger labelLocation = 0;
//    double tickLocationDouble;
//    NSMutableArray *customLabels = [NSMutableArray arrayWithCapacity:[tickLocations count]];
//    for (NSNumber *tickLocation in tickLocations) {
//        tickLocationDouble = [[tickLocations objectAtIndex:labelLocation++] doubleValue];
//        CPTAxisLabel *newLabel = [[CPTAxisLabel alloc] initWithText: [NSString stringWithFormat:@"%5.1f",tickLocationDouble] textStyle:[xAxis labelTextStyle]];
//        newLabel.tickLocation = [tickLocation decimalValue];
//        newLabel.offset = [xAxis labelOffset] + [xAxis majorTickLength];
//        newLabel.rotation = M_PI/4;
//        [customLabels addObject:newLabel];
//    }
//    
//    [xAxis setMajorTickLocations:tickLocationSet];
//    [xAxis setAxisLabels:[NSSet setWithArray:customLabels]];
//    
//    [xAxis setMajorGridLineStyle:majorGridLineStyle];
//    [xAxis setMinorGridLineStyle:minorGridLineStyle];
//    [xAxis setAxisLineStyle:axisLineStyle];
//    [xAxis setTickDirection:CPTSignNegative];
//    [xAxis setMajorTickLineStyle:nil];
//    [xAxis setMinorTickLineStyle:nil];
//    
//    xRange = [CPTMutablePlotRange plotRangeWithLocation:CPTDecimalFromDouble(minX) length:CPTDecimalFromDouble(maxX-minX)];
//    [xRange expandRangeByFactor:CPTDecimalFromDouble(X_RANGE_XPAN_FACTOR)];
//    xAxis.visibleRange	 = xRange;
//    xAxis.plotSpace = barPlotSpace;
//    
//	CPTXYAxis *yAxis = axisSet.yAxis;
//	
//    int nTicks = 10;
//    double d;
//    double yAxisMin = 0.0;
//    double yAxisMax = 0.0;
//    double range = [UtilityFunctions niceNumber: maxY-minY
//                                   withRounding: NO];
//    if(range > 0){
//        d = [UtilityFunctions niceNumber:range/(nTicks - 1)
//                            withRounding:YES];
//        if(plotB){
//            yAxisMin = floor(minY/d)*d;
//        }
//        yAxisMax = ceil(maxY/d)*d;
//    }else{
//        d = [UtilityFunctions niceNumber:2.0/(nTicks - 1)
//                            withRounding:YES];
//        if(plotB){
//            yAxisMin = minY - 1;
//        }
//        yAxisMax = maxY + 1;
//    }
//    
//    int nfrac = -floor(log10(d));
//    if(nfrac < 0){
//        nfrac = 0;
//    }
//    
//    // Grid line styles
//    majorGridLineStyle = [CPTMutableLineStyle lineStyle];
//    majorGridLineStyle.lineWidth = 0.75;
//    majorGridLineStyle.lineColor = [[CPTColor colorWithGenericGray:0.2] colorWithAlphaComponent:0.75];
//    
//    minorGridLineStyle = [CPTMutableLineStyle lineStyle];
//    minorGridLineStyle.lineWidth = 0.25;
//    minorGridLineStyle.lineColor = [[CPTColor whiteColor] colorWithAlphaComponent:0.1];
//    
//    yAxis.majorGridLineStyle		  = majorGridLineStyle;
//    yAxis.minorGridLineStyle		  = minorGridLineStyle;
//    
//    
//    axisLineStyle =  [CPTMutableLineStyle lineStyle];
//    axisLineStyle.lineWidth = 0.5;
//    axisLineStyle.lineColor = [[CPTColor whiteColor] colorWithAlphaComponent:0.5];
//    [yAxis setLabelOffset:5.0];
//    
//    [yAxis setMajorIntervalLength:CPTDecimalFromDouble(d)];
//    [yAxis setMinorTicksPerInterval:1];
//    
//    [yAxis setAxisLineStyle:axisLineStyle];
//    [yAxis setTickDirection:CPTSignNegative];
//    [yAxis setAxisConstraints:[CPTConstraints constraintWithLowerOffset:0.0]];
//    
//    NSNumberFormatter *numberFormatter = [[NSNumberFormatter alloc] init];
//    [numberFormatter setNumberStyle:NSNumberFormatterDecimalStyle];
//    [numberFormatter setMinimumFractionDigits:nfrac];
//    yAxis.labelFormatter = numberFormatter;
//    
//    CPTMutablePlotRange *yRange;
//    if(plotB){
//        yRange = [CPTMutablePlotRange plotRangeWithLocation:CPTDecimalFromDouble(yAxisMin)
//                                                                      length:CPTDecimalFromDouble((yAxisMax-yAxisMin)+(0.5*d))];
//        [yRange expandRangeByFactor:CPTDecimalFromDouble(Y_RANGE_XPAN_FACTOR)];
//    }else{
//        yRange = [CPTMutablePlotRange plotRangeWithLocation:CPTDecimalFromDouble(0.0)
//                                                     length:CPTDecimalFromDouble((yAxisMax)+(0.5*d))];
//    }
//     
//    [yAxis setPlotSpace:barPlotSpace];
//    [barPlotSpace setYRange:yRange];
//    
//    xAxis.orthogonalCoordinateDecimal = yRange.location;
//    yAxis.orthogonalCoordinateDecimal = xRange.location;
//    
//    
//    CPTMutableTextStyle *newTextStyle;
//    newTextStyle = [[yAxis labelTextStyle] mutableCopy];
//    [newTextStyle setColor:[CPTColor whiteColor]];
//    [yAxis setLabelTextStyle:newTextStyle];
//   
//	// Set axes
//	[[[self graph] axisSet] setAxes:[NSArray arrayWithObjects:xAxis, yAxis, nil]];
    
	// Create a bar line style
//    CPTMutableLineStyle *barLineStyle = [[CPTMutableLineStyle alloc] init];
//    barLineStyle.lineWidth = 1.0;
//    barLineStyle.lineColor = [CPTColor grayColor];
//    
//	// Create first bar plot
//	CPTBarPlot *barPlot = [[CPTBarPlot alloc] init];
//    barPlot.lineStyle = barLineStyle;
//	barPlot.fill			= [CPTFill fillWithColor:[CPTColor colorWithComponentRed:1.0f green:0.0f blue:0.0f alpha:0.5f]];
//	barPlot.barBasesVary	= YES;
//	barPlot.barWidth		= CPTDecimalFromDouble([self midpointsStep]);
//    barPlot.barCornerRadius = 0.0f;
//	barPlot.barsAreHorizontal = NO;
//	barPlot.labelTextStyle = nil;
//	[barPlot setDataSource:self];
//    [barPlot setDelegate:self];
//    barPlot.identifier = @"NEGA";
//	[[self graph] addPlot:barPlot toPlotSpace:[self plotSpace0]];
// 
//    
//    // Create second bar plot
//    barPlot = [[CPTBarPlot alloc] init];
//    barPlot.lineStyle = barLineStyle;
//	barPlot.fill			= [CPTFill fillWithColor:[CPTColor colorWithComponentRed:0.0f green:1.0f blue:0.0f alpha:0.5f]];
//	barPlot.barBasesVary	= YES;
//	barPlot.barWidth		= CPTDecimalFromFloat([self midpointsStep]); // bar is 50% of the available space
//	barPlot.barCornerRadius = 0.0f;
//	barPlot.barsAreHorizontal = NO;
//	barPlot.labelTextStyle = nil;
//    [barPlot setDataSource:self];
//    [barPlot setDelegate:self];
//	barPlot.identifier = @"POSA";
//	[[self graph] addPlot:barPlot toPlotSpace:[self plotSpace0]];
//    
//    // Create third bar plot
//	barPlot = [[CPTBarPlot alloc] init];
//    barPlot.lineStyle = nil;
//	barPlot.fill			= [CPTFill fillWithColor:[CPTColor colorWithComponentRed:1.0f green:0.0f blue:0.0f alpha:0.25f]];
//	barPlot.barBasesVary	= YES;
//	barPlot.barWidth		= CPTDecimalFromFloat(1.0f); // bar is 50% of the available space
//	barPlot.barCornerRadius = 0.0f;
//	barPlot.barsAreHorizontal = NO;
//	barPlot.labelTextStyle = nil;
//	[barPlot setDataSource:self];
//    [barPlot setDelegate:self];
//	barPlot.identifier = @"NEGB";
//	[[self graph] addPlot:barPlot toPlotSpace:[self plotSpace0]];
//    
//    // Create fourth bar plot
//    barPlot = [[CPTBarPlot alloc] init];
//    barPlot.lineStyle = nil;
//	barPlot.fill			= [CPTFill fillWithColor:[CPTColor colorWithComponentRed:0.0f green:1.0f blue:0.0f alpha:0.25f]];
//	barPlot.barBasesVary	= YES;
//	barPlot.barWidth		= CPTDecimalFromFloat(1.0f); // bar is 50% of the available space
//	barPlot.barCornerRadius = 0.0f;
//	barPlot.barsAreHorizontal = NO;
//	barPlot.labelTextStyle = nil;
//    [barPlot setDataSource:self];
//    [barPlot setDelegate:self];
//	barPlot.identifier = @"POSB";
//	[[self graph] addPlot:barPlot toPlotSpace:[self plotSpace0]];
//    
//}



- (void) createHistogramDataForSim: (Simulation *) simA
                    andOptionalSim: (Simulation *) simB
{
    int nBins = [self numberOfBins];
    BOOL zeroCentered = [self zeroCentered];
    BOOL simBIncluded = !(simB==nil);
    
    [self setSimBIncluded:simBIncluded];
    
    NSDictionary *signalAnalysisDetails;
    NSMutableArray *positiveReturnsA, *negativeReturnsA, *returnsA, *positiveReturnsB, *negativeReturnsB, *returnsB;
    if(zeroCentered){
        positiveReturnsA = [[NSMutableArray alloc] init];
        negativeReturnsA = [[NSMutableArray alloc] init];
        positiveReturnsB = [[NSMutableArray alloc] init];
        negativeReturnsB = [[NSMutableArray alloc] init];
    }else{
        returnsA = [[NSMutableArray alloc] init];
        returnsB = [[NSMutableArray alloc] init];
    }
    long numberOfSignalsA = [simA numberOfSignals];
    long numberOfSignalsB;
    if(simBIncluded){
        numberOfSignalsB = [simB numberOfSignals];
    }else{
        numberOfSignalsB = 0;
    }
    
    double pnl;
    double binsStep, binsMin, binsMax;
    double minReturn, maxReturn;
    int newNBinsNeg=0, newNBins = 0;
    
    BOOL A = numberOfSignalsA > 0;
    BOOL B = numberOfSignalsB > 0;
    
    double totalPnl = 0.0;
    
    if(A || B){
        if(self.zeroCentered){
            if(A){
                for(int i = 0; i < numberOfSignalsA; i++){
                    signalAnalysisDetails = [simA detailsOfSignalAtIndex:i];
                    pnl = [[signalAnalysisDetails objectForKey:@"PNL"] doubleValue];
                    totalPnl = totalPnl + pnl;
                    if(pnl <0 ){
                        [negativeReturnsA addObject:[signalAnalysisDetails objectForKey:@"PNL"]];
                    }else{
                        [positiveReturnsA addObject:[signalAnalysisDetails objectForKey:@"PNL"]];
                    }
                    
                }
                
                NSSortDescriptor* sortOrder = [NSSortDescriptor sortDescriptorWithKey: @"self" ascending: YES];
                [positiveReturnsA sortUsingDescriptors:[NSArray arrayWithObject: sortOrder]];
                [negativeReturnsA sortUsingDescriptors:[NSArray arrayWithObject: sortOrder]];
                if([negativeReturnsA count] > 0){
                    minReturn = [[negativeReturnsA objectAtIndex:0] doubleValue];
                }else{
                    minReturn = [[positiveReturnsA objectAtIndex:0] doubleValue];
                }
                if([positiveReturnsA count] > 0){
                    maxReturn = [[positiveReturnsA objectAtIndex:[positiveReturnsA count]-1] doubleValue];
                }else{
                    maxReturn = [[negativeReturnsA objectAtIndex:[negativeReturnsA count]-1] doubleValue];
                }
            }
            
            if(B){
                for(int i = 0; i < numberOfSignalsB; i++){
                    signalAnalysisDetails = [simB detailsOfSignalAtIndex:i];
                    pnl = [[signalAnalysisDetails objectForKey:@"PNL"] doubleValue];
                    
                    if(pnl <0 ){
                        [negativeReturnsB addObject:[signalAnalysisDetails objectForKey:@"PNL"]];
                    }else{
                        [positiveReturnsB addObject:[signalAnalysisDetails objectForKey:@"PNL"]];
                    }
                    
                }
                
                NSSortDescriptor* sortOrder = [NSSortDescriptor sortDescriptorWithKey: @"self" ascending: YES];
                [positiveReturnsB sortUsingDescriptors:[NSArray arrayWithObject: sortOrder]];
                [negativeReturnsB sortUsingDescriptors:[NSArray arrayWithObject: sortOrder]];
                if([negativeReturnsB count] > 0){
                    if(A){
                         minReturn = MIN(minReturn,[[negativeReturnsB objectAtIndex:0] doubleValue]);
                    }else{
                         minReturn = [[negativeReturnsB objectAtIndex:0] doubleValue];
                    }
                   
                }else{
                    if(A){
                        minReturn = MIN(minReturn,[[positiveReturnsB objectAtIndex:0] doubleValue]);
                    }else{
                        minReturn = [[positiveReturnsB objectAtIndex:0] doubleValue];
                    }
                }
                if([positiveReturnsB count] > 0){
                    if(A){
                        maxReturn = MAX(maxReturn,[[positiveReturnsB objectAtIndex:[positiveReturnsB count]-1] doubleValue]);
                    }else{
                        maxReturn = [[positiveReturnsB objectAtIndex:[positiveReturnsB count]-1] doubleValue];
                    }
                }else{
                    if(A){
                        maxReturn = MAX(maxReturn,[[negativeReturnsB objectAtIndex:[negativeReturnsB count]-1] doubleValue]);
                    }else{
                        maxReturn = [[negativeReturnsB objectAtIndex:[negativeReturnsB count]-1] doubleValue];
                    }
                }
            }
            
            int  newNBinsPos = 0;
            
            BOOL posRets = [positiveReturnsA count] > 0 || [positiveReturnsB count] > 0;
            BOOL negRets = [negativeReturnsA count] > 0 || [negativeReturnsB count] > 0;
            
            if(posRets && negRets){
                binsStep = (maxReturn - minReturn)/(nBins-1);
                newNBinsPos = (int)ceil(fabs(maxReturn/binsStep));
                newNBinsNeg =  (int)ceil(fabs(minReturn/binsStep));
                newNBins = newNBinsNeg + newNBinsPos;
                binsMin =  binsStep * -newNBinsNeg;
            }else{
                if(negRets){
                    if(nBins > 1){
                        binsStep = (maxReturn - minReturn)/(nBins - 1);
                        binsMin = -binsStep*ceil(minReturn/binsStep);
                        binsMax = -binsStep*floor(maxReturn/binsStep);
                        newNBins = (int)((binsMax - binsMin)/binsStep) + 1;
                        newNBinsNeg = 1;
                    }
                    if(nBins == 1){
                        binsStep = minReturn;
                        binsMin = minReturn;
                        newNBins = 1;
                        newNBinsNeg = 1;
                    }
                }
                if(posRets){
                    if(nBins > 1){
                        binsStep = (maxReturn - minReturn)/(nBins - 1);
                        binsMin = binsStep*floor(minReturn/binsStep);
                        binsMax = binsStep*ceil(maxReturn/binsStep);
                        newNBins = (int)((binsMax - binsMin)/binsStep);
                        newNBinsNeg = 0;
                    }
                    if(nBins == 1){
                        binsStep = maxReturn;
                        binsMin = 0;
                        binsMax = maxReturn;
                        newNBins = 1;
                        newNBinsNeg = 0;
                    }
                }
            }
            double binLower, currentReturn;
            int binIndex = -1;
            
            NSMutableData *countsNegAData = [[NSMutableData alloc] initWithLength:sizeof(long) *newNBinsNeg];
            long *countsNegAArray = (long *)[countsNegAData bytes];
            NSMutableData *countsPosAData = [[NSMutableData alloc] initWithLength:sizeof(long) *(newNBins -newNBinsNeg)];
            long *countsPosAArray = (long *)[countsPosAData bytes];
            
            NSMutableData *heightsNegAData = [[NSMutableData alloc] initWithLength:sizeof(double) *newNBinsNeg];
            double *heightsNegAArray = (double *)[heightsNegAData bytes];
            NSMutableData *heightsPosAData = [[NSMutableData alloc] initWithLength:sizeof(double) *(newNBins -newNBinsNeg)];
            double *heightsPosAArray = (double *)[heightsPosAData bytes];
            
            NSMutableData *midpointsNegAData = [[NSMutableData alloc] initWithLength:sizeof(double) *newNBinsNeg];
            double *midpointsNegAArray = (double *)[midpointsNegAData bytes];
            NSMutableData *midpointsPosAData = [[NSMutableData alloc] initWithLength:sizeof(double) *(newNBins -newNBinsNeg)];
            double *midpointsPosAArray = (double *)[midpointsPosAData bytes];
            
            NSMutableData *countsNegBData, *countsPosBData, *heightsNegBData, *heightsPosBData, *midpointsNegBData,*midpointsPosBData;
            double *heightsNegBArray, *heightsPosBArray, *midpointsNegBArray, *midpointsPosBArray;
            long *countsNegBArray, *countsPosBArray;
            
            if(B){
                countsNegBData = [[NSMutableData alloc] initWithLength:sizeof(long) *newNBinsNeg];
                countsNegBArray = (long *)[countsNegBData bytes];
                countsPosBData = [[NSMutableData alloc] initWithLength:sizeof(long) *(newNBins -newNBinsNeg)];
                countsPosBArray = (long *)[countsPosBData bytes];
                
                heightsNegBData = [[NSMutableData alloc] initWithLength:sizeof(double) *newNBinsNeg];
                heightsNegBArray = (double *)[heightsNegBData bytes];
                heightsPosBData = [[NSMutableData alloc] initWithLength:sizeof(double) *(newNBins -newNBinsNeg)];
                heightsPosBArray = (double *)[heightsPosBData bytes];
                
                midpointsNegBData = [[NSMutableData alloc] initWithLength:sizeof(double) *newNBinsNeg];
                midpointsNegBArray = (double *)[midpointsNegBData bytes];
                midpointsPosBData = [[NSMutableData alloc] initWithLength:sizeof(double) *(newNBins -newNBinsNeg)];
                midpointsPosBArray = (double *)[midpointsPosBData bytes];
            }
            
            binIndex = -1;
            binLower = binsMin - 1;
            for(int iReturn = 0; iReturn < [negativeReturnsA count]; iReturn++){
                currentReturn = [[negativeReturnsA objectAtIndex:iReturn] doubleValue];
                while (binLower < currentReturn) {
                    binIndex++;
                    midpointsNegAArray[binIndex] = binsMin + binsStep/2 + (binIndex * binsStep);
                    binLower = binsMin + (binIndex + 1) * binsStep;
                    
                }
                countsNegAArray[binIndex]++;
                heightsNegAArray[binIndex] = heightsNegAArray[binIndex] + fabs(currentReturn);
                
            }
            binIndex = -1;
            for(int iReturn = 0; iReturn < [positiveReturnsA count]; iReturn++){
                currentReturn = [[positiveReturnsA objectAtIndex:iReturn] doubleValue];
                while (binLower < currentReturn) {
                    binIndex++;
                    midpointsPosAArray[binIndex] = binsMin + binsStep/2 + ((newNBinsNeg + binIndex) * binsStep);
                    binLower = binsMin + (newNBinsNeg + binIndex + 1) * binsStep;
                }
                countsPosAArray[binIndex]++;
                heightsPosAArray[binIndex] =  heightsPosAArray[binIndex] + currentReturn;
            }
            
            binIndex = -1;
            if(B){
                binLower = binsMin - 1;
                for(int iReturn = 0; iReturn < [negativeReturnsB count]; iReturn++){
                    currentReturn = [[negativeReturnsB objectAtIndex:iReturn] doubleValue];
                    while (binLower < currentReturn) {
                        binIndex++;
                        midpointsNegBArray[binIndex] = binsMin + binsStep/2 + (binIndex * binsStep);
                        binLower = binsMin + (binIndex + 1) * binsStep;
                        
                    }
                    countsNegBArray[binIndex]++;
                    heightsNegBArray[binIndex] = heightsNegBArray[binIndex] + fabs(currentReturn);
                    
                }
                binIndex = -1;
                for(int iReturn = 0; iReturn < [positiveReturnsB count]; iReturn++){
                    currentReturn = [[positiveReturnsB objectAtIndex:iReturn] doubleValue];
                    while (binLower < currentReturn) {
                        binIndex++;
                        midpointsPosBArray[binIndex] = binsMin + binsStep/2 + ((newNBinsNeg + binIndex) * binsStep);
                        binLower = binsMin + (newNBinsNeg + binIndex + 1) * binsStep;
                    }
                    countsPosBArray[binIndex]++;
                    heightsPosBArray[binIndex] =  heightsPosBArray[binIndex] + currentReturn;
                }
            }
            
            NSMutableArray *midpointsNegA = [[NSMutableArray alloc] init];
            NSMutableArray *midpointsPosA = [[NSMutableArray alloc] init];
            
            NSMutableArray *heightsNegA = [[NSMutableArray alloc] init];
            NSMutableArray *heightsPosA = [[NSMutableArray alloc] init];
            
            NSMutableArray *countsNegA = [[NSMutableArray alloc] init];
            NSMutableArray *countsPosA = [[NSMutableArray alloc] init];
            
            NSMutableArray *midpointsNegB, *midpointsPosB, *heightsNegB, *heightsPosB, *countsNegB, *countsPosB;
            
            midpointsNegB = [[NSMutableArray alloc] init];
            midpointsPosB = [[NSMutableArray alloc] init];
            
            heightsNegB = [[NSMutableArray alloc] init];
            heightsPosB = [[NSMutableArray alloc] init];
            
            countsNegB = [[NSMutableArray alloc] init];
            countsPosB = [[NSMutableArray alloc] init];
            
            for(int i = 0; i <newNBinsNeg ;i++){
                [midpointsNegA addObject:[NSNumber numberWithDouble:midpointsNegAArray[i]]];
                [heightsNegA addObject:[NSNumber numberWithDouble:heightsNegAArray[i]]];
                [countsNegA addObject:[NSNumber numberWithLong:countsNegAArray[i]]];
                
                if(B){
                    [midpointsNegB addObject:[NSNumber numberWithDouble:midpointsNegBArray[i]]];
                    [heightsNegB addObject:[NSNumber numberWithDouble:heightsNegBArray[i]]];
                    [countsNegB addObject:[NSNumber numberWithLong:countsNegBArray[i]]];
                }
            }
            
            for(int i = 0; i <newNBins -newNBinsNeg ;i++){
                [midpointsPosA addObject:[NSNumber numberWithDouble:midpointsPosAArray[i]]];
                [heightsPosA addObject:[NSNumber numberWithDouble:heightsPosAArray[i]]];
                [countsPosA addObject:[NSNumber numberWithLong:countsPosAArray[i]]];
                
                if(B){
                    [midpointsPosB addObject:[NSNumber numberWithDouble:midpointsPosBArray[i]]];
                    [heightsPosB addObject:[NSNumber numberWithDouble:heightsPosBArray[i]]];
                    [countsPosB addObject:[NSNumber numberWithLong:countsPosBArray[i]]];
                }
            }
            
            [self setMidpointsNegA: midpointsNegA];
            [self setMidpointsPosA:midpointsPosA];
            [self setHeightsNegA:heightsNegA];
            [self setHeightsPosA:heightsPosA];
            [self setCountsNegA:countsNegA];
            [self setCountsPosA:countsPosA];
            
            
            [self setMidpointsNegB:midpointsNegB];
            [self setMidpointsPosB:midpointsPosB];
            [self setHeightsNegB:heightsNegB];
            [self setHeightsPosB:heightsPosB];
            [self setCountsNegB:countsNegB];
            [self setCountsPosB:countsPosB];
            
            
            [self setMidpointsStep:binsStep];
        }else{
            double binLower, binUpper,currentReturn;
            int binIndex = -1;

            if(numberOfSignalsA  > 0){
                for(int i = 0; i < numberOfSignalsA; i++){
                    signalAnalysisDetails = [simA detailsOfSignalAtIndex:i];
                    pnl = [[signalAnalysisDetails objectForKey:@"PNL"] doubleValue];
                    [returnsA addObject:[signalAnalysisDetails objectForKey:@"PNL"]];
                }
                NSSortDescriptor* sortOrder = [NSSortDescriptor sortDescriptorWithKey: @"self" ascending: YES];
                [returnsA sortUsingDescriptors:[NSArray arrayWithObject: sortOrder]];
                minReturn = [[returnsA objectAtIndex:0] doubleValue];
                maxReturn = [[returnsA objectAtIndex:[returnsA count]-1] doubleValue];
            }
            if(numberOfSignalsB  > 0){
                for(int i = 0; i < numberOfSignalsB; i++){
                    signalAnalysisDetails = [simB detailsOfSignalAtIndex:i];
                    pnl = [[signalAnalysisDetails objectForKey:@"PNL"] doubleValue];
                    [returnsB addObject:[signalAnalysisDetails objectForKey:@"PNL"]];
                }
                NSSortDescriptor* sortOrder = [NSSortDescriptor sortDescriptorWithKey: @"self" ascending: YES];
                [returnsB sortUsingDescriptors:[NSArray arrayWithObject: sortOrder]];
                if(numberOfSignalsA  > 0){
                    minReturn = MIN(minReturn,[[returnsB objectAtIndex:0] doubleValue]);
                    maxReturn = MAX(maxReturn,[[returnsB objectAtIndex:[returnsB count]-1] doubleValue]);
                    
                }else{
                    minReturn = [[returnsB objectAtIndex:0] doubleValue];
                    maxReturn = [[returnsB objectAtIndex:[returnsB count]-1] doubleValue];
                }
                
            }
        
            binsStep = (maxReturn - minReturn)/nBins;
            binsMin = minReturn;

            NSMutableData *countsAData = [[NSMutableData alloc] initWithLength:sizeof(long) *nBins];
            long *countsAArray = (long *)[countsAData bytes];
            NSMutableData *heightsAData = [[NSMutableData alloc] initWithLength:sizeof(long) *nBins];
            double *heightsAArray = (double *)[heightsAData bytes];
            NSMutableData *midpointsAData = [[NSMutableData alloc] initWithLength:sizeof(long) *nBins];
            double *midpointsAArray = (double *)[midpointsAData bytes];
            
            NSMutableData *countsBData, *heightsBData, *midpointsBData;
            double *heightsBArray, *midpointsBArray;
            long *countsBArray;
            
            if(B){
                countsBData = [[NSMutableData alloc] initWithLength:sizeof(long) *nBins];
                countsBArray = (long *)[countsBData bytes];
                heightsBData = [[NSMutableData alloc] initWithLength:sizeof(long) *nBins];
                heightsBArray = (double *)[heightsBData bytes];
                midpointsBData = [[NSMutableData alloc] initWithLength:sizeof(long) *nBins];
                midpointsBArray = (double *)[midpointsBData bytes];
            }
            binIndex = -1;
            binLower = binsMin - 1;
            binUpper = binsMin + binsStep;
            for(int iReturn = 0; iReturn < [returnsA count]; iReturn++){
                currentReturn = [[returnsA objectAtIndex:iReturn] doubleValue];
                while (binLower < currentReturn) {
                    binIndex++;
                    midpointsAArray[binIndex] = binsMin + binsStep/2 + (binIndex * binsStep);
                    binLower = binsMin + (binIndex + 1) * binsStep;
                    binUpper = binsMin + (binIndex + 2) * binsStep;
                    
                }
                countsAArray[binIndex]++;
                heightsAArray[binIndex] = heightsAArray[binIndex] + fabs(currentReturn);
                
            }
       
            if(B){
                binIndex = -1;
                binLower = binsMin - 1;
                binUpper = binsMin + binsStep;
                for(int iReturn = 0; iReturn < [returnsB count]; iReturn++){
                    currentReturn = [[returnsB objectAtIndex:iReturn] doubleValue];
                    while (binLower < currentReturn) {
                        binIndex++;
                        midpointsBArray[binIndex] = binsMin + binsStep/2 + (binIndex * binsStep);
                        binLower = binsMin + (binIndex + 1) * binsStep;
                        binUpper = binsMin + (binIndex + 2) * binsStep;
                        
                    }
                    countsBArray[binIndex]++;
                    heightsBArray[binIndex] = heightsBArray[binIndex] + fabs(currentReturn);
                }
            }
         
            NSMutableArray *midpointsA = [[NSMutableArray alloc] init];
            NSMutableArray *heightsA = [[NSMutableArray alloc] init];
            NSMutableArray *countsA = [[NSMutableArray alloc] init];
            
            NSMutableArray *midpointsB, *heightsB, *countsB;
            midpointsB = [[NSMutableArray alloc] init];
            heightsB = [[NSMutableArray alloc] init];
            countsB = [[NSMutableArray alloc] init];
            
            for(int i = 0; i <nBins ;i++){
                [midpointsA addObject:[NSNumber numberWithDouble:midpointsAArray[i]]];
                [heightsA addObject:[NSNumber numberWithDouble:heightsAArray[i]]];
                [countsA addObject:[NSNumber numberWithLong:countsAArray[i]]];
                if(B){
                    [midpointsB addObject:[NSNumber numberWithDouble:midpointsBArray[i]]];
                    [heightsB addObject:[NSNumber numberWithDouble:heightsBArray[i]]];
                    [countsB addObject:[NSNumber numberWithLong:countsBArray[i]]];
                }
            }
            
             
            [self setMidpointsA: midpointsA];
            [self setHeightsA:heightsA];
            [self setCountsA:countsA];
                [self setMidpointsB:midpointsB];
                [self setHeightsB:heightsB];
                [self setCountsB:countsB];
            
            [self setMidpointsStep:binsStep];
        }
    }
    [self setPlotAxesAndPlotSpace];
      
   
}



-(NSDictionary *) getPlotRange
{
    NSMutableDictionary *rangeValues = [[NSMutableDictionary alloc] init];
    double minX= 0.0, maxX = 0.0, minY = 0.0, maxY = 0.0;
    NSMutableArray *allMidpoints = [[NSMutableArray alloc] init];
    NSMutableArray *allHeightsA = [[NSMutableArray alloc] init];
    NSMutableArray *allHeightsB = [[NSMutableArray alloc] init];
  
    BOOL simB = [self simBIncluded];
    
    if([self zeroCentered]){
        BOOL negA = [[self heightsNegA] count] > 0;
        BOOL posA = [[self heightsPosA] count] > 0;
        BOOL negB = simB && [[self heightsNegB] count] > 0;
        BOOL posB = simB && [[self heightsPosB] count] > 0;
        
        
        if(negA){
            for(int i = 0; i < [[self heightsNegA] count];i++){
                [allMidpoints addObject:[[self midpointsNegA] objectAtIndex:i]];
                [allHeightsA addObject:[[self heightsNegA] objectAtIndex:i]];
            }
        }
        if(negB){
            for(int i = 0; i < [[self heightsNegB] count];i++){
                [allMidpoints addObject:[[self midpointsNegB] objectAtIndex:i]];
                [allHeightsB addObject:[[self heightsNegB] objectAtIndex:i]];
                
            }
        }
        if(posA){
            for(int i = 0; i < [[self heightsPosA] count];i++){
                [allMidpoints addObject:[[self midpointsPosA] objectAtIndex:i]];
                [allHeightsA addObject:[[self heightsPosA] objectAtIndex:i]];
                
            }
        }
        if(posB){
            for(int i = 0; i < [[self heightsPosB] count];i++){
                [allMidpoints addObject:[[self midpointsPosB] objectAtIndex:i]];
                [allHeightsB addObject:[[self heightsPosB] objectAtIndex:i]];
                
            }
        }
        
    }else{
        BOOL A = [[self heightsA] count] > 0;
        BOOL B = [[self heightsB] count] > 0;

        if(A){
            for(int i = 0; i < [[self heightsA] count];i++){
                [allMidpoints addObject:[[self midpointsA] objectAtIndex:i]];
                [allHeightsA addObject:[[self heightsA] objectAtIndex:i]];
            }
        }
        if(B){
            for(int i = 0; i < [[self heightsB] count];i++){
                [allMidpoints addObject:[[self midpointsB] objectAtIndex:i]];
                [allHeightsB addObject:[[self heightsB] objectAtIndex:i]];
            }
        }
    }
    
    if([allMidpoints count] > 0){
        minX = [[allMidpoints objectAtIndex:0] doubleValue];
        maxX = [[allMidpoints objectAtIndex:0] doubleValue];
        for(int i = 1; i < [allMidpoints count]; i++){
            minX = MIN(minX,[[allMidpoints objectAtIndex:i] doubleValue]);
            maxX = MAX(maxX,[[allMidpoints objectAtIndex:i] doubleValue]);
        }
    }
    
    if([allHeightsA count] > 0){
        for(int i = 0; i < [allHeightsA count]; i++){
            maxY = MAX(maxY,[[allHeightsA objectAtIndex:i] doubleValue]);
        }
    }
    if([allHeightsB count] > 0){
        for(int i = 0; i < [allHeightsB count]; i++){
            minY = MAX(minY,[[allHeightsB objectAtIndex:i] doubleValue]);
        }
    }

    minX = minX - [self midpointsStep];
    maxX = maxX + [self midpointsStep];
    [rangeValues setObject:[NSNumber numberWithDouble:minX] forKey:@"MINX"];
    [rangeValues setObject:[NSNumber numberWithDouble:maxX] forKey:@"MAXX"];
    [rangeValues setObject:[NSNumber numberWithDouble:-minY] forKey:@"MINY"];
    [rangeValues setObject:[NSNumber numberWithDouble:maxY] forKey:@"MAXY"];
    
    return rangeValues;
}


//-(CPTFill *)barFillForBarPlot:(CPTBarPlot *)barPlot recordIndex:(NSUInteger)index
//{
//	return nil;
//}
//
//-(CPTLayer *)dataLabelForPlot:(CPTPlot *)plot recordIndex:(NSUInteger)index
//{
//	return nil;
//}

-(NSNumber *)countForPlot:(CPTPlot *)plot
               recordIndex:(NSUInteger)index
{
	NSNumber *num = nil;
    num = [NSNumber numberWithInt:0];
    if([self zeroCentered]){
    if( [plot.identifier isEqual:@"NEGA"]) {
        num = [NSNumber numberWithDouble:[[[self countsNegA] objectAtIndex:index] doubleValue]];
    }
    if( [plot.identifier isEqual:@"POSA"]) {
        num = [NSNumber numberWithDouble:[[[self countsPosA] objectAtIndex:index] doubleValue]];
    }
    if( [plot.identifier isEqual:@"NEGB"]) {
        num = [NSNumber numberWithDouble:[[[self countsNegB] objectAtIndex:index] doubleValue]];
    }
    if( [plot.identifier isEqual:@"POSB"]) {
        num = [NSNumber numberWithDouble:[[[self countsPosB] objectAtIndex:index] doubleValue]];
    }
    }else{
        if( [plot.identifier isEqual:@"ALLA"]) {
            num = [NSNumber numberWithDouble:[[[self countsA] objectAtIndex:index] doubleValue]];
        }
        if( [plot.identifier isEqual:@"ALLB"]) {
            num = [NSNumber numberWithDouble:[[[self countsB] objectAtIndex:index] doubleValue]];
        }
    }
    
	return num;
}




#pragma mark -
#pragma mark Barplot Data Source Methods

-(NSUInteger)numberOfRecordsForPlot:(CPTPlot *)plot
{
    if([self zeroCentered]){
        if ( [plot.identifier isEqual:@"NEGA"] ) {
            return [[self midpointsNegA] count];
        }
        if ( [plot.identifier isEqual:@"POSA"] ) {
            return [[self midpointsPosA] count];
        }
        
        if ( [plot.identifier isEqual:@"NEGB"] ) {
            return [[self midpointsNegB] count];
        }
        if ( [plot.identifier isEqual:@"POSB"] ) {
            return [[self midpointsPosB] count];
        }
    }else{
        if ( [plot.identifier isEqual:@"ALLA"] ) {
            return [[self midpointsA] count];
        }
        if ( [plot.identifier isEqual:@"ALLB"] ) {
            return [[self midpointsB] count];
        }
       
    }

    return 0;
}

-(NSNumber *)numberForPlot:(CPTPlot *)plot
                     field:(NSUInteger)fieldEnum
               recordIndex:(NSUInteger)index
{
	NSNumber *num = nil;
    
	if ( fieldEnum == CPTBarPlotFieldBarLocation ) {
		// location
        if([self zeroCentered]){
            if( [plot.identifier isEqual:@"NEGA"]) {
                num = [NSNumber numberWithDouble:[[[self midpointsNegA] objectAtIndex:index] doubleValue]];
            }
            if( [plot.identifier isEqual:@"POSA"]) {
                num = [NSNumber numberWithDouble:[[[self midpointsPosA] objectAtIndex:index] doubleValue]];
            }
            if( [plot.identifier isEqual:@"NEGB"]) {
                num = [NSNumber numberWithDouble:[[[self midpointsNegB] objectAtIndex:index] doubleValue]];
            }
            if( [plot.identifier isEqual:@"POSB"]) {
                num = [NSNumber numberWithDouble:[[[self midpointsPosB] objectAtIndex:index] doubleValue]];
            }
        }else{
            if( [plot.identifier isEqual:@"ALLA"]) {
                num = [NSNumber numberWithDouble:[[[self midpointsA] objectAtIndex:index] doubleValue]];
            }
            if( [plot.identifier isEqual:@"ALLB"]) {
                num = [NSNumber numberWithDouble:[[[self midpointsB] objectAtIndex:index] doubleValue]];
            }

        }
 	}
	else if ( fieldEnum == CPTBarPlotFieldBarTip ) {
		// length
        if([self zeroCentered]){
            if ( [plot.identifier isEqual:@"NEGA"] ) {
                num = [NSNumber numberWithDouble:[[[self heightsNegA] objectAtIndex:index] doubleValue]];
            }
            if( [plot.identifier isEqual:@"POSA"]) {
                num = [NSNumber numberWithDouble:[[[self heightsPosA] objectAtIndex:index] doubleValue]];
            }
            if ( [plot.identifier isEqual:@"NEGB"] ) {
                num = [NSNumber numberWithDouble:-[[[self heightsNegB] objectAtIndex:index] doubleValue]];
            }
            if( [plot.identifier isEqual:@"POSB"]) {
                num = [NSNumber numberWithDouble:-[[[self heightsPosB] objectAtIndex:index] doubleValue]];
            }
        }else{
            if ( [plot.identifier isEqual:@"ALLA"] ) {
                num = [NSNumber numberWithDouble:[[[self heightsA] objectAtIndex:index] doubleValue]];
            }
            if( [plot.identifier isEqual:@"ALLB"]) {
                num = [NSNumber numberWithDouble:-[[[self heightsB] objectAtIndex:index] doubleValue]];
            }
        }
	}
	else {
		// base
        num = [NSNumber numberWithInt:0];
	}
    
	return num;
}






#pragma mark -
#pragma mark CPTBarPlot delegate method

-(void)barPlot:(CPTBarPlot *)plot barWasSelectedAtRecordIndex:(NSUInteger)index
{
    
	NSNumber *count = [self countForPlot:plot recordIndex:index];
    
    NSNumber *midpoint = [self numberForPlot:plot field:CPTBarPlotFieldBarLocation recordIndex:index];
    NSNumber *height = [self numberForPlot:plot field:CPTBarPlotFieldBarTip recordIndex:index];
    
    
	if ([self symbolTextAnnotation] ) {
		[[[[self graph] plotAreaFrame ] plotArea] removeAnnotation:[self symbolTextAnnotation]];
		[self setSymbolTextAnnotation:nil];
	}
    
	// Setup a style for the annotation
	CPTMutableTextStyle *hitAnnotationTextStyle = [CPTMutableTextStyle textStyle];
	hitAnnotationTextStyle.color	= [CPTColor whiteColor];
	hitAnnotationTextStyle.fontSize = 14.0f;
	hitAnnotationTextStyle.fontName =  @"Courier";
    
	// Determine point of symbol in plot coordinates
	//NSNumber *x = [NSNumber numberWithInt:(int)index];
	//NSNumber *y = [NSNumber numberWithInt:2]; //[self numberForPlot:plot field:0 recordIndex:index];
    NSNumber *halfHeight = [NSNumber numberWithDouble:[height doubleValue]/2.0];
	NSArray *anchorPoint = [NSArray arrayWithObjects:midpoint, halfHeight, nil];
    
	// Add annotation
	// First make a string for the y value
//	NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
//	[formatter setMaximumFractionDigits:2];
//	NSString *yString = [formatter stringFromNumber:value];
    
    NSString *yString = [NSString stringWithFormat:@"%@",count];
	// Now add the annotation to the plot area
	CPTTextLayer *textLayer = [[CPTTextLayer alloc] initWithText:yString style:hitAnnotationTextStyle];
	[self setSymbolTextAnnotation:[[CPTPlotSpaceAnnotation alloc] initWithPlotSpace:plot.plotSpace anchorPlotPoint:anchorPoint]];
	[[self symbolTextAnnotation] setContentLayer:textLayer];
	[[self symbolTextAnnotation] setDisplacement:CGPointMake(0.0f, 0.0f)];
    
	[[[[self graph] plotAreaFrame ] plotArea] addAnnotation:[self symbolTextAnnotation]];
}

#pragma mark -
#pragma mark Plot Adjustment methods



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


#pragma mark -
#pragma mark Plot Space Delegate Methods

-(BOOL)plotSpace:(CPTPlotSpace *)plotSpace shouldHandlePointingDeviceUpEvent:(id)event
         atPoint:(CGPoint)point
{
    if ([self symbolTextAnnotation] ) {
		[[[[self graph] plotAreaFrame ] plotArea] removeAnnotation:[self symbolTextAnnotation]];
		[self setSymbolTextAnnotation:nil];
	}
    return NO;
}
@end






