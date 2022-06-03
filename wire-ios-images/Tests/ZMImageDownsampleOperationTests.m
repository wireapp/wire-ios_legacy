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


@import WireImages;
@import WireTesting;

#import "NSOperationQueue+Helpers.h"

static NSString const * TypeJPEG = @"image/jpeg";

@interface ZMImageDownsampleOperationTests : ZMTBaseTest
@end



@implementation ZMImageDownsampleOperationTests


- (ZMImageDownsampleOperation *)mediumImageDataForInputFileName:(NSString *)name extension:(NSString *)ext
{
    NSData *inputData = [self dataForResource:name extension:ext];
    return [self mediumImageDataForInputData:inputData];
}

- (ZMImageDownsampleOperation *)mediumImageDataForInputData:(NSData *)inputData
{
    return [self downsampleResultForInputData:inputData downsampleType:ZMImageDownsampleTypeMedium];
}

- (ZMImageDownsampleOperation *)previewImageDataForInputFileName:(NSString *)name extension:(NSString *)ext
{
    NSData *inputData = [self dataForResource:name extension:ext];
    return [self previewImageDataForInputData:inputData];
}

- (ZMImageDownsampleOperation *)previewImageDataForInputData:(NSData *)inputData
{
    return [self downsampleResultForInputData:inputData downsampleType:ZMImageDownsampleTypePreview];
}

- (ZMImageDownsampleOperation *)smallProfileImageDataForInputFileName:(NSString *)name extension:(NSString *)ext
{
    NSData *inputData = [self dataForResource:name extension:ext];
    return [self smallProfileImageDataForInputData:inputData];
}

- (ZMImageDownsampleOperation *)smallProfileImageDataForInputData:(NSData *)inputData
{
    return [self downsampleResultForInputData:inputData downsampleType:ZMImageDownsampleTypeSmallProfile];
}

- (ZMImageDownsampleOperation *)downsampleResultForInputData:(NSData *)inputData downsampleType:(ZMImageDownsampleType)downSampleType
{
    ZMImageLoadOperation *loadOperation = [[ZMImageLoadOperation alloc] initWithImageData:inputData];
    
    ZMImageDownsampleOperation *sut = [[ZMImageDownsampleOperation alloc] initWithLoadOperation:loadOperation downsampleType:downSampleType];
    
    NSOperationQueue *queue = [NSOperationQueue serialQueueWithName:self.name];
    
    [queue addOperation:loadOperation];
    [queue addOperation:sut];
    
    [queue waitUntilAllOperationsAreFinishedWithTimeout:2];
    return sut;
}

- (void)assertThatItReorientatesAnImageWithOrientation:(NSUInteger)orientation format:(ZMImageFormat)format
{
    XCTAssertTrue(orientation >= 0 && orientation <= 8, @"Invalid orientation, values from 0 to 8 are valid.");
    XCTAssertFalse(ZMImageFormatOriginal == format, @"Only Medium and Preview are supported");
    
    // given
    NSString *filename = @"unsplash_medium";
    if (1 < orientation) {
        filename = [filename stringByAppendingString:[NSString stringWithFormat:@"_exif_%lu", orientation]];
    }
    
    ZMImageDownsampleOperation *outputData;
    
    if (ZMImageFormatMedium == format) {
        outputData = [self mediumImageDataForInputFileName:filename extension:@"jpg"];
    } else {
        outputData = [self previewImageDataForInputFileName:filename extension:@"jpg"];
    }
    
    // then
    XCTAssertNotNil(outputData);
    NSString *expectedDataFilename = ZMImageFormatMedium == format ? @"unsplash_medium" : @"unsplash_preview";
    NSData *expectedData = [self dataForResource:expectedDataFilename extension:@"jpg"];
    
    AssertImageDataIsEqual(outputData.downsampleImageData, expectedData);
    XCTAssertEqual(outputData.format, format);
    XCTAssert(CGSizeEqualToSize(outputData.properties.size, [UIImage imageWithData:outputData.downsampleImageData].size));
}

@end



@implementation ZMImageDownsampleOperationTests (MediumImage)

