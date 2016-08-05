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


#import "ProfileSelfViewController.h"
#import <Classy/Classy.h>
#import "NameField.h"
#import "TextView.h"
#import "UIFont+MagicAccess.h"
#import "FormGuidance.h"
#import "UIColor+MagicAccess.h"
#import "ProfileSelfNameFieldDelegate.h"
#import "WAZUIMagicIOS.h"
#import "UIColor+WAZExtensions.h"


#import "ProfileSelfPictureViewController.h"
#import "ColorPickerController+AccentColors.h"
#import "SelfUserColorPickerController.h"
#import "IdentifiableColor.h"
#import <WireExtensionComponents/WireExtensionComponents.h>
#import "AboutViewController.h"
#import "UIView+Borders.h"
#import "ZMUserSession+iOS.h"
#import "AppDelegate.h"
#import "Constants.h"
#import "ChatHeadsViewController.h"
#import "Settings.h"
#import "ProfileSelfDetailsViewController.h"
#import "IconButton.h"
#import "ActionSheetController.h"
#import "Wire-Swift.h"
#import "UIAlertController+NewSelfClients.h"

#import "AnalyticsTracker.h"
#import "Analytics+iOS.h"
#import "AnalyticsTracker+SelfUser.h"

#import "zmessaging+iOS.h"
#import "Message.h"
#import "NSURL+WireLocale.h"
#import "NSURL+WireURLs.h"
#import "NSLayoutConstraint+Helpers.h"
#import "NSString+Wire.h"
#import <PureLayout.h>
#import "AddressBookHelper.h"

@import MessageUI;




@interface ProfileSelfViewController () <ZMUserObserver, BottomOverlayViewControllerDelegate, UITextFieldDelegate, UIViewControllerTransitioningDelegate, ColorPickerDelegate, ChatHeadsViewControllerDelegate, ProfileSelfDetailsViewControllerDelegate, MFMailComposeViewControllerDelegate>

@property (nonatomic) UIView *containerView;

@property (nonatomic) NameField *nameField;
@property (nonatomic) IconButton *settingsButton;
@property (nonatomic) IconButton *closeButton;
@property (nonatomic) IconButton *themeButton;

@property (nonatomic) CGFloat keyboardHeight;
@property (nonatomic) CGFloat keyboardAnimationLength;
@property (nonatomic) CGFloat nameFieldMaxHeight;
@property (nonatomic) CGFloat colorPickerHeight;

@property (nonatomic) ZMAccentColor selectedAccentColor;
@property (nonatomic) BOOL displayingProfileImage;
@property (nonatomic) FormGuidance *nameFieldFormGuidance;
@property (nonatomic) ProfileSelfNameFieldDelegate *nameFieldDelegate;
@property (nonatomic) ColorPickerController *accentColorPickerController;
@property (nonatomic) ProfileSelfPictureViewController *pictureController;
@property (nonatomic) ChatHeadsViewController *chatHeadsViewController;
@property (nonatomic) ProfileSelfDetailsViewController *profileDetailsViewController;
@property (nonatomic) UILabel *selfPictureTipLabel;
@property (nonatomic) UILabel *accentColorTipLabel;
@property (nonatomic) UILongPressGestureRecognizer *extraSettingsGestureRecognizer;

@property (nonatomic) id <ZMUserObserverOpaqueToken> userObserverToken;

@end



@implementation ProfileSelfViewController

- (void)dealloc
{
    [ZMUser removeUserObserverForToken:self.userObserverToken];
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewDidLoad
{
	[super viewDidLoad];
    
    // If this is not set, the first scrollview encountered is adjusted with insets for the status bar.
    self.automaticallyAdjustsScrollViewInsets = NO;
    self.definesPresentationContext = YES;
    
    self.containerView = [[UIView alloc] init];
    self.containerView.translatesAutoresizingMaskIntoConstraints = NO;
    self.containerView.layoutMargins = [WAZUIMagic edgeInsetsForIdentified:@"self.content_insets"];
    [self.view addSubview:self.containerView];
    [self.containerView autoPinEdgesToSuperviewEdgesWithInsets:UIEdgeInsetsZero];
    
    [self loadMagicValues];
    [self setupNameField];
    [self setupCloseButton];
    [self setupProfileDetailsViewController];
    [self setupAccentColorPicker];
    [self setupSettingsButton];
    [self setupChatHeadsViewController];
    [self setupTips];
    
    if (IS_IPHONE) {
        [self setupThemeButton];
    }
    
    [self createInitialConstraints];

    // tap recognizer for global dismissing
    [self setupGestureRecognizers];
    self.userObserverToken = [ZMUser addUserObserver:self forUsers:@[[ZMUser selfUser]] inUserSession:[ZMUserSession sharedSession]];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardFrameWillChange:) name:UIKeyboardWillChangeFrameNotification object:nil];
}

- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
    [self updateTips];
}

- (void)viewDidAppear:(BOOL)animated
{
	[super viewDidAppear:animated];

	[[Analytics shared] tagScreen:@"SELF_PROFILE"];
    
    if (! IS_IPAD) {
        // We are presenting the self profile screen so mark it as the last viewed screen
        [Settings sharedSettings].lastViewedScreen = SettingsLastScreenSelfProfile;
    }
    
    [self presentNewLoginAlertControllerIfNeeded];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [self.nameFieldDelegate forceEndEditing];
}

- (BOOL)prefersStatusBarHidden
{
    return YES;
}

- (void)prepareForDismissal
{
    self.themeButton.hidden = YES;
}

- (void)setupGestureRecognizers
{
	UITapGestureRecognizer *tapper = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(didTap:)];
	[self.view addGestureRecognizer:tapper];
    
    self.extraSettingsGestureRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self
                                                                                        action:@selector(didLongPressForExtraSettings:)];
}

- (void)loadMagicValues
{
	self.nameFieldMaxHeight = [WAZUIMagic floatForIdentifier:@"profile.name_max_height"];
	self.colorPickerHeight = [WAZUIMagic floatForIdentifier:@"color_picker.height"];
}

- (FormGuidance *)addFormGuidanceBelowField:(UIView *)field
{
	FormGuidance *formGuidance = [[FormGuidance alloc] init];
	formGuidance.translatesAutoresizingMaskIntoConstraints = NO;

	[self addField:formGuidance belowField:field verticalOffset:0];

	return formGuidance;
}

- (void)addField:(UIView *)field belowField:(UIView *)topField verticalOffset:(CGFloat)offSet
{
	[self.containerView addSubview:field];
    [field autoPinEdgeToSuperviewMargin:ALEdgeLeft];
    [field autoPinEdgeToSuperviewMargin:ALEdgeRight];
    [field autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom  ofView:topField withOffset:offSet];
}

- (void)setupAccentColorPicker
{
    ZMAccentColor indexedAccentColor = [UIColor indexedAccentColor];
    NSArray *accentColors = [ColorPickerController defaultAccentColors];
    IdentifiableColor *selectedColor = [accentColors wr_identifiableColorByTag:indexedAccentColor];
    
    self.accentColorPickerController = [[SelfUserColorPickerController alloc] initWithColors:accentColors];
    self.accentColorPickerController.view.translatesAutoresizingMaskIntoConstraints = NO;
    self.accentColorPickerController.selectedColor = selectedColor;
	self.accentColorPickerController.delegate = self;

    [self addChildViewController:self.accentColorPickerController];
    [self.containerView addSubview:self.accentColorPickerController.view];
    [self.accentColorPickerController didMoveToParentViewController:self];
}

- (void)setupCloseButton
{
    IconButton *closeButton = [IconButton iconButtonCircularLight];
    closeButton.translatesAutoresizingMaskIntoConstraints = NO;
    [closeButton setIcon:ZetaIconTypeX withSize:ZetaIconSizeTiny forState:UIControlStateNormal];

    closeButton.accessibilityIdentifier = @"CloseButton";

    [self.containerView addSubview:closeButton];

    [closeButton addTarget:self action:@selector(onCloseButtonTouchUpInside:) forControlEvents:UIControlEventTouchUpInside];
    
    self.closeButton = closeButton;
}

- (void)setupSettingsButton
{
    IconButton *settingsButton = [IconButton iconButtonCircularLight];
    settingsButton.translatesAutoresizingMaskIntoConstraints = NO;
    [settingsButton setIcon:ZetaIconTypeElipsis withSize:ZetaIconSizeTiny forState:UIControlStateNormal];
    settingsButton.accessibilityIdentifier = @"SettingsButton";
    [settingsButton autoSetDimension:ALDimensionWidth toSize:[WAZUIMagic floatForIdentifier:@"self.settings_button_size"]];
    [settingsButton autoMatchDimension:ALDimensionHeight toDimension:ALDimensionWidth ofView:settingsButton];

    [self.containerView addSubview:settingsButton];
    
    
    [settingsButton addTarget:self action:@selector(onSettingsButtonTouchUpInside:) forControlEvents:UIControlEventTouchUpInside];
    self.settingsButton = settingsButton;
}

