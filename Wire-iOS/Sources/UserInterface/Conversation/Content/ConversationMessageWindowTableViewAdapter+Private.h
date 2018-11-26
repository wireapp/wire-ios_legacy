////
// Wire
// Copyright (C) 2018 Wire Swiss GmbH
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

NS_ASSUME_NONNULL_BEGIN

static NSString *const ConversationNameChangedCellId        = @"ConversationNameChangedCell";
static NSString *const ConversationTextCellId               = @"ConversationTextCell";
static NSString *const ConversationImageCellId              = @"ConversationImageCell";
static NSString *const ConversationConnectionRequestCellId  = @"ConversationConnectionRequestCellId";
static NSString *const ConversationMissedCallCellId         = @"ConversationMissedCallCell";
static NSString *const ConversationPerformedCallCellId      = @"ConversationPerformedCallCellId";
static NSString *const ConversationPingCellId               = @"conversationPingCellId";
static NSString *const ConversationNewDeviceCellId          = @"ConversationNewDeviceCellId";
static NSString *const ConversationVerifiedCellId           = @"conversationVerifiedCellId";
static NSString *const ConversationMissingMessagesCellId    = @"conversationMissingMessagesCellId";
static NSString *const ConversationIgnoredDeviceCellId      = @"conversationIgnoredDeviceCellId";
static NSString *const ConversationCannotDecryptCellId      = @"conversationCannotDecryptCellId";
static NSString *const ConversationFileTransferCellId       = @"conversationFileTransferCellId";
static NSString *const ConversationVideoMessageCellId       = @"conversationVideoMessageCellId";
static NSString *const ConversationAudioMessageCellId       = @"conversationAudioMessageCellId";
static NSString *const ConversationLocationMessageCellId    = @"conversationLocationMessageCellId";
static NSString *const ConversationMessageDeletedCellId     = @"conversationMessageDeletedCellId";
static NSString *const ConversationUnknownMessageCellId     = @"conversationUnknownMessageCellId";
static NSString *const ConversationMessageTimerUpdateCellId = @"ConversationMessageTimerUpdateCellId";

@class ConversationCell;
@class UpsideDownTableView;
@class ConversationMessageActionController;
@class ConversationMessageSectionController;

@interface ConversationMessageWindowTableViewAdapter ()

- (void)configureConversationCell:(ConversationCell *)conversationCell withMessage:(nullable id<ZMConversationMessage>)message;

@property (nonatomic) UpsideDownTableView * _Nonnull tableView;
@property (nonatomic) ZMConversationMessageWindow * _Nonnull messageWindow;
@property (nonatomic) id _Nonnull messageWindowObserverToken;
@property (nonatomic) BOOL expandingWindow;

@property (nonatomic, strong) NSMutableArray<Class> *registeredCells;
@property (nonatomic, strong) NSMutableDictionary<NSString *, ConversationMessageSectionController *> *sectionControllers;
@property (nonatomic, strong) NSMutableDictionary<NSString *, ConversationMessageActionController *> *actionControllers;

NS_ASSUME_NONNULL_END

@end
