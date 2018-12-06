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

extension NSAttributedString {
    fileprivate static func readReceiptsText(_ isEnabled: Bool) -> NSAttributedString {
        
        let paragraph = NSParagraphStyle.default.mutableCopy() as! NSMutableParagraphStyle
        paragraph.paragraphSpacing = 8
        paragraph.firstLineHeadIndent = 5
        paragraph.headIndent = 5
        paragraph.tailIndent = -5
        
        let titleFont = UIFont.smallSemiboldFont
        
        let titleText = isEnabled ? "profile.read_receipts_enabled_memo.header".localized : "profile.read_receipts_disabled_memo.header".localized
        
        let title = titleText && [NSAttributedString.Key.font: titleFont,
                                  NSAttributedString.Key.foregroundColor: UIColor.from(scheme: .sectionText),
                                  NSAttributedString.Key.paragraphStyle: paragraph]
        
        let lineBreak = "\n" && [NSAttributedString.Key.paragraphStyle: paragraph]
        
        let textFont = UIFont.mediumFont
        let text = "profile.read_receipts_memo.body".localized && [NSAttributedString.Key.font: textFont,
                                                                   NSAttributedString.Key.foregroundColor: UIColor.from(scheme: .textDimmed),
                                                                   NSAttributedString.Key.paragraphStyle: paragraph]
        
        return title + lineBreak + text
    }
}

extension ProfileDetailsViewController {
    @objc func setupStyle() {
        remainingTimeLabel.textColor = .from(scheme: .textDimmed)
        remainingTimeLabel.font = .mediumSemiboldFont
    }

    // MARK: - action menu

    @objc func presentMenuSheetController() {
        actionsController = ConversationActionController(conversation: conversation, target: self)
        actionsController.presentMenu(from: footerView, showConverationNameInMenuTitle: false)
    }
    
    // MARK: - Bottom labels
    
    @objc func createReadReceiptsEnabledLabel() {
        guard let selfUser = ZMUser.selfUser() else {
            return
        }
        
        readReceiptsEnabledLabel = UILabel()
        readReceiptsEnabledLabel.translatesAutoresizingMaskIntoConstraints = false
        readReceiptsEnabledLabel.accessibilityIdentifier = "ReadReceiptsEnabledLabel"
        
        readReceiptsEnabledLabel.setContentCompressionResistancePriority(.required, for: .vertical)
        readReceiptsEnabledLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
        readReceiptsEnabledLabel.setContentHuggingPriority(.required, for: .vertical)
        readReceiptsEnabledLabel.setContentHuggingPriority(.required, for: .horizontal)

        readReceiptsEnabledLabel.lineBreakMode = .byWordWrapping
        readReceiptsEnabledLabel.numberOfLines = 0
    
        readReceiptsEnabledLabel.attributedText = NSAttributedString.readReceiptsText(selfUser.readReceiptsEnabled)
        
        // On small screens the label gets compressed for unknown reason.
        if UIScreen.main.isSmall {
            readReceiptsEnabledLabel.heightAnchor.constraint(greaterThanOrEqualToConstant: 100).isActive = true
        }
    }

}
