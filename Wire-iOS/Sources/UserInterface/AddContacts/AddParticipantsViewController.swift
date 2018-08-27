//
// Wire
// Copyright (C) 2017 Wire Swiss GmbH
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
import Cartography
import Classy

extension ZMConversation {
    var canAddGuest: Bool {
        // If not a team conversation: possible to add any contact.
        guard let _ = self.team else {
            return true
        }
        
        // Access mode and/or role is unknown: let's try to add and observe the result.
        guard let accessMode = self.accessMode,
              let accessRole = self.accessRole else {
                return true
        }
        
        let canAddGuest = accessMode.contains(.invite)
        let guestCanBeAdded = accessRole != .team
        
        return canAddGuest && guestCanBeAdded
    }
}

public protocol AddParticipantsConversationCreationDelegate: class {

    func addParticipantsViewController(_ addParticipantsViewController : AddParticipantsViewController, didPerform action: AddParticipantsViewController.CreateAction)
}

extension AddParticipantsViewController.Context {
    var includeGuests: Bool {
        switch self {
        case .add(let conversation):
            return conversation.canAddGuest
        case .create(let creationValues):
            return creationValues.allowGuests
        }
    }
    
    var selectionLimit: Int {
        switch self {
        case .add(let conversation):
            return conversation.freeParticipantSlots
        case .create:
            return ZMConversation.maxParticipantsExcludingSelf
        }
    }
    
    var alertForSelectionOverflow: UIAlertController {
        let max = ZMConversation.maxParticipants
        let message: String
        switch self {
        case .add(let conversation):
            let freeSpace = conversation.freeParticipantSlots
            message = "add_participants.alert.message.existing_conversation".localized(args: max, freeSpace)
        case .create(_):
            message = "add_participants.alert.message.new_conversation".localized(args: max)
        }
        
        let controller = UIAlertController(
            title: "add_participants.alert.title".localized,
            message: message,
            preferredStyle: .alert
        )
        
        controller.addAction(.ok())
        return controller
    }
}

public class AddParticipantsViewController: UIViewController {
    
    public enum CreateAction {
        case updatedUsers(Set<ZMUser>)
        case create
    }
    
    public enum Context {
        case add(ZMConversation)
        case create(ConversationCreationValues)
    }
    
    fileprivate let variant: ColorSchemeVariant
    fileprivate let searchResultsViewController : SearchResultsViewController
    fileprivate let searchGroupSelector : SearchGroupSelector
    fileprivate let searchHeaderViewController : SearchHeaderViewController
    fileprivate let userSelection : UserSelection = UserSelection()
    fileprivate let collectionView : UICollectionView
    fileprivate let collectionViewLayout : UICollectionViewFlowLayout
    fileprivate let confirmButtonHeight: CGFloat = 46.0
    fileprivate let confirmButton : IconButton
    fileprivate let emptyResultView: EmptySearchResultsView
    fileprivate var bottomConstraint: NSLayoutConstraint?
    fileprivate let backButtonDescriptor = BackButtonDescription()
    private let bottomMargin: CGFloat = UIScreen.hasNotch ? 8 : 16

    
    public weak var conversationCreationDelegate : AddParticipantsConversationCreationDelegate?
    
    fileprivate var viewModel: AddParticipantsViewModel {
        didSet {
            updateValues()
        }
    }

    deinit {
        userSelection.remove(observer: self)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    convenience public init(conversation: ZMConversation) {
        self.init(context: .add(conversation))
    }
    
    public override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        searchHeaderViewController.tokenField.resignFirstResponder()
    }
        
