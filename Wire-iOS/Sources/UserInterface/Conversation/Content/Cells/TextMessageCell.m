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


#import "TextMessageCell.h"

#import <PureLayout/PureLayout.h>
#import <Classy/Classy.h>

#import "zmessaging+iOS.h"
#import "ZMConversation+Additions.h"
#import "WAZUIMagicIOS.h"
#import "TextViewWithDataDetectorWorkaround.h"
#import "Message+Formatting.h"
#import "MessageStatusIndicator.h"
#import "MessageTimestampView.h"
#import "UIView+Borders.h"
#import "Constants.h"
#import "AnalyticsTracker+Media.h"
#import "LinkAttachmentViewControllerFactory.h"
#import "LinkAttachment.h"
#import "Wire-Swift.h"


#import "Analytics+iOS.h"

@import ZMCLinkPreview;



@interface TextMessageCell (ArticleView) <ArticleViewDelegate>
@end



@interface TextMessageCell () <TextViewInteractionDelegate>

@property (nonatomic, assign) BOOL initialTextCellConstraintsCreated;

@property (nonatomic, strong) MessageStatusIndicator *messageStatusIndicator;
@property (nonatomic, strong) TextViewWithDataDetectorWorkaround *messageTextView;
@property (nonatomic, strong) UIView *linkAttachmentContainer;
@property (nonatomic, strong) UIImageView *editedImageView;
@property (nonatomic, strong) LinkAttachment *linkAttachment;
@property (nonatomic, strong) UIViewController <LinkAttachmentPresenter> *linkAttachmentViewController;
@property (nonatomic, strong) MessageTimestampView *messageTimestampView;

@property (nonatomic, strong) NSLayoutConstraint *mediaPlayerTopMarginConstraint;
@property (nonatomic, strong) NSLayoutConstraint *mediaPlayerLeftMarginConstraint;
@property (nonatomic, strong) NSLayoutConstraint *mediaPlayerRightMarginConstraint;
@property (nonatomic, strong) UIView *linkAttachmentView;

@property (nonatomic) NSLayoutConstraint *timestampHeightConstraint;
@property (nonatomic) NSLayoutConstraint *textViewHeightConstraint;

@end



@implementation TextMessageCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        [self createTextMessageViews];
        [self createConstraints];
    }
    
    return self;
}

- (void)prepareForReuse
{
    [super prepareForReuse];
    
    self.mediaPlayerTopMarginConstraint.constant = 0;
    [self.linkAttachmentViewController.view removeFromSuperview];
    self.linkAttachmentViewController = nil;
    [self.linkAttachmentView removeFromSuperview];
    self.linkAttachmentView = nil;
}

- (void)createTextMessageViews
{
    self.messageTextView = [[TextViewWithDataDetectorWorkaround alloc] init];
    self.messageTextView.translatesAutoresizingMaskIntoConstraints = NO;
    self.messageTextView.textViewInteractionDelegate = self;
    [self.messageContentView addSubview:self.messageTextView];
    
    ColorScheme *scheme = ColorScheme.defaultColorScheme;
    self.messageTextView.dataDetectorTypes = UIDataDetectorTypeNone;
    self.messageTextView.editable = NO;
    self.messageTextView.selectable = YES;
    self.messageTextView.backgroundColor = [scheme colorWithName:ColorSchemeColorBackground];
    self.messageTextView.scrollEnabled = NO;
    self.messageTextView.textContainerInset = UIEdgeInsetsZero;
    self.messageTextView.textContainer.lineFragmentPadding = 0;
    self.messageTextView.userInteractionEnabled = YES;

    self.linkAttachmentContainer = [[UIView alloc] init];
    self.linkAttachmentContainer.translatesAutoresizingMaskIntoConstraints = NO;
    self.linkAttachmentContainer.preservesSuperviewLayoutMargins = YES;
    [self.messageContentView addSubview:self.linkAttachmentContainer];
    
    self.messageStatusIndicator = [[MessageStatusIndicator alloc] init];
    self.messageStatusIndicator.translatesAutoresizingMaskIntoConstraints = NO;
    self.messageStatusIndicator.darkStyle = YES;
    [self.messageStatusIndicator setResendButtonTarget:self action:@selector(resendButtonPressed:)];
    [self.messageContentView addSubview:self.messageStatusIndicator];
    
    self.messageTimestampView = [[MessageTimestampView alloc] init];
    self.messageTimestampView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.messageContentView addSubview:self.messageTimestampView];
    
    self.editedImageView = [[UIImageView alloc] init];
    self.editedImageView.image = [UIImage imageForIcon:ZetaIconTypePencil
                                              iconSize:ZetaIconSizeMessageStatus
                                                 color:[scheme colorWithName:ColorSchemeColorIconNormal]];
    [self.contentView addSubview:self.editedImageView];
    
    UILongPressGestureRecognizer *attachmentLongPressRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleAttachmentLongPress:)];
    [self.linkAttachmentContainer addGestureRecognizer:attachmentLongPressRecognizer];
}

