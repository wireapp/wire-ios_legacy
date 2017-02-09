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


#import "Message+Formatting.h"

#import "WAZUIMagicIOS.h"
#import "zmessaging+iOS.h"
#import "LinkAttachment.h"
#import "NSString+EmoticonSubstitution.h"
#import "TSMarkdownParser+Wire.m"
#import "Settings.h"
#import "UIColor+WR_ColorScheme.h"
#import "NSString+Emoji.h"
#import "Wire-Swift.h"

@import WireExtensionComponents;
@import ZMCLinkPreview;

static NSMutableParagraphStyle *cellParagraphStyle;



@interface NSString (ZMTextMessageFormatting)

- (NSString *)trimmedCopy;

@end

@implementation NSString (ZMTextMessageFormatting)

- (NSString *)trimmedCopy
{
    return [self stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
}

@end

static TSMarkdownParser *WireMarkdownParser = nil;

static NSDataDetector *linkDataDetector(void);

static inline NSDataDetector *linkDataDetector(void)
{
    static NSDataDetector *detector;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSError *error;
        detector = [NSDataDetector dataDetectorWithTypes:NSTextCheckingTypeLink error:&error];
        
        if (error) {
            DDLogError(@"Couldn't create link data detector!!!");
        }
    });
    return detector;
}


@implementation NSAttributedString (FormatLinkAttachments)

