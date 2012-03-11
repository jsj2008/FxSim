//
//  Simulation.h
//  Simple Sim
//
//  Created by Martin O'Connor on 09/02/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
@class DataSeries;

@interface Simulation : NSObject{
    NSMutableArray *accBalance;
    NSMutableArray *trades;
    NSMutableArray *openPositions;
    int currentOpenPositionAmount;
    NSMutableArray *incidentalCosts;
    double spreadCrossingCostInBaseCurrency;
    //DataSeries *simulationDataSeries;
    //DataSeries *analysisDataSeries;
    //int leverage;
    //double marginUsed;
}

@property (readonly, retain) NSString *name;
@property (readonly, retain) NSString *accCode;
@property (readonly, retain) NSString *baseCode;
@property (readonly, retain) NSString *quoteCode;
@property (readonly) float maxLeverage;
@property (retain) DataSeries *simulationDataSeries;
@property (retain) DataSeries *analysisDataSeries;
//@property (readonly) double accountBalance;

@property long startDate;
@property long endDate;

typedef enum {
    TRANSFER = 1,
    TRADE_PNL = 2,
    INTEREST = 3
} BalAdjType;



-(id)initWithName: (NSString *) accountName 
          AndDate:(long) accStartDate 
       AndBalance:(double) startingBalance 
      AndCurrency: (NSString *) ISOcode
   AndTradingPair: (NSString *) codeForTradingPair
      AndMaxLeverage: (float) maxLeverage;


////-(struct balanceAdjustment) getBalanceAdjustmentAtIndex: (NSUInteger) index;

-(int)    currentExposure;
-(double) costOfCurrentExposure;
-(double) currentBalance;

-(int) numberOfPositions;
-(int) sizeOfPositionAtIndex:(int) positionIndex;
-(long) dateTimeOfPositionAtIndex:(int) positionIndex;
//-(void) addInterestToPositionAtIndex:(int) positionIndex;
-(long) dateTimeOfInterestForPositionAtIndex:(int) positionIndex;
-(float) entryPriceOfPositionAtIndex:(int) positionIndex;
-(void)addCashTransferWithAmount: (double) amount
                     AndDateTime: (long) dateTime;

-(BOOL) addTradeWithAmount:(int) tradeAmount 
                    AtTime: (long) tradeDateTime 
                 WithPrice:(double) tradePrice
       AndAccQuoteBidPrice:(double) accQuoteBidPrice
       AndAccQuoteAskPrice:(double) accQuoteAskPrice
      AndBaseQuoteBidPrice:(double) baseQuoteBidPrice
      AndBaseQuoteAskPrice:(double) baseQuoteAskPrice
         AndSignalDateTime:(long) signalDateTime;

-(void) addInterestToPosition:(int) positionIndex
                   WithAmount:(int) interestAmount 
                       AtTime:(long) interestDateTime;



////-(bool) closeExposureAtTimeDate:(long) timeDate;

-(double) getNAVWithBaseQuoteBidPrice: (float) baseQuoteBidPrice  
      AndBaseQuoteAskPrice: (float) baseQuoteAskPrice 
       AndAccQuoteBidPrice: (float) accQuoteBidPrice
       AndAccQuoteAskPrice: (float) accQuoteAskPrice;

-(double)getMarginAvailableWithBaseQuoteBidPrice: (float) baseQuoteBidPrice  
                            AndBaseQuoteAskPrice: (float) baseQuoteAskPrice 
                             AndAccQuoteBidPrice: (float) accQuoteBidPrice
                             AndAccQuoteAskPrice: (float) accQuoteAskPrice;

-(double)getMarginUsedWithAccBaseBidPrice: (float) accBaseBidPrice
                       AndAccBaseAskPrice: (float) accBaseAskPrice;


-(double)getMarginRequiredForExposure: (long) exposure
                  WithAccBaseBidPrice: (float) accBaseBidPrice
                   AndAccBaseAskPrice: (float) accBaseAskPrice;

-(int)numberOfPositions;
-(long)timeDateOfEarliestPosition;
-(int)numberOfTrades;
-(NSString *)getTradeDetailToPrint:(int) tradeIndex;
-(int)numberOfBalanceAdjustments;
-(NSString *)getBalanceDetailToPrint:(int) balAdjIndex;
-(NSDictionary *)getPerformanceAttribution;
-(double)getSpreadCrossingCostInBaseCurrency;

-(int)getAmountForTradeAtIndex:(int) tradeIndex;
-(long)getDateTimeForTradeAtIndex:(int) tradeIndex;
-(float)getPriceForTradeAtIndex:(int) tradeIndex;

-(double)getAmountForBalanceAdjustmentAtIndex:(int) balAdjIndex;
-(long)getDateTimeForBalanceAdjustmentAtIndex:(int) balAdjIndex;


//-(void) printAccDetails: (long) dateTime;
//-(long) currentDateTime;
//-(void) printLatestAccDetails;
//-(void) printAccTransactions;
@end
