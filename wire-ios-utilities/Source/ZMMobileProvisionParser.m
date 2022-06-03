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


#import "ZMMobileProvisionParser.h"

@import WireSystem;

static NSString * const WireTeamIdentifier = @"EDF3JCE8BC";
static NSString * const ZetaProjectEnterpriseIdentifier = @"W5KEQBF9B5";

@interface ZMMobileProvisionParser ()

@property (nonatomic) ZMProvisionTeam team;
@property (nonatomic) ZMAPSEnvironment APSEnvironment;

@end



@implementation ZMMobileProvisionParser

- (instancetype)init
{
    NSURL *fileURL = [[NSBundle mainBundle] URLForResource:@"embedded" withExtension:@"mobileprovision"];
    return [self initWithURL:fileURL];
}

- (instancetype)initWithURL:(NSURL *)fileURL;
{
    if (fileURL == nil) {
        return nil;
    }
    self = [super init];
    if (self) {
        NSData *data = [NSData dataWithContentsOfURL:fileURL options:NSDataReadingMappedIfSafe error:nil];
        if (data == nil) {
            return nil;
        }
        if (! [self parseData:data]) {
            return nil;
        }
    }
    return self;
}

- (BOOL)parseData:(NSData *)data;
{
    // This data is Abstract Syntax Notation One (ASN.1) <https://en.wikipedia.org/wiki/Abstract_Syntax_Notation_One>
    //
    // On OS X, you can parse such a file with
    // % security cms -D -i path/to/embedded.mobileprovision
    //
    // As a quick hack, we scan for "<?xml " and "</plist>". That works very well and is efficient.
    
    NSRange const startRange = [data rangeOfData:[NSData dataWithBytes:"<?xml " length:6] options:0 range:NSMakeRange(0, data.length)];
    if (startRange.location == NSNotFound) {
        return NO;
    }
    NSRange const endRange = [data rangeOfData:[NSData dataWithBytes:"</plist>" length:8] options:0 range:NSMakeRange(NSMaxRange(startRange), data.length - NSMaxRange(startRange))];
    if (endRange.location == NSNotFound) {
        return NO;
    }
    
    NSData *plistData = [data subdataWithRange:NSMakeRange(startRange.location, NSMaxRange(endRange) - startRange.location)];
    NSDictionary *plist = [NSPropertyListSerialization propertyListWithData:plistData options:0 format:NULL error:nil];
    if (! [plist isKindOfClass:NSDictionary.class]) {
        return NO;
    }
    
    NSArray *identifiers = plist[@"TeamIdentifier"];
    if ([identifiers isKindOfClass:NSArray.class]) {
        NSString *teamIdentifier = identifiers.firstObject;
        if ([WireTeamIdentifier isEqual:teamIdentifier]) {
            self.team = ZMProvisionTeamAppStore;
        } else if ([ZetaProjectEnterpriseIdentifier isEqual:teamIdentifier]) {
            self.team = ZMProvisionTeamEnterprise;
        } else {
            self.team = ZMProvisionTeamUnknown;
        }
    }
    
    NSDictionary *entitlements = plist[@"Entitlements"];
    if ([entitlements isKindOfClass:NSDictionary.class]) {
        NSString *environment = entitlements[@"aps-environment"];
        if ([@"production" isEqual:environment]) {
            self.APSEnvironment = ZMAPSEnvironmentProduction;
        } else if ([@"development" isEqual:environment]) {
                self.APSEnvironment = ZMAPSEnvironmentSandbox;
        } else {
            self.APSEnvironment = ZMAPSEnvironmentUnknown;
        }
    }
    
    return YES;
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"<%@: %p> Team \"%@\", %@",
            self.class, self,
            (self.team == ZMProvisionTeamAppStore) ? @"App Store" : ((self.team == ZMProvisionTeamEnterprise) ? @"Enterprise" : @"<unknown APNS>"),
            (self.APSEnvironment == ZMAPSEnvironmentProduction) ? @"Production APNS" : ((self.APSEnvironment == ZMAPSEnvironmentSandbox) ? @"Sandbox APNS" : @"<unknown APNS>")];
}

@end
