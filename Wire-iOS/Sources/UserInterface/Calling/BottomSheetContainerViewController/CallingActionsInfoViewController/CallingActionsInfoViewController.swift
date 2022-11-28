//
// Wire
// Copyright (C) 2022 Wire Swiss GmbH
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
import WireDataModel

class CallingActionsInfoViewController: UIViewController, UICollectionViewDelegateFlowLayout {
    private let actionsViewHeight = 150.0
    private let cellHeight: CGFloat = 56
    private var topConstraint: NSLayoutConstraint?
    private let selfUser: UserType

    fileprivate var collectionView: CallParticipantsListView!
    private let actionsView = CallingActionsView()
    private let stackView = UIStackView(axis: .vertical)

    weak var actionsDelegate: CallingActionsViewDelegate? {
        didSet {
            actionsView.delegate = actionsDelegate
        }
    }

    var participants: CallParticipantsList {
        didSet {
            updateRows()
        }
    }
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

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        createConstraints()
        view.backgroundColor = .black
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updateRows()
    }

    private func setupViews() {
        stackView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stackView)
        stackView.axis = .vertical
        stackView.alignment = .center
        stackView.distribution = .fill
        stackView.spacing = 16

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
        stackView.addArrangedSubview(actionsView)
        stackView.addArrangedSubview(collectionView)
        CallParticipantsListCellConfiguration.prepare(collectionView)
    }


    private func createConstraints() {
        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            stackView.topAnchor.constraint(equalTo: view.topAnchor),
            stackView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            stackView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            actionsView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            actionsView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.widthAnchor.constraint(equalTo: stackView.widthAnchor),
            collectionView.heightAnchor.constraint(equalTo: view.heightAnchor, constant: -actionsViewHeight)
        ])
    }

    private func updateRows() {
        collectionView?.rows = participants
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: collectionView.bounds.size.width, height: cellHeight)
    }

    func collectionView(_ collectionView: UICollectionView, shouldHighlightItemAt indexPath: IndexPath) -> Bool {
        return false
    }

    func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        false
    }

    private func updateAppearance() {
        collectionView?.colorSchemeVariant = variant
    }
}

extension CallingActionsInfoViewController: CallInfoConfigurationObserver {
    func didUpdateConfiguration(configuration: CallInfoConfiguration) {
        actionsView.update(with: configuration)
    }
}
