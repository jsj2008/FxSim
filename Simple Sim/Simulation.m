//
//  Account.m
//  Simple Sim
//
//  Created by Martin O'Connor on 09/02/2012.
//  Copyright (c) 2012 OCONNOR RESEARCH. All rights reserved.
//

#import "Simulation.h"
#import "EpochTime.h"
#import "UtilityFunctions.h"

@interface Simulation()
//-(void)addBalanceAdjustmentWithAmount: (double) amount
//                              AndDateTime: (long) dateTime;
-(long) dateTimeForBalAdjAtIndex: (NSUInteger) index;
-(long) dateTimeForTradeAtIndex: (NSUInteger) index;
-(int) resultingExposureForTradeAtIndex: (NSUInteger) index;
//
-(double) accBalanceAtDateTime:(long) dateTime;
-(void)addBalanceAdjustmentWithAmount: (double) amount
                          AndDateTime: (long) dateTime
                            AndReason:(BalAdjType) reasonCode;
//-(double)calcInterestForAmount:(int) amount 
//                        From:(long)fromDateTime 
//                          To:(long) tradeDateTime;
//-(int) currentBaseBalance:(long) dateTime;
//-(double) currentQuoteBalance:(long) dateTime;
//-(struct marketTransaction *) getMarketTransactionAtIndex: (NSUInteger) index;
@end

@implementation Simulation

@synthesize name;
@synthesize startDate;
@synthesize endDate;
@synthesize accCode;
@synthesize baseCode;
@synthesize quoteCode;
@synthesize maxLeverage;
@synthesize signalParameters;
@synthesize simulationDataSeries;
@synthesize analysisDataSeries;
@synthesize longPeriods;
@synthesize shortPeriods;
@synthesize dataStartDateTime;
@synthesize samplingRate;
@synthesize tradingLag;
@synthesize tradingDayStart;
@synthesize tradingDayEnd;
@synthesize reportDataFieldsArray;

NSMutableArray *openPositionsArray;

struct balanceAdjustment{
    float amount;
    float resultingBalance;
    long  dateTime;
    int reason;
};

struct marketTransaction{
    int amount;        
    long   dateTime;
    float price;
    int resultingMarketExposure;
    float spread;
    float spreadInAccCurrency;
    long signalDateTime;
    int signalIndex; 
};

struct position{
    int amount;        
    long   dateTime;
    float price;
    long   interestAccruedDateTime;
    double interestAccrued;
};

//This just marks whether the signal is biased long or short
// the amount of time in profit and the max profit
struct signalInfo{
    int signal;
    long startTime;
    long endTime;
    float entryPrice;
    float exitPrice;
    float timeInProfit;
    float maxPotentialProfit;
    float maxPotentialLoss;
};



-(id)initWithName: (NSString *) accountName 
          AndDate:(long) startDateTime 
       AndBalance:(double) startingBalance 
      AndCurrency: (NSString *) ISOcode
   AndTradingPair: (NSString *) codeForTradingPair
      AndMaxLeverage: (float) leverage
{
    self = [super init];
    if(self){
        name = accountName;
        startDate = startDateTime;
        maxLeverage = leverage;
        accBalanceArray = [[NSMutableArray alloc] init];
        tradesArray = [[NSMutableArray alloc] init];
        signalInfoArray= [[NSMutableArray alloc] init]; 
        openPositionsArray = [[NSMutableArray alloc] init];
        reportDataFieldsArray = [[NSMutableArray alloc] init];
        //spreadCrossingCostInBaseCurrency = 0.0;
        currentOpenPositionAmount = 0;
        
        simulationResults = [[NSMutableDictionary alloc] init ];
        
        accCode = ISOcode;
        baseCode = [codeForTradingPair substringToIndex:3];
        quoteCode = [codeForTradingPair substringFromIndex:3];
        if(startingBalance > 0){
            [self addBalanceAdjustmentWithAmount:startingBalance AndDateTime:startDateTime AndReason:TRANSFER];
        }
        reportDataFieldsArray = [NSArray arrayWithObjects:@"NAME", @"TRADINGPAIR",@"ACCOUNTCURRENCY",@"BLANK",@"--RESULTS--", @"CASHTRANSFERS", @"FINALNAV", @"TRADE PNL", @"INTEREST",  @"BIGGESTDRAWDOWN",@"DRAWDOWNTIME",  @"NUMBEROFTRADES", @"SPREADCOST", @"BLANK", @"--PARAMETERS--",@"STARTTIME", @"ENDTIME", @"STRATEGY",@"MAXLEVERAGE", @"TIMESTEP", @"TRADINGLAG",@"TRADINGDAYSTART",@"TRADINGDAYEND", nil]; 
    }
    
    return self;
}

-(void) printAccDetails: (long) dateTime
{
    NSLog(@"This account has a balance of %5.2f in %@",[self currentBalance],[self accCode]);
    NSLog(@"This account started on %@",[[NSDate dateWithTimeIntervalSince1970:[self startDate]]descriptionWithCalendarFormat:@"%a %Y-%m-%d" timeZone:[NSTimeZone timeZoneWithName:@"GMT"] locale:nil]);
    NSLog(@"This account trades %@%@",[self baseCode],[self quoteCode]);
}


-(int) getNumberOfReportDataFields
{
    return [reportDataFieldsArray count];
}

-(NSString *)getReportNameFieldAtIndex:(int) nameFieldIndex
{
    NSString *fieldName = [reportDataFieldsArray objectAtIndex:nameFieldIndex];
    if([fieldName isEqualToString:@"BLANK"]){
        return @"";
    }else{
        return fieldName;
    }
}

