//
//  DataView.m
//  Simple Sim
//
//  Created by Martin O'Connor on 27/01/2012.
//  Copyright (c) 2012 OCONNOR RESEARCH. All rights reserved.
//

#import "DataView.h"
#import "DataSeries.h"
#import "EpochTime.h"

@implementation DataView
@synthesize startIndexForPlot;
@synthesize countForPlot;
@synthesize name;
@synthesize minYvalues;
@synthesize maxYvalues;


-(id)initWithDataSeries: (DataSeries *) underlyingSeries AndName:(NSString *) viewName AndStartIndex: (long) startIndex AndEndIndex: (long) endIndex AndMins:(NSMutableDictionary *) mins AndMaxs:(NSMutableDictionary *) maxs;
{
    self = [super init];
    if(self){
        name = viewName;
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

- (NSString *)description
{
    long startDateTime, endDateTime;
    
    startDateTime = [[[dataSeries xData] sampleValue:startIndexForPlot] longValue];
    endDateTime = [[[dataSeries xData] sampleValue:(startIndexForPlot + countForPlot)-1] longValue];
    
    NSString *description;
    description = [NSString stringWithFormat:@"Name       :%@\n",name]; 
    description = [NSString stringWithFormat:@"%@Start      :%@\n",description, [EpochTime stringDateWithTime:startDateTime]];
    description = [NSString stringWithFormat:@"%@End        :%@\n",description, [EpochTime stringDateWithTime:endDateTime]];
   
    return description;
}

-(long)minDateTime
{
    return [[[dataSeries xData] sampleValue:startIndexForPlot] longValue];
}

-(long)maxDateTime
{
    return [[[dataSeries xData] sampleValue:((startIndexForPlot + countForPlot)-1)] longValue];
}

- (double) minDataValue
{
    NSArray *fieldNames = [minYvalues allKeys];
    
    double minValue = 0.0;
    if([fieldNames count] > 0){
        minValue = [[minYvalues objectForKey:[fieldNames objectAtIndex:0]] doubleValue];
        for(int i = 2; i < [minYvalues count];i++){
            minValue = fmin(minValue,[[minYvalues objectForKey:[fieldNames objectAtIndex:0]] doubleValue]);
        }
    }
    return minValue;
}

- (double) maxDataValue
{
    NSArray *fieldNames = [maxYvalues allKeys];
    
    double maxValue = 0.0;
    if([fieldNames count] > 0){
        maxValue = [[maxYvalues objectForKey:[fieldNames objectAtIndex:0]] doubleValue];
        for(int i = 2; i < [maxYvalues count];i++){
            maxValue = fmin(maxValue,[[maxYvalues objectForKey:[fieldNames objectAtIndex:0]] doubleValue]);
        }
    }
    return maxValue;
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
    NSString *dataIdentifer;
    dataIdentifer = (NSString *)plot.identifier;
    dataIdentifer = [dataIdentifer substringFromIndex:3];
    //return [dataSeries dataForPlot:plot field:field recordIndexRange: rangeOnOriginal]; 
    
    if (field == CPTScatterPlotFieldX)
    {
        dataToReturn = [dataSeries xData]; 
    }else
    {
        dataToReturn = [[dataSeries yData] objectForKey:dataIdentifer]; 
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

@end
