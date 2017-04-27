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


#import "ChatHeadsViewController.h"

#import "WireSyncEngine+iOS.h"

#import "ChatHeadView.h"
#import "PassthroughTouchesView.h"

// helpers
#import "WAZUIMagic.h"
#import "UIView+WAZUIMagicExtensions.h"
#import "Constants.h"
#import <PureLayout.h>
#import "UIView+MTAnimation.h"


typedef NS_ENUM(NSUInteger, ChatHeadPresentationState) {
    ChatHeadPresentationStateDefault = 0,
    ChatHeadPresentationStateHidden = ChatHeadPresentationStateDefault,
    ChatHeadPresentationStateShowing = 1,
    ChatHeadPresentationStateVisible = 2,
    ChatHeadPresentationStateDragging = 3,
    ChatHeadPresentationStateHiding = 4,
    ChatHeadPresentationStateLast = ChatHeadPresentationStateHiding,

};

@interface ChatHeadsViewController () <ZMNewUnreadMessagesObserver, ZMNewUnreadKnocksObserver>
@property (nonatomic, assign) ChatHeadPresentationState chatHeadState;

@property (nonatomic, strong) UIView *chatHeadsContainerView;

@property (nonatomic, strong) ChatHeadView *chatHeadView;
@property (nonatomic, strong) NSLayoutConstraint *chatHeadViewLeftMarginConstraint;
@property (nonatomic, strong) NSLayoutConstraint *chatHeadViewRightMarginConstraint;

@property (nonatomic, strong) UIPanGestureRecognizer *panGestureRecognizer;

@property (nonatomic) id unreadMessageObserverToken;
@property (nonatomic) id unreadKnockMessageObserverToken;


@end

@implementation ChatHeadsViewController


- (void)loadView
{
    self.view = [PassthroughTouchesView new];
    self.view.backgroundColor = [UIColor clearColor];
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.chatHeadsContainerView = [[UIView alloc] initForAutoLayout];
    self.chatHeadsContainerView.translatesAutoresizingMaskIntoConstraints = NO;
    self.chatHeadsContainerView.backgroundColor = [UIColor clearColor];
    [self.view addSubview:self.chatHeadsContainerView];

    [self.chatHeadsContainerView autoPinEdgeToSuperviewEdge:ALEdgeLeft
                                                  withInset:[WAZUIMagic cgFloatForIdentifier:@"notifications.inset_left"]];
    
    CGFloat statusBarHeight = [UIApplication sharedApplication].statusBarFrame.size.height;
    [self.chatHeadsContainerView autoPinEdgeToSuperviewEdge:ALEdgeTop
                                                  withInset:[WAZUIMagic cgFloatForIdentifier:@"notifications.inset_top"] + statusBarHeight];
    [self.chatHeadsContainerView autoPinEdgeToSuperviewEdge:ALEdgeRight
                                                  withInset:[WAZUIMagic cgFloatForIdentifier:@"notifications.inset_right"]];
    [self.chatHeadsContainerView autoPinEdgeToSuperviewEdge:ALEdgeBottom];

    self.unreadMessageObserverToken = [NewUnreadMessagesChangeInfo addNewMessageObserver:self];
    self.unreadKnockMessageObserverToken = [NewUnreadKnockMessagesChangeInfo addNewKnockObserver:self];
}

- (void)tryToDisplayNotificationForMessage:(id<ZMConversationMessage>)message
{
    if (self.chatHeadState != ChatHeadPresentationStateHidden) {
        if ([self.chatHeadView.message.sender isEqual:message.sender] && [self.chatHeadView.message.conversation isEqual:message.conversation]) {
            [self hideChatHeadFromCurrentStateWithTiming:MTTimingFunctionEaseInExpo duration:0.1f];
            [self performSelector:@selector(tryToDisplayNotificationForMessage:) withObject:message afterDelay:0.1];
        }
        // skip, notification is already visible
        return;
    }

    ChatHeadView *chatHeadView = [[ChatHeadView alloc] initWithMessage:message];
    chatHeadView.messageInCurrentConversation = [self.delegate chatHeadsViewController:self isMessageInCurrentConversation:message];
    chatHeadView.translatesAutoresizingMaskIntoConstraints = NO;
    @weakify(self);
    chatHeadView.onSelect = ^(id<ZMConversationMessage>message) {
        @strongify(self);
        [self.delegate chatHeadsViewController:self didSelectMessage:message];
    };
    self.chatHeadView = chatHeadView;
    self.chatHeadState = ChatHeadPresentationStateShowing;

    [self.chatHeadsContainerView addSubview:self.chatHeadView];

    [self.chatHeadView autoPinEdgeToSuperviewEdge:ALEdgeTop];
    [self.chatHeadView autoPinEdgeToSuperviewEdge:ALEdgeBottom];
    self.chatHeadViewRightMarginConstraint = [self.chatHeadView autoPinEdgeToSuperviewEdge:ALEdgeRight
                                                                                 withInset:[WAZUIMagic cgFloatForIdentifier:@"notifications.animation_inset_container"]
                                                                                  relation:NSLayoutRelationGreaterThanOrEqual];

    self.chatHeadViewLeftMarginConstraint = [self.chatHeadView autoPinEdgeToSuperviewEdge:ALEdgeLeft
                                                                                withInset:-[WAZUIMagic cgFloatForIdentifier:@"notifications.animation_inset_container"]];
    self.chatHeadView.imageToTextInset = -[WAZUIMagic cgFloatForIdentifier:@"notifications.animation_inset_text"];
    self.panGestureRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(onPanChatHead:)];
    [self.chatHeadView addGestureRecognizer:self.panGestureRecognizer];

    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(hideChatHeadView) object:nil];
    [self performSelector:@selector(hideChatHeadView)
               withObject:nil
               afterDelay:[WAZUIMagic cgFloatForIdentifier:@"notifications.single_user_duration"]];

    [self revealChatHeadFromCurrentState];
}

