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
@class SignalSystem;

@interface DataController : NSObject{
//    BOOL _connected;
    BOOL _doThreads;
//    BOOL cancelProcedure;
//    BOOL _adhocDataAdded;
//    id _delegate;
//    BOOL _fileDataAdded;
//    NSString *fileDataFileName;
//    NSArray *fileData;
//    DataSeries *_dataSeries;
    
}
@property (retain) NSMutableDictionary *archive;
@property(readonly) BOOL connected;
@property DataSeries *dataSeries;
@property(retain) NSDictionary *fxPairs;
@property(retain) NSDictionary *dataFields;
@property(retain) NSDictionary *minDateTimes;
@property(retain) NSDictionary *maxDateTimes;
@property(retain) NSString *fileDataFileName;
@property(retain) NSArray *fileData;
@property BOOL doThreads;
@property BOOL cancelProcedure;
@property BOOL fileDataAdded;
@property BOOL adhocDataAdded;
@property(retain) NSArray *signalStats;
@property id delegate;


- (id) init;
- (void) setDelegate:(id)del;
- (BOOL) doThreads;
- (void) setDoThreads:(BOOL)doThreadedProcedures;
+ (NSString *) getSignalListAsString;
+ (NSString *) getSeriesListAsString;
- (void) clearDataStore;
- (void) removeDerivedFromDataStore;
- (int) databaseSamplingRate;
- (NSString *) dataStoreCode;
- (long) dataStoreStart;
- (long) dataStoreEnd;
- (BOOL) okToUseDataStoreFrom: (long) startDateTime
                           To: (long) endDateTime
                 WithDataRate: (long) dataRate
                      ForCode: (NSString *) dataCode;
- (NSMutableDictionary *) getDataFromStoreForCode: (long) archiveCode;
- (BOOL) setupDataSeriesForName: (NSString *) dataSeriesName; 
- (long) getMinDateTimeForLoadedData;
- (long) getMaxDateTimeForLoadedData;
- (long) getMinDateTimeForFullData;
- (long) getMaxDateTimeForFullData;
- (NSArray *) getFieldNames;
- (void) setData: (NSArray *) adhocDataToAdd 
        FromFile: (NSString *) filename;


-(BOOL) getDataForStartDateTime: (long) requestedStartDate
                 AndEndDateTime: (long) requestedEndDate
              AndExtraVariables: (NSArray *) extraVariables
                AndSignalSystem: (SignalSystem *) signalSystem
                    AndDataRate: (long) dataRate
                  WithStoreCode: (long) archiveCode
       WithRequestTruncatedFlag: (int *) requestTrucated;

- (long) getMinDataDateTimeForPair:(NSString *) fxPairName;
- (long) getMaxDataDateTimeForPair:(NSString *) fxPairName;
- (NSDictionary *) getValues:(NSArray *) fieldNames 
                AtDateTime: (long) dateTime;
- (NSDictionary *) getValues:(NSArray *) fieldNames 
                  AtDateTime: (long) dateTime 
               WithTicOffset: (long) numberOfTics;

- (NSArray *) getAllInterestRatesForCurrency: (NSString *) currencyCode
                                   AndField: (NSString *) bidOrAsk;
- (DataSeries *) createNewDataSeriesWithXData: (NSMutableData *) dateTimes
                                    AndYData: (NSDictionary *) dataValues 
                               AndSampleRate: (long) newSampleRate;
- (double) getPipsizeForSeriesName: (NSString *) dataSeriesName;
- (long) getDataSeriesLength;

+ (long) getMaxDataLength;



@end
