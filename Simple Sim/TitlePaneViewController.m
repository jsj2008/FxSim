//
//  TitlePaneViewController.m
//  Simple Sim
//
//  Created by Martin O'Connor on 21/03/2012.
//  Copyright (c) 2015 MARTIN OCONNOR. All rights reserved.
//

#import "TitlePaneViewController.h"

@interface TitlePaneViewController ()

@end

@implementation TitlePaneViewController
@synthesize titlePaneGraphHostingView;

- (id)init
{
    self = [super initWithNibName:@"TitlePane" bundle:nil];
    if (self) {
        [self setTitle:@"Title"];
    }
    
    return self;
}

-(void)awakeFromNib
{
    titlePanePlot = [[SeriesPlot alloc] initWithIdentifier:@"TITLESCREEN"];
    [titlePanePlot setHostingView:titlePaneGraphHostingView];
    [titlePanePlot initialGraphAndAddAnnotation:YES];
}

@end
