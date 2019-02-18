//
//  ConversationDetailFooterView.swift
//  Wire-iOS
//
//  Created by Nicola Giancecchi on 18.02.19.
//  Copyright © 2019 Zeta Project Germany GmbH. All rights reserved.
//

import UIKit

protocol ConversationDetailFooterViewProtocol {
    
}

@objc class ConversationDetailFooterView: UIView {
    
    private let variant: ColorSchemeVariant
    @objc public let rightButton = IconButton()
    @objc public var leftButton: IconButton
    
    @objc public var leftIcon: ZetaIconType {
        get {
            return leftButton.iconType(for: .normal)
        }
        set {
            leftButton.isHidden = (newValue == .none)
            if newValue != .none {
                leftButton.setIcon(newValue, with: .tiny, for: .normal)
            }
        }
    }
    
    @objc public var rightIcon: ZetaIconType {
        get {
            return rightButton.iconType(for: .normal)
        }
        set {
            rightButton.isHidden = (newValue == .none)
            if newValue != .none {
                rightButton.setIcon(newValue, with: .tiny, for: .normal)
            }
        }
    }
    
    override convenience init(frame: CGRect) {
        self.init(mainButton: IconButton())
    }
    
    internal init(mainButton: IconButton = IconButton()) {
        self.variant = ColorScheme.default.variant
        self.leftButton = mainButton
        super.init(frame: .zero)
        setupViews()
        createConstraints()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupViews() {
        
        [leftButton, rightButton].forEach {
            addSubview($0)
            $0.translatesAutoresizingMaskIntoConstraints = false
            $0.setIconColor(UIColor.from(scheme: .iconNormal), for: .normal)
            $0.setIconColor(UIColor.from(scheme: .iconHighlighted), for: .highlighted)
            $0.setIconColor(UIColor.from(scheme: .buttonFaded), for: .disabled)
            $0.setTitleColor(UIColor.from(scheme: .iconNormal), for: .normal)
            $0.setTitleColor(UIColor.from(scheme: .textDimmed), for: .highlighted)
            $0.setTitleColor(UIColor.from(scheme: .buttonFaded), for: .disabled)
            $0.addTarget(self, action: #selector(buttonTapped), for: .touchUpInside)
        }
        
        leftButton.titleImageSpacing = 16
        leftButton.titleLabel?.font = FontSpec(.small, .regular).font
        backgroundColor = UIColor.from(scheme: .barBackground)
        
        setupButtons()
    }
    
    private func createConstraints() {
        NSLayoutConstraint.activate([
            heightAnchor.constraint(equalToConstant: 56),
            leftButton.centerYAnchor.constraint(equalTo: centerYAnchor),
            rightButton.centerYAnchor.constraint(equalTo: centerYAnchor),
            leftButton.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            rightButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            rightButton.leadingAnchor.constraint(greaterThanOrEqualTo: leftButton.leadingAnchor, constant: 16)
            ])
    }
    
    @objc internal func setupButtons() {
        //no-op
    }
    
    @objc internal func buttonTapped(_ sender: IconButton) {
        //no-op
    }
    
}
