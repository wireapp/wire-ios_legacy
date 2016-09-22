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


#import "GiphyConfirmImageViewController.h"

#import <PureLayout/PureLayout.h>
@import WireExtensionComponents;
@import Classy;


#import "WAZUIMagicIOS.h"
#import "UIColor+WAZExtensions.h"
#import "FLAnimatedImage.h"
#import "FLAnimatedImageView.h"
#import "Constants.h"
#import "AppDelegate.h"
#import "UIView+Borders.h"
#import "UIImage+ZetaIconsNeue.h"
#import "UIViewController+Orientation.h"
#import "GiphySearchResultsController.h"
#import "NSString+Wire.h"

#import "zmessaging+iOS.h"
#import "ZMUserSession+Additions.h"
#import "GiphyCollectionViewController.h"



#import "Analytics+iOS.h"



static const CGFloat BottomBarMinHeight = 88;
static const CGFloat BottomMarginInset = 24;



@interface GiphyConfirmImageViewController (Randomization)

- (void)excludeZiphFromRandom:(Ziph *)ziph;
- (Ziph *)randomZiph;

@end

@interface GiphyConfirmImageViewController ()

@property (nonatomic) UIButton *titleButton;

@property (nonatomic) UIView *bottomPanel;

@property (nonatomic) UIView *confirmButtonsContainer;

@property (nonatomic) Button *acceptImageButton;
@property (nonatomic) Button *rejectImageButton;

@property (nonatomic) UIView *containerView;
@property (nonatomic) FLAnimatedImageView *imagePreviewView;

@property (nonatomic) NSLayoutConstraint *topBarHeightConstraint;

@property (nonatomic, readwrite) NSData *imageData;
@property (nonatomic) NSUInteger lastPresentedGifIndex;
@property (nonatomic, copy, readwrite) NSString *searchTerm;
@property (nonatomic) Ziph *ziph;
@property (nonatomic) NSError *giphyError;

@property (nonatomic) BOOL didSearchMoreThanOnce;

@property (nonatomic) UIViewController *loadingIndicatorViewController;

@property (nonatomic) NSMutableSet *poolOfUsedZiphs;

@end



@implementation GiphyConfirmImageViewController

- (instancetype)initWithSearchTerm:(NSString *)searchTerm
{
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        
        self.searchTerm = searchTerm;
        
        self.poolOfUsedZiphs = [NSMutableSet set];
    }
    
    return self;
}


