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

import UIKit
import WireExtensionComponents

class GroupDetailsGuestOptionsCell: UICollectionViewCell {
    
    let guestIconView = UIImageView()
    let accessoryIconView = UIImageView()
    let titleLabel = UILabel()
    let statusLabel = UILabel()
    var contentStackView : UIStackView!
    
    var isOn = false {
        didSet {
            let key = "group_details.guest_options_cell.\(isOn ? "enabled" : "disabled")"
            statusLabel.text = key.localized
        }
    }
    
    override var isHighlighted: Bool {
        didSet {
            backgroundColor = isHighlighted
                ? .init(white: 0, alpha: 0.08)
                : .wr_color(fromColorScheme: ColorSchemeColorBarBackground, variant: variant)
        }
    }
    
    var variant : ColorSchemeVariant = ColorScheme.default().variant {
        didSet {
            guard oldValue != variant else { return }
            configureColors()
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
    
    fileprivate func setup() {
        accessibilityIdentifier = "cell.groupdetails.guestoptions"
        guestIconView.translatesAutoresizingMaskIntoConstraints = false
        guestIconView.contentMode = .scaleAspectFit
        guestIconView.setContentHuggingPriority(UILayoutPriority.required, for: .horizontal)
        
        accessoryIconView.translatesAutoresizingMaskIntoConstraints = false
        accessoryIconView.contentMode = .center
        
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.font = FontSpec.init(.normal, .light).font!
        titleLabel.text = "group_details.guest_options_cell.title".localized
        
        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        statusLabel.font = FontSpec.init(.normal, .light).font!
        statusLabel.setContentHuggingPriority(UILayoutPriority.required, for: .horizontal)
        
        let avatarSpacer = UIView()
        avatarSpacer.addSubview(guestIconView)
        avatarSpacer.translatesAutoresizingMaskIntoConstraints = false
        avatarSpacer.widthAnchor.constraint(equalToConstant: 64).isActive = true
        avatarSpacer.heightAnchor.constraint(equalTo: guestIconView.heightAnchor).isActive = true
        avatarSpacer.centerXAnchor.constraint(equalTo: guestIconView.centerXAnchor).isActive = true
        avatarSpacer.centerYAnchor.constraint(equalTo: guestIconView.centerYAnchor).isActive = true

        let iconViewSpacer = UIView()
        iconViewSpacer.translatesAutoresizingMaskIntoConstraints = false
        iconViewSpacer.widthAnchor.constraint(equalToConstant: 8).isActive = true
        
        contentStackView = UIStackView(arrangedSubviews: [avatarSpacer, titleLabel, statusLabel, iconViewSpacer, accessoryIconView])
        contentStackView.axis = .horizontal
        contentStackView.distribution = .fill
        contentStackView.alignment = .center
        contentStackView.translatesAutoresizingMaskIntoConstraints = false
        
        contentView.addSubview(contentStackView)
        contentStackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor).isActive = true
        contentStackView.topAnchor.constraint(equalTo: contentView.topAnchor).isActive = true
        contentStackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor).isActive = true
        contentStackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16).isActive = true
        
        configureColors()
    }
    
    private func configureColors() {
        let sectionTextColor = UIColor.wr_color(fromColorScheme: ColorSchemeColorSectionText, variant: variant)
        backgroundColor = .wr_color(fromColorScheme: ColorSchemeColorBarBackground, variant: variant)
        guestIconView.image = UIImage(for: .guest, iconSize: .tiny, color: UIColor.wr_color(fromColorScheme: ColorSchemeColorTextForeground, variant: variant))
        accessoryIconView.image = UIImage(for: .disclosureIndicator, iconSize: .like, color: sectionTextColor)
        titleLabel.textColor = .wr_color(fromColorScheme: ColorSchemeColorTextForeground, variant: variant)
        statusLabel.textColor = sectionTextColor
    }
    
}
