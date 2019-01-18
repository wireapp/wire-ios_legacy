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


#import "NSLayoutConstraint+Helpers.h"



static void pushPriority(UILayoutPriority const priority);
static void popPriority(void);
static UILayoutPriority currentPriority(void);



@implementation NSLayoutConstraint (Helpers)

+ (instancetype)constraintWithItem:(UIView *)view1 attribute:(NSLayoutAttribute)attr toItem:(UIView *)view2;
{
    NSLayoutConstraint *constraint = [self constraintWithItem:view1 attribute:attr toItem:view2 constant:0];
    constraint.priority = currentPriority();
    return constraint;
}

+ (instancetype)constraintWithItem:(UIView *)view1 attribute:(NSLayoutAttribute)attr toItem:(UIView *)view2 constant:(CGFloat)c;
{
    NSLayoutConstraint *constraint = [self constraintWithItem:view1 attribute:attr relatedBy:NSLayoutRelationEqual toItem:view2 attribute:attr multiplier:1 constant:c];
    constraint.priority = currentPriority();
    return constraint;
}

+ (instancetype)constraintWithItem:(UIView *)view attribute:(NSLayoutAttribute)attr constant:(CGFloat)c;
{
    NSLayoutConstraint *constraint = [NSLayoutConstraint constraintWithItem:view attribute:attr relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1 constant:c];
    constraint.priority = currentPriority();
    return constraint;
}

+ (instancetype)constraintForEqualWidthWithItem:(UIView *)view1 toItem:(UIView *)view2;
{
    return [self constraintWithItem:view1 attribute:NSLayoutAttributeWidth toItem:view2];
}

+ (instancetype)constraintForEqualHeightWithItem:(UIView *)view1 toItem:(UIView *)view2;
{
    return [self constraintWithItem:view1 attribute:NSLayoutAttributeHeight toItem:view2];
}

+ (NSArray *)constraintsHorizontallyFittingItem:(UIView *)view1 withItem:(UIView *)view2;
{
    return @[[self constraintWithItem:view1 attribute:NSLayoutAttributeLeft toItem:view2],
             [self constraintWithItem:view1 attribute:NSLayoutAttributeRight toItem:view2]];
}

+ (NSArray *)constraintsVerticallyFittingItem:(UIView *)view1 withItem:(UIView *)view2;
{
    return @[[self constraintWithItem:view1 attribute:NSLayoutAttributeTop toItem:view2],
             [self constraintWithItem:view1 attribute:NSLayoutAttributeBottom toItem:view2]];
}

@end



#pragma mark -

@implementation UIView (LayoutConstraintsHelpersAbsolute)

- (NSArray *)addConstraintsForSize:(CGSize)size
{
    NSLayoutConstraint *withConstraint = [self addConstraintForWidth:size.width];
    NSLayoutConstraint *heightConstraint = [self addConstraintForHeight:size.height];
    
    return @[withConstraint, heightConstraint];
}

- (NSLayoutConstraint *)addConstraintForHeight:(CGFloat)height;
{
    NSLayoutConstraint *constraint = [NSLayoutConstraint constraintWithItem:self attribute:NSLayoutAttributeHeight constant:height];
    constraint.priority = currentPriority();
    [self addConstraint:constraint];
    return constraint;
}

- (NSLayoutConstraint *)addConstraintForWidth:(CGFloat)width;
{
    NSLayoutConstraint *constraint = [NSLayoutConstraint constraintWithItem:self attribute:NSLayoutAttributeWidth constant:width];
    constraint.priority = currentPriority();
    [self addConstraint:constraint];
    return constraint;
}

- (NSLayoutConstraint *)addConstraintForMaxWidth:(CGFloat)width;
{
    NSLayoutConstraint *constraint = [NSLayoutConstraint constraintWithItem:self attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationLessThanOrEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0 constant:width];
    constraint.priority = currentPriority();
    [self addConstraint:constraint];
    return constraint;
}

