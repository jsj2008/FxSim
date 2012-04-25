//
//  AppController.m
//  Simple Sim
//
//  Created by O'Connor Martin on 19/12/2011.
//  Copyright (c) 2011 OCONNOR RESEARCH. All rights reserved.
//

#import "AppController.h"
#import "PlotController.h"
#import "SimulationController.h"
#import "Simulation.h"
#import "DataView.h"
#import "EpochTime.h"
#import "DataSeries.h"
#import "SeriesPlot.h"
#import "TimeSeriesLine.h"
#import "SimulationViewController.h"
#import "InteractiveTradeViewController.h"
#import "TitlePaneViewController.h"

//#import "UtilityFunctions.h"



#define THREADS YES

#define DAY_SECONDS 24*60*60


@interface AppController()
@end


@implementation AppController
@synthesize InteractiveViewButton;
@synthesize SimulationViewButton;
@synthesize shiftDataDaysLabel;
@synthesize shiftDataRangeForward;
@synthesize shiftDataRangeBack;
@synthesize dataRangeMoveValue;
@synthesize intraDayLeftSideTab;
@synthesize leftPanelStatusLabel;
@synthesize sideTitle;
@synthesize minAvailableDate;
@synthesize maxAvailableDate;
@synthesize leftSideProgressBar;
@synthesize colorsForPlots;
@synthesize currentDay;
@synthesize box;

//BOOL simDataZoomSelectFrom = YES;

