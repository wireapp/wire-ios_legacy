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
@import WireUtilities;
@import WireTransport;
@import UIKit;

#import "ZMBlacklistDownloader+Testing.h"
#import <WireSyncEngine/WireSyncEngine-Swift.h>

static NSString *ZMLogTag ZM_UNUSED = @"Blacklist";

/// When to retry if the requests are failing
static NSTimeInterval UnsuccessfulDownloadRetryInterval = 30 * 60; // 30 minutes

static NSString * const MinVersionKey = @"min_version";
static NSString * const ExcludeVersionsKey = @"exclude";


@interface ZMBlacklistDownloader ()
@property (nonatomic) NSURLSession *urlSession;

/// Current data task
@property (nonatomic) NSURLSessionDataTask *dataTask;

/// How often to check, if the last attempt was a success
@property (nonatomic) NSTimeInterval successCheckInterval;

/// How ofter to check, it the last attempt was a failure
@property (nonatomic) NSTimeInterval failureCheckInterval;

/// Where to load/save cached values from
@property (nonatomic) NSUserDefaults *userDefaults;

/// Current cached min version
@property (nonatomic) NSString *minVersion;

/// Current cached excluded version
@property (nonatomic) NSArray *excludedVersions;

/// Isolation queue
@property (nonatomic) dispatch_queue_t queue;

/// Backend environment to use
@property (nonatomic) id<BackendEnvironmentProvider> env;

/// Callback to be called when the blacklisted versions change
@property (nonatomic, copy) void(^completionHandler)(NSString *, NSArray *);

/// Date of last successful download. If nil, there was no successful download
@property (nonatomic) NSDate *dateOfLastSuccessfulDownload;

/// Date of last failed download. If nil, there was no failed download
@property (nonatomic) NSDate *dateOfLastUnsuccessfulDownload;

/// Current timer
@property (nonatomic) NSTimer *currentTimer;

/// In background
@property (nonatomic) BOOL inBackground;

/// Group used to do work on. Will be entered when starting a request and exit when the response is received
@property (nonatomic) ZMSDispatchGroup *workingGroup;

/// Application
@property (nonatomic) id<ZMApplication> application;

@property (nonatomic) BOOL tornDown;

@end



/**
 Black list format:
 
 {
    "min_version": "123",
    "exclude": ["345", "346"]
 }
 
 Version string is just a build version number.
 All version that are lower than `min_version` or that are listed in `exclude` are not legal.

 Use of timers:
 A timer is used to donwload at periodic intervals. The interval depends on whether the last
 download was a success or a failure. The timer is stopped when moving to the background
 and restarted when coming to the foreground.

*/
@implementation ZMBlacklistDownloader

- (instancetype)initWithDownloadInterval:(NSTimeInterval)downloadInterval
                             environment:(id<BackendEnvironmentProvider>)environment
                            workingGroup:(ZMSDispatchGroup *)workingGroup
                             application:(id<ZMApplication>)application
                       completionHandler:(void (^)(NSString *, NSArray *))completionHandler {
    return [self initWithURLSession:nil
                                env:environment
               successCheckInterval:downloadInterval
               failureCheckInterval:UnsuccessfulDownloadRetryInterval
                       userDefaults:[NSUserDefaults standardUserDefaults]
                        application:application
                       workingGroup:workingGroup
                  completionHandler:completionHandler];
}



- (instancetype)initWithURLSession:(NSURLSession *)session
                               env:(id<BackendEnvironmentProvider>)env
              successCheckInterval:(NSTimeInterval)successCheckInterval
              failureCheckInterval:(NSTimeInterval)failureCheckInterval
                      userDefaults:(NSUserDefaults *)userDefaults
                       application:(id<ZMApplication>)application
                      workingGroup:(ZMSDispatchGroup *)workingGroup
                 completionHandler:(void (^)(NSString *, NSArray *))completionHandler
{
    self = [super init];
    if (self != nil) {
        self.application = application;
        self.urlSession = session ?: [self defaultSession];
        self.successCheckInterval = successCheckInterval;
        self.failureCheckInterval = MIN(failureCheckInterval,successCheckInterval);  // Make sure we don't download slower when unsuccessful
        self.userDefaults = userDefaults;
        self.env = env;
        self.inBackground = NO;
        self.queue = dispatch_queue_create("ZMBlacklistDownloader", DISPATCH_QUEUE_SERIAL);
        id excludedVersions = [userDefaults objectForKey:ExcludeVersionsKey];
        if ([excludedVersions isKindOfClass:[NSArray class]]) {
            self.excludedVersions = excludedVersions;
        }
        id minVersion = [self.userDefaults objectForKey:MinVersionKey];
        if ([minVersion isKindOfClass:[NSString class]]) {
            self.minVersion = minVersion;
        }
        self.completionHandler = completionHandler;
        self.dateOfLastSuccessfulDownload = nil;
        self.dateOfLastUnsuccessfulDownload = nil;
        self.workingGroup = workingGroup;
        
        [application registerObserverForDidBecomeActive:self selector:@selector(didBecomeActive:)];
        [application registerObserverForWillResignActive:self selector:@selector(willResignActive:)];
        
        [self startTimerIfNeeded];        
    }
    return self;
}

