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

final class CallStatusViewTests: ZMSnapshotTestCase {
    
    private var sut: CallStatusView!

    override func setUp() {
        super.setUp()
        recordMode = true
        snapshotBackgroundColor = .white
        sut = CallStatusView(configuration: .init(state: .connecting, type: .audio, variant: .dark, isConstantBitRate: false, title: "Italy Trip"))
        sut.translatesAutoresizingMaskIntoConstraints = false
        sut.widthAnchor.constraint(equalToConstant: 320).isActive = true
        sut.setNeedsLayout()
        sut.layoutIfNeeded()
    }
    
    override func tearDown() {
        sut = nil
        super.tearDown()
    }
    
    func testConnectingAudioCallLight() {
        // When
        sut.configuration = .init(state: .connecting, type: .audio, variant: .light, isConstantBitRate: false, title: "Italy Trip")
        
        // Then
        verify(view: sut)
    }
    
    func testConnectingAudioCallDark() {
        // When
        snapshotBackgroundColor = .black
        sut.configuration = .init(state: .connecting, type: .audio, variant: .dark, isConstantBitRate: false, title: "Italy Trip")
        
        // Then
        verify(view: sut)
    }
    
    func testIncomingAudioLight() {
        // When
        sut.configuration = .init(state: .ringingIncoming(name: "Ulrike"), type: .audio, variant: .light, isConstantBitRate: false, title: "Italy Trip")
        
        // Then
        verify(view: sut)
    }
    
    func testIncomingAudioDark() {
        // When
        snapshotBackgroundColor = .black
        sut.configuration = .init(state: .ringingIncoming(name: "Ulrike"), type: .audio, variant: .dark, isConstantBitRate: false, title: "Italy Trip")
        
        // Then
        verify(view: sut)
    }
    
    func testIncomingVideoLight() {
        // When
        snapshotBackgroundColor = .black
        sut.configuration = .init(state: .ringingIncoming(name: "Ulrike"), type: .video, variant: .light, isConstantBitRate: false, title: "Italy Trip")
        
        // Then
        verify(view: sut)
    }
    
    func testIncomingVideoDark() {
        // When
        snapshotBackgroundColor = .black
        sut.configuration = .init(state: .ringingIncoming(name: "Ulrike"), type: .video, variant: .dark, isConstantBitRate: false, title: "Italy Trip")
        
        // Then
        verify(view: sut)
    }
    
    func testOutgoingLight() {
        // When
        sut.configuration = .init(state: .ringingOutgoing, type: .audio, variant: .light, isConstantBitRate: false, title: "Italy Trip")
        
        // Then
        verify(view: sut)
    }
    
    func testOutgoingDark() {
        // When
        snapshotBackgroundColor = .black
        sut.configuration = .init(state: .ringingOutgoing, type: .video, variant: .dark, isConstantBitRate: false, title: "Italy Trip")
        
        // Then
        verify(view: sut)
    }
    
    func testEstablishedBriefLight() {
        // When
        sut.configuration = .init(state: .established(duration: 42), type: .audio, variant: .light, isConstantBitRate: false, title: "Italy Trip")
        
        // Then
        verify(view: sut)
    }
    
    func testEstablishedBriefDark() {
        // When
        snapshotBackgroundColor = .black
        sut.configuration = .init(state: .established(duration: 42), type: .video, variant: .dark, isConstantBitRate: false, title: "Italy Trip")
        
        // Then
        verify(view: sut)
    }
    
    func testEstablishedLongLight() {
        // When
        sut.configuration = .init(state: .established(duration: 321), type: .audio, variant: .light, isConstantBitRate: false, title: "Italy Trip")
        
        // Then
        verify(view: sut)
    }
    
    func testEstablishedLongDark() {
        // When
        snapshotBackgroundColor = .black
        sut.configuration = .init(state: .established(duration: 321), type: .video, variant: .dark, isConstantBitRate: false, title: "Italy Trip")
        
        // Then
        verify(view: sut)
    }
    
    func testConstantBitRateLight() {
        // When
        sut.configuration = .init(state: .established(duration: 321), type: .audio, variant: .light, isConstantBitRate: true, title: "Italy Trip")
        
        // Then
        verify(view: sut)
    }
    
    func testConstantBitRateDark() {
        // When
        snapshotBackgroundColor = .black
        sut.configuration = .init(state: .established(duration: 321), type: .video, variant: .dark, isConstantBitRate: true, title: "Italy Trip")
        
        // Then
        verify(view: sut)
    }
    
    func testReconnectingLight() {
        // When
        sut.configuration = .init(state: .reconnecting, type: .audio, variant: .light, isConstantBitRate: false, title: "Italy Trip")
        
        // Then
        verify(view: sut)
    }
    
    func testReconnectingDark() {
        // When
        snapshotBackgroundColor = .black
        sut.configuration = .init(state: .reconnecting, type: .video, variant: .dark, isConstantBitRate: false, title: "Italy Trip")
        
        // Then
        verify(view: sut)
    }
    
    func testEndingLight() {
        // When
        sut.configuration = .init(state: .terminating, type: .audio, variant: .light, isConstantBitRate: false, title: "Italy Trip")
        
        // Then
        verify(view: sut)
    }
    
    func testEndingDark() {
        // When
        snapshotBackgroundColor = .black
        sut.configuration = .init(state: .terminating, type: .video, variant: .dark, isConstantBitRate: false, title: "Italy Trip")
        
        // Then
        verify(view: sut)
    }

}
