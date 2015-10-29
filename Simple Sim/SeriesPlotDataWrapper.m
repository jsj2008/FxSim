//
//  SeriesPlotDataWrapper.m
//  Simple Sim
//
//  Created by Martin on 25/04/2013.
//  Copyright (c) 2015 MARTIN OCONNOR. All rights reserved.
//

#import "SeriesPlotDataWrapper.h"
#import "Simulation.h"
#import "DataView.h"
#import "DataSeries.h"
#import "TimeSeriesLine.h"

@implementation SeriesPlotDataWrapper

#pragma mark -
#pragma mark Setup Methods

-(id)initWithTargetPlotName: (NSString *) plotName
             AndSimulationA: (Simulation *) simA
             AndSimulationB: (Simulation *) simB
            AndTSDictionary: (NSDictionary *) timeSeriesDictionary
    AndDoShortLongIndicator: (BOOL) doShortLong
                  AndDoDots: (BOOL) doDots
{
    self = [super init];
    if(self){
        _targetPlotName = plotName;
        _simulationA = simA;
        _simulationB = simB;
        _timeSeriesLinesDictionary = timeSeriesDictionary;
        _isZoomed = NO;
        _doDotsForSecondPlot = doDots;
        _shortLongIndicatorA = NO;
        _shortLongIndicatorB = NO;
        return self;
    }
    return nil;
}

- (id) initWithTargetPlotName: (NSString *) plotName
                AndSimulation: (Simulation *) simA
              AndTSDictionary: (NSDictionary *) timeSeriesDictionary
      AndDoShortLongIndicator: (BOOL) doShortLong
{
    return [self initWithTargetPlotName: plotName
                         AndSimulationA: simA
                         AndSimulationB: Nil
                        AndTSDictionary: timeSeriesDictionary
                AndDoShortLongIndicator:doShortLong
                              AndDoDots:NO];
}

- (NSDictionary *) setDataViewWithStartDateTime: (long) startDateTime
                                 AndEndDateTime: (long) endDateTime
                                         AsZoom: (BOOL) viewIsZoom
{
    DataSeries *dataSeriesA = [[self simulationA] analysisDataSeries];
    DataSeries *dataSeriesB;
    if([self simulationB]){
        dataSeriesB = [[self simulationB] analysisDataSeries];
    }
    
    NSDictionary *minMaxA, *minMaxB;
    
    minMaxA = [dataSeriesA setDataViewWithName: [self targetPlotName]
                              AndStartDateTime: startDateTime
                                AndEndDateTime: endDateTime];
    
    long minDateTime, maxDateTime;
    
    if([self simulationB]){
        minMaxB = [dataSeriesB setDataViewWithName: [self targetPlotName]
                                  AndStartDateTime: startDateTime
                                    AndEndDateTime: endDateTime];
        minDateTime = MAX([[minMaxA objectForKey:@"MIN"] longValue],[[minMaxB objectForKey:@"MIN"] longValue]);
        maxDateTime = MIN([[minMaxA objectForKey:@"MAX"] longValue],[[minMaxB objectForKey:@"MAX"] longValue]);
    }else{
        minDateTime = [[minMaxA objectForKey:@"MIN"] longValue];
        maxDateTime = [[minMaxA objectForKey:@"MAX"] longValue];
    }
    
    [self setDataViewStartDateTime:minDateTime];
    [self setDataViewEndDateTime:maxDateTime];
    if(!viewIsZoom){
        [self setMinStartDateTime:minDateTime];
        [self setMaxEndDateTime:maxDateTime];
    }
    
    [self setIsZoomed:viewIsZoom];
    NSDictionary *minMax = [[NSDictionary alloc] initWithObjectsAndKeys:[NSNumber numberWithLong:minDateTime],@"MIN",[NSNumber numberWithLong:maxDateTime], @"MAX", nil];
    return minMax;
}

- (void) unZoomDataView
{
    DataSeries *dataSeriesA = [[self simulationA] analysisDataSeries];
    DataSeries *dataSeriesB;
    if([self simulationB]){
        dataSeriesB = [[self simulationB] analysisDataSeries];
    }
    
    
    [dataSeriesA setDataViewWithName: [self targetPlotName]
                              AndStartDateTime: [self minStartDateTime]
                                AndEndDateTime: [self maxEndDateTime]];
    
    if([self simulationB]){
        [dataSeriesB setDataViewWithName: [self targetPlotName]
                        AndStartDateTime: [self minStartDateTime]
                          AndEndDateTime: [self maxEndDateTime]];
    }
    
    [self setDataViewStartDateTime: [self minStartDateTime]];
    [self setDataViewEndDateTime:[self maxEndDateTime]];
    [self setIsZoomed:NO];
    
}

- (void) setYRanges
{
    
}

