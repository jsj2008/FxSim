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
#import "PositionRecord.h"
#import "TransactionRecord.h"
#import "CashFlowRecord.h"
#import "SignalRecord.h"
#import "PositioningSystem.h"
#import "SignalSystem.h"
#import "RulesSystem.h"
#import "BasicParameters.h"

@interface Simulation()
- (void) addBalanceAdjustmentWithAmount: (double) amount
                            AndDateTime: (long) dateTime
                              AndReason: (BalAdjType) reasonCode;
@end

@implementation Simulation

-(id)  initWithName: (NSString *) accountName 
       AndStartDate: (long) accStartDate 
         AndEndDate: (long) accEndDate
         AndBalance: (double) startingBalance 
        AndCurrency: (NSString *) ISOcode
     AndTradingPair: (NSString *) codeForTradingPair
     AndMaxLeverage: (double) maxLeverage
        AndDataRate: (long) dataRate
    AndSamplingRate: (NSUInteger) dataSamplingRate
      AndTradingLag: (NSUInteger) signalToTradeLag
AndTradingTimeStart: (int) tradingTimeStart
  AndTradingTimeEnd: (int) tradingTimeEnd
  AndWeekendTrading: (BOOL) weekendTrading
      AndWarmupTime: (long) warmupTime;
{
    self = [super init];
    if(self){
        _basicParameters = [[BasicParameters alloc] initWithName: accountName 
                                                      AndAccCode: ISOcode
                                                     AndBaseCode: [codeForTradingPair substringToIndex:3]
                                                    AndQuoteCode: [codeForTradingPair substringFromIndex:3]
                                                    AndStartDate: accStartDate
                                                      AndEndDate: accEndDate
                                                     AndDataRate: dataRate
                                                  AndMaxLeverage: maxLeverage
                                                 AndSamplingRate: dataSamplingRate
                                                   AndTradingLag: signalToTradeLag
                                              AndTradingDayStart: tradingTimeStart
                                                AndTradingDayEnd: tradingTimeEnd
                                               AndWeekendTrading: weekendTrading
                                                   AndWarmupTime: warmupTime];
        
        _accBalanceArray = [[NSMutableArray alloc] init];
        _tradesArray = [[NSMutableArray alloc] init];
        _signalInfoArray= [[NSMutableArray alloc] init]; 
        _openPositionsArray = [[NSMutableArray alloc] init];

        _rulesSystem = [[NSMutableArray alloc] init];
        _simulationResults = [[NSMutableDictionary alloc] init ];
        
        _simulationRunOutput = [[NSTextStorage alloc] init];
        
        _userAddedData = @"None";
        
        if(startingBalance > 0){
            [self addBalanceAdjustmentWithAmount:startingBalance AndDateTime:accStartDate AndReason:TRANSFER];
            _unfunded = NO;
        }else{
            _unfunded = YES;
        }
        _reportDataFieldsArray = [Simulation getReportFields];
        _isAnalysed = NO;
        
    }
    
    return self;
}

-(void) encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:_accBalanceArray forKey:@"ACCBALANCEARRAY"];
    [aCoder encodeObject:_tradesArray forKey:@"TRADESARRAY"];
    [aCoder encodeObject:_signalInfoArray forKey:@"SIGNALINFOARRAY"];
    [aCoder encodeObject:_simulationResults forKey:@"SIMULATIONRESULTS"];
    [aCoder encodeObject:_openPositionsArray forKey:@"OPENPOSITIONARRAY"];
    [aCoder encodeObject:_userAddedData forKey:@"USERDATAADDED"];
    [aCoder encodeObject:_simulationDataSeries forKey:@"SIMULATIONDATASERIES"];
    [aCoder encodeObject:_analysisDataSeries forKey:@"ANALYSISDATASERIES"];
    [aCoder encodeObject:[NSNumber numberWithLong:_dataStartDateTime] forKey:@"DATASTARTDATE"];
    
    
    [aCoder encodeObject:[RulesSystem combinedRulesString:[self rulesSystem]] forKey:@"RULESSYSTEMSTRING"];
    
    [aCoder encodeObject:_basicParameters forKey:@"BASICPARAMETERS"];
    [aCoder encodeObject:[[self positionSystem] positioningString] forKey:@"POSITIONSYSTEMSTRING"];
    [aCoder encodeObject:[[self signalSystem] signalString] forKey:@"SIGNALSYSTEMSTRING"];
    
    [aCoder encodeObject:[NSNumber numberWithBool:_isAnalysed] forKey:@"ISANALYSED"];
    [aCoder encodeObject:_simulationRunOutput forKey:@"SIMULATIONRUNOUTPUT"];
}

