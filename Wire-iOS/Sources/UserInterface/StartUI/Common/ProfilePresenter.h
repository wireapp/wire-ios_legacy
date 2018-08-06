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

@protocol UserType;

@interface ProfilePresenter : NSObject
@property (nonatomic, assign) BOOL profileOpenedFromPeoplePicker;
@property (nonatomic, assign) BOOL keyboardPersistedAfterOpeningProfile;

- (void)presentProfileViewControllerForUser:(id<UserType>)user inController:(UIViewController *)controller fromRect:(CGRect)rect onDismiss:(dispatch_block_t)onDismiss arrowDirection:(UIPopoverArrowDirection)arrowDirection;
@end
