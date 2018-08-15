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


#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface KeyboardAvoidingViewController : UIViewController

@property (nonatomic, readonly) UIViewController *viewController;

@property (nonatomic, copy, nullable) BOOL (^shouldAdjustFrame)(UIViewController *);
@property (nonatomic) CGFloat topInset;

- (instancetype)initWithCoder:(NSCoder *)aDecoder NS_UNAVAILABLE;
- (instancetype)initWithNibName:(NSString * _Nullable)nibNameOrNil bundle:(NSBundle  * _Nullable)nibBundleOrNil NS_UNAVAILABLE;
- (instancetype)initWithViewController:(UIViewController *)viewController NS_DESIGNATED_INITIALIZER;

@end

NS_ASSUME_NONNULL_END
