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


#import <WireExtensionComponents/TextView.h>



@class TokenizedTextView;



@protocol TokenizedTextViewDelegate <UITextViewDelegate>

- (void)tokenizedTextView:(TokenizedTextView *)textView didTapTextRange:(NSRange)range fraction:(float)fraction;
- (void)tokenizedTextView:(TokenizedTextView *)textView textContainerInsetChanged:(UIEdgeInsets)textContainerInset;

@end
                          
                          
                          
//! Custom UITextView subclass to be used in TokenField.
//! Shouldn't be used anywhere else.
@interface TokenizedTextView : TextView

@property (weak, nonatomic) id< TokenizedTextViewDelegate > delegate;

@end