//- (NSDictionary *) setCompareDataViewWithStartDateTime: (long) startDateTime
//                                        AndEndDateTime: (long) endDateTime
//{
//    DataSeries *dataSeriesA = [[self simulationA] analysisDataSeries];
//    DataSeries *dataSeriesB;
//    if([self simulationB]){
//        dataSeriesB = [[self simulationB] analysisDataSeries];
//    }
//    
//    NSDictionary *minMaxA, *minMaxB;
//    
//    
//    minMaxA = [dataSeriesA setDataViewWithName: @"COMPARE"
//                              AndStartDateTime: startDateTime
//                                AndEndDateTime: endDateTime];
//    
//    long minDateTime, maxDateTime;
//    
//    if([self simulationB]){
//        minMaxB = [dataSeriesB setDataViewWithName: @"COMPARE"
//                                  AndStartDateTime: startDateTime
//                                    AndEndDateTime: endDateTime];
//        minDateTime = MAX([[minMaxA objectForKey:@"MIN"] longValue],[[minMaxB objectForKey:@"MIN"] longValue]);
//        maxDateTime = MIN([[minMaxA objectForKey:@"MAX"] longValue],[[minMaxB objectForKey:@"MAX"] longValue]);
//    }else{
//        minDateTime = [[minMaxA objectForKey:@"MIN"] longValue];
//        maxDateTime = [[minMaxB objectForKey:@"MAX"] longValue];
//    }
//    
//   
//   
//    NSDictionary *minMax = [[NSDictionary alloc] initWithObjectsAndKeys:[NSNumber numberWithLong:minDateTime],@"MIN",[NSNumber numberWithLong:maxDateTime], @"MAX", nil];
//    return minMax;
//}

//-(NSDictionary *) timeSeriesLines{
//    return [self timeSeriesLinesDictionary];
//}

//-(DataView *) getDataViewForKey: (NSString *) viewName
//{
//    return Nil;
//}

//- (long) minDateTime
//{
//    return MAX([[self simulationA] startDate],[[self simulationB] startDate]);
//}
//
//- (long) maxDateTime
//{
//    return MIN([[self simulationA] endDate],[[self simulationB] endDate]);
//}

//- (long) minDataViewDateTime
//{
//    DataView *dvA, *dvB;
//    long minDateTime = 0;
//    if([self simulationB] != Nil){
//        dvA = [[[self simulationA] analysisDataSeries] getDataViewForKey:@"COMPARE"];
//        dvB = [[[self simulationB] analysisDataSeries] getDataViewForKey:@"COMPARE"];
//        minDateTime =  MIN([dvA minDateTime],[dvB minDataValue]);
//    }else{
//        dvA = [[[self simulationA] analysisDataSeries] getDataViewForKey:@"ALL"];
//        minDateTime =  [dvA minDateTime];
//    }
//    return minDateTime;
//    
//}
//
//- (long) maxDataViewDateTime
//{
//    DataView *dvA, *dvB;
//    long maxDateTime = 0;
//    if([self simulationB] != Nil){
//        dvA = [[[self simulationA] analysisDataSeries] getDataViewForKey:@"COMPARE"];
//        dvB = [[[self simulationB] analysisDataSeries] getDataViewForKey:@"COMPARE"];
//        maxDateTime = MAX([dvA maxDateTime],[dvB maxDataValue]);
//    }else{
//        dvA = [[[self simulationA] analysisDataSeries] getDataViewForKey:@"ALL"];
//        maxDateTime = [dvA maxDateTime];
//    }
//    return maxDateTime;
//}


