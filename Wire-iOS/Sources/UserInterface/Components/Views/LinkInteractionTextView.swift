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

@objc public protocol TextViewInteractionDelegate: NSObjectProtocol {
    func textView(_ textView: LinkInteractionTextView, open url: URL) -> Bool
    func textViewDidLongPress(_ textView: LinkInteractionTextView)
}


@objc public class LinkInteractionTextView: UITextView {
    
    let marklightTextStorage = MarklightTextStorage()
    
    public weak var interactionDelegate: TextViewInteractionDelegate?
    
    override init(frame: CGRect, textContainer: NSTextContainer?) {
        
        MarklightTextView.configure(textStorage: marklightTextStorage, hideSyntax: true)
        
        let marklightLayoutManager = NSLayoutManager()
        marklightTextStorage.addLayoutManager(marklightLayoutManager)
        
        let marklightTextContainer = NSTextContainer()
        marklightLayoutManager.addTextContainer(marklightTextContainer)
        
        super.init(frame: frame, textContainer: marklightTextContainer)
        
        delegate = self
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override public func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        let isInside = super.point(inside: point, with: event)
        guard let position = characterRange(at: point), isInside else { return false }
        let index = offset(from: beginningOfDocument, to: position.start)
        return urlAttribtue(at: index)
    }

    private func urlAttribtue(at index: Int) -> Bool {
        guard attributedText.length > 0 else { return false }
        let attributes = attributedText.attributes(at: index, effectiveRange: nil)
        return attributes[NSLinkAttributeName] != nil
    }
    
}


extension LinkInteractionTextView: UITextViewDelegate {
    
    public func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange) -> Bool {
        let beganLongPressRecognizers: [UILongPressGestureRecognizer] = gestureRecognizers?.flatMap { (recognizer: AnyObject) -> (UILongPressGestureRecognizer?) in
            
            if let recognizer = recognizer as? UILongPressGestureRecognizer, recognizer.state == .began {
                return recognizer
            }
            else {
                return .none
            }
        } ?? []

        if beganLongPressRecognizers.count > 0 {
            interactionDelegate?.textViewDidLongPress(self)
            return false
        }
        
        return !(interactionDelegate?.textView(self, open: URL) ?? false)
    }
    
    public func textView(_ textView: UITextView, shouldInteractWith textAttachment: NSTextAttachment, in characterRange: NSRange) -> Bool {
        return true
    }
    
    @available(iOS 10.0, *)
    public func textView(_ textView: UITextView, shouldInteractWith textAttachment: NSTextAttachment, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
        if interaction == .presentActions {
            interactionDelegate?.textViewDidLongPress(self)
            return false
        }
        else {
            return true
        }
    }
    
    @available(iOS 10.0, *)
    public func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
        switch interaction {
        case .invokeDefaultAction:
            return !(interactionDelegate?.textView(self, open: URL) ?? false)
        case .presentActions:
            interactionDelegate?.textViewDidLongPress(self)
            return false
        default:
            return true
        }
    }
}
