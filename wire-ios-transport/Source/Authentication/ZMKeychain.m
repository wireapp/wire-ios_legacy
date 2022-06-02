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


@import Security;
@import WireSystem;
@import WireUtilities;

#import "ZMKeychain.h"

static char* const ZMLogTag ZM_UNUSED = "Keychain";


static BOOL isRunningTests(void)
{
    static BOOL flag;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        flag = (NSClassFromString(@"XCTestCase") != nil);
    });
    return flag;
}

extern NSString *ZMKeychainErrorDescription(OSStatus s);
extern NSString *ZMKeychainErrorDescription(OSStatus s)
{
#if TARGET_OS_IPHONE
    return [NSString stringWithFormat:@"(%d)", (int) s];
#else
    return [NSString stringWithFormat:@"%@ (%d)", CFBridgingRelease(SecCopyErrorMessageString(s, NULL)), s];
#endif
}

@implementation ZMKeychain

#pragma mark - Constants

+ (NSData *)keychainGenericData;
{
    if (isRunningTests()) {
        return [NSData dataWithBytes:"Zeta" length:4];
    } else {
        return [NSData dataWithBytes:"ZetT" length:4];
    }
}

+ (NSString *)keychainServiceName;
{
    return @"Wire: Credentials for wire.com";
}

#pragma mark - Public API

+ (NSData *)dataForAccount:(NSString *)accountName
{
    return [self dataForAccount:accountName fallbackToDefaultGroup:NO];
}

+ (NSData *)dataForAccount:(NSString *)accountName fallbackToDefaultGroup:(BOOL)fallback
{
    return [self valueForAccount:accountName inGroup:[self defaultAccessGroup] returnData:YES fallbackToDefaultGroup:fallback];
}

+ (NSString *)stringForAccount:(NSString *)accountName
{
    return [self stringForAccount:accountName fallbackToDefaultGroup:NO];
}

+ (NSString *)stringForAccount:(NSString *)accountName fallbackToDefaultGroup:(BOOL)fallback
{
    return [self valueForAccount:accountName inGroup:[self defaultAccessGroup] returnData:NO fallbackToDefaultGroup:fallback];
}

+ (BOOL)setData:(NSData *)data forAccount:(NSString *)accountName
{
    if ([self dataForAccount:accountName] != nil) {
        NSMutableDictionary *query = [self fetchQueryForAccountName:accountName];
        if ([self defaultAccessGroup] != nil) {
            query[(__bridge id) kSecAttrAccessGroup] = [self defaultAccessGroup];
        }
        
        NSMutableDictionary *update = [NSMutableDictionary dictionary];
        update[(__bridge id) kSecValueData] = data;
        
        OSStatus s = SecItemUpdate((__bridge CFDictionaryRef) query, (__bridge CFDictionaryRef) update);
        if ((s != errSecSuccess) && (s != errSecItemNotFound)) {
            ZMLogError(@"SecItemUpdate() failed: %@", ZMKeychainErrorDescription(s));
        }
        return (errSecSuccess == s);
    }
    else {
        NSMutableDictionary *query = [self fetchQueryForAccountName:accountName];
        query[(__bridge id) kSecValueData] = data;
        query[(__bridge id) kSecAttrAccessible] = (__bridge id) kSecAttrAccessibleAfterFirstUnlock;
        
        if ([self defaultAccessGroup] != nil) {
            query[(__bridge id) kSecAttrAccessGroup] = [self defaultAccessGroup];
        }
        
        OSStatus const s = SecItemAdd((__bridge CFDictionaryRef) query, NULL);
        if (s != errSecSuccess) {
            ZMLogError(@"SecItemAdd() failed: %@", ZMKeychainErrorDescription(s));
        }
        return (errSecSuccess == s);
    }
}

+ (void)deleteAllKeychainItemsWithAccountName:(NSString *)accountName
{
    NSString *accessGroup = [self defaultAccessGroup];
    if (accessGroup != nil) {
        [self deleteAllKeychainItemsInGroups: @[accessGroup] withAccountName:accountName];
    }
    else {
        [self deleteAllKeychainItemsInGroups:nil withAccountName:accountName];
    }
}

+ (NSString *)defaultAccessGroup
{
#if TARGET_OS_IPHONE && !TARGET_IPHONE_SIMULATOR
    NSDictionary *infoDict = [[NSBundle mainBundle] infoDictionary];
    //When client will enable access groups they should add this key in Info.plist
    if (infoDict[@"AppIdentifierPrefix"] != nil) {
        return [NSString stringWithFormat:@"%@%@", infoDict[@"AppIdentifierPrefix"], infoDict[@"WireGroupId"]];
    }
#endif
    return nil;
}

#pragma mark - Fetch query

+ (NSMutableDictionary *)fetchQuery
{
    NSMutableDictionary *query = [[NSMutableDictionary alloc] init];
    query[(__bridge id) kSecClass] = (__bridge id) kSecClassGenericPassword;
    query[(__bridge id) kSecAttrService] = self.keychainServiceName;
    
    // looks like we still need it no OSX, at least to pass tests
    // on iOS this does not work well with access groups
#if !TARGET_OS_IPHONE
    query[(__bridge id) kSecAttrGeneric] = self.keychainGenericData;
#endif
    
    return query;
}

+ (NSMutableDictionary *)fetchQueryForAccountName:(NSString *)accountName
{
    NSMutableDictionary *query = [self fetchQuery];
    query[(__bridge id) kSecAttrAccount] = accountName;

    return query;
}

