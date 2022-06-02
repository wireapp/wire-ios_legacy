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


@import OCMock;
@import WireTransport;
@import UIKit;

#import "MessagingTest.h"
#import "ZMBlacklistDownloader+Testing.h"
#import "Tests-Swift.h"

@interface ZMBlacklistDownloaderTest : MessagingTest

@property (nonatomic) id URLSession;
@property (nonatomic) NSTimeInterval successCheckTimeInterval;
@property (nonatomic) NSTimeInterval failureCheckTimeInterval;
@property (nonatomic) ZMBlacklistDownloader *sut;

@end

@implementation ZMBlacklistDownloaderTest

- (void)setUp {

    [super setUp];
    
    [[NSUserDefaults standardUserDefaults] setObject:nil forKey:@"min_version"];
    [[NSUserDefaults standardUserDefaults] setObject:nil forKey:@"exclude"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    self.successCheckTimeInterval = 30000;
    self.failureCheckTimeInterval = 4000;
    
    self.URLSession = [OCMockObject niceMockForClass:[NSURLSession class]];
}

- (void)createSUTWithCompletionHandler:(void (^)(NSString *minVersion, NSArray *excludedVersions))completionHandler
{
    self.sut = [[ZMBlacklistDownloader alloc] initWithURLSession:self.URLSession
                                                             env:[[MockEnvironment alloc] init]
                                            successCheckInterval:self.successCheckTimeInterval
                                            failureCheckInterval:self.failureCheckTimeInterval
                                                    userDefaults:[NSUserDefaults standardUserDefaults]
                                                     application:self.application
                                                    workingGroup:self.syncMOC.dispatchGroup
                                               completionHandler:completionHandler
                ];
}

- (void)stopTimers
{
    [self.sut tearDown];
    WaitForAllGroupsToBeEmpty(0.5);
}

- (void)tearDown
{
    self.sut = nil;
    [[NSUserDefaults standardUserDefaults] setObject:nil forKey:@"min_version"];
    [[NSUserDefaults standardUserDefaults] setObject:nil forKey:@"exclude"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    WaitForAllGroupsToBeEmpty(0.5);
    [super tearDown];
}

- (void)simulateCachedValuesForMinVersion:(NSString *)minVersion excluded:(NSArray *)excluded
{
    [[NSUserDefaults standardUserDefaults] setObject:minVersion forKey:@"min_version"];
    [[NSUserDefaults standardUserDefaults] setObject:excluded forKey:@"exclude"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (NSData *)blackListDataForObject:(id)object
{
    NSError *error;
    NSData *data = [NSJSONSerialization dataWithJSONObject:object options:0 error:&error];
    if (error != nil) {
        NSLog(@"%@", error);
    }
    return data;
}

- (id)validBlackListWithMinimumVersion:(NSString *)minVersion exclude:(NSArray *)exclude
{
    return @{@"min_version": minVersion, @"exclude": exclude};
}

- (id)invalidBlackList
{
    return @{@"a": @[@1, @2], @"b": @3 };
}

- (id)invalidTypeBlackList
{
    return @{@"min_version": @1234, @"exclude": @[@1, @2, @3] };
}

- (void)stubRequest:(NSURLRequest *)request withResponseData:(NSData *)responseData responseError:(NSError *)responseError HTTPStatusCode:(NSUInteger)statusCode;
{
    __block void (^completionHandler)(NSData *data, NSURLResponse *response, NSError *error);
    
    NSHTTPURLResponse *response = [[NSHTTPURLResponse alloc] initWithURL:request.URL statusCode:(int)statusCode HTTPVersion:@"1.1" headerFields:@{}];
    id taskMock = [OCMockObject niceMockForClass:NSURLSessionDataTask.class];
    [[[(id) self.URLSession stub] andReturn:taskMock] dataTaskWithRequest:request completionHandler:[OCMArg checkWithBlock:^BOOL(id obj) {
        completionHandler = [obj copy];
        return YES;
    }]];
        
    void(^resume)(NSInvocation *) = ^(NSInvocation * ZM_UNUSED i){
        completionHandler(responseData, response, responseError);
    };
    
    [(NSURLSessionDataTask *)[[taskMock stub] andDo:resume] resume];
}

- (void)stubRequestWithResponseObject:(id)object responseError:(NSError *)responseError statusCode:(NSUInteger)statusCode;
{
    NSData *data;
    if ([object isKindOfClass:[NSDictionary class]]) {
        data = [self blackListDataForObject:object];
    }
    else {
        data = object;
    }
    
    id<BackendEnvironmentProvider> env = [[MockEnvironment alloc] init];
    NSURL *url = [env.blackListURL URLByAppendingPathComponent:@"ios"];
    [self stubRequest:[NSURLRequest requestWithURL:url] withResponseData:data responseError:responseError HTTPStatusCode:statusCode];
}

- (void)stubRequestWithSuccessfulResponseObject:(id)object
{
    [self stubRequestWithResponseObject:object responseError:nil statusCode:200];
}

- (void)testItReturnsBlackListWhenThereIsNoError;
{
    [self performIgnoringZMLogError:^{
        // given
        NSString *expectedMinVersion = @"1";
        NSArray *expectedExclude = @[@"123", @"124"];
        id blackList = [self validBlackListWithMinimumVersion:expectedMinVersion exclude:expectedExclude];
        [self stubRequestWithSuccessfulResponseObject:blackList];
        
        XCTestExpectation *didComplete = [self expectationWithDescription:@"did complete"];
        
        // when
        [self createSUTWithCompletionHandler:^(NSString *minVersion, NSArray *excludeVersions) {
            XCTAssertEqualObjects(minVersion, expectedMinVersion);
            XCTAssertEqualObjects(excludeVersions, expectedExclude);
            [didComplete fulfill];
        }];
        
        // then
        XCTAssert([self waitForCustomExpectationsWithTimeout:0.5]);
        [self stopTimers];
    }];
}

- (void)testItReturnsNilWhenThePropertyListHasTheWrongFormat
{
    // given
    id json = [self invalidBlackList];
    // when
    Blacklist *blacklist = [[Blacklist alloc] initWithJson:json];
    // then
    XCTAssertNil(blacklist);
}

- (void)testItReturnsNilWhenThePropertyListHasTheWrongFormat_WrongType
{
    // given
    id json = [self invalidTypeBlackList];
    // when
    Blacklist *blacklist = [[Blacklist alloc] initWithJson:json];
    // then
    XCTAssertNil(blacklist);
}

- (void)testThatItDownloadsAgainAfterCheckInterval
{
    [self performIgnoringZMLogError:^{
        
        // given
        self.successCheckTimeInterval = 0.1f;
        NSString *expectedMinVersion = @"1";
        NSArray *expectedExclude = @[@"123", @"124"];
        id blackList = [self validBlackListWithMinimumVersion:expectedMinVersion exclude:expectedExclude];
        [self stubRequestWithSuccessfulResponseObject:blackList];

        //expect that method will be called for second time after check interval
        XCTestExpectation *exp = [self expectationWithDescription:@"download called again"];
        __block NSUInteger timesCalled = 0;
        ZM_WEAK(self);
        dispatch_block_t didDownload = ^{
            ZM_STRONG(self);
            [self stubRequestWithSuccessfulResponseObject:blackList];
            ++timesCalled;
            if (timesCalled == 3) {
                [exp fulfill];
            }
        };

        // when
        [self createSUTWithCompletionHandler:^(__unused NSString *minVersion, __unused NSArray *excludeVersions) {
            didDownload();
        }];
        
        // then
        XCTAssert([self waitForCustomExpectationsWithTimeout:0.5]);
        [self stopTimers];
    }];
}

typedef NS_ENUM(int, TestPhase) {
    WaitForFirstCall,
    Suspended,
    Resumed
};

- (void)testThatItSuspendsWhenInTheBackgroundThenResumes
{
    [self performIgnoringZMLogError:^{
        // given
        __block TestPhase phase = WaitForFirstCall;
        self.successCheckTimeInterval = 0.1f;
        NSString *expectedMinVersion = @"1";
        NSArray *expectedExclude = @[@"123", @"124"];
        id blackList = [self validBlackListWithMinimumVersion:expectedMinVersion exclude:expectedExclude];
        [self stubRequestWithSuccessfulResponseObject:blackList];
        
        //expect that method will be called for second time after check interval
        XCTestExpectation *doneExp = [self expectationWithDescription:@"download called again"];
        
        __block NSUInteger downloadWhileSuspendedCount = 0;
        __block NSUInteger downloadWhileResumedCount = 0;
        dispatch_block_t didDownload = ^{
            [self stubRequestWithSuccessfulResponseObject:blackList];
            
            // suspend after first call
            if(phase == WaitForFirstCall) {
                phase = Suspended;
                [self.application simulateApplicationWillResignActive];
                
                // make it restart after a while
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    phase = Resumed;
                    [self.application simulateApplicationDidBecomeActive];
                });
            }
            // because of a race condition, might be called a couple of times even when suspended
            else if(phase == Suspended) {
                ++downloadWhileSuspendedCount;
                XCTAssertLessThan(downloadWhileSuspendedCount, 3u);
            }
            // when resuming, and it is firing a few more times, test is done
            else if(phase == Resumed) {
                ++downloadWhileResumedCount;
                if(downloadWhileResumedCount > 2) {
                    [doneExp fulfill];
                    self.successCheckTimeInterval = 1.0f;
                }
            }
        };
    
        // when
        [self createSUTWithCompletionHandler:^(__unused NSString *minVersion, __unused NSArray *excludeVersions) {
            didDownload();
        }];
        
        // then
        XCTAssert([self waitForCustomExpectationsWithTimeout:1]);
        [self stopTimers];
    }];
}


@end
