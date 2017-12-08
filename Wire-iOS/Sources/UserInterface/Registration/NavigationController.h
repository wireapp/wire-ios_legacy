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


@import UIKit;
@import WireExtensionComponents;


@interface NavigationController : UINavigationController

@property (nonatomic, assign) BOOL backButtonEnabled;
@property (nonatomic, assign) BOOL rightButtonEnabled;
@property (nonatomic, assign) BOOL logoEnabled;

@property (nonatomic, readonly) IconButton *backButton;

- (void)updateRightButtonWithTitle:(NSString *)title
                            target:(id)target
                            action:(SEL)action
                          animated:(BOOL)animated;

- (void)updateRightButtonWithIconType:(ZetaIconType)iconType
                             iconSize:(ZetaIconSize)iconSize
                               target:(id)target
                               action:(SEL)action
                             animated:(BOOL)animated;

@end


@interface UIViewController (NavigationController)

@property (nonatomic, readonly) NavigationController *wr_navigationController;

@end
