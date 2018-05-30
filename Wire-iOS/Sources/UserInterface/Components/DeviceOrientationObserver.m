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

@import WireUtilities;

#import "DeviceOrientationObserver.h"

@import CoreMotion;



NSString * const DeviceOrientationObserverDidDetectRotationNotification = @"DeviceOrientationObserverDidDetectRotationNotification";

static DeviceOrientationObserver *sharedInstance = nil;



@interface DeviceOrientationObserver ()

@property (nonatomic) CMMotionManager *motionManager;
@property (nonatomic) NSOperationQueue *operationQueue;
@property (nonatomic) UIDeviceOrientation backgroundThreadDeviceOrientation;
@property (nonatomic) UIDeviceOrientation deviceOrientation;

@end



@implementation DeviceOrientationObserver

+ (instancetype)sharedInstance
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init];
    });
    
    return sharedInstance;
}

- (instancetype)init
{
    self = [super init];
    
    if (self) {
        self.motionManager = [[CMMotionManager alloc] init];
        self.operationQueue = [[NSOperationQueue alloc] init];
    }
    
    return self;
}

- (void)startMonitoringDeviceOrientation
{
    if ([self.motionManager isDeviceMotionAvailable]) {
        [self.motionManager startDeviceMotionUpdatesToQueue:self.operationQueue withHandler:^(CMDeviceMotion *motion, NSError *error) {
            UIDeviceOrientation newDeviceOrientation = [self deviceOrientationFromMotion:motion];
            
            if (newDeviceOrientation != self.backgroundThreadDeviceOrientation) {
                self.backgroundThreadDeviceOrientation = newDeviceOrientation;
                ZM_WEAK(self);
                [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                    ZM_STRONG(self);
                    self.deviceOrientation = newDeviceOrientation;
                    [self notifyAboutRotationToDeviceOrientation:newDeviceOrientation];
                }];
            }
        }];
    }
}

- (void)stopMonitoringDeviceOrientation
{
    [self.motionManager stopDeviceMotionUpdates];
}

- (void)notifyAboutRotationToDeviceOrientation:(UIDeviceOrientation)deviceOrientation
{
    NSNotification *notification = [NSNotification notificationWithName:DeviceOrientationObserverDidDetectRotationNotification object:@(deviceOrientation)];
    [[NSNotificationCenter defaultCenter] postNotification:notification];
}

- (UIDeviceOrientation)deviceOrientationFromMotion:(CMDeviceMotion *)motion
{
    CGFloat x = motion.gravity.x;
    CGFloat y = motion.gravity.y;
    CGFloat z = motion.gravity.z;
    
    CGFloat angle = atan2(y, x) + M_PI;
    CGFloat dotProduct = z;
    CGFloat planeAngle = acos(dotProduct);
    const CGFloat deadSector = M_PI / 8;
    
    UIDeviceOrientation deviceOrientation = self.backgroundThreadDeviceOrientation;
    
    if (planeAngle >= M_PI - M_PI / 8)
    {
        deviceOrientation = UIDeviceOrientationFaceUp;
    }
    else if (planeAngle <= M_PI / 8)
    {
        deviceOrientation = UIDeviceOrientationFaceDown;
    }
    else if (angle >=  (M_PI_4 + deadSector) && angle <= (3 * M_PI_4 - deadSector))
    {
        deviceOrientation = UIDeviceOrientationPortrait;
    }
    else if (angle >= (3 * M_PI_4 + deadSector) && angle <=  (M_PI + M_PI_4 - deadSector))
    {
        deviceOrientation = UIDeviceOrientationLandscapeRight;
    }
    else if (angle >= (M_PI + M_PI_4 + deadSector) && angle <= (M_PI + 3 * M_PI_4) - deadSector)
    {
        deviceOrientation = UIDeviceOrientationPortraitUpsideDown;
    }
    else if (angle >= (2 * M_PI - M_PI_4 + deadSector) || angle <= (M_PI_4 - deadSector))
    {
        deviceOrientation = UIDeviceOrientationLandscapeLeft;
    }
    
    return deviceOrientation;
}

@end
