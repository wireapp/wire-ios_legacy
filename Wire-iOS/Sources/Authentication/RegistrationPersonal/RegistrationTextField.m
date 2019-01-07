
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


#import "RegistrationTextField.h"
#import "RegistrationTextField+Internal.h"

@import WireExtensionComponents;


#import "UIImage+ZetaIconsNeue.h"
#import "GuidanceDotView.h"
#import "CountryCodeView.h"

#import "NSAttributedString+Wire.h"
#import "Wire-Swift.h"

static const CGFloat ConfirmButtonWidth = 40;
static const CGFloat CountryCodeViewWidth = 60;
static const CGFloat GuidanceDotViewWidth = 40;



@interface RegistrationTextField ()

@property (nonatomic, readwrite) IconButton *confirmButton;
@property (nonatomic) CountryCodeView *countryCodeView;
@property (nonatomic) GuidanceDotView *guidanceDotView;

@end

@implementation RegistrationTextField

@dynamic delegate;

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    
    if (self) {
        self.guidanceDotView = [[GuidanceDotView alloc] init];
        self.countryCodeView = [[CountryCodeView alloc] init];
        self.countryCodeView.isAccessibilityElement = YES;
        self.countryCodeView.accessibilityTraits = UIAccessibilityTraitButton;
        self.countryCodeView.accessibilityLabel = NSLocalizedString(@"registration.phone_code", @"");
        self.countryCodeView.accessibilityHint = NSLocalizedString(@"registration.phone_code.hint", @"");

        [self setupConfirmButton];
        
        self.font = UIFont.normalLightFont;
        self.textColor = [UIColor wr_colorFromColorScheme:ColorSchemeColorTextForeground variant:ColorSchemeVariantDark];
        self.textInsets = UIEdgeInsetsMake(0, 8, 0, 8);
        if ([[[UIDevice currentDevice] systemVersion] floatValue] < 11.0) {
            // Placeholder frame calculation is changed in iOS 11, therefore the TOP inset is not necessary
            self.placeholderInsets = UIEdgeInsetsMake(8, 8, 0, 8);
        }
        else {
            self.placeholderInsets = UIEdgeInsetsMake(0, 8, 0, 8);
        }
        self.keyboardAppearance = UIKeyboardAppearanceDark;
        self.autocorrectionType = UITextAutocorrectionTypeNo;
        self.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
        self.layer.cornerRadius = 4;
        self.layer.masksToBounds = YES;
        self.backgroundColor = [UIColor.blackColor colorWithAlphaComponent:0.4];
    }
    
    return self;
}

- (void)setupConfirmButton
{
    self.confirmButton = [[IconButton alloc] init];
    [self.confirmButton setBackgroundImageColor:[UIColor whiteColor] forState:UIControlStateNormal];
    ZetaIconType iconType = [UIApplication isLeftToRightLayout] ? ZetaIconTypeChevronRight : ZetaIconTypeChevronLeft;
    [self.confirmButton setIcon:iconType withSize:ZetaIconSizeSmall forState:UIControlStateNormal];
    [self.confirmButton setIconColor:[UIColor colorWithRed:0.20 green:0.21 blue:0.22 alpha:1.0] forState:UIControlStateNormal];
    self.confirmButton.accessibilityIdentifier= @"RegistrationConfirmButton";
}

- (void)setPlaceholder:(NSString *)placeholder
{
    self.attributedPlaceholder = [self attributedPlaceholderString:placeholder.uppercaseString];
}

- (NSAttributedString *)attributedPlaceholderString:(NSString *)placeholder
{
    return [placeholder attributedStringWithAttributes:@{ NSForegroundColorAttributeName : [UIColor.whiteColor colorWithAlphaComponent:0.4],
                                                          NSFontAttributeName : UIFont.smallLightFont }];
}

- (UIButton *)countryCodeButton
{
    return self.countryCodeView.button;
}

- (void)setCountryCode:(NSUInteger)countryCode
{
    _countryCode = countryCode;
    NSString *countryCodeText = [NSString stringWithFormat:@"+%lu", (unsigned long)countryCode];
    self.countryCodeView.accessibilityValue = countryCodeText;
    [self.countryCodeView.button setTitle:countryCodeText forState:UIControlStateNormal];
}

- (void)setEnabled:(BOOL)enabled
{
    [super setEnabled:enabled];
    
    if (enabled) {
        self.textColor = [UIColor wr_colorFromColorScheme:ColorSchemeColorTextForeground variant:ColorSchemeVariantDark];
    } else {
        self.textColor = [UIColor.whiteColor colorWithAlphaComponent:0.4];
    }
}

- (void)setRightAccessoryView:(RegistrationTextFieldRightAccessoryView)rightAccessoryView
{
    _rightAccessoryView = rightAccessoryView;
    
    switch (rightAccessoryView) {
        case RegistrationTextFieldRightAccessoryViewNone:
            self.rightView = nil;
            self.rightViewMode = UITextFieldViewModeNever;
            break;
            
        case RegistrationTextFieldRightAccessoryViewGuidanceDot:
            self.rightView = self.guidanceDotView;
            self.rightViewMode = UITextFieldViewModeAlways;
            break;
            
        case RegistrationTextFieldRightAccessoryViewConfirmButton:
            self.rightView = self.confirmButton;
            self.rightViewMode = UITextFieldViewModeAlways;
            break;
        case RegistrationTextFieldRightAccessoryViewCustom:
            self.rightView = self.customRightView;
            self.rightViewMode = UITextFieldViewModeAlways;
            break;
    }
}

