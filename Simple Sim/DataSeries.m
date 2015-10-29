//
//  DataSeries.m
//  Simple Sim
//
//  Created by Martin O'Connor on 06/01/2012.
//  Copyright (c) 2015 MARTIN OCONNOR. All rights reserved.
//

#import "DataSeries.h"
#import "EpochTime.h"
#import "DataView.h"

#pragma mark - 
#pragma mark Implementation 
@implementation DataSeries 


- (id)init
{
    NSLog(@"Tried to initialise a dataseries without instance variables, returning nil");
    return nil;    
}

- (id)  initWithName: (NSString *)seriesName 
            AndDbTag: (NSUInteger) databaseId 
          AndPipSize: (double) quotePipSize 
{
    self = [super init];
    if(self){
        _name = [NSString stringWithString:seriesName];
        _databaseId = databaseId;
        _pipSize = quotePipSize;
        _xData = nil; 
        _yData = [[NSMutableDictionary alloc] init]; 
        _dataViews = [[NSMutableDictionary alloc] init];
        _dataRate = 0;
    }    
    return self;    
}

- (NSString *)description
{
    NSString *description;
    description = [NSString stringWithFormat:@"%@\n", [self name]]; 
    description = [NSString stringWithFormat:@"%@Start   :%@\n",description, [EpochTime stringDateWithTime:[self minDateTime]]];
    description = [NSString stringWithFormat:@"%@End     :%@\n",description, [EpochTime stringDateWithTime:[self maxDateTime]]];
    description = [NSString stringWithFormat:@"%@Length  :%ld\n",description, [self length]];
    description = [NSString stringWithFormat:@"%@Sampling:%ld",description, [self dataRate]];
    return description;
}

-(void) encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:_name forKey:@"NAME"];
    [aCoder encodeObject:[NSNumber numberWithInteger:_databaseId] forKey:@"DATABASEID"];
    [aCoder encodeObject:[NSNumber numberWithDouble:_pipSize] forKey:@"PIPSIZE"];
    [aCoder encodeObject:_xData forKey:@"XDATA"];
    [aCoder encodeObject:_yData forKey:@"YDATA"];
    [aCoder encodeObject:_dataViews forKey:@"DATAVIEWS"];
    [aCoder encodeObject:[NSNumber numberWithInteger:_dataRate] forKey:@"SAMPLERATE"];
 }

