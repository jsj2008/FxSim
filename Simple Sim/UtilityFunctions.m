//
//  UtilityFunctions.m
//  Simple Sim
//
//  Created by Martin O'Connor on 17/03/2012.
//  Copyright (c) 2015 MARTIN OCONNOR. All rights reserved.
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

+(int) signOfLong: (long) n { return (n < 0) ? -1 : (n > 0) ? +1 : 0; };

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
                     WithStartIndex:(long) startIndex
                        AndEndIndex:(long) endIndex
                 AndReturningSortIndex:(int *) sortIndexArray
{
    double pivotValue = arrayToSort[startIndex]; 
    long leftIndex = startIndex + 1;
    long rightIndex = endIndex;
    
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
        if(rightIndex != startIndex){
            [self swapDoublesA:&arrayToSort[startIndex] AndB:&arrayToSort[rightIndex]];
            [self swapIntsA:&sortIndexArray[startIndex] AndB:&sortIndexArray[rightIndex]];
        }
        
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

+ (double) niceNumber: (double) x
         withRounding: (BOOL) doRounding
{
    double niceNumber, f, nf;
    int exp;
    exp = floor(log10(x));
    f = x/pow(10.0,exp);
    if(doRounding){
        if(f < 1.5)
            nf = 1;
        else if(f < 3)
            nf  = 2;
        else if(f < 7)
            nf = 5;
        else
            nf = 10;
    }else{
        if(f <= 1)
            nf = 1;
        else if(f <= 2)
            nf = 2;
        else if(f <= 5)
            nf = 5;
        else {
            nf = 10;
        }
    }
    niceNumber = nf*pow(10, exp);
    return niceNumber;
}

@end