- (void)testThatItGeneratesAMediumRepresentation
{
    // given
    ZMImageDownsampleOperation *outputData = [self mediumImageDataForInputFileName:@"unsplash_medium_exif_3" extension:@"jpg"];
    
    // then
    XCTAssertNotNil(outputData);
    XCTAssert(CGSizeEqualToSize(outputData.properties.size, [UIImage imageWithData:outputData.downsampleImageData].size));
}

- (void)testThatItDoesNotGeneratesAMediumRepresentationWhenCanceled
{
    // given
    NSData *invalidData = [NSData data];
    ZMImageDownsampleOperation *outputData = [self mediumImageDataForInputData:invalidData];
    
    // then
    XCTAssertNil(outputData.downsampleImageData);
}

- (void)testThatItDoesNotGeneratesAMediumRepresentationFromInvalidImage
{
    // given
    ZMImageDownsampleOperation *outputData = [self mediumImageDataForInputFileName:@"Lorem Ipsum" extension:@"txt"];
    
    // then
    XCTAssertNil(outputData.downsampleImageData);
}

- (void)testThatItScalesTheImage
{
    // Compression test case (1): Pixel dimensions too big
    
    // given
    ZMImageDownsampleOperation *outputData = [self mediumImageDataForInputFileName:@"unsplash_original" extension:@"jpg"];

    // then
    XCTAssertNotNil(outputData);
    NSData *expectedData = [self dataForResource:@"unsplash_original_medium" extension:@"jpg"];
    AssertImageDataIsEqual(outputData.downsampleImageData, expectedData);
    XCTAssertEqual(outputData.format, ZMImageFormatMedium);
    XCTAssertEqualObjects(outputData.properties.mimeType, TypeJPEG);
    XCTAssert(CGSizeEqualToSize(outputData.properties.size, [UIImage imageWithData:outputData.downsampleImageData].size));
}

- (void)testThatItUnrotatesAndScalesDownAnImageThatHasTooLargePixelDimensionsAndIsRotated
{
    // Compression test case (1): Pixel dimensions too big with rotated image
    
    // given
    ZMImageDownsampleOperation *outputData = [self mediumImageDataForInputFileName:@"unsplash_original_exif_6" extension:@"jpg"];
    
    // then
    XCTAssertNotNil(outputData);
    NSData *expectedData = [self dataForResource:@"unsplash_original_exif_6_medium" extension:@"jpg"];
    AssertImageDataIsEqual(outputData.downsampleImageData, expectedData);
    XCTAssertEqual(outputData.format, ZMImageFormatMedium);
    XCTAssert(CGSizeEqualToSize(outputData.properties.size, [UIImage imageWithData:outputData.downsampleImageData].size));

    
}

- (void)testMediumDownsamplePerformance;
{
    [self measureMetrics:[[self class] defaultPerformanceMetrics] automaticallyStartMeasuring:NO forBlock:^{
        @autoreleasepool {
            NSData *inputData = [self dataForResource:@"unsplash_original_exif_6" extension:@"jpg"];
            [self startMeasuring];
            ZMImageDownsampleOperation *outputData = [self mediumImageDataForInputData:inputData];
            [self stopMeasuring];
            (void) outputData;
        }
    }];
}

- (void)testThatItUnrotatesAnImage {
    // Compression test case (2): Pixel dimensions and byte OK, rotated

    // given
    ZMImageDownsampleOperation *outputData = [self mediumImageDataForInputFileName:@"unsplash_medium_exif_6_small" extension:@"jpg"];

    // then
    XCTAssertNotNil(outputData);
    NSData *expectedData = [self dataForResource:@"unsplash_medium_small" extension:@"jpg"];
    AssertImageDataIsEqual(outputData.downsampleImageData, expectedData);
    XCTAssertEqual(outputData.format, ZMImageFormatMedium);
    XCTAssert(CGSizeEqualToSize(outputData.properties.size, [UIImage imageWithData:outputData.downsampleImageData].size));

}

