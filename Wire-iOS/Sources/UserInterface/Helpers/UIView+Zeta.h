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

@interface UIView (Zeta)

+ (CGSize)wr_lastKeyboardSize;
+ (void)wr_setLastKeyboardSize:(CGSize)lastSize;

/// Provides correct handling for animating alongside a keyboard animation
+ (void)animateWithKeyboardNotification:(NSNotification *)notification
                                 inView:(UIView *)view
                             animations:(void (^)(CGRect keyboardFrameInView))animations
                             completion:(void (^)(BOOL finished))completion;

+ (void)animateWithKeyboardNotification:(NSNotification *)notification
                                 inView:(UIView *)view
                                  delay:(NSTimeInterval)delay
                             animations:(void (^)(CGRect keyboardFrameInView))animations
                             completion:(void (^)(BOOL finished))completion;

+ (CGRect)keyboardFrameInView:(UIView *)view forKeyboardNotification:(NSNotification *)notification;

+ (CGRect)keyboardFrameInView:(UIView *)view forKeyboardInfo:(NSDictionary *)keyboardInfo;

@end
