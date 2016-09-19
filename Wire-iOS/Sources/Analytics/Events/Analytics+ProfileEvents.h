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
#import "AnalyticsBase.h"



typedef enum ResetPasswordType {
    ResetFromProfile,
    ResetFromSignIn
} ResetPasswordType;

typedef enum PictureUploadType {
    PictureUploadCamera,
    PictureUploadPhotoLibrary
} PictureUploadType;

typedef enum SoundIntensityType {
    SoundIntensityTypeAlways,
    SoundIntensityTypeFirstOnly,
    SoundIntensityTypeNever
} SoundIntensityType;

typedef enum TOSOpenedFromType {
    TOSOpenedFromTypeJoinPage,
    TOSOpenedFromTypeAboutPage
} TOSOpenedFromType;

NSString *PictureUploadTypeToString(PictureUploadType uploadType);


@interface Analytics (ProfileEvents)

- (void)tagResetPassword:(BOOL)reset fromType:(ResetPasswordType)type;
- (void)tagSoundIntensityPreference:(SoundIntensityType)type;
- (void)tagHelp;
- (void)tagProfilePictureFromSource:(PictureUploadType)type;
- (void)tagViewedTOSFromPage:(TOSOpenedFromType)type;
- (void)tagViewedPrivacyPolicy;
- (void)tagViewedLicenseInformation;
- (void)tagViewedFingerprintLearnMore;
- (void)tagSendInviteViaMethod:(NSString *)method;
- (void)tagSendInviteCanceled;

@end
