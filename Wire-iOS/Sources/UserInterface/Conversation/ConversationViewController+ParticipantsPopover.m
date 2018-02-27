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


#import "ConversationViewController+ParticipantsPopover.h"
#import "ProfileViewController.h"
#import "Wire-Swift.h"

@implementation ConversationViewController (ParticipantsPopover)

- (void)createAndPresentParticipantsPopoverControllerWithRect:(CGRect)rect fromView:(UIView *)view contentViewController:(UIViewController *)controller
{
    controller.modalPresentationStyle = UIModalPresentationPopover;

    UIPopoverPresentationController *popover = controller.popoverPresentationController;
    popover.delegate = self;
    popover.sourceRect = rect;
    popover.sourceView = view;
    popover.backgroundColor = UIColor.whiteColor;

    [self presentViewController:controller animated:YES completion:nil];
}

- (void)hideAndDestroyParticipantsPopoverController
{
    if ([self.presentedViewController isKindOfClass:[GroupDetailsViewController class]] ||
        [self.presentedViewController isKindOfClass:[ProfileViewController class]]) {
        [self dismissViewControllerAnimated:YES completion:nil];
    }
}

#pragma mark - UIPopoverPresentationControllerDelegate

- (UIModalPresentationStyle)adaptivePresentationStyleForPresentationController:(UIPresentationController *)controller
{
    if ([controller.presentedViewController isKindOfClass:AddParticipantsViewController.class]) {
        return UIModalPresentationOverFullScreen;
    }
    return UIModalPresentationFullScreen;
}

@end

