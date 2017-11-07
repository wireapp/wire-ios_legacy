//
//  ShareExtensionNetworkObserver.swift
//  Wire-iOS
//
//  Created by Nicola Giancecchi on 07.11.17.
//  Copyright © 2017 Zeta Project Germany GmbH. All rights reserved.
//

import Foundation
import WireExtensionComponents

class ShareExtensionNetworkObserver: NSObject, NetworkStatusObserver {
    func wr_networkStatusDidChange(_ note: Notification!) {
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "networkStatusChange"), object: note.object, userInfo: nil)
    }
}
