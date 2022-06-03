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
#import <XCTest/XCTest.h>
#import "ZMFunctional.h"
#import <OCMock/OCMock.h>


@interface FunctionalTests : ZMTBaseTest
@end


@interface NSString (FunctionalTests)

- (id)functionalTests_map;

@end



@implementation FunctionalTests
@end



@implementation FunctionalTests (NSOrderedSet)

- (void)testThatOrderedSetMapsWithABlock
{
    // given
    NSOrderedSet *input = [NSOrderedSet orderedSetWithArray:@[@"a", @"b", @"c"]];
    
    // when
    NSOrderedSet *result = [input mapWithBlock:^(NSString *s) {
        return [s uppercaseString];
    }];
    
    // then
    NSOrderedSet *expected = [NSOrderedSet orderedSetWithArray:@[@"A", @"B", @"C"]];
    XCTAssertEqualObjects(result, expected);
}

- (void)testThatOrderedSetDoesNotMapNilValuesWithABlock
{
    // given
    NSOrderedSet *input = [NSOrderedSet orderedSetWithArray:@[@"a", @"b", @"c"]];
    
    // when
    NSOrderedSet *result = [input mapWithBlock:^(NSString *s) {
        if ([s isEqualToString:@"b"]) {
            return (NSString *) nil;
        } else {
            return s;
        }
    }];
    
    // then
    NSOrderedSet *expected = [NSOrderedSet orderedSetWithArray:@[@"a", @"c"]];
    XCTAssertEqualObjects(result, expected);
}

- (void)testThatOrderedSetMapsWithASelector
{
    // given
    NSOrderedSet *input = [NSOrderedSet orderedSetWithArray:@[@"a", @"b", @"c"]];
    
    // when
    NSOrderedSet *result = [input mapWithSelector:NSSelectorFromString(@"uppercaseString")];
    
    // then
    NSOrderedSet *expected = [NSOrderedSet orderedSetWithArray:@[@"A", @"B", @"C"]];
    XCTAssertEqualObjects(result, expected);
}

- (void)testThatOrderedSetDoesNotMapNilValuesWithASelector
{
    // given
    NSOrderedSet *input = [NSOrderedSet orderedSetWithArray:@[@"a", @"b", @"c"]];
    
    // when
    NSOrderedSet *result = [input mapWithSelector:@selector(functionalTests_map)];
    
    // then
    NSOrderedSet *expected = [NSOrderedSet orderedSetWithArray:@[@"a", @"c"]];
    XCTAssertEqualObjects(result, expected);
}


- (void)testThatOrderedSetFiltersObjectByClass
{
    // given
    NSNumber *n1 = @1;
    NSNumber *n2 = @35;
    NSString *s1 = @"ciao";
    NSString *s2 = @"bip";
    
    NSOrderedSet *expectedStrings = [NSOrderedSet orderedSetWithObjects:s1, s2, nil];
    NSOrderedSet *expectedNumbers = [NSOrderedSet orderedSetWithObjects:n1, n2, nil];
    NSOrderedSet *testedSet = [NSOrderedSet orderedSetWithObjects:n1, s1, n2, s2, nil];
    
    // when
    NSOrderedSet *computedStrings = [testedSet objectsOfClass:NSString.class];
    NSOrderedSet *computedNumbers = [testedSet objectsOfClass:NSNumber.class];
    
    // then
    XCTAssertEqualObjects(expectedStrings, computedStrings);
    XCTAssertEqualObjects(expectedNumbers, computedNumbers);
}

@end




@implementation FunctionalTests (NSArray)

- (void)testThatArraysMapsWithABlock
{
    // given
    NSArray *input = @[@"a", @"b", @"c"];
    
    // when
    NSArray *result = [input mapWithBlock:^(NSString *s) {
        return [s uppercaseString];
    }];
    
    // then
    NSArray *expected = @[@"A", @"B", @"C"];
    XCTAssertEqualObjects(result, expected);
}

- (void)testThatArraysDoesNotMapNilValuesWithABlock
{
    // given
    NSArray *input = @[@"a", @"b", @"c"];
    
    // when
    NSArray *result = [input mapWithBlock:^(NSString *s) {
        if ([s isEqualToString:@"b"]) {
            return (NSString *) nil;
        } else {
            return s;
        }
    }];
    
    // then
    NSArray *expected = @[@"a", @"c"];
    XCTAssertEqualObjects(result, expected);
}

- (void)testThatArraysMapsWithASelector
{
    // given
    NSArray *input = @[@"a", @"b", @"c"];
    
    // when
    NSArray *result = [input mapWithSelector:NSSelectorFromString(@"uppercaseString")];
    
    // then
    NSArray *expected = @[@"A", @"B", @"C"];
    XCTAssertEqualObjects(result, expected);
}

