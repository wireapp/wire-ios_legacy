
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

import UIKit

extension UILabel {
    static func createTitleTable() -> UILabel {
        let label = UILabel(key: nil,
                            size: .large,
                            weight: .semibold,
                            color: .textForeground,
                            variant: .dark)
        
        label.textAlignment = .center
        label.numberOfLines = 0
        label.lineBreakMode = .byWordWrapping
        label.setContentCompressionResistancePriority(.required, for: .horizontal)
        label.setContentCompressionResistancePriority(.required, for: .vertical)

        return label
    }
}

final class WipeDatabaseViewController: UIViewController {

    private let stackView: UIStackView = UIStackView.verticalStackView()

    private let titleLabel: UILabel = {
        let label = UILabel.createTitleTable()
        label.text = "wipe_database.title_label".localized
        
        return label
    }()

    private let infoLabel: UILabel = {
        let label = UILabel()
        
        let headingText =  NSAttributedString(string: "wipe_database.info_label".localized) && UIFont.normalRegularFont
        let highlightText = NSAttributedString(string: "wipe_database.info_label.highlighted".localized) && FontSpec(.normal, .bold).font!
        
        label.attributedText = headingText + highlightText

        return label
    }()
    
    private lazy var confirmButton: Button = {
        let button = Button(style: .fullMonochrome)
        
        button.setTitle("wipe_database.button.title".localized(uppercased: true), for: .normal)
        button.setTitleColor(UIColor.WipeDatabase.buttonTitle, for: .normal)
        
        button.addTarget(self, action: #selector(onConfirmButtonPressed(sender:)), for: .touchUpInside)
        
        return button
    }()

    @objc
    func onConfirmButtonPressed(sender: Button?) {
        //TODO: go to next screen
    }
    
    convenience init() {
        self.init(nibName: nil, bundle: nil)
        
        [stackView,
            confirmButton].forEach {
            view.addSubview($0)
        }
        
        stackView.distribution = .fillProportionally
        
//        contentView.addSubview(stackView)
        
        [titleLabel,
         SpacingView(45),
         infoLabel].forEach {
            stackView.addArrangedSubview($0)
        }
        
        createConstraints()
    }

    private func createConstraints() {
        
        [stackView,
         confirmButton].disableAutoresizingMaskTranslation()
        
        let widthConstraint = stackView.widthAnchor.constraint(equalToConstant: 375)
        widthConstraint.priority = .defaultHigh
        
        let stackViewPadding: CGFloat = 46
        
        NSLayoutConstraint.activate([
            // content view
            widthConstraint,
            stackView.widthAnchor.constraint(lessThanOrEqualToConstant: 375),
//            contentView.topAnchor.constraint(equalTo: view.safeTopAnchor),
//            contentView.bottomAnchor.constraint(equalTo: view.safeBottomAnchor),
            stackView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            stackView.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: stackViewPadding),
            stackView.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -stackViewPadding),
                        
            // authenticateButton
            confirmButton.heightAnchor.constraint(equalToConstant: CGFloat.PasscodeUnlock.buttonHeight),
            confirmButton.topAnchor.constraint(greaterThanOrEqualTo: stackView.bottomAnchor, constant: CGFloat.PasscodeUnlock.buttonPadding),
            confirmButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -CGFloat.PasscodeUnlock.buttonPadding),
            confirmButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: CGFloat.PasscodeUnlock.buttonPadding),
            confirmButton.bottomAnchor.constraint(equalTo: view.safeBottomAnchor, constant: -CGFloat.PasscodeUnlock.buttonPadding)])
    }

}
