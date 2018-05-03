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
#import "ZetaIconTypes.h"



@interface UIImage (ZetaIconsNeue)

/// This returns an image the contains the icon with the specified *icon font* size.  The dimensions of the
/// returned image are not guaranteed to be the same as the requested font size of the icon
+ (UIImage *)imageForIcon:(ZetaIconType)icon iconSize:(ZetaIconSize)iconSize color:(UIColor *)color;

/// This returns an image the contains the icon with the specified *icon font* size.  The dimensions of the
/// returned image are not guaranteed to be the same as the requested font size of the icon
+ (UIImage *)imageForIcon:(ZetaIconType)icon fontSize:(CGFloat)fontSize color:(UIColor *)color;
+ (CGFloat)sizeForZetaIconSize:(ZetaIconSize)iconSize;

+ (UIImage *)imageForIcon:(ZetaIconType)iconType iconSize:(ZetaIconSize)iconSize color1:(UIColor *)color1 color2:(UIColor *)color2 color3:(UIColor *)color3;

@end

@interface UIImage (ZetaCustomIcons)

// specific method to return the logo
+ (UIImage *)imageForWordmarkWithColor:(UIColor *)color;
+ (UIImage *)imageForLogoWithColor:(UIColor *)color iconSize:(ZetaIconSize)iconSize;
+ (UIImage *)imageForRestoreWithColor:(UIColor *)color iconSize:(ZetaIconSize)iconSize NS_SWIFT_NAME(imageForRestore(with:size:));

@end

