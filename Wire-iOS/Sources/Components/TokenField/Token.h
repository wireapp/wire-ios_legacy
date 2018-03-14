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


@import UIKit;


NS_ASSUME_NONNULL_BEGIN
@interface Token : NSObject

- (instancetype)initWithTitle:(nullable NSString *)title representedObject:(id)representedObject;

@property (strong, nonatomic) id representedObject;

@property (copy, nonatomic) NSString *title;

// if title render is longer than this length, it is trimmed with "..."
@property (assign, nonatomic) CGFloat maxTitleWidth;

@end
NS_ASSUME_NONNULL_END
