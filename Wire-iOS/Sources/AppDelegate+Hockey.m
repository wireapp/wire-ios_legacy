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


#import "AppDelegate+Hockey.h"

#import "Analytics.h"
#import "Application+runDuration.h"
#import "Settings.h"
#import "Wire-Swift.h"
@import WireExtensionComponents;

static NSString* ZMLogTag ZM_UNUSED = @"UI";

@implementation AppDelegate (Hockey)

- (void)setupHockeyWithCompletion:(dispatch_block_t)completed
{
    BOOL shouldUseHockey = AutomationHelper.sharedHelper.useHockey || USE_HOCKEY;
    
    if (!shouldUseHockey) {
        if (nil != completed) {
            completed();
        }
        return;
    }
    
    // see https://github.com/bitstadium/HockeySDK-iOS/releases/tag/4.0.1
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"kBITExcludeApplicationSupportFromBackup"];
    BOOL hockeyTrackingEnabled = ![[TrackingManager shared] disableCrashAndAnalyticsSharing];

    BITHockeyManager *hockeyManager = [BITHockeyManager sharedHockeyManager];
    [hockeyManager configureWithIdentifier:@STRINGIZE(HOCKEY_APP_ID_KEY) delegate:self];
    [hockeyManager.authenticator setIdentificationType:BITAuthenticatorIdentificationTypeAnonymous];
    
    if (! [BITHockeyManager sharedHockeyManager].crashManager.didCrashInLastSession) {
        [[UIApplication sharedApplication] resetRunDuration];
    }
    
    NSNumber *commandLineDisableUpdateManager = [[NSUserDefaults standardUserDefaults] objectForKey:@"DisableHockeyUpdates"];
    if ([commandLineDisableUpdateManager boolValue]) {
        hockeyManager.updateManager.updateSetting = BITUpdateCheckManually;
    }

    hockeyManager.crashManager.crashManagerStatus = BITCrashManagerStatusAutoSend;
    [hockeyManager setTrackingEnabled: hockeyTrackingEnabled]; // We need to disable tracking before starting the manager!

    if (hockeyTrackingEnabled) {
        [hockeyManager startManager];
        [hockeyManager.authenticator authenticateInstallation];
    }

    if (hockeyTrackingEnabled && // no need to wait for crash upload if uploads are disabled
        hockeyManager.crashManager.didCrashInLastSession &&
        hockeyManager.crashManager.timeIntervalCrashInLastSessionOccurred < 5)
    {
        ZMLogError(@"HockeyIntegration: START Waiting for the crash log upload...");
        self.hockeyInitCompletion = completed;
        
        // Timeout for crash log upload
        [self performSelector:@selector(crashReportUploadDone) withObject:nil afterDelay:5];
    }
    else {
        if (nil != completed) {
            completed();
        }
    }
}

- (void)crashReportUploadDone
{
    ZMLogError(@"HockeyIntegration: finished or timed out sending the crash report");
    if (nil != self.hockeyInitCompletion) {
        self.hockeyInitCompletion();
        ZMLogError(@"HockeyIntegration: END Waiting for the crash log upload...");
        self.hockeyInitCompletion = nil;
    }
}

#pragma mark - BITCrashManagerDelegate

- (void)crashManagerWillSendCrashReport:(BITCrashManager *)crashManager
{
    [[UIApplication sharedApplication] resetRunDuration];
}

- (void)crashManagerDidFinishSendingCrashReport:(BITCrashManager *)crashManager
{
    [self crashReportUploadDone];
}

#pragma mark - BITHockeyManagerDelegate
- (NSString *)applicationLogForCrashManager:(BITCrashManager *)crashManager
{
    // get the content
    NSData *fileContent = [NSData dataWithContentsOfURL:ZMLastAssertionFile()];
    if(fileContent == nil) {
        return nil;
    }
    
    // delete it
    [[NSFileManager defaultManager] removeItemAtURL:ZMLastAssertionFile() error:nil];
    
    // return
    return [[NSString alloc] initWithData:fileContent encoding:NSUTF8StringEncoding];
}

@end
