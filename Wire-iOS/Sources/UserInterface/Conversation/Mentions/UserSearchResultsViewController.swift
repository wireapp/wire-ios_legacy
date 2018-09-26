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

@objc protocol UserList {
    var users: [UserType] { get set }
}

class UserSearchResultsViewController: UIViewController {

    private let collectionView = UICollectionView(frame: .zero, collectionViewLayout: UICollectionViewLayout())
    private var searchResults: [UserType] = []
    private var query: String = ""
    private var collectionViewHeight: NSLayoutConstraint?
    private let rowHeight: CGFloat = 56.0
    
    @objc public weak var delegate: UserSearchResultsViewControllerDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        setupCollectionView()
        setupConstraints()
    }
    
    private func setupCollectionView() {
        view.isHidden = true
        
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(UserCell.self, forCellWithReuseIdentifier: UserCell.reuseIdentifier)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.backgroundColor = UIColor(scheme: .background)
        
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.minimumLineSpacing = 1
        layout.minimumInteritemSpacing = 1

        collectionView.collectionViewLayout = layout

        view.backgroundColor = UIColor(scheme: .background).withAlphaComponent(0.5)
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
        
        let viewHeight = self.view.bounds.size.height
        let minValue = min(viewHeight, CGFloat(searchResults.count) * rowHeight)
        collectionViewHeight?.constant = minValue
        collectionView.isScrollEnabled = (minValue == viewHeight)
        
        collectionView.reloadData()
        collectionView.layoutIfNeeded()

        let firstMatchIndexPath = IndexPath(item: searchResults.count - 1, section: 0)

        if collectionView.containsCell(at: firstMatchIndexPath) {
            collectionView.scrollToItem(at: firstMatchIndexPath, at: .bottom, animated: false)
        }

        if minValue > 0 {
            show()
        } else {
            dismiss()
        }
    }
    
    func show() {
        self.view.isHidden = false
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
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        delegate?.didSelect(user: searchResults[indexPath.item])
        dismiss()
    }
}
