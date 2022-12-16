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
import WireCommonComponents

private let zmLog = ZMSLog(tag: "UI")

final class ClientListViewController: UIViewController,
                                UITableViewDelegate,
                                UITableViewDataSource,
                                ClientUpdateObserver,
                                ClientColorVariantProtocol,
                                SpinnerCapable {
    // MARK: SpinnerCapable
    var dismissSpinner: SpinnerCompletion?

    var removalObserver: ClientRemovalObserver?

    var clientsTableView: UITableView?
    let topSeparator = OverflowSeparatorView()
    weak var delegate: ClientListViewControllerDelegate?

    var editingList: Bool = false {
        didSet {
            guard !clients.isEmpty else {
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
            self.clientsTableView?.reloadData()

            if !clients.isEmpty {
                createRightBarButtonItem()
            } else {
                self.editingList = false
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
    var userObserverToken: NSObjectProtocol?

    var leftBarButtonItem: UIBarButtonItem? {
        if self.isIPadRegular() {
            return UIBarButtonItem.createNavigationBarButtonDoneItem(
                systemImage: true,
                target: self,
                action: #selector(ClientListViewController.backPressed(_:)))
        }

        if let rootViewController = self.navigationController?.viewControllers.first,
            self.isEqual(rootViewController) {
            return UIBarButtonItem.createNavigationBarButtonDoneItem(
                systemImage: true,
                target: self,
                action: #selector(ClientListViewController.backPressed(_:)))
        }

        return nil
    }

    required init(clientsList: [UserClient]?,
                  selfClient: UserClient? = ZMUserSession.shared()?.selfUserClient,
                  credentials: ZMEmailCredentials? = .none,
                  detailedView: Bool = false,
                  showTemporary: Bool = true,
                  showLegalHold: Bool = true) {
        self.selfClient = selfClient
        self.detailedView = detailedView
        self.credentials = credentials

        clientFilter = {
            $0 != selfClient && (showTemporary || $0.type != .temporary) && (showLegalHold || $0.type != .legalHold)
        }

        clientSorter = {
            guard let leftDate = $0.activationDate, let rightDate = $1.activationDate else { return false }
            return leftDate.compare(rightDate) == .orderedDescending
        }

        super.init(nibName: nil, bundle: nil)
        setupControllerTitle()

        self.initalizeProperties(clientsList ?? Array(ZMUser.selfUser().clients.filter { !$0.isSelfClient() }))
        self.clientsObserverToken = ZMUserSession.shared()?.addClientUpdateObserver(self)
        if let user = ZMUser.selfUser(), let session = ZMUserSession.shared() {
            self.userObserverToken = UserChangeInfo.add(observer: self, for: user, in: session)
        }

        if clientsList == nil {
            if clients.isEmpty {
                (navigationController as? SpinnerCapableViewController ?? self).isLoadingViewVisible = true
            }
            ZMUserSession.shared()?.fetchAllClients()
        }
    }

    @available(*, unavailable)
    required override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        fatalError("init(nibNameOrNil:nibBundleOrNil:) has not been implemented")
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    fileprivate func initalizeProperties(_ clientsList: [UserClient]) {
        self.clients = clientsList.filter { !$0.isSelfClient() }
        self.editingList = false
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return [.portrait]
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        self.createTableView()
        self.view.addSubview(self.topSeparator)
        self.createConstraints()

        self.navigationItem.leftBarButtonItem = leftBarButtonItem
        self.navigationItem.backBarButtonItem?.accessibilityLabel = L10n.Accessibility.ClientsList.BackButton.description
        setColor()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.clientsTableView?.reloadData()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        dismissLoadingView()

        // Prevent more then one removalObserver in self and SettingsClientViewController
        removalObserver = nil
    }

    private func dismissLoadingView() {
        (navigationController as? SpinnerCapableViewController)?.isLoadingViewVisible = false
        isLoadingViewVisible = false
    }

    func openDetailsOfClient(_ client: UserClient) {
        if let navigationController = self.navigationController {
            let clientViewController = SettingsClientViewController(userClient: client, credentials: self.credentials)
            clientViewController.view.backgroundColor = SemanticColors.View.backgroundDefault
            navigationController.pushViewController(clientViewController, animated: true)
        }
    }

    fileprivate func createTableView() {
        let tableView = UITableView(frame: CGRect.zero, style: .grouped)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.delegate = self
        tableView.dataSource = self
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 80
        tableView.register(ClientTableViewCell.self, forCellReuseIdentifier: ClientTableViewCell.zm_reuseIdentifier)
        tableView.isEditing = self.editingList
        tableView.backgroundColor = SemanticColors.View.backgroundDefault
        tableView.separatorStyle = .none
        self.view.addSubview(tableView)
        self.clientsTableView = tableView
    }

    fileprivate func createConstraints() {
        guard let clientsTableView = clientsTableView else {
            return
        }

        clientsTableView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            clientsTableView.leadingAnchor.constraint(equalTo: view.safeLeadingAnchor),
            clientsTableView.topAnchor.constraint(equalTo: view.safeTopAnchor),
            clientsTableView.trailingAnchor.constraint(equalTo: view.safeTrailingAnchor),
            clientsTableView.bottomAnchor.constraint(equalTo: view.safeBottomAnchor)
        ])
    }

    fileprivate func convertSection(_ section: Int) -> Int {
        if self.selfClient != nil {
            return section
        } else {
            return section + 1
        }
    }

    // MARK: - Actions

    @objc func startEditing(_ sender: AnyObject!) {
        self.editingList = true
    }

    @objc private func endEditing(_ sender: AnyObject!) {
        self.editingList = false
    }

    @objc func backPressed(_ sender: AnyObject!) {
        self.navigationController?.presentingViewController?.dismiss(animated: true, completion: nil)
    }

    func deleteUserClient(_ userClient: UserClient,
                          credentials: ZMEmailCredentials?) {
        removalObserver = nil

        removalObserver = ClientRemovalObserver(userClientToDelete: userClient,
                                                delegate: self,
                                                credentials: credentials)

        removalObserver?.startRemoval()

        delegate?.finishedDeleting(self)
    }

    // MARK: - ClientRegistrationObserver

    func finishedFetching(_ userClients: [UserClient]) {
        dismissLoadingView()

        self.clients = userClients.filter { !$0.isSelfClient() }
    }

    func failedToFetchClients(_ error: Error) {
        dismissLoadingView()

        zmLog.error("Clients request failed: \(error.localizedDescription)")

        presentAlertWithOKButton(message: "error.user.unkown_error".localized)
    }

    func finishedDeleting(_ remainingClients: [UserClient]) {
        clients = remainingClients

        editingList = false
    }

    func failedToDeleteClients(_ error: Error) {
        // no-op
    }

    // MARK: - UITableViewDataSource & UITableViewDelegate

    func numberOfSections(in tableView: UITableView) -> Int {
        if self.selfClient != nil, self.sortedClients.count > 0 {
            return 2
        } else {
            return 1
        }
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch self.convertSection(section) {
        case 0:
            if self.selfClient != nil {
                return 1
            } else {
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
            if self.selfClient != nil {
                return NSLocalizedString("registration.devices.current_list_header", comment: "")
            } else {
                return nil
            }
        case 1:
            return NSLocalizedString("registration.devices.active_list_header", comment: "")
        default:
            return nil
        }
    }

    func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        switch self.convertSection(section) {
        case 0:
            return nil
        case 1:
            return NSLocalizedString("registration.devices.active_list_subtitle", comment: "")
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
            cell.showDisclosureIndicator()
            cell.showVerified = self.detailedView

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

            cell.accessibilityTraits = .button
            cell.accessibilityHint = L10n.Accessibility.ClientsList.DeviceDetails.hint

            return cell
        } else {
            return UITableViewCell()
        }
    }

    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        switch self.convertSection((indexPath as NSIndexPath).section) {
        case 1:

            let userClient = self.sortedClients[indexPath.row]

            self.deleteUserClient(userClient, credentials: credentials)
        default: break
        }

    }

    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        switch self.convertSection((indexPath as NSIndexPath).section) {
        case 0:
            return .none
        case 1:
            return sortedClients[indexPath.row].type == .legalHold ? .none : .delete
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

        case 1:
            self.openDetailsOfClient(self.sortedClients[indexPath.row])

        default:
            break
        }

    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        self.topSeparator.scrollViewDidScroll(scrollView: scrollView)
    }

    func createRightBarButtonItem() {
        if self.editingList {
            self.navigationItem.rightBarButtonItem = UIBarButtonItem.createNavigationBarButtonDoneItem(
                systemImage: false,
                target: self,
                action: #selector(ClientListViewController.endEditing(_:)))

            self.navigationItem.setLeftBarButton(nil, animated: true)
        } else {
            self.navigationItem.rightBarButtonItem = UIBarButtonItem.createNavigationBarEditItem(
                target: self,
                action: #selector(ClientListViewController.startEditing(_:)))

            self.navigationItem.setLeftBarButton(leftBarButtonItem, animated: true)
        }
    }

    private func setupControllerTitle() {
        navigationItem.setupNavigationBarTitle(title: L10n.Localizable.Registration.Devices.title.capitalized)
    }

}

// MARK: - ClientRemovalObserverDelegate

extension ClientListViewController: ClientRemovalObserverDelegate {
    func setIsLoadingViewVisible(_ clientRemovalObserver: ClientRemovalObserver, isVisible: Bool) {
        guard removalObserver == clientRemovalObserver else {
            return
        }

        isLoadingViewVisible = isVisible
    }

    func present(_ clientRemovalObserver: ClientRemovalObserver, viewControllerToPresent: UIViewController) {
        guard removalObserver == clientRemovalObserver else {
            return
        }

        present(viewControllerToPresent, animated: true)
    }
}

extension ClientListViewController: ZMUserObserver {

    func userDidChange(_ note: UserChangeInfo) {
        if note.clientsChanged || note.trustLevelChanged {
            guard let selfClient = ZMUser.selfUser().selfClient() else { return }
            var clients = ZMUser.selfUser().clients
            clients.remove(selfClient)
            self.clients = Array(clients)
        }
    }

}
