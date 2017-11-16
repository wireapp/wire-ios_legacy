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


#import "AppDelegate+Logging.h"

// Logging
@import CocoaLumberjack;
@import WireExtensionComponents;


/// Used and created only once, no need to hustle with objc_setAssociatedObject etc.
static DDFileLogger *VoiceFileLogger = nil;


@implementation AppDelegate (Logging)

- (NSString *)currentVoiceLogPath
{
    if (! VoiceFileLogger) {
        return nil;
    }
    NSArray *fileInfos = VoiceFileLogger.logFileManager.sortedLogFileInfos;
    if (fileInfos.count > 0) {
        return [fileInfos[0] filePath];
    }
    return nil;
}

- (NSData *)currentVoiceLogData
{
    NSString *logPath = [self currentVoiceLogPath];
    if  (! logPath) {
        return nil;
    }
    return [[NSData alloc] initWithContentsOfFile:logPath options:NSDataReadingUncached error:nil];
}

- (void)setupLogging
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSString *baseDir = paths.firstObject;
    if (baseDir == nil) {
        NSLog(@"Error: cannot create DD logs directory");
        return;
    }
    NSString *logsDirectory = [baseDir stringByAppendingPathComponent:@"Logs"];
    
    // Clean logs directory
    if ([[NSFileManager defaultManager] fileExistsAtPath:logsDirectory]) {
        NSError *error = nil;
        [[NSFileManager defaultManager] removeItemAtPath:logsDirectory error:&error];
        if (error != nil) {
            NSLog(@"Error: cannot clean DD logs directory: %@ (%@)", logsDirectory, error);
        }
    }
    
    NSError *error = nil;
    [[NSFileManager defaultManager] createDirectoryAtPath:logsDirectory withIntermediateDirectories:YES attributes:nil error:&error];
    if (nil != error) {
        NSLog(@"Error: cannot create DD logs directory: %@ (%@)", logsDirectory, error);
    }
    
    LineNumberLogFormatter *logFormatter = [[LineNumberLogFormatter alloc] init];
    [logFormatter addToWhitelist:0];
    
    DDASLLogger *aslLogger = [DDASLLogger sharedInstance];
    [aslLogger setLogFormatter:logFormatter];
    [DDLog addLogger:aslLogger];
    
    DDTTYLogger *ttyLogger = [DDTTYLogger sharedInstance];
    [ttyLogger setLogFormatter:logFormatter];
    [DDLog addLogger:ttyLogger];
    
    DDFileLogger *fileLogger = [[DDFileLogger alloc] init];
    [fileLogger setLogFormatter:logFormatter];
    [DDLog addLogger:fileLogger];
    
    // Voice logging setup

    NSString *voiceLogsDirectory = [logsDirectory stringByAppendingPathComponent:@"voice"];
    
    error = nil;
    [[NSFileManager defaultManager] createDirectoryAtPath:voiceLogsDirectory withIntermediateDirectories:YES attributes:nil error:&error];
    if (nil != error) {
        NSLog(@"Error: cannot create DD voice logs directory: %@ (%@)", voiceLogsDirectory, error);
    }
    
    DDLogFileManagerDefault *fileManagerVoice = [[DDLogFileManagerDefault alloc] initWithLogsDirectory:voiceLogsDirectory];
    if (! VoiceFileLogger) {
        VoiceFileLogger = [[DDFileLogger alloc] initWithLogFileManager:fileManagerVoice];
    }
    
    LineNumberLogFormatter *callFormatter = [[LineNumberLogFormatter alloc] init];
    callFormatter.appendFileName = NO;
    [callFormatter addToWhitelist:LOG_VOICE_CONTEXT];
    [callFormatter removeFromWhitelist:0];
    [VoiceFileLogger setLogFormatter:callFormatter];
    [DDLog addLogger:VoiceFileLogger];
}


@end
