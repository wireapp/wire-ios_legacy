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
// along with this program. If not, see <http://www.gnu.org/licenses/>.


#import <Foundation/Foundation.h>
#import <ZMCSystem/ZMSAsserts.h>

/**
 
 Logging
 
 
 This is for zmessaging logging.
 
 
 How to use:
 
 At the top of the file define the log level like so:
 
 @code
 static char* const ZMLogTag ZM_UNUSED = "Network";
 @endcode
 
 The @c ZMLogError() etc. then work just like @c NSLog() does.
 
 
 You can set a (symbolic) breakpoint at ZMLogDebugger to stop automatically when a warning or error level message is logged.
 
 **/

/// This is a callback that is invoked every time there is a log error
extern void (^ZMLoggingDebuggingHook)(const char *tag, char const * const filename, int linenumber, NSString *output);

#define ZMLogError(format, ...) ZMLogWithLevel(ZMLogLevelError, format, ##__VA_ARGS__)
#define ZMLogWarn(format, ...) ZMLogWithLevel(ZMLogLevelWarn, format, ##__VA_ARGS__)
#define ZMLogInfo(format, ...) ZMLogWithLevelAndTag(ZMLogLevelInfo, ZMLogTag, format, ##__VA_ARGS__)
#define ZMLogDebug(format, ...) ZMLogWithLevelAndTag(ZMLogLevelDebug, ZMLogTag, format, ##__VA_ARGS__)


#define ZMLogWithLevelAndTag(level, tag, format, ...) \
    do { \
        ZMLog(tag, __FILE__, __LINE__, level, format, ##__VA_ARGS__); \
    } while (0)

#define ZMLogWithLevel(level, format, ...) \
    do { \
        ZMLog(0, __FILE__, __LINE__, level, format, ##__VA_ARGS__); \
    } while (0)

typedef NS_ENUM(int8_t, ZMLogLevel_t) {
    ZMLogLevelError = 0,
    ZMLogLevelWarn,
    ZMLogLevelInfo,
    ZMLogLevelDebug,
};


/// Use this to know if the log is at a certain level. Allows you to avoid preparing a log message with some complex operations if the log is not needed
#define ZMLogLevelIsActive(tag, level) \
	(__builtin_expect((level <= ZMLogGetLevelForTag(tag)), 0))

/// Logs a message
ZM_EXTERN void ZMLog(const char *tag, char const * const filename, int linenumber, ZMLogLevel_t logLevel, NSString *format, ...) NS_FORMAT_FUNCTION(5,6);
/// Asserts
ZM_EXTERN void ZMDebugAssertMessage(const char *tag, char const * const assertion, char const * const filename, int linenumber, char const *format, ...) __attribute__((format(printf,5,6)));

#pragma mark - Turning logs on and off

/// Sets the log level for a specific tag
ZM_EXTERN void ZMLogSetLevelForTag(ZMLogLevel_t level, const char *tag);
/// Gets the log level for a specific tag
ZM_EXTERN ZMLogLevel_t ZMLogGetLevelForTag(const char *tag);
/// Returns a list of all currently registered log tags. A tag is returned only if it was ever logged, or ZMLogInitForTag was ever called.
ZM_EXTERN NSSet* ZMLogGetAllTags(void);
/// Registers a logging tag
ZM_EXTERN void ZMLogInitForTag(const char *tag);
/// Wait until all changes to the log levels have been propagated
ZM_EXTERN void ZMLogSynchronize();
/// write a snapshot of the last 10000 system logs, takes everything it can
ZM_EXTERN void ZMLogSnapshot(NSString *filepath);

