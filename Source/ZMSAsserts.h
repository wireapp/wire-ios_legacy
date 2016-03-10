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

#import <AssertMacros.h>
#import "ZMSDefines.h"
#import "ZMSActivity.h"
#import <os/trace.h>



/**
 
 Asserts and checks.
 
 
 There are 3 kinds: Require, Verify, and Check. Require is a _hard_ check that will cause the app to stop / crash if it fails. Verify is graceful by either causing an action or logging a string. Check has no other side effects and are pulled out in production.
 
 Any check that fails will funnel through ZMLogDebugger(). Setting a symbolic breakpoint on that function will cause the debugger to stop on any check failing.
 
 Require(assertion)
 RequireString(assertion, frmt, ...)
 
 VerifyAction(assertion, action)
 VerifyReturn(assertion)
 VerifyReturnValue(assertion, value)
 VerifyReturnNil(assertion)
 VerifyString(assertion, frmt, ...)
 
 Check(assertion)
 CheckNil(obj)
 CheckNotNil(obj)
 CheckString(assertion, frmt, ...)
 
 */


#define ZMTrap() do { \
		ZMCrash("Trap"); \
	} while (0)


#if DEBUG_ASSERT_PRODUCTION_CODE

#   define Require(assertion) \
	do { \
		if ( __builtin_expect(!(assertion), 0) ) { \
			ZMDebugAssertMessage( "Require", #assertion, __FILE__, __LINE__, nil); \
			ZMCrash(#assertion); \
		} \
	} while (0)

#   define RequireString(assertion, frmt, ...) \
	do { \
		if ( __builtin_expect(!(assertion), 0) ) { \
			ZMDebugAssertMessage( "RequireString", #assertion, __FILE__, __LINE__, frmt, ##__VA_ARGS__); \
			ZMCrashFormat(#assertion, frmt, ##__VA_ARGS__); \
		} \
	} while (0)

#   define RequireC(assertion) \
		Require(assertion)

#else

#   define Require(assertion) do { \
		if ( __builtin_expect(!(assertion), 0) ) { \
			ZMCrash(#assertion); \
		} \
	} while (0)
#   define RequireString(assertion, frmt, ...) do { \
		if ( __builtin_expect(!(assertion), 0) ) { \
			ZMCrashFormat(#assertion, frmt, ##__VA_ARGS__); \
		} \
	} while (0)
#   define RequireC(assertion) do { \
		if ( __builtin_expect(!(assertion), 0) ) { \
			ZMCrash(#assertion); \
		} \
	} while (0)

#endif



#define VerifyAction(assertion, action) \
	do { \
		if ( __builtin_expect(!(assertion), 0) ) { \
			ZMDebugAssertMessage("VerifyAction", #assertion, __FILE__, __LINE__, nil); \
			ZMTraceErrorMessage(#assertion); \
			action; \
		} \
	} while (0)

#define VerifyReturn(assertion) \
	VerifyAction(assertion, return)

#define VerifyReturnValue(assertion, value) \
	VerifyAction(assertion, return (value))

#define VerifyReturnNil(assertion) \
	VerifyAction(assertion, return nil)

#define VerifyString(assertion, frmt, ...) \
	do { \
		if ( __builtin_expect(!(assertion), 0) ) { \
			ZMDebugAssertMessage( "VerifyString", #assertion, __FILE__, __LINE__, frmt, ##__VA_ARGS__); \
			ZMTraceErrorMessage(#assertion); \
			ZMTraceErrorMessage(frmt, ##__VA_ARGS__); \
		} \
	} while (0)


#define VerifyActionString(assertion, action, frmt, ...) \
    do { \
        if ( __builtin_expect(!(assertion), 0) ) { \
            ZMDebugAssertMessage( "VerifyActionString", #assertion, __FILE__, __LINE__, frmt, ##__VA_ARGS__); \
            action; \
        } \
    } while (0)

#define VerifyStringReturnNil(assertion, frmt, ...) \
	do { \
		if ( __builtin_expect(!(assertion), 0) ) { \
			ZMDebugAssertMessage( "VerifyStringReturnNil", #assertion, __FILE__, __LINE__, frmt, ##__VA_ARGS__); \
			return nil; \
		} \
	} while (0)


#if DEBUG_ASSERT_PRODUCTION_CODE
# define Check(assertion)
#else
# define Check(assertion) \
	do { \
		if ( __builtin_expect(!(assertion), 0) ) { \
			ZMDebugAssertMessage( "Check", #assertion, __FILE__, __LINE__, nil); \
		} \
	} while (0)
#endif

#define CheckNil(value) \
	Check(value == nil)

#define CheckNotNil(value) \
	Check(value != nil)

#if DEBUG_ASSERT_PRODUCTION_CODE
# define CheckString(assertion, frmt, ...)
#else
# define CheckString(assertion, frmt, ...) \
	do { \
		if ( __builtin_expect(!(assertion), 0) ) { \
			ZMDebugAssertMessage( "CheckString", #assertion, __FILE__, __LINE__, frmt, ##__VA_ARGS__); \
		} \
	} while (0)
#endif



#pragma mark -

# define ZMCrash(reason) \
	ZMTraceFaultMessage(reason); \
	__builtin_trap();

# define ZMCrashFormat(reason, format, ...) \
	ZMTraceFaultMessage(reason); \
	ZMTraceFaultMessage(format, ##__VA_ARGS__); \
	__builtin_trap();
