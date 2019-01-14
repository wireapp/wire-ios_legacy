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


#import "InvisibleInputAccessoryView.h"
#import "KeyValueObserver.h"




@interface InvisibleInputAccessoryView ()

@property (nonatomic, strong) NSObject *frameObserver;

@end




@implementation InvisibleInputAccessoryView

@synthesize intrinsicContentSize = _intrinsicContentSize;

- (void)setIntrinsicContentSize:(CGSize)intrinsicContentSize
{
    _intrinsicContentSize = intrinsicContentSize;
    [self invalidateIntrinsicContentSize];
}

- (CGSize)intrinsicContentSize
{
    return _intrinsicContentSize;
}

- (void)didMoveToWindow
{
    [super didMoveToWindow];
    [self.delegate invisibleInputAccessoryView:self didMoveToWindow:self.window];
    
    if (self.window) {
        
        NSString *keypath = @"center";
        
        self.frameObserver = [KeyValueObserver observeObject:self.superview
                                                      keyPath:keypath
                                                       target:self
                                                     selector:@selector(superviewFrameChanged:)];
    }
    else {
        self.frameObserver = nil;
    }
}

- (void)superviewFrameChanged:(NSDictionary *)changes
{
    [self.delegate invisibleInputAccessoryView:self superviewFrameChanged:self.superview.frame];
}


@end