- (void)createConstraints
{
    [self.messageTextView autoPinEdgeToSuperviewEdge:ALEdgeTop];
    [self.messageTextView autoPinEdgeToSuperviewMargin:ALEdgeLeft];
    [self.messageTextView autoPinEdgeToSuperviewMargin:ALEdgeRight];
    
    self.textViewHeightConstraint = [self.messageTextView autoSetDimension:ALDimensionHeight toSize:0];
    self.textViewHeightConstraint.active = NO;
    
    self.mediaPlayerLeftMarginConstraint = [self.linkAttachmentContainer autoPinEdgeToSuperviewEdge:ALEdgeLeft withInset:0];
    self.mediaPlayerRightMarginConstraint = [self.linkAttachmentContainer autoPinEdgeToSuperviewEdge:ALEdgeRight withInset:0];
    self.mediaPlayerTopMarginConstraint = [self.linkAttachmentContainer autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.messageTextView];
    
    [self.messageStatusIndicator autoPinEdgeToSuperviewEdge:ALEdgeTop withInset:4];
    [self.messageStatusIndicator autoPinEdge:ALEdgeLeft toEdge:ALEdgeRight ofView:self.messageTextView withOffset:-5];
    
    [NSLayoutConstraint autoSetPriority:UILayoutPriorityDefaultHigh forConstraints:^{
        self.timestampHeightConstraint = [self.messageTimestampView autoSetDimension:ALDimensionHeight toSize:0];
    }];
    
    [self.messageTimestampView autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.linkAttachmentContainer];
    [self.messageTimestampView autoPinEdgeToSuperviewMargin:ALEdgeRight];
    [self.messageTimestampView autoPinEdgeToSuperviewMargin:ALEdgeLeft];
    [self.messageTimestampView autoPinEdgeToSuperviewEdge:ALEdgeBottom];

    [self.editedImageView autoPinEdge:ALEdgeLeft toEdge:ALEdgeRight ofView:self.authorLabel withOffset:8];
    [self.editedImageView autoAlignAxis:ALAxisHorizontal toSameAxisOfView:self.authorLabel];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];
    
    self.timestampHeightConstraint.active = !self.selected;
    [UIView animateWithDuration:0.35 animations:^{
        self.messageTimestampView.alpha = self.selected ? 1 : 0;
    }];
}

- (void)updateTextMessageConstraintConstants
{
    BOOL hasLinkAttachment = self.linkAttachment || self.linkAttachmentView;
    BOOL hasContentBeforeAttachment = self.layoutProperties.showSender || self.messageTextView.text.length > 0;
    
    if (hasLinkAttachment && hasContentBeforeAttachment) {
        self.mediaPlayerTopMarginConstraint.constant = 12;
    }
    
    self.timestampHeightConstraint.active = !self.selected;
    self.messageTimestampView.alpha = self.selected ? 1 : 0;
}

