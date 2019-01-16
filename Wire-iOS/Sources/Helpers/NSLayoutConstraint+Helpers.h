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



@import UIKit;

@interface NSLayoutConstraint (HelpersGeneric)

+ (instancetype)constraintWithItem:(UIView *)view1 attribute:(NSLayoutAttribute)attr toItem:(UIView *)view2;
+ (instancetype)constraintWithItem:(UIView *)view1 attribute:(NSLayoutAttribute)attr toItem:(UIView *)view2 constant:(CGFloat)c;

@end



@interface NSLayoutConstraint (HelpersRelative)

+ (instancetype)constraintForEqualWidthWithItem:(UIView *)view1 toItem:(UIView *)view2;
+ (instancetype)constraintForEqualHeightWithItem:(UIView *)view1 toItem:(UIView *)view2;

+ (NSArray *)constraintsHorizontallyFittingItem:(UIView *)view1 withItem:(UIView *)view2;
+ (NSArray *)constraintsVerticallyFittingItem:(UIView *)view1 withItem:(UIView *)view2;

@end



@interface UIView (LayoutConstraintsHelpersAbsolute)

- (NSArray *)addConstraintsForSize:(CGSize)size;
- (NSLayoutConstraint *)addConstraintForWidth:(CGFloat)width;
- (NSLayoutConstraint *)addConstraintForHeight:(CGFloat)height;
- (NSLayoutConstraint *)addConstraintForMaxWidth:(CGFloat)width;
- (NSLayoutConstraint *)addConstraintForMaxHeight:(CGFloat)height;
- (NSLayoutConstraint *)addConstraintForMinWidth:(CGFloat)width;
- (NSLayoutConstraint *)addConstraintForMinHeight:(CGFloat)height;
- (NSLayoutConstraint *)addConstraintForHeightAsMultipleOfWidth:(CGFloat)multiplier;
- (NSLayoutConstraint *)addConstraintForWidthAsMultipleOfHeight:(CGFloat)multiplier;


#if !TARGET_OS_IPHONE
// upstream APIs only available on OSX
- (void)setContentCompressionResistancePriority:(NSLayoutPriority)priority;
- (void)setContentHuggingPriority:(NSLayoutPriority)priority;
#endif

@end



@interface UIView (LayoutConstraintsHelpersRelative)

/**
 C.f. "Constraints May Cross View Hierarchies" documentation. */
- (UIView *)superviewCommonWithView:(UIView *)otherView;

/** Note the ordering! */
- (NSLayoutConstraint *)addConstraintWithAttribute:(NSLayoutAttribute)attr constant:(CGFloat)c toView:(UIView *)otherView;
- (NSLayoutConstraint *)addConstraintFromView:(UIView *)otherView constant:(CGFloat)c attribute:(NSLayoutAttribute)attr;

- (NSLayoutConstraint *)addConstraintForEqualWidthToView:(UIView *)otherView;
- (NSLayoutConstraint *)addConstraintForEqualHeightToView:(UIView *)otherView;

- (NSArray *)addConstraintsFittingToView:(UIView *)otherView;
- (NSArray *)addConstraintsFittingToView:(UIView *)otherView edgeInsets:(UIEdgeInsets)insets;
// Centers horizontally
- (NSArray *)addConstraintsHorizontallyFittingToView:(UIView *)otherView;
// Centers vertically
- (NSArray *)addConstraintsVerticallyFittingToView:(UIView *)otherView;

- (NSLayoutConstraint *)addConstraintsCenteringToView:(UIView *)otherView;

- (NSArray *)addConstraintsForRightMargin:(CGFloat)rightMargin leftMargin:(CGFloat)leftMargin relativeToView:(UIView *)otherView;
- (NSLayoutConstraint *)addConstraintForRightMargin:(CGFloat)rightMargin relativeToView:(UIView *)otherView;
- (NSLayoutConstraint *)addConstraintForLeftMargin:(CGFloat)leftMargin relativeToView:(UIView *)otherView;
- (NSLayoutConstraint *)addConstraintForMinRightMargin:(CGFloat)rightMargin relativeToView:(UIView *)otherView;
- (NSLayoutConstraint *)addConstraintForMaxRightMargin:(CGFloat)rightMargin relativeToView:(UIView *)otherView;
- (NSLayoutConstraint *)addConstraintForMinLeftMargin:(CGFloat)leftMargin relativeToView:(UIView *)otherView;
- (NSLayoutConstraint *)addConstraintForMaxLeftMargin:(CGFloat)leftMargin relativeToView:(UIView *)otherView;

