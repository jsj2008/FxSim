//
//  DataController.h
//  Simple Sim
//
//  Created by Martin O'Connor on 14/01/2012.
//  Copyright (c) 2012 OCR. All rights reserved.
//

#import <Foundation/Foundation.h>
@class DataSeries;
@class DataSeriesValue;

@interface DataController : NSObject{
    BOOL connected;
    DataSeries *currentData;
}
@property(readonly, assign) BOOL connected;
@property(readonly) DataSeries *currentData;
@property(readonly, retain)   NSDictionary *fxPairs;
@property(readonly, retain)   NSDictionary *dataFields;
@property(readonly, retain)   NSDictionary *minDateTimes;
@property(readonly, retain)   NSDictionary *maxDateTimes;



-(id)init;
//
-(bool)setupDataSeriesForName: (NSString *) dataSeriesName;
-(long)getMinDateTimeForLoadedData;
-(long)getMaxDateTimeForLoadedData;

-(bool)setBidAskMidForStartDateTime: (long) newStart 
                     AndEndDateTime: (long) newEnd;
//
-(void)addEWMAWithParameter: (int) param;
-(int)dataGranularity;
//
//
-(long)getMinDataDateTimeForPair:(NSString *) fxPairName;
//
-(long)getMaxDataDateTimeForPair:(NSString *) fxPairName;
//
-(NSDictionary *)getValuesForFields:(NSArray *) fieldNames AtDateTime: (long) dateTime;
-(DataSeriesValue *) valueFromDataBaseForFxPair: (NSString *) name 
                                    AndDateTime: (long) dateTime 
                                       AndField: (NSString *) field;

-(NSArray *) getAllInterestRatesForCurrency: (NSString *) currencyCode 
                                   AndField: (NSString *) bidOrAsk;

-(DataSeries *)newDataSeriesWithXData:(NSMutableData *) dateTimes 
                             AndYData:(NSDictionary *) dataValues 
                        AndSampleRate:(int)newSampleRate;
@end
