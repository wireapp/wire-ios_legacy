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


#import "AnalyticsTracker.h"

@class ZMConversation;

typedef NS_ENUM(NSUInteger, FileTransferContext) {
    FileTransferContextShareExtension,
    FileTransferContextApp
};

@interface AnalyticsTracker (FileTransfer)

- (void)tagCannotUploadFileSizeExceedsWithSize:(unsigned long long)size fileExtension:(NSString *)extension;
- (void)tagInitiatedFileUploadWithSize:(unsigned long long)size fileExtension:(NSString *)extension context:(FileTransferContext)context;
- (void)tagCancelledFileUploadWithSize:(unsigned long long)size fileExtension:(NSString *)extension;

- (void)tagSucceededFileUploadWithSize:(unsigned long long)size
                        inConversation:(ZMConversation *)conversation
                         fileExtension:(NSString *)extension
                              duration:(NSTimeInterval)duration;

- (void)tagFailedFileUploadWithSize:(unsigned long long)size fileExtension:(NSString *)extension;

- (void)tagInitiatedFileDownloadWithSize:(unsigned long long)size fileExtension:(NSString *)extension;
- (void)tagSuccededFileDownloadWithSize:(unsigned long long)size fileExtension:(NSString *)extension duration:(NSTimeInterval)duration;
- (void)tagFailedFileDownloadWithSize:(unsigned long long)size fileExtension:(NSString *)extension;

- (void)tagOpenedFileWithSize:(unsigned long long)size fileExtension:(NSString *)extension;
@end
