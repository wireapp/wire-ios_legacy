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

typedef NS_ENUM(NSUInteger, ActionSheetViewStyle) {
    ActionSheetViewStyleLight,
    ActionSheetViewStyleDark
};

@interface ActionSheetContainerView : UIView

@property (nonatomic) UIVisualEffectView *blurEffectView;
@property (nonatomic) UIBlurEffect *blurEffect;
@property (nonatomic) UIView *topContainerView;
@property (nonatomic) UIView *sheetView;

- (instancetype)initWithStyle:(ActionSheetViewStyle)style;
- (void)transitionFromSheetView:(UIView *)fromSheetView toSheetView:(UIView *)toSheetView completion:(void (^)(BOOL finished))completion;

@end