- (Ziph *)lastPresentedZiph
{
    NSUInteger index = self.lastPresentedGifIndex;
    
    if (self.giphySearchResultsController.searchResults.count > self.lastPresentedGifIndex) {
        self.lastPresentedGifIndex++;
    }
    
    return self.giphySearchResultsController.searchResults[index];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.view.backgroundColor = UIColor.blackColor;
    
    [self createPreviewPanel];
    [self createBottomPanel];
    [self createLoadingIndicatorViewController];
    [self createInitialConstraints];
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations
{
    return [self.class wr_supportedInterfaceOrientations];
}

- (BOOL)prefersStatusBarHidden
{
    return NO;
}

- (void)indicateLoadingActivity
{
    self.loadingIndicatorViewController.view.hidden = NO;
    self.loadingIndicatorViewController.showLoadingView = YES;
    self.acceptImageButton.enabled = NO;
    self.rejectImageButton.enabled = NO;
}

- (void)hideLoadingActivity
{
    self.loadingIndicatorViewController.showLoadingView = NO;
    self.loadingIndicatorViewController.view.hidden = YES;
    self.acceptImageButton.enabled = YES;
    self.rejectImageButton.enabled = YES;
    
}

- (void)performInitialSearch
{
    if (self.didSearchMoreThanOnce) {
        return;
    }
    
    [self indicateLoadingActivity];
    
    [self fetchNewPage];
}

- (void)fetchNewPage
{
    @weakify(self)
    
    [self.giphySearchResultsController fetchNewPage:^(BOOL success, NSError *error){
        
        @strongify(self)
        
        if (success) {
            
            Ziph *ziph = [self randomZiph];
            
            [self fetchImageForZiph:ziph ofType:ZiphyImageTypeDownsized];
        }
        else {
            [self handleZiphyResponse:nil ziph:nil error:error];
        }
        
        self.didSearchMoreThanOnce = YES;
    }];
}

- (void)presentNextImage
{
    [self indicateLoadingActivity];
    
    if (self.poolOfUsedZiphs.count == self.giphySearchResultsController.searchResults.count) {
        [self fetchNewPage];
    }
    else {
        
        Ziph *ziph = [self randomZiph];
        [self fetchImageForZiph:ziph ofType:ZiphyImageTypeDownsized];
    }
}

- (void)handleZiphyResponse:(NSData *)data ziph:(Ziph *)ziph error:(NSError *)error
{
    if (error == nil) {
        
        self.imageData = data;
        self.imagePreviewView.animatedImage = [[FLAnimatedImage alloc] initWithAnimatedGIFData:data];
        self.ziph = ziph;
    }
    else {

        self.giphyError = error;
        [self displayErrorMessage];
    }
    
    [self hideLoadingActivity];
}

- (void)fetchImageForZiph:(Ziph *)ziph ofType:(ZiphyImageType)type
{
    [self.giphySearchResultsController fetchImageForSearchResult:ziph
                                                          ofType:type
                                                      completion:^(BOOL success,
                                                                   ZiphyImageRep *ziphyImageRep,
                                                                   Ziph *ziph,
                                                                   NSData *imageData,
                                                                   NSError *error) {
                                                          
        [self handleZiphyResponse:imageData ziph:ziph error:error];
    }];
}

#pragma mark - View Creation

- (void)createPreviewPanel
{
    self.containerView = [[UIView alloc] initForAutoLayout];
    [self.view addSubview:self.containerView];
    
    self.imagePreviewView = [[FLAnimatedImageView alloc] initForAutoLayout];
    self.imagePreviewView.contentMode = UIViewContentModeScaleAspectFit;
    [self.containerView addSubview:self.imagePreviewView];
}

- (void)createBottomPanel
{
    self.bottomPanel = [[UIView alloc] init];
    self.bottomPanel.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.bottomPanel];
    
    self.confirmButtonsContainer = [[UIView alloc] init];
    self.confirmButtonsContainer.translatesAutoresizingMaskIntoConstraints = NO;
    [self.bottomPanel addSubview:self.confirmButtonsContainer];
    
    self.acceptImageButton = [Button buttonWithStyleClass:@"dialogue-button-full"];
    self.acceptImageButton.translatesAutoresizingMaskIntoConstraints = NO;
    [self.acceptImageButton addTarget:self action:@selector(acceptImage:) forControlEvents:UIControlEventTouchUpInside];
    [self.acceptImageButton setTitle:[NSLocalizedString(@"giphy.confirm", @"") uppercaseStringWithCurrentLocale] forState:UIControlStateNormal];
    self.acceptImageButton.accessibilityIdentifier = @"acceptButton";
    [self.confirmButtonsContainer addSubview:self.acceptImageButton];
    
    self.rejectImageButton = [Button buttonWithStyleClass:@"dialogue-button-empty"];
    self.rejectImageButton.translatesAutoresizingMaskIntoConstraints = NO;
    [self.rejectImageButton addTarget:self action:@selector(rejectImage:) forControlEvents:UIControlEventTouchUpInside];
    [self.rejectImageButton setTitle:[NSLocalizedString(@"giphy.try_another", @"") uppercaseStringWithCurrentLocale] forState:UIControlStateNormal];
    self.rejectImageButton.accessibilityIdentifier = @"rejectButton";
    [self.confirmButtonsContainer addSubview:self.rejectImageButton];
}

