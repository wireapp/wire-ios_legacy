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
@import OCMock;

#import "ZMTBaseTest.h"
#import "ZMTExpectation.h"
#import <libkern/OSAtomic.h>
#import <WireTesting/WireTesting-Swift.h>
#import <CommonCrypto/CommonCrypto.h>
#import "NSUUID+WireTesting.h"

@interface ZMTBaseTest()

@property (nonatomic) BOOL ignoreLogErrors; ///< if false, will fail on ZMLogError or ZMLogWarn
@property (nonatomic) NSMutableArray *mocksToBeVerified;
@property (nonatomic) NSMutableArray *expectations; // Beta3Workaround
@property (nonatomic) ZMSLogLogHookToken *logHookToken;

@property (nonatomic, strong) id<ZMSGroupQueue> innerFakeUIContext;
@property (nonatomic, strong) id<ZMSGroupQueue> innerFakeSyncContext;

@end

@implementation ZMTBaseTest

- (void)verifyMockLater:(id)mock;
{
    if (self.mocksToBeVerified == nil) {
        self.mocksToBeVerified = [NSMutableArray array];
    }
    XCTAssertNotNil(mock);
    [self.mocksToBeVerified addObject:mock];
}

- (void)verifyMocksNow;
{
    for (OCMockObject *mock in self.mocksToBeVerified) {
        
        @try {
            [mock verify];
        }
        @catch (NSException * e)
        {
            XCTFail(@"Mock not verified: %@", e);
        }
    }
    [self.mocksToBeVerified removeAllObjects];
}

+ (BOOL)isDebuggingTests
{
    NSString *debugTestContent = [[[NSProcessInfo processInfo]environment]objectForKey:@"DEBUG_TESTS"];
    return [debugTestContent boolValue];
}

- (void)performIgnoringZMLogError:(void(^)(void))block;
{
    if(!block) {
        return;
    }
    self.ignoreLogErrors = YES;
    block();
    [ZMSLog sync];
    self.ignoreLogErrors = NO;
}

- (void)registerLogErrorHook
{
    self.ignoreLogErrors = NO;
    ZM_WEAK(self);
    self.logHookToken = [ZMSLog addEntryHookWithLogHook:^(ZMLogLevel_t level, NSString * _Nullable tag, ZMSLogEntry * _Nonnull entry, ZM_UNUSED BOOL isSafe ) {
        ZM_STRONG(self);
        if (!self.ignoreLogErrors && level == ZMLogLevelError) {
            XCTFail(@"Unexpected log error: [%@] %@", tag, entry.text);
        }
    }];
}

- (void)unregisterLogErrorHook
{
    self.ignoreLogErrors = NO;
    if (self.logHookToken != nil) {
        [ZMSLog removeLogHookWithToken:_logHookToken];
        self.logHookToken = nil;
    }
}

- (void)setUp
{
    [super setUp];
    
    if (_dispatchGroup == nil) {
        _dispatchGroup = [ZMSDispatchGroup groupWithLabel:@"ZMTBaseTest"];
    }
    
    self.expectations = nil;
    
    [self registerLogErrorHook];
    
    self.innerFakeUIContext = [FakeGroupContext main];
    self.innerFakeSyncContext = [FakeGroupContext sync];
    
    [NSUUID reseedUUID:self.name];
}

- (void)tearDown
{
    [self unregisterLogErrorHook];
    [self verifyMocksNow];
    self.logHookToken = nil;
    self.innerFakeUIContext = nil;
    self.innerFakeSyncContext = nil;
    self.mocksToBeVerified = nil;
    self.expectations = nil;
    [super tearDown];
}

+ (void)tearDown {
    [self checkForMemoryLeaksAfterTestClassCompletes];
    [super tearDown];
}

- (id<ZMSGroupQueue>)fakeUIContext {
    return self.innerFakeUIContext;
}

- (id<ZMSGroupQueue>)fakeSyncContext {
    return self.innerFakeSyncContext;
}

