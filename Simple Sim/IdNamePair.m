//
//  IdNamePair.m
//  Simple Sim
//
//  Created by Martin O'Connor on 04/01/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "IdNamePair.h"

@implementation IdNamePair

@synthesize dbid;
@synthesize description;


-(id)init
{
    return [self initWithId: 0 AndName:[NSString stringWithString:@""]];
}


-(id)initWithId:(NSInteger) idNum AndName: (NSString *) name;
{
    self = [super init];
    if(self){
        dbid = idNum;
        description = name;
    }
    return self;
}


@end
