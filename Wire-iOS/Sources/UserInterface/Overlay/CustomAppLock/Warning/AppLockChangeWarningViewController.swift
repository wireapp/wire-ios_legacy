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
import WireSyncEngine
import WireCommonComponents

final class AppLockChangeWarningViewController: UIViewController {

    private let contentView: UIView = UIView()
    
    private lazy var confirmButton: Button = {
        let button = Button(style: .full, titleLabelFont: .smallSemiboldFont)
        button.setBackgroundImageColor(.strongBlue, for: .normal)
        
        button.accessibilityIdentifier = "confirmButton"
        button.setTitle("general.confirm".localized(uppercased: true), for: .normal)
        button.addTarget(self, action: #selector(confirmButtonTapped), for: .touchUpInside)

        return button
    }()
    
    private lazy var titleLabel: UILabel = {
        let label = UILabel.createMultiLineCenterdLabel(variant: variant)
        label.text = "warning_screen.title_label".localized

        return label
    }()
    
    private lazy var messageLabel: UILabel = {
        let text = isAppLockActive
            ? "warning_screen.main_info.forced_applock".localized + "\n\n" + "warning_screen.info_label.forced_applock".localized
            : "warning_screen.info_label.non_forced_applock".localized
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
    
    private let variant: ColorSchemeVariant
    private var callback: ResultHandler?
    
    private var appLock: AppLockType? = ZMUserSession.shared()?.appLockController

    private var isAppLockActive: Bool {
        return appLock?.isActive ?? false
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupViews()
    }
    
    /// init with parameters
    /// - Parameters:
    ///   - callback: callback for authentication
    ///   - variant: color variant for this screen
    required init(variant: ColorSchemeVariant = ColorScheme.default.variant,
                  callback: ResultHandler? = nil) {
        self.variant = variant
        self.callback = callback

        super.init(nibName: nil, bundle: nil)
    }
    
    private func setupViews() {
        view.backgroundColor = ColorScheme.default.color(named: .contentBackground, variant: variant)

        view.addSubview(contentView)
        
        contentView.addSubview(titleLabel)
        contentView.addSubview(confirmButton)
        contentView.addSubview(messageLabel)
                
        createConstraints()
    }

    private func createConstraints() {
        [contentView,
         titleLabel,
         confirmButton,
         messageLabel].disableAutoresizingMaskTranslation()

        let contentPadding: CGFloat = 24
                
        NSLayoutConstraint.activate([
            contentView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            contentView.topAnchor.constraint(equalTo: view.topAnchor),
            contentView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            // title Label
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 150),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: contentPadding),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -contentPadding),
            
            // message Label
            messageLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: contentPadding),
            messageLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: contentPadding),
            messageLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -contentPadding),

            // confirm Button
            confirmButton.heightAnchor.constraint(equalToConstant: CGFloat.WipeCompletion.buttonHeight),
            confirmButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -contentPadding),
            confirmButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: contentPadding),
            confirmButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -contentPadding)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc
    private func confirmButtonTapped(sender: AnyObject?) {
        ZMUserSession.shared()?.perform {
            self.appLock?.needsToNotifyUser = false
        }
        callback?(true)
        dismiss(animated: true)
    }

}
