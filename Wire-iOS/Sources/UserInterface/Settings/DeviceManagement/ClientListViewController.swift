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
import WireSyncEngine
import Cartography
import WireExtensionComponents

private let zmLog = ZMSLog(tag: "UI")

@objcMembers class ClientListViewController: UIViewController,
                                UITableViewDelegate,
                                UITableViewDataSource,
                                ZMClientUpdateObserver,
                                ClientColorVariantProtocol {
    var clientsTableView: UITableView?
    let topSeparator = OverflowSeparatorView()
    weak var delegate: ClientListViewControllerDelegate?

    var variant: ColorSchemeVariant? {
        didSet {
            setColor(for: variant)
        }
    }

    override open var showLoadingView: Bool {
        set {
            if let navigationController = self.navigationController {
                navigationController.showLoadingView = newValue

                // dismiss the loading view that toggled before navigationController is created
                if !newValue && super.showLoadingView {
                    super.showLoadingView = newValue
                }
            } else {
                super.showLoadingView = newValue
            }
        }
        get{
            if let navigationController = self.navigationController {
                return navigationController.showLoadingView
            } else {
                return super.showLoadingView
            }
        }
    }

    var editingList: Bool = false {
        didSet {
            guard clients.count > 0 else {
                self.navigationItem.rightBarButtonItem = nil
                self.navigationItem.setHidesBackButton(false, animated: true)
                return
            }

            createRightBarButtonItem()

            self.navigationItem.setHidesBackButton(self.editingList, animated: true)

            self.clientsTableView?.setEditing(self.editingList, animated: true)
        }
    }

    var clients: [UserClient] = [] {
        didSet {
            self.sortedClients = self.clients.filter(clientFilter).sorted(by: clientSorter)
            self.clientsTableView?.reloadData();

            if clients.count > 0 {
                createRightBarButtonItem()
            } else {
                self.navigationItem.rightBarButtonItem = nil
            }
        }
    }

    private let clientSorter: (UserClient, UserClient) -> Bool
    private let clientFilter: (UserClient) -> Bool

    var sortedClients: [UserClient] = []
    
    let selfClient: UserClient?
    let detailedView: Bool
    var credentials: ZMEmailCredentials?
    var clientsObserverToken: Any?
    var userObserverToken : NSObjectProtocol?

    var leftBarButtonItem: UIBarButtonItem? {
        if self.isIPadRegular() {
            return UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(ClientListViewController.backPressed(_:)))
        }

        if let rootViewController = self.navigationController?.viewControllers.first,
            self.isEqual(rootViewController) {
            return UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(ClientListViewController.backPressed(_:)))
        }

        return nil
    }

    required init(clientsList: [UserClient]?,
                  selfClient: UserClient? = ZMUserSession.shared()?.selfUserClient(),
                  credentials: ZMEmailCredentials? = .none,
                  detailedView: Bool = false,
                  showTemporary: Bool = true,
                  variant: ColorSchemeVariant? = .none) {
        self.selfClient = selfClient
        self.detailedView = detailedView
        self.credentials = credentials
        defer {
            self.variant = variant
        }

        clientFilter = { $0 != selfClient && (showTemporary || !$0.isTemporary) }
        clientSorter = {
            guard let leftDate = $0.activationDate, let rightDate = $1.activationDate else { return false }
            return leftDate.compare(rightDate) == .orderedDescending
        }

        super.init(nibName: nil, bundle: nil)
        self.title = "registration.devices.title".localized.uppercased()
        self.edgesForExtendedLayout = []

        self.initalizeProperties(clientsList ?? Array(ZMUser.selfUser().clients.filter { !$0.isSelfClient() } ))
        self.clientsObserverToken = ZMUserSession.shared()?.add(self)
        if let user = ZMUser.selfUser(), let session = ZMUserSession.shared() {
            self.userObserverToken = UserChangeInfo.add(observer: self, for: user, userSession: session)
        }
        
        if clientsList == nil {
            if clients.isEmpty {
                self.showLoadingView = true
            }
            ZMUserSession.shared()?.fetchAllClients()
        }
    }
    
    required override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        fatalError("init(nibNameOrNil:nibBundleOrNil:) has not been implemented")
    }
    
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    fileprivate func initalizeProperties(_ clientsList: [UserClient]) {
        self.clients = clientsList
        self.editingList = false
    }
    
    override var supportedInterfaceOrientations : UIInterfaceOrientationMask {
        return [.portrait]
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        self.createTableView()
        self.view.addSubview(self.topSeparator)
        self.createConstraints()

        self.navigationItem.leftBarButtonItem = leftBarButtonItem
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.clientsTableView?.reloadData()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        showLoadingView = false
    }

    func openDetailsOfClient(_ client: UserClient) {
        if let navigationController = self.navigationController {
            let clientViewController = SettingsClientViewController(userClient: client, credentials: self.credentials, variant: variant)
            clientViewController.view.backgroundColor = self.view.backgroundColor
            navigationController.pushViewController(clientViewController, animated: true)
        }
    }

    fileprivate func createTableView() {
        let tableView = UITableView(frame: CGRect.zero, style: .grouped);
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.delegate = self
        tableView.dataSource = self
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedRowHeight = 80
        tableView.register(ClientTableViewCell.self, forCellReuseIdentifier: ClientTableViewCell.zm_reuseIdentifier)
        tableView.isEditing = self.editingList
        tableView.backgroundColor = UIColor.clear
        tableView.separatorColor = separatorColor
        self.view.addSubview(tableView)
        self.clientsTableView = tableView
    }
    
    fileprivate func createConstraints() {
        if let clientsTableView = self.clientsTableView {
            constrain(self.view, clientsTableView, self.topSeparator) { selfView, clientsTableView, topSeparator in
                clientsTableView.edges == selfView.edges
                
                topSeparator.left == clientsTableView.left
                topSeparator.right == clientsTableView.right
                topSeparator.top == clientsTableView.top
            }
        }
    }
    
    fileprivate func convertSection(_ section: Int) -> Int {
        if let _ = self.selfClient {
            return section
        }
        else {
            return section + 1
        }
    }
    
    // MARK: - Actions
    
    @objc func startEditing(_ sender: AnyObject!) {
        self.editingList = true
    }
    
    @objc func endEditing(_ sender: AnyObject!) {
        self.editingList = false
    }
    
    @objc func backPressed(_ sender: AnyObject!) {
        self.navigationController?.presentingViewController?.dismiss(animated: true, completion: nil)
    }

    func deleteUserClient(_ userClient: UserClient, credentials: ZMEmailCredentials) {
        showLoadingView = true
        ZMUserSession.shared()?.delete([userClient], with: credentials);

        delegate?.finishedDeleting(self)
    }

    func displayError(_ message: String) {
        let alert = UIAlertController(title: "", message: message, preferredStyle: .alert)
        let action = UIAlertAction(title: NSLocalizedString("general.ok", comment: ""), style: .default) { [unowned alert] (_) -> Void in
            alert.dismiss(animated: true, completion: .none)
        }
        alert.addAction(action)
        self.present(alert, animated: true, completion: .none)
    }

    // MARK: - ZMClientRegistrationObserver

    func finishedFetching(_ userClients: [UserClient]!) {
        self.showLoadingView = false
        
        self.clients = userClients.filter { !$0.isSelfClient() }
    }
    
    func failedToFetchClientsWithError(_ error: Error!) {
        self.showLoadingView = false
        
        zmLog.error("Clients request failed: \(error)")
        
        self.displayError(NSLocalizedString("error.user.unkown_error", comment: ""))
    }
    
    func finishedDeleting(_ remainingClients: [UserClient]!) {
        self.showLoadingView = false

        self.clients = remainingClients

        Analytics.shared().tagDeleteDevice()

        self.editingList = false
    }
    
    func failedToDeleteClientsWithError(_ error: Error!) {
        self.showLoadingView = false
        self.credentials = .none
        
        self.displayError(NSLocalizedString("self.settings.account_details.remove_device.password.error", comment: ""))
    }
    
    // MARK: - UITableViewDataSource & UITableViewDelegate
    
    func numberOfSections(in tableView: UITableView) -> Int {
        if let _ = self.selfClient , self.sortedClients.count > 0 {
            return 2
        }
        else {
            return 1
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
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
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
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
    
    func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        switch self.convertSection(section) {
            case 0:
                return nil
            case 1:
                return NSLocalizedString("registration.devices.active_list_subtitle", comment:"")
            default:
                return nil
        }
    }
    
    func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        if let headerFooterView = view as? UITableViewHeaderFooterView {
            headerFooterView.textLabel?.textColor = headerFooterViewTextColor
        }
    }
    
    func tableView(_ tableView: UITableView, willDisplayFooterView view: UIView, forSection section: Int) {
        if let headerFooterView = view as? UITableViewHeaderFooterView {
            headerFooterView.textLabel?.textColor = headerFooterViewTextColor
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let cell = tableView.dequeueReusableCell(withIdentifier: ClientTableViewCell.zm_reuseIdentifier, for: indexPath) as? ClientTableViewCell {
            cell.selectionStyle = .none
            cell.accessoryType = self.detailedView ? .disclosureIndicator : .none
            cell.showVerified = self.detailedView
            cell.variant = variant
            
            switch self.convertSection((indexPath as NSIndexPath).section) {
            case 0:
                cell.userClient = self.selfClient
                cell.wr_editable = false
                cell.showVerified = false
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
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        switch self.convertSection((indexPath as NSIndexPath).section) {
        case 1:
            
            let userClient = self.sortedClients[indexPath.row]
            
            if let credentials = self.credentials {
                self.deleteUserClient(userClient, credentials: credentials)
            }
            else {
                let passwordRequest = RequestPasswordViewController.requestPasswordController() { (result: Either<String, NSError>) -> () in
                    switch result {
                    case .left(let passwordString):
                        if let email = ZMUser.selfUser()?.emailAddress {
                            let newCredentials = ZMEmailCredentials(email: email, password: passwordString)
                            self.credentials = newCredentials
                            self.deleteUserClient(userClient, credentials: newCredentials)
                        } else {
                            if DeveloperMenuState.developerMenuEnabled() {
                                DebugAlert.showGeneric(message: "No email set!")
                            }
                        }
                    case .right(let error):
                        zmLog.error("Error: \(error)")
                    }
                }
                self.present(passwordRequest, animated: true, completion: .none)
            }
        default: break
        }
        
    }
    
    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCellEditingStyle {
        switch self.convertSection((indexPath as NSIndexPath).section) {
        case 0:
            return .none
        case 1:
            return .delete
        default:
            return .none
        }
        
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        cell.separatorInset = UIEdgeInsets.zero
        cell.layoutMargins = UIEdgeInsets.zero
        cell.preservesSuperviewLayoutMargins = false
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if !self.detailedView {
            return
        }
        switch self.convertSection((indexPath as NSIndexPath).section) {
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
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        self.topSeparator.scrollViewDidScroll(scrollView: scrollView)
    }

    func createRightBarButtonItem() {
        if (self.editingList) {
            self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "general.done".localized.localizedUppercase, style: .plain, target: self, action: #selector(ClientListViewController.endEditing(_:)))

            self.navigationItem.setLeftBarButton(nil, animated: true)
        } else {
            self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "general.edit".localized.localizedUppercase, style: .plain, target: self, action: #selector(ClientListViewController.startEditing(_:)))

            self.navigationItem.setLeftBarButton(leftBarButtonItem, animated: true)
        }

        self.navigationItem.rightBarButtonItem?.tintColor = UIColor.accent()
    }
}

extension ClientListViewController : ZMUserObserver {
    
    func userDidChange(_ note: UserChangeInfo) {
        if (note.clientsChanged || note.trustLevelChanged) {
            guard let selfClient = ZMUser.selfUser().selfClient() else { return }
            var clients = ZMUser.selfUser().clients ?? Set()
            clients.remove(selfClient)
            self.clients = Array(clients)
        }
    }
    
}

fileprivate extension UserClient {

    var isTemporary: Bool {
        guard let type = type else { return false }
        return type == "temporary"
    }

}