- (NSDictionary *) xyRanges
{
    double minYrangeForPlot0 = 0.0, maxYrangeForPlot0 = 0.0;
    double minYrangeForPlot1 = 0.0, maxYrangeForPlot1 = 0.0;
    double minYrangeForPlot2 = 0.0, maxYrangeForPlot2 = 0.0;
    long minXrangeForPlots = 0, maxXrangeForPlots = 0;
    NSDictionary *returnValues;
    DataView *dv;
    BOOL plot0 = NO, plot1 = NO, plot2 = NO;
    NSString *lineName;
    TimeSeriesLine *tsl;
  
    DataView *dVA = [[[self simulationA] analysisDataSeries] getDataViewForKey:[self targetPlotName]];
    DataView *dVB = [[[self simulationB] analysisDataSeries] getDataViewForKey:[self targetPlotName]];
    
    NSArray *allKeys = [[self timeSeriesLinesDictionary] allKeys];
    for(int i = 0; i < [allKeys count]; i++){
        lineName = [allKeys objectAtIndex:i];
        tsl = [[self timeSeriesLinesDictionary] objectForKey:lineName];
        //lineName = [NSString stringWithFormat:@"S%ld_L%d_%@",[tsl simId], [tsl layerIndex], [tsl name]];
        
        if([tsl simId]==0){
            dv = dVA;
        }else{
            dv = dVB;
        }
        switch ([tsl layerIndex]) {
            case 0:
                if(plot0){
                    minYrangeForPlot0 = fmin(minYrangeForPlot0, [[[dv minYvalues] valueForKey:[tsl name]] doubleValue]);
                    maxYrangeForPlot0 = fmax(maxYrangeForPlot0, [[[dv maxYvalues] valueForKey:[tsl name]] doubleValue]);
                }else{
                    minYrangeForPlot0 = [[[dv minYvalues] valueForKey:[tsl name]] doubleValue];
                    maxYrangeForPlot0 = [[[dv maxYvalues] valueForKey:[tsl name]] doubleValue];
                }
                plot0 = YES;
                break;
            case 1:
                if(plot1){
                    minYrangeForPlot1 = fmin(minYrangeForPlot1, [[[dv minYvalues] valueForKey:[tsl name]] doubleValue]);
                    maxYrangeForPlot1 = fmax(maxYrangeForPlot1, [[[dv maxYvalues] valueForKey:[tsl name]] doubleValue]);
                }else{
                    minYrangeForPlot1 = [[[dv minYvalues] valueForKey:[tsl name]] doubleValue];
                    maxYrangeForPlot1 = [[[dv maxYvalues] valueForKey:[tsl name]] doubleValue];
                }
                plot1 = YES;
                break;
            case 2:
                if(plot2){
                    minYrangeForPlot2 = fmin(minYrangeForPlot2, [[[dv minYvalues] valueForKey:[tsl name]] doubleValue]);
                    maxYrangeForPlot2 = fmax(maxYrangeForPlot2, [[[dv maxYvalues] valueForKey:[tsl name]] doubleValue]);
                }else{
                    minYrangeForPlot2 = [[[dv minYvalues] valueForKey:[tsl name]] doubleValue];
                    maxYrangeForPlot2 = [[[dv maxYvalues] valueForKey:[tsl name]] doubleValue];
                }
                plot2 = YES;
                break;
            default:
                break;
        }

    }
    
    dv = [[[self simulationA] analysisDataSeries] getDataViewForKey:[self targetPlotName]];
    if(dv){
        minXrangeForPlots = [dv minDateTime];
        maxXrangeForPlots = [dv maxDateTime];
    }else{
        dv = [[[self simulationA] analysisDataSeries] getDataViewForKey:[self targetPlotName]];
        if(dv){
            minXrangeForPlots = MIN(minXrangeForPlots,[dv minDateTime]);
            maxXrangeForPlots = MAX(maxXrangeForPlots,[dv maxDateTime]);
        }
    }
    returnValues = [NSDictionary dictionaryWithObjectsAndKeys: [NSNumber numberWithLong:plot0], @"PLOT0",
                    [NSNumber numberWithBool:plot1], @"PLOT1", [NSNumber numberWithLong:plot2], @"PLOT2",
                    [NSNumber numberWithLong:minXrangeForPlots],@"MINX", [NSNumber numberWithLong:maxXrangeForPlots],@"MAXX",
                    [NSNumber numberWithDouble:minYrangeForPlot0],@"MINY0", [NSNumber numberWithDouble:maxYrangeForPlot0],@"MAXY0",
                    [NSNumber numberWithDouble:minYrangeForPlot1],@"MINY1", [NSNumber numberWithDouble:maxYrangeForPlot1],@"MAXY1",
                    [NSNumber numberWithDouble:minYrangeForPlot2],@"MINY2", [NSNumber numberWithDouble:maxYrangeForPlot2],@"MAXY2", nil];
    return returnValues;
}

-(NSUInteger)numberOfRecordsForPlot:(CPTPlot *)plot
{
    DataView *dv;
    NSString *dataIdentifer;
    dataIdentifer = (NSString *)plot.identifier;
    int simId = [[[dataIdentifer substringFromIndex:1] substringToIndex:1] intValue];
    if(simId == 0){
        dv = [[[self simulationA] analysisDataSeries] getDataViewForKey:[self targetPlotName]];
        return [dv numberOfRecordsForPlotLine];
    }else{
       dv = [[[self simulationB] analysisDataSeries] getDataViewForKey:[self targetPlotName]];
        return [dv numberOfRecordsForPlotLine];
    }
	return 0;
}

- (CPTNumericData *)dataForPlot: (CPTPlot *) plot
                          field: (NSUInteger) field
               recordIndexRange: (NSRange) indexRange
{
    DataView *dv;
    NSString *dataIdentifer;
    dataIdentifer = (NSString *)plot.identifier;
    int simId = [[[dataIdentifer substringFromIndex:1] substringToIndex:1] intValue];
    dataIdentifer = [dataIdentifer substringFromIndex:6];
    
    if(simId == 0){
        dv = [[[self simulationA] analysisDataSeries] getDataViewForKey:[self targetPlotName]];
        return [dv dataForPlotLine:dataIdentifer field:field recordIndexRange:indexRange];
    }else{
        dv = [[[self simulationB] analysisDataSeries] getDataViewForKey:[self targetPlotName]];
        return [dv dataForPlotLine:dataIdentifer field:field recordIndexRange:indexRange];
    }
	return 0;
}


- (NSString *)description
{
    return [NSString stringWithFormat:@"SeriesPlotDataWrapper \n %@", [self targetPlotName]];
}

#pragma mark -
#pragma mark Variables

@end