    public init(context: Context, variant: ColorSchemeVariant = ColorScheme.default.variant) {
        self.variant = variant
        
        viewModel = AddParticipantsViewModel(with: context, variant: variant)
        
        collectionViewLayout = UICollectionViewFlowLayout()
        collectionViewLayout.scrollDirection = .vertical
        collectionViewLayout.minimumInteritemSpacing = 12
        collectionViewLayout.minimumLineSpacing = 0
        
        collectionView = UICollectionView(frame: CGRect.zero, collectionViewLayout: collectionViewLayout)
        collectionView.backgroundColor = UIColor.clear
        collectionView.allowsMultipleSelection = true
        collectionView.keyboardDismissMode = .onDrag
        collectionView.bounces = true
        collectionView.alwaysBounceVertical = true

        confirmButton = IconButton()
        confirmButton.setIconColor(UIColor(scheme: .iconNormal, variant: .dark), for: .normal)
        confirmButton.setIconColor(UIColor(scheme: .iconHighlighted, variant: .dark), for: .highlighted)
        confirmButton.setTitleColor(UIColor(scheme: .iconNormal, variant: .dark), for: .normal)
        confirmButton.setTitleColor(UIColor(scheme: .iconHighlighted, variant: .dark), for: .highlighted)
        confirmButton.titleLabel?.font = FontSpec(.small, .medium).font!
        confirmButton.backgroundColor = UIColor.accent()
        confirmButton.contentHorizontalAlignment = .center
        confirmButton.setTitleImageSpacing(16, horizontalMargin: 24)
        confirmButton.roundCorners = true
        
        

        searchHeaderViewController = SearchHeaderViewController(userSelection: userSelection, variant: self.variant)
        
        searchGroupSelector = SearchGroupSelector(style: self.variant)

        searchResultsViewController = SearchResultsViewController(userSelection: userSelection,
                                                                  isAddingParticipants: true,
                                                                  shouldIncludeGuests: viewModel.context.includeGuests)

        emptyResultView = EmptySearchResultsView(variant: self.variant, isSelfUserAdmin: ZMUser.selfUser().canManageTeam)
        super.init(nibName: nil, bundle: nil)
        
        emptyResultView.delegate = self
        
        userSelection.setLimit(context.selectionLimit) {
            self.present(context.alertForSelectionOverflow, animated: true)
        }
        
        updateValues()

        confirmButton.addTarget(self, action: #selector(searchHeaderViewControllerDidConfirmAction(_:)), for: .touchUpInside)
        
        searchResultsViewController.filterConversation = viewModel.filterConversation
        searchResultsViewController.mode = .list
        searchResultsViewController.searchContactList()
        searchResultsViewController.delegate = self
        
        userSelection.add(observer: self)
        
        searchGroupSelector.onGroupSelected = { [weak self] group in
            guard let `self` = self else {
                return
            }
            // Remove selected users when switching to services tab to avoid the user confusion: users in the field are
            // not going to be added to the new conversation with the bot.
            if group == .services {
                self.searchHeaderViewController.clearInput()
            }
            
            self.searchResultsViewController.searchGroup = group
            self.performSearch()
        }
        
        viewModel.selectedUsers.forEach(userSelection.add)
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(keyboardFrameWillChange(notification:)),
                                               name: NSNotification.Name.UIKeyboardWillChangeFrame,
                                               object: nil)
        if viewModel.botCanBeAdded {
            view.addSubview(searchGroupSelector)
        }
        
        searchHeaderViewController.delegate = self
        addChildViewController(searchHeaderViewController)
        view.addSubview(searchHeaderViewController.view)
        searchHeaderViewController.didMove(toParentViewController: self)
        
        addChildViewController(searchResultsViewController)
        view.addSubview(searchResultsViewController.view)
        searchResultsViewController.didMove(toParentViewController: self)
        searchResultsViewController.searchResultsView?.emptyResultView = emptyResultView
        searchResultsViewController.searchResultsView?.backgroundColor = UIColor(scheme: .contentBackground, variant: self.variant)
        searchResultsViewController.searchResultsView?.collectionView.accessibilityIdentifier = "add_participants.list"
        
        view.backgroundColor = UIColor(scheme: .contentBackground, variant: self.variant)
        view.addSubview(confirmButton)
        
        createConstraints()
        updateSelectionValues()
        
        if searchResultsViewController.isResultEmpty {
            emptyResultView.updateStatus(searchingForServices: false, hasFilter: false)
        }
    }

