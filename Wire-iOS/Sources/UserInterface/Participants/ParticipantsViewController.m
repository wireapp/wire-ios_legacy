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


@import PureLayout;
#import <Classy/Classy.h>


#import "ParticipantsViewController.h"
#import "ParticipantsListCell.h"
#import "WAZUIMagicIOS.h"
#import "ZClientViewController.h"
#import "UIScrollView+Zeta.h"
#import "Constants.h"

#import "ParticipantsHeaderView.h"
#import "ParticipantsFooterView.h"

#import "ContactsDataSource.h"

#import "ZMConversation+Validation.h"
#import "ZetaIconTypes.h"
#import "ProfileNavigationControllerDelegate.h"

#import "Analytics.h"
#import "AnalyticsTracker.h"
#import "AnalyticsTracker+Invitations.h"

#import "ProfileViewController.h"

// model
#import "WireSyncEngine+iOS.h"
#import "avs+iOS.h"
#import "StartUIViewController.h"
#import "UIImage+ZetaIconsNeue.h"

#import "ActionSheetController.h"
#import "ZMConversation+Actions.h"
#import "ActionSheetController+Conversation.h"

#import "Wire-Swift.h"


static NSString *const ParticipantCellReuseIdentifier = @"ParticipantListCell";
static NSString *const ParticipantHeaderReuseIdentifier = @"ParticipantListHeader";



@interface ParticipantsViewController (AddParticipants) <AddParticipantsViewControllerDelegate>

@end



@interface ParticipantsViewController (ProfileView) <ProfileViewControllerDelegate>

@end



@interface ParticipantsViewController (HeaderFooter) <ParticipantsHeaderDelegate, ParticipantsFooterDelegate>

@end



@interface ParticipantsViewController () <UICollectionViewDataSource, UICollectionViewDelegate, ZMConversationObserver, UIGestureRecognizerDelegate>

@property (nonatomic) UICollectionView *collectionView;
@property (nonatomic) UICollectionViewFlowLayout *collectionViewLayout;
@property (nonatomic) ParticipantsHeaderView *headerView;
@property (nonatomic) ParticipantsFooterView *footerView;
@property (nonatomic) ProfileNavigationControllerDelegate *navigationControllerDelegate;

@property (nonatomic) UITapGestureRecognizer *tapToDismissEditingGestureRecognizer;

@property (nonatomic) NSMutableSet *userImageObserverTokens;

@property (nonatomic) NSArray *participants;
@property (nonatomic) BOOL ignoreNextNameChange;

// Cosmetic

@property (nonatomic) CGFloat insetMargin;
@property (nonatomic) id conversationObserverToken;

@end




@implementation ParticipantsViewController

- (instancetype)initWithConversation:(ZMConversation *)conversation;
{
    self = [super init];
    
    if (self) {
        self.automaticallyAdjustsScrollViewInsets = NO;
        self.conversation = conversation;
        self.userImageObserverTokens = [NSMutableSet setWithCapacity:5];
        self.navigationControllerDelegate = [[ProfileNavigationControllerDelegate alloc] init];
        
        [self loadMagic];
    }
    
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.navigationController.delegate = self.navigationControllerDelegate;
    
    self.tapToDismissEditingGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onBackgroundTap:)];
    self.tapToDismissEditingGestureRecognizer.delegate = self;
    [self.view addGestureRecognizer:self.tapToDismissEditingGestureRecognizer];

    self.collectionViewLayout = [[UICollectionViewFlowLayout alloc] init];
    self.collectionViewLayout.itemSize = [self itemSizeForMagicPrefix:@"participants"];
    self.collectionViewLayout.sectionInset = UIEdgeInsetsMake(self.insetMargin, self.insetMargin, self.insetMargin, self.insetMargin);
    self.collectionViewLayout.minimumLineSpacing = 0.0f;
    
    self.collectionView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:self.collectionViewLayout];
    self.collectionView.alwaysBounceVertical = YES;
    self.collectionView.translatesAutoresizingMaskIntoConstraints = NO;
    
    [self.collectionView setDataSource:self];
    [self.collectionView setDelegate:self];
    
    [self.collectionView registerClass:[ParticipantsListCell class] forCellWithReuseIdentifier:ParticipantCellReuseIdentifier];
    [self.collectionView setBackgroundColor:[UIColor clearColor]];
    
    [self.view addSubview:self.collectionView];
    [self.collectionView addConstraintsForRightMargin:0 leftMargin:0 relativeToView:self.view];
    
    self.collectionView.allowsSelection = YES;
    self.collectionView.allowsMultipleSelection = NO;
    
    [self addHeader];
    [self addFooter];
    
    [self.collectionView addConstraintForAligningTopToBottomOfView:self.headerView distance:0];
    [self.collectionView addConstraintForAligningBottomToTopOfView:self.footerView distance:0];
    
    self.view.opaque = NO;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    self.headerView.topButtonsHidden = NO;
    [[UIApplication sharedApplication] wr_updateStatusBarForCurrentControllerAnimated:YES];
}

