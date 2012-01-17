//
//  SimpleScatterPlot.h
//  CorePlotGallery
//
//  Created by Jeff Buck on 7/31/10.
//  Copyright 2010 Jeff Buck. All rights reserved.
//

#import "PlotItem.h"
@class DataSeries;

@interface SimpleScatterPlot : PlotItem<CPTPlotDataSource, CPTPlotSpaceDelegate>
{
	CPTPlotSpaceAnnotation *symbolTextAnnotation;
    
	//NSArray *plotData;
    DataSeries *plotData;
}

-(void)setData:(DataSeries *) newData;

@end


//CPTPlotSpaceDelegate