- (NSLayoutConstraint *)addConstraintForTopMargin:(CGFloat)topMargin relativeToView:(UIView *)otherView;
- (NSLayoutConstraint *)addConstraintForBottomMargin:(CGFloat)bottomMargin relativeToView:(UIView *)otherView;

- (NSLayoutConstraint *)addConstraintForAligningHorizontallyWithView:(UIView *)otherView;
- (NSLayoutConstraint *)addConstraintForAligningHorizontallyWithView:(UIView *)otherView offset:(CGFloat)offset;

- (NSLayoutConstraint *)addConstraintForAligningVerticallyWithView:(UIView *)otherView;
- (NSLayoutConstraint *)addConstraintForAligningVerticallyWithView:(UIView *)otherView offset:(CGFloat)offset;

- (NSLayoutConstraint *)addConstraintForAligningTopToBottomOfView:(UIView *)otherView distance:(CGFloat)c;
- (NSLayoutConstraint *)addConstraintForAligningBottomToTopOfView:(UIView *)otherView distance:(CGFloat)c;
- (NSLayoutConstraint *)addConstraintForAligningTopToTopOfView:(UIView *)otherView distance:(CGFloat)c;
- (NSLayoutConstraint *)addConstraintForAligningBottomToBottomOfView:(UIView *)otherView distance:(CGFloat)c;


- (NSLayoutConstraint *)addConstraintForAligningLeftToRightOfView:(UIView *)otherView distance:(CGFloat)c;
- (NSLayoutConstraint *)addConstraintForAligningLeftToRightOfView:(UIView *)otherView minDistance:(CGFloat)c;
- (NSLayoutConstraint *)addConstraintForAligningLeftToRightOfView:(UIView *)otherView maxDistance:(CGFloat)c;
- (NSLayoutConstraint *)addConstraintForAligningLeftToLeftOfView:(UIView *)otherView distance:(CGFloat)c;
- (NSLayoutConstraint *)addConstraintForAligningRightToLeftOfView:(UIView *)otherView distance:(CGFloat)c;
- (NSLayoutConstraint *)addConstraintForAligningRightToRightOfView:(UIView *)otherView distance:(CGFloat)c;
- (NSLayoutConstraint *)addConstraintForAligningCenterToLeftOfView:(UIView *)otherView distance:(CGFloat)c;
- (NSLayoutConstraint *)addConstraintForAligningCenterToBottomOfView:(UIView *)otherView distance:(CGFloat)c;

- (NSArray*)addConstraintsForStackingViewsVertically:(NSArray*)views withSpacing:(CGFloat)spacing bottomMargin:(CGFloat)bottomMargin;
- (NSArray*)addConstraintsForStackingViewsHorizontally:(NSArray*)views withSpacing:(CGFloat)spacing;

/// Add constraints to position a view in the given view with constants dictionary containing any subset of “top”, “bottom”, “left”, “right”, “height” and “width” keys
- (NSArray *)addConstraintsForPositioningInView:(UIView *)otherView withLayoutConstants:(NSDictionary *)constants;

@end



@interface UIView (LayoutConstraintsHelpersPriority)

/// Supports nesting.
/// @code
/// [NSView withPriority:500 setConstraints:^(){
///     [view addConstraintForMinHeight:200];
///     [view addConstraintForMaxHeight:500];
/// }];
/// @encode
+ (void)withPriority:(UILayoutPriority)priority setConstraints:(dispatch_block_t)block __attribute__((nonnull));

@end


/// Returns the priority used by +[NSView withPriority:setConstraints:] (or 1000 when used outside such a block).
FOUNDATION_EXTERN UILayoutPriority CurrentLayoutPriority(void);
