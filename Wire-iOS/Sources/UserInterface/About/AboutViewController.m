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



#import "AboutViewController.h"
@import WireExtensionComponents;

#import "UIColor+WAZExtensions.h"
#import "UIViewController+Orientation.h"
#import "VersionInfoViewController.h"

#import "zmessaging+iOS.h"


#import "UIFont+MagicAccess.h"
#import "UIView+Borders.h"
#import "UIImage+ZetaIconsNeue.h"
#import "WebViewController.h"
#import "Constants.h"
#import "Analytics+iOS.h"
#import "NSURL+WireURLs.h"
#import "NSURL+WireLocale.h"
#import "NSLayoutConstraint+Helpers.h"
#import "UIImage+ZetaIconsNeue.h"


@interface AboutViewController () <ZMUserObserver>

@property (nonatomic, strong) UIView *containerView;

@property (nonatomic, strong) UIImageView *companyWordmark;
@property (nonatomic, strong) UILabel *companyNameLabel;
@property (nonatomic, strong) UILabel *buildInfoLabel;

@property (nonatomic, strong) UIButton *licenseInformationButton;
@property (nonatomic, strong) UIButton *tosButton;
@property (nonatomic, strong) UIButton *privacyButton;
@property (nonatomic, strong) UIButton *companySiteButton;
@property (nonatomic, strong) UILabel *copyrightInfo;
@property (nonatomic) id <ZMUserObserverOpaqueToken> userObserverToken;

@end



@implementation AboutViewController

