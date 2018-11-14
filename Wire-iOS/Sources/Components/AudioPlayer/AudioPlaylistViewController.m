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
@import WireExtensionComponents;

#import "AudioPlaylistViewController.h"
#import "AudioHeaderView.h"
#import "AudioTrackView.h"
#import "AudioTrackPlayer.h"
#import "SoundcloudAudioTrack.h"

#import "AudioPlaylist.h"
#import "AudioTrack.h"
#import "AudioTrackCell.h"
#import "AudioPlaylistCell.h"
#import "WireSyncEngine+iOS.h"
#import "LinkAttachmentCache.h"
#import "SoundcloudService.h"
#import "LinkAttachment.h"
#import "Wire-Swift.h"

static NSString* ZMLogTag ZM_UNUSED = @"UI";

static NSString * const AudioPlaylistCellReuseIdentifier = @"AudioPlaylistCellReuseIdentifier";
static NSString * const AudioTrackCellReuseIdentifier = @"AudioTrackCellReuseIdentifier";
static const CGFloat SeparatorLineOverflow = 4;



@interface AudioPlaylistViewController () <UITableViewDelegate, UITableViewDataSource, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, AudioTrackCellDelegate>

@property (nonatomic, readonly) UIImageView *backgroundView;
@property (nonatomic, readonly) UIVisualEffectView *blurEffectView;
@property (nonatomic, readonly) AudioTrackPlayer *audioTrackPlayer;
@property (nonatomic, readonly) BOOL isTrackPlayingInAudioPlayer;
@property (nonatomic) BOOL loadingFailed;

@property (nonatomic, readonly) UIView *contentContainer;
@property (nonatomic, readonly) UITableView *playlistTableView;
@property (nonatomic, readonly) UICollectionView *tracksCollectionView;
@property (nonatomic, readonly) AudioHeaderView *audioHeaderView;
@property (nonatomic, readonly) UIView *tracksSeparatorLine;
@property (nonatomic, readonly) UIView *playlistSeparatorLine;
@property (nonatomic, readonly) NSLayoutConstraint *tracksSeparatorLineHeightConstraint;

@property (nonatomic) NSObject *artworkObserver;
@property (nonatomic) NSObject *audioTrackObserver;
@property (nonatomic) NSObject *audioProgressObserver;
@property (nonatomic) NSObject *audioPlayerStateObserver;

@end

@implementation AudioPlaylistViewController

@synthesize linkAttachment = _linkAttachment;

-(void)dealloc
{
    self.artworkObserver = nil;
}

- (void)tearDown;
{
    [self.audioTrackPlayer stop];
}

- (instancetype)initWithAudioTrackPlayer:(AudioTrackPlayer *)audioTrackPlayer
{
    self = [super initWithNibName:nil bundle:nil];
    
    if (self) {
        _audioTrackPlayer = audioTrackPlayer;
    }
    
    return self;
}

