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


#pragma mark - Unsorted stuff

#define IS_IPHONE ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone)
#define IS_IPHONE_4 (IS_IPHONE && [[UIScreen mainScreen] nativeBounds].size.height == 960.0f)
#define IS_IPHONE_5 (IS_IPHONE && [[UIScreen mainScreen] nativeBounds].size.height == 1136.0f)
#define IS_IPHONE_6 (IS_IPHONE && [[UIScreen mainScreen] nativeBounds].size.height == 1334.0)
#define IS_IPHONE_6_PLUS_OR_BIGGER (IS_IPHONE && [[UIScreen mainScreen] nativeBounds].size.height >= 1920.0f)

#define IS_IPAD ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad)
#define IS_IPAD_FULLSCREEN (IS_IPAD && [UIApplication sharedApplication].keyWindow.traitCollection.horizontalSizeClass == UIUserInterfaceSizeClassRegular)
#define IS_IPAD_LANDSCAPE_LAYOUT (IS_IPAD_FULLSCREEN && UIInterfaceOrientationIsLandscape([UIApplication sharedApplication].statusBarOrientation))
#define IS_IPAD_PORTRAIT_LAYOUT (IS_IPAD_FULLSCREEN && UIInterfaceOrientationIsPortrait([UIApplication sharedApplication].statusBarOrientation))
