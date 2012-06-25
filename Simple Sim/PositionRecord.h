//
//  PositionRecord.h
//  Simple Sim
//
//  Created by Martin O'Connor on 17/06/2012.
//  Copyright (c) 2012 OCONNOR RESEARCH. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface PositionRecord : NSObject{
    int     _amount;        
    long    _dateTime;
    double  _price;
    long    _interestAccruedDateTime;
    double  _interestAccrued;
}

- (id) initWithAmount: (int) amount
          AndDateTime: (long) dateTime
             AndPrice: (double) price
  AndInterestDateTime: (long) interestDateTime
   AndInterestAccrued: (double) interestAccrued;


@property int    amount;        
@property long   dateTime;
@property double price;
@property long   interestAccruedDateTime;
@property double interestAccrued;

@end
