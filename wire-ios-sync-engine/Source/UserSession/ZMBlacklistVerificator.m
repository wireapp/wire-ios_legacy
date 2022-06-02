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


@import WireSystem;
@import WireTransport;

#import "ZMBlacklistVerificator+Testing.h"
#import "ZMBlacklistDownloader.h"

@interface ZMBlacklistVerificator ()
@property (nonatomic) ZMBlacklistDownloader *downloader;
@end

@implementation ZMBlacklistVerificator

- (instancetype)initWithCheckInterval:(NSTimeInterval)checkInterval
                              version:(NSString *)version
                          environment:(id<BackendEnvironmentProvider>)environment
                         workingGroup:(ZMSDispatchGroup * _Nullable)workingGroup
                          application:(id<ZMApplication>)application
                    blacklistCallback:(void (^)(BOOL))blacklistCallback
{
    return [self initWithCheckInterval:checkInterval
                               version:version
                           environment:environment
                          workingGroup:workingGroup
                           application:application
                     blacklistCallback:blacklistCallback
                        blacklistClass:ZMBlacklistDownloader.class];
}

- (instancetype)initWithCheckInterval:(NSTimeInterval)checkInterval
                              version:(NSString *)version
                          environment:(id<BackendEnvironmentProvider>)environment
                         workingGroup:(ZMSDispatchGroup *)workingGroup
                          application:(id<ZMApplication>)application
                    blacklistCallback:(void (^)(BOOL))blacklistCallback
                       blacklistClass:(Class)blacklistClass
{
    self = [super init];
    if(self) {
        self.downloader = [[blacklistClass alloc] initWithDownloadInterval:checkInterval
                                                               environment:environment
                                                              workingGroup:workingGroup
                                                               application:application
                                                         completionHandler:^(NSString *minVersion, NSArray *excludedVersions) {
            [ZMBlacklistVerificator checkIfVersionIsBlacklisted:version completion:blacklistCallback minVersion:minVersion excludedVersions:excludedVersions];
        }];
    }
    return self;
}

+ (void)checkIfVersionIsBlacklisted:(NSString *)version completion:(void (^)(BOOL))completion minVersion:(NSString *)minVersion excludedVersions:(NSArray *)excludedVersions
{
    if (completion) {
        if ([version compare:minVersion
                     options:NSNumericSearch
                       range:NSMakeRange(0, version.length)
                      locale:[NSLocale localeWithLocaleIdentifier:@"en_US_POSIX"]] == NSOrderedAscending ||
            [excludedVersions containsObject:version]) {
            completion(YES);
        }
        else {
            completion(NO);
        }
    }
}

- (void)tearDown
{
    [self.downloader tearDown];
}

@end
