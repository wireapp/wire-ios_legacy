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
@import WireExtensionComponents;

typedef NS_OPTIONS(NSUInteger, WRExtendedBlockAnimationsOptions) {
    WRExtendedBlockAnimationsOptionsNone = 0,
    WRExtendedBlockAnimationsOptionsBeginFromCurrentState = 1 << 0
};



@interface UIView (WR_ExtendedBlockAnimations)

+ (void)wr_animateWithEasing:(WREasingFunction)easing
                    duration:(NSTimeInterval)duration
                  animations:(void (^)(void))animations NS_SWIFT_NAME(wr_animate(easing:duration:animations:));

+ (void)wr_animateWithEasing:(WREasingFunction)easing
                    duration:(NSTimeInterval)duration
                  animations:(void (^)(void))animations
                  completion:(void (^)(BOOL finished))completion NS_SWIFT_NAME(wr_animate(easing:duration:animations:completion:));

+ (void)wr_animateWithEasing:(WREasingFunction)easing
                    duration:(NSTimeInterval)duration
                       delay:(NSTimeInterval)delay
                  animations:(void (^)(void))animations
                  completion:(void (^)(BOOL finished))completion NS_SWIFT_NAME(wr_animate(easing:duration:delay:animations:completion:));

+ (void)wr_animateWithEasing:(WREasingFunction)easing
                    duration:(NSTimeInterval)duration
                       delay:(NSTimeInterval)delay
                  animations:(void (^)(void))animations
                     options:(WRExtendedBlockAnimationsOptions)options
                  completion:(void (^)(BOOL finished))completion NS_SWIFT_NAME(wr_animate(easing:duration:delay:animations:options:completion:));


+ (void)wr_animateWithBasicAnimation:(CABasicAnimation *)animation
                            duration:(NSTimeInterval)duration
                          animations:(void (^)(void))animations
                             options:(WRExtendedBlockAnimationsOptions)options
                          completion:(void (^)(BOOL finished))completion;

@end
