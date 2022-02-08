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
import WireSyncEngine

protocol ClassificationProviding {
    func classification(with users: [UserType]) -> SecurityClassification
}

extension ZMUserSession: ClassificationProviding {}

final class SecurityLevelView: UIView {
    private let securityLevelLabel = UILabel()

    init() {
        super.init(frame: .zero)

        setupViews()
        createConstraints()
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(with classification: SecurityClassification) {
        securityLevelLabel.font = FontSpec(.small, .bold).font

        guard
            classification != .none,
            let levelText = classification.levelText
        else {
            return
        }

        switch classification {
        case .none:
            isHidden = true

        case .classified:
            securityLevelLabel.textColor = UIColor.from(scheme: .textForeground)
            backgroundColor = UIColor.from(scheme: .textBackground)

        case .notClassified:
            securityLevelLabel.textColor = UIColor.from(scheme: .textSecurityNotClassified)
            backgroundColor = UIColor.from(scheme: .backgroundSecurityNotClassified)
        }

        let securityLevelText = L10n.Localizable.SecurityClassification.securityLevel
        securityLevelLabel.text = [securityLevelText, levelText].joined(separator: " ")

        layer.borderWidth = 1
        layer.borderColor = UIColor.from(scheme: .separator).cgColor
    }

    func configure(
        with otherUsers: [UserType],
        provider: ClassificationProviding? = ZMUserSession.shared()
    ) {
        guard let classification = provider?.classification(with: otherUsers) else { return }

        configure(with: classification)
    }

    private func setupViews() {
        translatesAutoresizingMaskIntoConstraints = false

        securityLevelLabel.textAlignment = .center
        addSubview(securityLevelLabel)
    }

    private func createConstraints() {
        securityLevelLabel.translatesAutoresizingMaskIntoConstraints = false

        securityLevelLabel.fitIn(view: self)

        NSLayoutConstraint.activate([
          securityLevelLabel.heightAnchor.constraint(equalToConstant: 24)
        ])
    }
}

private extension SecurityClassification {
    var levelText: String? {
        switch self {
        case .none:
            return nil

        case .classified:
            return L10n.Localizable.SecurityClassification.Level.bund

        case .notClassified:
            return L10n.Localizable.SecurityClassification.Level.notClassified
        }
    }
}
