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


#import "AudioErrorView.h"
#import <WireExtensionComponents/UIImage+ZetaIconsNeue.h>

@import PureLayout;

@interface AudioErrorView ()
@property (nonatomic) UIImageView *errorIconView;
@end

@implementation AudioErrorView

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.backgroundColor = [UIColor colorWithWhite:0.0f alpha:0.32f];

        self.errorIconView = [[UIImageView alloc] initForAutoLayout];
        self.errorIconView.image = [UIImage imageForIcon:ZetaIconTypeAudio iconSize:ZetaIconSizeCamera color:[UIColor colorWithWhite:1 alpha:0.16]];
        self.errorIconView.transform = CGAffineTransformMakeRotation(M_PI);
        [self addSubview:self.errorIconView];
        
        [self.errorIconView autoAlignAxisToSuperviewMarginAxis:ALAxisHorizontal];
        [self.errorIconView autoAlignAxisToSuperviewMarginAxis:ALAxisVertical];
    }
    return self;
}

@end
