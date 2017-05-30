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


#import "StartUIView.h"
#import <PureLayout/PureLayout.h>
#import "WAZUIMagicIOS.h"
@import WireExtensionComponents;
#import "PeoplePickerEmptyResultsView.h"
#import "StartUIQuickActionsBar.h"
#import "UIView+Zeta.h"
#import "IconButton.h"
#import "UIResponder+FirstResponder.h"

@interface StartUIView ()
@property (nonatomic, copy) NSString *emptyResultsViewTitle;
@property (nonatomic, copy) NSString *emptyResultsViewMessage;

@property (nonatomic, strong) PeoplePickerEmptyResultsView *emptyResultView;

@property (nonatomic) CGFloat keyboardHeight;
@property (nonatomic) NSLayoutConstraint *actionsBarBottomOffset;

@property (nonatomic) CGRect currentLayoutBounds;
@end

@implementation StartUIView

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardFrameDidChange:) name:UIKeyboardWillChangeFrameNotification object:nil];

        [self setupEmptySpinner];
        [self setupEmptyResultsActions];
        [self setupCollectionView];
        [self setupQuickActionsBar];
        
        [self createConstraints];
    }
    return self;
}

- (void)setupEmptySpinner
{
    self.emptySpinnerView = [[ProgressSpinner alloc] init];
    self.emptySpinnerView.accessibilityIdentifier = @"EmptySearchView_spinner";
    self.emptySpinnerView.translatesAutoresizingMaskIntoConstraints = NO;
    self.emptySpinnerView.hidesWhenStopped = YES;
    
    [self addSubview:self.emptySpinnerView];
}

- (void)setupCollectionView
{
    self.layout = [[UICollectionViewFlowLayout alloc] init];
    self.layout.scrollDirection = UICollectionViewScrollDirectionVertical;
    
    self.layout.minimumInteritemSpacing = 12;
    self.layout.minimumLineSpacing = 0;
    
    self.collectionView = [[UICollectionView alloc] initWithFrame:CGRectZero
                                             collectionViewLayout:self.layout];
    self.collectionView.translatesAutoresizingMaskIntoConstraints = NO;
    self.collectionView.backgroundColor = [UIColor clearColor];
    self.collectionView.bounces = YES;
    self.collectionView.alwaysBounceVertical = YES;
    self.collectionView.allowsMultipleSelection = YES;
    self.collectionView.keyboardDismissMode = UIScrollViewKeyboardDismissModeOnDrag;
    [self addSubview:self.collectionView];
}

- (void)setupQuickActionsBar
{
    self.quickActionsBar = [[StartUIQuickActionsBar alloc] initForAutoLayout];
    [self addSubview:self.quickActionsBar];
}

- (void)createConstraints
{
    [self.emptySpinnerView autoCenterInSuperview];
    [self.collectionView autoPinEdgeToSuperviewEdge:ALEdgeTop];
    [self.collectionView autoPinEdgeToSuperviewEdge:ALEdgeLeft];
    [self.collectionView autoPinEdgeToSuperviewEdge:ALEdgeRight];
    [self.collectionView autoPinEdge:ALEdgeBottom toEdge:ALEdgeTop ofView:self.quickActionsBar];
    
    
    [self.quickActionsBar autoPinEdgeToSuperviewEdge:ALEdgeLeft];
    [self.quickActionsBar autoPinEdgeToSuperviewEdge:ALEdgeRight];
    self.actionsBarBottomOffset = [self.quickActionsBar autoPinEdgeToSuperviewEdge:ALEdgeBottom];
    
    [self.quickActionsBar layoutIfNeeded];
    
    self.collectionView.contentInset = UIEdgeInsetsMake(8, 0, self.quickActionsBar.bounds.size.height + 24.0f, 0);
}

