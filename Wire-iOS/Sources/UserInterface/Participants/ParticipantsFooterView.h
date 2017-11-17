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


@class ParticipantsFooterView;


@protocol ParticipantsFooterDelegate <NSObject>

@optional
- (void)participantsFooterView:(ParticipantsFooterView *)footerView leftButtonTapped:(UIButton *)leftButton;
- (void)participantsFooterView:(ParticipantsFooterView *)footerView rightButtonTapped:(UIButton *)rightButton;

@end



@interface ParticipantsFooterView : UIView

- (void)setIconTypeForLeftButton:(ZetaIconType)iconType;
- (void)setTitleForLeftButton:(NSString *)title;

- (void)setIconTypeForRightButton:(ZetaIconType)iconType;

@property (nonatomic, weak) id <ParticipantsFooterDelegate> delegate;
@property (nonatomic, strong, readonly) UIView *separatorLine;

@end
