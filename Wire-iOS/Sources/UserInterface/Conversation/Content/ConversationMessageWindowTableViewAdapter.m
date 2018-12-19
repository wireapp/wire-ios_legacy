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


#import "ConversationMessageWindowTableViewAdapter.h"
#import "ConversationMessageWindowTableViewAdapter+Private.h"
#import "ZMConversationMessageWindow+Formatting.h"
#import "NSIndexSet+IndexPaths.h"
#import "Analytics.h"
#import "NSIndexSet+IndexPaths.h"

#import "Wire-Swift.h"

@implementation ConversationMessageWindowTableViewAdapter

- (instancetype)initWithTableView:(UpsideDownTableView *)tableView messageWindow:(ZMConversationMessageWindow *)messageWindow
{
    self = [super init];
    
    if (self) {
        self.tableView = tableView;
        self.messageWindow = messageWindow;
        self.messageWindowObserverToken = [MessageWindowChangeInfo addObserver:self forWindow:self.messageWindow];
        self.firstUnreadMessage = self.messageWindow.conversation.firstUnreadMessage;
        self.sectionControllers = [[NSMutableDictionary alloc] init];
        self.actionControllers = [[NSMutableDictionary alloc] init];
    }
    
    return self;
}

- (void)stopAudioPlayerForDeletedMessages:(NSSet *)deletedMessages
{
    AudioTrackPlayer *audioTrackerPlayer = [AppDelegate sharedAppDelegate].mediaPlaybackManager.audioTrackPlayer;
    
    for (NSObject *deletedMessage in deletedMessages) {
        if (audioTrackerPlayer.sourceMessage == deletedMessage) {
            [audioTrackerPlayer stop];
        }
    }
}

- (ConversationMessageActionController *)actionControllerForMessage:(id<ZMConversationMessage>)message
{
    NSString *identifier = message.objectIdentifier;
    ConversationMessageActionController *cachedEntry = [self.actionControllers objectForKey:identifier];

    if (cachedEntry) {
        return cachedEntry;
    }

    ConversationMessageActionController *actionController = [[ConversationMessageActionController alloc] initWithResponder:self.messageActionResponder message:message context: ConversationMessageActionControllerContextContent];
    [self.actionControllers setObject:actionController forKey:identifier];

    return actionController;
}

- (void)registerCellIfNeeded:(AnyConversationMessageCellDescription *)cellDescription inTableView:(UITableView *)tableView
{
    if ([self.registeredCells containsObject:cellDescription.baseType]) {
        return;
    }

    [cellDescription registerInTableView:tableView];
    [self.registeredCells addObject:cellDescription.baseType];
}

- (void)setEditingMessage:(id <ZMConversationMessage>)editingMessage
{
    _editingMessage = editingMessage;
    [self reconfigureVisibleSections];
}

- (void)messagesInsideWindow:(ZMConversationMessageWindow *)window didChange:(NSArray<MessageChangeInfo *> *)messageChangeInfos
{
    for (MessageChangeInfo *changeInfo in messageChangeInfos) {
        NSInteger sectionIndex = [self.messageWindow.messages indexOfObject:changeInfo.message];

        if (sectionIndex != NSNotFound) {
            ConversationMessageSectionController *controller = [self sectionControllerAt:sectionIndex in:self.tableView];
            [controller configureAt:sectionIndex in:self.tableView];
        }
    }
}

- (void)configureConversationCell:(ConversationCell *)conversationCell withMessage:(nullable id<ZMConversationMessage>)message
{
    // If a message has been deleted or nil, we don't try to configure it
    if (message == nil || message.hasBeenDeleted) { return; }
    
    ConversationCellLayoutProperties *layoutProperties = [self.messageWindow layoutPropertiesForMessage:message firstUnreadMessage:self.firstUnreadMessage];
    
    conversationCell.selected = [message isEqual:self.selectedMessage];
    conversationCell.beingEdited = [message isEqual:self.editingMessage];
    [conversationCell configureForMessage:message layoutProperties:layoutProperties];
}

- (void)expandMessageWindow
{
    if (! self.expandingWindow) {
        self.expandingWindow = YES;
        
        [self.messageWindow moveUpByMessages:25];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            self.expandingWindow = NO;
        });
    }
}

@end

