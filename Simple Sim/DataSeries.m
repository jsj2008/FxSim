//
//  DataSeries.m
//  Simple Sim
//
//  Created by Martin O'Connor on 06/01/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "DataSeries.h"
#import "EpochTime.h"

//Private method
@interface DataSeries() 
-(void)setForPlotStartIndex:(NSUInteger)startIndex AndCount:(NSUInteger)count; 
@end


#pragma mark - 
#pragma mark Implementation 
@implementation DataSeries 

-(id)init
{
    return [self initWithName:@"" AndDbTag:0];
}

-(id)initWithName:(NSString *)seriesName
{
    return [self initWithName:seriesName AndDbTag:0];
}


-(id)initWithName:(NSString *)seriesName AndDbTag:(int) dbId
{
    self = [super init];
    if(self){
        self.name = seriesName;
        self.idtag = dbId;
        self.count = 0;
        [self setForPlotStartIndex: 0 AndCount:0];
        self.xData = nil; 
        self.yData = nil; 
        self.timeStep =1;
    }    
    return self;    
}


// Reset ourself to baseline values. 
- (void)reset 
{ 
    self.count = 0; 
    self.xData = nil; 
    self.yData = nil; 
    self.timeStep =1;

} 

-(NSUInteger)startIndexForPlot
{
    return startIndexForPlot;
}

-(NSUInteger)countForPlot
{
    return countForPlot;
}


-(void)setForPlotStartIndex:(NSUInteger)startIndex AndCount:(NSUInteger)count 
{
    startIndexForPlot = startIndex;
    countForPlot = count;
}


-(void)setDataSeriesWithFieldName:(NSString*)fieldName AndLength: (NSUInteger)length AndMinDate:(long) minDate AndMaxDate:(long) maxDate AndDates:(CPTNumericData *)epochdates AndData: (CPTNumericData *)dataSeries AndMinDataValue:(double) minValue AndMaxDataValue:(double) maxValue;
{
    self.xData = epochdates;
    self.yData =  [[NSMutableDictionary alloc] init];
    [self.yData setObject:dataSeries forKey:fieldName] ;
    //self.minXdataForPlot = [[[self xData] sampleValue:0] longValue];
    //self.maxXdataForPlot = [[[self xData] sampleValue:(length-1)] longValue];
    self.minYdataForPlot = [[NSMutableDictionary alloc] init];
    [self.minYdataForPlot setObject:[NSNumber numberWithDouble:minValue]  forKey:fieldName] ;
    self.maxYdataForPlot = [[NSMutableDictionary alloc] init];
    [self.maxYdataForPlot setObject:[NSNumber numberWithDouble:maxValue]  forKey:fieldName] ;
    [self setForPlotStartIndex: 0 AndCount:length];
    self.count = length;
    self.timeStep = 1;
    self.minXdata = minDate;
    self.maxXdata = maxDate;
    //self.minXdataForPlot = minDate;
    //self.maxXdataForPlot = maxDate;
}

//-(void)setDataSeriesWithLength: (NSUInteger)length AndMinDate:(long) minDate AndMaxDate:(long) maxDate AndDates:(CPTNumericData *)epochdates AndData: (CPTNumericData *)dataSeries AndPassFilter:(NSUInteger) passfilter
//{
//    self.xData = epochdates;
//    self.yData = dataSeries;
//    self.count = length;
//    self.timeStep = passfilter;
//    self.minXdata = minDate;
//    self.maxXdata = maxDate;
//}

