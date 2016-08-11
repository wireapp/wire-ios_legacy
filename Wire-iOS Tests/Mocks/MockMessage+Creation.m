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
@import zmessaging;

@implementation MockMessageFactory

+ (MockMessage *)textMessageIncludingRichMedia:(BOOL)shouldIncludeRichMedia;
{
    MockMessage *message = [[MockMessage alloc] init];
    
    message.conversation = [MockLoader mockObjectsOfClass:[MockConversation class] fromFile:@"conversations-01.json"][0];
    message.serverTimestamp = [NSDate date];
    message.sender = (id)[MockUser mockSelfUser];
    MockTextMessageData *textMessageData = [[MockTextMessageData alloc] init];
    textMessageData.messageText = shouldIncludeRichMedia ? @"Check this 500lb squirrel! -> https://www.youtube.com/watch?v=0so5er4X3dc" : @"Just a random text message";
    message.backingTextMessageData = textMessageData;
    
    return message;

}

+ (MockMessage *)pingMessage;
{
    MockMessage *message = [[MockMessage alloc] init];
    
    message.conversation = [MockLoader mockObjectsOfClass:[MockConversation class] fromFile:@"conversations-01.json"][0];
    message.serverTimestamp = [NSDate date];
    message.sender = (id)[MockUser mockSelfUser];
    message.knockMessageData = [[MockKnockMessageData alloc] init];
    
    return message;
}

+ (MockMessage *)imageMessage;
{
    MockMessage *message = [[MockMessage alloc] init];
    
    message.conversation = [MockLoader mockObjectsOfClass:[MockConversation class] fromFile:@"conversations-01.json"][0];
    message.serverTimestamp = [NSDate date];
    message.sender = (id)[MockUser mockSelfUser];
    message.imageMessageData = [[MockImageMessageData alloc] init];

    return message;
}

+ (MockMessage *)systemMessageWithType:(ZMSystemMessageType)systemMessageType users:(NSUInteger)numUsers clients:(NSUInteger)numClients
{
    MockMessage *message = [[MockMessage alloc] init];

    MockSystemMessageData *mockSystemMessageData = [[MockSystemMessageData alloc] initWithSystemMessageType:systemMessageType];
    
    message.conversation = [MockLoader mockObjectsOfClass:[MockConversation class] fromFile:@"conversations-01.json"][0];
    message.serverTimestamp = [NSDate dateWithTimeIntervalSince1970:12345678564];

    message.sender = (id)[MockUser mockSelfUser];
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
    message.conversation = [MockLoader mockObjectsOfClass:[MockConversation class] fromFile:@"conversations-01.json"][0];
    message.serverTimestamp = [NSDate date];
    
    message.sender = (id)[MockUser mockSelfUser];
    message.backingFileMessageData = [[MockFileMessageData alloc] init];
    return message;
}

+ (MockMessage *)locationMessage
{
    MockMessage *message = [[MockMessage alloc] init];
    message.conversation = [MockLoader mockObjectsOfClass:[MockConversation class] fromFile:@"conversations-01.json"][0];
    message.serverTimestamp = [NSDate date];
    
    message.sender = (id)[MockUser mockSelfUser];
    message.backingLocationMessageData = [[MockLocationMessageData alloc] init];
    return message;
}

@end
