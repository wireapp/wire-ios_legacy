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

#import <WireSyncEngine/WireSyncEngine.h>

@protocol ColorPickerDelegate;
@class IdentifiableColor;



@interface ColorPickerController : UIViewController

@property (nonatomic, weak) id <ColorPickerDelegate> delegate;

/// Array of @c IdentifiableColor object's
@property (nonatomic, strong, readonly) NSArray *colors;
@property (nonatomic, strong) IdentifiableColor *selectedColor;

- (instancetype)initWithCoder:(NSCoder *)aDecoder NS_UNAVAILABLE;
- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil NS_UNAVAILABLE;
/// @param colors @c NSArray of @c IdentifiableColor objects
- (instancetype)initWithColors:(NSArray *)colors NS_DESIGNATED_INITIALIZER;

@end



@protocol ColorPickerDelegate <NSObject>

/// The user did something in the UI that caused the color picker to consider another color to be displayed/focused. However, this shouldn’t yet be considered their final choice.
- (void)colorPickerDidChangePreviewColor:(IdentifiableColor *)color;

/// The user committed their selection of the new accent color. New color should be set in the model.
- (void)colorPickerDidSelectColor:(IdentifiableColor *)color;

@optional

- (void)colorPickerWillLongPressOnColor:(IdentifiableColor *)color;

@end
