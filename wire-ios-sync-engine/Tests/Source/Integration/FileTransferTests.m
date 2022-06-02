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
@import WireMockTransport;
@import WireUtilities;
@import WireTesting;

#import "MessagingTest.h"
#import <WireSyncEngine/WireSyncEngine-Swift.h>
#import "Tests-Swift.h"
#import "ConversationTestsBase.h"

@interface FileTransferTests : ConversationTestsBase

@end

@implementation FileTransferTests

#pragma mark - Helper methods

- (NSURL *)testVideoFileURL
{
    NSBundle *bundle = [NSBundle bundleForClass:self.class];
    
    NSURL *url = [bundle URLForResource:@"video" withExtension:@"mp4"];
    if (nil == url) XCTFail("Unable to load video fixture from disk");
    return url;
}

- (NSArray *)filterOutRequestsForLastRead:(NSArray *)requests
{
    NSString *conversationPrefix = [NSString stringWithFormat:@"/conversations/%@/otr/messages",  [ZMConversation selfConversationInContext:self.userSession.managedObjectContext].remoteIdentifier.transportString];
    return [requests filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(id  obj, NSDictionary __unused *bindings) {
        return ![((ZMTransportRequest *)obj).path hasPrefix:conversationPrefix];
    }]];
}


#pragma mark - Asset V3

#pragma mark Sending

- (void)testThatItSendsATextMessageAfterAFileMessage
{
    //given
    XCTAssertTrue([self login]);
    
    ZMConversation *conversation = [self conversationForMockConversation:self.selfToUser1Conversation];
    XCTAssertNotNil(conversation);
    
    NSURL *fileURL = [self createTestFile:@"foo22cc"];
    
    // when
    __block ZMMessage *fileMessage;
    [self.userSession performChanges:^{
        fileMessage = (id)[conversation appendMessageWithFileMetadata:[[ZMFileMetadata alloc] initWithFileURL:fileURL thumbnail:nil]];
    }];
    WaitForAllGroupsToBeEmpty(0.5);
    
    __block ZMMessage *textMessage;
    [self.userSession performChanges:^{
        textMessage = (id)[conversation appendMessageWithText:@"foo22cc"];
    }];
    WaitForAllGroupsToBeEmpty(0.5);
    
    //then
    XCTAssertEqual(fileMessage.deliveryState, ZMDeliveryStateSent);
    //    XCTAssertEqual(fileMessage.fileMessageData.transferState, AssetTransferStateUploaded);
    XCTAssertEqual(textMessage.deliveryState, ZMDeliveryStateSent);
}

- (void)testThatItSendsAFileMessage_V3
{
    // given
    XCTAssertTrue([self login]);

    ZMConversation *conversation = [self conversationForMockConversation:self.selfToUser1Conversation];
    XCTAssertNotNil(conversation);
    [self prefetchRemoteClientByInsertingMessageInConversation:self.selfToUser1Conversation];

    NSURL *fileURL = [self createTestFile:@"foofile"];
    NSString *expectedMessageAddPath = [NSString stringWithFormat:@"/conversations/%@/otr/messages", conversation.remoteIdentifier.transportString];
    NSString *expectedAssetUploadPath = @"/assets/v3";

    // when
    [self.mockTransportSession resetReceivedRequests];

    __block ZMMessage *fileMessage;
    [self.userSession performChanges:^{
        fileMessage = (id)[conversation appendMessageWithFileMetadata:[[ZMFileMetadata alloc] initWithFileURL:fileURL thumbnail:nil]];
    }];
    WaitForAllGroupsToBeEmpty(0.5);

    // then
    XCTAssertEqual(fileMessage.deliveryState, ZMDeliveryStateSent);
    XCTAssertEqual(fileMessage.fileMessageData.downloadState, AssetDownloadStateDownloaded);

    NSArray <ZMTransportRequest *> *requests = [self filterOutRequestsForLastRead:self.mockTransportSession.receivedRequests];
    XCTAssertEqual(requests.count, 2lu); // Asset Upload (v3), Asset.Uploaded message
    ZMTransportRequest *fullAssetUploadRequest  = requests[0];
    ZMTransportRequest *fullAssetMessageRequest = requests[1];

    XCTAssertEqualObjects(fullAssetUploadRequest.path, expectedAssetUploadPath);
    XCTAssertEqualObjects(fullAssetMessageRequest.path, expectedMessageAddPath);

    ZMMessage *message = (ZMMessage *)conversation.lastMessage;

    XCTAssertNotNil(message.fileMessageData);
    XCTAssertNil(message.imageMessageData);
    XCTAssertEqualObjects(message.fileMessageData.filename.stringByDeletingPathExtension, @"foofile");
    XCTAssertEqualObjects(message.fileMessageData.filename.pathExtension, @"dat");
    XCTAssertEqual(message.fileMessageData.size, 256lu);
}

