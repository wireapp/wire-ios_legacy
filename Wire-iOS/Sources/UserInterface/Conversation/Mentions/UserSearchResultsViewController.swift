//
// Wire
// Copyright (C) 2018 Wire Swiss GmbH
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
import Cartography

@objc protocol UserSearchResultsViewControllerDelegate {
    func didSelect(user: UserType)
}

@objc protocol Dismissable {
    func dismiss()
}

@objc protocol KeyboardCollapseObserver {
    var isKeyboardCollapsed: Bool { get }
}

@objc protocol UserList {
    var users: [UserType] { get set }
}

class UserSearchResultsViewController: UIViewController, KeyboardCollapseObserver {

    private let collectionView = UICollectionView(frame: .zero, collectionViewLayout: UICollectionViewLayout())
    private var searchResults: [UserType] = []
    private var query: String = ""
    private var collectionViewHeight: NSLayoutConstraint?
    private let rowHeight: CGFloat = 56.0
    private var isKeyboardCollapsedFirstCalled = true
    public private(set) var isKeyboardCollapsed: Bool = true {
        didSet {
            guard oldValue != isKeyboardCollapsed || isKeyboardCollapsedFirstCalled else { return }
            collectionView.reloadData()

            isKeyboardCollapsedFirstCalled = false
        }
    }
    
    @objc public weak var delegate: UserSearchResultsViewControllerDelegate?

    private var keyboardObserver: KeyboardBlockObserver?

    override func viewDidLoad() {
        super.viewDidLoad()

        setupCollectionView()
        setupConstraints()
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(keyboardWillChangeFrame(_:)),
                                               name: UIResponder.keyboardWillChangeFrameNotification,
                                               object: nil)

        setupKeyboardObserver()
    }

    private func setupKeyboardObserver() {
        keyboardObserver = KeyboardBlockObserver { [weak self] info in
            guard let weakSelf = self else { return }
            if let isKeyboardCollapsed = info.isKeyboardCollapsed {
                weakSelf.isKeyboardCollapsed = isKeyboardCollapsed
            }
        }
    }
    
    private func setupCollectionView() {
        view.isHidden = true
        
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(UserCell.self, forCellWithReuseIdentifier: UserCell.reuseIdentifier)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.backgroundColor = UIColor(scheme: .barBackground)
        
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.minimumLineSpacing = 0
        layout.minimumInteritemSpacing = 0

        collectionView.collectionViewLayout = layout

        view.backgroundColor = UIColor.black.withAlphaComponent(0.32)
        view.addSubview(collectionView)
        
        view.accessibilityIdentifier = "mentions.list.container"
        collectionView.accessibilityIdentifier = "mentions.list.collection"
    }

    private func setupConstraints() {
        constrain(self.view, collectionView) { (selfView, collectionView) in
            collectionView.bottom == selfView.bottom
            collectionView.leading == selfView.leading
            collectionView.trailing == selfView.trailing
            collectionViewHeight = collectionView.height == 0
        }
    }
    
    @objc func reloadTable(with results: [UserType]) {
        searchResults = results
        resizeTable()
        
        collectionView.reloadData()
        collectionView.layoutIfNeeded()
        
        scrollToLastItem()

        if results.count > 0 {
            show()
        } else {
            dismiss()
        }
    }
    
    private func resizeTable() {
        let viewHeight = self.view.bounds.size.height
        let minValue = min(viewHeight, CGFloat(searchResults.count) * rowHeight)
        collectionViewHeight?.constant = minValue
        collectionView.isScrollEnabled = (minValue == viewHeight)
    }
    
    private func scrollToLastItem() {
        let firstMatchIndexPath = IndexPath(item: searchResults.count - 1, section: 0)
        
        if collectionView.containsCell(at: firstMatchIndexPath) {
            collectionView.scrollToItem(at: firstMatchIndexPath, at: .bottom, animated: false)
        }
    }
    
    func show() {
        self.view.isHidden = false
    }
    
    @objc dynamic func keyboardWillChangeFrame(_ notification: Notification) {
        guard let duration = notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? TimeInterval else { return }
        resizeTable()
        UIView.animate(withDuration: duration) {
            self.view.layoutIfNeeded()
            self.scrollToLastItem()
        }
    }
  
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)

        coordinator.animate(alongsideTransition: nil) { _ in
            self.collectionView.reloadData()
        }
    }
}

extension UserSearchResultsViewController: Dismissable {
    func dismiss() {
        self.view.isHidden = true
    }
}

extension UserSearchResultsViewController: UserList {
    var users: [UserType] {
        set {
            reloadTable(with: newValue.reversed())
        }
        get {
            return searchResults.reversed()
        }
    }
}

extension UserSearchResultsViewController: UICollectionViewDelegate {
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return searchResults.count
    }
}

extension UserSearchResultsViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: collectionView.bounds.size.width, height: rowHeight)
    }
}

extension UserSearchResultsViewController: UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let user = searchResults[indexPath.item]
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: UserCell.reuseIdentifier, for: indexPath) as! UserCell
        cell.configure(with: user)
        cell.showSeparator = false
        cell.avatarSpacing = UIView.conversationLayoutMargins.left

        // hightlight the lowest cell if keyboard is collapsed
        if isKeyboardCollapsed {
            if indexPath.item == searchResults.count - 1 {
                cell.backgroundColor = .contentBackground
            } else {
                cell.backgroundColor = .background
            }
        } else {
            cell.backgroundColor = .background
        }

        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        delegate?.didSelect(user: searchResults[indexPath.item])
        dismiss()
    }
}