- (void)revealChatHeadFromCurrentState
{
    [self.view layoutIfNeeded];

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.05 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [UIView mt_animateWithViews:[self.chatHeadView mt_allSubviews]
                           duration:0.55f
                     timingFunction:MTTimingFunctionEaseOutExpo
                         animations:^{
                             self.chatHeadView.imageToTextInset = 0;
                             [self.chatHeadView layoutIfNeeded];
                         }
                         completion:^{
                             self.chatHeadState = ChatHeadPresentationStateVisible;
                         }];

    });

    [UIView mt_animateWithViews:@[self.chatHeadView]
                       duration:0.35f
                 timingFunction:MTTimingFunctionEaseOutExpo
                     animations:^{
                         self.chatHeadViewRightMarginConstraint.constant = 0;
                         self.chatHeadViewLeftMarginConstraint.constant = 0;

                         [self.chatHeadView layoutIfNeeded];
                     }];
}

- (void)hideChatHeadFromCurrentState
{
    [self hideChatHeadFromCurrentStateWithTiming:MTTimingFunctionEaseInExpo
                                        duration:0.35f];
}

- (void)hideChatHeadFromCurrentStateWithTiming:(MTTimingFunction)timing
                                      duration:(NSTimeInterval)duration
{
    self.chatHeadViewRightMarginConstraint.constant = -[WAZUIMagic cgFloatForIdentifier:@"notifications.animation_inset_container"];
    self.chatHeadViewLeftMarginConstraint.constant = -[WAZUIMagic cgFloatForIdentifier:@"notifications.animation_inset_container"];
    self.chatHeadState = ChatHeadPresentationStateHiding;

    [UIView mt_animateWithViews:@[self.chatHeadView]
                       duration:duration
                 timingFunction:timing
                     animations:^{
                         self.chatHeadView.alpha = 0.0f;
                         [self.view layoutIfNeeded];
                     }
                     completion:^{
                         [self.chatHeadView removeFromSuperview];
                         self.chatHeadState = ChatHeadPresentationStateHidden;
                     }];
}

- (void)hideChatHeadView
{
    if (nil == self.chatHeadView) {
        return;
    }

    if (self.chatHeadState == ChatHeadPresentationStateDragging) {
        [self performSelector:@selector(hideChatHeadView)
                   withObject:nil
                   afterDelay:[WAZUIMagic cgFloatForIdentifier:@"notifications.single_user_duration"]];
        return;
    }

    [self hideChatHeadFromCurrentState];
}

- (void)processMessages:(NSArray *)messages
{
    for (id<ZMConversationMessage>message in messages) {
        if ([self.delegate chatHeadsViewController:self shouldDisplayMessage:message]) {
            [self tryToDisplayNotificationForMessage:message];
        }
    }
}

#pragma mark - Interaction

- (void)onPanChatHead:(UIPanGestureRecognizer *)pan
{
    CGPoint offset = [pan translationInView:self.view];

    switch (pan.state) {
        case UIGestureRecognizerStateBegan:
            self.chatHeadState = ChatHeadPresentationStateDragging;
            break;
        case UIGestureRecognizerStateChanged:
        {
            CGFloat viewOffsetX = offset.x < 0 ? offset.x : (1.0 - (1.0 / ((offset.x * 0.15f / self.view.bounds.size.width) + 1.0))) * self.view.bounds.size.width;
            self.chatHeadViewRightMarginConstraint.constant = viewOffsetX;
            self.chatHeadViewLeftMarginConstraint.constant = viewOffsetX;
        }
            break;
        case UIGestureRecognizerStateEnded:
        case UIGestureRecognizerStateFailed:
        case UIGestureRecognizerStateCancelled:
            if (offset.x < 0 && fabs(offset.x) > [WAZUIMagic cgFloatForIdentifier:@"notifications.gesture_threshold"]) {
                self.chatHeadViewRightMarginConstraint.constant = -self.view.bounds.size.width;
                self.chatHeadViewLeftMarginConstraint.constant = -self.view.bounds.size.width;

                self.chatHeadState = ChatHeadPresentationStateHiding;

                CGPoint velocityVector = [pan velocityInView:self.view];

                // calculate time from formula dx = t * v + d0
                CGFloat time = (self.view.bounds.size.width - fabs(offset.x)) / fabs(velocityVector.x);

                // min animation duration
                if (time < 0.05f) {
                    time = 0.05f;
                }
                // max animation duration
                if (time > 0.2f) {
                    time = 0.2f;
                }

                [UIView mt_animateWithViews:@[self.chatHeadView]
                                   duration:time
                             timingFunction:MTTimingFunctionEaseInQuad
                                 animations:^{
                                     [self.view layoutIfNeeded];
                                 }
                                 completion:^{
                                     [self.chatHeadView removeFromSuperview];
                                     self.chatHeadState = ChatHeadPresentationStateHidden;
                                 }];
            }
            else {
                [self revealChatHeadFromCurrentState];
            }
            break;
        default:
            break;
    }
}

#pragma mark - ZMNewUnreadMessagesObserver

- (void)didReceiveNewUnreadMessages:(NewUnreadMessagesChangeInfo *)change
{
    [self processMessages:change.messages];
}

#pragma mark - ZMNewUnreadKnocksObserver

- (void)didReceiveNewUnreadKnockMessages:(NewUnreadKnockMessagesChangeInfo *)change
{
    [self processMessages:change.messages];
}

@end
