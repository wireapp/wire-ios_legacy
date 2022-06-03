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

final class OpenGraphScanner: NSObject {

    typealias ParserCompletion = (OpenGraphData?) -> Void

    let xmlString: String
    var contentsByProperty = [OpenGraphPropertyType: String]()
    var images = [String]()
    var pageTitle: String?
    var completion: ParserCompletion
    var originalURL: URL

    init(_ xmlString: String, url: URL, completion: @escaping ParserCompletion) {
        self.xmlString = xmlString
        self.completion = completion
        originalURL = url
        super.init()
    }

    func parse() {
        // 1. Parse the document
        guard let document = HTMLDocument(xmlString: xmlString) else { return completion(nil) }
        defer { HTMLDocument.free(document) }

        // 2. Find the head
        guard let headElement = findHead(in: document) else { return completion(nil) }

        // 3. Go through the attributes
        for headChild in headElement.children {
            if headChild.tagName == "title" {
                pageTitle = headChild.content?.stringValue(removingEntities: true)
            } else if headChild.tagName == "meta" {
                parseOpenGraphMetadata(headChild)
            }
        }

        // 4. Finish parsing
        createObjectAndComplete()
    }

    // MARK: - Parsing

    /// Returns the first head element in the document.
    private func findHead(in document: HTMLDocument) -> HTMLElement? {
        guard let rootElement = document.rootElement else { return nil }

        if rootElement.tagName == "head" {
            return rootElement
        } else {
            return rootElement.children.first(where: { $0.tagName == "head" })
        }
    }

    /// Attempts to extract the OpenGraph metadata from an HTML element.
    private func parseOpenGraphMetadata(_ element: HTMLElement) {
        if let rawProperty = element[attribute: OpenGraphAttribute.property]?.stringValue(removingEntities: false),
            let property = OpenGraphPropertyType(rawValue: rawProperty),
            let content = element[attribute: OpenGraphAttribute.content]?.stringValue(removingEntities: true) {
            addProperty(property, value: content)
        }
    }

    private func addProperty(_ property: OpenGraphPropertyType, value: String) {
        if property == .image {
            images.append(value)
        } else {
            contentsByProperty[property] = value
        }
    }

    // MARK: - Post-Processing

    private func createObjectAndComplete() {
        insertMissingUrlIfNeeded()
        insertMissingTitleIfNeeded()
        let data = OpenGraphData(propertyMapping: contentsByProperty, resolvedURL: originalURL, images: images)
        completion(data)
    }

    private func insertMissingUrlIfNeeded() {
        guard !contentsByProperty.keys.contains(.url) else { return }
        contentsByProperty[.url] = originalURL.absoluteString
    }

    private func insertMissingTitleIfNeeded() {
        guard !contentsByProperty.keys.contains(.title) else { return }
        pageTitle.map { addProperty(.title, value: $0) }
    }

}
