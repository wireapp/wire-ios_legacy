//
// Wire
// Copyright (C) 2021 Wire Swiss GmbH
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
import Down

final class GuestLinkInfoCell: UITableViewCell, CellConfigurationConfigurable {

    // MARK: - Properties

    private let imageContainer = UIView()
    private let iconImageView = UIImageView()
    private let label = UILabel()

    typealias GuestRoomLinkStrings = L10n.Localizable.GuestRoom.Link.NotAllowed

    // MARK: - Life cycle

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupViews()
        createConstraints()
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Helpers

    private func setupViews() {
        backgroundColor = .clear
        imageContainer.addSubview(iconImageView)
        [imageContainer, label].forEach(contentView.addSubview)
    }

    private func createConstraints() {
        [label, imageContainer, iconImageView].prepareForLayout()
        NSLayoutConstraint.activate([
            imageContainer.topAnchor.constraint(equalTo: contentView.topAnchor),
            imageContainer.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            imageContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            imageContainer.widthAnchor.constraint(equalToConstant: 64),

            iconImageView.centerXAnchor.constraint(equalTo: imageContainer.centerXAnchor),
            iconImageView.centerYAnchor.constraint(equalTo: imageContainer.centerYAnchor),

            label.leadingAnchor.constraint(equalTo: imageContainer.trailingAnchor),
            label.topAnchor.constraint(equalTo: contentView.topAnchor),
            label.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            label.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])
    }

    // MARK: - Configuration

    func configure(with configuration: CellConfiguration, variant: ColorSchemeVariant) {
        guard case let .info(isSelfTeam) = configuration else { preconditionFailure() }
        accessibilityIdentifier = "guest_links.not_allowed.cell"
        iconImageView.setIcon(.about, size: .tiny, color: UIColor.from(scheme: .textForeground, variant: variant))

        let infoTextForSelfTeam = GuestRoomLinkStrings.ForSelfTeam.explanation
        let infoTextForOtherTeam = GuestRoomLinkStrings.ForOtherTeam.explanation

        let infoText = isSelfTeam ? infoTextForSelfTeam : infoTextForOtherTeam

        label.configMultipleLineLabel()
        label.attributedText = .markdown(from: infoText, style: .labelStyle)
        label.textColor = UIColor.from(scheme: .textForeground, variant: variant)
    }
}

private extension DownStyle {

    static var labelStyle: DownStyle {
        let style = DownStyle()
        style.baseFont = UIFont.systemFont(ofSize: 14)
        style.baseFontColor = UIColor.from(scheme: .textForeground)
        style.baseParagraphStyle = NSParagraphStyle.default

        return style
    }

}
