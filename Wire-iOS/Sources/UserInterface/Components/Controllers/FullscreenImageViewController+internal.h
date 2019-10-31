////
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

@class IconButton;
@class ObfuscationView;
@class ConversationMessageActionController;

static CGFloat const kZoomScaleDelta = 0.0003;

@interface FullscreenImageViewController ()

@property (nonatomic) CGFloat lastZoomScale;
@property (nullable, nonatomic, readwrite) UIImageView *imageView;
@property (nonatomic) CGFloat minimumDismissMagnitude;
@property (nonatomic, readwrite, nonnull) UIScrollView *scrollView;
@property (nonatomic, nullable) UIActivityIndicatorView *loadingSpinner;
@property (nonatomic, nonnull) ObfuscationView *obfuscationView;
@property (nonatomic, strong, nonnull) ConversationMessageActionController *actionController;

- (void)centerScrollViewContent;
- (void)setSelectedByMenu:(BOOL)selected animated:(BOOL)animated;

@end

@interface FullscreenImageViewController () <UIScrollViewDelegate>
@end