#pragma mark - Lookup

+ (BOOL)hasAccessibleAccountData
{
    NSMutableDictionary *query = [self fetchQuery];
    query[(__bridge id) kSecReturnData] = @(NO);
    NSString *group = [self defaultAccessGroup];
    
    if (group != nil) {
        query[(__bridge id) kSecAttrAccessGroup] = group;
    }
    
    OSStatus const s = SecItemCopyMatching((__bridge CFDictionaryRef) query, NULL);
    return errSecSuccess == s;
}

+ (id)valueForAccount:(NSString *)accountName
              inGroup:(NSString *)group
           returnData:(BOOL)returnData
{
    NSMutableDictionary *query = [self fetchQueryForAccountName:accountName];
    query[(__bridge id) kSecReturnData] = @(returnData);
    
    if (group != nil) {
        query[(__bridge id) kSecAttrAccessGroup] = group;
    }
    
    CFTypeRef cfResult = NULL;
    OSStatus const s = SecItemCopyMatching((__bridge CFDictionaryRef) query, &cfResult);
    BOOL success = errSecSuccess == s;
    if (!success) {
        if (errSecItemNotFound != s) {
            ZMLogError(@"SecItemCopyMatching() failed: %@", ZMKeychainErrorDescription(s));
        }
        return nil;
    }
    else {
        id result = CFBridgingRelease(cfResult);
        return result;
    }
}

+ (id)valueForAccount:(NSString *)accountName
              inGroup:(NSString *)group
           returnData:(BOOL)returnData
fallbackToDefaultGroup:(BOOL)fallback
{
    id result = [self valueForAccount:accountName inGroup:group returnData:returnData];
    
    if (fallback && result == nil) {
        result = [self valueForAccount:accountName inGroup:nil returnData:returnData];
        if (result != nil) {
            // The value is present in default keychain group, but not in the shared one => it should be migrated to the
            // shared keychain.
            if ([result isKindOfClass:[NSData class]]) {
                [self setData:result forAccount:accountName];
            }
        }
    }
    
    return result;
}

#pragma mark - Removing items

+ (BOOL)deleteKeychainReference:(id)reference
{
    VerifyReturnValue(reference != nil, NO);
#if ! TARGET_OS_IPHONE
    OSStatus const status = SecKeychainItemDelete((__bridge SecKeychainItemRef)reference);
    if ((status != noErr) && (status != errSecItemNotFound)) {
        ZMLogError(@"Keychain delete failed: %ld", (unsigned long) status);
        return NO;
    }
#else
    NOT_USED(reference);
    Require(NO); // Should only be used on OS X
    return NO;
#endif
    return YES;
}

+ (BOOL)deleteKeychainPersistentReference:(NSData *)persistentReference
{
    VerifyReturnValue(persistentReference != nil, NO);
#if TARGET_OS_IPHONE
    NSDictionary *deleteAttributes = @{(__bridge id) kSecValuePersistentRef: persistentReference};
    
    OSStatus const status = SecItemDelete((__bridge CFDictionaryRef) deleteAttributes);
    if ((status != noErr) && (status != errSecItemNotFound)) {
        ZMLogError(@"Keychain delete failed: %ld", (unsigned long) status);
        return NO;
    }
#else
    NOT_USED(persistentReference);
    Require(NO); // Should only be used on iOS
    return NO;
#endif
    return YES;
}

+ (void)deleteAllKeychainItemsInGroups:(NSArray *)accessGroups withAccountName:(NSString *)accountName
{
    for (NSString *accessGroup in accessGroups) {
        [self deleteAllKeychainItemsInGroup:accessGroup withAccountName:accountName];
    }
    [self deleteAllKeychainItemsInGroup:nil withAccountName:accountName];
}

+ (void)deleteAllKeychainItems
{
    [self deleteAllKeychainItemsInGroup:[self defaultAccessGroup] withAccountName:nil];
}

+ (void)deleteAllKeychainItemsInGroup:(NSString *)accessGroup withAccountName:(NSString *)accountName
{
    NSMutableDictionary *query;
    if (accountName.length != 0) {
        query = [self fetchQueryForAccountName:accountName];
    } else {
        query = [self fetchQuery];
    }
    
    query[(__bridge id) kSecMatchLimit] = (__bridge id) kSecMatchLimitAll;
    
#if TARGET_OS_IPHONE
    query[(__bridge id) kSecReturnPersistentRef] = @YES;
#else
    query[(__bridge id) kSecReturnRef] = @YES;
#endif
    if (accessGroup != nil) {
        query[(__bridge id) kSecAttrAccessGroup] = accessGroup;
    }
    
    CFTypeRef resultRef = NULL;
    OSStatus const status = SecItemCopyMatching((__bridge CFDictionaryRef)query, &resultRef);
    if (status != noErr || resultRef == NULL) {
        // The entry doesnt exists, nothing to delete here
        return;
    }
    
    id result = CFBridgingRelease(resultRef);
    
    if ([result isKindOfClass:[NSArray class]]) {
        for (id item in result) {
            if ([item isKindOfClass:[NSData class]]) {
                [self deleteKeychainPersistentReference:item];
            } else {
                [self deleteKeychainReference:item];
            }
        }
    } else if ([result isKindOfClass:[NSData class]]) {
        [self deleteKeychainPersistentReference:result];
    } else {
        [self deleteKeychainReference:result];
    }
}


@end
