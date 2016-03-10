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
// along with this program. If not, see <http://www.gnu.org/licenses/>.


@import ZMTransport;

#import "MessagingTest.h"
#import "ZMConversation+Internal.h"
#import "ZMMessage+Internal.h"
#import "ZMConversationMessageWindow.h"
#import "ZMConversationMessageWindow+Internal.h"
#import "ZMNotifications+Internal.h"
#import "ZMNotifications.h"



@interface ZMConversationMessageWindowTests : MessagingTest

- (ZMConversation *)createConversationWithMessages:(NSUInteger)numberOfMessages;
- (void)checkExpectedMessagesWithLastReadIndex:(NSUInteger)lastReadIndex
                              conversationSize:(NSUInteger)conversationSize
                                    windowSize:(NSUInteger)windowSize
               minExpectedMessageIndexInWindow:(NSUInteger)minExpectedMessage
                                          move:(NSInteger)move
                               failureRecorder:(ZMTFailureRecorder *)recorder;
- (NSOrderedSet *)messagesUntilEndOfConversation:(ZMConversation *)conversation fromIndex:(NSUInteger)from;

@property (nonatomic) MessageWindowChangeInfo* receivedWindowChangeNotification;


@end




@interface ZMConversationMessageWindowTests (Notifications) <ZMConversationMessageWindowObserver>
@end



@implementation ZMConversationMessageWindowTests

- (void)setUp
{
    [super setUp];
    
    self.receivedWindowChangeNotification = nil;
}

- (void)tearDown
{
    [super tearDown];
}

- (ZMConversation *)createConversationWithMessages:(NSUInteger)numberOfMessages firstIsSystemMessage:(BOOL)firstIsSystemMessage ofType:(ZMSystemMessageType)systemMessageType
{
    ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    
    for(NSUInteger i = 1; i < numberOfMessages+1; ++i)
    {
        ZMMessage *message;
        if (firstIsSystemMessage && i == 1) {
            message = [ZMSystemMessage insertNewObjectInManagedObjectContext:self.uiMOC];
            ((ZMSystemMessage* )message).systemMessageType = systemMessageType;
        } else {
            message = [ZMTextMessage insertNewObjectInManagedObjectContext:self.uiMOC];
        }
        [self addMessage:message withEventMajor:(uint64_t)i toConversation:conversation];
    }
    
    return conversation;
}

- (void)addMessage:(ZMMessage *)message withEventMajor:(uint64_t)major toConversation:(ZMConversation *)conversation
{
    NSDate *timeStamp = conversation.lastServerTimeStamp ? [conversation.lastServerTimeStamp dateByAddingTimeInterval:5] : [NSDate date];
    message.eventID = [ZMEventID eventIDWithMajor:major minor:554236];
    message.serverTimestamp = timeStamp;
    [conversation.mutableMessages addObject:message];
    [conversation addEventToDownloadedEvents:message.eventID timeStamp:message.serverTimestamp];
    conversation.lastEventID = message.eventID;
    conversation.lastServerTimeStamp = message.serverTimestamp;
}


- (ZMSystemMessage *)appendSystemMessageOfType:(ZMSystemMessageType)systemMessageType inConversation:(ZMConversation *)conversation
{
    ZMSystemMessage *message = [ZMSystemMessage insertNewObjectInManagedObjectContext:self.uiMOC];
    ((ZMSystemMessage* )message).systemMessageType = systemMessageType;
    [self addMessage:message withEventMajor:conversation.lastEventID.major+1 toConversation:conversation];
    return message;
}

- (ZMConversation *)createConversationWithMessages:(NSUInteger)numberOfMessages
{
    return [self createConversationWithMessages:numberOfMessages firstIsSystemMessage:NO ofType:ZMSystemMessageTypeInvalid];
}

- (NSMutableOrderedSet *)messagesUntilEndOfConversation:(ZMConversation *)conversation fromIndex:(NSUInteger)from;
{
    NSMutableOrderedSet *messages = [NSMutableOrderedSet orderedSet];
    const NSUInteger size = conversation.messages.count;
    for(NSUInteger i = from; i < size; ++i) {
        [messages addObject:conversation.messages[i]];
    }
    return messages;
}

