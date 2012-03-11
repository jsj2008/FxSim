//
//  DataSeries.m
//  Simple Sim
//
//  Created by Martin O'Connor on 06/01/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "DataSeries.h"
#import "EpochTime.h"
#import "DataView.h"



#pragma mark - 
#pragma mark Implementation 
@implementation DataSeries 

//-(id)init
//{
//    return [self initWithName:@"" AndDbTag:0];
//}
//
//-(id)initWithName:(NSString *)seriesName
//{
//    return [self initWithName:seriesName AndDbTag:0];
//}


- (id)initWithName:(NSString *)seriesName AndDbTag:(NSUInteger) databaseId AndPipSize:(double) quotePipSize;
{
    self = [super init];
    if(self){
        self.name = [NSString stringWithString:seriesName];
        self.dbId = databaseId;
        self.pipSize = quotePipSize;
        self.xData = nil; 
        self.yData = nil; //[[NSMutableDictionary alloc] init]; 
        self.dataViews = [[NSMutableDictionary alloc] init];
        self.sampleRate = 0;
    }    
    return self;    
}

-(long)minDateTime
{
    return [[[self xData] sampleValue:0] longValue];
}

-(long)maxDateTime
{
    long indexForLastData;
    indexForLastData = [[self xData] length]/[[self xData] sampleBytes];
    indexForLastData = indexForLastData-1;
    return [[[self xData] sampleValue:indexForLastData] longValue];
}

-(NSUInteger)length
{
    if(self.xData != nil)
    {
        return [[self xData] length]/[[self xData] sampleBytes];
    }
    return 0;
}

-(void)setDataSeriesWithFieldName:(NSString*)fieldName AndDates:(CPTNumericData *)epochdates AndData: (CPTNumericData *)dataSeries 
{
    self.xData = epochdates;
    self.yData =  [[NSMutableDictionary alloc] init];
    [self.yData setObject:dataSeries forKey:fieldName] ;
    [self setSampleRate:1];
}

-(DataSeries *) getCopyOfStaticData
{
    DataSeries *returnData  = [[DataSeries alloc] initWithName:[self name] 
                                                      AndDbTag:[self dbId] 
                                                    AndPipSize:[self pipSize]];
    return returnData;
}



