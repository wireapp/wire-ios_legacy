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


#import "GiphyViewController.h"
#import "GiphyConfirmImageViewController.h"
#import "GiphyCollectionViewController.h"
#import "GiphyNavigationBarController.h"
#import "zmessaging+iOS.h"


#import "UIView+Borders.h"
#import "ziphy+iOS.h"
#import "GiphySearchResultsController.h"

#import <PureLayout/PureLayout.h>
#import "Wire-Swift.h"

@interface GiphyViewController () <UINavigationControllerDelegate>

@property (nonatomic) GiphySearchResultsController *giphySearchResultsController;

@property (nonatomic, copy) NSString *searchTerm;

@property (nonatomic) BOOL initialConstrainsCreated;
@property (nonatomic) UIView *topSpacingView;

@property (nonatomic) UINavigationController *rootNavigationController;

@property (nonatomic) GiphyConfirmImageViewController *confirmImageViewController;
@property (nonatomic) GiphyNavigationBarController *navBarController;

@property (nonatomic) NSCache *gifsPreviewCache;

@end

@implementation GiphyViewController

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    return [self initWithSearchTerm:@""];
}

- (instancetype)initWithSearchTerm:(NSString *)searchTerm;
{
    self = [super initWithNibName:nil bundle:nil];
    
    if (self) {
        
#if DEBUG
        [ZiphyClient setLogLevel:ZiphyLogLevelVerbose];
#endif
        
        self.searchTerm = searchTerm;
        self.gifsPreviewCache = [[NSCache alloc] init];
        self.gifsPreviewCache.totalCostLimit = 1024 * 1024 * 10; //10MB
        
        self.giphySearchResultsController = [[GiphySearchResultsController alloc] initWithSearchTerm:self.searchTerm
                                                                                           imageType:ZiphyImageTypeDownsized
                                                                                            pageSize:50
                                                                                        maxImageSize:1024*1024*3];
    }
    
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self createNavigationBar];
    [self createNagivationController];
    [self createConstrains];
}

- (void)createNavigationBar
{
    self.navBarController = [[GiphyNavigationBarController alloc] init];
    
    @weakify(self)
    
    self.navBarController.onCancelTapped = ^{
        @strongify(self)
        if (self.onCancel != nil ) {
            self.onCancel();
        }
    };
    
    self.navBarController.onBackButtonTapped = ^{
        @strongify(self)
        [self.rootNavigationController popViewControllerAnimated:YES];
    };
    
    self.navBarController.onGiphyButtonTapped = ^{
        @strongify(self)
        [self presentGiphyCollectionViewController];
    };
    
    self.navBarController.onTitleTapped = ^{
        @strongify(self)
        [self openGiphyWebPage];
    };
    
    [self addChildViewController:self.navBarController];
    [self.view addSubview:self.navBarController.view];
    [self.navBarController didMoveToParentViewController:self];
    
    self.navBarController.view.opaque = YES;
    
    [self.navBarController setCentralTitle:[self.searchTerm uppercaseStringWithCurrentLocale] subTitle:[self.conversation.displayName uppercaseStringWithCurrentLocale]];
}

- (void)createNagivationController
{
    self.confirmImageViewController = [[GiphyConfirmImageViewController alloc] initWithSearchTerm:self.searchTerm];
    self.confirmImageViewController.analyticsTracker = self.analyticsTracker;
    self.confirmImageViewController.onCancel = self.onCancel;
    self.confirmImageViewController.onConfirm = self.onConfirm;
    self.confirmImageViewController.giphySearchResultsController = self.giphySearchResultsController;
    
    self.rootNavigationController = [[UINavigationController alloc] initWithRootViewController:self.confirmImageViewController];
    self.rootNavigationController.delegate = self;
    self.rootNavigationController.navigationBarHidden = YES;
    
    [self addChildViewController:self.rootNavigationController];
    [self.view addSubview:self.rootNavigationController.view];
    [self.rootNavigationController didMoveToParentViewController:self];
}

- (void)createConstrains
{
    [self.navBarController.view autoPinEdgesToSuperviewEdgesWithInsets:UIEdgeInsetsMake(20, 0, 0, 0) excludingEdge:ALEdgeBottom];
    [self.rootNavigationController.view autoPinEdgesToSuperviewEdgesWithInsets:UIEdgeInsetsMake(0, 0, 0, 0) excludingEdge:ALEdgeTop];
    [self.rootNavigationController.view autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.navBarController.view];
}

- (NSData *)imageData
{
    return self.confirmImageViewController.imageData;
}

- (void)presentGiphyCollectionViewController
{
    ARCollectionViewMasonryLayout *layout = [[ARCollectionViewMasonryLayout alloc] initWithDirection:ARCollectionViewMasonryLayoutDirectionVertical];
    CGSize viewSize = self.view.frame.size;
    layout.dimensionLength = viewSize.width/2;
    GiphyCollectionViewController *giphyCollectionViewController = [[GiphyCollectionViewController alloc] initWithCollectionViewLayout:layout];
    
    giphyCollectionViewController.delegate = self.confirmImageViewController;
    giphyCollectionViewController.giphySearchResultsController = self.giphySearchResultsController;
    giphyCollectionViewController.searchTerm = self.searchTerm;
    giphyCollectionViewController.cache = self.gifsPreviewCache;
    
    [self.rootNavigationController pushViewController:giphyCollectionViewController animated:YES];
}

- (void)openGiphyWebPage
{
    NSString *urlString = [NSString stringWithFormat:@"http://giphy.com/search/%@", self.searchTerm];
    
    NSURL *gifURL = [NSURL URLWithString:urlString];
    
    if (gifURL) {
        
        [[UIApplication sharedApplication] openURL:gifURL];
    }
}

#pragma mark - UINavigationControllerDelegate

- (void)navigationController:(UINavigationController *)navigationController willShowViewController:(UIViewController *)viewController animated:(BOOL)animated
{
    GiphyNavigationBarControllerState state = GiphyNavigationBarControllerStateInitial;
    
    if ([viewController isKindOfClass:[GiphyConfirmImageViewController class]]) {
        
        GiphyConfirmImageViewController *confirmImageController = (GiphyConfirmImageViewController *)viewController;
        [confirmImageController performInitialSearch];
    }
    else if ([viewController isKindOfClass:[GiphyCollectionViewController class]]) {
        
        state = GiphyNavigationBarControllerStatePushed;
    }
    
    if (self.transitionCoordinator) {
        
        [self.transitionCoordinator animateAlongsideTransition:nil completion:^(id<UIViewControllerTransitionCoordinatorContext> context) {
            
            [self.navBarController transitionToState:state];
        }];
    }
    else {
        
        [self.navBarController transitionToState:state];
    }
}

@end
