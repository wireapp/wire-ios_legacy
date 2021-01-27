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

    // MARK: - Properties

    private var isAppLockActive: Bool

    private var completion: Completion?

    private let contentView: UIView = UIView()
    
    private lazy var confirmButton: Button = {
        let button = Button(style: .full, titleLabelFont: .smallSemiboldFont)
        button.setBackgroundImageColor(.strongBlue, for: .normal)
        button.accessibilityIdentifier = "warning_screen.button.confirm"
        button.setTitle("general.confirm".localized(uppercased: true), for: .normal)
        button.addTarget(self, action: #selector(confirmButtonTapped), for: .touchUpInside)
        return button
    }()
    
    private lazy var titleLabel: UILabel = {
        let label = UILabel.createMultiLineCenterdLabel()
        label.text = "warning_screen.title_label".localized
        label.accessibilityIdentifier = "warning_screen.label.title"
        return label
    }()
    
    private lazy var messageLabel: UILabel = {
        let label = UILabel(size: .normal, weight: .regular, color: .landingScreen)
        label.text = messageLabelText
        label.textAlignment = .center
        label.numberOfLines = 0
        label.setContentCompressionResistancePriority(.required, for: .horizontal)
        label.accessibilityIdentifier = "warning_screen.label.message"
        return label
    }()

    private var messageLabelText: String {
        if isAppLockActive {
            return "warning_screen.main_info.forced_applock".localized + "\n\n" + "warning_screen.info_label.forced_applock".localized
        } else {
            return "warning_screen.info_label.non_forced_applock".localized
        }
    }

    // MARK: - Life cycle

    init(isAppLockActive: Bool, completion: Completion? = nil) {
        self.isAppLockActive = isAppLockActive
        self.completion = completion

        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        setupViews()
    }

    // MARK: - Helpers
    
    private func setupViews() {
        view.backgroundColor = ColorScheme.default.color(named: .contentBackground)

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

    // MARK: - Actions

    @objc
    func confirmButtonTapped(sender: AnyObject?) {
        if let session = ZMUserSession.shared() {
            session.perform {
                session.appLockController.needsToNotifyUser = false
            }
        }

        completion?()
        dismiss(animated: true)
    }

}
