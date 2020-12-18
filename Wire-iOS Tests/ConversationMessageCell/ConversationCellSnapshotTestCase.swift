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
import SnapshotTesting

/**
 * A base test class for section-based messages. Use the section property to build
 * your layout and call `verifySectionSnapshots` to record and verify the snapshot.
 */
class ConversationCellSnapshotTestCase: XCTestCase, CoreDataFixtureTestHelper {
    var coreDataFixture: CoreDataFixture!
    
    fileprivate static let defaultContext = ConversationMessageContext(isSameSenderAsPrevious: false,
                                                                       isTimeIntervalSinceLastMessageSignificant: false,
                                                                       isFirstMessageOfTheDay: false,
                                                                       isFirstUnreadMessage: false,
                                                                       isLastMessage: false,
                                                                       searchQueries: [],
                                                                       previousMessageIsKnock: false,
                                                                       spacing: 0)
    
    override class func setUp() {
        resetDayFormatter()
        
        [Message.shortDateFormatter, Message.shortTimeFormatter].forEach {
            $0.locale = Locale(identifier: "en_US")
            $0.timeZone = TimeZone(abbreviation: "CET")
        }
    }
    
    override class func tearDown() {
        ColorScheme.default.variant = .light
    }
    
    override func setUp() {
        super.setUp()
        coreDataFixture = CoreDataFixture()
        
        ColorScheme.default.variant = .light
        
    }
    
    override func tearDown() {
        coreDataFixture = nil
        super.tearDown()
    }
    
    private func createUIStackView(
        message: ZMConversationMessage,
        context: ConversationMessageContext?,
        waitForImagesToLoad: Bool,
        waitForTextViewToLoad: Bool,
        snapshotBackgroundColor: UIColor?
    ) -> UIStackView {
        let context = (context ?? ConversationCellSnapshotTestCase.defaultContext)!

        let section = ConversationMessageSectionController(message: message, context: context)
        let views = section.cellDescriptions.map({ $0.makeView() })
        let stackView = UIStackView(arrangedSubviews: views)
        stackView.axis = .vertical
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.backgroundColor = snapshotBackgroundColor ?? (ColorScheme.default.variant == .light ? .white : .black)
        
        if waitForImagesToLoad {
            XCTAssert(waitForGroupsToBeEmpty([MediaAssetCache.defaultImageCache.dispatchGroup]))
        }
        
        if waitForTextViewToLoad {
            // We need to run the run loop for UITextView to highlight detected links
            let delay = Date().addingTimeInterval(1)
            RunLoop.main.run(until: delay)
        }
        
        return stackView

    }
    
    /**
     * Performs a snapshot test for a message
     */
    func verify(message: ZMConversationMessage,
                context: ConversationMessageContext? = nil,
                waitForImagesToLoad: Bool = false,
                waitForTextViewToLoad: Bool = false,
                allColorSchemes: Bool = false,
                allWidths: Bool = true,
                snapshotBackgroundColor: UIColor? = nil,
                file: StaticString = #file,
                testName: String = #function,
                line: UInt = #line) {
        
        
        if allColorSchemes {
            ColorScheme.default.variant = .dark
            verify(matching: createUIStackView(message: message, context: context, waitForImagesToLoad: waitForImagesToLoad, waitForTextViewToLoad: waitForTextViewToLoad, snapshotBackgroundColor: snapshotBackgroundColor),
                   snapshotBackgroundColor: snapshotBackgroundColor,
                   named: "dark",
                   allWidths: allWidths,
                   file: file,
                   testName: testName,
                   line: line)

            ColorScheme.default.variant = .light
            verify(matching: createUIStackView(message: message, context: context, waitForImagesToLoad: waitForImagesToLoad, waitForTextViewToLoad: waitForTextViewToLoad, snapshotBackgroundColor: snapshotBackgroundColor),
                   snapshotBackgroundColor: snapshotBackgroundColor,
                   named: "light",
                   allWidths: allWidths,
                   file: file,
                   testName: testName,
                   line: line)            
        } else {
            verify(matching: createUIStackView(message: message, context: context, waitForImagesToLoad: waitForImagesToLoad, waitForTextViewToLoad: waitForTextViewToLoad, snapshotBackgroundColor: snapshotBackgroundColor),
                   snapshotBackgroundColor: snapshotBackgroundColor,
                   allWidths: allWidths,
                   file: file,
                   testName: testName,
                   line: line)
        }
    }
    
    private func verify(matching value: UIView,
                        snapshotBackgroundColor: UIColor?,
                        named name: String? = nil,
                        allColorSchemes: Bool = false,
                        allWidths: Bool = true,
                        file: StaticString = #file,
                        testName: String = #function,
                        line: UInt = #line) {
        let backgroundColor = snapshotBackgroundColor ?? (ColorScheme.default.variant == .light ? .white : .black)
        
        if allWidths {
            verifyInAllPhoneWidths(matching:value,
                                   snapshotBackgroundColor: backgroundColor,
                                   named: name,
                                   file: file,
                                   testName: testName,
                                   line: line)
        } else {
            verifyInWidths(matching:value,
                           widths: [smallestWidth],
                           snapshotBackgroundColor: backgroundColor,
                           named: name,
                           file: file,
                           testName: testName,
                           line: line)
        }
    }
    
}

func XCTAssertArrayEqual(_ descriptions: [Any], _ expectedDescriptions: [Any], file: StaticString = #file, line: UInt = #line) {
    let classes = descriptions.map { String(describing: $0) }
    let expectedClasses = expectedDescriptions.map { String(describing: $0) }
    XCTAssertEqual(classes, expectedClasses, file: file, line: line)
}
