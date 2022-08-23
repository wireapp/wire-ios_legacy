//
// Wire
// Copyright (C) 2017 Wire Swiss GmbH
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
import WireSystem

extension AppLockModule.View {

    final class LockView: UIView {

        // MARK: - Properties

        var actionRequested: Completion?

        var message: String = "" {
            didSet {
                messageLabel.text = message
            }
        }

        var buttonTitle: String = "" {
            didSet {
                actionButton.setTitle(buttonTitle, for: .normal)
            }
        }

        var showReauth: Bool = false {
            didSet {
                self.messageLabel.isHidden = !showReauth
                self.actionButton.isHidden = !showReauth
            }
        }

        private let shieldViewContainer = UIView()
        private let contentContainerView = UIView()
        private let blurView = UIVisualEffectView.blurView()

        private let messageLabel: UILabel = {
            let label = UILabel()
            label.font = .largeThinFont
            label.textColor = .from(scheme: .textForeground, variant: .dark)
            return label
        }()

        private let actionButton = LegacyButton(legacyStyle: .fullMonochrome, fontSpec: .smallLightFont)

        private var contentWidthConstraint: NSLayoutConstraint!
        private var contentCenterConstraint: NSLayoutConstraint!
        private var contentLeadingConstraint: NSLayoutConstraint!
        private var contentTrailingConstraint: NSLayoutConstraint!

        var userInterfaceSizeClass: (UITraitEnvironment) -> UIUserInterfaceSizeClass = {traitEnvironment in
            return traitEnvironment.traitCollection.horizontalSizeClass
        }

        // MARK: - Life cycle

        init() {
            super.init(frame: .zero)

            let shieldView = UIView.shieldView()
            shieldViewContainer.addSubview(shieldView)

            addSubview(shieldViewContainer)
            addSubview(blurView)

            messageLabel.isHidden = true
            messageLabel.numberOfLines = 0
            actionButton.isHidden = true

            addSubview(contentContainerView)

            contentContainerView.addSubview(messageLabel)
            contentContainerView.addSubview(actionButton)

            actionButton.addTarget(self, action: #selector(LockView.onButtonPressed(_:)), for: .touchUpInside)

            createConstraints(nibView: shieldView)

            toggleConstraints()
        }

        @available(*, unavailable)
        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder) is not implemented")
        }

        // MARK: - Helpers

        private func createConstraints(nibView: UIView) {
            self.translatesAutoresizingMaskIntoConstraints = false
            nibView.translatesAutoresizingMaskIntoConstraints = false
            shieldViewContainer.translatesAutoresizingMaskIntoConstraints = false
            blurView.translatesAutoresizingMaskIntoConstraints = false
            contentContainerView.translatesAutoresizingMaskIntoConstraints = false
            actionButton.translatesAutoresizingMaskIntoConstraints = false
            messageLabel.translatesAutoresizingMaskIntoConstraints = false

            // Compact
            contentLeadingConstraint = contentContainerView.leadingAnchor.constraint(equalTo: leadingAnchor)
            contentTrailingConstraint = contentContainerView.trailingAnchor.constraint(equalTo: trailingAnchor)

            // Regular
            contentCenterConstraint = contentContainerView.centerXAnchor.constraint(equalTo: centerXAnchor)
            contentWidthConstraint = contentContainerView.widthAnchor.constraint(equalToConstant: 320)

            NSLayoutConstraint.activate([
                // nibView
                nibView.leadingAnchor.constraint(equalTo: leadingAnchor),
                nibView.topAnchor.constraint(equalTo: topAnchor),
                nibView.trailingAnchor.constraint(equalTo: trailingAnchor),
                nibView.bottomAnchor.constraint(equalTo: bottomAnchor),

                // shieldViewContainer
                shieldViewContainer.leadingAnchor.constraint(equalTo: leadingAnchor),
                shieldViewContainer.topAnchor.constraint(equalTo: topAnchor),
                shieldViewContainer.trailingAnchor.constraint(equalTo: trailingAnchor),
                shieldViewContainer.bottomAnchor.constraint(equalTo: bottomAnchor),

                // blurView
                blurView.leadingAnchor.constraint(equalTo: leadingAnchor),
                blurView.topAnchor.constraint(equalTo: topAnchor),
                blurView.trailingAnchor.constraint(equalTo: trailingAnchor),
                blurView.bottomAnchor.constraint(equalTo: bottomAnchor),

                // contentContainerView
                contentContainerView.topAnchor.constraint(equalTo: topAnchor),
                contentContainerView.bottomAnchor.constraint(equalTo: bottomAnchor),

                // authenticateLabel
                messageLabel.leadingAnchor.constraint(equalTo: contentContainerView.leadingAnchor, constant: 24),
                messageLabel.trailingAnchor.constraint(equalTo: contentContainerView.trailingAnchor, constant: -24),

                // authenticateButton
                actionButton.heightAnchor.constraint(equalToConstant: CGFloat.PasscodeUnlock.buttonHeight),
                actionButton.leadingAnchor.constraint(equalTo: contentContainerView.leadingAnchor, constant: CGFloat.PasscodeUnlock.buttonPadding),
                actionButton.topAnchor.constraint(equalTo: messageLabel.bottomAnchor, constant: 24),
                actionButton.trailingAnchor.constraint(equalTo: contentContainerView.trailingAnchor, constant: -CGFloat.PasscodeUnlock.buttonPadding),
                actionButton.bottomAnchor.constraint(equalTo: contentContainerView.safeBottomAnchor, constant: -CGFloat.PasscodeUnlock.buttonPadding)])
        }

        override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
            super.traitCollectionDidChange(previousTraitCollection)
            toggleConstraints()
        }

        private func toggleConstraints() {
            userInterfaceSizeClass(self).toggle(
                compactConstraints: [contentLeadingConstraint, contentTrailingConstraint],
                regularConstraints: [contentCenterConstraint, contentWidthConstraint]
            )
        }

        // MARK: - Actions

        @objc func onButtonPressed(_ sender: AnyObject!) {
            actionRequested?()
        }

    }

}