- (NSLayoutConstraint *)addConstraintForMaxHeight:(CGFloat)height;
{
    NSLayoutConstraint *constraint = [NSLayoutConstraint constraintWithItem:self attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationLessThanOrEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0 constant:height];
    constraint.priority = currentPriority();
    [self addConstraint:constraint];
    return constraint;
}

- (NSLayoutConstraint *)addConstraintForMinWidth:(CGFloat)width;
{
    NSLayoutConstraint *constraint = [NSLayoutConstraint constraintWithItem:self attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationGreaterThanOrEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0 constant:width];
    constraint.priority = currentPriority();
    [self addConstraint:constraint];
    return constraint;
}

- (NSLayoutConstraint *)addConstraintForMinHeight:(CGFloat)height;
{
    NSLayoutConstraint *constraint = [NSLayoutConstraint constraintWithItem:self attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationGreaterThanOrEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0 constant:height];
    constraint.priority = currentPriority();
    [self addConstraint:constraint];
    return constraint;
}

- (NSLayoutConstraint *)addConstraintForHeightAsMultipleOfWidth:(CGFloat)multiplier
{
    NSLayoutConstraint *constraint = [NSLayoutConstraint constraintWithItem:self attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeWidth multiplier:multiplier constant:0];
    constraint.priority = currentPriority();
    [self addConstraint:constraint];
    return constraint;

}


- (NSLayoutConstraint *)addConstraintForWidthAsMultipleOfHeight:(CGFloat)multiplier
{
    NSLayoutConstraint *constraint = [NSLayoutConstraint constraintWithItem:self attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeHeight multiplier:multiplier constant:0];
    constraint.priority = currentPriority();
    [self addConstraint:constraint];
    return constraint;
   
}



#if !TARGET_OS_IPHONE

- (void)setContentCompressionResistancePriority:(NSLayoutPriority)priority;
{
    [self setContentCompressionResistancePriority:priority forOrientation:NSLayoutConstraintOrientationHorizontal];
    [self setContentCompressionResistancePriority:priority forOrientation:NSLayoutConstraintOrientationVertical];
}

- (void)setContentHuggingPriority:(NSLayoutPriority)priority;
{
    [self setContentHuggingPriority:priority forOrientation:NSLayoutConstraintOrientationHorizontal];
    [self setContentHuggingPriority:priority forOrientation:NSLayoutConstraintOrientationVertical];
}

#endif



@end



#pragma mark -

@implementation UIView (LayoutConstraintsHelpersRelative)

- (UIView *)superviewCommonWithView:(UIView *)otherView;
{
    // Check common case 1st:
    if (otherView.superview == self.superview) {
        return self.superview;
    }
    
    id chainA[10];
    size_t chainALength = 0;
    id chainB[10];
    size_t chainBLength = 0;
    
    // Slightly brute force:
    chainA[chainALength++] = otherView;
    chainB[chainBLength++] = self;
    do {
        // Check
        for (size_t i = 0; i < chainALength; ++i) {
            for (size_t j = 0; j < chainBLength; ++j) {
                if (chainA[i] == chainB[j]) {
                    return chainA[i];
                }
            }
        }
        BOOL const addToA = chainALength < (sizeof(chainA) / sizeof(*chainA));
        if (addToA) {
            UIView *view = chainA[chainALength - 1];
            chainA[chainALength++] = view.superview;
        }
        BOOL const addToB = chainBLength < (sizeof(chainB) / sizeof(*chainB));
        if (addToB) {
            UIView *view = chainB[chainBLength - 1];
            chainB[chainBLength++] = view.superview;
        }
        if (!addToA && !addToB) {
            break;
        }
    } while (YES);
    return nil;
}

- (NSLayoutConstraint *)addConstraintWithAttribute:(NSLayoutAttribute)attr constant:(CGFloat)c toView:(UIView *)otherView;
{
    UIView *superview = [self superviewCommonWithView:otherView];
    NSLayoutConstraint *constraint = [NSLayoutConstraint constraintWithItem:self attribute:attr toItem:otherView constant:c];
    [superview addConstraint:constraint];
    return constraint;
}

