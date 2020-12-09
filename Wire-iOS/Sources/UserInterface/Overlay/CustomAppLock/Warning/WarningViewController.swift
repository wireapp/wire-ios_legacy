//
// Wire
// Copyright (C) 2020 Wire Swiss GmbH
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

class WarningViewController: UIViewController {

    private let contentView: UIView = UIView()

    private lazy var titleLabel: UILabel = {
        let label = UILabel.createMultiLineCenterdLabel(variant: variant)
        label.text = "self.settings.privacy_security.lock_app.warning.title".localized

        return label
    }()
    
    private lazy var messageLabel: UILabel = {
        let text = isApplockForced
            ? "self.settings.privacy_security.lock_app.warning.force".localized
            : "self.settings.privacy_security.lock_app.warning.unforce".localized
        let label = UILabel(key: text,
                            size: .normal,
                            weight: .regular,
                            color: .landingScreen,
                            variant: .light)
        label.textAlignment = .center
        label.numberOfLines = 0
        label.setContentCompressionResistancePriority(.required, for: .horizontal)

        return label
    }()

    private lazy var createButton: Button = {
        let button = Button(style: .full, titleLabelFont: .smallSemiboldFont)

        button.setTitle("general.confirm".localized(uppercased: true), for: .normal)

        button.addTarget(self, action: #selector(onOkCodeButtonPressed), for: .touchUpInside)

        return button
    }()
      private let variant: ColorSchemeVariant
      private let isApplockForced: Bool
      private let delegate: AppLockInteractorInput
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupViews()
    }

    required init(isApplockForced: Bool, delegate: AppLockInteractorInput, variant: ColorSchemeVariant? = nil) {
        self.isApplockForced = isApplockForced
        self.variant = variant ?? ColorScheme.default.variant
        self.delegate = delegate

        super.init(nibName: nil, bundle: nil)
    }

    private func setupViews() {
        view.backgroundColor = ColorScheme.default.color(named: .contentBackground, variant: variant)

        view.addSubview(contentView)
        
        contentView.addSubview(titleLabel)
        contentView.addSubview(createButton)
        contentView.addSubview(messageLabel)
                
        createConstraints()
    }

    private func createConstraints() {
        contentView.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        createButton.translatesAutoresizingMaskIntoConstraints = false
        messageLabel.translatesAutoresizingMaskIntoConstraints = false
       
        
        NSLayoutConstraint.activate([
            contentView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            contentView.topAnchor.constraint(equalTo: view.topAnchor),
            contentView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            // title Label
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 150),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: CGFloat.PasscodeUnlock.buttonPadding),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -CGFloat.PasscodeUnlock.buttonPadding),
            
            // message Label
            messageLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            messageLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: CGFloat.PasscodeUnlock.buttonPadding),
            messageLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -CGFloat.PasscodeUnlock.buttonPadding),

            // create Button
            createButton.heightAnchor.constraint(equalToConstant: CGFloat.WipeCompletion.buttonHeight),
            createButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -CGFloat.PasscodeUnlock.buttonPadding),
            createButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: CGFloat.PasscodeUnlock.buttonPadding),
            createButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -CGFloat.PasscodeUnlock.buttonPadding)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc
    private func onOkCodeButtonPressed(sender: AnyObject?) {
        delegate.needsToNotify = false
        dismiss(animated: true)
        if isApplockForced {
            delegate.evaluateAuthentication(description: AuthenticationMessageKey.deviceAuthentication)
        }
    }

}

