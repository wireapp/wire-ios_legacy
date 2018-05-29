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

+ (instancetype)wr_fingerprintLearnMoreURL NS_REFINED_FOR_SWIFT;

+ (instancetype)wr_fingerprintHowToVerifyURL NS_REFINED_FOR_SWIFT;

+ (instancetype)wr_termsOfServicesURLForTeamAccount:(BOOL)teamAccount NS_REFINED_FOR_SWIFT;

+ (instancetype)wr_privacyPolicyURL NS_REFINED_FOR_SWIFT;

+ (instancetype)wr_licenseInformationURL NS_REFINED_FOR_SWIFT;

+ (instancetype)wr_websiteURL NS_REFINED_FOR_SWIFT;

+ (instancetype)wr_passwordResetURL NS_REFINED_FOR_SWIFT;

+ (instancetype)wr_supportURL NS_REFINED_FOR_SWIFT;

+ (instancetype)wr_askSupportURL NS_REFINED_FOR_SWIFT;

+ (instancetype)wr_reportAbuseURL NS_REFINED_FOR_SWIFT;

+ (instancetype)wr_cannotDecryptHelpURL NS_REFINED_FOR_SWIFT;

+ (instancetype)wr_cannotDecryptNewRemoteIDHelpURL NS_REFINED_FOR_SWIFT;

+ (instancetype)wr_createTeamURL NS_REFINED_FOR_SWIFT;

+ (instancetype)wr_createTeamFeaturesURL NS_REFINED_FOR_SWIFT;

+ (instancetype)wr_manageTeamURL NS_REFINED_FOR_SWIFT;

+ (instancetype)wr_emailInUseLearnMoreURL NS_REFINED_FOR_SWIFT;

@end

NS_ASSUME_NONNULL_END
