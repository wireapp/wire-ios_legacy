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

#import "TokenTextAttachment.h"
#import "Token.h"
#import "TokenField.h"

@implementation TokenSeparatorAttachment

- (instancetype)initWithToken:(Token *)token tokenField:(TokenField *)tokenField
{
    if (self = [super init]) {
        self.token = token;
        self.tokenField = tokenField;
        [self refreshImage];
    }
    return self;
}

- (void)refreshImage
{
    self.image = [self imageForCurrentToken];
}

- (UIImage *)imageForCurrentToken
{
    const CGFloat dotSize = 4.0f;
    const CGFloat dotSpacing = 8.0f;
    const CGFloat imageHeight = ceilf(self.tokenField.font.pointSize);
    
    CGSize imageSize = CGSizeMake(dotSize + dotSpacing * 2, imageHeight);
    
    const CGFloat delta = ceilf((self.tokenField.font.lineHeight - imageHeight) * 0.5f - self.tokenField.tokenTitleVerticalAdjustment);
    self.bounds = CGRectMake(0, delta, imageSize.width, imageSize.height);
    
    UIGraphicsBeginImageContextWithOptions(self.bounds.size, NO, 0.0);
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    CFRetain(context);
    
    CGContextSaveGState(context);
    
    CGContextSetFillColorWithColor(context, self.backgroundColor.CGColor);
    CGContextSetLineJoin(context, kCGLineJoinRound);
    CGContextSetLineWidth(context, 1);
    
    // draw dot
    UIBezierPath *dotPath = [UIBezierPath bezierPathWithOvalInRect:CGRectMake(dotSpacing,
                                                                              ceilf((imageSize.height + dotSize) / 2.0f),
                                                                              dotSize,
                                                                              dotSize)];
    
    CGContextSetFillColorWithColor(context, self.dotColor.CGColor);
    CGContextAddPath(context, dotPath.CGPath);
    CGContextFillPath(context);
    
    UIImage *i = UIGraphicsGetImageFromCurrentImageContext();
    
    CGContextRestoreGState(context);
    UIGraphicsEndImageContext();
    CFRelease(context);
    
    return i;
}

- (UIColor *)dotColor
{
    return self.tokenField.dotColor;
}

- (UIColor *)backgroundColor
{
    return self.tokenField.tokenBackgroundColor;
}

@end

@implementation TokenTextAttachment

- (instancetype)initWithToken:(Token *)token tokenField:(TokenField *)tokenField
{
    if (self = [super init]) {
        self.token = token;
        self.tokenField = tokenField;
        [self refreshImage];
    }
    return self;
}

- (void)setSelected:(BOOL)selected
{
    if (_selected == selected) {
        return;
    }
    _selected = selected;
    [self refreshImage];
}

- (void)refreshImage
{
    self.image = [self imageForCurrentToken];
}

- (UIImage *)imageForCurrentToken
{
    const CGFloat imageHeight = ceilf(self.tokenField.font.lineHeight);
    NSString *title = [self.token.title stringByApplyingTextTransform:self.tokenField.tokenTextTransform];
    CGFloat tokenMaxWidth = ceilf(self.token.maxTitleWidth - self.tokenField.tokenOffset - imageHeight);
    // Width cannot be smaller than height
    if (tokenMaxWidth < imageHeight) {
        tokenMaxWidth = imageHeight;
    }
    NSString *shortTitle = [self shortenedTextForText:title
                                       withAttributes:self.titleAttributes
                                        toFitMaxWidth:tokenMaxWidth];
    NSAttributedString *attributedName = [[NSAttributedString alloc] initWithString:shortTitle attributes:self.titleAttributes];
    
    CGSize size = attributedName.size;
    
    CGSize imageSize = size;
    imageSize.height = imageHeight;
    
    const CGFloat delta = ceilf((self.tokenField.font.capHeight - imageHeight) * 0.5f);
    self.bounds = CGRectMake(0, delta, imageSize.width, imageHeight);
    
    UIGraphicsBeginImageContextWithOptions(self.bounds.size, NO, 0.0);

    CGContextRef context = UIGraphicsGetCurrentContext();
    CFRetain(context);

    CGContextSaveGState(context);

    CGContextSetFillColorWithColor(context, self.backgroundColor.CGColor);
    CGContextSetStrokeColorWithColor(context, self.borderColor.CGColor);
    CGContextSetLineJoin(context, kCGLineJoinRound);
    CGContextSetLineWidth(context, 1);
    
    [attributedName drawAtPoint:CGPointMake(0, -delta + self.tokenField.tokenTitleVerticalAdjustment)];
    
    UIImage *i = UIGraphicsGetImageFromCurrentImageContext();
    
    CGContextRestoreGState(context);
    UIGraphicsEndImageContext();
    CFRelease(context);
    
    return i;
}