- (NSLayoutConstraint *)addConstraintFromView:(UIView *)otherView constant:(CGFloat)c attribute:(NSLayoutAttribute)attr;
{
    UIView *superview = [self superviewCommonWithView:otherView];
    NSLayoutConstraint *constraint = [NSLayoutConstraint constraintWithItem:otherView attribute:attr toItem:self constant:c];
    [superview addConstraint:constraint];
    return constraint;
}

- (NSLayoutConstraint *)addConstraintForEqualWidthToView:(id)otherView;
{
    UIView *superview = [self superviewCommonWithView:otherView];
    NSLayoutConstraint *constraint = [NSLayoutConstraint constraintForEqualWidthWithItem:self toItem:otherView];
    constraint.priority = currentPriority();
    [superview addConstraint:constraint];
    return constraint;
}

- (NSLayoutConstraint *)addConstraintForEqualHeightToView:(id)otherView;
{
    UIView *superview = [self superviewCommonWithView:otherView];
    NSLayoutConstraint *constraint = [NSLayoutConstraint constraintForEqualHeightWithItem:self toItem:otherView];
    constraint.priority = currentPriority();
    [superview addConstraint:constraint];
    return constraint;
}

- (NSArray *)addConstraintsCenteringToView:(UIView *)otherView
{
    NSLayoutConstraint *hConstraint = [self addConstraintForAligningHorizontallyWithView:otherView];
    NSLayoutConstraint *vConstraint = [self addConstraintForAligningVerticallyWithView:otherView];
    
    return @[hConstraint, vConstraint];
}

- (NSArray *)addConstraintsFittingToView:(UIView *)otherView;
{
    return [[self addConstraintsHorizontallyFittingToView:otherView] arrayByAddingObjectsFromArray:
            [self addConstraintsVerticallyFittingToView:otherView]];
}

- (NSArray *)addConstraintsFittingToView:(UIView *)otherView edgeInsets:(UIEdgeInsets)insets;
{
    UIView *superview = [self superviewCommonWithView:otherView];
    
    NSLayoutConstraint *left = [NSLayoutConstraint constraintWithItem:self attribute:NSLayoutAttributeLeft toItem:otherView constant:insets.left];
    left.priority = currentPriority();
    NSLayoutConstraint *right = [NSLayoutConstraint constraintWithItem:otherView attribute:NSLayoutAttributeRight toItem:self constant:insets.right];
    right.priority = currentPriority();
    NSLayoutConstraint *top = [NSLayoutConstraint constraintWithItem:self attribute:NSLayoutAttributeTop toItem:otherView constant:insets.top];
    top.priority = currentPriority();
    NSLayoutConstraint *bottom = [NSLayoutConstraint constraintWithItem:otherView attribute:NSLayoutAttributeBottom toItem:self constant:insets.bottom];
    bottom.priority = currentPriority();
    
    NSArray *constraints = @[left, right, top, bottom];
    [superview addConstraints:constraints];
    
    return constraints;
}

- (NSArray *)addConstraintsHorizontallyFittingToView:(id)otherView;
{
    UIView *superview = [self superviewCommonWithView:otherView];
    NSArray *constraints = [NSLayoutConstraint constraintsHorizontallyFittingItem:self withItem:otherView];
    [superview addConstraints:constraints];
    return constraints;
}

- (NSArray *)addConstraintsVerticallyFittingToView:(id)otherView;
{
    UIView *superview = [self superviewCommonWithView:otherView];
    NSArray *constraints = [NSLayoutConstraint constraintsVerticallyFittingItem:self withItem:otherView];
    [superview addConstraints:constraints];
    return constraints;
}

