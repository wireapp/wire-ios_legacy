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


#import "MockUser.h"

@implementation MockUser

#pragma mark - Mockable

- (instancetype)initWithJSONObject:(NSDictionary *)jsonObject
{
    self = [super init];
    if (self) {
        for (NSString *key in jsonObject.allKeys) {
            id value = jsonObject[key];
            [self setValue:value forKey:key];
        }
    }
    return self;
}

+ (NSArray *)mockUsers
{
    static NSArray *mockUsers = nil;
    if (mockUsers == nil) {
        mockUsers = [MockLoader mockObjectsOfClass:[MockUser class] fromFile:@"people-01.json"];
    }
    return mockUsers;
}

+ (MockUser *)mockSelfUser
{
    static MockUser *selfUser = nil;

    if (selfUser == nil) {
        selfUser = (MockUser *)self.mockUsers.lastObject;
        selfUser.isSelfUser = YES;
    }
    
    return selfUser;
}

+ (ZMUser<ZMEditableUser> *)selfUserInUserSession:(ZMUserSession *)session
{
    return (id)self.mockSelfUser;
}

- (NSArray<MockUserClient *> *)featureWithUserClients:(NSUInteger)numClients
{
    NSMutableArray *newClients = [NSMutableArray array];
    for (NSUInteger i = 0; i < numClients; i++) {
        MockUserClient *mockClient = [[MockUserClient alloc] init];
        mockClient.user = (id)self;
        [newClients addObject:mockClient];
    }
    self.clients = newClients.set;
    return newClients;
}

+ (id<ZMUserObserverOpaqueToken>)addUserObserver:(id<ZMUserObserver>)observer forUsers:(NSArray *)users inUserSession:(ZMUserSession *)userSession
{
    return nil;
}

- (NSString *)emailAddress
{
    return @"test@email.com";
}

- (NSString *)phoneNumber
{
    return @"+123456789";
}

#pragma mark - ZMBareUser

@synthesize name;
@synthesize displayName;
@synthesize initials;
@synthesize isSelfUser;
@synthesize isConnected;
@synthesize accentColorValue;
@synthesize imageMediumData;
@synthesize imageSmallProfileData;
@synthesize imageSmallProfileIdentifier;
@synthesize imageMediumIdentifier;
@synthesize canBeConnected;
@synthesize connectionRequestMessage;
@synthesize topCommonConnections;
@synthesize totalCommonConnections;

- (void)connectWithMessageText:(NSString *)text completionHandler:(dispatch_block_t)handler
{
    if (handler) {
        handler();
    }        
}

- (id<ZMCommonContactsSearchToken>)searchCommonContactsInUserSession:(ZMUserSession *)session
                                                        withDelegate:(id<ZMCommonContactsSearchDelegate>)delegate
{
    return nil;
}

- (BOOL)conformsToProtocol:(Protocol *)aProtocol
{
    if (aProtocol == @protocol(ZMBareUser)) {
        return YES;
    }
    else {
        return [super conformsToProtocol:aProtocol];
    }
}

- (NSData *)imageMediumData
{
    return nil;
}

- (NSString *)imageMediumIdentifier
{
    return @"identifier";
}

- (NSData *)imageSmallProfileData
{
    return nil;
}

- (NSString *)imageSmallProfileIdentifier
{
    return @"imagesmallidentifier";
}

- (UIColor *)accentColor
{
    return [UIColor colorWithRed:0.141 green:0.552 blue:0.827 alpha:1.0];
}

- (id)observableKeys
{
    return @[];
}

- (id)clients
{
    return @[];
}
    
- (BOOL)isPendingApproval {
    return false;
}

- (BOOL)isKindOfClass:(Class)aClass
{
    if ([aClass isSubclassOfClass:[ZMUser class]]) {
        return YES;
    } else {
        return [super isKindOfClass:aClass];
    }
}

- (void)requestSmallProfileImageInUserSession:(ZMUserSession *)userSession
{
    // no-op
}

- (void)requestMediumProfileImageInUserSession:(ZMUserSession *)userSession
{
    // no-op
}

#pragma mark - ZMBareUserConnection

@synthesize isPendingApprovalByOtherUser = _isPendingApprovalByOtherUser;

@end
