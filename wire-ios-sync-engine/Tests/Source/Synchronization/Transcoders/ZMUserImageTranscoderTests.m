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


@import zimages;
@import MobileCoreServices;
@import ZMTransport;
@import ZMCMockTransport;
@import WireSyncEngine;
@import ZMCDataModel;
@import WireRequestStrategy;

#import "MessagingTest.h"
#import "ZMUserImageTranscoder.h"
#import "ZMUserImageTranscoder+Testing.h"


@interface ZMUserImageTranscoderTests : MessagingTest

@property (nonatomic) ZMUserImageTranscoder *sut;
@property (nonatomic) ZMUser *user1;
@property (nonatomic) NSOperationQueue *queue;
@property (nonatomic) NSUUID *user1ID;

@end


@implementation ZMUserImageTranscoderTests

- (void)setUp
{
    [super setUp];
    
    self.syncMOC.zm_userImageCache = [[UserImageLocalCache alloc] initWithLocation:nil];
    self.uiMOC.zm_userImageCache = self.syncMOC.zm_userImageCache;
    
    self.queue = [[NSOperationQueue alloc] init];
    self.queue.name = self.name;
    self.queue.maxConcurrentOperationCount = 1;
    
    self.sut = (id) [[ZMUserImageTranscoder alloc] initWithManagedObjectContext:self.syncMOC imageProcessingQueue:self.queue];
    WaitForAllGroupsToBeEmpty(0.5);
    
    self.user1ID = [NSUUID createUUID];
    [self.syncMOC performGroupedBlockAndWait:^{
        self.user1 = [ZMUser insertNewObjectInManagedObjectContext:self.syncMOC];
        self.user1.remoteIdentifier = self.user1ID;
    
        XCTAssert([self.syncMOC saveOrRollback]);
    }];
}

- (void)tearDown
{
    [self.sut tearDown];
    self.sut = nil;
    self.user1 = nil;
    self.user1ID = nil;
    [super tearDown];
}

@end



@implementation ZMUserImageTranscoderTests (DownloadPredicate)

- (void)testThatItMatchesUserWithoutALocalImage;
{
    [self.syncMOC performGroupedBlockAndWait:^{
        // given
        NSPredicate *p = [ZMUser predicateForMediumImageNeedingToBeUpdatedFromBackend];
        
        // when
        self.user1.mediumRemoteIdentifier = [NSUUID createUUID];
        self.user1.localMediumRemoteIdentifier = nil;

        // then
        XCTAssertTrue([p evaluateWithObject:self.user1]);
    }];
}

- (void)testThatItMatchesUserWithALocalImageAndNoRemoteImage
{
    [self.syncMOC performGroupedBlockAndWait:^{
        // given
        NSPredicate *p = [ZMUser predicateForMediumImageNeedingToBeUpdatedFromBackend];
        
        // when
        self.user1.mediumRemoteIdentifier = [NSUUID createUUID];
        self.user1.localMediumRemoteIdentifier = [NSUUID createUUID];
        
        // then
        XCTAssertTrue([p evaluateWithObject:self.user1]);
    }];
}



- (void)testThatItDoesNotMatchAUserWithNoLocalImageAndNoRemoteImage
{
    [self.syncMOC performGroupedBlockAndWait:^{
        // given
        NSPredicate *p = [ZMUser predicateForMediumImageNeedingToBeUpdatedFromBackend];
        
        // when
        self.user1.mediumRemoteIdentifier = nil;
        self.user1.localMediumRemoteIdentifier = nil;
        
        // then
        XCTAssertFalse([p evaluateWithObject:self.user1]);
    }];
}

- (void)testThatItDoesNotMatchAUserWithALocalImageButNoRemoteImage;
{
    [self.syncMOC performGroupedBlockAndWait:^{
        // given
        NSPredicate *p = [ZMUser predicateForMediumImageNeedingToBeUpdatedFromBackend];
        
        // when
        self.user1.mediumRemoteIdentifier = nil;
        self.user1.localMediumRemoteIdentifier = [NSUUID createUUID];
        
        // then
        XCTAssertFalse([p evaluateWithObject:self.user1]);
    }];
}

@end



