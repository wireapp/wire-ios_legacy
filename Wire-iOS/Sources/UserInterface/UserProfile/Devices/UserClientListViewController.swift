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

import Foundation
import UIKit
import WireSyncEngine

final class UserClientListViewController: UIViewController, UICollectionViewDelegateFlowLayout, UICollectionViewDataSource {

    fileprivate let headerView: ParticipantDeviceHeaderView
    fileprivate let collectionView = UICollectionView(forGroupedSections: ())
    fileprivate var clients: [UserClientType]
    fileprivate var tokens: [Any?] = []
    fileprivate var user: UserType

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return wr_supportedInterfaceOrientations
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return ColorScheme.default.statusBarStyle
    }

    init(user: UserType) {
        self.user = user
        self.clients = UserClientListViewController.clientsSortedByRelevance(for: user)
        self.headerView = ParticipantDeviceHeaderView(userName: user.name ?? "")

        super.init(nibName: nil, bundle: nil)

        if let userSession = ZMUserSession.shared() {
            tokens.append(UserChangeInfo.add(observer: self, for: user, in: userSession))
        }

        self.headerView.delegate = self

        title = "profile.devices.title".localized
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        createConstraints()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        (user as? ZMUser)?.fetchUserClients()
    }

    private func setupViews() {
        headerView.translatesAutoresizingMaskIntoConstraints = false
        headerView.showUnencryptedLabel = (user as? ZMUser)?.clients.count == 0

        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.delegate = self
        collectionView.dataSource = self

        UserClientCell.register(in: collectionView)
        collectionView.register(CollectionViewCellAdapter.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: CollectionViewCellAdapter.zm_reuseIdentifier)

        view.addSubview(collectionView)
        view.backgroundColor = UIColor.from(scheme: .contentBackground)
    }

    private func createConstraints() {
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: view.topAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    fileprivate static func clientsSortedByRelevance(for user: UserType) -> [UserClientType] {
        return user.allClients.sortedByRelevance().filter({ !$0.isSelfClient() })
    }

    // MARK: - UICollectionViewDelegateFlowLayout & UICollectionViewDataSource

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        headerView.size(fittingWidth: collectionView.bounds.size.width)

        return headerView.bounds.size
    }

    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        let headerViewCell = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: CollectionViewCellAdapter.zm_reuseIdentifier, for: indexPath) as! CollectionViewCellAdapter

        headerViewCell.wrappedView = headerView

        return headerViewCell
    }

    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return clients.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(ofType: UserClientCell.self, for: indexPath)
        let client = clients[indexPath.row]

        cell.configure(with: client)

        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let client = clients[indexPath.row]
        let profileClientViewController = ProfileClientViewController(client: client as! UserClient, fromConversation: true) // TODO jacob don't force unwrap
        profileClientViewController.showBackButton = false

        show(profileClientViewController, sender: nil)
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return .init(width: view.bounds.size.width, height: 64)
    }
}

extension UserClientListViewController: ZMUserObserver {

    func userDidChange(_ changeInfo: UserChangeInfo) {
        guard changeInfo.clientsChanged || changeInfo.trustLevelChanged else { return }

        ///TODO: add clients to userType
        headerView.showUnencryptedLabel = (user as? ZMUser)?.clients.isEmpty == true
        clients = UserClientListViewController.clientsSortedByRelevance(for: user)
        collectionView.reloadData()
    }

}

extension UserClientListViewController: ParticipantDeviceHeaderViewDelegate {
    func participantsDeviceHeaderViewDidTapLearnMore(_ headerView: ParticipantDeviceHeaderView) {
        URL.wr_fingerprintLearnMore.openInApp(above: self)
    }
}
