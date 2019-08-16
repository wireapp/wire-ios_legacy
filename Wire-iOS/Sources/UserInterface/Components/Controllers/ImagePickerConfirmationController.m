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


#import "ImagePickerConfirmationController.h"

#import <AssetsLibrary/AssetsLibrary.h>
#import <MobileCoreServices/MobileCoreServices.h>

#import "Constants.h"
#import "ConfirmAssetViewController.h"
#import "UIView+PopoverBorder.h"
@import FLAnimatedImage;

#import "MediaAsset.h"

#import "Wire-Swift.h"



@interface ImagePickerConfirmationController ()

@end

@interface ImagePickerConfirmationController (CanvasViewControllerDelegate)
@end

@implementation ImagePickerConfirmationController

//- (void)assetPreviewFromMediaInfo:(NSDictionary *)info resultBlock:(void (^)(id media))resultBlock
//{
//    NSString *assetUTI = [self UTIFromAssetURL:info[UIImagePickerControllerReferenceURL]];
//
//    if ([assetUTI isEqualToString:(id)kUTTypeGIF]) {
//        [UIImagePickerController imageDataFromMediaInfo:info resultBlock:^(NSData *imageData) {
//            resultBlock([[FLAnimatedImage alloc] initWithAnimatedGIFData:imageData]);
//        }];
//    } else {
//        [UIImagePickerController imageFromMediaInfo:info resultBlock:^(UIImage *image) {
//            resultBlock(image);
//        }];
//    }
//}

//- (NSString *)UTIFromAssetURL:(NSURL *)assetURL
//{
//    NSString *extension = [assetURL pathExtension];
//    return (NSString *)CFBridgingRelease(UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension,(__bridge CFStringRef)extension , NULL));
//}


@end