@implementation ZMUserImageTranscoderTests (DownloadFilter)

- (void)testThatItDoesntFilterSelfUserWithALocalImageAndADifferentRemoteImage
{
    [self.syncMOC performGroupedBlockAndWait:^{
        // given
        NSPredicate *p = [ZMUser predicateForMediumImageDownloadFilter];
        
        // when
        ZMUser *selfUser = [ZMUser selfUserInContext:self.syncMOC];
        selfUser.remoteIdentifier = [NSUUID createUUID];
        selfUser.mediumRemoteIdentifier = [NSUUID createUUID];
        selfUser.localMediumRemoteIdentifier = [NSUUID createUUID];
        
        // then
        XCTAssertTrue([p evaluateWithObject:self.user1]);
    }];
}

- (void)testThatItFiltersSelfUserWithALocalImageAndTheSameRemoteImage
{
    [self.syncMOC performGroupedBlockAndWait:^{
        // given
        NSPredicate *p = [ZMUser predicateForMediumImageDownloadFilter];
        
        // when
        ZMUser *selfUser = [ZMUser selfUserInContext:self.syncMOC];
        selfUser.remoteIdentifier = [NSUUID createUUID];
        selfUser.mediumRemoteIdentifier = [NSUUID createUUID];
        selfUser.localMediumRemoteIdentifier = selfUser.mediumRemoteIdentifier;
        
        // then
        XCTAssertFalse([p evaluateWithObject:selfUser]);
    }];
}

- (void)testThatItFiltersAUserWithALocalImageWhichExistsInTheCache
{
    [self.syncMOC performGroupedBlockAndWait:^{
        // given
        NSPredicate *p = [ZMUser predicateForMediumImageDownloadFilter];
        
        // when
        self.user1.mediumRemoteIdentifier = [NSUUID createUUID];
        [self.user1 setImageMediumData:[@"data" dataUsingEncoding:NSUTF8StringEncoding]];
        
        // then
        XCTAssertFalse([p evaluateWithObject:self.user1]);
    }];
}

- (void)testThatItDoesntFiltersAUserWithoutALocalImageInTheCache
{
    [self.syncMOC performGroupedBlockAndWait:^{
        // given
        NSPredicate *p = [ZMUser predicateForMediumImageDownloadFilter];
        
        // when
        self.user1.mediumRemoteIdentifier = [NSUUID createUUID];
        
        // then
        XCTAssertTrue([p evaluateWithObject:self.user1]);
    }];
}

@end



@implementation ZMUserImageTranscoderTests (Requests)

- (void)testThatItGeneratesARequestWhenTheMediumSelfUserImageIsMissing
{
    // given
    NSUUID *imageID = [NSUUID createUUID];
    NSUUID *selfUserID = [NSUUID createUUID];
    __block ZMUser *selfUser = nil;
    [self.syncMOC performGroupedBlockAndWait:^{
        selfUser = [ZMUser selfUserInContext:self.syncMOC];
        selfUser.remoteIdentifier = selfUserID;
        selfUser.mediumRemoteIdentifier = imageID;
        selfUser.localMediumRemoteIdentifier = nil;
        selfUser.imageMediumData = nil;
        selfUser.localSmallProfileRemoteIdentifier = nil;
        selfUser.imageSmallProfileData = nil;
    }];
    
    // when
    __block ZMTransportRequest *request;
    [self.syncMOC performGroupedBlockAndWait:^{
        for (id<ZMContextChangeTracker> t in self.sut.contextChangeTrackers) {
            [t objectsDidChange:[NSSet setWithObject:selfUser]];
        }
        request = [self.sut.requestGenerators nextRequest];
    }];
    WaitForAllGroupsToBeEmpty(1);
    
    // then
    [self.syncMOC performGroupedBlockAndWait:^{
        XCTAssertNotNil(request);
        NSString *query = [@"?conv_id=" stringByAppendingString:selfUserID.transportString];
        NSString *path = [NSString pathWithComponents:@[@"/assets", imageID.transportString]];
        path = [path stringByAppendingString:query];
        XCTAssertEqualObjects(request.path, path);
    }];
}

