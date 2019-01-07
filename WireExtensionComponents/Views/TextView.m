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


@import MobileCoreServices;

#import "TextView.h"
#import "TextView+Internal.h"

#import "MediaAsset.h"
#import <WireExtensionComponents/WireExtensionComponents-Swift.h>
#import "Wire-Swift.h"

static NSString* ZMLogTag ZM_UNUSED = @"UI";

@interface TextView ()

@property (nonatomic) BOOL shouldDrawPlaceholder;
@end

// Inspired by https://github.com/samsoffes/sstoolkit/blob/master/SSToolkit/SSTextView.m
// and by http://derpturkey.com/placeholder-in-uitextview/

@implementation TextView

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self setup];
    }
    return self;
}


- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self setup];
    }
    return self;
}

- (id)initWithFrame:(CGRect)frame textContainer:(NSTextContainer *)textContainer
{
    self = [super initWithFrame:frame textContainer:textContainer];
    if (self) {
        [self setup];
    }
    return self;
}

#pragma mark Setup

- (void)setup
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(textChanged:) name:UITextViewTextDidChangeNotification object:self];
    self.placeholderTextColor = [UIColor lightGrayColor];
    self._placeholderTextContainerInset = self.textContainerInset;
    self.placeholderTextAlignment = NSTextAlignmentNatural;

    [self createPlaceholderLabel];

    if ([AutomationHelper.sharedHelper disableAutocorrection]) {
        self.autocorrectionType = UITextAutocorrectionTypeNo;
    }
}

- (void)setPlaceholder:(NSString *)placeholder
{
    _placeholder = placeholder;
    self.placeholderLabel.text = placeholder;
    [self.placeholderLabel sizeToFit];
    [self showOrHidePlaceholder];
}

- (void)setAttributedPlaceholder:(NSAttributedString *)attributedPlaceholder {
    NSMutableAttributedString *mutableCopy = attributedPlaceholder.mutableCopy;
    [mutableCopy addAttribute:NSForegroundColorAttributeName value:_placeholderTextColor range:NSMakeRange(0, mutableCopy.length)];
    _attributedPlaceholder = mutableCopy;
    self.placeholderLabel.attributedText = mutableCopy;
    [self.placeholderLabel sizeToFit];
    [self showOrHidePlaceholder];
}

- (void)setPlaceholderTextAlignment:(NSTextAlignment)placeholderTextAlignment
{
    _placeholderTextAlignment = placeholderTextAlignment;
    self.placeholderLabel.textAlignment = placeholderTextAlignment;
}

- (void)setPlaceholderTextColor:(UIColor *)placeholderTextColor
{
    _placeholderTextColor = placeholderTextColor;
    self.placeholderLabel.textColor = placeholderTextColor;
}

- (void)setText:(NSString *)text
{
    [super setText:text];
    [self showOrHidePlaceholder];
}

- (void)setAttributedText:(NSAttributedString *)attributedText
{
    [super setAttributedText:attributedText];
    [self showOrHidePlaceholder];
}

- (void)setPlaceholderFont:(UIFont *)placeholderFont
{
    _placeholderFont = placeholderFont;
    self.placeholderLabel.font = self.placeholderFont;
}

- (void)setPlaceholderTextTransform:(TextTransform)placeholderTextTransform
{
    _placeholderTextTransform = placeholderTextTransform;
    self.placeholderLabel.textTransform = self.placeholderTextTransform;
}

- (void)textChanged:(NSNotification *)note
{
    [self showOrHidePlaceholder];
}

- (void)setLineFragmentPadding:(CGFloat)lineFragmentPadding
{
    _lineFragmentPadding = lineFragmentPadding;
    self.textContainer.lineFragmentPadding = lineFragmentPadding;
}

- (void)showOrHidePlaceholder
{
    if(self.text.length == 0)
        [self.placeholderLabel setAlpha:1.0];
    else
        [self.placeholderLabel setAlpha:0];
}

#pragma mark - Copy/Pasting

- (void)paste:(id)sender
{
    UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
    ZMLogDebug(@"types available: %@", [pasteboard pasteboardTypes]);

    if ((pasteboard.hasImages)
        && [self.delegate respondsToSelector:@selector(textView:hasImageToPaste:)]) {
        id<MediaAsset> image = [[UIPasteboard generalPasteboard] mediaAsset];
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        [self.delegate performSelector:@selector(textView:hasImageToPaste:) withObject:self withObject:image];
#pragma clang diagnostic pop
    }
    else if (pasteboard.hasStrings) {
        [super paste:sender];
    }
    else if (pasteboard.hasURLs) {
        if (pasteboard.string.length != 0) {
            [super paste:sender];
        }
        else if (pasteboard.URL != nil) {
            [super paste:sender];
        }
    }
}

- (BOOL)canPerformAction:(SEL)action withSender:(id)sender
{
    if (action == @selector(paste:)) {
        UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
        return pasteboard.hasImages || pasteboard.hasStrings;
    }

    return [super canPerformAction:action withSender:sender];
}

- (BOOL)resignFirstResponder
{
    BOOL resigned = [super resignFirstResponder];
    if ([self.delegate respondsToSelector:@selector(textView:firstResponderChanged:)]) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        [self.delegate performSelector:@selector(textView:firstResponderChanged:) withObject:self withObject:@(resigned)];
#pragma clang diagnostic pop
    }
    return resigned;
}

#pragma mark Language

- (UITextInputMode *) textInputMode {
    return [self overriddenTextInputMode];
}

@end
