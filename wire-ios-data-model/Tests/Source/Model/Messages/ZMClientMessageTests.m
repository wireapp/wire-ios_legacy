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


#import "ZMMessageTests.h"
#import "MessagingTest+EventFactory.h"
#import "ZMMessage+Internal.h"
#import "ZMUser+Internal.h"
#import "NSString+RandomString.h"
#import "WireDataModelTests-Swift.h"
#import <WireDataModel/WireDataModel-Swift.h>

@import CoreGraphics;
@import WireLinkPreview;
@import WireDataModel;

@interface ZMClientMessageTests : BaseZMMessageTests
@end

@implementation ZMClientMessageTests
- (void)testThatItStoresClientAsMissing
{
    UserClient *client = [self createSelfClient];
    ZMClientMessage *message = [self createClientTextMessage];
    [message missesRecipient:client];

    XCTAssertEqualObjects(message.missingRecipients, [NSSet setWithObject:client]);
}

- (void)testThatItRemovesMissingClient
{
    UserClient *client = [self createSelfClient];
    ZMClientMessage *message = [self createClientTextMessage];
    [message missesRecipient:client];

    XCTAssertEqualObjects(message.missingRecipients, [NSSet setWithObject:client]);

    [message doesNotMissRecipient:client];

    XCTAssertEqual(message.missingRecipients.count, 0u);
}


- (void)testThatClientMessageIsMarkedAsDelivered
{
    ZMClientMessage *message = [self createClientTextMessage];
    [message setExpirationDate];

    [message markAsSent];
    XCTAssertTrue(message.delivered);
    XCTAssertFalse(message.isExpired);
}

- (void)testThatResendingClientMessageResetsExpirationDate
{
    ZMClientMessage *message = [self createClientTextMessage];

    [message resend];
    XCTAssertNotNil(message.expirationDate);
}

- (void)testThatItSetsLocallyModifiedKeysWhenLinkPreviewStateIsSet
{
    int16_t states[] = {
        ZMLinkPreviewStateWaitingToBeProcessed,
        ZMLinkPreviewStateDownloaded,
        ZMLinkPreviewStateProcessed ,
        ZMLinkPreviewStateUploaded,
        ZMLinkPreviewStateDone
    };
    
    for (unsigned long i = 0; i < sizeof(states) / sizeof(ZMLinkPreviewState); i++) {
        [self assertThatItSetsLocallyModifiedKeysWhenLinkPreviewStateIsSet:states[i] shouldSet:states[i] != ZMLinkPreviewStateDone];
    }
}

- (void)assertThatItSetsLocallyModifiedKeysWhenLinkPreviewStateIsSet:(ZMLinkPreviewState)state shouldSet:(BOOL)shouldSet
{
    // given
    ZMClientMessage *message = [self createClientTextMessage];
    XCTAssertFalse([message.keysThatHaveLocalModifications containsObject:ZMClientMessage.linkPreviewStateKey]);

    // when
    message.linkPreviewState = state;

    // then
    XCTAssertEqual([message.keysThatHaveLocalModifications containsObject:ZMClientMessage.linkPreviewStateKey], shouldSet);
}

- (void)testThatAInsertedClientMessageHasADefaultLinkPreviewStateDone
{
    ZMClientMessage *message = [[ZMClientMessage alloc] initWithNonce:NSUUID.createUUID managedObjectContext:self.uiMOC];
    XCTAssertEqual(message.linkPreviewState, ZMLinkPreviewStateDone);
}

- (void)testThatAAppendedClientMessageHasLinkPreviewStateWaitingToBeProcessed
{
    ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    ZMClientMessage *message = (ZMClientMessage *)[conversation appendMessageWithText:self.name];
    XCTAssertEqual(message.linkPreviewState, ZMLinkPreviewStateWaitingToBeProcessed);
}

- (void)testThatAAppendedClientMessageWithFlagToNotFetchPreviewSetHasLinkPreviewStateDone
{
    ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    ZMClientMessage *message = (ZMClientMessage *)[conversation appendMessageWithText:self.name fetchLinkPreview:NO];
    XCTAssertEqual(message.linkPreviewState, ZMLinkPreviewStateDone);
}
@end