- (void)testThatItGeneratesARequestWhenTheSmallSelfUserImageIsMissing
{
    // given
    NSUUID *imageID = [NSUUID createUUID];
    NSUUID *selfUserID = [NSUUID createUUID];
    __block ZMUser *selfUser = nil;
    [self.syncMOC performGroupedBlockAndWait:^{
        selfUser = [ZMUser selfUserInContext:self.syncMOC];
        selfUser.remoteIdentifier = selfUserID;
        selfUser.mediumRemoteIdentifier = nil;
        selfUser.localMediumRemoteIdentifier = nil;
        selfUser.imageMediumData = nil;
        selfUser.localSmallProfileRemoteIdentifier = nil;
        selfUser.imageSmallProfileData = nil;
        selfUser.smallProfileRemoteIdentifier = imageID;
    }];
    
    // when
    __block ZMTransportRequest *request;
    [self.syncMOC performGroupedBlockAndWait:^{
        for (id<ZMContextChangeTracker> t in self.sut.contextChangeTrackers) {
            [t objectsDidChange:[NSSet setWithObject:selfUser]];
        }
        request = [self.sut.requestGenerators nextRequest];
    }];
    WaitForAllGroupsToBeEmpty(1);
    
    // then
    [self.syncMOC performGroupedBlockAndWait:^{
        XCTAssertNotNil(request);
        NSString *query = [@"?conv_id=" stringByAppendingString:selfUserID.transportString];
        NSString *path = [NSString pathWithComponents:@[@"/assets", imageID.transportString]];
        path = [path stringByAppendingString:query];
        XCTAssertEqualObjects(request.path, path);
    }];
}

- (void)testThatItDoesntGeneratesARequestWhenAUserImageIsMissing
{
    // given
    NSUUID *imageID = [NSUUID createUUID];
    [self.syncMOC performGroupedBlockAndWait:^{
        self.user1.mediumRemoteIdentifier = imageID;
        self.user1.smallProfileRemoteIdentifier = imageID;
        self.user1.localMediumRemoteIdentifier = nil;
        self.user1.imageMediumData = nil;
        self.user1.localSmallProfileRemoteIdentifier = nil;
        self.user1.imageSmallProfileData = nil;
    }];
    
    // when
    __block ZMTransportRequest *request;
    [self.syncMOC performGroupedBlockAndWait:^{
        for (id<ZMContextChangeTracker> t in self.sut.contextChangeTrackers) {
            [t objectsDidChange:[NSSet setWithObject:self.user1]];
        }
        request = [self.sut.requestGenerators nextRequest];
    }];
    WaitForAllGroupsToBeEmpty(1);
    
    // then
    [self.syncMOC performGroupedBlockAndWait:^{
        XCTAssertNil(request);
    }];
}

- (void)testThatItGeneratesARequestWhenAUserImageIsMissingAndItHasBeenRequested
{
    // given
    NSUUID *imageID = [NSUUID createUUID];
    [self.syncMOC performGroupedBlockAndWait:^{
        self.user1.mediumRemoteIdentifier = imageID;
        self.user1.localMediumRemoteIdentifier = nil;
        self.user1.imageMediumData = nil;
        self.user1.localSmallProfileRemoteIdentifier = nil;
        self.user1.imageSmallProfileData = nil;
    }];
    
    // when
    [ZMUserImageTranscoder requestAssetForUserWithObjectID:self.user1.objectID];
    
    __block ZMTransportRequest *request;
    [self.syncMOC performGroupedBlockAndWait:^{
        for (id<ZMContextChangeTracker> t in self.sut.contextChangeTrackers) {
            [t objectsDidChange:[NSSet setWithObject:self.user1]];
        }
        request = [self.sut.requestGenerators nextRequest];
    }];
    WaitForAllGroupsToBeEmpty(1);
    
    // then
    [self.syncMOC performGroupedBlockAndWait:^{
        XCTAssertNotNil(request);
        NSString *query = [@"?conv_id=" stringByAppendingString:self.user1ID.transportString];
        NSString *path = [NSString pathWithComponents:@[@"/assets", imageID.transportString]];
        path = [path stringByAppendingString:query];
        XCTAssertEqualObjects(request.path, path);
    }];
}