- (void)testThatItSendsNoneVideoFileMessage_withThumbnail_V3
{
    // given
    XCTAssertTrue([self login]);

    ZMConversation *conversation = [self conversationForMockConversation:self.selfToUser1Conversation];
    XCTAssertNotNil(conversation);

    [self prefetchRemoteClientByInsertingMessageInConversation:self.selfToUser1Conversation];

    NSURL *fileURL = [self createTestFile:@"foogile"];
    NSString *expectedMessageAddPath = [NSString stringWithFormat:@"/conversations/%@/otr/messages", conversation.remoteIdentifier.transportString];
    NSString *expectedAssetUploadPath = @"/assets/v3";

    // when
    [self.mockTransportSession resetReceivedRequests];

    __block ZMMessage *fileMessage;
    [self.userSession performChanges:^{
        fileMessage = (id)[conversation appendMessageWithFileMetadata:[[ZMFileMetadata alloc] initWithFileURL:fileURL thumbnail:self.mediumJPEGData]];
    }];
    WaitForAllGroupsToBeEmpty(0.5);

    // then
    XCTAssertEqual(fileMessage.deliveryState, ZMDeliveryStateSent);
    XCTAssertEqual(fileMessage.fileMessageData.transferState, AssetTransferStateUploaded);

    NSArray <ZMTransportRequest *> *requests = [self filterOutRequestsForLastRead:self.mockTransportSession.receivedRequests];
    XCTAssertEqual(requests.count, 3lu); // Thumbnail Upload, Full Asset Upload, Asset.Uploaded

    ZMTransportRequest *thumbnailAssetUploadRequest = requests[0];
    ZMTransportRequest *fullAssetUploadRequest      = requests[1];
    ZMTransportRequest *fullAssetMessageRequest     = requests[2];

    XCTAssertEqualObjects(fullAssetMessageRequest.path, expectedMessageAddPath);
    XCTAssertEqualObjects(thumbnailAssetUploadRequest.path, expectedAssetUploadPath);
    XCTAssertEqualObjects(fullAssetUploadRequest.path, expectedAssetUploadPath);

    ZMMessage *message = (ZMMessage *)conversation.lastMessage;

    XCTAssertNotNil(message.fileMessageData);
    XCTAssertNil(message.imageMessageData);
    XCTAssertEqualObjects(message.fileMessageData.filename.stringByDeletingPathExtension, @"foogile");
    XCTAssertEqualObjects(message.fileMessageData.filename.pathExtension, @"dat");
    XCTAssertEqual(message.fileMessageData.size, 256lu);
    
}

