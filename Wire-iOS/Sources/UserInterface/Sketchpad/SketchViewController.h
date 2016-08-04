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

@class BackgroundViewController;
@protocol SketchViewControllerDelegate;



/// Sketchpad view controller
@interface SketchViewController : UIViewController

@property (nonatomic, readonly) BackgroundViewController *backgroundViewController;
/// If set, this image will be put in the background below the canvas, so the user can "draw" on top of it
@property (nonatomic) UIImage *canvasBackgroundImage;
@property (nonatomic, weak) id <SketchViewControllerDelegate> delegate;
@property (nonatomic, copy) NSString *sketchTitle;
@property (nonatomic) BOOL confirmsWithoutSketch;

@end



@protocol SketchViewControllerDelegate <NSObject>

- (void)sketchViewControllerDidCancel:(SketchViewController *)controller;
- (void)sketchViewController:(SketchViewController *)controller didSketchImage:(UIImage *)image;

@end
