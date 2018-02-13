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


class AddParticipantsNavigationController: UINavigationController {
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationBar.tintColor = ColorScheme.default().color(withName: ColorSchemeColorTextForeground)
        self.navigationBar.setBackgroundImage(UIImage(), for:.default)
        self.navigationBar.shadowImage = UIImage()
        self.navigationBar.isTranslucent = true
        self.navigationBar.titleTextAttributes = [NSForegroundColorAttributeName: ColorScheme.default().color(withName: ColorSchemeColorTextForeground),
                                                  NSFontAttributeName: FontSpec(.medium, .medium).font!.allCaps()]
    }
}

@objc
public protocol AddParticipantsViewControllerDelegate : class {
    
    func addParticipantsViewControllerDidCancel(_ addParticipantsViewController : AddParticipantsViewController)
    func addParticipantsViewController(_ addParticipantsViewController : AddParticipantsViewController, didSelectUsers users: Set<ZMUser>)
}

public protocol AddParticipantsConversationCreationDelegate: class {

    func addParticipantsViewController(_ addParticipantsViewController : AddParticipantsViewController, didPerform action: AddParticipantsViewController.CreateAction)
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
    
    fileprivate let searchResultsViewController : SearchResultsViewController
    fileprivate let searchGroupSelector : SearchGroupSelector
    fileprivate let searchHeaderViewController : SearchHeaderViewController
    fileprivate let userSelection : UserSelection = UserSelection()
    fileprivate let collectionView : UICollectionView
    fileprivate let collectionViewLayout : UICollectionViewFlowLayout
    fileprivate let bottomContainer = UIView()
    fileprivate let confirmButton : IconButton
    fileprivate let emptyResultLabel = UILabel()
    fileprivate var bottomConstraint: NSLayoutConstraint?
    fileprivate let backButtonDescriptor = BackButtonDescription()
    
    public weak var delegate : AddParticipantsViewControllerDelegate?
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
    
    override open var title: String? {
        didSet {
            navigationItem.titleView = ConversationCreationTitleFactory.createTitleLabel(for: self.title ?? "")
            navigationItem.titleView?.accessibilityIdentifier = "label.addpeople.title"
        }
    }
    
    public init(context: Context) {
        viewModel = AddParticipantsViewModel(with: context)
        
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
        confirmButton.setIcon(ZetaIconType.convMetaAddPerson, with: .tiny, for: .normal)
        confirmButton.setIconColor(UIColor.wr_color(fromColorScheme: ColorSchemeColorIconNormal, variant: .dark), for: .normal)
        confirmButton.setIconColor(UIColor.wr_color(fromColorScheme: ColorSchemeColorIconHighlighted, variant: .dark), for: .highlighted)
        confirmButton.setTitleColor(UIColor.wr_color(fromColorScheme: ColorSchemeColorIconNormal, variant: .dark), for: .normal)
        confirmButton.setTitleColor(UIColor.wr_color(fromColorScheme: ColorSchemeColorIconHighlighted, variant: .dark), for: .highlighted)
        confirmButton.titleLabel?.font = FontSpec(.small, .medium).font!
        confirmButton.backgroundColor = UIColor.accent()
        confirmButton.contentHorizontalAlignment = .left
        confirmButton.setTitleImageSpacing(16, horizontalMargin: 24)
        confirmButton.roundCorners = true
        
        
        bottomContainer.backgroundColor = UIColor.clear
        bottomContainer.addSubview(confirmButton)

        searchHeaderViewController = SearchHeaderViewController(userSelection: userSelection, variant: ColorScheme.default().variant)
        
        searchGroupSelector = SearchGroupSelector(variant: ColorScheme.default().variant)

        searchResultsViewController = SearchResultsViewController(userSelection: userSelection, variant: ColorScheme.default().variant, isAddingParticipants: true)

        super.init(nibName: nil, bundle: nil)
        updateValues()

        emptyResultLabel.text = everyoneHasBeenAddedText
        emptyResultLabel.textColor = UIColor.wr_color(fromColorScheme: ColorSchemeColorTextForeground)
        emptyResultLabel.font = FontSpec(.normal, .none).font!
        
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
        searchResultsViewController.searchResultsView?.emptyResultView = emptyResultLabel
        searchResultsViewController.searchResultsView?.backgroundColor = UIColor.wr_color(fromColorScheme: ColorSchemeColorContentBackground)
        
        createConstraints()
        updateSelectionValues()
        
        if case .create = context {
            backButtonDescriptor.buttonTapped = { [weak self] in self?.backButtonTapped() }
            backButtonDescriptor.accessibilityIdentifier = "button.addpeople.back"
            navigationItem.leftBarButtonItem = .init(customView: backButtonDescriptor.create())
        }
    }

