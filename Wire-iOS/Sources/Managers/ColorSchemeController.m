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


#import "ColorSchemeController.h"
#import "ColorScheme.h"
#import "Settings.h"
#import "WireSyncEngine+iOS.h"
#import "CASStyler+Variables.h"
#import "UIColor+WAZExtensions.h"
#import "Message+Formatting.h"


NSString * const ColorSchemeControllerDidApplyColorSchemeChangeNotification = @"ColorSchemeControllerDidApplyColorSchemeChangeNotification";



@interface ColorSchemeController () <ZMUserObserver>

@property (nonatomic) id userObserverToken;

@end

@implementation ColorSchemeController


#pragma mark - SettingsColorSchemeDidChangeNotification

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (instancetype)init
{
    self = [super init];
    
    if (self) {
        self.userObserverToken = [UserChangeInfo addUserObserver:self forUser:[ZMUser selfUser]];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(settingsColorSchemeDidChange:) name:SettingsColorSchemeChangedNotification object:nil];
    }
    
    return self;
}

- (void)notifyColorSchemeChange
{
    [[NSNotificationCenter defaultCenter] postNotificationName:ColorSchemeControllerDidApplyColorSchemeChangeNotification object:self];
}

#pragma mark - ZMUserObserver

- (void)userDidChange:(UserChangeInfo *)note
{
    if (! note.accentColorValueChanged) {
        return;
    }
    ColorScheme *colorScheme = [ColorScheme defaultColorScheme];
    UIColor *newAccentColor = [UIColor accentColor];
    if (![colorScheme.accentColor isEqual:newAccentColor]) {
        [[CASStyler defaultStyler] applyDefaultColorSchemeWithAccentColor:newAccentColor];
        [self notifyColorSchemeChange];
    }
}

#pragma mark - SettingsColorSchemeDidChangeNotification

- (void)settingsColorSchemeDidChange:(NSNotification *)notification
{
    [Message invalidateMarkdownStyle];
    [[CASStyler defaultStyler] applyDefaultColorSchemeWithVariant:(ColorSchemeVariant)[[Settings sharedSettings] colorScheme]];
    [self notifyColorSchemeChange];
}

@end
