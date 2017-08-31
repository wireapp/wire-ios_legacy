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


#import "NSURL+WireLocale.h"



NSString *const WireParameterKeyLocale = @"hl";

@implementation NSURL (WireLocale)

- (instancetype)wr_URLByAppendingLocaleParameter
{
    NSURLComponents *components = [[NSURLComponents alloc] initWithURL:self resolvingAgainstBaseURL:NO];
    
    NSLocale *locale = [NSLocale currentLocale];
    NSURLQueryItem *localeQueryItem = [[NSURLQueryItem alloc] initWithName:WireParameterKeyLocale value:[locale localeIdentifier]];
    
    NSMutableArray *newQueryItems = [[NSMutableArray alloc] initWithArray:components.queryItems];
    [newQueryItems addObject:localeQueryItem];
    
    components.queryItems = newQueryItems;
    return components.URL;
}

@end
