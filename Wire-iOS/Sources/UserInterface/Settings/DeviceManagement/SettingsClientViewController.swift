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

enum ClientSection: Int {
    case Info = 0
    case FingerprintAndVerify = 1
    case ResetSession = 2
    case RemoveDevice = 3
}

class SettingsClientViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UserClientObserver {
    
    private static let deleteCellReuseIdentifier: String = "DeleteCellReuseIdentifier"
    private static let resetCellReuseIdentifier: String = "ResetCellReuseIdentifier"
    private static let verifiedCellReuseIdentifier: String = "VerifiedCellReuseIdentifier"
    
    let userClient: UserClient
    var resetSessionPending: Bool = false
    
    var userClientToken: UserClientObserverOpaqueToken!
    var credentials: ZMEmailCredentials?

    var tableView: UITableView!
    let topSeparator = OverflowSeparatorView()

    required init(userClient: UserClient, credentials: ZMEmailCredentials? = .None) {
        self.userClient = userClient
        
        super.init(nibName: nil, bundle: nil)
        self.edgesForExtendedLayout = UIRectEdge.None

        self.userClientToken = userClient.addObserver(self)
        if userClient.fingerprint == .None {
            ZMUserSession.sharedSession().enqueueChanges({ () -> Void in
                userClient.markForFetchingPreKeys()
            })
        }
        self.title = userClient.deviceClass?.capitalizedString
        self.credentials = credentials
    }
    
    deinit {
        UserClient.removeObserverForUserClientToken(self.userClientToken)
    }
    
    override func supportedInterfaceOrientations() -> UIInterfaceOrientationMask {
        return [.Portrait]
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.backgroundColor = .clearColor()
        
        self.view.addSubview(self.topSeparator)
        self.createTableView()
        self.createConstraints()
        
        if let navController = self.navigationController
            where navController.viewControllers.count > 0 && navController.viewControllers[0] == self {
                self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .Done, target: self, action: #selector(SettingsClientViewController.onDonePressed(_:)));
        }
    }
    
    private func createTableView() {
        let tableView = UITableView(frame: CGRectZero, style: .Grouped)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedRowHeight = 80
        tableView.backgroundColor = .clearColor()
        tableView.separatorColor = UIColor(white: 1, alpha: 0.1)
        tableView.registerClass(ClientTableViewCell.self, forCellReuseIdentifier: ClientTableViewCell.zm_reuseIdentifier)
        tableView.registerClass(FingerprintTableViewCell.self, forCellReuseIdentifier: FingerprintTableViewCell.zm_reuseIdentifier)
        tableView.registerClass(SettingsTableCell.self, forCellReuseIdentifier: self.dynamicType.deleteCellReuseIdentifier)
        tableView.registerClass(SettingsTableCell.self, forCellReuseIdentifier: self.dynamicType.resetCellReuseIdentifier)
        tableView.registerClass(SettingsToggleCell.self, forCellReuseIdentifier: self.dynamicType.verifiedCellReuseIdentifier)
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
    
    required override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: NSBundle?) {
        fatalError("init(nibNameOrNil:nibBundleOrNil:) has not been implemented")
    }
    
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func onVerifiedChanged(sender: UISwitch!) {
        let selfClient = ZMUserSession.sharedSession().selfUserClient()
        if(sender.on) {
            selfClient.trustClient(self.userClient)
        } else {
            selfClient.ignoreClient(self.userClient)
        }
        sender.on = self.userClient.verified
        
        let verificationType : DeviceVerificationType = sender.on ? .Verified : .Unverified
        Analytics.shared()?.tagChangeDeviceVerification(verificationType, deviceOwner: .Self)
    }
    
    func onDonePressed(sender: AnyObject!) {
        self.navigationController?.presentingViewController?.dismissViewControllerAnimated(true, completion: .None)
    }
    
