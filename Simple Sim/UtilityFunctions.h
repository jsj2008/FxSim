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

+(int) signOfDouble: (double) n;

+(int) signOfInt: (int) n;

+(int) signOfLong: (long) n;

+(void) calcSortIndexForDoubleArray: (double *) arrayToSort
                     WithStartIndex: (long) startIndex
                        AndEndIndex: (long) endIndex
              AndReturningSortIndex: (int *) sortIndexArray;

@end
