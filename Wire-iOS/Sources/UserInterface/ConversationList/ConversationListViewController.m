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


#import "ConversationListViewController.h"
#import "ConversationListViewController+Private.h"
#import "ConversationListViewController+Internal.h"

#import "Settings.h"
#import "UIScrollView+Zeta.h"

#import "ZClientViewController.h"
#import "ZClientViewController+Internal.h"

#import "Constants.h"
#import "PermissionDeniedViewController.h"

#import "WireSyncEngine+iOS.h"

#import "ConversationListContentController.h"
#import "StartUIViewController.h"
#import "KeyboardAvoidingViewController.h"

// helpers

#import "Analytics.h"
#import "NSAttributedString+Wire.h"

// Transitions
#import "AppDelegate.h"
#import "Wire-Swift.h"

@interface ConversationListViewController (BottomBarDelegate) <ConversationListBottomBarControllerDelegate>
@end

@interface ConversationListViewController (Archive) <ArchivedListViewControllerDelegate>
@end




@implementation ConversationListViewController

- (void)dealloc
{
    [self removeUserProfileObserver];
}

- (void)removeUserProfileObserver
{
    self.userProfileObserverToken = nil;
}

- (void)setSelectedConversation:(ZMConversation *)conversation
{
    _selectedConversation = conversation;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.viewDidAppearCalled = NO;
    self.definesPresentationContext = YES;

    self.contentControllerBottomInset = 16;
    self.shouldAnimateNetworkStatusView = NO;
    
    self.contentContainer = [[UIView alloc] init];
    self.contentContainer.backgroundColor = [UIColor clearColor];
    [self.view addSubview:self.contentContainer];

    self.userProfile = ZMUserSession.sharedSession.userProfile;

    [self setupObservers];

    self.onboardingHint = [[ConversationListOnboardingHint alloc] init];
    [self.contentContainer addSubview:self.onboardingHint];

    self.conversationListContainer = [[UIView alloc] init];
    self.conversationListContainer.backgroundColor = [UIColor clearColor];
    [self.contentContainer addSubview:self.conversationListContainer];

    [self createNoConversationLabel];
    [self createListContentController];
    [self createBottomBarController];
    [self createTopBar];
    [self createNetworkStatusBar];

    [self createViewConstraints];
    [self.listContentController.collectionView scrollRectToVisible:CGRectMake(0, 0, self.view.bounds.size.width, 1) animated:NO];
    
    [self.topBarViewController didMoveToParentViewController:self];
    
    [self hideNoContactLabelAnimated:NO];
    [self updateNoConversationVisibility];
    [self updateArchiveButtonVisibility];
    
    [self updateObserverTokensForActiveTeam];
    [self showPushPermissionDeniedDialogIfNeeded];

    [self setupStyle];
}

- (void)setStateValue: (ConversationListState)newState
{
    _state = newState;
}

- (void)requestSuggestedHandlesIfNeeded
{
    if (nil == ZMUser.selfUser.handle &&
        ZMUserSession.sharedSession.hasCompletedInitialSync &&
        !ZMUserSession.sharedSession.isPendingHotFixChanges) {
        
        self.userProfileObserverToken = [self.userProfile addObserver:self];
        [self.userProfile suggestHandles];
    }
}


- (void)createNoConversationLabel;
{
    self.noConversationLabel = [[UILabel alloc] init];
    self.noConversationLabel.attributedText = self.attributedTextForNoConversationLabel;
    self.noConversationLabel.numberOfLines = 0;
    [self.contentContainer addSubview:self.noConversationLabel];
}

