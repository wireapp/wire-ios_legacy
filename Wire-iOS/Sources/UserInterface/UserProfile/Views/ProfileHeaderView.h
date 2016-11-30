//// 
//// Wire
//// Copyright (C) 2016 Wire Swiss GmbH
//// 
//// This program is free software: you can redistribute it and/or modify
//// it under the terms of the GNU General Public License as published by
//// the Free Software Foundation, either version 3 of the License, or
//// (at your option) any later version.
//// 
//// This program is distributed in the hope that it will be useful,
//// but WITHOUT ANY WARRANTY; without even the implied warranty of
//// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
//// GNU General Public License for more details.
//// 
//// You should have received a copy of the GNU General Public License
//// along with this program. If not, see http://www.gnu.org/licenses/.
//// 
//
//
//#import <UIKit/UIKit.h>
//
//@class ProfileHeaderViewModel;
//
//typedef NS_ENUM(NSInteger, ProfileHeaderStyle) {
//	ProfileHeaderStyleCancelButton,
//	ProfileHeaderStyleBackButton,
//	ProfileHeaderStyleNoButton
//};
//
//@class IconButton;
//
//@interface ProfileHeaderView : UIView
//
//- (instancetype)initWithCoder:(NSCoder *)aDecoder NS_UNAVAILABLE;
//- (instancetype)initWithFrame:(CGRect)frame NS_UNAVAILABLE;
//- (instancetype)initWithViewModel:(ProfileHeaderViewModel *)viewModel NS_DESIGNATED_INITIALIZER;
//
//@property (nonatomic, strong, readonly) IconButton *dismissButton;
//@property (nonatomic) BOOL showVerifiedShield;
//
///// Analytics purpose to figure out from where connection request is send
//@property (nonatomic, readonly) ProfileHeaderStyle headerStyle;
//
//@end
