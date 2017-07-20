//
// Wire
// Copyright (C) 2017 Wire Swiss GmbH
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
import Cartography
import Marklight


public protocol MarkdownBarViewDelegate: class {
    func markdownBarView(_ markdownBarView: MarkdownBarView, didSelectElementType type: MarkdownElementType, with sender: IconButton)
    func markdownBarView(_ markdownBarView: MarkdownBarView, didDeselectElementType type: MarkdownElementType, with sender: IconButton)
}


public final class MarkdownBarView: UIView {
    
    weak var delegate: MarkdownBarViewDelegate?
    
    private let stackView =  UIStackView()
    private let buttonMargin = WAZUIMagic.cgFloat(forIdentifier: "content.left_margin") / 2 - UIImage.size(for: .tiny) / 2
    private let accentColor = ColorScheme.default().accentColor
    private let normalColor = ColorScheme.default().color(withName: ColorSchemeColorIconNormal)
    
    public let headerButton         = PopUpIconButton()
    public let boldButton           = IconButton()
    public let italicButton         = IconButton()
    public let numberListButton     = IconButton()
    public let bulletListButton     = IconButton()
    public let codeButton           = IconButton()
    
    public let buttons: [IconButton]
    public var activeModes = [MarkdownElementType]()
    
    required public init() {
        buttons = [headerButton, boldButton, italicButton, numberListButton, bulletListButton, codeButton]
        super.init(frame: CGRect.zero)
        setupViews()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override public var intrinsicContentSize: CGSize {
        return CGSize(width: UIViewNoIntrinsicMetric, height: 56)
    }
    
    private func setupViews() {
        
        stackView.axis = .horizontal
        stackView.distribution = .equalSpacing
        stackView.alignment = .center
        stackView.layoutMargins = UIEdgeInsets(top: 0, left: buttonMargin, bottom: 0, right: buttonMargin)
        stackView.isLayoutMarginsRelativeArrangement = true
        
        
        headerButton.setIcon(.markdownH1, with: .tiny, for: .normal)
        boldButton.setIcon(.markdownBold, with: .tiny, for: .normal)
        italicButton.setIcon(.markdownItalic, with: .tiny, for: .normal)
        numberListButton.setIcon(.markdownNumberList, with: .tiny, for: .normal)
        bulletListButton.setIcon(.markdownBulletList, with: .tiny, for: .normal)
        codeButton.setIcon(.markdownCode, with: .tiny, for: .normal)
        
        for button in buttons {
            let color = ColorScheme.default().color(withName: ColorSchemeColorIconNormal)
            button.setIconColor(color, for: .normal)
            button.addTarget(self, action: #selector(buttonTapped(sender:)), for: .touchUpInside)
            stackView.addArrangedSubview(button)
        }
        
        addSubview(stackView)
        
        constrain(self, stackView) { view, stackView in
            stackView.edges == view.edges
        }
        
        headerButton.itemIcons = [.markdownH1, .markdownH2, .markdownH3]
        headerButton.expandDirection = .right
        headerButton.setupView()
    }
    
    // MARK: Actions
    
    @objc private func buttonTapped(sender: IconButton) {
        
        let elementType: MarkdownElementType
        
        switch sender {
        case headerButton:
            switch headerButton.iconType(for: .normal) {
            case .markdownH1:       elementType = .header(.h1)
            case .markdownH2:       elementType = .header(.h2)
            default:                elementType = .header(.h3)
            }
        case boldButton:            elementType = .bold
        case italicButton:          elementType = .italic
        case numberListButton:      elementType = .numberList
        case bulletListButton:      elementType = .bulletList
        case codeButton:            elementType = .code
        default: return
        }
        
        if sender.iconColor(for: .normal) != normalColor {
            sender.setIconColor(normalColor, for: .normal)
            delegate?.markdownBarView(self, didDeselectElementType: elementType, with: sender)
        } else {
            delegate?.markdownBarView(self, didSelectElementType: elementType, with: sender)
        }
    }
    
    public func updateIconsForModes(_ modes: [MarkdownElementType]) {
        
        buttons.forEach { $0.setIconColor(normalColor, for: .normal) }
        var buttonsToHighlight = [IconButton]()
        
        for type in modes {
            switch type {
            case .header(_): buttonsToHighlight.append(headerButton)
            case .italic: buttonsToHighlight.append(italicButton)
            case .bold: buttonsToHighlight.append(boldButton)
            case .numberList: buttonsToHighlight.append(numberListButton)
            case .bulletList: buttonsToHighlight.append(bulletListButton)
            case .code: buttonsToHighlight.append(codeButton)
            }
        }
        
        buttonsToHighlight.forEach { $0.setIconColor(accentColor, for: .normal) }
    }
}