-(NSString *)getReportDataFieldAtIndex:(int) dataFieldIndex
{
    NSString *dataFieldIdentifier =  [reportDataFieldsArray objectAtIndex:dataFieldIndex];
    
    if([dataFieldIdentifier isEqualToString:@"BLANK"]){
        return @"";
    }
    if([dataFieldIdentifier isEqualToString:@"--PARAMETERS--"]){
        return @"";
    }
    if([dataFieldIdentifier isEqualToString:@"--RESULTS--"]){
        return @"";
    }
    if([dataFieldIdentifier isEqualToString:@"NAME"]){
        return [self name];
    }
    if([dataFieldIdentifier isEqualToString:@"TRADINGPAIR"]){
        return [NSString stringWithFormat:@"%@%@", [self baseCode], [self quoteCode]];
    }
    if([dataFieldIdentifier isEqualToString:@"ACCOUNTCURRENCY"]){
        return [self accCode];
    }
    
    if([dataFieldIdentifier isEqualToString:@"STARTTIME"]){
        return [EpochTime stringDateWithTime:[self startDate]];
    }
    if([dataFieldIdentifier isEqualToString:@"ENDTIME"]){
        return [EpochTime stringDateWithTime:[self endDate]];
    }
    if([dataFieldIdentifier isEqualToString:@"STRATEGY"]){
        return signalParameters;
    }
    if([dataFieldIdentifier isEqualToString:@"MAXLEVERAGE"]){
        return [NSString stringWithFormat:@"%5.1",maxLeverage];    
    } 
    if([dataFieldIdentifier isEqualToString:@"TIMESTEP"]){
        return [NSString stringWithFormat:@"%d seconds",samplingRate];    
    }
    if([dataFieldIdentifier isEqualToString:@"TRADINGDAYSTART"]){
        return [EpochTime stringOfDateTimeForTime:tradingDayStart WithFormat:@"%H:%M"];    
    }
    if([dataFieldIdentifier isEqualToString:@"TRADINGDAYEND"]){
        return [EpochTime stringOfDateTimeForTime:tradingDayEnd WithFormat:@"%H:%M"];    
    }
    if([dataFieldIdentifier isEqualToString:@"TRADINGLAG"]){
        return [NSString stringWithFormat:@"%d seconds",tradingLag];    
    }
    
    id returnData = [simulationResults objectForKey:dataFieldIdentifier];
    if(returnData != nil){
        if([dataFieldIdentifier isEqualToString:@"DRAWDOWNTIME"]){
            returnData = [EpochTime stringDateWithTime:[returnData longValue]];
        }
        
        if([dataFieldIdentifier isEqualToString:@"PNLUPTIME"] || [dataFieldIdentifier isEqualToString:@"PNLDOWNTIME"]){
            returnData = [NSString stringWithFormat:@"%d hours",[returnData longValue]/(60*60)];
        }
        
        return returnData;
    }
    
    
    return @"Data not found";
}

-(void) clearSimulationResults{
    [simulationResults removeAllObjects];
}

-(void) addObjectToSimulationResults:(id) datum ForKey:(NSString *) key
{
    [simulationResults setObject:datum forKey:key];
}


//-(long) currentDateTime
//{
//    return 10000;
//}

-(void)addCashTransferWithAmount: (double) amount
                     AndDateTime: (long) dateTime
{
    [self addBalanceAdjustmentWithAmount:amount  
                             AndDateTime:dateTime
                               AndReason:TRANSFER];
}

-(void)addBalanceAdjustmentWithAmount: (double) amount
                          AndDateTime: (long) dateTime
                            AndReason:(BalAdjType) reasonCode
{
    struct balanceAdjustment *newBalAdj = malloc(sizeof(struct balanceAdjustment));
    struct balanceAdjustment *oldBalance;
    newBalAdj->amount = amount;
    newBalAdj->dateTime = dateTime;
    newBalAdj->reason = reasonCode;
    if([accBalanceArray count]>0){
        oldBalance = malloc(sizeof(struct balanceAdjustment));
        [[accBalanceArray objectAtIndex:([accBalanceArray count]-1)] getValue:oldBalance];
        newBalAdj->resultingBalance = oldBalance->resultingBalance + amount;
    }else{
        newBalAdj->resultingBalance = amount;
    }
    NSValue *wrappedAsObject = [NSValue valueWithBytes:newBalAdj objCType:@encode(struct balanceAdjustment)];
    [accBalanceArray addObject:wrappedAsObject];
}

-(int)addSignalStatisticsWithSignal:(int) signal
                    AndEntryTime:(long) entryTime
                     AndExitTime:(long) exitTime
                   AndEntryPrice:(float)entryPrice
                    AndExitPrice:(float) exitPrice
                 AndTimeInProfit:(float) timeInProfit
           AndMaxPotentialProfit:(float) potentialProfit
             AndMaxPotentialLoss:(float) potentialLoss
{
    struct signalInfo *newSignalInfoStruct = malloc(sizeof(struct signalInfo));
    newSignalInfoStruct->signal = signal;
    newSignalInfoStruct->startTime = entryTime;
    newSignalInfoStruct->endTime = exitTime;
    newSignalInfoStruct->entryPrice = entryPrice;
    newSignalInfoStruct->exitPrice = exitPrice;
    newSignalInfoStruct->timeInProfit = timeInProfit;
    newSignalInfoStruct->maxPotentialLoss = potentialLoss;
    newSignalInfoStruct->maxPotentialProfit = potentialProfit;
    newSignalInfoStruct->timeInProfit = timeInProfit;
    
    NSValue *wrappedsignalInfo = [NSValue valueWithBytes:newSignalInfoStruct objCType:@encode(struct signalInfo)];
    [signalInfoArray addObject:wrappedsignalInfo];
    
    return [signalInfoArray count] - 1;
}