- (void)testThatItGeneratesARequestForRetrievingASmallProfileUserImage;
{
    [self.syncMOC performGroupedBlockAndWait:^{
        // given
        NSUUID *imageID = [NSUUID createUUID];
        self.user1.smallProfileRemoteIdentifier = imageID;
        
        // when
        ZMTransportRequest *request = [self.sut requestForFetchingObject:self.user1 downstreamSync:self.sut.smallProfileDownstreamSync];
        
        // then
        XCTAssertEqual(request.method, ZMMethodGET);
        NSString *query = [@"?conv_id=" stringByAppendingString:self.user1ID.transportString];
        NSString *path = [NSString pathWithComponents:@[@"/assets", imageID.transportString]];
        path = [path stringByAppendingString:query];
        XCTAssertEqualObjects(request.path, path);
        XCTAssertEqual(request.acceptedResponseMediaTypes, ZMTransportAcceptImage);
        XCTAssertNil(request.payload);
    }];
}

- (void)testThatItGeneratesARequestForRetrievingAMediumUserImage;
{
    [self.syncMOC performGroupedBlockAndWait:^{
        // given
        NSUUID *imageID = [NSUUID createUUID];
        self.user1.mediumRemoteIdentifier = imageID;
        
        // when
        ZMTransportRequest *request = [self.sut requestForFetchingObject:self.user1 downstreamSync:self.sut.mediumDownstreamSync];
        
        // then
        XCTAssertEqual(request.method, ZMMethodGET);
        NSString *query = [@"?conv_id=" stringByAppendingString:self.user1ID.transportString];
        NSString *path = [NSString pathWithComponents:@[@"/assets", imageID.transportString]];
        path = [path stringByAppendingString:query];
        XCTAssertEqualObjects(request.path, path);
        XCTAssertEqual(request.acceptedResponseMediaTypes, ZMTransportAcceptImage);
        XCTAssertNil(request.payload);
    }];
}

- (void)testThatItUdpatesTheMediumImageFromAResponse;
{
    // TODO: There's a race condition here.
    // If the mediumRemoteIdentifier changes while we're retrieving image data
    // we'll still assume that the data is the newest. In order to fix that,
    // we would have to change the ZMDownloadTranscoder protocol such
    // that we can send the mediumRemoteIdentifier along the request and receive
    // it back with the response. This is similar to how the upstream sync works.
    
    [self.syncMOC performGroupedBlockAndWait:^{
        // given
        NSUUID *imageID = [NSUUID createUUID];
        self.user1.mediumRemoteIdentifier = imageID;
        self.user1.imageMediumData = nil;
        NSData *imageData = [self verySmallJPEGData];
        
        ZMTransportResponse *response = [[ZMTransportResponse alloc] initWithImageData:imageData HTTPStatus:200 transportSessionError:nil headers:@{}];
    
        // when
        [self.sut updateObject:self.user1 withResponse:response downstreamSync:self.sut.mediumDownstreamSync];
        
        // then
        XCTAssertEqualObjects(self.user1.imageMediumData, imageData);
        XCTAssertEqualObjects(self.user1.mediumRemoteIdentifier, imageID);
        XCTAssertEqualObjects(self.user1.localMediumRemoteIdentifier, imageID);
    }];
}


- (void)testThatItUdpatesTheSmallProfileImageFromAResponse;
{
    // TODO: There's a race condition here.
    // If the mediumRemoteIdentifier changes while we're retrieving image data
    // we'll still assume that the data is the newest. In order to fix that,
    // we would have to change the ZMDownloadTranscoder protocol such
    // that we can send the mediumRemoteIdentifier along the request and receive
    // it back with the response. This is similar to how the upstream sync works.
    
    [self.syncMOC performGroupedBlockAndWait:^{
        // given
        NSUUID *imageID = [NSUUID createUUID];
        self.user1.smallProfileRemoteIdentifier = imageID;
        self.user1.imageSmallProfileData = nil;
        NSData *imageData = [self verySmallJPEGData];
        ZMTransportResponse *response = [[ZMTransportResponse alloc] initWithImageData:imageData HTTPStatus:200 transportSessionError:nil headers:@{}];
        
        // when
        [self.sut updateObject:self.user1 withResponse:response downstreamSync:self.sut.smallProfileDownstreamSync];
        
        // then
        XCTAssertEqualObjects(self.user1.imageSmallProfileData, imageData);
        XCTAssertEqualObjects(self.user1.smallProfileRemoteIdentifier, imageID);
        XCTAssertEqualObjects(self.user1.localSmallProfileRemoteIdentifier, imageID);
    }];
}