    // MARK: - UITableViewDelegate, UITableViewDataSource
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        
        if self.userClient == ZMUserSession.sharedSession().selfUserClient() {
            return 2
        }
        else {
            return 4
        }
    }

    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let clientSection = ClientSection(rawValue: section) else { return 0 }
        switch clientSection {
            
        case .Info:
            return 1
        case .FingerprintAndVerify:
            if self.userClient == ZMUserSession.sharedSession().selfUserClient()  {
                return 1
            }
            else {
                return 2
            }
        case .ResetSession:
            return 1
        case .RemoveDevice:
            return 1
        }
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        guard let clientSection = ClientSection(rawValue: indexPath.section) else { return UITableViewCell() }

        switch clientSection {
            
        case .Info:
            if let cell = tableView.dequeueReusableCellWithIdentifier(ClientTableViewCell.zm_reuseIdentifier, forIndexPath: indexPath) as? ClientTableViewCell {
                cell.selectionStyle = .None
                cell.userClient = self.userClient
                cell.wr_editable = false
                cell.showVerified = false
                cell.showLabel = true
                return cell
            }

            break
        
        case .FingerprintAndVerify:
            if indexPath.row == 0 {
                if let cell = tableView.dequeueReusableCellWithIdentifier(FingerprintTableViewCell.zm_reuseIdentifier, forIndexPath: indexPath) as? FingerprintTableViewCell {
                    cell.selectionStyle = .None
                    cell.fingerprint = self.userClient.fingerprint
                    return cell
                }
            }
            else {
                if let cell = tableView.dequeueReusableCellWithIdentifier(self.dynamicType.verifiedCellReuseIdentifier, forIndexPath: indexPath) as? SettingsToggleCell {
                    cell.titleText = NSLocalizedString("device.verified", comment: "")
                    cell.switchView.addTarget(self, action: #selector(SettingsClientViewController.onVerifiedChanged(_:)), forControlEvents: .TouchUpInside)
                    cell.switchView.on = self.userClient.verified
                   
                    return cell
                }
            }
            break
        case .ResetSession:
            if let cell = tableView.dequeueReusableCellWithIdentifier(self.dynamicType.resetCellReuseIdentifier, forIndexPath: indexPath) as? SettingsTableCell {
                cell.titleText = NSLocalizedString("profile.devices.detail.reset_session.title", comment: "")
                
                return cell
            }
            
            break
        case .RemoveDevice:
            if let cell = tableView.dequeueReusableCellWithIdentifier(self.dynamicType.deleteCellReuseIdentifier, forIndexPath: indexPath) as? SettingsTableCell {
                cell.titleText = NSLocalizedString("self.settings.account_details.remove_device.title", comment: "")
                
                return cell
            }
            
            break
        }
        
        return UITableViewCell()
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
        
        guard let clientSection = ClientSection(rawValue: indexPath.section) else { return }
        switch clientSection {
       
        case .ResetSession:
            self.userClient.resetSession()
            self.resetSessionPending = true
            break
            
        case .RemoveDevice:
            if let credentials = self.credentials {
                ZMUserSession.sharedSession().deleteClients([self.userClient], withCredentials: credentials)
                if let navigationController = self.navigationController {
                    navigationController.popViewControllerAnimated(true)
                }
            }
            else {
                let passwordRequest = RequestPasswordViewController.requestPasswordController() { (result: Either<String, NSError>) -> () in
                    switch result {
                    case .Left(let passwordString):
                        let newCredentials = ZMEmailCredentials(email: ZMUser.selfUser().emailAddress, password: passwordString)
                        self.credentials = newCredentials
                        ZMUserSession.sharedSession().deleteClients([self.userClient], withCredentials: newCredentials)
                        if let navigationController = self.navigationController {
                            navigationController.popViewControllerAnimated(true)
                        }
                        
                    case .Right(let error):
                        DDLogError("Error: \(error)")
                    }
                }
                self.presentViewController(passwordRequest, animated: true, completion: .None)
            }
            
        default:
            break
        }

    }

    func tableView(tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        guard let clientSection = ClientSection(rawValue: section) else { return .None }
        switch clientSection {
           
        case .FingerprintAndVerify:
            return NSLocalizedString("self.settings.device_details.fingerprint.subtitle", comment: "")
        case .ResetSession:
            return NSLocalizedString("self.settings.device_details.reset_session.subtitle", comment: "")
        case .RemoveDevice:
            return NSLocalizedString("self.settings.device_details.remove_device.subtitle", comment: "")
            
        default:
            return .None
        }
    }
    
    func tableView(tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        if let headerFooterView = view as? UITableViewHeaderFooterView {
            headerFooterView.textLabel?.textColor = UIColor(white: 1, alpha: 0.4)
        }
    }
    
    func tableView(tableView: UITableView, willDisplayFooterView view: UIView, forSection section: Int) {
        if let headerFooterView = view as? UITableViewHeaderFooterView {
            headerFooterView.textLabel?.textColor = UIColor(white: 1, alpha: 0.4)
        }
    }
    
    func scrollViewDidScroll(scrollView: UIScrollView) {
        self.topSeparator.scrollViewDidScroll(scrollView)
    }
    
    // MARK: - UserClientObserver
    
    func userClientDidChange(changeInfo: UserClientChangeInfo) {
        if let tableView = self.tableView {
            tableView.reloadData()
        }
        
        // This means the fingerprint is acquired
        if self.resetSessionPending && self.userClient.fingerprint != .None {
            let alert = UIAlertController(title: "", message: NSLocalizedString("self.settings.device_details.reset_session.success", comment: ""), preferredStyle: .Alert)
            let okAction = UIAlertAction(title: NSLocalizedString("general.ok", comment: ""), style: .Default, handler:  { [unowned alert] (_) -> Void in
                alert.dismissViewControllerAnimated(true, completion: .None)
            })
            alert.addAction(okAction)
            self.presentViewController(alert, animated: true, completion: .None)
            self.resetSessionPending = false
        }
    }
}
