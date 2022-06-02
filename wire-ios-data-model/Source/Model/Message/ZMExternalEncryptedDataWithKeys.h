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


@import WireProtos;
@class ZMUpdateEvent;

@interface ZMEncryptionKeyWithChecksum: NSObject

/// AES Key used for the symmetric encryption of the data
@property (nonatomic, readonly) NSData *aesKey;
/// SHA-256 digest
@property (nonatomic, readonly) NSData *sha256;

+ (ZMEncryptionKeyWithChecksum *)keyWithAES:(NSData *)aesKey digest:(NSData *)sha256;

@end


@interface ZMExternalEncryptedDataWithKeys : NSObject

/// The encrypted data
@property (nonatomic, readonly) NSData *data;
/// The AES Key used to encrypt @c data and the sha-256 digest of @c data
@property (nonatomic, readonly) ZMEncryptionKeyWithChecksum *keys;

+ (ZMExternalEncryptedDataWithKeys *)dataWithKeysWithData:(NSData *)data keys:(ZMEncryptionKeyWithChecksum *)keys;

@end
