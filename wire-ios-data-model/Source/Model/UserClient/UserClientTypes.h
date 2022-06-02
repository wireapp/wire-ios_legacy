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

typedef NSString * ZMUserClientType NS_TYPED_EXTENSIBLE_ENUM NS_SWIFT_NAME(DeviceType);

extern ZMUserClientType const _Nonnull ZMUserClientTypePermanent;
extern ZMUserClientType const _Nonnull ZMUserClientTypeTemporary;
extern ZMUserClientType const _Nonnull ZMUserClientTypeLegalHold;

typedef NSString * ZMUserClientDeviceClass NS_TYPED_EXTENSIBLE_ENUM NS_SWIFT_NAME(DeviceClass);

extern ZMUserClientDeviceClass const _Nonnull ZMUserClientDeviceClassPhone;
extern ZMUserClientDeviceClass const _Nonnull ZMUserClientDeviceClassTablet;
extern ZMUserClientDeviceClass const _Nonnull ZMUserClientDeviceClassDesktop;
extern ZMUserClientDeviceClass const _Nonnull ZMUserClientDeviceClassLegalHold;