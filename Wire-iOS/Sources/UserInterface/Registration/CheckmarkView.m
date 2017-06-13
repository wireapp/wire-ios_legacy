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


#import "CheckmarkView.h"
#import "UIImage+ZetaIconsNeue.h"
#import "UIView+MTAnimation.h"

@import PureLayout;

@interface CheckmarkView ()
@property (nonatomic) UIView *circleView;
@end

@implementation CheckmarkView

- (instancetype)init
{
    self = [super init];
    if (nil != self) {
        self.circleView = [[UIView alloc] initForAutoLayout];
        self.circleView.backgroundColor = [UIColor colorWithWhite:0.0f alpha:0.5f];
        [self addSubview:self.circleView];

        UIImageView *checkmarkImageView = [[UIImageView alloc] initWithImage:[UIImage imageForIcon:ZetaIconTypeCheckmark
                                                                                          iconSize:ZetaIconSizeLarge
                                                                                             color:[UIColor whiteColor]]];
        checkmarkImageView.translatesAutoresizingMaskIntoConstraints = NO;
        checkmarkImageView.contentMode = UIViewContentModeCenter;
        [self addSubview:checkmarkImageView];

        [self.circleView autoPinEdgesToSuperviewEdgesWithInsets:UIEdgeInsetsZero];
        [checkmarkImageView autoPinEdgesToSuperviewEdgesWithInsets:UIEdgeInsetsZero];
    }
    return self;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    self.circleView.layer.cornerRadius = MIN(self.bounds.size.width, self.bounds.size.height) / 2.0f;
    self.circleView.clipsToBounds = YES;
}

- (void)revealWithAnimations:(void (^)())animations completion:(void (^)())completion
{
    self.transform = CGAffineTransformMakeScale(1.8f, 1.8f);
    self.mt_animationExaggeration = 4;
    self.hidden = NO;
    self.alpha = 0.0f;
    [UIView mt_animateWithViews:@[self]
                       duration:0.35f
                 timingFunction:MTTimingFunctionEaseOutBack
                     animations:^{
                         if (animations != nil) {
                             animations();
                         }
                         
                         self.alpha = 1.0f;
                         self.transform = CGAffineTransformIdentity;
                     }
                     completion:^{
                         dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                             if (completion != nil) {
                                 completion();
                             }
                         });
                     }];
}

@end
