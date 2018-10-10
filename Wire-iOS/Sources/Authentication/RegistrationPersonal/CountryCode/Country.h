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



NS_ASSUME_NONNULL_BEGIN
@interface Country : NSObject

@property (nonatomic, copy) NSString *ISO;
@property (nonatomic, copy) NSNumber *e164;
@property (nonatomic, readonly) NSString *displayName;
@property (nonatomic, readonly) NSString *e164PrefixString;   // E.g. "+1", "+49", "+380"

@property (class, nonatomic, readonly) Country *defaultCountry NS_SWIFT_NAME(default);

+ (instancetype)countryWithISO:(NSString *)ISO e164:(NSNumber *)e164;
+ (nullable instancetype)countryFromDevice;

// Normalized phone number required: "1234567890" instead of "+1 (23) 456-78-90"
+ (nullable instancetype)detectCountryForPhoneNumber:(NSString *)phoneNumber;
+ (NSArray *)allCountries;

#if WIRESTAN
/// A fake country with +0 country code. Used only on edge and staging environments
+ (instancetype)countryWirestan;
#endif

@end



@interface NSString (PhoneNumber)

+ (NSString *)phoneNumberStringWithE164:(NSNumber *)e164 number:(NSString *)number;

@end

NS_ASSUME_NONNULL_END
