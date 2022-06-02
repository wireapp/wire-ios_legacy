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


#import "AppDelegate.h"

@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    (void) application;
    (void) launchOptions;
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.window.backgroundColor = [UIColor redColor];
    [self.window makeKeyAndVisible];
    UIViewController *vc = [[UIViewController alloc] init];

    UITextView *textView = [[UITextView alloc] init];
    textView.text = @"This is the test host application for WireDataModel tests.";
    [vc.view addSubview:textView];
    textView.backgroundColor = [UIColor greenColor];
    textView.textContainerInset = UIEdgeInsetsMake(22, 22, 22, 22);
    textView.editable = NO;
    textView.frame = CGRectInset(vc.view.frame, 22, 44);

    self.window.rootViewController = vc;
    return YES;
}

@end
