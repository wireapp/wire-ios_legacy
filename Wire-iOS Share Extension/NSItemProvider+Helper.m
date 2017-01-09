//
//  NSItemProvider+Helper.m
//  Wire-iOS
//
//  Created by Jacob on 11/11/16.
//  Copyright © 2016 Zeta Project Germany GmbH. All rights reserved.
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