- (void)testThatArraysDoesNotMapNilValuesWithASelector
{
    // given
    NSArray *input = @[@"a", @"b", @"c"];
    
    // when
    NSArray *result = [input mapWithSelector:@selector(functionalTests_map)];
    
    // then
    NSArray *expected = @[@"a", @"c"];
    XCTAssertEqualObjects(result, expected);
}

- (void)testThatArraysReturnsFirstNotNil
{
    // given
    NSArray *input = @[@"b", @"b", @"c"];
    
    // when
    NSString *result = [input firstNonNilReturnedFromSelector:@selector(functionalTests_map)];
    
    // then
    XCTAssertEqualObjects(@"c", result);
}

- (void)testThatArraysReturnsFirstNotNilAskAllObjects
{
    // given
    NSString *string1 = [OCMockObject mockForClass:NSString.class];
    [[[(id)string1 expect] andReturn:nil] functionalTests_map];
    NSString *string2 = [OCMockObject mockForClass:NSString.class];
    [[[(id)string2 expect] andReturn:nil] functionalTests_map];
    NSString *string3 = [OCMockObject mockForClass:NSString.class];
    [[[(id)string3 expect] andReturn:@"ok"] functionalTests_map];
    NSArray *input = @[ string1, string2, string3 ];
    
    // when
    NSString *result = [input firstNonNilReturnedFromSelector:@selector(functionalTests_map)];
    
    // then
    XCTAssertEqualObjects(@"ok", result);
    [self verifyMockLater:string1];
    [self verifyMockLater:string2];
    [self verifyMockLater:string3];
}


- (void)testThatArrayFirstNotNilReturnsNilIfAllReturnsNil
{
    // given
    NSArray *input = @[@"b", @"b", @"b"];
    
    // when
    NSString *result = [input firstNonNilReturnedFromSelector:@selector(functionalTests_map)];
    
    // then
    XCTAssertNil(result);
}

- (void)testThatArrayFirstObjectMatchingIsReturned;
{
    // given
    NSArray *input = @[@"a", @"b", @"c"];
    
    // when
    NSString *result = [input firstObjectMatchingWithBlock:^BOOL(id obj) {
        return [@"b" isEqual:obj];
    }];
    
    // then
    XCTAssertEqual(result, @"b");
}

- (void)testThatArrayContainsObjectMatching
{
    // given
    NSArray *input = @[@"a", @"b", @3];
    
    // then
    XCTAssertTrue([input containsObjectMatchingWithBlock:^BOOL(NSString *s) {
        return (BOOL) [s isEqual:@"b"];
    }]);
    XCTAssertTrue([input containsObjectMatchingWithBlock:^BOOL(NSString *s) {
        return (BOOL) [s isEqual:@3];
    }]);
    XCTAssertFalse([input containsObjectMatchingWithBlock:^BOOL(NSString *s) {
        return (BOOL) [s isEqual:@"Z"];
    }]);
    XCTAssertFalse([input containsObjectMatchingWithBlock:^BOOL(NSString *s) {
        return (BOOL) [s isEqual:@7];
    }]);
}

- (void)testThatArrayFirstObjectMatchingReturnsNilIfNoneMatch
{
    // given
    NSArray *input = @[@"a", @"b", @"c"];
    
    // when
    NSString *result = [input firstObjectMatchingWithBlock:^BOOL(id obj) {
        return [@"ZZZZ" isEqual:obj];
    }];
    
    // then
    XCTAssertNil(result);
}

- (void)testThatArrayFiltersObjectByClass
{
    // given
    NSNumber *n1 = @1;
    NSNumber *n2 = @35;
    NSString *s1 = @"ciao";
    NSString *s2 = @"bip";
    
    NSArray *expectedStrings = @[s1, s2];
    NSArray *expectedNumbers = @[n1, n2];
    NSArray *testedArray = @[n1, s1, n2, s2];
    
    // when
    NSArray *computedStrings = [testedArray objectsOfClass:NSString.class];
    NSArray *computedNumbers = [testedArray objectsOfClass:NSNumber.class];
    
    // then
    XCTAssertEqualObjects(expectedStrings, computedStrings);
    XCTAssertEqualObjects(expectedNumbers, computedNumbers);
}

- (void)testThatItFlattensArrays
{
    // given
    NSArray *array1 = @[@"a", @"b", @"c"];
    NSArray *array2 = @[@"d", @"e", @"f"];

    NSArray *arrayToFlatten = @[array1, array2];
    
    // when
    NSArray *flattenedArray = [arrayToFlatten flattenWithBlock:^NSArray *(id obj) {
        return obj;
    }];
    
    // then
    NSArray *expected = @[@"a", @"b", @"c", @"d", @"e", @"f"];
    XCTAssertEqualObjects(flattenedArray, expected);
}

