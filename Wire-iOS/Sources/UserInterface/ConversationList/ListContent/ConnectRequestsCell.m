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


#import "ConnectRequestsCell.h"

@import PureLayout;

#import "ConversationListItemView.h"
#import "UIColor+WAZExtensions.h"

#import "WireSyncEngine+iOS.h"
#import "Constants.h"
#import "Wire-Swift.h"


@interface ConnectRequestsCell () <ZMConversationListObserver>

@property (nonatomic, strong) ConversationListItemView *itemView;
@property (nonatomic, assign) BOOL hasCreatedInitialConstraints;
@property (nonatomic, assign) NSUInteger currentConnectionRequestsCount;
@property (nonatomic) id conversationListObserverToken;

@end



@implementation ConnectRequestsCell

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self setupConnectRequestsCell];
    }
    return self;
}

- (void)setupConnectRequestsCell
{
    self.clipsToBounds = YES;
    self.itemView = [[ConversationListItemView alloc] initForAutoLayout];
    [self addSubview:self.itemView];
    [self updateAppearance];
    self.conversationListObserverToken = [ConversationListChangeInfo addObserver:self
                                                                         forList:[ZMConversationList pendingConnectionConversationsInUserSession:[ZMUserSession sharedSession]]
                                                                     userSession:[ZMUserSession sharedSession]];
    
    [self setNeedsUpdateConstraints];
}

- (void)updateConstraints
{
    if (! self.hasCreatedInitialConstraints) {
        self.hasCreatedInitialConstraints = YES;
        [self.itemView autoPinEdgesToSuperviewEdgesWithInsets:UIEdgeInsetsZero];
    }
    [super updateConstraints];
}

- (void)setSelected:(BOOL)selected
{
    [super setSelected:selected];
    if (IS_IPAD_FULLSCREEN) {
        self.itemView.selected  = self.selected || self.highlighted;
    }
}

- (void)setHighlighted:(BOOL)highlighted
{
    [super setHighlighted:highlighted];
    if (IS_IPAD_FULLSCREEN) {
        self.itemView.selected  = self.selected || self.highlighted;
    } else {
        self.itemView.selected  = self.highlighted;
    }
}

- (void)updateAppearance
{
    NSArray<ZMConversation *> *connectionRequests = [ZMConversationList pendingConnectionConversationsInUserSession:[ZMUserSession sharedSession]];
    
    NSUInteger newCount = connectionRequests.count;
    
    if (newCount != self.currentConnectionRequestsCount) {
        NSArray<ZMUser *> *connectionUsers = [connectionRequests mapWithBlock:^ZMUser *(ZMConversation *conversation) {
            return conversation.connection.to;
        }];
        
        self.currentConnectionRequestsCount = newCount;
        NSString *title = [NSString stringWithFormat:NSLocalizedString(@"list.connect_request.people_waiting", @""), newCount];
        [self.itemView configureWith:[[NSAttributedString alloc] initWithString:title]
                            subtitle:[[NSAttributedString alloc] init]
                               users:connectionUsers];
    }
}

- (void)conversationListDidChange:(ConversationListChangeInfo *)change
{
    [self updateAppearance];
}

@end
