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


#import "MockMessage+Creation.h"
#import "MockConversation.h"
#import "Wire_iOS_Tests-Swift.h"
#import "MockUserClient.h"
#import "Wire-Swift.h"
@import WireSyncEngine;

@implementation MockMessageFactory

+ (MockMessage *)textMessageIncludingRichMedia:(BOOL)shouldIncludeRichMedia;
{
    return [self textMessageWithText:@"Just a random text message" includingRichMedia:shouldIncludeRichMedia];
}

+ (MockMessage *)textMessageWithText:(NSString *)text;
{
    return [self textMessageWithText:text includingRichMedia:NO];
}

+ (MockMessage *)textMessageWithText:(NSString *)text includingRichMedia:(BOOL)shouldIncludeRichMedia;
{
    MockMessage *message = [[MockMessage alloc] init];
    MockConversation *conversation = [MockLoader mockObjectsOfClass:[MockConversation class] fromFile:@"conversations-01.json"][0];
    message.conversation = (ZMConversation *)conversation;
    message.serverTimestamp = [NSDate dateWithTimeIntervalSince1970:0];
    message.sender = (id)[MockUser mockSelfUser];
    conversation.activeParticipants = [[NSOrderedSet alloc] initWithObjects:message.sender, nil];
    MockTextMessageData *textMessageData = [[MockTextMessageData alloc] init];
    textMessageData.messageText = shouldIncludeRichMedia ? @"Check this 500lb squirrel! -> https://www.youtube.com/watch?v=0so5er4X3dc" : text;
    message.backingTextMessageData = textMessageData;
    
    return message;
}

+ (MockMessage *)pingMessage;
{
    MockMessage *message = [[MockMessage alloc] init];
    
    MockConversation *conversation = [MockLoader mockObjectsOfClass:[MockConversation class] fromFile:@"conversations-01.json"][0];
    message.conversation = (ZMConversation *)conversation;
    message.serverTimestamp = [NSDate dateWithTimeIntervalSince1970:0];
    message.sender = (id)[MockUser mockSelfUser];
    conversation.activeParticipants = [[NSOrderedSet alloc] initWithObjects:message.sender, nil];
    message.knockMessageData = [[MockKnockMessageData alloc] init];
    
    return message;
}

+ (MockMessage *)linkMessage {
    MockMessage *message = [[MockMessage alloc] init];

    MockConversation *conversation = [MockLoader mockObjectsOfClass:[MockConversation class] fromFile:@"conversations-01.json"][0];
    message.conversation = (ZMConversation *)conversation;
    message.serverTimestamp = [NSDate dateWithTimeIntervalSince1970:0];
    message.sender = (id)[MockUser mockSelfUser];
    conversation.activeParticipants = [[NSOrderedSet alloc] initWithObjects:message.sender, nil];

    MockTextMessageData *textData = [[MockTextMessageData alloc] init];
    Article *article = [[Article alloc] initWithOriginalURLString:@"http://foo.bar/baz" permanentURLString:@"http://foo.bar/baz" resolvedURLString:@"http://foo.bar/baz" offset:0];
    textData.linkPreview = article;
    message.backingTextMessageData = textData;
    
    return message;
}

+ (MockMessage *)imageMessageWithImage:(UIImage *)image {
    MockImageMessageData *imageData = [[MockImageMessageData alloc] init];
    imageData.mockImageData = image.data;
    
    MockMessage *message = [self imageMessage];
    message.imageMessageData = imageData;
    
    return message;
}

+ (MockMessage *)imageMessage;
{
    MockMessage *message = [[MockMessage alloc] init];
    
    MockConversation *conversation = [MockLoader mockObjectsOfClass:[MockConversation class] fromFile:@"conversations-01.json"][0];
    message.conversation = (ZMConversation *)conversation;
    message.serverTimestamp = [NSDate dateWithTimeIntervalSince1970:0];
    message.sender = (id)[MockUser mockSelfUser];
    conversation.activeParticipants = [[NSOrderedSet alloc] initWithObjects:message.sender, nil];
    message.imageMessageData = [[MockImageMessageData alloc] init];

    return message;
}

+ (MockMessage *)pendingImageMessage
{
    MockImageMessageData *imageData = [[MockImageMessageData alloc] init];
    
    MockMessage *message = [self imageMessage];
    message.imageMessageData = imageData;
    
    return message;
}

+ (MockMessage *)systemMessageWithType:(ZMSystemMessageType)systemMessageType users:(NSUInteger)numUsers clients:(NSUInteger)numClients
{
    MockMessage *message = [[MockMessage alloc] init];

    MockSystemMessageData *mockSystemMessageData = [[MockSystemMessageData alloc] initWithSystemMessageType:systemMessageType];
    
    MockConversation *conversation = [MockLoader mockObjectsOfClass:[MockConversation class] fromFile:@"conversations-01.json"][0];
    message.conversation = (ZMConversation *)conversation;
    message.serverTimestamp = [NSDate dateWithTimeIntervalSince1970:12345678564];

    message.sender = (id)[MockUser mockSelfUser];
    conversation.activeParticipants = [[NSOrderedSet alloc] initWithObjects:message.sender, nil];

    mockSystemMessageData.users = [[MockUser mockUsers] subarrayWithRange:NSMakeRange(0, numUsers)].set;
    
    NSMutableArray *userClients = [NSMutableArray array];
    
    for (MockUser *user in mockSystemMessageData.users) {
        [userClients addObjectsFromArray:[user featureWithUserClients:numClients]];
    }
    
    mockSystemMessageData.clients = userClients.set;
    
    message.systemMessageData = mockSystemMessageData;
    return message;
}

+ (MockMessage *)fileTransferMessage
{
    MockMessage *message = [[MockMessage alloc] init];
    
    MockConversation *conversation = [MockLoader mockObjectsOfClass:[MockConversation class] fromFile:@"conversations-01.json"][0];
    message.conversation = (ZMConversation *)conversation;
    message.serverTimestamp = [NSDate dateWithTimeIntervalSince1970:0];
    
    message.sender = (id)[MockUser mockSelfUser];
    conversation.activeParticipants = [[NSOrderedSet alloc] initWithObjects:message.sender, nil];

    message.backingFileMessageData = [[MockFileMessageData alloc] init];
    return message;
}

+ (MockMessage *)locationMessage
{
    MockMessage *message = [[MockMessage alloc] init];
    
    MockConversation *conversation = [MockLoader mockObjectsOfClass:[MockConversation class] fromFile:@"conversations-01.json"][0];
    message.conversation = (ZMConversation *)conversation;
    message.serverTimestamp = [NSDate dateWithTimeIntervalSince1970:0];
    
    message.sender = (id)[MockUser mockSelfUser];
    conversation.activeParticipants = [[NSOrderedSet alloc] initWithObjects:message.sender, nil];

    message.backingLocationMessageData = [[MockLocationMessageData alloc] init];
    return message;
}

@end