- (void)setLeftAccessoryView:(RegistrationTextFieldLeftAccessoryView)leftAccessoryView
{
    _leftAccessoryView = leftAccessoryView;
    
    switch (leftAccessoryView) {
        case RegistrationTextFieldLeftAccessoryViewNone:
            self.leftView = nil;
            self.leftViewMode = UITextFieldViewModeNever;
            break;
            
        case RegistrationTextFieldLeftAccessoryViewCountryCode:
            self.leftView = self.countryCodeView;
            self.leftViewMode = UITextFieldViewModeAlways;
            break;
    }
}

- (void)drawPlaceholderInRect:(CGRect)rect
{
    [super drawPlaceholderInRect:UIEdgeInsetsInsetRect(rect, self.placeholderInsets)];
}

- (CGRect)textRectForBounds:(CGRect)bounds
{
    CGRect textRect = [super textRectForBounds:bounds];

    // In case the text content should be center-aligned, we need to inset the text with the right accessory view size on the left
    if (self.rightAccessoryView != RegistrationTextFieldRightAccessoryViewNone && self.textAlignment == NSTextAlignmentCenter) {
        if ([UIApplication isLeftToRightLayout]) {
            textRect = UIEdgeInsetsInsetRect(textRect, UIEdgeInsetsMake(0, [self rightViewRectForBounds:bounds].size.width, 0, 0));
        } else {
            textRect = UIEdgeInsetsInsetRect(textRect, UIEdgeInsetsMake(0, 0, 0, [self leftViewRectForBounds:bounds].size.width));
        }
    }

    return UIEdgeInsetsInsetRect(textRect, self.textInsets);
}

- (CGRect)rightViewRectForBounds:(CGRect)bounds
{
    BOOL leftToRight = [UIApplication isLeftToRightLayout];
    if (leftToRight) {
        return [self rightAccessoryViewRectForBounds:bounds leftToRight:leftToRight];
    } else {
        return [self leftAccessoryViewRectForBounds:bounds leftToRight:leftToRight];
    }
}

- (CGRect)leftViewRectForBounds:(CGRect)bounds
{
    BOOL leftToRight = [UIApplication isLeftToRightLayout];
    if (leftToRight) {
        return [self leftAccessoryViewRectForBounds:bounds leftToRight:leftToRight];
    } else {
        return [self rightAccessoryViewRectForBounds:bounds leftToRight:leftToRight];
    }
}

- (CGRect)leftAccessoryViewRectForBounds:(CGRect)bounds leftToRight:(BOOL)leftToRight {
    CGRect leftViewRect;
    
    switch (self.leftAccessoryView) {
        case RegistrationTextFieldLeftAccessoryViewNone:
            leftViewRect = CGRectZero;
            break;
            
        case RegistrationTextFieldLeftAccessoryViewCountryCode:
            if (leftToRight) {
                leftViewRect = CGRectMake(bounds.origin.x, bounds.origin.y, CountryCodeViewWidth, bounds.size.height);
            } else {
                leftViewRect = CGRectMake(CGRectGetMaxX(bounds) - CountryCodeViewWidth, bounds.origin.y, CountryCodeViewWidth, bounds.size.height);
            }
            break;
    }
    
    return leftViewRect;
}

- (CGRect)rightAccessoryViewRectForBounds:(CGRect)bounds leftToRight:(BOOL)leftToRight {
    CGRect rightViewRect;
    
    switch (self.rightAccessoryView) {
        case RegistrationTextFieldRightAccessoryViewNone:
            rightViewRect = CGRectZero;
            break;
            
        case RegistrationTextFieldRightAccessoryViewGuidanceDot:
            if (leftToRight) {
                rightViewRect = CGRectMake(CGRectGetMaxX(bounds) - GuidanceDotViewWidth, bounds.origin.y, GuidanceDotViewWidth, bounds.size.height);
            } else {
                rightViewRect = CGRectMake(bounds.origin.x, bounds.origin.y, GuidanceDotViewWidth, bounds.size.height);
            }
            break;
            
        case RegistrationTextFieldRightAccessoryViewConfirmButton:
            if (leftToRight) {
                rightViewRect = CGRectMake(CGRectGetMaxX(bounds) - ConfirmButtonWidth, bounds.origin.y, ConfirmButtonWidth, bounds.size.height);
            } else {
                rightViewRect = CGRectMake(bounds.origin.x, bounds.origin.y, ConfirmButtonWidth, bounds.size.height);
            }
            break;
            
        case RegistrationTextFieldRightAccessoryViewCustom:
            if (leftToRight) {
                rightViewRect = CGRectMake(CGRectGetMaxX(bounds) - self.customRightView.intrinsicContentSize.width, bounds.origin.y, self.customRightView.intrinsicContentSize.width, bounds.size.height);
            } else {
                rightViewRect = CGRectMake(bounds.origin.x, bounds.origin.y, self.customRightView.intrinsicContentSize.width, bounds.size.height);
            }
            break;
    }
    
    return rightViewRect;
}

- (NSRange)selectedRange
{
    NSInteger location = [self offsetFromPosition:self.beginningOfDocument
                                       toPosition:self.selectedTextRange.start];
    NSInteger length = [self offsetFromPosition:self.selectedTextRange.start
                                     toPosition:self.selectedTextRange.end];
    
    return NSMakeRange(location, length);
}

@end
