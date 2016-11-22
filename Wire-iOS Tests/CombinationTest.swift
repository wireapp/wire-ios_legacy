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

import Foundation
@testable import Wire

struct Mutator<T: Copyable, I: Hashable> {
    typealias Mutation = (T, I)->(T)
    typealias CombinationPair = (combination: I, result: T)
    let mutation: Mutation
    let combinations: Set<I>
    init(mutation: @escaping Mutation, combinations: Set<I>) {
        self.mutation = mutation
        self.combinations = combinations
    }
    
    func apply(_ element: T) -> [CombinationPair] {
        return combinations.map {
            (combination: $0, result: self.mutation(element, $0))
        }
    }
}

class CombinationTest<T: Copyable, I: Hashable> {
    typealias M = Mutator<T, I>
    typealias CombinationChainPair = (combinationChain: [I], result: T)
    let mutators: [M]
    let mutable: T
    init(mutable: T, mutators: [M]) {
        self.mutable = mutable
        self.mutators = mutators
    }
    
    func allCombinations() -> [CombinationChainPair] {
        var current: [CombinationChainPair] = [(combinationChain: [], result: mutable)]
        
        self.mutators.forEach { mutator in
            let new = current.map { variation -> [CombinationChainPair] in
                let step = mutator.apply(variation.result)
                return step.map {
                    let newChain: [I] = [variation.combinationChain, [$0.combination]].reduce([],+)
                    return (combinationChain: newChain, result: $0.result)
                }
            }
            
            current = new.flatMap { $0 }
        }
        
        return current
    }
    
    @discardableResult func testAll(_ test: (CombinationChainPair)->(Bool?)) -> [CombinationChainPair] {
        return self.allCombinations().flatMap {
            !(test($0) ?? true) ? $0 : .none
        }
    }
}

struct BoolPair { // Tuple would work better, but it cannot conform to @c Copyable
    var first: Bool
    var second: Bool
    
    init(first: Bool, second: Bool) {
        self.first = first
        self.second = second
    }
    
    func calculate() -> Bool {
        return self.first && self.second;
    }
}

extension BoolPair: Copyable {
    init(instance: BoolPair) {
        self.first = instance.first
        self.second = instance.second
    }
}

class CombinationTestTest: XCTestCase {
    func testBoolConjunctionCombination() {
        let boolCombinations = Set<Bool>(arrayLiteral: false, true)
        
        let firstMutation = { (proto: BoolPair, value: Bool) -> BoolPair in
            var new = proto.copy()
            new.first = value
            return new
        }
        let firstMutator = Mutator<BoolPair, Bool>(mutation: firstMutation, combinations: boolCombinations)
        
        let secondMutation = { (proto: BoolPair, value: Bool) -> BoolPair in
            var new = proto.copy()
            new.second = value
            return new
        }
        let secondMutator = Mutator<BoolPair, Bool>(mutation: secondMutation, combinations: boolCombinations)
        
        let test = CombinationTest(mutable: BoolPair(first: false, second: false), mutators: [firstMutator, secondMutator])
        
        XCTAssertEqual(test.testAll { (variation) -> (Bool?) in
            return variation.result.calculate() == variation.combinationChain.reduce(true) { $0 && $1 }
        }.count,  0)
    }
}