- (instancetype)init
{
    self = [self initWithAudioTrackPlayer:[AppDelegate sharedAppDelegate].mediaPlaybackManager.audioTrackPlayer];
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.view.translatesAutoresizingMaskIntoConstraints = NO;
    self.view.preservesSuperviewLayoutMargins = YES;
    self.view.backgroundColor = UIColor.soundcloudOrange;
    _backgroundView = [[UIImageView alloc] initForAutoLayout];
    self.backgroundView.contentMode = UIViewContentModeScaleAspectFill;
    self.backgroundView.clipsToBounds = YES;
    [self.view addSubview:self.backgroundView];
    
    _blurEffectView = [[UIVisualEffectView alloc] initWithEffect:[UIBlurEffect effectWithStyle:UIBlurEffectStyleDark]];
    self.blurEffectView.translatesAutoresizingMaskIntoConstraints = NO;
    self.blurEffectView.preservesSuperviewLayoutMargins = YES;
    self.blurEffectView.contentView.preservesSuperviewLayoutMargins = YES;
    [self.view addSubview:self.blurEffectView];
    
    _audioHeaderView = [[AudioHeaderView alloc] initForAutoLayout];
    self.audioHeaderView.preservesSuperviewLayoutMargins = YES;
    [self.audioHeaderView.providerButton addTarget:self action:@selector(openInBrowser:) forControlEvents:UIControlEventTouchUpInside];
    [self.audioHeaderView.providerButton setImage:self.providerImage forState:UIControlStateNormal];
    [self.blurEffectView.contentView addSubview:self.audioHeaderView];
    
    _contentContainer = [[UIView alloc] initForAutoLayout];
    self.contentContainer.preservesSuperviewLayoutMargins = YES;
    [self.view addSubview:self.contentContainer];
    
    _playlistTableView = [[UITableView alloc] initForAutoLayout];
    [self.contentContainer addSubview:self.playlistTableView];
    self.playlistTableView.dataSource = self;
    self.playlistTableView.delegate = self;
    self.playlistTableView.backgroundColor = [UIColor clearColor];
    self.playlistTableView.separatorInset = UIEdgeInsetsZero;
    self.playlistTableView.rowHeight = 44;
    self.playlistTableView.showsVerticalScrollIndicator = NO;
    self.playlistTableView.separatorColor = [UIColor wr_colorFromColorScheme:ColorSchemeColorSeparator variant:ColorSchemeVariantDark];
    
    [self.playlistTableView registerClass:AudioPlaylistCell.class forCellReuseIdentifier:AudioPlaylistCellReuseIdentifier];
    
    UICollectionViewFlowLayout *tracksCollectionViewLayout = [[UICollectionViewFlowLayout alloc] init];
    tracksCollectionViewLayout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
    
    _tracksCollectionView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:tracksCollectionViewLayout];
    [self.contentContainer addSubview:self.tracksCollectionView];
    self.tracksCollectionView.translatesAutoresizingMaskIntoConstraints = NO;
    self.tracksCollectionView.dataSource = self;
    self.tracksCollectionView.delegate = self;
    self.tracksCollectionView.backgroundColor = [UIColor clearColor];
    self.tracksCollectionView.contentInset = UIEdgeInsetsMake(0, 0, 0, 8);
    self.tracksCollectionView.showsHorizontalScrollIndicator = NO;
    [self.tracksCollectionView registerClass:AudioTrackCell.class forCellWithReuseIdentifier:AudioTrackCellReuseIdentifier];
    
    _tracksSeparatorLine = [[UIView alloc] initForAutoLayout];
    [self.blurEffectView.contentView addSubview:self.tracksSeparatorLine];
    self.tracksSeparatorLine.backgroundColor = [UIColor wr_colorFromColorScheme:ColorSchemeColorSeparator variant:ColorSchemeVariantDark];
    
    _playlistSeparatorLine = [[UIView alloc] initForAutoLayout];
    [self.blurEffectView.contentView addSubview:self.playlistSeparatorLine];
    self.playlistSeparatorLine.backgroundColor = [UIColor wr_colorFromColorScheme:ColorSchemeColorSeparator variant:ColorSchemeVariantDark];
    
    [self createInitialConstraints];
    [self updateHeaderView];
    
    self.audioTrackObserver = [KeyValueObserver observeObject:self.audioTrackPlayer
                                                      keyPath:NSStringFromSelector(@selector(audioTrack))
                                                       target:self
                                                     selector:@selector(audioTrackChanged:)
                                                      options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew];
    
    self.audioPlayerStateObserver = [KeyValueObserver observeObject:self.audioTrackPlayer
                                                            keyPath:NSStringFromSelector(@selector(state))
                                                             target:self
                                                           selector:@selector(audioPlayerStateChanged:)
                                                            options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew];
    
    self.audioProgressObserver = [KeyValueObserver observeObject:self.audioTrackPlayer
                                                         keyPath:NSStringFromSelector(@selector(progress))
                                                          target:self
                                                        selector:@selector(audioProgressChanged:)
                                                         options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew];
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    
    if (self.isTrackPlayingInAudioPlayer) {
        [self scrollToAudioTrack:self.audioTrackPlayer.audioTrack animated:NO];
    }
    
    [self updateTracksSeparatorLine];
    [self updatePlaylistSeparatorLine];
    
    // NOTE Workaround for layoutMargins bug in <= iOS 8.2
    // http://stackoverflow.com/a/29712427/203073
    self.contentContainer.layoutMargins = self.view.layoutMargins;
}

