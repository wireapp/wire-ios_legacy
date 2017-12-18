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


@import AssetsLibrary;
@import MobileCoreServices;
@import WireExtensionComponents;

#import "FullscreenImageViewController.h"
#import "FullscreenImageViewController+PullToDismiss.h"

// ui
#import "UIView+Borders.h"
#import "IconButton.h"
@import FLAnimatedImage;
#import "MediaAsset.h"

#import "AppDelegate.h"
#import "NotificationWindowRootViewController.h"

// helpers

#import "WAZUIMagiciOS.h"
#import "UIFont+MagicAccess.h"
#import "UIColor+WR_ColorScheme.h"
#import "NSDate+Format.h"

#import "Constants.h"
#import "UIImage+ZetaIconsNeue.h"
@import PureLayout;

#import "Analytics.h"

// model
#import "WireSyncEngine+iOS.h"
#import "Wire-Swift.h"


@interface FirstReponderView : UIView
@end


@implementation FirstReponderView

- (BOOL)canBecomeFirstResponder
{
    return YES;
}

- (BOOL)becomeFirstResponder
{
    BOOL result = [super becomeFirstResponder];
    return result;
}

@end

@interface FullscreenImageViewController (MessageObserver) <ZMMessageObserver>

@end


@interface FullscreenImageViewController () <UIScrollViewDelegate>

@property (nonatomic, readwrite) UIScrollView *scrollView;

@property (nonatomic) UIView *topOverlay;
@property (nonatomic) CALayer *highlightLayer;

@property (nonatomic) IconButton *closeButton;

@property (nonatomic, readwrite) UIImageView *imageView;

@property (nonatomic) UITapGestureRecognizer *tapGestureRecognzier;
@property (nonatomic) UITapGestureRecognizer *doubleTapGestureRecognizer;
@property (nonatomic) UILongPressGestureRecognizer *longPressGestureRecognizer;

@property (nonatomic) UIActivityIndicatorView *loadingSpinner;

@property (nonatomic) BOOL isShowingChrome;
@property (nonatomic) BOOL assetWriteInProgress;

@property (nonatomic) CGFloat lastZoomScale;

@property (nonatomic) BOOL forcePortraitMode;

@property (nonatomic) id messageObserverToken;

@end

@implementation FullscreenImageViewController

- (instancetype)initWithMessage:(id<ZMConversationMessage>)message
{
    self = [self init];

    if (self) {
        _message = message;
        _forcePortraitMode = NO;
        _swipeToDismiss = YES;
        _showCloseButton = YES;
        if (nil != [ZMUserSession sharedSession]) {
            self.messageObserverToken = [MessageChangeInfo addObserver:self forMessage:message userSession:[ZMUserSession sharedSession]];
        }
    }

    return self;
}

- (void)loadView {
    self.view = [[FirstReponderView alloc] init];
}

- (void)dismissWithCompletion:(dispatch_block_t)completion
{
    if (nil != self.dismissAction) {
        self.dismissAction(completion);
    }
    else if (nil != self.navigationController) {
        [self.navigationController popViewControllerAnimated:YES];
        if (completion) {
            completion();
        }
    }
    else {
        [self dismissViewControllerAnimated:YES completion:completion];
    }
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    [self updateZoomWithSize:self.view.bounds.size];
    [self centerScrollViewContent];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self setupScrollView];
    [self setupTopOverlay];
    if ([[self.message imageMessageData] imageData] == nil) {
        [self.message requestImageDownload];
        [self setupSpinner];
    }
    else {
        [self loadImageAndSetupImageView];
    }
    
    self.view.userInteractionEnabled = YES;
    [self setupGestureRecognizers];
    [self showChrome:YES];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    self.closeButton.hidden = !self.showCloseButton;
}

- (BOOL)prefersStatusBarHidden
{
    return NO;
}

- (void)setForcePortraitMode:(BOOL)forcePortraitMode
{
    _forcePortraitMode = forcePortraitMode;
    [UIViewController attemptRotationToDeviceOrientation];
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskAll;
}

- (BOOL)shouldAutorotate
{
    return YES;
}

