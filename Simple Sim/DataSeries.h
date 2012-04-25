//
//  DataSeries.h
//  Simple Sim
//
//  Created by Martin O'Connor on 06/01/2012.
//  Copyright (c) 2012 OCONNOR RESEARCH. All rights reserved.
//



#import <Foundation/Foundation.h> 
#import <corePlot/corePlot.h> 
@interface DataSeries: NSObject{
    //NSUInteger startIndexForPlot;
    //NSUInteger countForPlot;
}
@property (atomic,retain)            NSString *name;
@property (assign)            NSUInteger dbId;
@property (nonatomic, retain) CPTNumericData * xData; 
@property (atomic, retain) NSMutableDictionary * yData;
@property (atomic, retain) NSMutableDictionary * dataViews;  
@property (assign)            NSUInteger sampleRate;  
@property (assign)            double pipSize;  
 

//- (id)init;
//- (id)initWithName:(NSString *)seriesName;
- (id)initWithName:(NSString *)seriesName AndDbTag:(NSUInteger) dbId AndPipSize:(double) pipSize;

-(void)setPlotViewWithName: (NSString *) description AndStartDateTime: (long) startDateTime AndEndDateTime: (long) endDateTime;
-(void)setDataSeriesWithFieldName:(NSString *)fieldName AndDates:(CPTNumericData *)epochdates AndData: (CPTNumericData *)dataSeries;
-(void)reduceDataSeriesToSampledSeconds: (int) numberOfSeconds;
-(DataSeries *) sampleDataAtInterval: (int) numberOfSeconds;
-(NSDictionary *)getValues:(NSArray *) fieldNames AtDateTime: (long) dateTime;
-(long)latestDateTimeBeforeOrEqualTo: (long) dateTime;
-(long)minDateTime;
-(long)maxDateTime;
-(NSUInteger)length;
-(DataSeries *) getCopyOfStaticData;
-(NSArray *)getFieldNames;
-(BOOL)writeDataSeriesToFile: (NSURL *) fileNameAndPath;

@end 

