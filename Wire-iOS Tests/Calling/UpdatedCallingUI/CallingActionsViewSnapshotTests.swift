//
// Wire
// Copyright (C) 2022 Wire Swiss GmbH
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
import WireSyncEngine
@testable import Wire

private struct CallingActionsViewInput: CallActionsViewInputType {
    var allowPresentationModeUpdates: Bool
    var videoGridPresentationMode: VideoGridPresentationMode
    var permissions: CallPermissionsConfiguration
    let canToggleMediaType, isVideoCall, isMuted: Bool
    let mediaState: MediaState
    let variant: ColorSchemeVariant
    var cameraType: CaptureDevice
    let networkQuality: NetworkQuality = .normal
    let callState: CallStateExtending
}

struct CallingStateMock: CallStateExtending {
    var isConnected: Bool
    var isTerminating: Bool
    var canAccept: Bool
}

extension CallingStateMock {
    static var incoming: CallingStateMock {
        return CallingStateMock(isConnected: false, isTerminating: false, canAccept: true)
    }

    static var outgoing: CallingStateMock {
        return CallingStateMock(isConnected: false, isTerminating: false, canAccept: false)
    }

    static var terminating: CallingStateMock {
        return CallingStateMock(isConnected: false, isTerminating: true, canAccept: false)
    }

    static var ongoing: CallingStateMock {
        return CallingStateMock(isConnected: true, isTerminating: false, canAccept: false)
    }
}

class CallingActionsViewSnapshotTests: ZMSnapshotTestCase {

    fileprivate var sut: CallingActionsView!
    fileprivate var widthConstraint: NSLayoutConstraint!

    override func setUp() {
        super.setUp()
    }

    override func tearDown() {
        sut = nil
        widthConstraint = nil
        super.tearDown()
    }

    private func createSut() {
        sut = CallingActionsView()
        sut.frame = CGRect(origin: .zero, size: CGSize(width: 382, height: 106))
    }

    func testCallActionsView_Compact() {
        // Given
       createSut()

        let input = CallingActionsViewInput(
            allowPresentationModeUpdates: true,
            videoGridPresentationMode: .allVideoStreams,
            permissions: MockCallPermissions.videoAllowedForever,
            canToggleMediaType: false,
            isVideoCall: false,
            isMuted: false,
            mediaState: .notSendingVideo(speakerState: .deselectedCanBeToggled),
            variant: .dark,
            cameraType: .front,
            callState: CallingStateMock.ongoing
        )

        // When
        sut.update(with: input)

        // Then
        verify(view: sut)
    }

    // MARK: - Call State: Incoming

    func testCallActionsView_StateIncoming_Audio() {
        // Given
        createSut()
        sut.isIncomingCall = true

        let input = CallingActionsViewInput(
            allowPresentationModeUpdates: false,
            videoGridPresentationMode: .allVideoStreams,
            permissions: MockCallPermissions.videoAllowedForever,
            canToggleMediaType: false,
            isVideoCall: false,
            isMuted: false,
            mediaState: .notSendingVideo(speakerState: .deselectedCanBeToggled),
            variant: .dark,
            cameraType: .front,
            callState: CallingStateMock.incoming
        )

        // When
        sut.update(with: input)

        // Then
        verify(view: sut)
    }

    func testCallActionsView_StateIncoming_Streaming_Video() {
        // Given
        createSut()
        sut.isIncomingCall = true

        let input = CallingActionsViewInput(
            allowPresentationModeUpdates: false,
            videoGridPresentationMode: .allVideoStreams,
            permissions: MockCallPermissions.videoAllowedForever,
            canToggleMediaType: true,
            isVideoCall: true,
            isMuted: false,
            mediaState: .sendingVideo,
            variant: .dark,
            cameraType: .front,
            callState: CallingStateMock.incoming
        )

        // When
        sut.update(with: input)

        // Then
        verify(view: sut)
    }

    // MARK: Call State: - Ongoing

    func testCallActionsView_StateOngoing_Audio() {
        // Given
        createSut()

        let input = CallingActionsViewInput(
            allowPresentationModeUpdates: false,
            videoGridPresentationMode: .allVideoStreams,
            permissions: MockCallPermissions.videoAllowedForever,
            canToggleMediaType: true,
            isVideoCall: false,
            isMuted: false,
            mediaState: .notSendingVideo(speakerState: .deselectedCanBeToggled),
            variant: .dark,
            cameraType: .front,
            callState: CallingStateMock.ongoing
        )

        // When
        sut.update(with: input)

        // Then
        verify(view: sut)
    }

    func testCallActionsView_StateOngoing_Audio_Muted() {
        // Given
        createSut()

        let input = CallingActionsViewInput(
            allowPresentationModeUpdates: false,
            videoGridPresentationMode: .allVideoStreams,
            permissions: MockCallPermissions.videoAllowedForever,
            canToggleMediaType: true,
            isVideoCall: false,
            isMuted: true,
            mediaState: .notSendingVideo(speakerState: .deselectedCanBeToggled),
            variant: .dark,
            cameraType: .front,
            callState: CallingStateMock.ongoing
        )

        // When
        sut.update(with: input)

        // Then
        verify(view: sut)
    }

    func testCallActionsView_StateOngoing_Video() {
        // Given
        createSut()

        let input = CallingActionsViewInput(
            allowPresentationModeUpdates: false,
            videoGridPresentationMode: .allVideoStreams,
            permissions: MockCallPermissions.videoAllowedForever,
            canToggleMediaType: true,
            isVideoCall: true,
            isMuted: false,
            mediaState: .sendingVideo,
            variant: .dark,
            cameraType: .front,
            callState: CallingStateMock.ongoing
        )

        // When
        sut.update(with: input)

        // Then
        verify(view: sut)
    }

    func testCallActionsView_StateOngoing_Video_PresentationMode_AllVideoStreams() {
        // Given
        createSut()

        let input = CallingActionsViewInput(
            allowPresentationModeUpdates: true,
            videoGridPresentationMode: .allVideoStreams,
            permissions: MockCallPermissions.videoAllowedForever,
            canToggleMediaType: true,
            isVideoCall: true,
            isMuted: false,
            mediaState: .sendingVideo,
            variant: .dark,
            cameraType: .front,
            callState: CallingStateMock.ongoing
        )

        // When
        sut.update(with: input)

        // Then
        verify(view: sut)
    }

    // MARK: - Permissions

    func testCallActionsView_Permissions_NotDetermined() {
        // Given
        createSut()

        let input = CallingActionsViewInput(
            allowPresentationModeUpdates: false,
            videoGridPresentationMode: .allVideoStreams,
            permissions: MockCallPermissions.videoPendingApproval,
            canToggleMediaType: false,
            isVideoCall: true,
            isMuted: false,
            mediaState: .notSendingVideo(speakerState: .deselectedCanBeToggled),
            variant: .dark,
            cameraType: .front,
            callState: CallingStateMock.ongoing
        )

        // When
        sut.update(with: input)

        // Then
        verify(view: sut)
    }

    func testCallActionsView_Permissions_NotAllowed() {
        // Given
        createSut()

        let input = CallingActionsViewInput(
            allowPresentationModeUpdates: false,
            videoGridPresentationMode: .allVideoStreams,
            permissions: MockCallPermissions.videoDeniedForever,
            canToggleMediaType: false,
            isVideoCall: true,
            isMuted: false,
            mediaState: .notSendingVideo(speakerState: .deselectedCanBeToggled),
            variant: .dark,
            cameraType: .front,
            callState: CallingStateMock.ongoing
        )

        // When
        sut.update(with: input)

        // Then
        verify(view: sut)
    }

}