- (void)setupSnapshotBackgroundView
{
    UIView *snapshotBackgroundView = [self.delegate respondsToSelector:@selector(backgroundScreenshotForController:)] ? [self.delegate backgroundScreenshotForController:self] : nil;
    if (nil == snapshotBackgroundView) {
        return;
    }
    self.snapshotBackgroundView = snapshotBackgroundView;
    snapshotBackgroundView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:snapshotBackgroundView];

    const CGFloat topBarHeight = CGRectGetMaxY(self.navigationController.navigationBar.frame);
    [snapshotBackgroundView autoPinEdgeToSuperviewEdge:ALEdgeTop withInset:-topBarHeight];
    [snapshotBackgroundView autoPinEdgeToSuperviewEdge:ALEdgeLeading];
    [snapshotBackgroundView autoSetDimensionsToSize:[[UIScreen mainScreen] bounds].size];
    snapshotBackgroundView.alpha = 0;
}

- (void)setupScrollView
{
    self.scrollView = [[UIScrollView alloc] init];
    self.scrollView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.scrollView];

    [self.scrollView addConstraintsFittingToView:self.view];

    self.automaticallyAdjustsScrollViewInsets = NO;
    self.scrollView.delegate = self;
    self.scrollView.accessibilityIdentifier = @"fullScreenPage";
    
    self.animator = [[UIDynamicAnimator alloc] initWithReferenceView:self.scrollView];
}

- (void)setupSpinner
{
    self.loadingSpinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:[[ColorScheme defaultColorScheme] variant] == ColorSchemeVariantDark ? UIActivityIndicatorViewStyleWhite : UIActivityIndicatorViewStyleGray];
    self.loadingSpinner.hidesWhenStopped = YES;
    [self.view addSubview:self.loadingSpinner];
    [self.loadingSpinner startAnimating];
    
    [self.loadingSpinner autoCenterInSuperview];
}

- (void)loadImageAndSetupImageView
{
    @weakify(self);
    
    const BOOL imageIsAnimatedGIF = self.message.imageMessageData.isAnimatedGIF;
    NSData *imageData = self.message.imageMessageData.imageData;
    
    dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void) {
        
        @strongify(self);
        
        id<MediaAsset> image;
        
        if (imageIsAnimatedGIF) {
            image = [[FLAnimatedImage alloc] initWithAnimatedGIFData:imageData];
        }
        else {
            image = [[UIImage alloc] initWithData:imageData];
        }
        
        @weakify(self);
        
        dispatch_async(dispatch_get_main_queue(), ^{
            @strongify(self);
            
            UIImageView *imageView = [UIImageView imageViewWithMediaAsset:image];
            imageView.clipsToBounds = YES;
            imageView.layer.allowsEdgeAntialiasing = YES;
            
            self.imageView = imageView;
            self.imageView.translatesAutoresizingMaskIntoConstraints = NO;
            [self.scrollView addSubview:self.imageView];
            
            self.scrollView.contentSize = imageView.image.size;
            
            [self centerScrollViewContent];
        });
    });
}

