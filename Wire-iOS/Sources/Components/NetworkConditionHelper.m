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


#import "NetworkConditionHelper.h"
#import "AppDelegate.h"
#import "Wire-Swift.h"

@import CoreTelephony;
@import WireSyncEngine;


NetworkQualityType
QualityTypeFromNSString(NSString *qualityString);


@interface NetworkConditionHelper ()

@property (nonnull, nonatomic) CTTelephonyNetworkInfo *networkInfo;

@end

@implementation NetworkConditionHelper

+ (instancetype)sharedInstance;
{
    static NetworkConditionHelper *instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[NetworkConditionHelper alloc] init];
    });
    return instance;
}

- (instancetype)init;
{
    self = [super init];
    if (self) {
        self.networkInfo = [[CTTelephonyNetworkInfo alloc] init];
    }
    return self;
}

- (NetworkQualityType)qualityType;
{
    id<ServerConnection> serverConnection = SessionManager.shared.serverConnection;
    
    if (serverConnection.isOffline) {
        return NetworkQualityTypeUnkown;
    }
    if (!serverConnection.isMobileConnection) {
        return NetworkQualityTypeWifi;
    }
    return QualityTypeFromNSString(self.networkInfo.currentRadioAccessTechnology);
}


@end

NetworkQualityType
QualityTypeFromNSString(NSString *cellularTypeString)
{
    if ([cellularTypeString isEqualToString:CTRadioAccessTechnologyGPRS] ||
        [cellularTypeString isEqualToString:CTRadioAccessTechnologyEdge] ||
        [cellularTypeString isEqualToString:CTRadioAccessTechnologyCDMA1x]) {
        return NetworkQualityType2G;
    }
    
    if ([cellularTypeString isEqualToString:CTRadioAccessTechnologyWCDMA]        ||
        [cellularTypeString isEqualToString:CTRadioAccessTechnologyHSDPA]        ||
        [cellularTypeString isEqualToString:CTRadioAccessTechnologyHSUPA]        ||
        [cellularTypeString isEqualToString:CTRadioAccessTechnologyCDMAEVDORev0] ||
        [cellularTypeString isEqualToString:CTRadioAccessTechnologyCDMAEVDORevA] ||
        [cellularTypeString isEqualToString:CTRadioAccessTechnologyCDMAEVDORevB] ||
        [cellularTypeString isEqualToString:CTRadioAccessTechnologyeHRPD]) {
        return NetworkQualityType3G;
    }
    
    if ([cellularTypeString isEqualToString:CTRadioAccessTechnologyLTE]) {
        return NetworkQualityType4G;
    }
    
    return NetworkQualityTypeUnkown;

}
