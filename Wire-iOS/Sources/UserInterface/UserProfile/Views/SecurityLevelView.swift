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

final class SecurityLevelView: UIView {
    let securityLevelLabel = UILabel()

    init() {
        super.init(frame: .zero)

        setupViews()
        createConstraints()
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(with otherUsers: [UserType], variant: ColorSchemeVariant) {
        guard let userSession = ZMUserSession.shared() else { return }

        securityLevelLabel.font = FontSpec(.small, .bold).font

        switch userSession.classification(with: otherUsers) {
        case .none:
            isHidden = true

        case .classified:
            securityLevelLabel.text = "Classified" // TODO: Translation: Need to clarify
            securityLevelLabel.textColor = UIColor.from(scheme: .textForeground, variant: variant)
            backgroundColor = UIColor.from(scheme: .textBackground, variant: variant)

        case .notClassified:
            securityLevelLabel.text = "NOT Classified" // TODO: Translation: Need to clarify
            securityLevelLabel.textColor = UIColor.from(scheme: .textSecurityNotClassified, variant: variant)
            backgroundColor = UIColor.from(scheme: .backgroundSecurityNotClassified, variant: variant)
        }

        layer.borderWidth = 1
        layer.borderColor = UIColor.from(scheme: .separator).cgColor
    }

    private func setupViews() {
        translatesAutoresizingMaskIntoConstraints = false

        securityLevelLabel.textAlignment = .center
        addSubview(securityLevelLabel)
    }

    private func createConstraints() {
        securityLevelLabel.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
          securityLevelLabel.topAnchor.constraint(equalTo: topAnchor),
          securityLevelLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
          securityLevelLabel.heightAnchor.constraint(equalToConstant: 24),
          securityLevelLabel.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }
}