- (void)setupTopOverlay
{
    self.topOverlay = [[UIView alloc] init];
    self.topOverlay.translatesAutoresizingMaskIntoConstraints = NO;
    self.topOverlay.hidden = !self.showCloseButton;
    [self.view addSubview:self.topOverlay];

    // Close button
    self.closeButton = [IconButton iconButtonCircular];
    self.closeButton.translatesAutoresizingMaskIntoConstraints = NO;
    [self.closeButton setIcon:ZetaIconTypeX withSize:ZetaIconSizeTiny forState:UIControlStateNormal];
    [self.topOverlay addSubview:self.closeButton];
    [self.closeButton addTarget:self action:@selector(closeButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    self.closeButton.accessibilityIdentifier = @"fullScreenCloseButton";
    
    // Constraints
    [self.topOverlay addConstraintForRightMargin:0 relativeToView:self.view];
    [self.topOverlay addConstraintForLeftMargin:0 relativeToView:self.view];
    [self.topOverlay addConstraintForTopMargin:0 relativeToView:self.view];
    [self.topOverlay addConstraintForHeight:[WAZUIMagic floatForIdentifier:@"one_message.top_gradient_height"]];

    [self.closeButton addConstraintForAligningVerticallyWithView:self.topOverlay offset:10];
    [self.closeButton addConstraintForRightMargin:8 relativeToView:self.topOverlay];
    [self.closeButton autoSetDimension:ALDimensionWidth toSize:32];
    [self.closeButton autoMatchDimension:ALDimensionWidth toDimension:ALDimensionHeight ofView:self.closeButton];
}

- (void)showChrome:(BOOL)shouldShow
{
    self.isShowingChrome = shouldShow;
    self.topOverlay.hidden = !self.showCloseButton || !shouldShow;
}

- (void)setSwipeToDismiss:(BOOL)swipeToDismiss
{
    _swipeToDismiss = swipeToDismiss;
    self.panRecognizer.enabled = self.swipeToDismiss;
}

- (void)setupGestureRecognizers
{
    self.tapGestureRecognzier = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(didTapBackground:)];

    UIGestureRecognizer *delayedTouchBeganRecognizer = self.scrollView.gestureRecognizers[0];
    [delayedTouchBeganRecognizer requireGestureRecognizerToFail:self.tapGestureRecognzier];

    [self.view addGestureRecognizer:self.tapGestureRecognzier];


    self.doubleTapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleDoubleTap:)];
    self.doubleTapGestureRecognizer.numberOfTapsRequired = 2;
    [self.view addGestureRecognizer:self.doubleTapGestureRecognizer];

    self.longPressGestureRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleLongPress:)];
    [self.view addGestureRecognizer:self.longPressGestureRecognizer];
    
    self.panRecognizer = [[UIPanGestureRecognizer alloc] init];
    self.panRecognizer.maximumNumberOfTouches = 1;
    self.panRecognizer.delegate = self;
    self.panRecognizer.enabled = self.swipeToDismiss;
    [self.panRecognizer addTarget:self action:@selector(dismissingPanGestureRecognizerPanned:)];
    [self.scrollView addGestureRecognizer:self.panRecognizer];
    
    [self.doubleTapGestureRecognizer requireGestureRecognizerToFail:self.panRecognizer];
    [self.tapGestureRecognzier requireGestureRecognizerToFail:self.panRecognizer];
    [delayedTouchBeganRecognizer requireGestureRecognizerToFail:self.panRecognizer];

    [self.tapGestureRecognzier requireGestureRecognizerToFail:self.doubleTapGestureRecognizer];
}

- (NSAttributedString *)attributedNameStringForDisplayName:(NSString *)displayName
{
    NSString *text = [displayName uppercasedWithCurrentLocale];
    NSDictionary *attributes = @{
                                 NSFontAttributeName : [UIFont fontWithMagicIdentifier:@"style.text.small.font_spec_bold"],
                                 NSForegroundColorAttributeName : [UIColor wr_colorFromColorScheme:ColorSchemeColorTextForeground],
                                 NSBackgroundColorAttributeName : [UIColor wr_colorFromColorScheme:ColorSchemeColorTextBackground] };
    
    NSAttributedString *attributedName = [[NSAttributedString alloc] initWithString:text attributes:attributes];
    
    return attributedName;
}

#pragma mark - UIButtons

- (void)closeButtonTapped:(id)sender
{
    [[UIMenuController sharedMenuController] setMenuVisible:NO];
    
    if (! IS_IPAD_FULLSCREEN) {
        self.forcePortraitMode = YES;
    }
    [self dismissWithCompletion:nil];
}

- (void)updateZoom
{
    [self updateZoomWithSize:self.view.bounds.size];
}

// Zoom to show as much image as possible unless image is smaller than screen
- (void)updateZoomWithSize:(CGSize)size
{
    float minZoom = MIN(size.width / self.imageView.image.size.width,
                        size.height / self.imageView.image.size.height);

    if (minZoom > 1) {
        minZoom = 1;
    }

    self.scrollView.minimumZoomScale = minZoom;

    // Force scrollViewDidZoom fire if zoom did not change
    if (minZoom == self.lastZoomScale) {
        minZoom += 0.000001;
    }

    self.scrollView.zoomScale = minZoom;
    self.lastZoomScale = minZoom;
}


#pragma mark - UIScrollViewDelegate

- (void)scrollViewWillBeginZooming:(UIScrollView *)scrollView withView:(UIView *)view
{
    [self.delegate fadeAndHideMenu:YES];
}

