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

import UIKit
import UserNotifications
import UserNotificationsUI
import WireExtensionComponents
import NotificationFetchComponents


fileprivate extension Bundle {
    var groupIdentifier: String? {
        return infoDictionary?["ApplicationGroupIdentifier"] as? String
    }

    var hostBundleIdentifier: String? {
        return infoDictionary?["HostBundleIdentifier"] as? String
    }
}

let log = ZMSLog(tag: "notification image extension")

@objc(NotificationViewController)
class NotificationViewController: UIViewController, UNNotificationContentExtension {

    private var imageView: UIImageView!
    private var fetchEngine: NotificationFetchEngine?
    private let infoDict = Bundle.main.infoDictionary
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.imageView = UIImageView()
        self.view.addSubview(self.imageView)

        do {
            try createFetchEngine()
        } catch {
            log.error("Failed to initialize NotificationFetchEngine: \(error)")
        }
    }

    private func createFetchEngine() throws {
        guard let groupIdentifier = Bundle.main.groupIdentifier,
            let hostIdentifier = Bundle.main.hostBundleIdentifier else { return }

        fetchEngine = try NotificationFetchEngine(
            applicationGroupIdentifier: groupIdentifier,
            hostBundleIdentifier: hostIdentifier
        )
    }
    
    func didReceive(_ notification: UNNotification) {
        dump(notification)
        dump(notification.request)
        dump(notification.request.content)
        dump(notification.request.content.userInfo)
    }

}
