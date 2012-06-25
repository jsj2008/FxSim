//
//  Simulation.h
//  Simple Sim
//
//  Created by Martin O'Connor on 09/02/2012.
//  Copyright (c) 2012 OCONNOR RESEARCH. All rights reserved.
//

#import <Foundation/Foundation.h>
@class DataSeries;

@interface Simulation : NSObject{
    NSMutableArray *accBalanceArray;
    NSMutableArray *tradesArray;
    
    NSMutableArray *signalInfoArray;
    NSMutableDictionary *simulationResults;
    NSMutableArray *openPositionsArray;
    int currentOpenPositionAmount;
    int tradingDayStartHour;
}

@property (readonly, retain) NSString *name;
@property (readonly, retain) NSString *accCode;
@property (readonly, retain) NSString *baseCode;
@property (readonly, retain) NSString *quoteCode;
@property (readonly) float maxLeverage;
@property int samplingRate;
@property int tradingLag;
@property int tradingDayStart;
@property int tradingDayEnd;
@property (retain) NSString *signalParameters;
@property (retain) NSString *positioningType;
@property (retain) NSString *userAddedData;
@property (retain) DataSeries *simulationDataSeries;
@property (retain) DataSeries *analysisDataSeries;
@property (retain) NSArray *longPeriods;
@property (retain) NSArray *shortPeriods;
@property long dataStartDateTime;
@property (retain) NSMutableArray* reportDataFieldsArray;
@property long startDate;
@property long endDate;

typedef enum {
    TRANSFER = 1,
    TRADE_PNL = 2,
    INTEREST = 3
} BalAdjType;

-(id)initWithName: (NSString *) accountName 
          AndDate: (long) accStartDate 
       AndBalance: (double) startingBalance 
      AndCurrency: (NSString *) ISOcode
   AndTradingPair: (NSString *) codeForTradingPair
    AndMaxLeverage: (double) maxLeverage;


-(int)    currentExposure;
//-(double) costOfCurrentExposure;
-(double) currentBalance;

-(int) numberOfPositions;
-(int) sizeOfPositionAtIndex:(int) positionIndex;
-(long) dateTimeOfPositionAtIndex:(int) positionIndex;
-(long) dateTimeOfInterestForPositionAtIndex:(int) positionIndex;
-(double) entryPriceOfPositionAtIndex:(int) positionIndex;
-(void) addCashTransferWithAmount: (double) amount
                     AndDateTime: (long) dateTime;

-(double) addTradeWithAmount: (int) tradeAmount 
                      AtTime: (long) tradeDateTime 
                   WithPrice: (double) tradePrice
         AndAccQuoteBidPrice: (double) accQuoteBidPrice
         AndAccQuoteAskPrice: (double) accQuoteAskPrice
        AndBaseQuoteBidPrice: (double) baseQuoteBidPrice
        AndBaseQuoteAskPrice: (double) baseQuoteAskPrice
              AndSignalIndex: (int) signalIndex;

-(void) addInterestToPosition:(int) positionIndex
                   WithAmount:(int) interestAmount 
                       AtTime:(long) interestDateTime;


-(int)addSignalStatisticsWithSignal: (double) signal
                       AndEntryTime: (long) entryTime
                        AndExitTime: (long) exitTime
                      AndEntryPrice: (double)entryPrice
                       AndExitPrice: (double) exitPrice
                    AndTimeInProfit: (double) timeInProfit
              AndMaxPotentialProfit: (double) potentialProfit
                AndMaxPotentialLoss: (double) potentialLoss;

-(int)getNewSignalForChangeAtIndex:(int) signalChangeIndex;
-(long)getDateTimeStartForSignalChangeAtIndex:(int) signalChangeIndex;
-(long)getDateTimeEndForSignalChangeAtIndex:(int) signalChangeIndex;

-(int)numberOfPositions;
-(long)timeDateOfEarliestPosition;
-(double) wgtAverageCostOfPosition;

-(NSString *)getBalanceDetailToPrint:(int) balAdjIndex;
-(NSDictionary *)getPerformanceAttribution;

-(int) numberOfTrades;
-(NSDictionary *) detailsOfTradeAtIndex:(int)tradeIndex;
-(NSString *) getTradeDetailToPrint:(int) tradeIndex;
-(int) getAmountForTradeAtIndex:(int) tradeIndex;
-(long) getDateTimeForTradeAtIndex:(int) tradeIndex;
-(double) getPriceForTradeAtIndex:(int) tradeIndex;
-(int) getResultingMarketExposureForTradeAtIndex:(int) tradeIndex;
-(double) getTotalSpreadCostForTradeAtIndex:(int) tradeIndex;
-(BOOL) writeTradesToFile:(NSURL *) urlOfFile;


-(int) numberOfBalanceAdjustments;
-(NSDictionary *) detailsOfBalanceAdjustmentIndex:(int)tradeIndex;
-(double) getAmountForBalanceAdjustmentAtIndex:(int) balAdjIndex;
-(long) getDateTimeForBalanceAdjustmentAtIndex:(int) balAdjIndex;
-(NSString *) getReasonForBalanceAdjustmentAtIndex:(int) balAdjIndex;
-(double) getResultingBalanceForBalanceAdjustmentAtIndex:(int) balAdjIndex;
-(BOOL) writeBalanceAdjustmentsToFile:(NSURL *) urlOfFile;

-(int) numberOfSignals;
-(NSDictionary *)detailsOfSignalAtIndex:(int)signalInfoIndex;
-(BOOL) isTransferBalanceAdjustmentAtIndex:(int) balAdjIndex;

-(void) clearSimulationResults;
-(void) addObjectToSimulationResults:(id) datum ForKey:(NSString *) key;

-(int) getNumberOfReportDataFields;
-(NSString *) getReportNameFieldAtIndex:(int) nameFieldIndex;
-(NSString *) getReportDataFieldAtIndex:(int) dataFieldIndex;

@end
