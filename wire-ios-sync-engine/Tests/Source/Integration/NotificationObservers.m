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

@import WireDataModel;

#import "NotificationObservers.h"

@interface ChangeObserver ()
@end



@implementation ChangeObserver

- (instancetype)init
{
    self = [super init];
    if (self) {
        _notifications = [[NSMutableArray alloc] init];
        [self startObservering];
    }
    return self;
}

- (void)dealloc
{
    [self stopObservering];
}

- (void)clearNotifications;
{
    [self.notifications removeAllObjects];
}

- (void)startObservering;
{
}

- (void)stopObservering;
{
}

- (void)tearDown;
{
}

@end

@interface ConversationChangeObserver ()
@property (nonatomic, weak) ZMConversation *conversation;
@property (nonatomic) id token;
@end


@implementation ConversationChangeObserver

- (instancetype)initWithConversation:(ZMConversation *)conversation
{
    self = [super init];
    if(self) {
        self.conversation = conversation;
        self.token = [ConversationChangeInfo addObserver:self forConversation:conversation];
    }
    return self;
}

- (void)conversationDidChange:(ConversationChangeInfo *)note;
{
    [self.notifications addObject:note];
    if (self.notificationCallback) {
        self.notificationCallback(note);
    }
}


@end



@interface ConversationListChangeObserver ()
@property (nonatomic, weak) ZMConversationList *conversationList;
@property (nonatomic) id token;
@end

@implementation ConversationListChangeObserver

ZM_EMPTY_ASSERTING_INIT()

- (instancetype)initWithConversationList:(ZMConversationList *)conversationList;
{
    self = [super init];
    if(self) {
        self.conversationList = conversationList;
        self.conversationChangeInfos = [NSMutableArray array];
        self.token = [ConversationListChangeInfo addObserver:self forList:conversationList managedObjectContext:conversationList.managedObjectContext];
    }
    return self;
}

- (void)conversationListDidChange:(ConversationListChangeInfo *)note;
{
    [self.notifications addObject:note];
    if (self.notificationCallback) {
        self.notificationCallback(note);
    }
}

- (void)conversationInsideList:(ZMConversationList *)list didChange:(ConversationChangeInfo *)changeInfo;
{
    NOT_USED(list);
    [self.conversationChangeInfos addObject:changeInfo];
}

@end



@interface UserChangeObserver ()
@property (nonatomic, weak) id<UserType> user;
@property (nonatomic) id token;
@end

@implementation UserChangeObserver

- (instancetype)initWithUser:(ZMUser *)user
{
    return [self initWithUser:user managedObjectContext:user.managedObjectContext];
}

- (instancetype)initWithUser:(id<UserType>)user managedObjectContext:(NSManagedObjectContext *)managedObjectContext
{
    self = [super init];
    if(self) {
        self.user = user;
        self.token = [UserChangeInfo addObserver:self forUser:user inManagedObjectContext:managedObjectContext];
    }
    return self;
}

- (void)startObservering;
{
}

- (void)stopObservering
{
}

- (void)userDidChange:(UserChangeInfo *)info;
{
    [self.notifications addObject:info];
    if (self.notificationCallback) {
        self.notificationCallback(info);
    }
}


@end



@interface MessageChangeObserver ()
@property (nonatomic, weak) ZMMessage *message;
@property (nonatomic) id token;
@end

@implementation MessageChangeObserver

- (instancetype)initWithMessage:(ZMMessage *)message
{
    self = [super init];
    if(self) {
        self.message = message;
        self.token = [MessageChangeInfo addObserver:self forMessage:message managedObjectContext:message.managedObjectContext];
    }
    return self;
}

- (void)messageDidChange:(MessageChangeInfo *)changeInfo
{
    [self.notifications addObject:changeInfo];
}

@end