- (void)testThatItResendsAFailedFileMessage_V3
{
    // given
    XCTAssertTrue([self login]);

    [self prefetchRemoteClientByInsertingMessageInConversation:self.selfToUser1Conversation];

    ZMConversation *conversation = [self conversationForMockConversation:self.selfToUser1Conversation];
    XCTAssertNotNil(conversation);

    NSURL *fileURL = [self createTestFile:@"fooz"];

    self.mockTransportSession.responseGeneratorBlock = ^ZMTransportResponse *(ZMTransportRequest *request) {
        if ([request.path isEqualToString:@"/assets/v3"]) {
            return [ZMTransportResponse responseWithPayload:nil HTTPStatus:400 transportSessionError:nil apiVersion:0];
        }
        return nil;
    };

    // when
    __block ZMMessage *fileMessage;
    [self.userSession performChanges:^{
        fileMessage = (id)[conversation appendMessageWithFileMetadata:[[ZMFileMetadata alloc] initWithFileURL:fileURL thumbnail:nil]];
    }];
    WaitForAllGroupsToBeEmpty(1.0);

    // then
    XCTAssertEqual(fileMessage.deliveryState, ZMDeliveryStateFailedToSend);
    XCTAssertEqual(fileMessage.fileMessageData.transferState, AssetTransferStateUploadingFailed);

    // and when
    self.mockTransportSession.responseGeneratorBlock = nil;
    [self.userSession performChanges:^{
        [fileMessage resend];
    }];
    WaitForAllGroupsToBeEmpty(0.5);

    // then
    XCTAssertEqual(fileMessage.deliveryState, ZMDeliveryStateSent);
    XCTAssertEqual(fileMessage.fileMessageData.transferState, AssetTransferStateUploaded);
    
}

- (void)testThatItSendsATextMessageAfterAFileMessage_V3
{
    // given
    XCTAssertTrue([self login]);

    ZMConversation *conversation = [self conversationForMockConversation:self.selfToUser1Conversation];
    XCTAssertNotNil(conversation);

    NSURL *fileURL = [self createTestFile:@"foob"];

    // when
    __block ZMMessage *fileMessage;
    [self.userSession performChanges:^{
        fileMessage = (id)[conversation appendMessageWithFileMetadata:[[ZMFileMetadata alloc] initWithFileURL:fileURL thumbnail:nil]];
    }];
    WaitForAllGroupsToBeEmpty(0.5);

    __block ZMMessage *textMessage;
    [self.userSession performChanges:^{
        textMessage = (id)[conversation appendMessageWithText:self.name];
    }];
    WaitForAllGroupsToBeEmpty(0.5);

    // then
    XCTAssertEqual(fileMessage.deliveryState, ZMDeliveryStateSent);
    XCTAssertEqual(fileMessage.fileMessageData.transferState, AssetTransferStateUploaded);
    XCTAssertEqual(textMessage.deliveryState, ZMDeliveryStateSent);
    
}

- (void)testThatItDoesReuploadTheAssetMetadataAfterReceivingA_412_MissingClients_V3
{
    //given
    XCTAssertTrue([self login]);
    
    ZMConversation *conversation = [self conversationForMockConversation:self.selfToUser1Conversation];
    XCTAssertNotNil(conversation);

    NSURL *fileURL = [self createTestFile:@"foo2432"];

    // when
    __block ZMMessage *fileMessage;

    [self.mockTransportSession resetReceivedRequests];
    [self.userSession performChanges:^{
        fileMessage = (id)[conversation appendMessageWithFileMetadata:[[ZMFileMetadata alloc] initWithFileURL:fileURL thumbnail:nil]];
    }];
    WaitForAllGroupsToBeEmpty(0.5);

    //then
    XCTAssertEqual(fileMessage.deliveryState, ZMDeliveryStateSent);
    ZMMessage *message = (ZMMessage *)conversation.lastMessage;
    XCTAssertNotNil(message.fileMessageData);
    XCTAssertNil(message.imageMessageData);
}


#pragma mark Sending Video (Preview)

