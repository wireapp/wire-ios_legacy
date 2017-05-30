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
    
    fileprivate let searchResultController : SearchResultsController
    fileprivate let searchHeaderViewController : SearchHeaderViewController
    fileprivate let userSelection : UserSelection = UserSelection()
    fileprivate let collectionView : UICollectionView
    fileprivate let collectionViewLayout : UICollectionViewFlowLayout
    fileprivate let bottomContainer = UIView()
    fileprivate let confirmButton : IconButton
    
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
        confirmButton.titleLabel?.font = FontSpec(.normal, .medium).font!
        confirmButton.backgroundColor = UIColor.accent()
        confirmButton.contentHorizontalAlignment = .left
        confirmButton.setTitleImageSpacing(16, horizontalMargin: 24)
        
        if conversation.conversationType == .oneOnOne {
            confirmButton.setTitle("peoplepicker.button.create_conversation".localized, for: .normal)
        } else {
            confirmButton.setTitle("peoplepicker.button.add_to_conversation".localized, for: .normal)
        }
 
        searchHeaderViewController = SearchHeaderViewController(userSelection: userSelection, variant: ColorScheme.default().variant)
        searchResultController = SearchResultsController(collectionView: collectionView, userSelection: userSelection, team: ZMUser.selfUser().activeTeam, variant: ColorScheme.default().variant, isAddingParticipants: true)
        
        super.init(nibName: nil, bundle: nil)
        
        confirmButton.addTarget(self, action: #selector(searchHeaderViewControllerDidConfirmAction(_:)), for: .touchUpInside)
        
        searchResultController.filterConversation = conversation
        searchResultController.mode = .list
        searchResultController.searchContactList()
        
        userSelection.add(observer: self)
    }

    override public func viewDidLoad() {
        searchHeaderViewController.title = conversation.displayName
        searchHeaderViewController.delegate = self
        addChildViewController(searchHeaderViewController)
        view.addSubview(searchHeaderViewController.view)
        searchHeaderViewController.didMove(toParentViewController: self)
        
        view.addSubview(collectionView)
        view.addSubview(bottomContainer)
        
        createConstraints()
    }
    
    func createConstraints() {
        constrain(view, collectionView, searchHeaderViewController.view, bottomContainer, confirmButton) { container, collectionView, searchHeaderView, bottomContainer, confirmButton in
            
            searchHeaderView.top == container.top
            searchHeaderView.left == container.left
            searchHeaderView.right == container.right
            
            collectionView.top == searchHeaderView.bottom
            collectionView.left == container.left
            collectionView.right == container.right
            
            bottomContainer.top == collectionView.bottom
            bottomContainer.left == container.left
            bottomContainer.right == container.right
            bottomContainer.bottom == container.bottom
            
            confirmButton.height == CGFloat(55.0)
        }
    }
    
    var bottomView : UIView? {
        didSet {
            guard oldValue != bottomView else { return }
            
            oldValue?.removeFromSuperview()
            
            if let bottomView = bottomView {
                bottomContainer.addSubview(bottomView)
                CASStyler.default().styleItem(bottomView)
                
                constrain(bottomContainer, bottomView) { container, bottomView in
                    bottomView.edges == container.edges
                }
            }
        }
    }
    
    func updateConfirmButtonVisibility() {
        if userSelection.users.isEmpty {
            bottomView = nil
        } else {
            bottomView = confirmButton
        }
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
            searchResultController.mode = .list
            searchResultController.searchContactList()
        } else {
            searchResultController.mode = .search
            searchResultController.search(withQuery: query, local: true)
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
