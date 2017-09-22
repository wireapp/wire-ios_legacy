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


#import "Analytics+Metrics.h"
#import "AnalyticsBase.h"
#import "AnalyticsLocalyticsProvider.h"
#import "avs+iOS.h"
#import "Wire-Swift.h"

@import WireSyncEngine;

@implementation Analytics (Metrics)

+ (void)updateAVSMetricsSettingsWithActiveProvider:(AnalyticsLocalyticsProvider *)provider
{
    BOOL uploadMetrics = provider ? !provider.isOptedOut : NO;
    
    [[[AVSProvider shared] flowManager] setEnableMetrics:uploadMetrics];
    DDLogInfo(@"Set AVS metrics upload to %d", uploadMetrics);
}

@end
