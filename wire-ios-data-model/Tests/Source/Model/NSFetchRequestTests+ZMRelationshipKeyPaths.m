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


#import "ZMBaseManagedObjectTest.h"
#import "NSFetchRequest+ZMRelationshipKeyPaths.h"



@interface NSFetchRequestTests_ZMRelationshipKeyPaths : ZMBaseManagedObjectTest
@end



@implementation NSFetchRequestTests_ZMRelationshipKeyPaths
@end



@implementation NSFetchRequestTests_ZMRelationshipKeyPaths (RelationshipPrefetching)

- (void)testThatItSetsRelationshipKeyPaths
{
    // given
    NSString *relationship = @"user";
    NSString *keyPath = [relationship stringByAppendingPathExtension:@"name"];
    
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"EntityName"];
    request.predicate = [NSPredicate predicateWithFormat:@"%K != nil", keyPath];
    
    // when
    [request configureRelationshipPrefetching];
    
    // then
    XCTAssertEqualObjects(request.relationshipKeyPathsForPrefetching, @[relationship]);
}

- (void)testThatItDoesNotSetSimpleProperties
{
    // given
    NSString *relationship = @"user";
    
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"EntityName"];
    request.predicate = [NSPredicate predicateWithFormat:@"%K != nil", relationship];
    
    // when
    [request configureRelationshipPrefetching];
    
    // then
    XCTAssertEqualObjects(request.relationshipKeyPathsForPrefetching, @[]);
}

- (void)testThatItSetsKeypathsForCompoundRequests
{
    // given
    NSString *relationship1 = @"user";
    NSString *relationship2 = @"conversation";

    NSString *keyPath1 = [relationship1 stringByAppendingPathExtension:@"name"];
    NSString *keyPath2 = [relationship2 stringByAppendingPathExtension:@"userDefinedName"];

    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"EntityName"];
    request.predicate = [NSPredicate predicateWithFormat:@"%K != nil AND %K != nil", keyPath1, keyPath2];
    
    // when
    [request configureRelationshipPrefetching];
    
    // then
    NSArray *expected = @[relationship1, relationship2];
    AssertArraysContainsSameObjects(request.relationshipKeyPathsForPrefetching, expected);
}

- (void)testThatItSetsAKeypathForTheSameEntityOnlyOnce_CompoundRequests
{
    // given
    NSString *relationship = @"user";
    
    NSString *keyPath1 = [relationship stringByAppendingPathExtension:@"name"];
    NSString *keyPath2 = [relationship stringByAppendingPathExtension:@"age"];
    
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"EntityName"];
    request.predicate = [NSPredicate predicateWithFormat:@"%K != nil AND %K != nil", keyPath1, keyPath2];
    
    // when
    [request configureRelationshipPrefetching];
    
    // then
    XCTAssertEqualObjects(request.relationshipKeyPathsForPrefetching, @[relationship]);
}

- (void)testThatItSetsKeyPathsForComparisonPredicates
{
    // given
    NSString *relationship1 = @"foo1";
    NSString *relationship2 = @"foo2";

    NSString *keyPath1 = [relationship1 stringByAppendingPathExtension:@"bar1"];
    NSString *keyPath2 = [relationship2 stringByAppendingPathExtension:@"bar2"];
    
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"EntityName"];
    request.predicate = [NSPredicate predicateWithFormat:@"%K > %K", keyPath1, keyPath2];
    
    // when
    [request configureRelationshipPrefetching];
    
    // then
    NSArray *expected = @[relationship1, relationship2];
    AssertArraysContainsSameObjects(request.relationshipKeyPathsForPrefetching, expected);
}

- (void)testThatItSetsKeyPathForTheSameEntityOnlyOnce_ComparisonPredicates
{
    // given
    NSString *relationship = @"foo";
    
    NSString *keyPath1 = [relationship stringByAppendingPathExtension:@"bar1"];
    NSString *keyPath2 = [relationship stringByAppendingPathExtension:@"bar2"];
    
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"EntityName"];
    request.predicate = [NSPredicate predicateWithFormat:@"%K > %K", keyPath1, keyPath2];
    
    // when
    [request configureRelationshipPrefetching];
    
    // then
    XCTAssertEqualObjects(request.relationshipKeyPathsForPrefetching, @[relationship]);
}

