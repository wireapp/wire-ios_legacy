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


#import <UIKit/UIKit.h>
#import "StyledTextField.h"
#import "UIView+Borders.h"
#import "NSAttributedString+Wire.h"
#import "Wire-Swift.h"




@interface StyledTextField ()

@property(nonatomic) CGFloat originalFontSize;

@end



@implementation StyledTextField {

}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self setup];
        self.placeholder = self.placeholder; // Make sure we go through the custom setter
    }
    return self;
}

- (id)init
{
    self = [super init];
    if (self) {
        [self setup];
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)setup
{
    self.textColor = [UIColor whiteColor];
    self.font = UIFont.normalLightFont;
    self.translatesAutoresizingMaskIntoConstraints = NO;
    self.originalFontSize = -1;

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(textFieldTextChanged:) name:UITextFieldTextDidChangeNotification object:self];

    self.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
}

- (void)setPlaceholder:(NSString *)placeholder
{
    [self setAttributedPlaceholder:[self attributedPlaceholderString:placeholder]];
}

- (void)setGuidanceType:(GuidanceType)guidanceType
{
    _guidanceType = guidanceType;
    UIColor *requiredColor = [UIColor colorWithRed:0.811 green:0.243 blue:0.235 alpha:1];
    UIColor *optionalColor = [UIColor colorWithRed:0.996 green:0.823 blue:0.019 alpha:1];
    UIColor *dotColor = guidanceType == GuidanceTypeInfo ? optionalColor : requiredColor;

    CGFloat dotDiameter = 10;

    UIView *dotView = [[UIView alloc] initWithFrame:(CGRect) {CGPointZero, {dotDiameter, dotDiameter}}];
    dotView.backgroundColor = dotColor;
    dotView.layer.cornerRadius = dotDiameter / 2.0;

    [UIView performWithoutAnimation:^{
        if (guidanceType == GuidanceTypeNone) {
            self.rightView = nil;
        }
        if (guidanceType == GuidanceTypeInfo || guidanceType == GuidanceTypeError) {
            self.rightView = dotView;
        }
        [self layoutIfNeeded];
    }];
}

- (void)layoutSubviews
{
    [super layoutSubviews];

    self.rightView.frame = (CGRect) {{self.rightView.frame.origin.x - self.textInset.right, self.rightView.frame.origin.y}, self.rightView.frame.size};
}

- (void)setRightView:(UIView *)rightView
{
    super.rightView = rightView;
}

- (void)textFieldTextChanged:(NSNotification *)notification
{
    CGFloat requiredFontSize = self.requiredFontSize - 1;
    if (self.font.pointSize != requiredFontSize) {
        self.font = [self.font fontWithSize:requiredFontSize];
    }
}

- (CGSize)intrinsicContentSize
{
    if (self.hidden || self.alpha == 0) {
        return CGSizeZero;
    }

    return [super intrinsicContentSize];
}

- (CGFloat)requiredFontSize
{
    const CGRect textBounds = [self textRectForBounds:self.bounds];
    const CGFloat maxWidth = textBounds.size.width;

    if (_originalFontSize == -1) {_originalFontSize = self.font.pointSize;}

    UIFont *font = self.font;
    CGFloat fontSize = _originalFontSize;

    do {
        if (font.pointSize != fontSize) {
            font = [font fontWithSize:fontSize];
        }

        CGSize size = [self.text sizeWithAttributes:@{NSFontAttributeName : font}];
        if (size.width < maxWidth) {
            break;
        }

        fontSize -= 1.0;
        if (fontSize < self.minimumFontSize) {
            break;
        }

    } while (TRUE);

    return (fontSize);
}

- (NSAttributedString *)attributedPlaceholderString:(NSString *)placeholder
{
    if (placeholder == nil) {return nil;}

    NSAttributedString *attributedPlaceholder = [placeholder attributedStringWithAttributes:@{
            NSForegroundColorAttributeName : [UIColor colorWithWhite:1 alpha:0.4],
            NSFontAttributeName : UIFont.normalLightFont
    }];
    return attributedPlaceholder;
}

#pragma mark - Text inset

// placeholder position
- (CGRect)textRectForBounds:(CGRect)bounds
{
    CGRect rect = [super textRectForBounds:bounds];
    return UIEdgeInsetsInsetRect(rect, self.textInset);
}

- (CGRect)editingRectForBounds:(CGRect)bounds
{
    CGRect rect = [super editingRectForBounds:bounds];

    return UIEdgeInsetsInsetRect(rect, self.textInset);
}

@end
