//
// Wire
// Copyright (C) 2018 Wire Swiss GmbH
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

import Foundation
import UIKit
import WireDataModel
import WireSyncEngine

extension SelfProfileViewController {


    func presentNewLoginAlertControllerIfNeeded() -> Bool {
        let clientsRequiringUserAttention = ZMUser.selfUser().clientsRequiringUserAttention

        if clientsRequiringUserAttention.count > 0 {
            self.presentNewLoginAlertController(clientsRequiringUserAttention)
            return true
        }
        else {
            return false
        }
    }

    fileprivate func presentNewLoginAlertController(_ clients: Set<UserClient>) {
        let newLoginAlertController = UIAlertController(forNewSelfClients: clients)

        let actionManageDevices = UIAlertAction(title: "self.new_device_alert.manage_devices".localized, style: .default) { _ in
            self.openControllerForCellWithIdentifier(SettingsCellDescriptorFactory.settingsDevicesCellIdentifier)
        }

        newLoginAlertController.addAction(actionManageDevices)

        let actionTrustDevices = UIAlertAction(title: "self.new_device_alert.trust_devices".localized, style: .default) { [weak self] _ in
            self?.presentUserSettingChangeControllerIfNeeded()
        }

        newLoginAlertController.addAction(actionTrustDevices)

        present(newLoginAlertController, animated: true, completion: .none)

        ZMUserSession.shared()?.enqueue {
            clients.forEach {
                $0.needsToNotifyUser = false
            }
        }
    }

    @discardableResult func openControllerForCellWithIdentifier(_ identifier: String) -> UIViewController? {
        var resultViewController: UIViewController? = .none
        // Let's assume for the moment that menu is only 2 levels deep
        rootGroup?.allCellDescriptors().forEach({ (topCellDescriptor: SettingsCellDescriptorType) -> () in

            if let cellIdentifier = topCellDescriptor.identifier,
                let cellGroupDescriptor = topCellDescriptor as? SettingsControllerGeneratorType,
                let viewController = cellGroupDescriptor.generateViewController(),
                cellIdentifier == identifier
            {
                self.navigationController?.pushViewController(viewController, animated: false)
                resultViewController = viewController
            }

            if let topCellGroupDescriptor = topCellDescriptor as? SettingsInternalGroupCellDescriptorType & SettingsControllerGeneratorType {
                topCellGroupDescriptor.allCellDescriptors().forEach({ (cellDescriptor: SettingsCellDescriptorType) -> () in
                    if let cellIdentifier = cellDescriptor.identifier,
                        let cellGroupDescriptor = cellDescriptor as? SettingsControllerGeneratorType,
                        let topViewController = topCellGroupDescriptor.generateViewController(),
                        let viewController = cellGroupDescriptor.generateViewController(),
                        cellIdentifier == identifier
                    {
                        self.navigationController?.pushViewController(topViewController, animated: false)
                        self.navigationController?.pushViewController(viewController, animated: false)
                        resultViewController = viewController
                    }
                })
            }

        })

        return resultViewController
    }

}

extension UIAlertController {
    convenience init(forNewSelfClients clients: Set<UserClient>) {
        var deviceNamesAndDates: [String] = []

        for userClient in clients {
            let deviceName: String

            if let model = userClient.model,
                model.isEmpty == false {
                deviceName = model
            } else {
                deviceName = userClient.type.rawValue
            }

            let formatKey = "registration.devices.activated".localized
            let formattedDate = userClient.activationDate?.formattedDate
            let deviceDate = String(format: formatKey, formattedDate ?? "")

            deviceNamesAndDates.append("\(deviceName)\n\(deviceDate)")
        }

        let title = "self.new_device_alert.title".localized

        let messageFormat = clients.count > 1 ? "self.new_device_alert.message_plural".localized : "self.new_device_alert.message".localized

        let message = String(format: messageFormat, deviceNamesAndDates.joined(separator: "\n\n"))

        self.init(title: title, message: message, preferredStyle: .alert)
    }
}
