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


@import WireTransport;
@import XCTest;
@import WireTesting;

@interface Collections_ZMTSafeTypesTests : XCTestCase

@end

@implementation Collections_ZMTSafeTypesTests

- (NSDictionary *)sampleDictionary {
    return @{
         @"string" : @"bar",
         @"number" : @(3),
         @"array_of_strings" : @[@"a",@"b"],
         @"dictionary" : @{ @"a":@"b"},
         @"date" : @"1437654971",
         @"data" : [NSData data],
         @"uuid" : @"1f7481fc-61ca-45f5-8dfb-5a27627a3539",
         @"event" : @"3d.8001123143087a8d"
    };
}

- (void)testThatItDoesNotThrowAnErrorForNSNull
{
    NSDictionary *sample = @{@"null" : [NSNull null]};
    id result = [sample optionalStringForKey:@"null"];
    XCTAssertNil(result);
}

- (void)testThatItReadsAString {
    NSString *key = @"string";
    XCTAssertEqualObjects(self.sampleDictionary[key], [self.sampleDictionary stringForKey:key]);
    XCTAssertEqualObjects(self.sampleDictionary[key], [self.sampleDictionary optionalStringForKey:key]);
    XCTAssertNil([self.sampleDictionary stringForKey:@"baz"]);
    XCTAssertNil([self.sampleDictionary optionalStringForKey:@"baz"]);
    XCTAssertNil([self.sampleDictionary stringForKey:@"number"]);
    XCTAssertNil([self.sampleDictionary optionalStringForKey:@"number"]);
}

- (void)testThatItReadsANumber {
    NSString *key = @"number";
    XCTAssertEqualObjects(self.sampleDictionary[key], [self.sampleDictionary numberForKey:key]);
    XCTAssertEqualObjects(self.sampleDictionary[key], [self.sampleDictionary optionalNumberForKey:key]);
    XCTAssertNil([self.sampleDictionary numberForKey:@"baz"]);
    XCTAssertNil([self.sampleDictionary optionalNumberForKey:@"baz"]);
    XCTAssertNil([self.sampleDictionary numberForKey:@"string"]);
    XCTAssertNil([self.sampleDictionary optionalNumberForKey:@"string"]);
}

- (void)testThatItReadsAnArray {
    NSString *key = @"array_of_strings";
    XCTAssertEqualObjects(self.sampleDictionary[key], [self.sampleDictionary arrayForKey:key]);
    XCTAssertEqualObjects(self.sampleDictionary[key], [self.sampleDictionary optionalArrayForKey:key]);
    XCTAssertNil([self.sampleDictionary arrayForKey:@"baz"]);
    XCTAssertNil([self.sampleDictionary optionalArrayForKey:@"baz"]);
    XCTAssertNil([self.sampleDictionary arrayForKey:@"number"]);
    XCTAssertNil([self.sampleDictionary optionalArrayForKey:@"number"]);
}

- (void)testThatItReadsData {
    NSString *key = @"data";
    XCTAssertEqualObjects(self.sampleDictionary[key], [self.sampleDictionary dataForKey:key]);
    XCTAssertNil([self.sampleDictionary dataForKey:@"baz"]);
    XCTAssertNil([self.sampleDictionary dataForKey:@"string"]);
}

- (void)testThatItReadsADate {
    NSString *key = @"date";
    XCTAssertEqualObjects([NSDate dateWithTransportString:self.sampleDictionary[key]], [self.sampleDictionary dateFor:key]);
    XCTAssertNil([self.sampleDictionary dateFor:@"baz"]);
    XCTAssertNil([self.sampleDictionary dateFor:@"string"]);
}

- (void)testThatItReadsAUUID {
    NSString *key = @"uuid";
    XCTAssertEqualObjects([NSUUID uuidWithTransportString:self.sampleDictionary[key]], [self.sampleDictionary uuidForKey:key]);
    XCTAssertEqualObjects([NSUUID uuidWithTransportString:self.sampleDictionary[key]], [self.sampleDictionary optionalUuidForKey:key]);
    XCTAssertNil([self.sampleDictionary uuidForKey:@"baz"]);
    XCTAssertNil([self.sampleDictionary optionalUuidForKey:@"baz"]);
    XCTAssertNil([self.sampleDictionary uuidForKey:@"string"]);
    XCTAssertNil([self.sampleDictionary optionalUuidForKey:@"string"]);
}

