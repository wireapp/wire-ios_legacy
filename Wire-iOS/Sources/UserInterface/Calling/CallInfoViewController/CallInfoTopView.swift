//
// Wire
// Copyright (C) 2020 Wire Swiss GmbH
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

protocol CallInfoTopViewDelegate: class {
    func callInfoTopViewDidAskToMinimizeOverlay(_ callInfoTopView: UIView)
}

class CallInfoTopView: UIView {
    
    weak var delegate: CallInfoTopViewDelegate?
    
    var variant: ColorSchemeVariant? {
        didSet {
            minimizeButton.setIconColor(minimizeButtonColor, for: .normal)
        }
    }
    
    private var minimizeButtonColor: UIColor {
        let variant = self.variant ?? .light
        return UIColor.from(scheme: .textForeground, variant: variant)
    }
    
    private let conferenceCallingBadge: UILabel = {
        let label = UILabel()
        label.text = "call.status.conference_call".localized(uppercased: true)
        label.backgroundColor = .accent()
        label.layer.cornerRadius = 8.0
        label.layer.masksToBounds = true
        label.font = .smallSemiboldFont
        label.textAlignment = .center
        label.textColor = .white
        label.translatesAutoresizingMaskIntoConstraints = false
        label.accessibilityIdentifier = "ConferenceCallingBadge"
        return label
    }()
    
    private let minimizeButton: IconButton = {
        let button = IconButton(style: .default)
        button.setIcon(.downArrow, size: .tiny, for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.accessibilityLabel = "call.actions.label.minimize_call".localized
        button.accessibilityIdentifier = "CallDismissOverlayButton"
        return button
    }()
        
    override init(frame: CGRect) {
        super.init(frame: .zero)
        setupViews()
        createConstraints()
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - UI Setup
    private func setupViews() {
        addSubview(conferenceCallingBadge)
        addSubview(minimizeButton)
        minimizeButton.addTarget(self, action: #selector(minimizeOverlay(_:)), for: .touchUpInside)
    }
    
    private func createConstraints() {
        NSLayoutConstraint.activate([
            conferenceCallingBadge.centerYAnchor.constraint(equalTo: centerYAnchor),
            conferenceCallingBadge.heightAnchor.constraint(equalToConstant: 16),
            conferenceCallingBadge.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -48),
            conferenceCallingBadge.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 48),
            minimizeButton.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            minimizeButton.centerYAnchor.constraint(equalTo: centerYAnchor),
            minimizeButton.widthAnchor.constraint(equalToConstant: 16),
            minimizeButton.heightAnchor.constraint(equalToConstant: 16)
        ])
    }
    
    // MARK: - Interface
    func setBadge(hidden: Bool) {
        conferenceCallingBadge.isHidden = hidden
    }
    
    // MARK: - Action
    @objc func minimizeOverlay(_ sender: IconButton) {
        delegate?.callInfoTopViewDidAskToMinimizeOverlay(self)
    }
}
