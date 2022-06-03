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


#import <XCTest/XCTest.h>



@interface ZMTFailureRecorder : NSObject

- (instancetype)initWithTestCase:(XCTestCase *)testCase filePath:(char const *)filePath lineNumber:(NSUInteger)lineNumber;

@property (nonatomic, readonly) XCTestCase *testCase;
@property (nonatomic, readonly, copy) NSString *filePath;
@property (nonatomic, readonly) NSUInteger lineNumber;

- (void)recordFailure:(NSString *)format, ... NS_FORMAT_FUNCTION(1,2);

@end



#define NewFailureRecorder() \
	[[ZMTFailureRecorder alloc] initWithTestCase:self filePath:__FILE__ lineNumber:__LINE__]




#define FHAssertEqual(fh, expression1, expression2) \
	do { \
		typeof(expression1) _e1 = (expression1); \
		typeof(expression2) _e2 = (expression2); \
		if (_e1 != _e2) { \
			NSValue *expressionBox1 = [NSValue value:&_e1 withObjCType:@encode(__typeof__(expression1))]; \
			NSValue *expressionBox2 = [NSValue value:&_e2 withObjCType:@encode(__typeof__(expression2))]; \
			[fh recordFailure:@"%@ != %@ (%@ vs %@)", @#expression1, @#expression2, expressionBox1, expressionBox2]; \
		} \
	} while (0)

#define FHAssertNotNil(fh, obj) \
	do { \
		id _obj = obj; \
		if (_obj == nil) { \
			[fh recordFailure:@"%@ != nil (%@)", @#obj, _obj]; \
		} \
	} while (0)

#define FHAssertEqualObjects(fh, obj1, obj2) FHAssertEqualObjectsString(fh, obj1, obj2, @"")

#define FHAssertEqualArrays(fh, obj1, obj2) \
	do { \
		NSArray *_oobj1 = obj1; \
		NSArray *_oobj2 = obj2; \
		NSString *_s = [NSString stringWithFormat:@"{%@} is not equal to {%@}", \
			[[_oobj1 valueForKey:@"description"] componentsJoinedByString:@", "], \
			[[_oobj2 valueForKey:@"description"] componentsJoinedByString:@", "]]; \
        FHAssertEqualObjectsString(fh, _oobj1, _oobj2, _s); \
	} while (0)

#define FHAssertEqualObjectsString(fh, obj1, obj2, string) \
    do { \
        id _obj1 = obj1; \
        id _obj2 = obj2; \
        if ((_obj1 == nil) && (_obj2 == nil)) { \
            break; \
        } \
        if (! [_obj1 isEqual:_obj2]) { \
            [fh recordFailure:@"%@ != %@, %@", @#obj1, @#obj2, string]; \
        } \
    } while (0)

#define FHAssertTrue(fh, expression1) \
	do { \
		typeof(expression1) _e1 = expression1; \
		if (! _e1) { \
			[fh recordFailure:@"%@", @#expression1]; \
		} \
	} while (0)

#define FHAssertFalse(fh, expression1) \
	do { \
		typeof(expression1) _e1 = expression1; \
		if (_e1) { \
			[fh recordFailure:@"%@ == NO", @#expression1]; \
		} \
	} while (0)