- (void)setupEmptyResultsActions
{
    UIColor *iconColor = [UIColor whiteColor];
    
    self.sendInviteActionView = [[PeoplePickerEmptyResultsActionView alloc] initWithTitle:NSLocalizedString(@"peoplepicker.no_matching_results.action.send_invite", @"")
                                                                                     icon:ZetaIconTypeEnvelope
                                                                          foregroundColor:iconColor
                                                                                   target:nil
                                                                                   action:nil];
    
    self.sendInviteActionView.accessibilityIdentifier = @"EmptySearch_SendInviteButton";
    self.shareContactsActionView = [[PeoplePickerEmptyResultsActionView alloc] initWithTitle:NSLocalizedString(@"peoplepicker.no_matching_results.action.share_contacts", @"")
                                                                                        icon:ZetaIconTypeExport
                                                                             foregroundColor:iconColor
                                                                                      target:nil
                                                                                      action:nil];
    
    self.shareContactsActionView.accessibilityIdentifier = @"EmptySearch_ShareContactsButton";
}

- (void)layoutSubviews
{
    if (! CGRectEqualToRect(self.currentLayoutBounds, self.bounds)) {
        [self.collectionView.collectionViewLayout invalidateLayout];
    }
    
    self.currentLayoutBounds = self.bounds;
    
    [super layoutSubviews];
}

#pragma mark - Progress view

- (void)showSearchProgressView
{
    self.emptySpinnerView.animating = YES;
}

- (void)hideSearchProgressView
{
    self.emptySpinnerView.animating = NO;
}

#pragma mark - Empty results view

- (void)reshowEmptyResultsView
{
    [self showEmptyResultsViewWithMessage:self.emptyResultsViewMessage
                                    title:self.emptyResultsViewTitle
                         showInviteAction:self.emptyResultsShowInviteAction
                  showShareContactsAction:self.emptyResultsShowShareContactsAction];
}

- (void)showEmptyResultsViewWithMessage:(NSString *)message
                                  title:(NSString *)title
                       showInviteAction:(BOOL)showInviteAction
                showShareContactsAction:(BOOL)showShareContactsAction
{
    self.emptyResultsViewMessage = message;
    self.emptyResultsViewTitle = title;
    self.emptyResultsShowInviteAction = showInviteAction;
    self.emptyResultsShowShareContactsAction = showShareContactsAction;
    
    
    if (! self.emptyResultView.superview) {
        self.emptyResultView = [PeoplePickerEmptyResultsView peoplePickerEmptyResultsView];
        self.emptyResultView.translatesAutoresizingMaskIntoConstraints = NO;
        [self addSubview:self.emptyResultView];
        
        [self.emptyResultView autoPinEdge:ALEdgeTop toEdge:ALEdgeTop ofView:self.collectionView withOffset:0];
        [self.emptyResultView autoPinEdgeToSuperviewEdge:ALEdgeLeft withInset:0];
        [self.emptyResultView autoPinEdgeToSuperviewEdge:ALEdgeRight withInset:0];
        
        [NSLayoutConstraint autoSetPriority:UILayoutPriorityDefaultHigh forConstraints:^{
            [self.emptyResultView autoPinEdge:ALEdgeBottom toEdge:ALEdgeBottom ofView:self.collectionView withOffset:self.keyboardHeight];
        }];
    }
    
    NSMutableAttributedString *string = [[NSMutableAttributedString alloc] init];
    
    UIColor *textColor = [UIColor whiteColor];
    
    UIFont *font = [UIFont fontWithMagicIdentifier:@"style.text.normal.font_spec"];
    NSMutableParagraphStyle *paragraphStyle = [NSMutableParagraphStyle new];
    paragraphStyle.alignment = NSTextAlignmentCenter;
    
    if (title.length != 0) {
        NSAttributedString *titleString = [[NSAttributedString alloc] initWithString:title attributes:@{NSFontAttributeName : font,
                                                                                                        NSForegroundColorAttributeName : textColor,
                                                                                                        NSParagraphStyleAttributeName : paragraphStyle
                                                                                                        }];
        [string appendAttributedString:titleString];
    }
    
    if (message.length != 0) {
        [string appendAttributedString:[[NSAttributedString alloc] initWithString:@"\n" attributes:@{NSParagraphStyleAttributeName: paragraphStyle}]];
        
        NSAttributedString *messageString = [[NSAttributedString alloc] initWithString:message attributes:@{NSFontAttributeName : font,
                                                                                                            NSForegroundColorAttributeName : textColor,
                                                                                                            NSParagraphStyleAttributeName : paragraphStyle
                                                                                                            }];
        [string appendAttributedString:messageString];
    }
    
    self.emptyResultView.messageTextView.attributedText = [[NSAttributedString alloc] initWithAttributedString:string];
    
    [self setEmptyResultsActionView:self.sendInviteActionView visible:self.emptyResultsShowInviteAction];
    [self setEmptyResultsActionView:self.shareContactsActionView visible:self.emptyResultsShowShareContactsAction];
}

