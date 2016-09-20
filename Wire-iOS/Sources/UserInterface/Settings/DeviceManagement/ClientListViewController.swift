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
import zmessaging
import Cartography
import WireExtensionComponents
import CocoaLumberjackSwift


@objc class ClientListViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, ZMClientUpdateObserver {
    var clientsTableView: UITableView?

    var editingList: Bool = false {
        didSet {
            if (self.editingList) {
                self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.Done, target: self, action: #selector(ClientListViewController.endEditing(_:)))
            }
            else {
                self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.Edit, target: self, action: #selector(ClientListViewController.startEditing(_:)))
            }
            
            self.navigationItem.setHidesBackButton(self.editingList, animated: true)
            self.clientsTableView?.setEditing(self.editingList, animated: true)
        }
    }
    var clients: [UserClient] = [] {
        didSet {
            self.sortedClients = self.clients.sort({ (c1: UserClient, c2: UserClient) -> Bool in
                if let dateC1 = c1.activationDate,
                    let dateC2 = c2.activationDate {
                    return dateC1.compare(dateC2) == .OrderedDescending
                }
                else {
                    return false
                }
            })
            self.clientsTableView?.reloadData();
        }
    }
    
    var sortedClients: [UserClient] = []
    
    let selfClient: UserClient?
    let detailedView: Bool
    var credentials: ZMEmailCredentials?
    var clientsObserverToken: ZMClientUpdateObserverToken?
    var userObserverToken : ZMUserObserverOpaqueToken?
        
    required init(clientsList: [UserClient]?, credentials: ZMEmailCredentials? = .None, detailedView: Bool = false) {
        self.selfClient = ZMUserSession.sharedSession().selfUserClient()
        self.detailedView = detailedView
        self.credentials = credentials
        super.init(nibName: nil, bundle: nil)
        self.title = NSLocalizedString("registration.devices.title", comment:"")
        self.edgesForExtendedLayout = UIRectEdge.None

        let filteredClients = clientsList?.filter { $0 != selfClient } ?? []
        self.initalizeProperties(filteredClients)

        self.clientsObserverToken = ZMUserSession.sharedSession().addClientUpdateObserver(self)
        self.userObserverToken = ZMUser.addUserObserver(self, forUsers: [ZMUser.selfUser()], inUserSession: ZMUserSession.sharedSession())
        
        if clientsList == nil {
            self.showLoadingView = true
            ZMUserSession.sharedSession().fetchAllClients()
        }
    }
    
