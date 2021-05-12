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
@testable import Wire

final private class MockAudioRecordViewControllerDelegate: NSObject, AudioRecordViewControllerDelegate {

    var cancelCallCount: UInt = 0

    func audioRecordViewControllerDidCancel(_ audioRecordViewController: AudioRecordBaseViewController) {
        cancelCallCount += 1
    }

    func audioRecordViewControllerDidStartRecording(_ audioRecordViewController: AudioRecordBaseViewController) {}

    func audioRecordViewControllerWantsToSendAudio(_ audioRecordViewController: AudioRecordBaseViewController, recordingURL: URL, duration: TimeInterval, filter: AVSAudioEffectType) {}
}

final class AudioRecordViewControllerTests: ZMSnapshotTestCase {

    var sut: AudioRecordViewController!
    fileprivate var delegate: MockAudioRecordViewControllerDelegate!

    override func setUp() {
        super.setUp()
        accentColor = .strongBlue
        sut = AudioRecordViewController()
        delegate = MockAudioRecordViewControllerDelegate()
        sut.delegate = delegate
        sut.updateTimeLabel(123)
        sut.setOverlayState(.default, animated: false)
    }

    override func tearDown() {
        sut = nil
        delegate = nil
        super.tearDown()
    }

    func verify() {
        verifyInAllPhoneWidths(view: sut.prepareForSnapshot(), tolerance: 0.05)
    }

    func testThatItRendersViewControllerCorrectlyState_Recording() {
        // when
        XCTAssertEqual(sut.recordingState, AudioRecordState.recording)

        // then
        verify()
    }

    func testThatItRendersViewControllerCorrectlyState_Recording_WithTime() {
        // when
        XCTAssertEqual(sut.recordingState, AudioRecordState.recording)

        // then
        verify()
    }

    func testThatItRendersViewControllerCorrectlyState_Recording_WithTime_Visualization() {
        // when
        XCTAssertEqual(sut.recordingState, AudioRecordState.recording)
        sut.updateTimeLabel(123)
        sut.audioPreviewView.updateWithLevel(0.2)
        sut.setOverlayState(.expanded(0), animated: false)

        // then
        verify()
    }

    func testThatItRendersViewControllerCorrectlyState_Recording_WithTime_Visualization_Full() {
        // when
        XCTAssertEqual(sut.recordingState, AudioRecordState.recording)
        sut.updateTimeLabel(123)
        sut.audioPreviewView.updateWithLevel(0.8)
        sut.setOverlayState(.expanded(1), animated: false)

        // then
        verify()
    }

    func testThatItRendersViewControllerCorrectlyState_FinishedRecording() {
        // when
        sut.recordingState = .finishedRecording

        // then
        verify()
    }

    func testThatItRendersViewControllerCorrectlyState_FinishedRecording_Playing() {
        // when
        sut.recordingState = .finishedRecording
        sut.buttonOverlay.playingState = .playing
        sut.updateTimeLabel(343)

        // then
        verify()
    }

    func testThatItCallsItsDelegateWhenCancelIsPressed() {
        // when
        sut.cancelButton.sendActions(for: .touchUpInside)

        // then
        XCTAssertEqual(delegate.cancelCallCount, 1)
    }

}

private extension UIViewController {
    @discardableResult func prepareForSnapshot() -> UIView {
        beginAppearanceTransition(true, animated: false)
        endAppearanceTransition()

        let container = UIView()
        container.addSubview(view)
        container.translatesAutoresizingMaskIntoConstraints = false
        view.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            view.heightAnchor.constraint(equalToConstant: 112),
            container.heightAnchor.constraint(equalToConstant: 130),
            view.bottomAnchor.constraint(equalTo: container.bottomAnchor),
            view.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            view.trailingAnchor.constraint(equalTo: container.trailingAnchor)
        ])

        return container
    }
}
