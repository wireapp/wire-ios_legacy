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

extension XCTestCase {
    func image(inTestBundleNamed name: String) -> UIImage {
        let url = urlForResource(inTestBundleNamed: name)
        if name.hasSuffix(".gif") { ///TODO: check is animated?
            if let data = try? Data(contentsOf: url) {

                do {
                    let image = try UIImage(gifData: data)
                    return image
                } catch {
//                    fatal("invalid GIF file, error is \(error)")
                    return UIImage(contentsOfFile: url.path)!
              }


            } else {
//                fatal("invalid GIF file")
                return UIImage(contentsOfFile: url.path)!
            }
        } else {
            return UIImage(contentsOfFile: url.path)!
        }
    }

    func urlForResource(inTestBundleNamed name: String) -> URL {
        let bundle = Bundle(for: type(of: self))

        let url = bundle.url(forResource: name, withExtension: "")

        if let isFileURL = url?.isFileURL {
            XCTAssert(isFileURL)
        } else {
            XCTFail("\(name) does not exist")
        }

        return url!
    }

    var mockImageData: Data {
        return image(inTestBundleNamed: "unsplash_matterhorn.jpg").jpegData(compressionQuality: 0.9)!
    }
}
