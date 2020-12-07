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
        label.text = "create_passcode.title_label".localized

        return label
    }()
    
    private lazy var createButton: Button = {
        let button = Button(style: .full, titleLabelFont: .smallSemiboldFont)

        button.setTitle("create_passcode.create_button.title".localized(uppercased: true), for: .normal)
        button.isEnabled = false

        button.addTarget(self, action: #selector(onOkCodeButtonPressed), for: .touchUpInside)

        return button
    }()
private let variant: ColorSchemeVariant

    override func viewDidLoad() {
        super.viewDidLoad()

       
    }
    
    /// init with parameters
    /// - Parameters:
    ///   - callback: callback for storing passcode result.
    ///   - variant: color variant for this screen. When it is nil, apply app's current scheme
    ///   - useCompactLayout: Set this to true for reduce font size and spacing for iPhone 4 inch screen. Set to nil to follow current window's height
    required init(variant: ColorSchemeVariant? = nil) {
        self.variant = variant ?? ColorScheme.default.variant

        super.init(nibName: nil, bundle: nil)

        setupViews()
    }
    
    private func setupViews() {
        view.backgroundColor = ColorScheme.default.color(named: .contentBackground,
                                                         variant: variant)
        
        view.addSubview(contentView)
        
        contentView.addSubview(titleLabel)
        contentView.addSubview(createButton)
         createConstraints()
    }
    
    private func createConstraints() {
        let widthConstraint = contentView.createContentWidthConstraint()
        let contentPadding: CGFloat = 24
        
        NSLayoutConstraint.activate([
            // content view
            widthConstraint,
            contentView.widthAnchor.constraint(lessThanOrEqualToConstant: 375),
            contentView.topAnchor.constraint(equalTo: view.safeTopAnchor),
            contentView.bottomAnchor.constraint(equalTo: view.safeBottomAnchor),
            contentView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            contentView.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: contentPadding),
            contentView.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -contentPadding),
            
            // create Button
            createButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -contentPadding),
            createButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            createButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor)
        ])
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    @objc
    private func onOkCodeButtonPressed(sender: AnyObject?) {
        dismiss(animated: true)
    }

}
