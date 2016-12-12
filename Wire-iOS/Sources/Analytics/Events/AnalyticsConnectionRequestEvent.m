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


#import "AnalyticsConnectionRequestEvent.h"



static NSString *AnalyticsConnectionRequestMethodToString(AnalyticsConnectionRequestMethod method)
{
    switch (method) {
        case AnalyticsConnectionRequestMethodUserSearch:
            return @"startui";
        case AnalyticsConnectionRequestMethodParticipants:
            return @"participants";
        case AnalyticsConnectionRequestMethodUnknown:
            return @"unknown";
    }
}



@interface AnalyticsConnectionRequestEvent ()

@property (assign, nonatomic, readwrite) NSUInteger connectRequestSharedContacts;
@property (assign, nonatomic, readwrite) AnalyticsConnectionRequestMethod AnalyticsConnectionRequestMethod;

@end

@implementation AnalyticsConnectionRequestEvent

+ (instancetype)eventForAddContactMethod:(AnalyticsConnectionRequestMethod)connectionRequestMethod connectRequestCount:(NSUInteger)connectCount
{
    return [[AnalyticsConnectionRequestEvent alloc]initForAddContactMethod:connectionRequestMethod connectRequestCount:connectCount];
}

- (instancetype)initForAddContactMethod:(AnalyticsConnectionRequestMethod)connectionRequestMethod connectRequestCount:(NSUInteger)connectCount
{
    self = [super init];
    if (self) {
        self.AnalyticsConnectionRequestMethod = connectionRequestMethod;
        self.connectRequestSharedContacts = connectCount;
    }
    return self;

}

- (NSString *)eventTag
{
    return @"connect.sent_connect_request";
}

- (NSDictionary *)attributesDump
{
    return @{
             @"common_users_count": @(self.connectRequestSharedContacts),
             @"context": AnalyticsConnectionRequestMethodToString(self.AnalyticsConnectionRequestMethod)
             };
}

@end
