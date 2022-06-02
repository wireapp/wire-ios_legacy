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


#import "MemoryLeaksObserver.h"


@interface Leak : NSObject

@property (nonatomic) intptr_t address;
@property (nonatomic) size_t length;
@property (nonatomic, copy) NSString *zoneName;
@property (nonatomic, copy) NSString *information;

@end



@implementation MemoryLeaksObserver

- (void)startObserving;
{
    int canSetABreakpointHere = 4;
    (void) canSetABreakpointHere;
}

#if (!TARGET_OS_IPHONE)
- (void)stopObserving;
{
    [(NSFileHandle *)[NSFileHandle fileHandleWithStandardError] writeData:[[self leaksOutput] dataUsingEncoding:NSUTF8StringEncoding]];
}

- (NSDictionary *)environmentForTasks
{
    NSMutableDictionary *env = [NSMutableDictionary dictionaryWithDictionary:[[NSProcessInfo processInfo] environment]];
    NSArray *keys = [[env allKeys] filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"NOT SELF BEGINSWITH \"Malloc\""]];
    [env removeObjectsForKeys:keys];
    return env;
}

- (NSString *)leaksOutput
{
    NSLog(@"Running leaks...");
    int const pid = [[NSProcessInfo processInfo] processIdentifier];
    
    NSTask *leaks = [[NSTask alloc] init];
    leaks.environment = [self environmentForTasks];
    leaks.launchPath = @"/usr/bin/xcrun";
    leaks.arguments = @[@"leaks", @"--nocontext", [NSString stringWithFormat:@"%d", pid]];
    NSPipe *pipe = [NSPipe pipe];
    leaks.standardOutput = pipe;
    [leaks launch];
    NSMutableData *leaksOutput = [NSMutableData data];
    while (leaks.isRunning) {
        NSData *d = pipe.fileHandleForReading.availableData;
        if (d != nil) {
            [leaksOutput appendData:d];
        }
    }
    return [[NSString alloc] initWithData:leaksOutput encoding:NSUTF8StringEncoding];
}
#endif

@end