- (NSArray *)addConstraintsForRightMargin:(CGFloat)rightMargin leftMargin:(CGFloat)leftMargin relativeToView:(UIView *)otherView;
{
    UIView *superview = [self superviewCommonWithView:otherView];
    NSLayoutConstraint *constraint1 = [NSLayoutConstraint constraintWithItem:self attribute:NSLayoutAttributeLeft toItem:otherView constant:leftMargin];
    constraint1.priority = currentPriority();
    NSLayoutConstraint *constraint2 = [NSLayoutConstraint constraintWithItem:otherView attribute:NSLayoutAttributeRight toItem:self constant:rightMargin];
    constraint2.priority = currentPriority();

    NSArray *constraints = @[constraint1, constraint2];
    [superview addConstraints:constraints];
    
    return constraints;
}

- (NSLayoutConstraint *)addConstraintForRightMargin:(CGFloat)rightMargin relativeToView:(UIView *)otherView;
{
    UIView *superview = [self superviewCommonWithView:otherView];
    NSLayoutConstraint *constraint = [NSLayoutConstraint constraintWithItem:otherView attribute:NSLayoutAttributeRight toItem:self constant:rightMargin];
    constraint.priority = currentPriority();
    [superview addConstraint:constraint];
    return constraint;
}

- (NSLayoutConstraint *)addConstraintForMinRightMargin:(CGFloat)rightMargin relativeToView:(UIView *)otherView;
{
    UIView *superview = [self superviewCommonWithView:otherView];
    NSLayoutConstraint *constraint = [NSLayoutConstraint constraintWithItem:otherView attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationGreaterThanOrEqual toItem:self attribute:NSLayoutAttributeRight multiplier:1.0 constant:rightMargin];
    constraint.priority = currentPriority();
    [superview addConstraint:constraint];
    return constraint;
}

- (NSLayoutConstraint *)addConstraintForMaxRightMargin:(CGFloat)rightMargin relativeToView:(UIView *)otherView;
{
    UIView *superview = [self superviewCommonWithView:otherView];
    NSLayoutConstraint *constraint = [NSLayoutConstraint constraintWithItem:otherView attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationLessThanOrEqual toItem:self attribute:NSLayoutAttributeRight multiplier:1.0 constant:rightMargin];
    constraint.priority = currentPriority();
    [superview addConstraint:constraint];
    return constraint;
}

- (NSLayoutConstraint *)addConstraintForLeftMargin:(CGFloat)leftMargin relativeToView:(UIView *)otherView;
{
    UIView *superview = [self superviewCommonWithView:otherView];
    NSLayoutConstraint *constraint = [NSLayoutConstraint constraintWithItem:self attribute:NSLayoutAttributeLeft toItem:otherView constant:leftMargin];
    constraint.priority = currentPriority();
    [superview addConstraint:constraint];
    return constraint;
}

- (NSLayoutConstraint *)addConstraintForMinLeftMargin:(CGFloat)leftMargin relativeToView:(UIView *)otherView;
{
    UIView *superview = [self superviewCommonWithView:otherView];
    NSLayoutConstraint *constraint = [NSLayoutConstraint constraintWithItem:self attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationGreaterThanOrEqual toItem:otherView attribute:NSLayoutAttributeLeft multiplier:1.0 constant:leftMargin];
    constraint.priority = currentPriority();
    [superview addConstraint:constraint];
    return constraint;
}

- (NSLayoutConstraint *)addConstraintForMaxLeftMargin:(CGFloat)leftMargin relativeToView:(UIView *)otherView;
{
    UIView *superview = [self superviewCommonWithView:otherView];
    NSLayoutConstraint *constraint = [NSLayoutConstraint constraintWithItem:self attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationLessThanOrEqual toItem:otherView attribute:NSLayoutAttributeLeft multiplier:1.0 constant:leftMargin];
    constraint.priority = currentPriority();
    [superview addConstraint:constraint];
    return constraint;
}

