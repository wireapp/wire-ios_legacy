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


import CocoaLumberjackSwift
import Foundation
import UIKit
import Cartography
import Classy

enum ClientSection: Int {
    case info = 0
    case fingerprintAndVerify = 1
    case resetSession = 2
    case removeDevice = 3
}

class SettingsClientViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UserClientObserver {
    
    fileprivate static let deleteCellReuseIdentifier: String = "DeleteCellReuseIdentifier"
    fileprivate static let resetCellReuseIdentifier: String = "ResetCellReuseIdentifier"
    fileprivate static let verifiedCellReuseIdentifier: String = "VerifiedCellReuseIdentifier"
    
    let userClient: UserClient
    var resetSessionPending: Bool = false
    
    var userClientToken: NSObjectProtocol!
    var credentials: ZMEmailCredentials?

    var tableView: UITableView!
    let topSeparator = OverflowSeparatorView()
    
    var fromConversation : Bool = false

    convenience init(userClient: UserClient, fromConversation: Bool, credentials: ZMEmailCredentials? = .none)
    {
        self.init(userClient: userClient, credentials: credentials)
        self.fromConversation = fromConversation
    }
    
    required init(userClient: UserClient, credentials: ZMEmailCredentials? = .none) {
        self.userClient = userClient
        
        super.init(nibName: nil, bundle: nil)
        self.edgesForExtendedLayout = []

        self.userClientToken = UserClientChangeInfo.add(observer: self, for: userClient)
        if userClient.fingerprint == .none {
            ZMUserSession.shared()?.enqueueChanges({ () -> Void in
                userClient.fetchFingerprintOrPrekeys()
            })
        }
        self.title = userClient.deviceClass?.capitalized(with: NSLocale.current)
        self.credentials = credentials
    }
    
    override var supportedInterfaceOrientations : UIInterfaceOrientationMask {
        return [.portrait]
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.addSubview(self.topSeparator)
        self.createTableView()
        self.createConstraints()
        
        // presented modally from conversation
        if let navController = self.navigationController, navController.viewControllers.count > 0 && navController.viewControllers[0] == self {
                self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(SettingsClientViewController.onDonePressed(_:)));
            if fromConversation {
                let barColor = Settings.shared().colorScheme == .light ? UIColor.white : UIColor.clear
                navController.navigationBar.barTintColor = barColor
            }
        }
        