-(double)currentBalance
{
    struct balanceAdjustment *lastBalance;
    double balance;
    if([accBalanceArray count]>0){
        lastBalance = malloc(sizeof(struct balanceAdjustment));
        [[accBalanceArray objectAtIndex:([accBalanceArray count]-1)] getValue:lastBalance];
        balance = lastBalance->resultingBalance;
    }else{
        balance = 0.0;
    }
    return balance;
}


-(int) currentExposure
{
    long positionIndex = 0;
    struct position *openPosition;
    int currentExposure = 0;
    if([openPositionsArray count]>0)
    {
        while(positionIndex < [openPositionsArray count])
        {
            openPosition = malloc(sizeof(struct position));
            [[openPositionsArray objectAtIndex:positionIndex] getValue:openPosition];
            currentExposure = currentExposure + openPosition->amount;
            positionIndex++;
        }
    }
    return currentExposure;
}

-(double) costOfCurrentExposure
{
    long positionIndex = 0;
    struct position *openPosition;
    int costOfExposure = 0;
    while(positionIndex < [openPositionsArray count])
    {
        openPosition = malloc(sizeof(struct position));
        [[openPositionsArray objectAtIndex:positionIndex] getValue:openPosition];
        costOfExposure = costOfExposure + (openPosition->amount * openPosition->price);
        positionIndex++;
    }
    return costOfExposure;
}

-(void) printPositions
{
    long positionIndex = 0;
    struct position *openPosition;
    while(positionIndex <= [openPositionsArray count])
    {
        openPosition = malloc(sizeof(struct position));
        [[openPositionsArray objectAtIndex:positionIndex] getValue:openPosition];
        NSLog(@"%lu Position %d at price %5.4f" , openPosition->dateTime, openPosition->amount, openPosition->price);
        positionIndex++;
    }
}


-(double) accBalanceAtDateTime:(long) dateTime
{
    
    long balanceIndex =  [accBalanceArray count];
    bool stillSearching = YES;
    //struct marketTransaction *currentTranaction; 
    double currentBalance = 0.0;
    while(stillSearching && balanceIndex >0)
    {
        balanceIndex--;
        struct balanceAdjustment balAdj;
        [[tradesArray objectAtIndex:balanceIndex] getValue:&balAdj];
        if(balAdj.dateTime < dateTime){
            stillSearching = NO;
            currentBalance = balAdj.resultingBalance;
        }
    }
    return currentBalance;
}


-(int) currentBaseBalance:(long) dateTime
{
    long balanceIndex =  [accBalanceArray count];
    bool stillSearching = YES;
    //struct marketTransaction *currentTranaction; 
    int currentBalance = 0;
    while(stillSearching && balanceIndex >0)
    {
        balanceIndex--;
        struct balanceAdjustment balAdj;
        [[tradesArray objectAtIndex:balanceIndex] getValue:&balAdj];
        if(balAdj.dateTime < dateTime){
            stillSearching = NO;
            currentBalance = (int)balAdj.resultingBalance;
        }
    }
    return currentBalance;
}

-(double) currentQuoteBalance:(long) dateTime
{
    long balanceIndex =  [accBalanceArray count];
    bool stillSearching = YES;
    //struct marketTransaction *currentTranaction; 
    double currentBalance = 0.0;
    while(stillSearching && balanceIndex >0)
    {
        balanceIndex--;
        struct balanceAdjustment balAdj;
        [[tradesArray objectAtIndex:balanceIndex] getValue:&balAdj];
        if(balAdj.dateTime < dateTime){
            stillSearching = NO;
            currentBalance = balAdj.resultingBalance;
        }
    }
    return currentBalance;
}

//-(long) numberOfMarketTransactions
//{
//    return [trades count];
//}

//-(double) positionPnlAtPrice:(float) newPrice
//{
//    double positionPnl = 0;
//    struct position *openPosition;
//    for(int iPos = 0;iPos <[openPositions count];iPos++){
//        openPosition = malloc(sizeof(struct position));
//        [[openPositions objectAtIndex:iPos] getValue:openPosition];
//        positionPnl = positionPnl + openPosition->amount * (newPrice - openPosition->price);
//    }
//    return positionPnl;
//}




-(void) addInterestToPosition:(int) positionIndex
                   WithAmount:(int) interestAmount 
                       AtTime:(long) interestDateTime
{
    struct position *openPosition = malloc(sizeof( struct position));
    [[openPositionsArray objectAtIndex:positionIndex] getValue:openPosition];
    openPosition->interestAccrued = openPosition->interestAccrued + interestAmount;
    openPosition->interestAccruedDateTime = interestDateTime;
    [openPositionsArray replaceObjectAtIndex:positionIndex 
                             withObject:[NSValue valueWithBytes:openPosition 
                                                       objCType:@encode(struct position)]];
    [self addBalanceAdjustmentWithAmount:interestAmount 
                             AndDateTime:interestDateTime 
                               AndReason:INTEREST];
}



