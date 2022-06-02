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

import Foundation
import WireTesting
import XCTest
import WireRequestStrategy

class DependentObjectsTests: ZMTBaseTest {

    var coreDataStack: CoreDataStack!
    var sut: DependentObjects<ZMManagedObject, ZMConversation>!
    var conversation1: ZMConversation!
    var conversation2: ZMConversation!
    var messageA: ZMClientMessage!
    var messageB: ZMClientMessage!
    var messageC: ZMClientMessage!

    override func setUp() {
        super.setUp()
        self.sut = DependentObjects()
        self.coreDataStack = createCoreDataStack()
        self.conversation1 = ZMConversation.insertNewObject(in: coreDataStack.viewContext)
        self.conversation2 = ZMConversation.insertNewObject(in: coreDataStack.viewContext)
        self.messageA = ZMClientMessage(nonce: UUID(), managedObjectContext: coreDataStack.viewContext)
        self.messageB = ZMClientMessage(nonce: UUID(), managedObjectContext: coreDataStack.viewContext)
        self.messageC = ZMClientMessage(nonce: UUID(), managedObjectContext: coreDataStack.viewContext)
    }

    override func tearDown() {
        self.sut = nil
        self.coreDataStack = nil
        super.tearDown()
    }

    func testThatItEnumeratesAllObjectsInTheOrderTheyWereAdded() {
        // GIVEN
        let messages = [self.messageA, self.messageB, self.messageC].compactMap { $0 }
        messages.forEach {
            self.sut.add(dependency: self.conversation1!, for: $0)
        }

        // WHEN
        var result = [ZMClientMessage]()
        self.sut.enumerateAndRemoveObjects(for: self.conversation1!) { (mo) -> Bool in
            result.append(mo as! ZMClientMessage)
            return true
        }

        // THEN
        XCTAssertEqual(Set(messages), Set(result))
    }

    func testThatItOnlyReturnsAnObjectOnceWhenItIsAddedMultipleTimes() {
        // GIVEN
        let messages = [self.messageA!, self.messageA!, self.messageA!]
        messages.forEach {
            self.sut.add(dependency: self.conversation1!, for: $0)
        }

        // WHEN
        var result = [ZMClientMessage]()
        self.sut.enumerateAndRemoveObjects(for: self.conversation1!) { (mo) -> Bool in
            result.append(mo as! ZMClientMessage)
            return true
        }

        // THEN
        XCTAssertEqual(result, [self.messageA])
    }

    func testThatItEnumeratesAllObjectsAgainIfTheyWereNotToBeRemoved() {
        // GIVEN
        let messages = [self.messageA!, self.messageB!, self.messageC!]
        messages.forEach {
            self.sut.add(dependency: self.conversation1!, for: $0)
        }

        // WHEN
        self.sut.enumerateAndRemoveObjects(for: self.conversation1!) { _ in
            return false
        }

        // THEN
        var result = [ZMClientMessage]()
        self.sut.enumerateAndRemoveObjects(for: self.conversation1!) { (mo) -> Bool in
            result.append(mo as! ZMClientMessage)
            return true
        }
        XCTAssertEqual(Set(messages), Set(result))
    }

    func testThatItRemovesObjects() {

        // GIVEN
        let messages = [self.messageA!, self.messageB!, self.messageC!]
        messages.forEach {
            self.sut.add(dependency: self.conversation1!, for: $0)
        }

        // WHEN
        self.sut.enumerateAndRemoveObjects(for: self.conversation1!) {
            $0 == self.messageA!
        }

        // THEN
        var result = [ZMClientMessage]()
        self.sut.enumerateAndRemoveObjects(for: self.conversation1!) { (mo) -> Bool in
            result.append(mo as! ZMClientMessage)
            return true
        }
        XCTAssertEqual(Set([self.messageB!, self.messageC!]), Set(result))
    }

