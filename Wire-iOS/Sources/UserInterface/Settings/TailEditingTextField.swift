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

/**
 * @abstract The purpose of this subclass of UITextField is to give the possibility to edit the right-aligned text field
 * with spaces. Default implementation collapses the trailing spaces as you type, which looks confusing. This control
 * can be used "as-is" without any additional configuration.
 */
class TailEditingTextField: UITextField {
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.setup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        self.setup()
    }
    
    func setup() {
        self.addTarget(self, action: #selector(TailEditingTextField.replaceNormalSpacesWithNonBreakingSpaces), for: UIControl.Event.editingDidBegin)
        self.addTarget(self, action: #selector(TailEditingTextField.replaceNormalSpacesWithNonBreakingSpaces), for: UIControl.Event.editingChanged)
        self.addTarget(self, action: #selector(TailEditingTextField.replaceNonBreakingSpacesWithNormalSpaces), for: UIControl.Event.editingDidEnd)
    }
    
    @objc func replaceNormalSpacesWithNonBreakingSpaces() {
        guard let isContainsNormalSpace = (self.text?.contains(String.breakingSpace)), isContainsNormalSpace else {
            return }

        self.text = self.text?.replacingOccurrences(of: String.breakingSpace, with: String.nonBreakingSpace)
    }
    
    @objc func replaceNonBreakingSpacesWithNormalSpaces() {
        guard let isContainsNonBreakingSpace = (self.text?.contains(String.nonBreakingSpace)), isContainsNonBreakingSpace else { return }
        
        self.text = self.text?.replacingOccurrences(of: String.nonBreakingSpace, with: String.breakingSpace)
    }
}