- (void)dealloc
{
    [ZMUser removeUserObserverForToken:self.userObserverToken];
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        UIImage *backImage = [[UIImage imageForIcon:ZetaIconTypeChevronLeft iconSize:ZetaIconSizeTiny color:[UIColor whiteColor]] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
        UIButton *backButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [backButton setImage:backImage forState:UIControlStateNormal];
        [backButton addTarget:self action:@selector(closeButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
        backButton.frame = CGRectMake(0, 0, 20, 20);
        self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:backButton];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.userObserverToken = [ZMUser addUserObserver:self forUsers:@[[ZMUser selfUser]] inUserSession:[ZMUserSession sharedSession]];

    self.view.backgroundColor = [UIColor accentColor];

    [self setupContainerView];

    [self setupCompanyWordmark];
    [self setupCopyrightInfo];
    [self setupLicenseInformationButton];
    [self setupPrivacyPolicyButton];
    [self setupTOSButton];
    [self setupCompanyWebSiteButton];
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations
{
    return [self.class wr_supportedInterfaceOrientations];
}

- (void)setupContainerView // to support iPad layout
{
    self.containerView = [[UIView alloc] initWithFrame:CGRectZero];
    self.containerView.translatesAutoresizingMaskIntoConstraints = NO;
    self.containerView.backgroundColor = [UIColor clearColor];
    self.containerView.opaque = NO;
    [self.view addSubview:self.containerView];

    [UIView withPriority:900 setConstraints:^{
        [self.containerView addConstraintsForSize:CGSizeMake(320, 568)];
    }];
    [self.containerView addConstraintsCenteringToView:self.view];
    
    [self.containerView addConstraintForMaxLeftMargin:0 relativeToView:self.view];
    [self.containerView addConstraintForMaxRightMargin:0 relativeToView:self.view];
    NSArray *constraints = [NSLayoutConstraint constraintsWithVisualFormat:@"V:|-(>=0)-[container]-(>=0)-|"
                                                                   options:0 metrics:0 views:@{@"container":self.containerView}];
    [self.view addConstraints:constraints];
}

- (void)setupCompanyWordmark
{
    self.companyWordmark = [[UIImageView alloc] init];
    self.companyWordmark.translatesAutoresizingMaskIntoConstraints = NO;

    [self.containerView addSubview:self.companyWordmark];

    [self.companyWordmark addConstraintForAligningHorizontallyWithView:self.containerView];
    [self.companyWordmark addConstraintForTopMargin:180 relativeToView:self.containerView];

    UIImage *wordmarkImage = [UIImage imageForWordmarkWithColor:[UIColor whiteColor]];
    self.companyWordmark.image = wordmarkImage;
    self.companyWordmark.contentMode = UIViewContentModeScaleAspectFit;
}

- (void)setupCopyrightInfo
{
    self.copyrightInfo = [[UILabel alloc] init];
    self.copyrightInfo.translatesAutoresizingMaskIntoConstraints = NO;
    [self.containerView addSubview:self.copyrightInfo];
    
    NSString *shortVersion = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"];
    NSString *buildNumber = [[[NSBundle mainBundle] infoDictionary] objectForKey:(NSString *) kCFBundleVersionKey];
    NSString *version = [NSString stringWithFormat:@"%@ (%@)", shortVersion, buildNumber];

    NSDate *currentDate = [NSDate date];
    NSUInteger currentYear = [[NSCalendar currentCalendar] component:NSCalendarUnitYear fromDate:currentDate];
    if (currentYear < 2014) {
        currentYear = 2014;
    }

    NSString *copyrightInfo = [NSString stringWithFormat:NSLocalizedString(@"about.copyright.title", @"Copyright Info"), currentYear];

    self.copyrightInfo.text = [NSString stringWithFormat:@"%@ • version %@", copyrightInfo, version];
    self.copyrightInfo.font = [UIFont fontWithMagicIdentifier:@"about_zeta.copyright_font"];
    self.copyrightInfo.textColor = [UIColor whiteColor];
    
    [self.copyrightInfo addConstraintForAligningBottomToBottomOfView:self.containerView distance:24];
    [self.copyrightInfo addConstraintForAligningHorizontallyWithView:self.containerView];
    
    UITapGestureRecognizer *tripleTapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(versionMenuTripleTap)];
    tripleTapGestureRecognizer.numberOfTapsRequired = 3;
    [self.copyrightInfo addGestureRecognizer:tripleTapGestureRecognizer];
    self.copyrightInfo.userInteractionEnabled = YES;
}

- (void)setupPrivacyPolicyButton
{
    self.privacyButton = [UIButton buttonWithType:UIButtonTypeSystem];
    self.privacyButton.translatesAutoresizingMaskIntoConstraints = NO;
    [self.containerView addSubview:self.privacyButton];

    [self.privacyButton addConstraintForAligningBottomToTopOfView:self.licenseInformationButton distance:6];
    [self.privacyButton addConstraintForAligningHorizontallyWithView:self.containerView];
    [self.privacyButton addConstraintForHeight:20];

    self.privacyButton.titleLabel.font = [UIFont fontWithMagicIdentifier:@"about_zeta.legal_font"];
    [self.privacyButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [self.privacyButton setTitle:NSLocalizedString(@"about.privacy.title", @"Privacy Policy") forState:UIControlStateNormal];
    [self.privacyButton addTarget:self action:@selector(privacyButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
}

- (void)setupTOSButton
{
    self.tosButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.tosButton.translatesAutoresizingMaskIntoConstraints = NO;
    [self.containerView addSubview:self.tosButton];

    [self.tosButton addConstraintForAligningBottomToTopOfView:self.privacyButton distance:6];
    [self.tosButton addConstraintForAligningHorizontallyWithView:self.containerView];
    [self.tosButton addConstraintForHeight:20];

    self.tosButton.titleLabel.font = [UIFont fontWithMagicIdentifier:@"about_zeta.legal_font"];
    [self.tosButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [self.tosButton setTitle:NSLocalizedString(@"about.tos.title", @"Terms Of Service") forState:UIControlStateNormal];
    [self.tosButton addTarget:self action:@selector(tosButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
}

- (void)setupLicenseInformationButton
{
    self.licenseInformationButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.licenseInformationButton.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.licenseInformationButton];

    [self.licenseInformationButton addConstraintForAligningBottomToTopOfView:self.copyrightInfo distance:54];
    [self.licenseInformationButton addConstraintForAligningHorizontallyWithView:self.containerView];
    [self.licenseInformationButton addConstraintForHeight:20];

    self.licenseInformationButton.titleLabel.font = [UIFont fontWithMagicIdentifier:@"about_zeta.legal_font"];
    [self.licenseInformationButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [self.licenseInformationButton setTitle:NSLocalizedString(@"about.license.title", @"Third Party Attributions") forState:UIControlStateNormal];
    [self.licenseInformationButton addTarget:self action:@selector(licenseInformationButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
}

- (void)setupCompanyWebSiteButton
{
    self.companySiteButton = [UIButton buttonWithType:UIButtonTypeSystem];
    self.companySiteButton.translatesAutoresizingMaskIntoConstraints = NO;
    [self.containerView addSubview:self.companySiteButton];
    
    [self.companySiteButton addConstraintForAligningBottomToTopOfView:self.tosButton distance:48];
    [self.companySiteButton addConstraintForAligningHorizontallyWithView:self.containerView];
    
    self.companySiteButton.titleLabel.font = [UIFont fontWithMagicIdentifier:@"about_zeta.website_font"];
    [self.companySiteButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [self.companySiteButton setTitle:NSLocalizedString(@"about.website.title", @"Website Title") forState:UIControlStateNormal];
    [self.companySiteButton addTarget:self action:@selector(companySiteButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
}


#pragma mark - ZMUserObserver

- (void)userDidChange:(UserChangeInfo *)change
{
	if (change.accentColorValueChanged) {
        self.view.backgroundColor = [UIColor accentColor];
	}
}

#pragma mark - Button Taps

- (void)versionMenuTripleTap
{
    VersionInfoViewController *versionInfoController = [VersionInfoViewController new];
    [self presentViewController:versionInfoController animated:YES completion:nil];
}

- (void)closeButtonTapped:(id)sender
{
    if (self.backAction) {
        self.backAction();
    }
}

- (void)licenseInformationButtonTapped:(id)sender
{
    WebViewController *vc = [WebViewController webViewControllerWithURL:[NSURL.wr_licenseInformationURL wr_URLByAppendingLocaleParameter]];
    [self presentViewController:vc animated:YES completion:nil];

    [[Analytics shared] tagViewedLicenseInformation];
}

- (void)tosButtonTapped:(id)sender
{
    WebViewController *vc = [WebViewController webViewControllerWithURL:[NSURL.wr_termsOfServicesURL wr_URLByAppendingLocaleParameter]];
    [self presentViewController:vc animated:YES completion:^{
        [[Analytics shared] tagViewedTOSFromPage:TOSOpenedFromTypeAboutPage];
    }];
}

- (void)privacyButtonTapped:(id)sender
{
    WebViewController *vc = [WebViewController webViewControllerWithURL:[NSURL.wr_privacyPolicyURL wr_URLByAppendingLocaleParameter]];
    [self presentViewController:vc animated:YES completion:nil];
    [[Analytics shared] tagViewedPrivacyPolicy];
}

- (void)companySiteButtonTapped:(id)sender
{
    [[UIApplication sharedApplication] openURL:[NSURL.wr_websiteURL wr_URLByAppendingLocaleParameter]];
}

@end
