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
    
    func testCallActionsView_CanNotToggle_Video_NotMuted_CanAccept_NotTerminating_NotSendingVideo_SpeakerEnabled() {
        // Given
        let input = CallActionsViewInput(
            permissions: MockCallPermissions.videoAllowedForever,
            canToggleMediaType: false,
            isVideoCall: true,
            isMuted: false,
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
    
    func testCallActionsView_CanToggle_Video_Muted_CanAccept_NotTerminating_NotSendingVideo_SpeakerDisabled() {
        // Given
        let input = CallActionsViewInput(
            permissions: CallPermissions(),
            canToggleMediaType: true,
            isVideoCall: true,
            isMuted: true,
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
    
    func testCallActionsView_CanNotToggle_NotMuted_Video_CanNotAccept_VideoUnvailable_FlipCamera_SpeakerDisabled() {
        // Given
        let input = CallActionsViewInput(
            permissions: MockCallPermissions.videoAllowedForever,
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

    func testCallActionsView_CanToggle_NotMuted_Video_CanAccept_SendingVideo_FlipCamera_DarkTheme() {
        // Given
        let input = CallActionsViewInput(
            permissions: MockCallPermissions.videoAllowedForever,
            canToggleMediaType: true,
            isVideoCall: true,
            isMuted: false,
            canAccept: true,
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
    
    func testCallActionsView_NotMuted_CanNotAccept_CanToggleMedia_SendingVideo_FlipCamera() {
        // Given
        let input = CallActionsViewInput(
            permissions: MockCallPermissions.videoAllowedForever,
            canToggleMediaType: true,
            isVideoCall: true,
            isMuted: false,
            canAccept: false,
            isTerminating: false,
            mediaState: .sendingVideo,
            variant: .light,
            cameraType: .front
        )
        
        // When
        sut.update(with: input)
        
        // Then
        verify(view: sut)
    }
    
    func testCallActionsView_NotMuted_Audio_CanNotAccept_VideoNotSending_SpearkerEnabled() {
        // Given
        snapshotBackgroundColor = .white
        let input = CallActionsViewInput(
            permissions: MockCallPermissions.videoDeniedForever,
            canToggleMediaType: false,
            isVideoCall: false,
            isMuted: false,
            canAccept: false,
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
    
    func testCallActionsView_NotMuted_Audio_CanNotAccept_VideoNotSending_SpearkerDisabled() {
        // Given
        snapshotBackgroundColor = .white
        let input = CallActionsViewInput(
            permissions: CallPermissions(),
            canToggleMediaType: false,
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
    
    func testCallActionsView_Muted_Audio_CanNotAccept_CanToggle_VideoNotSending_SpearkerDisabled_DarkTheme() {
        // Given
        snapshotBackgroundColor = .black
        let input = CallActionsViewInput(
            permissions: CallPermissions(),
            canToggleMediaType: true,
            isVideoCall: false,
            isMuted: true,
            canAccept: false,
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
    
    func testCallActionsView_NotMuted_Audio_CanNotAccept_CanToggle_VideoNotSending_SpearkerEnabled_SpeakerUnvailable() {
        // Given
        snapshotBackgroundColor = .white
        let input = CallActionsViewInput(
            permissions: CallPermissions(),
            canToggleMediaType: true,
            isVideoCall: false,
            isMuted: false,
            canAccept: false,
            isTerminating: false,
            mediaState: .notSendingVideo(speakerState: .selectedCanNotBeToggled),
            variant: .light,
            cameraType: .front
        )
        
        // When
        sut.update(with: input)
        
        // Then
        verify(view: sut)
    }
    
    func testCallActionsView_NotMuted_CanNotAccept_VideoNotSending_SpearkerEnabled_Terminating() {
        // Given
        snapshotBackgroundColor = .white
        let input = CallActionsViewInput(
            permissions: MockCallPermissions.videoDeniedForever,
            canToggleMediaType: false,
            isVideoCall: false,
            isMuted: false,
            canAccept: false,
            isTerminating: true,
            mediaState: .notSendingVideo(speakerState: .selectedCanBeToggled),
            variant: .light,
            cameraType: .front
        )
        
        // When
        sut.update(with: input)
        
        // Then
        verify(view: sut)
    }
    
    func testCallActionsView_Muted_CanAccept_Audio_VideoNotSending_SpearkerDisabled() {
        // Given
        snapshotBackgroundColor = .white
        let input = CallActionsViewInput(
            permissions: CallPermissions(),
            canToggleMediaType: false,
            isVideoCall: false,
            isMuted: true,
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
    
    func testCallActionsView_NotMuted_CanNotAccept_VideoNotSending_SpearkerEnabled_Compact() {
        // Given
        snapshotBackgroundColor = .white
        let input = CallActionsViewInput(
            permissions: MockCallPermissions.videoPendingApproval,
            canToggleMediaType: true,
            isVideoCall: false,
            isMuted: false,
            canAccept: false,
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
    
    func testCallActionsView_Muted_CanAccept_VideoSending_FlipCamera_Compact() {
        // Given
        let input = CallActionsViewInput(
            permissions: CallPermissions(),
            canToggleMediaType: true,
            isVideoCall: true,
            isMuted: true,
            canAccept: true,
            isTerminating: false,
            mediaState: .notSendingVideo(speakerState: .deselectedCanBeToggled),
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
