//
//  DataController.h
//  Simple Sim
//
//  Created by Martin O'Connor on 14/01/2012.
//  Copyright (c) 2012 OCONNOR RESEARCH. All rights reserved.
//

#import <Foundation/Foundation.h>
@class DataSeries;
@class DataSeriesValue;

@interface DataController : NSObject{
    BOOL connected;
    BOOL doThreads;
    BOOL cancelProcedure;
    BOOL adhocDataAdded;
    id delegate;
    
    BOOL _fileDataAdded;
    NSString *fileDataFileName;
    NSArray *fileData;
    //NSArray *fileDataFieldNames;
    //long *fileDataDateTimes;
    //double **fileDataValues;
}
@property(readonly) BOOL connected;
@property(readonly) DataSeries *dataSeries;
@property(readonly, retain) NSDictionary *fxPairs;
@property(readonly, retain) NSDictionary *dataFields;
@property(readonly, retain) NSDictionary *minDateTimes;
@property(readonly, retain) NSDictionary *maxDateTimes;
@property(readonly) NSString *fileDataFileName;
@property(readonly) NSArray *fileData;
@property BOOL fileDataAdded;


@property(retain) NSArray *signalStats;


- (id) init;
- (void) setDelegate:(id)del;
- (BOOL) doThreads;
- (void) setDoThreads:(BOOL)doThreadedProcedures;
- (BOOL) strategyUnderstood:(NSString *) strategyString;
- (BOOL) setupDataSeriesForName: (NSString *) dataSeriesName 
                  AndStrategy: (NSString *) strategyString;
- (long) getMinDateTimeForLoadedData;
- (long) getMaxDateTimeForLoadedData;
- (long) getMinDateTimeForFullData;
- (long) getMaxDateTimeForFullData;
- (NSArray *) getFieldNames;
- (void) setData: (NSArray *) adhocDataToAdd 
        FromFile: (NSString *) filename;
//- (void) addUserData:(NSArray *) userData WithFileName:(NSString *) userDataFileName;


- (DataSeries *) retrieveDataForStartDateTime: (long)requestedStartDate 
                               AndEndDateTime: (long)requestedEndDate 
                              AndSamplingRate: (long)samplingRate
                                  WithSuccess: (int *)successAsInt
                                  AndUpdateUI: (BOOL)doUpdateUI;

- (BOOL) getMoreDataForStartDateTime: (long) newStart 
                      AndEndDateTime: (long) newEnd
              AndReturningStatsArray: (NSMutableArray *) statsArray
            WithRequestTruncatedFlag: (int *) requestTrucated;


- (void) setDataForStartDateTime: (long)requestedStartDate 
                  AndEndDateTime: (long)requestedEndDate 
                 AndSamplingRate: (long)samplingRate
                     WithSuccess: (int *)successAsInt
                     AndUpdateUI: (BOOL) doUpdateUI;

- (int) dataGranularity;

- (long) getMinDataDateTimeForPair:(NSString *) fxPairName;
- (long) getMaxDataDateTimeForPair:(NSString *) fxPairName;
- (NSDictionary *) getValuesForFields:(NSArray *) fieldNames 
                           AtDateTime: (long) dateTime;
- (DataSeriesValue *) valueFromDataBaseForFxPair: (NSString *) name 
                                     AndDateTime: (long) dateTime 
                                        AndField: (NSString *) field;

-(NSArray *) getAllInterestRatesForCurrency: (NSString *) currencyCode 
                                   AndField: (NSString *) bidOrAsk;

-(DataSeries *) createNewDataSeriesWithXData: (NSMutableData *) dateTimes 
                                    AndYData: (NSDictionary *) dataValues 
                               AndSampleRate: (long) newSampleRate;

-(long) getDataSeriesLength;

@end
