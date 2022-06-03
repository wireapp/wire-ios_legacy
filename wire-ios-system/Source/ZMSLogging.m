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


#import "ZMSLogging.h"
#import "WireSystem/WireSystem-swift.h"

void ZMLog(NSString *tag, char const * const filename, int linenumber, ZMLogLevel_t logLevel, NSString *format, ...)
{
    va_list args;
    va_start(args, format);
    NSString *output = [[NSString alloc] initWithFormat:format arguments:args];
    va_end(args);
    
    [ZMSLog logWithLevel:logLevel message:^NSString * _Nonnull{
        return output;
    } tag:tag file:[NSString stringWithUTF8String:filename] line:(NSUInteger)linenumber];
}

void ZMDebugAssertMessage(NSString *tag, char const * const assertion, char const * const filename, int linenumber, char const * const format, ...)
{
    char * message = NULL;
    va_list ap;
    va_start(ap, format);
    if ((format == NULL) || (vasprintf(&message, format, ap) == 0)) {
        message = NULL;
    }
    va_end(ap);
    
    NSString *output = [NSString stringWithFormat:@"Assertion (%s) failed. %s", assertion, message ?: ""];
    [ZMSLog logWithLevel:ZMLogLevelError message:^NSString * _Nonnull{
        return output;
    } tag:tag file:[NSString stringWithUTF8String:filename] line:(NSUInteger)linenumber];
}