- (id) initWithCoder:(NSCoder *)aDecoder
{
    if (self = [super init]) {
        // If parent class also adopts NSCoding, replace [super init]
        // with [super initWithCoder:decoder] to properly initialize.
        
        // NOTE: Decoded objects are auto-released and must be retained
        _accBalanceArray = [aDecoder decodeObjectForKey:@"ACCBALANCEARRAY"];
        _tradesArray = [aDecoder decodeObjectForKey:@"TRADESARRAY"];
        _signalInfoArray = [aDecoder decodeObjectForKey:@"SIGNALINFOARRAY"];
        _simulationResults = [aDecoder decodeObjectForKey:@"SIMULATIONRESULTS"];
        _openPositionsArray = [aDecoder decodeObjectForKey:@"OPENPOSITIONARRAY"]; 
        _userAddedData = [aDecoder decodeObjectForKey:@"USERDATAADDED"];
        _simulationDataSeries = [aDecoder decodeObjectForKey:@"SIMULATIONDATASERIES"];
        _analysisDataSeries = [aDecoder decodeObjectForKey:@"ANALYSISDATASERIES"];
        _dataStartDateTime = [[aDecoder decodeObjectForKey:@"DATASTARTDATE"] longValue];
        _basicParameters =  [aDecoder decodeObjectForKey:@"BASICPARAMETERS"];
                             
        NSString *rulesString = [aDecoder decodeObjectForKey:@"RULESSYSTEMSTRING"];
        _rulesSystem = [[NSMutableArray alloc] init]; 
        BOOL check;
        check = [self addTradingRules:rulesString];
        
        NSString *positioningString = [aDecoder decodeObjectForKey:@"POSITIONSYSTEMSTRING"];
        _positionSystem = [[PositioningSystem alloc] initWithString:positioningString];
        NSString *signalString = [aDecoder decodeObjectForKey:@"SIGNALSYSTEMSTRING"];
        _signalSystem = [[SignalSystem alloc] initWithString:signalString];
        
        _reportDataFieldsArray = [Simulation getReportFields];
        _isAnalysed = [[aDecoder decodeObjectForKey:@"ISANALYSED"] boolValue];
        _simulationRunOutput = [aDecoder decodeObjectForKey:@"SIMULATIONRUNOUTPUT"];
        
        
        if(check == NO || _positionSystem == Nil || _signalSystem == Nil){
            NSLog(@"Problem recreating simulation");
            self = Nil;
        }
        
    }
    return self;
}

+(NSArray *)getReportFields
{
    NSArray *reportFields = [NSArray arrayWithObjects:@"NAME", @"TRADINGPAIR",@"ACCOUNTCURRENCY",@"BLANK",@"--RESULTS--", @"CASHTRANSFERS", @"FINALNAV", @"TRADE PNL", @"INTEREST",  @"DEEPESTDRAWDOWN", @"DEEPESTDRAWDOWNTIME", @"LONGESTDRAWDOWN", @"LONGESTDRAWDOWNTIME", @"NUMBEROFTRADES", @"SPREADCOST", @"BLANK",@"EXP NUMBER", @"EXP N LOSS", @"EXP N WIN", @"EXP MIN LEN", @"EXP MAX LEN", @"EXP MED LEN", @"EXP LOSS MED LEN", @"EXP WIN MED LEN", @"EXP BIG LOSS", @"EXP BIG WIN", @"SHARPE RATIO", @"SORTINO RATIO", @"BLANK", @"--PARAMETERS--",@"STARTTIME", @"ENDTIME", @"STRATEGY",@"EXTRASERIES",@"POSITIONING", @"RULES", @"MAXLEVERAGE", @"TIMESTEP", @"TRADINGLAG", @"TRADINGDAYSTART", @"TRADINGDAYEND", @"WARMUPTIME", @"DATARATE", @"USERADDEDDATA", nil];
    
    
    
    return reportFields;
}