- (UIView *)touchableView
{
    return self.view;
}

- (void)createInitialConstraints
{
    [self.backgroundView autoPinEdgesToSuperviewEdgesWithInsets:UIEdgeInsetsZero];
    [self.blurEffectView autoPinEdgesToSuperviewEdgesWithInsets:UIEdgeInsetsZero];
    
    [self.audioHeaderView autoPinEdgesToSuperviewEdgesWithInsets:UIEdgeInsetsZero excludingEdge:ALEdgeBottom];
    [self.audioHeaderView autoSetDimension:ALDimensionHeight toSize:64];

    [self.tracksCollectionView autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.audioHeaderView];
    [self.tracksCollectionView autoPinEdgeToSuperviewEdge:ALEdgeLeft];
    [self.tracksCollectionView autoPinEdgeToSuperviewEdge:ALEdgeRight];
    
    [self.playlistTableView autoPinEdgeToSuperviewEdge:ALEdgeLeft];
    [self.playlistTableView autoPinEdgeToSuperviewEdge:ALEdgeBottom];
    [self.playlistTableView autoPinEdgeToSuperviewMargin:ALEdgeRight];
    [self.playlistTableView autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.tracksCollectionView withOffset:16];
    [self.playlistTableView autoSetDimension:ALDimensionHeight toSize:self.playlistTableView.rowHeight * 2.5];
    
    [self.contentContainer autoPinEdgesToSuperviewEdgesWithInsets:UIEdgeInsetsZero excludingEdge:ALEdgeLeft];
    [self.contentContainer autoPinEdgeToSuperviewMargin:ALEdgeLeft];
    
    [self.tracksSeparatorLine autoSetDimension:ALDimensionWidth toSize:0.5];
    [self.tracksSeparatorLine autoAlignAxis:ALAxisHorizontal toSameAxisOfView:self.tracksCollectionView];
    [self.tracksSeparatorLine autoPinEdge:ALEdgeRight toEdge:ALEdgeLeft ofView:self.tracksCollectionView];
    _tracksSeparatorLineHeightConstraint = [self.tracksSeparatorLine autoSetDimension:ALDimensionHeight toSize:0];
    
    [self.playlistSeparatorLine autoSetDimension:ALDimensionHeight toSize:0.5];
    [self.playlistSeparatorLine autoMatchDimension:ALDimensionWidth toDimension:ALDimensionWidth ofView:self.playlistTableView withOffset:2 * SeparatorLineOverflow];
    [self.playlistSeparatorLine autoPinEdge:ALEdgeBottom toEdge:ALEdgeTop ofView:self.playlistTableView];
    [self.playlistSeparatorLine autoPinEdge:ALEdgeLeft toEdge:ALEdgeLeft ofView:self.tracksCollectionView withOffset:-SeparatorLineOverflow];
    
    [self.view autoSetDimension:ALDimensionHeight toSize:375 relation:NSLayoutRelationLessThanOrEqual];
    
    [NSLayoutConstraint autoSetPriority:UILayoutPriorityDefaultHigh forConstraints:^{
        [self.view autoMatchDimension:ALDimensionHeight toDimension:ALDimensionWidth ofView:self.view];
    }];
}

- (void)fetchAttachment
{
    LinkAttachmentCache *cache = [LinkAttachmentCache sharedInstance];
    id cachedResource = [cache objectForKey:self.linkAttachment.URL];
    
    self.loadingFailed = NO;

    if (cachedResource != nil) {
        self.audioPlaylist = cachedResource;
    } else {
        @weakify(self);
        [[SoundcloudService sharedInstance] loadAudioResourceFromURL:self.linkAttachment.URL completion:^(id audioResource, NSError *error) {
            @strongify(self);
            if (error == nil && audioResource != nil) {
                self.audioPlaylist = audioResource;
                [cache setObject:audioResource forKey:self.linkAttachment.URL];
                
                self.loadingFailed = NO;
            }
            else {
                self.loadingFailed = YES;
            }
        }];
    }
}

