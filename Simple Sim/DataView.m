//
//  DataView.m
//  Simple Sim
//
//  Created by Martin O'Connor on 27/01/2012.
//  Copyright (c) 2012 OCONNOR RESEARCH. All rights reserved.
//

#import "DataView.h"
#import "DataSeries.h"

@implementation DataView
@synthesize startIndexForPlot;
@synthesize countForPlot;
@synthesize description;
@synthesize minYvalues;
@synthesize maxYvalues;


-(id)initWithDataSeries: (DataSeries *) underlyingSeries AndName:(NSString *) name AndStartIndex: (long) startIndex AndEndIndex: (long) endIndex AndMins:(NSMutableDictionary *) mins AndMaxs:(NSMutableDictionary *) maxs;
{
    self = [super init];
    if(self){
        description = name;
        dataSeries = underlyingSeries;
        startIndexForPlot = startIndex;
        countForPlot = (endIndex - startIndex) + 1;
        minYvalues = mins;
        maxYvalues = maxs;
        
    }
    return self;
}

-(id)initAsDummy
{
    return [self initWithDataSeries: nil AndName: @"" AndStartIndex: 0 AndEndIndex:0 AndMins:Nil AndMaxs:Nil];
}

-(long)firstX
{
    return [[[dataSeries xData] sampleValue:startIndexForPlot] longValue];
}

-(long)lastX
{
    return [[[dataSeries xData] sampleValue:((startIndexForPlot + countForPlot)-1)] longValue];
}




-(NSUInteger)numberOfRecordsForPlot:(CPTPlot *)plot
{
	return [self countForPlot];
}

- (CPTNumericData *)dataForPlot:(CPTPlot  *)plot 
                          field:(NSUInteger)field 
               recordIndexRange:(NSRange   )indexRange 
{ 
    
    NSRange rangeOnOriginal =  NSMakeRange(startIndexForPlot + indexRange.location,indexRange.length);
    CPTNumericData *dataToReturn;
    //return [dataSeries dataForPlot:plot field:field recordIndexRange: rangeOnOriginal]; 
    
    if (field == CPTScatterPlotFieldX)
    {
        dataToReturn = [dataSeries xData]; 
    }else
    {
        dataToReturn = [[dataSeries yData] objectForKey:plot.identifier]; 
    }
    if (NSEqualRanges(rangeOnOriginal, NSMakeRange(0, [dataSeries  length]))) 
    { 
        return dataToReturn; 
    } 
    else 
    { 
        NSRange subRange = NSMakeRange(rangeOnOriginal.location * dataToReturn.dataType.sampleBytes, 
                                                      rangeOnOriginal.length   * dataToReturn.dataType.sampleBytes); 
            return [CPTNumericData numericDataWithData:[dataToReturn.data subdataWithRange:subRange] 
                                              dataType:dataToReturn.dataType 
                                                 shape:nil]; 
    } 
    return nil;
}

-(void)addMin: (double) min AndMax: (double) max ForKey: (NSString *)key
{
    [[self minYvalues] setObject:[NSNumber numberWithDouble:min] forKey:key];
    [[self maxYvalues] setObject:[NSNumber numberWithDouble:max] forKey:key];
}


//- (CPTNumericData *)dataForPlot:(CPTPlot  *)plot 
//                          field:(NSUInteger)field 
//               recordIndexRange:(NSRange   )indexRange 
//{ 
//    CPTNumericData *dataToReturn; 
//    NSRange range = {self.startIndexForPlot, self.countForPlot};
//    switch (field)
//    {
//        case CPTScatterPlotFieldX: 
//        {
//            dataToReturn = self.xData; 
//            //return dataToReturn;
//            break;
//        }
//        case CPTScatterPlotFieldY:
//        {
//            dataToReturn = [self.yData objectForKey:plot.identifier]; 
//            //return dataToReturn;
//            break;
//        }
//    }
//    if (NSEqualRanges(range, NSMakeRange(0, self.count))) 
//    { 
//        return dataToReturn; 
//    } 
//    else 
//    { 
//        NSRange            subRange = NSMakeRange(range.location * dataToReturn.dataType.sampleBytes, 
//                                                  range.length   * dataToReturn.dataType.sampleBytes); 
//        return [CPTNumericData numericDataWithData:[dataToReturn.data subdataWithRange:subRange] 
//                                          dataType:dataToReturn.dataType 
//                                             shape:nil]; 
//    } 
//    return nil;
//}


@end