- (void)testThatItReadsADictionary {
    NSString *key = @"dictionary";
    XCTAssertEqualObjects(self.sampleDictionary[key], [self.sampleDictionary dictionaryForKey:key]);
    XCTAssertEqualObjects(self.sampleDictionary[key], [self.sampleDictionary optionalDictionaryForKey:key]);
    XCTAssertNil([self.sampleDictionary dictionaryForKey:@"baz"]);
    XCTAssertNil([self.sampleDictionary optionalDictionaryForKey:@"baz"]);
    XCTAssertNil([self.sampleDictionary dictionaryForKey:@"number"]);
    XCTAssertNil([self.sampleDictionary optionalDictionaryForKey:@"number"]);
}

- (void)testThatItConvertsArrayToDictionaries {
    NSArray *arrayOfDictionaries = @[@{@"a":@"b"}, @{@"c":@"d"}];
    NSDictionary *dict = @{@"a":@"b"};
    NSArray *arrayMixed = @[@"foo",@[@(1),@(2)],dict];
    NSArray *arrayNone = @[@"foo",@[@(1),@(2)]];
    XCTAssertEqualObjects(arrayOfDictionaries, [arrayOfDictionaries asDictionaries]);
    XCTAssertEqualObjects(@[dict], [arrayMixed asDictionaries]);
    XCTAssertEqualObjects(@[], [arrayNone asDictionaries]);
}


- (void)testStringFromKeyPositive
{
    // given
    NSDictionary *dict = @{ @"foo" : @"giraffe" };
    
    // when
    id value = [dict stringForKey:@"foo"];
    
    // then
    XCTAssertNotNil(value);
    XCTAssertEqualObjects(value, @"giraffe");
}

- (void)testStringFromKeyWrongType
{
    // given
    NSDictionary *dict = @{ @"foo" : @2 };
    
    // when
    id value = [dict stringForKey:@"foo"];
    
    // then
    XCTAssertNil(value);
}

- (void)testStringFromKeyMissing
{
    // given
    NSDictionary *dict = @{ };
    
    // when
    id value = [dict stringForKey:@"bar"];
    
    // then
    XCTAssertNil(value);
}

- (void)testDictionaryFromKeyPositive
{
    // given
    NSDictionary *inner = @{ @"inner" : @"dict" };
    NSDictionary *dict = @{ @"foo" : inner };
    
    // when
    id value = [dict dictionaryForKey:@"foo"];
    
    // then
    XCTAssertNotNil(value);
    XCTAssertEqualObjects(value, inner);
}

- (void)testDictionaryFromKeyWrongType
{
    // given
    NSDictionary *dict = @{ };
    
    // when
    id value = [dict dictionaryForKey:@"foo"];
    
    // then
    XCTAssertNil(value);
}

- (void)testDictionaryFromKeyMissing
{
    // given
    NSDictionary *dict = @{ };
    
    // when
    id value = [dict dictionaryForKey:@"bar"];
    
    // then
    XCTAssertNil(value);
}

- (void)testArrayFromKeyPositive
{
    // given
    NSArray *array = @[ @3, @5 ];
    NSDictionary *dict = @{ @"foo" : array };
    
    // when
    id value = [dict arrayForKey:@"foo"];
    
    // then
    XCTAssertNotNil(value);
    XCTAssertEqualObjects(value, array);
}

- (void)testArrayFromKeyWrongType
{
    // given
    NSDictionary *dict = @{ @"foo" : @2 };
    
    // when
    id value = [dict arrayForKey:@"foo"];
    
    // then
    XCTAssertNil(value);
}

- (void)testArrayFromKeyMissing
{
    // given
    NSDictionary *dict = @{ };
    
    // when
    id value = [dict arrayForKey:@"bar"];
    
    // then
    XCTAssertNil(value);
}

- (void)testOptionalNumberMissing
{
    // given
    NSDictionary *dict = @{ @"foo": [NSNull null] };
    
    // when
    id value = [dict optionalNumberForKey:@"foo"];
    id value2 = [dict optionalNumberForKey:@"non-existing"];
    
    // then
    XCTAssertNil(value);
    XCTAssertNil(value2);
}

- (void)testOptionalNumberFromKeyPositive
{
    // given
    NSNumber *testValue = @3435;
    NSDictionary *dict = @{ @"foo" : testValue };
    
    // when
    id value = [dict optionalNumberForKey:@"foo"];
    
    // then
    XCTAssertNotNil(value);
    XCTAssertEqualObjects(value, testValue);
}

