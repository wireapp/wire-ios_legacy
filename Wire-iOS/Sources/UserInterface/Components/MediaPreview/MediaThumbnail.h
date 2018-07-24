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


@import Foundation;

NS_ASSUME_NONNULL_BEGIN

@interface MediaThumbnail : NSObject

@property (assign, nonatomic) CGSize size;
@property (copy, nonatomic) NSURL *URL;

- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithURL:(NSURL *)URL size:(CGSize)size NS_DESIGNATED_INITIALIZER;

@end

NS_ASSUME_NONNULL_END