/// Generates a conversation, sets some parameter about the window and make sure that
/// the messages in the window match the expected ones
- (void)checkExpectedMessagesWithLastReadIndex:(NSUInteger)lastReadIndex
                              conversationSize:(NSUInteger)conversationSize
                                    windowSize:(NSUInteger)windowSize
               minExpectedMessageIndexInWindow:(NSUInteger)minExpectedMessage
                                          move:(NSInteger)move
                               failureRecorder:(ZMTFailureRecorder *)recorder
{
    ZMConversation *conversation = [self createConversationWithMessages:conversationSize];
    if(lastReadIndex != NSNotFound) {
        ZMMessage *lastRead = conversation.messages[lastReadIndex];
        conversation.lastReadEventID = lastRead.eventID;
        conversation.lastReadServerTimeStamp = lastRead.serverTimestamp;
    }
    
    /* Here I'm using the fact that all eventIDs are sequential - I know it's true because I just created them myself */
    NSOrderedSet *expectedMessages = [self messagesUntilEndOfConversation:conversation fromIndex:minExpectedMessage];
    
    // when
    ZMConversationMessageWindow *window = [conversation conversationWindowWithSize:windowSize];
    if(move > 0) {
        [window moveDownByMessages:(NSUInteger) move];
    }
    else if(move < 0) {
        [window moveUpByMessages:(NSUInteger) -move];
    }
    
    // then
    FHAssertTrue(recorder, window != nil);
    FHAssertEqual(recorder, window.messages.count, expectedMessages.count);
    if(expectedMessages.count > 0u) {
        NSUInteger indexOfFirstActualMessage = [conversation.messages indexOfObject:expectedMessages[0]];
        NSString *errorMessage = [NSString stringWithFormat:@"Messages started at index %lu, vs. expected %lu", (unsigned long)indexOfFirstActualMessage, (unsigned long)minExpectedMessage];
        FHAssertEqualObjectsString(recorder,window.messages, expectedMessages,errorMessage);
    }
}

- (void)testThatAConversationWindowMatchesTheSizeIfThereIsNoLastRead
{
    for(NSNumber *size in @[@1,@45]) {
        
        // given
        const NSUInteger WINDOW_SIZE = (NSUInteger) size.integerValue;
        const NSUInteger CONVERSATION_SIZE = WINDOW_SIZE*2;
        const NSUInteger LAST_READ = NSNotFound;
        const NSUInteger MIN_EXPECTED_MESSAGE = CONVERSATION_SIZE-WINDOW_SIZE;
        const NSInteger MOVE = 0;
        
        // then
        [self checkExpectedMessagesWithLastReadIndex:LAST_READ conversationSize:CONVERSATION_SIZE windowSize:WINDOW_SIZE minExpectedMessageIndexInWindow:MIN_EXPECTED_MESSAGE move:MOVE failureRecorder:NewFailureRecorder()];
    }
}

- (void)testThatAConversationWindowMatchesTheSizeIfLastReadIsTheLastEvent
{

    // given
    const NSUInteger WINDOW_SIZE = 5;
    const NSUInteger CONVERSATION_SIZE = WINDOW_SIZE*2;
    const NSUInteger LAST_READ = CONVERSATION_SIZE - 1;
    const NSUInteger MIN_EXPECTED_MESSAGE = LAST_READ-WINDOW_SIZE+1;
    const NSInteger MOVE = 0;
    
    // then
    [self checkExpectedMessagesWithLastReadIndex:LAST_READ conversationSize:CONVERSATION_SIZE windowSize:WINDOW_SIZE minExpectedMessageIndexInWindow:MIN_EXPECTED_MESSAGE move:MOVE failureRecorder:NewFailureRecorder()];
    
}

- (void)testThatAConversationWindowMatchesTheSizeStartingFromLastRead
{
    // given
    const NSUInteger WINDOW_SIZE = 5;
    const NSUInteger CONVERSATION_SIZE = 20;
    const NSUInteger LAST_READ = 8;
    const NSUInteger MIN_EXPECTED_MESSAGE = LAST_READ-WINDOW_SIZE+1;
    const NSInteger MOVE = 0;
    
    // then
    [self checkExpectedMessagesWithLastReadIndex:LAST_READ conversationSize:CONVERSATION_SIZE windowSize:WINDOW_SIZE minExpectedMessageIndexInWindow:MIN_EXPECTED_MESSAGE move:MOVE failureRecorder:NewFailureRecorder()];
}

- (void)testThatAConversationWindowHasLessMessagesThanTheWindowSizeIfTheConversationHasLessMessages
{
    // given
    const NSUInteger WINDOW_SIZE = 45;
    const NSUInteger CONVERSATION_SIZE = 2;
    const NSUInteger LAST_READ = NSNotFound;
    const NSUInteger MIN_EXPECTED_MESSAGE = 0;
    const NSInteger MOVE = 0;
    
    // then
    [self checkExpectedMessagesWithLastReadIndex:LAST_READ conversationSize:CONVERSATION_SIZE windowSize:WINDOW_SIZE minExpectedMessageIndexInWindow:MIN_EXPECTED_MESSAGE move:MOVE failureRecorder:NewFailureRecorder()];
}