    func createConstraints() {
        let margin = (searchResultsViewController.view as! SearchResultsView).accessoryViewMargin

        constrain(view, searchHeaderViewController.view, searchResultsViewController.view, confirmButton) {
            container, searchHeaderView, searchResultsView, confirmButton in
            
            searchHeaderView.top == container.top
            searchHeaderView.left == container.left
            searchHeaderView.right == container.right
            
            searchResultsView.left == container.left
            searchResultsView.right == container.right
            searchResultsView.bottom == container.bottom
            
            confirmButton.height == self.confirmButtonHeight
            confirmButton.left == container.left + margin
            confirmButton.right == container.right - margin

            self.bottomConstraint = confirmButton.bottom == container.safeAreaLayoutGuideOrFallback.bottom - bottomMargin
        }
        
        if viewModel.botCanBeAdded {
            constrain(view, searchHeaderViewController.view, searchGroupSelector, searchResultsViewController.view) {
                view, searchHeaderView, searchGroupSelector, searchResultsView in
                searchGroupSelector.top == searchHeaderView.bottom
                searchGroupSelector.leading == view.leading
                searchGroupSelector.trailing == view.trailing
                searchResultsView.top == searchGroupSelector.bottom
            }
        }
        else {
            constrain(searchHeaderViewController.view, searchResultsViewController.view) {
                searchHeaderView, searchResultsView in
                searchResultsView.top == searchHeaderView.bottom
            }
        }
    }

    private func updateValues() {
        confirmButton.setTitle(viewModel.confirmButtonTitle, for: .normal)
        updateTitle()
        navigationItem.rightBarButtonItem = viewModel.rightNavigationItem(target: self, action: #selector(rightNavigationItemTapped))
    }

    fileprivate func updateSelectionValues() {
        // Update view model after selection changed
        if case .create(let values) = viewModel.context {
            let updated = ConversationCreationValues(name: values.name, participants: userSelection.users, allowGuests: true)
            viewModel = AddParticipantsViewModel(with: .create(updated), variant: variant)
        }

        // Update confirm button visibility & collection view content inset
        confirmButton.isHidden = userSelection.users.isEmpty || !viewModel.showsConfirmButton
        let bottomInset = confirmButton.isHidden ? bottomMargin : confirmButtonHeight + 16 + bottomMargin
        searchResultsViewController.searchResultsView?.collectionView.contentInset.bottom = bottomInset
        
        updateTitle()
        
        // Notify delegate
        conversationCreationDelegate?.addParticipantsViewController(self, didPerform: .updatedUsers(userSelection.users))
    }
    
    private func updateTitle() {
        title = {
            switch viewModel.context {
            case .create(let values): return viewModel.title(with: values.participants)
            case .add: return viewModel.title(with: userSelection.users)
            }
        }()
    }
    
    @objc private func rightNavigationItemTapped(_ sender: Any!) {
        switch viewModel.context {
        case .add: navigationController?.dismiss(animated: true, completion: nil)
        case .create: conversationCreationDelegate?.addParticipantsViewController(self, didPerform: .create)
        }
    }
    
    @objc func keyboardFrameWillChange(notification: Notification) {
        // Don't adjust the frame when being presented in a popover.
        if let arrowDirection = popoverPresentationController?.arrowDirection, arrowDirection == .unknown {
            return
        }
        
        let firstResponder = UIResponder.wr_currentFirst()
        let inputAccessoryHeight = firstResponder?.inputAccessoryView?.bounds.size.height ?? 0
        
        UIView.animate(withKeyboardNotification: notification, in: self.view, animations: { (keyboardFrameInView) in
            let keyboardHeight = keyboardFrameInView.size.height - inputAccessoryHeight
            let margin: CGFloat = {
                guard UIScreen.hasNotch, keyboardHeight > 0 else { return self.bottomMargin }
                return -self.bottomMargin
            }()
            
            self.bottomConstraint?.constant = -(keyboardHeight + margin)
            self.view.layoutIfNeeded()
        }, completion: nil)
    }
    
    fileprivate func performSearch() {
        let searchingForServices = searchResultsViewController.searchGroup == .services
        let hasFilter = !searchHeaderViewController.tokenField.filterText.isEmpty
        
        emptyResultView.updateStatus(searchingForServices: searchingForServices, hasFilter: hasFilter)
        
        switch (searchResultsViewController.searchGroup, hasFilter) {
        case (.services, _):
            searchResultsViewController.mode = .search
            searchResultsViewController.searchForServices(withQuery: searchHeaderViewController.tokenField.filterText)
        case (.people, false):
            searchResultsViewController.mode = .list
            searchResultsViewController.searchContactList()
        case (.people, true):
            searchResultsViewController.mode = .search
            searchResultsViewController.searchForLocalUsers(withQuery: searchHeaderViewController.tokenField.filterText)
        }
    }
    
    fileprivate func addSelectedParticipants(to conversation: ZMConversation) {
        let selectedUsers = self.userSelection.users
        
        conversation.addOrShowError(participants: selectedUsers)
    }
}

extension AddParticipantsViewController : UserSelectionObserver {
    
