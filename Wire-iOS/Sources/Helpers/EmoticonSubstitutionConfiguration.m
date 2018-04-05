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


#import "EmoticonSubstitutionConfiguration.h"

@import WireSystem;

static NSString* ZMLogTag ZM_UNUSED = @"UI";

@interface EmoticonSubstitutionConfiguration ()
@property (strong, nonatomic) NSArray *sortedShortcuts;
@property (strong, nonatomic) NSDictionary *substitutionRules;   // key is substitution string like ':)', value is smile string 😊
@end



@implementation EmoticonSubstitutionConfiguration

+ (instancetype)sharedInstance
{
    static id instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSString *filePath = [[NSBundle mainBundle] pathForResource:@"emoticons.min" ofType:@"json"];
        instance = [[self alloc] initWithConfigurationFile:filePath];
    });
    return instance;
}

- (instancetype)initWithConfigurationFile:(NSString *)filePath
{
    self = [super init];
    if (self) {
        NSError *error = nil;
        NSData *data = [NSData dataWithContentsOfFile:filePath options:0 error:&error];
        if (data == nil) {
            ZMLogError(@"Failed to load emoticon substitution rule at path: %@, error: %@", filePath, error);
            return nil;
        }
        
        NSDictionary *parsedJSONData = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
        if (parsedJSONData == nil) {
            ZMLogError(@"Failed to parse JSON at path: %@, error: %@", filePath, error);
            return nil;
        }
        
        NSMutableDictionary *rules = [@{} mutableCopy];
        if ([parsedJSONData isKindOfClass:[NSDictionary class]]) {
            [parsedJSONData enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSString *value, BOOL *stop) {
                NSString *prefixedValue = [NSString stringWithFormat:@"0x%@", value, nil];
                NSScanner *hexNumberScanner = [NSScanner scannerWithString:prefixedValue];
                uint32_t number = 0;
                if ([hexNumberScanner scanHexInt:&number]) {
                    number = CFSwapInt32HostToBig(number);
                    NSString *emo = [[NSString alloc] initWithBytes:&number length:sizeof(number) encoding:NSUTF32StringEncoding];
                    rules[key] = emo;
                }
            }];
        } else {
            ZMLogWarn(@"Failed to parse emoticon substitution rules, object: %@ is not an array", parsedJSONData);
        }
        self.substitutionRules = rules;
    }
    return self;
}

- (void)setSubstitutionRules:(NSDictionary *)substitutionRules
{
    _substitutionRules = substitutionRules;
    
    self.sortedShortcuts = [self.substitutionRules.allKeys sortedArrayUsingComparator:^NSComparisonResult(NSString *obj1, NSString *obj2) {
        if (obj1.length > obj2.length) {
            return NSOrderedAscending;
        } else if (obj1.length < obj2.length) {
            return NSOrderedDescending;
        } else {
            return NSOrderedSame;
        }
    }];
}

- (NSArray *)shortcuts
{
    // Sorting keys is important. Longer keys should be resolved first,
    // In order to make 'O:-)' to be resolved as '😇', not a 'O😊'.
    return self.sortedShortcuts;
}

- (NSString *)emoticonForShortcut:(NSString *)shortcut
{
    return self.substitutionRules[shortcut];
}

@end

