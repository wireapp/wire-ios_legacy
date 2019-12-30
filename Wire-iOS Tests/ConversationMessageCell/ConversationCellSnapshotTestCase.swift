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
                                                    isTimeIntervalSinceLastMessageSignificant: false,
                                                    isFirstMessageOfTheDay: false,
                                                    isFirstUnreadMessage: false,
                                                    isLastMessage: false,
                                                    searchQueries: [],
                                                    previousMessageIsKnock: false,
                                                    spacing: 0)
        
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
    func verify(message: ZMConversationMessage,
                context: ConversationMessageContext? = nil,
                waitForImagesToLoad: Bool = false,
                waitForTextViewToLoad: Bool = false,
                tolerance: CGFloat = 0,
                colorSchemes: Set<ColorSchemeVariant> = [],
                selfUser: UserType = ZMUser.selfUser(),
                file: StaticString = #file,
                line: UInt = #line) {

        verifyInAllPhoneWidths(initialization:{
            let context = (context ?? defaultContext)!
            let section = ConversationMessageSectionController(message: message, context: context, selfUser: selfUser)
            let views = section.cellDescriptions.map({ $0.makeView() })
            let stackView = UIStackView(arrangedSubviews: views)
            stackView.axis = .vertical
            stackView.translatesAutoresizingMaskIntoConstraints = false

            if waitForImagesToLoad {
                XCTAssertTrue(waitForGroupsToBeEmpty([defaultImageCache.dispatchGroup]))
            }

            if waitForTextViewToLoad {
                // We need to run the run loop for UITextView to highlight detected links
                let delay = Date().addingTimeInterval(1)
                RunLoop.main.run(until: delay)
            }

            return stackView
        },
           tolerance: tolerance,
           colorSchemes: colorSchemes,
           file: file,
           line: line)
    }

}

func XCTAssertArrayEqual(_ descriptions: [Any], _ expectedDescriptions: [Any], file: StaticString = #file, line: UInt = #line) {
    let classes = descriptions.map { String(describing: $0) }
    let expectedClasses = expectedDescriptions.map { String(describing: $0) }
    XCTAssertEqual(classes, expectedClasses, file: file, line: line)
}
