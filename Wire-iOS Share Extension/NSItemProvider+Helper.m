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

#import "NSItemProvider+Helper.h"

@import MobileCoreServices;
@import UIKit;

@implementation NSItemProvider (Helper)

- (void)loadItemForTypeIdentifier:(NSString *)typeIdentifier options:(NSDictionary *)options dataCompletionHandler:(ItemProviderDataCompletionHandler)dataCompletionHandler
{
    [self loadItemForTypeIdentifier:typeIdentifier options:options completionHandler:^(NSData * _Nullable item, NSError * _Null_unspecified error) {
        dataCompletionHandler(item, error);
    }];
}

- (void)loadItemForTypeIdentifier:(NSString *)typeIdentifier options:(NSDictionary *)options imageCompletionHandler:(ItemProviderImageCompletionHandler)imageCompletionHandler
{
    [self loadItemForTypeIdentifier:typeIdentifier options:options completionHandler:^(UIImage *  _Nullable item, NSError * _Null_unspecified error) {
        imageCompletionHandler(item, error);
    }];
}

- (void)loadItemForTypeIdentifier:(NSString *)typeIdentifier options:(NSDictionary *)options URLCompletionHandler:(ItemProviderURLCompletionHandler)URLCompletionHandler
{
    [self loadItemForTypeIdentifier:typeIdentifier options:nil completionHandler:URLCompletionHandler];
}

@end
