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


@import UIKit;



@interface UIColor (Mixing)

// Pass in amount of 0 for self, 1 is the other color
- (UIColor *)mix:(UIColor *)color amount:(double)amount;

- (UIColor *)removeAlphaByBlendingWithColor:(UIColor *)color;

+ (UIColor *)wr_colorFromString:(NSString *)string;

@end
