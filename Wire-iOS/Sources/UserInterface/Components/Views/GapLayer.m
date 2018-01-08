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


#import "GapLayer.h"



@interface GapLayer ()

@property (strong, nonatomic) UIBezierPath *path;
@end



@implementation GapLayer

-(void)updatePath
{
    UIBezierPath *path = [UIBezierPath bezierPathWithRect:CGRectMake(0, 0, self.bounds.size.width, self.bounds.size.height)];

    self.path = path;
}

- (id)initWithLayer:(id)layer
{
    self = [super initWithLayer:layer];

    if (nil != self) {
//        if ([layer isKindOfClass:[GapLayer class]]) {
//            GapLayer *other = layer;
//            self.gapPosition = other.gapPosition;
//            self.gapSize = other.gapSize;
//        }

        [self updatePath];
    }
    return self;
}

- (CABasicAnimation *)makeAnimationForKey:(NSString *)key
{
    CABasicAnimation *anim = [CABasicAnimation animationWithKeyPath:key];
    anim.fromValue = [[self presentationLayer] valueForKey:key];
    anim.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut];
    anim.duration = 0.5;

    return anim;
}

+ (BOOL)needsDisplayForKey:(NSString *)key
{
    if ([key isEqualToString:NSStringFromSelector(@selector(alpha))]) {
        return YES;
    }

    return [super needsDisplayForKey:key];
}

- (id <CAAction>)actionForKey:(NSString *)event
{
    NSString *gapKey = NSStringFromSelector(@selector(alpha));
//    NSString *gapSizeKey = NSStringFromSelector(@selector(gapSize));
    if ([event isEqualToString:gapKey]) {
        return [self makeAnimationForKey:gapKey];
    }

    return [super actionForKey:event];
}

- (void)setAlpha:(CGFloat)alpha {
    _alpha = alpha;
}

//- (void)setGapPosition:(CGFloat)gapPosition
//{
//    _gapPosition = gapPosition;
//
////    UIBezierPath *path = [UIBezierPath bezierPath];
//    UIBezierPath *path = [UIBezierPath bezierPathWithRect:CGRectMake(0, 0, self.bounds.size.width, self.bounds.size.height)];
//
////    UIBezierPath *pathLeft = [UIBezierPath bezierPathWithRect:CGRectMake(0, 0, self.gapPosition - self.gapSize / 2.0f, self.bounds.size.height)];
////    UIBezierPath *pathRight = [UIBezierPath bezierPathWithRect:CGRectMake(self.gapPosition + self.gapSize / 2.0f, 0, self.bounds.size.width - self.gapPosition - self.gapSize / 2.0f, self.bounds.size.height)];
//
////    [path appendPath:pathLeft];
////    [path appendPath:pathRight];
//
//    self.path = path;
//    [self setNeedsDisplay];
//}

- (BOOL)needsDisplayOnBoundsChange
{
    [self updatePath];
    return YES;
}

- (void)drawInContext:(CGContextRef)ctx
{
    CGContextSaveGState(ctx);
    CGContextSetInterpolationQuality(ctx, kCGInterpolationHigh);
    CGContextAddPath(ctx, self.path.CGPath);
    CGContextSetFillColorWithColor(ctx, [UIColor whiteColor].CGColor);
    CGContextFillPath(ctx);
    CGContextRestoreGState(ctx);
}

@end
