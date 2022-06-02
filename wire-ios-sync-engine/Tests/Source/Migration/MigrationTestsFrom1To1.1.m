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


#import "BaseMigrationTests.h"

#import "ZMUser+Internal.h"
#import "ZMConversation+Internal.h"
#import "ZMConnection+Internal.h"
#import "ZMMessage+Internal.h"
#import "NSUUID+Data.h"
#import "ZMEventID.h"
#import "ZMEventIDRangeSet.h"
#import "ZMManagedObject.h"
#import "FailureRecorder.h"
#import "ZMUser.h"

#import "ZMSyncMergePolicy.h"
#import "ZMMigrationMapping.h"


@interface MigrationTestsFrom1To1_1 : BaseMigrationTests

@end


@implementation MigrationTestsFrom1To1_1

- (NSURL *)dumpURL
{
    NSBundle *bundle = [NSBundle bundleForClass:[self class]];
    NSURL *dumpURL = [bundle URLForResource:@"migration-1.440" withExtension:@"cpio"];
    return dumpURL;
}


- (void)testThatItGetsAllUsers
{
    // given
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:[ZMUser entityName]];
    NSArray *result = [self.uiMOC executeFetchRequest:request error:nil];
    NSArray *expectedResult = [self.sourceContext executeFetchRequest:request error:nil];
    
    // then
    XCTAssertNotNil(result);
    XCTAssertEqual(result.count, expectedResult.count);
    ZMUser *selfUser = [ZMUser selfUserInContext:self.uiMOC];
    ZMUser *expectedSelfUser = [ZMUser selfUserInContext:self.sourceContext];
    XCTAssertEqualObjects(selfUser.name, expectedSelfUser.name);
    
    for (ZMUser *user in result) {
        NSUUID *userId = user.remoteIdentifier;
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"remoteIdentifier == %@", userId];
        ZMUser *expectedUser = [[expectedResult filteredArrayUsingPredicate:predicate] lastObject];
        XCTAssertNotNil(expectedUser);
        XCTAssertTrue([[ZMMigrationMapping userMapping] validateObject:user withExpectedObject:expectedUser], @"Migration failed.");
    }
}

- (void)testThatItGetsAllConversations
{
    // given
    NSFetchRequest *request = [[NSFetchRequest alloc] initWithEntityName:ZMConversation.entityName];
    
    // when
    NSArray *result = [self.uiMOC executeFetchRequest:request error:nil];
    NSArray *expectedResult = [self.sourceContext executeFetchRequest:request error:nil];

    // then
    XCTAssertNotNil(result);
    XCTAssertEqual(result.count, expectedResult.count);
    for (ZMConversation *conv in result) {
        NSUUID *convId = conv.remoteIdentifier;
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"remoteIdentifier == %@", convId];
        ZMConversation *expectedConv = [[expectedResult filteredArrayUsingPredicate:predicate] lastObject];
        XCTAssertNotNil(expectedConv);
        XCTAssertTrue([[ZMMigrationMapping conversationMapping:self.sourceContext] validateObject:conv withExpectedObject:expectedConv], @"Migration failed.");
    }
}