- (NSAttributedString *)attributedTextForNoConversationLabel
{
    NSMutableParagraphStyle *paragraphStyle = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
    paragraphStyle.paragraphSpacing = 10;
    paragraphStyle.alignment = NSTextAlignmentCenter;

    NSDictionary *titleAttributes = @{
                                      NSForegroundColorAttributeName : [UIColor whiteColor],
                                      NSFontAttributeName : UIFont.smallMediumFont,
                                      NSParagraphStyleAttributeName : paragraphStyle
                                      };

    paragraphStyle.paragraphSpacing = 4;

    NSString *titleLocalizationKey = @"conversation_list.empty.all_archived.message";
    NSString *titleString = NSLocalizedString(titleLocalizationKey, nil);

    NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:[titleString uppercaseString]
                                                                                         attributes:titleAttributes];
    
    return attributedString;
}

- (void)createBottomBarController
{
    self.bottomBarController = [[ConversationListBottomBarController alloc] initWithDelegate:self];
    self.bottomBarController.showArchived = YES;
    [self addChildViewController:self.bottomBarController];
    [self.conversationListContainer addSubview:self.bottomBarController.view];
    [self.bottomBarController didMoveToParentViewController:self];
}

- (ArchivedListViewController *)createArchivedListViewController
{
    ArchivedListViewController *archivedViewController = [ArchivedListViewController new];
    archivedViewController.delegate = self;
    return archivedViewController;
}

- (void)createListContentController
{
    self.listContentController = [[ConversationListContentController alloc] init];
    self.listContentController.collectionView.contentInset = UIEdgeInsetsMake(0, 0, self.contentControllerBottomInset, 0);
    self.listContentController.contentDelegate = self;

    [self addChildViewController:self.listContentController];
    [self.conversationListContainer addSubview:self.listContentController.view];
    [self.listContentController didMoveToParentViewController:self];
}


- (void)setBackgroundColorPreference:(UIColor *)color
{
    [UIView animateWithDuration:0.4 animations:^{
        self.view.backgroundColor = color;
        self.listContentController.view.backgroundColor = color;
    }];
}

#pragma mark - Conversation Collection Vertical Pan Gesture Handling

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    return NO;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRequireFailureOfGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    return YES;
}

- (void)showNoContactLabel;
{
    if (self.state == ConversationListStateConversationList) {
        [UIView animateWithDuration:0.20
                         animations:^{
                             self.noConversationLabel.alpha = self.hasArchivedConversations ? 1.0f : 0.0f;
                             self.onboardingHint.alpha = self.hasArchivedConversations ? 0.0f : 1.0f;
                         }];
    }
}

- (void)hideNoContactLabelAnimated:(BOOL)animated;
{
    [UIView animateWithDuration:animated ? 0.20 : 0.0
                     animations:^{
                         self.noConversationLabel.alpha = 0.0f;
                         self.onboardingHint.alpha = 0.0f;
                     }];
}

- (void)updateNoConversationVisibility;
{
    if (!self.hasConversations) {
        [self showNoContactLabel];
    } else {
        [self hideNoContactLabelAnimated:YES];
    }
}

- (BOOL)hasConversations
{
    ZMUserSession *session = ZMUserSession.sharedSession;
    NSUInteger conversationsCount = [ZMConversationList conversationsInUserSession:session].count +
    [ZMConversationList pendingConnectionConversationsInUserSession:session].count;
    return conversationsCount > 0;
}

- (BOOL)hasArchivedConversations
{
    return [ZMConversationList archivedConversationsInUserSession:ZMUserSession.sharedSession].count > 0;
}

- (void)updateBottomBarSeparatorVisibilityWithContentController:(ConversationListContentController *)controller
{
    CGFloat controllerHeight = CGRectGetHeight(controller.view.bounds);
    CGFloat contentHeight = controller.collectionView.contentSize.height;
    CGFloat offsetY = controller.collectionView.contentOffset.y;
    BOOL showSeparator = contentHeight - offsetY + self.contentControllerBottomInset > controllerHeight;
    
    if (self.bottomBarController.showSeparator != showSeparator) {
        self.bottomBarController.showSeparator = showSeparator;
    }
}

@end
