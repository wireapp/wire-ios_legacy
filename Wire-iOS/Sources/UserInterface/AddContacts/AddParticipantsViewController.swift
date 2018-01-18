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

@objc
public protocol AddParticipantsViewControllerDelegate : class {
    
    func addParticipantsViewControllerDidCancel(_ addParticipantsViewController : AddParticipantsViewController)
    func addParticipantsViewController(_ addParticipantsViewController : AddParticipantsViewController, didSelectUsers users: Set<ZMUser>)
    
}

public class AddParticipantsViewController : UIViewController {
    
    fileprivate let searchResultsViewController : SearchResultsViewController
    fileprivate let searchHeaderViewController : SearchHeaderViewController
    fileprivate let userSelection : UserSelection = UserSelection()
    fileprivate let collectionView : UICollectionView
    fileprivate let collectionViewLayout : UICollectionViewFlowLayout
    fileprivate let bottomContainer = UIView()
    fileprivate let confirmButton : IconButton
    fileprivate let emptyResultLabel = UILabel()
    
    public weak var delegate : AddParticipantsViewControllerDelegate? = nil
    
    fileprivate let conversation : ZMConversation
    
    deinit {
        userSelection.remove(observer: self)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public init(conversation: ZMConversation) {
        self.conversation = conversation
        
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
        
        if conversation.conversationType == .oneOnOne {
            confirmButton.setTitle("peoplepicker.button.create_conversation".localized.uppercased(), for: .normal)
        } else {
            confirmButton.setTitle("peoplepicker.button.add_to_conversation".localized.uppercased(), for: .normal)
        }
        
        bottomContainer.backgroundColor = UIColor.clear
        bottomContainer.addSubview(confirmButton)
 
        searchHeaderViewController = SearchHeaderViewController(userSelection: userSelection, variant: ColorScheme.default().variant)
        searchResultsViewController = SearchResultsViewController(userSelection: userSelection, variant: ColorScheme.default().variant, isAddingParticipants: true)

        super.init(nibName: nil, bundle: nil)
        
        emptyResultLabel.text = everyoneHasBeenAddedText
        emptyResultLabel.textColor = UIColor.wr_color(fromColorScheme: ColorSchemeColorTextForeground)
        emptyResultLabel.font = FontSpec(.normal, .none).font!
        
        confirmButton.addTarget(self, action: #selector(searchHeaderViewControllerDidConfirmAction(_:)), for: .touchUpInside)
        
        searchResultsViewController.filterConversation = conversation.conversationType == .group ? conversation : nil
        searchResultsViewController.mode = .list
        searchResultsViewController.searchContactList()
        searchResultsViewController.delegate = self
        
        userSelection.add(observer: self)
        
        if conversation.conversationType == .oneOnOne, let connectedUser = conversation.connectedUser {
            userSelection.add(connectedUser)
        }
    }

    override public func viewDidLoad() {
        searchHeaderViewController.title = conversation.displayName
        searchHeaderViewController.delegate = self
        addChildViewController(searchHeaderViewController)
        view.addSubview(searchHeaderViewController.view)
        searchHeaderViewController.didMove(toParentViewController: self)
        
        addChildViewController(searchResultsViewController)
        view.addSubview(searchResultsViewController.view)
        searchResultsViewController.didMove(toParentViewController: self)
        searchResultsViewController.searchResultsView?.emptyResultView = emptyResultLabel
        searchResultsViewController.searchResultsView?.backgroundColor = UIColor.wr_color(fromColorScheme: ColorSchemeColorContentBackground);

        createConstraints()
        updateConfirmButtonVisibility()
    }
    
    func createConstraints() {
        
        let margin = (searchResultsViewController.view as! SearchResultsView).accessoryViewMargin
        
        constrain(view, searchHeaderViewController.view, searchResultsViewController.view, confirmButton, bottomContainer) {
            container, searchHeaderView, searchResultsView, confirmButton, bottomContainer in
            
            searchHeaderView.top == container.top + UIScreen.safeArea.top
            searchHeaderView.left == container.left
            searchHeaderView.right == container.right
            
            searchResultsView.top == searchHeaderView.bottom
            searchResultsView.left == container.left
            searchResultsView.right == container.right
            searchResultsView.bottom == container.bottom
            
            confirmButton.height == 46.0
            confirmButton.top == bottomContainer.top
            confirmButton.left == bottomContainer.left + margin
            confirmButton.right == bottomContainer.right - margin
            confirmButton.bottom == bottomContainer.bottom - margin - UIScreen.safeArea.bottom
        }
    }
        
    func updateConfirmButtonVisibility() {
        if userSelection.users.isEmpty {
            searchResultsViewController.searchResultsView?.accessoryView = nil
        } else {
            searchResultsViewController.searchResultsView?.accessoryView = bottomContainer
        }
    }
    
    var emptySearchResultText : String {
        return "peoplepicker.no_matching_results_after_address_book_upload_title".localized
    }
    
    var everyoneHasBeenAddedText : String {
        return "add_participants.all_contacts_added".localized
    }
}

extension AddParticipantsViewController : UserSelectionObserver {
    
    public func userSelection(_ userSelection: UserSelection, didAddUser user: ZMUser) {
        updateConfirmButtonVisibility()
    }
    
    public func userSelection(_ userSelection: UserSelection, didRemoveUser user: ZMUser) {
        updateConfirmButtonVisibility()
    }
    
    public func userSelection(_ userSelection: UserSelection, wasReplacedBy users: [ZMUser]) {
        updateConfirmButtonVisibility()
    }
    
}

extension AddParticipantsViewController : SearchHeaderViewControllerDelegate {
    
    public func searchHeaderViewControllerDidCancelAction(_ searchHeaderViewController: SearchHeaderViewController) {
        delegate?.addParticipantsViewControllerDidCancel(self)
    }
    
    public func searchHeaderViewControllerDidConfirmAction(_ searchHeaderViewController: SearchHeaderViewController) {
        delegate?.addParticipantsViewController(self, didSelectUsers: userSelection.users)
    }
    
    public func searchHeaderViewController(_ searchHeaderViewController: SearchHeaderViewController, updatedSearchQuery query: String) {
        if query.isEmpty {
            emptyResultLabel.text = everyoneHasBeenAddedText
            searchResultsViewController.mode = .list
            searchResultsViewController.searchContactList()
        } else {
            emptyResultLabel.text = emptySearchResultText
            searchResultsViewController.mode = .search
            searchResultsViewController.searchForLocalUsers(withQuery: query)
        }
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
    public func searchResultsViewController(_ searchResultsViewController: SearchResultsViewController, didTapOnUser user: ZMSearchableUser, indexPath: IndexPath, section: SearchResultsViewControllerSection)
    {
        // no-op
    }
    
    public func searchResultsViewController(_ searchResultsViewController: SearchResultsViewController, didDoubleTapOnUser user: ZMSearchableUser, indexPath: IndexPath)
    {
        // no-op
    }
    
    public func searchResultsViewController(_ searchResultsViewController: SearchResultsViewController, didTapOnConversation conversation: ZMConversation)
    {
        // no-op
    }
    
    public func searchResultsViewController(_ searchResultsViewController: SearchResultsViewController, didTapOnSeviceUser user: ServiceUser)
    {
        guard let userSession = ZMUserSession.shared() else {
            return
        }
        self.showLoadingView = true
        self.conversation.add(serviceUser: user, in: userSession) { [weak self] _ in
            guard let `self` = self else {
                return
            }
            
            self.delegate?.addParticipantsViewControllerDidCancel(self)
            self.showLoadingView = false
        }
    }
}