- (void)testThatItUsesTheOriginalDataWhenTheImageIsSufficientlySmallAndNotRotated
{
    // Compression test case (3): Pixel dimensions and byte OK, not rotated
    
    // given
    NSData *inputData = [self dataForResource:@"unsplash_medium_small" extension:@"jpg"];
    ZMImageDownsampleOperation *outputData = [self mediumImageDataForInputData:inputData];
    
    // then
    XCTAssertNotNil(outputData);
    AssertImageDataIsEqual(outputData.downsampleImageData, inputData);
    XCTAssertEqual(outputData.format, ZMImageFormatMedium);
    XCTAssert(CGSizeEqualToSize(outputData.properties.size, [UIImage imageWithData:outputData.downsampleImageData].size));
}


- (void)testThatItRecompressesAnImageThatHasSmallPixelDimensionsButFileSizeThatIsTooBigToJPEG
{
    // In this case, initial recompression doesn't help much, so that it finally compresses the image as jpeg

    // Compression test case (4): Pixel dimension OK, byte size too big,
    // -> recompressed in original format and still too big, recompressed as JPEG
    
    // given
    ZMImageDownsampleOperation *outputData = [self mediumImageDataForInputFileName:@"unsplash_owl_1_MB" extension:@"png"];
    
    // then
    XCTAssertNotNil(outputData);
    NSData *expectedData = [self dataForResource:@"unsplash_owl_medium" extension:@"jpg"];
    AssertImageDataIsEqual(outputData.downsampleImageData, expectedData);
    XCTAssertEqual(outputData.format, ZMImageFormatMedium);
    XCTAssert(CGSizeEqualToSize(outputData.properties.size, [UIImage imageWithData:outputData.downsampleImageData].size));
}


- (void)disable_testThatItUnrotatesAnImageThatIsRotatedAndHasSmallPixelDimensionsButTooBigFileSize
{
    // Compression test case (5): Pixel dimension OK, byte size too big,
    // -> recompressed in original format, rotated

    // given
    ZMImageDownsampleOperation *outputData = [self mediumImageDataForInputFileName:@"ceiling_rotated_1" extension:@"jpg"];

    // then
    XCTAssertNotNil(outputData);
    NSData *expectedData = [self dataForResource:@"ceiling_recompressed_unrotated" extension:@"jpg"];
    AssertImageDataIsEqual(outputData.downsampleImageData, expectedData);
    /*
     ((comp.propertiesDiffer) is false) failed - Value for "{GPS}" doesn't match ({
         Altitude = "40.96623376623376";
         AltitudeRef = 0;
         Latitude = "52.52363666666667";
         LatitudeRef = N;
         Longitude = "13.40256666666667";
         LongitudeRef = E;
     } != {
         Altitude = "40.96623376623376";
         AltitudeRef = 0;
         DateStamp = "2014:06:24";
         Latitude = "52.52363666666667";
         LatitudeRef = N;
         Longitude = "13.40256666666667";
         LongitudeRef = E;
         TimeStamp = "09:23:19";
     }).
     */
    XCTAssertEqual(outputData.format, ZMImageFormatMedium);
    XCTAssert(CGSizeEqualToSize(outputData.properties.size, [UIImage imageWithData:outputData.downsampleImageData].size));
}


// XXX WONTFIX IMAGES add test cases for case (6): Pixel dimension OK, byte size too big,
//          -> recompressed in original format and still too big,
//          -> recompress as JPEG and did not change that much, not rotated
// XXX WONTFIX IMAGES add test cases for case (7): Pixel dimension OK, byte size too big,
//          -> recompressed in original format and still too big,
//          -> recompress as JPEG and it helped

- (void)testThatItDoesNotCompressAnImageFurtherIfOriginalFormatCompressionIsGoodEnough
{
    // Compression test case (8): Pixel dimension OK, byte size too big,
    // ->recompressed in original and it did not change that much, not rotated
    
    // given
    NSData *inputData = [self dataForResource:@"unsplash_720_KB" extension:@"jpg"];
    ZMImageDownsampleOperation *outputData = [self mediumImageDataForInputData:inputData];
    
    // then
    XCTAssertNotNil(outputData);
    AssertImageDataIsEqual(inputData, outputData.downsampleImageData);
    XCTAssertEqual(outputData.format, ZMImageFormatMedium);
    XCTAssert(CGSizeEqualToSize(outputData.properties.size, [UIImage imageWithData:outputData.downsampleImageData].size));
}


