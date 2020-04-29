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

protocol CallQualityIndicatorDelegate: class {
    func callQualityIndicator(_ callQualityIndicator: CallQualityIndicatorViewController,
                              didTapDismissButton: UIButton)
    func callQualityIndicator(_ callQualityIndicator: CallQualityIndicatorViewController,
                              didTapMoreInfoButton: UIButton)
}

class CallQualityIndicatorViewController: UIViewController {

    // MARK: - Public Properties
    
    weak var delegate: CallQualityIndicatorDelegate?
    var hasBeenShown = false
    var isHidden: Bool = false {
        didSet{
            view.isHidden = isHidden
        }
    }
    
    // MARK: - Private Properties
    
    private let padding = UIEdgeInsets(top: 16, left: 16, bottom: 8, right: 8)
    private let spacing: CGFloat = 16

    // MARK: - Components

    private let messageLabel: UILabel = {
        let label = UILabel()
        label.text = "call.quality.indicator.message".localized.uppercased()
        label.font = FontSpec(.small, .medium).font!
        label.textColor = .white
        label.numberOfLines = 0
        return label
    }()

    private let dismissButton: IconButton = {
        let button = IconButton(style: .default)
        button.setIcon(.cross, size: .tiny, for: .normal)
        button.setIconColor(.white, for: .normal)
        return button
    }()

    private let moreInfoButton: Button = {
        let button = Button(style: .empty,
                            titleLabelFont: .smallMediumFont)
        button.setTitle("call.quality.indicator.more_info.button.text".localized.uppercased(),
                        for: .normal)
        button.textTransform = .none
        button.backgroundColor = UIColor(white: 1, alpha: 0.24)
        button.setBorderColor(UIColor(rgb: (230, 6, 6)), for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 13
        return button
    }()

    // MARK: - Life Cycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setUpViews()
        setUpButtonActions()
        setUpConstraints()
    }
    
    // MARK: - Helpers

    private func setUpButtonActions() {
        dismissButton.addTarget(self,
                                action: #selector(didTapDismissButton),
                                for: .touchUpInside)
        moreInfoButton.addTarget(self,
                                 action: #selector(didTapMoreInfoButton),
                                 for: .touchUpInside)
    }
    
    private func setUpViews() {
        view.backgroundColor = UIColor(rgb: (230, 6, 6))
        view.layer.cornerRadius = 4
        view.clipsToBounds = true

        for subview in [messageLabel, dismissButton, moreInfoButton] {
            view.addSubview(subview)
            subview.translatesAutoresizingMaskIntoConstraints = false
        }
    }

    // MARK: - Constraints Helpers
    
    private func setUpConstraints() {
        setUpDismissButtonConstraints()
        setUpMoreInfoButtonConstraints()
        setUpMessageLabelConstraints()
    }

    private func setUpDismissButtonConstraints() {
        NSLayoutConstraint.activate([
            dismissButton.topAnchor.constraint(equalTo: view.topAnchor,
                                               constant: padding.top),
            dismissButton.trailingAnchor.constraint(equalTo: view.trailingAnchor,
                                                    constant: -padding.trailing)
        ])
    }
    
    private func setUpMoreInfoButtonConstraints() {
        NSLayoutConstraint.activate([
            moreInfoButton.heightAnchor.constraint(equalToConstant: 28.0),
            moreInfoButton.widthAnchor.constraint(equalToConstant: 111.0),
            moreInfoButton.trailingAnchor.constraint(equalTo: view.trailingAnchor,
                                                     constant: -padding.trailing),
            moreInfoButton.bottomAnchor.constraint(equalTo: view.bottomAnchor,
                                                   constant: -padding.bottom)
        ])
    }
    
    private func setUpMessageLabelConstraints() {
        NSLayoutConstraint.activate([
            messageLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor,
                                                  constant: padding.leading),
            messageLabel.topAnchor.constraint(equalTo: view.topAnchor,
                                              constant: padding.top),
            messageLabel.trailingAnchor.constraint(lessThanOrEqualTo: dismissButton.leadingAnchor,
                                                   constant: -spacing),
            messageLabel.bottomAnchor.constraint(lessThanOrEqualTo: moreInfoButton.topAnchor,
                                                 constant: -spacing)
        ])
    }
    
    // MARK: - Actions

    @objc
    private func didTapDismissButton() {
        delegate?.callQualityIndicator(self, didTapDismissButton: dismissButton)
    }

    @objc
    private func didTapMoreInfoButton() {
        delegate?.callQualityIndicator(self, didTapMoreInfoButton: moreInfoButton)
    }

}
