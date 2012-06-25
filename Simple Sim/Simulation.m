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

@interface Simulation()
-(int) resultingExposureForTradeAtIndex: (NSUInteger) index;
-(void) addBalanceAdjustmentWithAmount: (double) amount
                          AndDateTime: (long) dateTime
                            AndReason:(BalAdjType) reasonCode;
@end

@implementation Simulation


-(id)initWithName: (NSString *) accountName 
          AndDate: (long) startDateTime 
       AndBalance: (double) startingBalance 
      AndCurrency: (NSString *) ISOcode
   AndTradingPair: (NSString *) codeForTradingPair
   AndMaxLeverage: (double) leverage
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
        userAddedData = @"None";
        
        if(startingBalance > 0){
            [self addBalanceAdjustmentWithAmount:startingBalance AndDateTime:startDateTime AndReason:TRANSFER];
        }
        reportDataFieldsArray = [NSArray arrayWithObjects:@"NAME", @"TRADINGPAIR",@"ACCOUNTCURRENCY",@"BLANK",@"--RESULTS--", @"CASHTRANSFERS", @"FINALNAV", @"TRADE PNL", @"INTEREST",  @"BIGGESTDRAWDOWN",@"DRAWDOWNTIME",  @"NUMBEROFTRADES", @"SPREADCOST", @"BLANK", @"--PARAMETERS--",@"STARTTIME", @"ENDTIME", @"STRATEGY",@"POSITIONING",@"MAXLEVERAGE", @"TIMESTEP", @"TRADINGLAG",@"TRADINGDAYSTART",@"TRADINGDAYEND",@"USERADDEDDATA", nil]; 
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
    if([dataFieldIdentifier isEqualToString:@"POSITIONING"]){
        return positioningType;
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
    if([dataFieldIdentifier isEqualToString:@"USERADDEDDATA"]){
        return userAddedData;
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
    CashFlowRecord *cashFlowRecord;
    double newAccountBalance;
    
    if([accBalanceArray count]>0){
        CashFlowRecord *lastCashFlowRecord = [accBalanceArray objectAtIndex:[accBalanceArray count]-1];
        newAccountBalance = [lastCashFlowRecord resultingBalance] + amount;
    }else{
        newAccountBalance = amount; 
    }
    
    cashFlowRecord = [[CashFlowRecord alloc] initWithAmount:amount 
                                        AndResultingBalance:newAccountBalance 
                                                AndDateTime:dateTime 
                                                  AndReason:reasonCode];
    [accBalanceArray addObject:cashFlowRecord];
}

- (int) addSignalStatisticsWithSignal: (double) signal
                       AndEntryTime: (long) entryTime
                        AndExitTime: (long) exitTime
                      AndEntryPrice: (double)entryPrice
                       AndExitPrice: (double) exitPrice
                    AndTimeInProfit: (double) timeInProfit
              AndMaxPotentialProfit: (double) potentialProfit
                AndMaxPotentialLoss: (double) potentialLoss
{
    SignalRecord *signalRecord;
    signalRecord = [[SignalRecord alloc] initWithSignal:signal 
                                           AndStartTime:entryTime 
                                             AndEndTime:exitTime 
                                          AndEntryPrice:entryPrice 
                                           AndExitPrice:exitPrice 
                                        AndTimeInProfit:timeInProfit 
                                  AndMaxPotentialProfit:potentialProfit 
                                    AndMaxPotentialLoss:potentialLoss];
    [signalInfoArray addObject:signalRecord];
    return [signalInfoArray count] - 1;
}

- (double) currentBalance
{
    double balance;
    if([accBalanceArray count]>0){
        CashFlowRecord *cashFlowRecord;
        cashFlowRecord = [accBalanceArray objectAtIndex:[accBalanceArray count]-1];
        balance = [cashFlowRecord resultingBalance];
    }else{
        balance = 0.0;
    }
    return balance;
}


-(int) currentExposure
{
    long positionIndex = 0;
    PositionRecord *openPosition;
    int currentExposure = 0;
    if([openPositionsArray count]>0)
    {
        while(positionIndex < [openPositionsArray count])
        {
            openPosition = [openPositionsArray objectAtIndex:positionIndex]; 
            currentExposure = currentExposure + [openPosition amount];
            positionIndex++;
        }
    }
    return currentExposure;
}

-(void) printPositions
{
    long positionIndex = 0;
    PositionRecord *openPosition;
    while(positionIndex <= [openPositionsArray count])
    {
        openPosition = [openPositionsArray objectAtIndex:positionIndex];
        NSLog(@"%lu Position %d at price %5.4f" , [openPosition dateTime], [openPosition amount], [openPosition price]);
        positionIndex++;
    }
}

-(void) addInterestToPosition:(int) positionIndex
                   WithAmount:(int) interestAmount 
                       AtTime:(long) interestDateTime
{
    PositionRecord *openPosition;
    openPosition = [openPositionsArray objectAtIndex:positionIndex];
    [openPosition setInterestAccrued:[openPosition interestAccrued] + interestAmount];
    [openPosition setInterestAccruedDateTime:interestDateTime];
    
    [self addBalanceAdjustmentWithAmount:interestAmount 
                             AndDateTime:interestDateTime 
                               AndReason:INTEREST];
}

-(double) addTradeWithAmount: (int) tradeAmount 
                      AtTime: (long) tradeDateTime 
                   WithPrice: (double) tradePrice
         AndAccQuoteBidPrice: (double) accQuoteBidPrice
         AndAccQuoteAskPrice: (double) accQuoteAskPrice
        AndBaseQuoteBidPrice: (double) baseQuoteBidPrice
        AndBaseQuoteAskPrice: (double) baseQuoteAskPrice
              AndSignalIndex: (int) signalIndex
{
    double realisedPnl = 0.0;
    //adjust the positions as nessesary. If there are opposite position these will be closed oldest first
    
    if([openPositionsArray count] == 0 || ([UtilityFunctions signOfInt:[self currentExposure]] == [UtilityFunctions signOfInt:tradeAmount])){
        PositionRecord *newPosition; 
        newPosition = [[PositionRecord alloc] initWithAmount:tradeAmount 
                                                 AndDateTime:tradeDateTime 
                                                    AndPrice:tradePrice 
                                         AndInterestDateTime:tradeDateTime 
                                          AndInterestAccrued:0.0];
        [openPositionsArray addObject:newPosition];
    }else{
        int tradeRemainder = tradeAmount;
        int positionsToCancel = 0;
        int iPos = 0;
        PositionRecord *openPosition;
        iPos = 0;
        while(iPos < [openPositionsArray count]  && tradeRemainder != 0){
            openPosition = [openPositionsArray objectAtIndex:iPos];
            
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
                [openPositionsArray removeObjectAtIndex:0];
            }
        }
        if(abs(tradeRemainder)>0){
            PositionRecord *newPosition;
            newPosition = [[PositionRecord alloc] initWithAmount:tradeRemainder 
                                                     AndDateTime:tradeDateTime
                                                        AndPrice:tradePrice
                                             AndInterestDateTime:tradeDateTime
                                              AndInterestAccrued:0.0];
            [openPositionsArray addObject:newPosition];
        }
               
    }
    
    //Add the trade
    TransactionRecord *newTrade;
    double spreadInAccountCurrency;
    if([accCode isEqualToString:quoteCode]){
        spreadInAccountCurrency = baseQuoteAskPrice-baseQuoteBidPrice;
    }else{
          spreadInAccountCurrency = (baseQuoteAskPrice-baseQuoteBidPrice)/baseQuoteBidPrice;  
    }
    
    newTrade = [[TransactionRecord alloc] initWithAmount:tradeAmount 
                                             AndDateTime:tradeDateTime 
                                                AndPrice:tradePrice AndResultingExposure:[self currentExposure] 
                                               AndSpread:baseQuoteAskPrice-baseQuoteBidPrice AndSpreadInAccCurrency:spreadInAccountCurrency AndSignalDateTime:0 AndSignalIndex:signalIndex];
    [tradesArray addObject:newTrade];
    return realisedPnl;
}