-(DataSeries *) sampleDataAtInterval: (int) numberOfSeconds
{
    DataSeries *returnData  = [[DataSeries alloc] initWithName:[self name] 
                                                      AndDbTag:[self dbId] 
                                                    AndPipSize:[self pipSize]];
    long currentSampleDateTime, currentDateTime;
    NSNumber *datetime = [NSNumber numberWithLong:[[self.xData sampleValue:0] longValue]];
    long anchorDateTime;
    NSUInteger originalNumberOfData;
    originalNumberOfData = [self length];
    anchorDateTime = [EpochTime epochTimeAtZeroHour:[datetime longValue]];
    
    //NSLog(@"First TimeDate:%lu",[datetime longValue]);
    
    NSArray *fieldnames = [[NSArray alloc] initWithArray:[self.yData allKeys] copyItems:YES];
    NSUInteger numberOfFields = [[self yData] count];
    double *intermediateValues;
    long *intermediateDateTimes;
    intermediateDateTimes = malloc(originalNumberOfData *sizeof(long));
    intermediateValues = malloc(originalNumberOfData * numberOfFields *sizeof(double));
    
    CPTNumericData *yDataFields[numberOfFields];
    int fieldIndex;
    for( fieldIndex= 0; fieldIndex < numberOfFields; fieldIndex++){
        yDataFields[fieldIndex] = [self.yData objectForKey:[fieldnames objectAtIndex:fieldIndex]];
    }
    
    double minYvalues[numberOfFields];
    double maxYvalues[numberOfFields];
        
    if(numberOfSeconds >= 2){
        currentSampleDateTime = anchorDateTime + numberOfSeconds * (([datetime longValue]-anchorDateTime)/numberOfSeconds);
        long sampleCount = 0;
        long index = 0;
        BOOL dataForInterval = NO;
        while(index < originalNumberOfData)
        {
            currentDateTime = [[self.xData sampleValue:index] longValue];
            if(currentDateTime < currentSampleDateTime)
            {
                dataForInterval = YES;
            }else{
                if(dataForInterval == YES)
                {
                    if(currentDateTime == currentSampleDateTime){
                        intermediateDateTimes[sampleCount] = currentSampleDateTime;
                        for( fieldIndex= 0; fieldIndex < numberOfFields; fieldIndex++)
                        {
                            intermediateValues[(sampleCount*numberOfFields)+fieldIndex] = [[yDataFields[fieldIndex] sampleValue:index] doubleValue];
                        }
                        currentSampleDateTime = currentSampleDateTime + numberOfSeconds;
                        sampleCount = sampleCount + 1;
                        dataForInterval = NO;
                    }
                    if((currentDateTime > currentSampleDateTime)  & (index > 0)){
                        intermediateDateTimes[sampleCount] = currentSampleDateTime;
                        for(fieldIndex= 0; fieldIndex < numberOfFields; fieldIndex++)
                        {
                            intermediateValues[(sampleCount*numberOfFields)+fieldIndex] = [[yDataFields[fieldIndex] sampleValue:(index-1)] doubleValue];
                        }
                        currentSampleDateTime = currentSampleDateTime + numberOfSeconds;
                        sampleCount = sampleCount + 1;
                        dataForInterval = NO;
                    }
                }else{
                    // The new date is greater than the current sample date, so we have to bring the sample date up
                    // at least this date, and so we can set dataForInterval to true
                    dataForInterval = YES;
                    while(currentSampleDateTime < currentDateTime){
                        currentSampleDateTime = currentSampleDateTime + numberOfSeconds;
                    }
                    
                }
            }
            index++;
        }
        // Now reduce the arrays by copying into smaller ones
        NSMutableData *newXData = [[NSMutableData alloc] initWithLength:sampleCount * sizeof(long)]; 
        long *sampledDateTimes = [newXData mutableBytes];
        NSMutableDictionary *newYData = [[NSMutableDictionary alloc] initWithCapacity:numberOfFields];
        double **sampledValues = malloc(numberOfFields * sizeof(double*));
        for(fieldIndex = 0; fieldIndex < numberOfFields; fieldIndex++){
            [newYData setObject:[[NSMutableData alloc] initWithLength:sampleCount * sizeof(double)] forKey:[fieldnames objectAtIndex:fieldIndex]];
            sampledValues[fieldIndex] = [[newYData objectForKey:[fieldnames objectAtIndex:fieldIndex]] mutableBytes];
        }
       
        for(fieldIndex = 0;fieldIndex < numberOfFields; fieldIndex++){
            minYvalues[fieldIndex] = intermediateValues[fieldIndex];
            maxYvalues[fieldIndex] = intermediateValues[fieldIndex];
        }
        for(index = 0; index < sampleCount; index++)
        {
            sampledDateTimes[index] = intermediateDateTimes[index];
            for(fieldIndex = 0;fieldIndex < numberOfFields; fieldIndex++){
                sampledValues[fieldIndex][index] = intermediateValues[(index * numberOfFields) + fieldIndex];
                minYvalues[fieldIndex] = fmin(minYvalues[fieldIndex],intermediateValues[(index * numberOfFields) + fieldIndex]);
                maxYvalues[fieldIndex] = fmax(maxYvalues[fieldIndex],intermediateValues[(index * numberOfFields) + fieldIndex]);
            }
        }
        [returnData setXData:[CPTNumericData numericDataWithData:newXData 
                                                        dataType:CPTDataType(CPTIntegerDataType, 
                                                                             sizeof(long), 
                                                                             CFByteOrderGetCurrent()) 
                                                           shape:nil]]; 
        NSMutableDictionary *newYDataDictionary = [[NSMutableDictionary alloc] init];
        for(fieldIndex = 0;fieldIndex < numberOfFields; fieldIndex++){
            [newYDataDictionary setObject:[CPTNumericData numericDataWithData:[newYData objectForKey:[fieldnames objectAtIndex:fieldIndex]]
                                                                      dataType:CPTDataType(CPTFloatingPointDataType, 
                                                                                           sizeof(double), 
                                                                                           CFByteOrderGetCurrent()) 
                                                                         shape:nil]
                                    forKey:[fieldnames objectAtIndex:fieldIndex]];
        }
        [returnData setYData:newYDataDictionary];
        NSMutableDictionary *minYDataDictionary = [[NSMutableDictionary alloc] init];
        NSMutableDictionary *maxYDataDictionary = [[NSMutableDictionary alloc] init];
        for(fieldIndex = 0;fieldIndex < numberOfFields; fieldIndex++){
            [minYDataDictionary setObject:[NSNumber numberWithDouble:minYvalues[fieldIndex]] 
                                   forKey:[fieldnames objectAtIndex:fieldIndex]];
            [maxYDataDictionary setObject:[NSNumber numberWithDouble:maxYvalues[fieldIndex]] 
                                    forKey:[fieldnames objectAtIndex:fieldIndex]];
        }
        [[returnData dataViews] removeAllObjects];
        [returnData setPlotViewWithName:@"ALL" AndStartDateTime:sampledDateTimes[0] AndEndDateTime:sampledDateTimes[sampleCount-1]];
        
        [returnData setSampleRate:numberOfSeconds];
    }
    return returnData;
}