- (void)setupThemeButton
{
    IconButton *themeButton = [IconButton iconButtonCircularLight];
    themeButton.translatesAutoresizingMaskIntoConstraints = NO;
    [themeButton setIcon:ZetaIconTypeLightBulb withSize:ZetaIconSizeTiny forState:UIControlStateNormal];
    themeButton.accessibilityIdentifier = @"ThemeButton";
    [themeButton addTarget:self action:@selector(switchColorScheme:) forControlEvents:UIControlEventTouchUpInside];
    [themeButton autoSetDimension:ALDimensionWidth toSize:[WAZUIMagic floatForIdentifier:@"self.settings_button_size"]];
    [themeButton autoMatchDimension:ALDimensionHeight toDimension:ALDimensionWidth ofView:themeButton];
    themeButton.selected = [[Settings sharedSettings] colorScheme] == SettingsColorSchemeLight;
    
    [self.containerView addSubview:themeButton];
    
    self.themeButton = themeButton;
}

- (void)setupChatHeadsViewController
{
    self.chatHeadsViewController = [[ChatHeadsViewController alloc] init];
    self.chatHeadsViewController.delegate = self;
    self.chatHeadsViewController.view.translatesAutoresizingMaskIntoConstraints = NO;
    [self addChildViewController:self.chatHeadsViewController];
    [self.containerView addSubview:self.chatHeadsViewController.view];
    [self.chatHeadsViewController didMoveToParentViewController:self];
}

- (void)setupNameField
{
    self.nameField = [NameField nameField];
    
    self.nameField.translatesAutoresizingMaskIntoConstraints = NO;
    self.nameField.textView.keyboardAppearance = UIKeyboardAppearanceDark;
    [self.nameField configureWithMagicKeypath:@"profile.name_field"];
    self.nameField.shouldHighlightOnFocus = YES;
    self.nameField.shouldPresentHint = YES;

    self.nameField.textView.textContainer.lineFragmentPadding = 0.0f;

    UIFont *font = [UIFont fontWithMagicIdentifier:@"style.text.normal.font_spec_bold"];
    self.nameField.textView.font = font;
    [self.containerView addSubview:self.nameField];
    
    [self reloadUi];

    self.nameField.textView.placeholder = [NSLocalizedString(@"name.placeholder", nil) uppercaseStringWithCurrentLocale];
    self.nameField.textView.placeholderTextContainerInset = UIEdgeInsetsMake(13, 10, 0, 0);
    self.nameField.textView.placeholderFont = [UIFont fontWithMagicIdentifier:@"style.text.small.font_spec_light"];
    self.nameField.textView.editable = YES;

    self.nameFieldDelegate = [[ProfileSelfNameFieldDelegate alloc] initWithController:self field:self.nameField];
    self.nameField.textView.delegate = self.nameFieldDelegate;
    self.nameFieldFormGuidance = [self addFormGuidanceBelowField:self.nameField];
    self.nameFieldDelegate.formGuidance = self.nameFieldFormGuidance;

    self.nameField.accessibilityIdentifier = @"ProfileSelfNameField";
    
    CGFloat settingsButtonWidth = [WAZUIMagic floatForIdentifier:@"self.settings_button_size"];
    UIEdgeInsets insets = self.nameField.textView.textContainerInset;
    self.nameField.textView.textContainerInset = UIEdgeInsetsMake(insets.top, insets.left, insets.bottom, insets.right + settingsButtonWidth);
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(nameTextFieldDidBeginEditing:)
                                                 name:UITextViewTextDidBeginEditingNotification
                                               object:self.nameField.textView];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(nameTextFieldDidEndEditing:)
                                                 name:UITextViewTextDidEndEditingNotification
                                               object:self.nameField.textView];
}

- (void)setupProfileDetailsViewController
{
    self.profileDetailsViewController = [[ProfileSelfDetailsViewController alloc] init];
    self.profileDetailsViewController.analyticsTracker = [AnalyticsTracker analyticsTrackerWithContext:@"profile"];
    self.profileDetailsViewController.delegate = self;
    self.profileDetailsViewController.view.translatesAutoresizingMaskIntoConstraints = NO;
    [self addChildViewController:self.profileDetailsViewController];
    [self.containerView addSubview:self.profileDetailsViewController.view];
    [self.profileDetailsViewController didMoveToParentViewController:self];
    
    [self.profileDetailsViewController.view autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.nameField];
    [self.profileDetailsViewController.view autoPinEdgeToSuperviewMargin:ALEdgeLeft];
    [self.profileDetailsViewController.view autoPinEdgeToSuperviewMargin:ALEdgeRight];
}

