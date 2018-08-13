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

struct EmptySearchResultsViewTestState: Copyable {
    init(instance: EmptySearchResultsViewTestState) {
        self.colorSchemeVariant = instance.colorSchemeVariant
        self.isSelfUserAdmin = instance.isSelfUserAdmin
        self.searchingForServices = instance.searchingForServices
        self.hasFilter = instance.hasFilter
    }
    
    init(colorSchemeVariant: ColorSchemeVariant, isSelfUserAdmin: Bool, searchingForServices: Bool, hasFilter: Bool) {
        self.colorSchemeVariant = colorSchemeVariant
        self.isSelfUserAdmin = isSelfUserAdmin
        self.searchingForServices = searchingForServices
        self.hasFilter = hasFilter
    }
    
    var colorSchemeVariant: ColorSchemeVariant
    var isSelfUserAdmin: Bool
    var searchingForServices: Bool
    var hasFilter: Bool
    
    func createView() -> EmptySearchResultsView {
        let view = EmptySearchResultsView(variant: colorSchemeVariant, isSelfUserAdmin: isSelfUserAdmin)
        view.updateStatus(searchingForServices: searchingForServices, hasFilter: hasFilter)
        return view
    }
}

extension ColorSchemeVariant: CustomStringConvertible {
    public var description: String {
        switch self {
        case .dark:
            return "ColorSchemeVariant.dark"
        case .light:
            return "ColorSchemeVariant.light"
        }
    }
}

extension EmptySearchResultsViewTestState: CustomStringConvertible {
    var description: String {
        return "colorSchemeVariant: \(colorSchemeVariant) isSelfUserAdmin: \(isSelfUserAdmin) searchingForServices: \(searchingForServices) hasFilter: \(hasFilter)"
    }
}


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
    
    var hashValue: Int {
        return keyPath.hashValue
    }
}

func ==<T>(lhs: WritableKeyPathApplicator<T>, rhs: WritableKeyPathApplicator<T>) -> Bool {
    return lhs.keyPath == rhs.keyPath
}

class VariantsBuilder<Type: Copyable> {
    
    let initialValue: Type

    init(initialValue: Type) {
        self.initialValue = initialValue
    }
    
    func add<ValueType>(possibleValues values: [ValueType], for keyPath: WritableKeyPath<Type, ValueType>) {
        possibleValuesForKeyPath[WritableKeyPathApplicator(keyPath)] = values
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

final class EmptySearchResultsViewTests: ZMSnapshotTestCase {
    
    func testStates() {
        let initialState = EmptySearchResultsViewTestState(colorSchemeVariant: .light,
                                                           isSelfUserAdmin: false,
                                                           searchingForServices: false,
                                                           hasFilter: false)
        
        let builder = VariantsBuilder(initialValue: initialState)
        
        builder.add(possibleValues: [ColorSchemeVariant.light, ColorSchemeVariant.dark], for: \EmptySearchResultsViewTestState.colorSchemeVariant)
        builder.add(possibleValues: [true, false], for: \EmptySearchResultsViewTestState.isSelfUserAdmin)
        builder.add(possibleValues: [true, false], for: \EmptySearchResultsViewTestState.searchingForServices)
        builder.add(possibleValues: [true, false], for: \EmptySearchResultsViewTestState.hasFilter)
        
        
        builder.allVariants().forEach { version in
            let sut = version.createView()
            
            sut.prepareForSnapshot()
            
            sut.bounds.size = sut.systemLayoutSizeFitting(
                CGSize(width: 375, height: 600),
                withHorizontalFittingPriority: .required,
                verticalFittingPriority: .fittingSizeLevel
            )
            
            verify(view: sut, identifier: version.description, tolerance: 0)
        }
    }
}
