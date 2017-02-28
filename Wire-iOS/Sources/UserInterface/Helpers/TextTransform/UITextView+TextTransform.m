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


#import "UITextView+TextTransform.h"
#import "ObjcAssociatedObjectHelpers.h"
@import Classy;



@implementation  UITextView (TextTransform)

+ (void)initialize
{
    if (self == [UITextView self]) {
        [UILabel class];
        // Add textTransform property to Classy
        CASObjectClassDescriptor *classDescriptor = [CASStyler.defaultStyler objectClassDescriptorForClass:self];
        
        // Set mapping for property key
        [classDescriptor setArgumentDescriptors:@[[CASArgumentDescriptor argWithValuesByName:TextTransformTable()]]
                                 forPropertyKey:@cas_propertykey(UITextView, textTransform)];
        
        // Add textAlignment property to Classy
        NSDictionary *textAlignmentMap = @{
                                           @"center"    : @(NSTextAlignmentCenter),
                                           @"left"      : @(NSTextAlignmentLeft),
                                           @"right"     : @(NSTextAlignmentRight),
                                           @"justified" : @(NSTextAlignmentJustified),
                                           @"natural"   : @(NSTextAlignmentNatural),
                                           };
        
        // Set mapping for property key
        [classDescriptor setArgumentDescriptors:@[[CASArgumentDescriptor argWithValuesByName:textAlignmentMap]]
                                 forPropertyKey:@cas_propertykey(UITextView, textAlignment)];

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
    });
}

SYNTHESIZE_ASC_PRIMITIVE_BLOCK(textTransform, setTextTransform, TextTransform, ^{ }, ^{ [self updateTextTransform:value]; });

- (void)updateTextTransform:(TextTransform)newTransform
{
    self.text = [self.text transformStringWithTransform:newTransform];
}

- (void)zf_setText:(NSString *)text
{
    text = [text transformStringWithTransform:self.textTransform];
    [self zf_setText:text];
}

@end
