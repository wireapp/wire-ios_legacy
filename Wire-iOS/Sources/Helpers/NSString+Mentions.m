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


#import "NSString+Mentions.h"
#import "WireSyncEngine+iOS.h"


static NSRegularExpression *mentionMatcher;

@implementation NSString (Mentions)

+ (NSRegularExpression *)mentionMatcher
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        
        mentionMatcher = [NSRegularExpression regularExpressionWithPattern:@"\\B@\\w+(\\B)?" options:NSRegularExpressionCaseInsensitive error:nil];
    });
    
    return mentionMatcher;
}

- (NSArray *)mentions
{
    NSArray *matchets = [[NSString mentionMatcher] matchesInString:self options:0 range:NSMakeRange(0, self.length)];
    
    return matchets;
}

- (NSArray *)usersMatchingMentions:(NSArray *)users strict:(BOOL)strict
{
    
    NSMutableArray *mentions = [NSMutableArray array];
    
    for (NSTextCheckingResult *result in  self.mentions) {
        
        NSString *substringFromMatch = [self substringWithRange:result.range];
        [mentions addObject:substringFromMatch];
    }
    
    NSMutableArray *usersToPing = [NSMutableArray array];
    
    [users enumerateObjectsUsingBlock:^(id participant, NSUInteger idx, BOOL *stop) {
        
        [mentions enumerateObjectsUsingBlock:^(id mention, NSUInteger idx, BOOL *stop) {
            
            NSString *mentionString = mention;
            ZMUser *user = (ZMUser *) participant;
            NSString *nameToCompareTo = [[mentionString stringByReplacingOccurrencesOfString:@"@" withString:@""] lowercaseString];
            NSString *userName = [[user.displayName stringByReplacingOccurrencesOfString:@" " withString:@""] lowercaseString];
            
            if (strict) {
                
                if ([userName isEqualToString:nameToCompareTo]) {
                    
                    [usersToPing addObject:user];
                    *stop = YES;
                }
                
            }
            else {
                
                if ([userName hasPrefix:nameToCompareTo]) {
                    
                    [usersToPing addObject:user];
                    *stop = YES;
                }
            }
        }];
    }];
    
    return usersToPing;
}

- (NSArray *)usersMatchingLastMention:(NSArray *)users
{
    NSMutableArray *partialMatches = [NSMutableArray array];
        
    NSTextCheckingResult *lastMatch = self.mentions.lastObject;
    
    if (lastMatch.range.location+lastMatch.range.length != self.length) {
        
        return [NSArray array];
    }
    
    NSString *substringFromMatch = [[self substringWithRange:lastMatch.range] lowercaseString];
    NSString *nameToCompareTo = [[substringFromMatch stringByReplacingOccurrencesOfString:@"@" withString:@""] lowercaseString];
    
    
    [users enumerateObjectsUsingBlock:^(id participant, NSUInteger idx, BOOL *stop) {
        
        ZMUser *user = (ZMUser *) participant;
        
        NSString *userName = [[user.displayName stringByReplacingOccurrencesOfString:@" " withString:@""] lowercaseString];
        
        if ([userName hasPrefix:nameToCompareTo]) {
            
            if (! [userName isEqualToString:nameToCompareTo]) {
                
                [partialMatches addObject:user];
            }
        }
    }];
    
    return partialMatches;
}

@end
