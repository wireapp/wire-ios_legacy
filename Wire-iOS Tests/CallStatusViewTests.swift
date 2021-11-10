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

struct MockStatusViewConfiguration: CallStatusViewInputType {
    var state: CallStatusViewState
    var isVideoCall: Bool
    var variant: ColorSchemeVariant
    var isConstantBitRate: Bool
    let title: String
    let userEnabledCBR: Bool
    let isForcedCBR: Bool
}

final class CallStatusViewTests: ZMSnapshotTestCase {

    private var sut: CallStatusView!

    override func setUp() {
        super.setUp()
        snapshotBackgroundColor = .white
        sut = CallStatusView(configuration: MockStatusViewConfiguration(state: .connecting, isVideoCall: false, variant: .dark, isConstantBitRate: false, title: "Italy Trip", userEnabledCBR: false, isForcedCBR: false))
        sut.translatesAutoresizingMaskIntoConstraints = false
        sut.widthAnchor.constraint(equalToConstant: 320).isActive = true
        sut.setNeedsLayout()
        sut.layoutIfNeeded()
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    func testLongTitleMargins() {
        // When
        sut.configuration = MockStatusViewConfiguration(
            state: .connecting,
            isVideoCall: false,
            variant: .light,
            isConstantBitRate: false,
            title: "Amazing Way Too Long Group Conversation Name",
            userEnabledCBR: false,
            isForcedCBR: false
        )

        // Then
        verify(view: sut)
    }

    func testConnectingAudioCallLight() {
        // When
        sut.configuration = MockStatusViewConfiguration(state: .connecting, isVideoCall: false, variant: .light, isConstantBitRate: false, title: "Italy Trip", userEnabledCBR: false, isForcedCBR: false)

        // Then
        verify(view: sut)
    }

    func testConnectingAudioCallDark() {
        // When
        snapshotBackgroundColor = .black
        sut.configuration = MockStatusViewConfiguration(state: .connecting, isVideoCall: false, variant: .dark, isConstantBitRate: false, title: "Italy Trip", userEnabledCBR: false, isForcedCBR: false)

        // Then
        verify(view: sut)
    }

    func testIncomingAudioLight() {
        // When
        sut.configuration = MockStatusViewConfiguration(state: .ringingIncoming(name: "Ulrike"), isVideoCall: false, variant: .light, isConstantBitRate: false, title: "Italy Trip", userEnabledCBR: false, isForcedCBR: false)

        // Then
        verify(view: sut)
    }

    func testIncomingAudioLightOneOnOne() {
        // When
        sut.configuration = MockStatusViewConfiguration(state: .ringingIncoming(name: nil), isVideoCall: false, variant: .light, isConstantBitRate: false, title: "Miguel", userEnabledCBR: false, isForcedCBR: false)

        // Then
        verify(view: sut)
    }

    func testIncomingAudioDark() {
        // When
        snapshotBackgroundColor = .black
        sut.configuration = MockStatusViewConfiguration(state: .ringingIncoming(name: "Ulrike"), isVideoCall: false, variant: .dark, isConstantBitRate: false, title: "Italy Trip", userEnabledCBR: false, isForcedCBR: false)

        // Then
        verify(view: sut)
    }

    func testIncomingVideoLight() {
        // When
        snapshotBackgroundColor = .black
        sut.configuration = MockStatusViewConfiguration(state: .ringingIncoming(name: "Ulrike"), isVideoCall: true, variant: .light, isConstantBitRate: false, title: "Italy Trip", userEnabledCBR: false, isForcedCBR: false)

        // Then
        verify(view: sut)
    }

    func testIncomingVideoDark() {
        // When
        snapshotBackgroundColor = .black
        sut.configuration = MockStatusViewConfiguration(state: .ringingIncoming(name: "Ulrike"), isVideoCall: true, variant: .dark, isConstantBitRate: false, title: "Italy Trip", userEnabledCBR: false, isForcedCBR: false)

        // Then
        verify(view: sut)
    }

    func testOutgoingLight() {
        // When
        sut.configuration = MockStatusViewConfiguration(state: .ringingOutgoing, isVideoCall: false, variant: .light, isConstantBitRate: false, title: "Italy Trip", userEnabledCBR: false, isForcedCBR: false)

        // Then
        verify(view: sut)
    }

    func testOutgoingDark() {
        // When
        snapshotBackgroundColor = .black
        sut.configuration = MockStatusViewConfiguration(state: .ringingOutgoing, isVideoCall: true, variant: .dark, isConstantBitRate: false, title: "Italy Trip", userEnabledCBR: false, isForcedCBR: false)

        // Then
        verify(view: sut)
    }

    func testEstablishedBriefLight() {
        // When
        sut.configuration = MockStatusViewConfiguration(state: .established(duration: 42), isVideoCall: false, variant: .light, isConstantBitRate: false, title: "Italy Trip", userEnabledCBR: false, isForcedCBR: false)

        // Then
        verify(view: sut)
    }

    func testEstablishedBriefDark() {
        // When
        snapshotBackgroundColor = .black
        sut.configuration = MockStatusViewConfiguration(state: .established(duration: 42), isVideoCall: true, variant: .dark, isConstantBitRate: false, title: "Italy Trip", userEnabledCBR: false, isForcedCBR: false)

        // Then
        verify(view: sut)
    }

    func testEstablishedLongLight() {
        // When
        sut.configuration = MockStatusViewConfiguration(state: .established(duration: 321), isVideoCall: false, variant: .light, isConstantBitRate: false, title: "Italy Trip", userEnabledCBR: false, isForcedCBR: false)

        // Then
        verify(view: sut)
    }

    func testEstablishedLongDark() {
        // When
        snapshotBackgroundColor = .black
        sut.configuration = MockStatusViewConfiguration(state: .established(duration: 321), isVideoCall: true, variant: .dark, isConstantBitRate: false, title: "Italy Trip", userEnabledCBR: false, isForcedCBR: false)

        // Then
        verify(view: sut)
    }

    func testConstantBitRateLight() {
        // When
        sut.configuration = MockStatusViewConfiguration(state: .established(duration: 321), isVideoCall: false, variant: .light, isConstantBitRate: true, title: "Italy Trip", userEnabledCBR: true, isForcedCBR: false)

        // Then
        verify(view: sut)
    }

    func testConstantBitRateDark() {
        // When
        snapshotBackgroundColor = .black
        sut.configuration = MockStatusViewConfiguration(state: .established(duration: 321), isVideoCall: true, variant: .dark, isConstantBitRate: true, title: "Italy Trip", userEnabledCBR: true, isForcedCBR: false)

        // Then
        verify(view: sut)
    }

    func testVariableBitRateLight() {
        // When
        sut.configuration = MockStatusViewConfiguration(state: .established(duration: 321), isVideoCall: false, variant: .light, isConstantBitRate: false, title: "Italy Trip", userEnabledCBR: true, isForcedCBR: false)

        // Then
        verify(view: sut)
    }

    func testVariableBitRateDark() {
        // When
        snapshotBackgroundColor = .black
        sut.configuration = MockStatusViewConfiguration(state: .established(duration: 321), isVideoCall: true, variant: .dark, isConstantBitRate: false, title: "Italy Trip", userEnabledCBR: true, isForcedCBR: false)

        // Then
        verify(view: sut)
    }

    func testReconnectingLight() {
        // When
        sut.configuration = MockStatusViewConfiguration(state: .reconnecting, isVideoCall: false, variant: .light, isConstantBitRate: false, title: "Italy Trip", userEnabledCBR: false, isForcedCBR: false)

        // Then
        verify(view: sut)
    }

    func testReconnectingDark() {
        // When
        snapshotBackgroundColor = .black
        sut.configuration = MockStatusViewConfiguration(state: .reconnecting, isVideoCall: true, variant: .dark, isConstantBitRate: false, title: "Italy Trip", userEnabledCBR: false, isForcedCBR: false)

        // Then
        verify(view: sut)
    }

    func testEndingLight() {
        // When
        sut.configuration = MockStatusViewConfiguration(state: .terminating, isVideoCall: false, variant: .light, isConstantBitRate: false, title: "Italy Trip", userEnabledCBR: false, isForcedCBR: false)

        // Then
        verify(view: sut)
    }

    func testEndingDark() {
        // When
        snapshotBackgroundColor = .black
        sut.configuration = MockStatusViewConfiguration(state: .terminating, isVideoCall: true, variant: .dark, isConstantBitRate: false, title: "Italy Trip", userEnabledCBR: false, isForcedCBR: false)

        // Then
        verify(view: sut)
    }

}
