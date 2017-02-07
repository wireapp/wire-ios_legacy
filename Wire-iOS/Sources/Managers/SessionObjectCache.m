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


#import "SessionObjectCache.h"
#import "zmessaging+iOS.h"
#import "AppDelegate.h"



@interface SessionObjectCache ()

@property (nonatomic, strong, readwrite) ZMUserSession *userSession;

/// Cached, auto-updating model objects
@property (nonatomic, readwrite) ZMConversationList *conversationList;
@property (nonatomic, readwrite) ZMConversationList *archivedConversations;
@property (nonatomic, readwrite) ZMConversationList *allConversations;
@property (nonatomic, readwrite) ZMConversationList *clearedConversations;
@property (nonatomic, readwrite) ZMConversationList *pendingConnectionRequests;

@end




@implementation SessionObjectCache

+ (instancetype)sharedCache
{
    AppDelegate *appDelegate = [AppDelegate sharedAppDelegate];
    return appDelegate.sessionObjectCache;
}

- (instancetype)initWithUserSession:(ZMUserSession *)session
{
    self = [super init];
    if (self) {
        self.userSession = session;
    }
    return self;
}

- (void)refetchConversationLists
{
    if (self.userSession != nil) {
        [ZMConversationList refetchAllListsInUserSession:self.userSession];
    }
}

- (ZMConversationList *)conversationList
{
    if (_conversationList == nil && self.userSession != nil) {        
        _conversationList = [ZMConversationList conversationsInUserSession:self.userSession];
    }
    return _conversationList;
}

- (ZMConversationList *)archivedConversations
{    
    if (_archivedConversations == nil && self.userSession != nil) {
        _archivedConversations = [ZMConversationList archivedConversationsInUserSession:self.userSession];
    }
    return _archivedConversations;
}

- (ZMConversationList *)pendingConnectionRequests
{
    if (_pendingConnectionRequests == nil && self.userSession != nil) {
        _pendingConnectionRequests = [ZMConversationList pendingConnectionConversationsInUserSession:self.userSession];
    }
    return _pendingConnectionRequests;
}

- (ZMConversationList *)clearedConversations
{
    if (_clearedConversations == nil && self.userSession != nil) {
        _clearedConversations = [ZMConversationList clearedConversationsInUserSession:self.userSession];
    }
    return _clearedConversations;
}

- (ZMConversationList *)allConversations
{
    if (_allConversations == nil && self.userSession != nil) {
        _allConversations = [ZMConversationList conversationsIncludingArchivedInUserSession:self.userSession];
    }
    return _allConversations;
}

- (NSUInteger)totalConversationsCount
{
    if (_allConversations != nil) {
        return self.allConversations.count;
    }
    else {
        return self.archivedConversations.count + self.conversationList.count;
    }
}

@end
