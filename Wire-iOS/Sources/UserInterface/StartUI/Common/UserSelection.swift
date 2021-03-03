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
import WireUtilities
import WireDataModel

@objc
protocol UserSelectionObserver: class {

    func userSelection(_ userSelection: UserSelection, didAddUser user: UserType)
    func userSelection(_ userSelection: UserSelection, didRemoveUser user: UserType)
    func userSelection(_ userSelection: UserSelection, wasReplacedBy users: [UserType])

}

class UserSelection: NSObject {

    private(set) var users = UserSet()
    private var observers: [UnownedObject<UserSelectionObserver>] = []

    func replace(_ users: [UserType]) {
        self.users = UserSet(users)
        observers.forEach({ $0.unbox?.userSelection(self, wasReplacedBy: users) })
    }

    func add(_ user: UserType) {
        users.insert(user)
        observers.forEach({ $0.unbox?.userSelection(self, didAddUser: user) })
    }

    func remove(_ user: UserType) {
        users.remove(user)
        observers.forEach({ $0.unbox?.userSelection(self, didRemoveUser: user) })
    }

    func add(observer: UserSelectionObserver) {
        guard !observers.contains(where: { $0.unbox === observer}) else { return }

        observers.append(UnownedObject(observer))
    }

    func remove(observer: UserSelectionObserver) {
        guard let index = observers.firstIndex(where: { $0.unbox === observer}) else { return }

        observers.remove(at: index)
    }

    // MARK: - Limit

    private(set) var limit: Int?
    private var limitReachedHandler: (() -> Void)?

    var hasReachedLimit: Bool {
        guard let limit = limit, users.count >= limit else { return false }
        limitReachedHandler?()
        return true
    }

    func setLimit(_ limit: Int, handler: @escaping () -> Void) {
        self.limit = limit
        self.limitReachedHandler = handler
    }
}