-(float) addTradeWithAmount:(int) tradeAmount 
                    AtTime: (long) tradeDateTime 
                 WithPrice:(double) tradePrice
       AndAccQuoteBidPrice:(double) accQuoteBidPrice
       AndAccQuoteAskPrice:(double) accQuoteAskPrice
      AndBaseQuoteBidPrice:(double) baseQuoteBidPrice
      AndBaseQuoteAskPrice:(double) baseQuoteAskPrice
            AndSignalIndex:(int) signalIndex
{
    float realisedPnl = 0.0;
    //adjust the positions as nessesary. If there are opposite position these will be closed oldest first
    
    if([openPositionsArray count] == 0 || ([UtilityFunctions signum:[self currentExposure]] == [UtilityFunctions signum:tradeAmount])){
        struct position *newPosition = malloc(sizeof( struct position));
        newPosition->amount = tradeAmount;
        newPosition->price = tradePrice;
        newPosition->dateTime = tradeDateTime;
        newPosition->interestAccruedDateTime = tradeDateTime;
        newPosition->interestAccrued = 0.0;
        [openPositionsArray addObject:[NSValue valueWithBytes:newPosition objCType:@encode(struct position)]];
    }else{
        int tradeRemainder = tradeAmount;
        int positionsToCancel = 0;
        int iPos = 0;
        struct position *openPosition;
        iPos = 0;
        while(iPos < [openPositionsArray count]  && tradeRemainder != 0){
            openPosition = malloc(sizeof(struct position));
            [[openPositionsArray objectAtIndex:iPos] getValue:openPosition];
            
            if([UtilityFunctions signum:openPosition->amount]*[UtilityFunctions signum:tradeAmount] == -1)
            {
                if(abs(openPosition->amount) > abs(tradeAmount)){
                    tradeRemainder = 0;
                    openPosition->amount = openPosition->amount + tradeAmount;
                    [openPositionsArray replaceObjectAtIndex:iPos 
                                             withObject:[NSValue valueWithBytes:openPosition 
                                                                       objCType:@encode(struct position)]];
                    realisedPnl = tradeAmount * (tradePrice - openPosition->price);
                    
                    if(realisedPnl>0){
                        realisedPnl = realisedPnl / accQuoteAskPrice; 
                    }else{
                        realisedPnl = realisedPnl / accQuoteBidPrice; 
                    }
                    //[self addBalaInterestBalAdjForAmount:tradeAmount From:openPosition->dateTime To: tradeDateTime];  
                    [self addBalanceAdjustmentWithAmount:realisedPnl AndDateTime:tradeDateTime AndReason:TRADE_PNL];
                    
                }else{
                    tradeRemainder = tradeRemainder + openPosition->amount;
                    positionsToCancel = positionsToCancel + 1;
                    realisedPnl = openPosition->amount * (tradePrice - openPosition->price);
                    if(realisedPnl>0){
                        realisedPnl = realisedPnl / accQuoteAskPrice; 
                    }else{
                        realisedPnl = realisedPnl / accQuoteBidPrice; 
                    }
                    [self addBalanceAdjustmentWithAmount:realisedPnl AndDateTime:tradeDateTime AndReason:TRADE_PNL];
                }
            }else{
                return NO;
            }
            iPos++;
        }
        if(positionsToCancel >0){
            for(int i = 0; i <positionsToCancel;i++){
                [openPositionsArray removeObjectAtIndex:0];
            }
        }
        if(abs(tradeRemainder)>0){
            struct position *newPosition = malloc(sizeof( struct position));
            newPosition->amount = tradeRemainder;
            newPosition->price = tradePrice;
            newPosition->dateTime = tradeDateTime;
            newPosition->interestAccruedDateTime = tradeDateTime;
            newPosition->interestAccrued = 0.0;
            [openPositionsArray addObject:[NSValue valueWithBytes:newPosition objCType:@encode(struct position)]];
        }
               
    }
    
    //Add the trade
    struct marketTransaction *newTrade = malloc(sizeof( struct marketTransaction));
    newTrade->amount = tradeAmount;
    newTrade->price = tradePrice;
    newTrade->dateTime = tradeDateTime;
    newTrade->resultingMarketExposure = [self currentExposure];
    newTrade->spread = baseQuoteAskPrice-baseQuoteBidPrice;
    if([accCode isEqualToString:quoteCode]){
        newTrade->spreadInAccCurrency = baseQuoteAskPrice-baseQuoteBidPrice;
    }else{
        newTrade->spreadInAccCurrency = (baseQuoteAskPrice-baseQuoteBidPrice)/baseQuoteBidPrice;
    }
    newTrade->signalIndex = signalIndex;
    [tradesArray addObject:[NSValue valueWithBytes:newTrade objCType:@encode(struct marketTransaction)]];

    //spreadCrossingCostInBaseCurrency = spreadCrossingCostInBaseCurrency + 0.5 * abs(tradeAmount) *(1-baseQuoteBidPrice/baseQuoteAskPrice);
    return realisedPnl;
}




//-(double)getMarginAvailableWithBaseQuoteBidPrice: (float) baseQuoteBidPrice  
//                            AndBaseQuoteAskPrice: (float) baseQuoteAskPrice 
//                             AndAccQuoteBidPrice: (float) accQuoteBidPrice
//                             AndAccQuoteAskPrice: (float) accQuoteAskPrice
//{
//    double marginUsed, marginAvailable;
//    double nav;
//    
//    nav = [self getNAVWithBaseQuoteBidPrice: baseQuoteBidPrice  
//                              AndBaseQuoteAskPrice: baseQuoteAskPrice 
//                               AndAccQuoteBidPrice: accQuoteBidPrice
//                               AndAccQuoteAskPrice: accQuoteAskPrice];
//    
//    
//    marginUsed = [self getMarginUsedWithAccBaseBidPrice:accQuoteBidPrice 
//                                     AndAccBaseAskPrice:accQuoteAskPrice];
//    marginAvailable = nav - marginUsed;
//    return marginAvailable;
//}

