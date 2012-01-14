//
//  PlotController.h
//  Simple Sim
//
//  Created by Martin O'Connor on 12/01/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

//#import <Cocoa/Cocoa.h>
//#import <CorePlot/CorePlot.h>
//#import "PlotItem.h"
//
//@class DataSeries;
//
//@interface PlotController : NSObject <CPTPlotDataSource>{
//    IBOutlet CPTGraphHostingView *hostView;
//    CPTXYGraph *graph;
//    CPTNumericData *plotData;
//}
//
////-(void)addPlotData:(NSArray *) newData;
//@property (copy) CPTNumericData *plotData;
//@property (readonly) CPTXYGraph *graph;
//
//
////-(void)updateData:(DataSeries *) newData;
//
//@end


//
//  PlotGalleryController.h
//  CorePlotGallery
//
//  Created by Jeff Buck on 9/5/10.
//  Copyright 2010 Jeff Buck. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <CorePlot/CorePlot.h>
#import <Quartz/Quartz.h>

#import "PlotGallery.h"
#import "PlotItem.h"
#import "PlotView.h"

@interface PlotController : NSObject<PlotViewDelegate>
{
	//IBOutlet NSSplitView *splitView;
	//IBOutlet NSScrollView *scrollView;
	//IBOutlet IKImageBrowserView *imageBrowser;
	//IBOutlet NSPopUpButton *themePopUpButton;
    __weak NSTextField *fromDateLabel;
    __weak NSTextField *toDateLabel;
    __weak NSPopUpButton *pairPicker;
    __weak NSDatePicker *datePicker;
    __weak NSTextField *dayOfWeekLabel;
    
    NSDate *minAvailableDate;
    NSDate *maxAvailableDate;
    
	IBOutlet PlotView *hostingView;
	CPTGraphHostingView *defaultGraphHostingView;
    
	PlotItem *plotItem;
    
	NSString *currentThemeName;
}
- (IBAction)changePair:(id)sender;
- (IBAction)changeDate:(id)sender;
- (IBAction)plotData:(id)sender;

@property (nonatomic, retain) PlotItem *plotItem;
@property (nonatomic, copy) NSString *currentThemeName;
@property (readonly) NSDate *minAvailableDate;
@property (readonly) NSDate *maxAvailableDate;
//-(IBAction)themeSelectionDidChange:(id)sender;

@property (weak) IBOutlet NSView *mainGraph;

@property (weak) IBOutlet NSDatePicker *datePicker;
@property (weak) IBOutlet NSTextField *dayOfWeekLabel;
@property (weak) IBOutlet NSTextField *fromDateLabel;
@property (weak) IBOutlet NSTextField *toDateLabel;
@property (weak) IBOutlet NSPopUpButton *pairPicker;
@end
