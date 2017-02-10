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


#import <PureLayout/PureLayout.h>
@import Classy;
@import WireExtensionComponents;

#import "GroupConversationHeader.h"
#import "zmessaging+iOS.h"
#import "ParticipantsChangedView.h"
#import "Button.h"
#import "WebLinkTextView.h"
#import <WireExtensionComponents/WireStyleKit.h>
#import "UIColor+WR_ColorScheme.h"
#import "Wire-Swift.h"


@interface GroupConversationHeader () <UITextViewDelegate, ZMConversationObserver>

@property (nonatomic) UIImageView *messageImageView;
@property (nonatomic) UITextView *messageTextView;
@property (nonatomic) Button *inviteButton;
@property (nonatomic) UIView *separatorView;
@property (nonatomic) ParticipantsChangedView *participantsChangedView;
@property (nonatomic) id conversationObserverToken;

@property (nonatomic, readonly) ZMConversation *conversation;

@property (nonatomic) NSDictionary *messageTextAttributes;
@property (nonatomic) NSDictionary *titleTextAttributes;
@property (nonatomic) NSDictionary *descriptionTextAttributes;
@property (nonatomic) NSDictionary *explanationTextAttributes;

@end

@implementation GroupConversationHeader

- (instancetype)initWithConversation:(ZMConversation *)conversation
{
    self = [super initWithFrame:CGRectZero];
    
    if (self) {
        _conversation = conversation;
        
        [self createViews];
        [self createConstraints];
        
        [[CASStyler defaultStyler] styleItem:self];
        self.messageTextView.attributedText = [self attributedMessage];
        self.conversationObserverToken = [ConversationChangeInfo addObserver:self forConversation:self.conversation];
    }
    
    return self;
}

- (void)createViews
{
    self.separatorView = [[UIView alloc] initForAutoLayout];
    [self addSubview:self.separatorView];
    
    self.messageImageView = [[UIImageView alloc] initForAutoLayout];
    self.messageImageView.image = [WireStyleKit imageOfInviteWithColor:[UIColor wr_colorFromColorScheme:ColorSchemeColorTextDimmed]];
    [self addSubview:self.messageImageView];
    
    self.messageTextView = [[WebLinkTextView alloc] initForAutoLayout];
    self.messageTextView.delegate = self;
    [self addSubview:self.messageTextView];
    
    self.inviteButton = [Button buttonWithStyle:ButtonStyleEmpty];
    [self.inviteButton setTitle:NSLocalizedString(@"conversation.invite_more_people.button_title", nil) forState:UIControlStateNormal];
    self.inviteButton.enabled = self.conversation.selfUserIsActiveParticipant;
    [self addSubview:self.inviteButton];
    
    self.participantsChangedView = [[ParticipantsChangedView alloc] initForAutoLayout];
    self.participantsChangedView.userPerformingAction = self.conversation.creator;
    self.participantsChangedView.action = ParticipantsChangedActionStarted;
    self.participantsChangedView.participants = self.conversation.activeParticipants.array;
    [self addSubview:self.participantsChangedView];
}

- (void)createConstraints
{
    [self.messageImageView autoPinEdgeToSuperviewEdge:ALEdgeTop withInset:16];
    [self.messageImageView autoAlignAxisToSuperviewMarginAxis:ALAxisVertical];
    
    [self.messageTextView autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.messageImageView withOffset:8];
    [self.messageTextView autoPinEdgeToSuperviewMargin:ALEdgeLeft];
    [self.messageTextView autoPinEdgeToSuperviewMargin:ALEdgeRight];
    
    [self.inviteButton autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.messageTextView withOffset:18];
    [self.inviteButton autoPinEdgeToSuperviewMargin:ALEdgeLeft relation:NSLayoutRelationGreaterThanOrEqual];
    [self.inviteButton autoPinEdgeToSuperviewMargin:ALEdgeRight relation:NSLayoutRelationGreaterThanOrEqual];
    [self.inviteButton autoSetDimension:ALDimensionHeight toSize:28];
    [self.inviteButton autoAlignAxisToSuperviewAxis:ALAxisVertical];
    
    [self.separatorView autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.inviteButton withOffset:24];
    [self.separatorView autoPinEdgeToSuperviewMargin:ALEdgeLeft];
    [self.separatorView autoPinEdgeToSuperviewMargin:ALEdgeRight];
    [self.separatorView autoSetDimension:ALDimensionHeight toSize:0.5];
    
    [self.participantsChangedView autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.separatorView withOffset:24];
    [self.participantsChangedView autoPinEdgesToSuperviewMarginsExcludingEdge:ALEdgeTop];
}

- (NSAttributedString *)attributedMessage
{
    NSString *title = [NSLocalizedString(@"conversation.invite_more_people.title", nil) uppercasedWithCurrentLocale];
    NSString *description = NSLocalizedString(@"conversation.invite_more_people.description", nil);
    
    NSString *message =[@[title, description] componentsJoinedByString:@"\u2029"];
    
    NSMutableAttributedString *attributedString  = [[NSMutableAttributedString alloc] initWithString:message attributes:self.messageTextAttributes];
        
    [attributedString addAttributes:self.titleTextAttributes range:[message rangeOfString:title]];
    [attributedString addAttributes:self.descriptionTextAttributes range:[message rangeOfString:description]];
    
    NSMutableDictionary *explanationAttributes = [self.explanationTextAttributes mutableCopy];
    [explanationAttributes setObject:[NSURL URLWithString:NSLocalizedString(@"conversation.invite_more_people.explanation_url", nil)] forKey:NSLinkAttributeName];
    
    return [[NSAttributedString alloc] initWithAttributedString:attributedString];
}

#pragma mark - UITextViewDelegate

- (void)textViewDidChangeSelection:(UITextView *)textView
{
    // Prevent selection, which is enabled for links to be tappable.
    if (! NSEqualRanges(textView.selectedRange, NSMakeRange(0, 0))) {
        textView.selectedRange = NSMakeRange(0, 0);
    }
}

#pragma mark - ZMConversationObserver

- (void)conversationDidChange:(ConversationChangeInfo *)note
{
    if (note.participantsChanged) {
        self.inviteButton.enabled = self.conversation.selfUserIsActiveParticipant;
    }
}

@end
