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
import WireCommonComponents

private enum EmptySearchResultsViewState {
    case noUsers
    case noServices
    case everyoneAdded
    case noServicesEnabled
}

enum EmptySearchResultsViewAction {
    case openManageServices
    case openSearchSupportPage
}

extension EmptySearchResultsViewAction {
    var title: String {
        switch self {
        case .openManageServices:
            return L10n.Localizable.Peoplepicker.NoMatchingResults.Action.manageServices
        case .openSearchSupportPage:
            return L10n.Localizable.Peoplepicker.NoMatchingResults.Action.learnMore
        }
    }
}

protocol EmptySearchResultsViewDelegate: class {
    func execute(action: EmptySearchResultsViewAction, from: EmptySearchResultsView)
}

final class EmptySearchResultsView: UIView {

    private var state: EmptySearchResultsViewState = .noUsers {
        didSet {
            iconView.image = icon
            statusLabel.text = self.text

            if let action = self.buttonAction {
                actionButton.isHidden = false
                actionButton.setTitle(action.title, for: .normal)
            }
            else {
                actionButton.isHidden = true
            }
        }
    }

    func updateStatus(searchingForServices: Bool, hasFilter: Bool) {
        switch (searchingForServices, hasFilter) {
        case (true, false):
            self.state = .noServicesEnabled
        case (true, true):
            self.state = .noServices
        case (false, true):
            self.state = .noUsers
        case (false, false):
            self.state = .everyoneAdded
        }
    }

    private let variant: ColorSchemeVariant
    private let isSelfUserAdmin: Bool
    private let isFederationEnabled: Bool

    private let stackView: UIStackView
    private let iconView     = UIImageView()
    private let statusLabel  = UILabel()
    private let actionButton: InviteButton

    weak var delegate: EmptySearchResultsViewDelegate?

    init(variant: ColorSchemeVariant,
         isSelfUserAdmin: Bool,
         isFederationEnabled: Bool) {
        self.variant = variant
        self.isSelfUserAdmin = isSelfUserAdmin
        self.isFederationEnabled = isFederationEnabled
        stackView = UIStackView()
        actionButton = InviteButton(variant: variant)
        super.init(frame: .zero)

        iconView.alpha = 0.24

        stackView.alignment = .center
        stackView.spacing = 16
        stackView.axis = .vertical
        stackView.alignment = .center

        stackView.translatesAutoresizingMaskIntoConstraints = false
        [iconView, statusLabel, actionButton].prepareForLayout()
        [iconView, statusLabel, actionButton].forEach(stackView.addArrangedSubview)

        addSubview(stackView)

        stackView.centerInSuperview()

        statusLabel.numberOfLines = 0
        statusLabel.preferredMaxLayoutWidth = 200
        statusLabel.textColor = UIColor.from(scheme: .textForeground, variant: self.variant)
        statusLabel.font = FontSpec(.medium, .regular).font!
        statusLabel.textAlignment = .center

        actionButton.accessibilityIdentifier = "button.searchui.open-services-no-results"

        actionButton.addCallback(for: .touchUpInside) { [unowned self] _ in
            guard let action = self.buttonAction else {
                return
            }
            self.delegate?.execute(action: action, from: self)
        }

        state = .noUsers
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private var text: String {
        switch state {
        case .everyoneAdded:
            return L10n.Localizable.Peoplepicker.NoMatchingResults.Message.usersAllAdded
        case .noUsers:
            if isFederationEnabled {
                return L10n.Localizable.Peoplepicker.NoMatchingResults.Message.usersAndFederation
            } else {
                return L10n.Localizable.Peoplepicker.NoMatchingResults.Message.users
            }
        case .noServices:
            return L10n.Localizable.Peoplepicker.NoMatchingResults.Message.services
        case .noServicesEnabled:
            if isSelfUserAdmin {
                return L10n.Localizable.Peoplepicker.NoMatchingResults.Message.servicesNotEnabledAdmin
            } else {
                return L10n.Localizable.Peoplepicker.NoMatchingResults.Message.servicesNotEnabled
            }
        }
    }

    private var icon: UIImage {
        let icon: StyleKitIcon

        switch state {
        case .noServices, .noServicesEnabled:
            icon = .bot
        default:
            icon = .personalProfile
        }

        let color = UIColor.from(scheme: .iconNormal, variant: self.variant)
        return icon.makeImage(size: .large, color: color)
    }

    private var buttonAction: EmptySearchResultsViewAction? {
        switch state {
        case .noServicesEnabled where isSelfUserAdmin:
            return .openManageServices
        case .noUsers:
            return .openSearchSupportPage
        default:
            return nil
        }
    }
}
