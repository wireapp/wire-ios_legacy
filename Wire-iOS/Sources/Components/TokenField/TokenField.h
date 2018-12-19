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
#import "TextTransform.h"

NS_ASSUME_NONNULL_BEGIN

@class Token;
@class TokenField;
@class TextView;
@class IconButton;


@protocol TokenFieldDelegate <NSObject>

@optional
- (void)tokenField:(TokenField *)tokenField changedTokensTo:(NSArray <Token *> *)tokens;
- (void)tokenField:(TokenField *)tokenField changedFilterTextTo:(NSString *)text;
- (void)tokenFieldDidBeginEditing:(TokenField *)tokenField;
- (void)tokenFieldWillScroll:(TokenField *)tokenField;
- (void)tokenFieldDidConfirmSelection:(TokenField *)controller;
- (NSString *)tokenFieldStringForCollapsedState:(TokenField *)tokenField;

@end


@interface TokenField : UIView

@property (weak, nonatomic, nullable) id<TokenFieldDelegate> delegate;

@property (readonly, nonatomic) TextView *textView;

@property (nonatomic) BOOL hasAccessoryButton;
@property (readonly, nonatomic) IconButton *accessoryButton;

@property (readonly, nonatomic) NSArray <Token *> *tokens;
@property (copy, readonly, nonatomic) NSString *filterText;

- (void)addToken:(Token *)token;
- (void)addTokenForTitle:(NSString *)title representedObject:(id)object;
- (nullable Token *)tokenForRepresentedObject:(id)object;    // searches by isEqual:
- (void)removeToken:(Token *)token;
- (void)removeAllTokens;
- (void)clearFilterText;

// Collapse

@property (assign, nonatomic) NSUInteger numberOfLines; // in not collapsed state; in collapsed state - 1 line; default to NSUIntegerMax
@property (assign, nonatomic, getter=isCollapsed) BOOL collapsed;
- (void)setCollapsed:(BOOL)collapsed animated:(BOOL)animated;


// Appearance

@property (nonatomic, nullable) NSString *toLabelText;

@property (nonatomic, nullable) UIFont *font;
@property (nonatomic, nullable) UIColor *textColor;

@property (nonatomic, nullable) UIFont *tokenTitleFont;
@property (nonatomic, nullable) UIColor *tokenTitleColor;
@property (nonatomic, nullable) UIColor *tokenSelectedTitleColor;
@property (nonatomic, nullable) UIColor *tokenBackgroundColor;
@property (nonatomic, nullable) UIColor *tokenSelectedBackgroundColor;
@property (nonatomic, nullable) UIColor *tokenBorderColor;
@property (nonatomic, nullable) UIColor *tokenSelectedBorderColor;
@property (nonatomic, nullable) UIColor *dotColor;
@property (nonatomic) TextTransform tokenTextTransform;

@property (nonatomic) CGFloat lineSpacing;
@property (nonatomic) CGFloat tokenOffset;    // horisontal distance between tokens, and btw "To:" and first token
@property (nonatomic) CGFloat tokenTitleVerticalAdjustment;

// Utils
@property (nonatomic) CGRect excludedRect;  // rect for excluded path in textView text container

@property (nonatomic, readonly) BOOL userDidConfirmInput;
- (void)filterUnwantedAttachments;

- (void)scrollToBottomOfInputField;

- (BOOL)isFirstResponder;
- (BOOL)becomeFirstResponder;
- (BOOL)resignFirstResponder;


@end

NS_ASSUME_NONNULL_END