//-(double)getMarginUsedWithAccBaseBidPrice: (float) accBaseBidPrice
//                             AndAccBaseAskPrice: (float) accBaseAskPrice
//{
//    double marginUsed;
//    int currentExposure;
//    
//    currentExposure = [self currentExposure];
//    
//    if(currentExposure > 0)
//    {
//        marginUsed = ((1/maxLeverage) * ([self currentExposure] / accBaseBidPrice));
//    }else{
//        marginUsed = ((1/maxLeverage) * (abs([self currentExposure]) / accBaseAskPrice));
//    }
//    return marginUsed;
//}

//-(double)getMarginRequiredForExposure: (long) exposure
//                 WithAccBaseBidPrice: (float) accBaseBidPrice
//                  AndAccBaseAskPrice: (float) accBaseAskPrice
//{
//    double marginUsed;
//    if(exposure > 0)
//    {
//        marginUsed = ((1/maxLeverage) * (exposure * accBaseAskPrice));
//    }else{
//        marginUsed = ((1/maxLeverage) * (exposure * accBaseBidPrice));
//    }
//    return marginUsed;
//}

//-(double) getNAVWithBaseQuoteBidPrice: (float) baseQuoteBidPrice  
//                 AndBaseQuoteAskPrice: (float) baseQuoteAskPrice 
//                  AndAccQuoteBidPrice: (float) accQuoteBidPrice
//                  AndAccQuoteAskPrice: (float) accQuoteAskPrice;
//{
//
//    //Account balance and unrealised P&L 
//    double balance = [self currentBalance];
//    double unrealizedPnl;
//    int exposure = [self currentExposure];
//    double costOfExposure = [self costOfCurrentExposure];
//    
//    if(exposure == 0){
//        return balance;
//    }else{
//        if(exposure > 0){
//            unrealizedPnl = (exposure * baseQuoteBidPrice) - costOfExposure;
//        }else{
//            unrealizedPnl = (exposure * baseQuoteAskPrice) - costOfExposure;
//        }
//        unrealizedPnl = unrealizedPnl / baseQuoteAskPrice;
//        if(unrealizedPnl > 0){
//            balance = balance + (unrealizedPnl / accQuoteAskPrice);
//        }else{
//            balance = balance + (unrealizedPnl / accQuoteBidPrice);
//        }
//    }
//    return balance;
//}

-(long) dateTimeForBalAdjAtIndex: (NSUInteger) index
{
    struct balanceAdjustment returnData;
    [[accBalanceArray objectAtIndex:index] getValue:&returnData];
    return returnData.dateTime;
}

-(long) dateTimeForTradeAtIndex: (NSUInteger) index
{
    struct marketTransaction returnData;
    [[tradesArray objectAtIndex:index] getValue:&returnData];
    return returnData.dateTime;
}


-(int) resultingExposureForTradeAtIndex: (NSUInteger) tradeIndex
{
    struct marketTransaction returnData;
    [[tradesArray objectAtIndex:tradeIndex] getValue:&returnData];
    return returnData.resultingMarketExposure;
}

-(int)numberOfPositions
{
    return (int)[openPositionsArray count];
}

-(float)wgtAverageCostOfPosition
{
    float wgtCost = 0.0;
    int positionSize = 0;
    for(int positionIndex = 0; positionIndex < [openPositionsArray count];positionIndex++){
        struct position openPosition;
        [[openPositionsArray objectAtIndex:positionIndex] getValue:&openPosition];
        wgtCost = openPosition.amount * openPosition.price;
        positionSize = positionSize + openPosition.amount; 
    }
    if(positionSize != 0)
    {
        return wgtCost/positionSize;
    }else{
        return 0.0;
    }
}

-(NSDictionary *)detailsOfPositionAtIndex:(int)positionIndex
{
    NSMutableDictionary *positionDetails = [[NSMutableDictionary alloc] init];
    struct position openPosition;
    [[openPositionsArray objectAtIndex:positionIndex] getValue:&openPosition];
    [positionDetails setObject:[NSNumber numberWithInt:openPosition.amount ] forKey:@"AMOUNT"];
    [positionDetails setObject:[NSNumber numberWithLong:openPosition.dateTime ] forKey:@"DATETIME"];
    [positionDetails setObject:[NSNumber numberWithFloat:openPosition.price] forKey:@"PRICE"];
    [positionDetails setObject:[NSNumber numberWithInt:openPosition.interestAccrued] forKey:@"INTERESTACCURED"];
    [positionDetails setObject:[NSNumber numberWithFloat:openPosition.interestAccruedDateTime] forKey:@"INTERESTTIMEDATE"];
    return positionDetails;
    
}



-(int) sizeOfPositionAtIndex:(int) positionIndex{
    struct position *openPosition = malloc(sizeof( struct position));
    [[openPositionsArray objectAtIndex:positionIndex] getValue:openPosition];
    return openPosition->amount;
}

-(long) dateTimeOfPositionAtIndex:(int) positionIndex{
    struct position *openPosition = malloc(sizeof( struct position));
    [[openPositionsArray objectAtIndex:positionIndex] getValue:openPosition];
    return openPosition->dateTime;
}

-(float) entryPriceOfPositionAtIndex:(int) positionIndex{
    struct position *openPosition = malloc(sizeof( struct position));
    [[openPositionsArray objectAtIndex:positionIndex] getValue:openPosition];
    return openPosition->price;
}


