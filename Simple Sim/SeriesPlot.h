//
//  SimpleScatterPlot.h
//  CorePlotGallery
//
//  Created by Jeff Buck on 7/31/10.
//  Copyright 2010 Jeff Buck. All rights reserved.
//

#import <CorePlot/CorePlot.h>
#import "SimulationOutput.h"
@class DataSeries;
@class DataView;
@class TimeSeriesLines;

@interface SeriesPlot : NSObject<CPTPlotSpaceDelegate>
{
	CPTGraphHostingView *hostingView;
    CPTXYGraph *graph;
    CPTPlotSpaceAnnotation *symbolTextAnnotation;
	//NSMutableArray *graphs;
    DataView *dataView;
	NSString *title;
    DataSeries *plotData;
    NSArray *timeSeriesLines;
    //id<SimulationOutput> delegate;

    long minXrangeForPlot, maxXrangeForPlot;
    double minYrangeForPlot, maxYrangeForPlot;
    
    //long minXdataForPlot, maxXdataForPlot;
    int majorIntervalForX; 
    //double minYdataForPlot, maxYdataForPlot;
    double majorIntervalForY;
    
    CPTMutablePlotRange *xRangeZoomOut;
    CPTMutablePlotRange *yRangeZoomOut;
    
    BOOL zoomedOut;
    
    CPTPlotSpaceAnnotation *zoomAnnotation;
	CGPoint dragStart, dragEnd;
}

-(IBAction)zoomIn;
-(IBAction)zoomOut;


//-(void)setDelegate:(id)del;
-(void)initialGraphAndAddAnnotation: (BOOL) doAnnotation;
-(void)setData:(DataSeries  *) newData WithViewName: (NSString *) viewName;
-(void)showSeries:(NSString *)seriesName;
-(void)visibilityOfLineUpdated;
-(void)togglePositionIndicator;
-(void)leftSideExpand;
-(void)leftSideContract;
-(void)bottomExpand;
-(void)bottomContract;

@property (nonatomic, retain) CPTGraphHostingView *hostingView;
@property (nonatomic, retain) NSMutableArray *graphs;
@property (nonatomic, retain) NSString *title;

-(void)renderPlotWithFields: (NSArray *) timeSeriesLines;

@end


