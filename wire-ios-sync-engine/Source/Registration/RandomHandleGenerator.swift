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

private let maximumUserHandleLength = 21

private let minimumUserHandleLength = 2

struct RandomHandleGenerator {

    /// Generate somes possible handles for the given display name
    static func generatePossibleHandles(displayName: String, alternativeNames: Int) -> [String] {

        let normalized = displayName.normalizedForUserHandle.validHandle // this might be nil. if it is, we generate an extra one
        let alternativeNames = randomWordsCombinations(count: normalized == nil ? alternativeNames + 1 : alternativeNames)

        var possibleHandles = [String]()

        if let normalized = normalized {
            possibleHandles.append(normalized)
            possibleHandles.append(contentsOf: normalized.truncated(at: maximumUserHandleLength-1).appendAllDigits())
            possibleHandles.append(contentsOf: normalized.truncated(at: maximumUserHandleLength-2).appendRandomDigits(numberOfDigits: 2, variations: 4))
            possibleHandles.append(contentsOf: normalized.truncated(at: maximumUserHandleLength-3).appendRandomDigits(numberOfDigits: 3, variations: 4))
            possibleHandles.append(contentsOf: normalized.truncated(at: maximumUserHandleLength-4).appendRandomDigits(numberOfDigits: 4, variations: 6))
        }

        possibleHandles.append(contentsOf: alternativeNames)
        possibleHandles.append(contentsOf: alternativeNames.map { $0.truncated(at: maximumUserHandleLength-2).appendRandomDigits(numberOfDigits: 2, variations: 2) }.flatMap { $0 })
        possibleHandles.append(contentsOf: alternativeNames.map { $0.truncated(at: maximumUserHandleLength-3).appendRandomDigits(numberOfDigits: 3, variations: 2) }.flatMap { $0 })
        possibleHandles.append(contentsOf: alternativeNames.map { $0.truncated(at: maximumUserHandleLength-4).appendRandomDigits(numberOfDigits: 4, variations: 2) }.flatMap { $0 })

        return possibleHandles
    }
}

// MARK: - Random generation
extension RandomHandleGenerator {

    /// Generates some random combinations of words
    fileprivate static func randomWordsCombinations(count: Int) -> [String] {
        let list1 = self.loadWords(file: "random1", ext: "txt")
        let list2 = self.loadWords(file: "random2", ext: "txt")

        guard (list1.count * list2.count) > count*20 else {
            fatal("Won't generate that many random words \(count) with this little dictionary \(list1.count * list2.count)")
        }

        var generated = Set<String>()
        while (generated.count) < count {
            generated.insert(list1.random!+list2.random!)
        }

        return Array(generated)
    }
}

extension String {

    /// Returns an array with self with digits from 1 to 9 appended
    func appendAllDigits() -> [String] {
        return (1..<10).map { self + "\($0)" }
    }

    /// Return an array with self with random digits appended
    fileprivate func appendRandomDigits(numberOfDigits: Int, variations: Int) -> [String] {
        return (0..<variations).map { _ in
            return self + String.random(numberOfDigits: numberOfDigits)
        }
    }

    /// Returns a string composed of random digits
    fileprivate static func random(numberOfDigits: Int) -> String {
        return (0..<numberOfDigits).map { _ in "\(arc4random_uniform(10))" }
        .joined(separator: "")
    }
}

// MARK: - Helpers
extension RandomHandleGenerator {

    /// Load a list of words from a file
    fileprivate static func loadWords(file: String, ext: String) -> [String] {
        let bundle = Bundle(for: ZMUserSession.self)
        let resourceName = file + (ext != "" ? "." : "") + ext
        guard let url = bundle.url(forResource: file, withExtension: ext) else {
            fatal("Can't find resource \(resourceName)")
        }
        do {
            return try String(contentsOf: url)
                .components(separatedBy: "\n")
                .map { $0.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines) }
        } catch {
            fatal("Can't load random data from \(resourceName) : \(error)")
        }
    }
}

extension Array {

    /// Pick a random element from the array
    fileprivate var random: Element? {
        guard self.count > 1 else {
            return self.first
        }

        let index = Int(arc4random_uniform(UInt32(self.count)))
        return self[index]
    }
}

// MARK: - String normalization
extension String {

    /// Normalized user handle form
    public var normalizedForUserHandle: String {
        return self.translitteratedToLatin
            .spacesAndPuctationToUnderscore
            .onlyAlphanumericWithUnderscore
            .lowercased()
            .trimmingCharacters(in: CharacterSet(charactersIn: ""))
            .truncated(at: maximumUserHandleLength)
    }

    /// Removes punctation and spaces from self and collapses them into a single "_"
    fileprivate var spacesAndPuctationToUnderscore: String {
        let charactersToRemove = CharacterSet.punctuationCharacters
            .union(CharacterSet.whitespacesAndNewlines)
            .union(CharacterSet.controlCharacters)

        return self.components(separatedBy: charactersToRemove)
            .joined(separator: "")
    }

    /// Returns self transliterated to latin base
    fileprivate var translitteratedToLatin: String {
        let mutableString = NSMutableString(string: self) as CFMutableString
        for transform in [kCFStringTransformToLatin, kCFStringTransformStripDiacritics, kCFStringTransformStripCombiningMarks] {
            CFStringTransform(mutableString, nil, transform, false)
        }
        return String(mutableString)
    }

    /// returns self only with alphanumeric and underscore
    fileprivate var onlyAlphanumericWithUnderscore: String {
        let allowedCharacters = CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890_")
        return self.components(separatedBy: allowedCharacters.inverted).joined(separator: "")
    }

    /// Returns a truncated version of the string
    func truncated(at position: Int) -> String {
        return String(self[..<index(startIndex, offsetBy: min(position, count))])
    }

    /// Returns the string if its a valid handle, or nil
    fileprivate var validHandle: String? {
        let normalized = self.normalizedForUserHandle
        guard normalized.count >= minimumUserHandleLength else {
            return nil
        }
        return normalized
    }
}
