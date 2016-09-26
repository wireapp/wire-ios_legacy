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


@import Foundation;
@import zmessaging;
#import "MockLoader.h"
#import "MockUserClient.h"


@interface MockUser : NSObject<ZMBareUser, ZMBareUserConnection, Mockable>
+ (NSArray <ZMUser *> *)mockUsers;
+ (MockUser *)mockSelfUser;
+ (ZMUser<ZMEditableUser> *)selfUserInUserSession:(ZMUserSession *)session;


@property (nonatomic, readwrite) BOOL isBlocked;
@property (nonatomic, readwrite) BOOL isIgnored;
@property (nonatomic, readwrite) BOOL isPendingApprovalByOtherUser;
@property (nonatomic, readwrite) BOOL isPendingApprovalBySelfUser;
@property (nonatomic, assign) BOOL isSelfUser;
@property (nonatomic) NSSet <id<UserClientType>> * clients;
- (UIColor *)accentColor;

- (NSArray<MockUserClient *> *)featureWithUserClients:(NSUInteger)numClients;

@end
