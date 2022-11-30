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

class CallHeaderBar: UIView {
    private let titleLabel = DynamicFontLabel(fontSpec: .mediumSemiboldFont, color:  SemanticColors.Label.textDefault)
    private let avatarView = UIImageView()

    init() {
        super.init(frame: .zero)
        backgroundColor = SemanticColors.View.backgroundDefault
        setupViews()
        setupConstraints()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupViews() {
        avatarView.backgroundColor = SemanticColors.View.backgroundAvatar
        avatarView.layer.masksToBounds = true
        avatarView.layer.cornerRadius = 6.0
        avatarView.contentMode = .scaleToFill
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        avatarView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(titleLabel)
        addSubview(avatarView)
    }

    private func setupConstraints() {
        NSLayoutConstraint.activate([
            titleLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            titleLabel.centerYAnchor.constraint(equalTo: centerYAnchor, constant: 14.0),
            avatarView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20.0),
            avatarView.centerYAnchor.constraint(equalTo: centerYAnchor, constant: 14.0),
            avatarView.widthAnchor.constraint(equalToConstant: 26.0),
            avatarView.heightAnchor.constraint(equalToConstant: 26.0)
        ])
    }

    func setTitle(title: String) {
        titleLabel.text = title
    }

    func setAvatar(_ avatar: UIImage) {
        avatarView.image = avatar
    }
}
