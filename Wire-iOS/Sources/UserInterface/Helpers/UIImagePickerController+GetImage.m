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

@import Photos;
@import MobileCoreServices;
@import FLAnimatedImage;

@interface PHAsset (MediaInfo)
+ (nullable PHAsset *)loadFromMediaInfo:(nonnull NSDictionary *)mediaInfo;
@end

@implementation PHAsset (MediaInfo)

+ (nullable PHAsset *)loadFromMediaInfo:(nonnull NSDictionary *)mediaInfo
{
    NSURL *assetURL = [mediaInfo objectForKey:UIImagePickerControllerReferenceURL];
    if (nil == assetURL) {
        return nil;
    }
    PHFetchResult<PHAsset *> *result = [PHAsset fetchAssetsWithALAssetURLs:@[assetURL] options:nil];
    return result.firstObject;
}

@end

@implementation UIImagePickerController (GetImage)

+ (void)imageFromMediaInfo:(NSDictionary *)info resultBlock:(void(^)(UIImage*))callback
{
    UIImage *image = nil;
    PHAsset *resultAsset = [PHAsset loadFromMediaInfo:info];
    if (resultAsset != nil) {
        [PHImageManager.defaultManager requestImageForAsset:resultAsset
                                                 targetSize:PHImageManagerMaximumSize
                                                contentMode:PHImageContentModeDefault
                                                    options:[UIImagePickerController pickingOptions]
                                              resultHandler:^(UIImage * _Nullable result, NSDictionary * _Nullable info) {
                                                  dispatch_async(dispatch_get_main_queue(), ^{
                                                      callback(result);
                                                  });
                                              }];
        return;
    }
    else {
        image = info[UIImagePickerControllerEditedImage];
        
        if (image == nil) {
            image = info[UIImagePickerControllerOriginalImage];
        }
        
        if (image != nil) {
            callback(image);
        }
    }
}

+ (void)imageDataFromMediaInfo:(NSDictionary *)info resultBlock:(void (^)(NSData *imageData))resultBlock
{
    PHAsset *resultAsset = [PHAsset loadFromMediaInfo:info];

    if (nil != resultAsset) {
        [PHImageManager.defaultManager requestImageDataForAsset:resultAsset
                                                        options:[UIImagePickerController pickingOptions]
                                                  resultHandler:^(NSData * _Nullable imageData, NSString * _Nullable dataUTI, UIImageOrientation orientation, NSDictionary * _Nullable info) {
                                                      dispatch_async(dispatch_get_main_queue(), ^{
                                                          if (imageData != nil) {
                                                              resultBlock(imageData);
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
                                                      });
                                                  }];
    }
    else if (info[UIImagePickerControllerEditedImage]) {
        resultBlock(UIImageJPEGRepresentation(info[UIImagePickerControllerEditedImage], 0.9));
    }
    else if (info[UIImagePickerControllerOriginalImage]) {
        resultBlock(UIImageJPEGRepresentation(info[UIImagePickerControllerOriginalImage], 0.9));
    }
}

+(PHImageRequestOptions*)pickingOptions
{
    PHImageRequestOptions *options = [[PHImageRequestOptions alloc] init];
    options.deliveryMode = PHImageRequestOptionsDeliveryModeHighQualityFormat;
    return options;
}

@end
