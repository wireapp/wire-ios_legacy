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
import WireSyncEngine

extension ConversationInputBarViewController {

    func setupInputLanguageObserver() {
        NotificationCenter.default.addObserver(self, selector: #selector(inputModeDidChange(_:)), name: UITextInputMode.currentInputModeDidChangeNotification, object: nil)

    }

    @objc
    func inputModeDidChange(_ notification: Notification?) {
        guard let conversation = conversation as? ZMConversation else { return }

        guard let keyboardLanguage =  self.inputBar.textView.originalTextInputMode?.primaryLanguage else { return }

        ZMUserSession.shared()?.enqueue {
            conversation.language = keyboardLanguage
            self.setInputLanguage()
        }
    }

    func setInputLanguage() {
        guard let conversation = conversation as? ZMConversation else { return }

        inputBar.textView.language = conversation.language
    }
}
