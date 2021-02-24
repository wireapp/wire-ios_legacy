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

import Foundation
@testable import Wire

struct WritableKeyPathApplicator<Type>: Hashable {
    private let applicator: (Type, Any) -> Type
    let keyPath: AnyKeyPath
    init<ValueType>(_ keyPath: WritableKeyPath<Type, ValueType>) {
        self.keyPath = keyPath

        applicator = { instance, value in
            var variableInstance = instance
            guard let valueOfType = value as? ValueType else {
                fatal("Wrong type for \(instance): \(value)")
            }
            variableInstance[keyPath: keyPath] = valueOfType

            return variableInstance
        }
    }

    func apply(to object: Type, value: Any) -> Type {
        return applicator(object, value)
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(keyPath)
    }
}

func ==<T>(lhs: WritableKeyPathApplicator<T>, rhs: WritableKeyPathApplicator<T>) -> Bool {
    return lhs.keyPath == rhs.keyPath
}

extension Bool: CaseIterable {
    public static var allCases: [Bool] {
        return [true, false]
    }
}

class VariantsBuilder<Type: Copyable> {

    let initialValue: Type

    init(initialValue: Type) {
        self.initialValue = initialValue
    }

    func add<ValueType>(possibleValues values: [ValueType], for keyPath: WritableKeyPath<Type, ValueType>) {
        possibleValuesForKeyPath[WritableKeyPathApplicator(keyPath)] = values
    }

    func add<ValueType: CaseIterable>(keyPath: WritableKeyPath<Type, ValueType>) {
        possibleValuesForKeyPath[WritableKeyPathApplicator(keyPath)] = ValueType.allCases as? [Any]
    }

    var possibleValuesForKeyPath: [WritableKeyPathApplicator<Type>: [Any]] = [:]

    func allVariants() -> [Type] {
        var result = [initialValue]

        possibleValuesForKeyPath.forEach { (applicator, values) in
            let currentResults = result

            result = currentResults.flatMap { previousResult in
                return values.map { oneValue in
                    var new = previousResult.copyInstance()
                    new = applicator.apply(to: new, value: oneValue)
                    return new
                }
            }
        }

        return result
    }
}