-(id)init
{
    self = [super init];
    if(self){
        coloursForPlots = [NSArray arrayWithObjects:
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
        fieldNameOrdering = [[NSArray alloc] initWithObjects:
                             @"MID",
                             @"NAV",
                             @"DRAWDOWN",
                             @"MARGINUSED",
                             @"MARGINAVAIL",
                             @"CLOSEOUT",
                             @"CASHBALANCE",
                             @"TRADE_PNL",
                             @"POS_PNL",
                             @"CASHTRANSFER",
                             @"SIGNAL",
                             @"POSITION",
                             @"SHORT",@"LONG",
                             @"BID",
                             @"ASK",
                             @"EWMA18",
                             @"EWMA20", 
                             @"EWMA22", 
                             @"EWMA24", 
                             @"EWMA26", 
                             nil];

        

    }
    return self;
}

-(void)awakeFromNib
{
    dataControllerForUI = [[DataController alloc] init];
    listOfFxPairs = [dataControllerForUI fxPairs];
    
    viewControllers = [[NSMutableDictionary alloc] init];
    
    TitlePaneViewController *tpvc;
    tpvc = [[TitlePaneViewController alloc] init];
    [viewControllers setObject:tpvc forKey:@"TITLEPANE"];
    
    SimulationViewController *svc;
    svc = [[SimulationViewController alloc] init];
    
    [viewControllers setObject:svc forKey:@"SIMVIEW"];
    InteractiveTradeViewController *itvc;
    itvc = [[InteractiveTradeViewController alloc] init];
    if(THREADS){
        [itvc setDoThreads:YES];
        [svc setDoThreads:YES];
    }
    [viewControllers setObject:itvc forKey:@"INTERVIEW"];
    
    [svc setColoursForPlots:coloursForPlots];
    [svc setFieldNameOrdering:fieldNameOrdering];
    [svc setFxPairsAndDbIds:listOfFxPairs];
    [svc setDataControllerForUI:dataControllerForUI];
    [itvc setColoursForPlots:coloursForPlots];
    [itvc setFieldNameOrdering:fieldNameOrdering];
    [itvc setFxPairsAndDbIds:listOfFxPairs];
    
    [svc setDelegate:self];
    [itvc setDelegate:self];
    
    NSWindow *w = [box window];
    
    //Put the view in the box
    NSView *v = [[viewControllers objectForKey:@"TITLEPANE"] view];
    
    [box setContentView:v];
    
    //Compute the new window frame
    NSSize currentSize = [[box contentView] frame].size;
    NSSize newSize = [v frame].size;
    float deltaWidth = newSize.width - currentSize.width;
    float deltaHeight = newSize.height - currentSize.height;
    NSRect windowFrame = [w frame];
    windowFrame.size.height += deltaHeight;
    windowFrame.origin.y -= deltaHeight;
    windowFrame.size.width += deltaWidth;
    
    //Clear the box for resizing
    [box setContentView:nil];
    [w setFrame:windowFrame display:YES animate:YES];
    [box setContentView:v];
}

-(void)setStatusLabel:(NSTextField *) statusLabel WithMessage:(NSString *) newMessage 
{
    [statusLabel setStringValue:newMessage];
}

-(NSArray *)getFieldNamesInCorrectOrdering:(NSArray *) fieldNamesFromData
{      
    
    NSMutableArray *fieldNames = [fieldNameOrdering mutableCopy];
    NSMutableArray *isAvailable = [[NSMutableArray alloc] init];
   
    for(int i = 0; i < [fieldNames count]; i ++){
        BOOL found = NO;
        for(int j = 0; j < [fieldNamesFromData count]; j++){
            if([[fieldNames objectAtIndex:i] isEqualToString:[fieldNamesFromData objectAtIndex:j]])
            {
                found = YES;
                break;
            }
        }
        if(found){
            [isAvailable addObject:[NSNumber numberWithBool:YES]];
        }else{
            [isAvailable addObject:[NSNumber numberWithBool:NO]];
        }
    }
    for(int i = [fieldNames count] - 1; i >= 0; i--){
        if(![[isAvailable objectAtIndex:i] boolValue]){
            [fieldNames removeObjectAtIndex:i];
        }
    }
    return fieldNames;
}

- (IBAction)changeToSimulationView:(id)sender {
    [InteractiveViewButton setState:0];
    
    // Try to end editing
    NSWindow *w = [box window];
    BOOL ended = [w makeFirstResponder:w];
    if(!ended){
        NSBeep();
        return;
    }
    
    NSView *v;
    if([SimulationViewButton state]==0){
        v = [[viewControllers objectForKey:@"TITLEPANE"] view];
    }else{
    //Put the view in the box
        v = [[viewControllers objectForKey:@"SIMVIEW"] view];
    }
    [box setContentView:v];
        
    //Compute the new window frame
    NSSize currentSize = [[box contentView] frame].size;
    NSSize newSize = [v frame].size;
    float deltaWidth = newSize.width - currentSize.width;
    float deltaHeight = newSize.height - currentSize.height;
    NSRect windowFrame = [w frame];
    windowFrame.size.height += deltaHeight;
    windowFrame.origin.y -= deltaHeight;
    windowFrame.size.width += deltaWidth;
        
    //Clear the box for resizing
    [box setContentView:nil];
    [w setFrame:windowFrame display:YES animate:YES];
    [box setContentView:v];
}
    
- (IBAction)changeToInteractiveView:(id)sender {
    [SimulationViewButton setState:0];
    // Try to end editing
    NSWindow *w = [box window];
    BOOL ended = [w makeFirstResponder:w];
    if(!ended){
        NSBeep();
        return;
    }
    //Put the view in the box
    NSView *v;
    if([InteractiveViewButton state] == 0){
        v = [[viewControllers objectForKey:@"TITLEPANE"] view];    
    }else{
        v = [[viewControllers objectForKey:@"INTERVIEW"] view];
    }

    [box setContentView:v];
    
    //Compute the new window frame
    NSSize currentSize = [[box contentView] frame].size;
    NSSize newSize = [v frame].size;
    float deltaWidth = newSize.width - currentSize.width;
    float deltaHeight = newSize.height - currentSize.height;
    NSRect windowFrame = [w frame];
    windowFrame.size.height += deltaHeight;
    windowFrame.origin.y -= deltaHeight;
    windowFrame.size.width += deltaWidth;
    
    //Clear the box for resizing
    [box setContentView:nil];
    [w setFrame:windowFrame display:YES animate:YES];
    [box setContentView:v];
}

#pragma mark -
#pragma mark Simulation Output Methods


-(void)gettingDataIndicatorSwitchOn
{
    [leftPanelStatusLabel setHidden:NO];
    [leftPanelStatusLabel setStringValue:@"Retrieving from database"];
    [leftSideProgressBar setHidden:NO];
    [leftSideProgressBar startAnimation:nil];
}

-(void)gettingDataIndicatorSwitchOff
{
    [leftSideProgressBar stopAnimation:nil];
    [leftPanelStatusLabel setStringValue:@""];
    [leftSideProgressBar setHidden:YES];
    [leftPanelStatusLabel setHidden:YES];
}






#pragma mark -
#pragma mark TableView Methods
@end