@end




@implementation ZMUserImageTranscoderTests (ImagePreprocessing)


- (void)testThatSmallProfileImageAndMediumImageDataGetsGeneratedForNewlyUpdatedSelfUser;
{
    
    // given
    __block ZMUser *selfUser;
    [self.syncMOC performGroupedBlockAndWaitWithReasonableTimeout:^{
        selfUser = [ZMUser selfUserInContext:self.syncMOC];
        selfUser.originalProfileImageData = [self dataForResource:@"1900x1500" extension:@"jpg"];
        [self.sut.contextChangeTrackers[0] objectsDidChange:[NSSet setWithObject:selfUser]];
        
        XCTAssertEqual(selfUser.imageSmallProfileData.length, 0U);
        XCTAssertEqual(selfUser.imageMediumData.length, 0U);
    }];
    
    
    // when
    [self.syncMOC performBlockAndWait:^{
        (void) [self.sut.requestGenerators nextRequest];
    }];
    
    // then
    XCTAssert([self waitWithTimeout:0.5 forSaveOfContext:self.syncMOC untilBlock:^BOOL(){
        return selfUser.originalProfileImageData == nil;
    }]);
    
    
    [self.syncMOC performBlockAndWait:^{
        XCTAssertGreaterThan(selfUser.imageSmallProfileData.length, 0U);
        XCTAssertGreaterThan(selfUser.imageMediumData.length, 0U);
        XCTAssertNil(selfUser.originalProfileImageData);
    }];
}

@end



@implementation ZMUserImageTranscoderTests (ProfileImageUpload)


- (void)setUpSelfUser:(ZMUser **)selfUserP withRemoteID:(NSUUID *)remoteId formats:(NSArray *)formats locallyModifiedKeys:(NSArray *)locallyModifiedKeys
{
    // given
    __block ZMUser *selfUser;
    [self.syncMOC performGroupedBlockAndWaitWithReasonableTimeout:^{
        selfUser = [ZMUser selfUserInContext:self.syncMOC];
        selfUser.remoteIdentifier = remoteId;
        selfUser.imageCorrelationIdentifier = [NSUUID createUUID];
        
        for(NSNumber *boxedFormat in formats) {
            ZMImageFormat format = (ZMImageFormat) boxedFormat.integerValue;
            NSData *profileImageData;
            
            if (format == ZMImageFormatProfile) {
                profileImageData = [self dataForResource:@"tiny" extension:@"jpg"];
            }
            else if (format == ZMImageFormatMedium) {
                profileImageData = [self dataForResource:@"medium" extension:@"jpg"];
            }
            else {
                XCTFail(@"Unrecognized image format in test");
            }
            
            [selfUser setImageData:profileImageData forFormat:format properties:nil];
        }
        
        ZMConversation *selfConv = [ZMConversation insertNewObjectInManagedObjectContext:self.syncMOC];
        selfConv.conversationType = ZMConversationTypeSelf;
        selfConv.remoteIdentifier = remoteId;
        
        selfUser.needsToBeUpdatedFromBackend = NO;
        [selfUser setLocallyModifiedKeys:[NSSet setWithArray:locallyModifiedKeys]];
        
    }];
    
    XCTAssertFalse(selfUser.needsToBeUpdatedFromBackend);
    for (id<ZMContextChangeTracker> tracker in self.sut.contextChangeTrackers) {
        [tracker objectsDidChange:[NSSet setWithObject:selfUser]];
    }

    selfUser.originalProfileImageData = [self dataForResource:@"medium" extension:@"jpg"];
    *selfUserP = selfUser;
}


