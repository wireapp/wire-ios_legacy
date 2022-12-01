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

import Foundation
import UIKit
import WireCommonComponents

final class CallParticipantDetailsView: RoundedBlurView {
    private let nameLabel: UILabel

    private let microphoneIconView = PulsingIconImageView()

    var name: String? {
        didSet {
            nameLabel.text = name
        }
    }

    private let labelContainerView = UIView()
    private let microphoneImageView = UIImageView()

    var microphoneIconStyle: MicrophoneIconStyle = .hidden {
        didSet {
            microphoneIconView.set(style: microphoneIconStyle)
            guard DeveloperFlag.updatedCallingUI.isOn else { return }
            microphoneImageView.isHidden = true
            labelContainerView.backgroundColor = .black
            nameLabel.textColor = .white

            switch microphoneIconStyle {
            case .unmutedPulsing:
                labelContainerView.backgroundColor = UIColor.accent()
                nameLabel.textColor = SemanticColors.Label.textDefaultWhite
            case .muted:
                microphoneImageView.isHidden = false
            case .unmuted, .hidden:
                break
            }
        }
    }

    override init() {
        nameLabel = DeveloperFlag.updatedCallingUI.isOn
                    ? DynamicFontLabel(fontSpec: .mediumRegularFont, color: .white)
                    : UILabel(key: nil, size: .medium, weight: .semibold, color: .textForeground, variant: .dark)
        super.init()
    }

    override func setupViews() {
        super.setupViews()
        setCornerRadius(12)

        if DeveloperFlag.updatedCallingUI.isOn {
            [microphoneImageView, labelContainerView].forEach {
                $0.translatesAutoresizingMaskIntoConstraints = false
                addSubview($0)
            }
            nameLabel.translatesAutoresizingMaskIntoConstraints = false
            labelContainerView.addSubview(nameLabel)
            labelContainerView.backgroundColor = .black
            labelContainerView.layer.cornerRadius = 3.0
            labelContainerView.layer.masksToBounds = true
            microphoneImageView.image = StyleKitIcon.microphoneOff.makeImage(size: .tiny,
                                                                             color: SemanticColors.Icon.foregroundMuted)
            microphoneImageView.backgroundColor = SemanticColors.Icon.backgroundMuted
            microphoneImageView.contentMode = .center
            microphoneImageView.layer.cornerRadius = 3.0
            microphoneImageView.layer.masksToBounds = true
            blurView.alpha = 0
        } else {
            microphoneIconView.set(size: .tiny, color: .white)
            [microphoneIconView, nameLabel].forEach {
                $0.translatesAutoresizingMaskIntoConstraints = false
                addSubview($0)
            }
        }
    }

    func hideMicrophonePermamently() {
        microphoneImageView.widthAnchor.constraint(equalToConstant: 0).isActive = true
    }

    override func createConstraints() {
        super.createConstraints()
        if DeveloperFlag.updatedCallingUI.isOn {
            createUpdatedUIContraints()
            return
        }

        NSLayoutConstraint.activate([
            nameLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8),
            nameLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
            nameLabel.leadingAnchor.constraint(equalTo: microphoneIconView.trailingAnchor, constant: 4),
            microphoneIconView.centerYAnchor.constraint(equalTo: centerYAnchor),
            microphoneIconView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 4),
            microphoneIconView.widthAnchor.constraint(equalToConstant: 16),
            microphoneIconView.heightAnchor.constraint(equalToConstant: 16)
        ])
    }
    private func createUpdatedUIContraints() {
        NSLayoutConstraint.activate([
            labelContainerView.centerYAnchor.constraint(equalTo: centerYAnchor),
            labelContainerView.leadingAnchor.constraint(greaterThanOrEqualTo: microphoneImageView.trailingAnchor, constant: 4),
            labelContainerView.centerXAnchor.constraint(equalTo: centerXAnchor),
            microphoneImageView.centerYAnchor.constraint(equalTo: centerYAnchor),
            microphoneImageView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 6),
            microphoneImageView.widthAnchor.constraint(equalToConstant: 22),
            microphoneImageView.heightAnchor.constraint(equalToConstant: 22)
        ])
        NSLayoutConstraint.activate(
            NSLayoutConstraint.forView(view: nameLabel,
                                       inContainer: labelContainerView,
                                       withInsets: UIEdgeInsets.init(top: 4, left: 4, bottom: 4, right: 4))
        )
    }
}
