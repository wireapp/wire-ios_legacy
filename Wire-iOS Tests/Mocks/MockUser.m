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

static id<UserType> mockSelfUser = nil;

@implementation MockUser

#pragma mark - Mockable

- (instancetype)initWithJSONObject:(NSDictionary *)jsonObject
{
    self = [super init];
    if (self) {
        _clients = [NSSet set];
        self.isTeamMember = YES;
        for (NSString *key in jsonObject.allKeys) {
            id value = jsonObject[key];
            if (value == NSNull.null) { continue; }
            [self setValue:value forKey:key];

        }
    }
    return self;
}

- (BOOL)isEqual:(id)otherObject
{
    if (![otherObject isKindOfClass:ZMUser.class]) {
        return NO;
    }
    
    return [self.name isEqual:[(ZMUser *)otherObject name]];
}

+ (NSArray *)mockUsers
{
    return [self realMockUsers];
}

+ (NSArray *)realMockUsers
{
    return [MockLoader mockObjectsOfClass:[self class] fromFile:@"people-01.json"];
}

+ (MockUser *)mockSelfUser
{
    if (mockSelfUser == nil) {
        MockUser *mockUser = (MockUser *)self.mockUsers.lastObject;
        mockUser.isSelfUser = YES;
        mockSelfUser = (MockUser *)mockUser;
    }
    
    return (MockUser *)mockSelfUser;
}

+ (MockUser *)mockServiceUser
{
    return [[MockUser alloc] initWithJSONObject:@{@"name": @"GitHub",
                                                  @"displayName": @"GitHub",
                                                  @"isSelfUser": @false,
                                                  @"isServiceUser": @true,
                                                  @"isConnected": @true,
                                                  @"accentColorValue": @1}];
}

+ (void)setMockSelfUser:(id<UserType>)newMockUser
{
    mockSelfUser = newMockUser;
}

+ (MockUser *)mockUserFor:(ZMUser *)user
{
    return (MockUser *)user;
}

- (BOOL)isGuestInConversation:(ZMConversation *)conversation
{
    return self.isGuestInConversation;
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


- (NSString *)expirationDisplayString
{
    return @"";
}

#pragma mark - ZMBareUser

@synthesize name;
@synthesize displayName;
@synthesize initials;
@synthesize isSelfUser;
@synthesize isConnected;
@synthesize accentColorValue;
@synthesize previewImageData;
@synthesize completeImageData;
@synthesize connectionRequestMessage;
@synthesize totalCommonConnections;
@synthesize smallProfileImageCacheKey;
@synthesize mediumProfileImageCacheKey;
@synthesize isTeamMember;
@synthesize readReceiptsEnabled;

- (BOOL)conformsToProtocol:(Protocol *)aProtocol
{
    if (aProtocol == @protocol(UserType)) {
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

- (UIColor *)nameAccentColor
{
    return [UIColor colorWithRed:0.141 green:0.552 blue:0.827 alpha:0.7];
}

- (id)observableKeys
{
    return @[];
}

- (void)refreshData
{
    // no-op
}

- (void)connectWithMessage:(NSString * _Nonnull)message {
    
}

- (void)imageDataFor:(enum ProfileImageSize)size queue:(dispatch_queue_t _Nonnull)queue completion:(void (^ _Nonnull)(NSData * _Nullable))completion {
    switch (size) {
        case ProfileImageSizePreview:
            completion(previewImageData);
            break;
        case ProfileImageSizeComplete:
            completion(completeImageData);
    }
}


- (BOOL)isGuestIn:(ZMConversation * _Nonnull)conversation {
    return self.isGuestInConversation;
}


- (void)requestCompleteProfileImage {
    
}


- (void)requestPreviewProfileImage {
    
}

- (Team *)team
{
    return nil;
}

- (BOOL)isPendingApproval
{
    return false;
}

- (BOOL)canManageTeam
{
    return false;
}

- (BOOL)hasTeam
{
    return false;
}

- (BOOL)usesCompanyLogin
{
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

- (NSString *)displayNameInConversation:(MockConversation *)conversation
{
    return self.displayName;
}

- (void)fetchUserClients
{
    
}

- (NSSet<UserClient *> *)clientsRequiringUserAttention
{
    return [NSSet new];
}

- (ZMUser *)user
{
    return nil;
}

#pragma mark - ZMBareUserConnection

@synthesize isPendingApprovalByOtherUser = _isPendingApprovalByOtherUser;

@synthesize isServiceUser;

@end