- (void)testNumberFromKeyPositive
{
    // given
    NSNumber *testValue = @3435;
    NSDictionary *dict = @{ @"foo" : testValue };
    
    // when
    id value = [dict numberForKey:@"foo"];
    
    // then
    XCTAssertNotNil(value);
    XCTAssertEqualObjects(value, testValue);
}

- (void)testNumberFromKeyWrongType
{
    // given
    NSDictionary *dict = @{ @"foo" : @"fff" };
    
    // when
    id value = [dict numberForKey:@"foo"];
    
    // then
    XCTAssertNil(value);
}

- (void)testNumberFromKeyMissing
{
    // given
    NSDictionary *dict = @{ };
    
    // when
    id value = [dict numberForKey:@"bar"];
    
    // then
    XCTAssertNil(value);

}

- (void)testUUIDFromKeyWithUUIDString
{
    // given
    NSUUID *testValue = [NSUUID UUID];
    NSDictionary *dict = @{ @"foo" : [testValue UUIDString] };
    
    // when
    id value = [dict uuidForKey:@"foo"];
    
    // then
    XCTAssertNotNil(value);
    XCTAssertEqualObjects(value, testValue);
}

- (void)testUUIDFromKeyWithUUID
{
    // given
    NSUUID *testValue = [NSUUID UUID];
    NSDictionary *dict = @{ @"foo" : testValue };
    
    // when
    id value = [dict uuidForKey:@"foo"];
    
    // then
    XCTAssertNotNil(value);
    XCTAssertEqualObjects(value, testValue);
}

- (void)testUUIDFromKeyWithInvalidString
{
    // given
    NSDictionary *dict = @{ @"foo" : @"dog" };
    
    // when
    id value = [dict uuidForKey:@"foo"];
    
    // then
    XCTAssertNil(value);
}

- (void)testUUIDFromKeyWrongType
{
    // given
    NSDictionary *dict = @{ @"foo" : @3 };
    
    // when
    id value = [dict uuidForKey:@"foo"];
    
    // then
    XCTAssertNil(value);
}

- (void)testUUIDFromKeyMissing
{
    // given
    NSDictionary *dict = @{ };
    
    // when
    id value = [dict uuidForKey:@"bar"];
    
    // then
    XCTAssertNil(value);
}

- (void)testAsDictionaries
{
    // given
    NSDictionary *d1 = @{@"boo": @556};
    NSDictionary *d2 = @{@"foo": @"blurp"};
    NSArray *array = @[ @3, @"fdsf", d1, @54, @[], d2];
    
    // when
    NSArray *values = [array asDictionaries];
    
    // then
    XCTAssertEqual(2u, values.count);
    XCTAssertEqualObjects(values[0], d1);
    XCTAssertEqualObjects(values[1], d2);
}

- (void)testDateFromKeyWithDateString
{
    // given
    NSString *dateString = @"2014-04-30T16:30:16.625Z";
    NSDate *testValue = [NSDate dateWithTransportString:dateString];
    NSDictionary *dict = @{ @"foo" : dateString };
    
    // when
//    id value = [dict optionaldateFor:@"foo"]; ///TODO: optional?
    id value = [dict dateFor:@"foo"]; ///TODO: can not jump in?
//    id value = [

    // then
    XCTAssertNotNil(value);
//    XCTAssertNotNil(value);
    XCTAssertEqualObjects(value, testValue);
}

- (void)testDateFromKeyWithDate
{
    // given
    NSString *dateString = @"2014-04-30T16:30:16.625Z";
    NSDate *testValue = [NSDate dateWithTransportString:dateString];
    NSDictionary *dict = @{ @"foo" : testValue };
    
    // when
    id value = [dict dateFor:@"foo"];
    
    // then
    XCTAssertNotNil(value);
    XCTAssertEqualObjects(value, testValue);
}

- (void)testDateFromKeyWithInvalidString
{
    // given
    NSDictionary *dict = @{ @"foo" : @"dog" };
    
    // when
    id value = [dict dateFor:@"foo"];
    
    // then
    XCTAssertNil(value);
}

- (void)testDateFromKeyWrongType
{
    // given
    NSDictionary *dict = @{ @"foo" : @3 };
    
    // when
    id value = [dict dateFor:@"foo"];
    
    // then
    XCTAssertNil(value);
}

- (void)testDateFromKeyMissing
{
    // given
    NSDictionary *dict = @{ };
    
    // when
    id value = [dict dateFor:@"bar"];
    
    // then
    XCTAssertNil(value);
}


@end