- (void)setAudioPlaylist:(id<AudioPlaylist>)audioPlaylist
{
    _audioPlaylist = audioPlaylist;
    
    [self.playlistTableView reloadData];
    [self.tracksCollectionView reloadData];
    
    if (self.isTrackPlayingInAudioPlayer) {
        [self scrollToAudioTrack:self.audioTrackPlayer.audioTrack animated:NO];
    }
    
    [self updateHeaderView];
    [self updateStatusForAudioTrack:self.audioTrackPlayer.audioTrack];
    [self updateBackgroundForAudioTrack:self.audioTrackPlayer.audioTrack];
}

- (void)setLoadingFailed:(BOOL)loadingFailed
{
    if (_loadingFailed == loadingFailed) {
        return;
    }
    _loadingFailed = loadingFailed;
    
    [self updateForFailedState];
}

- (void)updateForFailedState
{
    if (self.loadingFailed) {
        self.view.backgroundColor = UIColor.blackColor;
    }
    else {
        self.view.backgroundColor = UIColor.soundcloudOrange;
    }
    
    [self.tracksCollectionView reloadData];
    [self.playlistTableView reloadData];
}

- (void)setProviderImage:(UIImage *)providerImage
{
    _providerImage = providerImage;
    
    [self.audioHeaderView.providerButton setImage:providerImage forState:UIControlStateNormal];
}

- (BOOL)isTrackPlayingInAudioPlayer
{
    return [self.audioTrackPlayer.sourceMessage isEqual:self.sourceMessage] && [self.audioPlaylist.tracks containsObject:self.audioTrackPlayer.audioTrack];
}

- (void)scrollToAudioTrack:(id<AudioTrack>)audioTrack animated:(BOOL)animated
{
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:[self.audioPlaylist.tracks indexOfObject:self.audioTrackPlayer.audioTrack] inSection:0];
    [self.tracksCollectionView scrollToItemAtIndexPath:indexPath atScrollPosition:UICollectionViewScrollPositionLeft animated:animated];
    [self.playlistTableView selectRowAtIndexPath:indexPath animated:animated scrollPosition:UITableViewScrollPositionTop];
}

- (void)updateHeaderView
{
    self.audioHeaderView.artistLabel.text = [self.audioPlaylist.author uppercasedWithCurrentLocale];
    self.audioHeaderView.trackTitleLabel.text = [self.audioPlaylist.title uppercasedWithCurrentLocale];
}

- (void)updateTracksSeparatorLine
{
    const CGFloat trackWidth = self.tracksCollectionView.bounds.size.height;
    const CGFloat trackSpacing = [(UICollectionViewFlowLayout *)self.tracksCollectionView.collectionViewLayout minimumInteritemSpacing];
    const CGFloat repeatingWidth = trackWidth + trackSpacing;

    if (trackWidth == 0) {
        return;
    }
    
    double integralPart = 0;
    double fractionalPart = modf(self.tracksCollectionView.contentOffset.x / repeatingWidth, &integralPart);
    
    if (fractionalPart * repeatingWidth >= trackWidth) {
        fractionalPart = 0;
    }
    
    const CGFloat base = MIN(1, fabs(((fractionalPart * repeatingWidth) / trackWidth) * 2 - 1));
    const CGFloat height = sqrt(1 - base * base) * trackWidth;
    
    self.tracksSeparatorLineHeightConstraint.constant = height + (height > 0 ? SeparatorLineOverflow * 2 : 0);
    [self.tracksSeparatorLine layoutIfNeeded];
}

- (void)updatePlaylistSeparatorLineAnimated
{
    [UIView animateWithDuration:0.35 animations:^{
        [self updatePlaylistSeparatorLine];
    }];
}

- (void)updatePlaylistSeparatorLine
{
    if (self.playlistTableView.contentOffset.y > 0) {
        self.playlistSeparatorLine.alpha = 1;
    } else {
        self.playlistSeparatorLine.alpha = 0;
    }
}

- (void)updateBackgroundForAudioTrack:(id<AudioTrack>)audioTrack
{
    if (! [self.audioPlaylist.tracks containsObject:audioTrack]) {
        audioTrack = self.audioPlaylist.tracks.firstObject;
    }
    
    self.artworkObserver = [KeyValueObserver observeObject:audioTrack keyPath:@"artwork" target:self selector:@selector(backgroundArtworkChanged:) options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew];
}

