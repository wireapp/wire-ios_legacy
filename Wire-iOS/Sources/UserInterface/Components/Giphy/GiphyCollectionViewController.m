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




#import "GiphyCollectionViewController.h"
#import "IconButton.h"
#import "WAZUIMagicIOS.h"
#import "UIImage+ZetaIconsNeue.h"
#import "UIView+Borders.h"

#import "FLAnimatedImageView.h"
#import "FLAnimatedImage.h"
#import "UIColor+WAZExtensions.h"
#import "StopWatch.h"
#import "UIScrollView+Zeta.h"
#import "NSString+Wire.h"

@import WireExtensionComponents;

#import "zmessaging+iOS.h"
#import "ziphy+iOS.h"
#import "GiphySearchResultsController.h"

#import <PureLayout/PureLayout.h>
#import <Classy/Classy.h>



@interface GiphyCollectionViewCell : UICollectionViewCell

@property (nonatomic) FLAnimatedImageView *imageView;
@property (nonatomic) Ziph *ziph;
@property (nonatomic) ZiphyImageRep *ziphyImageRep;

@end

@interface GiphyCollectionViewController () <ARCollectionViewMasonryLayoutDelegate>

@property (nonatomic) NSArray *ziphs;

@property (nonatomic) UIView *topPanel;
@property (nonatomic, readwrite) UIButton *titleButton;
@property (nonatomic, readwrite) IconButton *topPanelRightButton;
@property (nonatomic, readwrite) IconButton *topPanelLeftButton;

@property (nonatomic) UIViewController *loadingIndicatorViewController;

@property (nonatomic, copy) NSString *previewTitle;

@property (nonatomic, strong) id giphyPageFetchObserver;

@end

@implementation GiphyCollectionViewController

#pragma mark - UIViewController Lifecycle and Callbacks

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    
    [self.cache removeAllObjects];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.collectionView.accessibilityIdentifier = @"giphyCollectionView";
    [self.collectionView registerClass:[GiphyCollectionViewCell class] forCellWithReuseIdentifier:@"GiphyCollectionViewCell"];
    
    self.giphyPageFetchObserver = [KeyValueObserver observeObject:self.giphySearchResultsController
                                                          keyPath:NSStringFromSelector(@selector(isFetchingNewPage))
                                                           target:self
                                                         selector:@selector(onGiphySearchResultsLoadingChanghed:)
                                                          options:NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld];
    
    if (self.giphySearchResultsController.isFetchingNewPage) {
        
        [self indicateLoadingActivity];
    }
    
    if (self.giphySearchResultsController.fetchPageError &&
        self.giphySearchResultsController.searchResults.count == 0) {
        
        [self hideLoadingActivity];
        [self displayErrorMessage];
    }
}

- (void)setSearchTerm:(NSString *)searchTerm
{
    if (_searchTerm != searchTerm) {
        _searchTerm = [searchTerm copy];
        self.previewTitle = [_searchTerm uppercaseStringWithCurrentLocale];
    }
}

- (void)setPreviewTitle:(NSString *)previewTitle
{
    if (_previewTitle != previewTitle) {
        
        _previewTitle = [previewTitle copy];
        
        [self.titleButton setTitle:_previewTitle forState:UIControlStateNormal];
        [self.navigationController.navigationBar setNeedsDisplay];
        [self.navigationController.navigationBar layoutIfNeeded];
    }
}

- (void)indicateLoadingActivity
{
    self.showLoadingView = YES;
}

- (void)hideLoadingActivity
{
    self.showLoadingView = NO;
}

- (void)displayErrorMessage
{
    UILabel *errorLabel = [[UILabel alloc] initForAutoLayout];
    errorLabel.numberOfLines = 0;
    
    UIView *backDropView = [[UIView alloc] initForAutoLayout];
    backDropView.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.6];
    [self.view addSubview:backDropView];
    [backDropView autoPinEdgesToSuperviewEdgesWithInsets:UIEdgeInsetsZero];
    
    NSString *errorKey = @"giphy.error.no_more_results";
    
    errorLabel.text = [NSLocalizedString(errorKey, "") uppercaseStringWithCurrentLocale];
    errorLabel.font = [UIFont fontWithMagicIdentifier:@"style.text.small.font_spec_bold"];
    errorLabel.textColor = [UIColor whiteColor];
    
    [backDropView addSubview:errorLabel];
    [errorLabel autoCenterInSuperview];
}

- (void)fetchNewPage
{
    [self.giphySearchResultsController fetchNewPage:nil];
}

