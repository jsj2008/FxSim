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


-(id)initWithDataSeries: (DataSeries *) underlyingSeries 
                AndName: (NSString *) viewName 
          AndStartIndex: (long) startIndex 
            AndEndIndex: (long) endIndex 
                AndMins: (NSMutableDictionary *) mins 
                AndMaxs: (NSMutableDictionary *) maxs;
{
    self = [super init];
    if(self){
        _name = viewName;
        _dataSeries = underlyingSeries;
        _startIndexForPlot = startIndex;
        _countForPlot = (endIndex - startIndex) + 1;
        _minYvalues = mins;
        _maxYvalues = maxs;
        
    }
    return self;
}


- (NSString *)description
{
    long startDateTime, endDateTime;
    
    startDateTime = [[[_dataSeries xData] sampleValue:[self startIndexForPlot]] longValue];
    endDateTime = [[[_dataSeries xData] sampleValue:([self startIndexForPlot] + [self countForPlot])-1] longValue];
    
    NSString *description;
    description = [NSString stringWithFormat:@"Name:%@ \nStart:%@ \nEnd: %@",[self name],[EpochTime stringDateWithTime:startDateTime],[EpochTime stringDateWithTime:endDateTime]]; 
       return description;
}

- (void) encodeWithCoder:(NSCoder*)encoder
{
    
    
    [encoder encodeObject:_name forKey:@"NAME"];
    [encoder encodeObject:[NSNumber numberWithInteger:_startIndexForPlot] forKey:@"STARTINDEXFORPLOT"];
    [encoder encodeObject:[NSNumber numberWithInteger:_countForPlot] forKey:@"COUNTFORPLOT"];
    [encoder encodeObject:_minYvalues forKey:@"MINYVALUES"];
    [encoder encodeObject:_maxYvalues forKey:@"MAXYVALUES"];
    [encoder encodeObject:_dataSeries forKey:@"DATASERIES"];
    
}
- (id) initWithCoder:(NSCoder*)decoder
{
    if (self = [super init]) {
        // If parent class also adopts NSCoding, replace [super init]
        // with [super initWithCoder:decoder] to properly initialize.
        
        // NOTE: Decoded objects are auto-released and must be retained
        _name = [decoder decodeObjectForKey:@"NAME"];
        _startIndexForPlot = [[decoder decodeObjectForKey:@"STARTINDEXFORPLOT"] unsignedIntValue];
        _countForPlot = [[decoder decodeObjectForKey:@"COUNTFORPLOT"] unsignedIntValue];
        _minYvalues = [decoder decodeObjectForKey:@"MINYVALUES"];
        _maxYvalues = [decoder decodeObjectForKey:@"MAXYVALUES"]; 
        _dataSeries = [decoder decodeObjectForKey:@"DATASERIES"]; 
        
    }
    return self; 
}



-(long)minDateTime
{
    return [[[_dataSeries xData] sampleValue:[self startIndexForPlot]] longValue];
}

-(long)maxDateTime
{
    return [[[_dataSeries xData] sampleValue:(([self startIndexForPlot] + [self countForPlot])-1)] longValue];
}

- (double) minDataValue
{
    NSArray *fieldNames = [[self minYvalues] allKeys];
    
    double minValue = 0.0;
    if([fieldNames count] > 0){
        minValue = [[[self minYvalues] objectForKey:[fieldNames objectAtIndex:0]] doubleValue];
        for(int i = 2; i < [[self minYvalues] count];i++){
            minValue = fmin(minValue,[[[self minYvalues] objectForKey:[fieldNames objectAtIndex:0]] doubleValue]);
        }
    }
    return minValue;
}

- (double) maxDataValue
{
    NSArray *fieldNames = [[self maxYvalues] allKeys];
    
    double maxValue = 0.0;
    if([fieldNames count] > 0){
        maxValue = [[[self maxYvalues] objectForKey:[fieldNames objectAtIndex:0]] doubleValue];
        for(int i = 2; i < [[self maxYvalues] count];i++){
            maxValue = fmin(maxValue,[[[self maxYvalues] objectForKey:[fieldNames objectAtIndex:0]] doubleValue]);
        }
    }
    return maxValue;
}

-(NSUInteger)numberOfRecordsForPlot:(CPTPlot *)plot
{
	return (NSUInteger)[self countForPlot];
}

- (CPTNumericData *)dataForPlot:(CPTPlot  *) plot 
                          field:(NSUInteger) field 
               recordIndexRange:(NSRange) indexRange 
{ 
    
    NSRange rangeOnOriginal =  NSMakeRange([self startIndexForPlot] + indexRange.location,indexRange.length);
    CPTNumericData *dataToReturn;
    NSString *dataIdentifer;
    dataIdentifer = (NSString *)plot.identifier;
    dataIdentifer = [dataIdentifer substringFromIndex:3];
    
    if (field == CPTScatterPlotFieldX)
    {
        dataToReturn = [_dataSeries xData]; 
    }else
    {
        dataToReturn = [[_dataSeries yData] objectForKey:dataIdentifer]; 
    }
    if (NSEqualRanges(rangeOnOriginal, NSMakeRange(0, [_dataSeries  length]))) 
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

#pragma mark -
#pragma mark Variables 

@synthesize startIndexForPlot = _startIndexForPlot;
@synthesize countForPlot = _countForPlot;
@synthesize name = _name;
@synthesize minYvalues =_minYvalues;
@synthesize maxYvalues = _maxYvalues;


@end
