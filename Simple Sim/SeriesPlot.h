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
//    int majorIntervalForX;
}

- (id)   initWithIdentifier:(NSString*) identifierString;
- (void) initialGraphAndAddAnnotation: (BOOL) doAnnotation;
-(void) positionIndicatorOff: (SeriesPlotDataWrapper *) dataSource;
- (void) updatePositionIndicator: (SeriesPlotDataWrapper *) dataSource;
- (void) leftSideExpand;
- (void) leftSideContract;
- (void) rightSideExpand;
- (void) rightSideContract;
- (void) bottomExpand;
- (void) bottomContract;
- (void) topExpand;
- (void) topContract;
- (void) toggleAxisLabelsForLayer: (int) layerIndex;
- (void) removeLineAnnotation;
- (void) setBasicParametersForPlot;
- (void) updateLines: (SeriesPlotDataWrapper *) dataSource
      AndUpdateYAxes: (BOOL) updateYAxis;
@property (retain) CPTGraphHostingView *hostingView;
@property (readonly, retain) NSString *identifier;
@property (retain) SeriesPlotDataWrapper *dataSource;
@property (retain) NSArray *timeSeriesLines;
@property long minXrangeForPlot;
@property long maxXrangeForPlot;
@property (retain) NSAlert *alert;

@end


