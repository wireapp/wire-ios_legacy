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


#import "ZMDebugHelpers.h"

#if TARGET_OS_IPHONE
@import UIKit;
#else
@import AppKit;
#endif



@interface ZMQuickLookString ()

@property (nonatomic) NSMutableAttributedString *mutableText;
@property (nonatomic) NSDictionary *headerAttributes;
@property (nonatomic) NSDictionary *bodyAttributes;
@property (nonatomic) NSDictionary *labelAttributes;

@end




@implementation ZMQuickLookString

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.mutableText = [[NSMutableAttributedString alloc] init];
        [self setupAttributes];
    }
    return self;
}

#if TARGET_OS_IPHONE
- (void)setupAttributes;
{
    NSMutableParagraphStyle *paragraphStyle = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
    paragraphStyle.minimumLineHeight = 18;
    paragraphStyle.maximumLineHeight = paragraphStyle.minimumLineHeight;
    paragraphStyle.paragraphSpacingBefore = (CGFloat) (0.5 * paragraphStyle.minimumLineHeight);
    
    self.headerAttributes = @{
                              NSFontAttributeName: [UIFont boldSystemFontOfSize:13],
                              NSParagraphStyleAttributeName: paragraphStyle,
                              NSForegroundColorAttributeName: [UIColor blackColor],
                              };
    
    paragraphStyle = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
    paragraphStyle.minimumLineHeight = 13;
    paragraphStyle.maximumLineHeight = paragraphStyle.minimumLineHeight;
    
    self.bodyAttributes = @{
                            NSFontAttributeName: [UIFont systemFontOfSize:11],
                            NSParagraphStyleAttributeName: [paragraphStyle copy],
                            NSForegroundColorAttributeName: [UIColor blackColor],
                            };
    
    NSMutableDictionary *labelAttributes = [NSMutableDictionary dictionaryWithDictionary:self.bodyAttributes];
    labelAttributes[NSFontAttributeName] = [UIFont boldSystemFontOfSize:11];
    labelAttributes[NSForegroundColorAttributeName] = [UIColor darkGrayColor];
    
    CGFloat const columnWidth = 140;
    NSTextTab *t1 = [[NSTextTab alloc] initWithTextAlignment:NSTextAlignmentRight location:columnWidth options:@{}];
    NSTextTab *t2 = [[NSTextTab alloc] initWithTextAlignment:NSTextAlignmentLeft location:columnWidth + 4 options:@{}];
    paragraphStyle.tabStops = @[t1, t2];
    paragraphStyle.headIndent = columnWidth + 4;
    paragraphStyle.firstLineHeadIndent = 0;
    
    labelAttributes[NSParagraphStyleAttributeName] = [paragraphStyle copy];
    
    self.labelAttributes = labelAttributes;
}
#else
- (void)setupAttributes;
{
    NSMutableParagraphStyle *paragraphStyle = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
    paragraphStyle.minimumLineHeight = 18;
    paragraphStyle.maximumLineHeight = paragraphStyle.minimumLineHeight;
    paragraphStyle.paragraphSpacingBefore = 0.5 * paragraphStyle.minimumLineHeight;
    
    self.headerAttributes = @{
                              NSFontAttributeName: [NSFont boldSystemFontOfSize:13],
                              NSParagraphStyleAttributeName: paragraphStyle,
                              NSForegroundColorAttributeName: [NSColor blackColor],
                              };

    paragraphStyle = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
    paragraphStyle.minimumLineHeight = 13;
    paragraphStyle.maximumLineHeight = paragraphStyle.minimumLineHeight;
    
    self.bodyAttributes = @{
                            NSFontAttributeName: [NSFont systemFontOfSize:11],
                            NSParagraphStyleAttributeName: [paragraphStyle copy],
                            NSForegroundColorAttributeName: [NSColor blackColor],
                            };
    
    NSMutableDictionary *labelAttributes = [NSMutableDictionary dictionaryWithDictionary:self.bodyAttributes];
    labelAttributes[NSFontAttributeName] = [NSFont boldSystemFontOfSize:11];
    labelAttributes[NSForegroundColorAttributeName] = [NSColor darkGrayColor];
    
    CGFloat const columnWidth = 140;
    NSTextTab *t1 = [[NSTextTab alloc] initWithTextAlignment:NSRightTextAlignment location:columnWidth options:@{}];
    NSTextTab *t2 = [[NSTextTab alloc] initWithTextAlignment:NSLeftTextAlignment location:columnWidth + 4 options:@{}];
    paragraphStyle.tabStops = @[t1, t2];
    paragraphStyle.headIndent = columnWidth + 4;
    paragraphStyle.firstLineHeadIndent = 0;

    labelAttributes[NSParagraphStyleAttributeName] = [paragraphStyle copy];
    
    self.labelAttributes = labelAttributes;
}
#endif

- (void)appendString:(NSString *)text withFormat:(NSDictionary *)format;
{
    if (text != nil) {
        if (format != nil) {
            NSAttributedString *string = [[NSAttributedString alloc] initWithString:text attributes:format];
            [self.mutableText appendAttributedString:string];
        } else {
            [self.mutableText.mutableString appendString:text];
        }
    }
}

- (void)appendHeader:(NSString *)text;
{
    [self appendString:text withFormat:self.headerAttributes];
    [self appendString:@"\n" withFormat:nil];
}

- (void)appendBodyText:(NSString *)text;
{
    [self appendString:text withFormat:self.bodyAttributes];
    [self appendString:@"\n" withFormat:nil];
}

- (void)appendBodyTextWithFormat:(NSString *)format, ...
{
    va_list args;
    va_start(args, format);
    NSString *text = [[NSString alloc] initWithFormat:format arguments:args];
    va_end(args);
    [self appendBodyText:text];
}

- (void)appendLabel:(NSString *)label text:(NSString *)text;
{
    [self appendString:@"\t" withFormat:self.labelAttributes];
    [self appendString:label withFormat:self.labelAttributes];
    if (0 < label.length) {
        [self appendString:@":" withFormat:self.labelAttributes];
    }
    [self appendString:@"\t" withFormat:self.bodyAttributes];
    [self appendString:text withFormat:self.bodyAttributes];
    [self appendString:@"\n" withFormat:nil];
}

- (void)appendLabel:(NSString *)label textWithFormat:(NSString *)format, ...;
{
    va_list args;
    va_start(args, format);
    NSString *text = [[NSString alloc] initWithFormat:format arguments:args];
    va_end(args);
    [self appendLabel:label text:text];
}

- (NSAttributedString *)text;
{
    return [self.mutableText copy];
}

@end
