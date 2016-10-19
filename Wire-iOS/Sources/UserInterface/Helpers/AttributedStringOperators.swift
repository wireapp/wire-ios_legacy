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


import Foundation

// MARK: - Operators

// Concats the lhs and rhs and returns a NSAttributedString
infix operator + : AdditionPrecedence

func +(left: NSAttributedString, right: NSAttributedString) -> NSAttributedString {
    let result = NSMutableAttributedString()
    result.append(left)
    result.append(right)
    return result
}

func +(left: String, right: NSAttributedString) -> NSAttributedString {
    var range : NSRange? = NSMakeRange(0, 0)
    let attributes = right.length > 0 ? right.attributes(at: 0, effectiveRange: &range!) : [:]

    let result = NSMutableAttributedString()
    result.append(NSAttributedString(string: left, attributes: attributes))

    result.append(right)
    return result
}

func +(left: NSAttributedString, right: String) -> NSAttributedString {
    var range : NSRange? = NSMakeRange(0, 0)
    let attributes = left.length > 0 ? left.attributes(at: left.length - 1, effectiveRange: &range!) : [:]
    
    let result = NSMutableAttributedString()
    result.append(left)
    result.append(NSAttributedString(string:right, attributes: attributes))
    return result
}

// Concats the lhs and rhs and assigns the result to the lhs
infix operator += : AssignmentPrecedence

@discardableResult func +=(left: inout NSMutableAttributedString, right: String) -> NSMutableAttributedString {
    left.append(right.attributedString)
    return left
}

@discardableResult func +=(left: inout NSAttributedString, right: String) -> NSAttributedString {
    left = left + right
    return left
}

@discardableResult func +=(left: inout NSAttributedString, right: NSAttributedString) -> NSAttributedString {
    left = left + right
    return left
}

@discardableResult func +=(left: inout NSAttributedString, right: NSAttributedString?) -> NSAttributedString {
    guard let rhs = right else { return left }
    return left += rhs
}

// Applies the attributes on the rhs to the string on the lhs
infix operator && : LogicalConjunctionPrecedence

func &&(left: String, right: [String: AnyObject]) -> NSAttributedString {
    let result = NSAttributedString(string: left, attributes: right)
    return result
}

func &&(left: String, right: UIFont) -> NSAttributedString {
    let result = NSAttributedString(string: left, attributes: [NSFontAttributeName: right])
    return result
}

func &&(left: String, right: UIColor) -> NSAttributedString {
    let result = NSAttributedString(string: left, attributes: [NSForegroundColorAttributeName: right])
    return result
}

func &&(left: NSAttributedString, right: UIColor) -> NSAttributedString {
    let result = NSMutableAttributedString(attributedString: left)
    result.addAttributes([NSForegroundColorAttributeName: right], range: NSMakeRange(0, result.length))
    return result
}

func &&(left: NSAttributedString, right: [String: AnyObject]) -> NSAttributedString {
    let result = NSMutableAttributedString(attributedString: left)
    result.addAttributes(right, range: NSMakeRange(0, result.length))
    return result
}

// MARK: - Helper Functions

extension String {
    
    var attributedString: NSAttributedString {
        return NSAttributedString(string: self)
    }
}

extension String {
    
    // Returns the NSLocalizedString version of self
    var localized: String {
        return NSLocalizedString(self, comment: "")
    }
   
    // Used to generate localized strings with plural rules from the stringdict
    func localized(args: CVarArg...) -> String {
        return withVaList(args) {
            return NSString(format: self.localized, arguments: $0) as String
        }
    }
}

extension NSAttributedString {
    
    // Adds the attribtues to the given substring in self and returns the resulting String
    func addAttributes(_ attributes: [String: AnyObject], toSubstring substring: String) -> NSAttributedString {
        let mutableSelf = NSMutableAttributedString(attributedString: self)
        mutableSelf.addAttributes(attributes, to: substring)
        return mutableSelf
    }
    
    func setAttributes(_ attributes: [String: AnyObject], toSubstring substring: String) -> NSAttributedString {
        let mutableSelf = NSMutableAttributedString(attributedString: self)
        mutableSelf.setAttributes(attributes, range: (string as NSString).range(of: substring))
        return mutableSelf
    }

}

extension NSMutableAttributedString {

    func addAttributes(_ attributes: [String: AnyObject], to substring: String) {
        addAttributes(attributes, range: (string as NSString).range(of: substring))
    }

}
