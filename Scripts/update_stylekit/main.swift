//
// Wire
// Copyright (C) 2019 Wire Swiss GmbH
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
// This script updates the WireCommonComponents/Icons/Autogenerated/StyleKitIcons.swift file with the
// latest icon definitions from the WireStyleKit swift file.
//
// In Xcode, add this script as a build phase, before the "Compile Sources" phase in the
// common components main target.
//
// The first input file must be the WireStyleKit.swift file in the same directory. The output file must be the
// StyleKitIcons.swift file.
//
// This script will be run every time we clean the project, and when the StyleKit file changes.
//

import Foundation

let template = """
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
// AUTOGENERATED DURING BUILD, DO NOT EDIT
// --------------------------------------------------------------------
//

import UIKit

/**
* The list of icons that can be rendered from the style kit.
*/

public enum StyleKitIcon: Int {

    /// Represents the data necessary to render the icons.
    public typealias RenderingProperties = (renderingMethod: (UIColor) -> Void, originalSize: CGFloat)

{{ ENUM_CASES }}
    /// The properties to use to render the icon.
    var renderingProperties: RenderingProperties {
        switch self {
{{ RENDERING_PROPERTIES }}        }
    }
}
"""

// MARK: - Helpers

/// Exits the script because of an error.
func fail(_ error: String) -> Never {
    print("error:  \(error)")
    exit(-1)
}

/// Prints an info message.
func info(_ message: String) {
    print("warning:  \(message)")
}

/// Prints a success message and exits the script.
func success(_ message: String) -> Never {
    print("✅  \(message)")
    exit(0)
}

/// Gets an environment variable value with the given name.
func getEnvironmentValue(key: String) -> String? {
    guard let rawValue = getenv(key) else {
        return nil
    }

    return String(cString: rawValue)
}

// MARK: - Arguments

/// Returns the input files.
func getStyleKitURL() -> URL {
    guard let styleKit = getEnvironmentValue(key: "SCRIPT_INPUT_FILE_0") else {
        fail("The second input file in Xcode must be the 'WireStyleKit.swift' file.")
    }

    return URL(fileURLWithPath: styleKit)
}

/// Returns the output file.
func getOutput() -> URL {
    guard let swiftOutputPath = getEnvironmentValue(key: "SCRIPT_OUTPUT_FILE_0") else {
        fail("The second input file in Xcode must be the 'StyleKitIcons.swift' file.")
    }

    return URL(fileURLWithPath: swiftOutputPath)
}

// MARK: - Parsing

func getRenderingInfo(in str: String) -> [String: String] {
    let regex = try! NSRegularExpression(pattern: "@objc dynamic public class func drawIcon_(\\w+)_(\\d+)pt", options: [])
    let stringRange = NSRange(str.startIndex ..< str.endIndex, in: str)

    var knownIcons: [String: String] = [:]

    regex.enumerateMatches(in: str, options: [], range: stringRange) { result, _, _ in
        let m0Range = result!.range(at: 1)
        let m1Range = result!.range(at: 2)

        let id = str[Range(m0Range, in: str)!]
        let size = str[Range(m1Range, in: str)!]
        knownIcons[String(id)] = String(size)
    }

    return knownIcons
}

func generateText(renderingInfo: [String: String]) -> (enumCases: String, renderingProperties: String) {
    var enumCases: String = ""
    var renderingProperties: String = ""

    for (name, size) in renderingInfo {
        enumCases.append("    case \(name)\n")
        renderingProperties.append("        case .\(name): return (WireStyleKit.drawIcon_\(name)_\(size)pt, \(size))\n")
    }

    return (enumCases, renderingProperties)
}

// MARK: - Execution

let styleKit = getStyleKitURL()
let outputURL = getOutput()

// 1) Decode the Style Kit

let styleKitSources = try String(contentsOf: styleKit)
let renderingInfo = getRenderingInfo(in: styleKitSources)

let (enumCases, renderingProperties) = generateText(renderingInfo: renderingInfo)

// 2) Encode and write the data

var generatedSources = template
generatedSources = generatedSources.replacingOccurrences(of: "{{ ENUM_CASES }}", with: enumCases)
generatedSources = generatedSources.replacingOccurrences(of: "{{ RENDERING_PROPERTIES }}", with: renderingProperties)

try generatedSources.write(to: outputURL, atomically: true, encoding: .utf8)
success("Successfully updated the list of icons")