-(long) dateTimeOfInterestForPositionAtIndex:(int) positionIndex{
    struct position *openPosition = malloc(sizeof( struct position));
    [[openPositionsArray objectAtIndex:positionIndex] getValue:openPosition];
    return openPosition->interestAccruedDateTime;
}


//-(void) addInterest: (double) InterestAmount ToPositionAtIndex:(int) positionIndex;
//{
//    struct position *openPosition = malloc(sizeof( struct position));
//    [[openPositionsArray objectAtIndex:positionIndex] getValue:openPosition];
//    openPosition->interestAccrued = openPosition->interestAccrued + InterestAmount;
//    [openPositionsArray replaceObjectAtIndex:positionIndex 
//                             withObject:[NSValue valueWithBytes:openPosition 
//                                                       objCType:@encode(struct position)]];
//    
//}

-(long)timeDateOfEarliestPosition
{
    if([openPositionsArray count] >0)
    {
        struct position *openPosition;
        openPosition = malloc(sizeof(struct position));
        [[openPositionsArray objectAtIndex:0] getValue:openPosition];
        
    }
    return 0;
}

-(int)numberOfTrades
{
    return (int)[tradesArray count];
}



-(NSDictionary *)detailsOfTradeAtIndex:(int)tradeIndex
{
    NSMutableDictionary *tradeDetails = [[NSMutableDictionary alloc] init];
    struct marketTransaction trade;
    [[tradesArray objectAtIndex:tradeIndex] getValue:&trade];
    [tradeDetails setObject:[NSNumber numberWithInt:trade.amount ] forKey:@"AMOUNT"];
    [tradeDetails setObject:[NSNumber numberWithLong:trade.dateTime ] forKey:@"DATETIME"];
    [tradeDetails setObject:[NSNumber numberWithFloat:trade.price] forKey:@"PRICE"];
    [tradeDetails setObject:[NSNumber numberWithInt:trade.resultingMarketExposure] forKey:@"ENDEXP"];
    [tradeDetails setObject:[NSNumber numberWithFloat:trade.spread] forKey:@"SPREAD"];
    [tradeDetails setObject:[NSNumber numberWithLong:trade.signalDateTime] forKey:@"SIGDATETIME"]; 
    return tradeDetails;
 }


-(int)getAmountForTradeAtIndex:(int) tradeIndex
{
    struct marketTransaction trade;
    [[tradesArray objectAtIndex:tradeIndex] getValue:&trade];
    return trade.amount;
}

-(long)getDateTimeForTradeAtIndex:(int) tradeIndex
{
    struct marketTransaction trade;
    [[tradesArray objectAtIndex:tradeIndex] getValue:&trade];
    return trade.dateTime;
}

-(float)getPriceForTradeAtIndex:(int) tradeIndex
{
    struct marketTransaction trade;
    [[tradesArray objectAtIndex:tradeIndex] getValue:&trade];
    return trade.price;
}

-(float)getTotalSpreadCostForTradeAtIndex:(int) tradeIndex
{
    struct marketTransaction trade;
    [[tradesArray objectAtIndex:tradeIndex] getValue:&trade];
    return -(trade.spreadInAccCurrency*abs(trade.amount))/2;
}



-(int)getResultingMarketExposureForTradeAtIndex:(int) tradeIndex
{
    struct marketTransaction trade;
    [[tradesArray objectAtIndex:tradeIndex] getValue:&trade];
    return trade.resultingMarketExposure;
}

-(NSString *)getTradeDetailToPrint:(int) tradeIndex;
{
    struct marketTransaction trade;
    NSString *dateTimeString;
    [[tradesArray objectAtIndex:tradeIndex] getValue:&trade];
    dateTimeString = [EpochTime stringDateWithTime:trade.dateTime];
    return [NSString stringWithFormat: @"On %@ Traded %@ %d  at Price %@ %5.2f resulting in exposure %@ %d",
            dateTimeString, baseCode, trade.amount, quoteCode, trade.price, baseCode, trade.resultingMarketExposure];    
}