- (void)setupTips
{
    self.selfPictureTipLabel = [UILabel new];
    self.selfPictureTipLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.selfPictureTipLabel.font = [UIFont fontWithMagicIdentifier:@"style.text.small.font_spec_light"];
    self.selfPictureTipLabel.textColor = [UIColor colorWithMagicIdentifier:@"style.color.static_foreground.faded"];
    self.selfPictureTipLabel.text = [NSLocalizedString(@"self.settings.tip.change_picture", "")
                                     transformStringWithMagicKey:@"self.settings_pic_tip.text_transform"];
    [self.containerView addSubview:self.selfPictureTipLabel];
    
    self.accentColorTipLabel = [UILabel new];
    self.accentColorTipLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.accentColorTipLabel.font = [UIFont fontWithMagicIdentifier:@"style.text.small.font_spec_light"];
    self.accentColorTipLabel.textColor = [UIColor colorWithMagicIdentifier:@"style.color.static_foreground.faded"];
    self.accentColorTipLabel.text = [NSLocalizedString(@"self.settings.tip.change_color", "")
                                     transformStringWithMagicKey:@"self.settings_accent_color_tip.text_transform"];
    [self.containerView addSubview:self.accentColorTipLabel];
}

- (void)createInitialConstraints
{
    [self.chatHeadsViewController.view autoPinEdgesToSuperviewEdgesWithInsets:UIEdgeInsetsZero excludingEdge:ALEdgeBottom];
    
    if (self.themeButton != nil) {
        [self.accentColorPickerController.view autoPinEdge:ALEdgeLeft toEdge:ALEdgeRight ofView:self.themeButton withOffset:16];
    } else {
        [self.accentColorPickerController.view autoPinEdgeToSuperviewMargin:ALEdgeLeft];
    }
    
    [self.themeButton autoPinEdgeToSuperviewMargin:ALEdgeLeft];
    [self.themeButton autoAlignAxis:ALAxisHorizontal toSameAxisOfView:self.accentColorPickerController.view];
    
    [self.closeButton autoSetDimension:ALDimensionHeight toSize:[WAZUIMagic floatForIdentifier:@"self.close_button_size"]];
    [self.closeButton autoMatchDimension:ALDimensionHeight toDimension:ALDimensionWidth ofView:self.closeButton];
    [self.closeButton autoPinEdgeToSuperviewMargin:ALEdgeRight];
    [self.closeButton autoPinEdgeToSuperviewMargin:ALEdgeTop];
    
    [self.settingsButton autoAlignAxis:ALAxisHorizontal toSameAxisOfView:self.accentColorPickerController.view];
    [self.settingsButton autoPinEdgeToSuperviewMargin:ALEdgeRight];
    [self.settingsButton autoPinEdge:ALEdgeLeft toEdge:ALEdgeRight ofView:self.accentColorPickerController.view withOffset:16];
    [self.settingsButton autoPinEdgeToSuperviewMargin:ALEdgeBottom];
    
    [self.nameField addConstraintForMinHeight:40];
    NSLayoutConstraint *leftMarginConstraint = [self.nameField autoPinEdgeToSuperviewMargin:ALEdgeLeft];
    leftMarginConstraint.constant = -self.nameField.textView.textContainerInset.left;
    [self.nameField autoPinEdgeToSuperviewMargin:ALEdgeRight];
    [self.nameField autoPinEdgeToSuperviewMargin:ALEdgeTop];
    
    [self.selfPictureTipLabel autoCenterInSuperview];
    [self.accentColorTipLabel autoAlignAxisToSuperviewAxis:ALAxisVertical];
    
    CGFloat bottomMargin = [WAZUIMagic floatForIdentifier:@"self.settings_accent_color_tip.bottom_margin"];
    [self.accentColorTipLabel autoPinEdge:ALEdgeBottom
                                   toEdge:ALEdgeTop
                                   ofView:self.accentColorPickerController.view
                               withOffset: - bottomMargin];
}

- (void)updateTips
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    BOOL selfPictureTipCompleted = [defaults boolForKey:UserPrefKeyProfilePictureTipCompleted];
    self.selfPictureTipLabel.hidden = selfPictureTipCompleted;
    self.accentColorTipLabel.hidden = ! selfPictureTipCompleted || [defaults boolForKey:UserPrefKeyAccentColorTipCompleted];
}

