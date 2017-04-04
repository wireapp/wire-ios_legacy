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


#import "AnalyticsTracker+FileTransfer.h"
#import "DefaultIntegerClusterizer.h"
#import "Wire-Swift.h"

@import WireDataModel;

NSString * const AnalyticsFileSizeBytesKey = @"size_bytes";
NSString * const AnalyticsFileSizeMegabytesKey = @"size_mb";


FOUNDATION_EXPORT NSString *FileTransferContextToNSString(FileTransferContext context);

FOUNDATION_EXPORT NSString *FileTransferContextToNSString(FileTransferContext context)
{
    switch (context) {
        case FileTransferContextApp:
            return @"app";
            break;
        case FileTransferContextShareExtension:
            return @"share_extension";
            break;
    }
    
    return @"";
}

@implementation AnalyticsTracker (FileTransfer)

- (void)tagCannotUploadFileSizeExceedsWithSize:(unsigned long long)size fileExtension:(NSString *)extension
{
    [self tagEvent:@"file.attempted_too_big_file_upload"
        attributes:@{AnalyticsFileSizeBytesKey: [NSString stringWithFormat:@"%llu", size],
                     AnalyticsFileSizeMegabytesKey: [[DefaultIntegerClusterizer fileSizeClusterizer] clusterizeInteger:(int)roundf(((float)size) / (1024.0 * 1024.0))],
                     @"type": extension}];
}

- (void)tagInitiatedFileUploadWithSize:(unsigned long long)size fileExtension:(NSString *)extension context:(FileTransferContext)context
{
    [self tagEvent:@"file.initiated_file_upload"
        attributes:@{AnalyticsFileSizeBytesKey: [NSString stringWithFormat:@"%llu", size],
                     AnalyticsFileSizeMegabytesKey: [[DefaultIntegerClusterizer fileSizeClusterizer] clusterizeInteger:(int)roundf(((float)size) / (1024.0 * 1024.0))],
                     @"type": extension,
                     @"context": FileTransferContextToNSString(context)}];
}

- (void)tagCancelledFileUploadWithSize:(unsigned long long)size fileExtension:(NSString *)extension
{
    [self tagEvent:@"file.cancelled_file_upload"
        attributes:@{AnalyticsFileSizeBytesKey: [NSString stringWithFormat:@"%llu", size],
                     AnalyticsFileSizeMegabytesKey: [[DefaultIntegerClusterizer fileSizeClusterizer] clusterizeInteger:(int)roundf(((float)size) / (1024.0 * 1024.0))],
                     @"type": extension}];
}

- (void)tagSucceededFileUploadWithSize:(unsigned long long)size
                        inConversation:(ZMConversation *)conversation
                         fileExtension:(NSString *)extension
                              duration:(NSTimeInterval)duration;
{

    NSMutableDictionary *attributes = conversation.ephemeralTrackingAttributes.mutableCopy;
    attributes[AnalyticsFileSizeBytesKey] = [NSString stringWithFormat:@"%llu", size];
    attributes[AnalyticsFileSizeMegabytesKey] = [[DefaultIntegerClusterizer fileSizeClusterizer] clusterizeInteger:(int)roundf(((float)size) / (1024.0 * 1024.0))];
    attributes[@"type"] = extension;
    attributes[@"time"] = [NSString stringWithFormat:@"%.02f", duration];

    [self tagEvent:@"file.successfully_uploaded_file" attributes:attributes];
}

- (void)tagFailedFileUploadWithSize:(unsigned long long)size fileExtension:(NSString *)extension
{
    [self tagEvent:@"file.failed_file_upload"
        attributes:@{AnalyticsFileSizeBytesKey: [NSString stringWithFormat:@"%llu", size],
                     AnalyticsFileSizeMegabytesKey: [[DefaultIntegerClusterizer fileSizeClusterizer] clusterizeInteger:(int)roundf(((float)size) / (1024.0 * 1024.0))],
                     @"type": extension}];
}

- (void)tagInitiatedFileDownloadWithSize:(unsigned long long)size message:(id <ZMConversationMessage>)message fileExtension:(NSString *)extension
{
    NSMutableDictionary *attributes = [self.class ephemeralAttributesForMessage:message].mutableCopy;
    attributes[AnalyticsFileSizeBytesKey] = [NSString stringWithFormat:@"%llu", size];
    attributes[AnalyticsFileSizeMegabytesKey] = [[DefaultIntegerClusterizer fileSizeClusterizer] clusterizeInteger:(int)roundf(((float)size) / (1024.0 * 1024.0))];
    attributes[@"types"] = extension;

    [self tagEvent:@"file.initiated_file_download" attributes:attributes];
}

- (void)tagSuccededFileDownloadWithSize:(unsigned long long)size message:(id <ZMConversationMessage>)message fileExtension:(NSString *)extension duration:(NSTimeInterval)duration
{
    NSMutableDictionary *attributes = [self.class ephemeralAttributesForMessage:message].mutableCopy;
    attributes[AnalyticsFileSizeBytesKey] = [NSString stringWithFormat:@"%llu", size];
    attributes[AnalyticsFileSizeMegabytesKey] = [[DefaultIntegerClusterizer fileSizeClusterizer] clusterizeInteger:(int)roundf(((float)size) / (1024.0 * 1024.0))];
    attributes[@"types"] = extension;
    attributes[@"time"] = [NSString stringWithFormat:@"%.02f", duration];

    [self tagEvent:@"file.successfully_downloaded_file" attributes:attributes];
}

- (void)tagFailedFileDownloadWithSize:(unsigned long long)size fileExtension:(NSString *)extension
{
    [self tagEvent:@"file.failed_file_download"
        attributes:@{AnalyticsFileSizeBytesKey: [NSString stringWithFormat:@"%llu", size],
                     AnalyticsFileSizeMegabytesKey: [[DefaultIntegerClusterizer fileSizeClusterizer] clusterizeInteger:(int)roundf(((float)size) / (1024.0 * 1024.0))],
                     @"type": extension}];
}

- (void)tagOpenedFileWithSize:(unsigned long long)size fileExtension:(NSString *)extension
{
    [self tagEvent:@"file.opened_preview"
        attributes:@{AnalyticsFileSizeBytesKey: [NSString stringWithFormat:@"%llu", size],
                     AnalyticsFileSizeMegabytesKey: [[DefaultIntegerClusterizer fileSizeClusterizer] clusterizeInteger:(int)roundf(((float)size) / (1024.0 * 1024.0))],
                     @"type": extension}];
}

+ (NSDictionary *)ephemeralAttributesForMessage:(id <ZMConversationMessage>)message
{
    NSMutableDictionary *attributes = @{@"is_ephemeral": message.isEphemeral ? @"true" : @"false"}.mutableCopy;
    if (! message.isEphemeral) {
        return attributes;
    }

    attributes[@"ephemeral_time"] = [NSString stringWithFormat:@"%.f", message.deletionTimeout];
    return attributes;
}

@end
