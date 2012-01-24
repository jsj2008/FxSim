//
//  DataSeries.h
//  Simple Sim
//
//  Created by Martin O'Connor on 06/01/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//



#import <Foundation/Foundation.h> 
#import <corePlot/corePlot.h> 
@interface DataSeries : NSObject<CPTPlotDataSource>{
    NSUInteger startIndexForPlot;
    NSUInteger countForPlot;
}
@property (assign)            NSString *name;
@property (assign)            NSUInteger idtag;
@property (nonatomic)         NSUInteger count;
@property (nonatomic, strong) CPTNumericData * xData; 
@property (nonatomic, strong) NSMutableDictionary * yData;
@property (nonatomic, strong) NSMutableDictionary * minYdataForPlot; 
@property (nonatomic, strong) NSMutableDictionary * maxYdataForPlot;
@property (assign)            double pipSize;  
@property (nonatomic)         NSUInteger       timeStep; 
//@property (nonatomic)         long       minXdataForPlot; 
//@property (nonatomic)         long       maxXdataForPlot;
@property (nonatomic)         long       minXdata; 
@property (nonatomic)         long       maxXdata;


- (void)reset; 

-(id)init;
-(id)initWithName:(NSString *)seriesName;
-(id)initWithName:(NSString *)seriesName AndDbTag:(int) dbId;
-(NSUInteger)startIndexForPlot;
-(NSUInteger)countForPlot;
//-(void)setForPlotStartIndex:(NSUInteger)startIndex AndCount:(NSUInteger)count; 
-(void)setDataSeriesWithFieldName:(NSString *)fieldName AndLength: (NSUInteger)length AndMinDate:(long) minDate AndMaxDate:(long) maxDate AndDates:(CPTNumericData *)epochdates AndData: (CPTNumericData *)dataSeries AndMinDataValue:(double) minValue AndMaxDataValue:(double) maxValue;
-(BOOL)setPlottingSubsetFromStartIndex: (long) startIndex ToEndIndex: (long) endIndex;



//
//-(void)setDataSeriesWithFieldName:(NSString *)fieldName AndLength: (NSUInteger)length AndMinDate:(long) minDate AndMaxDate:(long) maxDate AndDates:(CPTNumericData *)epochdates AndData: (CPTNumericData *)dataSeries AndMinDataValue:(double) minValue AndMaxDataValue:(double) AndPlotRange: (NSRange *) rangeToPlot;

-(void)reduceDataSeriesToSampledSeconds: (int) numberOfSeconds;

-(long)nearestXBelowOrEqualTo: (long) xValue;



@end 

