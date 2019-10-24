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

#import <Foundation/Foundation.h>
#import "MessageAction.h"

NS_ASSUME_NONNULL_BEGIN

@protocol ZMConversationMessage;

@class MessagePresenter;
@class MediaPlayerController;

@interface MessagePresenter : NSObject

/// Container of the view that hosts popover controller.
@property (nonatomic, nullable, weak) UIViewController *targetViewController;
/// Controller that would be the modal parent of message details.
@property (nonatomic, nullable, weak) UIViewController *modalTargetController;

@property (nonatomic, readonly) BOOL waitingForFileDownload;

- (void)openDocumentControllerForMessage:(id<ZMConversationMessage>)message targetView:(UIView *)targetView withPreview:(BOOL)preview;

@end

NS_ASSUME_NONNULL_END
