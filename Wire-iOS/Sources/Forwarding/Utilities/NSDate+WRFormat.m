// 
// Wire
// Copyright (C) 2016 Wire Swiss GmbH
// 
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
// 
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
// 
// You should have received a copy of the GNU General Public License
// along with this program. If not, see http://www.gnu.org/licenses/.
// 


#import "NSDate+WRFormat.h"
@import FormatterKit;

#define NSTimeIntervalOneHour 3600.0

static NSCalendarUnit const DayMonthYearUnits = NSCalendarUnitDay | NSCalendarUnitMonth | NSCalendarUnitYear;
static NSCalendarUnit const WeekMonthYearUnits = NSCalendarUnitWeekOfMonth | NSCalendarUnitMonth | NSCalendarUnitYear;


@implementation NSDate (WRFormat)

- (NSString *)wr_formattedDate
{
    NSCalendar *gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
    
    // Today's date
    NSDate *today = [NSDate new];
    NSDateComponents *todayDateComponents = [gregorian components:DayMonthYearUnits fromDate:today];
    NSDateComponents *todayYearComponents = [gregorian components:NSCalendarUnitYear fromDate:today];
    
    // Yesterday
    NSDateComponents *componentsToSubtract = [[NSDateComponents alloc] init];
    componentsToSubtract.day = - 1;
    NSDate *yesterday = [gregorian dateByAddingComponents:componentsToSubtract toDate:today options:0];
    NSDateComponents *yesterdayComponents = [gregorian components:DayMonthYearUnits fromDate:yesterday];
    // This week
    NSDateComponents *thisWeekComponents = [gregorian components:WeekMonthYearUnits fromDate:today];
    
    // Received date
    NSDateComponents *dateComponents = [gregorian components:DayMonthYearUnits fromDate:self];
    NSDateComponents *weekComponents = [gregorian components:WeekMonthYearUnits fromDate:self];
    NSDateComponents *yearComponents = [gregorian components:NSCalendarUnitYear fromDate:self];
    
    NSTimeInterval intervalSinceDate = - [self timeIntervalSinceNow];
    
    BOOL isToday = [todayDateComponents isEqual:dateComponents];
    BOOL isYesterday = [yesterdayComponents isEqual:dateComponents];
    BOOL isThisWeek = [thisWeekComponents isEqual:weekComponents];
    BOOL isThisYear = [todayYearComponents isEqual:yearComponents];
    
    NSLocale *locale = [NSLocale currentLocale];
    
    NSString *dateString = nil;
    
    // use this to format clock times, so they are correctly formatted to 12/24 hours according to locale
    static NSDateFormatter *clockTimeFormatter;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        clockTimeFormatter = [[NSDateFormatter alloc] init];
        clockTimeFormatter.dateStyle = NSDateFormatterNoStyle;
        clockTimeFormatter.timeStyle = NSDateFormatterShortStyle;
    });
    
    // Date is within the last hour
    if (intervalSinceDate < NSTimeIntervalOneHour) {
        
        // Creating and configuring date formatters is insanely expensive.
        // This is why there’s a bunch of statically configured ones here that are reused.
        
        static TTTTimeIntervalFormatter *timeIntervalFormatter;
        static dispatch_once_t oneHourToken;
        dispatch_once(&oneHourToken, ^{
            timeIntervalFormatter = [[TTTTimeIntervalFormatter alloc] init];
            timeIntervalFormatter.presentTimeIntervalMargin = 60;
            timeIntervalFormatter.locale = locale;
            timeIntervalFormatter.usesApproximateQualifier = NO;
            timeIntervalFormatter.usesIdiomaticDeicticExpressions = YES;
        });
        
        dateString = [timeIntervalFormatter stringForTimeInterval:- intervalSinceDate];
    }
    // Date is from today or yesterday
    else if (isToday || isYesterday) {
        
        static NSDateFormatter *todayYesterdayFormatter;
        static dispatch_once_t todayYesterdayToken;
        dispatch_once(&todayYesterdayToken, ^{
            todayYesterdayFormatter = [[NSDateFormatter alloc] init];
            todayYesterdayFormatter.locale = locale;
            [todayYesterdayFormatter setTimeStyle:NSDateFormatterShortStyle];
            todayYesterdayFormatter.doesRelativeDateFormatting = YES;
        });
        NSDateFormatterStyle dateStyle = isToday ? NSDateFormatterNoStyle : NSDateFormatterMediumStyle;
        [todayYesterdayFormatter setDateStyle:dateStyle];
        
        dateString = [todayYesterdayFormatter stringFromDate:self];
    }
    else if (isThisWeek) {
        
        static NSDateFormatter *thisWeekFormatter;
        static dispatch_once_t thisWeekToken;
        dispatch_once(&thisWeekToken, ^{
            thisWeekFormatter = [[NSDateFormatter alloc] init];
            NSString *formatString = [NSDateFormatter dateFormatFromTemplate:@"EEEE" options:0
                                                                      locale:locale];
            [thisWeekFormatter setDateFormat:formatString];
        });
        
        dateString = [NSString stringWithFormat:@"%@ %@", [thisWeekFormatter stringFromDate:self], [clockTimeFormatter stringFromDate:self]];
    }
    else {
        
        static NSDateFormatter *elseFormatter;
        static dispatch_once_t elseToken;
        dispatch_once(&elseToken, ^{
            NSString *formatString = nil;
            
            if (isThisYear) {
                formatString = [NSDateFormatter dateFormatFromTemplate:@"EEEEdMMMM" options:0 locale:locale];
            }
            else {
                formatString = [NSDateFormatter dateFormatFromTemplate:@"EEEEdMMMMYYYY" options:0 locale:locale];
            }
            elseFormatter = [[NSDateFormatter alloc] init];
            [elseFormatter setDateFormat:formatString];
        });
        
        dateString = [NSString stringWithFormat:@"%@ %@", [elseFormatter stringFromDate:self], [clockTimeFormatter stringFromDate:self]];
    }
    
    return dateString;
}
@end