- (void)updateStatusForAudioTrack:(id<AudioTrack>)audioTrack
{
    if (audioTrack == nil || ! [self.audioPlaylist.tracks containsObject:audioTrack]) {
        return;
    }
    
    if (self.audioTrackPlayer.state == MediaPlayerStateError) {
        [self.playlistTableView reloadData];
    }
    
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:[self.audioPlaylist.tracks indexOfObject:audioTrack] inSection:0];
    AudioTrackCell *cell = (AudioTrackCell *)[self.tracksCollectionView cellForItemAtIndexPath:indexPath];
    [self configureAudioTrackCell:cell withAudioTrack:audioTrack];
    
    if ([self.audioTrackPlayer.sourceMessage isEqual:self.sourceMessage]) {
        if ([self.audioTrackPlayer.audioTrack isEqual:audioTrack]) {
            [self.playlistTableView selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
        } else {
            [self.playlistTableView deselectRowAtIndexPath:indexPath animated:NO];
        }
    }
}

- (void)configureAudioTrackCell:(AudioTrackCell *)audioTrackCell withAudioTrack:(id<AudioTrack>)audioTrack
{
    if ([self.audioTrackPlayer.sourceMessage isEqual:self.sourceMessage] && [self.audioTrackPlayer.audioTrack isEqual:audioTrack]) {
        audioTrackCell.audioTrackView.progress = self.audioTrackPlayer.progress;
        audioTrackCell.audioTrackView.failedToLoad = audioTrack.failedToLoad;
        ZetaIconType icon = self.audioTrackPlayer.isPlaying ? ZetaIconTypePause : ZetaIconTypePlay;
        [audioTrackCell.audioTrackView.playPauseButton setIcon:icon withSize:ZetaIconSizeLarge forState:UIControlStateNormal];
    } else {
        audioTrackCell.audioTrackView.progress = 0;
        [audioTrackCell.audioTrackView.playPauseButton setIcon:ZetaIconTypePlay withSize:ZetaIconSizeLarge forState:UIControlStateNormal];
    }
}

- (void)playPauseTrack:(id<AudioTrack>)audioTrack
{
    if ([self.audioTrackPlayer.sourceMessage isEqual:self.sourceMessage] && [self.audioTrackPlayer.audioTrack isEqual:audioTrack]) {
        if (self.audioTrackPlayer.isPlaying) {
            [self.audioTrackPlayer pause];
        } else {
            [self.audioTrackPlayer play];
        }
    } else {
        [self.audioTrackPlayer loadTrack:audioTrack playlist:self.audioPlaylist sourceMessage:self.sourceMessage completionHandler:^(BOOL loaded, NSError *error) {
            if (loaded) {
                [self.audioTrackPlayer play];
            } else {
                ZMLogWarn(@"Couldn't load audio track (%@): %@", audioTrack.title, error);
            }
        }];
    }
}


#pragma mark - Actions 

- (IBAction)openInBrowser:(id)sender
{
    [[UIApplication sharedApplication] openURL:self.audioPlaylist.externalURL
                                       options:@{}
                             completionHandler:NULL];
}

#pragma mark - AudioTrackCellDelegate

