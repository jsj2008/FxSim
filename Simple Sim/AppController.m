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
@synthesize leftPanelStatusLabel;
@synthesize minAvailableDate;
@synthesize maxAvailableDate;
@synthesize leftSideProgressBar;
@synthesize leftSideProgressBar2;
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
                             @"POSAVEPRICE",
                             @"BID",
                             @"ASK",
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
    //[svc setFieldNameOrdering:fieldNameOrdering];
    [svc setFxPairsAndDbIds:listOfFxPairs];
    [svc setDataControllerForUI:dataControllerForUI];
    [itvc setColoursForPlots:coloursForPlots];
    //[itvc setFieldNameOrdering:fieldNameOrdering];
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
    
    if([SimulationViewButton state] == 1){
        SimulationViewController *controllerOfView = (SimulationViewController *)[viewControllers objectForKey:@"SIMVIEW"];
        [controllerOfView viewChosenFromMainMenu];
    }
    
}
    
-  (IBAction) changeToInteractiveView:(id)sender {
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
    
    if([InteractiveViewButton state] == 1){
        InteractiveTradeViewController *controllerOfView = (InteractiveTradeViewController *)[viewControllers objectForKey:@"INTERVIEW"];
        [controllerOfView viewChosenFromMainMenu];
    }
}

#pragma mark -
#pragma mark Simulation Output Methods


- (void) gettingDataIndicatorSwitchOn
{
    [leftPanelStatusLabel setHidden:NO];
    [leftPanelStatusLabel setStringValue:@"Reading Recordset"];
    [leftSideProgressBar setHidden:NO];
    [leftSideProgressBar startAnimation:nil];
    [leftSideProgressBar2 setHidden:NO];
    [leftSideProgressBar2 startAnimation:nil];
    [leftSideProgressBar2 setMinValue:0.0];
    [leftSideProgressBar2 setMaxValue:1.0];
    [leftSideProgressBar2 setDoubleValue:0.0];
}

- (void) gettingDataIndicatorSwitchOff
{
    [leftPanelStatusLabel setStringValue:@""];
    [leftPanelStatusLabel setHidden:YES];
    [leftSideProgressBar stopAnimation:nil];
    [leftSideProgressBar2 stopAnimation:nil];
    [leftSideProgressBar setHidden:YES];
    [leftSideProgressBar2 setHidden:YES];
    
}

- (void) readingRecordSetsProgress: (NSNumber *) progressFraction;
{
    [leftSideProgressBar2 setDoubleValue:[progressFraction doubleValue]];
}

- (void) showAlertPanelWithInfo: (NSDictionary *) alertInfo
{
    NSString *title  = [alertInfo objectForKey:@"TITLE"];
    NSString *msgFormat = [alertInfo objectForKey:@"MSGFORMAT"];
    NSString *defaultButton = [alertInfo objectForKey:@"DEFAULTBUTTON"]; 
    NSString * altButton =  [alertInfo objectForKey:@"ALTBUTTON"]; 
    NSString *otherButton =  [alertInfo objectForKey:@"OTHERBUTTON"]; 
    NSRunAlertPanel(title, msgFormat, defaultButton, altButton, otherButton);
}
 
- (void) putFieldNamesInCorrectOrdering:(NSMutableArray *) fieldNamesFromData
{      
    
    NSMutableArray *fieldNames = [fieldNameOrdering mutableCopy];
    NSMutableArray *isAvailable = [[NSMutableArray alloc] init];
    NSMutableArray *isFound = [[NSMutableArray alloc] init];
    NSMutableArray *newFields =  [[NSMutableArray alloc] init];
    int i, j;
    for(i = 0; i < [fieldNamesFromData count]; i ++){
        [isFound addObject:[NSNumber numberWithBool:NO]];   
    }
    
    for(i = 0; i < [fieldNames count]; i ++){
        BOOL found = NO;
        for(j = 0; j < [fieldNamesFromData count]; j++){
            if([[fieldNames objectAtIndex:i] isEqualToString:[fieldNamesFromData objectAtIndex:j]])
            {
                found = YES;
                [isFound replaceObjectAtIndex:j withObject:[NSNumber numberWithBool:YES]];
                break;
            }
        }
        if(found){
            [isAvailable addObject:[NSNumber numberWithBool:YES]];
        }else{
            [isAvailable addObject:[NSNumber numberWithBool:NO]];
        }
    }
    for(i = [fieldNames count] - 1; i >= 0; i--){
        if(![[isAvailable objectAtIndex:i] boolValue]){
            [fieldNames removeObjectAtIndex:i];
        }
    }
    for(i = 0; i < [isFound count]; i++){
        if(![[isFound objectAtIndex:i] boolValue]){
            [newFields addObject:[fieldNamesFromData objectAtIndex:i]];
        }
    }
    NSArray *newFieldsSorted = [newFields sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
    for(i = 0; i < [newFieldsSorted count]; i++){
        [fieldNames addObject:[newFieldsSorted objectAtIndex:i]];
    }
    while([fieldNamesFromData count]>0){
        [fieldNamesFromData removeObjectAtIndex:0];
    }
    for(i = 0; i < [fieldNames count]; i++){
        [fieldNamesFromData addObject:[fieldNames objectAtIndex:i]];
    }
}




#pragma mark -
#pragma mark TableView Methods
@end
