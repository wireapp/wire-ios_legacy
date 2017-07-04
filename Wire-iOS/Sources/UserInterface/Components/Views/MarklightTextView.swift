//
//  MarklightTextView.swift
//  Wire-iOS
//
//  Created by John Nguyen on 04.07.17.
//  Copyright © 2017 Zeta Project Germany GmbH. All rights reserved.
//

import UIKit
import Marklight

public class MarklightTextView: NextResponderTextView {
    
    let marklightTextStorage = MarklightTextStorage()
    
    override init(frame: CGRect, textContainer: NSTextContainer?) {
        
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
