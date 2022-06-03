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



@import Foundation;


typedef NS_ENUM(int8_t, ZMAPSEnvironment) {
    ZMAPSEnvironmentUnknown = 0,
    ZMAPSEnvironmentProduction,
    ZMAPSEnvironmentSandbox,
};

typedef NS_ENUM(int8_t, ZMProvisionTeam) {
    ZMProvisionTeamUnknown = 0,
    ZMProvisionTeamAppStore,
    ZMProvisionTeamEnterprise,
};


@interface ZMMobileProvisionParser : NSObject

- (instancetype)initWithURL:(NSURL *)fileURL;

@property (nonatomic, readonly) ZMProvisionTeam team;
@property (nonatomic, readonly) ZMAPSEnvironment APSEnvironment;

@end
