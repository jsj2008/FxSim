//
//  HistogramPlot.h
//  Simple Sim
//
//  Created by Martin on 11/07/2013.
//  Copyright (c) 2013 OCONNOR RESEARCH. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <corePlot/corePlot.h>

@class Simulation;

@interface HistogramPlot : NSObject<CPTPlotDataSource, CPTBarPlotDelegate, CPTPlotSpaceDelegate>
-(id)initWithIdentifier:(NSString*) identifierString;




- (void) createHistogramDataForSim: (Simulation *) simA
                    andOptionalSim: (Simulation *) simB;



- (void) leftSideExpand;
- (void) leftSideContract;
- (void) bottomExpand;
- (void) bottomContract;
- (void) rightSideExpand;
- (void) rightSideContract;
- (void) topExpand;
- (void) topContract;



@property (readonly, retain) NSString *identifier;
@property (retain) CPTGraphHostingView *hostingView;
@property int numberOfBins;

@end
