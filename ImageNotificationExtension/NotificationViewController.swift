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
public class NotificationViewController: UIViewController, UNNotificationContentExtension {

    private var fetchEngine: NotificationFetchEngine?
    private var imageMessageView: ImageMessageView!
    
    private var message: ZMAssetClientMessage? {
        didSet {
            self.imageMessageView.message = self.message
        }
    }
   
    override public func viewDidLoad() {
        super.viewDidLoad()
        
        self.imageMessageView = ImageMessageView()
        self.view.addSubview(self.imageMessageView)
        
        constrain(self.view, self.imageMessageView) { selfView, imageMessageView in
            imageMessageView.top == selfView.top + 10
            imageMessageView.leading == selfView.leading
            imageMessageView.trailing == selfView.trailing
            imageMessageView.bottom == selfView.bottom
        }
    }

    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        createFetchEngine()
    }

    private func createFetchEngine() {
        guard let groupIdentifier = Bundle.main.groupIdentifier,
            let hostIdentifier = Bundle.main.hostBundleIdentifier else { return }

        do {
            fetchEngine = try NotificationFetchEngine(
                applicationGroupIdentifier: groupIdentifier,
                hostBundleIdentifier: hostIdentifier
            )
        } catch {
            fatal("Failed to initialize NotificationFetchEngine: \(error)")
        }

        fetchEngine?.changeClosure = { [weak self] in
            self?.imageMessageView.updateForImage()
        }
    }
    
    public func didReceive(_ notification: UNNotification) {
        guard let nonceString = notification.request.content.userInfo["nonce"] as? String,
            let conversationString = notification.request.content.userInfo["conversation"] as? String,
            let nonce = UUID(uuidString: nonceString),
            let conversation = UUID(uuidString: conversationString) else { return }

        if let assetMessage = fetchEngine?.fetch(nonce, conversation: conversation) {
            message = assetMessage
            assetMessage.requestImageDownload()
        }
    }

}

// TODO: Move accent colors handling to shared components
extension ZMUser {

    @objc func accentColor() -> UIColor {
        return UIColor.gray
    }


    var nameAccentColor: UIColor {
        return UIColor.gray
    }

}

extension UIColor {

    @objc func colorForZMAccentColor(_ color: ZMAccentColor) -> UIColor? {
        return UIColor.gray
    }

}
