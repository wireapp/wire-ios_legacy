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

import Foundation
import ZMCSystem
import zmessaging
import Cartography
import MessageUI
import UIKit

class DeveloperOptionsController : UIViewController {
    
    /// Cells
    var tableCells : [UITableViewCell]!
    /// Map from UISwitch to the action it should perform. 
    /// The parameter of the action is whether the switch is on or off
    var uiSwitchToAction : [UISwitch : (Bool)->()] = [:]
    
    /// Map from UIButton to the action it should perform.
    var uiButtonToAction : [UIButton : ()->()] = [:]
    
    var mailViewController : MFMailComposeViewController? = nil
}

extension DeveloperOptionsController {
    
    override func loadView() {
        self.title = "options"
        self.view = UIView()
        self.edgesForExtendedLayout = UIRectEdge()
        self.view.backgroundColor = .clear
        
        self.tableCells = [forwardLogCell()] + ZMSLog.allTags.sorted().map { logSwitchCell(tag: $0) }
        
        let tableView = UITableView()
        tableView.dataSource = self
        tableView.backgroundColor = .clear
        tableView.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(tableView)
        
        constrain(self.view, tableView) { view, tableView in
            tableView.edges == view.edges
        }
    }

}

extension DeveloperOptionsController : UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.tableCells.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        return self.tableCells[indexPath.row]
    }
}

// MARK: - Cells
extension DeveloperOptionsController {
    
    /// Creates a cell to switch a specific log tag on or off
    func logSwitchCell(tag: String) -> UITableViewCell {
        return self.createCellWithSwitch(labelText: tag, isOn: ZMSLog.getLevel(tag: tag) == .debug) { (isOn) in
            Settings.shared().set(logTag: tag, enabled: isOn)
        }
    }
    
    /// Creates a cell to forward logs
    func forwardLogCell() -> UITableViewCell {
        return self.createCellWithButton(labelText: "Forward log records") {
            let logs = ZMSLog.recordedContent
            self.sendEmail(logs: logs)
        }
    }
    
    /// Creates a cell to forward logs
    func createCellWithButton(labelText: String, onTouchDown: @escaping ()->()) -> UITableViewCell {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("Go!", for: .normal)
        button.addTarget(self, action: #selector(DeveloperOptionsController.didPressButton(sender:)), for: .touchDown)
        self.uiButtonToAction[button] = onTouchDown
        return self.createCellWithLabelAndView(labelText: labelText, view: button)
    }
    
    /// Creates and sets the layout of a cell with a UISwitch
    func createCellWithSwitch(labelText: String, isOn: Bool, onValueChange: @escaping (Bool)->() ) -> UITableViewCell {
        let toggle = UISwitch()
        toggle.translatesAutoresizingMaskIntoConstraints = false
        toggle.isOn = isOn
        toggle.addTarget(self, action: #selector(DeveloperOptionsController.switchDidChange(sender:)), for: .valueChanged)
        self.uiSwitchToAction[toggle] = onValueChange
        return self.createCellWithLabelAndView(labelText: labelText, view: toggle)
    }
    
    /// Creates and sets the layout of a cell with a label and a view
    func createCellWithLabelAndView(labelText: String, view: UIView) -> UITableViewCell {
        let cell = UITableViewCell()
        cell.backgroundColor = .clear
        
        let label = UILabel()
        label.text = labelText
        label.textColor = .white
        label.translatesAutoresizingMaskIntoConstraints = false
        cell.contentView.addSubview(label)
        
        constrain(cell.contentView, label) { contentView, label in
            label.centerY == contentView.centerY
            label.left == contentView.left + 20
        }
        
        cell.contentView.addSubview(view)
        
        constrain(cell.contentView, view, label) { contentView, view, label in
            view.trailing == contentView.trailing - 20
            label.trailing == view.leading
            view.centerY == label.centerY
        }
        return cell
    }
}

// MARK: - Actions
extension DeveloperOptionsController {
    
    /// Invoked when one of the switches changes
    func switchDidChange(sender: AnyObject) {
        if let toggle = sender as? UISwitch {
            guard let action = self.uiSwitchToAction[toggle] else {
                fatalError("Unknown switch?")
            }
            action(toggle.isOn)
        }
    }
    
    /// Invoked when one of the buttons is pressed
    func didPressButton(sender: AnyObject) {
        if let button = sender as? UIButton {
            guard let action = self.uiButtonToAction[button] else {
                fatalError("Unknown button?")
            }
            action()
        }
    }
}

// MARK: - Email sending
extension DeveloperOptionsController : MFMailComposeViewControllerDelegate {
    
    func sendEmail(logs: [String]) {
        
        if self.mailViewController != nil {
            return
        }
        
        guard logs.count > 0 else {
            let alert = UIAlertView(title: "Error", message: "You have no logs to send", delegate: nil, cancelButtonTitle: "Ok")
            alert.show()
            return
        }
        guard MFMailComposeViewController.canSendMail() else {
            let alert = UIAlertView(title: "Error", message: "You do not have email set up", delegate: nil, cancelButtonTitle: "Ok")
            alert.show()
            return
        }
        
        // Prepare subject & body
        let user = ZMUser.selfUser()!
        let userID = user.remoteIdentifier?.transportString() ?? ""
        let device = UIDevice.current.name
        let now = Date()
        let userDescription = "\(user.name ?? "") [user: \(userID)] [device: \(device)]"
        let message = "Here are the logs from \(userDescription), at \(now)\n"
            + "It contains \(logs.count) log entries, please find them in the attached file"
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
        let timeStr = formatter.string(from: now)
        let fileName = "logs_U\(userID)_T\(timeStr).txt"
        
        // compose
        let mailVC = MFMailComposeViewController()
        mailVC.setToRecipients(["ios@wire.com"])
        mailVC.setSubject("iOS logs from \(userDescription)")
        mailVC.setMessageBody(message, isHTML: false)
        let completeLog = logs.joined(separator: "\n")
        mailVC.addAttachmentData(completeLog.data(using: .utf8)!, mimeType: "text/plain", fileName: fileName)
        mailVC.mailComposeDelegate = self
        self.mailViewController = mailVC
        self.present(mailVC, animated: true, completion: nil)
    }
    
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        self.mailViewController = nil
        controller.dismiss(animated: true)
    }
}