-(int) resultingExposureForTradeAtIndex: (NSUInteger) tradeIndex
{
    return [[tradesArray objectAtIndex:tradeIndex] resultingMarketExposure];
}

-(int) numberOfPositions
{
    return (int)[openPositionsArray count];
}

-(double) wgtAverageCostOfPosition
{
    double wgtCost = 0.0;
    int positionSize = 0;
    for(int positionIndex = 0; positionIndex < [openPositionsArray count];positionIndex++){
        PositionRecord *openPosition;
        openPosition = [openPositionsArray objectAtIndex:positionIndex];
        wgtCost = [openPosition amount] * [openPosition price];
        positionSize = positionSize + [openPosition amount]; 
    }
    if(positionSize != 0)
    {
        return wgtCost/positionSize;
    }else{
        return 0.0;
    }
}

-(NSDictionary *) detailsOfPositionAtIndex:(int)positionIndex
{
    NSMutableDictionary *positionDetails = [[NSMutableDictionary alloc] init];
    PositionRecord *openPosition;
    openPosition = [openPositionsArray objectAtIndex:positionIndex];
    [positionDetails setObject:[NSNumber numberWithInt:openPosition.amount ] forKey:@"AMOUNT"];
    [positionDetails setObject:[NSNumber numberWithLong:openPosition.dateTime ] forKey:@"DATETIME"];
    [positionDetails setObject:[NSNumber numberWithDouble:openPosition.price] forKey:@"PRICE"];
    [positionDetails setObject:[NSNumber numberWithInt:openPosition.interestAccrued] forKey:@"INTERESTACCURED"];
    [positionDetails setObject:[NSNumber numberWithDouble:openPosition.interestAccruedDateTime] forKey:@"INTERESTTIMEDATE"];
    return positionDetails;
    
}