- (void)scrollViewDidZoom:(UIScrollView *)scrollView
{
    [self setSelectedByMenu:NO animated:NO];
    [[UIMenuController sharedMenuController] setMenuVisible:NO];

    [self centerScrollViewContent];
}

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView
{
    return self.imageView;
}

- (void)centerScrollViewContent
{
    float imageWidth = self.imageView.image.size.width;
    float imageHeight = self.imageView.image.size.height;

    float viewWidth = self.view.bounds.size.width;
    float viewHeight = self.view.bounds.size.height;
    
    CGFloat horizontalInset = (viewWidth - self.scrollView.zoomScale * imageWidth) / 2;
    horizontalInset = MAX(0, horizontalInset);
    
    CGFloat verticalInset = (viewHeight - self.scrollView.zoomScale * imageHeight) / 2;
    verticalInset = MAX(0, verticalInset);
    
    self.scrollView.contentInset = UIEdgeInsetsMake(verticalInset, horizontalInset, verticalInset, horizontalInset);
}

#pragma mark - Gesture Handling

- (void)didTapBackground:(UITapGestureRecognizer *)tapper
{
    [self showChrome:!self.isShowingChrome];
    [self setSelectedByMenu:NO animated:NO];
    [[UIMenuController sharedMenuController] setMenuVisible:NO];
    [self.delegate fadeAndHideMenu:!self.delegate.menuVisible];
}

- (void)handleDoubleTap:(UITapGestureRecognizer *)doubleTapper
{
    [self setSelectedByMenu:NO animated:NO];
    [[UIMenuController sharedMenuController] setMenuVisible:NO];

    CGPoint point = [doubleTapper locationInView:doubleTapper.view];

    CGRect zoomRect = CGRectMake(point.x - 25, point.y - 25, 50, 50);

    CGRect finalRect = [self.imageView convertRect:zoomRect fromView:doubleTapper.view];

    CGFloat scaleDiff = self.scrollView.zoomScale - self.scrollView.minimumZoomScale;

    if (scaleDiff < 0.0003) {
        [self.scrollView zoomToRect:finalRect animated:YES];
    } else {
        [self.scrollView setZoomScale:self.lastZoomScale animated:YES];
    }
}

- (void)handleLongPress:(UILongPressGestureRecognizer *)longPressRecognizer
{
    if ([longPressRecognizer state] == UIGestureRecognizerStateBegan) {

        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(menuDidHide:)
                                                     name:UIMenuControllerDidHideMenuNotification object:nil];

        /**
         *  The reason why we are touching the window here is to workaround a bug where,
         *  After dismissing the webplayer, the window would fail to become the first responder,
         *  preventing us to show the menu at all.
         *  We now force the window to be the key window and to be the first responder to ensure that we can
         *  show the menu controller.
         */
        [self.view.window makeKeyWindow];
        [self.view.window becomeFirstResponder];
        [self.view becomeFirstResponder];
        
        UIMenuController *menuController = UIMenuController.sharedMenuController;
        menuController.menuItems = @[
                                     [UIMenuItem likeItemForMessage:self.message action:@selector(likeImage)],
                                     [UIMenuItem saveItemWithAction:@selector(saveImage)],
                                     [UIMenuItem forwardItemWithAction:@selector(forward)],
                                     [UIMenuItem deleteItemWithAction:@selector(deleteImage)],
                                     [UIMenuItem revealItemWithAction:@selector(revealInConversation)]
                                     ];
        
        [menuController setTargetRect:self.imageView.bounds inView:self.imageView];
        [menuController setMenuVisible:YES animated:YES];
        [self setSelectedByMenu:YES animated:YES];
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
        return !self.message.isEphemeral && [self.delegate canPerformAction:MessageActionCopy forMessage:self.message];
    }
    else if (action == @selector(saveImage)) {
        return !self.message.isEphemeral && [self.delegate canPerformAction:MessageActionSave forMessage:self.message];
    }
    else if (action == @selector(forward)) {
        return !self.message.isEphemeral && [self.delegate canPerformAction:MessageActionForward forMessage:self.message];
    }
    else if (action == @selector(revealInConversation)) {
        return !self.message.isEphemeral && [self.delegate canPerformAction:MessageActionShowInConversation forMessage:self.message];
    }
    else if (action == @selector(likeImage)) {
        return [Message messageCanBeLiked:self.message];
    }
    else if (action == @selector(deleteImage)) {
        return self.message.canBeDeleted;
    }
    else if (action == @selector(paste:)) {
        return NO;
    }
    else if (action == @selector(select:) || action == @selector(selectAll:)) {
        return NO;
    }

    return [super canPerformAction:action withSender:sender];
}

