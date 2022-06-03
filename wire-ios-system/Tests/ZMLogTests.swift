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


import XCTest
@testable import WireSystem

class ZMLogTests: XCTestCase {

    override func setUp() {
        super.setUp()
        ZMSLog.debug_resetAllLevels();
        ZMSLog.clearLogs()
    }
    
    override func tearDown() {
        ZMSLog.debug_resetAllLevels();
        ZMSLog.stopRecording()
        ZMSLog.removeAllLogHooks()
        super.tearDown()
    }
    
    func testThatTheLoggerRegistersATag() {
        
        // given
        let tag = "Foo"
        
        // when
        let _ = ZMSLog(tag: tag)
        
        // then
        let allTags = ZMSLog.allTags
        XCTAssertTrue(allTags.contains(tag))
    }
    
    func testThatTheLoggerRegistersTheRightLevel() {
        
        // given
        let tag = "Test11"
        
        // when
        let _ = ZMSLog(tag: tag)
        
        // then
        XCTAssertEqual(ZMSLog.getLevel(tag: tag), ZMLogLevel_t.warn)
    }
    
    func testThatTheLevelIsDebug() {
        
        // given
        let tag = "22test"
        let sut = ZMSLog(tag: tag)
        ZMSLog.set(level: .debug, tag: tag)
        
        // when
        var isDebug = false
        var isWarn = false
        var isInfo = false
        sut.ifDebug { isDebug = true }
        sut.ifInfo { isInfo = true }
        sut.ifWarn { isWarn = true }
        
        // then
        XCTAssertTrue(isDebug)
        XCTAssertTrue(isInfo)
        XCTAssertTrue(isWarn)
    }
    
    func testThatTheLevelIsWarn() {
        
        // given
        let tag = "22test"
        let sut = ZMSLog(tag: tag)
        ZMSLog.set(level: .warn, tag: tag)
        
        // when
        var isDebug = false
        var isWarn = false
        var isInfo = false
        sut.ifDebug { isDebug = true }
        sut.ifInfo { isInfo = true }
        sut.ifWarn { isWarn = true }
        
        // then
        XCTAssertFalse(isDebug)
        XCTAssertFalse(isInfo)
        XCTAssertTrue(isWarn)
    }
    
    func testThatTheLevelIsInfo() {
        
        // given
        let tag = "22test"
        let sut = ZMSLog(tag: tag)
        ZMSLog.set(level: .info, tag: tag)
        
        // when
        var isDebug = false
        var isWarn = false
        var isInfo = false
        sut.ifDebug { isDebug = true }
        sut.ifInfo { isInfo = true }
        sut.ifWarn { isWarn = true }
        
        // then
        XCTAssertFalse(isDebug)
        XCTAssertTrue(isInfo)
        XCTAssertTrue(isWarn)
    }
    
    func testThatTheLevelIsError() {
        
        // given
        let tag = "22test"
        let sut = ZMSLog(tag: tag)
        ZMSLog.set(level: .error, tag: tag)
        
        // when
        var isDebug = false
        var isWarn = false
        var isInfo = false
        sut.ifDebug { isDebug = true }
        sut.ifInfo { isInfo = true }
        sut.ifWarn { isWarn = true }
        
        // then
        XCTAssertFalse(isDebug)
        XCTAssertFalse(isInfo)
        XCTAssertFalse(isWarn)
    }
}

// MARK: - Log level management
extension ZMLogTests {
    
    func testThatLogIsNotRegisteredIfNoLogIsCalled() {
        XCTAssertEqual(ZMSLog.allTags.count, 0);
    }

    func testThatLogIsRegistered() {
        
        // GIVEN
        let tag = "Async"
        
        // WHEN
        ZMSLog.register(tag: tag)
        
        // THEN
        XCTAssertTrue(ZMSLog.allTags.contains(tag));
    }
    
    func testThatTheLogTagIsRegisteredAfterInitializingLog() {
        
        // GIVEN
        let tag = "Network"
        
        // WHEN
        let _ = ZMSLog(tag: tag)
        
        // THEN
        XCTAssertTrue(ZMSLog.allTags.contains(tag))
    }
    
    func testThatTheDefaultLogLevelIsWarning() {
        XCTAssertEqual(ZMSLog.getLevel(tag: "1234"), .warn)
    }