#pragma mark - ZMUserObserver

- (void)userDidChange:(UserChangeInfo *)change
{
	[self reloadUi];
}

#pragma mark - Overrides

- (void)reloadUi
{
	self.nameField.textView.text = [ZMUser selfUser].name;
	self.nameField.textView.textColor = [UIColor whiteColor];
	// set correct height of name field in case of multiline layout
    self.nameField.shouldPresentHint = YES;
    self.nameField.shouldHighlightOnFocus = YES;
	[self.nameField showEditingHint];
	dispatch_async(dispatch_get_main_queue(), ^{
		[self.nameField.textView setNeedsUpdateConstraints];
	});

    NSArray *accentColors = self.accentColorPickerController.colors;
    IdentifiableColor *color = [accentColors wr_identifiableColorByTag:[ZMUser selfUser].accentColorValue];
    self.accentColorPickerController.selectedColor = color;
}

- (void)didTap:(id)sender
{
    BOOL isFirstResponder = [self.nameField.textView isFirstResponder];

    if (isFirstResponder) {
        [self.view endEditing:YES];
    }
    else if (! self.displayingProfileImage && [sender locationInView:self.view].y > CGRectGetMaxY(self.profileDetailsViewController.view.frame)) {
        [self presentProfilePicture];
    }
    else {
        [self dismissProfilePicture];
    }
}

- (void)didLongPressForExtraSettings:(UILongPressGestureRecognizer *)longPressRecognizer
{
    [self dismissViewControllerAnimated:YES completion:^{
        [self presentSettingsWithExtraSettings:YES completion:nil];
    }];
}

- (void)onCloseButtonTouchUpInside:(UIButton *)btt
{
    self.accentColorPickerController.view.alpha = 0.0f;
    self.settingsButton.alpha = 0.0f;
    [[ZClientViewController sharedZClientViewController] dismissSelfProfileAnimated:YES];
}

- (IBAction)switchColorScheme:(id)sender
{
    SettingsColorScheme colorScheme = [Settings sharedSettings].colorScheme;
    colorScheme = colorScheme == SettingsColorSchemeLight ? SettingsColorSchemeDark : SettingsColorSchemeLight;
    
    [self.analyticsTracker tagSwitchColorScheme:colorScheme];
    [[Settings sharedSettings] setColorScheme:colorScheme];
    [[UIApplication sharedApplication] wr_updateStatusBarForCurrentControllerAnimated:NO];
    
    self.themeButton.selected = [[Settings sharedSettings] colorScheme] == SettingsColorSchemeLight;
}

- (void)onSettingsButtonTouchUpInside:(UIButton *)btt
{
    [self presentMenuSheetController];
}

- (void)presentNewLoginAlertControllerIfNeeded
{
    NSSet *clientsRequiringUserAttention = ZMUser.selfUser.clientsRequiringUserAttention;
    
    if (clientsRequiringUserAttention.count > 0) {
        [self presentNewLoginAlertControllerWithClients:clientsRequiringUserAttention];
    }
}

- (void)presentNewLoginAlertControllerWithClients:(NSSet *)clients
{
    UIAlertController *newLoginAlertController = [UIAlertController alertControllerForNewSelfClients:clients];
    
    [newLoginAlertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"self.new_device_alert.manage_devices", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        SettingsNavigationController *settingsController = [self presentSettingsWithExtraSettings:NO completion:nil];
        [settingsController openControllerForCellWithIdentifier:[SettingsCellDescriptorFactory settingsDevicesCellIdentifier]];
    }]];
    
    [newLoginAlertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"self.new_device_alert.trust_devices", nil) style:UIAlertActionStyleDefault handler:nil]];
    
    [self presentViewController:newLoginAlertController animated:YES completion:nil];
    
    [[ZMUserSession sharedSession] enqueueChanges:^{
        [self confirmClients:clients];
    }];
}

- (void)confirmClients:(NSSet<UserClient *> *)clients
{
    for (UserClient *userClient in clients) {
        userClient.needsToNotifyUser = false;
    }
}

- (void)presentMenuSheetController
{
    [self presentViewController:[self menuActionSheetController] animated:YES completion:nil];
}

