//
//  PlotItem.m
//  CorePlotGallery
//
//  Created by Jeff Buck on 9/4/10.
//  Copyright 2010 Jeff Buck. All rights reserved.
//

#import "PlotItem.h"

#import <tgmath.h>

#if TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE
#else
// For IKImageBrowser
#import <Quartz/Quartz.h>
#endif

@implementation PlotItem

@synthesize defaultLayerHostingView;
@synthesize graphs;
@synthesize title;

-(id)init
{
	if ( (self = [super init]) ) {
		graphs = [[NSMutableArray alloc] init];
	}
    
	return self;
}

-(void)addGraph:(CPTGraph *)graph toHostingView:(CPTGraphHostingView *)layerHostingView
{
	[graphs addObject:graph];
    
	if ( layerHostingView ) {
		layerHostingView.hostedGraph = graph;
	}
}

-(void)addGraph:(CPTGraph *)graph
{
	[self addGraph:graph toHostingView:nil];
}

-(void)killGraph
{
	// Remove the CPTLayerHostingView
	if ( defaultLayerHostingView ) {
		[defaultLayerHostingView removeFromSuperview];
        
		defaultLayerHostingView.hostedGraph = nil;
		//[defaultLayerHostingView release];
		defaultLayerHostingView = nil;
	}
    
	//[cachedImage release];
	//cachedImage = nil;
    
	[graphs removeAllObjects];
}

-(void)showSeries:(NSString *)seriesName
{
    
}

-(void)dealloc
{
	[self killGraph];
}

-(void)setData:(DataSeries *) plotData
{
}

-(NSComparisonResult)titleCompare:(PlotItem *)other
{
	return [title caseInsensitiveCompare:other.title];
}

-(void)setTitleDefaultsForGraph:(CPTGraph *)graph withBounds:(CGRect)bounds
{
	graph.title = title;
	CPTMutableTextStyle *textStyle = [CPTMutableTextStyle textStyle];
	textStyle.color				   = [CPTColor grayColor];
	textStyle.fontName			   = @"Helvetica-Bold";
	textStyle.fontSize			   = round(bounds.size.height / (CGFloat)20.0);
	graph.titleTextStyle		   = textStyle;
	graph.titleDisplacement		   = CGPointMake( 0.0f, round(bounds.size.height / (CGFloat)18.0) ); // Ensure that title displacement falls on an integral pixel
	graph.titlePlotAreaFrameAnchor = CPTRectAnchorTop;
}

-(void)setPaddingDefaultsForGraph:(CPTGraph *)graph withBounds:(CGRect)bounds
{
	CGFloat boundsPadding = round(bounds.size.width / (CGFloat)20.0); // Ensure that padding falls on an integral pixel
    
	graph.paddingLeft = boundsPadding;
    
	if ( graph.titleDisplacement.y > 0.0 ) {
		graph.paddingTop = graph.titleDisplacement.y * 2;
	}
	else {
		graph.paddingTop = boundsPadding;
	}
    
	graph.paddingRight	= boundsPadding;
	graph.paddingBottom = boundsPadding;
}


-(void)applyTheme:(CPTTheme *)theme toGraph:(CPTGraph *)graph withDefault:(CPTTheme *)defaultTheme
{
	if ( theme == nil ) {
		[graph applyTheme:defaultTheme];
	}
	else if ( ![theme isKindOfClass:[NSNull class]] ) {
		[graph applyTheme:theme];
	}
}

-(void)setFrameSize:(NSSize)size
{
}

-(void)renderInView:(NSView *)hostingView withTheme:(CPTTheme *)theme
{
	[self killGraph];
    
	defaultLayerHostingView = [(CPTGraphHostingView *)[CPTGraphHostingView alloc] initWithFrame:hostingView.bounds];
    
	[defaultLayerHostingView setAutoresizesSubviews:YES];
	[defaultLayerHostingView setAutoresizingMask:NSViewWidthSizable | NSViewHeightSizable];
    
	[hostingView addSubview:defaultLayerHostingView];
	//[self generateData];
	[self renderInLayer:defaultLayerHostingView withTheme:theme];
}

-(void)renderInLayer:(CPTGraphHostingView *)layerHostingView withTheme:(CPTTheme *)theme
{
	NSLog(@"PlotItem:renderInLayer: Override me");
}

-(void)reloadData
{
	for ( CPTGraph *g in graphs ) {
		[g reloadData];
	}
}

@end