-(int) sizeOfPositionAtIndex:(int) positionIndex{
    PositionRecord *openPosition;
    openPosition = [openPositionsArray objectAtIndex:positionIndex];
    return [openPosition amount];
}

-(long) dateTimeOfPositionAtIndex:(int) positionIndex{
    PositionRecord *openPosition;
    openPosition = [openPositionsArray objectAtIndex:positionIndex];
    return [openPosition dateTime];
}

-(double) entryPriceOfPositionAtIndex:(int) positionIndex{
    PositionRecord *openPosition;
    openPosition = [openPositionsArray objectAtIndex:positionIndex];
    return [openPosition price];
}


-(long) dateTimeOfInterestForPositionAtIndex:(int) positionIndex{
    PositionRecord *openPosition;
    openPosition = [openPositionsArray objectAtIndex:positionIndex];
    return [openPosition interestAccruedDateTime];
}

-(long)timeDateOfEarliestPosition
{
    if([openPositionsArray count] >0)
    {
        PositionRecord *openPosition;
        openPosition = [openPositionsArray objectAtIndex:0];
        return [openPosition dateTime];
    }else{
        return 0;
    }
}

-(int)numberOfTrades
{
    return (int)[tradesArray count];
}

-(NSDictionary *)detailsOfTradeAtIndex:(int)tradeIndex
{
    NSMutableDictionary *tradeDetails = [[NSMutableDictionary alloc] init];
    TransactionRecord *trade;
    trade = [tradesArray objectAtIndex:tradeIndex];
    [tradeDetails setObject:[NSNumber numberWithInt:[trade amount] ] forKey:@"AMOUNT"];
    [tradeDetails setObject:[NSNumber numberWithLong:[trade dateTime]] forKey:@"DATETIME"];
    [tradeDetails setObject:[NSNumber numberWithDouble:[trade price]] forKey:@"PRICE"];
    [tradeDetails setObject:[NSNumber numberWithInt:[trade resultingMarketExposure]] forKey:@"ENDEXP"];
    [tradeDetails setObject:[NSNumber numberWithDouble:[trade spread]] forKey:@"SPREAD"];
    [tradeDetails setObject:[NSNumber numberWithLong:[trade signalDateTime]] forKey:@"SIGDATETIME"]; 
    return tradeDetails;
 }


-(int)getAmountForTradeAtIndex:(int) tradeIndex
{
    TransactionRecord *trade;
    trade = [tradesArray objectAtIndex:tradeIndex];
    return trade.amount;
}

