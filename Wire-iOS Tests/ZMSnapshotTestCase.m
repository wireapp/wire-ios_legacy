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


#import "ZMSnapshotTestCase.h"
#import <PureLayout/PureLayout.h>
#import <WireSyncEngine/WireSyncEngine.h>
#import "UIColor+WAZExtensions.h"
#import "ColorScheme.h"
#import "MagicConfig.h"

static CGSize const ZMDeviceSizeIPhone4 = (CGSize){ .width = 320, .height = 480 };
static CGSize const ZMDeviceSizeIPhone5 = (CGSize){ .width = 320, .height = 568 };
static CGSize const ZMDeviceSizeIPhone6 = (CGSize){ .width = 375, .height = 667 };
static CGSize const ZMDeviceSizeIPhone6Plus = (CGSize){ .width = 414, .height = 736 };
static CGSize const ZMDeviceSizeIPadPortrait = (CGSize){ .width = 768, .height = 1024 };
static CGSize const ZMDeviceSizeIPadLandscape = (CGSize){ .width = 1024, .height = 768 };

static NSArray *phoneSizes(void) {
    return @[
             [NSValue valueWithCGSize:ZMDeviceSizeIPhone4],
             [NSValue valueWithCGSize:ZMDeviceSizeIPhone5],
             [NSValue valueWithCGSize:ZMDeviceSizeIPhone6],
             [NSValue valueWithCGSize:ZMDeviceSizeIPhone6Plus]
             ];
}

static NSArray *tabletSizes(void) {
    return @[
             [NSValue valueWithCGSize:ZMDeviceSizeIPadPortrait],
             [NSValue valueWithCGSize:ZMDeviceSizeIPadLandscape]
             ];
}

static NSArray *deviceSizes(void) {
    return [phoneSizes() arrayByAddingObjectsFromArray:tabletSizes()];
}

static NSSet *phoneWidths(void) {
    return [phoneSizes() mapWithBlock:^NSValue *(NSValue *boxedSize) {
        return @(boxedSize.CGSizeValue.width);
    }].set;
}


@implementation ZMSnapshotTestCase

- (void)setUp
{
    [super setUp];
    [MagicConfig sharedConfig];
    XCTAssertEqual(UIScreen.mainScreen.scale, 2, @"Snapshot tests need to be run on a device with a 2x scale");

    if ([UIDevice.currentDevice.systemVersion compare:@"10" options:NSNumericSearch] == NSOrderedAscending) {
        XCTFail(@"Snapshot tests need to be run on a device running at least iOS 10");
    }

    [UIView setAnimationsEnabled:NO];
    self.snapshotBackgroundColor = UIColor.clearColor;
    // Enable when the design of the view has changed in order to update the reference snapshots
#ifdef RECORDING_SNAPSHOTS
    self.recordMode = YES;
#endif
    
    self.usesDrawViewHierarchyInRect = YES;

    [NSManagedObjectContext setUseInMemoryStore:YES];
    [NSManagedObjectContext resetUserInterfaceContext];
    [NSManagedObjectContext resetSharedPersistentStoreCoordinator];
    self.uiMOC = [NSManagedObjectContext createUserInterfaceContextWithStoreAtURL:[[NSFileManager defaultManager] URLForDirectory:NSDocumentDirectory inDomain:NSUserDomainMask appropriateForURL:nil create:YES error:nil]];
}

- (void)tearDown
{
    [super tearDown];
    [UIColor setAccentOverrideColor:ZMAccentColorUndefined];
    [UIView setAnimationsEnabled:YES];
}

- (void)setAccentColor:(ZMAccentColor)accentColor
{
     [UIColor setAccentOverrideColor:accentColor];
}

- (void)assertAmbigousLayout:(UIView *)view file:(const char[])file line:(NSUInteger)line
{
    if (view.hasAmbiguousLayout) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"
        NSString *description = [NSString stringWithFormat:@"Ambigous layout in view: %@ trace: \n%@", view, [view performSelector:@selector(_autolayoutTrace)]];
#pragma clang diagnostic pop
        NSString *filePath = [NSString stringWithFormat:@"%s", file];
        [self recordFailureWithDescription:description inFile:filePath atLine:line expected:YES];
    }
}

- (UIView *)containerViewWithView:(UIView *)view
{
    UIView *container = [[UIView alloc] initWithFrame:view.bounds];
    container.backgroundColor = self.snapshotBackgroundColor;
    
    [container addSubview:view];
    [view autoPinEdgesToSuperviewEdgesWithInsets:UIEdgeInsetsZero];
    return container;
}

- (void)verifyView:(UIView *)view extraLayoutPass:(BOOL)extraLayoutPass file:(const char[])file line:(NSUInteger)line
{
    [self verifyView:view extraLayoutPass:extraLayoutPass tolerance:0 file:file line:line identifier:nil];
}

- (void)verifyView:(UIView *)view extraLayoutPass:(BOOL)extraLayoutPass file:(const char[])file line:(NSUInteger)line identifier:(NSString *)identifier
{
    [self verifyView:view extraLayoutPass:extraLayoutPass tolerance:0 file:file line:line identifier:identifier];
}

