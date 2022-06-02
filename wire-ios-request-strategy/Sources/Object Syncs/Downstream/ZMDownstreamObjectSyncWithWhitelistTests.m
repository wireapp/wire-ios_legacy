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

@import WireDataModel;
@import WireTransport;
@import WireTesting;

#import "MockEntity.h"
#import "MockModelObjectContextFactory.h"
#import "ZMDownstreamObjectSyncWithWhitelist+Internal.h"
#import "ZMChangeTrackerBootstrap+Testing.h"



@interface ZMDownstreamObjectSyncWithWhitelistTests : ZMTBaseTest

@property (nonatomic) NSManagedObjectContext *moc;
@property (nonatomic) id<ZMDownstreamTranscoder> transcoder;
@property (nonatomic) ZMDownstreamObjectSyncWithWhitelist *sut;
@property (nonatomic) ZMDownstreamObjectSyncWithWhitelist *sutWithRealTranscoder;

@property (nonatomic) NSPredicate *predicateForObjectsToDownload;
@property (nonatomic) NSPredicate *predicateForObjectsRequiringWhitelisting;
@end

@implementation ZMDownstreamObjectSyncWithWhitelistTests

- (void)setUp {
    [super setUp];
    
    self.moc = [MockModelObjectContextFactory testContext];
    self.transcoder = [OCMockObject niceMockForProtocol:@protocol(ZMDownstreamTranscoder)];
    
    [self verifyMockLater:self.transcoder];
    
    self.predicateForObjectsToDownload = [NSPredicate predicateWithFormat:@"needsToBeUpdatedFromBackend == YES"];
    self.sut = [[ZMDownstreamObjectSyncWithWhitelist alloc] initWithTranscoder:self.transcoder
                                                                    entityName:@"MockEntity"
                                                 predicateForObjectsToDownload:self.predicateForObjectsToDownload
                                                          managedObjectContext:self.moc];
    
    self.sutWithRealTranscoder = [[ZMDownstreamObjectSyncWithWhitelist alloc] initWithTranscoder:nil entityName:@"MockEntity" predicateForObjectsToDownload:self.predicateForObjectsToDownload managedObjectContext:self.moc];
}

- (void)tearDown {
    self.transcoder = nil;
    self.sut = nil;
    self.sutWithRealTranscoder = nil;
    self.predicateForObjectsToDownload = nil;
    self.predicateForObjectsRequiringWhitelisting = nil;
    [super tearDown];
}

- (void)makeSureFetchObjectsToDownloadHasBeenCalled;
{
    XCTAssertNil([self.sut nextRequestForAPIVersion:APIVersionV0], @"Make sure -fetchObjectsToDownload has been called.");
}

- (void)testThatOnNextRequestsItDoesNotCreateARequestWhenTheObjectIsNotWhiteListed;
{
    // given
    [self makeSureFetchObjectsToDownloadHasBeenCalled];
    MockEntity *entity = [MockEntity insertNewObjectInManagedObjectContext:self.moc];
    entity.needsToBeUpdatedFromBackend = YES;

    [self.sut objectsDidChange:[NSSet setWithObject:entity]];
    
    // expect
    [[(id)self.transcoder reject] requestForFetchingObject:OCMOCK_ANY downstreamSync:OCMOCK_ANY apiVersion:APIVersionV0];
    
    // when
    ZMTransportRequest *request = [self.sut nextRequestForAPIVersion:APIVersionV0];
    
    // then
    XCTAssertNil(request);
    [(id)self.transcoder verify];
}

- (void)testThatOnNextRequestsItDoesCreateARequestWhenTheObjectIsWhiteListed;
{
    // given
    [self makeSureFetchObjectsToDownloadHasBeenCalled];
    MockEntity *entity = [MockEntity insertNewObjectInManagedObjectContext:self.moc];
    entity.needsToBeUpdatedFromBackend = YES;
    [self.sut objectsDidChange:[NSSet setWithObject:entity]];
    
    ZMTransportRequest *dummyRequest = [ZMTransportRequest requestGetFromPath:@"dummy" apiVersion:APIVersionV0];
    
    // expect
    [[[(id)self.transcoder expect] andReturn:dummyRequest] requestForFetchingObject:entity downstreamSync:self.sut apiVersion:APIVersionV0];
    
    // when
    [self.sut whiteListObject:entity];
    ZMTransportRequest *request = [self.sut nextRequestForAPIVersion:APIVersionV0];
    
    // then
    XCTAssertEqualObjects(dummyRequest, request);
    [(id) self.transcoder verify];
}

- (void)testThatItAddsObjectsMatchingThePredicate
{
    // given
    MockEntity *entity = [MockEntity insertNewObjectInManagedObjectContext:self.moc];
    entity.needsToBeUpdatedFromBackend = YES;

    // when
    [self.sutWithRealTranscoder whiteListObject:entity];
    
    // then
    XCTAssertTrue([self.sutWithRealTranscoder.whitelist containsObject:entity]);
    XCTAssertTrue(self.sutWithRealTranscoder.hasOutstandingItems);
}

- (void)testThatItDoesNotRemoveAnObjectStillMatchingThePredicate
{
    // given
    MockEntity *entity = [MockEntity insertNewObjectInManagedObjectContext:self.moc];
    entity.needsToBeUpdatedFromBackend = YES;
    [self.sutWithRealTranscoder whiteListObject:entity];
    
    XCTAssertTrue([self.sutWithRealTranscoder.whitelist containsObject:entity]);
    XCTAssertTrue(self.sutWithRealTranscoder.innerDownstreamSync.hasOutstandingItems);
    
    // when
    entity.needsToBeUpdatedFromBackend = YES;
    [self.sutWithRealTranscoder objectsDidChange:[NSSet setWithObject:entity]];
    
    // then
    XCTAssertTrue([self.sutWithRealTranscoder.whitelist containsObject:entity]);
    XCTAssertTrue(self.sutWithRealTranscoder.hasOutstandingItems);
}

@end