-(long)getDateTimeForTradeAtIndex:(int) tradeIndex
{
    TransactionRecord *trade;
    trade = [tradesArray objectAtIndex:tradeIndex];
    return [trade dateTime];
}

-(double)getPriceForTradeAtIndex:(int) tradeIndex
{
    TransactionRecord *trade;
    trade = [tradesArray objectAtIndex:tradeIndex];
    return [trade price];
}

-(double)getTotalSpreadCostForTradeAtIndex:(int) tradeIndex
{
    TransactionRecord *trade;
    trade = [tradesArray objectAtIndex:tradeIndex];
    return -([trade spreadInAccCurrency]*abs([trade amount]))/2;
}



-(int)getResultingMarketExposureForTradeAtIndex:(int) tradeIndex
{
    TransactionRecord *trade;
    trade = [tradesArray objectAtIndex:tradeIndex];
    return [trade resultingMarketExposure];
}

-(NSString *)getTradeDetailToPrint:(int) tradeIndex;
{
    TransactionRecord *trade;
    NSString *dateTimeString;
    trade = [tradesArray objectAtIndex:tradeIndex];
    dateTimeString = [EpochTime stringDateWithTime:[trade dateTime]];
    return [NSString stringWithFormat: @"On %@ Traded %@ %d  at Price %@ %5.2f resulting in exposure %@ %d",
            dateTimeString, baseCode, [trade amount], quoteCode, [trade price], baseCode, [trade resultingMarketExposure]];    
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
        TransactionRecord *trade;
        lineOfDataAsString = @"DATETIME, CODE, AMOUNT, PRICE, RESULTING EXPOSURE \r\n";
        [outFile writeData:[lineOfDataAsString dataUsingEncoding:NSUTF8StringEncoding]];
        for(int tradeIndex = 0; tradeIndex < [tradesArray count];tradeIndex++){
            trade = [tradesArray objectAtIndex:tradeIndex];
            dateTimeString = [EpochTime stringDateWithTime:[trade dateTime]];
            lineOfDataAsString = [NSString stringWithFormat:@"%@, %@%@, %d, %5.4f, %d", dateTimeString, baseCode, quoteCode, [trade amount], [trade price], [trade resultingMarketExposure]];
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
        for(int balAdjIndex = 0; balAdjIndex < [accBalanceArray count];balAdjIndex++){
            balAdj = [accBalanceArray objectAtIndex:balAdjIndex];
            dateTimeString = [EpochTime stringDateWithTime:[balAdj dateTime]];
            switch([balAdj reason])
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

            lineOfDataAsString = [NSString stringWithFormat:@"%@, %f, %@, %f, %@", dateTimeString, [balAdj amount], reasonString, [balAdj resultingBalance], accCode];
            lineOfDataAsString = [lineOfDataAsString stringByAppendingFormat:@"\r\n"];
            [outFile writeData:[lineOfDataAsString dataUsingEncoding:NSUTF8StringEncoding]];
        }
        [outFile closeFile];
        
    }
    return allOk;
}

