//
//  TimeSeriesValue.h
//  Simple Sim
//
//  Created by Martin O'Connor on 18/02/2012.
//  Copyright (c) 2015 MARTIN OCONNOR. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface DataSeriesValue : NSObject
@property long dateTime;
@property double value; 
@property (retain) NSString *fieldName;
@end
