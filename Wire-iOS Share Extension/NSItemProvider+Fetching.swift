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


import MobileCoreServices


extension NSItemProvider {

    /// Extracts the URL from the item provider
    func fetchURL(completion: @escaping (URL?)->()) {
        self.loadItem(forTypeIdentifier: kUTTypeURL as String, options: nil, urlCompletionHandler: { (url, error) in
            guard let url = url, error == nil else {
                completion(nil)
                return
            }
            completion(url)
        })
    }

    /// Extracts data from the item provider
    func fetchData(completion: @escaping(Data?)->()) {
        self.loadItem(forTypeIdentifier: kUTTypeData as String, options: [:], dataCompletionHandler: { (data, error) in
            guard let data = data, error != nil else {
                completion(nil)
                return
            }
            completion(data)
        })
    }
}
