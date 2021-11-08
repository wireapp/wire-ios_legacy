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

public enum DeniedAuthorizationType {
    case camera
    case photos
    case cameraAndPhotos
    case ongoingCall
}

class CameraKeyboardPermissionsCell: UICollectionViewCell {

    let settingsButton = Button()
    let cameraIcon = IconButton()
    let descriptionLabel = UILabel()

    private let containerView = UIView()

    public override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = .graphite

        cameraIcon.setIcon(.cameraLens, size: .tiny, for: .normal)
        cameraIcon.setIconColor(.white, for: .normal)
        cameraIcon.isUserInteractionEnabled = false

        descriptionLabel.backgroundColor = .clear
        descriptionLabel.textColor = .white
        descriptionLabel.numberOfLines = 0
        descriptionLabel.textAlignment = .center

        settingsButton.setTitleColor(.white, for: .normal)
        settingsButton.titleLabel?.font = UIFont.systemFont(ofSize: 16.0, weight: UIFont.Weight.semibold)
        settingsButton.setTitle("keyboard_photos_access.denied.keyboard.settings".localized, for: .normal)
        settingsButton.contentEdgeInsets = UIEdgeInsets(top: 10, left: 30, bottom: 10, right: 30)
        settingsButton.layer.cornerRadius = 4.0
        settingsButton.layer.masksToBounds = true
        settingsButton.addTarget(self, action: #selector(CameraKeyboardPermissionsCell.openSettings), for: .touchUpInside)
        settingsButton.setBackgroundImageColor(UIColor.white.withAlphaComponent(0.16), for: .normal)
        settingsButton.setBackgroundImageColor(UIColor.white.withAlphaComponent(0.24), for: .highlighted)
        containerView.backgroundColor = .clear

        containerView.addSubview(descriptionLabel)

        if SecurityFlags.cameraRoll.isEnabled { addSubview(containerView) }

    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    public convenience init(frame: CGRect, deniedAuthorization: DeniedAuthorizationType) {
        self.init(frame: frame)
        configure(deniedAuthorization: deniedAuthorization)
    }

    func configure(deniedAuthorization: DeniedAuthorizationType) {
        var title = ""

        switch deniedAuthorization {
        case .camera:           title = "keyboard_photos_access.denied.keyboard.camera"
        case .photos:           title = "keyboard_photos_access.denied.keyboard.photos"
        case .cameraAndPhotos:  title = "keyboard_photos_access.denied.keyboard.camera_and_photos"
        case .ongoingCall:      title = "keyboard_photos_access.denied.keyboard.ongoing_call"
        }

        descriptionLabel.font = UIFont.systemFont(ofSize: (deniedAuthorization == .ongoingCall ? 14.0 : 16.0),
                                                  weight: UIFont.Weight.light)
        descriptionLabel.text = title.localized

        if SecurityFlags.cameraRoll.isEnabled {
            createConstraints(deniedAuthorization: deniedAuthorization)
        }

    }

    @objc private func openSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString), UIApplication.shared.canOpenURL(url) else { return }
        UIApplication.shared.open(url)
    }

    private func createConstraints(deniedAuthorization: DeniedAuthorizationType) {

        [<#views#>].prepareForLayout()
        NSLayoutConstraint.activate([
          description.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 16),
          description.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -16),
          container.centerYAnchor.constraint(equalTo: selfView.centerYAnchor),
          container.leadingAnchor.constraint(equalTo: selfView.leadingAnchor),
          container.trailingAnchor.constraint(equalTo: selfView.trailingAnchor)
        ])

        if deniedAuthorization == .ongoingCall {
            createConstraintsForOngoingCallAlert()
        } else {
            createConstraintsForPermissionsAlert()
        }
    }

    private func createConstraintsForPermissionsAlert() {

        if cameraIcon.superview != nil {
            cameraIcon.removeFromSuperview()
        }
        containerView.addSubview(settingsButton)

        [<#views#>].prepareForLayout()
        NSLayoutConstraint.activate([
          settings.bottomAnchor.constraint(equalTo: container.bottomAnchor),
          settings.topAnchor.constraint(equalTo: description.bottomAnchor, constant: 24),
          settings.heightAnchor.constraint(equalTo: 44.0Anchor),
          settings.centerXAnchor.constraint(equalTo: container.centerXAnchor),
          description.topAnchor.constraint(equalTo: container.topAnchor)
        ])
    }

    private func createConstraintsForOngoingCallAlert() {

        if settingsButton.superview != nil {
            settingsButton.removeFromSuperview()
        }
        containerView.addSubview(cameraIcon)

        [<#views#>].prepareForLayout()
        NSLayoutConstraint.activate([
          description.bottomAnchor.constraint(equalTo: container.bottomAnchor),
          description.topAnchor.constraint(equalTo: cameraIcon.bottomAnchor, constant: 16),
          cameraIcon.topAnchor.constraint(equalTo: container.topAnchor),
          cameraIcon.centerXAnchor.constraint(equalTo: container.centerXAnchor)
        ])
    }

}