- (BOOL) addTradingRules: (NSString *) rulesString
{
    BOOL allOk = YES; 
    NSString *trimmedRulesString = [rulesString stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    if([trimmedRulesString length] > 0)
    {
        NSString *singleRuleString;
        NSArray *separatedRules  = [trimmedRulesString componentsSeparatedByString:@";"];
        
        for(int i = 0; i < [separatedRules count]; i++){
            singleRuleString = [separatedRules objectAtIndex:i];
            allOk = [RulesSystem basicCheck:singleRuleString];
            if(allOk){
                [[self rulesSystem] addObject:singleRuleString];
            }else{
                break;
            }
        }
    }
    return allOk;
}

-(void) addObjectToSimulationResults:(id) datum 
                              ForKey:(NSString *) key
{
    [[self simulationResults] setObject:datum forKey:key];
}

- (double) currentBalance
{
    double balance;
    if([[self accBalanceArray] count]>0){
        CashFlowRecord *cashFlowRecord;
        cashFlowRecord = [[self accBalanceArray] objectAtIndex:[[self accBalanceArray] count]-1];
        balance = [cashFlowRecord resultingBalance];
    }else{
        balance = 0.0;
    }
    return balance;
}


- (int) currentExposure
{
    long positionIndex = 0;
    PositionRecord *openPosition;
    int currentExposure = 0;
    if([[self openPositionsArray] count]>0)
    {
        while(positionIndex < [[self openPositionsArray] count])
        {
            openPosition = [[self openPositionsArray] objectAtIndex:positionIndex]; 
            currentExposure = currentExposure + [openPosition amount];
            positionIndex++;
        }
    }
    return currentExposure;
}

- (NSDictionary *) getPerformanceAttribution
{
    NSDictionary * perfAttrib = [[NSMutableDictionary alloc] init];
    double transferAmounts = 0.0;
    double tradePnl = 0.0;
    double interestAccrued = 0.0;
    double other = 0.0;
    BOOL unIdentified = NO;
    CashFlowRecord *balAdj;
    
    for(int balAdjIndex = 0;balAdjIndex < [[self accBalanceArray] count]; balAdjIndex++)
    {
        balAdj = [[self accBalanceArray] objectAtIndex:balAdjIndex];
    
        switch([balAdj reason]){
        case(TRANSFER):
            transferAmounts = transferAmounts + [balAdj amount];
            break;
        case(TRADE_PNL):
            tradePnl = tradePnl + [balAdj amount];
            break;
        case(INTEREST):
            interestAccrued = interestAccrued + [balAdj amount];
            break;
        default:
            other = other + [balAdj amount];
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

#pragma mark -
#pragma mark General Methods, About Positions

-(NSUInteger) numberOfPositions
{
    return [[self openPositionsArray] count];
}

-(double) wgtAverageCostOfPosition
{
    double wgtCost = 0.0;
    int positionSize = 0;
    for(int positionIndex = 0; positionIndex < [[self openPositionsArray] count];positionIndex++){
        PositionRecord *openPosition;
        openPosition = [[self openPositionsArray] objectAtIndex:positionIndex];
        wgtCost = wgtCost + [openPosition amount] * [openPosition price];
        positionSize = positionSize + [openPosition amount]; 
    }
    if(positionSize != 0)
    {
        return wgtCost/positionSize;
    }else{
        return 0.0;
    }
}

- (NSDictionary *) detailsOfPositionAtIndex:(int)positionIndex
{
    NSMutableDictionary *positionDetails = [[NSMutableDictionary alloc] init];
    PositionRecord *openPosition;
    openPosition = [[self openPositionsArray] objectAtIndex:positionIndex];
    [positionDetails setObject:[NSNumber numberWithInt:openPosition.amount ] forKey:@"AMOUNT"];
    [positionDetails setObject:[NSNumber numberWithLong:openPosition.dateTime ] forKey:@"DATETIME"];
    [positionDetails setObject:[NSNumber numberWithDouble:openPosition.price] forKey:@"PRICE"];
    [positionDetails setObject:[NSNumber numberWithInt:openPosition.interestAccrued] forKey:@"INTERESTACCURED"];
    [positionDetails setObject:[NSNumber numberWithDouble:openPosition.interestAccruedDateTime] forKey:@"INTERESTTIMEDATE"];
    return positionDetails;
    
}

- (int) sizeOfPositionAtIndex:(int) positionIndex{
    PositionRecord *openPosition;
    openPosition = [[self openPositionsArray] objectAtIndex:positionIndex];
    return [openPosition amount];
}

- (double) entryPriceOfPositionAtIndex:(int) positionIndex{
    PositionRecord *openPosition;
    openPosition = [[self openPositionsArray] objectAtIndex:positionIndex];
    return [openPosition price];
}


- (long) dateTimeOfInterestForPositionAtIndex:(int) positionIndex{
    PositionRecord *openPosition;
    openPosition = [[self openPositionsArray] objectAtIndex:positionIndex];
    return [openPosition interestAccruedDateTime];
}

- (long) dateTimeOfEarliestPosition
{
    if([[self openPositionsArray] count] >0)
    {
        PositionRecord *openPosition;
        openPosition = [[self openPositionsArray] objectAtIndex:0];
        return [openPosition dateTime];
    }else{
        return 0;
    }
}

#pragma mark -
#pragma mark General Methods, About Balance Adjustments

-(void)addBalanceAdjustmentWithAmount: (double) amount
                          AndDateTime: (long) dateTime
                            AndReason: (BalAdjType) reasonCode
{
    CashFlowRecord *cashFlowRecord;
    double newAccountBalance;
    
    if([[self accBalanceArray] count]>0){
        CashFlowRecord *lastCashFlowRecord = [[self accBalanceArray] objectAtIndex:[[self accBalanceArray] count]-1];
        newAccountBalance = [lastCashFlowRecord resultingBalance] + amount;
    }else{
        newAccountBalance = amount; 
    }
    
    cashFlowRecord = [[CashFlowRecord alloc] initWithAmount:amount 
                                        AndResultingBalance:newAccountBalance 
                                                AndDateTime:dateTime 
                                                  AndReason:reasonCode];
    [[self accBalanceArray] addObject:cashFlowRecord];
}


- (NSDictionary *) detailsOfBalanceAdjustmentIndex: (NSUInteger)tradeIndex
{
    NSMutableDictionary *balAdjDetails = [[NSMutableDictionary alloc] init];
    CashFlowRecord *balAdj;
    balAdj = [[self accBalanceArray] objectAtIndex:tradeIndex];
    
    [balAdjDetails setObject:[NSNumber numberWithLong:[balAdj dateTime]] forKey:@"DATETIME"];
    [balAdjDetails setObject:[NSNumber numberWithDouble:[balAdj amount]] forKey:@"AMOUNT"];
    
    [balAdjDetails setObject:[NSNumber numberWithDouble:[balAdj resultingBalance]] forKey:@"ENDBAL"];
    NSString *reasonString;
    switch([balAdj reason])
    {
        case TRANSFER:
            reasonString = @"TRANSFER";
            break;
        case TRADE_PNL:
            reasonString = @"TRADE PNL";
            break;
        case INTEREST:
            reasonString = @"INTEREST";
            break;
        default:
            reasonString = @"UNKNOWN";
            break;
    }   
    
    [balAdjDetails setObject:reasonString forKey:@"REASON"];
    return balAdjDetails;
}


- (double) getAmountForBalanceAdjustmentAtIndex:(NSUInteger) balAdjIndex
{
    CashFlowRecord *balAdj;
    balAdj = [[self accBalanceArray] objectAtIndex:balAdjIndex];
    return [balAdj amount];
}

- (long) getDateTimeForBalanceAdjustmentAtIndex:(NSUInteger) balAdjIndex
{
    CashFlowRecord *balAdj;
    balAdj = [[self accBalanceArray] objectAtIndex:balAdjIndex];
    return [balAdj dateTime];
}

- (double) getResultingBalanceForBalanceAdjustmentAtIndex:(NSUInteger) balAdjIndex
{
    CashFlowRecord *balAdj;
    balAdj = [[self accBalanceArray] objectAtIndex:balAdjIndex];
    return [balAdj resultingBalance];
}

- (NSString *) getReasonForBalanceAdjustmentAtIndex:(NSUInteger) balAdjIndex
{
    CashFlowRecord *balAdj;
    balAdj = [[self accBalanceArray] objectAtIndex:balAdjIndex];
    NSString *reasonString;
    switch([balAdj reason])
    {
        case TRANSFER:
            reasonString = @"TRANSFER";
            break;
        case TRADE_PNL:
            reasonString = @"TRADE PNL";
            break;
        case INTEREST:
            reasonString = @"INTEREST";
            break;
        default:
            reasonString = @"UNKNOWN";
            break;
    }   
    
    return reasonString;
}

- (int) numberOfBalanceAdjustments
{
    return (int)[[self accBalanceArray] count];
}

- (NSString *) getBalanceDetailToPrint:(int) balAdjIndex;
{
    CashFlowRecord *newBalAdj;
    NSString *reason;
    NSString *dateTimeString;
    
    newBalAdj = [[self accBalanceArray] objectAtIndex:balAdjIndex];
    
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
    
    return [NSString stringWithFormat: @"On %@ the account was adjusted by %@ %5.2f to %5.2f because of %@ \n",dateTimeString, [self accCode],newBalAdj.amount, newBalAdj.resultingBalance, reason];
}

- (void) addInterestToPosition: (int) positionIndex
                    WithAmount: (int) interestAmount 
                        AtTime: (long) interestDateTime
{
    PositionRecord *openPosition;
    openPosition = [[self openPositionsArray] objectAtIndex:positionIndex];
    [openPosition setInterestAccrued:[openPosition interestAccrued] + interestAmount];
    [openPosition setInterestAccruedDateTime:interestDateTime];
    
    [self addBalanceAdjustmentWithAmount:interestAmount 
                             AndDateTime:interestDateTime 
                               AndReason:INTEREST];
}

- (double) getInterestCostsFrom: (long) startDateTime
                            To:(long) endDateTime
{
    CashFlowRecord *cfr;
    double interestCosts = 0.0;
    for(int i = 0; i < [[self accBalanceArray] count]; i++){
        cfr = [[self accBalanceArray] objectAtIndex:i];
        
        if([cfr reason] == INTEREST){
            if([cfr dateTime] > startDateTime && [cfr dateTime] <= endDateTime){
                interestCosts = interestCosts + [cfr amount];
            }
        }
    }
    return interestCosts;
}


#pragma mark -
#pragma mark General Methods, About Trades

-(double) addTradeWithAmount: (int) tradeAmount 
                      AtTime: (long) tradeDateTime 
                   WithPrice: (double) tradePrice
         AndAccQuoteBidPrice: (double) accQuoteBidPrice
         AndAccQuoteAskPrice: (double) accQuoteAskPrice
        AndBaseQuoteBidPrice: (double) baseQuoteBidPrice
        AndBaseQuoteAskPrice: (double) baseQuoteAskPrice
               AndSignalTime: (long) timeOfSignal
{
    double realisedPnl = 0.0;
    //adjust the positions as nessesary. If there are opposite position these will be closed oldest first
    
    if([[self openPositionsArray] count] == 0 || ([UtilityFunctions signOfInt:[self currentExposure]] == [UtilityFunctions signOfInt:tradeAmount])){
        PositionRecord *newPosition; 
        newPosition = [[PositionRecord alloc] initWithAmount:tradeAmount 
                                                 AndDateTime:tradeDateTime 
                                                    AndPrice:tradePrice 
                                         AndInterestDateTime:tradeDateTime 
                                          AndInterestAccrued:0.0];
        [[self openPositionsArray] addObject:newPosition];
    }else{
        int tradeRemainder = tradeAmount;
        int positionsToCancel = 0;
        int iPos = 0;
        PositionRecord *openPosition;
        iPos = 0;
        while(iPos < [[self openPositionsArray] count]  && tradeRemainder != 0){
            openPosition = [[self openPositionsArray] objectAtIndex:iPos];
            
            if([UtilityFunctions signOfInt:[openPosition amount]]*[UtilityFunctions signOfInt:tradeAmount] == -1)
            {
                if(abs([openPosition amount]) > abs(tradeAmount)){
                    tradeRemainder = 0;
                    [openPosition setAmount:[openPosition amount] + tradeAmount];
                    realisedPnl = tradeAmount * (tradePrice - [openPosition price]);
                    
                    if(realisedPnl>0){
                        realisedPnl = realisedPnl / accQuoteAskPrice; 
                    }else{
                        realisedPnl = realisedPnl / accQuoteBidPrice; 
                    }
                    [self addBalanceAdjustmentWithAmount:realisedPnl AndDateTime:tradeDateTime AndReason:TRADE_PNL];
                    
                }else{
                    tradeRemainder = tradeRemainder + [openPosition amount];
                    positionsToCancel = positionsToCancel + 1;
                    realisedPnl = [openPosition amount] * (tradePrice - [openPosition price]);
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
                [[self openPositionsArray] removeObjectAtIndex:0];
            }
        }
        if(abs(tradeRemainder)>0){
            PositionRecord *newPosition;
            newPosition = [[PositionRecord alloc] initWithAmount:tradeRemainder 
                                                     AndDateTime:tradeDateTime
                                                        AndPrice:tradePrice
                                             AndInterestDateTime:tradeDateTime
                                              AndInterestAccrued:0.0];
            [[self openPositionsArray] addObject:newPosition];
        }
        
    }
    
    //Add the trade
    TransactionRecord *newTrade;
    double spreadInAccountCurrency;
    if([[self accCode] isEqualToString:[self quoteCode]]){
        spreadInAccountCurrency = baseQuoteAskPrice-baseQuoteBidPrice;
    }else{
        spreadInAccountCurrency = (baseQuoteAskPrice-baseQuoteBidPrice)/baseQuoteBidPrice;  
    }
    
    newTrade = [[TransactionRecord alloc] initWithAmount:tradeAmount 
                                             AndDateTime:tradeDateTime 
                                                AndPrice:tradePrice AndResultingExposure:[self currentExposure] 
                                               AndSpread:baseQuoteAskPrice-baseQuoteBidPrice AndSpreadInAccCurrency:spreadInAccountCurrency AndSignalDateTime:timeOfSignal ];
    [[self tradesArray] addObject:newTrade];
    return realisedPnl;
}

- (NSUInteger) numberOfTrades
{
    return [[self tradesArray] count];
}

- (NSDictionary *) detailsOfTradeAtIndex:(NSUInteger)tradeIndex
{
    NSMutableDictionary *tradeDetails = [[NSMutableDictionary alloc] init];
    TransactionRecord *trade;
    trade = [[self tradesArray] objectAtIndex:tradeIndex];
    [tradeDetails setObject:[NSNumber numberWithInt:[trade amount] ] forKey:@"AMOUNT"];
    [tradeDetails setObject:[NSNumber numberWithLong:[trade dateTime]] forKey:@"DATETIME"];
    [tradeDetails setObject:[NSNumber numberWithDouble:[trade price]] forKey:@"PRICE"];
    [tradeDetails setObject:[NSNumber numberWithInt:[trade resultingMarketExposure]] forKey:@"ENDEXP"];
    [tradeDetails setObject:[NSNumber numberWithDouble:[trade spread]] forKey:@"SPREAD"];
    [tradeDetails setObject:[NSNumber numberWithLong:[trade signalDateTime]] forKey:@"SIGDATETIME"]; 
    return tradeDetails;
}


- (int) getAmountForTradeAtIndex:(NSUInteger) tradeIndex
{
    TransactionRecord *trade;
    trade = [[self tradesArray] objectAtIndex:tradeIndex];
    return trade.amount;
}

- (long) getDateTimeForTradeAtIndex:(NSUInteger) tradeIndex
{
    TransactionRecord *trade;
    trade = [[self tradesArray] objectAtIndex:tradeIndex];
    return [trade dateTime];
}

- (double) getPriceForTradeAtIndex:(NSUInteger) tradeIndex
{
    TransactionRecord *trade;
    trade = [[self tradesArray] objectAtIndex:tradeIndex];
    return [trade price];
}

- (int) getResultingMarketExposureForTradeAtIndex:(NSUInteger) tradeIndex
{
    TransactionRecord *trade;
    trade = [[self tradesArray] objectAtIndex:tradeIndex];
    return [trade resultingMarketExposure];
}

- (NSString *) getTradeDetailToPrint:(NSUInteger) tradeIndex;
{
    TransactionRecord *trade;
    NSString *dateTimeString;
    trade = [[self tradesArray] objectAtIndex:tradeIndex];
    dateTimeString = [EpochTime stringDateWithTime:[trade dateTime]];
    return [NSString stringWithFormat: @"On %@ Traded %@ %d  at Price %@ %5.2f resulting in exposure %@ %d \n",
            dateTimeString, [self baseCode], [trade amount], [self quoteCode], [trade price], [self baseCode], [trade resultingMarketExposure]];    
}



#pragma mark -
#pragma mark General Methods, About Report Data


-(NSUInteger) getNumberOfReportDataFields
{
    return [[self reportDataFieldsArray] count];
}

-(NSString *)getReportNameFieldAtIndex:(NSUInteger) nameFieldIndex
{
    NSString *fieldName = [[self reportDataFieldsArray] objectAtIndex:nameFieldIndex];
    if([fieldName isEqualToString:@"BLANK"]){
        return @"";
    }else{
        return fieldName;
    }
}

-(NSString *)getReportDataFieldAtIndex:(NSUInteger) dataFieldIndex
{
    NSString *dataFieldIdentifier =  [[Simulation getReportFields] objectAtIndex:dataFieldIndex];
    
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
        NSString *strategyAndSeriesString = [[self signalSystem] signalString];
        NSArray *strategyAndSeriesComponents = [strategyAndSeriesString componentsSeparatedByString:@";"];
        if([strategyAndSeriesComponents count] == 1){
            return strategyAndSeriesString;
        }else{
            return [strategyAndSeriesComponents objectAtIndex:0];
        }
    }
    if([dataFieldIdentifier isEqualToString:@"EXTRASERIES"]){
        NSString *strategyAndSeriesString = [[self signalSystem] signalString];
        NSArray *strategyAndSeriesComponents = [strategyAndSeriesString componentsSeparatedByString:@";"];
        if([strategyAndSeriesComponents count] == 1){
            return @"";
        }else{
            return [strategyAndSeriesString substringFromIndex:[[strategyAndSeriesComponents objectAtIndex:0] length]+1];
        }
    }
    if([dataFieldIdentifier isEqualToString:@"POSITIONING"]){
        return [[self positionSystem] positioningString];
    } 
    if([dataFieldIdentifier isEqualToString:@"RULES"]){
        return [RulesSystem combinedRulesString:[self rulesSystem]];
    } 
    
    if([dataFieldIdentifier isEqualToString:@"MAXLEVERAGE"]){
        return [NSString stringWithFormat:@"%5.0f",[self maxLeverage]];    
    }
    if([dataFieldIdentifier isEqualToString:@"DATARATE"]){
        return [NSString stringWithFormat:@"%ld",[self dataRate]];
    }
    if([dataFieldIdentifier isEqualToString:@"TIMESTEP"]){
        return [NSString stringWithFormat:@"%ld seconds",[self samplingRate]];
    }
    if([dataFieldIdentifier isEqualToString:@"TRADINGDAYSTART"]){
        return [EpochTime stringOfDateTime:[self tradingDayStart] WithFormat:@"%H:%M"];    
    }
    if([dataFieldIdentifier isEqualToString:@"TRADINGDAYEND"]){
        return [EpochTime stringOfDateTime:[self tradingDayEnd] WithFormat:@"%H:%M"];    
    }
    if([dataFieldIdentifier isEqualToString:@"TRADINGLAG"]){
        return [NSString stringWithFormat:@"%ld seconds",[self tradingLag]];
    }
    if([dataFieldIdentifier isEqualToString:@"USERADDEDDATA"]){
        return [self userAddedData];
    }
    if([dataFieldIdentifier isEqualToString:@"WARMUPTIME"]){
        
        return [NSString stringWithFormat:@"%5.1f days",[self warmupTime]/(24.0*60*60)];
    }

    
    id returnData = [[self simulationResults] objectForKey:dataFieldIdentifier];
    if(returnData != nil){
        if([dataFieldIdentifier isEqualToString:@"DEEPESTDRAWDOWNTIME"]){
            returnData = [EpochTime stringDateWithTime:[returnData longValue]];
            return returnData;
        }
        if([dataFieldIdentifier isEqualToString:@"LONGESTDRAWDOWNTIME"]){
            returnData = [EpochTime stringDateWithTime:[returnData longValue]];
            return returnData;
        }

        if([dataFieldIdentifier isEqualToString:@"LONGESTDRAWDOWN"]){
            returnData = [NSString stringWithFormat:@"%5.1f days",(double)[returnData longValue]/(24*60*60)];
            return returnData;
        }
        
        if([dataFieldIdentifier isEqualToString:@"PNLUPTIME"] || [dataFieldIdentifier isEqualToString:@"PNLDOWNTIME"]){
            returnData = [NSString stringWithFormat:@"%ld hours",[returnData longValue]/(60*60)];
            return returnData;
        }
        
        if([dataFieldIdentifier isEqualToString:@"EXP NUMBER"] ||
           [dataFieldIdentifier isEqualToString:@"EXP N LOSS"] ||
           [dataFieldIdentifier isEqualToString:@"EXP N WIN"]){
            returnData = [NSString stringWithFormat:@"%ld",[returnData longValue]];
            return returnData;
        }
        if([dataFieldIdentifier isEqualToString:@"EXP MIN LEN"] ||
           [dataFieldIdentifier isEqualToString:@"EXP MAX LEN"] ||
           [dataFieldIdentifier isEqualToString:@"EXP MED LEN"] ||
           [dataFieldIdentifier isEqualToString:@"EXP LOSS MED LEN"] ||
           [dataFieldIdentifier isEqualToString:@"EXP WIN MED LEN"]){
            returnData = [NSString stringWithFormat:@"%5.2f hours",[returnData longValue]/(60.0*60)];
            return returnData;
        }
        if([dataFieldIdentifier isEqualToString:@"EXP BIG LOSS"] ||
           [dataFieldIdentifier isEqualToString:@"EXP BIG WIN"]){
            returnData = [NSString stringWithFormat:@"%5.2f",[returnData doubleValue]];
            return returnData;
        }
                
        
        returnData = [NSString stringWithFormat:@"%5.2f",[returnData floatValue]];
        
        return returnData;
    }
    
    
    return @"Data not found";
}

#pragma mark -
#pragma mark General Methods, About Signals

- (NSUInteger) addSignalStatisticsWithSignal: (double) signal
                         AndEntryTime: (long) entryTime
                          AndExitTime: (long) exitTime
                        AndEntryPrice: (double)entryPrice
                         AndExitPrice: (double) exitPrice
{
    SignalRecord *signalRecord;
    signalRecord = [[SignalRecord alloc] initWithSignal:signal 
                                           AndStartTime:entryTime 
                                             AndEndTime:exitTime 
                                          AndEntryPrice:entryPrice 
                                           AndExitPrice:exitPrice];
    [[self signalInfoArray] addObject:signalRecord];
    return [[self signalInfoArray] count] - 1;
}

-(NSUInteger)numberOfSignals
{
    return [[self signalInfoArray] count];
}

-(NSDictionary *)detailsOfSignalAtIndex:(NSUInteger)signalInfoIndex
{
    NSMutableDictionary *signalInfoDetails = [[NSMutableDictionary alloc] init];
    SignalRecord *signalRecord;
    signalRecord = [[self signalInfoArray] objectAtIndex:signalInfoIndex];
    [signalInfoDetails setObject:[NSNumber numberWithDouble:[signalRecord signal]] forKey:@"SIGNAL"];
    [signalInfoDetails setObject:[NSNumber numberWithLong:[signalRecord startTime]] forKey:@"ENTRYTIME"];
    [signalInfoDetails setObject:[NSNumber numberWithLong:[signalRecord endTime]] forKey:@"EXITTIME"]; 
    [signalInfoDetails setObject:[NSNumber numberWithDouble:[signalRecord entryPrice]] forKey:@"ENTRYPRICE"];
    [signalInfoDetails setObject:[NSNumber numberWithDouble:[signalRecord exitPrice]] forKey:@"EXITPRICE"];
    [signalInfoDetails setObject:[NSNumber numberWithDouble:[signalRecord pnl]] forKey:@"PNL"];
    return signalInfoDetails;
}

-(void) addToSignalInfoAtIndex:(NSUInteger)signalInfoIndex
                  EstimatedPnl: (double) pnl

{
    SignalRecord *signalRecord;
    signalRecord = [[self signalInfoArray] objectAtIndex:signalInfoIndex];
    [signalRecord setPnl:pnl];
    
}


#pragma mark -
#pragma mark General Methods, Data Output

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
        TransactionRecord *trade;
        lineOfDataAsString = @"DATETIME, CODE, AMOUNT, PRICE, RESULTING EXPOSURE \r\n";
        [outFile writeData:[lineOfDataAsString dataUsingEncoding:NSUTF8StringEncoding]];
        for(int tradeIndex = 0; tradeIndex < [[self tradesArray] count];tradeIndex++){
            trade = [[self tradesArray] objectAtIndex:tradeIndex];
            dateTimeString = [EpochTime stringDateWithTime:[trade dateTime]];
            lineOfDataAsString = [NSString stringWithFormat:@"%@, %@%@, %d, %5.4f, %d", dateTimeString, [self baseCode], [self quoteCode], [trade amount], [trade price], [trade resultingMarketExposure]];
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
        CashFlowRecord *balAdj;
        lineOfDataAsString = @"DATETIME, AMOUNT, REASON, RESULTING BALANCE, CODE \r\n";
        [outFile writeData:[lineOfDataAsString dataUsingEncoding:NSUTF8StringEncoding]];
        for(int balAdjIndex = 0; balAdjIndex < [[self accBalanceArray] count];balAdjIndex++){
            balAdj = [[self accBalanceArray] objectAtIndex:balAdjIndex];
            dateTimeString = [EpochTime stringDateWithTime:[balAdj dateTime]];
            switch([balAdj reason])
            {
                case TRANSFER:
                    reasonString = @"TRANSFER";
                    break;
                case TRADE_PNL:
                    reasonString = @"TRADE PNL";
                    break;
                case INTEREST:
                    reasonString = @"INTEREST";
                    break;
                default:
                    reasonString = @"UNKNOWN";
                    break;
            }   
            
            lineOfDataAsString = [NSString stringWithFormat:@"%@, %f, %@, %f, %@", dateTimeString, [balAdj amount], reasonString, [balAdj resultingBalance], [self accCode]];
            lineOfDataAsString = [lineOfDataAsString stringByAppendingFormat:@"\r\n"];
            [outFile writeData:[lineOfDataAsString dataUsingEncoding:NSUTF8StringEncoding]];
        }
        [outFile closeFile];
        
    }
    return allOk;
}



#pragma mark -
#pragma mark General Methods, Property retrieval

- (NSUInteger) tradingLag
{
    return [[self basicParameters] tradingLag];
}

-(NSString *)name
{
    return [[self basicParameters] name];
}

-(NSString *)accCode
{
    return [[self basicParameters] accCode];
}

-(NSString *)baseCode
{
    return [[self basicParameters] baseCode];
}

-(NSString *)quoteCode
{
    return [[self basicParameters] quoteCode];
}

- (float) maxLeverage
{
    return [[self basicParameters] maxLeverage];
}

- (NSUInteger) tradingDayStart
{
    return [[self basicParameters] tradingDayStart];
}

- (NSUInteger) tradingDayEnd
{
    return [[self basicParameters] tradingDayEnd];
}

- (long) startDate
{
    return [[self basicParameters] startDate];
}

- (long) endDate
{
    return [[self basicParameters] endDate];
}

- (BOOL) weekendTrading
{
    return [[self basicParameters] weekendTrading];
}

- (NSUInteger) samplingRate
{
    return [[self basicParameters] samplingRate];
}

- (long) dataRate
{
    return [[self basicParameters] dataRate];
}

- (long) warmupTime
{
    return [[self basicParameters] warmupTime];
}


- (void) setSimName:(NSString *)name
{
    [[self basicParameters] setName:name];
}

#pragma mark -
#pragma mark Properties
     
@synthesize basicParameters = _basicParameters;
@synthesize positionSystem = _positionSystem;
@synthesize signalSystem = _signalSystem;
@synthesize rulesSystem = _rulesSystem;
@synthesize simulationDataSeries = _simulationDataSeries;
@synthesize analysisDataSeries = _analysisDataSeries;
@synthesize dataStartDateTime = _dataStartDateTime;
@synthesize reportDataFieldsArray = _reportDataFieldsArray;
@synthesize userAddedData = _userAddedData;
@synthesize simulationResults = _simulationResults;
@synthesize accBalanceArray = _accBalanceArray;
@synthesize signalInfoArray = _signalInfoArray;
@synthesize openPositionsArray = _openPositionsArray;
@synthesize tradesArray = _tradesArray;
@synthesize isAnalysed = _isAnalysed;
@synthesize simulationRunOutput = _simulationRunOutput;

@end
