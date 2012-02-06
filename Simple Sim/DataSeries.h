//
//  DataSeries.h
//  Simple Sim
//
//  Created by Martin O'Connor on 06/01/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//



#import <Foundation/Foundation.h> 
#import <corePlot/corePlot.h> 
@interface DataSeries: NSObject{
    NSUInteger startIndexForPlot;
    NSUInteger countForPlot;
}
@property (assign)            NSString *name;
@property (assign)            NSUInteger dbId;
@property (nonatomic, strong) CPTNumericData * xData; 
@property (nonatomic, strong) NSMutableDictionary * yData;
@property (nonatomic, strong) NSMutableDictionary * dataViews;  
@property (nonatomic)         NSUInteger       timeStep;
@property (assign)            NSUInteger sampleRate;  
@property (assign)            double pipSize;  
 

- (id)init;
- (id)initWithName:(NSString *)seriesName;
- (id)initWithName:(NSString *)seriesName AndDbTag:(NSUInteger) dbId;
- (void)setPlotViewWithName: (NSString *) description AndStartDateTime: (long) startDateTime AndEndDateTime: (long) endDateTime;
- (void)setDataSeriesWithFieldName:(NSString *)fieldName AndDates:(CPTNumericData *)epochdates AndData: (CPTNumericData *)dataSeries;
-(void)reduceDataSeriesToSampledSeconds: (int) numberOfSeconds;
-(DataSeries *) sampleDataAtInterval: (int) numberOfSeconds;
-(long)nearestXBelowOrEqualTo: (long) xValue;
-(long)minDateTime;
-(long)maxDateTime;
-(NSUInteger)length;


@end 

