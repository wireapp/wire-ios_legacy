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

import UIKit
@testable import Wire

class AudioRecorderTests: XCTestCase {

    var recorder: AudioRecorder?
    
    func testThatItFiresAudioMessageMaximumSizeError() {
        
        recorder = AudioRecorder(maxRecordingDuration: 100, maxFileSize: 0)
        recorder?.startRecording()
        
        let expectation = self.expectation(description: "Wait for recorder to stop")
        
        recorder?.recordEndedCallback = { result in
            expectation.fulfill()
            let error = result.error
            XCTAssertNotNil(error)
            XCTAssertEqual(error as! RecordingError, RecordingError.toMaxSize)
        }
        
        self.waitForExpectations(timeout: 10.0, handler: nil)
    }
    
    func testThatItFiresAudioMessageMaximumDurationError() {
        
        recorder = AudioRecorder(maxRecordingDuration: 1, maxFileSize: 1000000)
        recorder?.startRecording()
        
        let expectation = self.expectation(description: "Wait for recorder to stop")
        
        recorder?.recordEndedCallback = { result in
            expectation.fulfill()
            let error = result.error
            XCTAssertNotNil(error)
            XCTAssertEqual(error as! RecordingError, RecordingError.toMaxDuration)
        }
        
        self.waitForExpectations(timeout: 10.0, handler: nil)
    }
}
