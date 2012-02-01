//
//  TimeSeriesAnalysis.h
//  Simple Sim
//
//  Created by Martin O'Connor on 31/01/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
@class CPTColor;

@interface TimeSeriesLine : NSObject{
    NSString *name;
    BOOL visible;
    NSUInteger colourId;
    NSString *colour;
    CPTColor *cpColour;
    NSArray *allColourNames;
    NSArray *allColourCPTypes;
}
@property (copy) NSString *name;
@property BOOL visible;
@property NSUInteger colourId;
@property (copy) NSString *colour;
@property (copy) CPTColor *cpColour;
@property (copy) NSArray *allColourNames;
@property (copy) NSArray *allColourCPTypes;

-(id)initWithVisibility: (BOOL) isVisible AndName: (NSString *) name AndColour:(NSString *) colour;
- (NSString *)description;
-(void)setColourId:(NSUInteger) newColourId;
-(NSUInteger)colourId;
@end
