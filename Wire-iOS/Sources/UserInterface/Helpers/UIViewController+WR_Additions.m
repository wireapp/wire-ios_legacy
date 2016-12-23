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


#import "UIViewController+WR_Additions.h"

@implementation UIViewController (WR_Additions)

- (BOOL)wr_isInsidePopoverPresentation
{
    UIView *view = self.view;
    do {
        if ([NSStringFromClass(view.class) isEqualToString:@"_UIPopoverView"]) {
            return YES;
        }
        view = view.superview;
    } while (view != nil);
    
    return NO;
}

- (BOOL)wr_isVisible
{
    BOOL isInWindow = self.view.window != nil;
    BOOL notCoveredModally = self.presentedViewController == nil;
    BOOL viewIsVisible = CGRectIntersectsRect([self.view convertRect:self.view.bounds toView:nil], [[UIScreen mainScreen] bounds]);
    
    return isInWindow && notCoveredModally && viewIsVisible;
}

@end
