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
#import "TextTransform.h"

@protocol TextViewProtocol;

/**
Adds placeholder support to @c UITextView. The position of the placeholder is automatically set based on the text view container insets, which ensures correct vertical position. In some cases, it is desirable to horizontally offset the text, which can be done manually.
*/
IB_DESIGNABLE
@interface TextView : UITextView

@property (nonatomic, copy) IBInspectable NSString *placeholder;
@property (nonatomic, copy) IBInspectable NSAttributedString *attributedPlaceholder;
@property (nonatomic) IBInspectable UIColor  *placeholderTextColor;
@property (nonatomic) IBInspectable UIFont   *placeholderFont;
@property (nonatomic) TextTransform placeholderTextTransform;
@property (nonatomic) CGFloat lineFragmentPadding;
@property (nonatomic) UIEdgeInsets placeholderTextContainerInset;
@property (nonatomic) NSTextAlignment placeholderTextAlignment;

- (void)showOrHidePlaceholder;
    
@end

@protocol MediaAsset;
//
/// Informal protocol
@protocol TextViewProtocol <NSObject>

@required
- (void)textView:(UITextView *)textView hasImageToPaste:(id<MediaAsset>)image;

@optional
- (void)textView:(UITextView *)textView firstResponderChanged:(NSNumber *)resigned;

@end
