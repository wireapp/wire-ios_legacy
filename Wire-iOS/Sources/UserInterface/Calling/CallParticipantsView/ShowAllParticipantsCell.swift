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

class ShowAllParticipantsCell: UICollectionViewCell {
    
    let participantIconView = UIImageView()
    let titleLabel = UILabel()
    let accessoryIconView = UIImageView()
    var contentStackView : UIStackView!
    
    override var isHighlighted: Bool {
        didSet {
            backgroundColor = isHighlighted
                ? .init(white: 0, alpha: 0.08)
                : .clear
        }
    }
    
    var variant : ColorSchemeVariant = ColorScheme.default.variant {
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
        accessibilityIdentifier = "cell.call.show_all_participants"
        participantIconView.translatesAutoresizingMaskIntoConstraints = false
        participantIconView.contentMode = .scaleAspectFit
        participantIconView.setContentHuggingPriority(UILayoutPriority.required, for: .horizontal)
        
        accessoryIconView.translatesAutoresizingMaskIntoConstraints = false
        accessoryIconView.contentMode = .center
        
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.font = FontSpec.init(.normal, .light).font!
        
        let avatarSpacer = UIView()
        avatarSpacer.addSubview(participantIconView)
        avatarSpacer.translatesAutoresizingMaskIntoConstraints = false
        avatarSpacer.widthAnchor.constraint(equalToConstant: 64).isActive = true
        avatarSpacer.heightAnchor.constraint(equalTo: participantIconView.heightAnchor).isActive = true
        avatarSpacer.centerXAnchor.constraint(equalTo: participantIconView.centerXAnchor).isActive = true
        avatarSpacer.centerYAnchor.constraint(equalTo: participantIconView.centerYAnchor).isActive = true
        
        let iconViewSpacer = UIView()
        iconViewSpacer.translatesAutoresizingMaskIntoConstraints = false
        iconViewSpacer.widthAnchor.constraint(equalToConstant: 8).isActive = true
        
        contentStackView = UIStackView(arrangedSubviews: [avatarSpacer, titleLabel, iconViewSpacer, accessoryIconView])
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
        let sectionTextColor = UIColor(scheme: .sectionText, variant: variant)
        backgroundColor = .clear
        participantIconView.image = UIImage(for: .person, iconSize: .tiny, color: UIColor(scheme: .textForeground, variant: variant))
        accessoryIconView.image = UIImage(for: .disclosureIndicator, iconSize: .like, color: sectionTextColor)
        titleLabel.textColor = UIColor(scheme: .textForeground, variant: variant)
    }
    
}

extension ShowAllParticipantsCell: CallParticipantsCellConfigurationConfigurable {
    func configure(with configuration: CallParticipantsCellConfiguration, variant: ColorSchemeVariant) {
        guard case let .showAll(totalCount: totalCount) = configuration else { preconditionFailure() }
        
        self.variant = variant
        titleLabel.text = "call.participants.show_all".localized(args: String(totalCount))
    }
}

extension ShowAllParticipantsCell: ParticipantsCellConfigurable {
    func configure(with rowType: ParticipantsRowType, conversation: ZMConversation, showSeparator: Bool) {
        guard case let .showAll(count) = rowType else { preconditionFailure() }
        titleLabel.text = "call.participants.show_all".localized(args: String(count))
        backgroundColor = .init(scheme: .barBackground)
    }
}
