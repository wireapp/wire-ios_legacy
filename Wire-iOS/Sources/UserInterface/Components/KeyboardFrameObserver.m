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

#import "KeyboardFrameObserver.h"
#import "UIView+Zeta.h"



@interface KeyboardFrameObserver ()

@property (nonatomic) NSDictionary *currentKeyboardInfo;
@property (nonatomic) BOOL keyboardWasShown;
@end



@implementation KeyboardFrameObserver

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.keyboardWasShown = NO;
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillChangeFrame:) name:UIKeyboardWillChangeFrameNotification object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardDidShow:) name:UIKeyboardDidShowNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardDidHide:) name:UIKeyboardDidHideNotification object:nil];
    }
    return self;
}

- (void)keyboardWillChangeFrame:(NSNotification *)notification
{
    self.currentKeyboardInfo = [notification.userInfo copy];
}

- (void)keyboardDidShow:(NSNotification *)notification
{
    self.keyboardWasShown = YES;
}

- (void)keyboardWillHide:(NSNotification *)notification
{
    self.currentKeyboardInfo = nil;
}

- (void)keyboardDidHide:(NSNotification *)notification
{
    self.keyboardWasShown = NO;
}

- (CGRect)keyboardFrame
{
    if (self.currentKeyboardInfo && self.keyboardIsVisible) {
        return [[self.currentKeyboardInfo objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
    } else {
        return CGRectZero;
    }
}

- (CGRect)keyboardFrameInView:(UIView *)view
{
    if (self.currentKeyboardInfo && self.keyboardIsVisible) {
        return [UIView keyboardFrameInView:view forKeyboardInfo:self.currentKeyboardInfo];
    } else {
        return CGRectZero;
    }
}

- (BOOL)keyboardIsVisible
{
    if (!self.keyboardWasShown) {
        return NO;
    }
    
    CGRect screenRect = [[self.currentKeyboardInfo objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
    CGRect visibleRect = CGRectIntersection([UIScreen mainScreen].bounds, screenRect);
    
    return visibleRect.size.height > 0;
}

@end