        if fromConversation {
            self.cas_styleClass = "conversation"
        }
        CASStyler.default().styleItem(self)
    }
    
    fileprivate func createTableView() {
        let tableView = UITableView(frame: CGRect.zero, style: .grouped)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedRowHeight = 80
        tableView.backgroundColor = UIColor.clear
        tableView.register(ClientTableViewCell.self, forCellReuseIdentifier: ClientTableViewCell.zm_reuseIdentifier)
        tableView.register(FingerprintTableViewCell.self, forCellReuseIdentifier: FingerprintTableViewCell.zm_reuseIdentifier)
        tableView.register(SettingsTableCell.self, forCellReuseIdentifier: type(of: self).deleteCellReuseIdentifier)
        tableView.register(SettingsTableCell.self, forCellReuseIdentifier: type(of: self).resetCellReuseIdentifier)
        tableView.register(SettingsToggleCell.self, forCellReuseIdentifier: type(of: self).verifiedCellReuseIdentifier)
        self.tableView = tableView
        self.view.addSubview(tableView)
    }
    
    private func createConstraints() {
        constrain(tableView, self.view, self.topSeparator) { tableView, selfView, topSeparator in
            tableView.edges == selfView.edges
            
            topSeparator.left == tableView.left
            topSeparator.right == tableView.right
            topSeparator.top == tableView.top
        }
    }
    
    required override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        fatalError("init(nibNameOrNil:nibBundleOrNil:) has not been implemented")
    }
    
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func onVerifiedChanged(_ sender: UISwitch!) {
        let selfClient = ZMUserSession.shared()!.selfUserClient()
        
        ZMUserSession.shared()?.enqueueChanges({
            if (sender.isOn) {
                selfClient?.trustClient(self.userClient)
            } else {
                selfClient?.ignoreClient(self.userClient)
            }
        }, completionHandler: {
            sender.isOn = self.userClient.verified
            
            let verificationType : DeviceVerificationType = sender.isOn ? .verified : .unverified
            Analytics.shared().tagChange(verificationType, deviceOwner: .self)
        })
    }
    
    func onDonePressed(_ sender: AnyObject!) {
        self.navigationController?.presentingViewController?.dismiss(animated: true, completion: .none)
    }
    
    // MARK: - UITableViewDelegate, UITableViewDataSource
    
    func numberOfSections(in tableView: UITableView) -> Int {
        
        if self.userClient == ZMUserSession.shared()!.selfUserClient() {
            return 2
        }
        else {
            return 4
        }
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let clientSection = ClientSection(rawValue: section) else { return 0 }
        switch clientSection {
            
        case .info:
            return 1
        case .fingerprintAndVerify:
            if self.userClient == ZMUserSession.shared()?.selfUserClient()  {
                return 1
            }
            else {
                return 2
            }
        case .resetSession:
            return 1
        case .removeDevice:
            return 1
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let clientSection = ClientSection(rawValue: (indexPath as NSIndexPath).section) else { return UITableViewCell() }

        let styler = {[unowned self] (cell: UITableViewCell) -> () in
            if self.fromConversation {
                cell.cas_styleClass = "conversation"
            }
        }
        
        switch clientSection {
            
        case .info:
            if let cell = tableView.dequeueReusableCell(withIdentifier: ClientTableViewCell.zm_reuseIdentifier, for: indexPath) as? ClientTableViewCell {
                cell.selectionStyle = .none
                cell.userClient = self.userClient
                cell.wr_editable = false
                cell.showVerified = false
                cell.showLabel = true
                styler(cell)
                return cell
            }

            break
        
        case .fingerprintAndVerify:
            if (indexPath as NSIndexPath).row == 0 {
                if let cell = tableView.dequeueReusableCell(withIdentifier: FingerprintTableViewCell.zm_reuseIdentifier, for: indexPath) as? FingerprintTableViewCell {
                    
                    cell.selectionStyle = .none
                    cell.fingerprint = self.userClient.fingerprint
                    styler(cell)
                    return cell
                }
            }
            else {
                if let cell = tableView.dequeueReusableCell(withIdentifier: type(of: self).verifiedCellReuseIdentifier, for: indexPath) as? SettingsToggleCell {
                    cell.titleText = NSLocalizedString("device.verified", comment: "")
                    cell.cellNameLabel.accessibilityIdentifier = "device verified label"
                    cell.switchView.addTarget(self, action: #selector(SettingsClientViewController.onVerifiedChanged(_:)), for: .touchUpInside)
                    cell.switchView.accessibilityIdentifier = "device verified"
                    cell.switchView.isOn = self.userClient.verified
                   styler(cell)
                    return cell
                }
            }
            break
        case .resetSession:
            if let cell = tableView.dequeueReusableCell(withIdentifier: type(of: self).resetCellReuseIdentifier, for: indexPath) as? SettingsTableCell {
                cell.titleText = NSLocalizedString("profile.devices.detail.reset_session.title", comment: "")
                cell.accessibilityIdentifier = "reset session"
                styler(cell)
                return cell
            }
            
            break
        case .removeDevice:
            if let cell = tableView.dequeueReusableCell(withIdentifier: type(of: self).deleteCellReuseIdentifier, for: indexPath) as? SettingsTableCell {
                cell.titleText = NSLocalizedString("self.settings.account_details.remove_device.title", comment: "")
                cell.accessibilityIdentifier = "remove device"
                styler(cell)
                return cell
            }
            
            break
        }
        
        return UITableViewCell()
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        guard let clientSection = ClientSection(rawValue: (indexPath as NSIndexPath).section) else { return }
        switch clientSection {
       
        case .resetSession:
            self.userClient.resetSession()
            self.resetSessionPending = true
            break
            
        case .removeDevice:
            if let credentials = self.credentials {
                ZMUserSession.shared()?.delete([self.userClient], with: credentials)
                if let navigationController = self.navigationController {
                    navigationController.popViewController(animated: true)
                }
            }
            else {
                let passwordRequest = RequestPasswordViewController.requestPasswordController() { (result: Either<String, NSError>) -> () in
                    switch result {
                    case .left(let passwordString):
                        let newCredentials = ZMEmailCredentials(email: ZMUser.selfUser().emailAddress, password: passwordString)
                        self.credentials = newCredentials
                        ZMUserSession.shared()?.delete([self.userClient], with: newCredentials)
                        if let navigationController = self.navigationController {
                            navigationController.popViewController(animated: true)
                        }
                        
                    case .right(let error):
                        DDLogError("Error: \(error)")
                    }
                }
                self.present(passwordRequest, animated: true, completion: .none)
            }
            
        default:
            break
        }

    }

    func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        guard let clientSection = ClientSection(rawValue: section) else { return .none }
        switch clientSection {
           
        case .fingerprintAndVerify:
            return NSLocalizedString("self.settings.device_details.fingerprint.subtitle", comment: "")
        case .resetSession:
            return NSLocalizedString("self.settings.device_details.reset_session.subtitle", comment: "")
        case .removeDevice:
            return NSLocalizedString("self.settings.device_details.remove_device.subtitle", comment: "")
            
        default:
            return .none
        }
    }
    
    func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        if let headerFooterView = view as? UITableViewHeaderFooterView {
            headerFooterView.textLabel?.textColor = UIColor(white: 1, alpha: 0.4)
        }
    }
    
    func tableView(_ tableView: UITableView, willDisplayFooterView view: UIView, forSection section: Int) {
        if let headerFooterView = view as? UITableViewHeaderFooterView {
            headerFooterView.textLabel?.textColor = UIColor(white: 1, alpha: 0.4)
        }
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        self.topSeparator.scrollViewDidScroll(scrollView: scrollView)
    }
    
    // MARK: - UserClientObserver
    
    func userClientDidChange(_ changeInfo: UserClientChangeInfo) {
        if let tableView = self.tableView {
            tableView.reloadData()
        }
        
        // This means the fingerprint is acquired
        if self.resetSessionPending && self.userClient.fingerprint != .none {
            let alert = UIAlertController(title: "", message: NSLocalizedString("self.settings.device_details.reset_session.success", comment: ""), preferredStyle: .alert)
            let okAction = UIAlertAction(title: NSLocalizedString("general.ok", comment: ""), style: .default, handler:  { [unowned alert] (_) -> Void in
                alert.dismiss(animated: true, completion: .none)
            })
            alert.addAction(okAction)
            self.present(alert, animated: true, completion: .none)
            self.resetSessionPending = false
        }
    }
}
