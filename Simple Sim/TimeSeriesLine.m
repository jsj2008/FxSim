//
//  TimeSeriesAnalysis.m
//  Simple Sim
//
//  Created by Martin O'Connor on 31/01/2012.
//  Copyright (c) 2015 MARTIN OCONNOR. All rights reserved.
//

#import "TimeSeriesLine.h"
#import <CorePlot/CorePlot.h> 

@implementation TimeSeriesLine

-(id)initWithLayerIndex: (int) layerIndex 
                AndName: (NSString *) timeSeriesName 
              AndColour: (NSString *) timeSeriesColour
               AndSimId: (long) simulationId
{
    _allColourNames = [NSArray arrayWithObjects:
                      //@"Clear",
                      @"Green",
                      @"Blue",
                      @"Cyan",
                      @"Red",
                      @"Yellow",
                      @"Magenta",
                      @"Orange",
                      @"Purple",
                      @"Brown", 
                      @"White", 
                      @"LightGray", 
                      @"Gray",
                      @"DarkGray",
                      @"Black",
                      nil];
    _allColourCPTypes= [NSArray arrayWithObjects:
                       //[CPTColor clearColor],
                       [CPTColor greenColor],
                       [CPTColor blueColor],
                       [CPTColor cyanColor],
                       [CPTColor redColor],
                       [CPTColor yellowColor],
                       [CPTColor magentaColor],
                       [CPTColor orangeColor],
                       [CPTColor purpleColor],
                       [CPTColor brownColor],
                       [CPTColor whiteColor],
                       [CPTColor lightGrayColor],
                       [CPTColor grayColor],
                       [CPTColor darkGrayColor],
                       [CPTColor blackColor],
                                              nil];
    _allNSColourTypes = [NSArray arrayWithObjects:
                       //[NSColor clearColor],
                       [NSColor greenColor],
                       [NSColor blueColor],
                       [NSColor cyanColor],
                       [NSColor redColor],
                       [NSColor yellowColor],
                       [NSColor magentaColor],
                       [NSColor orangeColor],
                       [NSColor purpleColor],
                       [NSColor brownColor],
                       [NSColor whiteColor],
                       [NSColor lightGrayColor],
                       [NSColor grayColor],
                       [NSColor darkGrayColor],
                       [NSColor blackColor],
                       nil];
    
    self = [super init];
    if(self){
        _layerIndex = layerIndex;
//        _overlay = NO;
        _name = timeSeriesName; 
        _colour = timeSeriesColour;
        _colourId = [_allColourNames indexOfObject:timeSeriesColour];
        _cpColour = [_allColourCPTypes objectAtIndex:_colourId];
        _nsColour = [_allNSColourTypes objectAtIndex:_colourId];
        _simId = simulationId;
    }
    return self;
}

- (id)initWithLayerIndex: (int)        layerIndex
                 AndName: (NSString *)  name
               AndColour: (NSString *)  colour{
    return [self initWithLayerIndex:layerIndex
                     AndName:name
                   AndColour:colour
                    AndSimId:0];
}

-(void)setColourId:(NSUInteger) newColourId
{
    _colourId = newColourId;
    _colour = [[self allColourNames] objectAtIndex:newColourId];
    _cpColour = [[self allColourCPTypes] objectAtIndex:newColourId];
    _nsColour = [[self allNSColourTypes] objectAtIndex:newColourId];
 }

-(NSUInteger)colourId
{
    return _colourId;
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"name:%@\nlayer:%d\ncolour:%@\nSimId:%ld",[self name],[self layerIndex],[self colour],[self simId]];
}

@synthesize name = _name;
@synthesize layerIndex = _layerIndex;
@synthesize colour = _colour;
@synthesize cpColour = _cpColour;
@synthesize nsColour = _nsColour;
@synthesize allColourNames = _allColourNames;
@synthesize allColourCPTypes = _allColourCPTypes;
@synthesize allNSColourTypes = _allNSColourTypes;
@synthesize colourId = _colourId;
@synthesize simId = _simId;


@end
