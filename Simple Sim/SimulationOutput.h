//
//  SimulationOutput.h
//  Simple Sim
//
//  Created by Martin O'Connor on 22/02/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol SimulationOutput <NSObject>
- (void) clearSimulationMessage;
- (void) outputSimulationMessage:(NSString *) message;
- (void) gettingDataIndicatorSwitchOn;
- (void) gettingDataIndicatorSwitchOff;
@end
