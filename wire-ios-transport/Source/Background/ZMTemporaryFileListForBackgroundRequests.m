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


@import WireSystem;
#import "ZMTemporaryFileListForBackgroundRequests.h"
#import "ZMTaskIdentifierMap.h"

static NSString * const TemporaryDirectoryName = @"com.wire.zmessaging.ZMTemporaryFileListForBackgroundRequests";



@interface ZMTemporaryFileListForBackgroundRequests ()

@property (nonatomic, readonly) ZMTaskIdentifierMap *taskToTemporaryFile;

@end



@implementation ZMTemporaryFileListForBackgroundRequests

- (instancetype)init
{
    self = [super init];
    if(self) {
        _taskToTemporaryFile = [[ZMTaskIdentifierMap alloc] init];
    }
    return self;
}

- (NSURL *)temporaryFileWithBodyData:(NSData *)bodyData;
{
    static int counter;
    ++counter;
    
    NSError *error = nil;
    NSString *directoryPath = [NSString pathWithComponents:@[NSTemporaryDirectory(), TemporaryDirectoryName]];
    [[NSFileManager defaultManager] createDirectoryAtPath:directoryPath withIntermediateDirectories:YES attributes:@{} error:&error];
    
    NSString *filename = [NSString stringWithFormat:@"%d.bodydata", counter];
    NSURL *fileURL = [NSURL fileURLWithPath:directoryPath];
    fileURL = [fileURL URLByAppendingPathComponent:filename];
    
    BOOL success = [bodyData writeToURL:fileURL options:0 error:&error];
    if(!success) {
        ZMLogError(@"Failed to write payload to file %@: %@", fileURL.path, error);
        return nil;
    }
    
    return fileURL;
}

- (void)setTemporaryFile:(NSURL *)fileURL forTaskIdentifier:(NSUInteger)taskId;
{
    RequireString(self.taskToTemporaryFile[taskId] == nil, "Trying to create a temporary file for the same task twice");
    self.taskToTemporaryFile[taskId] = fileURL;
}

- (void)deleteFileForTaskID:(NSUInteger)taskId
{
    
    NSURL *temporaryFile = self.taskToTemporaryFile[taskId];
    if (temporaryFile != nil) {
        NSError *error;
        if (! [[NSFileManager defaultManager] removeItemAtURL:temporaryFile error:&error]) {
            ZMLogError(@"Unable to remove temporary body data file '%@': %@", temporaryFile.path, error);
        }
        [self.taskToTemporaryFile removeObjectForTaskIdentifier:taskId];
    }

}

@end
