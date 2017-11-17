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


#import "Geometry.h"


#if ! TARGET_OS_IPHONE

NSRect __attribute__((overloadable)) InsetRect(NSRect rect, NSEdgeInsets insets)
{
    rect.origin.x += insets.left;
    rect.origin.y += insets.top;
    rect.size.width -= insets.left + insets.right;
    rect.size.height -= insets.top + insets.bottom;
    return rect;
}

NSRect OutsetRect(NSRect rect, NSEdgeInsets insets)
{
    return InsetRect(rect, NSEdgeInsetsMake(-insets.top, -insets.left, -insets.bottom, -insets.right));
}

NSRect __attribute__((overloadable)) InsetRect(NSRect rect, CGFloat top, CGFloat left, CGFloat bottom, CGFloat right)
{
    return InsetRect(rect, NSEdgeInsetsMake(top, left, bottom, right));
}

NSRect VerticallyCenterRect(NSRect rect, NSRect containerRect)
{
    rect.origin.y = 0.5 * (NSHeight(containerRect) - NSHeight(rect));
    return rect;
}



@implementation NSView (Geometry)

- (NSRect)backingOutwardAlignedRect:(NSRect)rect;
{
    return [self backingAlignedRect:rect options:(NSAlignMinXOutward | NSAlignMinYOutward |
                                                  NSAlignWidthOutward | NSAlignMaxYOutward)];
}

@end

#endif