-(void)reduceDataSeriesToSampledSeconds: (int) numberOfSeconds
{
    NSNumber *datetime = [self.xData sampleValue:0];
    long currentSampleDateTime, currentDateTime;
    NSLog(@"First TimeDate:%lu",[datetime longValue]);
    long anchorDateTime = [EpochTime epochTimeAtZeroHour:[datetime longValue]];
    NSUInteger originalNumberOfData;
    originalNumberOfData = [self length];
    
    if(numberOfSeconds >= 2){
        //Using integer division to get a time that is an integer number of steps from 00:00
        currentSampleDateTime = anchorDateTime + numberOfSeconds * (([datetime longValue]-anchorDateTime)/numberOfSeconds);
        long sampleCount = 0;
        long index = 0;
        BOOL dataForInterval = NO;
        while(index < originalNumberOfData)
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
        while(index < originalNumberOfData)
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
        
        [self setSampleRate:numberOfSeconds];
    }
}


-(NSDictionary *)getValues:(NSArray *) fieldNames AtDateTime: (long) dateTime
{
    NSMutableDictionary *returnValues = [[NSMutableDictionary alloc] init];
    long dateTimeIndex;
    
    if((dateTime >= [self minDateTime]) & (dateTime <= [self maxDateTime]))
    {
        //First find the index value
        dateTimeIndex = [self latestDateTimeBeforeOrEqualTo:dateTime];
    
        NSNumber *newDateTime = [NSNumber numberWithLong:[[[self xData] sampleValue:dateTimeIndex] longValue]];
        [returnValues setObject:newDateTime forKey:@"DATETIME"];
    
        for(int i=0; i < [fieldNames count]; i++)
        {
            CPTNumericData *data = [[self yData] objectForKey:[fieldNames objectAtIndex:i]];
            NSNumber *newDataValue = [NSNumber numberWithDouble:[[data sampleValue:dateTimeIndex] doubleValue]];
            [returnValues setObject:newDataValue forKey:[fieldNames objectAtIndex:i]];
        }
        [returnValues setObject:[NSNumber numberWithBool:YES] forKey:@"SUCCESS"];
    }else{
        [returnValues setObject:[NSNumber numberWithBool:NO] forKey:@"SUCCESS"];
    }
    return returnValues;    
}



