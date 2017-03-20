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

@interface BackgroundView : UIView
- (instancetype)initWithCoder:(NSCoder *)aDecoder NS_UNAVAILABLE;
- (instancetype)initWithFrame:(CGRect)frame NS_UNAVAILABLE;
- (instancetype)initWithFilterColor:(UIColor *)filterColor NS_DESIGNATED_INITIALIZER;

@property (nonatomic, strong) UIColor *filterColor;

/// Set the main "image" to be a flat color.  Overrides whatever the current image is.
- (void)setFlatColor:(UIColor *)color;

- (void)setImageData:(NSData *)imageData
            animated:(BOOL)animated;
@end


@interface BackgroundView (Animations)

- (void)updateAppearanceAnimated:(BOOL)animated;

@end
