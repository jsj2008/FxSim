//
//  DataView.h
//  Simple Sim
//
//  Created by Martin O'Connor on 27/01/2012.
//  Copyright (c) 2012 OCONNOR RESEARCH. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <corePlot/corePlot.h>

@class DataSeries;

@interface DataView: NSObject<CPTPlotDataSource>{
    NSString *_name;
    __weak DataSeries *_dataSeries;
    long _startIndexForPlot;
    long _countForPlot;
    NSMutableDictionary *_minYvalues;
    NSMutableDictionary *_maxYvalues;
}

@property (nonatomic, strong) NSString *name;
@property long startIndexForPlot;
@property long countForPlot;
@property (nonatomic, strong) NSMutableDictionary *minYvalues;
@property (nonatomic, strong) NSMutableDictionary *maxYvalues;


-(id) initWithDataSeries: (DataSeries *) underlyingSeries 
                 AndName:(NSString *) name 
           AndStartIndex: (long) startIndex 
             AndEndIndex: (long) endIndex 
                 AndMins:(NSMutableDictionary *) mins 
                 AndMaxs:(NSMutableDictionary *) maxs;

- (void) encodeWithCoder:(NSCoder*)encoder;
- (id) initWithCoder:(NSCoder*)decoder;


- (void)addMin: (double) min 
        AndMax: (double) max 
        ForKey: (NSString *)key;

- (NSString *)description;
- (long) minDateTime;
- (long) maxDateTime;
- (double) minDataValue;
- (double) maxDataValue;






@end