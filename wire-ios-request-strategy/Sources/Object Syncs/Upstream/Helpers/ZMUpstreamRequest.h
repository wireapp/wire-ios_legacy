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


@import WireTransport;


@interface ZMUpstreamRequest : NSObject

- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithKeys:(NSSet<NSString *> *)keys transportRequest:(ZMTransportRequest *)transportRequest;
- (instancetype)initWithKeys:(NSSet<NSString *> *)keys transportRequest:(ZMTransportRequest *)transportRequest userInfo:(NSDictionary *)info NS_DESIGNATED_INITIALIZER;
- (instancetype)initWithTransportRequest:(ZMTransportRequest *)transportRequest;


@property (nonatomic, readonly) NSSet<NSString *> *keys;
@property (nonatomic, readonly) ZMTransportRequest *transportRequest;
@property (nonatomic) ZMTransportResponse *transportResponse;
@property (nonatomic, readonly) NSDictionary *userInfo;

@end