- (void)spinMainQueueWithTimeout:(NSTimeInterval)timeout
{
    NSDate *runUntil = [NSDate dateWithTimeIntervalSinceNow: timeout];
    (void) [self waitUntilDate:runUntil verificationBlock:^BOOL{
        return NO;
    }];
}

- (BOOL)waitOnMainLoopUntilBlock:(VerificationBlock)block timeout:(NSTimeInterval)timeout;
{
    NSDate *start = [NSDate date];
    NSDate *runUntil = [NSDate dateWithTimeIntervalSinceNow: [self.class timeToUseForOriginalTime:timeout]];
    BOOL const result = [self waitUntilDate:runUntil verificationBlock:block];
    PrintTimeoutWarning(self, timeout, -[start timeIntervalSinceNow]);
    return result;
}

- (BOOL)waitWithTimeout:(NSTimeInterval)timeout verificationBlock:(VerificationBlock)block;
{
    return [self waitUntilDate:[NSDate dateWithTimeIntervalSinceNow:timeout] verificationBlock:block];
}

- (BOOL)waitUntilDate:(NSDate *)runUntil verificationBlock:(VerificationBlock)block;
{
    BOOL success = NO;
    while (! success && (0. < [runUntil timeIntervalSinceNow])) {
        
        if (! [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate dateWithTimeIntervalSinceNow:0.01]]) {
            [NSThread sleepForTimeInterval:0.005];
        }
        
        if ((block != nil) && block()) {
            success = YES;
            break;
        }
    }
    return success;
}

+ (NSTimeInterval)timeToUseForOriginalTime:(NSTimeInterval)originalTime
{
    NSTimeInterval realTime = ([self isDebuggingTests] ? 1000.0 : 5.0) * originalTime;
#if TARGET_OS_IPHONE || TARGET_IPHONE_SIMULATOR
    realTime *= 20;
#endif
    return realTime;
}

+ (void)performRunLoopTick;
{
    [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.05]];
}

- (XCTestExpectation *)expectationWithDescription:(NSString *)description;
{
    ZMTExpectation *expectation = [[ZMTExpectation alloc] init];
    expectation.name = description;
    
    if (self.expectations == nil) {
        self.expectations = [NSMutableArray arrayWithObject:expectation];
    } else {
        [self.expectations addObject:expectation];
    }
    
    return (XCTestExpectation *) expectation;
}

- (XCTestExpectation *)expectationForNotification:(NSString *)notificationName object:(id)objectToObserve handler:(XCNotificationExpectationHandler)handlerOrNil;
{
    ZMTNotificationExpectation *expectation = [[ZMTNotificationExpectation alloc] init];
    ZM_ALLOW_MISSING_SELECTOR([[NSNotificationCenter defaultCenter] addObserver:expectation selector:@selector(observe:) name:notificationName object:objectToObserve]);
    expectation.handler = handlerOrNil;
    expectation.name = notificationName;
    
    if (self.expectations == nil) {
        self.expectations = [NSMutableArray arrayWithObject:expectation];
    } else {
        [self.expectations addObject:expectation];
    }
    
    return (XCTestExpectation *) expectation;
}

- (XCTestExpectation *)keyValueObservingExpectationForObject:(id)objectToObserve keyPath:(NSString *)keyPath expectedValue:(id)expectedValue;
{
    RequireString(expectedValue == nil, "Not implemented");
    ZMTKeyValueObservingExpectation *expectation = [[ZMTKeyValueObservingExpectation alloc] init];
    expectation.object = objectToObserve;
    expectation.keyPath = keyPath;
    [objectToObserve addObserver:expectation forKeyPath:keyPath options:0 context:(__bridge void *) expectation];
    
    if (self.expectations == nil) {
        self.expectations = [NSMutableArray arrayWithObject:expectation];
    } else {
        [self.expectations addObject:expectation];
    }
    
    return (id) expectation;
}

- (NSArray *)allDispatchGroups;
{
    return @[self.dispatchGroup, self.fakeSyncContext.dispatchGroup, self.fakeUIContext.dispatchGroup];
}

