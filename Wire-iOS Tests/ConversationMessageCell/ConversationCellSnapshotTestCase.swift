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

import XCTest
@testable import Wire

/**
 * A base test class for section-based messages. Use the section property to build
 * your layout and call `verifySectionSnapshots` to record and verify the snapshot.
 */
class ConversationCellSnapshotTestCase: CoreDataSnapshotTestCase {

    fileprivate var defaultContext: ConversationMessageContext!

    override func setUp() {
        super.setUp()
        
        ColorScheme.default.variant = .light
        NSAttributedString.invalidateParagraphStyle()
        NSAttributedString.invalidateMarkdownStyle()
        snapshotBackgroundColor = UIColor.from(scheme: .contentBackground)
        defaultContext = ConversationMessageContext(isSameSenderAsPrevious: false,
                                                    isLastMessageSentBySelfUser: false,
                                                    isTimeIntervalSinceLastMessageSignificant: false,
                                                    isFirstMessageOfTheDay: false,
                                                    isFirstUnreadMessage: false,
                                                    searchQueries: [])
        
        resetDayFormatter()
        
        [Message.shortDateFormatter, Message.shortTimeFormatter].forEach {
            $0.locale = Locale(identifier: "en_US")
            $0.timeZone = TimeZone(abbreviation: "CET")
        }
    }

    override func tearDown() {
        ColorScheme.default.variant = .light
        defaultContext = nil
        super.tearDown()
    }
    
    func enableDarkMode() {
        ColorScheme.default.variant = .dark
        snapshotBackgroundColor = UIColor.from(scheme: .contentBackground)
        NSAttributedString.invalidateParagraphStyle()
        NSAttributedString.invalidateMarkdownStyle()
    }

    /**
     * Performs a snapshot test for a message
     */
    func verify(message: ZMConversationMessage, context: ConversationMessageContext? = nil, file: StaticString = #file, line: UInt = #line) {
        let context = (context ?? defaultContext)!
        let section = ConversationMessageSectionController(message: message, context: context, layoutProperties: ConversationCellLayoutProperties())
        let views = section.cellDescriptions.map({ $0.makeView() })
        let stackView = UIStackView(arrangedSubviews: views)
        stackView.axis = .vertical
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        verifyView(inAllPhoneWidths: stackView, extraLayoutPass: false, file: file.utf8SignedStart(), line: line)
    }

}