-(BOOL)writeTradesToFile:(NSURL *) urlOfFile
{
    BOOL allOk = YES;
    NSFileHandle *outFile;
    
    // Create the output file first if necessary
    // Need to remove file: //localhost for some reason
    NSString *filePathString = [urlOfFile path];//[[fileNameAndPath absoluteString] substringFromIndex:16];
    allOk = [[NSFileManager defaultManager] createFileAtPath: filePathString
                                                    contents: nil 
                                                  attributes: nil];
    //[fileNameAndPath absoluteString]
    if(allOk){
        outFile = [NSFileHandle fileHandleForWritingAtPath:filePathString];
        [outFile truncateFileAtOffset:0];
        
        NSString *dateTimeString;
        NSString *lineOfDataAsString;
        struct marketTransaction trade;
        lineOfDataAsString = @"DATETIME, CODE, AMOUNT, PRICE, RESULTING EXPOSURE \r\n";
        [outFile writeData:[lineOfDataAsString dataUsingEncoding:NSUTF8StringEncoding]];
        for(int tradeIndex = 0; tradeIndex < [tradesArray count];tradeIndex++){
            [[tradesArray objectAtIndex:tradeIndex] getValue:&trade];
            dateTimeString = [EpochTime stringDateWithTime:trade.dateTime];
            lineOfDataAsString = [NSString stringWithFormat:@"%@, %@%@, %d, %5.4f, %d", dateTimeString, baseCode, quoteCode, trade.amount, trade.price, trade.resultingMarketExposure];
            lineOfDataAsString = [lineOfDataAsString stringByAppendingFormat:@"\r\n"];
            [outFile writeData:[lineOfDataAsString dataUsingEncoding:NSUTF8StringEncoding]];
        }
        [outFile closeFile];
        
    }
    return allOk;
    
}
-(BOOL)writeBalanceAdjustmentsToFile:(NSURL *) urlOfFile
{
    BOOL allOk = YES;
    NSFileHandle *outFile;
    
    // Create the output file first if necessary
    // Need to remove file: //localhost for some reason
    NSString *filePathString = [urlOfFile path];//[[fileNameAndPath absoluteString] substringFromIndex:16];
    allOk = [[NSFileManager defaultManager] createFileAtPath: filePathString
                                                    contents: nil 
                                                  attributes: nil];
    //[fileNameAndPath absoluteString]
    if(allOk){
        outFile = [NSFileHandle fileHandleForWritingAtPath:filePathString];
        [outFile truncateFileAtOffset:0];
        
        NSString *dateTimeString;
        NSString *lineOfDataAsString;
        NSString *reasonString;
        struct balanceAdjustment balAdj;
        lineOfDataAsString = @"DATETIME, AMOUNT, REASON, RESULTING BALANCE, CODE \r\n";
        [outFile writeData:[lineOfDataAsString dataUsingEncoding:NSUTF8StringEncoding]];
        for(int balAdjIndex = 0; balAdjIndex < [accBalanceArray count];balAdjIndex++){
            [[accBalanceArray objectAtIndex:balAdjIndex] getValue:&balAdj];
            dateTimeString = [EpochTime stringDateWithTime:balAdj.dateTime];
            
            switch(balAdj.reason)
            {
                case TRANSFER:
                    reasonString = [NSString stringWithString:@"TRANSFER"];
                    break;
                case TRADE_PNL:
                    reasonString = [NSString stringWithString:@"TRADE PNL"];
                    break;
                case INTEREST:
                    reasonString = [NSString stringWithString:@"INTEREST"];
                    break;
                default:
                    reasonString = [NSString stringWithString:@"UNKNOWN"];
                    break;
            }   

            lineOfDataAsString = [NSString stringWithFormat:@"%@, %f, %@, %f, %@", dateTimeString, balAdj.amount, reasonString, balAdj.resultingBalance, accCode];
            lineOfDataAsString = [lineOfDataAsString stringByAppendingFormat:@"\r\n"];
            [outFile writeData:[lineOfDataAsString dataUsingEncoding:NSUTF8StringEncoding]];
        }
        [outFile closeFile];
        
    }
    return allOk;
}

//-(double)getSpreadCrossingCostInBaseCurrency;
//{
//    return spreadCrossingCostInBaseCurrency;
//}

//Balance Adjustment Info

-(NSDictionary *)detailsOfBalanceAdjustmentIndex:(int)tradeIndex
{
    NSMutableDictionary *balAdjDetails = [[NSMutableDictionary alloc] init];
    struct balanceAdjustment balAdj;
    [[accBalanceArray objectAtIndex:tradeIndex] getValue:&balAdj];
    
    [balAdjDetails setObject:[NSNumber numberWithLong:balAdj.dateTime] forKey:@"DATETIME"];
    [balAdjDetails setObject:[NSNumber numberWithFloat:balAdj.amount] forKey:@"AMOUNT"];
    
    [balAdjDetails setObject:[NSNumber numberWithFloat:balAdj.resultingBalance] forKey:@"ENDBAL"];
    NSString *reasonString;
    switch(balAdj.reason)
    {
        case TRANSFER:
            reasonString = [NSString stringWithString:@"TRANSFER"];
            break;
        case TRADE_PNL:
            reasonString = [NSString stringWithString:@"TRADE PNL"];
            break;
        case INTEREST:
            reasonString = [NSString stringWithString:@"INTEREST"];
            break;
        default:
            reasonString = [NSString stringWithString:@"UNKNOWN"];
            break;
    }   
           
    [balAdjDetails setObject:reasonString forKey:@"REASON"];
    return balAdjDetails;
}
                        
                              
-(float)getAmountForBalanceAdjustmentAtIndex:(int) balAdjIndex
{
    struct balanceAdjustment balAdj;
    [[accBalanceArray objectAtIndex:balAdjIndex] getValue:&balAdj];
    return balAdj.amount;
}

-(long)getDateTimeForBalanceAdjustmentAtIndex:(int) balAdjIndex
{
    struct balanceAdjustment balAdj;
    [[accBalanceArray objectAtIndex:balAdjIndex] getValue:&balAdj];
    return balAdj.dateTime;
}

-(float)getResultingBalanceForBalanceAdjustmentAtIndex:(int) balAdjIndex
{
    struct balanceAdjustment balAdj;
    [[accBalanceArray objectAtIndex:balAdjIndex] getValue:&balAdj];
    return balAdj.resultingBalance;
}

-(NSString *)getReasonForBalanceAdjustmentAtIndex:(int) balAdjIndex
{
    struct balanceAdjustment balAdj;
    [[accBalanceArray objectAtIndex:balAdjIndex] getValue:&balAdj];
    NSString *reasonString;
    switch(balAdj.reason)
    {
        case TRANSFER:
            reasonString = [NSString stringWithString:@"TRANSFER"];
            break;
        case TRADE_PNL:
            reasonString = [NSString stringWithString:@"TRADE PNL"];
            break;
        case INTEREST:
            reasonString = [NSString stringWithString:@"INTEREST"];
            break;
        default:
            reasonString = [NSString stringWithString:@"UNKNOWN"];
            break;
    }   

    return reasonString;
}

