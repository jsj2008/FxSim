//
//  RulesSystem.h
//  Simple Sim
//
//  Created by Martin O'Connor on 20/09/2012.
//  Copyright (c) 2012 OCONNOR RESEARCH. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface RulesSystem : NSObject
{
    NSString *_type;
    int _historyDays;
    double _cutoff;

}

- (id) initWithString: (NSString *) ruleString;
+ (BOOL) basicCheck: (NSString *) rulesString;
-(NSArray *) variablesNeeded;

@property (readonly) NSString *ruleString;
@property (readonly) NSString *type;
@property (readonly) int historyDays;
@property (readonly) double cutoff;
@end
