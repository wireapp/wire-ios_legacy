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

#import "UIApplication+StatusBar.h"

@implementation UIApplication (StatusBar)

- (void)wr_setStatusBarStyle:(UIStatusBarStyle)style animated:(BOOL)animated
{
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    [self setStatusBarStyle:style animated:animated];
#pragma clang diagnostic pop
}

- (void)wr_setStatusBarHidden:(BOOL)hidden withAnimation:(UIStatusBarAnimation)animation
{
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    [self setStatusBarHidden:hidden withAnimation:animation];
#pragma clang diagnostic pop
}

@end