- (void)expectRequest:(ZMTransportRequest *)expectedRequest forSelfUser:(ZMUser *)selfUser format:(ZMImageFormat)format convID:(NSUUID *)conversationID handler:(void(^)(ZMTransportRequest *))handler
{
    __block ZMTransportRequest *request;
    [self.syncMOC performGroupedBlockAndWait:^{
        id assetRequestFactoryMock = [OCMockObject mockForClass:ZMAssetRequestFactory.class];
        [[[[assetRequestFactoryMock expect] classMethod]
          andReturn:expectedRequest] requestForImageOwner:selfUser
         format:format
         conversationID:conversationID
         correlationID:OCMOCK_ANY
         resultHandler:OCMOCK_ANY];
        
        // when
        request = [self.sut.requestGenerators nextRequest];

        // finally
        [assetRequestFactoryMock stopMocking];
    }];
    WaitForAllGroupsToBeEmpty(0.5);
    [self.syncMOC performGroupedBlockAndWait:^{
        // then
        handler(request);
    }];
}

- (void)checkImageUploadWithFormat:(ZMImageFormat)format modifiedKeys:(NSArray *)locallyModifiedKeys failureRecorder:(ZMTFailureRecorder *)failureRecorder
{
    // given
    ZMUser *selfUser;
    NSUUID *selfUserAndSelfConversationID = [NSUUID createUUID];
    [self setUpSelfUser:&selfUser withRemoteID:selfUserAndSelfConversationID formats:@[@(format)] locallyModifiedKeys:locallyModifiedKeys];

    // expect
    ZMTransportRequest *expectedRequest = [ZMTransportRequest requestGetFromPath:@"/TEST-SUCCESSFUL"];
    
    // then
    [self expectRequest:expectedRequest forSelfUser:selfUser format:format convID:selfUserAndSelfConversationID handler:^(ZMTransportRequest *request) {
        FHAssertTrue(failureRecorder, request != nil);
        FHAssertEqualObjects(failureRecorder, request, expectedRequest);
    }];

}


- (void)testThatItUploadsProfileImageDataToSelfConversation
{
    [self checkImageUploadWithFormat:ZMImageFormatProfile modifiedKeys:@[@"imageSmallProfileData"] failureRecorder:NewFailureRecorder()];
}


- (void)testThatItUploadsMediumImageDataToSelfConversation
{
    [self checkImageUploadWithFormat:ZMImageFormatMedium modifiedKeys:@[@"imageMediumData"] failureRecorder:NewFailureRecorder()];
}


- (void)testThatItSetsTheRemoteIdentifierForSmallProfile
{
    // given
    ZMUser *selfUser;
    NSUUID *selfUserAndSelfConversationID = [NSUUID createUUID];
    [self setUpSelfUser:&selfUser
           withRemoteID:selfUserAndSelfConversationID
                formats:@[@(ZMImageFormatProfile)]
    locallyModifiedKeys:@[@"imageSmallProfileData"]];

    NSUUID *imageID = [NSUUID createUUID];
    NSDictionary *smallProfileAsset = [ZMAssetMetaDataEncoder createAssetDataWithID:imageID imageOwner:selfUser format:ZMImageFormatProfile correlationID:selfUser.imageCorrelationIdentifier];
    
    // expect
    ZMTransportRequest *expectedSmallProfileRequest = [ZMTransportRequest requestGetFromPath:@"/small-profile-upload-request"];
    ZMTransportResponse *smallProfileResponse = [ZMTransportResponse responseWithPayload:@{@"data": smallProfileAsset} HTTPStatus:200 transportSessionError:nil];
    [self expectRequest:expectedSmallProfileRequest forSelfUser:selfUser format:ZMImageFormatProfile convID:selfUserAndSelfConversationID handler:^(ZMTransportRequest *request) {
        XCTAssertNotNil(request);
        XCTAssertEqual(request, expectedSmallProfileRequest);
        
        [request completeWithResponse:smallProfileResponse];
    }];
    
    // then
    [self.syncMOC performBlockAndWait:^{
        XCTAssertEqualObjects(selfUser.smallProfileRemoteIdentifier, imageID);
        XCTAssertEqualObjects(selfUser.localSmallProfileRemoteIdentifier, imageID);
        XCTAssertFalse([selfUser.keysThatHaveLocalModifications containsObject:@"smallProfileRemoteIdentifier_data"]);
        XCTAssertFalse([selfUser.keysThatHaveLocalModifications containsObject:@"imageSmallProfileData"]);
    }];
}



