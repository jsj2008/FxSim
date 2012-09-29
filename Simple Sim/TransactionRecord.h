//
//  TransactionRecord.h
//  Simple Sim
//
//  Created by Martin O'Connor on 17/06/2012.
//  Copyright (c) 2012 OCONNOR RESEARCH. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TransactionRecord : NSObject{
    int _amount;        
    long   _dateTime;
    double _price;
    int _resultingMarketExposure;
    double _spread;
    double _spreadInAccCurrency;
    long _signalDateTime;
    //int _signalIndex;     
}

- (id) initWithAmount:(int) amount
          AndDateTime:(long)dateTime 
             AndPrice:(double)price 
 AndResultingExposure: (int) resultingExposure
            AndSpread: (double) spread
AndSpreadInAccCurrency: (double) spreadInAccCurrency
    AndSignalDateTime: (long) signalDateTime;


@property (readonly) int amount;        
@property (readonly) long   dateTime;
@property (readonly) double price;
@property (readonly) int resultingMarketExposure;
@property (readonly) double spread;
@property (readonly) double spreadInAccCurrency;
@property (readonly) long signalDateTime;
@property (readonly) int signalIndex; 


@end
