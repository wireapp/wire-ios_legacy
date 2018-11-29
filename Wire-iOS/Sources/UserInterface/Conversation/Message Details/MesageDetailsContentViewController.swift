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

class MessageDetailsCellDescription: NSObject, NSCopying {
    let user: ZMUser
    let subtitle: String?

    init(user: ZMUser, subtitle: String?) {
        self.user = user
        self.subtitle = subtitle
    }

    override var hash: Int {
        return user.hash
    }

    override func isEqual(_ object: Any?) -> Bool {
        guard let otherDescription = object as? MessageDetailsCellDescription else {
            return false
        }

        return user == otherDescription.user && subtitle == otherDescription.subtitle
    }

    func copy(with zone: NSZone? = nil) -> Any {
        return MessageDetailsCellDescription(user: user, subtitle: subtitle)
    }
}

class MesageDetailsContentViewController: UIViewController {

    enum ContentType {
        case reactions, receipts, receiptsDisabled
    }

    let noResultsView = NoResultsView()
    let collectionViewLayout = UICollectionViewFlowLayout()
    var collectionView: UICollectionView!

    var isEmpty: Bool = false {
        didSet {
            self.noResultsView.isHidden = !self.isEmpty
        }
    }

    var contentType: ContentType {
        didSet {
            configureNoResultsViewForContentType()
        }
    }

    var cells: [MessageDetailsCellDescription] = [] {
        didSet {
            reloadData(oldValue, cells)
        }
    }

    // MARK: - Initialization

    init(contentType: ContentType) {
        self.contentType = contentType
        super.init(nibName: nil, bundle: nil)
        configureSubviews()
        configureConstraints()
    }

    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func configureSubviews() {
        view.backgroundColor = .from(scheme: .contentBackground)

        collectionViewLayout.scrollDirection = .vertical
        collectionViewLayout.minimumLineSpacing = 0
        collectionViewLayout.minimumInteritemSpacing = 0
        collectionViewLayout.sectionInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)

        collectionView = UICollectionView(frame: CGRect.zero, collectionViewLayout: collectionViewLayout)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.allowsMultipleSelection = false
        collectionView.allowsSelection = true
        collectionView.alwaysBounceVertical = true
        collectionView.isScrollEnabled = true
        collectionView.backgroundColor = UIColor.clear
        collectionView.dataSource = self
        collectionView.delegate = self
        ReactionCell.register(in: collectionView)
        view.addSubview(collectionView)

        noResultsView.isHidden = true
        configureNoResultsViewForContentType()
        view.addSubview(noResultsView)
    }

    private func configureNoResultsViewForContentType() {
        switch contentType {
        case .reactions:
            noResultsView.label.accessibilityLabel = "no likes"
            noResultsView.label.text = "message_details.empty_likes".localized.uppercased()
            noResultsView.icon = .like

        case .receipts:
            noResultsView.label.accessibilityLabel = "no read receipts"
            noResultsView.label.text = "message_details.empty_read_receipts".localized.uppercased()
            noResultsView.icon = .eye

        case .receiptsDisabled:
            noResultsView.label.accessibilityLabel = "read receipts disabled"
            noResultsView.label.text = "message_details.read_receipts_disabled".localized.uppercased()
            noResultsView.icon = .eye
        }
    }

    private func configureConstraints() {
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        noResultsView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            // noResultsView
            noResultsView.topAnchor.constraint(greaterThanOrEqualTo: view.topAnchor, constant: 12),
            noResultsView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            noResultsView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            noResultsView.bottomAnchor.constraint(lessThanOrEqualTo: view.bottomAnchor, constant: -12),
            noResultsView.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 24),
            noResultsView.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -24),

            // collectionView
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.topAnchor.constraint(equalTo: view.topAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    private func reloadData(_ old: [MessageDetailsCellDescription], _ new: [MessageDetailsCellDescription]) {
        collectionView.reloadData()
        //        let updates = {
//            let old = ZMOrderedSetState(orderedSet: NSOrderedSet(array: old))
//            let new = ZMOrderedSetState(orderedSet: NSOrderedSet(array: new))
//            let change = ZMChangedIndexes(start: old, end: new, updatedState: new, moveType: .uiCollectionView)
//
//            if let deleted = change?.deletedIndexes.indexPaths(in: 0) {
//                self.collectionView.deleteItems(at: deleted)
//            }
//
//            if let inserted = change?.insertedIndexes.indexPaths(in: 0) {
//                self.collectionView.insertItems(at: inserted)
//            }
//
//            change?.enumerateMovedIndexes { (oldIndex, newIndex) in
//                let oldIndexPath = IndexPath(item: Int(oldIndex), section: 0)
//                let newIndexPath = IndexPath(item: Int(newIndex), section: 0)
//                self.collectionView.moveItem(at: oldIndexPath, to: newIndexPath)
//            }
//        }
//
//        collectionView.performBatchUpdates(updates, completion: nil)
    }

}

extension MesageDetailsContentViewController: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return cells.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(ofType: ReactionCell.self, for: indexPath)
        let description = cells[indexPath.row]
        cell.configure(user: description.user, subtitle: description.subtitle)
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: collectionView.bounds.width, height: 52)
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        // todo: open user profile
    }

}
