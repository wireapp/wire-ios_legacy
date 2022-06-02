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


@import Foundation;

@class ZMManagedObject;
@class ZMLocallyModifiedObjectSyncStatusToken;



@interface ZMLocallyModifiedObjectSyncStatus : NSObject

@property (nonatomic, readonly) ZMManagedObject *object;
@property (nonatomic, readonly) NSSet *keysToSynchronize;
@property (nonatomic, readonly) BOOL isDone;

- (instancetype)initWithObject:(ZMManagedObject *)object trackedKeys:(NSSet *)trackedKeys;

- (ZMLocallyModifiedObjectSyncStatusToken *)startSynchronizingKeys:(NSSet *)keys;

/// Returns the keys that did change since the token was created
- (NSSet *)returnChangedKeysAndFinishTokenSync:(ZMLocallyModifiedObjectSyncStatusToken *)token;

- (void)resetLocallyModifiedKeysForToken:(ZMLocallyModifiedObjectSyncStatusToken *)token;

@end