- (void)testThatItFlattensDictionarysOfArrays
{
    // given
    NSDictionary *dictionary1 = @{@"array": @[@"a", @"b", @"c"]};
    NSDictionary *dictionary2 = @{@"array":@[ @"d", @"e", @"f"]};

    NSArray *arrayToFlatten = @[dictionary1, dictionary2];
    
    // when
    NSArray *flattenedArray = [arrayToFlatten flattenWithBlock:^NSArray *(id obj) {
        return obj[@"array"];
    }];
    
    // then
    NSArray *expected = @[@"a", @"b", @"c", @"d", @"e", @"f"];
    XCTAssertEqualObjects(flattenedArray, expected);
}

- (void)testThatItDoesNotFlattenNilValues
{
    // given
    NSDictionary *dictionary = @{@"foo":@[ @"g", @"h", @"j"]};
    
    NSArray *arrayToFlatten = @[dictionary];
    
    // when
    NSArray *flattenedArray = [arrayToFlatten flattenWithBlock:^NSArray *(id obj) {
        return obj[@"array"];
    }];
    
    // then
    NSArray *expected = @[];
    XCTAssertEqualObjects(flattenedArray, expected);
}

- (void)testThatItDoesNotFlattenNonArrayElements
{
    // given
    NSDictionary *dictionary1 = @{@"array": @"a"};
    NSDictionary *dictionary2 = @{@"array": @"b"};
    
    NSArray *arrayToFlatten = @[dictionary1, dictionary2];
    
    // when
    NSArray *flattenedArray = [arrayToFlatten flattenWithBlock:^NSArray *(id obj) {
        return obj[@"array"];
    }];
    
    // then
    NSArray *expected = @[];
    XCTAssertEqualObjects(flattenedArray, expected);
}

- (void)testThatItFiltersArray
{
    // given
    NSArray *words = @[@"cat",@"duck",@"elephant",@"dog", @"duck"];
    
    // when
    NSArray *filtered = [words filterWithBlock:^BOOL(NSString *s) {
        return s.length > 3;
    }];
    
    // then
    NSArray *expected = @[@"duck",@"elephant",@"duck"];
    XCTAssertEqualObjects(filtered,expected);
}

- (void)testThatItFiltersEmptyArray
{
    // given
    NSArray *array = @[];
    
    // when
    NSArray *filtered = [array filterWithBlock:^BOOL(id __unused obj) {
        return YES;
    }];
    
    // then
    XCTAssertEqual(filtered.count, 0u);
}


@end


@implementation FunctionalTests (NSArray_Set)

- (void)testThatItConvertsArrayIntoSet
{
    // given
    NSArray *words = @[@1, @2, @1, @3, @4, @1, @2];
    
    // when
    NSSet *wordsSet = words.set;
    
    // then
    NSSet *expected = [NSSet setWithObjects:@1, @2, @3, @4, nil];
    XCTAssertEqualObjects(wordsSet, expected);
}

- (void)testThatItConvertsArrayIntoOrderedSet
{
    // given
    NSArray *words = @[@2, @1, @3, @4, @1, @2];
    
    // when
    NSOrderedSet *wordsSet = words.orderedSet;
    
    // then
    NSOrderedSet *expected = [NSOrderedSet orderedSetWithObjects:@2, @1, @3, @4, nil];
    XCTAssertEqualObjects(wordsSet, expected);
}


@end


@implementation FunctionalTests (NSSet)

- (void)testThatSetMapsWithABlock
{
    // given
    NSSet *input = [NSSet setWithArray:@[@"a", @"b", @"c"]];
    
    // when
    NSSet *result = [input mapWithBlock:^(NSString *s) {
        return [s uppercaseString];
    }];
    
    // then
    NSSet *expected = [NSSet setWithArray:@[@"A", @"B", @"C"]];
    XCTAssertEqualObjects(result, expected);
}

- (void)testThatSetFiltersObjectByClass
{
    // given
    NSNumber *n1 = @1;
    NSNumber *n2 = @35;
    NSString *s1 = @"ciao";
    NSString *s2 = @"bip";
    
    NSSet *expectedStrings = [NSSet setWithObjects:s1, s2, nil];
    NSSet *expectedNumbers = [NSSet setWithObjects:n1, n2, nil];
    NSSet *testedSet = [NSSet setWithObjects:n1, s1, n2, s2, nil];
    
    // when
    NSSet *computedStrings = [testedSet objectsOfClass:NSString.class];
    NSSet *computedNumbers = [testedSet objectsOfClass:NSNumber.class];
    
    // then
    XCTAssertEqualObjects(expectedStrings, computedStrings);
    XCTAssertEqualObjects(expectedNumbers, computedNumbers);
}

@end



@implementation NSString (FunctionalTests)

- (id)functionalTests_map;
{
    if ([self isEqualToString:@"b"]) {
        return nil;
    } else {
        return self;
    }
}

@end