- (BOOL)waitForAllGroupsToBeEmptyWithTimeout:(NSTimeInterval)timeout;
{
    NSArray *groups = [self.allDispatchGroups copy];
    
    NSDate * const start = [NSDate date];
    NSTimeInterval timeinterval2 = [self.class timeToUseForOriginalTime:timeout];
    NSDate *end = [start dateByAddingTimeInterval:timeinterval2];
    
    __block NSUInteger waitCount = groups.count;
    for (ZMSDispatchGroup *g in groups) {
        [g notifyOnQueue:dispatch_get_main_queue() block:^{
            --waitCount;
        }];
    }
    @try {
        while ((0 < waitCount) && (0. < [end timeIntervalSinceNow])) {
            if (! [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate dateWithTimeIntervalSinceNow:0.002]]) {
                [NSThread sleepForTimeInterval:0.002];
            }
        }
    } @catch (NSException *exception) {
        @throw exception;
    }
    PrintTimeoutWarning(self, timeout, -[start timeIntervalSinceNow]);
    return (waitCount == 0);
}

- (BOOL)waitForCustomExpectationsWithTimeout:(NSTimeInterval)timeout handler:(XCWaitCompletionHandler)handlerOrNil;
{
    NSTimeInterval timeInterval2 = [self.class timeToUseForOriginalTime:timeout];
    NSDate * const start = [NSDate date];
    NSDate * const end = [NSDate dateWithTimeIntervalSinceNow:timeInterval2];
    NSArray *expectations = [self.expectations copy];
    [self.expectations removeAllObjects];
    for (ZMTExpectation *e in expectations) {
        if (! [e waitUntil:end]) {
            PrintTimeoutWarning(self, timeout, -[start timeIntervalSinceNow]);
            return NO;
        }
    }
    // reset
    if (handlerOrNil) {
        handlerOrNil(nil);
    }
    PrintTimeoutWarning(self, timeout, -[start timeIntervalSinceNow]);
    return YES;
}

- (BOOL)verifyAllExpectationsNow
{
    return [self waitForCustomExpectationsWithTimeout:0];
}

- (BOOL)waitForCustomExpectationsWithTimeout:(NSTimeInterval)timeout;
{
    BOOL result = [self waitForCustomExpectationsWithTimeout:timeout handler:nil];
    return result;
}

+ (NSData *)verySmallJPEGData;
{
    NSURL *imageURL = [[NSBundle bundleForClass:[ZMTBaseTest class]] URLForResource:@"tiny" withExtension:@"jpg"];
    NSData *data = [NSData dataWithContentsOfURL:imageURL];
    RequireString(data != nil, "tiny.jpg not found");
    return data;
}

- (NSData *)verySmallJPEGData;
{
    return [[self class] verySmallJPEGData];
}

+ (NSData *)mediumJPEGData
{
    NSURL *imageURL = [[NSBundle bundleForClass:[ZMTBaseTest class]] URLForResource:@"medium" withExtension:@"jpg"];
    NSData *data = [NSData dataWithContentsOfURL:imageURL];
    RequireString(data != nil, "medium.jpg not found");
    return data;
}

- (NSData *)mediumJPEGData
{
    return [[self class] mediumJPEGData];

}

+ (NSData *)largeJPEGData
{
    NSURL *imageURL = [[NSBundle bundleForClass:[ZMTBaseTest class]] URLForResource:@"large" withExtension:@"jpg"];
    NSData *data = [NSData dataWithContentsOfURL:imageURL];
    RequireString(data != nil, "large.jpg not found");
    return data;
}

- (NSData *)largeJPEGData
{
    return [[self class] largeJPEGData];
    
}

@end


@implementation ZMTBaseTest (Asserts)

- (void)assertDictionary:(NSDictionary *)d1 isEqualToDictionary:(NSDictionary *)d2 name1:(char const *)name1 name2:(char const *)name2 failureRecorder:(ZMTFailureRecorder *)failureRecorder;
{
    [self assertDictionary:d1 isEqualToDictionary:d2 name1:name1 name2:name2 ignoreKeys:@[] failureRecorder:failureRecorder];
}