- (void)tearDown
{
    if (self.tornDown) {
        return;
    }
    self.tornDown = YES;
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self.application unregisterObserverForStateChange:self];
    self.inBackground = YES;

    [self.workingGroup enter];
    dispatch_sync(self.queue, ^{
        [self.currentTimer invalidate];
        self.currentTimer = nil;
    });
    [self.workingGroup leave];

    self.queue = nil;
    self.completionHandler = nil;
    // self.workingGroup = nil; --> NOTE! Do not nil out workingGroup otherwise we might not leave all groups when an async dispatch is performed
}

- (void)dealloc
{
    RequireString(self.tornDown, "ZMBlacklistDownloader needs to be torn down before deallocating.");
}

- (NSURLSession *)defaultSession
{
    NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
    configuration.requestCachePolicy = NSURLRequestReloadIgnoringCacheData;
    return [NSURLSession sessionWithConfiguration:configuration];
}	

- (void)willResignActive:(NSNotification * __unused)note
{
    if (self.tornDown) {
        return;
    }
    ZM_WEAK(self);
    [self.workingGroup enter];
    dispatch_async(self.queue, ^{
        ZM_STRONG(self);
        if (self == nil || self.tornDown) {
            [self.workingGroup leave];
            return;
        }
        self.inBackground = YES;
        [self.currentTimer invalidate];
        self.currentTimer = nil;
        [self.workingGroup leave];
    });
}

- (void)didBecomeActive:(NSNotification * __unused)note
{
    if (self.tornDown) {
        return;
    }
    ZM_WEAK(self);
    [self.workingGroup enter];
    dispatch_async(self.queue, ^{
        ZM_STRONG(self);
        if (self == nil || self.tornDown) {
            [self.workingGroup leave];
            return;
        }
        self.inBackground = NO;
        [self startTimerIfNeeded];
        [self.workingGroup leave];
    });
}

- (void)startTimerIfNeeded
{
    if (self.tornDown || self.inBackground || self.currentTimer != nil) {
        return;
    }
    
    ZM_WEAK(self);
    [self.workingGroup enter];
    dispatch_async(self.queue, ^{
        ZM_STRONG(self);
        if (self == nil || self.tornDown) {
            [self.workingGroup leave];
            return;
        }
        
        NSTimeInterval timeLeftSinceNextDownload = [self timeToNextDownload];
        if(timeLeftSinceNextDownload == 0) {
            [self fetchBlackList];
        }
        else {
            NSTimer *timer = [NSTimer timerWithTimeInterval:timeLeftSinceNextDownload target:self selector:@selector(timerDidFire) userInfo:nil repeats:NO];
            self.currentTimer = timer;
            [self.workingGroup enter];
            dispatch_async(dispatch_get_main_queue(), ^{
                ZM_STRONG(self);
                if (self == nil || self.tornDown) {
                    [self.workingGroup leave];
                    return;
                }
                if(self) {
                    [[NSRunLoop currentRunLoop] addTimer:timer forMode:NSRunLoopCommonModes];
                }
                [self.workingGroup leave];
            });
        }
        [self.workingGroup leave];
    
    });
}

- (void)timerDidFire
{
    if (self.tornDown) {
        return;
    }
    
    ZM_WEAK(self);
    [self.workingGroup enter];
    dispatch_async(self.queue, ^{
        ZM_STRONG(self);
        if (self == nil || self.tornDown) {
            [self.workingGroup leave];
            return;
        }
        self.currentTimer = nil;
        if(!self.inBackground) {
            [self fetchBlackList];
        }
        [self.workingGroup leave];
    });
}

- (NSTimeInterval)timeToNextDownload
{
    if(self.dateOfLastUnsuccessfulDownload == nil && self.dateOfLastSuccessfulDownload == nil) {
        return 0;
    }
    
    NSTimeInterval timeLeft = 0;
    
    BOOL isFailureMoreRecent =
        self.dateOfLastUnsuccessfulDownload != nil && // there was a failure
            (self.dateOfLastSuccessfulDownload == nil // never downloaded successfully
                || [self.dateOfLastUnsuccessfulDownload compare:self.dateOfLastSuccessfulDownload] == NSOrderedAscending // or failure is more recent that success
             );
    if(isFailureMoreRecent) {
        timeLeft = MAX(0, self.failureCheckInterval + [self.dateOfLastUnsuccessfulDownload timeIntervalSinceNow]);
    }
    else {
        timeLeft = MAX(0, self.successCheckInterval + [self.dateOfLastSuccessfulDownload timeIntervalSinceNow]);
    }
    return timeLeft;
}

