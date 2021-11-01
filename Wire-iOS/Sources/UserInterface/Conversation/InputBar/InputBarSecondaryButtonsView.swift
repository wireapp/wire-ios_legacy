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

import UIKit
import Cartography

// Acts as a container for InputBarEditView & MarkdownBarView, however
// only one of the views will be in the view hierarchy at a time.
//
class InputBarSecondaryButtonsView: UIView {

    let editBarView: InputBarEditView
    let markdownBarView: MarkdownBarView

    init(editBarView: InputBarEditView, markdownBarView: MarkdownBarView) {
        self.editBarView = editBarView
        self.markdownBarView = markdownBarView
        super.init(frame: .zero)
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setView(_ newView: UIView) {

        // only if newView isnt already a subview
        guard !newView.isDescendant(of: self) else { return }

        subviews.forEach { $0.removeFromSuperview() }
        addSubview(newView)

        constrain(self, newView) { view, newView in
            newView.edges == view.edges
        }
    }

    func setEditBarView() {
        setView(editBarView)
    }

    func setMarkdownBarView() {
        setView(markdownBarView)
    }
}