- (void)configureForMessage:(id<ZMConversationMessage>)message layoutProperties:(ConversationCellLayoutProperties *)layoutProperties
{
    if ( ! [Message isTextMessage:message]) {
        return;
    }
    
    [super configureForMessage:message layoutProperties:layoutProperties];
    [message requestImageDownload];
    
    id<ZMTextMessageData> textMesssageData = message.textMessageData;

    // We do not want to expand the giphy.com link that is sent when sending a GIF via Giphy
    BOOL isGiphy = [textMesssageData.linkPreview.originalURLString.lowercaseString isEqualToString:@"giphy.com"];

    NSAttributedString *attributedMessageText = [Message formattedTextWithLinkAttachments:layoutProperties.linkAttachments
                                                                               forMessage:message.textMessageData
                                                                                  isGiphy:isGiphy];
    self.messageTextView.attributedText = attributedMessageText;
    [self.messageTextView layoutIfNeeded];
    self.messageTimestampView.timestampLabel.text = [Message formattedReceivedDateLongVersion:self.message];
    self.textViewHeightConstraint.active = attributedMessageText.length == 0;
    self.editedImageView.hidden = (nil == self.message.updatedAt);

    LinkPreview *linkPreview = textMesssageData.linkPreview;
    
    if (self.linkAttachmentView != nil) {
        [self.linkAttachmentView removeFromSuperview];
        self.linkAttachmentView = nil;
    }

    if (self.linkAttachmentViewController != nil) {
        [self.linkAttachmentViewController.view removeFromSuperview];
        self.linkAttachmentViewController = nil;
    }
    
    self.linkAttachment = [self lastKnownLinkAttachmentInList:layoutProperties.linkAttachments];
    self.linkAttachmentViewController = [[LinkAttachmentViewControllerFactory sharedInstance] viewControllerForLinkAttachment:self.linkAttachment message:self.message];
    
    if (self.linkAttachmentViewController) {
        self.linkAttachmentViewController.view.translatesAutoresizingMaskIntoConstraints = NO;
        [self.linkAttachmentContainer addSubview:self.linkAttachmentViewController.view];
        [self.linkAttachmentViewController.view autoPinEdgesToSuperviewEdgesWithInsets:UIEdgeInsetsZero];
    }

    if (linkPreview != nil && nil == self.linkAttachmentViewController && !isGiphy) {
            ArticleView *articleView = [[ArticleView alloc] initWithImagePlaceholder:textMesssageData.hasImageData];
            articleView.translatesAutoresizingMaskIntoConstraints = NO;
            [articleView configureWithTextMessageData:textMesssageData];
            [self.linkAttachmentContainer addSubview:articleView];
            [articleView autoPinEdgeToSuperviewEdge:ALEdgeTop];
            [articleView autoPinEdgeToSuperviewEdge:ALEdgeBottom];
            [articleView autoPinEdgeToSuperviewMargin:ALEdgeLeft];
            [articleView autoPinEdgeToSuperviewMargin:ALEdgeRight];
            articleView.delegate = self;
            self.linkAttachmentView = articleView;
        }
    
    [self.linkAttachmentViewController fetchAttachment];
    
    ZMDeliveryState deliveryState = message.deliveryState;
    if (deliveryState == ZMDeliveryStatePending) {
        NSTimeInterval elapsedTime = [NSDate timeIntervalSinceReferenceDate] - [self.message.serverTimestamp timeIntervalSinceReferenceDate];
        [self.messageStatusIndicator setPendingStatusWithElapsedTime:elapsedTime];
    }
    else {
        self.messageStatusIndicator.deliveryState = message.deliveryState;
    }
    
    [self updateTimestampLabel];
    [self updateTextMessageConstraintConstants];
}

- (LinkAttachment *)lastKnownLinkAttachmentInList:(NSArray *)linkAttachments
{
    LinkAttachment *result = nil;
    
    for (NSInteger i = linkAttachments.count - 1; i >= 0; i--) {
        LinkAttachment *linkAttachment = linkAttachments[i];
        if (linkAttachment.type != LinkAttachmentTypeNone) {
            result = linkAttachment;
        }
    }
    
    return result;
}

- (void)resendButtonPressed:(id)sender
{
    if ([self.delegate respondsToSelector:@selector(conversationCell:resendMessageTapped:)]) {
        [self.delegate conversationCell:self resendMessageTapped:self.message];
    }
}

#pragma mark - Message updates

/// Overriden from the super class cell
- (BOOL)updateForMessage:(MessageChangeInfo *)change
{
    BOOL needsLayout = [super updateForMessage:change];
    
    // If a text message changes, the only thing that can change at the moment is its delivery state
    if (change.deliveryStateChanged) {
        self.messageStatusIndicator.deliveryState = change.message.deliveryState;
        [self updateTimestampLabel];
    }
    
    if (change.linkPreviewChanged && self.linkAttachmentView == nil) {
        [self configureForMessage:change.message layoutProperties:self.layoutProperties];
        
        // Fade in the link preview so we don't see a broken layout during cell expansion
        self.linkAttachmentView.alpha = 0;
        [UIView animateWithDuration:0.15 delay:0.2 options:0 animations:^{
            self.linkAttachmentView.alpha = 1;
        } completion:nil];
        
        needsLayout = YES;
    }
    
    id<ZMTextMessageData> textMesssageData = change.message.textMessageData;
    if (change.imageChanged && nil != textMesssageData.linkPreview && [self.linkAttachmentView isKindOfClass:ArticleView.class]) {
        ArticleView *articleView = (ArticleView *)self.linkAttachmentView;
        [articleView configureWithTextMessageData:textMesssageData];
        [self.message requestImageDownload];
    }
    
    return needsLayout;
}

- (void)updateTimestampLabel
{
    if (nil != self.message.updatedAt) {
        self.messageTimestampView.timestampLabel.text = [Message formattedEditedDateForMessage:self.message];
    } else {
        self.messageTimestampView.timestampLabel.text = [Message formattedReceivedDateLongVersion:self.message];
    }
}


#pragma mark - Copy/Paste