    required override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: NSBundle?) {
        fatalError("init(nibNameOrNil:nibBundleOrNil:) has not been implemented")
    }
    
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        ZMUserSession.sharedSession().removeClientUpdateObserver(self.clientsObserverToken)
        ZMUser.removeUserObserverForToken(self.userObserverToken)
    }
    
    private func initalizeProperties(clientsList: [UserClient]) {
        self.clients = clientsList
        self.editingList = false
    }
    
    override func supportedInterfaceOrientations() -> UIInterfaceOrientationMask {
        return [.Portrait]
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.view.backgroundColor = .clearColor()
        
        self.createTableView()
        self.createConstraints()
        
        if self.traitCollection.userInterfaceIdiom == .Pad {
            self.navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.Cancel, target: self, action: #selector(ClientListViewController.backPressed(_:)))
        }
        
        if let rootViewController = self.navigationController?.viewControllers.first
            where self.isEqual(rootViewController) {
                self.navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .Cancel, target: self, action: #selector(ClientListViewController.backPressed(_:)))
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        self.clientsTableView?.reloadData()
    }
    
    func openDetailsOfClient(client: UserClient) {
        if let navigationController = self.navigationController {
            let clientViewController = SettingsClientViewController(userClient: client, credentials: self.credentials)
            clientViewController.view.backgroundColor = self.view.backgroundColor
            navigationController.pushViewController(clientViewController, animated: true)
        }
    }

    private func createTableView() {
        let tableView = UITableView(frame: CGRectZero, style: .Grouped);
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.delegate = self
        tableView.dataSource = self
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedRowHeight = 80
        tableView.registerClass(ClientTableViewCell.self, forCellReuseIdentifier: ClientTableViewCell.zm_reuseIdentifier)
        tableView.editing = self.editingList
        tableView.backgroundColor = .clearColor()
        tableView.separatorColor = UIColor(white: 1, alpha: 0.1)
        self.view.addSubview(tableView)
        self.clientsTableView = tableView
    }
    
    private func createConstraints() {
        if let clientsTableView = self.clientsTableView {
            constrain(self.view, clientsTableView) { selfView, clientsTableView in
                clientsTableView.edges == selfView.edges
            }
        }
    }
    
    private func convertSection(section: Int) -> Int {
        if let _ = self.selfClient {
            return section
        }
        else {
            return section + 1
        }
    }
    
    // MARK: - Actions
    
    func startEditing(sender: AnyObject!) {
        self.editingList = true
    }
    
    func endEditing(sender: AnyObject!) {
        self.editingList = false
    }
    
    func backPressed(sender: AnyObject!) {
        self.navigationController?.presentingViewController?.dismissViewControllerAnimated(true, completion: nil)
    }
    
    func deleteUserClient(userClient: UserClient, credentials: ZMEmailCredentials) {
        self.showLoadingView = true
        ZMUserSession.sharedSession().deleteClients([userClient], withCredentials: credentials);
    }

    func displayError(message: String) {
        let alert = UIAlertController(title: "", message: message, preferredStyle: .Alert)
        let action = UIAlertAction(title: NSLocalizedString("general.ok", comment: ""), style: .Default) { [unowned alert] (_) -> Void in
            alert.dismissViewControllerAnimated(true, completion: .None)
        }
        alert.addAction(action)
        self.presentViewController(alert, animated: true, completion: .None)
    }

    // MARK: - ZMClientRegistrationObserver

    func finishedFetchingClients(userClients: [UserClient]!) {
        self.showLoadingView = false
        
        self.clients = userClients
    }
    
    func failedToFetchClientsWithError(error: NSError!) {
        self.showLoadingView = false
        
        DDLogError("Clients request failed: \(error)")
        
        self.displayError(NSLocalizedString("error.user.unkown_error", comment: ""))
    }
    
    func finishedDeletingClients(remainingClients: [UserClient]!) {
        self.showLoadingView = false
        self.clients = remainingClients
        Analytics.shared()?.tagDeleteDevice()
    }
    
    func failedToDeleteClientsWithError(error: NSError!) {
        self.showLoadingView = false
        self.credentials = .None
        
        self.displayError(NSLocalizedString("self.settings.account_details.remove_device.password.error", comment: ""))
    }
    
    // MARK: - UITableViewDataSource & UITableViewDelegate
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        if let _ = self.selfClient where self.sortedClients.count > 0 {
            return 2
        }
        else {
            return 1
        }
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch self.convertSection(section) {
        case 0:
            if let _ = self.selfClient {
                return 1
            }
            else {
                return 0
            }
        case 1:
            return self.sortedClients.count
        default:
            return 0
        }
    }
    
    func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch self.convertSection(section) {
            case 0:
                if let _ = self.selfClient {
                    return NSLocalizedString("registration.devices.current_list_header", comment:"")
                }
                else {
                    return nil
                }
            case 1:
                return NSLocalizedString("registration.devices.active_list_header", comment:"")
            default:
                return nil
        }
    }
    
    func tableView(tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        switch self.convertSection(section) {
            case 0:
                return nil
            case 1:
                return NSLocalizedString("registration.devices.active_list_subtitle", comment:"")
            default:
                return nil
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
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        if let cell = tableView.dequeueReusableCellWithIdentifier(ClientTableViewCell.zm_reuseIdentifier, forIndexPath: indexPath) as? ClientTableViewCell {
            cell.selectionStyle = .None
            cell.accessoryType = self.detailedView ? .DisclosureIndicator : .None
            cell.showVerified = self.detailedView
            
            switch self.convertSection(indexPath.section) {
            case 0:
                cell.userClient = self.selfClient
                cell.wr_editable = false
            case 1:
                cell.userClient = self.sortedClients[indexPath.row]
                cell.wr_editable = true
            default:
                cell.userClient = nil
            }
            
            return cell
        }
        else {
            return UITableViewCell()
        }
    }
    
    func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        switch self.convertSection(indexPath.section) {
        case 1:
            
            let userClient = self.sortedClients[indexPath.row]
            
            if let credentials = self.credentials {
                self.deleteUserClient(userClient, credentials: credentials)
            }
            else {
                let passwordRequest = RequestPasswordViewController.requestPasswordController() { (result: Either<String, NSError>) -> () in
                    switch result {
                    case .Left(let passwordString):
                        let newCredentials = ZMEmailCredentials(email: ZMUser.selfUser().emailAddress, password: passwordString)
                        self.credentials = newCredentials
                        self.deleteUserClient(userClient, credentials: newCredentials)
                    case .Right(let error):
                        DDLogError("Error: \(error)")
                    }
                }
                self.presentViewController(passwordRequest, animated: true, completion: .None)
            }
        default: break
        }
        
    }
    
    func tableView(tableView: UITableView, editingStyleForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCellEditingStyle {
        switch self.convertSection(indexPath.section) {
        case 0:
            return .None
        case 1:
            return .Delete
        default:
            return .None
        }
        
    }
    
    func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
        cell.separatorInset = UIEdgeInsetsZero
        cell.layoutMargins = UIEdgeInsetsZero
        cell.preservesSuperviewLayoutMargins = false
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if !self.detailedView {
            return
        }
        switch self.convertSection(indexPath.section) {
        case 0:
            if let selfClient = self.selfClient {
                self.openDetailsOfClient(selfClient)
            }
            break;
        case 1:
            self.openDetailsOfClient(self.sortedClients[indexPath.row])
            break;
        default:
            break;
        }

    }
}

extension ClientListViewController : ZMUserObserver {
    
    func userDidChange(note: UserChangeInfo!) {
        if (note.clientsChanged || note.trustLevelChanged) {
            guard let selfClient = ZMUser.selfUser().selfClient() else { return }
            var clients = ZMUser.selfUser().clients
            clients.remove(selfClient)
            self.clients = Array(clients)
        }
    }
    
}