- (void)testThatItUnrotatesAnImageThatIsIsSmallEnoughWhenRecompressedAsJPEG
{
    // Compression test case (9): Pixel dimensions OK, byte size too big,
    // ->recompressed in original format and it did not change that much, rotated
    
    // given
    ZMImageDownsampleOperation *outputData = [self mediumImageDataForInputFileName:@"unsplash_720_KB_rotated" extension:@"jpg"];
    
    // then
    XCTAssertNotNil(outputData);
    NSData *expectedData = [self dataForResource:@"unsplash_720_KB_unrotated" extension:@"jpg"];
    AssertImageDataIsEqual(outputData.downsampleImageData, expectedData);
    XCTAssertEqual(outputData.format, ZMImageFormatMedium);
    XCTAssert(CGSizeEqualToSize(outputData.properties.size, [UIImage imageWithData:outputData.downsampleImageData].size));
}

- (void)testThatItDoesNotChangeAnImageWithOrientation_1
{
    [self assertThatItReorientatesAnImageWithOrientation:1 format:ZMImageFormatMedium];
}

- (void)testThatItReorientatesAnImageWithOrientation_2
{
    [self assertThatItReorientatesAnImageWithOrientation:2 format:ZMImageFormatMedium];
}

- (void)testThatItReorientatesAnImageWithOrientation_3
{
    [self assertThatItReorientatesAnImageWithOrientation:3 format:ZMImageFormatMedium];
}

- (void)testThatItReorientatesAnImageWithOrientation_4
{
    [self assertThatItReorientatesAnImageWithOrientation:4 format:ZMImageFormatMedium];
}

- (void)testThatItReorientatesAnImageWithOrientation_5
{
    [self assertThatItReorientatesAnImageWithOrientation:5 format:ZMImageFormatMedium];
}

- (void)testThatItReorientatesAnImageWithOrientation_6
{
    [self assertThatItReorientatesAnImageWithOrientation:6 format:ZMImageFormatMedium];
}

- (void)testThatItReorientatesAnImageWithOrientation_7
{
    [self assertThatItReorientatesAnImageWithOrientation:7 format:ZMImageFormatMedium];
}

- (void)testThatItReorientatesAnImageWithOrientation_8
{
    [self assertThatItReorientatesAnImageWithOrientation:8 format:ZMImageFormatMedium];
}

- (void)testThatItReturnsTheOriginalImageDataForAGIFThatsFailyLarge;
{
    // given
    ZMImageDownsampleOperation *outputData = [self mediumImageDataForInputFileName:@"unsplash_big_gif" extension:@"gif"];
    
    // then
    XCTAssertNotNil(outputData);
    NSData *expectedData = [self dataForResource:@"unsplash_big_gif" extension:@"gif"];
    AssertEqualData(outputData.downsampleImageData, expectedData);
    XCTAssertEqual(outputData.format, ZMImageFormatMedium);
    XCTAssert(CGSizeEqualToSize(outputData.properties.size, [UIImage imageWithData:outputData.downsampleImageData].size));
}

@end



@implementation ZMImageDownsampleOperationTests (PreviewImage)

- (void)testThatItDoesNotGeneratesAPreviewRepresentationFromInvalidImage
{
    // given
    NSData *invalidData = [NSData data];
    ZMImageLoadOperation *loadOperation = [[ZMImageLoadOperation alloc] initWithImageData:invalidData];
    ZMImageDownsampleOperation *sut = [[ZMImageDownsampleOperation alloc] initWithLoadOperation:loadOperation downsampleType:ZMImageDownsampleTypePreview];
    
    // when
    NSOperationQueue *queue = [NSOperationQueue serialQueueWithName:self.name];
    [queue addOperation:loadOperation];
    [queue waitUntilAllOperationsAreFinishedWithTimeout:2];
    
    // then
    XCTAssertNil(sut.downsampleImageData);
}

- (void)testThatItGeneratesAPreviewRepresentation
{
    // given
    ZMImageDownsampleOperation *outputData = [self previewImageDataForInputFileName:@"unsplash_original" extension:@"jpg"];
    
    // then
    XCTAssertNotNil(outputData);
    XCTAssertEqual(outputData.format, ZMImageFormatPreview);
    XCTAssert(CGSizeEqualToSize(outputData.properties.size, [UIImage imageWithData:outputData.downsampleImageData].size));
}

