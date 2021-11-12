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
import UIKit
import WireDataModel

protocol CallParticipantsListViewControllerDelegate: AnyObject {
    func callParticipantsListViewControllerDidSelectShowMore(viewController: CallParticipantsListViewController)
}

final class CallParticipantsListViewController: UIViewController, UICollectionViewDelegateFlowLayout {

    private let cellHeight: CGFloat = 56
    private var topConstraint: NSLayoutConstraint?
    weak var delegate: CallParticipantsListViewControllerDelegate?
    private let selfUser: UserType

    var participants: CallParticipantsList {
        didSet {
            updateRows()
        }
    }

    fileprivate var collectionView: CallParticipantsListView!
    let showParticipants: Bool

    var variant: ColorSchemeVariant = .light {
        didSet {
            updateAppearance()
        }
    }

    init(participants: CallParticipantsList,
         showParticipants: Bool,
         selfUser: UserType) {
        self.participants = participants
        self.showParticipants = showParticipants
        self.selfUser = selfUser
        super.init(nibName: nil, bundle: nil)
    }

    convenience init(scrollableWithConfiguration configuration: CallInfoViewControllerInput,
                     selfUser: UserType = ZMUser.selfUser()) {
        self.init(participants: configuration.accessoryType.participants,
                  showParticipants: true,
                  selfUser: selfUser)
        variant = configuration.effectiveColorVariant
        view.backgroundColor = configuration.overlayBackgroundColor
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
        view = PassthroughTouchesView()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        createConstraints()
        updateAppearance()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        topConstraint?.constant = navigationController?.navigationBar.frame.maxY ?? 0
    }

    private func setupViews() {
        title = "call.participants.list.title".localized(uppercased: true)
        let collectionViewLayout = UICollectionViewFlowLayout()
        collectionViewLayout.scrollDirection = .vertical
        collectionViewLayout.minimumInteritemSpacing = 12
        collectionViewLayout.minimumLineSpacing = 0

        let collectionView = CallParticipantsListView(collectionViewLayout: collectionViewLayout, selfUser: selfUser)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.bounces = showParticipants
        collectionView.delegate = self
        self.collectionView = collectionView
        view.addSubview(collectionView)
        CallParticipantsListCellConfiguration.prepare(collectionView)
    }

    private func createConstraints() {
        NSLayoutConstraint.activate([
            collectionView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            collectionView.leftAnchor.constraint(greaterThanOrEqualTo: view.leftAnchor),
            collectionView.rightAnchor.constraint(lessThanOrEqualTo: view.rightAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        let widthConstraint = collectionView.widthAnchor.constraint(equalToConstant: 414)
        widthConstraint.priority = UILayoutPriority.defaultHigh
        widthConstraint.isActive = true

        topConstraint = collectionView.topAnchor.constraint(equalTo: view.topAnchor)
        topConstraint?.isActive = true
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updateRows()
    }

    private func updateRows() {
        collectionView?.rows = showParticipants
            ? participants
            : [.showAll(totalCount: participants.count)]
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: collectionView.bounds.size.width, height: cellHeight)
    }

    func collectionView(_ collectionView: UICollectionView, shouldHighlightItemAt indexPath: IndexPath) -> Bool {
        guard case .showAll = self.collectionView.rows[indexPath.item] else { return false }
        return true
    }

    func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        guard case .showAll = self.collectionView.rows[indexPath.item] else { return false }
        return true
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: true)
        delegate?.callParticipantsListViewControllerDidSelectShowMore(viewController: self)
    }

    private func updateAppearance() {
        collectionView?.colorSchemeVariant = variant
    }

}
