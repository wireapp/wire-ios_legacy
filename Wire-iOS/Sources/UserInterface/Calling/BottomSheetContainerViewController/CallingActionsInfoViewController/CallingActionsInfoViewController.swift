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
    private let participantsHeaderHeight: CGFloat = 42
    private let cellHeight: CGFloat = 56
    private var topConstraint: NSLayoutConstraint?
    private let selfUser: UserType

    private var collectionView: CallParticipantsListView!
    private let stackView = UIStackView(axis: .vertical)
    private var participantsHeaderView = UIView()
    private let securityLevelView = SecurityLevelView()
    private var participantsHeaderLabel = DynamicFontLabel(fontSpec: .smallSemiboldFont, color: SemanticColors.Label.textSectionHeader)
    private var actionsViewHeightConstraint: NSLayoutConstraint!
    var isIncomingCall: Bool = false

    let actionsView = CallingActionsView()

    var participants: CallParticipantsList {
        didSet {
            updateRows()
            participantsHeaderLabel.text = L10n.Localizable.Call.Participants.showAll(participants.count).uppercased()
        }
    }

    var variant: ColorSchemeVariant = .light {
        didSet {
            updateAppearance()
        }
    }

    init(participants: CallParticipantsList,
         selfUser: UserType) {
        self.participants = participants
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
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updateRows()
    }

    func setCallingActionsViewDelegate(actionsDelegate: CallingActionsViewDelegate?) {
        actionsView.delegate = actionsDelegate
    }

    private func setupViews() {
        stackView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stackView)
        stackView.axis = .vertical
        stackView.alignment = .center
        stackView.distribution = .fill
        stackView.spacing = 0
        let collectionViewLayout = UICollectionViewFlowLayout()
        collectionViewLayout.scrollDirection = .vertical
        collectionViewLayout.minimumInteritemSpacing = 12
        collectionViewLayout.minimumLineSpacing = 0

        participantsHeaderView.backgroundColor = SemanticColors.View.backgroundDefault
        participantsHeaderView.addSubview(participantsHeaderLabel)
        participantsHeaderLabel.translatesAutoresizingMaskIntoConstraints = false
        participantsHeaderLabel.applyStyle(.headerLabel)
        participantsHeaderLabel.accessibilityTraits.insert(.header)
        participantsHeaderLabel.text = L10n.Localizable.Call.Participants.showAll(participants.count).uppercased()

        let collectionView = CallParticipantsListView(collectionViewLayout: collectionViewLayout, selfUser: selfUser)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.bounces = true
        collectionView.delegate = self
        self.collectionView = collectionView
        [actionsView, securityLevelView, participantsHeaderView, collectionView].forEach(stackView.addArrangedSubview)
        CallParticipantsListCellConfiguration.prepare(collectionView)
        view.backgroundColor = SemanticColors.View.backgroundDefaultWhite
    }

    private func createConstraints() {
        actionsViewHeightConstraint = actionsView.heightAnchor.constraint(equalToConstant: 128.0)
        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: view.safeLeadingAnchor),
            stackView.topAnchor.constraint(equalTo: view.safeTopAnchor),
            stackView.trailingAnchor.constraint(equalTo: view.safeTrailingAnchor),
            stackView.bottomAnchor.constraint(equalTo: view.safeBottomAnchor, constant: -20),

            actionsView.leadingAnchor.constraint(equalTo: view.safeLeadingAnchor),
            actionsView.trailingAnchor.constraint(equalTo: view.safeTrailingAnchor),
            actionsViewHeightConstraint,

            participantsHeaderView.heightAnchor.constraint(equalToConstant: participantsHeaderHeight),
            participantsHeaderLabel.leadingAnchor.constraint(equalTo: participantsHeaderView.leadingAnchor, constant: 16.0),
            participantsHeaderLabel.centerYAnchor.constraint(equalTo: participantsHeaderView.centerYAnchor),

            collectionView.leadingAnchor.constraint(equalTo: view.safeLeadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.safeTrailingAnchor),
            participantsHeaderView.leadingAnchor.constraint(equalTo: view.safeLeadingAnchor),
            participantsHeaderView.trailingAnchor.constraint(equalTo: view.safeTrailingAnchor),
            securityLevelView.widthAnchor.constraint(equalTo: stackView.widthAnchor)
        ])
    }

    func updateActionViewHeight() {
        guard UIDevice.current.orientation.isLandscape else {
            actionsViewHeightConstraint.constant =  isIncomingCall ? 230 : 128
            actionsView.verticalStackView.alignment = .fill
            return
        }
        actionsViewHeightConstraint.constant =  128.0
        actionsView.verticalStackView.alignment = .center
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
        isIncomingCall = configuration.state.isIncoming
        actionsView.isIncomingCall = isIncomingCall
        actionsView.update(with: configuration)
        updateActionViewHeight()
        securityLevelView.configure(with: configuration.classification)
    }
}
