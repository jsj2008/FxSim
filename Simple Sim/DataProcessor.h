//
//  DataProcessor.h
//  Simple Sim
//
//  Created by Martin O'Connor on 26/04/2012.
//  Copyright (c) 2012 OCONNOR RESEARCH. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface DataProcessor : NSObject

+(NSDictionary *)processWithDataSeries: (NSDictionary *) dataSeries
                           AndStrategy: (NSString *) strategyString
                        AndProcessInfo: (NSDictionary *) parameters
                     AndReturningStats: (NSMutableArray *) statsArray;

+(BOOL)strategyUnderstood:(NSString *) strategyString;


@end