- (void)testThatItSendsAFileMessage_WithVideo_V3
{
    // given
    XCTAssertTrue([self login]);

    ZMConversation *conversation = [self conversationForMockConversation:self.selfToUser1Conversation];
    XCTAssertNotNil(conversation);

    [self prefetchRemoteClientByInsertingMessageInConversation:self.selfToUser1Conversation];

    NSURL *fileURL = self.testVideoFileURL;
    NSString *expectedMessageAddPath = [NSString stringWithFormat:@"/conversations/%@/otr/messages", conversation.remoteIdentifier.transportString];
    // Used for uploading the thumbnail and the full asset
    NSString *expectedAssetAddPath = @"/assets/v3";

    // when
    [self.mockTransportSession resetReceivedRequests];

    __block ZMMessage *fileMessage;
    [self.userSession performChanges:^{
        ZMVideoMetadata *metadata = [[ZMVideoMetadata alloc] initWithFileURL:fileURL thumbnail:self.mediumJPEGData];
        fileMessage = (id)[conversation appendMessageWithFileMetadata:metadata];
    }];
    WaitForAllGroupsToBeEmpty(0.5);

    // then
    XCTAssertEqual(fileMessage.deliveryState, ZMDeliveryStateSent);
    XCTAssertEqual(fileMessage.fileMessageData.transferState, AssetTransferStateUploaded);

    NSArray <ZMTransportRequest *> *requests = [self filterOutRequestsForLastRead:self.mockTransportSession.receivedRequests];

    //  Preview upload, Asset upload, generic message
    if (3 != requests.count) {
        return XCTFail(@"Wrong number of requests");
    }

    ZMTransportRequest *thumbnailRequest = requests[0];
    XCTAssertEqualObjects(thumbnailRequest.path, expectedAssetAddPath);

    ZMTransportRequest *fullAssetRequest = requests[1];
    XCTAssertEqualObjects(fullAssetRequest.path, expectedAssetAddPath);

    ZMTransportRequest *fullAssetGenericMessageRequest = requests[2];
    XCTAssertEqualObjects(fullAssetGenericMessageRequest.path, expectedMessageAddPath);

    ZMMessage *message = (ZMMessage *)conversation.lastMessage;

    XCTAssertNotNil(message.fileMessageData);
    XCTAssertNil(message.imageMessageData);
    XCTAssertEqualObjects(message.fileMessageData.filename.stringByDeletingPathExtension, @"video");
    XCTAssertEqualObjects(message.fileMessageData.filename.pathExtension, @"mp4");

    NSError *error = nil;
    NSUInteger size = [NSFileManager.defaultManager attributesOfItemAtPath:fileURL.path error:&error].fileSize;

    XCTAssertNil(error);
    XCTAssertEqual(message.fileMessageData.size, size);
    
}

- (void)testThatItSendsAFileMessage_WithVideo_Ephemeral_V3
{
    //given
    XCTAssertTrue([self login]);
    
    ZMConversation *conversation = [self conversationForMockConversation:self.selfToUser1Conversation];
    conversation.localMessageDestructionTimeout = 10;
    XCTAssertNotNil(conversation);
    
    [self prefetchRemoteClientByInsertingMessageInConversation:self.selfToUser1Conversation];
    
    NSURL *fileURL = self.testVideoFileURL;
    NSString *expectedMessageAddPath = [NSString stringWithFormat:@"/conversations/%@/otr/messages", conversation.remoteIdentifier.transportString];
    // Used for uploading the thumbnail and the full asset
    NSString *expectedAssetUploadPath = @"/assets/v3";
    
    // when
    [self.mockTransportSession resetReceivedRequests];
    
    __block ZMMessage *fileMessage;
    [self.userSession performChanges:^{
        fileMessage = (id)[conversation appendMessageWithFileMetadata:[[ZMVideoMetadata alloc] initWithFileURL:fileURL thumbnail:self.mediumJPEGData]];
    }];
    WaitForAllGroupsToBeEmpty(0.5);
    
    //then
    XCTAssertTrue(fileMessage.isEphemeral);
    XCTAssertEqual(fileMessage.deliveryState, ZMDeliveryStateSent);
    XCTAssertEqual(fileMessage.fileMessageData.downloadState, AssetDownloadStateDownloaded);
    
    NSArray <ZMTransportRequest *> *requests = [self filterOutRequestsForLastRead:self.mockTransportSession.receivedRequests];
    
    
    if (3 != requests.count) {
        return XCTFail(@"Wrong number of requests");
    }
    
    XCTAssertEqualObjects(requests[0].path, expectedAssetUploadPath);   // /assets/v3       (Preview)
    XCTAssertEqualObjects(requests[1].path, expectedAssetUploadPath);   // /assets/v3       (Medium)
    XCTAssertEqualObjects(requests[2].path, expectedMessageAddPath);    // /otr/messages    (Including Uploaded)
    
    ZMMessage *message = (ZMMessage *)conversation.lastMessage;
    
    XCTAssertNotNil(message.fileMessageData);
    XCTAssertNil(message.imageMessageData);
    XCTAssertEqualObjects(message.fileMessageData.filename.stringByDeletingPathExtension, @"video");
    XCTAssertEqualObjects(message.fileMessageData.filename.pathExtension, @"mp4");
    
    NSError *error = nil;
    NSUInteger size = [NSFileManager.defaultManager attributesOfItemAtPath:fileURL.path error:&error].fileSize;
    
    XCTAssertNil(error);
    XCTAssertEqual(message.fileMessageData.size, size);
}

