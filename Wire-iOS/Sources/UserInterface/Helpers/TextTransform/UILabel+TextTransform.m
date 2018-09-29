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


#import "UILabel+TextTransform.h"
#import "ObjcAssociatedObjectHelpers.h"
#import <WireExtensionComponents/WireExtensionComponents-Swift.h>


@implementation UILabel (TextTransform)

+ (void)initialize
{
    if (UIApplication.runningInExtension) {
        return;
    }
    
    // swizzle setText: to keep text transformed when it changes.
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        Class class = [self class];
        
        SEL originalSelector = @selector(setText:);
        SEL swizzledSelector = @selector(zf_setText:);
        
        Method originalMethod = class_getInstanceMethod(class, originalSelector);
        Method swizzledMethod = class_getInstanceMethod(class, swizzledSelector);
        
        BOOL didAddMethod =
        class_addMethod(class,
                        originalSelector,
                        method_getImplementation(swizzledMethod),
                        method_getTypeEncoding(swizzledMethod));
        
        if (didAddMethod) {
            class_replaceMethod(class,
                                swizzledSelector,
                                method_getImplementation(originalMethod),
                                method_getTypeEncoding(originalMethod));
        } else {
            method_exchangeImplementations(originalMethod, swizzledMethod);
        }
        
        
        originalSelector = @selector(setAttributedText:);
        swizzledSelector = @selector(zf_setAttributedText:);
        
        originalMethod = class_getInstanceMethod(class, originalSelector);
        swizzledMethod = class_getInstanceMethod(class, swizzledSelector);
        
        didAddMethod = class_addMethod(class,
                                       originalSelector,
                                       method_getImplementation(swizzledMethod),
                                       method_getTypeEncoding(swizzledMethod));
        if (didAddMethod) {
            class_replaceMethod(class,
                                swizzledSelector,
                                method_getImplementation(originalMethod),
                                method_getTypeEncoding(originalMethod));
        } else {
            method_exchangeImplementations(originalMethod, swizzledMethod);
        }
    });
}

SYNTHESIZE_ASC_PRIMITIVE_BLOCK(textTransform, setTextTransform, TextTransform, ^{ }, ^{ [self updateTextTransform:value]; });

- (void)updateTextTransform:(TextTransform)newTransform
{
    if (self.attributedText != nil) {
        self.attributedText = [self transformAttributedString:self.attributedText
                                                withTransform:newTransform];
    } else {
        self.text = [self.text transformStringWithTransform:newTransform];
    }
}

- (void)zf_setText:(NSString *)text
{
    text = [text transformStringWithTransform:self.textTransform];
    [self zf_setText:text];
}

- (void)zf_setAttributedText:(NSAttributedString *)attributedText
{
    NSAttributedString *transformedAttributedText = [self transformAttributedString:attributedText
                                                                      withTransform:self.textTransform];
    [self zf_setAttributedText:transformedAttributedText];
}

- (NSAttributedString *)transformAttributedString:(NSAttributedString *)attributedString withTransform:(TextTransform)textTransform
{
    if (attributedString == nil) {
        return nil;
    }
    NSString *transformedText = [attributedString.string transformStringWithTransform:textTransform];
    NSMutableAttributedString *transformedAttributedString = [[NSMutableAttributedString alloc] initWithString:transformedText];
    
    [attributedString enumerateAttributesInRange:NSMakeRange(0, attributedString.length) options:0 usingBlock:^(NSDictionary<NSString *,id> * _Nonnull attrs, NSRange range, BOOL * _Nonnull stop) {
        [transformedAttributedString setAttributes:attrs range:range];
    }];
    
    return [[NSAttributedString alloc] initWithAttributedString:transformedAttributedString];
}

@end
