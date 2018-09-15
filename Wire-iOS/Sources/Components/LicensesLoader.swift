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

import Foundation

/**
 * Loads the list of licenses embedded inside the app.
 *
 * This object is not thread safe and should only be used from the main thread.
 */

@objc class LicensesLoader: NSObject {

    /// The shared loader.
    static let shared = LicensesLoader()

    private let sourceName = "Licenses.generated"
    private let sourceExtension = "plist"

    private(set) var cache: [SettingsLicenseItem]? = nil
    private var memoryWarningToken: Any?

    // MARK: - Initialization

    init(memoryManager: Any? = nil) {
        super.init()
        memoryWarningToken = NotificationCenter.default.addObserver(forName: UIApplication.didReceiveMemoryWarningNotification, object: memoryManager, queue: .main) { [weak self] _ in
            self?.cache = nil
        }
    }

    deinit {
        memoryWarningToken.apply(NotificationCenter.default.removeObserver)
    }

    // MARK: - Reading the list of Licences

    /// Returns the list of 3rd party licences used by the app.
    func loadLicenses() -> [SettingsLicenseItem]? {
        if let cachedItems = cache {
            return cachedItems
        }

        guard
            let plistURL = Bundle.main.url(forResource: sourceName, withExtension: sourceExtension),
            let plistContents = try? Data(contentsOf: plistURL),
            let decodedPlist = try? PropertyListDecoder().decode([SettingsLicenseItem].self, from: plistContents)
        else {
            return nil
        }

        self.cache = decodedPlist
        return decodedPlist
    }

    // MARK: - Testing

    @objc var cacheEmpty: Bool {
        return cache == nil
    }

}
