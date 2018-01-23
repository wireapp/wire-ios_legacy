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


#import "TokenizedTextView.h"
#import "TokenTextAttachment.h"
#import "Token.h"

@interface TokenizedTextView () <UIGestureRecognizerDelegate>
@property (nonatomic, strong) UITapGestureRecognizer *tapSelectionGestureRecognizer;
@end

@implementation TokenizedTextView

@dynamic delegate;

#pragma mark - Init

- (instancetype)initWithFrame:(CGRect)frame textContainer:(NSTextContainer *)textContainer
{
    self = [super initWithFrame:frame textContainer:textContainer];
    if (self) {
        [self setupGestureRecognizer];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self setupGestureRecognizer];
    }
    return self;
}

- (void)setupGestureRecognizer
{
    if (self.tapSelectionGestureRecognizer == nil) {
        self.tapSelectionGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(didTapText:)];
        self.tapSelectionGestureRecognizer.delegate = self;
        [self addGestureRecognizer:self.tapSelectionGestureRecognizer];
    }
}

#pragma mark - Actions

- (void)setContentOffset:(CGPoint)contentOffset
{
    // Text view require no scrolling in case the content size is not overflowing the bounds
    if (self.contentSize.height > self.bounds.size.height) {
        [super setContentOffset:contentOffset];
    }
    else {
        [super setContentOffset:CGPointZero];
    }

}

- (void)setTextContainerInset:(UIEdgeInsets)textContainerInset
{
    [super setTextContainerInset:textContainerInset];
    if ([self.delegate respondsToSelector:@selector(tokenizedTextView:textContainerInsetChanged:)]) {
        [self.delegate tokenizedTextView:self textContainerInsetChanged:textContainerInset];
    }
}

- (void)didTapText:(UITapGestureRecognizer *)recognizer
{
    NSLayoutManager *layoutManager = self.layoutManager;
    CGPoint location = [recognizer locationInView:self];
    location.x -= self.textContainerInset.left;
    location.y -= self.textContainerInset.top;

    // Find the character that's been tapped on
    NSUInteger characterIndex;
    CGFloat fraction = 0;
    characterIndex = [layoutManager characterIndexForPoint:location
                                           inTextContainer:self.textContainer
                  fractionOfDistanceBetweenInsertionPoints:&fraction];
    
    if ([self.delegate respondsToSelector:@selector(tokenizedTextView:didTapTextRange:fraction:)]) {
        [self.delegate tokenizedTextView:self didTapTextRange:NSMakeRange(characterIndex, 1) fraction:fraction];
    }
}

- (void)copy:(id)sender
{
    NSString *stringToCopy = [self pasteboardStringFromRange:self.selectedRange];
    [super copy:sender];
    [[UIPasteboard generalPasteboard] setString:stringToCopy];
}

- (void)cut:(id)sender
{
    NSString *stringToCopy = [self pasteboardStringFromRange:self.selectedRange];
    [super cut:sender];
    [[UIPasteboard generalPasteboard] setString:stringToCopy];
    
    // To fix the iOS bug
    if ([self.delegate respondsToSelector:@selector(textViewDidChange:)]) {
        [self.delegate textViewDidChange:self];
    }
}

- (void)paste:(id)sender
{
    [super paste:sender];
    
    // To fix the iOS bug
    if ([self.delegate respondsToSelector:@selector(textViewDidChange:)]) {
        [self.delegate textViewDidChange:self];
    }
}

#pragma mark - Utils

- (NSString *)pasteboardStringFromRange:(NSRange)range
{
    // enumerate range of current text, resolving person attachents with user name.
    NSMutableString *string = [NSMutableString new];
    for (NSUInteger i = range.location; i < NSMaxRange(range); i++) {
        if ([self.attributedText.string characterAtIndex:i] == NSAttachmentCharacter) {
            TokenTextAttachment *tokenAttachemnt = [self.attributedText attribute:NSAttachmentAttributeName
                                                                          atIndex:i effectiveRange:NULL];
            if ([tokenAttachemnt isKindOfClass:[TokenTextAttachment class]]) {
                [string appendString:tokenAttachemnt.token.title];
                if (i < NSMaxRange(range) - 1) {
                    [string appendString:@", "];
                }
            }
        } else {
            [string appendString:[self.attributedText.string substringWithRange:NSMakeRange(i, 1)]];
        }
    }
    return string;
}

#pragma mark - UIGestureRecognizerDelegate

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    if (self.tapSelectionGestureRecognizer == gestureRecognizer || self.tapSelectionGestureRecognizer == otherGestureRecognizer) {
        return YES;
    }

    return YES;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch
{
    if (self.tapSelectionGestureRecognizer == gestureRecognizer) {
        return YES;
    }

    return YES;
}

@end
