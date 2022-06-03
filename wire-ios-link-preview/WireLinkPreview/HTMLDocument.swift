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

import Foundation
import HTMLString
import libxml2

// MARK: Models

/// Pointer that represents an HTML document.
typealias HTMLDocument = xmlDocPtr

/// Pointer that represents an element in an HTML tree.
typealias HTMLElement = xmlNodePtr

extension UnsafeMutablePointer where Pointee == xmlDoc {

    /// Tries to create a new HTML document.
    init?(xmlString: String) {
        let options = Int32(HTML_PARSE_NOWARNING.rawValue) | Int32(HTML_PARSE_NOERROR.rawValue) | Int32(HTML_PARSE_RECOVER.rawValue)
        let data = Data(xmlString.utf8)

        let decodedDocument = data.withUnsafeBytes { (pointer: UnsafeRawBufferPointer) -> xmlDocPtr? in
            guard let cString = pointer.baseAddress?.assumingMemoryBound(to: Int8.self) else { return nil }
            return htmlReadMemory(cString, Int32(data.count), "", nil, options)
        }

        guard let rawPtr = decodedDocument else { return nil }
        self = rawPtr
    }

    /// Returns the root element of the document.
    var rootElement: xmlNodePtr? {
        return xmlDocGetRootElement(self)
    }

    /// Releases the resources used by an HTML document after we are done processing it.
    static func free(_ doc: HTMLDocument) {
        xmlFreeDoc(doc)
    }

}

extension UnsafeMutablePointer where Pointee == xmlNode {

    /// The name of the HTML tag.
    var tagName: HTMLStringBuffer {
        return HTMLStringBuffer(unowned: pointee.name)
    }

    /// The textual content of the element.
    var content: HTMLStringBuffer? {
        guard let text = xmlNodeGetContent(self) else { return nil }
        return HTMLStringBuffer(retaining: text)
    }

    /// The children of the element, as an iterable sequence.
    var children: HTMLChildrenSequence {
        let iterator = HTMLChildrenIterator(rootElement: self)
        return HTMLChildrenSequence(iterator)
    }

    /// Returns the attribute of the element for the given name.
    subscript(attribute attributeName: String) -> HTMLStringBuffer? {
        guard let xmlProp = xmlGetProp(self, attributeName) else { return nil }
        return HTMLStringBuffer(retaining: xmlProp)
    }

}

// MARK: - Helper Types

/// A sequence of HTML elements.
typealias HTMLChildrenSequence = IteratorSequence<HTMLChildrenIterator>

final class HTMLChildrenIterator: IteratorProtocol {
    let rootElement: HTMLElement
    var currentChild: HTMLElement?

    init(rootElement: HTMLElement) {
        self.rootElement = rootElement
        self.currentChild = nil
    }

    func next() -> HTMLElement? {
        let nextPtr: xmlNodePtr?

        if let currentChild = self.currentChild {
            nextPtr = xmlNextElementSibling(currentChild)
        } else {
            nextPtr = xmlFirstElementChild(rootElement)
        }

        currentChild = nextPtr
        return currentChild
    }
}

/**
 * Wrapper around a `xmlCharPtr`, that represents an HTML string.
 */

final class HTMLStringBuffer {
    enum Storage {
        case retained(UnsafeMutablePointer<xmlChar>)
        case unowned(UnsafePointer<xmlChar>)
    }

    let storage: Storage

    /// Creates a new string wrapper.
    init(unowned ptr: UnsafePointer<xmlChar>) {
        self.storage = .unowned(ptr)
    }

    /// Creates a new string wrapper.
    init(retaining ptr: UnsafeMutablePointer<xmlChar>) {
        self.storage = .retained(ptr)
    }

    deinit {
        if case let .retained(ptr) = storage {
            xmlFree(ptr)
        }
    }

    /// Returns the value of the string, with unescaped HTML entities.
    func stringValue(removingEntities removeEntities: Bool) -> String {
        let stringValue: String

        switch storage {
        case .retained(let ptr):
            stringValue = String(cString: ptr)
        case .unowned(let ptr):
            stringValue = String(cString: ptr)
        }

        return removeEntities ? stringValue.removingHTMLEntities() : stringValue
    }

}

/// Compares an HTML string with an UTF-8 Swift string.
func == (lhs: HTMLStringBuffer, rhs: String) -> Bool {
    switch lhs.storage {
    case .retained(let ptr):
        return xmlStrEqual(ptr, rhs) == 1
    case .unowned(let ptr):
        return xmlStrEqual(ptr, rhs) == 1
    }
}