- (void)createLoadingIndicatorViewController
{
    self.loadingIndicatorViewController = [[UIViewController alloc] init];
    self.loadingIndicatorViewController.view.translatesAutoresizingMaskIntoConstraints = NO;
    
    [self addChildViewController:self.loadingIndicatorViewController];
    [self.containerView addSubview:self.loadingIndicatorViewController.view];
    [self.loadingIndicatorViewController didMoveToParentViewController:self];
    
    self.loadingIndicatorViewController.view.hidden = YES;
}

- (void)displayErrorMessage
{
    UILabel *errorLabel = [[UILabel alloc] initForAutoLayout];
    errorLabel.numberOfLines = 0;
    
    UIView *backDropView = [[UIView alloc] initForAutoLayout];
    backDropView.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.6];
    [self.imagePreviewView addSubview:backDropView];
    [backDropView autoPinEdgesToSuperviewEdgesWithInsets:UIEdgeInsetsZero];
    
    NSString *errorKey = self.didSearchMoreThanOnce ? @"giphy.error.no_more_results" : @"giphy.error.no_result";
    
    errorLabel.text = [NSLocalizedString(errorKey, "") uppercaseStringWithCurrentLocale];
    errorLabel.font = [UIFont fontWithMagicIdentifier:@"style.text.small.font_spec_bold"];
    errorLabel.textColor = [UIColor whiteColor];
    
    [backDropView addSubview:errorLabel];
    [errorLabel autoCenterInSuperview];
    
    if (self.imageData) {
        
        [UIView animateWithDuration:1.0 delay:1.0f options:UIViewAnimationOptionCurveEaseInOut animations:^{
            backDropView.alpha = 0;
        } completion:^(BOOL finished) {
            
            if(finished) {
                [backDropView removeFromSuperview];
            }
        }];
    }
}

- (void)createInitialConstraints
{
    
    // Bottom panel
    [self.bottomPanel autoPinEdgesToSuperviewEdgesWithInsets:UIEdgeInsetsZero excludingEdge:ALEdgeTop];
    [self.bottomPanel autoSetDimension:ALDimensionHeight toSize:BottomBarMinHeight];
    
    // Accept/Reject panel
    [self.confirmButtonsContainer autoAlignAxis:ALAxisHorizontal toSameAxisOfView:self.bottomPanel];
    [self.confirmButtonsContainer autoPinEdgeToSuperviewEdge:ALEdgeLeft withInset:0 relation:NSLayoutRelationGreaterThanOrEqual];
    [self.confirmButtonsContainer autoPinEdgeToSuperviewEdge:ALEdgeRight withInset:0 relation:NSLayoutRelationGreaterThanOrEqual];
    [self.confirmButtonsContainer autoAlignAxisToSuperviewAxis:ALAxisVertical];
    [self.confirmButtonsContainer autoMatchDimension:ALDimensionHeight toDimension:ALDimensionHeight ofView:self.bottomPanel];
    
    [self.acceptImageButton autoSetDimension:ALDimensionHeight toSize:40];
    [self.acceptImageButton autoAlignAxisToSuperviewAxis:ALAxisHorizontal];
    [self.acceptImageButton autoPinEdgeToSuperviewEdge:ALEdgeRight withInset:BottomMarginInset];
    [self.acceptImageButton setContentHuggingPriority:UILayoutPriorityDefaultLow forAxis:UILayoutConstraintAxisHorizontal];
    
    [self.rejectImageButton autoSetDimension:ALDimensionHeight toSize:40];
    [self.rejectImageButton autoAlignAxisToSuperviewAxis:ALAxisHorizontal];
    [self.rejectImageButton autoPinEdgeToSuperviewEdge:ALEdgeLeft withInset:BottomMarginInset];
    [self.rejectImageButton setContentHuggingPriority:UILayoutPriorityDefaultLow forAxis:UILayoutConstraintAxisHorizontal];
    
    [NSLayoutConstraint autoSetPriority:UILayoutPriorityDefaultHigh forConstraints:^{
        [self.acceptImageButton autoSetDimension:ALDimensionWidth toSize:184];
        [self.rejectImageButton autoSetDimension:ALDimensionWidth toSize:184];
        [self.acceptImageButton autoPinEdge:ALEdgeLeft toEdge:ALEdgeRight ofView:self.rejectImageButton withOffset:16];
    }];
    [self.acceptImageButton autoMatchDimension:ALDimensionWidth toDimension:ALDimensionWidth ofView:self.rejectImageButton];
    
    // Preview image
    [self.containerView autoPinEdgeToSuperviewEdge:ALEdgeTop];
    [self.containerView autoPinEdgeToSuperviewEdge:ALEdgeLeft];
    [self.containerView autoPinEdgeToSuperviewEdge:ALEdgeRight];
    [self.containerView autoPinEdge:ALEdgeBottom toEdge:ALEdgeTop ofView:self.bottomPanel];
    [self.imagePreviewView autoPinEdgesToSuperviewEdgesWithInsets:UIEdgeInsetsZero];
    [self.loadingIndicatorViewController.view autoPinEdgesToSuperviewEdgesWithInsets:UIEdgeInsetsZero];
}

