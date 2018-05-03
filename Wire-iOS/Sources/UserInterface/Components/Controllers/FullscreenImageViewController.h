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

@class CenteredScrollView;
@protocol ZMConversationMessage;

NS_ASSUME_NONNULL_BEGIN
@class FullscreenImageViewController;

@protocol ScreenshotProvider <NSObject>
- (nullable UIView *)backgroundScreenshotForController:(FullscreenImageViewController *)fullscreenController;
@end

@protocol MenuVisibilityController <NSObject>
@property (nonatomic, readonly) BOOL menuVisible;
- (void)fadeAndHideMenu:(BOOL)hidden;
@end

@interface FullscreenImageViewController : UIViewController

@property (nonatomic, strong, readonly) UIScrollView *scrollView;
@property (nonatomic, readonly) id<ZMConversationMessage> message;
@property (nonatomic) UIView *snapshotBackgroundView;
@property (nonatomic, weak)   id <MessageActionResponder, ScreenshotProvider, MenuVisibilityController> delegate;
@property (nonatomic) BOOL swipeToDismiss;
@property (nonatomic) BOOL showCloseButton;
@property (nonatomic, copy, nullable) void (^dismissAction)(__nullable dispatch_block_t);

- (instancetype)initWithMessage:(id<ZMConversationMessage>)message;

- (void)showChrome:(BOOL)shouldShow;

- (void)setupSnapshotBackgroundView;
- (void)dismissWithCompletion:(nullable dispatch_block_t)completion;
- (void)performSaveImageAnimationFromView:(UIView *)saveView;
@end

NS_ASSUME_NONNULL_END