- (void)testThatItGetsAllMessages
{
    // given
    NSFetchRequest *allRequest = [[NSFetchRequest alloc] initWithEntityName:[ZMMessage entityName]];
    NSFetchRequest *imageRequest = [[NSFetchRequest alloc] initWithEntityName:[ZMImageMessage entityName]];
    NSFetchRequest *textRequest = [[NSFetchRequest alloc] initWithEntityName:[ZMTextMessage entityName]];
    NSFetchRequest *systemRequest = [[NSFetchRequest alloc] initWithEntityName:[ZMSystemMessage entityName]];
    NSFetchRequest *knockRequest = [[NSFetchRequest alloc] initWithEntityName:[ZMKnockMessage entityName]];

    // when
    NSArray *allMessages = [self.uiMOC executeFetchRequest:allRequest error:nil];
    NSArray *allExpectedMessages = [self.sourceContext executeFetchRequest:allRequest error:nil];

    NSArray *imageMessages = [self.uiMOC executeFetchRequest:imageRequest error:nil];
    NSArray *expectedImageMessages = [self.sourceContext executeFetchRequest:imageRequest error:nil];

    NSArray *textMessages = [self.uiMOC executeFetchRequest:textRequest error:nil];
    NSArray *expectedTextMessages = [self.sourceContext executeFetchRequest:textRequest error:nil];

    NSArray *knockMessages = [self.uiMOC executeFetchRequest:knockRequest error:nil];
    NSArray *expectedKnockMessages = [self.sourceContext executeFetchRequest:knockRequest error:nil];

    NSArray *systemMessages = [self.uiMOC executeFetchRequest:systemRequest error:nil];
    NSArray *expectedSystemMessages = [self.sourceContext executeFetchRequest:systemRequest error:nil];

    // then
    XCTAssertEqual(allMessages.count, allExpectedMessages.count);
    XCTAssertEqual(imageMessages.count, expectedImageMessages.count);
    XCTAssertEqual(textMessages.count, expectedTextMessages.count);
    XCTAssertEqual(systemMessages.count, expectedSystemMessages.count);
    XCTAssertEqual(knockMessages.count, expectedKnockMessages.count);
    XCTAssertEqual(allMessages.count, imageMessages.count + textMessages.count + systemMessages.count + knockMessages.count);
    
    
    for (ZMMessage *message in textMessages) {
        NSUUID *nonce = message.nonce;
        NSPredicate *predicated = [NSPredicate predicateWithFormat:@"nonce == %@", nonce];
        ZMMessage *expectedMessage = [[expectedTextMessages filteredArrayUsingPredicate:predicated] lastObject];
        XCTAssertNotNil(expectedMessage);
        XCTAssertTrue([[ZMMigrationMapping textMessageMapping:self.sourceContext] validateObject:message withExpectedObject:expectedMessage], @"Migration failed.");
    }

    for (ZMImageMessage *message in imageMessages) {
        NSUUID *nonce = message.nonce;
        NSPredicate *predicated = [NSPredicate predicateWithFormat:@"nonce == %@", nonce];
        ZMMessage *expectedMessage = [[expectedImageMessages filteredArrayUsingPredicate:predicated] lastObject];
        XCTAssertNotNil(expectedMessage);
        XCTAssertTrue([[ZMMigrationMapping imageMessageMapping:self.sourceContext] validateObject:message withExpectedObject:expectedMessage], @"Migration failed.");
        XCTAssertNil(message.originalImageData);
        XCTAssertNil(message.expirationDate);
        XCTAssertNotNil(message.mediumData);
    }

    for (ZMKnockMessage *message in knockMessages) {
        NSUUID *nonce = message.nonce;
        NSPredicate *predicated = [NSPredicate predicateWithFormat:@"nonce == %@", nonce];
        ZMMessage *expectedMessage = [[expectedKnockMessages filteredArrayUsingPredicate:predicated] lastObject];
        XCTAssertNotNil(expectedMessage);
        XCTAssertTrue([[ZMMigrationMapping knockMessageMapping:self.sourceContext] validateObject:message withExpectedObject:expectedMessage], @"Migration failed.");
        XCTAssertNil([message valueForKey:@"eventReference_data"]);
        XCTAssertNil(message.expirationDate);
    }
    
    for (ZMSystemMessage *message in systemMessages) {
        NSUUID *nonce = message.nonce;
        NSPredicate *predicated = [NSPredicate predicateWithFormat:@"nonce == %@", nonce];
        ZMMessage *expectedMessage = [[expectedSystemMessages filteredArrayUsingPredicate:predicated] lastObject];
        XCTAssertNotNil(expectedMessage);
        XCTAssertTrue([[ZMMigrationMapping systemMessageMapping:self.sourceContext] validateObject:message withExpectedObject:expectedMessage], @"Migration failed.");
    }
}


- (void)testThatItGetsAllConnections
{
    // given
    NSFetchRequest *request = [[NSFetchRequest alloc] initWithEntityName:[ZMConnection entityName]];
    
    // when
    NSArray *result = [self.uiMOC executeFetchRequest:request error:nil];
    NSArray *expectedResult = [self.sourceContext executeFetchRequest:request error:nil];

    // then
    XCTAssertEqual(result.count, expectedResult.count);
    for (ZMConnection *connection in result) {
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"message == %@", connection.message];
        ZMConnection *expectedConnection = [[expectedResult filteredArrayUsingPredicate:predicate] lastObject];
        XCTAssertTrue([[ZMMigrationMapping connectionMapping] validateObject:connection withExpectedObject:expectedConnection], @"Migration failed.");
    }
}

- (void)testThatItGetsSession
{
    //given
    NSFetchRequest *request = [[NSFetchRequest alloc] initWithEntityName:@"Session"];
    
    //when
    NSArray *result = [self.uiMOC executeFetchRequest:request error:NULL];
    ZMSession *session = [result lastObject];
    ZMUser *expectedUser = [ZMUser selfUserInContext:self.sourceContext];
    
    //then
    XCTAssert(result.count == 1u);
    XCTAssertEqualObjects(expectedUser.remoteIdentifier, session.selfUser.remoteIdentifier);
}


- (void)testThatItGetsCallParticipants_1
{
    // given
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"%K.@count > 0", @"callParticipants"];

    NSFetchRequest *request = [[NSFetchRequest alloc] initWithEntityName:@"Conversation"];
    request.predicate = predicate;
    
    // when
    NSArray *result = [self.uiMOC executeFetchRequest:request error:NULL];
    NSArray *expectedResult = [self.sourceContext executeFetchRequest:request error:NULL];
    
    // then
    XCTAssert(result.count == 1u);
    ZMConversation *conversation = result.firstObject;
    
    XCTAssert(conversation.mutableCallParticipants.count == 1u);
    XCTAssert([conversation.mutableCallParticipants.lastObject isKindOfClass:[ZMUser class]]);
    
    XCTAssert(expectedResult.count == 1u);
    ZMConversation *sourceConversation = expectedResult.firstObject;

    XCTAssertTrue([[ZMMigrationMapping conversationMapping:self.sourceContext] validateObject:conversation withExpectedObject:sourceConversation], @"Migration failed.");

}


@end
