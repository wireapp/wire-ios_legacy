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




#pragma mark - Turn features on or off



#pragma mark - URLs
FOUNDATION_EXTERN NSString *const WireURLScheme;
FOUNDATION_EXTERN NSString *const WireURLSchemeInvite;

FOUNDATION_EXTERN NSString *const WireURLPathTeamJoin;


#pragma mark - Preference keys

FOUNDATION_EXPORT NSString *const UserPrefKeyProfilePictureTipCompleted;
FOUNDATION_EXPORT NSString *const UserPrefKeyAccentColorTipCompleted;

#pragma mark - Unsorted stuff

#define IS_IPHONE ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone)
#define IS_IPHONE_4 (IS_IPHONE && [[UIScreen mainScreen] nativeBounds].size.height == 960.0f)
#define IS_IPHONE_5 (IS_IPHONE && [[UIScreen mainScreen] nativeBounds].size.height == 1136.0f)
#define IS_IPHONE_6 (IS_IPHONE && [[UIScreen mainScreen] nativeBounds].size.height == 1334.0)
#define IS_IPHONE_6_PLUS_OR_BIGGER (IS_IPHONE && [[UIScreen mainScreen] nativeBounds].size.height >= 1920.0f)

#define IS_OS_8_OR_LATER    ([[[UIDevice currentDevice] systemVersion] floatValue] >= 8.0)
#define IS_ZOOMED_IPHONE_6 (IS_IPHONE && [[UIScreen mainScreen] bounds].size.height == 568.0 && IS_OS_8_OR_LATER && [UIScreen mainScreen].nativeScale > [UIScreen mainScreen].scale)
#define IS_ZOOMED_IPHONE_6_PLUS (IS_IPHONE && [[UIScreen mainScreen] bounds].size.height == 667.0 && IS_OS_8_OR_LATER && [UIScreen mainScreen].nativeScale < [UIScreen mainScreen].scale)

#define IS_IPAD ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad)
#define IS_IPAD_LANDSCAPE_LAYOUT (([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad) && UIInterfaceOrientationIsLandscape([UIApplication sharedApplication].statusBarOrientation))
#define IS_IPAD_PORTRAIT_LAYOUT (([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad) && UIInterfaceOrientationIsPortrait([UIApplication sharedApplication].statusBarOrientation))