- (void)testThatItSetsTheRemoteIdentifierForMedium
{
    // given
    ZMUser *selfUser;
    NSUUID *selfUserAndSelfConversationID = [NSUUID createUUID];
    [self setUpSelfUser:&selfUser
           withRemoteID:selfUserAndSelfConversationID
                formats:@[@(ZMImageFormatMedium)]
    locallyModifiedKeys:@[@"imageMediumData"]];
    
    NSUUID *imageID = [NSUUID createUUID];
    NSDictionary *mediumAsset = [ZMAssetMetaDataEncoder createAssetDataWithID:imageID
                                                                   imageOwner:selfUser
                                                                       format:ZMImageFormatMedium
                                                                correlationID:selfUser.imageCorrelationIdentifier];
    
    // expect
    ZMTransportRequest *expectedMediumRequest = [ZMTransportRequest requestGetFromPath:@"/medium-upload-request"];
    ZMTransportResponse *mediumResponse = [ZMTransportResponse responseWithPayload:@{@"data": mediumAsset} HTTPStatus:200 transportSessionError:nil];
    [self expectRequest:expectedMediumRequest forSelfUser:selfUser format:ZMImageFormatMedium convID:selfUserAndSelfConversationID handler:^(ZMTransportRequest *request) {
        XCTAssertNotNil(request);
        XCTAssertEqual(request, expectedMediumRequest);
        
        [request completeWithResponse:mediumResponse];
    }];
    
    // then
    [self.syncMOC performBlockAndWait:^{
        XCTAssertEqualObjects(selfUser.mediumRemoteIdentifier, imageID);
        XCTAssertEqualObjects(selfUser.localMediumRemoteIdentifier, imageID);
        XCTAssertFalse([selfUser.keysThatHaveLocalModifications containsObject:@"mediumRemoteIdentifier_data"]);
        XCTAssertFalse([selfUser.keysThatHaveLocalModifications containsObject:@"imageMediumData"]);
    }];
    
}


- (void)testThatItRecoverFromInconsistenUserImageState
{
    // given
    NSSet *modifiedKeys = [NSSet setWithArray:@[@"imageMediumData", @"imageSmallProfileData"]];
    ZMUser *selfUser;
    NSUUID *selfUserAndSelfConversationID = [NSUUID createUUID];
    [self setUpSelfUser:&selfUser
           withRemoteID:selfUserAndSelfConversationID
                formats:@[@(ZMImageFormatProfile), @(ZMImageFormatMedium)]
    locallyModifiedKeys:modifiedKeys.allObjects];
    
    WaitForAllGroupsToBeEmpty(0.5);
    
    selfUser.imageMediumData = nil;
    selfUser.imageSmallProfileData = nil;
    
    XCTAssertTrue([selfUser hasLocalModificationsForKeys:modifiedKeys]);
    XCTAssertNil(selfUser.imageSmallProfileData);
    XCTAssertNil(selfUser.imageMediumData);

    // when
    ZMUserImageTranscoder __block *localSUT = [[ZMUserImageTranscoder alloc] initWithManagedObjectContext:self.syncMOC
                                                                                     imageProcessingQueue:self.queue];
    
    XCTAssertTrue([self waitForAllGroupsToBeEmptyWithTimeout:0.5]);
    
    // then
    [self.syncMOC performGroupedBlock:^{
        XCTAssertFalse([selfUser hasLocalModificationsForKeys:modifiedKeys]);
        [localSUT tearDown];
        localSUT = nil;
    }];
    
    WaitForAllGroupsToBeEmpty(0.5);
}

