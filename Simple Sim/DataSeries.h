//
//  DataSeries.h
//  Simple Sim
//
//  Created by Martin O'Connor on 06/01/2012.
//  Copyright (c) 2015 MARTIN OCONNOR. All rights reserved.
//

#import <Foundation/Foundation.h> 
#import <corePlot/corePlot.h> 
//#import "SeriesPlotData.h"

@class DataView;

@interface DataSeries: NSObject<NSCoding>{
    NSString *_name;
    NSUInteger _databaseId;
    double _pipSize;
    CPTNumericData *_xData; 
    NSMutableDictionary *_yData; 
    NSMutableDictionary *_dataViews;
    
}

@property (retain) NSString *name;
@property  NSUInteger dbId;
@property  double pipSize; 
@property (nonatomic, retain) CPTNumericData *xData;
@property (atomic, retain) NSMutableDictionary *yData;
@property (atomic, retain) NSMutableDictionary *dataViews;
@property  long dataRate;
 


- (id)init;

- (id)  initWithName: (NSString *)seriesName 
            AndDbTag: (NSUInteger) databaseId 
          AndPipSize: (double) quotePipSize; 

- (void) encodeWithCoder:(NSCoder*)encoder;
- (id) initWithCoder:(NSCoder*)decoder;

- (NSString *)description;

- (NSDictionary *) setDataViewWithName: (NSString *) description
                      AndStartDateTime: (long) startDateTime 
                        AndEndDateTime: (long) endDateTime;

- (void) reduceDataSeriesToSampledSeconds: (int) numberOfSeconds;

//- (DataSeries *) sampleDataAtInterval: (int) numberOfSeconds;

- (NSDictionary *) getValues: (NSArray *) fieldNames 
                  AtDateTime: (long) dateTime;

- (NSDictionary *)getValues:(NSArray *) fieldNames 
                 AtDateTime: (long) dateTime 
              WithTicOffset: (long) numberOfTics;

- (NSNumber *) getDateTimeAtIndex: (long) dataIndex;

- (NSNumber *) getDataFor:(NSString *) dataField 
              AtIndex: (long) dataIndex;

- (long) latestDateTimeBeforeOrEqualTo: (long) dateTime;

- (long) minDateTime;

- (long) maxDateTime;

- (NSUInteger) length;

- (DataSeries *) getCopyOfStaticData;

- (NSArray *) getFieldNames;


- (BOOL) writeDataSeriesToFile: (NSURL *) fileNameAndPath;

- (BOOL) writeDataSeriesToFile: (NSURL *) fileNameAndPath
                  ForStartTime: (long) startDateTime
                    AndEndTime: (long) endDateTime;

-(DataView *) getDataViewForKey: (NSString *) viewName;

@end 