-(void)reduceDataSeriesToSampledSeconds: (int) numberOfSeconds
{
    NSNumber *datetime = [self.xData sampleValue:0];
    long currentSampleDateTime, currentDateTime;
    //double currentSampleValue;
    NSLog(@"First TimeDate:%lu",[datetime longValue]);
    long anchorDateTime = [EpochTime epochTimeAtZeroHour:[datetime longValue]];
    
    if(numberOfSeconds >= 2){
        //Using integer division to get a time that is an integer number of steps from 00:00
        currentSampleDateTime = anchorDateTime + numberOfSeconds * (([datetime longValue]-anchorDateTime)/numberOfSeconds);
        long sampleCount = 0;
        long index = 0;
        BOOL dataForInterval = NO;
        while(index < self.count)
        {
            currentDateTime = [[self.xData sampleValue:index] longValue];
            if(currentDateTime < currentSampleDateTime)
            {
                dataForInterval = YES;
            }else{
                if(dataForInterval == YES)
                {
                    if((currentDateTime == currentSampleDateTime) || (currentDateTime > currentSampleDateTime &     index > 0) ){
                        currentSampleDateTime = currentSampleDateTime + numberOfSeconds;
                        sampleCount = sampleCount + 1;
                        dataForInterval = NO;
                    }
                }else{
                    while(currentSampleDateTime < currentDateTime){
                        currentSampleDateTime = currentSampleDateTime + numberOfSeconds;
                    }
                    dataForInterval = YES;
                }
            }
            index++;
        }
    
        NSMutableData *newXData = [NSMutableData dataWithLength:sampleCount * sizeof(long)];
        long *newXLongs = [newXData mutableBytes];
        NSUInteger numberOfFields = [self.yData count];
        double **newYDoubles = malloc([self.yData count] * sizeof(double*));
        NSArray *fieldnames = [[NSArray alloc] initWithArray:[self.yData allKeys]];
        // Put all the Y values into a temp dictionary
        NSMutableDictionary  * newYDataTemp = [[NSMutableDictionary alloc] init ];
        for(NSUInteger i = 0; i < numberOfFields;i++)
        {
            NSMutableData *newYField = [NSMutableData dataWithLength:sampleCount * sizeof(double)];
            newYDoubles[i] = [newYField mutableBytes]; 
            [newYDataTemp setObject:newYField forKey:[fieldnames objectAtIndex:i]];
        }
    
        CPTNumericData *oldYData;
        CPTNumericData *newYData;
        currentSampleDateTime = anchorDateTime + numberOfSeconds * (([datetime longValue]-anchorDateTime)/numberOfSeconds);
        sampleCount = 0;
        index = 0;
        dataForInterval = NO;
        while(index < self.count)
        {
            currentDateTime = [[self.xData sampleValue:index] longValue];
            if(currentDateTime < currentSampleDateTime)
            {
                dataForInterval = YES;
            }else{    
                if(dataForInterval == YES)
                {
                    if(currentDateTime == currentSampleDateTime){
                        newXLongs[sampleCount] = currentSampleDateTime;
                        for(NSUInteger i = 0; i < numberOfFields;i++)
                        {
                            oldYData = [self.yData objectForKey:[fieldnames objectAtIndex:i]];
                            newYDoubles[i][sampleCount] = [[oldYData  sampleValue:index] doubleValue];
                        }
                        currentSampleDateTime = currentSampleDateTime + numberOfSeconds;
                        sampleCount = sampleCount + 1;
                        dataForInterval = NO;
                    }
                    if(currentDateTime > currentSampleDateTime & index > 0){
                        newXLongs[sampleCount] = currentSampleDateTime;
                        for(NSUInteger i = 0; i < numberOfFields;i++)
                        {
                            oldYData = [self.yData objectForKey:[fieldnames objectAtIndex:i]];
                            newYDoubles[i][sampleCount] = [[oldYData  sampleValue:(index-1)] doubleValue];
                        }
                        currentSampleDateTime = currentSampleDateTime + numberOfSeconds;
                        sampleCount = sampleCount + 1;
                        dataForInterval = NO;
                    }
                }else{
                    while(currentSampleDateTime < currentDateTime){
                        currentSampleDateTime = currentSampleDateTime + numberOfSeconds;
                    }
                    dataForInterval = YES;
                }
            }
            index++;
        }
        self.xData = [CPTNumericData numericDataWithData:newXData 
                                            dataType:CPTDataType(CPTIntegerDataType, 
                                                                            sizeof(long), 
                                                                             CFByteOrderGetCurrent()) 
                                               shape:nil];
        
        //Need to get the new Y data out of the dictionary and into a CPTNumericData object
        // These then are put into a dictionary at yData
        self.yData = [[NSMutableDictionary alloc] init];
        for(NSUInteger i = 0; i < numberOfFields;i++)
        {
            newYData = [CPTNumericData 
                        numericDataWithData:[newYDataTemp objectForKey:[fieldnames objectAtIndex:i]] 
                            dataType:CPTDataType(CPTFloatingPointDataType, 
                                                 sizeof(double), 
                                                 CFByteOrderGetCurrent())
                        shape:nil];
            
            [self.yData setObject:newYData forKey:[fieldnames objectAtIndex:i]];
        }        
//        self.yData = [CPTNumericData numericDataWithData:newYData 
//                                            dataType:CPTDataType(CPTFloatingPointDataType, 
//                                                                             sizeof(double), 
//                                                                             CFByteOrderGetCurrent()) 
//                                                shape:nil]; 
        
        self.count = sampleCount;
        [self setForPlotStartIndex: 0 AndCount:sampleCount];
        self.timeStep = numberOfSeconds;
    }
}

