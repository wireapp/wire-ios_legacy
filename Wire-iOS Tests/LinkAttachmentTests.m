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
#import <XCTest/XCTest.h>

#import "LinkAttachment.h"


@interface LinkAttachmentTests : XCTestCase

@end

@implementation LinkAttachmentTests

- (void)testThatUnknownLinksAreNotAssignedAnAttachment
{
    // Given
    NSString *link = @"http://www.example.com";
    NSRange range = NSMakeRange(0, link.length);

    // When
    LinkAttachment *linkAttachment = [[LinkAttachment alloc] initWithURL:[NSURL URLWithString:link] range:range string:link];

    // Then
    XCTAssertEqual(linkAttachment.type, LinkAttachmentTypeNone);
}

- (void)testThatYoutubeMatcherRecognizesNormalYoutubeLinks
{
    // Given
    NSString *link = @"https://www.youtube.com/watch?v=example";
    NSRange range = NSMakeRange(0, link.length);
    
    // When
    LinkAttachment *linkAttachment = [[LinkAttachment alloc] initWithURL:[NSURL URLWithString:link] range:range string:link];
    
    // Then
    XCTAssertEqual(linkAttachment.type, LinkAttachmentTypeYoutubeVideo);
}

- (void)testThatYoutubeMatcherRecognizesMobileYoutubeLinks
{
    // Given
    NSString *link = @"https://m.youtube.com/watch?v=example";
    NSRange range = NSMakeRange(0, link.length);

    // When
    LinkAttachment *linkAttachment = [[LinkAttachment alloc] initWithURL:[NSURL URLWithString:link] range:range string:link];
    
    // Then
    XCTAssertEqual(linkAttachment.type, LinkAttachmentTypeYoutubeVideo);
}

- (void)testThatYoutubeMatcherRecognizesShortYoutubeLinks
{
    // Given
    NSString *link = @"https://youtu.be/example";
    NSRange range = NSMakeRange(0, link.length);
    
    // When
    LinkAttachment *linkAttachment = [[LinkAttachment alloc] initWithURL:[NSURL URLWithString:link] range:range string:link];
    
    // Then
    XCTAssertEqual(linkAttachment.type, LinkAttachmentTypeYoutubeVideo);
}

- (void)testThatYoutubeMatcherRecognizesNonSecureYoutubeLinks
{
    // Given
    NSString *link = @"http://youtube.com/watch?v=example";
    NSRange range = NSMakeRange(0, link.length);
    
    // When
    LinkAttachment *linkAttachment = [[LinkAttachment alloc] initWithURL:[NSURL URLWithString:link] range:range string:link];
    
    // Then
    XCTAssertEqual(linkAttachment.type, LinkAttachmentTypeYoutubeVideo);
}

#pragma mark - Vimeo

- (void)testThatItDoesNotMatchVimeoLinks
{
    // Given
    NSString *link = @"https://vimeo.com/1234567890";
    NSRange range = NSMakeRange(0, link.length);
    
    // When
    LinkAttachment *linkAttachment = [[LinkAttachment alloc] initWithURL:[NSURL URLWithString:link] range:range string:link];
    
    // Then
    XCTAssertEqual(linkAttachment.type, LinkAttachmentTypeNone);
}

#pragma mark - Soundcloud Track

- (void)testThatSoundcloudLinkWithUnknownSubdomainDoesntGetRecognizedAsTrackOrSet
{
    // Given
    NSString *link = @"https://blog.soundcloud.com/example/example";
    NSRange range = NSMakeRange(0, link.length);
    
    // When
    LinkAttachment *linkAttachment = [[LinkAttachment alloc] initWithURL:[NSURL URLWithString:link] range:range string:link];
    
    // Then
    XCTAssertEqual(linkAttachment.type, LinkAttachmentTypeNone);
}

- (void)testThatRegularSoundcloudTrackLinkIsRecognized
{
    // Given
    NSString *link = @"https://soundcloud.com/example/example";
    NSRange range = NSMakeRange(0, link.length);
    
    // When
    LinkAttachment *linkAttachment = [[LinkAttachment alloc] initWithURL:[NSURL URLWithString:link] range:range string:link];
    
    // Then
    XCTAssertEqual(linkAttachment.type, LinkAttachmentTypeSoundcloudTrack);
}

- (void)testThatMobileSoundcloudTrackLinkIsRecognized
{
    // Given
    NSString *link = @"https://m.soundcloud.com/example/example";
    NSRange range = NSMakeRange(0, link.length);
    
    // When
    LinkAttachment *linkAttachment = [[LinkAttachment alloc] initWithURL:[NSURL URLWithString:link] range:range string:link];
    
    // Then
    XCTAssertEqual(linkAttachment.type, LinkAttachmentTypeSoundcloudTrack);
}

#pragma mark - Soundcloud Set

- (void)testThatSoundCloudSetMatcherRecognizesNormalLinks
{
    // Given
    NSString *link = @"https://soundcloud.com/example/sets/example";
    NSRange range = NSMakeRange(0, link.length);
    
    // When
    LinkAttachment *linkAttachment = [[LinkAttachment alloc] initWithURL:[NSURL URLWithString:link] range:range string:link];
    
    // Then
    XCTAssertEqual(linkAttachment.type, LinkAttachmentTypeSoundcloudSet);
}

@end
