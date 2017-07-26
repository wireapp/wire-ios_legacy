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
#import "TextMessageCell+Internal.h"

@import PureLayout;
#import <Classy/Classy.h>

#import "WireSyncEngine+iOS.h"
#import "ZMConversation+Additions.h"
#import "WAZUIMagicIOS.h"
#import "Message+Formatting.h"
#import "UIView+Borders.h"
#import "Constants.h"
#import "AnalyticsTracker+Media.h"
#import "LinkAttachmentViewControllerFactory.h"
#import "LinkAttachment.h"
#import "Wire-Swift.h"


#import "Analytics+iOS.h"

@import WireLinkPreview;



@interface TextMessageCell (ArticleView) <ArticleViewDelegate>
@end



@interface TextMessageCell () <TextViewInteractionDelegate>

@property (nonatomic) BOOL initialTextCellConstraintsCreated;

@property (nonatomic) UIImageView *editedImageView;
@property (nonatomic) UIView *linkAttachmentContainer;
@property (nonatomic) LinkAttachment *linkAttachment;
@property (nonatomic) UIViewController <LinkAttachmentPresenter> *linkAttachmentViewController;

@property (nonatomic) NSLayoutConstraint *mediaPlayerTopMarginConstraint;
@property (nonatomic) UIView *linkAttachmentView;

@property (nonatomic) NSLayoutConstraint *textViewHeightConstraint;
@end



@implementation TextMessageCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {        
        [self createTextMessageViews];
        [NSLayoutConstraint autoCreateAndInstallConstraints:^{
            [self createConstraints];
        }];
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
    self.messageTextView = [[LinkInteractionTextView alloc] init];
    self.messageTextView.translatesAutoresizingMaskIntoConstraints = NO;
    self.messageTextView.interactionDelegate = self;
    [self.messageContentView addSubview:self.messageTextView];

    ColorScheme *scheme = ColorScheme.defaultColorScheme;
    self.messageTextView.editable = NO;
    self.messageTextView.selectable = YES;
    self.messageTextView.backgroundColor = [scheme colorWithName:ColorSchemeColorConversationBackground];
    self.messageTextView.scrollEnabled = NO;
    self.messageTextView.textContainerInset = UIEdgeInsetsZero;
    self.messageTextView.textContainer.lineFragmentPadding = 0;
    self.messageTextView.userInteractionEnabled = YES;
    self.messageTextView.accessibilityIdentifier = @"Message";
    self.messageTextView.accessibilityElementsHidden = NO;
    self.messageTextView.dataDetectorTypes = UIDataDetectorTypeLink |
                                             UIDataDetectorTypeAddress |
                                             UIDataDetectorTypePhoneNumber |
                                             UIDataDetectorTypeFlightNumber |
                                             UIDataDetectorTypeCalendarEvent |
                                             UIDataDetectorTypeShipmentTrackingNumber;

    self.linkAttachmentContainer = [[UIView alloc] init];
    self.linkAttachmentContainer.translatesAutoresizingMaskIntoConstraints = NO;
    self.linkAttachmentContainer.preservesSuperviewLayoutMargins = YES;
    [self.messageContentView addSubview:self.linkAttachmentContainer];
    
    self.editedImageView = [[UIImageView alloc] init];
    self.editedImageView.image = [UIImage imageForIcon:ZetaIconTypePencil
                                              iconSize:ZetaIconSizeMessageStatus
                                                 color:[scheme colorWithName:ColorSchemeColorIconNormal]];
    [self.contentView addSubview:self.editedImageView];
    
    UILongPressGestureRecognizer *attachmentLongPressRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleAttachmentLongPress:)];
    [self.linkAttachmentContainer addGestureRecognizer:attachmentLongPressRecognizer];
    
    NSMutableArray *accessibilityElements = [NSMutableArray arrayWithArray:self.accessibilityElements];
    [accessibilityElements addObjectsFromArray:@[self.messageTextView]];
    self.accessibilityElements = accessibilityElements;
}