- (void)testThatItDoesNotGeneratesAPreviewRepresentationWhenCanceled
{
    // given
    NSData *invalidData = [NSData data];
    ZMImageDownsampleOperation *outputData = [self previewImageDataForInputData:invalidData];
    
    // then
    XCTAssertNil(outputData.downsampleImageData);
    XCTAssertEqual(outputData.format, ZMImageFormatPreview);
    XCTAssert(CGSizeEqualToSize(outputData.properties.size, [UIImage imageWithData:outputData.downsampleImageData].size));
}

- (void)testThatItDoesNotGenerateAPreviewRepresentationFromInvalidImage
{
    // given
    ZMImageDownsampleOperation *outputData = [self previewImageDataForInputFileName:@"Lorem Ipsum" extension:@"txt"];
    
    // then
    XCTAssertNil(outputData.downsampleImageData);
    XCTAssertEqual(outputData.format, ZMImageFormatPreview);
}

- (void)testThatItScalesThePreviewImage
{
    // Compression test case (1): Pixel dimensions too big
    
    // given
    ZMImageDownsampleOperation *outputData = [self previewImageDataForInputFileName:@"unsplash_original" extension:@"jpg"];
    
    // then
    XCTAssertNotNil(outputData);
    NSData *expectedData = [self dataForResource:@"unsplash_preview" extension:@"jpg"];
    AssertImageDataIsEqual(outputData.downsampleImageData, expectedData);
    XCTAssertEqual(outputData.format, ZMImageFormatPreview);
    XCTAssert(CGSizeEqualToSize(outputData.properties.size, [UIImage imageWithData:outputData.downsampleImageData].size));
}

- (void)testThatItUnrotatesAndScalesDownAPreviewImageThatHasTooLargePixelDimensionsAndIsRotated
{
    // Compression test case (1): Pixel dimensions too big with rotated image
    
    // given
    ZMImageDownsampleOperation *outputData = [self previewImageDataForInputFileName:@"unsplash_original_exif_6" extension:@"jpg"];
    
    // then
    XCTAssertNotNil(outputData);
    NSData *expectedData = [self dataForResource:@"unsplash_preview" extension:@"jpg"];
    AssertImageDataIsEqual(outputData.downsampleImageData, expectedData);
    XCTAssertEqual(outputData.format, ZMImageFormatPreview);
    XCTAssert(CGSizeEqualToSize(outputData.properties.size, [UIImage imageWithData:outputData.downsampleImageData].size));
}

- (void)testThatItUnrotatesAPreviewImage
{
    // Compression test case (2): Pixel dimensions and byte OK, rotated
    
    // given
    ZMImageDownsampleOperation *outputData = [self previewImageDataForInputFileName:@"unsplash_medium_exif_6_small" extension:@"jpg"];
    
    // then
    XCTAssertNotNil(outputData);
    NSData *expectedData = [self dataForResource:@"unsplash_preview" extension:@"jpg"];
    AssertImageDataIsEqual(outputData.downsampleImageData, expectedData);
    XCTAssertEqual(outputData.format, ZMImageFormatPreview);
    XCTAssert(CGSizeEqualToSize(outputData.properties.size, [UIImage imageWithData:outputData.downsampleImageData].size));
}

- (void)testThatItUsesTheOriginalDataWhenThePreviewImageIsSufficientlySmallAndNotRotated
{
    // Compression test case (3): Pixel dimensions and byte OK, not rotated
    
    // given
    NSData *inputData = [self dataForResource:@"unsplash_preview" extension:@"jpg"];
    ZMImageDownsampleOperation *outputData = [self previewImageDataForInputData:inputData];
    
    // then
    XCTAssertNotNil(outputData);
    AssertImageDataIsEqual(outputData.downsampleImageData, inputData);
    XCTAssertEqual(outputData.format, ZMImageFormatPreview);
    XCTAssert(CGSizeEqualToSize(outputData.properties.size, [UIImage imageWithData:outputData.downsampleImageData].size));
}

