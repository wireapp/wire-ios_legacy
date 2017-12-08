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


#import "NSURL+WireURLs.h"



@implementation NSURL (WireURLs)

+ (instancetype)wr_fingerprintLearnMoreURL
{
    return [self URLWithString:@"https://wire.com/privacy/why"];
}

+ (instancetype)wr_fingerprintHowToVerifyURL
{
    return [self URLWithString:@"https://wire.com/privacy/how"];
}

+ (instancetype)wr_termsOfServicesURL
{
    return [self URLWithString:@"https://wire.com/legal/terms/embed/"];
}

+ (instancetype)wr_privacyPolicyURL
{
    return [self URLWithString:@"https://wire.com/legal/privacy/embed/"];
}

+ (instancetype)wr_licenseInformationURL
{
    return [self URLWithString:@"https://wire.com/legal/licenses/embed/"];
}

+ (instancetype)wr_websiteURL
{
    return [self URLWithString:@"https://wire.com"];
}

+ (instancetype)wr_passwordResetURL
{
    return [self URLWithString:@"https://account.wire.com/forgot/"];
}

+ (instancetype)wr_supportURL
{
    return [self URLWithString:@"https://support.wire.com"];
}

+ (instancetype)wr_askSupportURL
{
    return [self URLWithString:@"https://support.wire.com/hc/requests/new"];
}

+ (instancetype)wr_reportAbuseURL
{
    return [self URLWithString:@"https://wire.com/support/misuse/"];
}

+ (instancetype)wr_cannotDecryptHelpURL
{
    return [self URLWithString:@"https://wire.com/privacy/error-1"];
}

+ (instancetype)wr_cannotDecryptNewRemoteIDHelpURL
{
    return [self URLWithString:@"https://wire.com/privacy/error-2"];
}

+ (instancetype)wr_unknownMessageHelpURL
{
    return [self URLWithString:@"https://wire.com/compatibility/unknown-message"];
}

+ (instancetype)wr_createTeamURL
{
    return [self URLWithString:@"https://wire.com/create-team?pk_campaign=client&pk_kwd=ios"];
}

+ (instancetype)wr_createTeamFeaturesURL
{
    return [self URLWithString:@"https://wire.com/create-team?pk_campaign=client&pk_kwd=ios#features"];
}

+ (instancetype)wr_manageTeamURL
{
    return [self URLWithString:@"https://teams.wire.com/login?pk_campaign=client&pk_kwd=ios"];
}

+ (instancetype)wr_emailInUseLearnMoreURL
{
    return [self URLWithString:@"https://wire.com/support/email-in-use"];
}

@end
