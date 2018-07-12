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


#import "RegistrationStepViewController.h"
#import "PhoneNumberViewController.h"


@class ZMIncompleteRegistrationUser;

@interface PhoneNumberStepViewController : RegistrationStepViewController

- (instancetype)initWithPhoneNumber:(NSString *)phoneNumber isEditable:(BOOL)isEditable;
- (instancetype)initWithUnregisteredUser:(ZMIncompleteRegistrationUser *)unregisteredUser;

@property (nonatomic, readonly) UILabel *heroLabel;
@property (nonatomic, copy, readonly) NSString *phoneNumber;
@property (nonatomic) BOOL invitationButtonDisplayed;
@property (nonatomic) PhoneNumberViewController *phoneNumberViewController;

- (void)takeFirstResponder;
- (void)reset;

@end