    func testThatTheLogLevelCanBeChanged() {
        
        // GIVEN
        let tag = "Draw"
        
        // WHEN
        ZMSLog.set(level: .debug, tag: tag)
        
        // THEN
        XCTAssertEqual(ZMSLog.getLevel(tag: tag), .debug)
    }
}

// MARK: - Debug hook
extension ZMLogTests {
    
    func testThatLogHookIsCalledWithError() {
        
        // GIVEN
        let tag = "Network"
        let level = ZMLogLevel_t.error
        let message = "PANIC!"
        
        let expectation = self.expectation(description: "Log received")
        let token = ZMSLog.addEntryHook { (_level, _tag, entry, isSafe) in
            XCTAssertEqual(level, _level)
            XCTAssertEqual(tag, _tag)
            XCTAssertEqual(entry.text, message)
            expectation.fulfill()
        }
        
        // WHEN
        ZMSLog(tag: tag).error(message)
        
        // THEN
        self.waitForExpectations(timeout: 0.5)
        
        // AFTER
        ZMSLog.removeLogHook(token: token)
    }
    
    func testThatLogHookIsNotCalledWithInfo() {
        
        // GIVEN
        let tag = "Network"
        let level = ZMLogLevel_t.info
        let message = "PANIC!"
        
        let token = ZMSLog.addEntryHook { (_level, _tag, entry, isSafe) in
            XCTAssertEqual(level, _level)
            XCTAssertEqual(tag, _tag)
            XCTAssertEqual(entry.text, message)
        }
        
        // WHEN
        ZMSLog(tag: tag).info(message)
        
        // THEN
        Thread.sleep(forTimeInterval: 0.2)
        
        // AFTER
        ZMSLog.removeLogHook(token: token)
    }
    
    func testThatLogHookIsCalledWithWarning() {
        
        // GIVEN
        let tag = "Network"
        let level = ZMLogLevel_t.warn
        let message = "PANIC!"
        
        let expectation = self.expectation(description: "Log received")
        let token = ZMSLog.addEntryHook { (_level, _tag, entry, isSafe) in
            XCTAssertEqual(level, _level)
            XCTAssertEqual(tag, _tag)
            XCTAssertEqual(entry.text, message)
            expectation.fulfill()
        }
        
        // WHEN
        ZMSLog(tag: tag).warn(message)
        
        // THEN
        self.waitForExpectations(timeout: 0.5)
        
        // AFTER
        ZMSLog.removeLogHook(token: token)
    }
    
    func testThatLogHookIsNotCalledWithDebug() {
        
        // GIVEN
        let tag = "Network"
        let level = ZMLogLevel_t.debug
        let message = "PANIC!"
        
        let token = ZMSLog.addEntryHook { (_level, _tag, entry, isSafe) in
            XCTAssertEqual(level, _level)
            XCTAssertEqual(tag, _tag)
            XCTAssertEqual(entry.text, message)
            XCTFail()
        }
        
        // WHEN
        ZMSLog(tag: tag).debug(message)
        
        // THEN
        Thread.sleep(forTimeInterval: 0.2)
        
        // AFTER
        ZMSLog.removeLogHook(token: token)
    }
    
    func testThatLogHookIsCalledWithDebugIfEnabled() {
        
        // GIVEN
        let tag = "Network"
        let level = ZMLogLevel_t.debug
        let message = "PANIC!"
        
        let expectation = self.expectation(description: "Log received")
        let token = ZMSLog.addEntryHook { (_level, _tag, entry, isSafe) in
            XCTAssertEqual(level, _level)
            XCTAssertEqual(tag, _tag)
            XCTAssertEqual(entry.text, message)
            expectation.fulfill()
        }
        
        // WHEN
        ZMSLog.set(level: .debug, tag: tag)
        ZMSLog(tag: tag).debug(message)
        
        // THEN
        self.waitForExpectations(timeout: 0.5)
        
        // AFTER
        ZMSLog.removeLogHook(token: token)
    }
    
    func testThatLogHookIsNotCalledWhenRemoved() {
        
        // GIVEN
        let tag = "Network"
        let message = "PANIC!"

        let token = ZMSLog.addEntryHook { (_level, _tag, entry, isSafe) in
            XCTFail()
        }
        ZMSLog.removeLogHook(token: token)
        
        // WHEN
        ZMSLog(tag: tag).error(message)
        Thread.sleep(forTimeInterval: 0.2)
    }
    
    
    func testThatLogHookIsNotCalledWhenRemovedAll() {
        
        // GIVEN
        let tag = "Network"
        let message = "PANIC!"
        
        let _ = ZMSLog.addEntryHook { (_level, _tag, entry, isSafe) in
            XCTFail()
        }
        ZMSLog.removeAllLogHooks()
        
        // WHEN
        ZMSLog(tag: tag).error(message)
        Thread.sleep(forTimeInterval: 0.2)
    }
    
