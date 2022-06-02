//
// Wire
// Copyright (C) 2018 Wire Swiss GmbH
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
import UIKit

extension MarkdownTextView {
    func setupGestureRecognizer() {
        let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(didTapTextView(_:)))
        tapRecognizer.delegate = self
        addGestureRecognizer(tapRecognizer)
    }

    @objc func didTapTextView(_ recognizer: UITapGestureRecognizer) {
        var location = recognizer.location(in: self)
        location.x -= textContainerInset.left
        location.y -= textContainerInset.top

        let characterIndex = layoutManager.characterIndex(for: location, in: textContainer, fractionOfDistanceBetweenInsertionPoints: nil)
        selectTextAttachmentIfNeeded(at: characterIndex)
    }

    func selectTextAttachmentIfNeeded(at index: Int) {
        guard attributedText.wholeRange.contains(index) else { return }

        let attributes = attributedText.attributes(at: index, effectiveRange: nil)
        guard attributes[NSAttributedString.Key.attachment] as? MentionTextAttachment != nil else { return }

        guard let start = position(from: beginningOfDocument, offset: index) else { return }
        guard let end = position(from: start, offset: 1) else { return }

        selectedTextRange = textRange(from: start, to: end)
    }
}

extension MarkdownTextView: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {

        // prevent recognizing other UIPanGestureRecognizers at the same time, e.g. SplitViewController's panGestureRecognizers will dismiss the keyboard and this MarkdownTextView moves down immediately
        if otherGestureRecognizer is UIPanGestureRecognizer {
            return false
        }

        return true
    }
}
