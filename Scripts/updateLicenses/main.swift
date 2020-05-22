//
// Wire
// Copyright (C) 2020 Wire Swiss GmbH
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
// --------------------------------------------------------------------
// This script updates the Wire-iOS/Resources/Licenses file with the
// latest licenses and dependencies from Carthage.
//
// In Xcode, add this script as a build phase, before the "Copy Bundle
// Resources" phase in the main target.
//
// The first input file must be the Cartfile.resolved file. The second
// input file must be the Cartfile/Checkouts directory. The third input
// file must be the EmbeddedDependencies file. The output filecmust be the
// plist file that will contain the licenses.
//
// This script will be run everytime we clean the project, and when the
// build enviroment changes (when we update Carthage or add/remove
// dependencies).
//

import Foundation

// MARK: - Models

/// The structure representing license items to add in the Plist.
struct Dependency: Codable {

    /// The name of the project.
    let name: String

    /// The text of the license file.
    let licenseText: String

    /// The URL of the project.
    let projectURL: URL

    enum CodingKeys: String, CodingKey {
        case name = "Name"
        case licenseText = "LicenseText"
        case projectURL = "ProjectURL"
    }
}

/// The different file names for the license files.
let licenseSpellings = [
    "LICENSE",
    "License",
    "LICENSE.txt",
    "License.txt",
    "LICENSE.md",
    "License.md"
]

// MARK: - Helpers

/// Exits the script because of an error.
func fail(_ error: String) -> Never {
    print("💥  \(error)")
    exit(-1)
}

/// Prints an info message.
func info(_ message: String) {
    print("ℹ️  \(message)")
}

/// Prints a success message and exits the script.
func success(_ message: String) -> Never {
    print("✅  \(message)")
    exit(0)
}

extension String {

    /// Removes the license columns in the string.
    var removingColumns: String {
        let paragraphs = self.components(separatedBy: "\n\n")
        var singleLines: [String] = []

        for paragraph in paragraphs {
            let lines = paragraph.components(separatedBy: "\n")
            let sanitizedLines = lines.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            let singleLine = sanitizedLines.joined(separator: " ")
            singleLines.append(singleLine)
        }

        return singleLines.joined(separator: "\n\n")
    }

}

/// Gets the license text in the given directory.
func getLicenseURL(in directory: URL) -> URL? {
    guard let topLevelItems = try? FileManager.default.contentsOfDirectory(atPath: directory.path) else {
        return nil
    }

    for spelling in licenseSpellings {
        if topLevelItems.contains(spelling) {
            let possibleURL = directory.appendingPathComponent(spelling)

            guard FileManager.default.fileExists(atPath: possibleURL.path) else {
                continue
            }

            return possibleURL
        }
    }

    return nil
}

// MARK: - Parsing

/// Get the list of depedencies from the Cartfile.resolved file.
func generateFromCartfileResolved(_ content: String, checkoutsDir: URL) -> [Dependency] {
    let dependencyLines = content.split(separator: "\n").filter { $0.hasPrefix("github") }
    var items: [Dependency] = []

    for dependency in dependencyLines {
        // 1) Parse the component info from the Carthage file (ex: github "wireapp/dependency" "version")
        let components = dependency.components(separatedBy: " ")

        guard components.count == 3 else {
            info("Skipping invalid dependency.")
            continue
        }

        let projectPath = components[1].trimmingCharacters(in: .punctuationCharacters)

        let url = URL(string: "https://github.com/\(projectPath)")!

        let projectComponents = projectPath.components(separatedBy: "/")

        guard projectComponents.count == 2 else {
            info("Skipping invalid dependency.")
            continue
        }

        let name = projectComponents[1].trimmingCharacters(in: .symbols)

        // Do not include Wire frameworks
        guard !name.hasPrefix("wire-ios-"), !name.hasPrefix("avs-ios-") else {
            info("Skipping Wire component.")
            continue
        }

        // 2) Get the license text from the checkout out directory

        let projectCheckoutFolder = checkoutsDir.appendingPathComponent(name, isDirectory: true)

        guard let licenseTextURL = getLicenseURL(in: projectCheckoutFolder) else {
            info("The dependency \(name) does not have a license. Skipping.")
            continue
        }

        guard let data = try? Data(contentsOf: licenseTextURL) else {
            info("Could not read the license of \(name). Skipping.")
            break
        }

        let licenseText = String(decoding: data, as: UTF8.self).removingColumns

        //3) Create the item
        let item = Dependency(name: name, licenseText: licenseText, projectURL: url)
        items.append(item)
    }

    return items
}

// MARK: - Execution

let (cartfileURL, checkoutsURL, embeddedDependencies) = (URL(fileURLWithPath: "Cartfile.resolved"),
                                                         URL(fileURLWithPath: "Carthage/Checkouts"),
                                                         URL(fileURLWithPath: "EmbeddedDependencies.plist"))
let outputURL = URL(fileURLWithPath:"Wire-iOS/Resources/Licenses.generated.plist")

// 1) Decode the Cartfile

let cartfileBinary = try Data(contentsOf: cartfileURL)
let cartfileContents = String(decoding: cartfileBinary, as: UTF8.self)

let dependenciesBinary = try Data(contentsOf: embeddedDependencies)
let existingDependencies = try PropertyListDecoder().decode([Dependency].self, from: dependenciesBinary)
let dynamicItems = generateFromCartfileResolved(cartfileContents, checkoutsDir: checkoutsURL)

let items = (existingDependencies + dynamicItems).sorted {
    $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
}

info("Encoding \(items.count) dependencies.")

let encoder = PropertyListEncoder()
encoder.outputFormat = .binary

// 2) Encode and write the data

let encodedPlist = try encoder.encode(items)
try? FileManager.default.removeItem(at: outputURL)
try encodedPlist.write(to: outputURL)

success("Successfully updated the list of licenses")
