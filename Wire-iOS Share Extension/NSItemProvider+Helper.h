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

@import UIKit;


typedef void (^ItemProviderDataCompletionHandler)(NSData * _Nullable data, NSError * _Nullable error);
typedef void (^ItemProviderImageCompletionHandler)(UIImage * _Nullable image, NSError * _Nullable error);
typedef void (^ItemProviderURLCompletionHandler)(NSURL * _Nullable url, NSError * _Nullable error);

@interface NSItemProvider (Helper)

- (void)loadItemForTypeIdentifier:(nonnull NSString *)typeIdentifier options:(nullable NSDictionary *)options dataCompletionHandler:(nonnull ItemProviderDataCompletionHandler)dataCompletionHandler;

- (void)loadItemForTypeIdentifier:(nonnull NSString *)typeIdentifier options:(nullable NSDictionary *)options imageCompletionHandler:(nonnull ItemProviderImageCompletionHandler)imageCompletionHandler;

- (void)loadItemForTypeIdentifier:(nonnull NSString *)typeIdentifier options:(nullable NSDictionary *)options URLCompletionHandler:(nonnull ItemProviderURLCompletionHandler)URLCompletionHandler;
@end
