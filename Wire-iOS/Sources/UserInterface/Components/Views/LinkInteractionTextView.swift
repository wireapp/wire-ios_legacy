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

protocol TextViewInteractionDelegate: class {
    func textView(_ textView: LinkInteractionTextView, open url: URL) -> Bool
    func textViewDidLongPress(_ textView: LinkInteractionTextView)
}


final class LinkInteractionTextView: UITextView {
    
    weak var interactionDelegate: TextViewInteractionDelegate?

    override var selectedTextRange: UITextRange? {
        get { return nil }
        set { /* no-op */ }
    }
    
    // URLs with these schemes should be handled by the os.
    fileprivate let dataDetectedURLSchemes = [ "x-apple-data-detectors", "tel", "mailto"]
    
    override init(frame: CGRect, textContainer: NSTextContainer?) {
        super.init(frame: frame, textContainer: textContainer)
        delegate = self
        
        if #available(iOS 11.0, *) {
            textDragDelegate = self
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        let isInside = super.point(inside: point, with: event)
        guard !UIMenuController.shared.isMenuVisible else { return false }
        guard let position = characterRange(at: point), isInside else { return false }
        let index = offset(from: beginningOfDocument, to: position.start)
        return urlAttribute(at: index)
    }

    private func urlAttribute(at index: Int) -> Bool {
        guard attributedText.length > 0 else { return false }
        let attributes = attributedText.attributes(at: index, effectiveRange: nil)
        return attributes[.link] != nil
    }
    
    /// Returns an alert controller configured to open the given URL.
    private func confirmationAlert(for url: URL) -> UIAlertController {
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
    
    /// An alert is shown (asking the user if they wish to open the url) if the
    /// link in the specified range is a markdown link.
    fileprivate func showAlertIfNeeded(for url: URL, in range: NSRange) -> Bool {
        // only show alert if the link is a markdown link
        guard attributedText.ranges(containing: .link, inRange: range) == [range] else { return false }
        ZClientViewController.shared()?.present(confirmationAlert(for: url), animated: true, completion: nil)
        return true
    }
}


extension LinkInteractionTextView: UITextViewDelegate {
    
    func textView(_ textView: UITextView, shouldInteractWith textAttachment: NSTextAttachment, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
        guard interaction == .presentActions else { return true }
        interactionDelegate?.textViewDidLongPress(self)
        return false
    }
    
    func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
        switch interaction {
        case .invokeDefaultAction:
            
            guard !UIMenuController.shared.isMenuVisible else {
                return false // Don't open link/show alert if menu controller is visible
            }

            // if alert shown, link opening is handled in alert actions
            if showAlertIfNeeded(for: URL, in: characterRange) { return false }

            /// workaround for iOS 13 - this delegate method is called multiple times and we only want to handle it when the state == .ended
            if #available(iOS 13.0, *) {
                if textView.gestureRecognizers?.contains(where: {$0.isKind(of: UITapGestureRecognizer.self) && $0.state == .ended}) == true {

                    // data detector links should be handle by the system
                    return dataDetectedURLSchemes.contains(URL.scheme ?? "") || !(interactionDelegate?.textView(self, open: URL) ?? false)
                }

                return true
            } else {
                // data detector links should be handle by the system
                return dataDetectedURLSchemes.contains(URL.scheme ?? "") || !(interactionDelegate?.textView(self, open: URL) ?? false)
            }
            
        case .presentActions,
             .preview:
            // do not allow peeking links, as it blocks showing the menu for replies
            interactionDelegate?.textViewDidLongPress(self)
            return false
        @unknown default:
            interactionDelegate?.textViewDidLongPress(self)
            return false
        }
    }
}

@available(iOS 11.0, *)
extension LinkInteractionTextView: UITextDragDelegate {
    
    func textDraggableView(_ textDraggableView: UIView & UITextDraggable, itemsForDrag dragRequest: UITextDragRequest) -> [UIDragItem] {
        
        func isMentionLink(_ attributeTuple: (NSAttributedString.Key, Any)) -> Bool {
            return attributeTuple.0 == NSAttributedString.Key.link && (attributeTuple.1 as? NSURL)?.scheme ==  Mention.mentionScheme
        }
        
        if let attributes = textStyling(at: dragRequest.dragRange.start, in: .forward) {
            if attributes.contains(where: isMentionLink) {
                return []
            }
        }
        
        return dragRequest.suggestedItems
    }
    
}
