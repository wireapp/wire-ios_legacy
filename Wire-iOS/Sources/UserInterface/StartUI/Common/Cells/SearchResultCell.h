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
@import WireExtensionComponents;
#import "SwipeMenuCollectionCell.h"

@protocol ZMBareUser;
@protocol ZMSearchableUser;
@class ZMConversation, Team;

@interface SearchResultCell : SwipeMenuCollectionCell

@property (nonatomic) ColorSchemeVariant colorSchemeVariant;
@property (nonatomic, nullable) Team *team;
@property (nonatomic, nullable) id<ZMBareUser, ZMSearchableUser, AccentColorProvider> user;
@property (nonatomic, nullable) ZMConversation *conversation;
@property (nonatomic, copy, nullable)   NSString *displayName;
@property (nonatomic, copy, nullable)   void (^doubleTapAction)(SearchResultCell * _Nonnull);
@property (nonatomic, copy, nullable)   void (^instantConnectAction)(SearchResultCell * _Nonnull);

- (void)playAddUserAnimation;

@end
