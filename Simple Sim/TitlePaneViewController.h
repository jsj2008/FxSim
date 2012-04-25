//
//  TitlePaneViewController.h
//  Simple Sim
//
//  Created by Martin O'Connor on 21/03/2012.
//  Copyright (c) 2012 OCONNOR RESEARCH. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "SeriesPlot.h"

@interface TitlePaneViewController : NSViewController{
    SeriesPlot *titlePanePlot;
}
@property (weak) IBOutlet CPTGraphHostingView *titlePaneGraphHostingView;

@end
