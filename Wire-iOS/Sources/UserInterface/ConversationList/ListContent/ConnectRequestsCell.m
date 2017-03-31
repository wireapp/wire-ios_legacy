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

#import <PureLayout/PureLayout.h>

#import "ConversationListItemView.h"

#import "WAZUIMagiciOS.h"
#import "UIColor+WAZExtensions.h"
#import "NSString+WAZUIMagic.h"

#import "zmessaging+iOS.h"
#import "Constants.h"


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
    self.conversationListObserverToken = [ConversationListChangeInfo addObserver:self forList:[SessionObjectCache sharedCache].pendingConnectionRequests];
    
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
    if (IS_IPAD) {
        self.itemView.selected  = self.selected || self.highlighted;
    }
}

- (void)setHighlighted:(BOOL)highlighted
{
    [super setHighlighted:highlighted];
    if (IS_IPAD) {
        self.itemView.selected  = self.selected || self.highlighted;
    } else {
        self.itemView.selected  = self.highlighted;
    }
}

- (void)updateAppearance
{
    NSUInteger newCount = [SessionObjectCache sharedCache].pendingConnectionRequests.count;
    
    if (newCount != self.currentConnectionRequestsCount) {
        self.currentConnectionRequestsCount = newCount;
        self.itemView.titleText = [[self class] titleForConnectionRequests:self.currentConnectionRequestsCount];
    }
}

+ (NSString *)titleForConnectionRequests:(NSUInteger)connectionRequestCount
{
    NSString *title = [NSString stringWithFormat:NSLocalizedString(@"list.connect_request.people_waiting", @""), connectionRequestCount];
    return title;
}

- (void)conversationListDidChange:(ConversationListChangeInfo *)change
{
    [self updateAppearance];
}

@end
