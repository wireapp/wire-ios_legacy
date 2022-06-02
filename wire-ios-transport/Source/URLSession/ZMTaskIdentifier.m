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


#import "ZMTaskIdentifier.h"


static NSString * const IdentifierKey = @"identifier";
static NSString * const SessionIdentifierKey = @"sessionIdentifier";


@interface ZMTaskIdentifier ()

@property (nonatomic, readwrite) NSUInteger identifier;
@property (nonatomic, readwrite) NSString *sessionIdentifier;

@end


@implementation ZMTaskIdentifier

+ (instancetype)identifierWithIdentifier:(NSUInteger)identifier sessionIdentifier:(NSString *)sessionIdentifier;
{
    return [[self alloc] initWithIdentifier:identifier sessionIdentifier:sessionIdentifier];
}

- (instancetype)initWithIdentifier:(NSUInteger)identifier sessionIdentifier:(NSString *)sessionIdentifier;
{
    self = [super init];
    if (self) {
        self.identifier = identifier;
        self.sessionIdentifier = sessionIdentifier;
    }
    return self;
}

+ (instancetype)identifierFromData:(NSData *)data
{
    if (nil == data) {
        return nil;
    }
    
    ZMTaskIdentifier *object = [NSKeyedUnarchiver unarchivedObjectOfClass:ZMTaskIdentifier.class fromData:data error:nil];
        
    return object;
}

+ (BOOL)supportsSecureCoding
{
    return YES;
}

- (NSData *)data
{
    return [NSKeyedArchiver archivedDataWithRootObject:self requiringSecureCoding:YES error:nil];
}

#pragma mark - Equality

- (BOOL)isEqual:(id)other
{
    if (! [other isKindOfClass:self.class]) {
        return NO;
    }
    ZMTaskIdentifier *otherIdentifier = (ZMTaskIdentifier *)other;
    return self.identifier == otherIdentifier.identifier &&
           [self.sessionIdentifier isEqualToString:otherIdentifier.sessionIdentifier];
}

#pragma mark - NSCoding

- (instancetype)initWithCoder:(NSCoder *)decoder {
    self = [super init];
    if (self) {
        self.identifier = [[decoder decodeObjectForKey:IdentifierKey] unsignedIntegerValue];
        self.sessionIdentifier = [decoder decodeObjectForKey:SessionIdentifierKey];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
    [coder encodeObject:@(self.identifier) forKey:IdentifierKey];
    [coder encodeObject:self.sessionIdentifier forKey:SessionIdentifierKey];
}

#pragma mark - Description

- (NSString *)description
{
    return [NSString stringWithFormat:@"<%@: %p> identifier: %lu, session identifier: %@",
            self.class, self, (unsigned long)self.identifier, self.sessionIdentifier];
}

@end