- (void)testThatItRecompressesAPreviewImageThatHasSmallPixelDimensionsButFileSizeThatIsTooBigToJPEG
{
    // In this case, initial recompression doesn't help much, so that it finally compresses the image as jpeg
    
    // Compression test case (4): Pixel dimension OK, byte size too big,
    // -> recompressed in original format and still too big, recompressed as JPEG
    
    // given
    ZMImageDownsampleOperation *outputData = [self previewImageDataForInputFileName:@"unsplash_owl_1_MB" extension:@"png"];
    
    // then
    XCTAssertNotNil(outputData);
    NSData *expectedData = [self dataForResource:@"unsplash_owl_small" extension:@"jpg"];
    AssertImageDataIsEqual(outputData.downsampleImageData, expectedData);
    XCTAssertEqual(outputData.format, ZMImageFormatPreview);
    XCTAssert(CGSizeEqualToSize(outputData.properties.size, [UIImage imageWithData:outputData.downsampleImageData].size));
}

- (void)testThatItUnrotatesAPreviewImageThatIsRotatedAndHasSmallPixelDimensionsButTooBigFileSize
{
    // Compression test case (5): Pixel dimension OK, byte size too big,
    // -> recompressed in original format, rotated
    
    // given
    ZMImageDownsampleOperation *outputData = [self previewImageDataForInputFileName:@"ceiling_rotated_1" extension:@"jpg"];
    
    // then
    XCTAssertNotNil(outputData);
    NSData *expectedData = [self dataForResource:@"ceiling_recompressed_unrotated_preview" extension:@"jpg"];
    AssertImageDataIsEqual(outputData.downsampleImageData, expectedData);
    XCTAssertEqual(outputData.format, ZMImageFormatPreview);
    XCTAssert(CGSizeEqualToSize(outputData.properties.size, [UIImage imageWithData:outputData.downsampleImageData].size));
}

// XXX WONTFIX IMAGES add test cases for case (6): Pixel dimension OK, byte size too big,
//          -> recompressed in original format and still too big,
//          -> recompress as JPEG and did not change that much, not rotated
// XXX WONTFIX IMAGES add test cases for case (7): Pixel dimension OK, byte size too big,
//          -> recompressed in original format and still too big,
//          -> recompress as JPEG and it helped

// XXX WONTFIX IMAGES find a fitting image for this test case
//- (void)testThatItDoesNotCompressAPreviewImageFurtherIfOriginalFormatCompressionIsGoodEnough
//{
//    // Compression test case (8): Pixel dimension OK, byte size too big,
//    // ->recompressed in original and it did not change that much, not rotated
//
//    // given
//    NSData *inputData = [self dataForResource:@"Church_900KB" extension:@"jpg"];
//    NSData *outputData = [self previewImageDataForInputData:inputData];
//    
//    // then
//    XCTAssertNotNil(outputData);
//    AssertImageDataIsEqual(inputData, outputData);
//}

- (void)testThatItUnrotatesAPreviewImageThatIsIsSmallEnoughWhenRecompressedAsJPEG
{
    // Compression test case (9): Pixel dimensions OK, byte size too big,
    // ->recompressed in original format and it did not change that much, rotated
    
    // given
    ZMImageDownsampleOperation *outputData = [self previewImageDataForInputFileName:@"unsplash_720_KB_rotated" extension:@"jpg"];
    
    // then
    XCTAssertNotNil(outputData);
    NSData *expectedData = [self dataForResource:@"unsplash_720_KB_preview" extension:@"jpg"];
    AssertImageDataIsEqual(outputData.downsampleImageData, expectedData);
    XCTAssertEqual(outputData.format, ZMImageFormatPreview);
    XCTAssert(CGSizeEqualToSize(outputData.properties.size, [UIImage imageWithData:outputData.downsampleImageData].size));
}

- (void)testThatItDoesNotChangeAPreviewImageWithOrientation_1
{
    [self assertThatItReorientatesAnImageWithOrientation:1 format:ZMImageFormatPreview];
}

- (void)testThatItReorientatesAPreviewImageWithOrientation_2
{
    [self assertThatItReorientatesAnImageWithOrientation:2 format:ZMImageFormatPreview];
}