- (BOOL)canPerformAction:(SEL)action
              withSender:(id)sender
{
    if (action == @selector(cut:)) {
        return NO;
    }
    else if (action == @selector(copy:)) {
        return self.messageTextView.text != nil;
    }
    else if (action == @selector(paste:)) {
        return NO;
    }
    else if (action == @selector(select:) || action == @selector(selectAll:)) {
        return NO;
    }
    else if (action == @selector(edit:) && self.message.sender.isSelfUser) {
        return YES;
    }
    
    return [super canPerformAction:action withSender:sender];
}

- (void)delete:(id)sender;
{
    [self.linkAttachmentViewController tearDown];
    [super delete:sender];
}

- (void)copy:(id)sender
{
    if (self.message.textMessageData.messageText) {
        [[Analytics shared] tagOpenedMessageAction:MessageActionTypeCopy];
        [[Analytics shared] tagMessageCopy];
        [UIPasteboard generalPasteboard].string = self.message.textMessageData.messageText;
    }
}

- (void)edit:(id)sender;
{
    if([self.delegate respondsToSelector:@selector(conversationCell:didSelectAction:)]) {
        self.beingEdited = YES;
        [self.delegate conversationCell:self didSelectAction:ConversationCellActionEdit];
        // TODO: Add tracking
    }
}

- (void)setSelectedByMenu:(BOOL)selected animated:(BOOL)animated
{
    dispatch_block_t animationBlock = ^{
        // animate self.contentTextView.alpha, not self.contentTextView.textColor : animating textColor causes UIMenuController to hide
        CGFloat newAplha = selected ? ConversationCellSelectedOpacity : 1.0f;
        self.messageTextView.alpha = newAplha;
        self.linkAttachmentContainer.alpha = newAplha;
    };
    
    if (animated) {
        [UIView animateWithDuration:ConversationCellSelectionAnimationDuration animations:animationBlock];
    } else {
        animationBlock();
    }
}

- (CGRect)selectionRect
{
    if (self.message.textMessageData.linkPreview && self.linkAttachmentView) {
        return self.messageTextView.bounds;
    } else {
        return [self.messageTextView.layoutManager usedRectForTextContainer:self.messageTextView.textContainer];
    }
}

- (UIView *)selectionView
{
    return self.messageTextView;
}

- (MenuConfigurationProperties *)menuConfigurationProperties
{
    MenuConfigurationProperties *properties = [[MenuConfigurationProperties alloc] init];
    properties.additionalItems = @[[[UIMenuItem alloc] initWithTitle:NSLocalizedString(@"message.menu.edit.title", @"") action:@selector(edit:)]];
    
    properties.targetRect = self.selectionRect;
    properties.targetView = self.selectionView;
    properties.selectedMenuBlock = ^(BOOL selected, BOOL animated) {
        [self setSelectedByMenu:selected animated:animated];
    };

    return properties;
}

- (MessageType)messageType;
{
    return self.linkAttachment != nil ? MessageTypeRichMedia : MessageTypeText;
}

#pragma mark - Delete

- (void)handleAttachmentLongPress:(UIGestureRecognizer *)gestureRecognizer
{
    BOOL touchInContainer = CGRectContainsPoint(self.linkAttachmentContainer.bounds, [gestureRecognizer locationInView:self.contentView]);
    if (! touchInContainer || ! self.message.canBeDeleted) {
        gestureRecognizer.enabled = NO;
        gestureRecognizer.enabled = YES;
    }
 
    if (gestureRecognizer.state == UIGestureRecognizerStateBegan) {
        [self showMenu];
    }
}

#pragma mark - TextViewInteractionDelegate

- (void)textView:(TextViewWithDataDetectorWorkaround *)textView willOpenURL:(NSURL *)URL
{
    LinkAttachment *linkAttachment = [self.layoutProperties.linkAttachments filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"SELF.URL == %@", URL]].lastObject;
    
    if (linkAttachment != nil) {
        [self.analyticsTracker tagExternalLinkVisitEventForAttachmentType:linkAttachment.type
                                                         conversationType:self.message.conversation.conversationType];
    } else {
        [self.analyticsTracker tagExternalLinkVisitEventForAttachmentType:LinkAttachmentTypeNone
                                                         conversationType:self.message.conversation.conversationType];
    }
}

- (void)textView:(TextViewWithDataDetectorWorkaround *)textView didLongPressLinkWithGestureRecognizer:(UILongPressGestureRecognizer *)longPress
{
    [self showMenu];
}

@end



@implementation TextMessageCell (ArticleView)

- (void)articleViewWantsToOpenURL:(ArticleView *)articleView url:(NSURL *)url
{
    if (! [UIApplication.sharedApplication openURL:url]) {
        DDLogError(@"Unable to open URL: %@", url);
    }
}

- (void)articleViewDidLongPressView:(ArticleView *)articleView
{
    [self showMenu];
}

@end
