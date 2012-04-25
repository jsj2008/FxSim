//
//  UtilityFunctions.h
//  Simple Sim
//
//  Created by Martin O'Connor on 17/03/2012.
//  Copyright (c) 2012 OCONNOR RESEARCH. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface UtilityFunctions : NSObject
+(int)fib:(int)n;

+(int) signum: (int) n;

//+(void) sortDoubleArray:(double *) arrayToSort WithStartIndex:(int) startIndex AndEndIndex:(int) endIndex;
+(void) calcSortIndexForDoubleArray:(double *) arrayToSort 
                     WithStartIndex:(int) startIndex 
                        AndEndIndex:(int) endIndex
              AndReturningSortIndex:(int *) sortIndexArray;

@end
