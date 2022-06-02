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

@objc(ZMVersion) final public class Version: NSObject, Comparable {

    @objc public private(set) var versionString: String
    @objc public private(set) var arrayRepresentation: [Int]

    @objc(initWithVersionString:)
    public init(string: String) {
        requireInternal(!string.isEmpty, "invalid version string")
        versionString = string
        arrayRepresentation = Version.integerComponents(of: string)
        super.init()
    }

    private static func integerComponents(of string: String) -> [Int] {
        return string.components(separatedBy: ".").map {
            ($0 as NSString).integerValue
        }
    }

    @objc(compareWithVersion:)
    public func compare(with other: Version) -> ComparisonResult {
        guard other.arrayRepresentation.count > 0 else { return .orderedDescending }
        guard versionString != other.versionString else { return .orderedSame }

        for i in 0..<arrayRepresentation.count {
            guard other.arrayRepresentation.count != i else { return .orderedDescending }
            let selfNumber = arrayRepresentation[i]
            let otherNumber = other.arrayRepresentation[i]

            if selfNumber > otherNumber {
                return .orderedDescending
            } else if selfNumber < otherNumber {
                return .orderedAscending
            }
        }

        if arrayRepresentation.count < other.arrayRepresentation.count {
            return .orderedAscending
        }

        return .orderedSame
    }

    public override func isEqual(_ object: Any?) -> Bool {
        guard let other = object as? Version else { return false }
        return other == self
    }

    public override var description: String {
        return arrayRepresentation.map { "\($0)" }.joined(separator: ".")
    }

    public override var debugDescription: String {
        return String(format: "<%@ %p> %@", NSStringFromClass(type(of: self)), self, description)
    }

}

// MARK: - Operators

public func == (lhs: Version, rhs: Version) -> Bool {
    return lhs.compare(with: rhs) == .orderedSame
}

public func < (lhs: Version, rhs: Version) -> Bool {
    return lhs.compare(with: rhs) == .orderedAscending
}
