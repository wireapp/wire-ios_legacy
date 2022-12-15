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
import WireCommonComponents

protocol ClassificationProviding {
    func classification(with users: [UserType]) -> SecurityClassification
}

extension ZMUserSession: ClassificationProviding {}

final class SecurityLevelView: UIView {
    private let securityLevelLabel = UILabel()
    typealias SecurityLocalization = L10n.Localizable.SecurityClassification

    init() {
        super.init(frame: .zero)

        setupViews()
        createConstraints()

        isAccessibilityElement = true
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(with classification: SecurityClassification) {
        securityLevelLabel.font = FontSpec.smallSemiboldFont.font!

        guard
            classification != .none,
            let levelText = classification.levelText
        else {
            isHidden = true
            return
        }

        switch classification {

        case .classified:
            securityLevelLabel.textColor = SemanticColors.Label.textDefault
            backgroundColor = SemanticColors.View.backgroundSecurityLevel

        case .notClassified:
            securityLevelLabel.textColor = SemanticColors.Label.textDefault
            backgroundColor = SemanticColors.View.backgroundSecurityLevel

        default:
            isHidden = true
            assertionFailure("should not reach this point")
        }

        let securityLevelText = SecurityLocalization.securityLevel
        securityLevelLabel.text = [securityLevelText, levelText].joined(separator: " ")

        accessibilityIdentifier = "ClassificationBanner" + classification.accessibilitySuffix
    }

    func configure(
        with otherUsers: [UserType],
        provider: ClassificationProviding? = ZMUserSession.shared()
    ) {
        guard let classification = provider?.classification(with: otherUsers) else {
            isHidden = true
            return
        }

        configure(with: classification)
    }

    private func setupViews() {
        translatesAutoresizingMaskIntoConstraints = false

        securityLevelLabel.textAlignment = .center
        self.addBorder(for: .top)
        self.addBorder(for: .bottom)
        addSubview(securityLevelLabel)
    }

    private func createConstraints() {
        [securityLevelLabel].prepareForLayout()

        securityLevelLabel.fitIn(view: self)

        NSLayoutConstraint.activate([
          securityLevelLabel.heightAnchor.constraint(equalToConstant: 24)
        ])
    }
}

private extension SecurityClassification {

    typealias SecurityClassificationLevel = L10n.Localizable.SecurityClassification.Level

    var levelText: String? {
        switch self {
        case .none:
            return nil

        case .classified:
            return SecurityClassificationLevel.bund

        case .notClassified:
            return L10n.Localizable.SecurityClassification.Level.notClassified
        }
    }

    var accessibilitySuffix: String {
        switch self {
        case .none:
            return ""

        case .classified:
            return "Classified"

        case .notClassified:
            return "Unclassified"
        }
    }
}
