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
@synthesize name;
@synthesize minDateTime;
@synthesize maxDateTime;


-(id)initWithId:(NSInteger) idNum 
        AndName: (NSString *) nameString 
 AndMinDateTime: (long) minDateTimeData 
 AndMaxDateTime: (long) maxDateTimeData
{
    self = [super init];
    if(self){
        dbid = idNum;
        name = nameString;
        minDateTime = minDateTimeData;
        maxDateTime = maxDateTimeData;
    }
    return self;
}

-(id)initWithId:(NSInteger) idNum 
        AndName: (NSString *) nameString
{
    return [self initWithId:idNum 
                    AndName:nameString 
             AndMinDateTime:0 
             AndMaxDateTime:0];
}

@end
