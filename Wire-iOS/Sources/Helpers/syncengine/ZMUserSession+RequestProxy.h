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


#import <Foundation/Foundation.h>

@import Ziphy;
@import WireSyncEngine;

@protocol ProxiedURLRequester <NSObject>
- (ZMProxyRequest  * _Nonnull)doRequestWithPath:(NSString * __nonnull)path
                                         method:(ZMTransportRequestMethod)method
                                           type:(ProxiedRequestType)type
                              completionHandler:(void (^ __nonnull)(NSData * __nullable, NSURLResponse * __nullable, NSError * __nullable))completionHandler;
@end



/// Extension for Ziphy and WireSyncEngine proxying of the request to the Wire backend
@interface ZMUserSession (RequestProxy) <ProxiedURLRequester, ZiphyURLRequester>

@end
