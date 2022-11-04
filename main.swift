
// Wire
// Copyright (C) 2022 Wire Swiss GmbH
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

import UIKit

/*

 ------------------------
 NSE

 - detect call event
 - switch event type
    - incoming call
        if not yet reported
            then forward to main app
        else
            ignore

    - terminated call (cancel, answered elsewhere, rejected elsewhere, maybe normal termination too)
        if not yet reported
            ignore
        else
            then foward to main app

    - other
        ignore

 -------------------------
 Main app

 - switCh event type
        - incoming call
            report incoming to call kit
            forward event to avs

        - terminated
            report call ended to call kit
            forward event to avs (with changes to not duplicate call kit reporting)


 */



// Conditionally inject App Delegate depending on whether we're running tests or not.
let appDelegateClass: AnyClass = NSClassFromString("TestingAppDelegate") ?? AppDelegate.self

UIApplicationMain(
    CommandLine.argc,
    CommandLine.unsafeArgv,
    NSStringFromClass(WireApplication.self),
    NSStringFromClass(appDelegateClass)
)