- (void)createConstraints
{
    [self.messageTextView autoPinEdgeToSuperviewMargin:ALEdgeTop];
    [self.messageTextView autoPinEdgeToSuperviewMargin:ALEdgeLeading];
    [self.messageTextView autoPinEdgeToSuperviewMargin:ALEdgeTrailing];
    
    self.textViewHeightConstraint = [self.messageTextView autoSetDimension:ALDimensionHeight toSize:0];
    self.textViewHeightConstraint.active = NO;
    
    [self.linkAttachmentContainer autoPinEdgeToSuperviewEdge:ALEdgeLeading withInset:0];
    [self.linkAttachmentContainer autoPinEdgeToSuperviewEdge:ALEdgeTrailing withInset:0];
    self.mediaPlayerTopMarginConstraint = [self.linkAttachmentContainer autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.messageTextView];
    
    [NSLayoutConstraint autoSetPriority:UILayoutPriorityDefaultHigh forConstraints:^{
        [self.linkAttachmentContainer autoPinEdgeToSuperviewMargin:ALEdgeBottom];
    }];
    
    [self.editedImageView autoPinEdge:ALEdgeLeft toEdge:ALEdgeRight ofView:self.authorLabel withOffset:8];
    [self.editedImageView autoAlignAxis:ALAxisHorizontal toSameAxisOfView:self.authorLabel];
    [self.countdownContainerView autoPinEdge:ALEdgeTop toEdge:ALEdgeTop ofView:self.messageTextView];
}

- (void)updateTextMessageConstraintConstants
{
    BOOL hasLinkAttachment = self.linkAttachment || self.linkAttachmentView;
    BOOL hasContentBeforeAttachment = self.layoutProperties.showSender || self.messageTextView.text.length > 0;
    
    if (hasLinkAttachment && hasContentBeforeAttachment) {
        self.mediaPlayerTopMarginConstraint.constant = 12;
    }
}

- (void)flashBackground
{
    [self.messageTextView flashBackground];
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

    NSAttributedString *attributedMessageText = [NSAttributedString formattedStringWithLinkAttachments:layoutProperties.linkAttachments
                                                                                            forMessage:message.textMessageData
                                                                                               isGiphy:isGiphy
                                                                                            obfuscated:message.isObfuscated];
    if (self.searchQueries.count > 0 && attributedMessageText.length > 0) {
        
        NSMutableDictionary<NSString *, id> *highlightStyle = [NSMutableDictionary dictionaryWithDictionary:[attributedMessageText attributesAtIndex:0
                                                                                                                                     effectiveRange:nil]];
        highlightStyle[NSBackgroundColorAttributeName] = [[ColorScheme defaultColorScheme] colorWithName:ColorSchemeColorAccentDarken];
        attributedMessageText = [attributedMessageText highlightingAppearancesOf:self.searchQueries
                                                                            with:highlightStyle
                                                                       upToWidth:0
                                                                    totalMatches:nil];
    }
    
    self.messageTextView.attributedText = attributedMessageText;
    [self.messageTextView layoutIfNeeded];
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
        BOOL showImage = !self.smallLinkAttachments && textMesssageData.hasImageData;
        ArticleView *articleView = [[ArticleView alloc] initWithImagePlaceholder:showImage];

        if (self.smallLinkAttachments) {
            articleView.messageLabel.numberOfLines = 1;
            articleView.authorLabel.numberOfLines = 1;
            [articleView autoSetDimension:ALDimensionHeight toSize:70];
        }
        articleView.translatesAutoresizingMaskIntoConstraints = NO;
        [articleView configureWithTextMessageData:textMesssageData obfuscated:message.isObfuscated];
        [self.linkAttachmentContainer addSubview:articleView];
        [articleView autoPinEdgeToSuperviewEdge:ALEdgeTop];
        [articleView autoPinEdgeToSuperviewEdge:ALEdgeBottom];
        [articleView autoPinEdgeToSuperviewMargin:ALEdgeLeft];
        [articleView autoPinEdgeToSuperviewMargin:ALEdgeRight];
        articleView.delegate = self;
        self.linkAttachmentView = articleView;
    }

    [self.linkAttachmentViewController fetchAttachment];

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

