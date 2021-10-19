//
// Wire
// Copyright (C) 2019 Wire Swiss GmbH
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

private let zmLog = ZMSLog(tag: "StartUIViewController")

final class StartUIViewController: UIViewController, SpinnerCapable {
    var dismissSpinner: SpinnerCompletion?

    static let InitiallyShowsKeyboardConversationThreshold = 10

    weak var delegate: StartUIDelegate?

    let searchHeaderViewController: SearchHeaderViewController = SearchHeaderViewController(userSelection: UserSelection(), variant: .dark)

    let groupSelector: SearchGroupSelector = SearchGroupSelector(style: .dark)

    let searchResultsViewController: SearchResultsViewController

    var addressBookUploadLogicHandled = false

    var addressBookHelperType: AddressBookHelperProtocol.Type

    var addressBookHelper: AddressBookHelperProtocol {
        return addressBookHelperType.sharedHelper
    }

    let isFederationEnabled: Bool

    let quickActionsBar: StartUIInviteActionBar = StartUIInviteActionBar()

    let profilePresenter: ProfilePresenter = ProfilePresenter()
    private var emptyResultView: EmptySearchResultsView!

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /// init method for injecting mock addressBookHelper
    ///
    /// - Parameter addressBookHelperType: a class type conforms AddressBookHelperProtocol
    init(addressBookHelperType: AddressBookHelperProtocol.Type = AddressBookHelper.self,
         isFederationEnabled: Bool = Settings.shared.federationEnabled || AutomationHelper.sharedHelper.enableFederation) {
        self.isFederationEnabled = isFederationEnabled
        self.addressBookHelperType = addressBookHelperType
        self.searchResultsViewController = SearchResultsViewController(userSelection: UserSelection(),
                                                                       isAddingParticipants: false,
                                                                       shouldIncludeGuests: true,
                                                                       isFederationEnabled: isFederationEnabled)

        super.init(nibName: nil, bundle: nil)

        configGroupSelector()
        setupViews()
    }

    var searchHeader: SearchHeaderViewController {
        return self.searchHeaderViewController
    }

    var searchResults: SearchResultsViewController {
        return self.searchResultsViewController
    }

    var selfUser: UserType {
        return SelfUser.current
    }

    // MARK: - Overloaded methods
    override func loadView() {
        view = StartUIView(frame: CGRect.zero)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        navigationController?.navigationBar.barTintColor = UIColor.clear
        navigationController?.navigationBar.isTranslucent = true
        navigationController?.navigationBar.tintColor = UIColor.from(scheme: .textForeground, variant: .dark)
        navigationController?.navigationBar.titleTextAttributes = DefaultNavigationBar.titleTextAttributes(for: .dark)

    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }

    private func configGroupSelector() {
        groupSelector.translatesAutoresizingMaskIntoConstraints = false
        groupSelector.backgroundColor = UIColor.from(scheme: .searchBarBackground, variant: .dark)
    }

    func setupViews() {
        configGroupSelector()
        emptyResultView = EmptySearchResultsView(variant: .dark,
                                                 isSelfUserAdmin: selfUser.canManageTeam,
                                                 isFederationEnabled: isFederationEnabled)

        emptyResultView.delegate = self

        searchResultsViewController.mode = .list
        searchResultsViewController.searchResultsView.emptyResultView = self.emptyResultView
        searchResultsViewController.searchResultsView.collectionView.accessibilityIdentifier = "search.list"

        if let team = (selfUser as? ZMUser)?.team {
            title = team.name?.uppercased()
        } else {
            title = selfUser.name?.uppercased()
        }

        searchHeader.delegate = self
        searchHeader.allowsMultipleSelection = false
        searchHeader.view.backgroundColor = UIColor.from(scheme: .searchBarBackground, variant: .dark)

        addToSelf(searchHeader)

        groupSelector.onGroupSelected = { [weak self] group in
            if .services == group {
                // Remove selected users when switching to services tab to avoid the user confusion: users in the field are
                // not going to be added to the new conversation with the bot.
                self?.searchHeader.clearInput()
            }

            self?.searchResults.searchGroup = group
            self?.performSearch()
        }

        if showsGroupSelector {
            view.addSubview(groupSelector)
        }

        searchResults.delegate = self
        addToSelf(searchResults)
        searchResults.searchResultsView.emptyResultView = emptyResultView
        searchResults.searchResultsView.collectionView.accessibilityIdentifier = "search.list"

        quickActionsBar.inviteButton.addTarget(self, action: #selector(inviteMoreButtonTapped(_:)), for: .touchUpInside)

        view.backgroundColor = UIColor.clear

        createConstraints()
        updateActionBar()
        searchResults.searchContactList()

        let closeButton = UIBarButtonItem(icon: .cross, style: UIBarButtonItem.Style.plain, target: self, action: #selector(onDismissPressed))

        closeButton.accessibilityLabel = "general.close".localized
        closeButton.accessibilityIdentifier = "close"

        navigationItem.rightBarButtonItem = closeButton
        view.accessibilityViewIsModal = true
    }

    func showKeyboardIfNeeded() {
        let conversationCount = ZMConversationList.conversations(inUserSession: ZMUserSession.shared()!).count /// TODO: unwrap
        if conversationCount > StartUIViewController.InitiallyShowsKeyboardConversationThreshold {
            _ = searchHeader.tokenField.becomeFirstResponder()
        }

    }

    func updateActionBar() {
        if !searchHeader.query.isEmpty || (selfUser as? ZMUser)?.hasTeam == true {
            searchResults.searchResultsView.accessoryView = nil
        } else {
            searchResults.searchResultsView.accessoryView = quickActionsBar
        }

        view.setNeedsLayout()
    }

    @objc
    private func onDismissPressed() {
        _ = searchHeader.tokenField.resignFirstResponder()
        navigationController?.dismiss(animated: true)
    }

    override func accessibilityPerformEscape() -> Bool {
        onDismissPressed()
        return true
    }

    // MARK: - Instance methods
    @objc
    func performSearch() {
        let searchString = searchHeader.query
        zmLog.info("Search for \(searchString)")

        if groupSelector.group == .people {
            if searchString.count == 0 {
                searchResults.mode = .list
                searchResults.searchContactList()
            } else {
                searchResults.mode = .search
                searchResults.searchForUsers(withQuery: searchString)
            }
        } else {
            searchResults.searchForServices(withQuery: searchString)
        }
        emptyResultView.updateStatus(searchingForServices: groupSelector.group == .services,
                                     hasFilter: !searchString.isEmpty)
    }

    // MARK: - Action bar

    @objc
    func inviteMoreButtonTapped(_ sender: UIButton?) {
        if needsAddressBookPermission {
            presentShareContactsViewController()
        } else {
            navigationController?.pushViewController(ContactsViewController(), animated: true)
        }
    }

}

extension StartUIViewController: SearchHeaderViewControllerDelegate {
    func searchHeaderViewController(_ searchHeaderViewController: SearchHeaderViewController, updatedSearchQuery query: String) {
        searchResults.cancelPreviousSearch()
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(performSearch), object: nil)
        perform(#selector(performSearch), with: nil, afterDelay: 0.2)
    }

    func searchHeaderViewControllerDidConfirmAction(_ searchHeaderViewController: SearchHeaderViewController) {
        searchHeaderViewController.resetQuery()
    }
}
