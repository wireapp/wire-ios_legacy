//
// Wire
// Copyright (C) 2019 Wire Swiss GmbH
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

extension Button {
    @objc
    convenience init(style: ButtonStyle, variant: ColorSchemeVariant) {
        self.init()
        
        textTransform = .upper
        titleLabel?.font = .smallLightFont
        layer.cornerRadius = 4
        contentEdgeInsets = UIEdgeInsets(top: 4, left: 16, bottom: 4, right: 16)
        
        switch style {
        case .full:
            setBackgroundImageColor(.accent(), for: .normal)
            setTitleColor(UIColor.white, for: .normal)
            setTitleColor(UIColor.from(scheme: .textDimmed, variant: variant), for: .highlighted)
        case .fullMonochrome:
            setBackgroundImageColor(UIColor.white, for: .normal)
            setTitleColor(UIColor.from(scheme: .textForeground, variant: .light), for: .normal)
            setTitleColor(UIColor.from(scheme: .textDimmed, variant: .light), for: .highlighted)
        case .empty:
            layer.borderWidth = 1
            setTitleColor(UIColor.buttonEmptyText(variant: variant), for: .normal)
            setTitleColor(UIColor.from(scheme: .textDimmed, variant: variant), for: .highlighted)
            setTitleColor(UIColor.from(scheme: .textDimmed, variant: variant), for: .disabled)
            setBorderColor(UIColor.accent(), for: .normal)
            setBorderColor(UIColor.accentDarken, for: .highlighted)
            setBorderColor(UIColor.from(scheme: .textDimmed, variant: variant), for: .disabled)
        case .emptyMonochrome:
            setBackgroundImageColor(UIColor.clear, for: .normal)
            setTitleColor(UIColor.white, for: .normal)
            setTitleColor(UIColor.from(scheme: .textDimmed, variant: .light), for: .highlighted)
            setBorderColor(UIColor(white: 1.0, alpha: 0.32), for: .normal)
            setBorderColor(UIColor(white: 1.0, alpha: 0.16), for: .highlighted)
        default:
            break
        }
    }

    open override func setTitle(_ title: String?, for state: UIControl.State) {
        var title = title
        state.expanded.forEach(){ expandedState in
            if title != nil {
                originalTitles?[NSNumber(value: expandedState.rawValue)] = title
            } else {
                originalTitles?.removeObject(forKey: NSNumber(value: expandedState.rawValue))
            }
        }
        
        if textTransform != .none {
            title = title?.applying(transform: textTransform)
        }
        
        super.setTitle(title, for: state)
    }
    
    @objc(setBorderColor:forState:)
    func setBorderColor(_ color: UIColor?, for state: UIControl.State) {
        state.expanded.forEach(){ expandedState in
            if color != nil {
                borderColorByState[NSNumber(value: expandedState.rawValue)] = color
            }
        }
        
        updateBorderColor()
    }
}