- (void)testThatItReorientatesAPreviewImageWithOrientation_3
{
    [self assertThatItReorientatesAnImageWithOrientation:3 format:ZMImageFormatPreview];
}

- (void)testThatItReorientatesAPreviewImageWithOrientation_4
{
    [self assertThatItReorientatesAnImageWithOrientation:4 format:ZMImageFormatPreview];
}

- (void)testThatItReorientatesAPreviewImageWithOrientation_5
{
    [self assertThatItReorientatesAnImageWithOrientation:5 format:ZMImageFormatPreview];
}

- (void)testThatItReorientatesAPreviewImageWithOrientation_6
{
    [self assertThatItReorientatesAnImageWithOrientation:6 format:ZMImageFormatPreview];
}

- (void)testThatItReorientatesAPreviewImageWithOrientation_7
{
    [self assertThatItReorientatesAnImageWithOrientation:7 format:ZMImageFormatPreview];
}

- (void)testThatItReorientatesAPreviewImageWithOrientation_8
{
    [self assertThatItReorientatesAnImageWithOrientation:8 format:ZMImageFormatPreview];
}

@end



@implementation ZMImageDownsampleOperationTests (SmallProfile)

- (void)testThatItDoesNotGeneratesASmallProfileRepresentationFromInvalidImage
{
    // given
    NSData *invalidData = [NSData data];
    ZMImageLoadOperation *loadOperation = [[ZMImageLoadOperation alloc] initWithImageData:invalidData];
    ZMImageDownsampleOperation *sut = [[ZMImageDownsampleOperation alloc] initWithLoadOperation:loadOperation downsampleType:ZMImageDownsampleTypeSmallProfile];
    
    // when
    NSOperationQueue *queue = [NSOperationQueue serialQueueWithName:self.name];
    [queue addOperation:loadOperation];
    [queue waitUntilAllOperationsAreFinishedWithTimeout:2];
    
    // then
    XCTAssertNil(sut.downsampleImageData);
}

- (void)testThatItGeneratesASmallProfileRepresentationALandscapeImage
{
    // given
    ZMImageDownsampleOperation *outputData = [self smallProfileImageDataForInputFileName:@"unsplash_original" extension:@"jpg"];

    // then
    XCTAssertNotNil(outputData);
    NSData *expectedData = [self dataForResource:@"unsplash_small_profile" extension:@"jpg"];
    AssertImageDataIsEqual(outputData.downsampleImageData, expectedData);
    XCTAssertEqual(outputData.format, ZMImageFormatProfile);
    XCTAssert(CGSizeEqualToSize(outputData.properties.size, [UIImage imageWithData:outputData.downsampleImageData].size));
}

- (void)testThatItGeneratesASmallProfileRepresentationFromAPortraitImage
{
    // given
    ZMImageDownsampleOperation *outputData = [self smallProfileImageDataForInputFileName:@"unsplash_portrait" extension:@"jpg"];
    
    // then
    XCTAssertNotNil(outputData);
    NSData *expectedData = [self dataForResource:@"unsplash_portrait_small_profile" extension:@"jpg"];
    AssertImageDataIsEqual(outputData.downsampleImageData, expectedData);
    XCTAssertEqual(outputData.format, ZMImageFormatProfile);
    XCTAssert(CGSizeEqualToSize(outputData.properties.size, [UIImage imageWithData:outputData.downsampleImageData].size));
}

- (void)testThatItGeneratesASmallProfileRepresentationFromATinyImage
{
    // given
    ZMImageDownsampleOperation *outputData = [self smallProfileImageDataForInputFileName:@"unsplash_preview" extension:@"jpg"];
    
    // then
    XCTAssertNotNil(outputData);
    NSData *expectedData = [self dataForResource:@"unsplash_preview_small_profile" extension:@"jpg"];
    AssertImageDataIsEqual(outputData.downsampleImageData, expectedData);
    XCTAssertEqual(outputData.format, ZMImageFormatProfile);
    XCTAssert(CGSizeEqualToSize(outputData.properties.size, [UIImage imageWithData:outputData.downsampleImageData].size));
}

@end
