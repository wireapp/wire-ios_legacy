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


#import "LineNumberLogFormatter.h"
#import <libkern/OSAtomic.h>

static NSString * dateFormatString = @"yyyy/MM/dd HH:mm:ss:SSS";



@interface LineNumberLogFormatter () {
    int atomicLoggerCount;
    NSDateFormatter *threadUnsafeDateFormatter;
}

@end



@implementation LineNumberLogFormatter

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.appendFileName = YES;
        
        threadUnsafeDateFormatter = [[NSDateFormatter alloc] init];
        [threadUnsafeDateFormatter setFormatterBehavior:NSDateFormatterBehavior10_4];
        [threadUnsafeDateFormatter setDateFormat:dateFormatString];
    }
    return self;
}

- (NSString *)formatLogMessage:(DDLogMessage *)logMessage
{
    NSString *superResult = [super formatLogMessage:logMessage];
    // super formatLogMessage respects the context. This class don't.
    if (! superResult) {
        return nil;
    }
    
    NSString *logLevel;
    switch (logMessage.flag)
    {
        case DDLogFlagError : logLevel = @"ERROR"; break;
        case DDLogFlagWarning  : logLevel = @"WARN "; break;
        case DDLogFlagInfo  : logLevel = @"INFO "; break;
        case DDLogFlagDebug : logLevel = @"DEBUG"; break;
        default             : logLevel = @"VERB "; break;
    }
    
    NSString *dateAndTime = [self stringFromDate:(logMessage.timestamp)];
    NSString *fileName = logMessage.fileName;
    
    if (self.appendFileName) {
        return [NSString stringWithFormat:@"[%@] (%@) %@ (%@:%lu)", dateAndTime, logLevel, logMessage.message, fileName, (unsigned long)logMessage.line];
    } else {
        return [NSString stringWithFormat:@"[%@] (%@) %@", dateAndTime, logLevel, logMessage.message];
    }
}

- (NSString *)stringFromDate:(NSDate *)date
{
    int32_t loggerCount = OSAtomicAdd32(0, &atomicLoggerCount);
    
    if (loggerCount <= 1)
    {
        // Single-threaded mode.
        
        if (threadUnsafeDateFormatter == nil)
        {
            threadUnsafeDateFormatter = [[NSDateFormatter alloc] init];
            [threadUnsafeDateFormatter setFormatterBehavior:NSDateFormatterBehavior10_4];
            [threadUnsafeDateFormatter setDateFormat:dateFormatString];
        }
        
        return [threadUnsafeDateFormatter stringFromDate:date];
    }
    else
    {
        // Multi-threaded mode.
        // NSDateFormatter is NOT thread-safe.
        
        NSString *key = @"MyCustomFormatter_NSDateFormatter";
        
        NSMutableDictionary *threadDictionary = [[NSThread currentThread] threadDictionary];
        NSDateFormatter *dateFormatter = [threadDictionary objectForKey:key];
        
        if (dateFormatter == nil)
        {
            dateFormatter = [[NSDateFormatter alloc] init];
            [dateFormatter setFormatterBehavior:NSDateFormatterBehavior10_4];
            [dateFormatter setDateFormat:dateFormatString];
            
            [threadDictionary setObject:dateFormatter forKey:key];
        }
        
        return [dateFormatter stringFromDate:date];
    }
}

- (void)didAddToLogger:(id <DDLogger>)logger
{
    OSAtomicIncrement32(&atomicLoggerCount);
}

- (void)willRemoveFromLogger:(id <DDLogger>)logger
{
    OSAtomicDecrement32(&atomicLoggerCount);
}

@end
