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


@import WireExtensionComponents;

#import <PureLayout/PureLayout.h>
#import <Classy/Classy.h>

#import "PeoplePickerEmptyResultsActionView.h"
#import "WAZUIMagicIOS.h"

#import "UIImage+ZetaIconsNeue.h"
#import "NSString+WAZUIMagic.h"
#import "Constants.h"

@interface PeoplePickerEmptyResultsActionView ()
@property (strong, nonatomic) NSString *title;
@property (assign, nonatomic) ZetaIconType icon;
@property (strong, nonatomic) IconButton *iconButton;
@property (strong, nonatomic) UILabel *titleLabel;
@property (strong, nonatomic) UIColor *foregroundColor;
@end

@implementation PeoplePickerEmptyResultsActionView

#pragma mark - Init

- (instancetype)initWithTitle:(NSString *)title
                         icon:(ZetaIconType)icon foregroundColor:(UIColor *)color
                       target:(id)target action:(SEL)action
{
    self = [super init];
    if (self) {
        self.foregroundColor = color;
        
        [self setupSubviews];
        [self setupConstraints];
        
        [self setTitle:title];
        [self setIcon:icon];
        [self setTarget:target action:action];
    }
    return self;
}

#pragma mark - Setup subviews

- (void)setupSubviews
{
    self.iconButton = [IconButton iconButtonCircularLight];
    self.iconButton.translatesAutoresizingMaskIntoConstraints = NO;
    [self addSubview:self.iconButton];
    
    self.titleLabel = [UILabel new];
    self.titleLabel.font = [UIFont fontWithMagicIdentifier:@"people_picker.search_results_empty.action_title.font"];
    self.titleLabel.textColor = self.foregroundColor;
    self.titleLabel.numberOfLines = 5;
    self.titleLabel.textAlignment = NSTextAlignmentCenter;
    self.titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [self addSubview:self.titleLabel];
}

- (void)setupConstraints
{
    [self.iconButton addConstraintsForRightMargin:20 leftMargin:20 relativeToView:self];
    [self.iconButton addConstraintForTopMargin:0 relativeToView:self];
    [self.iconButton addConstraintsForSize:CGSizeMake(64.0f, 64.0f)];
    
    [self.titleLabel addConstraintForAligningTopToBottomOfView:self.iconButton distance:12];
    
    [self.titleLabel addConstraintForAligningHorizontallyWithView:self];
    [self.titleLabel addConstraintForMinLeftMargin:5 relativeToView:self];
    [self.titleLabel addConstraintForMinRightMargin:5 relativeToView:self];
    [self.titleLabel addConstraintForBottomMargin:0 relativeToView:self];
}

#pragma mark - Properties

- (void)setTitle:(NSString *)title
{
    if ([_title isEqualToString:title]) {
        return;
    }
    
    _title = [title transformStringWithMagicKey:@"people_picker.search_results_empty.action_title.transform"];
    if (self.titleLabel) {
        self.titleLabel.text = _title;
    }
}

- (void)setIcon:(ZetaIconType)icon
{
    [self.iconButton setIcon:icon withSize:ZetaIconSizeSmall forState:UIControlStateNormal];
}

- (void)setTarget:(id)target action:(SEL)action
{
    NSArray *actions = [self.iconButton actionsForTarget:target forControlEvent:UIControlEventTouchUpInside];
    if (actions) {
        for (NSString *actionName in actions) {
            [self.iconButton removeTarget:target action:NSSelectorFromString(actionName) forControlEvents:UIControlEventTouchUpInside];
        }
    }
    [self.iconButton addTarget:target action:action forControlEvents:UIControlEventTouchUpInside];
}

@end
