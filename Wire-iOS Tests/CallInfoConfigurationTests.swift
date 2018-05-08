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

func ==(lhs: CallInfoViewControllerInput, rhs: CallInfoViewControllerInput) -> Bool {
    return lhs.accessoryType == rhs.accessoryType &&
        lhs.appearance == rhs.appearance &&
        lhs.canAccept == rhs.canAccept &&
        lhs.canToggleMediaType == rhs.canToggleMediaType &&
        lhs.displayString == rhs.displayString &&
        lhs.isConstantBitRate == rhs.isConstantBitRate &&
        lhs.state == rhs.state &&
        lhs.mediaState == rhs.mediaState
}

class CallInfoConfigurationTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func assertEquals(_ lhsConfig: CallInfoViewControllerInput, _ rhsConfig: CallInfoViewControllerInput, file: StaticString = #file, line: UInt = #line) {
        XCTAssertTrue(lhsConfig == rhsConfig, "\n\(lhsConfig)\n\nis not equal to\n\n\(rhsConfig)", file: file, line: line)
    }
    
    func testOneToOneIncomingAudioConnecting() {
        // given
        let mockConversation = ((MockConversation.oneOnOneConversation() as Any) as! ZMConversation)
        let mockVoiceChannel = TestableVoiceChannel(conversation: mockConversation)
        let fixture = CallInfoTestFixture(otherUser: mockConversation.connectedUser!)
        
        mockVoiceChannel.mockCallState = .answered(degraded: false)
        mockVoiceChannel.mockInitiator = mockConversation.connectedUser
        
        // when
        let configuration = CallInfoConfiguration(voiceChannel: mockVoiceChannel)
        
        // then
        assertEquals(fixture.oneToOneIncomingAudioConnecting, configuration)
    }
    
    func testOneToOneIncomingAudioEstablished() {
        // given
        let mockConversation = ((MockConversation.oneOnOneConversation() as Any) as! ZMConversation)
        let mockVoiceChannel = TestableVoiceChannel(conversation: mockConversation)
        let fixture = CallInfoTestFixture(otherUser: mockConversation.connectedUser!)
        
        mockVoiceChannel.mockCallState = .established
        mockVoiceChannel.mockInitiator = mockConversation.connectedUser
        mockVoiceChannel.mockCallDuration = 10
        
        // when
        let configuration = CallInfoConfiguration(voiceChannel: mockVoiceChannel)
        
        // then
        assertEquals(fixture.oneToOneIncomingAudioEstablished, configuration)
    }
    
    func testOneToOneIncomingAudioEstablishedCBR() {
        // given
        let mockConversation = ((MockConversation.oneOnOneConversation() as Any) as! ZMConversation)
        let mockVoiceChannel = TestableVoiceChannel(conversation: mockConversation)
        let fixture = CallInfoTestFixture(otherUser: mockConversation.connectedUser!)
        
        mockVoiceChannel.mockCallState = .established
        mockVoiceChannel.mockInitiator = mockConversation.connectedUser
        mockVoiceChannel.mockCallDuration = 10
        mockVoiceChannel.mockIsConstantBitRateAudioActive = true
        
        // when
        let configuration = CallInfoConfiguration(voiceChannel: mockVoiceChannel)
        
        // then
        assertEquals(fixture.oneToOneIncomingAudioEstablishedCBR, configuration)
    }
    
    func testGroupOutgoingAudioRinging() {
        // given
        let selfUser = (MockUser.mockSelf() as Any) as? ZMUser
        let otherUser = MockUser.mockUsers().first!
        let mockConversation = ((MockConversation.groupConversation() as Any) as! ZMConversation)
        let mockVoiceChannel = TestableVoiceChannel(conversation: mockConversation)
        let fixture = CallInfoTestFixture(otherUser: otherUser)
        
        mockVoiceChannel.mockCallState = .outgoing(degraded: false)
        mockVoiceChannel.mockInitiator = selfUser
        
        // when
        let configuration = CallInfoConfiguration(voiceChannel: mockVoiceChannel)
        
        // then
        assertEquals(fixture.groupOutgoingAudioRinging, configuration)
    }
    
    func testGroupOutgoingAudioConnecting() {
        // given
        let selfUser = (MockUser.mockSelf() as Any) as? ZMUser
        let otherUser = MockUser.mockUsers().first!
        let mockConversation = ((MockConversation.groupConversation() as Any) as! ZMConversation)
        let mockVoiceChannel = TestableVoiceChannel(conversation: mockConversation)
        let fixture = CallInfoTestFixture(otherUser: otherUser)
        
        mockVoiceChannel.mockCallState = .answered(degraded: false)
        mockVoiceChannel.mockInitiator = selfUser
        
        // when
        let configuration = CallInfoConfiguration(voiceChannel: mockVoiceChannel)
        
        // then
        assertEquals(fixture.groupOutgoingAudioConnecting, configuration)
    }
    
    func testGroupOutgoingAudioEstablished() {
        // given
        let selfUser = (MockUser.mockSelf() as Any) as? ZMUser
        let otherUser = MockUser.mockUsers().first!
        let mockConversation = ((MockConversation.groupConversation() as Any) as! ZMConversation)
        let mockVoiceChannel = TestableVoiceChannel(conversation: mockConversation)
        let mockUsers: [ZMUser] = MockUser.mockUsers()!
        let fixture = CallInfoTestFixture(otherUser: otherUser)
        
        mockVoiceChannel.mockCallState = .established
        mockVoiceChannel.mockCallDuration = 10
        mockVoiceChannel.mockInitiator = selfUser
        mockVoiceChannel.mockParticipants = NSOrderedSet(array: Array(mockUsers[0..<fixture.groupSize.rawValue]))
        mockVoiceChannel.mockCallParticipantState = .connected(videoState: .stopped)
        
        // when
        let configuration = CallInfoConfiguration(voiceChannel: mockVoiceChannel)
        
        // then
        assertEquals(fixture.groupOutgoingAudioEstablished, configuration)
    }

}

