//
// Wire
// Copyright (C) 2019 Wire Swiss GmbH
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

final class ParticipantDeviceCell: UITableViewCell {

    private var nameLabel: UILabel!
    private let boldFingerprintFont: UIFont = .smallSemiboldFont
    private let fingerprintFont: UIFont = .smallFont
    private var identifierLabel: UILabel!
    private var trustLevelImageView: UIImageView!

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        backgroundColor = UIColor.clear
        selectionStyle = .none
        accessoryType = .disclosureIndicator

        createViews()
        setupConstraints()
        setupStyle()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func createViews() {
        nameLabel = UILabel()
        contentView.addSubview(nameLabel)

        identifierLabel = UILabel()
        contentView.addSubview(identifierLabel)

        trustLevelImageView = UIImageView()
        trustLevelImageView.contentMode = .scaleAspectFit
        trustLevelImageView.clipsToBounds = true
        contentView.addSubview(trustLevelImageView)
    }

    private func setupConstraints() {
        [trustLevelImageView,
         nameLabel,
         identifierLabel].forEach() { $0.translatesAutoresizingMaskIntoConstraints = false }

        var constraints: [NSLayoutConstraint] = []

        constraints += trustLevelImageView.setDimensions(length: 16, activate: false)
        constraints.append(trustLevelImageView.pinToSuperview(anchor: .leading, inset: 24, activate: false))
        constraints.append(trustLevelImageView.pin(to: nameLabel, axisAnchor: .centerY, activate: false))

        constraints.append(nameLabel.pinToSuperview(anchor: .top, inset: 16, activate: false))
        constraints.append(nameLabel.leadingAnchor.constraint(equalTo: trustLevelImageView.trailingAnchor, constant: 16))

        constraints.append(identifierLabel.pin(to: nameLabel, anchor: .leading, activate: false))
        constraints.append(identifierLabel.topAnchor.constraint(greaterThanOrEqualTo: nameLabel.bottomAnchor))
        constraints.append(identifierLabel.pinToSuperview(anchor: .bottom, inset: 16, activate: false))

        NSLayoutConstraint.activate(constraints)
    }

    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        super.setHighlighted(highlighted, animated: animated)
        backgroundColor = highlighted ? UIColor(white: 0, alpha: 0.08) : UIColor.clear
    }

    // MARK: - Configuration

    @objc(configureForClient:)
    func configure(for client: UserClientType & UserClientTypeAttributedString) {
        let attributes: [NSAttributedString.Key: AnyObject] = [NSAttributedString.Key.font: fingerprintFont.monospaced()]
        let boldAttributes: [NSAttributedString.Key: AnyObject] = [NSAttributedString.Key.font: boldFingerprintFont.monospaced()]

        identifierLabel.attributedText = client.attributedRemoteIdentifier(attributes, boldAttributes: boldAttributes, uppercase: true)
        nameLabel.text = client.deviceClass?.uppercased() ?? client.type.uppercased()


        trustLevelImageView.image = client.verified ? WireStyleKit.imageOfShieldverified : WireStyleKit.imageOfShieldnotverified
    }

    private func setupStyle() {
        nameLabel.textColor = .from(scheme: .textForeground)
        nameLabel.font = .smallSemiboldFont

        identifierLabel.textColor = .from(scheme: .textForeground)
    }
}
