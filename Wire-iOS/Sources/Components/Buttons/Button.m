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

@import WireExtensionComponents;

#import "Button.h"

// helpers
#import "UIColor+Mixing.h"

#import "UIControl+Wire.h"
#import "UIImage+ImageUtilities.h"
#import "Wire-Swift.h"

@import QuartzCore;

@interface Button ()

@property (nonatomic) NSMutableDictionary *originalTitles;
@property (nonatomic, readonly) NSMutableDictionary *borderColorByState;

@end



@implementation Button

+ (instancetype)buttonWithStyle:(ButtonStyle)style
{
    return [[Button alloc] initWithStyle:style];
}

+ (instancetype)buttonWithStyle:(ButtonStyle)style variant:(ColorSchemeVariant)variant
{
    return [[Button alloc] initWithStyle:style variant:variant];
}

- (instancetype)initWithStyle:(ButtonStyle)style
{
    return [self initWithStyle:style variant:ColorScheme.defaultColorScheme.variant];
}

- (instancetype)initWithStyle:(ButtonStyle)style variant:(ColorSchemeVariant)variant
{
    self = [self init];
    
    self.textTransform = TextTransformUpper;
    self.titleLabel.font = UIFont.smallLightFont;
    self.layer.cornerRadius = 4;
    self.contentEdgeInsets = UIEdgeInsetsMake(4, 16, 4, 16);
    
    switch (style) {
        case ButtonStyleFull:
            [self setBackgroundImageColor:UIColor.accentColor forState:UIControlStateNormal];
            [self setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
            [self setTitleColor:[UIColor wr_colorFromColorScheme:ColorSchemeColorTextDimmed variant:variant] forState:UIControlStateHighlighted];
            break;
        case ButtonStyleFullMonochrome:
            [self setBackgroundImageColor:UIColor.whiteColor forState:UIControlStateNormal];
            [self setTitleColor:[UIColor wr_colorFromColorScheme:ColorSchemeColorTextForeground variant:ColorSchemeVariantLight] forState:UIControlStateNormal];
            [self setTitleColor:[UIColor wr_colorFromColorScheme:ColorSchemeColorTextDimmed variant:ColorSchemeVariantLight] forState:UIControlStateHighlighted];
            break;
        case ButtonStyleEmpty:
            self.layer.borderWidth = 1;
            
            [self setTitleColor:[UIColor buttonEmptyTextWithVariant:variant] forState:UIControlStateNormal];
            [self setTitleColor:[UIColor wr_colorFromColorScheme:ColorSchemeColorTextDimmed variant:variant] forState:UIControlStateHighlighted];
            [self setTitleColor:[UIColor wr_colorFromColorScheme:ColorSchemeColorTextDimmed variant:variant] forState:UIControlStateDisabled];
            
            [self setBorderColor:UIColor.accentColor forState:UIControlStateNormal];
            [self setBorderColor:UIColor.accentDarken forState:UIControlStateHighlighted];
            [self setBorderColor:[UIColor wr_colorFromColorScheme:ColorSchemeColorTextDimmed  variant:variant] forState:UIControlStateDisabled];
            break;
        case ButtonStyleEmptyMonochrome:
            self.layer.borderWidth = 1;
            
            [self setBackgroundImageColor:UIColor.clearColor forState:UIControlStateNormal];
            [self setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
            [self setTitleColor:[UIColor wr_colorFromColorScheme:ColorSchemeColorTextDimmed variant:ColorSchemeVariantLight] forState:UIControlStateHighlighted];
            
            [self setBorderColor:[UIColor colorWithWhite:1.0 alpha:0.32] forState:UIControlStateNormal];
            [self setBorderColor:[UIColor colorWithWhite:1.0 alpha:0.16] forState:UIControlStateHighlighted];
            break;
    }
    
    return self;
}

- (instancetype)init
{
    self = [super init];
    
    if (self) {
        _borderColorByState = [NSMutableDictionary dictionary];
        _originalTitles = [[NSMutableDictionary alloc] init];
        self.clipsToBounds = YES;
    }
    
    return self;
}

- (CGSize)intrinsicContentSize
{
    CGSize s = [super intrinsicContentSize];
    
    return CGSizeMake(s.width + self.titleEdgeInsets.left + self.titleEdgeInsets.right,
                      s.height + self.titleEdgeInsets.top + self.titleEdgeInsets.bottom);
}

- (void)setBounds:(CGRect)bounds
{
    [super setBounds:bounds];
    
    [self updateCornerRadius];
}

- (void)setBackgroundImageColor:(UIColor *)color forState:(UIControlState)state
{
    [self setBackgroundImage:[UIImage singlePixelImageWithColor:color] forState:state];
}

- (void)setTitle:(NSString *)title forState:(UIControlState)state
{
    [self expandState:state block:^(UIControlState state) {
        if (title) {
            [self.originalTitles setObject:title forKey:@(state)];
        } else {
            [self.originalTitles removeObjectForKey:@(state)];
        }
    }];
    
    if (self.textTransform != TextTransformNone) {
        title = [title stringByApplyingTextTransform:self.textTransform];
    }

    [super setTitle:title forState:state];
}

- (void)setBorderColor:(UIColor *)color forState:(UIControlState)state
{
    [self expandState:state block:^(UIControlState state) {
        if (color) {
            [self.borderColorByState setObject:[color copy] forKey:@(state)];
        }
    }];
    
    [self updateBorderColor];
}

- (UIColor *)borderColorForState:(UIControlState)state
{
    UIColor *borderColor = self.self.borderColorByState[@(state)];
    
    if (borderColor == nil) {
        borderColor = self.borderColorByState[@(UIControlStateNormal)];
    }
    
    return borderColor;
}

- (void)updateBorderColor
{
    self.layer.borderColor = [self borderColorForState:self.state].CGColor;
}

- (void)setTextTransform:(TextTransform)textTransform
{
    _textTransform = textTransform;
    
    [self.originalTitles enumerateKeysAndObjectsUsingBlock:^(NSNumber *state, NSString *title, BOOL *stop) {
        [self setTitle:title forState:state.unsignedIntegerValue];
    }];
}

- (void)setCircular:(BOOL)circular
{
    _circular = circular;
    
    if (circular) {
        self.layer.masksToBounds = YES;
        [self updateCornerRadius];
    } else {
        self.layer.masksToBounds = NO;
        self.layer.cornerRadius = 0;
    }
}

- (void)updateCornerRadius
{
    if (self.circular) {
        self.layer.cornerRadius = self.bounds.size.height / 2;
    }
}

#pragma mark - Observing state

- (void)setHighlighted:(BOOL)highlighted
{
    UIControlState previousState = self.state;
    [super setHighlighted:highlighted];
    [self updateAppearanceWithPreviousState:previousState];
}

- (void)setSelected:(BOOL)selected
{
    UIControlState previousState = self.state;
    [super setSelected:selected];
    [self updateAppearanceWithPreviousState:previousState];
}

- (void)setEnabled:(BOOL)enabled
{
    UIControlState previousState = self.state;
    [super setEnabled:enabled];
    [self updateAppearanceWithPreviousState:previousState];
}

- (void)updateAppearanceWithPreviousState:(UIControlState)previousState
{
    if (self.state == previousState) {
        return;
    }
    
    // Update for new state (selected, highlighted, disabled) here if needed
    [self updateBorderColor];
}


@end
