//
// Wire
// Copyright (C) 2016 Wire Swiss GmbH
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
import Cartography


@objc enum ProfileHeaderStyle: Int {
    case cancelButton, backButton, noButton
}


final class ProfileHeaderView: UIView {

    var showVerifiedShield = false {
        didSet {
            updateVerifiedShield()
        }
    }

    private(set) var dismissButton = IconButton.iconButtonCircular()
    private(set) var headerStyle: ProfileHeaderStyle

    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let correlationLabel = UILabel()
    private let verifiedImageView = UIImageView(image: WireStyleKit.imageOfShieldverified())

    @objc(initWithViewModel:)
    init(with viewModel: ProfileHeaderViewModel) {
        headerStyle = viewModel.style
        super.init(frame: .zero)

        setupViews()
        configure(with: viewModel)
        createConstraints()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupViews() {
        translatesAutoresizingMaskIntoConstraints = false

        [titleLabel, subtitleLabel, correlationLabel].forEach {
            $0.textAlignment = .center
            $0.backgroundColor = .clear
        }

        [titleLabel, subtitleLabel, correlationLabel, dismissButton, verifiedImageView].forEach(addSubview)
        verifiedImageView.isHidden = true

        verifiedImageView.accessibilityIdentifier = "VerifiedShield"
        dismissButton.accessibilityIdentifier = "OtherUserProfileCloseButton"

        switch headerStyle {
        case .backButton: dismissButton.setIcon(.chevronLeft, with: .tiny, for: .normal)
        case .cancelButton: dismissButton.setIcon(.X, with: .tiny, for: .normal)
        default: break
        }
    }

    private func createConstraints() {
        let topMargin = WAZUIMagic.cgFloat(forIdentifier: "profile_temp.content_top_margin")
        let horizontalMargin = WAZUIMagic.cgFloat(forIdentifier: "profile_temp.content_left_margin")

        constrain(self, titleLabel, subtitleLabel, correlationLabel) { view, title, subtitle, correlation in
            title.top == view.top + topMargin
            title.height == 32
            title.leading == view.leading + horizontalMargin + 32
            title.trailing == view.trailing - (horizontalMargin + 32)

            subtitle.top == title.bottom + 10
            subtitle.centerX == view.centerX
            subtitle.height == 16

            correlation.top == subtitle.bottom
            correlation.centerX == view.centerX
            correlation.height == 16
            correlation.bottom == view.bottom - 12
        }

        constrain(self, dismissButton, verifiedImageView, titleLabel) { view, dismiss, verified, title in
            dismiss.top == view.top + 24
            dismiss.width == dismiss.height
            dismiss.width == 32

            verified.centerY == title.centerY
            verified.width == verified.height
            verified.width == 16
            verified.leading == view.leading + horizontalMargin

            switch headerStyle {
            case .backButton: dismiss.leading == view.leading + horizontalMargin
            case .cancelButton: dismiss.trailing == view.trailing - horizontalMargin
            default: break
            }
        }
    }

    private func configure(with model: ProfileHeaderViewModel) {
        titleLabel.attributedText = model.title
        subtitleLabel.attributedText = model.subtitle
        correlationLabel.attributedText = model.correlationText
    }

    private func updateVerifiedShield() {
        var shouldHide = true
        if headerStyle != .backButton {
            shouldHide = !showVerifiedShield
        }
        UIView.transition(with: verifiedImageView, duration: 0.2, options: .transitionCrossDissolve, animations: {
            self.verifiedImageView.isHidden = shouldHide
            }, completion: nil)
    }

}
