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


@import WireExtensionComponents;
@import Classy;

#import "InvitationStatusController.h"
#import "BarController.h"
#import "TitleBar.h"
#import "TitleBarViewController.h"
#import "WireSyncEngine+iOS.h"


@interface InvitationStatusController () <ZMInvitationStatusObserver>

@property (nonatomic, readonly) BarController *barController;

@end

@implementation InvitationStatusController

- (instancetype)initWithBarController:(BarController *)barController
{
    self = [self init];
    
    if (self) {
        _barController = barController;
        
        [ZMInvitationStatusChangedNotification addInvitationStatusObserver:self];
    }
    
    return self;
}

- (void)dealloc
{
    [ZMInvitationStatusChangedNotification removeInvitationStatusObserver:self];
}

#pragma mark - ZMInvitationStatusObserver

- (void)invitationStatusChanged:(ZMInvitationStatusChangedNotification *)note
{
    NSString *message = [self messageForStatus:note.newStatus];
    
    if (! message) {
        return;
    }
    
    TitleBarViewController *titleBarViewController = [[TitleBarViewController alloc] init];
    titleBarViewController.titleBar.titleLabel.text = [message transformStringWithTransform:TextTransformUpper];
    titleBarViewController.titleBar.cas_styleClass = @"invitation-status";
    [self.barController presentBar:titleBarViewController];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self.barController dismissBar:titleBarViewController];
    });
}

- (NSString *)messageForStatus:(ZMInvitationStatus)status
{
    switch (status) {
        case ZMInvitationStatusSent:
            return NSLocalizedString(@"contacts_ui.notification.invitation_sent", @"");
            break;
        case ZMInvitationStatusFailed:
            return NSLocalizedString(@"contacts_ui.notification.invitation_failed", @"");
            break;
        case ZMInvitationStatusPending:
        case ZMInvitationStatusNone:
        default:
            return nil;
            break;
    }
}

@end