- (void)storeMinVersion:(NSString *)minVersion excludedVersions:(NSArray *)excludedVersions
{
    NSParameterAssert([minVersion isKindOfClass:[NSString class]]);
    NSParameterAssert([excludedVersions isKindOfClass:[NSArray class]]);
    
    if(self.minVersion != minVersion || ![self.minVersion isEqualToString:minVersion]) {
        self.minVersion = minVersion;
        [self.userDefaults setObject:self.minVersion forKey:MinVersionKey];
    }
    
    if(self.excludedVersions != excludedVersions || ![self.excludedVersions isEqualToArray:excludedVersions]) {
        self.excludedVersions = excludedVersions;
        [self.userDefaults setObject:self.excludedVersions forKey:ExcludeVersionsKey];
    }
}

- (void)didReceiveResponseForBlacklistWithData:(NSData *)data response:(NSURLResponse * __unused)response error:(NSError *)error {
    
    if (self.tornDown) {
        return;
    }
    BOOL isSuccess = NO;
    NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
    if (error != nil) {
        ZMLogError(@"Failed to download black list: %@", error);
    }
    else if (data == nil) {
        ZMLogError(@"Black list data is nil");
    }
    else if(httpResponse.statusCode >= 400) {
        ZMLogError(@"Blacklist download returned status code %ld", (long)httpResponse.statusCode);
    }
    else {
        NSDictionary *blackListJSON = [self responseObjectWithData:data];
        if ([blackListJSON isKindOfClass:[NSDictionary class]]) {
            Blacklist *blacklist = [[Blacklist alloc] initWithJson:blackListJSON];
            
            if (nil != blacklist) {
                ZMLogInfo(@"Blacklist minimum version: %@, excluded versions: %@", blacklist.minVersion, blacklist.excludedVersions);

                [self didDownloadBlacklistWithMinVersion:blacklist.minVersion
                                                 exclude:blacklist.excludedVersions];
                isSuccess = YES;
            }
        }
    }
    
    if(isSuccess) {
        self.dateOfLastSuccessfulDownload = [NSDate date];
        self.dateOfLastUnsuccessfulDownload = nil;
    }
    else {
        self.dateOfLastSuccessfulDownload = nil;
        self.dateOfLastUnsuccessfulDownload = [NSDate date];
    }
    [self startTimerIfNeeded];
}

- (void)didDownloadBlacklistWithMinVersion:(NSString *)minVersion exclude:(NSArray *)exclude
{
    if(self.minVersion != minVersion || ![self.minVersion isEqualToString:minVersion]
       || self.excludedVersions != exclude || ![self.excludedVersions isEqualToArray:exclude]) {
        [self storeMinVersion:minVersion excludedVersions:exclude];
        
        if (self.completionHandler) {
            void(^completionHandler)(NSString *, NSArray *) = self.completionHandler;
            [self.workingGroup enter];
            ZM_WEAK(self);
            dispatch_async(dispatch_get_main_queue(), ^ void () {
                ZM_STRONG(self);
                completionHandler(minVersion, exclude);
                [self.workingGroup leave];
            });
        }
    }
}

- (void)fetchBlackList
{
    NSURL *backendURL = [self.env.blackListURL URLByAppendingPathComponent:@"ios"];
    NSURLRequest *urlRequest = [[NSURLRequest alloc] initWithURL:backendURL];
    ZMLogInfo(@"Blacklist URL: %@", backendURL.absoluteString);
    
    //If we have something cached - pass it back
    if (self.minVersion != nil && self.excludedVersions != nil) {
        [self didDownloadBlacklistWithMinVersion:self.minVersion exclude:self.excludedVersions];
    }
    // But also redownload because it might change
    ZM_WEAK(self);
    [self.workingGroup enter];
    self.dataTask = [self.urlSession dataTaskWithRequest:urlRequest completionHandler:^(NSData *data, NSURLResponse * __unused response, NSError *error) {
        ZM_STRONG(self);
        [self didReceiveResponseForBlacklistWithData:data response:response error:error];
        [self.workingGroup leave];
    }];
    [self.dataTask resume];
}

- (NSDictionary *)responseObjectWithData:(NSData *)data
{
    NSError *error;
    NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
    if (error) {
        ZMLogError(@"Black list json could not be parsed");
        return nil;
    }
    if (json == nil || ![json isKindOfClass:[NSDictionary class]]) {
        ZMLogError(@"Black list is empty or has invalid format");
        return nil;
    }
    return json;
}


@end