- (void)testThatItResendsAFailedFileMessage_WithVideo_V3
{
    //given
    XCTAssertTrue([self login]);

    ZMConversation *conversation = [self conversationForMockConversation:self.selfToUser1Conversation];
    XCTAssertNotNil(conversation);

    NSURL *fileURL = self.testVideoFileURL;

    self.mockTransportSession.responseGeneratorBlock = ^ZMTransportResponse *(ZMTransportRequest *request) {
        // We fail the thumbnail asset upload
        if ([request.path isEqualToString:@"/assets/v3"]) {
            return [ZMTransportResponse responseWithPayload:nil HTTPStatus:400 transportSessionError:nil apiVersion:0];
        }
        return nil;
    };

    // when
    __block ZMMessage *fileMessage;
    [self.userSession performChanges:^{
        ZMVideoMetadata *metadata = [[ZMVideoMetadata alloc] initWithFileURL:fileURL thumbnail:self.mediumJPEGData];
        fileMessage = (id)[conversation appendMessageWithFileMetadata:metadata];
    }];
    WaitForAllGroupsToBeEmpty(0.5);

    // then
    XCTAssertEqual(fileMessage.deliveryState, ZMDeliveryStateFailedToSend);
    XCTAssertEqual(fileMessage.fileMessageData.transferState, AssetTransferStateUploadingFailed);

    // and when
    self.mockTransportSession.responseGeneratorBlock = nil;
    [self.userSession performChanges:^{
        [fileMessage resend];
    }];
    WaitForAllGroupsToBeEmpty(0.5);

    // then
    XCTAssertEqual(fileMessage.deliveryState, ZMDeliveryStateSent);
    XCTAssertEqual(fileMessage.fileMessageData.transferState, AssetTransferStateUploaded);
    XCTAssertEqualObjects(fileMessage.fileMessageData.filename.stringByDeletingPathExtension, @"video");
    XCTAssertEqualObjects(fileMessage.fileMessageData.filename.pathExtension, @"mp4");

    NSError *error = nil;
    NSUInteger size = [NSFileManager.defaultManager attributesOfItemAtPath:fileURL.path error:&error].fileSize;

    XCTAssertNil(error);
    XCTAssertEqual(fileMessage.fileMessageData.size, size);
}

