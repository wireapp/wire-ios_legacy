
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

final class UnlockViewController: UIViewController {
    
    private let shieldView = UIView.shieldView()
    private let blurView: UIVisualEffectView = UIVisualEffectView.blurView()
    
    private let stackView: UIStackView = UIStackView.verticalStackView()

    private let contentView: UIView = { let view = UIView()
        return view
    }()

    convenience init() {
        self.init(nibName:nil, bundle:nil)
        
        view.addSubview(shieldView)
        view.addSubview(blurView)
        
        view.addSubview(contentView)

        contentView.addSubview(stackView)

        //TODO: copy, factory
        let label = UILabel(key: "Enter Passcode to unlock Wire".localized, size: FontSize.large, weight: .semibold, color: .textForeground, variant: .dark)
        
        label.textAlignment = .center
        label.numberOfLines = 2
        label.setContentCompressionResistancePriority(.required, for: .horizontal)

        stackView.addArrangedSubview(label)

        
        createConstraints()
    }
    
    //MARK: - status bar
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    private func createConstraints(/*nibView: UIView*/) { ///TODO: snapshot test
        
        [shieldView,
            blurView,
            contentView,
            stackView].disableAutoresizingMaskTranslation()
        
        let widthConstraint = contentView.widthAnchor.constraint(equalToConstant: 375)
        widthConstraint.priority = .defaultHigh
        
        NSLayoutConstraint.activate([
            // nibView
            shieldView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            shieldView.topAnchor.constraint(equalTo: view.topAnchor),
            shieldView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            shieldView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            // blurView
            blurView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            blurView.topAnchor.constraint(equalTo: view.topAnchor),
            blurView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            blurView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            // content view
            widthConstraint,
            contentView.widthAnchor.constraint(lessThanOrEqualToConstant: 375),
            contentView.topAnchor.constraint(equalTo: view.safeTopAnchor),
            contentView.bottomAnchor.constraint(equalTo: view.safeBottomAnchor),
            contentView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            contentView.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 32),
            contentView.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -32),

            // stack view
            stackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            stackView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),

        ])
    }

}
