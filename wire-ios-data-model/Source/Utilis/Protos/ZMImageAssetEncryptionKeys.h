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
@import WireImages;
@import WireProtos;

@class ZMIImageProperties;
@class ZMConversation;


@interface ZMImageAssetEncryptionKeys: NSObject

/// Key used for symmetric encryption of the asset
@property (nonatomic, copy, readonly, nonnull) NSData *otrKey;
/// HMAC key used to compute the digest
@property (nonatomic, copy, readonly, nullable) NSData *macKey;
/// HMAC digest
@property (nonatomic, copy, readonly, nullable) NSData *mac;
/// SHA-256 digest
@property (nonatomic, copy, readonly, nullable) NSData *sha256;
/// Wether it has a HMAC digest
@property (nonatomic, readonly) BOOL hasHMACDigest;
/// Wether it has a SHA256 digest
@property (nonatomic, readonly) BOOL hasSHA256Digest;


- (nonnull instancetype)initWithOtrKey:(nonnull NSData *)otrKey macKey:(nonnull NSData *)macKey mac:(nonnull NSData *)mac;
- (nonnull instancetype)initWithOtrKey:(nonnull NSData *)otrKey sha256:(nonnull NSData *)sha256;

@end
