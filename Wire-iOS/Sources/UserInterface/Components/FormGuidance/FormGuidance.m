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


#import "FormGuidance.h"

#import "Guidance.h"
#import "WAZUIMagicIOS.h"
#import "UIColor+WAZExtensions.h"
#import "Wire-Swift.h"



@implementation FormGuidance

+ (instancetype)formGuidanceWithGuidance:(Guidance *)guidance
{
    FormGuidance *formGuidance = [[self alloc] initWithGuidance:guidance];

    return formGuidance;
}

- (instancetype)init
{
    self = [self initWithGuidance:nil];
    if (self) {

    }

    return self;
}

- (instancetype)initWithGuidance:(Guidance *)guidance
{
    self = [super init];
    if (self) {
        [self setupStyles];
        self.guidance = guidance;
    }

    return self;
}

- (void)setBounds:(CGRect)bounds
{
    if (self.bounds.size.width != bounds.size.width) {
        [self invalidateIntrinsicContentSize];
    }
    [super setBounds:bounds];
}

- (void)setFrame:(CGRect)frame
{
    if (self.frame.size.width != frame.size.width) {
        [self invalidateIntrinsicContentSize];
    }
    [super setFrame:frame];
}

- (void)didMoveToSuperview
{
    [super didMoveToSuperview];
}

- (CGSize)intrinsicContentSize
{
    CGSize size = [self contentSizeWhenGuidanceIsSet];

    if (self.guidance) {
        return size;
    }
    else {
        return (CGSize) {size.width, 0};
    }
}

- (CGSize)contentSizeWhenGuidanceIsSet
{
    [self.titleLabel sizeToFit];
    
    CGSize targetSize = self.titleLabel.frame.size;

    CGSize intrinsicSize = (CGSize) {UIViewNoIntrinsicMetric, targetSize.height};

    return intrinsicSize;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
        
    self.titleLabel.frame = self.bounds;
}

- (void)setupStyles
{
    self.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;

    self.titleLabel.font = [UIFont fontWithMagicIdentifier:@"style.text.small.font_spec_bold"];
    self.titleLabel.numberOfLines = 0;
    self.titleLabel.textAlignment = NSTextAlignmentLeft;
}

- (void)setContentVerticalAlignment:(UIControlContentVerticalAlignment)contentVerticalAlignment
{
    [super setContentVerticalAlignment:contentVerticalAlignment];
}

- (void)setContentPadding:(CGFloat)contentPadding
{
    _contentPadding = contentPadding;
    [self invalidateIntrinsicContentSize];
}

- (void)setGuidance:(Guidance *)guidance
{
    if (guidance == _guidance) {
        return;
    }

    _guidance = guidance;

    if (_guidance) {
        NSString *textString;
        NSMutableAttributedString *attributedTitle;

        UIColor *titleColor = [UIColor whiteColor];
        UIColor *explanationColor = [UIColor colorWithWhite:1.0 alpha:0.48];

        if (guidance.title && guidance.explanation) {

            textString = [NSString stringWithFormat:@"%@\n%@", guidance.title, guidance.explanation];
            NSRange titleRange = [textString rangeOfString:guidance.title];
            NSRange explanationRange = [textString rangeOfString:guidance.explanation];
            attributedTitle = [[NSMutableAttributedString alloc] initWithString:[textString uppercasedWithCurrentLocale]];

            [attributedTitle addAttribute:NSForegroundColorAttributeName value:titleColor range:titleRange];
            [attributedTitle addAttribute:NSForegroundColorAttributeName value:explanationColor range:explanationRange];

            [self setAttributedTitle:[[NSAttributedString alloc] initWithAttributedString:attributedTitle] forState:UIControlStateNormal];
        }
        else if (guidance.title || guidance.explanation) {
            NSString *guidanceText = guidance.title != nil ? guidance.title : guidance.explanation;
            UIColor *color = guidance.title != nil ? titleColor : explanationColor;
            NSRange range = NSMakeRange(0, guidanceText.length);
            attributedTitle = [[NSMutableAttributedString alloc] initWithString:guidanceText];

            [attributedTitle addAttribute:NSForegroundColorAttributeName value:color range:range];
            [self setAttributedTitle:[[NSAttributedString alloc] initWithAttributedString:attributedTitle] forState:UIControlStateNormal];
        }

        [self setContentCompressionResistancePriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisVertical];
    }
    else {
        [self setContentCompressionResistancePriority:UILayoutPriorityDefaultHigh forAxis:UILayoutConstraintAxisVertical];
    }
    
    [self invalidateIntrinsicContentSize];
    [self setNeedsLayout];
}

@end
