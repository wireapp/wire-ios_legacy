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


#import "UIAlertController+NewSelfClients.h"
#import "WireSyncEngine+iOS.h"
@import WireExtensionComponents;

@implementation UIAlertController (NewSelfClients)

+ (UIAlertController *)alertControllerForNewSelfClients:(NSSet<UserClient *> *)clients
{
    NSMutableArray *deviceNamesAndDates = [NSMutableArray array];
    
    for (UserClient *userClient in clients) {
        NSString *deviceName = nil;
        
        if (userClient.model.length > 0) {
            deviceName = userClient.model;
        } else {
            deviceName = userClient.type;
        }
        
        NSString *deviceDate = [userClient.activationDate wr_formattedDate];
        
        [deviceNamesAndDates addObject:[NSString stringWithFormat:@"%@\n%@", deviceName, deviceDate]];
    }
    
    NSString *titleDevices = nil;
    
    if (clients.count > 1) {
        titleDevices = [NSString stringWithFormat:NSLocalizedString(@"self.new_device_alert.title_prefix.devices", nil), clients.count];
    } else {
        NSString *deviceClass = clients.anyObject.deviceClass;
        
        if ([deviceClass isEqualToString:@"tablet"]) {
            titleDevices = NSLocalizedString(@"self.new_device_alert.title_prefix.tablet", nil);
        } else if ([deviceClass isEqualToString:@"phone"]) {
            titleDevices = NSLocalizedString(@"self.new_device_alert.title_prefix.phone", nil);
        } else {
            titleDevices = [NSString stringWithFormat:NSLocalizedString(@"self.new_device_alert.title_prefix.devices", nil), 1];
        }
    }
    
    NSString *title = [NSString stringWithFormat:NSLocalizedString(@"self.new_device_alert.title", nil), titleDevices];
    
    NSString *messageFormat = clients.count > 1 ? NSLocalizedString(@"self.new_device_alert.message_plural", nil) : NSLocalizedString(@"self.new_device_alert.message", nil);
    
    NSString *message = [NSString stringWithFormat:messageFormat, [deviceNamesAndDates componentsJoinedByString:@", "]];
    
    UIAlertController* newLoginAlertController = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];
    
    return newLoginAlertController;
}

@end
