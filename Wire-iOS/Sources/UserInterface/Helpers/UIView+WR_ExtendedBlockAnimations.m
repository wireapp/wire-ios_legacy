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


@import ObjectiveC;

#import "UIView+WR_ExtendedBlockAnimations.h"



@interface WRAnimationBlockDelegate : NSObject <CAAnimationDelegate>

@property (nonatomic, copy) void(^start)(void);
@property (nonatomic, copy) void(^stop)(BOOL);

+(instancetype)animationDelegateWithBeginning:(void(^)(void))beginning
                                   completion:(void(^)(BOOL finished))completion;

@end



@implementation WRAnimationBlockDelegate

+ (instancetype)animationDelegateWithBeginning:(void (^)(void))beginning
                                    completion:(void (^)(BOOL))completion
{
    WRAnimationBlockDelegate *result = [WRAnimationBlockDelegate new];
    result.start = beginning;
    result.stop  = completion;
    return result;
}

- (void)animationDidStart:(CAAnimation *)anim
{
    if (self.start) {
        self.start();
    }
    self.start = nil;
}

- (void)animationDidStop:(CAAnimation *)anim finished:(BOOL)flag
{
    if (self.stop) {
        self.stop(flag);
    }
    self.stop = nil;
}

@end



@interface WRSavedAnimationState : NSObject

@property (nonatomic) CALayer *layer;
@property (nonatomic, copy) NSString *keyPath;
@property (nonatomic) id oldValue;

+ (instancetype)savedStateWithLayer:(CALayer *)layer
                            keyPath:(NSString *)keyPath;

@end



@implementation WRSavedAnimationState

+ (instancetype)savedStateWithLayer:(CALayer *)layer
                            keyPath:(NSString *)keyPath
{
    WRSavedAnimationState *savedState = [WRSavedAnimationState new];
    savedState.layer    = layer;
    savedState.keyPath  = keyPath;
    savedState.oldValue = [layer valueForKeyPath:keyPath];
    return savedState;
}

@end



@implementation UIView (WR_ExtendedBlockAnimations)

+ (void)load
{
    SEL originalSelector = @selector(actionForLayer:forKey:);
    SEL extendedSelector = @selector(WR_actionForLayer:forKey:);
    
    Method originalMethod = class_getInstanceMethod(self, originalSelector);
    Method extendedMethod = class_getInstanceMethod(self, extendedSelector);
    
    NSAssert(originalMethod, @"original method should exist");
    NSAssert(extendedMethod, @"exchanged method should exist");
    
    if(class_addMethod(self, originalSelector, method_getImplementation(extendedMethod), method_getTypeEncoding(extendedMethod))) {
        class_replaceMethod(self, extendedSelector, method_getImplementation(originalMethod), method_getTypeEncoding(originalMethod));
    } else {
        method_exchangeImplementations(originalMethod, extendedMethod);
    }
}

+ (NSMutableArray *)WR_savedAnimationStates
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        WR_savedAnimationStates = [NSMutableArray array];
    });
    
    return WR_savedAnimationStates;
}

static void *WR_currentAnimationContext = NULL;
static void *WR_extendedBlockAnimationsContext = &WR_extendedBlockAnimationsContext;
static NSArray *supportedAnimatableProperties = nil;
static NSArray *supportedAdditiveAnimatableProperties = nil;
static NSMutableArray *WR_savedAnimationStates = nil;