- (void)copy:(id)sender
{
    [self.delegate wantsToPerformAction:MessageActionCopy forMessage:self.message];
}

- (void)forward
{
    [self dismissWithCompletion:^{
        [self.delegate wantsToPerformAction:MessageActionForward forMessage:self.message];
    }];
}

- (void)revealInConversation
{
    [self dismissWithCompletion:^{
        [self.delegate wantsToPerformAction:MessageActionShowInConversation forMessage:self.message];
    }];
}

- (void)saveImage
{
    [self.delegate wantsToPerformAction:MessageActionSave forMessage:self.message];
}

- (void)likeImage
{
    [self.delegate wantsToPerformAction:MessageActionLike forMessage:self.message];
}

-(void)deleteImage
{
    [self.delegate wantsToPerformAction:MessageActionDelete forMessage:self.message];
}

- (void)setSelectedByMenu:(BOOL)selected animated:(BOOL)animated
{
    DDLogDebug(@"Setting selected: %@ animated: %@", @(selected), @(animated));
    if (selected) {

        self.highlightLayer = [CALayer layer];
        self.highlightLayer.backgroundColor = [UIColor clearColor].CGColor;
        self.highlightLayer.frame = CGRectMake(0, 0, self.imageView.frame.size.width / self.scrollView.zoomScale, self.imageView.frame.size.height / self.scrollView.zoomScale);
        [self.imageView.layer insertSublayer:self.highlightLayer atIndex:0];

        if (animated) {
            [UIView animateWithDuration:0.33 animations:^{
                self.highlightLayer.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.4].CGColor;
            }];
        } else {
            self.highlightLayer.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.4].CGColor;
        }
    }
    else {
        if (animated) {
            [UIView animateWithDuration:0.33 animations:^{
                self.highlightLayer.backgroundColor = [UIColor clearColor].CGColor;;
            } completion:^(BOOL finished){
                if (finished) {
                    [self.highlightLayer removeFromSuperlayer];
                }
            }];
        }
        else {
            self.highlightLayer.backgroundColor = [UIColor clearColor].CGColor;
            [self.highlightLayer removeFromSuperlayer];
        }
    }
}

- (void)menuDidHide:(NSNotification *)notification
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIMenuControllerDidHideMenuNotification object:nil];
    [self setSelectedByMenu:NO animated:YES];
}

#pragma mark - Utilities, custom UI

- (void)performSaveImageAnimationFromView:(UIView *)saveView
{
    UIImageView *ghostImageView = [[UIImageView alloc] initWithImage:self.imageView.image];
    ghostImageView.contentMode = UIViewContentModeScaleAspectFit;
    ghostImageView.translatesAutoresizingMaskIntoConstraints = YES;
    CGRect initialFrame = [self.view convertRect:self.imageView.frame fromView:self.imageView.superview];
    [self.view addSubview:ghostImageView];
    ghostImageView.frame = initialFrame;
    CGPoint targetCenter = [self.view convertPoint:saveView.center fromView:saveView.superview];
    
    [UIView wr_animateWithEasing:RBBEasingFunctionEaseInExpo duration:0.55f animations:^{
        ghostImageView.center = targetCenter;
        ghostImageView.alpha = 0;
        ghostImageView.transform = CGAffineTransformMakeScale(0.01, 0.01);
    } completion:^(BOOL finished) {
        [ghostImageView removeFromSuperview];
    }];
}

@end

@implementation FullscreenImageViewController (MessageObserver)

- (void)messageDidChange:(MessageChangeInfo *)changeInfo
{
    if (changeInfo.imageChanged && [[self.message imageMessageData] imageData] != nil) {
        [self.loadingSpinner removeFromSuperview];
        self.loadingSpinner = nil;
        
        [self loadImageAndSetupImageView];
    }
}

@end
