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
    NSString *description;
    DataSeries *dataSeries;
    NSUInteger startIndexForPlot;
    NSUInteger countForPlot;
    
    NSMutableDictionary *minYvalues;
    NSMutableDictionary *maxYvalues;
}
@property (nonatomic, strong) NSString *description;
@property NSUInteger startIndexForPlot;
@property NSUInteger countForPlot;
@property (nonatomic, strong) NSMutableDictionary *minYvalues;
@property (nonatomic, strong) NSMutableDictionary *maxYvalues;

-(id)initWithDataSeries: (DataSeries *) underlyingSeries AndName:(NSString *) name AndStartIndex: (long) startIndex AndEndIndex: (long) endIndex AndMins:(NSMutableDictionary *) mins AndMaxs:(NSMutableDictionary *) maxs;

-(void)addMin: (double) min AndMax: (double) max ForKey: (NSString *)key;

-(id)initAsDummy;

-(long)firstX;
-(long)lastX;

@end