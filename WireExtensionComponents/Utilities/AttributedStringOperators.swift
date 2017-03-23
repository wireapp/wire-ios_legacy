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

public func +(left: NSAttributedString, right: NSAttributedString) -> NSAttributedString {
    let result = NSMutableAttributedString()
    result.append(left)
    result.append(right)
    return NSAttributedString(attributedString: result)
}

public func +(left: String, right: NSAttributedString) -> NSAttributedString {
    var range : NSRange? = NSMakeRange(0, 0)
    let attributes = right.length > 0 ? right.attributes(at: 0, effectiveRange: &range!) : [:]

    let result = NSMutableAttributedString()
    result.append(NSAttributedString(string: left, attributes: attributes))

    result.append(right)
    return NSAttributedString(attributedString: result)
}

public func +(left: NSAttributedString, right: String) -> NSAttributedString {
    var range : NSRange? = NSMakeRange(0, 0)
    let attributes = left.length > 0 ? left.attributes(at: left.length - 1, effectiveRange: &range!) : [:]
    
    let result = NSMutableAttributedString()
    result.append(left)
    result.append(NSAttributedString(string:right, attributes: attributes))
    return NSAttributedString(attributedString: result)
}

// Concats the lhs and rhs and assigns the result to the lhs
infix operator += : AssignmentPrecedence

@discardableResult public func +=(left: inout NSMutableAttributedString, right: String) -> NSMutableAttributedString {
    left.append(right.attributedString)
    return left
}

@discardableResult public func +=(left: inout NSAttributedString, right: String) -> NSAttributedString {
    left = left + right
    return left
}

@discardableResult public func +=(left: inout NSAttributedString, right: NSAttributedString) -> NSAttributedString {
    left = left + right
    return left
}

@discardableResult public func +=(left: inout NSAttributedString, right: NSAttributedString?) -> NSAttributedString {
    guard let rhs = right else { return left }
    return left += rhs
}

// Applies the attributes on the rhs to the string on the lhs
infix operator && : LogicalConjunctionPrecedence

public func &&(left: String, right: [String: Any]) -> NSAttributedString {
    let result = NSAttributedString(string: left, attributes: right)
    return result
}

public func &&(left: String, right: UIFont) -> NSAttributedString {
    let result = NSAttributedString(string: left, attributes: [NSFontAttributeName: right])
    return result
}

public func &&(left: NSAttributedString, right: UIFont?) -> NSAttributedString {
    guard let font = right else { return left }
    let result = NSMutableAttributedString(attributedString: left)
    result.addAttributes([NSFontAttributeName: font], range: NSMakeRange(0, result.length))
    return NSAttributedString(attributedString: result)
}

public func &&(left: String, right: UIColor) -> NSAttributedString {
    let result = NSAttributedString(string: left, attributes: [NSForegroundColorAttributeName: right])
    return result
}

public func &&(left: NSAttributedString, right: UIColor) -> NSAttributedString {
    let result = NSMutableAttributedString(attributedString: left)
    result.addAttributes([NSForegroundColorAttributeName: right], range: NSMakeRange(0, result.length))
    return NSAttributedString(attributedString: result)
}

public func &&(left: NSAttributedString, right: [String: Any]) -> NSAttributedString {
    let result = NSMutableAttributedString(attributedString: left)
    result.addAttributes(right, range: NSMakeRange(0, result.length))
    return NSAttributedString(attributedString: result)
}

// MARK: - Helper Functions

public extension String {
    
    public var attributedString: NSAttributedString {
        return NSAttributedString(string: self)
    }
}

public extension String {
    
    // Returns the NSLocalizedString version of self
    public var localized: String {
        return NSLocalizedString(self, comment: "")
    }
   
    // Used to generate localized strings with plural rules from the stringdict
    public func localized(args: CVarArg...) -> String {
        return withVaList(args) {
            return NSString(format: self.localized, arguments: $0) as String
        }
    }
}

public extension NSAttributedString {
    
    // Adds the attribtues to the given substring in self and returns the resulting String
    public func addAttributes(_ attributes: [String: AnyObject], toSubstring substring: String) -> NSAttributedString {
        let mutableSelf = NSMutableAttributedString(attributedString: self)
        mutableSelf.addAttributes(attributes, to: substring)
        return NSAttributedString(attributedString: mutableSelf)
    }
    
    public func setAttributes(_ attributes: [String: AnyObject], toSubstring substring: String) -> NSAttributedString {
        let mutableSelf = NSMutableAttributedString(attributedString: self)
        mutableSelf.setAttributes(attributes, range: (string as NSString).range(of: substring))
        return NSAttributedString(attributedString: mutableSelf)
    }

    @objc(addingColor:toSubstring:)
    func adding(color: UIColor, to substring: String) -> NSAttributedString {
        return addAttributes([NSForegroundColorAttributeName: color], toSubstring: substring)
    }
    
    @objc(addingFont:toSubstring:)
    func adding(font: UIFont, to substring: String) -> NSAttributedString {
        return addAttributes([NSFontAttributeName: font], toSubstring: substring)
    }
}

extension Sequence where Iterator.Element == NSAttributedString {
    public func joined(separator: NSAttributedString) -> NSAttributedString {
        let result = NSMutableAttributedString()
        
        var first = true
        
        self.forEach { string in
            if !first {
                result.append(separator)
            }
            result.append(string)
            
            first = false
        }
        
        return NSAttributedString(attributedString: result)
    }
}

public extension NSMutableAttributedString {

    public func addAttributes(_ attributes: [String: AnyObject], to substring: String) {
        addAttributes(attributes, range: (string as NSString).range(of: substring))
    }

}