- (void)testThatAConversationWindowIsEmptyIfThereIsALastReadEventIDButNoMessages
{
    // given
    const NSUInteger WINDOW_SIZE = 5;
    ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    conversation.lastReadEventID = [ZMEventID eventIDWithMajor:8 minor:214235];
    
    // when
    ZMConversationMessageWindow *window = [conversation conversationWindowWithSize:WINDOW_SIZE];
    
    // then
    XCTAssertNotNil(window);
    XCTAssertEqual(window.messages.count, 0u);
}

- (void)testThatAConversationWindowMatchesTheEntireConversationIsTheLastReadIsTheFirstMessage
{
    // given
    const NSUInteger WINDOW_SIZE = 5;
    const NSUInteger CONVERSATION_SIZE = 20;
    const NSUInteger LAST_READ = 0;
    const NSUInteger MIN_EXPECTED_MESSAGE = 0;
    const NSInteger MOVE = 0;
    
    // then
    [self checkExpectedMessagesWithLastReadIndex:LAST_READ conversationSize:CONVERSATION_SIZE windowSize:WINDOW_SIZE minExpectedMessageIndexInWindow:MIN_EXPECTED_MESSAGE move:MOVE failureRecorder:NewFailureRecorder()];
}

@end



@implementation ZMConversationMessageWindowTests (MovingWindow)

- (void)testThatAConversationWindowMovesDownAndNotifiesOfScrolling
{
    // given
    const NSUInteger WINDOW_SIZE = 5;
    const NSUInteger CONVERSATION_SIZE = 20;
    const NSUInteger LAST_READ = 10;
    const NSInteger MOVE = 4;
    const NSUInteger MIN_EXPECTED_MESSAGE = 10;

    // then
    [self checkExpectedMessagesWithLastReadIndex:LAST_READ conversationSize:CONVERSATION_SIZE windowSize:WINDOW_SIZE minExpectedMessageIndexInWindow:MIN_EXPECTED_MESSAGE move:MOVE failureRecorder:NewFailureRecorder()];
    
}

- (void)testThatAConversationWindowMovesUp
{
    // given
    const NSUInteger WINDOW_SIZE = 5;
    const NSUInteger CONVERSATION_SIZE = 20;
    const NSUInteger LAST_READ = 10;
    const NSInteger MOVE = -4;
    const NSUInteger MIN_EXPECTED_MESSAGE = 2;
    
    
    // then
    [self checkExpectedMessagesWithLastReadIndex:LAST_READ conversationSize:CONVERSATION_SIZE windowSize:WINDOW_SIZE minExpectedMessageIndexInWindow:MIN_EXPECTED_MESSAGE move:MOVE failureRecorder:NewFailureRecorder()];
    
}


- (void)testThatAConversationWindowDoesNotMoveUpWhenAlreadyAtTheFirst
{
    // given
    const NSUInteger WINDOW_SIZE = 5;
    const NSUInteger CONVERSATION_SIZE = 20;
    const NSUInteger LAST_READ = 4;
    const NSInteger MOVE = -4;
    const NSUInteger MIN_EXPECTED_MESSAGE = 0;
    
    
    // then
    [self checkExpectedMessagesWithLastReadIndex:LAST_READ conversationSize:CONVERSATION_SIZE windowSize:WINDOW_SIZE minExpectedMessageIndexInWindow:MIN_EXPECTED_MESSAGE move:MOVE failureRecorder:NewFailureRecorder()];
}

- (void)testThatAConversationWindowDoesMoveUpUntilTheSizeIsOneAndNoMore
{
    // given
    const NSUInteger WINDOW_SIZE = 5;
    const NSUInteger CONVERSATION_SIZE = 20;
    const NSUInteger LAST_READ = 15;
    const NSInteger MOVE = 10;
    const NSUInteger MIN_EXPECTED_MESSAGE = 19;
    
    
    // then
    [self checkExpectedMessagesWithLastReadIndex:LAST_READ conversationSize:CONVERSATION_SIZE windowSize:WINDOW_SIZE minExpectedMessageIndexInWindow:MIN_EXPECTED_MESSAGE move:MOVE failureRecorder:NewFailureRecorder()];
}


@end


@implementation ZMConversationMessageWindowTests (UpdateAfterChangeInConversation)

