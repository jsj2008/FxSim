//
//  SimpleScatterPlot.m
//  CorePlotGallery
//

#import "SeriesPlot.h"
#import "DataView.h"
#import "EpochTime.h"
#import "TimeSeriesLine.h"
#import "SeriesPlotDataWrapper.h"
#import "UtilityFunctions.h"

#define X_RANGE_XPAN_FACTOR 1.1
#define Y_RANGE_XPAN_FACTOR 1.1

@interface SeriesPlot()
- (BOOL) fixUpXAxisLabelsFrom: (long) minX
                           To: (long) maxX;
- (void) fixUpYAxisForLayerIndex: (int) layerIndex;
- (void) zoomInAndZoomY: (BOOL) zoomY;;
- (void) zoomOut;
- (void) addHorizontalLineAt:(double) yValue
                ForPlotspace:(CPTXYPlotSpace *) plotSpace;


@property (retain) CPTXYGraph *graph;
@property int majorIntervalForX;
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
    
    
    NSString *subString = @"2015, Martin O'Connor";
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

  [[self xAxis0] setNeedsDisplay];
  [[self yAxis0] setNeedsDisplay];
  [[self yAxis1] setNeedsDisplay];
  [[self yAxis2] setNeedsDisplay];
 
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

-(void)positionIndicatorOff: (SeriesPlotDataWrapper *) dataSource
{
  CPTPlot *plot1, *plot2, *plot3, *plot4;
  plot1 = [[self graph] plotWithIdentifier:@"S0_L0_SHORT"];
  plot2 = [[self graph] plotWithIdentifier:@"S0_L0_LONG"];
  [plot1 setDataSource:nil];
  [plot2 setDataSource:nil];
  [dataSource setShortLongIndicatorA:NO];
  
  if([dataSource simulationB]){
    plot3 = [[self graph] plotWithIdentifier:@"S1_L0_SHORT"];
    plot4 = [[self graph] plotWithIdentifier:@"S1_L0_LONG"];
    [plot3 setDataSource:nil];
    [plot4 setDataSource:nil];
    [dataSource setShortLongIndicatorB:NO];
  }
  
}

