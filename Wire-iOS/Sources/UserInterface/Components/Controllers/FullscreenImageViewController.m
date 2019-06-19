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


#import "FullscreenImageViewController.h"
#import "FullscreenImageViewController+PullToDismiss.h"
#import "FullscreenImageViewController+internal.h"

// ui
#import "IconButton.h"
@import FLAnimatedImage;
#import "MediaAsset.h"

#import "AppDelegate.h"

// helpers
#import "MessageAction.h"

#import "Constants.h"

#import "Analytics.h"

// model
#import "WireSyncEngine+iOS.h"
#import "Wire-Swift.h"

static NSString* ZMLogTag ZM_UNUSED = @"UI";

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

@property (nonatomic, strong) ConversationMessageActionController *actionController;

@property (nonatomic) CALayer *highlightLayer;

@property (nonatomic) UITapGestureRecognizer *tapGestureRecognzier;
@property (nonatomic) UITapGestureRecognizer *doubleTapGestureRecognizer;
@property (nonatomic) UILongPressGestureRecognizer *longPressGestureRecognizer;

@property (nonatomic) BOOL isShowingChrome;
@property (nonatomic) BOOL assetWriteInProgress;

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

        [self setupScrollView];
        [self updateForMessage];

        self.view.userInteractionEnabled = YES;
        [self setupGestureRecognizers];
        [self showChrome:YES];

        [self setupStyle];

        self.actionController = [[ConversationMessageActionController alloc] initWithResponder:self message:message context:ConversationMessageActionControllerContextCollection view: self.scrollView];
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
    [self centerScrollViewContent];
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

- (void)updateForMessage
{
    if (self.message.isObfuscated || self.message.hasBeenDeleted) {
        [self removeImage];
        self.obfuscationView.hidden = NO;
    } else {
        self.obfuscationView.hidden = YES;
        [self loadImageAndSetupImageView];
    }
}

- (void)loadImageAndSetupImageView
{
    ZM_WEAK(self);
    
    const BOOL imageIsAnimatedGIF = self.message.imageMessageData.isAnimatedGIF;
    NSData *imageData = self.message.imageMessageData.imageData;
    
    dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void) {
        
        ZM_STRONG(self);
        
        id<MediaAsset> image;
        
        if (imageIsAnimatedGIF) {
            image = [[FLAnimatedImage alloc] initWithAnimatedGIFData:imageData];
        }
        else {
            image = [[UIImage alloc] initWithData:imageData];
        }
        
        ZM_WEAK(self);
        
        dispatch_async(dispatch_get_main_queue(), ^{
            ZM_STRONG(self);

            CGSize parentSize = self.parentViewController.view.bounds.size;
            [self setupImageViewWithImage:image parentSize:parentSize];
        });
    });
}

- (void)removeImage
{
    [self.imageView removeFromSuperview];
    self.imageView = nil;
}

- (void)showChrome:(BOOL)shouldShow
{
    self.isShowingChrome = shouldShow;
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
                                 NSFontAttributeName : UIFont.smallMediumFont,
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

#pragma mark - UIScrollViewDelegate

- (void)scrollViewWillBeginZooming:(UIScrollView *)scrollView withView:(UIView *)view
{
    [self updateScrollViewZoomScaleWithViewSize: self.view.frame.size imageSize:self.imageView.image.size];

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
        menuController.menuItems = ConversationMessageActionController.allMessageActions;
        
        [menuController setTargetRect:self.imageView.bounds inView:self.imageView];
        [menuController setMenuVisible:YES animated:YES];
        [self setSelectedByMenu:YES animated:YES];
    }
}


#pragma mark - Actions

- (BOOL)canPerformAction:(SEL)action withSender:(id)sender
{
    return [self.actionController canPerformAction:action];
}

- (id)forwardingTargetForSelector:(SEL)aSelector
{
    return self.actionController;
}

- (void)setSelectedByMenu:(BOOL)selected animated:(BOOL)animated
{
    ZMLogDebug(@"Setting selected: %@ animated: %@", @(selected), @(animated));
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
    
    [UIView wr_animateWithEasing:WREasingFunctionEaseInExpo duration:0.55f animations:^{
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
    if (((changeInfo.transferStateChanged || changeInfo.imageChanged) && ([[self.message imageMessageData] imageData] != nil)) ||
        changeInfo.isObfuscatedChanged) {
        
        [self updateForMessage];
    }
}

@end
