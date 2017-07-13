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

public enum MarkdownElementType {
    
    public enum HeaderLevel {
        case h1, h2, h3
    }

    case header(HeaderLevel), bold, italic, underline, list, code
}


public protocol MarkdownBarViewDelegate: class {
    func markdownBarView(_ markdownBarView: MarkdownBarView, didSelectElementType type: MarkdownElementType, with sender: IconButton)
}


public final class MarkdownBarView: UIView {
    
    weak var delegate: MarkdownBarViewDelegate?
    
    private let stackView =  UIStackView()
    
    public let headerButton     = IconButton()
    public let boldButton       = IconButton()
    public let italicButton     = IconButton()
    public let underlineButton  = IconButton()
    public let listButton       = IconButton()
    public let codeButton       = IconButton()
    
    public let buttons: [IconButton]
    
    required public init() {
        buttons = [headerButton, boldButton, italicButton, underlineButton, listButton, codeButton]
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
        stackView.distribution = .fillEqually
        
        headerButton.setIcon(.markdownH1, with: .tiny, for: .normal)
        boldButton.setIcon(.markdownBold, with: .tiny, for: .normal)
        italicButton.setIcon(.markdownItalic, with: .tiny, for: .normal)
        underlineButton.setIcon(.markdownUnderline, with: .tiny, for: .normal)
        listButton.setIcon(.markdownList, with: .tiny, for: .normal)
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
    }
    
    // MARK: Actions
    
    func buttonTapped(sender: IconButton) {
        
        let elementType: MarkdownElementType
        
        switch sender {
        case headerButton:      elementType = .header(.h1)
        case boldButton:        elementType = .bold
        case italicButton:      elementType = .italic
        case underlineButton:   elementType = .underline
        case listButton:        elementType = .list
        case codeButton:        elementType = .code
        default: return
        }
        
        delegate?.markdownBarView(self, didSelectElementType: elementType, with: sender)
    }
}
