//
//  PlotController.h
//  Simple Sim
//
//  Created by Martin O'Connor on 12/01/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <CorePlot/CorePlot.h>
#import <Quartz/Quartz.h>

#import "PlotItem.h"
//#import "PlotView.h"
#import "DataController.h"

@interface PlotController : NSObject //<PlotViewDelegate>
{
    __weak NSTextField *fromDateLabel;
    __weak NSTextField *toDateLabel;
    __weak NSPopUpButton *pairPicker;
    __weak NSDatePicker *datePicker;
    __weak NSTextField *dayOfWeekLabel;
    __weak NSMatrix *filterUnit;
    __weak NSMatrix *bidAskPicker;
    __weak NSTextField *filterValue;
    IBOutlet CPTGraphHostingView *hostingView;
    
    NSDate *minAvailableDate;
    NSDate *maxAvailableDate;
    CPTGraphHostingView *defaultGraphHostingView;
    PlotItem *plotItem;
    DataController *dataController;
    
	//NSString *currentThemeName;
}
- (IBAction)changePair:(id)sender;
- (IBAction)changeDate:(id)sender;
- (IBAction)plotData:(id)sender;
- (IBAction)changeSeriesType:(id)sender;

@property (nonatomic, retain) PlotItem *plotItem;
@property (readonly) NSDate *minAvailableDate;
@property (readonly) NSDate *maxAvailableDate;
@property (weak) IBOutlet NSDatePicker *datePicker;
@property (weak) IBOutlet NSTextField *dayOfWeekLabel;
@property (weak) IBOutlet NSTextField *fromDateLabel;
@property (weak) IBOutlet NSTextField *toDateLabel;
@property (weak) IBOutlet NSPopUpButton *pairPicker;
@property (weak) IBOutlet NSMatrix *filterUnit;
@property (weak) IBOutlet NSTextField *filterValue;
@property (weak) IBOutlet NSMatrix *bidAskPicker;
@end