#pragma mark - Actions

- (IBAction)cancelButtonTapped:(id)sender
{
    [self performCancelAction];
}

- (IBAction)titleButtonTapped:(id)sender
{
    NSURLComponents *urlComponents = [[NSURLComponents alloc] init];
    urlComponents.scheme = @"http";
    urlComponents.host = @"giphy.com";
    urlComponents.path = [NSString stringWithFormat:@"/search/%@", self.searchTerm];
    
    NSURL *url = urlComponents.URL;
    [[UIApplication sharedApplication] openURL:url];
}

- (IBAction)acceptImage:(id)sender
{
    [self performAcceptAction];
}

- (IBAction)rejectImage:(id)sender
{
    [self performNextImageAction];
}

- (void)performAcceptAction
{
    if (self.onConfirm &&
        self.loadingIndicatorViewController.showLoadingView == NO &&
        self.imageData) {
        
        [Analytics shared].sessionSummary.imagesSent++;
        
        self.onConfirm();
    }
    else {
        if (self.onCancel) {
            self.onCancel();
        }
    }
}

- (void)performCancelAction
{
    if (self.onCancel) {
        self.onCancel();
    }
}

- (void)performNextImageAction
{
    [[ZMUserSession sharedSession] checkNetworkAndFlashIndicatorIfNecessary];
    
    if ([ZMUserSession sharedSession].networkState != ZMNetworkStateOffline) {
        
        [self presentNextImage];
    }
}

#pragma mark - GiphyCollectionViewController

- (void)giphyCollectionViewController:(GiphyCollectionViewController *)controller didSelectZiph:(Ziph *)ziph previewImageData:(NSData *)data
{
    [self indicateLoadingActivity];
    self.imagePreviewView.animatedImage = [[FLAnimatedImage alloc] initWithAnimatedGIFData:data];
    [self excludeZiphFromRandom:ziph];
    [self fetchImageForZiph:ziph ofType:ZiphyImageTypeDownsized];
}

@end


@implementation GiphyConfirmImageViewController (Randomization)

- (Ziph *)randomZiph
{
    Ziph *randomZiph = nil;
    
    NSMutableSet *leftZiphs = [NSMutableSet setWithArray:self.giphySearchResultsController.searchResults];
    [leftZiphs minusSet:self.poolOfUsedZiphs];
    
    NSArray *unusedZiphsAsArray = leftZiphs.allObjects;
    NSUInteger randomIndex = (NSUInteger) arc4random_uniform((u_int32_t) unusedZiphsAsArray.count);
    randomZiph = unusedZiphsAsArray[randomIndex];
    [self excludeZiphFromRandom:randomZiph];
    
    return randomZiph;
}

- (void)excludeZiphFromRandom:(Ziph *)ziph
{
    [self.poolOfUsedZiphs addObject:ziph];
}

@end
