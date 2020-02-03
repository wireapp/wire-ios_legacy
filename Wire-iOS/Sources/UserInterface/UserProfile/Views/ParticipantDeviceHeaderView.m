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


#import "ParticipantDeviceHeaderView.h"
#import "ParticipantDeviceHeaderView+Internal.h"
#import "Wire-Swift.h"

@interface ParticipantDeviceHeaderView ()
@property (strong, nonatomic, readwrite) NSString *userName;
@end



@implementation ParticipantDeviceHeaderView

- (instancetype)initWithUserName:(NSString *)userName
{
    self = [super initWithFrame:CGRectZero];
    
    if (self) {
        _userName = userName;
        [self setup];
    }
    return self;
}

- (void)setup
{
    self.backgroundColor = UIColor.clearColor;
    [self createViews];
    [self setupConstraints];

    [self setupStyle];
}

- (void)createViews
{
    self.textView = [[WebLinkTextView alloc] init];

    self.textView.textContainer.maximumNumberOfLines = 0;
    self.textView.delegate = self;
    self.textView.linkTextAttributes = @{};
    
    [self addSubview:self.textView];
}

- (void)setShowUnencryptedLabel:(BOOL)showUnencryptedLabel
{
    self.textView.attributedText = [self attributedExplanationTextForUserName:self.userName showUnencryptedLabel:showUnencryptedLabel];
}

@end