- (void)testThatItResendsAFailedFileMessage_UploadingFullAssetFails_V3
{
    //given
    XCTAssertTrue([self login]);

    ZMConversation *conversation = [self conversationForMockConversation:self.selfToUser1Conversation];
    XCTAssertNotNil(conversation);

    NSURL *fileURL = self.testVideoFileURL;
    __block NSUInteger assetUploadCounter = 0;

    self.mockTransportSession.responseGeneratorBlock = ^ZMTransportResponse *(ZMTransportRequest *request) {
        // We fail the second post to `/assets/v3`, which is the upload of the full asset
        if ([request.path isEqualToString:@"/assets/v3"] && ++assetUploadCounter == 2) {
            return [ZMTransportResponse responseWithPayload:nil HTTPStatus:400 transportSessionError:nil apiVersion:0];
        }
        return nil;
    };

    // when
    __block ZMMessage *fileMessage;
    [self.userSession performChanges:^{
        ZMVideoMetadata *metadata = [[ZMVideoMetadata alloc] initWithFileURL:fileURL thumbnail:self.mediumJPEGData];
        fileMessage = (id)[conversation appendMessageWithFileMetadata:metadata];
    }];
    WaitForAllGroupsToBeEmpty(0.5);

    // then
    XCTAssertEqual(fileMessage.deliveryState, ZMDeliveryStateFailedToSend);
    XCTAssertEqual(fileMessage.fileMessageData.transferState, AssetTransferStateUploadingFailed);

    // and when
    self.mockTransportSession.responseGeneratorBlock = nil;
    [self.userSession performChanges:^{
        [fileMessage resend];
    }];
    WaitForAllGroupsToBeEmpty(0.5);

    //then
    XCTAssertEqual(fileMessage.deliveryState, ZMDeliveryStateSent);
    XCTAssertEqual(fileMessage.fileMessageData.transferState, AssetTransferStateUploaded);
    XCTAssertEqualObjects(fileMessage.fileMessageData.filename.stringByDeletingPathExtension, @"video");
    XCTAssertEqualObjects(fileMessage.fileMessageData.filename.pathExtension, @"mp4");

    NSError *error = nil;
    NSUInteger size = [NSFileManager.defaultManager attributesOfItemAtPath:fileURL.path error:&error].fileSize;

    XCTAssertNil(error);
    XCTAssertEqual(fileMessage.fileMessageData.size, size);
}

- (void)testThatItResendsAFailedFileMessage_UploadingFullAssetGenericMessageFails_V3
{
    //given
    XCTAssertTrue([self login]);

    ZMConversation *conversation = [self conversationForMockConversation:self.selfToUser1Conversation];
    XCTAssertNotNil(conversation);

    NSURL *fileURL = self.testVideoFileURL;
    NSString *genericMessagePath = [NSString stringWithFormat:@"/conversations/%@/otr/messages", conversation.remoteIdentifier.transportString];

    __block NSUInteger genericMessageUploadCount = 0;

    self.mockTransportSession.responseGeneratorBlock = ^ZMTransportResponse *(ZMTransportRequest *request) {
        // We fail the post to `/otr/messages`, which is the upload of the full asset generic message
        if ([request.path isEqualToString:genericMessagePath] && ++genericMessageUploadCount == 1) {
            return [ZMTransportResponse responseWithPayload:nil HTTPStatus:400 transportSessionError:nil apiVersion:0];
        }
        return nil;
    };

    // when
    __block ZMMessage *fileMessage;
    [self.userSession performChanges:^{
        ZMVideoMetadata *metadata = [[ZMVideoMetadata alloc] initWithFileURL:fileURL thumbnail:self.mediumJPEGData];
        fileMessage = (id)[conversation appendMessageWithFileMetadata:metadata];
    }];
    WaitForAllGroupsToBeEmpty(0.5);

    // then
    XCTAssertEqual(fileMessage.deliveryState, ZMDeliveryStateFailedToSend);
    XCTAssertEqual(fileMessage.fileMessageData.transferState, AssetTransferStateUploaded);

    // and when
    self.mockTransportSession.responseGeneratorBlock = nil;
    [self.userSession performChanges:^{
        [fileMessage resend];
    }];
    WaitForAllGroupsToBeEmpty(0.5);

    //then
    XCTAssertEqual(fileMessage.deliveryState, ZMDeliveryStateSent);
    XCTAssertEqual(fileMessage.fileMessageData.transferState, AssetTransferStateUploaded);
    XCTAssertEqualObjects(fileMessage.fileMessageData.filename.stringByDeletingPathExtension, @"video");
    XCTAssertEqualObjects(fileMessage.fileMessageData.filename.pathExtension, @"mp4");

    NSError *error = nil;
    NSUInteger size = [NSFileManager.defaultManager attributesOfItemAtPath:fileURL.path error:&error].fileSize;

    XCTAssertNil(error);
    XCTAssertEqual(fileMessage.fileMessageData.size, size);

}

