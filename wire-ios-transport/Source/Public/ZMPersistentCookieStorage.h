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


NS_ASSUME_NONNULL_BEGIN

/// This overrides the @c NSHTTPCookieStorage and adds convenience to check for the cookies relevant for our backend.
///
/// We will only store cookies relevant to our backend. They'll be persisted in the keychain.
@interface ZMPersistentCookieStorage : NSObject

+ (instancetype)storageForServerName:(NSString *)serverName userIdentifier:(NSUUID *)userIdentifier;

/// Looks up if there's any accessible authentication cookie data for any user
///
/// - Returns: True if it's possible acccess any authentication cookie data
+ (BOOL)hasAccessibleAuthenticationCookieData;

/// Delete all keychain items for for all servers and users
+ (void)deleteAllKeychainItems;

/// Delete all keychain items for current the user and server
- (void)deleteKeychainItems;
    
/// Date and time when the authentication cookie is no longer valid
@property (nonatomic, nullable) NSDate *authenticationCookieExpirationDate;

/// Authentication cookie available in the storage
@property (nonatomic, nullable) NSData *authenticationCookieData;

/// User identifier associated with the storage
@property (nonatomic, readonly) NSUUID *userIdentifier;

@end






@interface ZMPersistentCookieStorage (HTTPCookie)

//If you try tu set it to something different than NSHTTPCookieAcceptPolicyNever it will be set to NSHTTPCookieAcceptPolicyAlways
+ (void)setCookiesPolicy:(NSHTTPCookieAcceptPolicy)policy;
+ (NSHTTPCookieAcceptPolicy)cookiesPolicy;

- (void)setCookieDataFromResponse:(NSHTTPURLResponse *)response forURL:(NSURL *)URL;
- (void)setRequestHeaderFieldsOnRequest:(NSMutableURLRequest *)request;

@end


/// The @c ZMPersistentCookieStorageMigrator class should be used to migrate cookies from an
/// old legacy store to the multi account stores. Callers should use this class to create a cookie store
/// for the currently logged in user for the first time after upgrading. After the initial migration
/// callers should use the initializers of @c ZMPersistentCookieStorage directly.
/// The migrator will migrate the legacy data to the store with the identifier specified in @c init,
/// meaning callers need to ensure these to match (which will always be the case when called in a single account setup).
@interface ZMPersistentCookieStorageMigrator : NSObject

+ (instancetype)migratorWithUserIdentifier:(NSUUID *)userIdentifier serverName:(NSString *)serverName;
- (ZMPersistentCookieStorage *)createStoreMigratingLegacyStoreIfNeeded;

@end

NS_ASSUME_NONNULL_END
