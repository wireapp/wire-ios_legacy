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


#import <UIKit/UIKit.h>

@protocol ZMBareUser;
@class ZMConversation;


@interface BackgroundViewController : UIViewController

@property (nonatomic, weak) ZMConversation *conversation;

@property (nonatomic) BOOL forceFullScreen;

@property (nonatomic, strong) UIColor *overrideFilterColor;

/// Sets the blur percent visibility.  Not animated.
@property (nonatomic, assign) CGFloat blurPercent;

/// Disables the blur. Animated.
@property (nonatomic, assign) BOOL blurDisabled;

- (void)setForceFullScreen:(BOOL)forceFullScreen animated:(BOOL)animated;
/// Sets the blur percent visibility.  Animated.
- (void)setBlurPercentAnimated:(CGFloat)blurPercent;

- (void)setUser:(id<ZMBareUser>)user animated:(BOOL)animated;

- (void)setOverrideUser:(id<ZMBareUser>)user disableColorFilter:(BOOL)disableColorFilter animated:(BOOL)animated;
- (void)setOverrideUser:(id<ZMBareUser>)user disableColorFilter:(BOOL)disableColorFilter animated:(BOOL)animated completionBlock:(dispatch_block_t)completionBlock;

/// Unset the override user and re-enable color filter if it was disabled
- (void)unsetOverrideUserAnimated:(BOOL)animated;

@end
