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


#import "UIAlertView+Zeta.h"
#import "Wire-Swift.h"



@implementation UIAlertView (Zeta)

+ (UIAlertView *)microphoneDisabledAlertViewWithDelegate:(id)delegate
{
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:[NSLocalizedString(@"call.microphone_warning.title", @"Mic disabled") uppercaseStringWithCurrentLocale] message:NSLocalizedString(@"call.microphone_warning.explanation", @"Enable Mic in Privacy settings") delegate:delegate cancelButtonTitle:@"OK" otherButtonTitles:nil];
    return alertView;
}

@end
