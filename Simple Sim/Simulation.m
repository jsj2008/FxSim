//
//  Account.m
//  Simple Sim
//
//  Created by Martin O'Connor on 09/02/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "Simulation.h"
#import "EpochTime.h"

@interface Simulation()
//-(void)addBalanceAdjustmentWithAmount: (double) amount
//                              AndDateTime: (long) dateTime;
-(long) dateTimeForBalAdjAtIndex: (NSUInteger) index;
-(long) dateTimeForTradeAtIndex: (NSUInteger) index;
-(int) resultingExposureForTradeAtIndex: (NSUInteger) index;
//
-(double) accBalanceAtDateTime:(long) dateTime;
-(int) signum:(int) n;
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
@synthesize simulationDataSeries;
@synthesize analysisDataSeries;
//@synthesize accountBalance;

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
    long signalDateTime;
};

struct position{
    int amount;        
    long   dateTime;
    float price;
    long   interestAccruedToTimeDate;
    double interestAccrued;
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
        accBalance = [[NSMutableArray alloc] init];
        //baseBalance = [[NSMutableArray alloc] init];
        //quoteBalance = [[NSMutableArray alloc] init];
        trades = [[NSMutableArray alloc] init];
        incidentalCosts = [[NSMutableArray alloc] init];
        openPositions = [[NSMutableArray alloc] init];
        spreadCrossingCostInBaseCurrency = 0.0;
        currentOpenPositionAmount = 0;
        
        //balance = startingBalance;
        accCode = ISOcode;
        baseCode = [codeForTradingPair substringToIndex:3];
        quoteCode = [codeForTradingPair substringFromIndex:3];
        if(startingBalance > 0){
            [self addBalanceAdjustmentWithAmount:startingBalance AndDateTime:startDateTime AndReason:TRANSFER];
        }
//        if(startingBalance > 0){
//            struct balanceAdjustment *newBalAdj = malloc(sizeof(struct balanceAdjustment));
//            newBalAdj->amount = startingBalance;
//            newBalAdj->dateTime = startDateTime;
//            newBalAdj->currentBalance = startingBalance;
//            NSValue *wrappedAsObject = [NSValue valueWithBytes:newBalAdj objCType:@encode(struct balanceAdjustment)];
//            [accBalance addObject:wrappedAsObject];
//        }
    }
    return self;
}

-(void) printAccDetails: (long) dateTime
{
    NSLog(@"This account has a balance of %5.2f in %@",[self currentBalance],[self accCode]);
    NSLog(@"This account started on %@",[[NSDate dateWithTimeIntervalSince1970:[self startDate]]descriptionWithCalendarFormat:@"%a %Y-%m-%d" timeZone:[NSTimeZone timeZoneWithName:@"GMT"] locale:nil]);
    NSLog(@"This account trades %@%@",[self baseCode],[self quoteCode]);
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
    if([accBalance count]>0){
        oldBalance = malloc(sizeof(struct balanceAdjustment));
        [[accBalance objectAtIndex:([accBalance count]-1)] getValue:oldBalance];
        newBalAdj->resultingBalance = oldBalance->resultingBalance + amount;
    }else{
        newBalAdj->resultingBalance = amount;
    }
    NSValue *wrappedAsObject = [NSValue valueWithBytes:newBalAdj objCType:@encode(struct balanceAdjustment)];
    [accBalance addObject:wrappedAsObject];
}