    func testThatCallsMultipleLogHook() {
        
        // GIVEN
        let tag = "Network"
        let level = ZMLogLevel_t.error
        let message = "PANIC!"
        
        let expectation1 = self.expectation(description: "Log received")
        let expectation2 = self.expectation(description: "Log received")

        let token1 = ZMSLog.addEntryHook { (_level, _tag, entry, isSafe) in
            XCTAssertEqual(level, _level)
            XCTAssertEqual(tag, _tag)
            XCTAssertEqual(entry.text, message)
            expectation1.fulfill()
        }
        let token2 = ZMSLog.addEntryHook { (_level, _tag, entry, isSafe) in
            XCTAssertEqual(level, _level)
            XCTAssertEqual(tag, _tag)
            XCTAssertEqual(entry.text, message)
            expectation2.fulfill()
        }
        
        // WHEN
        ZMSLog(tag: tag).error(message)
        
        // THEN
        self.waitForExpectations(timeout: 0.5)
        
        // AFTER
        ZMSLog.removeLogHook(token: token1)
        ZMSLog.removeLogHook(token: token2)
    }
    
    func testThatItAppendsOnlyOneNewlineWhenLogEntryContainsNewline() {
        // GIVEN
        let sut = ZMSLog(tag: "foo")
        ZMSLog.startRecording()
        
        // WHEN
        sut.error("PANIC\n")
        sut.error("HELP")
        
        Thread.sleep(forTimeInterval: 0.2)
        
        // THEN
        let lines = getLinesFromCurrentLog()

        XCTAssertEqual(lines.count, 2)
    }

}

extension ZMLogTests {
    
    func testThatRecordedLogsAreNotWritedWhenNotStarted() {
        
        // GIVEN
        let sut = ZMSLog(tag: "foo")
        let currentLog = ZMSLog.currentLog
        
        // WHEN
        sut.error("PANIC")
        
        // THEN
        XCTAssertEqual(ZMSLog.currentLog, currentLog)
        
    }
    
    func testThatItRecordsLogs() {
        
        // GIVEN
        let sut = ZMSLog(tag: "foo")
        ZMSLog.startRecording()
        
        // WHEN
        sut.error("PANIC")
        sut.error("HELP")
        
        Thread.sleep(forTimeInterval: 0.2)
        
        // THEN
        let lines = getLinesFromCurrentLog()

        XCTAssertEqual(lines.count, 2)
        XCTAssertTrue(lines.first!.hasSuffix("[1] [foo] PANIC"))
        XCTAssertTrue(lines.last!.hasSuffix("[1] [foo] HELP"))
    }
    
    func testThatItDoesNotRecordsPublicLogsWhenLevelIsTooLow() {
        struct Item: SafeForLoggingStringConvertible {
            var name: String
            var safeForLoggingDescription: String {
                return "hidden"
            }
        }
        
        // GIVEN
        let sut = ZMSLog(tag: "foo")
        let item = Item(name: "Secret")
        ZMSLog.startRecording()
        
        // WHEN
        sut.safePublic("Item: \(item)")
        
        // THEN
        let currentLog = ZMSLog.currentLog
        XCTAssertNil(currentLog)
    }
    
    func testThatItRecordsPublicLogsWhenLevelIsEnabled() {
        struct Item: SafeForLoggingStringConvertible {
            var name: String
            var safeForLoggingDescription: String {
                return "hidden"
            }
        }
        
        // GIVEN
        let sut = ZMSLog(tag: "foo")
        ZMSLog.set(level: .debug, tag: "foo")
        let item = Item(name: "Secret")
        ZMSLog.startRecording()
        
        // WHEN
        sut.safePublic("Item: \(item)")
        
        Thread.sleep(forTimeInterval: 0.2)
        
        // THEN
        let lines = getLinesFromCurrentLog()
        
        XCTAssertEqual(lines.count, 1)
        XCTAssertTrue(lines.first!.hasSuffix("[3] [foo] Item: hidden"))
    }
    