- (ActionSheetController *)menuActionSheetController
{
    ActionSheetController *actionSheetController = [[ActionSheetController alloc] initWithTitle:@"" layout:ActionSheetControllerLayoutList style:ActionSheetControllerStyleDark];
    
    @weakify(self);
    [actionSheetController addAction:[SheetAction actionWithTitle:NSLocalizedString(@"meta.menu.cancel", nil) iconType:ZetaIconTypeNone style:SheetActionStyleCancel handler:^(SheetAction *action) {
        @strongify(self);
        [self dismissViewControllerAnimated:YES completion:nil];
    }]];
    
#if ENABLE_DEVELOPER_MENU
    SheetAction *developerActions = [SheetAction actionWithTitle:@"Developer" iconType:ZetaIconTypeNone handler:^(SheetAction *action) {
        @strongify(self);
        UIAlertController *debugOptionsController = [UIAlertController alertControllerWithTitle:@"Debug Options" message:nil preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *simulateInactivePeriodAction = [UIAlertAction actionWithTitle:@"404 on /notifications (add sys-msg top)"
                                                                               style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [[ZMUser selfUser].managedObjectContext setPersistentStoreMetadata:@"00000000-0000-0000-0000-000000000000" forKey:@"LastUpdateEventID"];
            [debugOptionsController dismissViewControllerAnimated:YES completion:nil];
        }];
        
        UIAlertAction *uploadAddresBookAction = [UIAlertAction actionWithTitle:@"Force upload address book"
                                                               style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                                                                   [AddressBookHelper.sharedHelper forceUploadAddressBook];
                                                                   [debugOptionsController dismissViewControllerAnimated:YES completion:nil];
                                                               }];
        
        UIAlertAction *send500Times = [UIAlertAction actionWithTitle:@"Send next text message 500 times"
                                                                  style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                                                                      [Settings sharedSettings].shouldSend500Messages = YES;
                                                                      [debugOptionsController dismissViewControllerAnimated:YES completion:nil];
                                                                  }];
        
        UIAlertAction *decreaseMaxRecording = [UIAlertAction actionWithTitle:@"Decrease max audio recording to 5 sec"
                                                               style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                                                                   [Settings sharedSettings].maxRecordingDurationDebug = 5;
                                                                   [debugOptionsController dismissViewControllerAnimated:YES completion:nil];
                                                               }];
        
        UIAlertAction *logSnapshot = [UIAlertAction actionWithTitle:@"Make a log snapshot"
                                                              style:UIAlertActionStyleDefault
                                                            handler:^(UIAlertAction * _Nonnull action) {
                                                                
                                                                
                                                                NSURL *cacheDirectory = [[NSFileManager defaultManager] URLForDirectory:NSCachesDirectory inDomain:NSUserDomainMask appropriateForURL:nil create:YES error:nil];
                                                                NSString *filename = [NSString stringWithFormat:@"%@%@.log", [NSBundle mainBundle].bundleIdentifier, [NSDate date]];
                                                                NSString *filepath = [cacheDirectory URLByAppendingPathComponent:filename].path;
                                                                
                                                                ZMLogSnapshot(filepath);
                                                                
                                                                [debugOptionsController dismissViewControllerAnimated:YES completion:nil];
                                                                
                                                                if ([MFMailComposeViewController canSendMail]) { // send mail if we can
                                                                    
                                                                    MFMailComposeViewController *mailComposer = [[MFMailComposeViewController alloc] init];
                                                                    [mailComposer setToRecipients:@[@"ios@wire.com"]];
                                                                    [mailComposer setSubject:@"Logs from Wire"];
                                                                    [mailComposer addAttachmentData:[NSData dataWithContentsOfFile:filepath]
                                                                                           mimeType:@"text/plain"
                                                                                           fileName:filename];
                                                                    mailComposer.mailComposeDelegate = self;
                                                                    [self presentViewController:mailComposer animated:YES completion:nil];
                                                                }
                                                            }];
        
        UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil];
        
        [debugOptionsController addAction:simulateInactivePeriodAction];
        [debugOptionsController addAction:logSnapshot];
        [debugOptionsController addAction:send500Times];
        [debugOptionsController addAction:decreaseMaxRecording];
        [debugOptionsController addAction:uploadAddresBookAction];
        [debugOptionsController addAction:cancelAction];
        
        [self dismissViewControllerAnimated:YES completion:^{
            [self presentViewController:debugOptionsController animated:YES completion:nil];
        }];
    }];
    
    [actionSheetController addAction:developerActions];
