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
//@class PositioningSystem;
//@class RulesSystem;

@interface DataController : NSObject{
    BOOL _connected;
    BOOL doThreads;
    BOOL cancelProcedure;
    BOOL _adhocDataAdded;
    id _delegate;
    
    BOOL _fileDataAdded;
    NSString *fileDataFileName;
    NSArray *fileData;
    DataSeries *_dataSeries;
    
}
@property (retain) NSMutableDictionary *archive;
@property(readonly) BOOL connected;
@property DataSeries *dataSeries;
@property(readonly, retain) NSDictionary *fxPairs;
@property(readonly, retain) NSDictionary *dataFields;
@property(readonly, retain) NSDictionary *minDateTimes;
@property(readonly, retain) NSDictionary *maxDateTimes;
@property(readonly) NSString *fileDataFileName;
@property(readonly) NSArray *fileData;
@property BOOL fileDataAdded;
@property(retain) NSArray *signalStats;
@property id delegate;


- (id) init;
- (void) setDelegate:(id)del;
- (BOOL) doThreads;
- (void) setDoThreads:(BOOL)doThreadedProcedures;
- (BOOL) strategyUnderstood:(NSString *) strategyString;
- (long) leadTimeRequired:(NSString *) strategyString;
- (long) leadTicsRequired:(NSString *) strategyString;
- (BOOL) setupDataSeriesForName: (NSString *) dataSeriesName; 
- (long) getMinDateTimeForLoadedData;
- (long) getMaxDateTimeForLoadedData;
- (long) getMinDateTimeForFullData;
- (long) getMaxDateTimeForFullData;
- (NSArray *) getFieldNames;
- (void) setData: (NSArray *) adhocDataToAdd 
        FromFile: (NSString *) filename;

- (DataSeries *) retrieveDataForStartDateTime: (long) requestedStartDate 
                               AndEndDateTime: (long) requestedEndDate 
                            AndExtraVariables: (NSArray *) extraVariables
                              AndSignalSystem: (SignalSystem *) signalSystem
                              AndSamplingRate: (long) samplingRate
                                  WithSuccess: (int *) successAsInt
                                  AndUpdateUI: (BOOL) doUpdateUI;

-(BOOL) getMoreDataForStartDateTime: (long) requestedStartDate 
                     AndEndDateTime: (long) requestedEndDate
                  AndExtraVariables: (NSArray *) extraVariables
                    AndSignalSystem: (SignalSystem *) signalSystem
             AndReturningStatsArray: (NSMutableArray *) statsArray
              IncludePrecedingTicks: (long) numberOfPrecedingData
           WithRequestTruncatedFlag: (int *) requestTrucated;

- (void) setDataForStartDateTime: (long) requestedStartDate 
                  AndEndDateTime: (long) requestedEndDate 
               AndExtraVariables: (NSArray *) extraVariables
                 AndSignalSystem: (SignalSystem *) signalSystem
                 AndSamplingRate: (long) samplingRate
                     WithSuccess: (int *) successAsInt
                     AndUpdateUI: (BOOL) doUpdateUI;

- (int) dataGranularity;
- (long) getMinDataDateTimeForPair:(NSString *) fxPairName;
- (long) getMaxDataDateTimeForPair:(NSString *) fxPairName;
- (NSDictionary *) getValues:(NSArray *) fieldNames 
                AtDateTime: (long) dateTime;
- (NSDictionary *) getValues:(NSArray *) fieldNames 
                  AtDateTime: (long) dateTime 
               WithTicOffset: (long) numberOfTics;
- (DataSeriesValue *) valueFromDataBaseForFxPair: (NSString *) name 
                                     AndDateTime: (long) dateTime 
                                        AndField: (NSString *) field;
-(NSArray *) getAllInterestRatesForCurrency: (NSString *) currencyCode 
                                   AndField: (NSString *) bidOrAsk;
-(DataSeries *) createNewDataSeriesWithXData: (NSMutableData *) dateTimes 
                                    AndYData: (NSDictionary *) dataValues 
                               AndSampleRate: (long) newSampleRate;

-(long) getDataSeriesLength;

+ (long) getMaxDataLength;

@end
