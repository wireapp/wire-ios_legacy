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

@objcMembers public class PersonName: NSObject {

    public override func isEqual(_ object: Any?) -> Bool {
        guard let other = object as? PersonName else { return false }
        return self.components == other.components
    }

    enum NameOrder {
        case givenNameFirst, givenNameLast, arabicGivenName
    }

    let components: [String]
    let fullName: String
    let rawFullName: String
    let nameOrder: NameOrder
    static let stringsToPersonNames = NSCache<NSString, PersonName>()

    lazy var secondNameComponents: [String] = {
        guard self.components.count < 2  else { return [] }

        var startIndex = 0
        var lastIndex = 0

        switch self.nameOrder {
        case .givenNameLast:
            lastIndex = self.components.count - 2
        case .givenNameFirst:
            startIndex = 1
            lastIndex = self.components.count - 1
        case .arabicGivenName:
            startIndex = 1
            lastIndex = self.components.count - 1
            guard self.components.count > 1 && self.components[1].zmIsGodName() else { break }
            guard self.components.count > 2 else { return [] }
            startIndex += 1
        }
        return Array(self.components[startIndex...lastIndex])
    }()

    lazy var givenName: String = {
        guard let firstComponent = self.components.first else { return self.fullName }

        var name = String()
        switch self.nameOrder {
        case .givenNameLast:
            name += self.components.last!
        case .givenNameFirst:
            name += firstComponent
        case .arabicGivenName:
            name += firstComponent
            guard self.components.count > 1 else { break }
            let comp = self.components[1]
            guard comp.zmIsGodName() else { break }
            name = [name, comp].joined(separator: " ")
        }
        return name
    }()

    lazy public var initials: String = {
        guard let firstComponent = self.components.first else { return "" }

        var _initials = String()
        switch self.nameOrder {
        case .givenNameLast:
            _initials += (firstComponent.zmFirstComposedCharacter() ?? "")
            _initials += (firstComponent.zmSecondComposedCharacter() ?? "")
        case .arabicGivenName, .givenNameFirst:
            _initials += (firstComponent.zmFirstComposedCharacter() ?? "")
            guard self.components.count > 1, let lastComponent = self.components.last else { break }
            _initials += (lastComponent.zmFirstComposedCharacter() ?? "")
        }
        return _initials
    }()

    public static func person(withName name: String, schemeTagger: NSLinguisticTagger?) -> PersonName {
        let tagger = schemeTagger ?? NSLinguisticTagger(tagSchemes: convertToNSLinguisticTagSchemeArray([convertFromNSLinguisticTagScheme(NSLinguisticTagScheme.script)]), options: 0)

        if let cachedPersonName = stringsToPersonNames.object(forKey: name as NSString) {
            return cachedPersonName
        }
        let cachedPersonName = PersonName(name: name, schemeTagger: tagger)
        stringsToPersonNames.setObject(cachedPersonName, forKey: name as NSString)
        return cachedPersonName
    }

    public init(name: String, schemeTagger: NSLinguisticTagger) {
        // We're using -precomposedStringWithCanonicalMapping (Unicode Normalization Form C)
        // since this allows us to use faster string comparison later.
        self.rawFullName = name
        self.fullName = name.precomposedStringWithCanonicalMapping
        self.nameOrder = type(of: self).script(of: name, schemeTagger: schemeTagger)
        self.components = type(of: self).splitNameComponents(fullName: fullName)
    }

    static func script(of string: String, schemeTagger: NSLinguisticTagger) -> NameOrder {
        // We are checking the linguistic scheme in order to distinguisch between differences in the order of given and last name
        // If the name contains latin scheme tag, it uses the first name as the given name
        // If the name is in arab sript, we will check if the givenName consists of "servent of" + one of the names for god
        schemeTagger.string = string
        let tags = schemeTagger.tags(in: NSRange(location: 0, length: schemeTagger.string!.count), scheme: convertFromNSLinguisticTagScheme(NSLinguisticTagScheme.script), options: [.omitPunctuation, .omitWhitespace, .omitOther, .joinNames], tokenRanges: nil)

        let nameOrder: NameOrder
        if tags.contains("Arab") {
            nameOrder = .arabicGivenName
        }
        else if tags.contains(where: {["Hani", "Jpan", "Deva", "Gurj"].contains($0)}) {
            nameOrder = tags.contains("Latn") ? .givenNameFirst : .givenNameLast
        }
        else {
            nameOrder = .givenNameFirst
        }
        return nameOrder
    }

    static func splitNameComponents(fullName: String) -> [String] {
        let fullRange = Range<String.Index>(uncheckedBounds: (lower:fullName.startIndex, upper:fullName.endIndex))
        var components = [String]()
        var component: String?
        var lastRange: Range<String.Index>?

        // This is a bit more complicated because we don't want chinese names to be split up by their individual characters
        let options: NSLinguisticTagger.Options = [.omitPunctuation, .omitWhitespace, .omitOther]
        fullName.enumerateLinguisticTags(in: fullRange, scheme: convertFromNSLinguisticTagScheme(NSLinguisticTagScheme.tokenType), options: options, orthography: nil) { (tag, substringRange, _, _) in
            guard tag == convertFromNSLinguisticTag(NSLinguisticTag.word) else { return }
            let substring = fullName[substringRange]
            if let aComponent = component {
                if let lastRangeBound = lastRange?.upperBound, lastRangeBound == substringRange.lowerBound {
                    component = aComponent+substring
                    return
                }
                components.append(aComponent)
                component = nil
            }
            if !substring.isEmpty {
                component = String(substring)
                lastRange = substringRange
            } else {
                lastRange = nil
            }
        }
        if let aComponent = component {
            components.append(aComponent)
        }
        return components
    }

    override public var hash: Int {
        var hash = 0
        components.forEach {hash ^= $0.hash}
        return hash
    }

    func stringStarts(withUppercaseString string: String) -> Bool {
        guard let scalar = string.unicodeScalars.first else { return false }

        let uppercaseCharacterSet = NSCharacterSet.uppercaseLetters
        return uppercaseCharacterSet.contains(scalar)
    }

}

// Helper function inserted by Swift 4.2 migrator.
private func convertToNSLinguisticTagSchemeArray(_ input: [String]) -> [NSLinguisticTagScheme] {
	return input.map { key in NSLinguisticTagScheme(key) }
}

// Helper function inserted by Swift 4.2 migrator.
private func convertFromNSLinguisticTagScheme(_ input: NSLinguisticTagScheme) -> String {
	return input.rawValue
}

// Helper function inserted by Swift 4.2 migrator.
private func convertFromNSLinguisticTag(_ input: NSLinguisticTag) -> String {
	return input.rawValue
}
