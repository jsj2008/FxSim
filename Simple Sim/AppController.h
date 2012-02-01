//
//  AppController.h
//  Simple Sim
//
//  Created by O'Connor Martin on 19/12/2011.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CorePlot/CorePlot.h>
#import <Quartz/Quartz.h>
#import "SeriesPlot.h"
#import "DataController.h"
@class TimeSeriesLine;


@interface AppController : NSObject <NSTableViewDataSource>{
    __weak NSTextField *shortTermSamplingValue;
    __weak NSTextField *longTermSamplingValue;
    __weak NSTextField *intraDaySamplingValue;
    __weak NSMatrix *shortTermSamplingUnit;
    __weak NSMatrix *longTermSamplingUnit;
    __weak NSMatrix *intraDaySamplingUnit;
    __weak NSTextField *fromDateLabel;
    __weak NSTextField *toDateLabel;
    __weak NSPopUpButton *pairPicker;
    __weak NSDatePicker *datePicker;
    __weak NSTextField *dayOfWeekLabel;
    __weak NSMatrix *filterUnit;
    __weak NSTextField *filterValue;
    __weak CPTGraphHostingView *hostingView1;
    __weak CPTGraphHostingView *hostingView2;
    __weak CPTGraphHostingView *hostingView3;
    __weak NSTabView *mainTabs;
    __weak NSTextFieldCell *startupLabel;
    __weak NSTextField *startupMessageLabel;
    __weak NSTextField *dataGranularityLabel;
    __weak NSTextField *currentDateLabel;
    __weak NSTextField *fxPairLabel;
    NSDate *minAvailableDate;
    NSDate *maxAvailableDate;
    SeriesPlot *plot1;
    SeriesPlot *plot2;
    SeriesPlot *plot3;
    DataController *dataController;
    NSMutableArray *timeSeries;
    NSArray *colorsForPlots;
}
- (IBAction)changePair:(id)sender;
- (IBAction)changeDate:(id)sender;
- (IBAction)setUp:(id)sender;
@property (weak) IBOutlet NSScrollView *timeSeriesPicker;

@property (nonatomic, retain) SeriesPlot *plot1;
@property (nonatomic, retain) SeriesPlot *plot2;
@property (nonatomic, retain) SeriesPlot *plot3;
@property (weak) IBOutlet NSTextField *shortTermHistory;
@property (weak) IBOutlet NSTextField *longTermHistory;
@property (readonly) NSDate *minAvailableDate;
@property (readonly) NSDate *maxAvailableDate;
@property (weak) IBOutlet NSDatePicker *datePicker;
@property (weak) IBOutlet NSTextField *dayOfWeekLabel;
@property (weak) IBOutlet NSTextField *fromDateLabel;
@property (weak) IBOutlet NSTextField *toDateLabel;
@property (weak) IBOutlet NSPopUpButton *pairPicker;
@property (weak) IBOutlet NSTextField *fxPairLabel;
@property (weak) IBOutlet NSTextField *currentDateLabel;
@property (weak) IBOutlet NSTextField *dataGranularityLabel;
@property (weak) IBOutlet NSTabView *mainTabs;
@property (weak) IBOutlet NSTextFieldCell *startupLabel;
@property (weak) IBOutlet NSTextField *startupMessageLabel;
@property (weak) IBOutlet CPTGraphHostingView *hostingView1;
@property (weak) IBOutlet NSTextField *shortTermSamplingValue;
@property (weak) IBOutlet NSTextField *longTermSamplingValue;
@property (weak) IBOutlet NSMatrix *shortTermSamplingUnit;
@property (weak) IBOutlet CPTGraphHostingView *hostingView3;
@property (weak) IBOutlet NSMatrix *longTermSamplingUnit;
@property (weak) IBOutlet CPTGraphHostingView *hostingView2;
@property (weak) IBOutlet NSTextField *intraDaySamplingValue;
@property (weak) IBOutlet NSMatrix *intraDaySamplingUnit;
@property (weak) IBOutlet NSTableView *timeSeriesTableView;
@property (retain) NSMutableArray *timeSeries; 
@property (retain) NSArray *colorsForPlots;

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView;
- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row;
- (void)tableView:(NSTableView *)tableView setObjectValue:(id) obj forTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row;
-(void)addToTSTableView:(TimeSeriesLine *)TSLine;
-(void)clearTSTableView;

@end
