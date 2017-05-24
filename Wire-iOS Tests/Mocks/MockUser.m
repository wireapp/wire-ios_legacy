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
#import "MockConversation.h"

static id<ZMBareUser> mockSelfUser = nil;

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
    return [MockLoader mockObjectsOfClass:[self class] fromFile:@"people-01.json"];
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

+ (void)setMockSelfUser:(id<ZMBareUser>)newMockUser
{
    mockSelfUser = newMockUser;
}

+ (ZMUser<ZMEditableUser> *)selfUserInUserSession:(ZMUserSession *)session
{
    return mockSelfUser ? : (id)self.mockSelfUser;
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
@synthesize totalCommonConnections;
@synthesize smallProfileImageCacheKey;
@synthesize mediumProfileImageCacheKey;

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

- (void)doesNotRecognizeSelector:(SEL)aSelector
{

}

- (NSData *)imageMediumData
{
    return nil;
}

- (AddressBookEntry *)addressBookEntry
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

- (UIColor *)nameAccentColor
{
    return [UIColor colorWithRed:0.141 green:0.552 blue:0.827 alpha:0.7];
}

- (id)observableKeys
{
    return @[];
}

- (id)clients
{
    return @[];
}

- (void)refreshData
{
    // no-op
}

- (NSSet *)teams
{
    return [NSSet set];
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

- (NSString *)displayNameInConversation:(MockConversation *)conversation
{
    return self.displayName;
}

#pragma mark - ZMBareUserConnection

@synthesize isPendingApprovalByOtherUser = _isPendingApprovalByOtherUser;

@end