- (void)assertDictionary:(NSDictionary *)d1
     isEqualToDictionary:(NSDictionary *)d2
                   name1:(char const *)name1
                   name2:(char const *)name2
              ignoreKeys:(NSArray *)ignoredKeys
         failureRecorder:(ZMTFailureRecorder *)failureRecorder;
{
    NSMutableSet *keys1 = [NSSet setWithArray:d1.allKeys].mutableCopy;
    [keys1 minusSet:[NSSet setWithArray:ignoredKeys]];
    
    NSMutableSet *keys2 = [NSSet setWithArray:d2.allKeys].mutableCopy;
    [keys2 minusSet:[NSSet setWithArray:ignoredKeys]];
    
    
    if (! [keys1 isEqualToSet:keys2]) {
        XCTFail(@"Keys don't match for %s and %s", name1, name2);
        NSMutableSet *missingKeys = [keys1 mutableCopy];
        [missingKeys minusSet:keys2];
        if (0 < missingKeys.count) {
            [failureRecorder recordFailure:@"%s is missing keys: '%@'",
             name1, [[missingKeys allObjects] componentsJoinedByString:@"', '"]];
        }
        NSMutableSet *additionalKeys = [keys2 mutableCopy];
        [additionalKeys minusSet:keys1];
        if (0 < additionalKeys.count) {
            [failureRecorder recordFailure:@"%s has additional keys: '%@'",
             name1, [[additionalKeys allObjects] componentsJoinedByString:@"', '"]];
        }
    }
    for (id key in keys1) {
        if (! [d1[key] isEqual:d2[key]]) {
            [failureRecorder recordFailure:@"Value for '%@' in '%s' does not match '%s'. %@ == %@",
             key, name1, name2, d1[key], d2[key]];
        }
    }
}

- (void)assertArray:(NSArray *)a1 hasSameElementsAsArray:(NSArray *)a2 name1:(char const *)name1 name2:(char const *)name2 failureRecorder:(ZMTFailureRecorder *)failureRecorder;
{
    if(a1 == nil && a2 == nil) {
        [failureRecorder recordFailure:@"Both arrays are nil: %s == %s", name1, name2];
        return;
    }
    
    if(a1 == nil || a2 == nil) {
        [failureRecorder recordFailure:@"%s array is nil: %s == %s",
         (a1 == nil ? name1 : name2), name1, name2];
        return;
    }
    
    if(a1 == a2) {
        return;
    }
    
    NSCountedSet *set1 = [[NSCountedSet alloc] initWithArray:a1];
    NSCountedSet *set2 = [[NSCountedSet alloc] initWithArray:a2];
    
    for (id obj1 in set1) {
        NSUInteger count2 = [set2 countForObject:obj1];
        if (count2 == 0) {
            [failureRecorder recordFailure:@"Missing element from %s is not in %s: %@",
             name1, name2, obj1];
        } else if (count2 != [set1 countForObject:obj1]) {
            [failureRecorder recordFailure:@"Count of element in %s is not equal to count in %s (%u != %u): %@",
             name1, name2,
             (unsigned) [set1 countForObject:obj1], (unsigned) count2,
             obj1];
        }
    }
    for (id obj2 in set2) {
        NSUInteger count1 = [set1 countForObject:obj2];
        if (count1 == 0) {
            [failureRecorder recordFailure:@"Extra element in %s is not in %s: %@",
             name2, name1, obj2];
        }
    }
}



@end

void PrintTimeoutWarning(XCTestCase *test, NSTimeInterval const maxTimeout, NSTimeInterval const actualTimeout)
{
    if ([test.class isDebuggingTests] &&
        ((maxTimeout * 0.9) < actualTimeout))
    {
        NSString *output = [NSString stringWithFormat:@"warning: Timeout is set to %g, actually took %g (%@)",
                            maxTimeout, actualTimeout, test.name];
        fprintf(stderr, "%s\n", [output UTF8String]);
    }
}