-(double)currentBalance
{
    struct balanceAdjustment *lastBalance;
    double balance;
    if([accBalance count]>0){
        lastBalance = malloc(sizeof(struct balanceAdjustment));
        [[accBalance objectAtIndex:([accBalance count]-1)] getValue:lastBalance];
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
    if([openPositions count]>0)
    {
        while(positionIndex < [openPositions count])
        {
            openPosition = malloc(sizeof(struct position));
            [[openPositions objectAtIndex:positionIndex] getValue:openPosition];
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
    while(positionIndex < [openPositions count])
    {
        openPosition = malloc(sizeof(struct position));
        [[openPositions objectAtIndex:positionIndex] getValue:openPosition];
        costOfExposure = costOfExposure + (openPosition->amount * openPosition->price);
        positionIndex++;
    }
    return costOfExposure;
}

-(void) printPositions
{
    long positionIndex = 0;
    struct position *openPosition;
    while(positionIndex <= [openPositions count])
    {
        openPosition = malloc(sizeof(struct position));
        [[openPositions objectAtIndex:positionIndex] getValue:openPosition];
        NSLog(@"%lu Position %d at price %5.4f" , openPosition->dateTime, openPosition->amount, openPosition->price);
        positionIndex++;
    }
}


-(double) accBalanceAtDateTime:(long) dateTime
{
    
    long balanceIndex =  [accBalance count];
    bool stillSearching = YES;
    //struct marketTransaction *currentTranaction; 
    double currentBalance = 0.0;
    while(stillSearching && balanceIndex >0)
    {
        balanceIndex--;
        struct balanceAdjustment balAdj;
        [[trades objectAtIndex:balanceIndex] getValue:&balAdj];
        if(balAdj.dateTime < dateTime){
            stillSearching = NO;
            currentBalance = balAdj.resultingBalance;
        }
    }
    return currentBalance;
}


-(int) currentBaseBalance:(long) dateTime
{
    long balanceIndex =  [accBalance count];
    bool stillSearching = YES;
    //struct marketTransaction *currentTranaction; 
    int currentBalance = 0;
    while(stillSearching && balanceIndex >0)
    {
        balanceIndex--;
        struct balanceAdjustment balAdj;
        [[trades objectAtIndex:balanceIndex] getValue:&balAdj];
        if(balAdj.dateTime < dateTime){
            stillSearching = NO;
            currentBalance = (int)balAdj.resultingBalance;
        }
    }
    return currentBalance;
}

-(double) currentQuoteBalance:(long) dateTime
{
    long balanceIndex =  [accBalance count];
    bool stillSearching = YES;
    //struct marketTransaction *currentTranaction; 
    double currentBalance = 0.0;
    while(stillSearching && balanceIndex >0)
    {
        balanceIndex--;
        struct balanceAdjustment balAdj;
        [[trades objectAtIndex:balanceIndex] getValue:&balAdj];
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

-(int) signum: (int) n { return (n < 0) ? -1 : (n > 0) ? +1 : 0; };


-(void) addInterestToPosition:(int) positionIndex
                   WithAmount:(int) interestAmount 
                       AtTime:(long) interestDateTime
{
    struct position *openPosition = malloc(sizeof( struct position));
    [[openPositions objectAtIndex:positionIndex] getValue:openPosition];
    openPosition->interestAccrued = openPosition->interestAccrued + interestAmount;
    openPosition->interestAccruedToTimeDate = interestDateTime;
    [openPositions replaceObjectAtIndex:positionIndex 
                             withObject:[NSValue valueWithBytes:openPosition 
                                                       objCType:@encode(struct position)]];
    [self addBalanceAdjustmentWithAmount:interestAmount 
                             AndDateTime:interestDateTime 
                               AndReason:INTEREST];
}



-(BOOL) addTradeWithAmount:(int) tradeAmount 
                    AtTime: (long) tradeDateTime 
                 WithPrice:(double) tradePrice
       AndAccQuoteBidPrice:(double) accQuoteBidPrice
       AndAccQuoteAskPrice:(double) accQuoteAskPrice
      AndBaseQuoteBidPrice:(double) baseQuoteBidPrice
      AndBaseQuoteAskPrice:(double) baseQuoteAskPrice
         AndSignalDateTime:(long) signalDateTime
{
    
    //adjust the positions as nessesary. If there are opposite position these will be closed oldest first
    
    if([openPositions count] == 0 || ([self signum:[self currentExposure]] == [self signum:tradeAmount])){
        struct position *newPosition = malloc(sizeof( struct position));
        newPosition->amount = tradeAmount;
        newPosition->price = tradePrice;
        newPosition->dateTime = tradeDateTime;
        newPosition->interestAccruedToTimeDate = tradeDateTime;
        newPosition->interestAccrued = 0.0;
        [openPositions addObject:[NSValue valueWithBytes:newPosition objCType:@encode(struct position)]];
    }else{
        int tradeRemainder = tradeAmount;
        int positionsToCancel = 0;
        int iPos = 0;
        double realisedPnl;
        struct position *openPosition;
        iPos = 0;
        while(iPos < [openPositions count]  && tradeRemainder != 0){
            openPosition = malloc(sizeof(struct position));
            [[openPositions objectAtIndex:iPos] getValue:openPosition];
            
            if([self signum:openPosition->amount]*[self signum:tradeAmount] == -1)
            {
                if(abs(openPosition->amount) > abs(tradeAmount)){
                    tradeRemainder = 0;
                    openPosition->amount = openPosition->amount + tradeAmount;
                    [openPositions replaceObjectAtIndex:iPos 
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
                [openPositions removeObjectAtIndex:0];
            }
        }
        if(abs(tradeRemainder)>0){
            struct position *newPosition = malloc(sizeof( struct position));
            newPosition->amount = tradeRemainder;
            newPosition->price = tradePrice;
            newPosition->dateTime = tradeDateTime;
            newPosition->interestAccruedToTimeDate = tradeDateTime;
            newPosition->interestAccrued = 0.0;
            [openPositions addObject:[NSValue valueWithBytes:newPosition objCType:@encode(struct position)]];
        }
               
    }
    
    //Add the trade
    struct marketTransaction *newTrade = malloc(sizeof( struct marketTransaction));
    newTrade->amount = tradeAmount;
    newTrade->price = tradePrice;
    newTrade->dateTime = tradeDateTime;
    newTrade->resultingMarketExposure = [self currentExposure];
    newTrade->spread = (1-baseQuoteBidPrice/baseQuoteAskPrice);
    newTrade->signalDateTime = signalDateTime;
    [trades addObject:[NSValue valueWithBytes:newTrade objCType:@encode(struct marketTransaction)]];

    spreadCrossingCostInBaseCurrency = spreadCrossingCostInBaseCurrency + 0.5 * abs(tradeAmount) *(1-baseQuoteBidPrice/baseQuoteAskPrice);
    return YES;
}




-(double)getMarginAvailableWithBaseQuoteBidPrice: (float) baseQuoteBidPrice  
                            AndBaseQuoteAskPrice: (float) baseQuoteAskPrice 
                             AndAccQuoteBidPrice: (float) accQuoteBidPrice
                             AndAccQuoteAskPrice: (float) accQuoteAskPrice
{
    double marginUsed, marginAvailable;
    double nav;
    
    nav = [self getNAVWithBaseQuoteBidPrice: baseQuoteBidPrice  
                              AndBaseQuoteAskPrice: baseQuoteAskPrice 
                               AndAccQuoteBidPrice: accQuoteBidPrice
                               AndAccQuoteAskPrice: accQuoteAskPrice];
    
    
    marginUsed = [self getMarginUsedWithAccBaseBidPrice:accQuoteBidPrice 
                                     AndAccBaseAskPrice:accQuoteAskPrice];
    marginAvailable = nav - marginUsed;
    return marginAvailable;
}

-(double)getMarginUsedWithAccBaseBidPrice: (float) accBaseBidPrice
                             AndAccBaseAskPrice: (float) accBaseAskPrice
{
    double marginUsed;
    int currentExposure;
    
    currentExposure = [self currentExposure];
    
    if(currentExposure > 0)
    {
        marginUsed = ((1/maxLeverage) * ([self currentExposure] / accBaseBidPrice));
    }else{
        marginUsed = ((1/maxLeverage) * (abs([self currentExposure]) / accBaseAskPrice));
    }
    return marginUsed;
}

-(double)getMarginRequiredForExposure: (long) exposure
                 WithAccBaseBidPrice: (float) accBaseBidPrice
                  AndAccBaseAskPrice: (float) accBaseAskPrice
{
    double marginUsed;
    if(exposure > 0)
    {
        marginUsed = ((1/maxLeverage) * (exposure * accBaseAskPrice));
    }else{
        marginUsed = ((1/maxLeverage) * (exposure * accBaseBidPrice));
    }
    return marginUsed;
}

-(double) getNAVWithBaseQuoteBidPrice: (float) baseQuoteBidPrice  
                 AndBaseQuoteAskPrice: (float) baseQuoteAskPrice 
                  AndAccQuoteBidPrice: (float) accQuoteBidPrice
                  AndAccQuoteAskPrice: (float) accQuoteAskPrice;
{

    //Account balance and unrealised P&L 
    double balance = [self currentBalance];
    double unrealizedPnl;
    int exposure = [self currentExposure];
    double costOfExposure = [self costOfCurrentExposure];
    
    if(exposure == 0){
        return balance;
    }else{
        if(exposure > 0){
            unrealizedPnl = (exposure * baseQuoteBidPrice) - costOfExposure;
        }else{
            unrealizedPnl = (exposure * baseQuoteAskPrice) - costOfExposure;
        }
        unrealizedPnl = unrealizedPnl / baseQuoteAskPrice;
        if(unrealizedPnl > 0){
            balance = balance + (unrealizedPnl / accQuoteAskPrice);
        }else{
            balance = balance + (unrealizedPnl / accQuoteBidPrice);
        }
    }
    return balance;
}

-(long) dateTimeForBalAdjAtIndex: (NSUInteger) index
{
    struct balanceAdjustment returnData;
    [[accBalance objectAtIndex:index] getValue:&returnData];
    return returnData.dateTime;
}

-(long) dateTimeForTradeAtIndex: (NSUInteger) index
{
    struct marketTransaction returnData;
    [[trades objectAtIndex:index] getValue:&returnData];
    return returnData.dateTime;
}


-(int) resultingExposureForTradeAtIndex: (NSUInteger) tradeIndex
{
    struct marketTransaction returnData;
    [[trades objectAtIndex:tradeIndex] getValue:&returnData];
    return returnData.resultingMarketExposure;
}

-(int)numberOfPositions
{
    return (int)[openPositions count];
}

-(int) sizeOfPositionAtIndex:(int) positionIndex{
    struct position *openPosition = malloc(sizeof( struct position));
    [[openPositions objectAtIndex:positionIndex] getValue:openPosition];
    return openPosition->amount;
}

-(long) dateTimeOfPositionAtIndex:(int) positionIndex{
    struct position *openPosition = malloc(sizeof( struct position));
    [[openPositions objectAtIndex:positionIndex] getValue:openPosition];
    return openPosition->dateTime;
}

-(float) entryPriceOfPositionAtIndex:(int) positionIndex{
    struct position *openPosition = malloc(sizeof( struct position));
    [[openPositions objectAtIndex:positionIndex] getValue:openPosition];
    return openPosition->price;
}


-(long) dateTimeOfInterestForPositionAtIndex:(int) positionIndex{
    struct position *openPosition = malloc(sizeof( struct position));
    [[openPositions objectAtIndex:positionIndex] getValue:openPosition];
    return openPosition->interestAccruedToTimeDate;
}


-(void) addInterest: (double) InterestAmount ToPositionAtIndex:(int) positionIndex;
{
    struct position *openPosition = malloc(sizeof( struct position));
    [[openPositions objectAtIndex:positionIndex] getValue:openPosition];
    openPosition->interestAccruedToTimeDate = openPosition->interestAccruedToTimeDate + InterestAmount;
    [openPositions replaceObjectAtIndex:positionIndex 
                             withObject:[NSValue valueWithBytes:openPosition 
                                                       objCType:@encode(struct position)]];
    
}





-(long)timeDateOfEarliestPosition
{
    if([openPositions count] >0)
    {
        struct position *openPosition;
        openPosition = malloc(sizeof(struct position));
        [[openPositions objectAtIndex:0] getValue:openPosition];
        
    }
    return 0;
}

-(int)numberOfTrades
{
    return (int)[trades count];
}

-(int)getAmountForTradeAtIndex:(int) tradeIndex
{
    struct marketTransaction trade;
    [[trades objectAtIndex:tradeIndex] getValue:&trade];
    return trade.amount;
}

-(long)getDateTimeForTradeAtIndex:(int) tradeIndex
{
    struct marketTransaction trade;
    [[trades objectAtIndex:tradeIndex] getValue:&trade];
    return trade.dateTime;
}

-(float)getPriceForTradeAtIndex:(int) tradeIndex
{
    struct marketTransaction trade;
    [[trades objectAtIndex:tradeIndex] getValue:&trade];
    return trade.price;
}

//Balance Adjustment Info
-(double)getAmountForBalanceAdjustmentAtIndex:(int) balAdjIndex
{
    struct balanceAdjustment balAdj;
    [[accBalance objectAtIndex:balAdjIndex] getValue:&balAdj];
    return balAdj.amount;
}

-(long)getDateTimeForBalanceAdjustmentAtIndex:(int) balAdjIndex
{
    struct balanceAdjustment balAdj;
    [[accBalance objectAtIndex:balAdjIndex] getValue:&balAdj];
    return balAdj.dateTime;
}


-(NSString *)getTradeDetailToPrint:(int) tradeIndex;
{
    struct marketTransaction trade;
    NSString *dateTimeString;
    [[trades objectAtIndex:tradeIndex] getValue:&trade];
    dateTimeString = [EpochTime stringDateWithTime:trade.dateTime];
    return [NSString stringWithFormat: @"On %@ Traded %@ %d  at Price %@ %5.2f resulting in exposure %@ %d",
            dateTimeString, baseCode, trade.amount, quoteCode, trade.price, baseCode, trade.resultingMarketExposure];    
}

-(int)numberOfBalanceAdjustments
{
    return (int)[accBalance count];
}

-(NSString *)getBalanceDetailToPrint:(int) balAdjIndex;
{
    struct balanceAdjustment newBalAdj; 
    NSString *reason;
    NSString *dateTimeString;
    
    [[accBalance objectAtIndex:balAdjIndex] getValue:&newBalAdj];
    
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

-(NSDictionary *)getPerformanceAttribution
{
    NSDictionary * perfAttrib = [[NSMutableDictionary alloc] init];
    double transferAmounts = 0.0;
    double tradePnl = 0.0;
    double interestAccrued = 0.0;
    double other = 0.0;
    BOOL unIdentified = NO;
    struct balanceAdjustment *balAdj;
    
    for(int balAdjIndex = 0;balAdjIndex < [accBalance count]; balAdjIndex++)
    {
        balAdj = malloc(sizeof(struct balanceAdjustment));
        [[accBalance objectAtIndex:balAdjIndex] getValue:balAdj];
    
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


-(double)getSpreadCrossingCostInBaseCurrency;
{
    return spreadCrossingCostInBaseCurrency;
}
//-(void)applyDailyInterest
//{
//    int exposure = [self currentExposure];
//    
//    if(exposure !=0){
//        if(exposure > 0){
//            
//            //Ask when Broker lends customer money
//            //Bid when Broker holds your money
//            
//            // Borrowed Interest = units * BASE Interest Rate * TIME in Years / Primary Currency
//            // Lent interest = units * Quote Interest rate * TIME in Years / Primary Currency
//            // Total = Borrowed - Lent 
//            
//            
//        }else{
//            // Borrowed Interest = (converted units) * QUOTE interest Rate * TIME in years * QUOTE/Primary Currency
//            // Lent Interest = units * (BASE) interest rate * TIME in years * Base/Primary Currency
//            // Total = Borrowed - Lent 
//            
//        }
//    }
//    
//}

//-(void) printAccTransactions:(Account *) account
//{
//    double tradingBalance = 0;
//    struct marketTransaction transaction;
//    return [NSString stringWithFormat: @"On %lu Traded %d  at Price %f resulting in exposure %d",
//            transaction.dateTime, transaction.amount, transaction.price, transaction.resultingMarketExposure];
//    
//    for(int transactionIndex = 0; transactionIndex < [trades count];transactionIndex++){
//        [[trades objectAtIndex:transactionIndex] getValue:&transaction];
//        
//        tradingBalance = tradingBalance - (transaction.amount*transaction.price);
//        
//        [self sendMessageToUserInterface:[NSString stringWithFormat: @"On %lu Traded %d  at Price %f resulting in exposure %d",
//                                          transaction.dateTime, transaction.amount, transaction.price, transaction.resultingMarketExposure]];
//        NSLog(@"Trading Balance %f", tradingBalance);
//    }
//}




//
//
//-(struct balanceAdjustment) getBalanceAdjustmentAtIndex: (NSUInteger) index
//{
//    struct balanceAdjustment returnData;
//    // Use this code if you wish to check
//    //if (strcmp([wrappedObject objCType],@encode(struct balanceAdjustment))==0)
//    [[balanceAdjustments objectAtIndex:index] getValue:&returnData];
//    return returnData;
//}





@end