-(BOOL)isTransferBalanceAdjustmentAtIndex:(int) balAdjIndex
{
    struct balanceAdjustment balAdj;
    [[accBalanceArray objectAtIndex:balAdjIndex] getValue:&balAdj];
    if(balAdj.reason == TRANSFER){
        return YES;
    }else{
        return NO;
    }
}

-(int)numberOfBalanceAdjustments
{
    return (int)[accBalanceArray count];
}

-(NSString *)getBalanceDetailToPrint:(int) balAdjIndex;
{
    struct balanceAdjustment newBalAdj; 
    NSString *reason;
    NSString *dateTimeString;
    
    [[accBalanceArray objectAtIndex:balAdjIndex] getValue:&newBalAdj];
    
    switch(newBalAdj.reason){
        case(TRANSFER):
            reason = @"TRANSFER";
            break;
        case(TRADE_PNL):
            reason = @"TRADEPNL";
            break;
        case(INTEREST):
            reason = @"INTEREST";
            break;
        default:
            reason = @"UNKNOWN";
            break;
    }
    dateTimeString = [EpochTime stringDateWithTime:newBalAdj.dateTime];
    
    return [NSString stringWithFormat: @"On %@ the account was adjusted by %@ %5.2f to %5.2f because of %@",dateTimeString, accCode,newBalAdj.amount, newBalAdj.resultingBalance, reason];
}

-(int)numberOfSignals
{
    return [signalInfoArray count];
}

-(NSDictionary *)detailsOfSignalAtIndex:(int)signalInfoIndex
{
    NSMutableDictionary *signalInfoDetails = [[NSMutableDictionary alloc] init];
    struct signalInfo signalInfoStruct;
    [[signalInfoArray objectAtIndex:signalInfoIndex] getValue:&signalInfoStruct];
    [signalInfoDetails setObject:[NSNumber numberWithInt:signalInfoStruct.signal] forKey:@"SIGNAL"];
    [signalInfoDetails setObject:[NSNumber numberWithLong:signalInfoStruct.startTime] forKey:@"ENTRYTIME"];
    [signalInfoDetails setObject:[NSNumber numberWithLong:signalInfoStruct.endTime] forKey:@"EXITTIME"]; 
    [signalInfoDetails setObject:[NSNumber numberWithFloat:signalInfoStruct.entryPrice] forKey:@"ENTRYPRICE"];
    [signalInfoDetails setObject:[NSNumber numberWithFloat:signalInfoStruct.exitPrice] forKey:@"EXITPRICE"];
    [signalInfoDetails setObject:[NSNumber numberWithFloat:signalInfoStruct.maxPotentialLoss] forKey:@"POTLOSS"];
    [signalInfoDetails setObject:[NSNumber numberWithFloat:signalInfoStruct.maxPotentialProfit] forKey:@"POTGAIN"];
    [signalInfoDetails setObject:[NSNumber numberWithFloat:signalInfoStruct.timeInProfit] forKey:@"UPTIME"]; 
    return signalInfoDetails;
}

-(int)getNewSignalForChangeAtIndex:(int) signalChangeIndex
{
    struct signalInfo signalInfoStruct;
    [[signalInfoArray objectAtIndex:signalChangeIndex] getValue:&signalInfoStruct];
    return signalInfoStruct.signal;
}

-(long)getDateTimeStartForSignalChangeAtIndex:(int) signalChangeIndex
{
    struct signalInfo signalInfoStruct;
    [[signalInfoArray objectAtIndex:signalChangeIndex] getValue:&signalInfoStruct];
    return signalInfoStruct.startTime;
}

-(long)getDateTimeEndForSignalChangeAtIndex:(int) signalChangeIndex
{
    struct signalInfo signalInfoStruct;
    [[signalInfoArray objectAtIndex:signalChangeIndex] getValue:&signalInfoStruct];
    return signalInfoStruct.endTime;
}

-(NSDictionary *)getPerformanceAttribution
{
    NSDictionary * perfAttrib = [[NSMutableDictionary alloc] init];
    double transferAmounts = 0.0;
    double tradePnl = 0.0;
    double interestAccrued = 0.0;
    double other = 0.0;
    BOOL unIdentified = NO;
    struct balanceAdjustment *balAdj;
    
    for(int balAdjIndex = 0;balAdjIndex < [accBalanceArray count]; balAdjIndex++)
    {
        balAdj = malloc(sizeof(struct balanceAdjustment));
        [[accBalanceArray objectAtIndex:balAdjIndex] getValue:balAdj];
    
        switch(balAdj->reason){
        case(TRANSFER):
            transferAmounts = transferAmounts + balAdj->amount;
            break;
        case(TRADE_PNL):
            tradePnl = tradePnl + balAdj->amount;
            break;
        case(INTEREST):
            interestAccrued = interestAccrued + balAdj->amount;
            break;
        default:
            other = other + balAdj->amount;
            unIdentified = YES;
            break;
        }
    }
    [perfAttrib  setValue:[NSNumber numberWithDouble:transferAmounts] forKey:@"TRANSFER"];  
    [perfAttrib setValue:[NSNumber numberWithDouble:tradePnl] forKey:@"TRADEPNL"];
    [perfAttrib setValue:[NSNumber numberWithDouble:interestAccrued] forKey:@"INTEREST"];
    if(unIdentified){
        [perfAttrib setValue:[NSNumber numberWithDouble:other] forKey:@"UNKNOWN"];
    }
    return perfAttrib;
}

@end
