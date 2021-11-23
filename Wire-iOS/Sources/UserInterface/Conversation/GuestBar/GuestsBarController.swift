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
import UIKit
import Down

final class GuestsBarController: UIViewController {

    enum State: Equatable {
        case visible(labelKey: String, identifier: String)
        case hidden
    }

    private let label = UILabel()
    private let container = UIView()
    private lazy var containerHeightConstraint: NSLayoutConstraint = container.heightAnchor.constraint(equalToConstant: GuestsBarController.expandedHeight)
    private lazy var heightConstraint: NSLayoutConstraint = view.heightAnchor.constraint(equalToConstant: GuestsBarController.expandedHeight)
    private lazy var bottomLabelConstraint: NSLayoutConstraint = label.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -3)

    private static let collapsedHeight: CGFloat = 2
    private static let expandedHeight: CGFloat = 20

    private var _state: State = .hidden
    var shouldIgnoreUpdates: Bool = false

    var state: State {
        get {
            return _state
        }
        set {
            guard newValue != state else { return }
            setState(newValue, animated: false)
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        createConstraints()
    }

    private func setupViews() {
        view.backgroundColor = .clear
        container.backgroundColor = .accent()
        container.clipsToBounds = true
        container.addSubview(label)
        view.addSubview(container)
    }

    private func createConstraints() {
        [container, label].prepareForLayout()
        NSLayoutConstraint.activate([
          label.leadingAnchor.constraint(equalTo: view.leadingAnchor),
          bottomLabelConstraint,
          label.trailingAnchor.constraint(equalTo: view.trailingAnchor),
          view.leadingAnchor.constraint(equalTo: container.leadingAnchor),
          view.trailingAnchor.constraint(equalTo: container.trailingAnchor),
          container.topAnchor.constraint(equalTo: view.topAnchor),

          heightConstraint,
          containerHeightConstraint
        ])
    }

    // MARK: - State Changes

    func setState(_ state: State, animated: Bool) {
        guard _state != state, isViewLoaded, !shouldIgnoreUpdates else { return }

        _state = state
        configureTitle(with: state)
        let collapsed = state == .hidden

        let change = {
            if !collapsed {
                self.heightConstraint.constant = collapsed ? GuestsBarController.collapsedHeight : GuestsBarController.expandedHeight
                self.view.setNeedsLayout()
                self.view.layoutIfNeeded()
            }

            self.containerHeightConstraint.constant = collapsed ? GuestsBarController.collapsedHeight : GuestsBarController.expandedHeight
            self.bottomLabelConstraint.constant = collapsed ? -GuestsBarController.expandedHeight : -3
            self.label.alpha = collapsed ? 0 : 1
            self.view.setNeedsLayout()
            self.view.layoutIfNeeded()
        }

        let completion: (Bool) -> Void = { _ in
            guard collapsed else { return }
            self.containerHeightConstraint.constant = collapsed ? GuestsBarController.collapsedHeight : GuestsBarController.expandedHeight
        }

        if animated {
            UIView.animate(easing: collapsed ? .easeOutQuad : .easeInQuad, duration: 0.4, animations: change, completion: completion)
        } else {
            change()
            completion(true)
        }
    }

    func configureTitle(with state: State) {
        switch state {
        case .hidden:
            label.text = nil
            label.accessibilityIdentifier = nil
        case .visible(let labelKey, let accessibilityIdentifier):
            let markdownTitle = labelKey.localized
            label.attributedText = .markdown(from: markdownTitle,
                                             style: .labelStyle)
            label.textAlignment = .center
            label.accessibilityIdentifier = accessibilityIdentifier
        }
    }

}

// MARK: - Bar

extension GuestsBarController: Bar {
    var weight: Float {
        return 1
    }
}

private extension DownStyle {

    static var labelStyle: DownStyle {
        let style = DownStyle()
        style.baseFont = UIFont.systemFont(ofSize: 12, contentSizeCategory: .medium, weight: .light)
        style.baseFontColor = .white
        style.baseParagraphStyle = NSParagraphStyle.default

        return style
    }

}