    public func userSelection(_ userSelection: UserSelection, didAddUser user: ZMUser) {
        updateSelectionValues()
    }
    
    public func userSelection(_ userSelection: UserSelection, didRemoveUser user: ZMUser) {
        updateSelectionValues()
    }
    
    public func userSelection(_ userSelection: UserSelection, wasReplacedBy users: [ZMUser]) {
        updateSelectionValues()
    }
    
}

extension AddParticipantsViewController : SearchHeaderViewControllerDelegate {
    
    public func searchHeaderViewControllerDidConfirmAction(_ searchHeaderViewController: SearchHeaderViewController) {
        if case .add(let conversation) = viewModel.context {
            self.dismiss(animated: true) {
                self.addSelectedParticipants(to: conversation)
            }
            
        }
    }
    
    public func searchHeaderViewController(_ searchHeaderViewController: SearchHeaderViewController, updatedSearchQuery query: String) {
        self.performSearch()
    }
    
}

extension AddParticipantsViewController : UIPopoverPresentationControllerDelegate {

    public func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle {
        return UIModalPresentationStyle.overFullScreen
    }
    
    public func adaptivePresentationStyle(for controller: UIPresentationController, traitCollection: UITraitCollection) -> UIModalPresentationStyle {
        return UIModalPresentationStyle.overFullScreen
    }
    
}

extension AddParticipantsViewController: SearchResultsViewControllerDelegate {
    public func searchResultsViewController(_ searchResultsViewController: SearchResultsViewController, didTapOnUser user: UserType, indexPath: IndexPath, section: SearchResultsViewControllerSection) {
        // no-op
    }
    
    public func searchResultsViewController(_ searchResultsViewController: SearchResultsViewController, didDoubleTapOnUser user: UserType, indexPath: IndexPath) {
        // no-op
    }
    
    public func searchResultsViewController(_ searchResultsViewController: SearchResultsViewController, didTapOnConversation conversation: ZMConversation) {
        // no-op
    }
    
    public func searchResultsViewController(_ searchResultsViewController: SearchResultsViewController, wantsToPerformAction action: SearchResultsViewControllerAction) {
        // no-op
    }

    public func searchResultsViewController(_ searchResultsViewController: SearchResultsViewController, didTapOnSeviceUser user: ServiceUser) {
        guard case let .add(conversation) = viewModel.context else { return }
        let detail = ServiceDetailViewController(
            serviceUser: user,
            actionType: .addService(conversation),
            variant: .init(colorScheme: self.variant, opaque: true)
        ) { [weak self] result in
            guard let `self` = self, let result = result else { return }
            switch result {
            case .success:
                self.dismiss(animated: true)
            case .failure(let error):
                guard let controller = self.navigationController?.topViewController else { return }
                error.displayAddBotError(in: controller)
            }
        }
        
        self.navigationController?.pushViewController(detail, animated: true)
    }
    
}

extension AddParticipantsViewController: EmptySearchResultsViewDelegate {
    func execute(action: EmptySearchResultsViewAction, from: EmptySearchResultsView) {
        switch action {
        case .openManageServices:
            URL.manageTeam(source: .onboarding).openInApp(above: self)
        }
    }
}
