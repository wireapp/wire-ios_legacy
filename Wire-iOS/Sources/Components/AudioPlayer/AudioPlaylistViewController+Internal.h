//
// Wire
// Copyright (C) 2019 Wire Swiss GmbH
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

#import "AudioHeaderView.h"
#import "AudioTrackView.h"

@interface AudioPlaylistViewController ()

@property (nonatomic, readonly) UIImageView *backgroundView;
@property (nonatomic, readonly) UIVisualEffectView *blurEffectView;
@property (nonatomic, readonly) AudioHeaderView *audioHeaderView;
@property (nonatomic, readonly) UIView *contentContainer;
@property (nonatomic, readonly) UITableView *playlistTableView;
@property (nonatomic, readonly) UICollectionView *tracksCollectionView;
@property (nonatomic, readonly) UIView *tracksSeparatorLine;
@property (nonatomic, readonly) UIView *playlistSeparatorLine;
@property (nonatomic) NSLayoutConstraint *tracksSeparatorLineHeightConstraint;

+ (CGFloat)separatorLineOverflow;

@end
