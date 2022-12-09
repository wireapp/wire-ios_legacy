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
import WireCommonComponents

class IncomingCallStatusView: UIView {
    let nameLabel = DynamicFontLabel(text: "Test Name",
                                     fontSpec: .largeSemiboldFont,
                                     color: SemanticColors.Label.textDefault)
    let callingLabel = DynamicFontLabel(text: L10n.Localizable.Voice.Calling.title,
                                        fontSpec: .mediumRegularFont,
                                        color: SemanticColors.Label.textDefault)
    let spaceView = UIView()
    let profileImageView = UIImageView()
    let stackView = UIStackView(axis: .vertical)

    init() {
        super.init(frame: .zero)
        setupViews()
        setupConstraints()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupViews() {
        stackView.translatesAutoresizingMaskIntoConstraints = false
        profileImageView.translatesAutoresizingMaskIntoConstraints = false
        spaceView.translatesAutoresizingMaskIntoConstraints = false
        stackView.alignment = .center
        stackView.spacing = 8
        addSubview(stackView)
        [nameLabel, callingLabel, spaceView, profileImageView].forEach(stackView.addArrangedSubview)
        profileImageView.layer.cornerRadius = 64.0
        profileImageView.layer.masksToBounds = true


        profileImageView.backgroundColor = .red
    }


    private func setupConstraints() {
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: topAnchor),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor),
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor),
            profileImageView.widthAnchor.constraint(equalToConstant: 128.0),
            profileImageView.heightAnchor.constraint(equalToConstant: 128.0),
            spaceView.heightAnchor.constraint(equalToConstant: 100.0),
            ])
    }
    func setCallerName(name: String) {
        nameLabel.text = name
    }

    func setProfileImage(_ image: UIImage?) {
        profileImageView.image = image
    }

}