#endif
    
    
#if ENABLE_SIGNOUT
    SheetAction *signOutAction = [SheetAction actionWithTitle:NSLocalizedString(@"self.sign_out", @"") iconType:ZetaIconTypeNone handler:^(SheetAction *action) {
        [ZMUserSession resetStateAndExit];
        [[Settings sharedSettings] reset];
        
        @strongify(self);
        [self dismissViewControllerAnimated:YES completion:^{
            [self signOut];
        }];
    }];
    
    signOutAction.accessibilityIdentifier = @"SignOutButton";
    [actionSheetController addAction:signOutAction];
#endif
    
    [actionSheetController addAction:[SheetAction actionWithTitle:NSLocalizedString(@"self.about", nil) iconType:ZetaIconTypeNone handler:^(SheetAction *action) {
        [[Analytics shared]tagAbout];
        
        @strongify(self);
        AboutViewController *aboutViewController = [[AboutViewController alloc] init];
        aboutViewController.backAction = ^{ [self dismissViewControllerAnimated:YES completion:nil]; };
        
        [self dismissViewControllerAnimated:YES completion:^{
            [self presentViewController:aboutViewController animated:YES completion:nil];
        }];
    }]];
    
    [actionSheetController addAction:[SheetAction actionWithTitle:NSLocalizedString(@"self.help_center", nil) iconType:ZetaIconTypeNone handler:^(SheetAction *action) {
        [[Analytics shared] tagHelp];
        [[UIApplication sharedApplication] openURL:[NSURL.wr_supportURL wr_URLByAppendingLocaleParameter]];
    }]];
    
    [actionSheetController addAction:[SheetAction actionWithTitle:NSLocalizedString(@"self.settings", nil) iconType:ZetaIconTypeNone handler:^(SheetAction *action) {
        @strongify(self);
        [self dismissViewControllerAnimated:YES completion:^{
            [self presentSettingsWithExtraSettings:NO completion:nil];
        }];
    }]];
    
    [actionSheetController.view addGestureRecognizer:self.extraSettingsGestureRecognizer];
    
    return actionSheetController;
}

- (SettingsNavigationController *)presentSettingsWithExtraSettings:(BOOL)showExtraSettings
                                                        completion:(void(^)(SettingsNavigationController *))completion
{
    SettingsNavigationController *settingsViewController = [SettingsNavigationController settingsNavigationController];

    if (IS_IPAD) {
        settingsViewController.modalPresentationStyle = UIModalPresentationFormSheet;
    }
    
    [self presentViewController:settingsViewController animated:YES completion:^() {
        if (completion) {
            completion(settingsViewController);
        }
    }];
    return settingsViewController;
}

- (void)presentProfilePicture
{
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:UserPrefKeyProfilePictureTipCompleted];
    [self updateTips];
    
    [self.backgroundViewController setOverrideUser:[ZMUser selfUser]
                                disableColorFilter:YES
                                          animated:YES
                                   completionBlock:^() {
                                       self.displayingProfileImage = YES;
                                   }];

    [self presentProfilePictureOnViewController:self];
}

- (void)presentProfilePictureOnViewController:(UIViewController *)viewController
{
    ProfileSelfPictureViewController *pictureController = [[ProfileSelfPictureViewController alloc] init];
    pictureController.analyticsTracker = self.analyticsTracker;
    pictureController.user = [ZMUser selfUser];
    pictureController.delegate = self;
    self.pictureController = pictureController;
    
    [self presentViewController:pictureController animated:YES completion:nil];
}

- (void)dismissProfilePicture
{
    [self.backgroundViewController setOverrideUser:nil
                                disableColorFilter:NO
                                          animated:YES
                                   completionBlock:^{
                                       self.displayingProfileImage = NO;
                                   }];
    
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)signOut
{
    if (ENABLE_SIGNOUT) {
        [ZMUserSession resetStateAndExit];
    }
}

#pragma mark UITextFieldDelegate

- (void)textFieldDidEndEditing:(UITextField *)textField
{
    [self.analyticsTracker tagNameChanged:self.nameField.textView.text];
    
    if ([ZMUserSession sharedSession].networkState == ZMNetworkStateOffline) {
        self.nameField.textView.text = [ZMUser selfUser].name;
    }
}

#pragma mark - BottomOverlayViewControllerDelegate

- (void)bottomOverlayViewControllerBackgroundTapped:(id)controller
{
    [self dismissProfilePicture];
}

#pragma mark - UIKeyBoard

