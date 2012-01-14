//
//  IdNamePair.h
//  Simple Sim
//
//  Created by Martin O'Connor on 04/01/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface IdNamePair : NSObject{
    NSInteger dbid;
    NSString *description;
}
@property NSInteger dbid;
@property (retain) NSString *description;

-(id)init;
-(id)initWithId:(NSInteger) idNum AndName: (NSString *) name;

@end