- (void)setEmptyResultsActionView:(PeoplePickerEmptyResultsActionView *)actionView visible:(BOOL)visible
{
    if (visible) {
        if (! [self.emptyResultView.actionViews containsObject:actionView]) {
            [self.emptyResultView addActionView:actionView];
        }
    } else {
        NSUInteger index = [self.emptyResultView.actionViews indexOfObject:actionView];
        if (index != NSNotFound) {
            [self.emptyResultView removeActionViewAtIndex:index];
        }
    }
}

- (void)showEmptySearchResultsViewForSuggestedUsersShowingShareContacts:(BOOL)showShareContacts
{
    [self showEmptyResultsViewWithMessage:@""
                                    title:NSLocalizedString(@"peoplepicker.share_contacts.no_results.title", @"")
                         showInviteAction:YES
                  showShareContactsAction:showShareContacts];
}

- (void)showEmptySearchResultsAfterAddressBookUpload
{
    [self showEmptyResultsViewWithMessage:NSLocalizedString(@"peoplepicker.no_matching_results_message", @"")
                                    title:NSLocalizedString(@"peoplepicker.no_matching_results_title", @"")
                         showInviteAction:YES
                  showShareContactsAction:NO];
}

- (void)showEmptySearchResultsViewForEmail:(BOOL)email showShareContacts:(BOOL)showShareContacts
{
    if (showShareContacts) {
        
        if (email) {            
            [self showEmptyResultsViewWithMessage:NSLocalizedString(@"peoplepicker.no_matching_results_after_address_book_upload_message", @"")
                                            title:NSLocalizedString(@"peoplepicker.no_matching_results_after_address_book_upload_title", @"")
                                 showInviteAction:YES
                          showShareContactsAction:YES];
        }
        else {
            [self showEmptyResultsViewWithMessage:NSLocalizedString(@"peoplepicker.no_matching_results_provide_valid_email", @"")
                                            title:NSLocalizedString(@"peoplepicker.no_matching_results_after_address_book_upload_title", @"")
                                 showInviteAction:YES
                          showShareContactsAction:YES];
        }
    }
    else {
        if (email) {
            [self showEmptyResultsViewWithMessage:NSLocalizedString(@"peoplepicker.no_matching_results_after_address_book_upload_message", @"")
                                            title:NSLocalizedString(@"peoplepicker.no_matching_results_title", @"")
                                 showInviteAction:YES
                          showShareContactsAction:YES];
        }
        else {
            [self showEmptyResultsViewWithMessage:NSLocalizedString(@"peoplepicker.no_matching_results_provide_valid_email", @"")
                                            title:NSLocalizedString(@"peoplepicker.no_matching_results_after_address_book_upload_title", @"")
                                 showInviteAction:YES
                          showShareContactsAction:YES];
        }
    }
}

- (void)hideEmptyResutsView
{
    [self.emptyResultView removeFromSuperview];
    self.emptyResultView = nil;
}

#pragma mark - Keyboard

- (void)keyboardFrameDidChange:(NSNotification *)notification
{
    UIResponder *firstResponder = [UIResponder wr_currentFirstResponder];
    CGFloat inputAccessoryViewHeight = firstResponder.inputAccessoryView.bounds.size.height;
    
    [UIView animateWithKeyboardNotification:notification
                                     inView:self
                                 animations:^(CGRect keyboardFrameInView) {
                                     // NOTE: we don't attach a input accessory view in the start UI but we do
                                     // in the conversation input bar so we must subtracts its height here.
                                     self.keyboardHeight = keyboardFrameInView.size.height - inputAccessoryViewHeight;
                                     self.actionsBarBottomOffset.constant = -self.keyboardHeight;
                                     [self updateConstraints];
                                     [self layoutIfNeeded];
                                 }
                                 completion:nil];
}

@end