- (BOOL)prefersStatusBarHidden
{
    return NO;
}

- (UIStatusBarStyle)preferredStatusBarStyle
{
    switch ([ColorScheme defaultColorScheme].variant) {
        case ColorSchemeVariantLight:
            return UIStatusBarStyleDefault;
            break;
            
        case ColorSchemeVariantDark:
            return UIStatusBarStyleLightContent;
            break;
    }
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations
{
    return self.wr_supportedInterfaceOrientations;
}

- (void)viewWillAppearCustomPresentationAnimated:(BOOL)animated isInteractive:(BOOL)interactive
{
    self.headerView.topSeparatorLine.hidden = ! self.shouldDrawTopSeparatorLineDuringPresentation;
}

- (void)viewDidAppearCustomPresentationAnimated:(BOOL)animated isInteractive:(BOOL)interactive
{
    self.headerView.topSeparatorLine.hidden = YES;
}

- (void)onBackgroundTap:(id)sender
{
    if (self.headerView.titleView.isFirstResponder) {
        self.ignoreNextNameChange = YES;
        [self.headerView endEditing:YES];
    }
}

- (void)addHeader
{
    self.headerView = [[ParticipantsHeaderView alloc] init];
    self.headerView.translatesAutoresizingMaskIntoConstraints = NO;
    self.headerView.topSeparatorLine.hidden = YES;
    
    [self.view addSubview:self.headerView];
    
    [self.headerView addConstraintForAligningTopToTopOfView:self.view distance:-UIScreen.safeArea.top+20];
    [self.headerView addConstraintsForRightMargin:0 leftMargin:0 relativeToView:self.view];
    [self.headerView setCancelButtonAccessibilityIdentifier:@"metaControllerCancelButton"];
    
    [self reloadUI];
    
    self.headerView.delegate = self;
}

- (void)addFooter
{
    self.footerView = [[ParticipantsFooterView alloc] init];
    self.footerView.translatesAutoresizingMaskIntoConstraints = NO;
    
    [self.view addSubview:self.footerView];
    
    [self.footerView addConstraintForBottomMargin:UIScreen.safeArea.bottom relativeToView:self.view];
    [self.footerView addConstraintsForRightMargin:0 leftMargin:0 relativeToView:self.view];
    
    if ([[ZMUser selfUser] canAddUserToConversation:self.conversation]) {
        [self.footerView setIconTypeForLeftButton:ZetaIconTypeConvMetaAddPerson];
        [self.footerView setTitleForLeftButton:NSLocalizedString(@"participants.add_people_button_title", @"")];
    } else {
        [self.footerView setIconTypeForLeftButton:ZetaIconTypeNone];
    }
    
    [self.footerView setIconTypeForRightButton:ZetaIconTypeEllipsis];
    
    self.footerView.delegate = self;
}

- (void)reloadUI
{
    self.headerView.title = self.conversation.displayName;
    
    NSString *subtitle = [NSString stringWithFormat:NSLocalizedString(@"participants.people.count", @""),
                          (unsigned long)self.conversation.otherActiveParticipants.count, nil];
    if (IS_IPAD_FULLSCREEN) {
        subtitle = [subtitle uppercaseString];
    }
    self.headerView.subtitle = subtitle;
}

- (void)dismissSelfAnimated
{
    if ([self.delegate respondsToSelector:@selector(participantsViewControllerWantsToBeDismissed:)]) {
        [self.delegate participantsViewControllerWantsToBeDismissed:self];
    } else {
        [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
    }
}

- (void)setConversation:(ZMConversation *)conversation
{
    _conversation = conversation;
    
    if (conversation != nil) {
        self.conversationObserverToken = [ConversationChangeInfo addObserver:self forConversation:self.conversation];
    }
    
    self.participants = self.conversation.sortedOtherActiveParticipants;
    
    [self.collectionView reloadData];
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    self.footerView.separatorLine.hidden = ! self.collectionView.isContentOverflowing;
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    CGPoint contentOffset = self.collectionView.contentOffset;
    
    if (self.collectionView.isContentOverflowing && self.collectionView.contentOffset.y - self.insetMargin > 0) {
        self.headerView.separatorLine.hidden = NO;
    }
    else {
        self.headerView.separatorLine.hidden = (contentOffset.y > 0) ? NO: YES;
    }
    
    if (self.collectionView.isContentOverflowing && self.collectionView.scrollOffsetFromBottom > self.collectionView.contentInset.bottom) {
        self.footerView.separatorLine.hidden = NO;
    }
    else {
        self.footerView.separatorLine.hidden = YES;
    }
}

- (void)onTapToResign:(id)sender
{
    [self.headerView.titleView resignFirstResponder];
}

#pragma mark - Magic

- (void)loadMagic
{
    self.insetMargin = 24;
}

- (CGSize)itemSizeForMagicPrefix:(NSString *)prefix
{
    CGSize itemSize = CGSizeMake([WAZUIMagic floatForIdentifier:[prefix stringByAppendingString:@".tile_width"]],
                                 [WAZUIMagic floatForIdentifier:[prefix stringByAppendingString:@".tile_height"]]);
    return itemSize;
}

#pragma mark - Delegates

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return self.participants.count;
}

// The cell that is returned must be retrieved from a call to -dequeueReusableCellWithReuseIdentifier:forIndexPath:
- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    ParticipantsListCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:ParticipantCellReuseIdentifier forIndexPath:indexPath];
    
    [self configureCell:cell atIndexPath:indexPath];
    
    return cell;
}