- (NSLayoutConstraint *)addConstraintForTopMargin:(CGFloat)topMargin relativeToView:(UIView *)otherView;
{
    UIView *superview = [self superviewCommonWithView:otherView];
    NSLayoutConstraint *constraint = [NSLayoutConstraint constraintWithItem:self attribute:NSLayoutAttributeTop toItem:otherView constant:topMargin];
    constraint.priority = currentPriority();
    [superview addConstraint:constraint];
    return constraint;
}

- (NSLayoutConstraint *)addConstraintForBottomMargin:(CGFloat)bottomMargin relativeToView:(UIView *)otherView;
{
    UIView *superview = [self superviewCommonWithView:otherView];
    NSLayoutConstraint *constraint = [NSLayoutConstraint constraintWithItem:otherView attribute:NSLayoutAttributeBottom toItem:self constant:bottomMargin];
    constraint.priority = currentPriority();
    [superview addConstraint:constraint];
    return constraint;
}


- (NSLayoutConstraint *)addConstraintForAligningHorizontallyWithView:(UIView *)otherView
{
    return [self addConstraintForAligningHorizontallyWithView:otherView offset:0];
}

- (NSLayoutConstraint *)addConstraintForAligningHorizontallyWithView:(UIView *)otherView offset:(CGFloat)offset;
{
    UIView *superview = [self superviewCommonWithView:otherView];
    NSLayoutConstraint *constraint = [NSLayoutConstraint constraintWithItem:otherView attribute:NSLayoutAttributeCenterX toItem:self constant:offset];
    constraint.priority = currentPriority();
    [superview addConstraint:constraint];
    return constraint;
}

- (NSLayoutConstraint *)addConstraintForAligningVerticallyWithView:(UIView *)otherView;
{
    return [self addConstraintForAligningVerticallyWithView:otherView offset:0];
}

- (NSLayoutConstraint *)addConstraintForAligningVerticallyWithView:(UIView *)otherView offset:(CGFloat)offset;
{
    UIView *superview = [self superviewCommonWithView:otherView];
    NSLayoutConstraint *constraint = [NSLayoutConstraint constraintWithItem:self attribute:NSLayoutAttributeCenterY toItem:otherView constant:offset];
    constraint.priority = currentPriority();
    [superview addConstraint:constraint];
    return constraint;
}

- (NSLayoutConstraint *)addConstraintForAligningTopToBottomOfView:(UIView *)otherView distance:(CGFloat)c;
{
    UIView *superview = [self superviewCommonWithView:otherView];
    NSLayoutConstraint *constraint = [NSLayoutConstraint constraintWithItem:self attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:otherView attribute:NSLayoutAttributeBottom multiplier:1 constant:c];
    constraint.priority = currentPriority();
    [superview addConstraint:constraint];
    return constraint;
}

- (NSLayoutConstraint *)addConstraintForAligningBottomToTopOfView:(UIView *)otherView distance:(CGFloat)c;
{
    UIView *superview = [self superviewCommonWithView:otherView];
    NSLayoutConstraint *constraint = [NSLayoutConstraint constraintWithItem:otherView attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeBottom multiplier:1 constant:c];
    constraint.priority = currentPriority();
    [superview addConstraint:constraint];
    return constraint;
}

- (NSLayoutConstraint *)addConstraintForAligningBottomToBottomOfView:(UIView *)otherView distance:(CGFloat)c
{
    UIView *superview = [self superviewCommonWithView:otherView];
    NSLayoutConstraint *constraint = [NSLayoutConstraint constraintWithItem:otherView attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeBottom multiplier:1 constant:c];
    constraint.priority = currentPriority();
    [superview addConstraint:constraint];
    return constraint;
}

- (NSLayoutConstraint *)addConstraintForAligningTopToTopOfView:(UIView *)otherView distance:(CGFloat)c
{
    UIView *superview = [self superviewCommonWithView:otherView];
    NSLayoutConstraint *constraint = [NSLayoutConstraint constraintWithItem:otherView attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeTop multiplier:1 constant:c];
    constraint.priority = currentPriority();
    [superview addConstraint:constraint];
    return constraint;
}


