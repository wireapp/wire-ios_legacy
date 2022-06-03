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


@import WireTesting;
#import "NSOperationQueue+Helpers.h"

@implementation NSOperationQueue (Helpers)

+ (instancetype)serialQueueWithName:(NSString *)name;
{
    NSOperationQueue *queue = [[self alloc] init];
    queue.maxConcurrentOperationCount = 1;
    queue.name = name;
    return queue;
}

- (void)waitUntilAllOperationsAreFinishedWithTimeout:(NSTimeInterval)timeout;
{
    timeout = [ZMTBaseTest timeToUseForOriginalTime:timeout];
    dispatch_semaphore_t sem = dispatch_semaphore_create(0);
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        [self waitUntilAllOperationsAreFinished];
        dispatch_semaphore_signal(sem);
    });
    dispatch_time_t t = dispatch_walltime(DISPATCH_TIME_NOW, llround(timeout * NSEC_PER_SEC));
    if (dispatch_semaphore_wait(sem, t) != 0) {
        NSLog(@"Timed out while waiting for queue \"%@\". Call stack:\n%@",
              self.name, [NSThread callStackSymbols]);
        exit(-1);
    }
}

@end
