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


#import "ParticipantDeviceCell.h"
#import "ParticipantDeviceCell+Internal.h"

#import "WireSyncEngine+iOS.h"
#import "UIImage+ZetaIconsNeue.h"
#import "WireExtensionComponents.h"
@import PureLayout;
#import "NSString+Fingerprint.h"
#import "Wire-Swift.h"



@interface ParticipantDeviceCell ()

@property (strong, nonatomic) UIImageView *trustLevelImageView;

@end


@implementation ParticipantDeviceCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    
    if (self) {
        self.backgroundColor = UIColor.clearColor;
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        self.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        [self createViews];
        [self setupConstraints];
        [self setupStyle];
    }
    
    return self;
}

- (void)createViews
{
    self.nameLabel = [[UILabel alloc] initForAutoLayout];
    [self.contentView addSubview:self.nameLabel];
    
    self.identifierLabel = [[UILabel alloc] initForAutoLayout];
    [self.contentView addSubview:self.identifierLabel];
    
    self.trustLevelImageView = [[UIImageView alloc] initForAutoLayout];
    self.trustLevelImageView.contentMode = UIViewContentModeScaleAspectFit;
    self.trustLevelImageView.clipsToBounds = YES;
    [self.contentView addSubview:self.trustLevelImageView];
}

- (void)setupConstraints
{
    [self.trustLevelImageView autoSetDimensionsToSize:CGSizeMake(16, 16)];
    [self.trustLevelImageView autoPinEdgeToSuperviewEdge:ALEdgeLeading withInset:24];
    [self.trustLevelImageView autoAlignAxis:ALAxisHorizontal toSameAxisOfView:self.nameLabel];
    
    [self.nameLabel autoPinEdgeToSuperviewEdge:ALEdgeTop withInset:16];
    [self.nameLabel autoPinEdge:ALEdgeLeading toEdge:ALEdgeTrailing ofView:self.trustLevelImageView withOffset:16];
    
    [self.identifierLabel autoPinEdge:ALEdgeLeading toEdge:ALEdgeLeading ofView:self.nameLabel];
    [self.identifierLabel autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.nameLabel withOffset:0 relation:NSLayoutRelationGreaterThanOrEqual];
    [self.identifierLabel autoPinEdgeToSuperviewEdge:ALEdgeBottom withInset:16];
}

- (void)setHighlighted:(BOOL)highlighted animated:(BOOL)animated
{
    [super setHighlighted:highlighted animated:animated];
    self.backgroundColor = highlighted ? [UIColor colorWithWhite:0 alpha:0.08] : UIColor.clearColor;
}

#pragma mark - Configuration

- (void)configureForClient:(UserClient *)client
{
    NSDictionary *attributes = @{ NSFontAttributeName: self.fingerprintFont.monospaced };
    NSDictionary *boldAttributes = @{ NSFontAttributeName: self.boldFingerprintFont.monospaced };
    self.identifierLabel.attributedText = [client attributedRemoteIdentifier:attributes boldAttributes:boldAttributes uppercase:YES];
    self.nameLabel.text = client.deviceClass.uppercaseString ?: client.type.uppercaseString;
    self.trustLevelImageView.image = client.verified ? WireStyleKit.imageOfShieldverified : WireStyleKit.imageOfShieldnotverified;
}

@end
