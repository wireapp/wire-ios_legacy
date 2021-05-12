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

import Foundation
import WireDataModel

class ContactsSectionController: SearchSectionController {

    var contacts: [UserType] = []
    var selection: UserSelection? = nil {
        didSet {
            selection?.add(observer: self)
        }
    }
    var allowsSelection: Bool = false
    weak var delegate: SearchSectionControllerDelegate?
    weak var collectionView: UICollectionView?

    deinit {
        selection?.remove(observer: self)
    }

    override func prepareForUse(in collectionView: UICollectionView?) {
        super.prepareForUse(in: collectionView)

        collectionView?.register(UserCell.self, forCellWithReuseIdentifier: UserCell.zm_reuseIdentifier)

        self.collectionView = collectionView
    }

    override var isHidden: Bool {
        return contacts.isEmpty
    }

    var title: String = ""

    override var sectionTitle: String {
        return title
    }

    override var sectionAccessibilityIdentifier: String {
        return "label.search.participants"
    }

    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return contacts.count
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let user = contacts[indexPath.row]
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: UserCell.zm_reuseIdentifier, for: indexPath) as! UserCell

        cell.configure(with: user, selfUser: ZMUser.selfUser())
        cell.showSeparator = (contacts.count - 1) != indexPath.row
        cell.checkmarkIconView.isHidden = !allowsSelection
        cell.accessoryIconView.isHidden = true

        let selected = selection?.users.contains(user) ?? false
        cell.isSelected = selected

        if selected {
            collectionView.selectItem(at: indexPath, animated: false, scrollPosition: [])
        }

        return cell
    }

    override func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        return !(selection?.hasReachedLimit ?? false)
    }

    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let user = contacts[indexPath.row]
        selection?.add(user)

        delegate?.searchSectionController(self, didSelectUser: user, at: indexPath)
    }

    override func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        let user = contacts[indexPath.row]
        selection?.remove(user)
    }

}

extension ContactsSectionController: UserSelectionObserver {

    func userSelection(_ userSelection: UserSelection, wasReplacedBy users: [UserType]) {
        collectionView?.reloadData()
    }

    func userSelection(_ userSelection: UserSelection, didAddUser user: UserType) {
        collectionView?.reloadData()
    }

    func userSelection(_ userSelection: UserSelection, didRemoveUser user: UserType) {
        collectionView?.reloadData()
    }

}