- (id<CAAction>)WR_actionForLayer:(CALayer *)layer forKey:(NSString *)event
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        supportedAnimatableProperties = @[@"position", @"bounds", @"opacity", @"transform"];
        supportedAdditiveAnimatableProperties = @[@"position", @"bounds"];
    });
    
    
    if (WR_currentAnimationContext == WR_extendedBlockAnimationsContext && [supportedAnimatableProperties containsObject:event]) {
        
        if ([event isEqualToString:@"bounds"]) {
            [[UIView WR_savedAnimationStates] addObject:[WRSavedAnimationState savedStateWithLayer:layer
                                                                                           keyPath:@"bounds.origin"]];
            
            [[UIView WR_savedAnimationStates] addObject:[WRSavedAnimationState savedStateWithLayer:layer
                                                                                           keyPath:@"bounds.size"]];
        } else {
            [[UIView WR_savedAnimationStates] addObject:[WRSavedAnimationState savedStateWithLayer:layer
                                                                                           keyPath:event]];
        }
        
        // no implicit animation (it will be added later)
        return (id<CAAction>)[NSNull null];
    }
    
    // call the original implementation
    return [self WR_actionForLayer:layer forKey:event]; // yes, they are swizzled
}

+ (void)wr_animateWithBasicAnimation:(CABasicAnimation *)animation
                            duration:(NSTimeInterval)duration
                          animations:(void (^)(void))animations
                            options:(WRExtendedBlockAnimationsOptions)options
                          completion:(void (^)(BOOL finished))completion
{
    WR_currentAnimationContext = WR_extendedBlockAnimationsContext;
    
    animations();
    
    NSUInteger savedAnimationStateCount = [[self WR_savedAnimationStates] count];
    
    BOOL beginFromCurrentState = (options & WRExtendedBlockAnimationsOptionsBeginFromCurrentState) == WRExtendedBlockAnimationsOptionsBeginFromCurrentState;
    
    if (beginFromCurrentState) {
        animation.additive = NO;
    }
    
    __block NSUInteger animationCount = 0;
    
    [[UIView WR_savedAnimationStates] enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        WRSavedAnimationState *savedState   = (WRSavedAnimationState *)obj;
        CALayer *layer    = savedState.layer;
        NSString *keyPath = savedState.keyPath;
        id oldValue       = savedState.oldValue;
        id newValue       = [layer valueForKeyPath:keyPath];
        
        CABasicAnimation *anim = [animation copy];
        anim.keyPath = keyPath;
        anim.duration = duration;
        anim.beginTime += [layer convertTime:0 fromLayer:nil]; // Compensate for layer.timeOffset
        
        if (anim.isAdditive && ! [supportedAdditiveAnimatableProperties containsObject:keyPath]) {
            anim.additive = NO;
        }
        
        if (anim.isAdditive) {
            anim.fromValue = [self differenceFromValue:oldValue toValue:newValue];
            anim.toValue = [self zeroValueForValue:newValue];
        } else if (beginFromCurrentState) {
            anim.fromValue = layer.presentationLayer ? [layer.presentationLayer valueForKeyPath:keyPath] : oldValue;
            anim.toValue = newValue;
        } else {
            anim.fromValue = oldValue;
            anim.toValue = newValue;
        }
        
        anim.delegate = [WRAnimationBlockDelegate animationDelegateWithBeginning:^{
            animationCount++;
        } completion:^(BOOL finished) {
            animationCount--;
            
            if (animationCount == 0) {
                if (completion != nil) completion(finished);
            }
        }];
        
        // Additive animations need a unique or nil animation key
        NSString *animationKey = anim.isAdditive ? nil : keyPath;
        [layer addAnimation:anim forKey:animationKey];
    }];
    
    // clean up (remove all the stored state)
    [[self WR_savedAnimationStates] removeAllObjects];
    
    WR_currentAnimationContext = NULL;
    
    if (savedAnimationStateCount == 0) {
        // No animations were created
        if (completion != nil) completion(YES);
    }
}

+ (void)wr_animateWithEasing:(WREasingFunction)easing duration:(NSTimeInterval)duration animations:(void (^)(void))animations
{
    [self wr_animateWithEasing:easing duration:duration delay:0 animations:animations options:WRExtendedBlockAnimationsOptionsNone completion:nil];
}

+ (void)wr_animateWithEasing:(WREasingFunction)easing duration:(NSTimeInterval)duration animations:(void (^)(void))animations completion:(void (^)(BOOL))completion
{
    [self wr_animateWithEasing:easing duration:duration delay:0 animations:animations options:WRExtendedBlockAnimationsOptionsNone completion:completion];
}

