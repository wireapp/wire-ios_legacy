//
// Wire
// Copyright (C) 2018 Wire Swiss GmbH
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

@class ImageToolbarView;
@class Button;
@class FLAnimatedImageView;

@import AVKit;

@interface ConfirmAssetViewController ()

@property (nonatomic, nullable) NSURL *videoURL;
@property (nonatomic, nullable) AVPlayerViewController *playerViewController;

@property (nonatomic, nonnull) UIView *topPanel;
@property (nonatomic, nonnull) UILabel *titleLabel;
@property (nonatomic, nonnull) UIView *bottomPanel;
@property (nonatomic, nonnull) UIStackView *confirmButtonsStack;
@property (nonatomic, nonnull) Button *acceptImageButton;
@property (nonatomic, nonnull) Button *rejectImageButton;

@property (nonatomic, nonnull) UILayoutGuide *contentLayoutGuide;

// The preview view and image toolbar are optional
@property (nonatomic, nullable) FLAnimatedImageView *imagePreviewView;
@property (nonatomic, nullable) UIView *imageToolbarSeparatorView;
@property (nonatomic, nullable) ImageToolbarView *imageToolbarViewInsideImage;
@property (nonatomic, nullable) ImageToolbarView *imageToolbarView;

@end
