//
//  SimpleScatterPlot.h
//  CorePlotGallery
//
//  Created by Jeff Buck on 7/31/10.
//  Copyright 2010 Jeff Buck. All rights reserved.
//

#import <CorePlot/CorePlot.h>
@class DataSeries;
@class DataView;
@class TimeSeriesLines;

@interface SeriesPlot : NSObject<CPTPlotSpaceDelegate>//: PlotItem<CPTPlotSpaceDelegate>
{
	CPTGraphHostingView *hostingView;
    CPTPlotSpaceAnnotation *symbolTextAnnotation;
	NSMutableArray *graphs;
    DataView *dataView;
	NSString *title;
    DataSeries *plotData;
}

-(void)initialGraph;
-(void)setData:(DataSeries  *) newData WithViewName: (NSString *) viewName;
-(void)showSeries:(NSString *)seriesName;

@property (nonatomic, retain) CPTGraphHostingView *hostingView;
@property (nonatomic, retain) NSMutableArray *graphs;
@property (nonatomic, retain) NSString *title;

-(void)renderPlotWithFields: (NSArray *) timeSeriesLines;

@end