- (void)audioTrackCell:(AudioTrackCell *)cell didPlayPauseTrack:(id<AudioTrack>)audioTrack
{
    [self playPauseTrack:cell.audioTrack];
    
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:[self.audioPlaylist.tracks indexOfObject:audioTrack] inSection:0];
    [self.playlistTableView selectRowAtIndexPath:indexPath animated:YES scrollPosition:UITableViewScrollPositionTop];
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (self.loadingFailed) {
        return 1;
    }
    if (section == 0) {
        return self.audioPlaylist.tracks.count;
    }
    
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    AudioPlaylistCell *cell = [tableView dequeueReusableCellWithIdentifier:AudioPlaylistCellReuseIdentifier forIndexPath:indexPath];
    
    cell.separatorInset = UIEdgeInsetsZero;
    cell.layoutMargins = UIEdgeInsetsZero;
    cell.preservesSuperviewLayoutMargins = NO;
    
    if (self.loadingFailed) {
        cell.titleLabel.text = NSLocalizedString(@"content.player.unable_to_play", @"");
    }
    else {
        id<AudioTrack> audioTrack = [self.audioPlaylist.tracks objectAtIndex:indexPath.row];
        if (audioTrack.failedToLoad) {
            cell.titleLabel.text = NSLocalizedString(@"content.player.unable_to_play", @"");
        }
        else {
            cell.titleLabel.text = [audioTrack.title uppercasedWithCurrentLocale];
        }
        cell.durationLabel.text = [[NSDateComponentsFormatter new] stringFromTimeInterval:audioTrack.duration];
        
        BOOL isLastItem = indexPath.row == (NSInteger)self.audioPlaylist.tracks.count - 1;
        
        if (isLastItem) {
            cell.separatorInset = UIEdgeInsetsMake(0, 0, 0, tableView.bounds.size.width);
        }
    }
    
    return cell;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (self.loadingFailed) {
        return;
    }
    id<AudioTrack> audioTrack = [self.audioPlaylist.tracks objectAtIndex:indexPath.row];
    
    [self playPauseTrack:audioTrack];
    
    [self.tracksCollectionView scrollToItemAtIndexPath:indexPath atScrollPosition:UICollectionViewScrollPositionLeft animated:YES];
}

#pragma mark - UICollectionViewDataSource

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    if (self.loadingFailed) {
        return 1;
    }
    if (section == 0) {
        return self.audioPlaylist.tracks.count;
    }
    
    return 0;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    AudioTrackCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:AudioTrackCellReuseIdentifier forIndexPath:indexPath];
    
    if (self.loadingFailed) {
        cell.audioTrack = nil;
    }
    else {
        id<AudioTrack> audioTrack = [self.audioPlaylist.tracks objectAtIndex:indexPath.row];
        cell.audioTrack = audioTrack;
        cell.delegate = self;
        
        [self configureAudioTrackCell:cell withAudioTrack:audioTrack];
    }
    
    return cell;
}

#pragma mark - UICollectionViewDelegateFlowLayout

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    CGFloat itemHeight = collectionView.bounds.size.height - collectionView.contentInset.top - collectionView.contentInset.bottom;
    return CGSizeMake(itemHeight, itemHeight);
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    if (scrollView == self.tracksCollectionView) {
        [self updateTracksSeparatorLine];
    }
    
    if (scrollView == self.playlistTableView) {
        [self updatePlaylistSeparatorLineAnimated];
    }
}

#pragma mark - KVO observers

- (void)audioProgressChanged:(NSDictionary *)change
{
    if (self.isTrackPlayingInAudioPlayer) {
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:[self.audioPlaylist.tracks indexOfObject:self.audioTrackPlayer.audioTrack] inSection:0];
        AudioTrackCell *cell = (AudioTrackCell *)[self.tracksCollectionView cellForItemAtIndexPath:indexPath];
        [cell.audioTrackView setProgress:self.audioTrackPlayer.progress duration:1.0f/60.0f];
    }
}

- (void)audioPlayerStateChanged:(NSDictionary *)change
{
    if (self.isTrackPlayingInAudioPlayer) {
        [self updateStatusForAudioTrack:self.audioTrackPlayer.audioTrack];
    }
}

- (void)audioTrackChanged:(NSDictionary *)change
{
    [self updateStatusForAudioTrack:[change valueForKey:NSKeyValueChangeOldKey]];
    [self updateStatusForAudioTrack:[change valueForKey:NSKeyValueChangeNewKey]];
    [self updateBackgroundForAudioTrack:[change valueForKey:NSKeyValueChangeNewKey]];
}

- (void)backgroundArtworkChanged:(NSDictionary *)change
{
    UIImage *artwork = [change valueForKey:NSKeyValueChangeNewKey];
    
    if (! [artwork isEqual:NSNull.null]) {
        [UIView transitionWithView:self.backgroundView duration:0.55 options:UIViewAnimationOptionTransitionCrossDissolve animations:^{
            self.backgroundView.image = artwork;
        } completion:nil];
    }
}

@end
