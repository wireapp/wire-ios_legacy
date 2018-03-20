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

protocol AlertResultConfiguration {
    static var title: String { get }
    static var all: [Self] { get }
    func action(_ handler: @escaping (Self) -> Void) -> UIAlertAction
}

extension AlertResultConfiguration {
    static func controller(_ handler: @escaping (Self) -> Void) -> UIAlertController {
        let controller = UIAlertController(title: title, message: nil, preferredStyle: .actionSheet)
        all.map { $0.action(handler) }.forEach(controller.addAction)
        return controller
    }
}

extension ConversationActionController {
    
    func request<T: AlertResultConfiguration>(_ result: T.Type, handler: @escaping (T) -> Void) {
        present(result.controller(handler))
    }

}
