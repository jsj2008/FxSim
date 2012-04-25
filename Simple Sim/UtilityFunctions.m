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

+(int) signum: (int) n { return (n < 0) ? -1 : (n > 0) ? +1 : 0; };

+(void) swapDoublesA: (double *) a 
                AndB: (double *) b
{
    double t=*a; *a=*b; *b=t;
}
//
//+(void) sortDoubleArray:(double *) arrayToSort 
//         WithStartIndex:(int) startIndex 
//            AndEndIndex:(int) endIndex
//{
//    if (endIndex > startIndex + 1)
//    {
//        int piv = arrayToSort[startIndex], leftIndex = startIndex + 1, rightIndex = endIndex;
//        while (leftIndex < rightIndex)
//        {
//            if (arrayToSort[leftIndex] <= piv){
//                leftIndex++;
//            }else{
//                [self swapDoublesA: &arrayToSort[leftIndex] 
//                        AndB:&arrayToSort[--rightIndex]];
//            }
//        }
//        [self swapDoublesA:&arrayToSort[--leftIndex] AndB:&arrayToSort[startIndex]];
//        [self sortDoubleArray:arrayToSort WithStartIndex:startIndex AndEndIndex:leftIndex];
//        [self sortDoubleArray:arrayToSort WithStartIndex:rightIndex AndEndIndex:endIndex];
//    }
//}
//
+(void) swapIntsA: (int *) a 
                AndB: (int *) b
{
    int t=*a; *a=*b; *b=t;
}
//
//+(void) sortIntArray:(int *) arrayToSort 
//         WithStartIndex:(int) startIndex 
//            AndEndIndex:(int) endIndex
//{
//    if (endIndex > startIndex + 1)
//    {
//        int piv = arrayToSort[startIndex], leftIndex = startIndex + 1, rightIndex = endIndex;
//        while (leftIndex < rightIndex)
//        {
//            if (arrayToSort[leftIndex] <= piv){
//                leftIndex++;
//            }else{
//                [self swapIntsA: &arrayToSort[leftIndex] 
//                              AndB:&arrayToSort[--rightIndex]];
//            }
//        }
//        [self swapIntsA:&arrayToSort[--leftIndex] AndB:&arrayToSort[startIndex]];
//        [self sortIntArray:arrayToSort WithStartIndex:startIndex AndEndIndex:leftIndex];
//        [self sortIntArray:arrayToSort WithStartIndex:rightIndex AndEndIndex:endIndex];
//    }
//}

+(void) calcSortIndexForDoubleArray:(double *) arrayToSort 
                     WithStartIndex:(int) startIndex 
                        AndEndIndex:(int) endIndex
                 AndReturningSortIndex:(int *) sortIndexArray
{
    double pivotValue = arrayToSort[startIndex]; 
    int leftIndex = startIndex + 1; 
    int rightIndex = endIndex;
    
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
            }
        }
    }
}


//function quicksort(array)
//if length(array) > 1
//pivot := select any element of array
//left := first index of array
//right := last index of array
//while left ≤ right
//while array[left] < pivot
//left := left + 1
//while array[right] > pivot
//right := right - 1
//if left ≤ right
//swap array[left] with array[right]
//left := left + 1
//right := right - 1
//quicksort(array from first index to right)
//quicksort(array from left to last index)


//void quicksort(int list[],int m,int n)
//{
//    int key,i,j,k;
//    if( m < n)
//    {
//        k = choose_pivot(m,n);
//        swap(&list[m],&list[k]);
//        key = list[m];
//        i = m+1;
//        j = n;
//        while(i <= j)
//        {
//            while((i <= n) && (list[i] <= key))
//                i++;
//            while((j >= m) && (list[j] > key))
//                j--;
//            if( i < j)
//                swap(&list[i],&list[j]);
//        }
//        // swap two elements
//        swap(&list[m],&list[j]);
//        // recursively sort the lesser list
//        quicksort(list,m,j-1);
//        quicksort(list,j+1,n);
//    }
//}









@end
