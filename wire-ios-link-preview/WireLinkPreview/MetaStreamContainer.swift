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

final class MetaStreamContainer {

    var bytes = Data()

    var stringContent: String? {
        return parseString(from: bytes)
    }

    var head: String? {
        guard let content = stringContent else { return nil }
        var startBound = content.range(of: OpenGraphXMLNode.headStart.rawValue)?.lowerBound ??
                           content.range(of: OpenGraphXMLNode.headStartNoAttributes.rawValue)?.lowerBound ??
                           content.startIndex

        let upperBound = content.range(of: OpenGraphXMLNode.headEnd.rawValue)?.upperBound ?? content.endIndex

        if startBound >= upperBound {
            startBound = content.startIndex
        }

        let result = content[startBound..<upperBound]
        return String(result)
    }

    var reachedEndOfHead = false

    @discardableResult func addData(_ data: Data) -> Data {
        updateReachedEndOfHead(withData: data)
        bytes.append(data)
        return bytes as Data
    }

    private func updateReachedEndOfHead(withData data: Data) {
        guard let string = parseString(from: data)?.lowercased() else { return }
        if string.contains(OpenGraphXMLNode.headEnd.rawValue) {
            reachedEndOfHead = true
        }
    }

    private func parseString(from data: Data) -> String? {
        return String(data: data, encoding: .utf8)
            ?? String(data: data, encoding: .isoLatin1)
    }

}