+ (void)wr_animateWithEasing:(WREasingFunction)easing duration:(NSTimeInterval)duration delay:(NSTimeInterval)delay animations:(void (^)(void))animations completion:(void (^)(BOOL))completion
{
    [self wr_animateWithEasing:easing duration:duration delay:delay animations:animations options:WRExtendedBlockAnimationsOptionsNone completion:completion];
}

+ (void)wr_animateWithEasing:(WREasingFunction)easing
                    duration:(NSTimeInterval)duration
                       delay:(NSTimeInterval)delay
                  animations:(void (^)(void))animations
                     options:(WRExtendedBlockAnimationsOptions)options
                  completion:(void (^)(BOOL finished))completion
{
    WREasingAnimation *animation = [WREasingAnimation new];

    animation.easing = easing;
    animation.beginTime = CACurrentMediaTime() + delay;
    animation.fillMode = kCAFillModeBoth;
    animation.additive = YES;
    
    // WREasingAnimation has the same interface as CABasicAnimation so this should be safe
    [self wr_animateWithBasicAnimation:(CABasicAnimation *)animation duration:duration animations:animations options:options completion:completion];
}

#pragma mark NSValue helper methods

+ (NSValue *)differenceFromValue:(NSValue *)fromValue toValue:(NSValue *)toValue
{
    NSValue *differenceValue = nil;
    
    if (strcmp(fromValue.objCType, @encode(CGPoint)) == 0) {
        CGPoint fromPoint = [fromValue CGPointValue];
        CGPoint toPoint = [toValue CGPointValue];
        CGPoint difference = CGPointMake(fromPoint.x - toPoint.x, fromPoint.y - toPoint.y);
        differenceValue = [NSValue valueWithCGPoint:difference];
    }
    else if (strcmp(fromValue.objCType, @encode(CGSize)) == 0) {
        CGSize fromSize = [fromValue CGSizeValue];
        CGSize toSize = [toValue CGSizeValue];
        CGSize difference = CGSizeMake(fromSize.width - toSize.width, fromSize.height - toSize.height);
        differenceValue = [NSValue valueWithCGSize:difference];
    }
    else if (strcmp(fromValue.objCType, @encode(CGRect)) == 0) {
        differenceValue = [NSValue valueWithCGRect:CGRectMake([fromValue CGRectValue].origin.x - [toValue CGRectValue].origin.x,
                                                              [fromValue CGRectValue].origin.y - [toValue CGRectValue].origin.y,
                                                              [fromValue CGRectValue].size.width - [toValue CGRectValue].size.width,
                                                              [fromValue CGRectValue].size.height - [toValue CGRectValue].size.height)];
    }
    else if ([fromValue isKindOfClass:[NSNumber class]]) {
        NSNumber *fromNumber = (NSNumber *)fromValue;
        NSNumber *toNumber = (NSNumber *)toValue;
        differenceValue =  @(fromNumber.doubleValue - toNumber.doubleValue);
    }
    else {
        NSAssert(NO, @"Unsupported difference calculation from value: %@ to value: %@", fromValue, toValue);
    }
    
    return differenceValue;
}

+ (NSValue *)zeroValueForValue:(NSValue *)value
{
    NSValue *zeroValue = nil;
    
    if (strcmp(value.objCType, @encode(CGPoint)) == 0) {
        zeroValue = [NSValue valueWithCGPoint:CGPointZero];
    }
    else if (strcmp(value.objCType, @encode(CGSize)) == 0) {
        zeroValue = [NSValue valueWithCGSize:CGSizeZero];
    }
    else if (strcmp(value.objCType, @encode(CGRect)) == 0) {
        zeroValue = [NSValue valueWithCGRect:CGRectZero];
    }
    else if ([value isKindOfClass:[NSNumber class]]) {
        zeroValue = @(0);
    }
    else {
        NSAssert(NO, @"Undefined zero value for value: %@", value);
    }
    
    return zeroValue;
}


@end
