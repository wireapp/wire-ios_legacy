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


#import "TokenField.h"
#import "TokenField+Internal.h"

#import "Wire-Swift.h"

@class TokenizedTextView;

static NSString* ZMLogTag ZM_UNUSED = @"UI";

CGFloat const accessoryButtonSize = 32.0f;



@implementation TokenField

#pragma mark - Init

- (instancetype)init
{
    self = [super init];
    if (self) {
        [self setup];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    return self;
}

#pragma mark - Setup

- (void)setup
{
    self.currentTokens = [@[] mutableCopy];
    self.numberOfLines = NSUIntegerMax;
    
    [self setupDefaultAppearance];
    [self setupSubviews];
    [self setupConstraints];
    [self setupStyle];
}

- (void)setupDefaultAppearance
{
    [self setupFonts];
    _textColor = [UIColor blackColor];
    _lineSpacing = 8.0f;
    _hasAccessoryButton = NO;
    _tokenTitleVerticalAdjustment = 1;

    self.tokenTitleColor = [UIColor whiteColor];
    self.tokenSelectedTitleColor = [UIColor colorWithRed:0.103 green:0.382 blue:0.691 alpha:1.000];
    self.tokenBackgroundColor = [UIColor colorWithRed:0.118 green:0.467 blue:0.745 alpha:1.000];
    self.tokenSelectedBackgroundColor = [UIColor whiteColor];
    self.tokenBorderColor = [UIColor colorWithRed:0.118 green:0.467 blue:0.745 alpha:1.000];
    self.tokenSelectedBorderColor = [UIColor colorWithRed:0.118 green:0.467 blue:0.745 alpha:1.000];
    self.tokenTextTransform = TextTransformUpper;
    self.dotColor = [ColorScheme.defaultColorScheme colorWithName:ColorSchemeColorTextDimmed];
}

- (void)setupConstraints
{
    NSDictionary *views = @{@"textView": self.textView,
                            @"toLabel": self.toLabel,
                            @"button": self.accessoryButton};
    NSDictionary *metrics = @{@"left": @(self.textView.textContainerInset.left),
                              @"top": @(self.textView.textContainerInset.top),
                              @"right": @(self.textView.textContainerInset.right),
                              @"bSize": @(accessoryButtonSize),
                              @"bTop": @(self.accessoryButtonTop),
                              @"bRight": @(self.accessoryButtonRight),
                              };

    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[textView]|" options:0 metrics:nil views:views]];
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[textView]|" options:0 metrics:nil views:views]];
    self.accessoryButtonRightMargin = [[NSLayoutConstraint constraintsWithVisualFormat:@"H:[button]-(bRight)-|" options:0 metrics:metrics views:views] objectAtIndex:0];
    self.accessoryButtonTopMargin = [[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-(bTop)-[button]" options:0 metrics:metrics views:views] objectAtIndex:0];
    [self addConstraints:@[self.accessoryButtonRightMargin, self.accessoryButtonTopMargin]];
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:[button(bSize)]" options:0 metrics:metrics views:views]];
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[button(bSize)]" options:0 metrics:metrics views:views]];
    
    self.toLabelLeftMargin = [[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-(left)-[toLabel]" options:0 metrics:metrics views:views] objectAtIndex:0];
    self.toLabelTopMargin = [[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-(top)-[toLabel]" options:0 metrics:metrics views:views] objectAtIndex:0];
    [self.textView addConstraints:@[self.toLabelLeftMargin, self.toLabelTopMargin]];
    
    [self updateTextAttributes];
}

#pragma mark - Appearance

- (void)setFont:(UIFont *)font
{
    if ([_font isEqual:font]) {
        return;
    }
    _font = font;
    [self updateTextAttributes];
}

- (void)setTextColor:(UIColor *)textColor
{
    if ([_textColor isEqual:textColor]) {
        return;
    }
    _textColor = textColor;
    [self updateTextAttributes];
}

- (void)setLineSpacing:(CGFloat)lineSpacing
{
    if (_lineSpacing == lineSpacing) {
        return;
    }
    _lineSpacing = lineSpacing;
    [self updateTextAttributes];
}

- (void)setTokenOffset:(CGFloat)tokenOffset
{
    if (_tokenOffset == tokenOffset) {
        return;
    }
    _tokenOffset = tokenOffset;
    [self updateExcludePath];
    [self updateTokenAttachments];
}

- (NSDictionary *)textAttributes
{
    NSMutableDictionary *attributes = [NSMutableDictionary new];
    
    NSMutableParagraphStyle *inputParagraphStyle = [[NSMutableParagraphStyle alloc] init];
    inputParagraphStyle.lineSpacing = self.lineSpacing;
    attributes[NSParagraphStyleAttributeName] = inputParagraphStyle;
    
    if (self.font) {
        attributes[NSFontAttributeName] = self.font;
    }
    if (self.textColor) {
        attributes[NSForegroundColorAttributeName] = self.textColor;
    }
    
    return attributes;
}

- (void)setToLabelText:(NSString *)toLabelText
{
    if ([_toLabelText isEqualToString:toLabelText]) {
        return;
    }
    _toLabelText = toLabelText;
    [self updateTextAttributes];
}

- (void)setHasAccessoryButton:(BOOL)hasAccessoryButton
{
    if (_hasAccessoryButton == hasAccessoryButton) {
        return;
    }
    
    _hasAccessoryButton = hasAccessoryButton;
    self.accessoryButton.hidden = ! hasAccessoryButton;
    [self updateExcludePath];
}

- (void)setTokenTitleColor:(UIColor *)color
{
    if ([_tokenTitleColor isEqual:color]) {
        return;
    }
    _tokenTitleColor = color;
    [self updateTokenAttachments];
}

- (void)setTokenSelectedTitleColor:(UIColor *)color
{
    if ([_tokenSelectedTitleColor isEqual:color]) {
        return;
    }
    _tokenSelectedTitleColor = color;
    [self updateTokenAttachments];
}

- (void)setTokenBackgroundColor:(UIColor *)color
{
    if ([_tokenBackgroundColor isEqual:color]) {
        return;
    }
    _tokenBackgroundColor = color;
    [self updateTokenAttachments];
}

- (void)setTokenSelectedBackgroundColor:(UIColor *)color
{
    if ([_tokenSelectedBackgroundColor isEqual:color]) {
        return;
    }
    _tokenSelectedBackgroundColor = color;
    [self updateTokenAttachments];
}

- (void)setTokenBorderColor:(UIColor *)color
{
    if ([_tokenBorderColor isEqual:color]) {
        return;
    }
    _tokenBorderColor = color;
    [self updateTokenAttachments];
}

- (void)setTokenSelectedBorderColor:(UIColor *)color
{
    if ([_tokenSelectedBorderColor isEqual:color]) {
        return;
    }
    _tokenSelectedBorderColor = color;
    [self updateTokenAttachments];
}

- (void)setTokenTitleVerticalAdjustment:(CGFloat)tokenTitleVerticalAdjustment
{
    if (_tokenTitleVerticalAdjustment == tokenTitleVerticalAdjustment) {
        return;
    }
    _tokenTitleVerticalAdjustment = tokenTitleVerticalAdjustment;
    [self updateTokenAttachments];
}

#pragma mark - UIView overrides

- (BOOL)isFirstResponder
{
    return self.textView.isFirstResponder;
}

- (BOOL)canBecomeFirstResponder
{
    return [self.textView canBecomeFirstResponder];
}

- (BOOL)canResignFirstResponder
{
    return [self.textView canResignFirstResponder];
}

- (BOOL)becomeFirstResponder
{
    [self setCollapsed:NO animated:YES];
    return [self.textView becomeFirstResponder];
}

- (BOOL)resignFirstResponder
{
    [super resignFirstResponder];
    return [self.textView resignFirstResponder];
}

#pragma mark - Public Interface

- (NSArray *)tokens
{
    return self.currentTokens;
}

- (void)addTokenForTitle:(NSString *)title representedObject:(id)object
{
    Token *token = [[Token alloc] initWithTitle:title representedObject:object];
    [self addToken:token];
}

- (void)addToken:(Token *)token
{
    if (! [self.currentTokens containsObject:token]) {
        [self.currentTokens addObject:token];
    } else {
        return;
    }
    
    [self updateMaxTitleWidthForToken:token];
    
    if (! self.isCollapsed) {
        self.textView.attributedText = [self stringForTokens:self.currentTokens];
        // Calling -insertText: forces textView to update its contentSize, while other public methods do not.
        // Broken contentSize leads to broken scrolling to bottom of input field.
        [self.textView insertText:@""];
        
        if ([self.delegate respondsToSelector:@selector(tokenField:changedFilterTextTo:)]) {
            [self.delegate tokenField:self changedFilterTextTo:@""];
        }

        [self invalidateIntrinsicContentSize];
        
        // Move the cursor to the end of the input field
        self.textView.selectedRange = NSMakeRange(self.textView.text.length, 0);
        
        // autoscroll to the end of the input field
        [self setNeedsLayout];
        [self updateLayout];
        [self scrollToBottomOfInputField];
    } else {
        self.textView.attributedText = [self collapsedString];
        [self invalidateIntrinsicContentSize];
    }    
}

- (void)updateMaxTitleWidthForToken:(Token *)token
{
    CGFloat tokenMaxSizeWidth = self.textView.textContainer.size.width;
    if (self.currentTokens.count == 0) {
        tokenMaxSizeWidth -= self.toLabel.frame.size.width + (self.hasAccessoryButton ? self.accessoryButton.frame.size.width : 0.0f) + self.tokenOffset;
    } else if (self.currentTokens.count == 1) {
        tokenMaxSizeWidth -= (self.hasAccessoryButton ? self.accessoryButton.frame.size.width : 0.0f);
    }
    token.maxTitleWidth = tokenMaxSizeWidth;
}

- (Token *)tokenForRepresentedObject:(id)object
{
    for (Token *token in self.currentTokens) {
        if ([token.representedObject isEqual:object]) {
            return token;
        }
    }
    return nil;
}

- (void)scrollToBottomOfInputField
{
    if (self.textView.contentSize.height > self.textView.bounds.size.height) {
        [self.textView setContentOffset:CGPointMake(0.0f, self.textView.contentSize.height - self.textView.bounds.size.height)
                               animated:YES];
    }
    else {
        [self.textView setContentOffset:CGPointZero];
    }
}

- (void)setExcludedRect:(CGRect)excludedRect
{
    if (CGRectEqualToRect(_excludedRect, excludedRect)) {
        return;
    }
    
    _excludedRect = excludedRect;
    [self updateExcludePath];
}

- (void)setNumberOfLines:(NSUInteger)numberOfLines
{
    if (_numberOfLines != numberOfLines) {
        _numberOfLines = numberOfLines;
        [self invalidateIntrinsicContentSize];
    }
}

- (void)setCollapsed:(BOOL)collapsed
{
    [self setCollapsed:collapsed animated:NO];
}

- (void)setCollapsed:(BOOL)collapsed animated:(BOOL)animated
{
    if (_collapsed == collapsed) {
        return;
    }
    
    if (self.currentTokens.count == 0) {
        return;
    }
    
    _collapsed = collapsed;
    
    dispatch_block_t animationBlock = ^{
        [self invalidateIntrinsicContentSize];
        [self layoutIfNeeded];
    };
    ZM_WEAK(self);
    void (^compeltionBlock) (BOOL) = ^(BOOL finnished) {
        ZM_STRONG(self);
        if (self.collapsed) {
            self.textView.attributedText = [self collapsedString];
            [self invalidateIntrinsicContentSize];
            [UIView animateWithDuration:0.2 animations:^{
                [self.textView setContentOffset:CGPointZero animated:NO];
            }];
        } else {
            self.textView.attributedText = [self stringForTokens:self.currentTokens];
            [self invalidateIntrinsicContentSize];
            if (self.textView.attributedText.length > 0) {
                self.textView.selectedRange = NSMakeRange(self.textView.attributedText.length, 0);
                [UIView animateWithDuration:0.2 animations:^{
                    [self.textView scrollRangeToVisible:self.textView.selectedRange];
                }];
            }
        }
    };
    
    if (animated) {
        [UIView animateWithDuration:0.25
                         animations:animationBlock
                         completion:compeltionBlock];
    } else {
        animationBlock();
        compeltionBlock(YES);
    }
}

#pragma mark - Layout

- (CGSize)intrinsicContentSize
{
    CGFloat height = self.textView.contentSize.height;
    CGFloat maxHeight = self.font.lineHeight * self.numberOfLines + self.lineSpacing * (self.numberOfLines - 1) +
        self.textView.textContainerInset.top + self.textView.textContainerInset.bottom;
    CGFloat minHeight = self.font.lineHeight * 1 + self.textView.textContainerInset.top + self.textView.textContainerInset.bottom;
    
    if (self.collapsed) {
        return CGSizeMake(UIViewNoIntrinsicMetric, minHeight);
    } else {
        return CGSizeMake(UIViewNoIntrinsicMetric, MAX(MIN(height, maxHeight), minHeight));
    }
}

- (CGFloat)accessoryButtonTop
{
    return self.textView.textContainerInset.top + (self.font.lineHeight - accessoryButtonSize) / 2 - self.textView.contentOffset.y;
}

- (CGFloat)accessoryButtonRight
{
    return self.textView.textContainerInset.right;
}

- (void)updateLayout
{
    if (self.toLabelText.length > 0) {
        self.toLabelLeftMargin.constant = self.textView.textContainerInset.left;
        self.toLabelTopMargin.constant = self.textView.textContainerInset.top;
    }
    if (self.hasAccessoryButton) {
        self.accessoryButtonRightMargin.constant = self.accessoryButtonRight;
        self.accessoryButtonTopMargin.constant = self.accessoryButtonTop;
    }
    [self layoutIfNeeded];
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    BOOL anyTokenUpdated = NO;
    for (Token *token in self.currentTokens) {
        if (token.maxTitleWidth == 0) {
            [self updateMaxTitleWidthForToken:token];
            anyTokenUpdated = YES;
        }
    }
    
    if (anyTokenUpdated) {
        [self updateTokenAttachments];
        NSRange wholeRange = NSMakeRange(0, self.textView.attributedText.length);
        [self.textView.layoutManager invalidateLayoutForCharacterRange:wholeRange actualCharacterRange:NULL];
    }
}

#pragma mark - Utility

- (NSAttributedString *)collapsedString
{
    NSString *collapsedText = NSLocalizedString(@" ...", nil);

    return [[NSAttributedString alloc] initWithString:collapsedText attributes:self.textAttributes];
}

- (void)clearFilterText
{
    __block NSInteger firstCharacterIndex = NSNotFound;
    
    NSCharacterSet *notWhitespace = [[NSCharacterSet whitespaceAndNewlineCharacterSet] invertedSet];
    
    [self.textView.text enumerateSubstringsInRange:NSMakeRange(0, self.textView.text.length)
                                           options:NSStringEnumerationByComposedCharacterSequences
                                        usingBlock:^(NSString *substring, NSRange substringRange, NSRange enclosingRange, BOOL *stop)
     {
         if (substring.length && ([substring characterAtIndex:0] != NSAttachmentCharacter) && [substring rangeOfCharacterFromSet:notWhitespace].location != NSNotFound) {
             firstCharacterIndex = substringRange.location;
             *stop = YES;
         }
     }];
    
    self.filterText = @"";
    if (firstCharacterIndex != NSNotFound) {
        NSRange rangeToClear = NSMakeRange(firstCharacterIndex, self.textView.text.length - firstCharacterIndex);
        
        [self.textView.textStorage beginEditing];
        [self.textView.textStorage deleteCharactersInRange:rangeToClear];
        [self.textView.textStorage endEditing];
        [self.textView insertText:@""];
        
        [self invalidateIntrinsicContentSize];
        [self layoutIfNeeded];
    }
}

- (void)updateTextAttributes
{
    self.textView.typingAttributes = self.textAttributes;
    [self.textView.textStorage beginEditing];
    [self.textView.textStorage addAttributes:self.textAttributes range:NSMakeRange(0, self.textView.textStorage.length)];
    [self.textView.textStorage endEditing];
    
    if (self.toLabelText) {
        self.toLabel.attributedText = [[NSMutableAttributedString alloc] initWithString:self.toLabelText attributes:self.textAttributes];
    } else {
        self.toLabel.text = @"";
    }
    
    [self updateExcludePath];
}

- (void)updateExcludePath
{
    [self updateLayout];
    
    NSMutableArray *exclusionPaths = [@[] mutableCopy];
    
    if (CGRectEqualToRect(self.excludedRect, CGRectZero) == false) {
        CGAffineTransform transform = CGAffineTransformMakeTranslation(self.textView.contentOffset.x,
                                                                       self.textView.contentOffset.y);
        CGRect transformedRect = CGRectApplyAffineTransform(self.excludedRect, transform);
        UIBezierPath *path = [UIBezierPath bezierPathWithRect:transformedRect];
        [exclusionPaths addObject:path];
    }
    
    if (self.toLabelText.length > 0) {
        CGRect transformedRect = CGRectOffset(self.toLabel.frame,
                                              - self.textView.textContainerInset.left,
                                              - self.textView.textContainerInset.top);
        transformedRect.size.width += self.tokenOffset;
        UIBezierPath *path = [UIBezierPath bezierPathWithRect:transformedRect];
        [exclusionPaths addObject:path];
    }
    
    if (self.hasAccessoryButton) {
        // Exclude path should be relative to content of button, not frame.
        // Assuming intrinsic content size is a size of visual content of the button,
        // 1. Calcutale frame with same center as accessoryButton has, but with size of intrinsicContentSize
        CGRect transformedRect = self.accessoryButton.frame;
        CGSize contentSize = CGSizeMake(accessoryButtonSize, accessoryButtonSize);
        transformedRect = CGRectInset(transformedRect, 0.5 * (transformedRect.size.width - contentSize.width), 0.5 * (transformedRect.size.height - contentSize.height));
        
        // 2. Convert frame to textView coordinate system
        transformedRect = [self.textView convertRect:transformedRect fromView:self];
        CGAffineTransform transform = CGAffineTransformMakeTranslation( - self.textView.textContainerInset.left, - self.textView.textContainerInset.top);
        transformedRect = CGRectApplyAffineTransform(transformedRect, transform);
        
        UIBezierPath *path = [UIBezierPath bezierPathWithRect:transformedRect];
        [exclusionPaths addObject:path];
    }
    
    self.textView.textContainer.exclusionPaths = exclusionPaths;
}


#pragma mark - UIScrollViewDelegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    if (scrollView == self.textView) {
        [self updateExcludePath];
    }
}

@end
