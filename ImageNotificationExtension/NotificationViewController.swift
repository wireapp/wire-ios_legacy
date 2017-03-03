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
import Cartography


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
    private var userImageView: UserImageView!
    private var userNameLabel: UILabel!
    private var userImageViewContainer: UIView!
    private var fetchEngine: NotificationFetchEngine?
    private let infoDict = Bundle.main.infoDictionary
    
    private var user: ZMUser? {
        didSet {
            if let user = self.user {
                self.userNameLabel.textColor = ColorScheme.default().nameAccent(for: user.accentColorValue, variant: .light)
                self.userNameLabel.text = user.displayName
                self.userImageView.user = user
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.imageView = UIImageView()
        self.imageView.contentMode = .scaleAspectFit
        
        self.userImageViewContainer = UIView()
        
        self.userImageView = UserImageView(size: .tiny)
        self.userImageViewContainer.addSubview(self.userImageView)
        
        self.userNameLabel = UILabel()
        
        [self.imageView, self.userImageViewContainer, self.userNameLabel].forEach(self.view.addSubview)
        
        constrain(self.view, self.imageView, self.userImageView, self.userImageViewContainer, self.userNameLabel) { selfView, imageView, userImageView, userImageViewContainer, userNameLabel in
            
            userImageViewContainer.left == selfView.left
            userImageViewContainer.width == 48
            userImageViewContainer.height == 24
            userImageViewContainer.top == selfView.top
            
            userImageView.top == userImageViewContainer.top
            userImageView.bottom == userImageViewContainer.bottom
            userImageView.centerX == userImageViewContainer.centerX
            
            userNameLabel.left == userImageViewContainer.right
            userNameLabel.right == selfView.right
            userNameLabel.centerY == userImageView.centerY
            
            imageView.top == userImageViewContainer.bottom
            imageView.left == userImageViewContainer.right
            imageView.right == selfView.right
            imageView.bottom == selfView.bottom
        }
        
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
