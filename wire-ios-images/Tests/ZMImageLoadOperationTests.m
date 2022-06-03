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


@import ImageIO;

#if TARGET_OS_IPHONE
@import MobileCoreServices;
#endif

@import WireImages;
@import WireTesting;



@interface ZMImageLoadOperationTests : ZMTBaseTest
@end



@implementation ZMImageLoadOperationTests

- (void)testThatItLoadsJPEGData;
{
    // given
    NSData *imageData = [self dataForResource:@"unsplash_medium_exif_2" extension:@"jpg"];
    ZMImageLoadOperation *sut = [[ZMImageLoadOperation alloc] initWithImageData:imageData];
    
    // when
    [sut start];
    XCTAssert([self waitOnMainLoopUntilBlock:^BOOL{
        return [sut isFinished];
    } timeout:1]);
    
    // then
    XCTAssertNotNil(sut);
    XCTAssertNotEqual(sut.CGImage, NULL);
    XCTAssertEqualObjects(sut.sourceImageProperties[(__bridge id) kCGImagePropertyTIFFDictionary][(__bridge id) kCGImagePropertyTIFFOrientation], @2);
    XCTAssertEqualObjects(sut.sourceImageProperties[(__bridge id) kCGImagePropertyOrientation], @2);
    XCTAssertEqualObjects(sut.sourceImageProperties[(__bridge id) kCGImagePropertyPixelHeight], @346);
    XCTAssertEqualObjects(sut.sourceImageProperties[(__bridge id) kCGImagePropertyPixelWidth], @531);
    AssertEqualData(sut.originalImageData, imageData);
    XCTAssertEqualObjects(sut.computedImageProperties.mimeType, (__bridge id)kUTTypeJPEG);
    XCTAssertEqual(sut.tiffOrientation, 2);
    AssertEqualSizes(sut.computedImageProperties.size, CGSizeMake(531, 346));
}

- (void)testThatItDoesNotLoadWhenCancelled
{
    // given
    NSData *imageData = [self dataForResource:@"unsplash_medium" extension:@"jpg"];
    XCTAssertNotNil(imageData);
    ZMImageLoadOperation *sut = [[ZMImageLoadOperation alloc] initWithImageData:imageData];
    [sut cancel];
    
    // when
    [sut start];
    XCTAssert([self waitOnMainLoopUntilBlock:^BOOL{
        return [sut isFinished];
    } timeout:1]);
    
    // then
    XCTAssertNotNil(sut);
    XCTAssertEqual(sut.CGImage, NULL);
    XCTAssertNil(sut.sourceImageProperties);
}

- (void)testThatItDoesNotCrashOnInvalidData
{
    // given
    NSData *imageData = [self dataForResource:@"Lorem Ipsum" extension:@"txt"];
    ZMImageLoadOperation *sut = [[ZMImageLoadOperation alloc] initWithImageData:imageData];
    
    // when
    [sut start];
    XCTAssert([self waitOnMainLoopUntilBlock:^BOOL{
        return [sut isFinished];
    } timeout:1]);
    
    // then
}

@end
