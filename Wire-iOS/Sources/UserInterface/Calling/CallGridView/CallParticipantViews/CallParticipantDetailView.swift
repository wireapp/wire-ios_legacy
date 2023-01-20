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
    private var microphoneWidth: NSLayoutConstraint?

    var microphoneIconStyle: MicrophoneIconStyle = .hidden {
        didSet {
            microphoneIconView.set(style: microphoneIconStyle)
            guard DeveloperFlag.isUpdatedCallingUI else { return }
            makeMicrophone(hidden: true)
            labelContainerView.backgroundColor = .black
            nameLabel.textColor = .white

            switch microphoneIconStyle {
            case .unmutedPulsing:
                labelContainerView.backgroundColor = UIColor.accent()
                nameLabel.textColor = SemanticColors.Label.textDefaultWhite
            case .muted:
                makeMicrophone(hidden: false)
            case .unmuted, .hidden:
                break
            }
        }
    }

    override init() {
        nameLabel = DeveloperFlag.isUpdatedCallingUI
        ? DynamicFontLabel(fontSpec: .mediumRegularFont, color: SemanticColors.Label.textWhite)
                    : UILabel(key: nil, size: .medium, weight: .semibold, color: .textForeground, variant: .dark)
        super.init()
    }

    override func setupViews() {
        super.setupViews()
        if DeveloperFlag.isUpdatedCallingUI {
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
                                                                             color: SemanticColors.Icon.foregroundMicrophone)
            microphoneImageView.backgroundColor = SemanticColors.Icon.foregroundDefaultWhite
            microphoneImageView.contentMode = .center
            microphoneImageView.layer.cornerRadius = 3.0
            microphoneImageView.layer.masksToBounds = true
            blurView.alpha = 0
        } else {
            setCornerRadius(12)
            microphoneIconView.set(size: .tiny, color: .white)
            [microphoneIconView, nameLabel].forEach {
                $0.translatesAutoresizingMaskIntoConstraints = false
                addSubview($0)
            }
        }
    }

    override func createConstraints() {
        super.createConstraints()
        if DeveloperFlag.isUpdatedCallingUI {
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

    private func makeMicrophone(hidden: Bool) {
            self.microphoneWidth?.constant = hidden ? 0 : 22
            self.setNeedsDisplay()
    }

    private func createUpdatedUIContraints() {
        labelContainerView.setContentCompressionResistancePriority(.required, for: .horizontal)
        microphoneWidth = microphoneImageView.widthAnchor.constraint(equalToConstant: 22)
        NSLayoutConstraint.activate([
            labelContainerView.centerXAnchor.constraint(equalTo: centerXAnchor).withPriority(.defaultLow),
            labelContainerView.centerYAnchor.constraint(equalTo: centerYAnchor),
            labelContainerView.leadingAnchor.constraint(greaterThanOrEqualTo: microphoneImageView.trailingAnchor, constant: 2.0),
            labelContainerView.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor),
            microphoneImageView.centerYAnchor.constraint(equalTo: centerYAnchor),
            microphoneImageView.leadingAnchor.constraint(equalTo: leadingAnchor),
            microphoneImageView.heightAnchor.constraint(equalToConstant: 22),
            microphoneWidth!
        ])
        NSLayoutConstraint.activate(
            NSLayoutConstraint.forView(view: nameLabel,
                                       inContainer: labelContainerView,
                                       withInsets: UIEdgeInsets.init(top: 4, left: 4, bottom: 4, right: 4))
        )
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        guard previousTraitCollection?.userInterfaceStyle != traitCollection.userInterfaceStyle else { return }
        microphoneImageView.image = StyleKitIcon.microphoneOff.makeImage(size: .tiny,
                                                                         color: SemanticColors.Icon.foregroundMicrophone)
    }
}
