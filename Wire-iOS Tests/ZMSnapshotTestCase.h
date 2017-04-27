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


#import <UIKit/UIKit.h>
#import <FBSnapshotTestCase/FBSnapshotTestCase.h>
@import WireDataModel;

#define ZMVerifyViewInAllDeviceSizesWithBlock(view__, configuration__) \
do { \
    [self verifyViewInAllDeviceSizes:view__ extraLayoutPass:NO file:__FILE__ line:__LINE__ configurationBlock:configuration__]; \
} while (0)

#define ZMVerifyViewInAllDeviceSizes(view__) \
do { \
    [self verifyViewInAllDeviceSizes:view__ extraLayoutPass:NO file:__FILE__ line:__LINE__]; \
} while(0)

#define ZMVerifyViewInAllIPhoneWidths(view__) \
do { \
    [self verifyViewInAllPhoneWidths:view__ extraLayoutPass:NO file:__FILE__ line:__LINE__]; \
} while(0)

#define ZMVerifyViewInAllIPhoneSizes(view__) \
do { \
    [self verifyViewInAllPhoneSizes:view__ extraLayoutPass:NO file:__FILE__ line:__LINE__ configurationBlock:nil]; \
} while(0)

#define ZMVerifyViewInAllIPhoneSizesWithBlock(view__, configuration__) \
do { \
    [self verifyViewInAllPhoneSizes:view__ extraLayoutPass:NO file:__FILE__ line:__LINE__ configurationBlock:configuration__]; \
} while(0)

#define ZMVerifyView(view__) \
do { \
    [self verifyView:view__ extraLayoutPass:NO file:__FILE__ line:__LINE__]; \
} while(0)


NS_ASSUME_NONNULL_BEGIN

@interface ZMSnapshotTestCase : FBSnapshotTestCase

@property (nonatomic) NSManagedObjectContext *uiMOC;

/// The color of the container view in which the view to
/// be snapshot will be placed, defaults to UIColor.lightGrayColor
@property (nonatomic, nullable) UIColor *snapshotBackgroundColor;

/// If this is set the accent color will be overriden for the tests
@property (nonatomic) ZMAccentColor accentColor;

/// Performs an assertion with the given view and the recorded snapshot.
- (void)verifyView:(UIView *)view extraLayoutPass:(BOOL)extraLayoutPass file:(const char [_Nullable])file line:(NSUInteger)line;

- (void)verifyView:(UIView *)view
   extraLayoutPass:(BOOL)extraLayoutPass
              file:(const char[_Nullable])file
              line:(NSUInteger)line
        identifier:(nullable NSString *)identifier;

- (void)verifyView:(UIView *)view
   extraLayoutPass:(BOOL)extraLayoutPass
         tolerance:(float)tolerance
              file:(const char[_Nullable])file
              line:(NSUInteger)line
        identifier:(nullable NSString *)identifier;

/// Performs multiple assertions with the given view using the screen sizes of
/// the common iPhones in Portrait and iPad in Landscape and Portrait.
/// This method only makes sense for views that will be on presented fullscreen.
- (void)verifyViewInAllDeviceSizes:(UIView *)view extraLayoutPass:(BOOL)extraLayoutPass file:(const char[_Nullable])file line:(NSUInteger)line;

- (void)verifyViewInAllPhoneWidths:(UIView *)view extraLayoutPass:(BOOL)extraLayoutPass file:(const char[_Nullable])file line:(NSUInteger)line;

- (void)verifyViewInAllTabletWidths:(UIView *)view extraLayoutPass:(BOOL)extraLayoutPass file:(const char[_Nullable])file line:(NSUInteger)line;

- (void)verifyViewInAllPhoneSizes:(UIView *)view
                  extraLayoutPass:(BOOL)extraLayoutPass
                             file:(const char[_Nullable])file
                             line:(NSUInteger)line
               configurationBlock:(nullable void (^)(UIView * view))configuration;

- (void)verifyViewInAllDeviceSizes:(UIView *)view
                   extraLayoutPass:(BOOL)extraLayoutPass
                              file:(const char[_Nullable])file
                              line:(NSUInteger)line
                configurationBlock:(nullable void (^)(UIView *view, BOOL isPad))configuration;

#pragma mark - Helper

- (UIImage *)imageInTestBundleNamed:(NSString *)name;

@end

NS_ASSUME_NONNULL_END