+ (NSAttributedString *)formattedStringWithLinkAttachments:(NSArray <LinkAttachment *>*)linkAttachments
                                                forMessage:(id<ZMTextMessageData>)message
                                                   isGiphy:(BOOL)isGiphy
                                                obfuscated:(BOOL)obfuscated
{
    if (message.messageText.length == 0) {
        return [[NSAttributedString alloc] initWithString:@""];
    }
    
    NSString *text = message.messageText;
    LinkPreview *linkPreview = message.linkPreview;
    
    // Remove any trailing links which have a link preview, but not for old style embeds (SoundCloud, Vimeo, YouTube)
    BOOL containsEmbed = linkAttachments.firstObject.type != LinkAttachmentTypeNone;
    
    if (linkPreview != nil && text.length == linkPreview.characterOffsetInText + linkPreview.originalURLString.length && !containsEmbed && !isGiphy) {
        text = [text stringByReplacingOccurrencesOfString:message.linkPreview.originalURLString withString:@"" options:0 range:NSMakeRange(0, text.length)];
        linkAttachments = [linkAttachments filterWithBlock:^BOOL(LinkAttachment *linkAttachment) {
            return (NSInteger)linkAttachment.range.location != linkPreview.characterOffsetInText;
        }];
    }
    
    text = [text trimmedCopy];
    
    if (nil == cellParagraphStyle) {
        cellParagraphStyle = [[NSMutableParagraphStyle alloc] init];
        cellParagraphStyle.minimumLineHeight = [WAZUIMagic floatForIdentifier:@"content.line_height"] * [UIFont wr_preferredContentSizeMultiplierFor:[[UIApplication sharedApplication] preferredContentSizeCategory]];
    }

    UIFont *font;
    UIColor *foregroundColor;

    if (obfuscated) {
        font = [UIFont fontWithName:@"RedactedScript-Regular" size:18];
        foregroundColor = [UIColor wr_colorFromColorScheme:ColorSchemeColorAccent];
    } else {
        font = [UIFont fontWithMagicIdentifier:@"style.text.normal.font_spec"];
        foregroundColor = [UIColor wr_colorFromColorScheme:ColorSchemeColorTextForeground];
    }
    
    NSDictionary *attributes = @{
                                NSFontAttributeName : font,
                                NSForegroundColorAttributeName : foregroundColor,
                                NSParagraphStyleAttributeName : cellParagraphStyle,
                                NSBackgroundColorAttributeName : [UIColor wr_colorFromColorScheme:ColorSchemeColorTextBackground]
                                };
    
    NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:text attributes:attributes];

    if (obfuscated) {
        return attributedString;
    }

    [attributedString beginEditing];
    
    NSMutableArray *invalidLinkAttachments = [NSMutableArray array];
    for (LinkAttachment *linkAttachment in linkAttachments) {
        if (attributedString.length >= NSMaxRange(linkAttachment.range)) {
            [attributedString addAttribute:NSLinkAttributeName value:linkAttachment.URL range:linkAttachment.range];
        } else {
            // We can end up with invalid attachments if a link preview's characterOffsetInText doesn't
            // match up with the linkAttachment.range provided by the URL data detector.
            [invalidLinkAttachments addObject:linkAttachment];
        }
    }
    
    NSMutableArray *mutableLinkAttachments = linkAttachments.mutableCopy;
    [mutableLinkAttachments removeObjectsInArray:invalidLinkAttachments];
    linkAttachments = mutableLinkAttachments;
    
    // Emoticon substitution should not be performed on URLs.
    // 1. Get ranges with no URLs inside each range.
    NSMutableArray *nonURLRanges = [@[] mutableCopy];
    NSUInteger nextRangeBegining = 0;
    for (LinkAttachment *linkAttachment in linkAttachments) {
        NSRange URLRange = linkAttachment.range;
        NSRange emoticonRange = NSMakeRange(nextRangeBegining, URLRange.location - nextRangeBegining);
        if (emoticonRange.length > 0) {
            [nonURLRanges addObject:[NSValue valueWithRange:emoticonRange]];
        }
        nextRangeBegining = NSMaxRange(URLRange);
    }
    NSRange emoticonRange = NSMakeRange(nextRangeBegining, text.length - nextRangeBegining);
    if (emoticonRange.length > 0) {
        [nonURLRanges addObject:[NSValue valueWithRange:emoticonRange]];
    }
    
    // 2. Substitute emoticons on ranges.
    // reverse iteration keeps values in nonURLRanges actual while enumeration
    // (stringByResolvingEmoticonShortcuts changes length of string)
    for (NSValue *rangeValue in nonURLRanges.reverseObjectEnumerator) {
        [attributedString.mutableString resolveEmoticonShortcutsInRange:rangeValue.rangeValue];
    }
    
    [attributedString endEditing];
    
    
    NSAttributedString *markdownStr = nil;
    if ([[Settings sharedSettings] enableMarkdown]) {
        if (! WireMarkdownParser) {
            WireMarkdownParser = [TSMarkdownParser standardWireParserWithTextColor:[UIColor wr_colorFromColorScheme:ColorSchemeColorTextForeground]];
        }
        
        markdownStr = [WireMarkdownParser attributedStringFromAttributedMarkdownString:attributedString];
    }
    
    if ([attributedString.string wr_containsOnlyEmojiWithSpaces]) {
        [attributedString setAttributes:@{NSFontAttributeName: [UIFont systemFontOfSize:40]} range:NSMakeRange(0, attributedString.length)];
    }
    
    return (nil != markdownStr) ? markdownStr: [[NSAttributedString alloc] initWithAttributedString:attributedString];
}

+ (void)wr_flushCellParagraphStyleCache
{
    cellParagraphStyle = nil;
}

@end


@implementation Message (Formatting)

+ (void)invalidateTextColorConfiguration
{
    WireMarkdownParser = nil;
}

+ (NSArray *)linkAttachmentsForURLMatches:(NSArray *)matches
{
    if (matches == nil || matches.count == 0) {
        return nil;
    }
    
    NSMutableArray *linkAttributes = [NSMutableArray arrayWithCapacity:matches.count];
    
    for (NSTextCheckingResult *match in matches) {
        LinkAttachment *linkAttachment = [[LinkAttachment alloc] initWithURL:match.URL range:match.range];
        [linkAttributes addObject:linkAttachment];
    }
    
    return linkAttributes;
}

+ (NSArray<LinkAttachment *> *)linkAttachments:(id<ZMTextMessageData>)message
{
    NSDataDetector *detector = linkDataDetector();
    NSArray *contentURLs = nil;
    NSString *trimmedText = [message.messageText trimmedCopy];
    
    if (trimmedText.length > 0) {
        NSArray *matches = [detector matchesInString:trimmedText options:0 range:NSMakeRange(0, trimmedText.length)];
        contentURLs = [Message linkAttachmentsForURLMatches:matches];
    }
    
    return contentURLs;
}

@end
