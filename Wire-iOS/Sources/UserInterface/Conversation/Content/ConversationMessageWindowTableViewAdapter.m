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

// Cells
#import "TextMessageCell.h"
#import "ImageMessageCell.h"
#import "PingCell.h"
#import "ConnectionRequestCell.h"

#import "Wire-Swift.h"

@implementation ConversationMessageWindowTableViewAdapter

- (instancetype)initWithTableView:(UITableView *)tableView messageWindow:(ZMConversationMessageWindow *)messageWindow
{
    self = [super init];
    
    if (self) {
        self.tableView = tableView;
        self.messageWindow = messageWindow;
        self.messageWindowObserverToken = [MessageWindowChangeInfo addObserver:self forWindow:self.messageWindow];
        self.firstUnreadMessage = self.messageWindow.conversation.firstUnreadMessage;
        
        [self registerTableCellClasses];
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

#pragma mark - ZMConversationMessageWindowObserver

- (void)conversationWindowDidChange:(MessageWindowChangeInfo *)change
{
    BOOL initialContentLoad = self.messageWindow.messages.count == change.insertedIndexes.count && change.deletedIndexes.count == 0;
    BOOL updateOnlyChange = change.insertedIndexes.count == 0 && change.deletedIndexes.count == 0 && change.zm_movedIndexPairs.count == 0;
    BOOL expandedWindow = change.insertedIndexes.count > 0 && change.insertedIndexes.lastIndex == self.messageWindow.messages.count - 1;
    
    [self stopAudioPlayerForDeletedMessages:change.deletedObjects];

    // We want to reload if this is the initial content load or if the message window did expand to the top
    // (e.g. when scrolling to the top), as there are also insertions at the top if messages get deleted we do not
    // trigger a full reload if there are also deleted indices.
    if (initialContentLoad || (expandedWindow && !change.deletedIndexes.count) || change.needsReload) {
        [self.tableView reloadData];
    }
    else if (! updateOnlyChange) {
        [self.tableView beginUpdates];
        
        if (change.deletedIndexes.count) {
            [self.tableView deleteRowsAtIndexPaths:[change.deletedIndexes indexPaths] withRowAnimation:UITableViewRowAnimationFade];
        }
        
        if (change.insertedIndexes.count) {
            [self.tableView insertRowsAtIndexPaths:[change.insertedIndexes indexPaths] withRowAnimation:UITableViewRowAnimationFade];
        }
        
        [change.zm_movedIndexPairs enumerateObjectsUsingBlock:^(ZMMovedIndex *moved, NSUInteger idx, BOOL *stop) {
            NSIndexPath *from = [NSIndexPath indexPathForRow:moved.from inSection:0];
            NSIndexPath *to = [NSIndexPath indexPathForRow:moved.to inSection:0];
            [self.tableView moveRowAtIndexPath:from toIndexPath:to];
        }];
        
        if (change.insertedIndexes.count > 0 || change.deletedIndexes.count > 0 || change.zm_movedIndexPairs.count > 0) {
            // deleted index paths need to be passed in because this method is called before `endUpdates`, when
            // the cells have not yet been removed from the view but the messages they refer to can not be
            // materialized anymore
            [self reconfigureVisibleCellsWithDeletedIndexPaths:[NSSet setWithArray:[change.deletedIndexes indexPaths]]];
        }
        
        [self.tableView endUpdates];
    }
}

- (void)setEditingMessage:(id <ZMConversationMessage>)editingMessage
{
    _editingMessage = editingMessage;
    [self reconfigureVisibleCellsWithDeletedIndexPaths:nil];
}

- (void)reconfigureVisibleCellsWithDeletedIndexPaths:(NSSet<NSIndexPath *>*)deletedIndexPaths
{
    for (ConversationCell *cell in self.tableView.visibleCells) {
        
        if (! [cell isKindOfClass:ConversationCell.class]) {
            continue;
        }
        
        // ignore deleted cells, or it will configure them, which might be
        // unsafe if the original message was deleted
        if (deletedIndexPaths != nil) {
            NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];
            if ([deletedIndexPaths containsObject:indexPath]) {
                continue;
            }
        }
        cell.searchQueries = self.searchQueries;
        [self configureConversationCell:cell withMessage:cell.message];
    }
}

- (void)messagesInsideWindow:(ZMConversationMessageWindow *)window didChange:(NSArray<MessageChangeInfo *> *)messageChangeInfos
{
    BOOL needsToLayoutCells = NO;
    
    for (UITableViewCell *cell in self.tableView.visibleCells) {
        if ([cell isKindOfClass:[ConversationCell class]]) {
            ConversationCell *conversationCell = (ConversationCell *)cell;
            
            for (MessageChangeInfo *changeInfo in messageChangeInfos) {
                if ([changeInfo.message isEqual:conversationCell.message]) {
                    needsToLayoutCells |= [conversationCell updateForMessage:changeInfo];
                }
            }
        }
    }
    
    if (needsToLayoutCells) {
        // Make table view to update cells with animation
        [self.tableView beginUpdates];
        [self.tableView endUpdates];
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
