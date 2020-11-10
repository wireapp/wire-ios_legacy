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

fileprivate struct CallActionsViewInput: CallActionsViewInputType {
    var permissions: CallPermissionsConfiguration
    let canToggleMediaType, isVideoCall, isMuted, canAccept, isTerminating: Bool
    let mediaState: MediaState
    let variant: ColorSchemeVariant
    var cameraType: CaptureDevice
    let networkQuality: NetworkQuality = .normal
}

class CallActionsViewTests: ZMSnapshotTestCase {
    
    fileprivate var sut: CallActionsView!
    fileprivate var widthConstraint: NSLayoutConstraint!

    override func setUp() {
        super.setUp()
        snapshotBackgroundColor = .darkGray
        sut = CallActionsView()
        sut.translatesAutoresizingMaskIntoConstraints = false
        widthConstraint = sut.widthAnchor.constraint(equalToConstant: 340)
        widthConstraint.isActive = true
        sut.setNeedsLayout()
        sut.layoutIfNeeded()
    }
    
    override func tearDown() {
        sut = nil
        widthConstraint = nil
        super.tearDown()
    }
    
    // MARK: - Light Theme
    
    func testCallActionsView_LightTheme_WithSelectedButtons() {
        snapshotBackgroundColor = .white
        
        // Given
        let input = CallActionsViewInput(
            permissions: MockCallPermissions.videoAllowedForever,
            canToggleMediaType: true,
            isVideoCall: false,
            isMuted: true,
            canAccept: true,
            isTerminating: false,
            mediaState: .notSendingVideo(speakerState: .selectedCanBeToggled),
            variant: .light,
            cameraType: .front
        )
        
        // When
        sut.update(with: input)
        
        // Then
        verify(view: sut)
    }
    
    func testCallActionsView_LightTheme() {
        snapshotBackgroundColor = .white
        
        // Given
        let input = CallActionsViewInput(
            permissions: MockCallPermissions.videoAllowedForever,
            canToggleMediaType: true,
            isVideoCall: false,
            isMuted: false,
            canAccept: true,
            isTerminating: false,
            mediaState: .notSendingVideo(speakerState: .deselectedCanBeToggled),
            variant: .light,
            cameraType: .front
        )
        
        // When
        sut.update(with: input)
        
        // Then
        verify(view: sut)
    }
    
    // MARK: - Dark Theme

    func testCallActionsView_DarkTheme_WithSelectedButtons() {
        snapshotBackgroundColor = .black
        
        // Given
        let input = CallActionsViewInput(
            permissions: MockCallPermissions.videoAllowedForever,
            canToggleMediaType: true,
            isVideoCall: false,
            isMuted: true,
            canAccept: true,
            isTerminating: false,
            mediaState: .notSendingVideo(speakerState: .selectedCanBeToggled),
            variant: .dark,
            cameraType: .front
        )
        
        // When
        sut.update(with: input)
        
        // Then
        verify(view: sut)
    }
    
    func testCallActionsView_DarkTheme() {
        snapshotBackgroundColor = .black
        
        // Given
        let input = CallActionsViewInput(
            permissions: MockCallPermissions.videoAllowedForever,
            canToggleMediaType: true,
            isVideoCall: false,
            isMuted: false,
            canAccept: true,
            isTerminating: false,
            mediaState: .notSendingVideo(speakerState: .deselectedCanBeToggled),
            variant: .dark,
            cameraType: .front
        )
        
        // When
        sut.update(with: input)
        
        // Then
        verify(view: sut)
    }
    
    // MARK: - Compact
    
    func testCallActionsView_Compact() {
        // Given
        let input = CallActionsViewInput(
            permissions: MockCallPermissions.videoPendingApproval,
            canToggleMediaType: true,
            isVideoCall: false,
            isMuted: false,
            canAccept: true,
            isTerminating: false,
            mediaState: .notSendingVideo(speakerState: .selectedCanBeToggled),
            variant: .light,
            cameraType: .front
        )
        
        // When
        widthConstraint.constant = 400
        sut.isCompact = true
        sut.update(with: input)
        
        // Then
        verify(view: sut)
    }
    
    // MARK: - Call State: Incoming
    
    func testCallActionsView_StateIncoming_Audio() {

        // Given
        let input = CallActionsViewInput(
            permissions: MockCallPermissions.videoAllowedForever,
            canToggleMediaType: false,
            isVideoCall: false,
            isMuted: false,
            canAccept: true,
            isTerminating: false,
            mediaState: .notSendingVideo(speakerState: .deselectedCanBeToggled),
            variant: .light,
            cameraType: .front
        )
        
        // When
        sut.update(with: input)
        
        // Then
        verify(view: sut)
    }

    func testCallActionsView_StateIncoming_Video() {
        // Given
        let input = CallActionsViewInput(
            permissions: MockCallPermissions.videoAllowedForever,
            canToggleMediaType: false,
            isVideoCall: false,
            isMuted: false,
            canAccept: true,
            isTerminating: false,
            mediaState: .notSendingVideo(speakerState: .deselectedCanBeToggled),
            variant: .dark,
            cameraType: .front
        )
        
        // When
        sut.update(with: input)
        
        // Then
        verify(view: sut)
    }
    
    // MARK: - Call State: Outgoing
    
