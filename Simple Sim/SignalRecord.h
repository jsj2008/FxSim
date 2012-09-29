//
//  SignalRecord.h
//  Simple Sim
//
//  Created by Martin O'Connor on 18/06/2012.
//  Copyright (c) 2012 OCONNOR RESEARCH. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SignalRecord : NSObject{
    double _signal;
    long _startTime;
    long _endTime;
    double _entryPrice;
    double _exitPrice;
//    double _timeInProfit;
//    double _maxPotentialProfit;
//    double _maxPotentialLoss;
}

//- (id) initWithSignal:(double) signal
//         AndStartTime: (long) startTime
//           AndEndTime: (long) endTime
//        AndEntryPrice: (double) entryPrice
//         AndExitPrice: (double) exitPrice
//      AndTimeInProfit: (double) timeInProfit
//AndMaxPotentialProfit: (double) maxPotentialProfit
//  AndMaxPotentialLoss: (double) maxPotentialLoss;

- (id) initWithSignal:(double) signal
         AndStartTime: (long) startTime
           AndEndTime: (long) endTime
        AndEntryPrice: (double) entryPrice
         AndExitPrice: (double) exitPrice;
//      AndTimeInProfit: (double) timeInProfit
//AndMaxPotentialProfit: (double) maxPotentialProfit
//  AndMaxPotentialLoss: (double) maxPotentialLoss;


@property    double signal;
@property    long   startTime;
@property    long   endTime;
@property    double entryPrice;
@property    double exitPrice;
//@property    double timeInProfit;
//@property    double maxPotentialProfit;
//@property    double maxPotentialLoss;


@end
