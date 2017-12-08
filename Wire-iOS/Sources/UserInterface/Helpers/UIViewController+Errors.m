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


#import "UIViewController+Errors.h"
#import "WireSyncEngine+iOS.h"

@implementation UIViewController (Errors)

- (void)showAlertForError:(NSError *)error
{
    [self showAlertForError:error handler:nil];
}

- (void)showAlertForError:(NSError *)error handler:(void(^)(UIAlertAction *action))handler
{
    NSString *message = @"";
    NSString *title = @"";
    
    if ([error.domain isEqualToString:ZMObjectValidationErrorDomain]) {
        switch (error.code) {
            case ZMObjectValidationErrorCodeStringTooLong:
                message = NSLocalizedString(@"error.input.too_long", @"");
                break;
            case ZMObjectValidationErrorCodeStringTooShort:
                message = NSLocalizedString(@"error.input.too_short", @"");
                break;
            case ZMObjectValidationErrorCodeEmailAddressIsInvalid:
                message = NSLocalizedString(@"error.email.invalid", @"");
                break;
            case ZMObjectValidationErrorCodePhoneNumberContainsInvalidCharacters:
                message = NSLocalizedString(@"error.phone.invalid", @"");
                break;
        }
    }
    else if ([error.domain isEqualToString:NSError.ZMUserSessionErrorDomain]) {
        switch (error.code) {
            case ZMUserSessionNoError:
                message = @"";
                break;
                
            case ZMUserSessionNeedsCredentials:
                message = NSLocalizedString(@"error.user.needs_credentials", @"");
                break;
                
            case ZMUserSessionInvalidCredentials:
                message = NSLocalizedString(@"error.user.invalid_credentials", @"");
                break;
                
            case ZMUserSessionAccountIsPendingActivation:
                message = NSLocalizedString(@"error.user.account_pending_activation", @"");
                break;
                
            case ZMUserSessionNetworkError:
                message = NSLocalizedString(@"error.user.network_error", @"");
                break;
                
            case ZMUserSessionEmailIsAlreadyRegistered:
                message = NSLocalizedString(@"error.user.email_is_taken", @"");
                break;
                
            case ZMUserSessionPhoneNumberIsAlreadyRegistered:
                message = NSLocalizedString(@"error.user.phone_is_taken", @"");
                break;
                
            case ZMUserSessionInvalidPhoneNumberVerificationCode:
                message = NSLocalizedString(@"error.user.phone_code_invalid", @"");
                break;
                
            case ZMUserSessionRegistrationDidFailWithUnknownError:
                message = NSLocalizedString(@"error.user.registration_unknown_error", @"");
                break;
                
            case ZMUserSessionInvalidPhoneNumber:
                message = NSLocalizedString(@"error.phone.invalid", @"");
                break;
                
            case ZMUserSessionInvalidEmail:
                message = NSLocalizedString(@"error.email.invalid", @"");
                break;
            case ZMUserSessionCodeRequestIsAlreadyPending:
                message = NSLocalizedString(@"error.user.phone_code_too_many", @"");
                break;
            case ZMUserSessionClientDeletedRemotely:
                message = NSLocalizedString(@"error.user.device_deleted_remotely", @"");
                break;
            case ZMUserSessionLastUserIdentityCantBeDeleted:
                message = NSLocalizedString(@"error.user.last_identity_cant_be_deleted", @"");
                break;
            case ZMUserSessionAccountSuspended:
                message = NSLocalizedString(@"error.user.account_suspended", @"");
                break;
            case ZMUserSessionAccountLimitReached:
                message = NSLocalizedString(@"error.user.account_limit_reached", @"");
                break;
                
            default:
            case ZMUserSessionUnknownError:
                message = NSLocalizedString(@"error.user.unkown_error", @"");
                break;
        }
    } 
    else {
        message = error.localizedDescription;
    }

    [self showAlertForMessage:message title:title handler:handler];
}

- (void)showAlertForMessage:(NSString *)message
{
    [self showAlertForMessage:message title:@"" handler:nil];
}

- (void)showAlertForMessage:(NSString *)message title:(NSString *)title handler:(void(^)(UIAlertAction *action))handler
{
    UIAlertController *controller = [UIAlertController alertControllerWithTitle:title
                                                                        message:message
                                                                 preferredStyle:UIAlertControllerStyleAlert];
    [controller addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"general.ok", @"")
                                                   style:UIAlertActionStyleCancel
                                                 handler:handler]];
    
    [self presentViewController:controller animated:YES completion:nil];
}

@end
