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
#import "ZetaIconTypes.h"
@import WireExtensionComponents;

@class CheckBoxButton;


typedef NS_ENUM(NSUInteger, SheetActionStyle) {
    SheetActionStyleDefault = 0,
    SheetActionStyleCancel
};


@interface SheetAction : NSObject

@property (nonatomic) NSString *accessibilityIdentifier;
@property (nonatomic, readonly) NSString *title;
@property (nonatomic, readonly) NSString *message;
@property (nonatomic, readonly) ZetaIconType iconType;
@property (nonatomic, readonly) SheetActionStyle style;

- (IBAction)performAction:(id)sender;

+ (instancetype)actionWithTitle:(NSString *)title iconType:(ZetaIconType)iconType handler:(void (^)(SheetAction *))handler;
+ (instancetype)actionWithTitle:(NSString *)title iconType:(ZetaIconType)iconType style:(SheetActionStyle)style handler:(void (^)(SheetAction *action))handler;

@end



typedef NS_ENUM(NSUInteger, ActionSheetControllerLayout) {
    ActionSheetControllerLayoutList,
    ActionSheetControllerLayoutGrid,
    ActionSheetControllerLayoutAlert
};

typedef NS_ENUM(NSUInteger, ActionSheetControllerStyle) {
    ActionSheetControllerStyleLight,
    ActionSheetControllerStyleDark
};

typedef NS_ENUM(NSUInteger, ActionSheetControllerDismissStyle) {
    ActionSheetControllerDismissStyleBackground,
    ActionSheetControllerDismissStyleCloseButton
};


@interface ActionSheetController : UIViewController

@property (nonatomic, readonly) NSArray *actions;
@property (nonatomic, readonly) NSArray *checkBoxButtons;
@property (nonatomic, readonly) ActionSheetControllerStyle style;
@property (nonatomic, readonly) ActionSheetControllerDismissStyle dismissStyle;

@property (nonatomic, copy) NSString *message;
@property (nonatomic, copy) NSString *messageTitle;
@property (nonatomic, copy) UIImage *iconImage;

- (instancetype)initWithTitle:(NSString *)title layout:(ActionSheetControllerLayout)layout style:(ActionSheetControllerStyle)style;
- (instancetype)initWithTitle:(NSString *)title layout:(ActionSheetControllerLayout)layout style:(ActionSheetControllerStyle)style dismissStyle:(ActionSheetControllerDismissStyle)dismissStyle;
- (instancetype)initWithTitleView:(UIView *)titleView
                           layout:(ActionSheetControllerLayout)layout
                            style:(ActionSheetControllerStyle)style
                     dismissStyle:(ActionSheetControllerDismissStyle)dismissStyle NS_DESIGNATED_INITIALIZER;

- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithCoder:(NSCoder *)aDecoder NS_UNAVAILABLE;
- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil NS_UNAVAILABLE;

- (void)addAction:(SheetAction *)action;
- (void)addCheckBoxButtonWithConfigurationHandler:(void (^)(CheckBoxButton *checkBoxButton))configurationHandler;

- (void)pushActionSheetController:(ActionSheetController *)actionSheetControllerToPresent animated:(BOOL)animated completion:(dispatch_block_t)completion;
- (void)popActionSheetControllerAnimated:(BOOL)animated completion:(dispatch_block_t)completion;

@end
