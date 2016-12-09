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


#import "ActionSheetController.h"
#import "ZMConversation+Actions.h"



@interface ActionSheetController (Conversation)

- (void)addActionsForConversation:(ZMConversation *)conversation;

+ (ActionSheetController *)dialogForConversationDetails:(ZMConversation *)conversation style:(ActionSheetControllerStyle)style;
+ (ActionSheetController *)dialogForBlockingUser:(ZMUser *)user style:(ActionSheetControllerStyle)style completion:(void (^)(BOOL canceled))completion;
+ (ActionSheetController *)dialogForRemovingUser:(ZMUser *)user fromConversation:(ZMConversation *)conversation style:(ActionSheetControllerStyle)style completion:(void (^)(BOOL canceled))completion;
+ (ActionSheetController *)dialogForAcceptingConnectionRequestWithUser:(ZMUser *)user style:(ActionSheetControllerStyle)style completion:(void (^)(BOOL ignored))completion;
+ (ActionSheetController *)dialogForCancelingConnectionRequestWithUser:(ZMUser *)user style:(ActionSheetControllerStyle)style completion:(void (^)(BOOL canceled))completion;
+ (ActionSheetController *)dialogForUnknownClientsForUsers:(NSSet<ZMUser *> *)users style:(ActionSheetControllerStyle)style completion:(void (^)(BOOL sendAnywayPressed, BOOL showDetailsPressed))completion;


+ (ActionSheetControllerStyle)defaultStyle;

@end
