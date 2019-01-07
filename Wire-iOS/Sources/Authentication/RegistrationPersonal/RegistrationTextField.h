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

@class IconButton;

typedef NS_ENUM(NSUInteger, RegistrationTextFieldRightAccessoryView) {
    RegistrationTextFieldRightAccessoryViewNone,
    RegistrationTextFieldRightAccessoryViewConfirmButton,
    RegistrationTextFieldRightAccessoryViewGuidanceDot,
    RegistrationTextFieldRightAccessoryViewCustom
};

typedef NS_ENUM(NSUInteger, RegistrationTextFieldLeftAccessoryView) {
    RegistrationTextFieldLeftAccessoryViewNone,
    RegistrationTextFieldLeftAccessoryViewCountryCode
};

@interface RegistrationTextField : UITextField

@property (nonatomic, weak) id<UITextFieldDelegate> delegate;

@property (nonatomic) RegistrationTextFieldLeftAccessoryView leftAccessoryView;
@property (nonatomic) RegistrationTextFieldRightAccessoryView rightAccessoryView;
@property (nonatomic) UIView *customRightView;

@property (nonatomic) NSUInteger countryCode;
@property (nonatomic, readonly) UIButton *countryCodeButton;
@property (nonatomic, readonly) IconButton *confirmButton;

@end