- (void)testThatItDoesNotSetSimpleProperties_ComparisonPredicates
{
    // given
    NSString *relationship1 = @"foo1";
    NSString *relationship2 = @"foo2";
    
    NSString *keyPath1 = [relationship1 stringByAppendingPathExtension:@"bar"];
    
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"EntityName"];
    request.predicate = [NSPredicate predicateWithFormat:@"%K > %K", keyPath1, relationship2];
    
    // when
    [request configureRelationshipPrefetching];
    
    // then
    XCTAssertEqualObjects(request.relationshipKeyPathsForPrefetching, @[relationship1]);
}

- (void)testThatItSetsRelationshipsForComplexPredicatesCorrectly
{
    // given
    NSString *relationship1 = @"user";
    NSString *relationship2 = @"conversation.localParticipants";
    
    NSString *keyPath1 = [relationship1 stringByAppendingPathExtension:@"name"];
    NSString *keyPath2 = [relationship2 stringByAppendingPathExtension:@"name"];

    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"EntityName"];
    request.predicate = [NSPredicate predicateWithFormat:@"(%K == nil) AND (ANY %K CONTAINS %K)",
                         keyPath1,
                         keyPath2, keyPath1];
    
    // when
    [request configureRelationshipPrefetching];
    
    // then
    NSArray *expected = @[relationship1, relationship2];
    AssertArraysContainsSameObjects(request.relationshipKeyPathsForPrefetching, expected);
}

- (void)testThatItDoesNotCrashWhenConfiguringOnNilPredicate
{
    // given
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"EntityName"];
    
    // when
    [request configureRelationshipPrefetching];
    
    // then
    XCTAssertEqualObjects(request.relationshipKeyPathsForPrefetching, @[]);
}

@end



@implementation NSFetchRequestTests_ZMRelationshipKeyPaths (AllKeyPathsInPredicate)

- (void)testThatItReturnsRelationshipKeyPaths
{
    // given
    NSString *keyPath = @"user.name";
    
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"EntityName"];
    request.predicate = [NSPredicate predicateWithFormat:@"%K != nil", keyPath];
    
    // then
    XCTAssertEqualObjects([request allKeyPathsInPredicate], [NSSet setWithObject:keyPath]);
}

- (void)testThatItReturnsSimpleProperties
{
    // given
    NSString *relationship = @"user";
    
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"EntityName"];
    request.predicate = [NSPredicate predicateWithFormat:@"%K != nil", relationship];
    
    // then
    XCTAssertEqualObjects([request allKeyPathsInPredicate], [NSSet setWithObject:relationship]);
}

- (void)testThatItReturnsKeypathsForCompoundRequests
{
    // given
    NSString *keyPath1 = @"user.name";
    NSString *keyPath2 = @"conversation.userDefinedName";
    
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"EntityName"];
    request.predicate = [NSPredicate predicateWithFormat:@"%K != nil AND %K != nil", keyPath1, keyPath2];
    
    // then
    NSSet *expected = [NSSet setWithObjects:keyPath1, keyPath2, nil];
    XCTAssertEqualObjects([request allKeyPathsInPredicate], expected);
}

- (void)testThatItReturnsKeyPathsForComparisonPredicates
{
    // given
    NSString *keyPath1 = @"foo1.bar1";
    NSString *keyPath2 = @"foo2.bar2";
    
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"EntityName"];
    request.predicate = [NSPredicate predicateWithFormat:@"%K > %K", keyPath1, keyPath2];
    
    // then
    NSSet *expected = [NSSet setWithObjects:keyPath1, keyPath2, nil];
    XCTAssertEqualObjects([request allKeyPathsInPredicate], expected);
}

- (void)testThatItReturnsRelationshipsForComplexPredicatesCorrectly
{
    // given
    NSString *keyPath1 = @"user.name";
    NSString *keyPath2 = @"conversation.localParticipants.name";
    
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"EntityName"];
    request.predicate = [NSPredicate predicateWithFormat:@"(%K == nil) AND (ANY %K CONTAINS %K)",
                         keyPath1,
                         keyPath2, keyPath1];
    
    // then
    NSSet *expected = [NSSet setWithObjects:keyPath1, keyPath2, nil];
    XCTAssertEqualObjects([request allKeyPathsInPredicate], expected);
}

- (void)testThatItDoesNotCrashWhenCallingOnNilPredicate
{
    // given
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"EntityName"];
    
    // then
    XCTAssertEqualObjects([request allKeyPathsInPredicate], [NSSet set]);
}

@end
