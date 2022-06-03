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
@testable import WireUtilities

private struct Person {
    let name: String
    let age: Int?
}

private struct SocialPerson {
    let name: String
    let friends: [String]
}

private struct Office: Equatable {
    let id: Int
    let isInBerlin: Bool
}

class MapKeyPathTests: XCTestCase {

    // MARK: - Optional

    func testOptionalMap() {
        // GIVEN
        let personWithAge: Person? = Person(name: "Human", age: 20)
        let personWithoutAge: Person? = Person(name: "Bot", age: nil)
        let ghost: Person? = nil

        // WHEN
        let humanName = personWithAge.map(\.name)
        let humanAge = personWithAge.map(\.age)

        let botName = personWithoutAge.map(\.name)
        let botAge = personWithoutAge.map(\.age)

        let ghostName = ghost.map(\.name)
        let ghostAge = ghost.map(\.age)

        // THEN
        XCTAssertEqual(humanName, Optional<String>.some("Human"))
        XCTAssertEqual(humanAge, Optional<Optional<Int>>.some(.some(20)))

        XCTAssertEqual(botName, Optional<String>.some("Bot"))
        XCTAssertEqual(botAge, Optional<Optional<Int>>.some(.none))

        XCTAssertEqual(ghostName, Optional<String>.none)
        XCTAssertEqual(ghostAge, Optional<Optional<Int>>.none)
    }

    func testOptionalFlatMap() {
        // GIVEN
        let personWithAge: Person? = Person(name: "Human", age: 20)
        let personWithoutAge: Person? = Person(name: "Bot", age: nil)
        let ghost: Person? = nil

        // WHEN
        let humanAge = personWithAge.flatMap(\.age)
        let botAge = personWithoutAge.flatMap(\.age)
        let ghostAge = ghost.flatMap(\.age)

        // THEN
        XCTAssertEqual(humanAge, Optional<Int>.some(20))
        XCTAssertEqual(botAge, Optional<Int>.none)
        XCTAssertEqual(ghostAge, Optional<Int>.none)
    }

    // MARK: - Sequence

    func testSequenceKeyPath() {
        // GIVEN
        let personWithAge: Person = Person(name: "Human", age: 20)
        let personWithoutAge: Person = Person(name: "Bot", age: nil)

        let alice = SocialPerson(name: "Alice", friends: ["@bob"])
        let bob = SocialPerson(name: "Bob", friends: ["@alice"])

        let people = [personWithAge, personWithoutAge]
        let socialPeople = [alice, bob]

        // WHEN
        let names = people.map(\.name)
        let ages = people.compactMap(\.age)

        let socialMediaMembers = socialPeople.flatMap(\.friends)

        // THEN
        XCTAssertEqual(names, ["Human", "Bot"])
        XCTAssertEqual(ages, [20])

        XCTAssertEqual(socialMediaMembers, ["@bob", "@alice"])
    }

    func testFilter() {
        // GIVEN
        let wire = Office(id: 0, isInBerlin: true)
        let microsoft = Office(id: 1, isInBerlin: true)
        let apple = Office(id: 2, isInBerlin: false)

        let workplaces = [wire, microsoft, apple]

        // WHEN
        let berlinOffices = workplaces.filter(\.isInBerlin)
        let containsAtLeastOneBerlinOffice = workplaces.any(\.isInBerlin)
        let containsOnlyBerlinOffices = workplaces.all(\.isInBerlin)

        // THEN
        XCTAssertEqual(berlinOffices, [wire, microsoft])
        XCTAssertTrue(containsAtLeastOneBerlinOffice)
        XCTAssertFalse(containsOnlyBerlinOffices)
    }

}
