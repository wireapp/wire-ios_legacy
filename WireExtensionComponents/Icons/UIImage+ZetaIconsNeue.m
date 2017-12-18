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


#import <WireExtensionComponents/WireExtensionComponents.h>

static CGFloat const ZetaIconDefaultSizes[] = {32, 16};


static NSParagraphStyle *cachedParagraphStyle;


@implementation UIImage (ZetaIconsNeue)

+ (UIImage *)imageForIcon:(ZetaIconType)icon iconSize:(ZetaIconSize)iconSize color:(UIColor *)color
{
    return [self imageForIcon:icon fontSize:[self sizeForZetaIconSize:iconSize] color:color];
}

+ (UIImage *)imageForIcon:(ZetaIconType)icon fontSize:(CGFloat)fontSize color:(UIColor *)color
{
    if (icon == ZetaIconTypeNone) {
        return nil;
    }

    return [self imageForPaintCodeIcon:icon fontSize:fontSize color:color];
}

+ (SEL)selectorForPaintCodeIcon:(ZetaIconType)iconType ofSize:(CGFloat)size
{
    NSString *iconNumberString = [NSString stringWithFormat:@"%03x", (unsigned int)iconType];
    
    NSString *selString = [NSString stringWithFormat:@"drawIcon_0x%@_%.0fptWithColor:", iconNumberString, size];

    return NSSelectorFromString(selString);
}

+ (SEL)selectorForMultiColorPaintCodeIcon:(ZetaIconType)iconType ofSize:(CGFloat)size
{
    NSString *iconNumberString = [NSString stringWithFormat:@"%03x", (unsigned int)iconType];
    
    NSString *selString = [NSString stringWithFormat:@"drawIcon_0x%@_%.0fptWithColor:darkenerColor:lightenerColor:", iconNumberString, size];
    
    return NSSelectorFromString(selString);
}

+ (UIImage *)imageForIcon:(ZetaIconType)iconType iconSize:(ZetaIconSize)iconSize color1:(UIColor *)color1 color2:(UIColor *)color2 color3:(UIColor *)color3
{
    CGFloat size = [self sizeForZetaIconSize:iconSize];
    SEL selector = [self selectorForMultiColorPaintCodeIcon:iconType ofSize:size];
    
    if (! [WireStyleKit respondsToSelector:selector]) {
        NSAssert(NO, @"Missing paint code icon for selector: %@", NSStringFromSelector(selector));
        return nil;
    }
    
    NSMethodSignature *signature = [WireStyleKit methodSignatureForSelector:selector];
    NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:signature];
    
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(size, size), NO, 0.0f);
    CGContextScaleCTM(UIGraphicsGetCurrentContext(), 0.5, 0.5);
    
    [invocation setSelector:selector];
    [invocation setArgument:&color1 atIndex:2];
    [invocation setArgument:&color2 atIndex:3];
    [invocation setArgument:&color3 atIndex:4];
    [invocation setTarget:WireStyleKit.class];
    [invocation invoke];
    
    UIImage *result = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return result;
}

+ (UIImage *)imageForPaintCodeIcon:(ZetaIconType)character fontSize:(CGFloat)fontSize color:(UIColor *)color
{
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(fontSize, fontSize), NO, 0.0f);
    CGContextRef context = UIGraphicsGetCurrentContext();

    SEL selector = [self selectorForPaintCodeIcon:character ofSize:fontSize];

    CGContextSaveGState(context);
    CGContextScaleCTM(context, 1.0f / 2.0f, 1.0f / 2.0f); // duplication because PaintCode size is in points
    
    if ([WireStyleKit respondsToSelector:selector]) {
        [WireStyleKit performSelector:selector withObject:color];
    }
    else {
        for (unsigned int i = 0; i < sizeof(ZetaIconDefaultSizes) / sizeof(int); i++) {
            BOOL hasDefaultSize = [WireStyleKit respondsToSelector:[self selectorForPaintCodeIcon:character
                                                                                           ofSize:ZetaIconDefaultSizes[i]]];
            if (hasDefaultSize) { // means it can be scaled
                CGContextSaveGState(context);

                CGContextScaleCTM(context, fontSize / (ZetaIconDefaultSizes[i]), fontSize / (ZetaIconDefaultSizes[i]));

                selector = [self selectorForPaintCodeIcon:character ofSize:ZetaIconDefaultSizes[i]];

                [WireStyleKit performSelector:selector withObject:color];

                CGContextRestoreGState(context);
                break;
            }
        }
    }

    CGContextRestoreGState(context);
    UIImage *result = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return result;
}

+ (CGFloat)sizeForZetaIconSize:(ZetaIconSize)iconSize
{
    CGFloat size = iconSize;
    switch (iconSize) {
        case ZetaIconSizeMessageStatus:
            size = 8.0;
            break;
        case ZetaIconSizeLike:
            size = 12;
            break;
        case ZetaIconSizeSearchBar:
            size = 14;
            break;
        case ZetaIconSizeTiny:
            size = 16;
            break;
            
        case ZetaIconSizeSmall:
            size = 20;
            break;
            
        case ZetaIconSizeMedium:
            size = 24;
            break;
            
        case ZetaIconSizeActionButton:
            size = 28;
            break;

        case ZetaIconSizeRegistrationButton:
            size = 32;
            break;

        case ZetaIconSizeLarge:
            size = 48;
            break;
            
        case ZetaIconSizeCamera:
            size = 40;
            break;

    }
    return size;
}

@end

@implementation UIImage (ZetaCustomIcons)

+ (UIImage *)imageForWordmarkWithColor:(UIColor *)color
{
    return [WireStyleKit imageOfWireWithColor:color];
}

+ (UIImage *)imageForLogoWithColor:(UIColor *)color
{
    return [self imageForLogoWithColor:color iconSize:ZetaIconSizeSmall];
}

+ (UIImage *)imageForLogoWithColor:(UIColor *)color iconSize:(ZetaIconSize)iconSize
{
    CGFloat logoSize = [self sizeForZetaIconSize:iconSize];
    
    UIImage *logoImage = [WireStyleKit imageOfLogoWithColor:color];
    CGSize originalSize = logoImage.size;
    CGSize targetSize = CGSizeMake(MIN(logoSize, logoSize * originalSize.width / originalSize.height),
                                   MIN(logoSize, logoSize * originalSize.height / originalSize.width));
    
    UIGraphicsBeginImageContextWithOptions(targetSize, NO, 0.0f);
    
    [logoImage drawInRect:CGRectMake(0, 0, targetSize.width, targetSize.height)];

    UIImage *result = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return result;
}

@end

