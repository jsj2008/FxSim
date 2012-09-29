//
//  DataSeries.h
//  Simple Sim
//
//  Created by Martin O'Connor on 06/01/2012.
//  Copyright (c) 2012 OCONNOR RESEARCH. All rights reserved.
//

#import <Foundation/Foundation.h> 
#import <corePlot/corePlot.h> 
@class DataView;
//@class SignalSystem;
//@class PositioningSystem;
//@class RulesSystem;

@interface DataSeries: NSObject{
    NSString *_name;
    int _databaseId;
    double _pipSize;
    CPTNumericData *_xData; 
    NSMutableDictionary *_yData; 
    NSMutableDictionary *_dataViews;
    int _sampleRate;
    //SignalSystem *_signalSystem;
    //PositioningSystem *_positioningSystem;
}

@property (retain) NSString *name;
@property (assign) int dbId;
@property (nonatomic, retain) CPTNumericData * xData; 
@property (atomic, retain) NSMutableDictionary * yData;
@property (atomic, retain) NSMutableDictionary * dataViews;  
@property (assign) int sampleRate;  
@property (assign) double pipSize;  
//@property SignalSystem *signalSystem; 
//@property PositioningSystem *positioningSystem;
//@property RulesSystem *rulesSystem; 

//@property (retain)            NSString *strategy;


- (id)init;

- (id)  initWithName: (NSString *)seriesName 
            AndDbTag: (NSUInteger) databaseId 
          AndPipSize: (double) quotePipSize; 
//     AndSignalSystem: (SignalSystem *) signalSystem
//   AndPositionSystem: (PositioningSystem *) positionSystem
//AndRulesSystem: (RulesSystem *) rulesSystem;

- (NSString *)description;

- (DataView *) setPlotViewWithName: (NSString *) description 
                  AndStartDateTime: (long) startDateTime 
                    AndEndDateTime: (long) endDateTime;

- (void) setDataSeriesWithFieldName: (NSString *) fieldName 
                           AndDates: (CPTNumericData *) epochdates 
                            AndData: (CPTNumericData *) dataSeries;

- (void) reduceDataSeriesToSampledSeconds: (int) numberOfSeconds;

- (DataSeries *) sampleDataAtInterval: (int) numberOfSeconds;

- (NSDictionary *) getValues: (NSArray *) fieldNames 
                  AtDateTime: (long) dateTime;

-(NSDictionary *)getValues:(NSArray *) fieldNames 
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

//- (NSArray *) derivedVariables;



@end 

