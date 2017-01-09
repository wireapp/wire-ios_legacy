//
//  NSItemProvider+Helper.h
//  Wire-iOS
//
//  Created by Jacob on 11/11/16.
//  Copyright © 2016 Zeta Project Germany GmbH. All rights reserved.
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