- (void)testThatItDoesReuploadTheAssetMetadataAfterReceivingA_412_MissingClients_WithVideo_V3
{
    //given
    XCTAssertTrue([self login]);

    ZMConversation *conversation = [self conversationForMockConversation:self.selfToUser1Conversation];

    NSURL *fileURL = self.testVideoFileURL;

    // when
    __block ZMMessage *fileMessage;

    [self.mockTransportSession resetReceivedRequests];
    [self.userSession performChanges:^{
        ZMVideoMetadata *metadata = [[ZMVideoMetadata alloc] initWithFileURL:fileURL thumbnail:self.mediumJPEGData];
        fileMessage = (id)[conversation appendMessageWithFileMetadata:metadata];
    }];

    WaitForAllGroupsToBeEmpty(0.5);

    //then
    XCTAssertEqual(fileMessage.deliveryState, ZMDeliveryStateSent);
    XCTAssertEqual(fileMessage.fileMessageData.transferState, AssetTransferStateUploaded);    
    ZMMessage *message = (ZMMessage *)conversation.lastMessage;
    XCTAssertNotNil(message.fileMessageData);
    XCTAssertNil(message.imageMessageData);
}

- (void)testThatItSendsARegularFileMessageForAFileWithVideoButNilThumbnail_V3
{
    //given
    XCTAssertTrue([self login]);

    ZMConversation *conversation = [self conversationForMockConversation:self.selfToUser1Conversation];
    XCTAssertNotNil(conversation);

    [self prefetchRemoteClientByInsertingMessageInConversation:self.selfToUser1Conversation];

    NSURL *fileURL = self.testVideoFileURL; // Video URL
    NSString *expectedMessageAddPath = [NSString stringWithFormat:@"/conversations/%@/otr/messages", conversation.remoteIdentifier.transportString];
    NSString *expectedAssetAddPath = @"/assets/v3";

    // when
    [self.mockTransportSession resetReceivedRequests];

    __block ZMMessage *fileMessage;
    [self.userSession performChanges:^{
        ZMVideoMetadata *metadata = [[ZMVideoMetadata alloc] initWithFileURL:fileURL thumbnail:nil]; // No thumbnail
        fileMessage = (id)[conversation appendMessageWithFileMetadata:metadata];
    }];
    WaitForAllGroupsToBeEmpty(0.5);

    // then
    XCTAssertEqual(fileMessage.deliveryState, ZMDeliveryStateSent);
    XCTAssertEqual(fileMessage.fileMessageData.transferState, AssetTransferStateUploaded);

    NSArray <ZMTransportRequest *> *requests = [self filterOutRequestsForLastRead:self.mockTransportSession.receivedRequests];
    XCTAssertEqual(requests.count, 2lu); // Asset.Uploaded asset upload & Asset.Uploaded generic message

    ZMTransportRequest *uploadAssetRequest = requests[0];
    ZMTransportRequest *uploadMessageRequest = requests[1];

    XCTAssertEqualObjects(uploadAssetRequest.path, expectedAssetAddPath);
    XCTAssertEqualObjects(uploadMessageRequest.path, expectedMessageAddPath);

    ZMMessage *message = (ZMMessage *)conversation.lastMessage;

    XCTAssertNotNil(message.fileMessageData);
    XCTAssertNil(message.imageMessageData);
    XCTAssertEqualObjects(message.fileMessageData.filename.stringByDeletingPathExtension, @"video");
    XCTAssertEqualObjects(message.fileMessageData.filename.pathExtension, @"mp4");

    NSError *error = nil;
    NSUInteger size = [NSFileManager.defaultManager attributesOfItemAtPath:fileURL.path error:&error].fileSize;

    XCTAssertNil(error);
    XCTAssertEqual(message.fileMessageData.size, size);
    
}

@end
