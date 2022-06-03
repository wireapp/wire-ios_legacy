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


#import <OCMock/OCMock.h>

#define AssertDictionaryHasKeys(a1, a2) \
    do { \
        NSArray *_k1 = [[(a1) allKeys] sortedArrayUsingSelector:NSSelectorFromString(@"compare:")]; \
        NSArray *_k2 = [(a2) sortedArrayUsingSelector:NSSelectorFromString(@"compare:")]; \
        if (! [_k1 isEqual:_k2]) { \
            XCTFail(@"'%s' should have keys \"%@\", has \"%@\"", #a1, [_k2 componentsJoinedByString:@"\", \""], [_k1 componentsJoinedByString:@"\", \""]); \
        } \
    } while (0)

#define AssertArraysContainsSameObjects(a1, a2) \
    do { \
        [self assertArray:a1 hasSameElementsAsArray:a2 name1:#a1 name2:#a2 failureRecorder:NewFailureRecorder()]; \
    } while (0)

#define AssertIsValidUUIDString(a1) \
    do { \
        NSUUID *_u = ([a1 isKindOfClass:[NSString class]] ? [[NSUUID alloc] initWithUUIDString:(a1)] : nil); \
        if (_u == nil) { \
            XCTFail(@"'%@' is not a valid UUID string", a1); \
        } \
    } while (0)

#define AssertEqualSizes(s1, s2) \
    do { \
        CGSize _s1 = s1; \
        CGSize _s2 = s2; \
        XCTAssertTrue(CGSizeEqualToSize(_s1, _s2), @"%s (%g x %g) != %s (%g x %g)", #s1, _s1.width, _s1.height, #s2, _s2.width, _s2.height); \
    } while (0)

#define AssertEqualData(d1, d2) \
    do { \
        NSData *_d1 = d1; \
        NSData *_d2 = d2; \
        if ((_d1.length < 100) && (_d2.length < 100)) { \
            XCTAssertEqualObjects(_d1, _d2, @"%s == %s", #d1, #d2); \
        } else { \
            XCTAssertTrue([_d1 isEqual:_d2], @"%s == %s", #d1, #d2); \
        } \
    } while (0)

#define AssertNotEqualData(d1, d2) \
    do { \
        NSData *_d1 = d1; \
        NSData *_d2 = d2; \
        if ((_d1.length < 100) && (_d2.length < 100)) { \
            XCTAssertNotEqualObjects(_d1, _d2, @"%s != %s", #d1, #d2); \
        } else { \
            XCTAssertFalse([_d1 isEqual:_d2], @"%s != %s", #d1, #d2); \
        } \
    } while (0)



#define AssertEqualDictionaries(d1, d2) \
    do { \
        [self assertDictionary:d1 isEqualToDictionary:d2 name1:#d1 name2:#d2 failureRecorder:NewFailureRecorder()]; \
    } while (0)


#define AssertPartiallyEqualDictionaries(d1, d2, ignored) \
    do { \
        [self assertDictionary:d1 isEqualToDictionary:d2 name1:#d1 name2:#d2 ignoreKeys:ignored failureRecorder:NewFailureRecorder()]; \
    } while (0)

#define AssertImageDataIsEqual(d1, d2) \
    do { \
        XCTAssertNotNil(d1); \
        XCTAssertNotNil(d2); \
        if ((d1 != nil) && (d2 != nil)) { \
            ZMTImageComparator *comp = [[ZMTImageComparator alloc] initWithImageDataA:d1 imageDataB:d2]; \
            [comp calculateDifference]; \
            XCTAssertTrue(comp.maxPixelDifference < 2, @"Some pixel values were too different."); \
            XCTAssertFalse(comp.propertiesDiffer, @"%@", comp.propertiesDiffDescription); \
        } \
    } while (0)


#define AssertDateIsRecent(d) \
    do { \
        NSDate *_d = d; \
        XCTAssertNotNil(_d, @"%s", #d); \
        XCTAssertGreaterThan(_d.timeIntervalSinceNow, -5, @"%s", #d); \
        XCTAssertLessThanOrEqual(_d.timeIntervalSinceNow, 0.1, @"%s", #d); \
    } while (0)

#define ZMAssertQueue(_queue)	\
    do { \
        NSAssert( ([NSOperationQueue currentQueue] == _queue), @"Not on expected queue: %@", _queue); \
    } while(0)



#pragma mark - Queues

#define WaitForAllGroupsToBeEmpty(timeout) \
    do { \
        if (! [self waitForAllGroupsToBeEmptyWithTimeout:timeout]) { \
            XCTFail(@"Timed out waiting for groups to empty."); \
        } \
    } while (0)

//This only works if com.apple.CoreData.ConcurrencyDebug is enabled
#define ZMAssertGroupQueue(_queue)	\
    do { \
        ((NSManagedObjectContext *)_queue).userInfo; \
    } while(0)


#pragma mark - OCMock

#define ZM_ARG_SAVE(x) [OCMArg checkWithBlock:^BOOL(id obj) { \
    x = obj; \
    return YES; \
}]

#define ZM_ARG_ADD_TO(x) [OCMArg checkWithBlock:^BOOL(id obj) { \
    [x addObject:obj]; \
    return YES; \
}]

#define ZM_ARG_CHECK_IF_EQUAL(x) [OCMArg checkWithBlock:^BOOL(id obj) { \
    return obj == x; \
}]

#define ZM_ARG_CHECK_IF_EQUAL_OBJECTS(x) [OCMArg checkWithBlock:^BOOL(id obj) { \
    return obj == x || [obj isEqual:x]; \
}]


