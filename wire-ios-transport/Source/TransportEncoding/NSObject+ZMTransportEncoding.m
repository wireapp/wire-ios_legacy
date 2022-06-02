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


@import WireSystem;

#import "NSObject+ZMTransportEncoding.h"

static NSDateFormatter* iso8601DateFormatter;

@implementation NSDate (ZMTransportEncoding)

// NOTE: can be replaced by NSISO8601DateFormatter when we drop support for iOS 10
+ (NSDateFormatter *)ISO8601DateFormatter
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        NSLocale *enUSPOSIXLocale = [NSLocale localeWithLocaleIdentifier:@"en_US_POSIX"];
        [dateFormatter setLocale:enUSPOSIXLocale];
        [dateFormatter setTimeZone:[NSTimeZone timeZoneWithAbbreviation: @"UTC"]];
        [dateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss.SSSZZZZZ"];
        [dateFormatter setCalendar:[NSCalendar calendarWithIdentifier:NSCalendarIdentifierGregorian]];
        
        iso8601DateFormatter = dateFormatter;
    });
        
    return iso8601DateFormatter;
}

+ (instancetype)dateWithTransportString:(NSString *)transportString;
{
    return [[self ISO8601DateFormatter] dateFromString:transportString];
}

- (NSString *)transportString;
{
    return [[NSDate ISO8601DateFormatter] stringFromDate:self];
}

@end




@implementation NSUUID (ZMTransportEncoding)

+ (instancetype)uuidWithTransportString:(NSString *)transportString;
{
    return [[NSUUID alloc] initWithUUIDString:transportString];
}

- (NSString *)transportString;
{
    return [[self UUIDString] lowercaseString];
}

@end
