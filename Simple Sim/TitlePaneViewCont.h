//
//  FrontView.h
//  Simple Sim
//
//  Created by Martin O'Connor on 21/03/2012.
//  Copyright (c) 2012 OCONNOR RESEARCH. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "CorePlot.h"
#import "SeriesPlot.h"

@interface titlePane : NSViewController{

    SeriesPlot *titlePanePlot;    
}

@property (weak) IBOutlet CPTGraphHostingView *titlePaneGraphHostingView;
@end
