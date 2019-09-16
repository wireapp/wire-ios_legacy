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


@class InvisibleInputAccessoryView;


// Because the system manages the input accessory view lifecycle and positioning, we have to monitor what
// is being done to us and report back
@protocol InvisibleInputAccessoryViewDelegate <NSObject>

- (void)invisibleInputAccessoryView:(InvisibleInputAccessoryView *)view didMoveToWindow:(UIWindow *)window;
- (void)invisibleInputAccessoryView:(InvisibleInputAccessoryView *)view superviewFrameChanged:(CGRect)frame;

@end



@interface InvisibleInputAccessoryView : UIView

@property (nonatomic, weak, nullable) id<InvisibleInputAccessoryViewDelegate> delegate;
@property (nonatomic, assign, readwrite) CGSize intrinsicContentSize;

@end