    func testCallActionsView_StateOutgoing_Audio() {
        // Given
        let input = CallActionsViewInput(
            permissions: MockCallPermissions.videoAllowedForever,
            canToggleMediaType: true,
            isVideoCall: false,
            isMuted: false,
            canAccept: false,
            isTerminating: false,
            mediaState: .notSendingVideo(speakerState: .deselectedCanBeToggled),
            variant: .light,
            cameraType: .front
        )
        
        // When
        sut.update(with: input)
        
        // Then
        verify(view: sut)
    }
    
    func testCallActionsView_StateOutgoing_Video() {
        // Given
        let input = CallActionsViewInput(
            permissions: MockCallPermissions.videoAllowedForever,
            canToggleMediaType: true,
            isVideoCall: true,
            isMuted: false,
            canAccept: false,
            isTerminating: false,
            mediaState: .sendingVideo,
            variant: .dark,
            cameraType: .front
        )
        
        // When
        sut.update(with: input)
        
        // Then
        verify(view: sut)
    }

    // MARK: Call State: - Ongoing

    func testCallActionsView_StateOngoing_Audio() {
        // Given
        let input = CallActionsViewInput(
            permissions: MockCallPermissions.videoAllowedForever,
            canToggleMediaType: true,
            isVideoCall: false,
            isMuted: false,
            canAccept: false,
            isTerminating: false,
            mediaState: .notSendingVideo(speakerState: .deselectedCanBeToggled),
            variant: .light,
            cameraType: .front
        )
        
        // When
        sut.update(with: input)
        
        // Then
        verify(view: sut)
    }
    
    func testCallActionsView_StateOngoing_Audio_Muted() {
        // Given
        let input = CallActionsViewInput(
            permissions: MockCallPermissions.videoAllowedForever,
            canToggleMediaType: true,
            isVideoCall: false,
            isMuted: true,
            canAccept: false,
            isTerminating: false,
            mediaState: .notSendingVideo(speakerState: .deselectedCanBeToggled),
            variant: .light,
            cameraType: .front
        )
        
        // When
        sut.update(with: input)
        
        // Then
        verify(view: sut)
    }
    
    func testCallActionsView_StateOngoing_Audio_SpeakerUnavailable() {
        // Given
        let input = CallActionsViewInput(
            permissions: MockCallPermissions.videoAllowedForever,
            canToggleMediaType: true,
            isVideoCall: false,
            isMuted: false,
            canAccept: false,
            isTerminating: false,
            mediaState: .notSendingVideo(speakerState: .deselectedCanNotBeToggled),
            variant: .light,
            cameraType: .front
        )
        
        // When
        sut.update(with: input)
        
        // Then
        verify(view: sut)
    }
    
    func testCallActionsView_StateOngoing_Video() {
        // Given
        let input = CallActionsViewInput(
            permissions: MockCallPermissions.videoAllowedForever,
            canToggleMediaType: true,
            isVideoCall: true,
            isMuted: false,
            canAccept: false,
            isTerminating: false,
            mediaState: .sendingVideo,
            variant: .dark,
            cameraType: .front
        )
        
        // When
        sut.update(with: input)
        
        // Then
        verify(view: sut)
    }
    
    // MARK: Call State: - Terminating
    
    func testCallActionsView_StateTerminating_Audio() {
        // Given
        let input = CallActionsViewInput(
            permissions: MockCallPermissions.videoAllowedForever,
            canToggleMediaType: true,
            isVideoCall: false,
            isMuted: false,
            canAccept: false,
            isTerminating: true,
            mediaState: .notSendingVideo(speakerState: .deselectedCanBeToggled),
            variant: .light,
            cameraType: .front
        )
        
        // When
        sut.update(with: input)
        
        // Then
        verify(view: sut)
    }
    
    func testCallActionsView_StateTerminating_Video() {
        // Given
        let input = CallActionsViewInput(
            permissions: MockCallPermissions.videoAllowedForever,
            canToggleMediaType: true,
            isVideoCall: true,
            isMuted: false,
            canAccept: false,
            isTerminating: true,
            mediaState: .sendingVideo,
            variant: .dark,
            cameraType: .front
        )
        
        // When
        sut.update(with: input)
        
        // Then
        verify(view: sut)
    }
    
    // MARK: - Permissions

    func testCallActionsView_Permissions_NotDetermined() {
        // Given
        let input = CallActionsViewInput(
            permissions: MockCallPermissions.videoPendingApproval,
            canToggleMediaType: false,
            isVideoCall: true,
            isMuted: false,
            canAccept: false,
            isTerminating: false,
            mediaState: .notSendingVideo(speakerState: .deselectedCanBeToggled),
            variant: .light,
            cameraType: .front
        )

        // When
        sut.update(with: input)

        // Then
        verify(view: sut)
    }

    func testCallActionsView_Permissions_NotAllowed() {
        // Given
        let input = CallActionsViewInput(
            permissions: MockCallPermissions.videoDeniedForever,
            canToggleMediaType: false,
            isVideoCall: true,
            isMuted: false,
            canAccept: false,
            isTerminating: false,
            mediaState: .notSendingVideo(speakerState: .deselectedCanBeToggled),
            variant: .light,
            cameraType: .front
        )

        // When
        sut.update(with: input)

        // Then
        verify(view: sut)
    }

}
