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

/*
typealias ItemProviderDataCompletionHandler = (Data?, Error?) -> Void
typealias ItemProviderImageCompletionHandler = (UIImage?, Error?) -> Void
typealias ItemProviderURLCompletionHandler = (URL?, Error?) -> Void


extension NSItemProvider {
    func loadItem(forTypeIdentifier typeIdentifier: String?,
                  options: [AnyHashable : Any]?, dataCompletionHandler: @escaping ItemProviderDataCompletionHandler) {
        loadItem(forTypeIdentifier: typeIdentifier ?? "", options: options, completionHandler: { item, error in
            dataCompletionHandler(item, error)
        })
    }

    func loadItem(forTypeIdentifier typeIdentifier: String?, options: [AnyHashable : Any]?, imageCompletionHandler: @escaping ItemProviderImageCompletionHandler) {
        loadItem(forTypeIdentifier: typeIdentifier ?? "", options: options, completionHandler: { item, error in
            imageCompletionHandler(item, error)
        })
    }

    func loadItem(forTypeIdentifier typeIdentifier: String?, options: [AnyHashable : Any]?, urlCompletionHandler URLCompletionHandler: @escaping ItemProviderURLCompletionHandler) {
        loadItem(forTypeIdentifier: typeIdentifier ?? "", options: nil, completionHandler: URLCompletionHandler)
    }
}
*/
