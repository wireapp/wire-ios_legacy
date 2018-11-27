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


#import "UIView+Zeta.h"
#import "UIResponder+FirstResponder.h"
#import "Wire-Swift.h"

static NSString * const WireLastCachedKeyboardHeightKey = @"WireLastCachedKeyboardHeightKey";

@implementation UIView (Zeta)

+ (void)animateWithKeyboardNotification:(NSNotification *)notification
                                 inView:(UIView *)view
                             animations:(void (^)(CGRect keyboardFrameInView))animations
                             completion:(void (^)(BOOL finished))completion
{
    [self animateWithKeyboardNotification:notification inView:view delay:0 animations:animations completion:completion];
}

+ (void)animateWithKeyboardNotification:(NSNotification *)notification
                                 inView:(UIView *)view
                                  delay:(NSTimeInterval)delay
                             animations:(void (^)(CGRect keyboardFrameInView))animations
                             completion:(void (^)(BOOL finished))completion
{
    CGRect keyboardFrame = [self keyboardFrameInView:view forKeyboardNotification:notification];
    
    UIResponder *currentFirstResponder = [UIResponder wr_currentFirstResponder];
    if (currentFirstResponder != nil) {
        CGSize keyboardSize = CGSizeMake(keyboardFrame.size.width, keyboardFrame.size.height - currentFirstResponder.inputAccessoryView.bounds.size.height);
        [self wr_setLastKeyboardSize:keyboardSize];
    }
    
    NSDictionary *userInfo = notification.userInfo;
    double animationLength = [[userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    UIViewAnimationCurve const animationCurve = (UIViewAnimationCurve) [userInfo[UIKeyboardAnimationCurveUserInfoKey] unsignedIntegerValue];
    
    UIViewAnimationOptions animationOptions = UIViewAnimationOptionBeginFromCurrentState;
    if (animationCurve == UIViewAnimationCurveEaseIn) {
        animationOptions |= UIViewAnimationOptionCurveEaseIn;
    }
    else if (animationCurve == UIViewAnimationCurveEaseInOut) {
        animationOptions |= UIViewAnimationOptionCurveEaseInOut;
    }
    else if (animationCurve == UIViewAnimationCurveEaseOut) {
        animationOptions |= UIViewAnimationOptionCurveEaseOut;
    }
    else if (animationCurve == UIViewAnimationCurveLinear) {
        animationOptions |= UIViewAnimationOptionCurveLinear;
    }
    
    [UIView animateWithDuration:animationLength
                          delay:delay
                        options:animationOptions
                     animations:^{
                         animations(keyboardFrame);
                     }
                     completion:completion];
}

+ (void)wr_setLastKeyboardSize:(CGSize)lastSize
{
    [[NSUserDefaults standardUserDefaults] setObject:NSStringFromCGSize(lastSize) forKey:WireLastCachedKeyboardHeightKey];
}

+ (CGSize)wr_lastKeyboardSize
{
    NSString *currentLastValue = [[NSUserDefaults standardUserDefaults] objectForKey:WireLastCachedKeyboardHeightKey];
    
    if (currentLastValue == nil) {
        return CGSizeMake([UIScreen mainScreen].bounds.size.width, KeyboardHeight.current);
    }
    else {
        CGSize keyboardSize = CGSizeFromString(currentLastValue);
        
        // If keyboardSize value is clearly off we need to pull default value
        if (keyboardSize.height < 150) {
            keyboardSize.height = KeyboardHeight.current;
        }
        
        return keyboardSize;
    }
}

+ (CGRect)keyboardFrameInView:(UIView *)view forKeyboardNotification:(NSNotification *)notification
{
    NSDictionary *userInfo = notification.userInfo;
    return [self keyboardFrameInView:view forKeyboardInfo:userInfo];
}

+ (CGRect)keyboardFrameInView:(UIView *)view forKeyboardInfo:(NSDictionary *)keyboardInfo
{
    CGRect screenRect = [[keyboardInfo objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
    CGRect windowRect = [view.window convertRect:screenRect fromWindow:nil];
    CGRect viewRect = [view convertRect:windowRect fromView:nil];
    
    CGRect intersection = CGRectIntersection(viewRect, view.bounds);
    
    return intersection;
}

@end
