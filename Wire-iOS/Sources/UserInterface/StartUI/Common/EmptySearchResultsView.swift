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


fileprivate enum EmptySearchResultsViewState {
    case noUsersOrServices
    case everyoneAdded
    case noServicesEnabled
}

enum EmptySearchResultsViewAction {
    case openManageServices
}

extension EmptySearchResultsViewAction {
    var title: String {
        switch self {
        case .openManageServices:
            return "peoplepicker.no_matching_results_services_manage_services_title".localized
        }
    }
}

protocol EmptySearchResultsViewDelegate: class {
    func execute(action: EmptySearchResultsViewAction, from: EmptySearchResultsView)
}

final class EmptySearchResultsView: UIView {
    
    private var state: EmptySearchResultsViewState = .noUsersOrServices {
        didSet {
            if let icon = self.icon {
                iconView.isHidden = false
                iconView.image = icon
            }
            else {
                iconView.isHidden = true
            }
            
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
        case (_, true):
            self.state = .noUsersOrServices
        case (false, false):
            self.state = .everyoneAdded
        }
    }
    
    private let variant: ColorSchemeVariant
    private let isSelfUserAdmin: Bool
    
    private let stackView: UIStackView
    private let iconView     = UIImageView()
    private let statusLabel  = UILabel()
    private let actionButton: InviteButton
    
    weak var delegate: EmptySearchResultsViewDelegate?
    
    init(variant: ColorSchemeVariant, isSelfUserAdmin: Bool) {
        self.variant = variant
        self.isSelfUserAdmin = isSelfUserAdmin
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
        statusLabel.font = FontSpec(.medium, .semibold).font!
        statusLabel.textAlignment = .center
        
        actionButton.accessibilityIdentifier = "button.searchui.open-services-no-results"
        
        actionButton.addCallback(for: .touchUpInside) { [unowned self] _ in
            guard let action = self.buttonAction else {
                return
            }
            self.delegate?.execute(action: action, from: self)
        }
        
        state = .noUsersOrServices
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private var text: String {
        switch (state, isSelfUserAdmin) {
        case (.noUsersOrServices, _):
            return "peoplepicker.no_matching_results_after_address_book_upload_title".localized
        case (.everyoneAdded, _):
            return "add_participants.all_contacts_added".localized
        case (.noServicesEnabled, false):
            return "peoplepicker.no_matching_results_services_title".localized
        case (.noServicesEnabled, true):
            return "peoplepicker.no_matching_results_services_admin_title".localized
        }
    }
    
    private var icon: UIImage? {
        switch state {
        case .noServicesEnabled:
            return StyleKitIcon.bot.makeImage(size: .large, color: UIColor.from(scheme: .iconNormal, variant: self.variant))
        default:
            return nil
        }
    }
    
    private var buttonAction: EmptySearchResultsViewAction? {
        switch (state, isSelfUserAdmin) {
        case (.noServicesEnabled, true):
            return .openManageServices
        default:
            return nil
        }
    }
}
