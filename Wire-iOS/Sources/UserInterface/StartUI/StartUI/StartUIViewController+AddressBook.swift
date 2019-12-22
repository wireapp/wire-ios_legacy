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

private let zmLog = ZMSLog(tag: "StartUIViewController")

final class StartUIViewController: UIViewController {
    static let StartUIInitiallyShowsKeyboardConversationThreshold = 10
    
    weak var delegate: StartUIDelegate?
    private(set) var scrollView: UIScrollView?

    let searchHeader: SearchHeaderViewController = SearchHeaderViewController(userSelection: UserSelection(), variant: .dark)
    
    let groupSelector: SearchGroupSelector = {
        let searchGroupSelector = SearchGroupSelector(style: .dark)
        searchGroupSelector.translatesAutoresizingMaskIntoConstraints = false
        searchGroupSelector.backgroundColor = UIColor.from(scheme: .searchBarBackground, variant: .dark)

        return searchGroupSelector
    }()
    
    let searchResults: SearchResultsViewController = {
        let viewController = SearchResultsViewController(userSelection: UserSelection(), isAddingParticipants: false, shouldIncludeGuests: true)
        viewController.mode = .list
        
        return viewController
    }()
    
    private var addressBookUploadLogicHandled = false
    var addressBookHelper: AddressBookHelperProtocol? {
        return AddressBookHelper.sharedHelper()
    }
    private var quickActionsBar: StartUIInviteActionBar?

    let profilePresenter: ProfilePresenter = ProfilePresenter()
    private let emptyResultView: EmptySearchResultsView = EmptySearchResultsView(variant: .dark, isSelfUserAdmin: ZMUser.selfUser().canManageTeam)

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Overloaded methods
    override func loadView() {
        view = StartUIView(frame: CGRect.zero)
    }
    
    convenience init() {
        self.init(nibName: nil, bundle: nil)
        
        setupViews()
    }
    
