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


#import "UIImagePickerController+GetImage.h"

#import <AssetsLibrary/AssetsLibrary.h>
#import <MobileCoreServices/MobileCoreServices.h>

#import "NSError+Zeta.h"
@import FLAnimatedImage;

UIImageOrientation ImageOrientationFromAssetOrientation(ALAssetOrientation orientation);

UIImageOrientation ImageOrientationFromAssetOrientation(ALAssetOrientation orientation)
{
    switch (orientation) {
        case ALAssetOrientationUp:
            return UIImageOrientationUp;
            break;
        case ALAssetOrientationDown:
            return UIImageOrientationDown;
            break;
        case ALAssetOrientationLeft:
            return UIImageOrientationLeft;
            break;
        case ALAssetOrientationRight:
            return UIImageOrientationRight;
            break;
        case ALAssetOrientationUpMirrored:
            return UIImageOrientationUpMirrored;
            break;
        case ALAssetOrientationDownMirrored:
            return UIImageOrientationDownMirrored;
            break;
        case ALAssetOrientationLeftMirrored:
            return UIImageOrientationLeftMirrored;
            break;
        case ALAssetOrientationRightMirrored:
            return UIImageOrientationRightMirrored;
            break;
        default:
            break;
    }
}

@implementation UIImagePickerController (GetImage)

+ (void)loadImageFromMediaInfo:(NSDictionary *)info result:(void(^)(UIImage*,NSData*,NSString*))callback failure:(void(^)(NSError*))failure
{
    NSString *mediaType = info[UIImagePickerControllerMediaType];
    DDLogDebug(@"mediaType chosen %@", mediaType);

    ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];

    [library assetForURL:[info objectForKey:UIImagePickerControllerReferenceURL]
             resultBlock:^(ALAsset *asset) {
                 // NB: sometimes it returns asset == nil

                 NSData *imageData = nil;
                 UIImage *image = nil;

                 if (asset != nil) {
                     ALAssetRepresentation *representation = [asset defaultRepresentation];

                     uint8_t *buffer = (uint8_t *) malloc((unsigned long) representation.size);
                     unsigned long buffered = [representation getBytes:buffer fromOffset:0.0 length:(NSUInteger)representation.size error:nil];
                     imageData = [NSData dataWithBytesNoCopy:buffer length:buffered freeWhenDone:YES];
                     image = [UIImage imageWithCGImage:[representation fullResolutionImage]
                                                 scale:[representation scale]
                                           orientation:ImageOrientationFromAssetOrientation([representation orientation])];
                 }
                 else {
                     image = info[UIImagePickerControllerEditedImage];

                     if (image == nil) {
                         image = info[UIImagePickerControllerOriginalImage];
                     }
                 }

                 if (image == nil && imageData != nil) {
                     image = [UIImage imageWithData:imageData];
                 }
                 else if (image != nil && imageData == nil) {
                     imageData = UIImageJPEGRepresentation(image, 0.9f);
                 }

                 if (image != nil && imageData != nil) {
                     callback(image, imageData, mediaType);
                 }
                 else {
                     failure([NSError errorWithDomain:ZetaErrorDomain code:0 userInfo:@{NSLocalizedDescriptionKey: @"Cannot pick image"}]);
                 }
             }
            failureBlock:^(NSError *error) {
                failure(error);
            }];
}

+ (void)imageDataFromMediaInfo:(NSDictionary *)info resultBlock:(void (^)(NSData *imageData))resultBlock
{
    if (info[UIImagePickerControllerReferenceURL]) {
        ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
        
        [library assetForURL:info[UIImagePickerControllerReferenceURL]
                 resultBlock:^(ALAsset *asset) {
                     if (asset != nil) {
                         ALAssetRepresentation *representation = [asset defaultRepresentation];
                         
                         uint8_t *buffer = (uint8_t *) malloc((unsigned long) representation.size);
                         unsigned long buffered = [representation getBytes:buffer fromOffset:0.0 length:(NSUInteger)representation.size error:nil];
                         resultBlock([NSData dataWithBytesNoCopy:buffer length:buffered freeWhenDone:YES]);
                     }
                     else {
                         if (info[UIImagePickerControllerEditedImage] != nil) {
                             resultBlock(UIImageJPEGRepresentation(info[UIImagePickerControllerEditedImage], 0.9f));
                         }
                         else if (info[UIImagePickerControllerOriginalImage] != nil) {
                             resultBlock(UIImageJPEGRepresentation(info[UIImagePickerControllerOriginalImage], 0.9f));
                         }
                         else {
                             resultBlock(nil);
                         }
                     }
                 } failureBlock:^(NSError *error) {
                     resultBlock(nil);
                 }];
    }
    else if (info[UIImagePickerControllerEditedImage]) {
        resultBlock(UIImageJPEGRepresentation(info[UIImagePickerControllerEditedImage], 0.9));
    }
    else if (info[UIImagePickerControllerOriginalImage]) {
        resultBlock(UIImageJPEGRepresentation(info[UIImagePickerControllerOriginalImage], 0.9));
    }
}

+ (void)previewImageFromMediaInfo:(NSDictionary *)info resultBlock:(void (^)(UIImage *image))resultBlock
{
    if (info[UIImagePickerControllerReferenceURL]) {
        ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
        
        [library assetForURL:info[UIImagePickerControllerReferenceURL]
                 resultBlock:^(ALAsset *asset) {
                     if (asset != nil) {
                         ALAssetRepresentation *representation = [asset defaultRepresentation];
                         CGImageRef fullScreenImage = representation.fullScreenImage;

                         if (fullScreenImage != NULL) {
                             resultBlock([UIImage imageWithCGImage:fullScreenImage]);
                         } else {
                             resultBlock(nil);
                         }

                     }
                     else {
                         if (info[UIImagePickerControllerEditedImage] != nil) {
                             resultBlock(info[UIImagePickerControllerEditedImage]);
                         }
                         else if (info[UIImagePickerControllerOriginalImage] != nil) {
                             resultBlock(info[UIImagePickerControllerOriginalImage]);
                         }
                         else {
                             resultBlock(nil);
                         }
                     }


                 } failureBlock:^(NSError *error) {
                     resultBlock(nil);
                 }];
    }
    else if (info[UIImagePickerControllerEditedImage]) {
        resultBlock(info[UIImagePickerControllerEditedImage]);
    }
    else if (info[UIImagePickerControllerOriginalImage]) {
        resultBlock(info[UIImagePickerControllerOriginalImage]);
    }
}

@end
