//
// Wire
// Copyright (C) 2017 Wire Swiss GmbH
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
import Classy
import Cartography
import WireLinkPreview
@testable import Wire

class ShareViewControllerTests: CoreDataSnapshotTestCase {
    
    var groupConversation: ZMConversation!
    
    override func setUp() {
        super.setUp()
        self.groupConversation = self.createGroupConversation()
    }
    
    override var needsCaches: Bool {
        return true
    }
    
    func testThatItRendersCorrectlyShareViewController_OneLineTextMessage() {
        groupConversation.appendMessage(withText: "This is a text message.")
        makeTestForShareViewController()
    }
    
    func testThatItRendersCorrectlyShareViewController_MultiLineTextMessage() {
        groupConversation.appendMessage(withText: "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Fusce tempor nulla nec justo tincidunt iaculis. Suspendisse et viverra lacus. Orci varius natoque penatibus et magnis dis parturient montes, nascetur ridiculus mus. Aliquam pretium suscipit purus, sed eleifend erat ullamcorper non. Sed non enim diam. Fusce pulvinar turpis sit amet pretium finibus. Donec ipsum massa, aliquam eget sollicitudin vel, fringilla eget arcu. Donec faucibus porttitor nisi ut fermentum. Donec sit amet massa sodales, facilisis neque et, condimentum leo. Maecenas quis vulputate libero, id suscipit magna.")
        makeTestForShareViewController()
    }
    
    func testThatItRendersCorrectlyShareViewController_LocationMessage() {
        let location = LocationData.locationData(withLatitude: 43.94, longitude: 12.46, name: "Stranger Place", zoomLevel: 5)
        groupConversation.appendMessage(with: location)
        makeTestForShareViewController()
    }
    
    func testThatItRendersCorrectlyShareViewController_Photos() {
        let img = image(inTestBundleNamed: "unsplash_matterhorn.jpg")
        self.groupConversation.appendMessage(withImageData: img.data()!)
        
        groupConversation.addParticipant(self.createUser(name: "John Appleseed"))
        let oneToOneConversation = self.createGroupConversation()
        
        guard let message = groupConversation.messages.firstObject as? ZMMessage else {
            XCTFail("Cannot add test message to the group conversation")
            return
        }
        
        if let preview = message.previewView() as? ImageMessageCell {
            _ = preview.prepareForSnapshot(img.size, image: img)
        }
        
        let sut = ShareViewController<ZMConversation, ZMMessage>(
            shareable: message,
            destinations: [groupConversation, oneToOneConversation],
            showPreview: true
        )
        
        self.verifyInAllDeviceSizes(view: sut.view)
    }
    
    func makeTestForShareViewController() {
        
        groupConversation.addParticipant(self.createUser(name: "John Appleseed"))
        
        let oneToOneConversation = self.createGroupConversation()
        
        guard let message = groupConversation.messages.firstObject as? ZMMessage else {
            XCTFail("Cannot add test message to the group conversation")
            return
        }
    
        let sut = ShareViewController<ZMConversation, ZMMessage>(
            shareable: message,
            destinations: [groupConversation, oneToOneConversation],
            showPreview: true
        )
        
        self.verifyInAllDeviceSizes(view: sut.view)
    }
    
    /// BOTS INTEGRATION
    
    func testThatItRendersCorrectlyShareServiceViewController_Selection() {
        
        let serviceUser = createService(name: "Wire Mountain Bot")
        
        let serviceToAdd = Service(serviceUser: serviceUser)
        groupConversation.addParticipant(self.createUser(name: "John Appleseed"))
        groupConversation.addParticipant(self.createUser(name: "Frank Smith"))
        XCTAssert(groupConversation.activeParticipants.count == 4)
        
        let otherServiceUser = createService(name: "WireBurger Bot")
        
        let serviceConversation = ZMConversation.insertNewObject(in: uiMOC)
        serviceConversation.remoteIdentifier = UUID()
        serviceConversation.conversationType = .group
        serviceConversation.internalAddParticipants([selfUser, otherServiceUser], isAuthoritative: true)
        
        let allConversations: [ServiceConversation] = [.new, .existing(groupConversation), .existing(serviceConversation)]
        
        let sut = ShareServiceViewController(shareable: serviceToAdd, destinations: allConversations, showPreview: true, allowsMultipleSelection: false)
        
        verifyInAllDeviceSizes(view: sut.view)
    }
    
    private func createService(name: String) -> ZMUser {
        let bot = createUser(name: name)
        bot.serviceIdentifier = "serviceIdentifier"
        bot.providerIdentifier = "providerIdentifier"
        XCTAssert(bot.isServiceUser)
        return bot
    }

}
