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

enum ProfileHeaderStyle: Int {
    case cancelButton, backButton, noButton
}

final class ProfileHeaderView: UIView {

    var showVerifiedShield = false {
        didSet {
            updateVerifiedShield()
        }
    }

    private(set) var dismissButton = IconButton.iconButtonCircular()
    internal(set) var headerStyle: ProfileHeaderStyle
    /// flag for disable headerStyle update in traitCollectionDidChange. It should be used for test only.
    private let navigationControllerViewControllerCount: Int?
    private let profileViewControllerContext: ProfileViewControllerContext?

    private let detailView = UserNameDetailView()
    private let verifiedImageView = UIImageView(image: WireStyleKit.imageOfShieldverified())

    private var backButtonLeading: NSLayoutConstraint?
    private var cancelButtonTrailing: NSLayoutConstraint?
    fileprivate var uIIdiomSizeClassOrientationProtocol: UIIdiomSizeClassOrientationProtocol.Type

    convenience init(with viewModel: ProfileHeaderViewModel,
                     _ uIIdiomSizeClassOrientationProtocol: UIIdiomSizeClassOrientationProtocol.Type = UIIdiomSizeClassOrientation.self) {
        self.init(with: viewModel)

        self.uIIdiomSizeClassOrientationProtocol = uIIdiomSizeClassOrientationProtocol
    }

    @objc(initWithViewModel:)
    init(with viewModel: ProfileHeaderViewModel) {
        headerStyle = .noButton
        navigationControllerViewControllerCount = viewModel.navigationControllerViewControllerCount
        profileViewControllerContext = viewModel.context
        self.uIIdiomSizeClassOrientationProtocol = UIIdiomSizeClassOrientation.self

        super.init(frame: .zero)

        setupViews()
        configure(with: viewModel)
        createConstraints()
        updateHeaderStyle()
        updateDismissButton()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupViews() {
        translatesAutoresizingMaskIntoConstraints = false

        [detailView, dismissButton, verifiedImageView].forEach(addSubview)
        verifiedImageView.isHidden = true

        verifiedImageView.accessibilityIdentifier = "VerifiedShield"
        dismissButton.accessibilityIdentifier = "OtherUserProfileCloseButton"
    }

    private func createConstraints() {
        let topMargin = WAZUIMagic.cgFloat(forIdentifier: "profile_temp.content_top_margin")
        let horizontalMargin = WAZUIMagic.cgFloat(forIdentifier: "profile_temp.content_left_margin")

        let detailViewMargin = horizontalMargin + 32

        constrain(self, detailView) { (view: LayoutProxy, detailView: LayoutProxy) -> () in
            detailView.top == view.top + topMargin
            detailView.leading == view.leading + detailViewMargin
            detailView.trailing == view.trailing - detailViewMargin
            detailView.bottom == view.bottom - 12
        }

        constrain(self, dismissButton, verifiedImageView, detailView.titleLabel) { (view: LayoutProxy, dismiss: LayoutProxy, verified: LayoutProxy, title: LayoutProxy) -> () in
            dismiss.top == view.top + 26
            dismiss.width == dismiss.height
            dismiss.width == 32

            verified.centerY == title.centerY
            verified.width == verified.height
            verified.width == 16
            verified.leading == view.leading + horizontalMargin

            backButtonLeading = dismiss.leading == view.leading + horizontalMargin
            cancelButtonTrailing = dismiss.trailing == view.trailing - horizontalMargin
        }
    }

    @objc(configureWithViewModel:)
    public func configure(with model: ProfileHeaderViewModel) {
        detailView.configure(with: model.userDetailViewModel)
    }

    private func updateVerifiedShield() {
        var shouldHide = true
        if headerStyle != .backButton {
            shouldHide = !showVerifiedShield
        }

        UIView.transition(
            with: verifiedImageView,
            duration: 0.2,
            options: .transitionCrossDissolve,
            animations: { self.verifiedImageView.isHidden = shouldHide },
            completion: nil
        )
    }

    // MARK: - DismissButton style and constraints

    func updateDismissButton() {
        switch headerStyle {
        case .backButton:
            cancelButtonTrailing?.isActive = false
            backButtonLeading?.isActive = true

            dismissButton.isHidden = false

            dismissButton.setIcon(.chevronLeft, with: .tiny, for: .normal)
        case .cancelButton:
            backButtonLeading?.isActive = false
            cancelButtonTrailing?.isActive = true

            dismissButton.isHidden = false

            dismissButton.setIcon(.X, with: .tiny, for: .normal)
        case .noButton:
            ///the button is hidden, the position is not important
            backButtonLeading?.isActive = false
            cancelButtonTrailing?.isActive = true

            dismissButton.isHidden = true
        }
    }

    private func updateHeaderStyle() {
        var headerStyle: ProfileHeaderStyle = .cancelButton

        if uIIdiomSizeClassOrientationProtocol.current().isIPadRegular() {

            if navigationControllerViewControllerCount > 1 {
                headerStyle = .backButton
            } else if profileViewControllerContext != .deviceList {
                headerStyle = .noButton
            }
        }

        self.headerStyle = headerStyle
    }

    // MARK: - UITraitCollection

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        let currentIdiomSizeClassOrientation = uIIdiomSizeClassOrientationProtocol.current()
        guard currentIdiomSizeClassOrientation.idiom == .pad &&
              currentIdiomSizeClassOrientation.horizontalSizeClass != .unspecified else {
            return
        }

        updateHeaderStyle()
        updateDismissButton()
    }
}

