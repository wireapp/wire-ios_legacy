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

NS_ASSUME_NONNULL_BEGIN

@interface NSURL (WireURLs)

+ (instancetype)wr_fingerprintLearnMoreURL;

+ (instancetype)wr_fingerprintHowToVerifyURL;

+ (instancetype)wr_termsOfServicesURL;

+ (instancetype)wr_privacyPolicyURL;

+ (instancetype)wr_licenseInformationURL;

+ (instancetype)wr_websiteURL;

+ (instancetype)wr_passwordResetURL;

+ (instancetype)wr_supportURL;

+ (instancetype)wr_askSupportURL;

+ (instancetype)wr_reportAbuseURL;

+ (instancetype)wr_cannotDecryptHelpURL;

+ (instancetype)wr_cannotDecryptNewRemoteIDHelpURL;

+ (instancetype)wr_unknownMessageHelpURL;

+ (instancetype)wr_createTeamURL;

+ (instancetype)wr_createTeamFeaturesURL;

+ (instancetype)wr_manageTeamURL;

+ (instancetype)wr_emailInUseLearnMoreURL;

@end

NS_ASSUME_NONNULL_END
