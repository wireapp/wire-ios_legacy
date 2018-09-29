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


#import "ButtonWithLargerHitArea.h"
#import "TextTransform.h"
#import "ColorScheme.h"



typedef NS_ENUM(NSUInteger, ButtonStyle) {
    ButtonStyleFull,
    ButtonStyleEmpty,
    ButtonStyleFullMonochrome,
    ButtonStyleEmptyMonochrome
};

NS_ASSUME_NONNULL_BEGIN

@interface Button : ButtonWithLargerHitArea

@property (nonatomic) BOOL circular;
@property (nonatomic) TextTransform textTransform;

+ (instancetype)buttonWithStyle:(ButtonStyle)style;
+ (instancetype)buttonWithStyle:(ButtonStyle)style variant:(ColorSchemeVariant)variant;

- (instancetype)initWithStyle:(ButtonStyle)style;
- (instancetype)initWithStyle:(ButtonStyle)style variant:(ColorSchemeVariant)variant;

- (UIColor *)borderColorForState:(UIControlState)state;
- (void)setBorderColor:(UIColor *)color forState:(UIControlState)state;
- (void)setBackgroundImageColor:(UIColor *)color forState:(UIControlState)state;

@end

NS_ASSUME_NONNULL_END