    func createConstraints() {
        let margin = (searchResultsViewController.view as! SearchResultsView).accessoryViewMargin
        
        constrain(view, searchHeaderViewController.view, searchResultsViewController.view, confirmButton, bottomContainer) {
            container, searchHeaderView, searchResultsView, confirmButton, bottomContainer in
            
            searchHeaderView.top == container.top
            searchHeaderView.left == container.left
            searchHeaderView.right == container.right
            
            searchResultsView.left == container.left
            searchResultsView.right == container.right
            searchResultsView.bottom == container.bottom
            
            confirmButton.height == 46.0
            confirmButton.top == bottomContainer.top
            confirmButton.left == bottomContainer.left + margin
            confirmButton.right == bottomContainer.right - margin
            self.bottomConstraint = confirmButton.bottom == bottomContainer.bottom - margin - UIScreen.safeArea.bottom
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
    
    @objc private func backButtonTapped() {
        navigationController?.popViewController(animated: true)
    }
    
    private func updateValues() {
        confirmButton.setTitle(viewModel.confirmButtonTitle, for: .normal)
        updateTitle()
        navigationItem.rightBarButtonItem = viewModel.rightNavigationItem(target: self, action: #selector(rightNavigationItemTapped))
    }

    fileprivate func updateSelectionValues() {
        // Update view model after selection changed
        if case .create(let values) = viewModel.context {
            let updated = ConversationCreationValues(name: values.name, participants: userSelection.users)
            viewModel = AddParticipantsViewModel(with: .create(updated))
        }

        // Update confirm button visibility
        if userSelection.users.isEmpty || !viewModel.showsConfirmButton {
            searchResultsViewController.searchResultsView?.accessoryView = nil
        } else {
            searchResultsViewController.searchResultsView?.accessoryView = bottomContainer
        }
        
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
    
    var emptySearchResultText : String {
        return "peoplepicker.no_matching_results_after_address_book_upload_title".localized
    }
    
    var everyoneHasBeenAddedText : String {
        return "add_participants.all_contacts_added".localized
    }
    
    @objc private func rightNavigationItemTapped(_ sender: Any!) {
        switch viewModel.context {
        case .add: navigationController?.dismiss(animated: true, completion: nil)
        case .create: conversationCreationDelegate?.addParticipantsViewController(self, didPerform: .create)
        }
    }
    
    func keyboardFrameWillChange(notification: Notification) {
        let firstResponder = UIResponder.wr_currentFirst()
        let inputAccessoryHeight = firstResponder?.inputAccessoryView?.bounds.size.height ?? 0
        let margin = (searchResultsViewController.view as! SearchResultsView).accessoryViewMargin
        
        UIView.animate(withKeyboardNotification: notification, in: self.view, animations: { (keyboardFrameInView) in
            let keyboardHeight = keyboardFrameInView.size.height - inputAccessoryHeight
            self.bottomConstraint?.constant = -margin - (keyboardHeight == 0 ? UIScreen.safeArea.bottom : CGFloat(0))
            self.view.layoutIfNeeded()
        }, completion: nil)
    }
    
    fileprivate func performSearch() {
        switch (searchResultsViewController.searchGroup, searchHeaderViewController.tokenField.filterText.isEmpty) {
        case (.services, _):
            emptyResultLabel.text = emptySearchResultText
            searchResultsViewController.mode = .search
            searchResultsViewController.searchForServices(withQuery: searchHeaderViewController.tokenField.filterText)
        case (.people, true):
            emptyResultLabel.text = everyoneHasBeenAddedText
            searchResultsViewController.mode = .list
            searchResultsViewController.searchContactList()
        case (.people, false):
            emptyResultLabel.text = emptySearchResultText
            searchResultsViewController.mode = .search
            searchResultsViewController.searchForLocalUsers(withQuery: searchHeaderViewController.tokenField.filterText)
        }
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
        delegate?.addParticipantsViewController(self, didSelectUsers: userSelection.users)
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
    public func searchResultsViewController(_ searchResultsViewController: SearchResultsViewController, didTapOnUser user: ZMSearchableUser, indexPath: IndexPath, section: SearchResultsViewControllerSection) {
        // no-op
    }
    
    public func searchResultsViewController(_ searchResultsViewController: SearchResultsViewController, didDoubleTapOnUser user: ZMSearchableUser, indexPath: IndexPath) {
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
            destinationConversation: conversation,
            actionType: .addService,
            variant: .init(colorScheme: ColorScheme.default().variant, opaque: true)
        )

        detail.completion = { [weak self] result in
            guard let `self` = self, let result = result else { return }
            switch result {
            case .success:
                self.dismiss(animated: true) {
                    self.delegate?.addParticipantsViewController(self, didSelectUsers: [])
                }
            case .failure(let error):
                error.displayAddBotError(in: detail)
            }
        }
        
        self.navigationController?.pushViewController(detail, animated: true)
    }
    
}

