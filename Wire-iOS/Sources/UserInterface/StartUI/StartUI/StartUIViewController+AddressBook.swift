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

private let StartUIInitiallyShowsKeyboardConversationThreshold = 10
private var ZM_UNUSED = "UI"

final class StartUIViewController: UIViewController {
    weak var delegate: StartUIDelegate?
    private(set) var scrollView: UIScrollView?

    private var searchHeaderViewController: SearchHeaderViewController?
    private var groupSelector: SearchGroupSelector?
    private var searchResultsViewController: SearchResultsViewController?
    private var addressBookUploadLogicHandled = false
    private weak var addressBookHelper: AddressBookHelperProtocol?
    private var quickActionsBar: StartUIInviteActionBar?

    func showKeyboardIfNeeded() {
    }
    
    private init() {
    }
    
    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Overloaded methods
    func loadView() {
        view = StartUIView(frame: CGRect.zero)
    }
    
    init() {
        super.init()
        
        addressBookHelper = AddressBookHelper.shared()
        
        setupViews()
    }
    
    func setupViews() {
        let team = ZMUser.selfUser.team
        
        profilePresenter = ProfilePresenter()
        
        emptyResultView = EmptySearchResultsView(variant: ColorSchemeVariantDark, isSelfUserAdmin: ZMUser.selfUser().canManageTeam())
        emptyResultView.delegate = self
        
        searchHeaderViewController = SearchHeaderViewController(userSelection: UserSelection(), variant: ColorSchemeVariantDark)
        title = (team != nil ? team?.name : ZMUser.selfUser.displayName)?.localizedUppercase
        searchHeaderViewController.delegate = self
        searchHeaderViewController.allowsMultipleSelection = false
        searchHeaderViewController.view.backgroundColor = UIColor.wr_color(fromColorScheme: ColorSchemeColorSearchBarBackground, variant: ColorSchemeVariantDark)
        addChildViewController(searchHeaderViewController)
        view.addSubview(searchHeaderViewController.view)
        searchHeaderViewController.didMove(toParent: self)
        
        groupSelector = SearchGroupSelector(style: ColorSchemeVariantDark)
        groupSelector.translatesAutoresizingMaskIntoConstraints = false
        groupSelector.backgroundColor = UIColor.wr_color(fromColorScheme: ColorSchemeColorSearchBarBackground, variant: ColorSchemeVariantDark)
        ZM_WEAK(self)
        groupSelector.onGroupSelected = { group in
            ZM_STRONG(self)
            if SearchGroupServices == group {
                // Remove selected users when switching to services tab to avoid the user confusion: users in the field are
                // not going to be added to the new conversation with the bot.
                self.searchHeaderViewController.clearInput()
            }
            
            self.searchResultsViewController.searchGroup = group
            self.performSearch()
        }
        
        if showsGroupSelector() {
            view.addSubview(groupSelector)
        }
        
        searchResultsViewController = SearchResultsViewController(userSelection: UserSelection(), isAddingParticipants: false, shouldIncludeGuests: true)
        searchResultsViewController.mode = SearchResultsViewControllerModeList
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
    
    func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        UIApplication.shared.wr_updateStatusBarForCurrentController(animated: animated)
        handleUploadAddressBookLogicIfNeeded()
    }
    
    func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        navigationController.navigationBar.barTintColor = UIColor.clear
        navigationController.navigationBar.isTranslucent = true
        navigationController.navigationBar.tintColor = UIColor.wr_color(fromColorScheme: ColorSchemeColorTextForeground, variant: ColorSchemeVariantDark)
        navigationController.navigationBar.titleTextAttributes = DefaultNavigationBar.titleTextAttributes(for: ColorSchemeVariantDark)
        
        UIApplication.shared.wr_updateStatusBarForCurrentController(animated: animated)
    }
    
    func preferredStatusBarStyle() -> UIStatusBarStyle {
        return .lightContent
    }
    
    func showKeyboardIfNeeded() {
        let conversationCount = ZMConversationList.conversations(inUserSession: ZMUserSession.shared()).count
        if conversationCount > Int(StartUIInitiallyShowsKeyboardConversationThreshold) {
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
        searchHeaderViewController.tokenField.resignFirstResponder()
        navigationController.dismiss(animated: true)
    }
    
    func accessibilityPerformEscape() -> Bool {
        onDismissPressed()
        return true
    }
    
    // MARK: - Instance methods
    @objc func performSearch() {
        let searchString = searchHeaderViewController.query
        ZMLogInfo("Search for %@", searchString)
        
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
    
    // MARK: - SearchHeaderViewControllerDelegate
    func searchHeaderViewControllerDidConfirmAction(_ searchHeaderViewController: SearchHeaderViewController?) {
        self.searchHeaderViewController.resetQuery()
    }
    
    func searchHeaderViewController(_ searchHeaderViewController: SearchHeaderViewController?, updatedSearchQuery query: String?) {
        searchResultsViewController.cancelPreviousSearch()
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(performSearch), object: nil)
        perform(#selector(performSearch), with: nil, afterDelay: 0.2)
    }
}


//#pragma clang diagnostic push
// To get rid of 'No protocol definition found' warnings which are not accurate
//#pragma clang diagnostic ignored "-Weverything"
extension  StartUIViewController: SearchHeaderViewControllerDelegate {
    private var profilePresenter: ProfilePresenter?
    private var emptyResultView: EmptySearchResultsView?
}
//#pragma clang diagnostic pop


protocol StartUIDelegate: NSObjectProtocol {
    func startUI(_ startUI: StartUIViewController, didSelectUsers users: Set<ZMUser>)
    func startUI(_ startUI: StartUIViewController, createConversationWithUsers users: Set<ZMUser>, name: String, allowGuests: Bool, enableReceipts: Bool)
    func startUI(_ startUI: StartUIViewController, didSelect conversation: ZMConversation)
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
