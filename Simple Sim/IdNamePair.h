//
//  IdNamePair.h
//  Simple Sim
//
//  Created by Martin O'Connor on 04/01/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface IdNamePair : NSObject
@property NSInteger dbid;
@property (retain) NSString *name;
@property long minDateTime;
@property long maxDateTime;

//-(id)init;
-(id)initWithId:(NSInteger) idNum 
        AndName: (NSString *) name;
-(id)initWithId:(NSInteger) idNum 
        AndName: (NSString *) name 
 AndMinDateTime: (long) minDateTimeData 
 AndMaxDateTime: (long) maxDateTimeData;
@end