- (id) initWithCoder:(NSCoder *)aDecoder
{
    if (self = [super init]) {
        // If parent class also adopts NSCoding, replace [super init]
        // with [super initWithCoder:decoder] to properly initialize.
        
        // NOTE: Decoded objects are auto-released and must be retained
        _name = [aDecoder decodeObjectForKey:@"NAME"];
        _databaseId = [[aDecoder decodeObjectForKey:@"DATABASEID"] intValue];
        _pipSize = [[aDecoder decodeObjectForKey:@"PIPSIZE"] doubleValue];
        _xData = [aDecoder decodeObjectForKey:@"XDATA"];
        _yData = [aDecoder decodeObjectForKey:@"YDATA"]; 
        _dataViews = [aDecoder decodeObjectForKey:@"DATAVIEWS"];
        _dataRate = [[aDecoder decodeObjectForKey:@"SAMPLERATE"] intValue];
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


-(DataSeries *) getCopyOfStaticData
{
    DataSeries *returnData  = [[DataSeries alloc] initWithName:[self name] 
                                                      AndDbTag:[self dbId] 
                                                    AndPipSize:[self pipSize]];
    return returnData;
}

-(BOOL)writeDataSeriesToFile: (NSURL *) fileNameAndPath
{
    BOOL allOk = YES;
    NSArray *fieldNames = [[self yData] allKeys]; 
    NSFileHandle *outFile;
    
    // Create the output file first if necessary
    // Need to remove file: //localhost for some reason
    NSString *filePathString = [fileNameAndPath path];//[[fileNameAndPath absoluteString] substringFromIndex:16];
    allOk = [[NSFileManager defaultManager] createFileAtPath: filePathString
                                                    contents: nil 
                                                  attributes: nil];
    //[fileNameAndPath absoluteString]
    if(allOk){
        outFile = [NSFileHandle fileHandleForWritingAtPath:filePathString];
        [outFile truncateFileAtOffset:0];
        NSString *lineOfDataAsString;
        long *xDataArray = (long *)[[self xData] bytes];
        double **yDataArray = malloc([[self yData] count] * sizeof(double*));
     
        lineOfDataAsString = @"EPOCHTIME, DATETIME"; 
        for(int i = 0;i < [fieldNames count] ; i++)
        {
            lineOfDataAsString = [lineOfDataAsString stringByAppendingFormat:@", %@",[fieldNames objectAtIndex:i]];
        }
        lineOfDataAsString = [lineOfDataAsString stringByAppendingFormat:@"\r\n"];
        [outFile writeData:[lineOfDataAsString dataUsingEncoding:NSUTF8StringEncoding]];
        
        for(int i = 0; i < [[self yData] count]; i++){
            yDataArray[i] = (double *)[[[self yData] objectForKey:[fieldNames objectAtIndex:i]] bytes];
        }
        
        for(int i = 0; i < [self length]; i ++){
            lineOfDataAsString = [NSString stringWithFormat:@"%ld,%@",xDataArray[i],[EpochTime stringDateWithTime:xDataArray[i]]];
            for(int j=0; j <[fieldNames count];j++){
                lineOfDataAsString = [lineOfDataAsString stringByAppendingFormat:@", %f",yDataArray[j][i]];  
            }
            lineOfDataAsString = [lineOfDataAsString stringByAppendingFormat:@"\r\n"];
            [outFile writeData:[lineOfDataAsString dataUsingEncoding:NSUTF8StringEncoding]];
        }
        [outFile closeFile];
        free(yDataArray);
    }
    return allOk;
}

-(BOOL)writeDataSeriesToFile: (NSURL *) fileNameAndPath
                ForStartTime: (long) startDateTime
                  AndEndTime: (long) endDateTime
{
    BOOL allOk = YES;
    NSArray *fieldNames = [[self yData] allKeys];
    NSFileHandle *outFile;
    
    
    // Create the output file first if necessary
    // Need to remove file: //localhost for some reason
    NSString *filePathString = [fileNameAndPath path];//[[fileNameAndPath absoluteString] substringFromIndex:16];
    allOk = [[NSFileManager defaultManager] createFileAtPath: filePathString
                                                    contents: nil
                                                  attributes: nil];
    //[fileNameAndPath absoluteString]
    if(allOk){
        outFile = [NSFileHandle fileHandleForWritingAtPath:filePathString];
        [outFile truncateFileAtOffset:0];
        NSString *lineOfDataAsString;
        long *xDataArray = (long *)[[self xData] bytes];
        double **yDataArray = malloc([[self yData] count] * sizeof(double*));
        
        lineOfDataAsString = @"EPOCHTIME, DATETIME";
        for(int i = 0;i < [fieldNames count] ; i++)
        {
            lineOfDataAsString = [lineOfDataAsString stringByAppendingFormat:@", %@",[fieldNames objectAtIndex:i]];
        }
        lineOfDataAsString = [lineOfDataAsString stringByAppendingFormat:@"\r\n"];
        [outFile writeData:[lineOfDataAsString dataUsingEncoding:NSUTF8StringEncoding]];
        
        for(int i = 0; i < [[self yData] count]; i++){
            yDataArray[i] = (double *)[[[self yData] objectForKey:[fieldNames objectAtIndex:i]] bytes];
        }
        
        for(int i = 0; i < [self length]; i ++){
            if(xDataArray[i] >= startDateTime && xDataArray[i] <= endDateTime){
                lineOfDataAsString = [NSString stringWithFormat:@"%ld,%@",xDataArray[i],[EpochTime stringDateWithTime:xDataArray[i]]];
                for(int j=0; j <[fieldNames count];j++){
                    lineOfDataAsString = [lineOfDataAsString stringByAppendingFormat:@", %f",yDataArray[j][i]];
                }
                lineOfDataAsString = [lineOfDataAsString stringByAppendingFormat:@"\r\n"];
                [outFile writeData:[lineOfDataAsString dataUsingEncoding:NSUTF8StringEncoding]];
            }
        }
        [outFile closeFile];
        free(yDataArray);
    }
    return allOk;
}





//-(DataSeries *) sampleDataAtInterval: (int) numberOfSeconds
//{
//    DataSeries *returnData  = [[DataSeries alloc] initWithName:[self name] 
//                                                      AndDbTag:[self dbId] 
//                                                    AndPipSize:[self pipSize]];
//    long currentSampleDateTime, currentDateTime;
//    NSNumber *datetime = [NSNumber numberWithLong:[[self.xData sampleValue:0] longValue]];
//    long anchorDateTime;
//    NSUInteger originalNumberOfData;
//    originalNumberOfData = [self length];
//    anchorDateTime = [EpochTime epochTimeAtZeroHour:[datetime longValue]];
//    
//    NSArray *fieldnames = [[NSArray alloc] initWithArray:[[self yData] allKeys] copyItems:YES];
//    NSUInteger numberOfFields = [[self yData] count];
//    NSMutableData *intermediateValueData;
//    double *intermediateValues;
//    NSMutableData *intermediateDateTimeData;
//    long *intermediateDateTimes;
//    
//    intermediateDateTimeData = [[NSMutableData alloc] initWithLength:originalNumberOfData *sizeof(long)];
//    intermediateDateTimes = (long *)[intermediateDateTimeData mutableBytes];
//    
//    intermediateValueData = [[NSMutableData alloc] initWithLength:originalNumberOfData *sizeof(double)];
//    intermediateValues = (double *)[intermediateValueData mutableBytes];
//    
//    CPTNumericData *yDataFields[numberOfFields];
//    int fieldIndex;
//    for( fieldIndex= 0; fieldIndex < numberOfFields; fieldIndex++){
//        yDataFields[fieldIndex] = [[self yData] objectForKey:[fieldnames objectAtIndex:fieldIndex]];
//    }
//    
//    double minYvalues[numberOfFields];
//    double maxYvalues[numberOfFields];
//        
//    if(numberOfSeconds >= 2){
//        currentSampleDateTime = anchorDateTime + numberOfSeconds * (([datetime longValue]-anchorDateTime)/numberOfSeconds);
//        long sampleCount = 0;
//        long index = 0;
//        BOOL dataForInterval = NO;
//        while(index < originalNumberOfData)
//        {
//            currentDateTime = [[self.xData sampleValue:index] longValue];
//            if(currentDateTime < currentSampleDateTime)
//            {
//                dataForInterval = YES;
//            }else{
//                if(dataForInterval == YES)
//                {
//                    if(currentDateTime == currentSampleDateTime){
//                        intermediateDateTimes[sampleCount] = currentSampleDateTime;
//                        for( fieldIndex= 0; fieldIndex < numberOfFields; fieldIndex++)
//                        {
//                            intermediateValues[(sampleCount*numberOfFields)+fieldIndex] = [[yDataFields[fieldIndex] sampleValue:index] doubleValue];
//                        }
//                        currentSampleDateTime = currentSampleDateTime + numberOfSeconds;
//                        sampleCount = sampleCount + 1;
//                        dataForInterval = NO;
//                    }
//                    if((currentDateTime > currentSampleDateTime)  & (index > 0)){
//                        intermediateDateTimes[sampleCount] = currentSampleDateTime;
//                        for(fieldIndex= 0; fieldIndex < numberOfFields; fieldIndex++)
//                        {
//                            intermediateValues[(sampleCount*numberOfFields)+fieldIndex] = [[yDataFields[fieldIndex] sampleValue:(index-1)] doubleValue];
//                        }
//                        currentSampleDateTime = currentSampleDateTime + numberOfSeconds;
//                        sampleCount = sampleCount + 1;
//                        dataForInterval = NO;
//                    }
//                }else{
//                    // The new date is greater than the current sample date, so we have to bring the sample date up
//                    // at least this date, and so we can set dataForInterval to true
//                    dataForInterval = YES;
//                    while(currentSampleDateTime < currentDateTime){
//                        currentSampleDateTime = currentSampleDateTime + numberOfSeconds;
//                    }
//                    
//                }
//            }
//            index++;
//        }
//        // Now reduce the arrays by copying into smaller ones
//        NSMutableData *newXData = [[NSMutableData alloc] initWithLength:sampleCount * sizeof(long)]; 
//        long *sampledDateTimes = [newXData mutableBytes];
//        NSMutableDictionary *newYData = [[NSMutableDictionary alloc] initWithCapacity:numberOfFields];
//        double **sampledValues = malloc(numberOfFields * sizeof(double*));
//        for(fieldIndex = 0; fieldIndex < numberOfFields; fieldIndex++){
//            [newYData setObject:[[NSMutableData alloc] initWithLength:sampleCount * sizeof(double)] forKey:[fieldnames objectAtIndex:fieldIndex]];
//            sampledValues[fieldIndex] = [[newYData objectForKey:[fieldnames objectAtIndex:fieldIndex]] mutableBytes];
//        }
//       
//        for(fieldIndex = 0;fieldIndex < numberOfFields; fieldIndex++){
//            minYvalues[fieldIndex] = intermediateValues[fieldIndex];
//            maxYvalues[fieldIndex] = intermediateValues[fieldIndex];
//        }
//        for(index = 0; index < sampleCount; index++)
//        {
//            sampledDateTimes[index] = intermediateDateTimes[index];
//            for(fieldIndex = 0;fieldIndex < numberOfFields; fieldIndex++){
//                sampledValues[fieldIndex][index] = intermediateValues[(index * numberOfFields) + fieldIndex];
//                minYvalues[fieldIndex] = fmin(minYvalues[fieldIndex],intermediateValues[(index * numberOfFields) + fieldIndex]);
//                maxYvalues[fieldIndex] = fmax(maxYvalues[fieldIndex],intermediateValues[(index * numberOfFields) + fieldIndex]);
//            }
//        }
//        free(sampledValues);
//        [returnData setXData:[CPTNumericData numericDataWithData:newXData 
//                                                        dataType:CPTDataType(CPTIntegerDataType, 
//                                                                             sizeof(long), 
//                                                                             CFByteOrderGetCurrent()) 
//                                                           shape:nil]]; 
//        [[returnData yData] removeAllObjects];
//        for(fieldIndex = 0;fieldIndex < numberOfFields; fieldIndex++){
//            [[returnData yData] setObject:[CPTNumericData numericDataWithData:[newYData objectForKey:[fieldnames objectAtIndex:fieldIndex]]
//                                                                      dataType:CPTDataType(CPTFloatingPointDataType, 
//                                                                                           sizeof(double), 
//                                                                                           CFByteOrderGetCurrent()) 
//                                                                         shape:nil]
//                                    forKey:[fieldnames objectAtIndex:fieldIndex]];
//        }
//        NSMutableDictionary *minYDataDictionary = [[NSMutableDictionary alloc] init];
//        NSMutableDictionary *maxYDataDictionary = [[NSMutableDictionary alloc] init];
//        for(fieldIndex = 0;fieldIndex < numberOfFields; fieldIndex++){
//            [minYDataDictionary setObject:[NSNumber numberWithDouble:minYvalues[fieldIndex]] 
//                                   forKey:[fieldnames objectAtIndex:fieldIndex]];
//            [maxYDataDictionary setObject:[NSNumber numberWithDouble:maxYvalues[fieldIndex]] 
//                                    forKey:[fieldnames objectAtIndex:fieldIndex]];
//        }
//        [[returnData dataViews] removeAllObjects];
//        [returnData setDataViewWithName:@"ALL"
//                       AndStartDateTime:sampledDateTimes[0]
//                         AndEndDateTime:sampledDateTimes[sampleCount-1]];
//        
//        [returnData setDataRate:numberOfSeconds];
//    }
//    return returnData;
//}

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
        NSUInteger numberOfFields = [[self yData] count];
        NSMutableData *newYDoublesData = [[NSMutableData alloc] initWithLength:[[self yData] count] * sizeof(double*)];
        double **newYDoubles = (double **)[newYDoublesData mutableBytes];
        NSArray *fieldnames = [[NSArray alloc] initWithArray:[[self yData] allKeys]];
        // Put all the Y values into a temp dictionary
        NSMutableDictionary  * newYDataTemp = [[NSMutableDictionary alloc] init ];
        for(NSUInteger i = 0; i < numberOfFields;i++)
        {
            NSMutableData *newYField = [NSMutableData dataWithLength:sampleCount * sizeof(double)];
            newYDoubles[i] = (double *)[newYField mutableBytes]; 
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
                            oldYData = [[self yData] objectForKey:[fieldnames objectAtIndex:i]];
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
                            oldYData = [[self yData] objectForKey:[fieldnames objectAtIndex:i]];
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
        [self setYData:[[NSMutableDictionary alloc] init]];
        for(NSUInteger i = 0; i < numberOfFields;i++)
        {
            newYData = [CPTNumericData 
                        numericDataWithData:[newYDataTemp objectForKey:[fieldnames objectAtIndex:i]] 
                            dataType:CPTDataType(CPTFloatingPointDataType, 
                                                 sizeof(double), 
                                                 CFByteOrderGetCurrent())
                        shape:nil];
            
            [[self yData] setObject:newYData forKey:[fieldnames objectAtIndex:i]];
        }        
        
        [self setDataRate:numberOfSeconds];
    }
}


-(NSDictionary *)getValues:(NSArray *) fieldNames 
                AtDateTime: (long) dateTime
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
        NSLog(@"Problem: datetime requested that is outside loaded data range! \n datetime %lu is not between %lu and %lu",dateTime,[self minDateTime],[self maxDateTime]);
    }
    return returnValues;    
}

