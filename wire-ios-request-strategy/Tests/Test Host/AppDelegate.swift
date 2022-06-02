//
// Wire
// Copyright (C) 2017 Wire Swiss GmbH
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

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        window = UIWindow(frame: UIScreen.main.bounds)
        window?.backgroundColor = .red
        window?.makeKeyAndVisible()
        let vc = UIViewController()
        let textView = UITextView()
        textView.text = "This is the test host application for WireRequestStrategy tests."
        vc.view.addSubview(textView)
        textView.backgroundColor = .green
        textView.textContainerInset = .init(top: 22, left: 22, bottom: 22, right: 22)
        textView.isEditable = false
        textView.frame = vc.view.frame.insetBy(dx: 22, dy: 44)
        window?.rootViewController = vc

        return true
    }
}
