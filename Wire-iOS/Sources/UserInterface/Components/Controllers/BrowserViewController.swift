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
import SafariServices

final class BrowserViewController: SFSafariViewController {

    var completion: (() -> Void)?
    var onDismiss: (() -> Void)?

    // MARK: - Tint Color

    private var overrider = TintColorOverrider()

    override func viewDidLoad() {
        super.viewDidLoad()
        preferredControlTintColor = SemanticColors.Label.textDefault
        delegate = self
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        overrider.override()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        overrider.restore()
    }

    override func dismiss(animated flag: Bool, completion defaultBlock: (() -> Void)? = nil) {
        super.dismiss(animated: flag) {
            self.onDismiss?()
            defaultBlock?()
        }
    }

}

extension BrowserViewController: SFSafariViewControllerDelegate {
    func safariViewControllerDidFinish(_ controller: SFSafariViewController) {
        completion?()
    }
}
