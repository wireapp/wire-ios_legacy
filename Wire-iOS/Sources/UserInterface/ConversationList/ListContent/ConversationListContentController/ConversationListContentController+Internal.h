//
// Wire
// Copyright (C) 2019 Wire Swiss GmbH
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

@class ConversationListViewModel;

@protocol ConversationListViewModelDelegate;

static NSString * _Nullable const CellReuseIdConnectionRequests = @"CellIdConnectionRequests";
static NSString * _Nullable const CellReuseIdConversation = @"CellId";

NS_ASSUME_NONNULL_BEGIN

@interface ConversationListContentController () <ConversationListViewModelDelegate>

@property (nonatomic, strong) ConversationListViewModel *listViewModel;

@property (nonatomic, nullable) NSObject *activeMediaPlayerObserver;
@property (nonatomic, nullable) MediaPlaybackManager *mediaPlaybackManager;
@property (nonatomic) BOOL focusOnNextSelection;
@property (nonatomic) BOOL animateNextSelection;
@property (nonatomic, nullable) id<ZMConversationMessage> scrollToMessageOnNextSelection;
@property (nonatomic, copy, nullable) dispatch_block_t selectConversationCompletion;
@property (nonatomic) ConversationListCell *layoutCell;
@property (nonatomic) ConversationCallController *startCallController;

@property (nonatomic) UISelectionFeedbackGenerator *selectionFeedbackGenerator;

- (void)ensureCurrentSelection;
- (void)setupViews;
- (void)listViewModelShouldBeReloaded;

@end

@interface ConversationListContentController (PeekAndPop) <UIViewControllerPreviewingDelegate>

- (void)setupViews;

@end

NS_ASSUME_NONNULL_END
