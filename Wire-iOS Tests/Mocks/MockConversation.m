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


#import "MockConversation.h"


@implementation MockConversation

#pragma mark - Mockable

- (instancetype)initWithJSONObject:(NSDictionary *)jsonObject
{
    self = [self init];
    
    if (self) {
        for (NSString *key in jsonObject.allKeys) {
            id value = jsonObject[key];
            [self setValue:value forKey:key];
        }
    }
    return self;
}

- (instancetype)init
{
    self = [super init];
    
    if (self) {
        self.isConversationEligibleForVideoCalls = YES;
    }
    
    return self;
}

- (BOOL)isKindOfClass:(Class)aClass
{
    if ([aClass isSubclassOfClass:[ZMConversation class]]) {
        return YES;
    } else {
        return [super isKindOfClass:aClass];
    }
}

- (ZMUser *)firstActiveParticipantOtherThanSelf
{
    return nil;
}

- (NSArray *)messages;
{
    return nil;
}

- (BOOL)isCallingSupported;
{
    return NO;
}

- (id<ZMConversationMessage>)firstUnreadMessage
{
    return nil;
}

- (NSManagedObjectContext *)managedObjectContext
{
    return nil;
}

- (BOOL)isSelfAnActiveMember
{
    return YES;
}

@end
