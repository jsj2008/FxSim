//
//  UtilityFunctions.m
//  Simple Sim
//
//  Created by Martin O'Connor on 17/03/2012.
//  Copyright (c) 2012 OCONNOR RESEARCH. All rights reserved.
//

#import "UtilityFunctions.h"

@interface UtilityFunctions()  
+(void) swapDoublesA:(double *) a 
                AndB: (double *) b;
+(void) swapIntsA: (int *) a 
             AndB: (int *) b;
@end

@implementation UtilityFunctions
+(int)fib:(int)n
{
    int first = 1;
    int second = 1;
    int temp;
    if(n == 1){
        return first;
    }
    if(n == 2){
        return second;
    }
    for(int i = 3; i <= n; i++){
        if(i == n){
            return first + second;
        }else{
            temp = first;
            first = second;
            second = temp + second;
        }
        
    }
    return 0;
}

+(int) signOfDouble: (double) n { return (n < 0.0) ? -1 : (n > 0.0) ? +1 : 0; };

+(int) signOfInt: (int) n { return (n < 0) ? -1 : (n > 0) ? +1 : 0; };


+(void) swapDoublesA: (double *) a 
                AndB: (double *) b
{
    double t=*a; *a=*b; *b=t;
}

+(void) swapIntsA: (int *) a 
                AndB: (int *) b
{
    int t=*a; *a=*b; *b=t;
}

+(void) calcSortIndexForDoubleArray:(double *) arrayToSort 
                     WithStartIndex:(NSUInteger) startIndex
                        AndEndIndex:(NSUInteger) endIndex
                 AndReturningSortIndex:(int *) sortIndexArray
{
    double pivotValue = arrayToSort[startIndex]; 
    NSUInteger leftIndex = startIndex + 1;
    NSUInteger rightIndex = endIndex;
    
    if (endIndex > startIndex + 1)
    {
        
        while (leftIndex < rightIndex)
        {
            while (arrayToSort[leftIndex] < pivotValue && leftIndex < endIndex){
                leftIndex++;
            }
            while(arrayToSort[rightIndex] >= pivotValue &&  rightIndex > startIndex){
                rightIndex--;
            }
            if(leftIndex<rightIndex)
            {
                [self swapDoublesA: &arrayToSort[leftIndex] 
                              AndB:&arrayToSort[rightIndex]];
                [self swapIntsA: &sortIndexArray[leftIndex] 
                              AndB:&sortIndexArray[rightIndex]];
                //leftIndex++;
                //rightIndex--;
            }
        }
        [self swapDoublesA:&arrayToSort[startIndex] AndB:&arrayToSort[rightIndex]];
        [self swapIntsA:&sortIndexArray[startIndex] AndB:&sortIndexArray[rightIndex]];
        
        [self calcSortIndexForDoubleArray:arrayToSort 
                           WithStartIndex:startIndex 
                              AndEndIndex:rightIndex-1
                    AndReturningSortIndex:sortIndexArray];
        [self calcSortIndexForDoubleArray:arrayToSort 
                           WithStartIndex:rightIndex+1 
                              AndEndIndex:endIndex
                    AndReturningSortIndex:sortIndexArray];
    }else{
        if(endIndex == (startIndex + 1)){
            if(arrayToSort[startIndex]>arrayToSort[endIndex]){
                [self swapDoublesA:&arrayToSort[startIndex] AndB:&arrayToSort[endIndex]];
                [self swapIntsA:&sortIndexArray[startIndex] AndB:&sortIndexArray[endIndex]];
            }
        }
    }
}

@end
