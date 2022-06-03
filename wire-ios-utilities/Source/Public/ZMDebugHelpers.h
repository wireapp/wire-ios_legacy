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

// TODO move to ZMCSystem

@interface ZMQuickLookString : NSObject

- (void)appendHeader:(NSString *)text;
- (void)appendBodyText:(NSString *)text;
- (void)appendBodyTextWithFormat:(NSString *)format, ... NS_FORMAT_FUNCTION(1,2);
- (void)appendLabel:(NSString *)label text:(NSString *)text;
- (void)appendLabel:(NSString *)label textWithFormat:(NSString *)format, ... NS_FORMAT_FUNCTION(2,3);

@property (nonatomic, readonly) NSAttributedString *text;

@end