- (NSLayoutConstraint *)addConstraintForAligningLeftToRightOfView:(UIView *)otherView distance:(CGFloat)c;
{
    UIView *superview = [self superviewCommonWithView:otherView];
    NSLayoutConstraint *constraint = [NSLayoutConstraint constraintWithItem:self attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:otherView attribute:NSLayoutAttributeRight multiplier:1 constant:c];
    constraint.priority = currentPriority();
    [superview addConstraint:constraint];
    return constraint;
}

- (NSLayoutConstraint *)addConstraintForAligningLeftToRightOfView:(UIView *)otherView maxDistance:(CGFloat)c;
{
    UIView *superview = [self superviewCommonWithView:otherView];
    NSLayoutConstraint *constraint = [NSLayoutConstraint constraintWithItem:self attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationLessThanOrEqual toItem:otherView attribute:NSLayoutAttributeRight multiplier:1 constant:c];
    constraint.priority = currentPriority();
    [superview addConstraint:constraint];
    return constraint;
}

- (NSLayoutConstraint *)addConstraintForAligningLeftToRightOfView:(UIView *)otherView minDistance:(CGFloat)c;
{
    UIView *superview = [self superviewCommonWithView:otherView];
    NSLayoutConstraint *constraint = [NSLayoutConstraint constraintWithItem:self attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationGreaterThanOrEqual toItem:otherView attribute:NSLayoutAttributeRight multiplier:1 constant:c];
    constraint.priority = currentPriority();
    [superview addConstraint:constraint];
    return constraint;
}

- (NSLayoutConstraint *)addConstraintForAligningLeftToLeftOfView:(UIView *)otherView distance:(CGFloat)c;
{
    UIView *superview = [self superviewCommonWithView:otherView];
    NSLayoutConstraint *constraint = [NSLayoutConstraint constraintWithItem:self attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:otherView attribute:NSLayoutAttributeLeft multiplier:1 constant:c];
    constraint.priority = currentPriority();
    [superview addConstraint:constraint];
    return constraint;
}

- (NSLayoutConstraint *)addConstraintForAligningRightToLeftOfView:(UIView *)otherView distance:(CGFloat)c;
{
    UIView *superview = [self superviewCommonWithView:otherView];
    NSLayoutConstraint *constraint = [NSLayoutConstraint constraintWithItem:self attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:otherView attribute:NSLayoutAttributeLeft multiplier:1 constant:c];
    constraint.priority = currentPriority();
    [superview addConstraint:constraint];
    return constraint;
}

- (NSLayoutConstraint *)addConstraintForAligningRightToRightOfView:(UIView *)otherView distance:(CGFloat)c;
{
    UIView *superview = [self superviewCommonWithView:otherView];
    NSLayoutConstraint *constraint = [NSLayoutConstraint constraintWithItem:self attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:otherView attribute:NSLayoutAttributeRight multiplier:1 constant:c];
    constraint.priority = currentPriority();
    [superview addConstraint:constraint];
    return constraint;
}

- (NSLayoutConstraint *)addConstraintForAligningCenterToLeftOfView:(UIView *)otherView distance:(CGFloat)c;
{
    UIView *superview = [self superviewCommonWithView:otherView];
    NSLayoutConstraint *constraint = [NSLayoutConstraint constraintWithItem:self attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:otherView attribute:NSLayoutAttributeLeft multiplier:1 constant:c];
    constraint.priority = currentPriority();
    [superview addConstraint:constraint];
    return constraint;
}

- (NSLayoutConstraint *)addConstraintForAligningCenterToBottomOfView:(UIView *)otherView distance:(CGFloat)c
{
    UIView *superview = [self superviewCommonWithView:otherView];
    NSLayoutConstraint *constraint = [NSLayoutConstraint constraintWithItem:otherView attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeCenterY multiplier:1 constant:c];
    constraint.priority = currentPriority();
    [superview addConstraint:constraint];
    return constraint;
}