- (void)verifyView:(UIView *)view extraLayoutPass:(BOOL)extraLayoutPass tolerance:(float)tolerance file:(const char[])file line:(NSUInteger)line identifier:(NSString *)identifier
{
    UIView *container = [self containerViewWithView:view];
    if ([self assertEmptyFrame:container file:file line:line]) {
        return;
    }
    NSString *finalIdentifier = @"";
    
    if (0 == identifier.length) {
        finalIdentifier = NSStringFromCGSize(view.bounds.size);
    }
    else {
        finalIdentifier = [NSString stringWithFormat:@"%@-%@", identifier, NSStringFromCGSize(view.bounds.size)];
    }
    if (extraLayoutPass) {
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.1]];
    }
    
    FBSnapshotVerifyViewWithOptions(container, finalIdentifier, FBSnapshotTestCaseDefaultSuffixes(), tolerance);
    [self assertAmbigousLayout:container file:file line:line];
}

- (BOOL)assertEmptyFrame:(UIView *)view file:(const char[])file line:(NSUInteger)line
{
    if (CGRectIsEmpty(view.frame)) {
        NSString *description = @"View frame can not be empty";
        NSString *filePath = [NSString stringWithFormat:@"%s", file];
        [self recordFailureWithDescription:description inFile:filePath atLine:line expected:YES];
        return YES;
    }
    
    return NO;
}

- (void)verifyViewInAllDeviceSizes:(UIView *)view  extraLayoutPass:(BOOL)extraLayoutPass file:(const char[])file line:(NSUInteger)line
{
    [self verifyViewInAllDeviceSizes:view extraLayoutPass:extraLayoutPass file:file line:line configurationBlock:nil];
}

- (void)verifyViewInAllPhoneWidths:(UIView *)view extraLayoutPass:(BOOL)extraLayoutPass file:(const char[])file line:(NSUInteger)line
{
    [self assertAmbigousLayout:view file:file line:line];
    for (NSValue *value in phoneWidths()) {
        [self verifyView:view extraLayoutPass:extraLayoutPass width:value.CGSizeValue.width file:file line:line];
    }
}

- (void)verifyViewInAllTabletWidths:(UIView *)view extraLayoutPass:(BOOL)extraLayoutPass file:(const char[])file line:(NSUInteger)line
{
    [self assertAmbigousLayout:view file:file line:line];
    for (NSValue *value in tabletSizes()) {
        [self verifyView:view extraLayoutPass:extraLayoutPass width:value.CGSizeValue.width file:file line:line];
    }
}

- (void)verifyView:(UIView *)view extraLayoutPass:(BOOL)extraLayoutPass width:(CGFloat)width file:(const char[])file line:(NSUInteger)line
{
    UIView *container = [self containerViewWithView:view];
    
    [container autoSetDimension:ALDimensionWidth toSize:width];
    [container setNeedsLayout];
    [container layoutIfNeeded];
    [container setNeedsLayout];
    [container layoutIfNeeded];
    if ([self assertEmptyFrame:container file:file line:line]) {
        return;
    }
    if (extraLayoutPass) {
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.1]];
    }
    
    FBSnapshotVerifyView(container, @(width).stringValue)
}

- (void)verifyViewInAllPhoneSizes:(UIView *)view
                  extraLayoutPass:(BOOL)extraLayoutPass
                             file:(const char[])file
                             line:(NSUInteger)line
               configurationBlock:(void (^)(UIView * view))configuration;
{
    [self verifyView:view extraLayoutPass:extraLayoutPass inSizes:phoneSizes() file:file line:line configuration:^(UIView *view,__unused BOOL isPad) {
        if (nil != configuration) {
            configuration(view);
        }
    }];
}


- (void)verifyViewInAllDeviceSizes:(UIView *)view
                   extraLayoutPass:(BOOL)extraLayoutPass
                              file:(const char[])file
                              line:(NSUInteger)line
                configurationBlock:(void (^)(UIView * view, BOOL isPad))configuration
{
    [self verifyView:view extraLayoutPass:extraLayoutPass inSizes:deviceSizes() file:file line:line configuration:configuration];
}

- (void)verifyView:(UIView *)view
   extraLayoutPass:(BOOL)extraLayoutPass
           inSizes:(NSArray <NSValue *>*)sizes
              file:(const char[])file
              line:(NSUInteger)line
     configuration:(void (^)(UIView * view, BOOL isPad))configuration
{
    for (NSValue *value in sizes) {
        CGSize size = value.CGSizeValue;
        view.frame = CGRectMake(0, 0, size.width, size.height);
        if (nil != configuration) {
            BOOL iPad = CGSizeEqualToSize(size, ZMDeviceSizeIPadLandscape) || CGSizeEqualToSize(size, ZMDeviceSizeIPadPortrait);
            [UIView performWithoutAnimation:^{
                configuration(view, iPad);
            }];
        }
        
        [self verifyView:view extraLayoutPass:extraLayoutPass file:file line:line];
    }
}

#pragma mark - Helper

- (UIImage *)imageInTestBundleNamed:(NSString *)name
{
    return [UIImage imageWithContentsOfFile:[self URLForResourceInTestBundleNamed:name].path];
}

- (NSURL *)URLForResourceInTestBundleNamed:(NSString *)name
{
    NSBundle *bundle = [NSBundle bundleForClass:self.class];
    NSURL *url = [bundle URLForResource:name.stringByDeletingPathExtension withExtension:name.pathExtension];
    XCTAssertTrue(url.fileURL);
    
    return url;
}

@end
