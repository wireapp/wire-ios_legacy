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


#import "ZMAddressBookContact.h"
#import "ZMUser.h"

@implementation ZMAddressBookContact

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.emailAddresses = @[];
        self.phoneNumbers = @[];
    }
    return self;
}

- (NSString *)name
{
    NSMutableArray *names = [NSMutableArray array];
    
    if (self.firstName.length > 0) {
        [names addObject:self.firstName];
    }
    
    if (self.middleName.length > 0) {
        [names addObject:self.middleName];
    }
    
    if (self.lastName.length > 0) {
        [names addObject:self.lastName];
    }
    
    if (names.count > 0) {
        return [names componentsJoinedByString:@" "];
    } else if (self.organization) {
        return self.organization;
    } else if (self.nickname) {
        return self.nickname;
    } else if (self.emailAddresses.count > 0) {
        return self.emailAddresses.firstObject;
    } else if (self.phoneNumbers.count > 0) {
        return self.phoneNumbers.firstObject;
    }
    return @"";
}

- (NSString *)description;
{
    return [NSString stringWithFormat:@"<%@: %p> email: {%@}, phone: {%@}",
            self.class, self,
            [self.emailAddresses componentsJoinedByString:@"; "],
            [self.phoneNumbers componentsJoinedByString:@"; "]];
}

- (NSArray *)contactDetails
{
    NSMutableArray *details = [NSMutableArray array];
    [details addObjectsFromArray:self.emailAddresses];
    [details addObjectsFromArray:self.phoneNumbers];
    return details;
}

- (BOOL)isEqual:(id)object
{
    if(![object isKindOfClass:ZMAddressBookContact.class]) {
        return false;
    }
    return [self isEqualToAddressBookContact:object];
}

- (BOOL)isEqualToAddressBookContact:(ZMAddressBookContact *)addressBookContact {
    return [self.emailAddresses isEqualToArray:addressBookContact.emailAddresses]
    && [self.phoneNumbers isEqualToArray:addressBookContact.phoneNumbers]
    && [self.name isEqualToString:addressBookContact.name];
}

- (NSUInteger)hash {
    return self.emailAddresses.hash ^ self.phoneNumbers.hash ^ self.name.hash;
}

@end
