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


#import "CameraAccessDeniedView.h"

@import PureLayout;


#import "UIColor+WAZExtensions.h"
#import "WAZUIMagicIOS.h"
#import "Button.h"
#import "Wire-Swift.h"



@interface CameraAccessDeniedView ()

@property (nonatomic) UILabel *titleLabel;
@property (nonatomic) UILabel *instructionsLabel;
@property (nonatomic) Button *openSettingsButton;

@property (nonatomic) BOOL initialContraintsCreated;

@end



@implementation CameraAccessDeniedView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    
    if (self) {
        self.backgroundColor = [UIColor blackColor];
        
        self.titleLabel = [[UILabel alloc] initForAutoLayout];
        self.titleLabel.font = [UIFont fontWithMagicIdentifier:@"style.text.normal.font_spec_bold"];
        self.titleLabel.textColor = UIColor.whiteColor;
        self.titleLabel.textAlignment = NSTextAlignmentLeft;
        self.titleLabel.text = NSLocalizedString(@"camera_access.denied", "");
        self.titleLabel.numberOfLines = 0;
        [self addSubview:self.titleLabel];
        
        self.instructionsLabel = [[UILabel alloc] initForAutoLayout];
        self.instructionsLabel.font = [UIFont fontWithMagicIdentifier:@"style.text.normal.font_spec"];
        self.instructionsLabel.textColor = UIColor.whiteColor;
        self.instructionsLabel.text = NSLocalizedString(@"camera_access.denied.instruction", "");
        self.instructionsLabel.numberOfLines = 0;
        [self addSubview:self.instructionsLabel];
        
        self.openSettingsButton = [Button buttonWithStyleClass:@"dialogue-button-full"];
        self.openSettingsButton.translatesAutoresizingMaskIntoConstraints = NO;
        self.openSettingsButton.backgroundColor = UIColor.accentColor;
        [self.openSettingsButton setTitle:[NSLocalizedString(@"camera_access.denied.open_settings", nil) uppercasedWithCurrentLocale] forState:UIControlStateNormal];
        [self.openSettingsButton addTarget:self action:@selector(launchAppSettings:) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:self.openSettingsButton];
        
        [self setNeedsUpdateConstraints];
    }
    
    return self;
}

- (void)updateConstraints
{
    if (! self.initialContraintsCreated) {
        
        [self.titleLabel autoPinEdgesToSuperviewEdgesWithInsets:UIEdgeInsetsZero excludingEdge:ALEdgeBottom];
        [self.instructionsLabel autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.titleLabel withOffset:12];
        [self.instructionsLabel autoPinEdgeToSuperviewEdge:ALEdgeLeft];
        [self.instructionsLabel autoPinEdgeToSuperviewEdge:ALEdgeRight];
        
        [self.openSettingsButton autoSetDimension:ALDimensionHeight toSize:40];
        [self.openSettingsButton autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.instructionsLabel withOffset:24];
        [self.openSettingsButton autoPinEdgeToSuperviewEdge:ALEdgeBottom];
        [self.openSettingsButton autoAlignAxisToSuperviewAxis:ALAxisVertical];
        
        self.initialContraintsCreated = YES;
    }
    
    [super updateConstraints];
}

- (IBAction)launchAppSettings:(id)sender
{
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString]];
}

@end
