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

/// The purpose of this subclass of NSTextAttachment is to render a mention in the input bar.
/// It also stores relevant information about the mention that can be used
/// to flatten the attachment when sending a text message containing mentions.
class MentionsTextAttachment: NSTextAttachment {
    
    /// The text the attachment renders, this is the name passed to init prefixed with an "@".
    let attributedText: NSAttributedString
    
    init(name: String, font: UIFont = .normalLightFont, color: UIColor = .accent()) {
        attributedText = "@" + name && font && color
        super.init(data: nil, ofType: nil)
        refreshImage()
    }
    
    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func refreshImage() {
        image = imageForName()
    }

    private func imageForName() -> UIImage? {
        bounds = attributedText.boundingRect(with: .max, options: [], context: nil)
        UIGraphicsBeginImageContextWithOptions(bounds.size, false, 0)
        
        attributedText.draw(at: .zero)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image
    }

}

fileprivate extension CGSize {
    static let max = CGSize(width: .max, height: .max)
}