    func setupViews() {
        let team = ZMUser.selfUser().team
        
        emptyResultView.delegate = self
        
        title = (team != nil ? team?.name : ZMUser.selfUser().displayName)?.localizedUppercase
        searchHeader.delegate = self
        searchHeader.allowsMultipleSelection = false
        searchHeader.view.backgroundColor = UIColor.from(scheme: .searchBarBackground, variant: .dark)
        addChildViewController(searchHeaderViewController)
        view.addSubview(searchHeaderViewController.view)
        searchHeaderViewController.didMove(toParent: self)
        
        groupSelector.onGroupSelected = { [weak self] group in
            if SearchGroupServices == group {
                // Remove selected users when switching to services tab to avoid the user confusion: users in the field are
                // not going to be added to the new conversation with the bot.
                self?.searchHeaderViewController.clearInput()
            }
            
            self?.searchResultsViewController.searchGroup = group
            self?.performSearch()
        }
        
        if showsGroupSelector() {
            view.addSubview(groupSelector)
        }
        
        searchResultsViewController.delegate = self
        addChildViewController(searchResultsViewController)
        view.addSubview(searchResultsViewController.view)
        searchResultsViewController.didMove(toParent: self)
        searchResultsViewController.searchResultsView.emptyResultView = emptyResultView
        searchResultsViewController.searchResultsView.collectionView.accessibilityIdentifier = "search.list"
        
        quickActionsBar = StartUIInviteActionBar()
        quickActionsBar.inviteButton.addTarget(self, action: #selector(inviteMoreButtonTapped(_:)), for: .touchUpInside)
        
        view.backgroundColor = UIColor.clear
        
        createConstraints()
        updateActionBar()
        searchResultsViewController.searchContactList()
        
        let closeButton = UIBarButtonItem(icon: WRStyleKitIconCross, style: UIBarButtonItem.Style.plain, target: self, action: #selector(onDismissPressed))
        
        closeButton.accessibilityLabel = NSLocalizedString("general.close", comment: "")
        closeButton.accessibilityIdentifier = "close"
        
        navigationItem.rightBarButtonItem = closeButton
        view.accessibilityViewIsModal = true
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        UIApplication.shared().wr_updateStatusBarForCurrentController(animated: animated)
        handleUploadAddressBookLogicIfNeeded()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        navigationController?.navigationBar.barTintColor = UIColor.clear
        navigationController?.navigationBar.isTranslucent = true
        navigationController?.navigationBar.tintColor = UIColor.from(scheme: .textForeground, variant: .dark)
        navigationController?.navigationBar.titleTextAttributes = DefaultNavigationBar.titleTextAttributes(for: .dark)
        
        UIApplication.shared().wr_updateStatusBarForCurrentController(animated: animated)
    }
    
    func preferredStatusBarStyle() -> UIStatusBarStyle {
        return .lightContent
    }
    
    func showKeyboardIfNeeded() {
        let conversationCount = ZMConversationList.conversations(inUserSession: ZMUserSession.shared()).count
        if conversationCount > StartUIViewController.StartUIInitiallyShowsKeyboardConversationThreshold {
            searchHeaderViewController.tokenField.becomeFirstResponder()
        }
        
    }
    
    func updateActionBar() {
        if searchHeaderViewController.query.length != 0 || ZMUser.selfUser.hasTeam {
            searchResultsViewController.searchResultsView.accessoryView = nil
        } else {
            searchResultsViewController.searchResultsView.accessoryView = quickActionsBar
        }
        
        view.setNeedsLayout()
    }
    
    func onDismissPressed() {
        searchHeader.tokenField.resignFirstResponder()
        navigationController?.dismiss(animated: true)
    }
    
    override func accessibilityPerformEscape() -> Bool {
        onDismissPressed()
        return true
    }
    
    // MARK: - Instance methods
    @objc func performSearch() {
        let searchString = searchHeader.query
        zmLog.info("Search for %@", searchString)
        
        if groupSelector.group == SearchGroupPeople {
            if searchString.count == 0 {
                searchResultsViewController.mode = SearchResultsViewControllerModeList
                searchResultsViewController.searchContactList()
            } else {
                searchResultsViewController.mode = SearchResultsViewControllerModeSearch
                searchResultsViewController.searchForUsers(withQuery: searchString)
            }
        } else {
            searchResultsViewController.searchForServices(withQuery: searchString)
        }
        
        emptyResultView.updateStatusWithSearching(forServices: groupSelector.group == SearchGroupServices, hasFilter: searchString.count != 0)
    }
    
    // MARK: - Action bar
    func inviteMoreButtonTapped(_ sender: UIButton?) {
        let inviteContactsViewController = InviteContactsViewController()
        inviteContactsViewController.delegate = self
        navigationController.pushViewController(inviteContactsViewController, animated: true)
    }
    
}


extension  StartUIViewController: SearchHeaderViewControllerDelegate {
    func searchHeaderViewController(_ searchHeaderViewController : SearchHeaderViewController, updatedSearchQuery query: String) {
        searchResultsViewController.cancelPreviousSearch()
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(performSearch), object: nil)
        perform(#selector(performSearch), with: nil, afterDelay: 0.2)
    }
    
    func searchHeaderViewControllerDidConfirmAction(_ searchHeaderViewController : SearchHeaderViewController) {
        searchHeaderViewController.resetQuery()
    }
}


extension StartUIViewController {

    /// init method for injecting mock addressBookHelper
    ///
    /// - Parameter addressBookHelper: an object conforms AddressBookHelperProtocol 
    convenience init(addressBookHelper: AddressBookHelperProtocol) {
        self.init()

        self.addressBookHelper = addressBookHelper
    }

    @objc
    func handleUploadAddressBookLogicIfNeeded() {
        guard !addressBookUploadLogicHandled else { return }

        addressBookUploadLogicHandled = true

        // We should not even try to access address book when in a team
        guard !ZMUser.selfUser().hasTeam else { return }

        if addressBookHelper.isAddressBookAccessGranted {
            // Re-check if we need to start AB search
            addressBookHelper.startRemoteSearch(true)
        } else if addressBookHelper.isAddressBookAccessUnknown {
            self.addressBookHelper.requestPermissions({ success in
                if success {
                    DispatchQueue.main.async(execute: {
                        self.addressBookHelper.startRemoteSearch(true)
                    })
                }
            })
        }
    }
}

extension StartUIViewController: ContactsViewControllerDelegate {
    
    public func contactsViewControllerDidCancel(_ controller: ContactsViewController) {
        dismiss(animated: true)
    }
    
    public func contactsViewControllerDidNotShareContacts(_ controller: ContactsViewController) {
        dismiss(animated: true) {
            UIApplication.shared.topmostViewController()?.presentInviteActivityViewController(with: self.quickActionsBar)
        }
    }
    
}
