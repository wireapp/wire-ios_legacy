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

class UnlockViewController: UIViewController {
    
    private let contentView: UIView = UIView()
    private let stackView: UIStackView = UIStackView.verticalStackView()
    
    private lazy var unlockButton: UIButton = {
        var button = UIButton()
//        (style: .fullMonochrome,
//                            titleLabelFont: .smallSemiboldFont)

        button.setBackgroundImage(UIImage.singlePixelImage(with: .white), for: .normal)
        button.setTitleColor(UIColor.graphite, for: .normal)
        button.setTitleColor(UIColor.lightGraphite, for: .highlighted)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 14)
        
        button.setTitle("share_extension.unlock.submit_button.title".localized, for: .normal)
        button.isEnabled = false
        button.addTarget(self, action: #selector(onUnlockButtonPressed(sender:)), for: .touchUpInside)
        button.accessibilityIdentifier = "unlock_screen.button.unlock"

        return button
    }()

    private lazy var accessoryTextField: AccessoryTextField = {
//    lazy var accessoryTextField: AccessoryTextField = {
        //let textField = AccessoryTextField.createPasscodeTextField(kind: .passcode(isNew: false), delegate: self)
        let textField = AccessoryTextField()
        textField.isSecureTextEntry = true
        textField.autocapitalizationType = .none
        
        textField.placeholder = "share_extension.unlock.textfield.placeholder".localized
        //textField.delegate = self
        textField.accessibilityIdentifier = "unlock_screen.text_field.enter_passcode"

        return textField
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        
        label.text = "share_extension.unlock.title_label".localized
        label.font = UIFont.boldSystemFont(ofSize: 14)
        label.textColor = .white

        label.textAlignment = .center
        label.numberOfLines = 0
        label.lineBreakMode = .byWordWrapping
        label.setContentCompressionResistancePriority(.required, for: .horizontal)
        label.setContentCompressionResistancePriority(.required, for: .vertical)

        return label
    }()
    
    @objc
    private func onUnlockButtonPressed(sender: AnyObject?) {
       // unlock()
    }
    
    init() {
        super.init(nibName: nil, bundle: nil)
        view.backgroundColor = .black
        
        view.addSubview(contentView)
        
        stackView.distribution = .fill
        contentView.addSubview(stackView)
        
        [titleLabel, accessoryTextField, unlockButton].forEach(stackView.addArrangedSubview)
        
        createConstraints()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidAppear(_ animated: Bool) {
           super.viewDidAppear(animated)

           accessoryTextField.becomeFirstResponder()
       }

    private func createConstraints() {
        
        [contentView,
         stackView].forEach { (view) in
            view.translatesAutoresizingMaskIntoConstraints = false
        }
        
        let widthConstraint = contentView.createContentWidthConstraint()
        
        let contentPadding: CGFloat = 24
        
        NSLayoutConstraint.activate([
            // content view
            widthConstraint,
            contentView.widthAnchor.constraint(lessThanOrEqualToConstant: CGFloat.iPhone4_7Inch.width),
            contentView.topAnchor.constraint(equalTo: view.topAnchor),
            contentView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            contentView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            contentView.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: contentPadding),
            contentView.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -contentPadding),

            // stack view
            stackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            stackView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),

            // unlock Button
            unlockButton.heightAnchor.constraint(equalToConstant: CGFloat.PasscodeUnlock.buttonHeight),
        ])
    }
}

extension UIColor {
    static var graphite: UIColor = UIColor(rgb: (51, 55, 58))
    static var lightGraphite: UIColor = UIColor(rgb:(141, 152, 159))
}

extension UIView {
    func createContentWidthConstraint() -> NSLayoutConstraint {
        let widthConstraint = widthAnchor.constraint(equalToConstant: 375)
        widthConstraint.priority = .defaultHigh

        return widthConstraint
    }
}

extension UIStackView {
    convenience init(axis: NSLayoutConstraint.Axis) {
        self.init(frame: .zero)
        self.axis = axis
    }
    
    var visibleSubviews: [UIView] {
        return subviews.filter { !$0.isHidden }
    }

    // factory methods
    static func verticalStackView() -> UIStackView {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 8
        stackView.alignment = .fill
        stackView.setContentCompressionResistancePriority(.required, for: .vertical)
        stackView.setContentCompressionResistancePriority(.required, for: .horizontal)
        
        return stackView
    }
}

extension CGFloat {
    enum PasscodeUnlock {
        static let textFieldHeight: CGFloat = 40
        static let buttonHeight: CGFloat = 40
        static let buttonPadding: CGFloat = 24
        static let textFieldPadding: CGFloat = 19
    }
    
    enum iPhone4_7Inch {
        static let width: CGFloat = 375
        static let height: CGFloat = 667
    }
}


