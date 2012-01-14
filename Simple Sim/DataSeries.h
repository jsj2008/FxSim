//
//  DataSeries.h
//  Simple Sim
//
//  Created by Martin O'Connor on 06/01/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//



#import <Foundation/Foundation.h> 
#import <corePlot/corePlot.h> 
@interface DataSeries : NSObject 
@property (assign)            NSString *name;
@property (assign)            NSUInteger idtag;
@property (nonatomic)         NSUInteger       count; 
@property (nonatomic, strong) CPTNumericData * xData; 
@property (nonatomic, strong) CPTNumericData * yData; 
@property (nonatomic)         NSUInteger       passFilter; 
@property (nonatomic)         long       minXdata; 
@property (nonatomic)         long       maxXdata;
@property (nonatomic)         double       minYdata; 
@property (nonatomic)         double       maxYdata;


- (void)reset; 
//- (CPTNumericData *)dataForField:(CPTScatterPlotField)field 
//                           range:(NSRange            )range; 

-(id)init;
-(id)initWithName:(NSString *)seriesName AndDbTag:(int) dbId;
-(void)setDataSeriesWithLength: (NSUInteger)length AndMinDate:(long) minDate AndMaxDate:(long) maxDate AndDates:(CPTNumericData *)epochdates AndData: (CPTNumericData *)dataSeries AndMinDataValue:(double) minValue AndMaxDataValue:(double) maxValue;

-(void)setDataSeriesWithLength: (NSUInteger)length AndMinDate:(long) minDate AndMaxDate:(long) maxDate AndDates:(CPTNumericData *)epochdates AndData: (CPTNumericData *)dataSeries AndPassFilter:(NSUInteger) passfilter;

@end 





//#import <Foundation/Foundation.h>
//#import <corePlot/corePlot.h>
//
//@interface DataSeries : NSObject{
//    NSString *name;
//    int tag;
//    int length;
//    
//    
//    @private
//    CPTNumericDataType *dateTimes;
//    CPTNumericDataType *dataValues; 
//    
//}
//-(long *)getDates;
//-(float *)getData;
//
//-(id)init;
//-(id)initWithName:(NSString *)seriesName AndDbTag:(int) dbId;
//-(id)initWithName:(NSString *)seriesName AndDbTag:(int) dbId AndLength:(int) size;
//-(void)setDataSeriesWithLength: (int)size AndDates:(long *)epochdates AndData: (float *)dataSeries; 
//-(BOOL)setValueAtIndex: (int) index WithDateTime: (long) dateTime AndValue: (float) value;
//-(float)getValueAtZeroBasedIndex: (int) index;
//-(long)getDateTimeAtZeroBasedIndex: (int) index;
//-(long)getFirstDateTime;
//-(long)getLastDateTime;
//
//@property(readonly) NSString *name;
//@property(readonly) int tag;
//@property(readonly) int length;
//
//@end
