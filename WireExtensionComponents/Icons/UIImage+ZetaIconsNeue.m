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
#import <WireExtensionComponents/WireExtensionComponents-Swift.h>

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
    switch (iconSize) {
        case ZetaIconSizeMessageStatus:
            return 8.0;
        case ZetaIconSizeLike:
            return 12;
        case ZetaIconSizeSearchBar:
            return 14;
        case ZetaIconSizeTiny:
            return 16;
        case ZetaIconSizeSmall:
            return 20;
        case ZetaIconSizeMedium:
            return 24;
        case ZetaIconSizeActionButton:
            return 28;
        case ZetaIconSizeRegistrationButton:
            return 32;
        case ZetaIconSizeLarge:
            return 48;
        case ZetaIconSizeCamera:
            return 40;
        case ZetaIconSizeCameraKeyboardButton:
            return 36;
    }
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
    return [self resizedImageForImage:[WireStyleKit imageOfLogoWithColor:color] iconSize:iconSize];
}

+ (UIImage *)imageForRestoreWithColor:(UIColor *)color iconSize:(ZetaIconSize)iconSize
{
    return [self resizedImageForImage:[WireStyleKit imageOfRestoreWithColor:color] iconSize:iconSize];
}

+ (UIImage *)resizedImageForImage:(UIImage *)image iconSize:(ZetaIconSize)iconSize
{
    CGFloat size = [self sizeForZetaIconSize:iconSize];
    
    CGSize originalSize = image.size;
    CGSize targetSize = CGSizeMake(MIN(size, size * originalSize.width / originalSize.height),
                                   MIN(size, size * originalSize.height / originalSize.width));
    
    UIGraphicsBeginImageContextWithOptions(targetSize, NO, 0.0f);
    
    [image drawInRect:CGRectMake(0, 0, targetSize.width, targetSize.height)];
    
    UIImage *result = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return result;
}

@end

