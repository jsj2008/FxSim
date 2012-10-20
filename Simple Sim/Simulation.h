//
//  Simulation.h
//  Simple Sim
//
//  Created by Martin O'Connor on 09/02/2012.
//  Copyright (c) 2012 OCONNOR RESEARCH. All rights reserved.
//

#import <Foundation/Foundation.h>
@class DataSeries;
@class PositioningSystem;
@class SignalSystem;
@class BasicParameters;

@interface Simulation : NSObject<NSCoding>{
    NSMutableArray *_accBalanceArray;
    NSMutableArray *_tradesArray;
    NSMutableArray *_signalInfoArray;
    NSMutableDictionary *_simulationResults;
    NSMutableArray *_openPositionsArray;
    NSString *_userAddedData;
    DataSeries *_simulationDataSeries;
    DataSeries *_analysisDataSeries;
    long _dataStartDateTime;
    NSArray* _reportDataFieldsArray;
    BasicParameters *_basicParameters;
    PositioningSystem *_positionSystem;
    SignalSystem *_signalSystem;
    NSMutableArray *_rulesSystem;
    BOOL _isAnalysed;
    
    NSTextStorage *_simulationRunOutput;
}

@property (retain) NSMutableArray *accBalanceArray;
@property (retain) NSMutableArray *tradesArray;
@property (retain) NSMutableArray *signalInfoArray;
@property (readonly) NSMutableDictionary *simulationResults;
@property (retain) NSMutableArray *openPositionsArray;
@property (retain) NSString *userAddedData;
@property (retain) DataSeries *simulationDataSeries;
@property (retain) DataSeries *analysisDataSeries;
@property long dataStartDateTime;
@property (retain) NSArray *reportDataFieldsArray;
@property (readonly) BasicParameters *basicParameters;
@property (retain) PositioningSystem *positionSystem;
@property (retain) SignalSystem *signalSystem;
@property (readonly) NSMutableArray *rulesSystem;
@property BOOL isAnalysed;
@property (retain) NSTextStorage *simulationRunOutput;

typedef enum {
    TRANSFER = 1,
    TRADE_PNL = 2,
    INTEREST = 3
} BalAdjType;

-(id)  initWithName: (NSString *) accountName 
       AndStartDate: (long) accStartDate 
         AndEndDate: (long) accEndDate
         AndBalance: (double) startingBalance 
        AndCurrency: (NSString *) ISOcode
     AndTradingPair: (NSString *) codeForTradingPair
     AndMaxLeverage: (double) maxLeverage
    AndSamplingRate: (NSUInteger)dataSamplingRate
      AndTradingLag: (NSUInteger) signalToTradeLag
AndTradingTimeStart: (int) tradingTimeStart
  AndTradingTimeEnd: (int) tradingTimeEnd;




+ (NSArray *) getReportFields;
- (int)    currentExposure;
- (double) currentBalance;
- (NSString *) name;
- (NSString *) accCode;
- (NSString *) baseCode;
- (NSString *) quoteCode;
- (NSUInteger) tradingLag;
- (NSUInteger) numberOfPositions;
- (float) maxLeverage;
- (long) startDate;
- (long) endDate;
- (NSUInteger) tradingDayStart;
- (NSUInteger) tradingDayEnd;
- (NSUInteger) samplingRate;

- (int) sizeOfPositionAtIndex:(int) positionIndex;

- (long) dateTimeOfInterestForPositionAtIndex:(int) positionIndex;
- (double) entryPriceOfPositionAtIndex:(int) positionIndex;


- (double) addTradeWithAmount: (int) tradeAmount 
                       AtTime: (long) tradeDateTime 
                    WithPrice: (double) tradePrice
          AndAccQuoteBidPrice: (double) accQuoteBidPrice
          AndAccQuoteAskPrice: (double) accQuoteAskPrice
         AndBaseQuoteBidPrice: (double) baseQuoteBidPrice
         AndBaseQuoteAskPrice: (double) baseQuoteAskPrice
                AndSignalTime: (long) timeOfSignal;

- (void) addInterestToPosition:(int) positionIndex
                   WithAmount:(int) interestAmount 
                       AtTime:(long) interestDateTime;

- (BOOL) addTradingRules: (NSString *) ruleString;
- (NSUInteger) addSignalStatisticsWithSignal: (double) signal
                                AndEntryTime: (long) entryTime
                                 AndExitTime: (long) exitTime
                               AndEntryPrice: (double)entryPrice
                                AndExitPrice: (double) exitPrice;




- (long) timeDateOfEarliestPosition;
- (double) wgtAverageCostOfPosition;

- (NSString *) getBalanceDetailToPrint:(int) balAdjIndex;
- (NSDictionary *) getPerformanceAttribution;

- (NSUInteger) numberOfTrades;
- (NSDictionary *) detailsOfTradeAtIndex:(NSUInteger)tradeIndex;
- (NSString *) getTradeDetailToPrint:(NSUInteger) tradeIndex;
- (int) getAmountForTradeAtIndex:(NSUInteger) tradeIndex;
- (long) getDateTimeForTradeAtIndex:(NSUInteger) tradeIndex;
- (double) getPriceForTradeAtIndex:(NSUInteger) tradeIndex;
- (int) getResultingMarketExposureForTradeAtIndex:(NSUInteger) tradeIndex;
//- (double) getTotalSpreadCostForTradeAtIndex:(int) tradeIndex;
- (BOOL) writeTradesToFile:(NSURL *) urlOfFile;

- (int) numberOfBalanceAdjustments;
- (NSDictionary *) detailsOfBalanceAdjustmentIndex:(NSUInteger)tradeIndex;
- (double) getAmountForBalanceAdjustmentAtIndex:(NSUInteger) balAdjIndex;
- (long) getDateTimeForBalanceAdjustmentAtIndex:(NSUInteger) balAdjIndex;
- (NSString *) getReasonForBalanceAdjustmentAtIndex:(NSUInteger) balAdjIndex;
- (double) getResultingBalanceForBalanceAdjustmentAtIndex:(NSUInteger) balAdjIndex;
- (BOOL) writeBalanceAdjustmentsToFile:(NSURL *) urlOfFile;

- (NSUInteger) numberOfSignals;
- (NSDictionary *) detailsOfSignalAtIndex:(NSUInteger)signalInfoIndex;
//- (BOOL) isTransferBalanceAdjustmentAtIndex:(int) balAdjIndex;

//- (void) clearSimulationResults;
- (void) addObjectToSimulationResults:(id) datum ForKey:(NSString *) key;

-(NSUInteger) getNumberOfReportDataFields;
-(NSString *) getReportNameFieldAtIndex: (NSUInteger) nameFieldIndex;
-(NSString *) getReportDataFieldAtIndex: (NSUInteger) dataFieldIndex;

- (void) encodeWithCoder:(NSCoder *)aCoder;
- (id) initWithCoder:(NSCoder *)aDecoder;

@end
