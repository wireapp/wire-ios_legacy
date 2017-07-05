//
// Wire
// Copyright (C) 2016 Wire Swiss GmbH
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
import Marklight

public class MarklightTextView: NextResponderTextView {
    
    fileprivate let marklightTextStorage = MarklightTextStorage()
    
    public override init(frame: CGRect, textContainer: NSTextContainer?) {
        
        MarklightTextView.configure(textStorage: marklightTextStorage, hideSyntax: false)
        
        let marklightLayoutManager = NSLayoutManager()
        marklightTextStorage.addLayoutManager(marklightLayoutManager)
        
        let marklightTextContainer = NSTextContainer()
        marklightLayoutManager.addTextContainer(marklightTextContainer)
        
        super.init(frame: frame, textContainer: marklightTextContainer)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    class func configure(textStorage: MarklightTextStorage, hideSyntax: Bool) {
        
        let colorScheme = ColorScheme.default()
        textStorage.syntaxColor = colorScheme.color(withName: ColorSchemeColorAccent)
        textStorage.quoteColor = colorScheme.color(withName: ColorSchemeColorTextForeground)
        textStorage.codeColor = colorScheme.color(withName: ColorSchemeColorTextForeground)
        textStorage.codeFontName = "Courier"
        textStorage.fontTextStyle = UIFontTextStyle.subheadline.rawValue
        textStorage.hideSyntax = hideSyntax
        
        textStorage.defaultAttributes = [
            NSForegroundColorAttributeName: colorScheme.color(withName: ColorSchemeColorTextForeground),
            NSFontAttributeName: FontSpec(.normal, .none).font!
        ]
    }
}
