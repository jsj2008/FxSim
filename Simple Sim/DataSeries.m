//
//  DataSeries.m
//  Simple Sim
//
//  Created by Martin O'Connor on 06/01/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "DataSeries.h"

#pragma mark - 
#pragma mark Implementation 
@implementation DataSeries 

-(id)init
{
    return [self initWithName:@"" AndDbTag:0];
}
-(id)initWithName:(NSString *)seriesName AndDbTag:(int) dbId
{
    self = [super init];
    if(self){
        self.name = seriesName;
        self.idtag = dbId;
        self.count = 0;
        self.xData = nil; 
        self.yData = nil; 
        self.passFilter =1;
    }    
    return self;    
}


// Reset ourself to baseline values. 
- (void)reset 
{ 
    self.count = 0; 
    self.xData = nil; 
    self.yData = nil; 
    self.passFilter =1;

} 


-(void)setDataSeriesWithLength: (NSUInteger)length AndMinDate:(long) minDate AndMaxDate:(long) maxDate AndDates:(CPTNumericData *)epochdates AndData: (CPTNumericData *)dataSeries AndMinDataValue:(double) minValue AndMaxDataValue:(double) maxValue;
{
    self.xData = epochdates;
    self.yData = dataSeries;
    self.count = length;
    self.passFilter = 1;
    self.minXdata = minDate;
    self.maxXdata = maxDate;
    self.minYdata = minValue;
    self.maxYdata = maxValue;
}

-(void)setDataSeriesWithLength: (NSUInteger)length AndMinDate:(long) minDate AndMaxDate:(long) maxDate AndDates:(CPTNumericData *)epochdates AndData: (CPTNumericData *)dataSeries AndPassFilter:(NSUInteger) passfilter
{
    self.xData = epochdates;
    self.yData = dataSeries;
    self.count = length;
    self.passFilter = passfilter;
    self.minXdata = minDate;
    self.maxXdata = maxDate;
}

// If the requested range is the same as our field range, then return 
// the corresponding field range, otherwise return a subrange. 
//- (CPTNumericData *)dataForField:(CPTScatterPlotField)field 
//                           range:(NSRange            )range 
//{ 
//    CPTNumericData * data; 
//    if (field == CPTScatterPlotFieldX) data = self.xData; 
//    else                               data = self.yData; 
//    if (NSEqualRanges(range, NSMakeRange(0, self.count))) 
//    { 
//        return data; 
//    } 
//    else 
//    { 
//        CPTNumericDataType dataType = data.dataType; 
//        NSRange            subRange = NSMakeRange(range.location * dataType.sampleBytes, 
//                                                  range.length   * dataType.sampleBytes); 
//        return [CPTNumericData numericDataWithData:[data.data subdataWithRange:subRange] 
//                                          dataType:dataType 
//                                             shape:nil]; 
//    } 
//} 

#pragma mark - 
#pragma mark Accessors 
@synthesize count = __count; 
@synthesize xData = __xData; 
@synthesize yData = __yData; 
@synthesize idtag;
@synthesize name;
@synthesize passFilter;
@synthesize minXdata;
@synthesize maxXdata;
@synthesize minYdata;
@synthesize maxYdata;
@synthesize pipSize;


#pragma mark -
#pragma mark Plot Data Source Methods

-(NSUInteger)numberOfRecordsForPlot:(CPTPlot *)plot
{
	return [self count];
}

- (CPTNumericData *)dataForPlot:(CPTPlot  *)plot 
                          field:(NSUInteger)field 
               recordIndexRange:(NSRange   )indexRange 
{ 
    CPTNumericData * data; 
    if (field == CPTScatterPlotFieldX) 
    {
        data = self.xData; 
    }else{
        data = self.yData;    
    }
    if (NSEqualRanges(indexRange, NSMakeRange(0, self.count))) 
    { 
        return data; 
    } 
    else 
    { 
        CPTNumericDataType dataType = data.dataType; 
        NSRange subRange = NSMakeRange(indexRange.location * dataType.sampleBytes, indexRange.length * dataType.sampleBytes); 
        return [CPTNumericData numericDataWithData:[data.data subdataWithRange:subRange] 
                                          dataType:dataType 
                                             shape:nil]; 
    } 
}





@end 


//#import "DataSeries.h"
//
//@implementation DataSeries
//@synthesize name;
//@synthesize tag;
//@synthesize length;
//
//-(long *)getDates
//{
//    return dateTimes;
//    
//}
//-(float *)getData
//{
//    return dataValues;
//}
//
//-(id)init
//{
//    return [self initWithName:@"" AndDbTag:0 AndLength:0];
//}
//
//-(id)initWithName:(NSString *)seriesName AndDbTag:(int) dbId
//{
//    return [self initWithName:seriesName AndDbTag:dbId AndLength:0];
//}
//
//-(id)initWithName:(NSString *)seriesName AndDbTag:(int) dbId AndLength:(int) size
//{
//    self = [super init];
//    if(self){
//        name = seriesName;
//        tag = dbId;
//        length = size;
//        if(length > 0)
//        {
//            @try{
//                dateTimes = calloc(length,sizeof(long));
//                dataValues = calloc(length,sizeof(long));
//            }
//            @catch (NSException* ex) {
//                length = 0;
//                dateTimes = nil;
//                dataValues = nil;
//                NSLog(@"Error occured setting up data %@",[ex description]);
//            }
//        }
//
//    }
//    return self;    
//}
//
//-(void)setDataSeriesWithLength: (int)size AndDates:(long *)epochdates AndData: (float *)dataSeries
//{
//    if(size > 0)
//    {
//        @try{
//            length = size;
//            dateTimes = calloc(length,sizeof(long));
//            dataValues = calloc(length,sizeof(long));
//            for(int i = 0;i<length;i++)
//            {
//                dateTimes[i] = epochdates[i];
//                dataValues[i] = dataSeries[i];
//            }
//        }
//        @catch (NSException* ex) {
//            length = 0;
//            dateTimes = nil;
//            dataValues = nil;
//            NSLog(@"Error occured setting up data %@",[ex description]);
//        }
//    }
//}
//
//-(BOOL)setValueAtIndex: (int)index WithDateTime: (long) dateTime AndValue: (float) value
//{
//    BOOL success = YES;
//    if((index > -1) && (index < [self length])){
//        @try{
//            self->dateTimes[index] = dateTime;
//            self->dataValues[index] = value;
//        }
//        @catch(NSException* ex) {
//            success = NO;
//        }
//    }else{
//        success = NO;
//    }
//    return success;
//}
//
//-(float)getValueAtZeroBasedIndex: (int) index{
//    return dataValues[index];
//}
//-(long)getDateTimeAtZeroBasedIndex: (int) index{
//    return dateTimes[index];
//}
//-(long)getFirstDateTime{
//    return dateTimes[0];
//
//}
//-(long)getLastDateTime{
//    return dateTimes[length-1];
//}
//
//@end
