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

import Foundation

@objc final public class ManagedObjectContextChangeObserver: NSObject {

    public typealias ChangeCallback = () -> Void
    private unowned var context: NSManagedObjectContext
    private let callback: ChangeCallback
    private var token: NSObjectProtocol?

    public init(context: NSManagedObjectContext, callback: @escaping ChangeCallback) {
        self.context = context
        self.callback = callback
        super.init()
        addSaveNotificationObserver()
    }

    private func addSaveNotificationObserver() {
        token = NotificationCenter.default.addObserver(
            forName: .NSManagedObjectContextObjectsDidChange,
            object: context,
            queue: nil,
            using: {  [weak self] _ in self?.callback() }
        )
    }

    deinit {
        guard let token = token else { return }
        NotificationCenter.default.removeObserver(token)
    }

}