-(void)updatePositionIndicator: (SeriesPlotDataWrapper *) dataSource
{
  CPTPlot *plotS, *plotL;
  
  plotS = [[self graph] plotWithIdentifier:@"S0_L0_SHORT"];
  plotL = [[self graph] plotWithIdentifier:@"S0_L0_LONG"];
  
  if([dataSource shortLongIndicatorA]){
    [plotS setDataSource:[self dataSource]];
    [plotL setDataSource:[self dataSource]];
  }else{
    [plotS setDataSource:nil];
    [plotL setDataSource:nil];
  }
  [plotS dataNeedsReloading];
  [plotL dataNeedsReloading];
  
  
  if([dataSource simulationB]){
    plotS = [[self graph] plotWithIdentifier:@"S1_L0_SHORT"];
    plotL = [[self graph] plotWithIdentifier:@"S1_L0_LONG"];
    
    if([dataSource shortLongIndicatorB]){
      [plotS setDataSource:[self dataSource]];
      [plotL setDataSource:[self dataSource]];
    }else{
      [plotS setDataSource:nil];
      [plotL setDataSource:nil];
    }
    [plotS dataNeedsReloading];
    [plotL dataNeedsReloading];
  }
  
  
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
  [self fixUpXAxisLabels];
  
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
      AndUpdateYAxes: (BOOL) updateYAxis
{
  //Create a plot that uses the data source method
  CPTScatterPlot *dataSourceLinePlot;
  //CPTLineStyle *ls;
  CPTMutableLineStyle *lineStyle;
  [self setDataSource:dataSource];
  [self setInteractionLayer:nil];
  
  NSDictionary *xyRanges = [dataSource xyRanges];
  
  [self setMinXrangeForPlot: [[xyRanges objectForKey:@"MINX"] longValue]];
  [self setMaxXrangeForPlot: [[xyRanges objectForKey:@"MAXX"] longValue]];
  if(updateYAxis){
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
      
      if([[[self graph] allPlots] count] > 0){
        dataSourceLinePlot = (CPTScatterPlot *)[[self graph] plotWithIdentifier:lineName];
        if(dataSourceLinePlot){
          lineFound = YES;
          //ls = [dataSourceLinePlot dataLineStyle];
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
        
        if([tsl simId]==1 && [[self dataSource] doDotsForSecondPlot]){
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
    //
    if([dataSource shortLongIndicatorA]){
      [dataSourceLinePlot setDataSource:dataSource];
    }else{
      [dataSourceLinePlot setDataSource:nil];
    }
    
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
    
    if([dataSource shortLongIndicatorA]){
      [dataSourceLinePlot setDataSource:dataSource];
    }else{
      [dataSourceLinePlot setDataSource:nil];
    }
    [[self graph] addPlot:dataSourceLinePlot toPlotSpace:[self shortLongPlotSpace]];
    
    
    if([dataSource simulationB]){
      dataSourceLinePlot = [[CPTScatterPlot alloc] init];
      dataSourceLinePlot.identifier = @"S1_L0_SHORT";
      lineStyle = [[dataSourceLinePlot dataLineStyle] mutableCopy];
      [lineStyle setLineWidth:1.0];
      [lineStyle setLineColor:[CPTColor clearColor]];
      
      CPTColor *areaColor = [CPTColor colorWithComponentRed:1.0 green:0.0 blue:0.0 alpha:0.3];
      
      [dataSourceLinePlot setAreaFill	:[CPTFill fillWithColor:areaColor]];
      [dataSourceLinePlot setAreaBaseValue:CPTDecimalFromDouble(0.0)];
      
      [dataSourceLinePlot setDataLineStyle:lineStyle];
      
      if([dataSource shortLongIndicatorB]){
        [dataSourceLinePlot setDataSource:dataSource];
      }else{
        [dataSourceLinePlot setDataSource:nil];
      }
      [[self graph] addPlot:dataSourceLinePlot toPlotSpace:[self shortLongPlotSpace]];
      // Long indicator
      dataSourceLinePlot = [[CPTScatterPlot alloc] init];
      dataSourceLinePlot.identifier = @"S1_L0_LONG";
      lineStyle = [dataSourceLinePlot.dataLineStyle mutableCopy];
      [lineStyle setLineWidth:1.0];
      [lineStyle setLineColor:[CPTColor clearColor]];
      
      areaColor		  = [CPTColor colorWithComponentRed:0.0 green:1.0 blue:0.0 alpha:0.3];
      [dataSourceLinePlot setAreaFill:[CPTFill fillWithColor:areaColor]];
      [dataSourceLinePlot setAreaBaseValue :CPTDecimalFromDouble(0.0)];
      [dataSourceLinePlot setDataLineStyle:lineStyle];
      //
      if([dataSource shortLongIndicatorB]){
        [dataSourceLinePlot setDataSource:dataSource];
      }else{
        [dataSourceLinePlot setDataSource:nil];
      }
      [[self graph] addPlot:dataSourceLinePlot toPlotSpace:[self shortLongPlotSpace]];
    }
    
    // Find a good range for the X axis
    double niceXrange = (ceil( (double)([self maxXrangeForPlot] - [self minXrangeForPlot]) / [self majorIntervalForX]) * [self majorIntervalForX]);
    CPTMutablePlotRange *xRange;
    if((niceXrange/([self maxXrangeForPlot] - [self minXrangeForPlot]))>1.1){
      xRange = [CPTMutablePlotRange plotRangeWithLocation:CPTDecimalFromDouble((double)[self minXrangeForPlot])
                                                   length:CPTDecimalFromDouble((double)[self maxXrangeForPlot] - [self minXrangeForPlot])];
    }else{
      xRange = [CPTMutablePlotRange plotRangeWithLocation:CPTDecimalFromDouble((double)[self minXrangeForPlot])
                                                   length:CPTDecimalFromDouble(niceXrange)];
      
    }
    
    [xRange expandRangeByFactor:CPTDecimalFromDouble(X_RANGE_XPAN_FACTOR)];
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
    
    CPTPlotRange *shortLongPlotYRange;
    shortLongPlotYRange = [[CPTPlotRange alloc] initWithLocation:[[NSDecimalNumber numberWithInt:0] decimalValue]  length:[[NSDecimalNumber numberWithInt:1] decimalValue]];
    CPTMutablePlotRange *shortLongPlotXRange =[[[self plotSpace0] xRange] copy];
    [[self shortLongPlotSpace] setXRange:shortLongPlotXRange];
    [[self shortLongPlotSpace] setYRange:shortLongPlotYRange];
    
    //        [self setXRangeZoomOut:xRange];
    
    BOOL dateAnnotateRequired = [self fixUpXAxisLabels];
    if(dateAnnotateRequired){
      if(([self maxXrangeForPlot] - [self minXrangeForPlot])/(365.0*60 * 60 * 24)>1 ){
        NSString *stringFromDate;
        CPTMutableTextStyle *dateStringStyle;
        NSArray *dateAnnotationPoint;
        CPTTextLayer *textLayer;
        CPTPlotSpaceAnnotation *dateAnnotation;
        
        CGRect bounds = NSRectToCGRect([[self hostingView] bounds]);
        CPTPlotRange *yRange = [[self plotSpace0] yRange];
        
        long yearEnd;
        
        yearEnd = [EpochTime epochTimeAtZeroHourJan1NextYear:[self minXrangeForPlot]];
        
        while(yearEnd < [self maxXrangeForPlot]){
          stringFromDate = [EpochTime stringOfDateTime:yearEnd
                                            WithFormat:@"%Y"];
          dateStringStyle = [CPTMutableTextStyle textStyle];
          dateStringStyle.color	= [CPTColor redColor];
          dateStringStyle.fontSize = round(bounds.size.height / (CGFloat)30.0);
          dateStringStyle.fontName = @"Courier";
          
          // Determine point of symbol in plot coordinates
          dateAnnotationPoint = [NSArray arrayWithObjects:[NSDecimalNumber numberWithLong:yearEnd],[NSDecimalNumber decimalNumberWithDecimal: yRange.location], nil];
          
          textLayer = [[CPTTextLayer alloc] initWithText:stringFromDate style:dateStringStyle];
          
          dateAnnotation = [[CPTPlotSpaceAnnotation alloc] initWithPlotSpace:[[self graph] defaultPlotSpace] anchorPlotPoint:dateAnnotationPoint];
          dateAnnotation.contentLayer = textLayer;
          dateAnnotation.displacement =  CGPointMake( 0.0f,10.0f);
          [[[[self graph] plotAreaFrame] plotArea] addAnnotation:dateAnnotation];
          [[self dateAnnotationArray] addObject:dateAnnotation];
          
          yearEnd = [EpochTime epochTimeAtZeroHourJan1NextYear:yearEnd + 100];
        }
        
        
      }else{
        long firstMidnight = [EpochTime epochTimeAtZeroHour:[self minXrangeForPlot]];
        long lastMidnight = [EpochTime epochTimeNextDayAtZeroHour:[self maxXrangeForPlot]];
        
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
    }
  }else{
    while([[[self graph] allPlots] count] > 0){
      [[self graph] removePlot:[[[self graph] allPlots] objectAtIndex:0]];
    }
  }
  if([[self lineAnnotationArray] count] > 0){
    NSMutableArray *renewLines = [[NSMutableArray alloc] init];
    for(int i = 0; i < [[self lineAnnotationArray] count]; i++){
      [renewLines addObject:[[self lineAnnotationLevelArray] objectAtIndex:i]];
    }
    [self removeLineAnnotation];
    for(int i = 0; i < [renewLines count]; i++){
      [self addHorizontalLineAt:[[renewLines objectAtIndex:i] doubleValue] ForPlotspace:[self plotSpace0]];
    }
  }
  
}

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
  
  BOOL dateIsFullySpecifiedInAxis = NO;
  
  [self setMinXrangeForPlot:minXaxis];
  [self setMaxXrangeForPlot:maxXaxis];
  //
  if(((float)([self maxXrangeForPlot] - [self minXrangeForPlot])/(121*30*60 * 60 * 24))>1){
    [self setMajorIntervalForX:120 * 24 * 60 * 60];
    [[self xAxis0] setMajorIntervalLength:CPTDecimalFromInt([self majorIntervalForX])]; // 14 Day
    [[self xAxis0] setMinorTicksPerInterval:40];
    [dateFormatter setDateFormat:@"MM/dd"];
    dateIsFullySpecifiedInAxis = NO;
  }else{
    if(((float)([self maxXrangeForPlot] - [self minXrangeForPlot])/(4*30*60 * 60 * 24))>1){
      [self setMajorIntervalForX:14 * 24 * 60 * 60];
      [[self xAxis0] setMajorIntervalLength:CPTDecimalFromInt([self majorIntervalForX])]; // 14 Day
      [[self xAxis0] setMinorTicksPerInterval:13];
      [dateFormatter setDateFormat:@"MM/dd"];
      dateIsFullySpecifiedInAxis = TRUE;
    }else{
      if(((float)([self maxXrangeForPlot] - [self minXrangeForPlot])/(21*60 * 60 * 24))>1){
        [self setMajorIntervalForX:7 * 24 * 60 * 60];
        [[self xAxis0] setMajorIntervalLength:CPTDecimalFromInt([self majorIntervalForX])]; // 7 Day
        [[self xAxis0] setMinorTicksPerInterval:6];
        [dateFormatter setDateFormat:@"MM/dd"];
        dateIsFullySpecifiedInAxis = TRUE;
      }else{
        //If greater than 3 days
        if(((float)([self maxXrangeForPlot] - [self minXrangeForPlot])/(3*60 * 60 * 24))>1){
          [self setMajorIntervalForX:24 * 60 * 60];
          [[self xAxis0] setMajorIntervalLength:CPTDecimalFromInt([self majorIntervalForX])]; // 1 Day
          [[self xAxis0] setMinorTicksPerInterval:5];
          [dateFormatter setDateFormat:@"MM/dd"];
          dateIsFullySpecifiedInAxis = TRUE;
        }else{
          //If greater than 12 hours
          if(((float)([self maxXrangeForPlot] - [self minXrangeForPlot])/(60 * 60 * 12))>1){
            [self setMajorIntervalForX:4 * 60 * 60];
            [[self xAxis0] setMajorIntervalLength:CPTDecimalFromInt([self majorIntervalForX])]; // 4 hours
            [[self xAxis0] setMinorTicksPerInterval:3];
            [dateFormatter setDateStyle:NSDateFormatterNoStyle];
            [dateFormatter setTimeStyle:NSDateFormatterShortStyle];
          }else{
            //If less than 12 hours
            if(((float)([self maxXrangeForPlot] - [self minXrangeForPlot])/(60 * 60 * 12))<=1){
              [self setMajorIntervalForX:(60 * 60)];
              [[self xAxis0] setMajorIntervalLength:CPTDecimalFromInt([self majorIntervalForX])]; // 1 hours
              [[self xAxis0] setMinorTicksPerInterval:5];
              [dateFormatter setDateStyle:NSDateFormatterNoStyle];
              [dateFormatter setTimeStyle:NSDateFormatterShortStyle];
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
  
  return !dateIsFullySpecifiedInAxis;
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
  
  BOOL dateIsFullySpecifiedInAxis = NO;
  
  //
  if(((float)([self maxXrangeForPlot] - [self minXrangeForPlot])/(365*60 * 60 * 24))>1){
    [self setMajorIntervalForX:(121 * 24 * 60 * 60)];
    [[self xAxis0] setMajorIntervalLength:CPTDecimalFromInt([self majorIntervalForX])]; // 121 Day
    [[self xAxis0] setMinorTicksPerInterval:40];
    [dateFormatter setDateFormat:@"MM/dd"];
    dateIsFullySpecifiedInAxis = NO;
  }else{
    if(((float)([self maxXrangeForPlot] - [self minXrangeForPlot])/(4*30*60 * 60 * 24))>1){
      [self setMajorIntervalForX:14 * 24 * 60 * 60];
      [[self xAxis0] setMajorIntervalLength:CPTDecimalFromInt([self majorIntervalForX])]; // 14 Day
      [[self xAxis0] setMinorTicksPerInterval:13];
      [dateFormatter setDateFormat:@"MM/dd"];
      dateIsFullySpecifiedInAxis = YES;
    }else{
      if(((float)([self maxXrangeForPlot] - [self minXrangeForPlot])/(21*60 * 60 * 24))>1){
        [self setMajorIntervalForX:7 * 24 * 60 * 60];
        [[self xAxis0] setMajorIntervalLength:CPTDecimalFromInt([self majorIntervalForX])]; // 7 Day
        [[self xAxis0] setMinorTicksPerInterval:6];
        [dateFormatter setDateFormat:@"MM/dd"];
        dateIsFullySpecifiedInAxis = YES;
      }else{
        //If greater than 3 days
        if(((float)([self maxXrangeForPlot] - [self minXrangeForPlot])/(3*60 * 60 * 24))>1){
          [self setMajorIntervalForX:24 * 60 * 60];
          [[self xAxis0] setMajorIntervalLength:CPTDecimalFromInt([self majorIntervalForX])]; // 1 Day
          [[self xAxis0] setMinorTicksPerInterval:5];
          [dateFormatter setDateFormat:@"MM/dd"];
          dateIsFullySpecifiedInAxis = YES;
        }else{
          //If greater than 12 hours
          if(((float)([self maxXrangeForPlot] - [self minXrangeForPlot])/(60 * 60 * 12))>1){
            [self setMajorIntervalForX:4 * 60 * 60];
            [[self xAxis0] setMajorIntervalLength:CPTDecimalFromInt([self majorIntervalForX])]; // 4 hours
            [[self xAxis0] setMinorTicksPerInterval:3];
            [dateFormatter setDateStyle:NSDateFormatterNoStyle];
            [dateFormatter setTimeStyle:NSDateFormatterShortStyle];
          }else{
            //If less than 12 hours
            if(((float)([self maxXrangeForPlot] - [self minXrangeForPlot])/(60 * 60 * 12))<=1){
              [self setMajorIntervalForX:60 * 60];
              [[self xAxis0] setMajorIntervalLength:CPTDecimalFromInt([self majorIntervalForX])]; // 1 hours
              [[self xAxis0] setMinorTicksPerInterval:5];
              [dateFormatter setDateStyle:NSDateFormatterNoStyle];
              [dateFormatter setTimeStyle:NSDateFormatterShortStyle];
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
  
  return !dateIsFullySpecifiedInAxis;
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
    double range = [UtilityFunctions niceNumber:  maxYrangeForPlot-minYrangeForPlot
                                   withRounding:NO];
    if(range > 0){
      d = [UtilityFunctions niceNumber:range/(nTicks - 1)
                          withRounding:YES];
      axisMin = floor(minYrangeForPlot/d)*d;
      axisMax = ceil(maxYrangeForPlot/d)*d;
    }else{
      d = [UtilityFunctions niceNumber:2.0/(nTicks - 1)
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
    [yRange expandRangeByFactor:CPTDecimalFromDouble(Y_RANGE_XPAN_FACTOR)];
    
    [plotSpace setYRange:yRange];
    
    CPTMutableTextStyle *newTextStyle;
    newTextStyle = [[yAxis labelTextStyle] mutableCopy];
    [newTextStyle setColor:[CPTColor whiteColor]];
    [yAxis setLabelTextStyle:newTextStyle];
    
  }
}

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
  
  CGPoint startPoint =  [plotSpace plotAreaViewPointForDoublePrecisionPlotPoint:dataValues
                                                            numberOfCoordinates:2];
  dataValues[0] = maxXRange;
  CGPoint endPoint =  [plotSpace plotAreaViewPointForDoublePrecisionPlotPoint:dataValues
                                                          numberOfCoordinates:2];
  
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
#pragma mark Plot Space Delegate Methods

-(BOOL)plotSpace:(CPTPlotSpace *)plotSpace shouldHandlePointingDeviceDraggedEvent:(id)event
         atPoint:(CGPoint)interactionPoint
{
  NSUInteger flags = [event modifierFlags] & NSDeviceIndependentModifierFlagsMask;
  
  // convert the dragStart and dragEnd values to plot coordinates
  CGPoint dragStartInPlotArea = [[self graph] convertPoint:[self dragStart] toLayer:[self interactionLayer]];
  CGPoint dragEndInPlotArea	= [[self graph] convertPoint:interactionPoint toLayer:[self interactionLayer]];
  
  // create the dragrect from dragStart to the current location
  CGRect borderRect;
  
  if([self interactionLayer]){
    if(flags == NSAlternateKeyMask){
      borderRect = CGRectMake(dragStartInPlotArea.x, dragStartInPlotArea.y,
                              (dragEndInPlotArea.x - dragStartInPlotArea.x),
                              (dragEndInPlotArea.y - dragStartInPlotArea.y));
    }else if(flags == 0){
      double getValues[2];
      double minYRange = [[NSDecimalNumber decimalNumberWithDecimal:[[[self plotSpace0] yRange] location]] doubleValue];
      double maxYRange =  minYRange + [[NSDecimalNumber decimalNumberWithDecimal:[[[self plotSpace0] yRange] length]] doubleValue];
      
      getValues[0] = 0.0;
      getValues[1] = minYRange;
      
      CGPoint getMinY =  [[self plotSpace0] plotAreaViewPointForDoublePrecisionPlotPoint:getValues
                                                                     numberOfCoordinates:2];
      getValues[1] = maxYRange;
      CGPoint getMaxY =  [[self plotSpace0] plotAreaViewPointForDoublePrecisionPlotPoint:getValues
                                                                     numberOfCoordinates:2];
      borderRect = CGRectMake(dragStartInPlotArea.x, getMinY.y ,
                              (dragEndInPlotArea.x - dragStartInPlotArea.x),
                              getMaxY.y);
      
    }
    if(flags == 0 || flags == NSAlternateKeyMask){
      // force the drawing of the zoomRect
      [[[self zoomAnnotation] contentLayer] setFrame:borderRect];
      [[[self zoomAnnotation] contentLayer] setNeedsDisplay];
      
      // Add a date
      //CPTXYPlotSpace *plotSpace = (CPTXYPlotSpace *)graph.defaultPlotSpace;
      CGPoint dragInPlotArea = [[self graph] convertPoint:interactionPoint toLayer:[self interactionLayer]];
      double dataCoords[2];
      [[self plotSpace0] doublePrecisionPlotPoint:dataCoords
                              numberOfCoordinates: 2
                             forPlotAreaViewPoint:dragInPlotArea];
      
      NSString *currentValue;
      if(flags == NSAlternateKeyMask){
        currentValue = [NSString stringWithFormat:@"%5.3f",dataCoords[CPTCoordinateY]];
      }else{
        currentValue = [EpochTime stringOfDateTime:(long)dataCoords[CPTCoordinateX]
                                        WithFormat: @"%a %Y-%m-%d %H:%M:%S"];
      }
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
  }
  return NO;
}

-(BOOL)plotSpace:(CPTPlotSpace *)plotSpace shouldHandlePointingDeviceDownEvent:(id)event
         atPoint:(CGPoint)interactionPoint
{
  NSUInteger flags = [event modifierFlags] & NSDeviceIndependentModifierFlagsMask;
 	if([self interactionLayer]){
    if(flags == NSCommandKeyMask){
      CGPoint clickInPlotArea = [[self graph] convertPoint:interactionPoint
                                                   toLayer:[self interactionLayer]];
      double dataCoords[2];
      
      [plotSpace doublePrecisionPlotPoint:dataCoords
                      numberOfCoordinates:2
                     forPlotAreaViewPoint:clickInPlotArea];
      [self addHorizontalLineAt:dataCoords[CPTCoordinateY]
                   ForPlotspace:[self plotSpace0]];
    }else if(flags == NSCommandKeyMask + NSAlternateKeyMask){
      NSTextField *accessory = [[NSTextField alloc] initWithFrame:NSMakeRect(0,0,200,22)];
      [accessory setEditable:YES];
      
      [accessory setDrawsBackground:YES];
      
      [self setAlert:[[NSAlert alloc] init]];
      [[self alert] setMessageText:@"Enter a (left-most axis) value for horizontal line"];
      [[self alert] setInformativeText:@""];
      [[self alert] setAccessoryView:accessory];
      [[self alert] runModal];
      NSString *inputString = [accessory stringValue];
      NSArray* words = [inputString componentsSeparatedByCharactersInSet :[NSCharacterSet whitespaceCharacterSet]];
      NSString* noSpaceString = [words componentsJoinedByString:@""];
      NSNumberFormatter *numberFormatter = [[NSNumberFormatter alloc] init];
      if([numberFormatter numberFromString:noSpaceString]){
        double inputValue = [[numberFormatter numberFromString:noSpaceString] doubleValue];
        [self addHorizontalLineAt:inputValue
                     ForPlotspace:[self plotSpace0]];
      }
    }else if(flags == NSCommandKeyMask + NSShiftKeyMask){
      [self removeLineAnnotation];
    }else {
      [self setDragStart:interactionPoint];
      CGPoint clickInPlotArea = [[self graph] convertPoint:interactionPoint
                                                   toLayer:[self interactionLayer]];
      double dataCoords[2];
      [plotSpace doublePrecisionPlotPoint:dataCoords
                      numberOfCoordinates:2
                     forPlotAreaViewPoint:clickInPlotArea];
      
      // Add annotation
      // First make a string for the y value
      NSString *currentValue;
      if(flags == NSAlternateKeyMask){
        currentValue = [NSString stringWithFormat:@"%5.4f",dataCoords[CPTCoordinateY]];
      }else{
        currentValue = [EpochTime stringOfDateTime:(long)dataCoords[CPTCoordinateX]
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
  NSUInteger flags = [NSEvent modifierFlags] & NSDeviceIndependentModifierFlagsMask;
  if([self interactionLayer]){
    //        if(flags == NSCommandKeyMask){
    //            if([event clickCount] == 2){
    //                [self removeLineAnnotation];
    //            }
    //        }else
    if(flags == 0 || flags == NSAlternateKeyMask){
      if ( [self clickDateAnnotation] ) {
        [[[[self graph] plotAreaFrame] plotArea] removeAnnotation:[self clickDateAnnotation]];
        [self setClickDateAnnotation:nil];
      }
      // double-click to completely zoom out
      if ( [event clickCount] == 2 ) {
        [self zoomOut];
        
      }
      
      if ( [self dragDateAnnotation] ) {
        [[[[self graph] plotAreaFrame] plotArea] removeAnnotation:[self dragDateAnnotation]];
        [self setDragDateAnnotation:nil];
        [self setDragEnd:point];
        
        if ( !CGPointEqualToPoint([self dragStart], [self dragEnd]) ) {
          // no accidental drag, so zoom in
          if(flags == NSAlternateKeyMask){
            [self zoomInAndZoomY:YES];
          }else{
            [self zoomInAndZoomY:NO];
          }
          
          // and we're done with the drag
          [[[self zoomAnnotation] contentLayer] setFrame:CGRectNull];
          [[[self zoomAnnotation] contentLayer] setNeedsDisplay];
        }
        
      }
    }
  }
  return NO;
}

#pragma mark -
#pragma mark Zoom Methods

-(void)zoomInAndZoomY: (BOOL) zoomY;
{
  double minXzoomForPlot;
  double maxXzoomForPlot;
  double minYzoomForPlot0;
  double maxYzoomForPlot0;
  double minYzoomForPlot1;
  double maxYzoomForPlot1;
  double minYzoomForPlot2;
  double maxYzoomForPlot2;
  
  // convert the dragStart and dragEnd values to plot coordinates
  CGPoint dragStartInPlotArea = [[self graph] convertPoint:[self dragStart] toLayer:[self interactionLayer]];
  CGPoint dragEndInPlotArea	= [[self graph] convertPoint:[self dragEnd] toLayer:[self interactionLayer]];
  
  double start0[2], end0[2], start1[2], end1[2], start2[2], end2[2];
  
  // obtain the datapoints for the drag start and end
  [[self plotSpace0] doublePrecisionPlotPoint:start0
                          numberOfCoordinates:2
                         forPlotAreaViewPoint:dragStartInPlotArea];
  [[self plotSpace0] doublePrecisionPlotPoint:end0
                          numberOfCoordinates:2
                         forPlotAreaViewPoint:dragEndInPlotArea];
  
  [[self plotSpace1] doublePrecisionPlotPoint:start1
                          numberOfCoordinates:2
                         forPlotAreaViewPoint:dragStartInPlotArea];
  [[self plotSpace1] doublePrecisionPlotPoint:end1
                          numberOfCoordinates:2
                         forPlotAreaViewPoint:dragEndInPlotArea];
  
  [[self plotSpace2] doublePrecisionPlotPoint:start2
                          numberOfCoordinates:2
                         forPlotAreaViewPoint:dragStartInPlotArea];
  [[self plotSpace2] doublePrecisionPlotPoint:end2
                          numberOfCoordinates:2
                         forPlotAreaViewPoint:dragEndInPlotArea];
  
  // recalculate the min and max values
  minXzoomForPlot = MIN(start0[CPTCoordinateX], end0[CPTCoordinateX]);
  maxXzoomForPlot = MAX(start0[CPTCoordinateX], end0[CPTCoordinateX]);
  
  [[self dataSource] setDataViewWithStartDateTime:(long)minXzoomForPlot
                                   AndEndDateTime:(long)maxXzoomForPlot
                                           AsZoom:YES];
  
  
  if(zoomY){
    minYzoomForPlot0 = MIN(start0[CPTCoordinateY], end0[CPTCoordinateY]);
    maxYzoomForPlot0 = MAX(start0[CPTCoordinateY], end0[CPTCoordinateY]);
    [[self plotSpace0] setYRange:[CPTPlotRange plotRangeWithLocation:CPTDecimalFromDouble(minYzoomForPlot0)
                                                              length:CPTDecimalFromDouble(maxYzoomForPlot0 - minYzoomForPlot0)]];
    [self setMinYrangeForPlot0: minYzoomForPlot0];
    [self setMaxYrangeForPlot0: maxYzoomForPlot0];
    
    minYzoomForPlot1 = MIN(start1[CPTCoordinateY], end1[CPTCoordinateY]);
    maxYzoomForPlot1 = MAX(start1[CPTCoordinateY], end1[CPTCoordinateY]);
    [[self plotSpace1] setYRange:[CPTPlotRange plotRangeWithLocation:CPTDecimalFromDouble(minYzoomForPlot1)
                                                              length:CPTDecimalFromDouble(maxYzoomForPlot1 - minYzoomForPlot1)]];
    [self setMinYrangeForPlot1: minYzoomForPlot1];
    [self setMaxYrangeForPlot1: maxYzoomForPlot1];
    
    minYzoomForPlot2 = MIN(start2[CPTCoordinateY], end2[CPTCoordinateY]);
    maxYzoomForPlot2 = MAX(start2[CPTCoordinateY], end2[CPTCoordinateY]);
    [[self plotSpace2] setYRange:[CPTPlotRange plotRangeWithLocation:CPTDecimalFromDouble(minYzoomForPlot2)
                                                              length:CPTDecimalFromDouble(maxYzoomForPlot2 - minYzoomForPlot2)]];
    
    [self setMinYrangeForPlot2: minYzoomForPlot2];
    [self setMaxYrangeForPlot2: maxYzoomForPlot2];
    
    
    [self updateLines:[self dataSource]
       AndUpdateYAxes:NO];
  }else{
    [self updateLines:[self dataSource]
       AndUpdateYAxes:YES];
  }
  
}

-(void)zoomOut
{
  [[self dataSource] unZoomDataView];
  [self updateLines:[self dataSource]
     AndUpdateYAxes:YES];
}

@end
