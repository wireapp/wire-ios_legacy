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
    private let participantsHeaderHeight: CGFloat = 42
    private let cellHeight: CGFloat = 56
    private var topConstraint: NSLayoutConstraint?
    private let selfUser: UserType

    fileprivate var collectionView: CallParticipantsListView!
    private let actionsView = CallingActionsView()
    private let stackView = UIStackView(axis: .vertical)
    private var participantsHeaderView = UIView()
    private var participantsHeaderLabel = DynamicFontLabel(fontSpec: .smallSemiboldFont, color: .sectionText)

    weak var actionsDelegate: CallingActionsViewDelegate? {
        didSet {
            actionsView.delegate = actionsDelegate
        }
    }

    var participants: CallParticipantsList {
        didSet {
            updateRows()
            participantsHeaderLabel.text = L10n.Localizable.Call.Participants.showAll(participants.count).uppercased()
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
        view.backgroundColor = UIColor.from(scheme: .callActionBackground, variant: ColorScheme.default.variant)
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
        stackView.spacing = 0

        actionsView.setContentHuggingPriority(.defaultHigh, for: .vertical)
        actionsView.setContentCompressionResistancePriority(.defaultLow, for: .vertical)

        let collectionViewLayout = UICollectionViewFlowLayout()
        collectionViewLayout.scrollDirection = .vertical
        collectionViewLayout.minimumInteritemSpacing = 12
        collectionViewLayout.minimumLineSpacing = 0

        participantsHeaderView.backgroundColor = SemanticColors.View.backgroundDefault
        participantsHeaderView.addSubview(participantsHeaderLabel)
        participantsHeaderLabel.translatesAutoresizingMaskIntoConstraints = false
        participantsHeaderLabel.applyStyle(.headerLabel)
        participantsHeaderLabel.accessibilityTraits.insert(.header)

        let collectionView = CallParticipantsListView(collectionViewLayout: collectionViewLayout, selfUser: selfUser)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.bounces = showParticipants
        collectionView.delegate = self
        self.collectionView = collectionView
        [actionsView, participantsHeaderView, collectionView].forEach(stackView.addArrangedSubview)
        CallParticipantsListCellConfiguration.prepare(collectionView)
    }


    private func createConstraints() {
        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            stackView.topAnchor.constraint(equalTo: view.topAnchor),
            stackView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            stackView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            participantsHeaderView.heightAnchor.constraint(equalToConstant: participantsHeaderHeight),
            participantsHeaderLabel.leadingAnchor.constraint(equalTo: participantsHeaderView.leadingAnchor, constant: 16.0),
            participantsHeaderLabel.centerYAnchor.constraint(equalTo: participantsHeaderView.centerYAnchor),

            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            participantsHeaderView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            participantsHeaderView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
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