- (NSArray*)addConstraintsForStackingViewsVertically:(NSArray*)views withSpacing:(CGFloat)spacing bottomMargin:(CGFloat)bottomMargin
{
    NSMutableArray* constraints = [NSMutableArray array];
    UIView *previousView = nil;
    for (UIView *view in views) {
        if (previousView) {
            NSLayoutConstraint* constraint = [view addConstraintForAligningTopToBottomOfView:previousView distance:spacing];
            constraint.priority = currentPriority();
            [constraints addObject:constraint];
        }
        previousView = view;
    }
    NSLayoutConstraint* constraint = [views.lastObject addConstraintForBottomMargin:bottomMargin relativeToView:self];
    constraint.priority = currentPriority();
    [constraints addObject:constraint];
    return constraints;
}

- (NSArray*)addConstraintsForStackingViewsHorizontally:(NSArray*)views withSpacing:(CGFloat)spacing
{
    NSMutableArray* constraints = [NSMutableArray array];
    UIView *previousView = nil;
    for (UIView *view in views) {
        if (previousView) {
            NSLayoutConstraint* constraint = [view addConstraintForAligningLeftToRightOfView:previousView distance:spacing];
            constraint.priority = currentPriority();
            [constraints addObject:constraint];
        }
        previousView = view;
    }
    NSLayoutConstraint* constraint = [views.lastObject addConstraintForRightMargin:0 relativeToView:self];
    constraint.priority = currentPriority();
    [constraints addObject:constraint];
    return constraints;
}

- (NSArray *)addConstraintsForPositioningInView:(UIView *)otherView withLayoutConstants:(NSDictionary *)constants
{
    NSMutableArray *constraints = [NSMutableArray array];
    
    if (constants[@"top"]) {
        NSLayoutConstraint *constraint = [self addConstraintForTopMargin:[constants[@"top"] floatValue] relativeToView:otherView];
        [constraints addObject:constraint];
    }
    
    if (constants[@"bottom"]) {
        NSLayoutConstraint *constraint = [self addConstraintForBottomMargin:[constants[@"bottom"] floatValue] relativeToView:otherView];
        [constraints addObject:constraint];
    }
    
    if (constants[@"left"]) {
        NSLayoutConstraint *constraint = [self addConstraintForLeftMargin:[constants[@"left"] floatValue] relativeToView:otherView];
        [constraints addObject:constraint];
    }
    
    if (constants[@"right"]) {
        NSLayoutConstraint *constraint = [self addConstraintForRightMargin:[constants[@"right"] floatValue] relativeToView:otherView];
        [constraints addObject:constraint];
    }

    if (constants[@"height"]) {
        NSLayoutConstraint *constraint = [self addConstraintForHeight:[constants[@"height"] floatValue]];
        [constraints addObject:constraint];
    }

    if (constants[@"width"]) {
        NSLayoutConstraint *constraint = [self addConstraintForWidth:[constants[@"width"] floatValue]];
        [constraints addObject:constraint];
    }
    
    return constraints;
}



@end



@implementation UIView (LayoutConstraintsHelpersPriority)

+ (void)withPriority:(UILayoutPriority)priority setConstraints:(dispatch_block_t)block;
{
    pushPriority(priority);
    block();
    popPriority();
}

@end



static UILayoutPriority priorities[3];
static int priorityCount;

static void pushPriority(UILayoutPriority const newPriority)
{
    ++priorityCount;
    NSCAssert((ssize_t) priorityCount < (ssize_t) (sizeof(priorities) / sizeof(*priorities)), @"");
    priorities[priorityCount] = newPriority;
}

static void popPriority(void)
{
    NSCAssert(0 < priorityCount, @"");
    --priorityCount;
}

static UILayoutPriority currentPriority(void)
{
    return (0 < priorityCount) ? priorities[priorityCount] : 1000;
}

UILayoutPriority CurrentLayoutPriority(void)
{
    return currentPriority();
}

