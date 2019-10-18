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


@class ZMConversation;
@class ConversationListContentController;
@protocol ZMConversationMessage;
@protocol ConversationListContentDelegate;

NS_ASSUME_NONNULL_BEGIN

@interface ConversationListContentController : UICollectionViewController

@property (nonatomic, weak, nullable) id <ConversationListContentDelegate> contentDelegate;

- (instancetype)initWithCoder:(NSCoder *)aDecoder NS_UNAVAILABLE;
- (instancetype)initWithNibName:(nullable NSString *)nibNameOrNil bundle:(nullable NSBundle *)nibBundleOrNil NS_UNAVAILABLE;
- (instancetype)initWithCollectionViewLayout:(UICollectionViewLayout *)layout NS_UNAVAILABLE;
- (nonnull instancetype)init NS_DESIGNATED_INITIALIZER;

- (BOOL)selectConversation:(ZMConversation *)conversation scrollToMessage:(id<ZMConversationMessage>)message focusOnView:(BOOL)focus animated:(BOOL)animated;
- (BOOL)selectConversation:( ZMConversation * _Nonnull )conversation scrollToMessage:(id<ZMConversationMessage> _Nullable)message focusOnView:(BOOL)focus animated:(BOOL)animated completion:(dispatch_block_t _Nullable)completion;

- (void)deselectAll;

@end

NS_ASSUME_NONNULL_END