-(NSDictionary *)getValues:(NSArray *) fieldNames 
                AtDateTime: (long) dateTime 
             WithTicOffset: (long) numberOfTics
{
    NSMutableDictionary *returnValues = [[NSMutableDictionary alloc] init];
    long dateTimeIndex, offsetTics;
    
    
    if((dateTime >= [self minDateTime]) & (dateTime <= [self maxDateTime]))
    {
        //First find the index value
        dateTimeIndex = [self latestDateTimeBeforeOrEqualTo:dateTime];
        if(dateTimeIndex < numberOfTics){
            offsetTics = dateTimeIndex;
            dateTimeIndex = 0; 
        }else{
            dateTimeIndex = dateTimeIndex - numberOfTics;
            offsetTics = numberOfTics;
        }
        [returnValues setObject:[NSNumber numberWithLong:offsetTics] forKey:@"TICOFFSET"];    
        
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
        NSLog(@"Problem: datetime requested that is outside loaded data range! \n datetime %lu is not between %lu and %lu",dateTime,[self minDateTime],[self maxDateTime]);
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
    return lBound;
}

-(long)earliestDateTimeAfterOrEqualTo: (long) dateTime;
{
    long uBound;
    long *xDataLongs = (long *)[self.xData bytes];
    long maxIndex = [self length];
    uBound = [self latestDateTimeBeforeOrEqualTo:dateTime];
    while(xDataLongs[uBound] < dateTime && uBound < maxIndex-1){
        uBound++;
    }
    return uBound;
}

-(NSDictionary *)setDataViewWithName: (NSString *) plotViewName
                    AndStartDateTime: (long) startDateTime
                      AndEndDateTime: (long) endDateTime
{
    long startIndex, endIndex;
    //double minY, maxY;
    NSArray *fieldnames;
    DataView *dataView; 
    NSMutableDictionary *mins = [[NSMutableDictionary alloc] init];
    NSMutableDictionary *maxs = [[NSMutableDictionary alloc] init];
    
    startIndex = [self latestDateTimeBeforeOrEqualTo: startDateTime];
    endIndex = [self earliestDateTimeAfterOrEqualTo:endDateTime];
    
    //Figure out the minimums and maximums
    fieldnames = [[self yData] allKeys];
    CPTNumericData *dataSeries;
    
    NSMutableData *minsData = [[NSMutableData alloc] initWithLength:[fieldnames count]*sizeof(double)];
    NSMutableData *maxsData = [[NSMutableData alloc] initWithLength:[fieldnames count]*sizeof(double)];
    double *minsArray = [minsData mutableBytes];
    double *maxsArray = [maxsData mutableBytes];
    NSMutableData *dataPointersData = [[NSMutableData alloc] initWithLength:[fieldnames count]*sizeof(double*)];
    double **dataPointersArray = [dataPointersData mutableBytes];
    
    //double *yDataArray;
    NSString *fieldname;
    for (int i = 0;i < [fieldnames count];i++) {
        fieldname = [fieldnames objectAtIndex:i];
        dataSeries = [[self yData] objectForKey:fieldname];
        dataPointersArray[i] = (double *)[dataSeries bytes];
        dataPointersArray[i] = &(dataPointersArray[i][startIndex]);
        minsArray[i] = *dataPointersArray[i];
        maxsArray[i] = *dataPointersArray[i];
    }
    
    for(long j = (startIndex+1); j <= endIndex; j++){
        for (int k = 0;k < [fieldnames count];k++) {
            if(*dataPointersArray[k] < minsArray[k])
            {
                minsArray[k] = *dataPointersArray[k];
            }
            if(*dataPointersArray[k] > maxsArray[k])
            {
                maxsArray[k] = *dataPointersArray[k];
            }
            dataPointersArray[k]++;
        }
        
        
    }
    for (int i = 0;i < [fieldnames count];i++) {
        fieldname = [fieldnames objectAtIndex:i];
        [mins setValue:[NSNumber numberWithDouble:minsArray[i]] forKey:fieldname];
        [maxs setValue:[NSNumber numberWithDouble:maxsArray[i]] forKey:fieldname];
    }

    dataView = [[DataView alloc] initWithDataSeries: self 
                                            AndName: plotViewName
                                      AndStartIndex: startIndex 
                                        AndEndIndex: endIndex 
                                            AndMins: mins 
                                            AndMaxs: maxs];
    [[self dataViews] setObject: dataView
                         forKey: plotViewName];
    
    NSDictionary *minMaxArray = [[NSDictionary alloc] initWithObjects:[[NSArray alloc] initWithObjects:[NSNumber numberWithLong:[dataView minDateTime]],[NSNumber numberWithLong:[dataView maxDateTime]], nil] forKeys:[[NSArray alloc] initWithObjects:@"MIN",@"MAX", nil]];
    
    
    return minMaxArray;
}

-(NSArray *)getFieldNames
{
    NSArray *fieldNames;
    if([self yData]!= nil)
    {
        fieldNames = [[self yData] allKeys];
    }
    return fieldNames;
}

- (NSNumber *)getDateTimeAtIndex: (long) dataIndex{
    
    return [[self xData] sampleValue:dataIndex];
}

- (NSNumber *) getDataFor:(NSString *) dataField 
              AtIndex: (long) dataIndex{
    if([[self yData] objectForKey:dataField]){
        CPTNumericData *data = [[self yData] objectForKey:dataField];
        return [data sampleValue:dataIndex];
    }
    return nil;
}

-(DataView *) getDataViewForKey: (NSString *) viewName
{
    return [[self dataViews] objectForKey:viewName];
}

- (NSArray *) timeSeriesLines
{
    return Nil;
}

#pragma mark - 
#pragma mark Accessors 
@synthesize xData = _xData; 
@synthesize yData = _yData; 
@synthesize dbId = _databaseId;
@synthesize name = _name;
@synthesize dataViews = _dataViews;
@synthesize pipSize = _pipSize;
//@synthesize sampleRate = _sampleRate;
@end 