- (void)testThatItDoesNotUpdateTheImageIfTheCorrelationIDFromTheBackendResponseDiffersFromTheUserImageCorrelationID
{
    // given
    ZMUser *selfUser;
    NSUUID *selfUserAndSelfConversationID = [NSUUID createUUID];
    [self setUpSelfUser:&selfUser
           withRemoteID:selfUserAndSelfConversationID
                formats:@[@(ZMImageFormatProfile), @(ZMImageFormatMedium)]
    locallyModifiedKeys:@[@"imageMediumData", @"imageSmallProfileData"]];
    
    NSUUID *originalImageCorrelationIdentifier = selfUser.imageCorrelationIdentifier;
    
    NSUUID *imageID = [NSUUID createUUID];
    NSUUID *invalidCorrelationID = [NSUUID createUUID];
    NSDictionary *smallProfileAsset = [ZMAssetMetaDataEncoder createAssetDataWithID:imageID
                                                                         imageOwner:selfUser
                                                                             format:ZMImageFormatProfile
                                                                      correlationID:invalidCorrelationID];
    
    // expect
    ZMTransportRequest *expectedSmallProfileRequest = [ZMTransportRequest requestGetFromPath:@"/upload-request"];
    ZMTransportResponse *response = [ZMTransportResponse responseWithPayload:@{@"data": smallProfileAsset,
                                                                               @"id" : NSUUID.createUUID.transportString}
                                                                  HTTPStatus:200
                                                       transportSessionError:nil];
    
    [self expectRequest:expectedSmallProfileRequest
            forSelfUser:selfUser
                 format:ZMImageFormatProfile
                 convID:selfUserAndSelfConversationID
                handler:^(ZMTransportRequest *request) {
                    
                    XCTAssertNotNil(request);
                    XCTAssertEqual(request, expectedSmallProfileRequest);
                    
                    [request completeWithResponse:response];
                }];
    
    // then
    [self.syncMOC performBlockAndWait:^{
        XCTAssertEqualObjects(selfUser.imageCorrelationIdentifier, originalImageCorrelationIdentifier);
        XCTAssertNil(selfUser.smallProfileRemoteIdentifier);
        XCTAssertFalse([selfUser.keysThatHaveLocalModifications containsObject:@"mediumRemoteIdentifier_data"]);
    }];
    
}

- (void)testThatItMarksImageIdentifiersAsToBeUploadedAfterUploadingSmallProfileWhenBothImagesAreUploaded
{
    // given
    ZMUser *selfUser;
    NSUUID *selfUserAndSelfConversationID = [NSUUID createUUID];
    [self setUpSelfUser:&selfUser
           withRemoteID:selfUserAndSelfConversationID
                formats:@[@(ZMImageFormatProfile)]
    locallyModifiedKeys:@[@"imageSmallProfileData"]];
    
    NSUUID *imageID = [NSUUID createUUID];
    NSDictionary *smallProfileAsset = [ZMAssetMetaDataEncoder createAssetDataWithID:imageID imageOwner:selfUser format:ZMImageFormatProfile correlationID:selfUser.imageCorrelationIdentifier];
    [selfUser processingDidFinish];
    
    // expect
    ZMTransportRequest *expectedSmallProfileRequest = [ZMTransportRequest requestGetFromPath:@"/small-profile-upload-request"];
    ZMTransportResponse *smallProfileResponse = [ZMTransportResponse responseWithPayload:@{@"data": smallProfileAsset} HTTPStatus:200 transportSessionError:nil];
    [self expectRequest:expectedSmallProfileRequest forSelfUser:selfUser format:ZMImageFormatProfile convID:selfUserAndSelfConversationID handler:^(ZMTransportRequest *request) {
        XCTAssertNotNil(request);
        
        [request completeWithResponse:smallProfileResponse];
    }];
    
    // then
    [self.syncMOC performBlockAndWait:^{
        XCTAssertEqualObjects(selfUser.smallProfileRemoteIdentifier, imageID);
        XCTAssertEqualObjects(selfUser.localSmallProfileRemoteIdentifier, imageID);
        XCTAssertTrue([selfUser.keysThatHaveLocalModifications containsObject:@"smallProfileRemoteIdentifier_data"]);
        XCTAssertTrue([selfUser.keysThatHaveLocalModifications containsObject:@"mediumRemoteIdentifier_data"]);
        XCTAssertFalse([selfUser.keysThatHaveLocalModifications containsObject:@"imageSmallProfileData"]);
    }];
}

@end