- (void)configureCell:(ParticipantsListCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
    ZMUser *user = self.participants[indexPath.row];
    [cell updateForUser:user inConversation:self.conversation];
}

#pragma mark - ZMConversationObserver

- (void)conversationDidChange:(ConversationChangeInfo *)change
{
    if (change.nameChanged || change.participantsChanged) {
        // using async dispatch here because when renaming a conversation,
        // text view is still first responder, and we do not want to overwrite
        // the name in that case (that the user may still be editing).
        // when user has committed editing, we resign first responder and do async dispatch,
        // so that in next run loop, the text field is no longer first responder
        // and thus name can be updated
        @weakify(self);
        
        dispatch_async(dispatch_get_main_queue(), ^{
            @strongify(self);
            self.participants = self.conversation.sortedOtherActiveParticipants;
            [self reloadUI];
            [self.collectionView reloadData];
            
        });
    }
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    if ([self.headerView.titleView isFirstResponder]) {
        [self.headerView.titleView resignFirstResponder];
        return;
    }
    
    ZMUser *user = self.participants[indexPath.row];
    
    ProfileViewController *profileViewController = [[ProfileViewController alloc] initWithUser:user conversation:self.conversation];
    profileViewController.delegate = self;
    profileViewController.navigationControllerDelegate = self.navigationControllerDelegate;
    
    UICollectionViewLayoutAttributes *layoutAttributes = [self.collectionView layoutAttributesForItemAtIndexPath:indexPath];
    
    self.navigationControllerDelegate.tapLocation = [self.collectionView convertPoint:layoutAttributes.center toView:self.view];
    
    [self.navigationController pushViewController:profileViewController animated:YES];
}

@end



@implementation ParticipantsViewController (HeaderFooter)

- (void)participantsHeaderView:(ParticipantsHeaderView *)headerView didTapButton:(UIButton *)button
{
    if (headerView.titleView.isFirstResponder) {
        [self setConversationNameIfValid:headerView.titleView.text];
    }
    [self dismissSelfAnimated];
}

- (BOOL)participantsHeaderView:(ParticipantsHeaderView *)headerView textViewShouldBeginEditing:(UITextView *)textView
{
    if ([self.conversation.activeParticipants containsObject:[ZMUser selfUser]]) {
        if (! IS_IPAD_FULLSCREEN) {
            self.collectionView.hidden = YES;
            self.headerView.topButtonsHidden = YES;
            self.headerView.subtitleHidden = YES;
        }
        
        // Pre-check the current conversation name. If it's not valid, we reset
        // the textview to allow user to change the displayName completely.
        // Otherwise, in case the name is too long, the user won't be able to
        // change the name anymore, cause the validators kicks in the name is
        // not changeble
        NSString *conversationName = self.conversation.displayName;
        BOOL isValid = [self.conversation validateName:&conversationName error:NULL];
        if (! isValid) {
            headerView.titleView.text = @"";
        }
        return YES;
    }
    
    return NO;
}

- (BOOL)participantsHeaderView:(ParticipantsHeaderView *)headerView textViewDidEndEditing:(UITextView *)textView
{
    if (! IS_IPAD_FULLSCREEN) {
        self.collectionView.hidden = NO;
        self.headerView.topButtonsHidden = NO;
        self.headerView.subtitleHidden = NO;
    }
    
    if (self.ignoreNextNameChange) {
        self.ignoreNextNameChange = NO;
        self.headerView.title = self.conversation.displayName;
        return YES;
    }
    
    NSString *newName = textView.text;
    if ([newName length] > 0) {
        BOOL isValid = [self.conversation validateName:&newName error:NULL];
        if (! isValid) {
            [self reloadUI];
            return NO;
        }
    }
    
    BOOL couldSetName = [self setConversationNameIfValid:textView.text];
    if ( ! couldSetName) {
        [self reloadUI];
    }
    
    return YES;
}

