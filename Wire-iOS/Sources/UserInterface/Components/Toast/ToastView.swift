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

struct ToastConfiguration {
    typealias MoreInfoAction = () -> Void
    
    let message: String
    let colorScheme: ColorSchemeColor
    let variant: ColorSchemeVariant
    let moreInfoAction: MoreInfoAction?
}

class ToastView: UIView {
    var configuration: ToastConfiguration? {
        didSet {
            applyConfiguration()
        }
    }
    
    // MARK: - Views
    
    private let topView = UIView()
    private let bottomView = UIView()
    private let stackView = UIStackView(axis: .vertical)
    
    private let messageLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        label.lineBreakMode = .byWordWrapping
        label.font = FontSpec(.small, .semibold).font
        return label
    }()
    
    private let closeButton: IconButton = {
        let button = IconButton(style: .default)
        button.setIcon(.cross, size: .tiny, for: .normal)
        return button
    }()
        
    private let moreInfoButton: UIButton = {
        let button = UIButton()
        button.contentEdgeInsets = UIEdgeInsets(top: 7, left: 24, bottom: 7, right: 24)
        button.setTitle(
            L10n.Localizable.Call.Quality.Indicator.MoreInfo.Button.text.uppercased(),
            for: .normal
        )
        button.layer.cornerRadius = button.frame.size.height / 2
        button.titleLabel?.font = FontSpec(.small, .semibold).font
        return button
    }()
    
    // MARK: - Life Cycle

    init(configuration: ToastConfiguration) {
        self.configuration = configuration
        super.init(frame: .zero)
        setupViews()
        setupConstraints()
        applyConfiguration()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Configuration

    private func applyConfiguration() {
        guard let config = configuration else { return }
       
        messageLabel.text = config.message.uppercased()
        messageLabel.textColor = textColor
        backgroundColor = UIColor.from(scheme: config.colorScheme, variant: config.variant)
        closeButton.setIconColor(UIColor.from(scheme: .iconNormal, variant: config.variant), for: .normal)
        
        guard config.moreInfoAction != nil else {
            bottomView.isHidden = true
            return
        }
        
        bottomView.isHidden = false
        moreInfoButton.backgroundColor = moreInfoButtonColor
        moreInfoButton.setTitleColor(textColor, for: .normal)
    }
    
    private func setupViews() {
        layer.cornerRadius = 4
        addSubview(stackView)
        bottomView.addSubview(moreInfoButton)
        [messageLabel, closeButton].forEach {
            topView.addSubview($0)
        }
        [topView, bottomView].forEach {
            stackView.addArrangedSubview($0)
        }
        
        moreInfoButton.addTarget(self, action: #selector(moreInfoTapHandler), for: .touchUpInside)
        closeButton.addTarget(self, action: #selector(closeButtonTapHandler), for: .touchUpInside)
    }
    
    private func setupConstraints() {
        [topView,
         bottomView,
         stackView,
         messageLabel,
         closeButton,
         moreInfoButton].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
        }
        
        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 15),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -10),
            stackView.topAnchor.constraint(equalTo: topAnchor, constant: 15),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -15),
            messageLabel.leadingAnchor.constraint(equalTo: topView.leadingAnchor),
            messageLabel.topAnchor.constraint(equalTo: topView.topAnchor),
            messageLabel.bottomAnchor.constraint(equalTo: topView.bottomAnchor),
            messageLabel.trailingAnchor.constraint(equalTo: closeButton.leadingAnchor),
            closeButton.topAnchor.constraint(equalTo: topView.topAnchor),
            closeButton.trailingAnchor.constraint(equalTo: topView.trailingAnchor),
            closeButton.bottomAnchor.constraint(lessThanOrEqualTo: topView.bottomAnchor),
            closeButton.widthAnchor.constraint(equalToConstant: 16),
            closeButton.heightAnchor.constraint(equalToConstant: 16),
            moreInfoButton.heightAnchor.constraint(equalTo: bottomView.heightAnchor),
            moreInfoButton.centerYAnchor.constraint(equalTo: bottomView.centerYAnchor),
            moreInfoButton.trailingAnchor.constraint(equalTo: bottomView.trailingAnchor)
        ])
    }
    
    // MARK: - Events

    @objc func closeButtonTapHandler() {
        removeFromSuperview()
    }
    
    @objc func moreInfoTapHandler() {
        configuration?.moreInfoAction?()
    }
    
    // MARK: - Helpers
    
    private var moreInfoButtonColor: UIColor {
        switch configuration?.variant {
        case .some(.dark):
            return UIColor(rgba: (23, 24, 26, 0.12))
        default:
            return .whiteAlpha24
        }
    }
    
    private var textColor: UIColor {
        switch configuration?.variant {
        case .some(.dark):
            return .black
        default:
            return .white
        }
    }
}
