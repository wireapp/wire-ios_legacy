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


@import WireTransport;
@import WireUtilities;
@import WireTesting;

#import "MockPicture.h"
#import "MockAsset.h"

#if TARGET_OS_IPHONE
@import ImageIO;
@import MobileCoreServices;
#else
@import ApplicationServices;
@import CoreServices;
#endif

#import <WireMockTransport/WireMockTransport-Swift.h>

@implementation MockPicture

- (void)setAsSmallProfileFromImageData:(NSData *)imageData forUser:(MockUser *)user;
{
    self.identifier = [NSUUID createUUID].transportString;
    self.contentLength = (int16_t) imageData.length;
    CGImageSourceRef source = CGImageSourceCreateWithData((__bridge CFDataRef) imageData, NULL);
    Require(source != NULL);
    NSString *type = CFBridgingRelease(CGImageSourceGetType(source));
    self.contentType = [UTIHelper convertToMimeWithUti:type];
    NSDictionary *properties =  CFBridgingRelease(CGImageSourceCopyPropertiesAtIndex(source, 0, NULL));
    self.info = @{
                  @"width" : properties[(__bridge id) kCGImagePropertyPixelWidth],
                  @"height" : properties[(__bridge id) kCGImagePropertyPixelHeight],
                  @"tag" : @"smallProfile",
                  @"original_width" : @600,
                  @"correlation_id" : [NSUUID createUUID].transportString,
                  @"original_height" : @774,
                  @"nonce" : self.identifier,
                  @"public" : @true
                  };
    self.identifier = [NSUUID createUUID].transportString;
    CFRelease(source);
    
    MockAsset *asset = [MockAsset insertIntoManagedObjectContext:self.managedObjectContext];
    asset.data = imageData;
    asset.identifier = self.identifier;
    asset.conversation = user.identifier;
    
}

- (void)setAsMediumWithSmallProfile:(MockPicture *)smallProfile forUser:(MockUser *)user imageData:(NSData *)imageData;
{
    self.contentLength = (int16_t) 44092;
    self.contentType = @"image/jpeg";
    self.identifier = [NSUUID createUUID].transportString;
    NSMutableDictionary *info = [NSMutableDictionary dictionaryWithDictionary:smallProfile.info];
    info[@"width"] = @960;
    info[@"height"] = @1280;
    info[@"nonce"] = [NSUUID createUUID].transportString;
    info[@"tag"] = @"medium";
    self.info = info;
    
    MockAsset *asset = [MockAsset insertIntoManagedObjectContext:self.managedObjectContext];
    asset.data = imageData;
    asset.identifier = self.identifier;
    asset.conversation = user.identifier;
}

@dynamic contentLength;
@dynamic contentType;
@dynamic identifier;
@dynamic info;

- (id<ZMTransportData>)transportData;
{
    return @{
             @"content_length": @(self.contentLength),
             @"content_type": self.contentType,
             @"id": self.identifier,
             @"info": self.info,
             @"data": @"",
             };
}

@end