#pragma mark - Message updates

/// Overriden from the super class cell
- (BOOL)updateForMessage:(MessageChangeInfo *)change
{
    if (change.isObfuscatedChanged) {
        // We need to tear down the attachment controller before super is called,
        // as the attachment will already be set to `nil` otherwise
        [self.linkAttachmentViewController tearDown];
    }

    BOOL needsLayout = [super updateForMessage:change];

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
        [articleView configureWithTextMessageData:textMesssageData obfuscated:self.message.isObfuscated];
        [self.message requestImageDownload];
    }

    return needsLayout;
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
    else if (action == @selector(forward:)) {
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
        [self.delegate conversationCell:self didSelectAction:MessageActionEdit];
        [[Analytics shared] tagOpenedMessageAction:MessageActionTypeEdit];
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
        if (self.messageTextView.text.length == 0) {
            return self.linkAttachmentView.bounds;
        } else {
            return self.messageTextView.bounds;
        }
    } else {
        return [self.messageTextView.layoutManager usedRectForTextContainer:self.messageTextView.textContainer];
    }
}

- (UIView *)selectionView
{
    if (self.message.textMessageData.linkPreview && self.linkAttachmentView && self.messageTextView.text.length == 0) {
        return self.linkAttachmentView;
    } else {
        return self.messageTextView;
    }
}

- (UIView *)previewView
{
    return self.linkAttachmentView;
}

- (MenuConfigurationProperties *)menuConfigurationProperties
{
    MenuConfigurationProperties *properties = [[MenuConfigurationProperties alloc] init];
    
    BOOL isEditableMessage = self.message.conversation.isSelfAnActiveMember && (self.message.deliveryState == ZMDeliveryStateDelivered || self.message.deliveryState == ZMDeliveryStateSent);
    NSMutableArray *additionalItems = [NSMutableArray array];
    if (isEditableMessage) {
         [additionalItems addObject:[[UIMenuItem alloc] initWithTitle:NSLocalizedString(@"message.menu.edit.title", @"") action:@selector(edit:)]];
    }

    UIMenuItem *forwardItem = [UIMenuItem forwardItemWithAction:@selector(forward:)];
    [additionalItems addObject:forwardItem];
    
    properties.additionalItems = additionalItems;
    
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
    CGPoint location = [gestureRecognizer locationInView:self.linkAttachmentViewController.touchableView];
    BOOL hit = CGRectContainsPoint(self.linkAttachmentViewController.touchableView.bounds, location);
    if (! hit || ! self.message.canBeDeleted) {
        gestureRecognizer.enabled = NO;
        gestureRecognizer.enabled = YES;
    }
 
    if (gestureRecognizer.state == UIGestureRecognizerStateBegan) {
        [self showMenu];
    }
}

#pragma mark - TextViewInteractionDelegate

- (BOOL)textView:(LinkInteractionTextView *)textView open:(NSURL *)url
{
    LinkAttachment *linkAttachment = [self.layoutProperties.linkAttachments filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"SELF.URL == %@", url]].lastObject;
    
    if (linkAttachment != nil) {
        [self.analyticsTracker tagExternalLinkVisitEventForAttachmentType:linkAttachment.type
                                                         conversationType:self.message.conversation.conversationType];
    } else {
        [self.analyticsTracker tagExternalLinkVisitEventForAttachmentType:LinkAttachmentTypeNone
                                                         conversationType:self.message.conversation.conversationType];
    }

    return [url open];
}

- (void)textViewDidLongPress:(LinkInteractionTextView *)textView
{
    [self showMenu];
}

@end



@implementation TextMessageCell (ArticleView)

- (void)articleViewWantsToOpenURL:(ArticleView *)articleView url:(NSURL *)url
{
    [self.delegate conversationCell:self didSelectURL:url];
}

- (void)articleViewDidLongPressView:(ArticleView *)articleView
{
    [self showMenu];
}

@end