- (void)keyboardFrameWillChange:(NSNotification *)notification
{

    NSDictionary *userInfo = notification.userInfo;
    CGRect endFrame = [[userInfo objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
    CGRect endFrameInView = [self.view convertRect:endFrame fromView:self.view.window];
    CGFloat keyboardHeight = CGRectGetMaxY(self.view.bounds) - CGRectGetMinY(endFrameInView);
    double animationLength = [[userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue];

    UIViewAnimationCurve const curve = (UIViewAnimationCurve) [userInfo[UIKeyboardAnimationCurveUserInfoKey] intValue];
    UIViewAnimationOptions const options = (UIViewAnimationOptions) (curve << 16);

    self.keyboardHeight = keyboardHeight;
    self.keyboardAnimationLength = (CGFloat) animationLength;

    [UIView animateWithDuration:animationLength
                          delay:0
                        options:options
                     animations:^{
        [self.view layoutIfNeeded];
    }
                     completion:nil];
}



#pragma mark - Name text field listeners

- (void)nameTextFieldDidBeginEditing:(NSNotification *)note
{
    [UIView animateWithAnimationIdentifier:@"profile.name_field.focused_background_show_animation"
                                animations:^{
                                    self.settingsButton.alpha = 0;
                                    self.closeButton.alpha = 0;
                                    self.profileDetailsViewController.view.alpha = 0;
                                }
                                   options:0 completion:nil];
}

- (void)nameTextFieldDidEndEditing:(NSNotification *)note
{
    [UIView animateWithAnimationIdentifier:@"profile.name_field.focused_background_hide_animation"
                                animations:^{
                                    self.settingsButton.alpha = 1;
                                    self.closeButton.alpha = 1;
                                    self.profileDetailsViewController.view.alpha = 1;
                                }
                                   options:0 completion:nil];
}

#pragma mark - ColorPickerDelegate

- (void)colorPickerDidChangePreviewColor:(IdentifiableColor *)color
{
    UIColor *accentColor = [UIColor colorForZMAccentColor:color.tag];
    self.backgroundViewController.overrideFilterColor = accentColor;
    [self.profileDetailsViewController updateAccentColor:accentColor];
}

- (void)colorPickerDidSelectColor:(IdentifiableColor *)color
{
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:UserPrefKeyAccentColorTipCompleted];
    [UIView animateWithDuration:0.25f
                     animations:^{
                         self.accentColorTipLabel.alpha = 0.0f;
                     } completion:^(BOOL finished) {
                         [self updateTips];
                     }];
    
    [[ZMUserSession sharedSession] enqueueChanges:^{
        [ZMUser editableSelfUser].accentColorValue = (ZMAccentColor)color.tag;
    } completionHandler:^{
        self.backgroundViewController.overrideFilterColor = nil;
        [self.profileDetailsViewController updateAccentColor:[UIColor colorForZMAccentColor:color.tag]];
    }];
}

#pragma mark - ChatHeadsViewControllerDelegate

- (BOOL)chatHeadsViewController:(ChatHeadsViewController *)viewController isMessageInCurrentConversation:(id<ZMConversationMessage>)message
{
    return NO;
}

- (BOOL)chatHeadsViewController:(ChatHeadsViewController *)viewController shouldDisplayMessage:(id<ZMConversationMessage>)message
{
    if (IS_IPAD && IS_IPAD_LANDSCAPE_LAYOUT) {
        // no notifications in landscape
        return NO;
    }

    return [Message isPresentableAsNotification:message];
}

- (void)chatHeadsViewController:(ChatHeadsViewController *)viewController didSelectMessage:(id<ZMConversationMessage>)message
{
    [[ZClientViewController sharedZClientViewController] selectConversation:message.conversation 
                                                                focusOnView:YES
                                                                   animated:YES];
}

#pragma mark - ProfileSelfDetailsViewControllerDelegate

- (void)profileSelfDetailsViewControllerWillEditDetails
{
    self.backgroundViewController.blurDisabled = NO;
    [self.backgroundViewController setBlurPercentAnimated:1];
    
    [UIView animateWithDuration:0.35 animations:^{
        self.view.alpha = 0;
    }];
}

- (void)profileSelfDetailsViewControllerDidStopEditingDetails
{
    self.backgroundViewController.blurDisabled = YES;
    [self.backgroundViewController setBlurPercentAnimated:0];
    
    [UIView animateWithDuration:0.35 animations:^{
        self.view.alpha = 1;
    }];
}


@end

#pragma mark - Mail Composer

#ifdef ENABLE_DEVELOPER_MENU

@interface ProfileSelfViewController (MailComposer) <MFMailComposeViewControllerDelegate>
@end

@implementation ProfileSelfViewController (MailComposer)

- (void)mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error
{
    [controller dismissViewControllerAnimated:YES completion:nil];
}

@end

#endif
