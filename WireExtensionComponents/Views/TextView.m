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
#import "Logging.h"

@import PureLayout;
#import "MediaAsset.h"
#import "UILabel+TextTransform.h"
#import <WireExtensionComponents/WireExtensionComponents-Swift.h>
@import Classy;

@interface TextView ()

@property (nonatomic) BOOL shouldDrawPlaceholder;
@property (nonatomic) UILabel *placeholderLabel;
@end

// Inspired by https://github.com/samsoffes/sstoolkit/blob/master/SSToolkit/SSTextView.m
// and by http://derpturkey.com/placeholder-in-uitextview/

@implementation TextView

+ (void)initialize
{
    if (self == [TextView class]) {
        // Add textTransform property to Classy
        CASObjectClassDescriptor *classDescriptor = [CASStyler.defaultStyler objectClassDescriptorForClass:self];
        
        // Set mapping for property key
        [classDescriptor setArgumentDescriptors:@[[CASArgumentDescriptor argWithValuesByName:TextTransformTable()]]
                                 forPropertyKey:@cas_propertykey(TextView, placeholderTextTransform)];
    }
}

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

#pragma mark Setup

- (void)setup
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(textChanged:) name:UITextViewTextDidChangeNotification object:self];
    self.placeholderTextColor = [UIColor lightGrayColor];
    self.placeholderTextContainerInset = self.textContainerInset;
    self.placeholderTextAlignment = NSTextAlignmentNatural;
    
    if ([AutomationHelper.sharedHelper disableAutocorrection]) {
        self.autocorrectionType = UITextAutocorrectionTypeNo;
    }
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)setPlaceholder:(NSString *)placeholder
{
    _placeholder = placeholder;
    self.placeholderLabel.text = placeholder;
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

- (void)drawRect:(CGRect)rect
{
    if(self.placeholder.length > 0) {
        if(self.placeholderLabel == nil) {
            
            float linePadding = self.textContainer.lineFragmentPadding;
            
            CGRect placeholderRect = CGRectMake(self.placeholderTextContainerInset.left + linePadding,
                                                self.placeholderTextContainerInset.top,
                                                rect.size.width - self.placeholderTextContainerInset.left - self.placeholderTextContainerInset.right - 2 * linePadding,
                                                rect.size.height - self.placeholderTextContainerInset.top - self.placeholderTextContainerInset.bottom);
            self.placeholderLabel = [[UILabel alloc] initWithFrame:placeholderRect];
            self.placeholderLabel.font = self.placeholderFont;
            self.placeholderLabel.textAlignment = self.textAlignment;
            self.placeholderLabel.textColor = self.placeholderTextColor;
            self.placeholderLabel.textTransform = self.placeholderTextTransform;
            self.placeholderLabel.textAlignment = self.placeholderTextAlignment;
            [self addSubview:self.placeholderLabel];
            
            self.placeholderLabel.text = self.placeholder;
            if (self.textAlignment == NSTextAlignmentLeft) {
                [self.placeholderLabel sizeToFit];
            }
            
        }
        [self showOrHidePlaceholder];
    }
    
    [super drawRect:rect];
}


#pragma mark - Copy/Pasting

- (void)paste:(id)sender
{
    UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
    DDLogDebug(@"types available: %@", [pasteboard pasteboardTypes]);

    if ([pasteboard containsPasteboardTypes:UIPasteboardTypeListImage] && [self.delegate respondsToSelector:@selector(textView:hasImageToPaste:)]) {
        id<MediaAsset> image = [[UIPasteboard generalPasteboard] mediaAsset];
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        [self.delegate performSelector:@selector(textView:hasImageToPaste:) withObject:self withObject:image];
#pragma clang diagnostic pop
    }
    else if ([pasteboard containsPasteboardTypes:UIPasteboardTypeListString]) {
        [super paste:sender];
    }
    else if ([pasteboard containsPasteboardTypes:UIPasteboardTypeListURL]) {
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
        return pasteboard.image || pasteboard.string;
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

@end
