//
//  CashFlowRecord.h
//  Simple Sim
//
//  Created by Martin O'Connor on 17/06/2012.
//  Copyright (c) 2012 OCONNOR RESEARCH. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CashFlowRecord : NSObject<NSCoding>{
//    double _amount;
//    double _resultingBalance;
//    long  _dateTime;
//    int _reason;    
}

- (id) initWithAmount: (double) amount
  AndResultingBalance: (double) resultingBalance
          AndDateTime: (long) datetime
            AndReason: (int) reason;

- (void) encodeWithCoder:(NSCoder*)encoder;
- (id) initWithCoder:(NSCoder*)decoder;

- (NSString *)description;

@property (readonly) double amount;
@property (readonly) double resultingBalance;
@property (readonly) long  dateTime;
@property (readonly) int reason;

@end