- (BOOL)participantsHeaderView:(ParticipantsHeaderView *)headerView textView:(UITextView *)textView shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string;
{
    NSString *newName = [textView.text stringByReplacingCharactersInRange:range withString:string];
    if ([newName length] > 0) {
        BOOL isValid = [self.conversation validateName:&newName error:NULL];
        return isValid;
    }
    
    return YES;
}

- (void)participantsFooterView:(ParticipantsFooterView *)footerView rightButtonTapped:(UIButton *)rightButton
{
    if (IS_IPAD_FULLSCREEN && [self.headerView.titleView isFirstResponder]) {
        
        [self.headerView.titleView resignFirstResponder];
        return;
    }
    
    [self presentMenuSheetController];
}

- (void)participantsFooterView:(ParticipantsFooterView *)footerView leftButtonTapped:(UIButton *)leftButton
{
    if (IS_IPAD_FULLSCREEN && [self.headerView.titleView isFirstResponder]) {
        
        [self.headerView.titleView resignFirstResponder];
        return;
    }
    
    [self presentAddParticipantsViewController];
}

- (void)presentMenuSheetController
{
    ActionSheetController *actionSheetController =
    [[ActionSheetController alloc] initWithTitle:self.conversation.displayName
                                          layout:ActionSheetControllerLayoutList
                                           style:[ActionSheetController defaultStyle]];
    
    [actionSheetController addActionsForConversation:self.conversation];
    
    [actionSheetController addAction:[SheetAction actionWithTitle:NSLocalizedString(@"meta.menu.rename", nil) iconType:ZetaIconTypePencil handler:^(SheetAction *action) {
        [self dismissViewControllerAnimated:YES completion:^{
            [self.headerView.titleView becomeFirstResponder];
        }];
    }]];
    
    [self presentViewController:actionSheetController animated:YES completion:nil];
}

- (void)presentAddParticipantsViewController
{    
    AddParticipantsViewController *addParticipantsViewController = [[AddParticipantsViewController alloc] initWithConversation:self.conversation];
    addParticipantsViewController.modalPresentationStyle = UIModalPresentationOverCurrentContext;
    addParticipantsViewController.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
    addParticipantsViewController.delegate = self;
    
    [self presentViewController:addParticipantsViewController animated:YES completion:nil];
}

/// Returns whether the conversation name was valid and could be set as the new name.
- (BOOL)setConversationNameIfValid:(NSString *)newName
{
    BOOL isValid = [self.conversation validateName:&newName error:NULL];
    if ([newName isEqualToString:@""] || ! isValid) {
        return NO;
    }
    
    if (! [newName isEqualToString:self.conversation.userDefinedName]) {
        [[ZMUserSession sharedSession] enqueueChanges:^{
            self.conversation.userDefinedName = newName;
        }];
    }
    return YES;
}

#pragma mark - UIGestureRecognizerDelegate

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch
{
    if ([gestureRecognizer isEqual:self.tapToDismissEditingGestureRecognizer]) {
        return (self.headerView.titleView.isFirstResponder);
    }
    else {
        return YES;
    }
}

@end



@implementation ParticipantsViewController (AddParticipants)

- (void)addParticipantsViewControllerDidCancel:(AddParticipantsViewController *)addParticipantsViewController
{
    [addParticipantsViewController dismissViewControllerAnimated:YES completion:nil];
}

- (void)addParticipantsViewController:(AddParticipantsViewController *)addParticipantsViewController didSelectUsers:(NSSet<ZMUser *> *)users
{
    [addParticipantsViewController dismissViewControllerAnimated:YES completion:^{
        if ([self.delegate respondsToSelector:@selector(participantsViewController:wantsToAddUsers:toConversation:)]) {
            [self.delegate participantsViewController:self wantsToAddUsers:users toConversation:self.conversation];
        }
    }];
}

@end



@implementation ParticipantsViewController (ProfileView)

- (void)profileViewControllerWantsToBeDismissed:(ProfileViewController *)profileViewController completion:(dispatch_block_t)completion
{
    [self.navigationController popViewControllerAnimated:YES];
    [self.navigationController.transitionCoordinator animateAlongsideTransition:nil completion:^(id<UIViewControllerTransitionCoordinatorContext> context) {
        if (completion != nil) completion();
    }];
}

- (void)profileViewController:(ProfileViewController *)controller wantsToNavigateToConversation:(ZMConversation *)conversation
{
    [self dismissViewControllerAnimated:YES completion:^{
        [self.zClientViewController selectConversation:conversation focusOnView:YES animated:YES];
    }];
}

@end
