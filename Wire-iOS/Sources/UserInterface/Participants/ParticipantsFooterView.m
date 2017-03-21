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


#import "ParticipantsFooterView.h"
#import "IconButton.h"

#import "WAZUIMagicIOS.h"
#import <PureLayout/PureLayout.h>
#import "Wire-Swift.h"
@import WireExtensionComponents;


@interface ParticipantsFooterView ()

@property (nonatomic, readwrite) UIView *separatorLine;

@property (nonatomic) UIView *containerView;

@property (nonatomic) IconButton *leftButton;
@property (nonatomic) IconButton *rightButton;

@property (nonatomic) CGSize buttonSize;

@end



@implementation ParticipantsFooterView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    
    if (self) {
        self.buttonSize = (CGSize) {[WAZUIMagic cgFloatForIdentifier:@"participants.footer_button_size"], [WAZUIMagic cgFloatForIdentifier:@"participants.footer_button_size"]};
        [self addContainerView];
        [self addLeftButton];
        [self addRightButton];

        [self addSeparatorLine];

    }
    return self;
}

- (void)addContainerView
{
    self.containerView = [[UIView alloc] init];
    self.containerView.translatesAutoresizingMaskIntoConstraints = NO;


    [self addSubview:self.containerView];

    [self.containerView addConstraintForTopMargin:0 relativeToView:self];
    [self.containerView addConstraintForRightMargin:16 relativeToView:self];
    [self.containerView addConstraintForLeftMargin:16 relativeToView:self];
    [self addConstraintForAligningBottomToBottomOfView:self.containerView distance:0];


    self.containerView.backgroundColor = [UIColor clearColor];
}

- (void)addLeftButton
{
    self.leftButton = [IconButton iconButtonCircular];
    self.leftButton.translatesAutoresizingMaskIntoConstraints = NO;
    self.leftButton.accessibilityIdentifier = @"metaControllerLeftButton";
    [self.leftButton addTarget:self action:@selector(leftButtonTapped:) forControlEvents:UIControlEventTouchUpInside];

    [self.containerView addSubview:self.leftButton];

    [self.leftButton autoSetDimension:ALDimensionHeight toSize:24];
    [self.leftButton addConstraintForLeftMargin:0 relativeToView:self.containerView];
    [self.containerView addConstraintForAligningTopToTopOfView:self.leftButton distance:16];
    [self.containerView addConstraintForAligningBottomToBottomOfView:self.leftButton distance:- 16];
}

- (void)addRightButton
{
    self.rightButton = [IconButton iconButtonCircular];
    self.rightButton.translatesAutoresizingMaskIntoConstraints = NO;
    self.rightButton.accessibilityIdentifier = @"metaControllerRightButton";
    [self.rightButton addTarget:self action:@selector(rightButtonTapped:) forControlEvents:UIControlEventTouchUpInside];

    [self.containerView addSubview:self.rightButton];

    [self.rightButton autoMatchDimension:ALDimensionWidth toDimension:ALDimensionHeight ofView:self.rightButton];
    [self.rightButton autoSetDimension:ALDimensionWidth toSize:24];
    
    [self.rightButton addConstraintForRightMargin:0 relativeToView:self.containerView];
    [self.containerView addConstraintForAligningTopToTopOfView:self.rightButton distance:16];
    [self.containerView addConstraintForAligningBottomToBottomOfView:self.rightButton distance:- 16];
}

- (void)addSeparatorLine
{
    self.separatorLine = [[UIView alloc] init];
    self.separatorLine.translatesAutoresizingMaskIntoConstraints = NO;

    [self addSubview:self.separatorLine];
    [self.separatorLine addConstraintsForRightMargin:0 leftMargin:0 relativeToView:self];
    [self.separatorLine addConstraintForHeight:0.5];
    [self.separatorLine addConstraintForAligningTopToTopOfView:self distance:0];

    self.separatorLine.hidden = YES;
}

- (void)setIconTypeForLeftButton:(ZetaIconType)iconType
{
    [self setIconType:iconType forButton:self.leftButton];
}

- (void)setIconTypeForRightButton:(ZetaIconType)iconType
{
    [self setIconType:iconType forButton:self.rightButton];
}

- (void)setTitleForLeftButton:(NSString *)title
{
    [self.leftButton setTitle:title.uppercasedWithCurrentLocale forState:UIControlStateNormal];
}

- (void)setIconType:(ZetaIconType)iconType forButton:(IconButton *)button
{
    button.hidden = iconType == ZetaIconTypeNone;
    [button setIcon:iconType withSize:ZetaIconSizeTiny forState:UIControlStateNormal];
    
    [self layoutIfNeeded];
}

- (void)rightButtonTapped:(id)sender
{
    UIImage *image = [self.rightButton imageForState:UIControlStateNormal];
    if (! image) {
        // if the button has no image, its not enabled
        return;
    }

    if ([self.delegate respondsToSelector:@selector(participantsFooterView:rightButtonTapped:)]) {
        [self.delegate participantsFooterView:self rightButtonTapped:self.rightButton];
    }
}

- (void)leftButtonTapped:(id)sender
{
    UIImage *image = [self.leftButton imageForState:UIControlStateNormal];
    if (! image) {
        // if the button has no image, its not enabled
        return;
    }

    if ([self.delegate respondsToSelector:@selector(participantsFooterView:leftButtonTapped:)]) {
        [self.delegate participantsFooterView:self leftButtonTapped:self.leftButton];
    }
}

@end