//Return -1 on out of bounds error
-(long)latestDateTimeBeforeOrEqualTo: (long) dateTime;
{
    long newBound;
    double step;
    long lBound, uBound;
    long valueAtLBound, valueAtUBound;
    int iters = 0;
    long *xDataLongs;
    lBound = 0;
    uBound = [self length]-1;
    xDataLongs = (long *)[self.xData bytes];
    valueAtLBound = xDataLongs[lBound];
    valueAtUBound = xDataLongs[uBound];
    
    if(dateTime <= valueAtLBound)
    {
        return 0;
    }
    if(dateTime >= valueAtUBound)
    {
        return uBound;
    }
    
    while((uBound-lBound)>1){
        iters = iters + 1;
        //NSLog(@"Iteration %d  %ld  to %ld",iters,lBound,uBound);
        step = (((double)dateTime - valueAtLBound)/(valueAtUBound - valueAtLBound));
        newBound = lBound + (long)(step*(uBound-lBound));
        
        if(newBound == lBound){
            if(xDataLongs[lBound+1] > dateTime)
            {
                //NSLog(@"1.UB is  %ld",[[self.xData sampleValue:uBound] longValue]);
                //NSLog(@"1.Returning with %ld",[[self.xData sampleValue:lBound] longValue]);
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
                //We know that xValue is less than value at the upper bound
                //so if it above the datum below it, that is our answer 
                if(dateTime >= xDataLongs[uBound-1]){
                    //NSLog(@"2.UB is  %ld",[[self.xData sampleValue:uBound] longValue]);
                    ///NSLog(@"2.Returning with %ld",[[self.xData sampleValue:(uBound -1)] longValue]);
                    return (uBound -1);
                }else{
                    newBound = uBound -1;
                }
            }
        }
        if(dateTime < xDataLongs[newBound]){
            uBound = newBound;
            valueAtUBound = xDataLongs[uBound];
        }else{
            lBound = newBound;
            if(xDataLongs[lBound+1]> dateTime){
                //NSLog(@"3.UB is  %ld",[[self.xData sampleValue:(lBound+1)] longValue]);
                //NSLog(@"3.Returning with lb %ld",[[self.xData sampleValue:lBound] longValue]);
                return lBound;
            }
            valueAtLBound = xDataLongs[lBound];
        }
        
    }
    //NSLog(@"4.UB is  %ld",[[self.xData sampleValue:uBound] longValue]);
    //NSLog(@"4.Returning with %ld",[[self.xData sampleValue:lBound] longValue]);
    return lBound;
}


-(void)setPlotViewWithName: (NSString *) plotViewName AndStartDateTime: (long) startDateTime AndEndDateTime: (long) endDateTime
{
    long startIndex, endIndex;
    double minY, maxY;
    NSArray *fieldnames;
    DataView *dataView; 
    NSMutableDictionary *mins = [[NSMutableDictionary alloc] init];
    NSMutableDictionary *maxs = [[NSMutableDictionary alloc] init];
    
    
    startIndex = [self latestDateTimeBeforeOrEqualTo: startDateTime];
    endIndex = [self latestDateTimeBeforeOrEqualTo:endDateTime];
    
    //Figure out the minimums and maximums
    fieldnames = [self.yData allKeys];
    CPTNumericData *dataSeries;
    double *yDataArray;
    for (NSString *fieldname in fieldnames) {
        dataSeries = [self.yData objectForKey:fieldname];
//        minY = [dataSeries sampleValue:startIndex];
//        maxY = [dataSeries sampleValue:startIndex];  
        
        yDataArray = (double *)[dataSeries bytes];
        minY = yDataArray[startIndex];
        maxY = yDataArray[startIndex];
        for(long i = (startIndex+1); i <= endIndex; i++){
            if(yDataArray[i] < minY)
            {
                minY = yDataArray[i];
            }
            if(yDataArray[i] > maxY)
            {
                maxY = yDataArray[i];
            }
        }
        
//        for(long i = (startIndex+1); i <= endIndex; i++){
//            if([[dataSeries sampleValue:i] isLessThan:minY])
//            {
//                minY = [NSNumber numberWithDouble:[[dataSeries sampleValue:i] doubleValue]];
//            }
//            if([[dataSeries sampleValue:i] isGreaterThan:maxY])
//            {
//                maxY = [NSNumber numberWithDouble:[[dataSeries sampleValue:i] doubleValue]];
//            }
//        }
        [mins setValue:[NSNumber numberWithDouble:minY] forKey:fieldname];
        [maxs setValue:[NSNumber numberWithDouble:maxY] forKey:fieldname];
    }
    dataView = [[DataView alloc] initWithDataSeries:self 
                                            AndName:plotViewName
                                      AndStartIndex: startIndex 
                                        AndEndIndex: endIndex 
                                            AndMins: mins 
                                            AndMaxs: maxs];
    [[self dataViews] setObject:dataView forKey: plotViewName];
}

-(NSArray *)getFieldNames
{
    NSArray *fieldNames;
    if(self.yData != nil)
    {
        fieldNames = [self.yData allKeys]; 
    }
    return fieldNames;
}

#pragma mark - 
#pragma mark Accessors 
@synthesize xData; 
@synthesize yData; 
@synthesize dbId;
@synthesize name;
@synthesize dataViews;
@synthesize pipSize;
@synthesize sampleRate;


@end 


