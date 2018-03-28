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

@objc public protocol TextViewInteractionDelegate: NSObjectProtocol {
    func textView(_ textView: LinkInteractionTextView, open url: URL) -> Bool
    func textViewDidLongPress(_ textView: LinkInteractionTextView)
}


@objc public class LinkInteractionTextView: UITextView {
    
    public weak var interactionDelegate: TextViewInteractionDelegate?
    
    override init(frame: CGRect, textContainer: NSTextContainer?) {
        super.init(frame: frame, textContainer: textContainer)
        delegate = self
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override public func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        let isInside = super.point(inside: point, with: event)
        guard let position = characterRange(at: point), isInside else { return false }
        let index = offset(from: beginningOfDocument, to: position.start)
        return urlAttribute(at: index)
    }

    private func urlAttribute(at index: Int) -> Bool {
        guard attributedText.length > 0 else { return false }
        let attributes = attributedText.attributes(at: index, effectiveRange: nil)
        return attributes[NSLinkAttributeName] != nil
    }
    
    /// Returns true if the substring in the given range is a link and its
    /// attached URL is not described by this link.
    private func link(in range: NSRange, hides url: URL) -> Bool {
        
        guard
            // try to detect a link in the given range
            let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue),
            let match = detector.firstMatch(in: text, options: [], range: range),
            let detectedURL = match.url, match.range == range
            else { return true }
        
        return detectedURL.absoluteString != url.absoluteString
    }
    
    /// Returns an alert controller configured to open the given URL.
    private func openAlert(for url: URL) -> UIAlertController {
        let alert = UIAlertController(
            title: "content.message.open_link_alert.title".localized,
            message: "content.message.open_link_alert.message".localized(args: url.absoluteString),
            preferredStyle: .alert
        )
        
        let okAction = UIAlertAction(title: "content.message.open_link_alert.open".localized, style: .default) { _ in
            _ = self.interactionDelegate?.textView(self, open: url)
        }
        
        alert.addAction(.cancel())
        alert.addAction(okAction)
        return alert
    }
    
    /// An alert is shown (asking the user if they wish to open the url) if the link
    /// attachment contains a hidden url, i.e the substring in the given range
    /// doesn't not describe its attched url.
    fileprivate func showAlertIfNeeded(for url: URL, in range: NSRange) -> Bool {
        // if link has hidden url
        if link(in: range, hides: url) {
            ZClientViewController.shared()?.present(openAlert(for: url), animated: true, completion: nil)
            return true
        }
        return false
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
        
        // if alert shown, link opening is handled in alert actions
        if showAlertIfNeeded(for: URL, in: characterRange) { return false }
        
        // data detector links should be handled by the system
        return URL.scheme == "x-apple-data-detectors" || !(interactionDelegate?.textView(self, open: URL) ?? false)
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
            // if alert shown, link opening is handled in alert actions
            if showAlertIfNeeded(for: URL, in: characterRange) { return false }
            // data detector links should be handle by the system
            return  URL.scheme == "x-apple-data-detectors" || !(interactionDelegate?.textView(self, open: URL) ?? false)
        case .presentActions:
            interactionDelegate?.textViewDidLongPress(self)
            return false
        case .preview:
            // if no alert is shown, still allow preview peeking
            return !showAlertIfNeeded(for: URL, in: characterRange)
        }
    }
}
