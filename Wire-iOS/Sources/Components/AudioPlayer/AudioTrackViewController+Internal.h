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

@interface AudioTrackViewController ()

@property (nonnull, nonatomic, readonly) UIImageView *backgroundView;
@property (nonnull, nonatomic, readonly) UIVisualEffectView *blurEffectView;
@property (nonnull, nonatomic, readonly) AudioHeaderView *audioHeaderView;
@property (nonnull, nonatomic, readonly) AudioTrackView *audioTrackView;
@property (nonnull, nonatomic, readonly) UILabel *subtitleLabel;

@end