    func testThatItRemovesAllObjects() {
        // GIVEN
        self.sut.add(dependency: self.conversation1!, for: self.messageA!)
        self.sut.add(dependency: self.conversation2!, for: self.messageA!)

        // WHEN
        sut.removeAllDependencies(for: messageA)

        // THEN
        XCTAssertTrue(sut.dependencies(for: messageA).isEmpty)
    }

    func testThatItEnumeratesObjectsForTheCorrectDependency() {
        // GIVEN
        self.sut.add(dependency: self.conversation2!, for: self.messageA!)
        self.sut.add(dependency: self.conversation1!, for: self.messageB!)
        self.sut.add(dependency: self.conversation2!, for: self.messageC!)

        // WHEN
        var result1 = [ZMClientMessage]()
        self.sut.enumerateAndRemoveObjects(for: self.conversation1!) { (mo) -> Bool in
            result1.append(mo as! ZMClientMessage)
            return true
        }

        var result2 = [ZMClientMessage]()
        self.sut.enumerateAndRemoveObjects(for: self.conversation2!) { (mo) -> Bool in
            result2.append(mo as! ZMClientMessage)
            return true
        }
        // THEN
        XCTAssertEqual([self.messageB!], result1)
        XCTAssertEqual(Set([self.messageA!, self.messageC!]), Set(result2))

    }

    func testThatItReturnsAllDependenciesForAnObject() {
        // GIVEN
        self.sut.add(dependency: self.conversation2!, for: self.messageA!)
        self.sut.add(dependency: self.conversation1!, for: self.messageB!)
        self.sut.add(dependency: self.conversation2!, for: self.messageB!)

        // WHEN
        let dependenciesB = self.sut.dependencies(for: self.messageB!)
        let dependenciesA = self.sut.dependencies(for: self.messageA!)

        // THEN
        XCTAssertEqual(Set([self.conversation1!, self.conversation2!]), dependenciesB)
        XCTAssertEqual(Set([self.conversation2!]), dependenciesA)
    }

    func testThatItReturnsAllDependentsOnADependency() {
        // GIVEN
        self.sut.add(dependency: self.conversation2!, for: self.messageA!)
        self.sut.add(dependency: self.conversation1!, for: self.messageB!)
        self.sut.add(dependency: self.conversation2!, for: self.messageB!)

        // WHEN
        let dependents = self.sut.dependents(on: self.conversation1!)

        // THEN
        XCTAssertEqual(Set([self.messageB!]), dependents)
    }

    func testThatItDoesNotEnumerateWhenNoObjectsAreAdded() {
        self.sut.enumerateAndRemoveObjects(for: self.conversation1!) { (_) -> Bool in
            XCTFail("It enumerated when it shouldn't")
            return true
        }
    }

    func testThatItRemovesDependencies() {

        // GIVEN
        self.sut.add(dependency: self.conversation2!, for: self.messageA!)
        self.sut.add(dependency: self.conversation1!, for: self.messageB!)
        self.sut.add(dependency: self.conversation2!, for: self.messageB!)

        // WHEN
        self.sut.remove(dependency: self.conversation1!, for: self.messageB!)

        // THEN
        XCTAssertTrue(self.sut.dependents(on: self.conversation1!).isEmpty)
        XCTAssertEqual(self.sut.dependencies(for: self.messageB!), Set([self.conversation2!]))
    }

    func testThatItReturnsNoObjectForDepedency() {
        XCTAssertNil(self.sut.anyDependency(for: self.conversation1!))
    }

    func testThatItReturnsOneObjectForDependency() {

        // GIVEN
        self.sut.add(dependency: self.conversation2!, for: self.messageA!)
        self.sut.add(dependency: self.conversation1!, for: self.messageB)

        // WHEN
        let result = self.sut.anyDependency(for: self.messageB!)

        // THEN
        XCTAssertEqual(result, self.conversation1!)

    }
}