//Balance Adjustment Info
- (NSDictionary *) detailsOfBalanceAdjustmentIndex:(int)tradeIndex
{
    NSMutableDictionary *balAdjDetails = [[NSMutableDictionary alloc] init];
    CashFlowRecord *balAdj;
    balAdj = [accBalanceArray objectAtIndex:tradeIndex];
    
    [balAdjDetails setObject:[NSNumber numberWithLong:[balAdj dateTime]] forKey:@"DATETIME"];
    [balAdjDetails setObject:[NSNumber numberWithDouble:[balAdj amount]] forKey:@"AMOUNT"];
    
    [balAdjDetails setObject:[NSNumber numberWithDouble:[balAdj resultingBalance]] forKey:@"ENDBAL"];
    NSString *reasonString;
    switch([balAdj reason])
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
                        
                              
-(double)getAmountForBalanceAdjustmentAtIndex:(int) balAdjIndex
{
    CashFlowRecord *balAdj;
    balAdj = [accBalanceArray objectAtIndex:balAdjIndex];
    return [balAdj amount];
}

-(long)getDateTimeForBalanceAdjustmentAtIndex:(int) balAdjIndex
{
    CashFlowRecord *balAdj;
    balAdj = [accBalanceArray objectAtIndex:balAdjIndex];
    return [balAdj dateTime];
}

-(double)getResultingBalanceForBalanceAdjustmentAtIndex:(int) balAdjIndex
{
    CashFlowRecord *balAdj;
    balAdj = [accBalanceArray objectAtIndex:balAdjIndex];
    return [balAdj resultingBalance];
}

-(NSString *)getReasonForBalanceAdjustmentAtIndex:(int) balAdjIndex
{
    CashFlowRecord *balAdj;
    balAdj = [accBalanceArray objectAtIndex:balAdjIndex];
    NSString *reasonString;
    switch([balAdj reason])
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
    CashFlowRecord *balAdj;
    balAdj = [accBalanceArray objectAtIndex:balAdjIndex];
    if([balAdj reason] == TRANSFER){
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
    CashFlowRecord *newBalAdj; 
    NSString *reason;
    NSString *dateTimeString;
    
    newBalAdj = [accBalanceArray objectAtIndex:balAdjIndex];
    
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
    SignalRecord *signalRecord;
    signalRecord = [signalInfoArray objectAtIndex:signalInfoIndex];
    [signalInfoDetails setObject:[NSNumber numberWithDouble:[signalRecord signal]] forKey:@"SIGNAL"];
    [signalInfoDetails setObject:[NSNumber numberWithLong:[signalRecord startTime]] forKey:@"ENTRYTIME"];
    [signalInfoDetails setObject:[NSNumber numberWithLong:[signalRecord endTime]] forKey:@"EXITTIME"]; 
    [signalInfoDetails setObject:[NSNumber numberWithDouble:[signalRecord entryPrice]] forKey:@"ENTRYPRICE"];
    [signalInfoDetails setObject:[NSNumber numberWithDouble:[signalRecord exitPrice]] forKey:@"EXITPRICE"];
    [signalInfoDetails setObject:[NSNumber numberWithDouble:[signalRecord maxPotentialLoss]] forKey:@"POTLOSS"];
    [signalInfoDetails setObject:[NSNumber numberWithDouble:[signalRecord maxPotentialProfit]] forKey:@"POTGAIN"];
    [signalInfoDetails setObject:[NSNumber numberWithDouble:[signalRecord timeInProfit]] forKey:@"UPTIME"]; 
    return signalInfoDetails;
}

-(int)getNewSignalForChangeAtIndex:(int) signalChangeIndex
{
    SignalRecord *signalRecord;
    signalRecord = [signalInfoArray objectAtIndex:signalChangeIndex];
    return [signalRecord signal];
}

-(long)getDateTimeStartForSignalChangeAtIndex:(int) signalChangeIndex
{
    SignalRecord *signalRecord;
    signalRecord = [signalInfoArray objectAtIndex:signalChangeIndex];
    return [signalRecord startTime];
}

-(long)getDateTimeEndForSignalChangeAtIndex:(int) signalChangeIndex
{
    SignalRecord *signalRecord;
    signalRecord = [signalInfoArray objectAtIndex:signalChangeIndex];
    return [signalRecord endTime];
}

-(NSDictionary *)getPerformanceAttribution
{
    NSDictionary * perfAttrib = [[NSMutableDictionary alloc] init];
    double transferAmounts = 0.0;
    double tradePnl = 0.0;
    double interestAccrued = 0.0;
    double other = 0.0;
    BOOL unIdentified = NO;
    CashFlowRecord *balAdj;
    
    for(int balAdjIndex = 0;balAdjIndex < [accBalanceArray count]; balAdjIndex++)
    {
        balAdj = [accBalanceArray objectAtIndex:balAdjIndex];
    
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
#pragma mark Properties

@synthesize name;
@synthesize startDate;
@synthesize endDate;
@synthesize accCode;
@synthesize baseCode;
@synthesize quoteCode;
@synthesize maxLeverage;
@synthesize signalParameters;
@synthesize positioningType;
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
@synthesize userAddedData;


@end