#pragma mark - String formatting

- (UIColor *)titleColor
{
    if (self.isSelected) {
        return self.tokenField.tokenSelectedTitleColor;
    } else {
        return self.tokenField.tokenTitleColor;
    }
}

- (UIColor *)backgroundColor
{
    if (self.isSelected) {
        return self.tokenField.tokenSelectedBackgroundColor;
    } else {
        return self.tokenField.tokenBackgroundColor;
    }
}

- (UIColor *)borderColor
{
    if (self.isSelected) {
        return self.tokenField.tokenSelectedBorderColor;
    } else {
        return self.tokenField.tokenBorderColor;
    }
}

- (UIColor *)dotColor
{
    return self.tokenField.dotColor;
}

- (NSDictionary *)titleAttributes
{
    return  @{
              NSFontAttributeName : self.tokenField.tokenTitleFont,
              NSForegroundColorAttributeName : self.titleColor,
              };
}

#pragma mark - String shortening

- (NSString *)appendixString
{
    return @"…";
}

- (NSString *)shortenedTextForText:(NSString *)text
                    withAttributes:(NSDictionary *)attributes
                     toFitMaxWidth:(CGFloat)maxWidth
{
    if ([self sizeForString:text attributes:attributes].width < maxWidth) {
        return text;
    } else {
        return [self searchForShortenedTextForText:text
                                    withAttributes:attributes
                                     toFitMaxWidth:maxWidth
                                           inRange:NSMakeRange(0, text.length)];
    }
}

// Search for longest substring, which render width is less than maxWidth
- (NSString *)searchForShortenedTextForText:(NSString *)text
                             withAttributes:(NSDictionary *)attributes
                              toFitMaxWidth:(CGFloat)maxWidth
                                    inRange:(NSRange)range
{
    // In other words, search for such number l, that
    // [title substringToIndex:l].width <= maxWidth,
    // and [title substringToIndex:l+1].width > maxWidth;
    
    // the longer substring is, the longer its width, so
    // we can use binary search here.
    NSUInteger shortedTextLength = range.location + range.length / 2;
    NSString *shortedText = [[text substringToIndex:shortedTextLength] stringByAppendingString:self.appendixString];
    NSString *shortedText1 = [[text substringToIndex:shortedTextLength + 1] stringByAppendingString:self.appendixString];
    
    CGSize shortedTextSize = [self sizeForString:shortedText attributes:attributes];
    CGSize shortedText1Size = [self sizeForString:shortedText1 attributes:attributes];
    if (shortedTextSize.width <= maxWidth &&
        shortedText1Size.width > maxWidth) {
        return shortedText;
    } else if (shortedText1Size.width <= maxWidth) {
        // Search in right range
        return [self searchForShortenedTextForText:text
                                    withAttributes:attributes
                                     toFitMaxWidth:maxWidth
                                           inRange:NSMakeRange(shortedTextLength, NSMaxRange(range) - shortedTextLength)];
    } else if (shortedTextSize.width > maxWidth) {
        // Search in left range
        return [self searchForShortenedTextForText:text
                                    withAttributes:attributes
                                     toFitMaxWidth:maxWidth
                                           inRange:NSMakeRange(range.location, shortedTextLength - range.location)];
    } else {
        return text;
    }
}

- (CGSize)sizeForString:(NSString *)string attributes:(NSDictionary *)attributes
{
    NSAttributedString *attributedString = [[NSAttributedString alloc] initWithString:string attributes:attributes];
    return attributedString.size;
}

#pragma mark - Description

- (NSString *)description
{
    return [NSString stringWithFormat:@"<%@: %p, name %@>", [self class], self, self.token.title, nil];
}

- (UIImage *)debugQuickLookObject
{
    return self.image;
}

@end
