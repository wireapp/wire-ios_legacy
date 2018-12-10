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


@import WireExtensionComponents;
@import WireDataModel;

#import "ConversationInputBarSendController.h"
#import "ZMUserSession+iOS.h"
#import "Analytics.h"
#import "LinkAttachment.h"
#import "Settings.h"
#import "Wire-Swift.h"


@interface ConversationInputBarSendController ()

@property (nonatomic, readwrite) ZMConversation *conversation;
@property (nonatomic) UIImpactFeedbackGenerator* feedbackGenerator;

@end

@implementation ConversationInputBarSendController

- (instancetype)initWithConversation:(ZMConversation *) conversation
{
    self = [super init];
    if (self) {
        self.conversation = conversation;
        if (nil != [UIImpactFeedbackGenerator class]) {
            self.feedbackGenerator = [[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleLight];
        }
    }
    return self;
}

- (void)sendMessageWithImageData:(NSData *)imageData completion:(dispatch_block_t)completionHandler
{
    if (imageData == nil) {
        return;
    }
    [self.feedbackGenerator prepare];
    [[ZMUserSession sharedSession] enqueueChanges:^{
        [self.conversation appendMessageWithImageData:imageData];
        [self.feedbackGenerator impactOccurred];
    } completionHandler:^{
        if (completionHandler){
            completionHandler();
        }
        [[Analytics shared] tagMediaActionCompleted:ConversationMediaActionPhoto inConversation:self.conversation];
    }];
}

- (void)sendTextMessage:(NSString *)text
               mentions:(NSArray <Mention *>*)mentions
      replyingToMessage:(ZMClientMessage *)message
{
    [[ZMUserSession sharedSession] enqueueChanges:^{
        BOOL shouldFetchLinkPreview = ![Settings sharedSettings].disableLinkPreviews;
        [self.conversation appendText:text
                             mentions:mentions
                    replyingToMessage:message
                     fetchLinkPreview:shouldFetchLinkPreview
                                nonce:NSUUID.UUID];
        self.conversation.draftMessage = nil;
    } completionHandler:^{
        [[Analytics shared] tagMediaActionCompleted:ConversationMediaActionText inConversation:self.conversation];
    }];
}

- (void)sendTextMessage:(NSString *)text mentions:(NSArray <Mention *>*)mentions withImageData:(NSData *)data
{
    __block id <ZMConversationMessage> textMessage = nil;
    
    BOOL shouldFetchLinkPreview = ![Settings sharedSettings].disableLinkPreviews;
    
    [ZMUserSession.sharedSession enqueueChanges:^{
        textMessage = [self.conversation appendText:text
                                           mentions:mentions
                                  replyingToMessage:nil
                                   fetchLinkPreview:shouldFetchLinkPreview
                                              nonce:NSUUID.UUID];
        
        [self.conversation appendMessageWithImageData:data];
        self.conversation.draftMessage = nil;
    } completionHandler:^{
        [[Analytics shared] tagMediaActionCompleted:ConversationMediaActionPhoto inConversation:self.conversation];
        [[Analytics shared] tagMediaActionCompleted:ConversationMediaActionText inConversation:self.conversation];
    }];
}

@end
