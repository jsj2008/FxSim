//
//  SeriesPlotDataWrapper.h
//  Simple Sim
//
//  Created by Martin on 25/04/2013.
//  Copyright (c) 2015 MARTIN OCONNOR. All rights reserved.
//

#import <Foundation/Foundation.h>
//#import "SeriesPlotData.h"
#import <corePlot/corePlot.h>

@class Simulation;

@interface SeriesPlotDataWrapper : NSObject<CPTPlotDataSource>

-(id)initWithTargetPlotName: (NSString *) plotName
             AndSimulationA: (Simulation *) simA
             AndSimulationB: (Simulation *) simB
            AndTSDictionary: (NSDictionary *) timeSeriesDictionary
    AndDoShortLongIndicator: (BOOL) doShortLong
                  AndDoDots: (BOOL) doDots;

- (id) initWithTargetPlotName: (NSString *) plotName
                AndSimulation: (Simulation *) simA
              AndTSDictionary: (NSDictionary *) timeSeriesDictionary
      AndDoShortLongIndicator: (BOOL) doShortLong;

- (NSDictionary *) setDataViewWithStartDateTime: (long) startDateTime
                                 AndEndDateTime: (long) endDateTime
                                         AsZoom: (BOOL) viewIsZoom;
- (NSDictionary *) xyRanges;
- (void) unZoomDataView;

@property (retain) Simulation *simulationA;
@property (retain) Simulation *simulationB;
@property (retain) NSDictionary *timeSeriesLinesDictionary;
@property (retain) NSString *targetPlotName;
@property long dataViewStartDateTime;
@property long dataViewEndDateTime;
@property long minStartDateTime;
@property long maxEndDateTime;
@property long isZoomed;
@property BOOL shortLongIndicatorA;
@property BOOL shortLongIndicatorB;
@property BOOL doDotsForSecondPlot;
@end