//Return -1 on out of bounds error
-(long)nearestXBelowOrEqualTo: (long) xValue;
{
    long newBound;
    double step;
    long lBound, uBound;
    long valueAtLBound, valueAtUBound;
    int iters = 0;
    lBound = 0;
    uBound = (self.count-1);
    valueAtLBound = [[self.xData sampleValue:lBound] longValue];
    valueAtUBound = [[self.xData sampleValue:uBound] longValue];
    
    if(xValue < valueAtLBound)
    {
        return 1;
    }
    if(xValue > valueAtUBound)
    {
        return uBound;
    }
    
    while((uBound-lBound)>1){
        iters = iters + 1;
        NSLog(@"Iteration %d  %ld  to %ld",iters,lBound,uBound);
        step = (((double)xValue - valueAtLBound)/(valueAtUBound - valueAtLBound));
        newBound = lBound + (long)(step*(uBound-lBound));
        
        if(newBound == lBound){
            if([[self.xData sampleValue:(lBound+1)] longValue] > xValue)
            {
                NSLog(@"1.UB is  %ld",[[self.xData sampleValue:uBound] longValue]);
                NSLog(@"1.Returning with %ld",[[self.xData sampleValue:lBound] longValue]);
                return lBound;
            }else{
                newBound = lBound + 1;
            }
        }
        if(newBound >= uBound){
            if(newBound > uBound){
                newBound = uBound; 
            }
            if(newBound == uBound){
                if([[self.xData sampleValue:(uBound-1)] longValue] <= xValue){
                    NSLog(@"2.UB is  %ld",[[self.xData sampleValue:uBound] longValue]);
                    NSLog(@"2.Returning with %ld",[[self.xData sampleValue:(uBound -1)] longValue]);
                    return (uBound -1);
                }else{
                    newBound = uBound -1;
                }
            }
        }
        if([[self.xData sampleValue:newBound] longValue]>xValue){
            uBound = newBound;
            valueAtUBound = [[self.xData sampleValue:uBound] longValue];
        }else{
            lBound = newBound;
            if([[self.xData sampleValue:(lBound+1)] longValue] > xValue){
                NSLog(@"3.UB is  %ld",[[self.xData sampleValue:(lBound+1)] longValue]);
                NSLog(@"3.Returning with lb %ld",[[self.xData sampleValue:lBound] longValue]);
                return lBound;
            }
            valueAtLBound = [[self.xData sampleValue:lBound] longValue];
        }
        
    }
    NSLog(@"4.UB is  %ld",[[self.xData sampleValue:uBound] longValue]);
    NSLog(@"4.Returning with %ld",[[self.xData sampleValue:lBound] longValue]);
    return lBound;
}


-(BOOL)setPlottingSubsetFromStartIndex: (long) startIndex ToEndIndex: (long) endIndex
{
    BOOL isOk = YES;
    NSNumber *minY, *maxY;
    NSArray *fieldnames;
   
    if(startIndex >=0 &&  endIndex < self.count)
    {
        [self setForPlotStartIndex:startIndex AndCount:(endIndex - startIndex + 1)];
    }else{
        isOk = NO;
    }

    
    //Figure out the minimums and maximums
    fieldnames = [self.yData allKeys];
    CPTNumericData *dataSeries;
    for (NSString *fieldname in fieldnames) {
        dataSeries = [self.yData objectForKey:fieldname];
        minY = [dataSeries sampleValue:startIndex];
        maxY = [dataSeries sampleValue:startIndex];        
        for(long i = (startIndex+1); i <= endIndex; i++){
            if([[dataSeries sampleValue:i] isLessThan:minY])
            {
                minY = [NSNumber numberWithDouble:[[dataSeries sampleValue:i] doubleValue]];
            }
            if([[dataSeries sampleValue:i] isGreaterThan:maxY])
            {
                maxY = [NSNumber numberWithDouble:[[dataSeries sampleValue:i] doubleValue]];
            }
        }
        [self.minYdataForPlot setValue:minY forKey:fieldname];
        [self.maxYdataForPlot setValue:maxY forKey:fieldname];
    }
    
    return isOk;
}

#pragma mark - 
#pragma mark Accessors 
@synthesize count;
//@synthesize countForPlot; 
//@synthesize startIndexForPlot;
@synthesize xData; 
@synthesize yData; 
@synthesize idtag;
@synthesize name;
@synthesize timeStep;
@synthesize minXdata;
@synthesize maxXdata;
//@synthesize minXdataForPlot;
//@synthesize maxXdataForPlot;
@synthesize minYdataForPlot;
@synthesize maxYdataForPlot;
@synthesize pipSize;


#pragma mark -
#pragma mark Plot Data Source Methods

-(NSUInteger)numberOfRecordsForPlot:(CPTPlot *)plot
{
	return [self countForPlot];
}

- (CPTNumericData *)dataForPlot:(CPTPlot  *)plot 
                          field:(NSUInteger)field 
               recordIndexRange:(NSRange   )indexRange 
{ 
    CPTNumericData *dataToReturn; 
    NSRange range = {self.startIndexForPlot, self.countForPlot};
    switch (field)
    {
        case CPTScatterPlotFieldX: 
        {
            dataToReturn = self.xData; 
            //return dataToReturn;
            break;
        }
        case CPTScatterPlotFieldY:
        {
            dataToReturn = [self.yData objectForKey:plot.identifier]; 
            //return dataToReturn;
            break;
        }
    }
    if (NSEqualRanges(range, NSMakeRange(0, self.count))) 
    { 
        return dataToReturn; 
    } 
    else 
    { 
        CPTNumericDataType dataType = dataToReturn.dataType; 
        NSRange            subRange = NSMakeRange(range.location * dataType.sampleBytes, 
                                                  range.length   * dataType.sampleBytes); 
        return [CPTNumericData numericDataWithData:[dataToReturn.data subdataWithRange:subRange] 
                                          dataType:dataType 
                                             shape:nil]; 
    } 
    return nil;
}

@end 


