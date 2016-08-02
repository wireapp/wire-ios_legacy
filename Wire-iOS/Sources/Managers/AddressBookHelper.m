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


#import "AddressBookHelper.h"
#import "zmessaging+iOS.h"

@import AddressBook;

static NSTimeInterval const AddressBookHelperReUploadTimeInterval = 60 * 60 * 24; // 24h

static NSString * const UserDefaultsKeyAddressBookExportDate = @"UserDefaultsKeyAddressBookExportDate";


@interface AddressBookHelper ()

@property (nonatomic) dispatch_queue_t adressBookIsolationQueue;

@end


@implementation AddressBookHelper

- (instancetype)init
{
    self = [super init];
    
    if (self != nil) {
        self.adressBookIsolationQueue = dispatch_queue_create("AddressBookHelper", DISPATCH_QUEUE_SERIAL);
    }
    
    return self;
}

+ (instancetype)sharedHelper
{
    static AddressBookHelper *helper = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        helper = [self.class new];
    });
    return helper;
}

- (BOOL)isAddressBookSupported
{
    return &ABAddressBookCreateWithOptions != NULL;
}

- (BOOL)isAddressBookAccessUnknown
{
    return [self isAddressBookSupported] && ABAddressBookGetAuthorizationStatus() == kABAuthorizationStatusNotDetermined;
}

- (BOOL)isAddressBookAccessGranted
{
    return [self isAddressBookSupported] && ABAddressBookGetAuthorizationStatus() == kABAuthorizationStatusAuthorized;
}

- (BOOL)isAddressBookAccessDisabled
{
    return [self isAddressBookSupported] && ABAddressBookGetAuthorizationStatus() == kABAuthorizationStatusDenied;
}

- (void)uploadAddressBook
{
    if (! [self addressBookUploadIsAllowed]) {
        return;
    }
    [self internalUploadAddressBook];
}

- (void)forceUploadAddressBook
{
    [self internalUploadAddressBook];
}

- (BOOL)addressBookUploadIsAllowed
{
    NSDate *lastUpdateDate = [[NSUserDefaults standardUserDefaults] objectForKey:UserDefaultsKeyAddressBookExportDate];
    if (! lastUpdateDate) {
        return YES;
    }
    // Date check
    NSTimeInterval timeIntervalSinceDate = [[NSDate date] timeIntervalSinceDate:lastUpdateDate];
    if (timeIntervalSinceDate > AddressBookHelperReUploadTimeInterval) {
        return YES;
    }
    return NO;
}

- (void)internalUploadAddressBook
{
    self.addressBookUploadWasPostponed = NO;
    self.addressBookWasUploaded = YES;
#if !TARGET_IPHONE_SIMULATOR
    [[ZMUserSession sharedSession] uploadAddressBook];
#endif
    [[NSUserDefaults standardUserDefaults] setObject:[NSDate date] forKey:UserDefaultsKeyAddressBookExportDate];
}

- (void)setAddressBookWasUploaded:(BOOL)addressBookWasUploaded
{
    [[NSUserDefaults standardUserDefaults] setBool:addressBookWasUploaded forKey:@"AddressBookWasUploaded"];
}

- (BOOL)addressBookWasUploaded
{
    return [[NSUserDefaults standardUserDefaults] boolForKey:@"AddressBookWasUploaded"];
}

- (void)setAddressBookUploadWasPostponed:(BOOL)addressBookUploadWasPostponed
{
    [[NSUserDefaults standardUserDefaults] setBool:addressBookUploadWasPostponed forKey:@"AddressBookUploadWasPosponed"];
}

- (BOOL)addressBookUploadWasPostponed
{
    return [[NSUserDefaults standardUserDefaults] boolForKey:@"AddressBookUploadWasPosponed"];
}

- (void)setAddressBookUploadWasProposed:(BOOL)addressBookUploadWasProposed
{
    [[NSUserDefaults standardUserDefaults] setBool:addressBookUploadWasProposed forKey:@"AddressBookUploadWasProposed"];
}

- (BOOL)addressBookUploadWasProposed
{
    return [[NSUserDefaults standardUserDefaults] boolForKey:@"AddressBookUploadWasProposed"];
}

- (void)requestPermissions:(void (^)(BOOL))callback
{
    if (! self.isAddressBookSupported) {
        if (callback != nil) {
            callback(NO);
        }
        return;
    }
    
    dispatch_async(self.adressBookIsolationQueue, ^{
        ABAddressBookRef addressBookRef = ABAddressBookCreateWithOptions(NULL, NULL);
        
        if (addressBookRef == NULL) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (callback != nil) {
                    callback(NO);
                }
            });
        } else {
            ABAddressBookRequestAccessWithCompletion(addressBookRef, ^(bool granted, CFErrorRef error) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (callback != nil) {
                        callback(granted);
                    }
                });
            });
            
            CFRelease(addressBookRef);
        }
    });
}

@end