- (void)onGiphySearchResultsLoadingChanghed:(NSDictionary *)change
{
    [self hideLoadingActivity];
    
    if (self.giphySearchResultsController.isFetchingNewPage == NO &&
        self.giphySearchResultsController.numberOfResultsLastFetch > 0){
        [self.collectionView reloadData];
    }
}

#pragma mark - UICollectionViewDataSource Methods

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    NSUInteger count = self.giphySearchResultsController.searchResults.count;
    return count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    
    GiphyCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"GiphyCollectionViewCell" forIndexPath:indexPath];
    
    Ziph *ziph = self.giphySearchResultsController.searchResults[indexPath.row];
    ZiphyImageRep *ziphyImageRep = ziph.ziphyImages[[ZiphyClient fromZiphyImageTypeToString:ZiphyImageTypeFixedWidthDownsampled]];
    
    
    NSData *gifImageData = [self.cache objectForKey:ziphyImageRep.url];
    
    cell.ziph = ziph;
    cell.ziphyImageRep = ziphyImageRep;
    cell.backgroundColor = [UIColor colorForZMAccentColor:[ZMUser pickRandomAccentColor]];
    
    
    if (gifImageData) {
        cell.imageView.animatedImage = [[FLAnimatedImage alloc] initWithAnimatedGIFData:gifImageData];
    }
    else {
        [self retreiveImageFromZiph:ziph ofType:ZiphyImageTypeFixedWidthDownsampled forCell:cell];
    }
    
    if (indexPath.row == (NSInteger)(self.giphySearchResultsController.searchResults.count/2)
        && self.giphySearchResultsController.numberOfResultsLastFetch > 0) {
        
        [self fetchNewPage];
    }
    
    return cell;
}

- (void)retreiveImageFromZiph:(Ziph *)ziph ofType:(ZiphyImageType)imageType forCell:(GiphyCollectionViewCell *)cell
{
    if (cell.ziph) {
        
        @weakify(self, cell);
        
        [self.giphySearchResultsController fetchImageForSearchResult:ziph
                                                              ofType:imageType
                                                          completion:^(BOOL success,
                                                                       ZiphyImageRep *ziphyImageRep,
                                                                       Ziph *fetchedZiph,
                                                                       NSData *imageData,
                                                                       NSError *error) {
                                                              
                                                              @strongify(self, cell);
                                                              
                                                              if (error == nil){
                                                                  
                                                                  if (cell.ziph == fetchedZiph) {
                                                                      
                                                                      [self.cache setObject:imageData forKey:cell.ziphyImageRep.url];
                                                                      cell.imageView.animatedImage = [[FLAnimatedImage alloc] initWithAnimatedGIFData:imageData];
                                                                  }
                                                              }
                                                          }];
    }
}

#pragma mark - UICollectionViewDelegate

-(void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    if (self.delegate && [self.delegate respondsToSelector:@selector(giphyCollectionViewController:didSelectZiph:previewImageData:)]) {
        
        Ziph *ziph = self.giphySearchResultsController.searchResults[indexPath.row];
        NSString *urlString = [ziph imageWithType:ZiphyImageTypeFixedWidthDownsampled].url;
        NSData *previewData = [self.cache objectForKey:urlString];
        [self.delegate giphyCollectionViewController:self didSelectZiph:ziph previewImageData:previewData];
        [self.navigationController popViewControllerAnimated:YES];
    }
}

#pragma mark - ARCollectionViewMasonryLayoutDelegate Methods

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(ARCollectionViewMasonryLayout *)collectionViewLayout variableDimensionForItemAtIndexPath:(NSIndexPath *)indexPath
{
    Ziph *ziph = self.giphySearchResultsController.searchResults[indexPath.row];
    ZiphyImageRep *ziphyImageRep =  ziph.ziphyImages[[ZiphyClient fromZiphyImageTypeToString:ZiphyImageTypeFixedWidthDownsampled]];
    
    return ziphyImageRep.height;
}

@end



@implementation GiphyCollectionViewCell

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.autoresizesSubviews = YES;
        self.clipsToBounds = YES;
        self.imageView = [[FLAnimatedImageView alloc] initForAutoLayout];
        self.imageView.contentMode = UIViewContentModeScaleAspectFill;
        [self.contentView addSubview:self.imageView];
        [self setupConstraints];
    }
    return self;
}

- (void)setupConstraints
{
    [self.contentView autoPinEdgesToSuperviewEdgesWithInsets:UIEdgeInsetsZero];
    [self.imageView autoPinEdgesToSuperviewEdgesWithInsets:UIEdgeInsetsZero];
    
}

- (void)prepareForReuse
{
    self.imageView.animatedImage = nil;
    self.ziph = nil;
    self.ziphyImageRep = nil;
    self.backgroundColor = nil;
}


@end
