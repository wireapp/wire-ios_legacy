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


#import "UIControl+Wire.h"

@implementation UIControl (Wire)

- (void)expandState:(UIControlState)state block:(void(^)(UIControlState state))block
{
    if (state == UIControlStateNormal) {
        block(UIControlStateNormal);
    }
    
    if ((state & UIControlStateDisabled) == UIControlStateDisabled) {
        block(UIControlStateDisabled);
    }
    
    if ((state & UIControlStateHighlighted) == UIControlStateHighlighted) {
        block(UIControlStateHighlighted);
    }
    
    if ((state & UIControlStateSelected) == UIControlStateSelected) {
        block(UIControlStateSelected);
    }
}

@end
