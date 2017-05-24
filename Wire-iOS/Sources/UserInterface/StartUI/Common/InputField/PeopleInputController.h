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


@import UIKit;


@class ZMUser, PeopleInputController, TokenField, UserSelection;


@protocol PeopleInputControllerTextDelegate <NSObject>

- (void)peopleInputController:(PeopleInputController *)controller changedFilterTextTo:(NSString *)text;

- (void)peopleInputControllerDidConfirmInput:(PeopleInputController *)controller;

@end

@interface PeopleInputController : UIViewController

@property (strong, nonatomic, readonly) TokenField *tokenField;

@property (weak, nonatomic) id <PeopleInputControllerTextDelegate> delegate;
@property (nonatomic) UserSelection *userSelection;
@property (nonatomic) BOOL retainSelectedState;
@property (nonatomic, readonly) BOOL userDidConfirmInput;

@property (copy, readonly, nonatomic) NSString *plainTextContent;

- (void)addTokenForUser:(ZMUser *)user;

- (void)removeTokenForUser:(ZMUser *)user;

- (void)removeAllTokens;

- (void)filterUnwantedAttachments;

@end
