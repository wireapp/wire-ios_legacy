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

#import "SketchViewController.h"

NS_ASSUME_NONNULL_BEGIN

@class AudioRecordKeyboardViewController;
@class CameraKeyboardViewController;
@class ConversationInputBarSendController;


@interface ConversationInputBarViewController ()
@property (nonatomic, nullable) AudioRecordViewController *audioRecordViewController;
@property (nonatomic, nullable) AudioRecordKeyboardViewController *audioRecordKeyboardViewController;
@property (nonatomic, nullable) CameraKeyboardViewController *cameraKeyboardViewController;
@property (nonatomic, nonnull)  ConversationInputBarSendController *sendController;

@property (nonatomic)           BOOL shouldRefocusKeyboardAfterImagePickerDismiss;

@property (nonatomic)           NSUInteger videoSendContext;
- (void)createAudioRecordViewController;
@end


@interface ConversationInputBarViewController (Sketch) <SketchViewControllerDelegate>
- (void)sketchButtonPressed:(nullable id)sender;
@end


NS_ASSUME_NONNULL_END
