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


#import "AVAsset+VideoConvert.h"
#import "weakify.h"
@import WireSystem;

@implementation AVAsset (VideoConvert)

+ (void)wr_convertVideoAtURL:(NSURL*)url toUploadFormatWithCompletion:(void(^)(NSURL *,AVAsset *, NSError *))completion
{
    NSString *filename = [[[url lastPathComponent] stringByDeletingPathExtension] stringByAppendingPathExtension:@"mp4"];
    AVURLAsset *asset = [AVURLAsset URLAssetWithURL:url options:nil];
    
    [asset wr_convertWithCompletion:^(NSURL *URL,AVAsset *asset, NSError *error) {
        
        if (completion != nil) {
            completion(URL, asset, error);
        }
        
        NSError *deleteError = nil;
        [[NSFileManager defaultManager] removeItemAtURL:url error:&deleteError];
        if (nil != deleteError) {
            ZMLogError(@"Cannot delete file: %@ (%@)", url, deleteError);
        }
        
    }
                           filename:filename];
}

- (void)wr_convertWithCompletion:(void(^)(NSURL *,AVAsset *, NSError *))completion filename:(NSString *)filename
{
    NSString *tmpfile = [NSTemporaryDirectory() stringByAppendingPathComponent:filename];
    
    NSURL *outputURL = [NSURL fileURLWithPath:tmpfile];

    if ([[NSFileManager defaultManager] fileExistsAtPath:outputURL.path]) {
        NSError *deleteError = nil;
        [[NSFileManager defaultManager] removeItemAtURL:outputURL error:&deleteError];
        if (nil != deleteError) {
            ZMLogError(@"Cannot delete old leftover at %@: %@", outputURL, deleteError);
        }
    }
    
    AVAssetExportSession *exportSession = [[AVAssetExportSession alloc] initWithAsset:self presetName:AVAssetExportPresetMediumQuality];
    exportSession.outputURL = outputURL;
    exportSession.shouldOptimizeForNetworkUse = YES;
    exportSession.outputFileType = AVFileTypeMPEG4;
    exportSession.metadata = @[];
    exportSession.metadataItemFilter = [AVMetadataItemFilter metadataItemFilterForSharing];
    @weakify(exportSession);
    [exportSession exportAsynchronouslyWithCompletionHandler:^(void) {
        @strongify(exportSession);
        if (exportSession.error) {
            ZMLogError(@"Export session error: status=%ld error=%@ output=%@", (long)exportSession.status, exportSession.error, outputURL);
        }
        
        if (completion) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(outputURL, self, exportSession.error);
            });
        }
        
       
    }];
}

@end