- (void)testThatWhenAddingAMessageBeforeTheWindowTheWindowHasTheSameMessages
{
    // given
    ZMConversation *conversation = [self createConversationWithMessages:15];
    ZMMessage *lastReadMessage = conversation.messages[7];
    conversation.lastReadEventID = lastReadMessage.eventID;
    conversation.lastReadServerTimeStamp = lastReadMessage.serverTimestamp;
    ZMConversationMessageWindow *sut = [conversation conversationWindowWithSize:5];
    ZMTextMessage *newMessage = [ZMTextMessage insertNewObjectInManagedObjectContext:self.uiMOC];
    
    // when
    [conversation.mutableMessages insertObject:newMessage atIndex:0];
    [sut recalculateMessages];
    
    
    // then
    NSOrderedSet *expectedMessages = [self messagesUntilEndOfConversation:conversation fromIndex:4];
    XCTAssertEqualObjects(sut.messages, expectedMessages);
}

- (void)testThatAddingAMessageAtTheEndDoesNotPopMessagesOffTheTopIfTheWindowFitsAllMessages
{
    // given
    ZMConversation *conversation = [self createConversationWithMessages:5];
    ZMMessage *lastReadMessage = conversation.messages[1];
    conversation.lastReadEventID = lastReadMessage.eventID;
    ZMConversationMessageWindow *sut = [conversation conversationWindowWithSize:10];
    ZMTextMessage *newMessage = [ZMTextMessage insertNewObjectInManagedObjectContext:self.uiMOC];
    XCTAssertEqualObjects(sut.messages, conversation.messages);
    
    // when
    [conversation.mutableMessages addObject:newMessage];
    [sut recalculateMessages];
    
    // then
    XCTAssertEqualObjects(sut.messages, conversation.messages);
}

- (void)testThatWhenAddingAMessageInsideTheWindowTheWindowGrows
{
    // given
    ZMConversation *conversation = [self createConversationWithMessages:15];
    ZMMessage *lastReadMessage = conversation.messages[7];
    conversation.lastReadEventID = lastReadMessage.eventID;
    conversation.lastReadServerTimeStamp = lastReadMessage.serverTimestamp;
    ZMConversationMessageWindow *sut = [conversation conversationWindowWithSize:5];
    ZMTextMessage *newMessage = [ZMTextMessage insertNewObjectInManagedObjectContext:self.uiMOC];
    
    // when
    [conversation.mutableMessages insertObject:newMessage atIndex:5];
    [sut recalculateMessages];
    
    // then
    NSOrderedSet *expectedMessages = [self messagesUntilEndOfConversation:conversation fromIndex:4];
    XCTAssertEqualObjects(sut.messages, expectedMessages);
}

- (void)testThatUnsentPendingMessagesAreNotHiddenWhenTheConversationIsCleared
{
    // given
    ZMConversation *conversation = [self createConversationWithMessages:3];
    ZMMessage *lastReadMessage = conversation.messages.lastObject;
    conversation.lastReadEventID = lastReadMessage.eventID;
    ZMConversationMessageWindow *sut = [conversation conversationWindowWithSize:30];
    ZMTextMessage *newMessage = [ZMTextMessage insertNewObjectInManagedObjectContext:self.uiMOC];
    
    // when
    conversation.clearedEventID = lastReadMessage.eventID;
    [conversation.mutableMessages addObject:newMessage];
    [sut recalculateMessages];
    
    // then
    XCTAssertEqualObjects(sut.messages, [NSOrderedSet orderedSetWithObject:newMessage]);
}

@end



@implementation ZMConversationMessageWindowTests (ScrollingNotification)

- (void)testThatScrollingTheWindowUpCausesAScrollingNotification
{
    // given
    ZMConversation *conversation = [self createConversationWithMessages:20];
    ZMConversationMessageWindow *window = [conversation conversationWindowWithSize:10];
    
    // expect
    [self expectationForNotification:ZMConversationMessageWindowScrolledNotificationName object:window handler:nil];
    
    // when
    [window moveUpByMessages:10];
    
    // then
    XCTAssertTrue([self waitForCustomExpectationsWithTimeout:0.2]);
}

- (void)testThatScrollingTheWindowUpDoesNotCauseAScrollingNotificationIfTheWindowDidNotChange
{
    // given
    ZMConversation *conversation = [self createConversationWithMessages:10];
    ZMConversationMessageWindow *window = [conversation conversationWindowWithSize:10];
    
    // expect
    [self expectationForNotification:ZMConversationMessageWindowScrolledNotificationName object:window handler:nil];
    
    // when
    [window moveUpByMessages:10];
    
    // then
    [self spinMainQueueWithTimeout:0.1];
    XCTAssertFalse([self waitForCustomExpectationsWithTimeout:0.0]);
}



@end


