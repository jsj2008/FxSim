//
//  SimpleScatterPlot.h
//  CorePlotGallery
//


#import <CorePlot/CorePlot.h>
#import "SimulationOutput.h"
//#import "SeriesPlotData.h"
@class DataView;
@class TimeSeriesLines;
@class SeriesPlotDataWrapper;

@interface SeriesPlot : NSObject<CPTPlotSpaceDelegate>
{
	//CPTGraphHostingView *_hostingView;
    //CPTXYGraph *_graph;
    
    //DataView *_dataView;
	//NSString *identifier;
    //NSArray *timeSeriesLines;
   
    //BOOL plot1AxisVisible;
    //BOOL plot2AxisVisible;
    
    //long minXrangeForPlot, maxXrangeForPlot;
//    double minYrangeForPlot0, maxYrangeForPlot0;
//    double minYrangeForPlot1, maxYrangeForPlot1;
//    double minYrangeForPlot2, maxYrangeForPlot2;
//    
    int majorIntervalForX;
    //double majorIntervalForY;
    
//    CPTMutablePlotRange *xRangeZoomOut;
//    CPTMutablePlotRange *yRange0ZoomOut;
//    CPTMutablePlotRange *yRange1ZoomOut;
//    CPTMutablePlotRange *yRange2ZoomOut;
//    
//    BOOL zoomedOut;
//    CPTXYPlotSpace *plotSpace0;
//    CPTXYPlotSpace *plotSpace1;
//    CPTXYPlotSpace *plotSpace2;
//    CPTXYPlotSpace *overlayPlotSpace;
//    
//    CPTXYAxis *xAxis0;
//    CPTXYAxis *yAxis0;
//    CPTXYAxis *yAxis1;
//    CPTXYAxis *yAxis2;
//    CPTPlotSpaceAnnotation *clickDateAnnotation;
//    CPTPlotSpaceAnnotation *dragDateAnnotation;
//    CPTPlotSpaceAnnotation *zoomAnnotation;
//    CPTPlotSpaceAnnotation *lineAnnotation;
//    NSMutableArray *lineAnnotationArray;
//    NSMutableArray *lineAnnotationLevelArray; 
//    
//    NSMutableArray *dateAnnotationArray;
//	CGPoint dragStart, dragEnd;
    
    //id<SeriesPlotData> plotData;
}

- (id)   initWithIdentifier:(NSString*) identifierString;
- (void) initialGraphAndAddAnnotation: (BOOL) doAnnotation;
//-(void)setData: (SimDataCombi *) newData
//  WithViewName: (NSString *) viewName;
//- (void) updatePlotWithUpdateAxes: (BOOL) updateAxes;
- (void) togglePositionIndicator;
- (void) leftSideExpand;
- (void) leftSideContract;
- (void) rightSideExpand;
- (void) rightSideContract;
- (void) bottomExpand;
- (void) bottomContract;
- (void) topExpand;
- (void) topContract;
//- (void) setZoomDataViewFrom:(long)startDateTime
//                          To:(long) endDateTime;
//- (void) renderPlotWithFields: (NSArray *) linesToPlot;
- (void) toggleAxisLabelsForLayer: (int) layerIndex;
- (void) removeLineAnnotation;
- (void) setBasicParametersForPlot;
- (void) updateLines: (SeriesPlotDataWrapper *) dataSource;
@property (retain) CPTGraphHostingView *hostingView;
@property (readonly, retain) NSString *identifier;
@property (retain) SeriesPlotDataWrapper *dataSource;
//@property (retain) DataView *dataView;
@property (retain) NSArray *timeSeriesLines;
@property long minXrangeForPlot;
@property long maxXrangeForPlot;


@end