    func testThatItDiscardsLogsWhenStopped() {
        
        // GIVEN
        let sut = ZMSLog(tag: "foo")
        ZMSLog.startRecording()
        
        // WHEN
        sut.error("PANIC")
        sut.error("HELP")
        ZMSLog.stopRecording()
        
        // THEN
        XCTAssertNil(ZMSLog.currentLog)
        XCTAssertNil(ZMSLog.previousLog)
    }
}


// MARK: - Save on disk
extension ZMLogTests {
    
    func testThatItSavesLogsOnDisk() {
        
        //given
        let sut = ZMSLog(tag: "foo")
        ZMSLog.startRecording()
        
        //when
        sut.warn("DON'T")
        sut.error("PANIC")
        
        Thread.sleep(forTimeInterval: 0.2)
        
        //then
        XCTAssertNotNil(ZMSLog.currentLog)
    }
    
    func testThatSwitchesCurrentLogToPrevious() {
        
        //given
        let sut = ZMSLog(tag: "foo")
        ZMSLog.startRecording()
        
        //when
        sut.warn("DON'T")
        sut.error("PANIC")
        
        Thread.sleep(forTimeInterval: 0.2)
        
        let currentLog = ZMSLog.currentLog
        ZMSLog.switchCurrentLogToPrevious()
        
        Thread.sleep(forTimeInterval: 0.2)
        
        //then
        XCTAssertNotNil(ZMSLog.previousLog)
        XCTAssertEqual(ZMSLog.previousLog, currentLog)
        XCTAssertNil(ZMSLog.currentLog)
        
    }
    
}

extension ZMLogTests {
    
    func testThatItSavesDebugTagsInProduction() {
        
        //given
        let tag = "tag"
        let sut = ZMSLog(tag: tag)
        
        //when
        ZMSLog.startRecording(isInternal: false)
        
        sut.safePublic("PUBLIC", level: .public)
        
        ZMSLog.set(level: .error, tag: tag)
        sut.error("ERROR")
        
        ZMSLog.set(level: .warn, tag: tag)
        sut.warn("WARN")
        
        ZMSLog.set(level: .info, tag: tag)
        sut.info("INFO")
        
        ZMSLog.set(level: .debug, tag: tag)
        sut.debug("DEBUG")
        
        Thread.sleep(forTimeInterval: 0.5)
        
        let lines = getLinesFromCurrentLog()
        
        //then
        XCTAssertEqual(lines.count, 1)
        XCTAssertFalse(lines.first!.hasSuffix("[0] [tag] ERROR"))
    }
    
    func testThatItSavesAllLevelsOnInternals() {
        
        //given
        let tag = "tag"
        let sut = ZMSLog(tag: tag)
        
        //when
        ZMSLog.startRecording(isInternal: true)
        ZMSLog.set(level: .debug, tag: "tag")
        
        sut.safePublic("PUBLIC")
        
        ZMSLog.set(level: .error, tag: tag)
        sut.error("ERROR")
        
        ZMSLog.set(level: .warn, tag: tag)
        sut.warn("WARN")
        
        ZMSLog.set(level: .info, tag: tag)
        sut.info("INFO")
        
        ZMSLog.set(level: .debug, tag: tag)
        sut.debug("DEBUG")
        
        Thread.sleep(forTimeInterval: 0.5)
        
        let lines = getLinesFromCurrentLog()
        
        //then
        XCTAssertEqual(lines.count, 5)
        XCTAssertTrue(lines[0].hasSuffix("[3] [tag] PUBLIC"))
        XCTAssertTrue(lines[1].hasSuffix("[1] [tag] ERROR"))
        XCTAssertTrue(lines[2].hasSuffix("[2] [tag] WARN"))
        XCTAssertTrue(lines[3].hasSuffix("[3] [tag] INFO"))
        XCTAssertTrue(lines[4].hasSuffix("[4] [tag] DEBUG"))
    }
    
    
    func getLinesFromCurrentLog(file: StaticString = #file, line: UInt = #line) -> [String] {
        
        guard let currentLog = ZMSLog.currentLog,
            let logContent = String(data: currentLog, encoding: .utf8) else {
                XCTFail(file: file, line: line)
                return []
        }
        
        var lines: [String] = []
        logContent.enumerateLines { (str, _) in
            lines.append(str)
        }
        
        return lines
    }
}
