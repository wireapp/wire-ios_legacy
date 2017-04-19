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


import Cartography

@objc enum ComposeAction: UInt {
    case contacts = 1, drafts = 2
}

@objc class ComposeEntryViewController: UIViewController {

    private let plusButton = IconButton.iconButtonDefaultDark()
    private let contactsButton = IconButton.iconButtonCircularDark()
    private let composeButton = IconButton.iconButtonCircularDark()
    private let dimmView = UIView()
    private unowned let referenceView: UIView

    var onDismiss: ((ComposeEntryViewController) -> Void)?
    var onAction: ((ComposeEntryViewController, ComposeAction) -> Void)?

    init(referenceView: UIView) {
        self.referenceView = referenceView
        super.init(nibName: nil, bundle: nil)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
    }

    override func didMove(toParentViewController parent: UIViewController?) {
        super.didMove(toParentViewController: parent)
        guard nil != parent else { return }
        createConstraints()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupViews() {
        dimmView.backgroundColor = UIColor(white: 0, alpha: 0.5)
        dimmView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(dismissController)))
        contactsButton.backgroundColor = UIColor(for: .strongBlue)
        contactsButton.setIcon(.person, with: .tiny, for: .normal)
        contactsButton.setIconColor(.white, for: .normal)
        contactsButton.addTarget(self, action: #selector(contactsTapped), for: .touchUpInside)
        composeButton.backgroundColor = .white
        composeButton.addTarget(self, action: #selector(draftsTapped), for: .touchUpInside)
        composeButton.setIcon(.conversation, with: .tiny, for: .normal)
        plusButton.setIcon(.plus, with: .tiny, for: .normal)
        plusButton.addTarget(self, action: #selector(dismissController), for: .touchUpInside)
        [dimmView, plusButton, contactsButton, composeButton].forEach(view.addSubview)
    }

    private func createConstraints() {
        constrain(referenceView, plusButton, contactsButton, composeButton)
        { referenceView, plusButton, contactsButton, composeButton in
            plusButton.edges == referenceView.edges

            composeButton.height == 50
            composeButton.width == 50
            contactsButton.height == 50
            contactsButton.width == 50
        }

        constrain(view, dimmView) { view, dimmView in
            dimmView.edges == view.edges
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        contactsButton.center = plusButton.center.pointOnCircle(radius: 100, angle: -75)
        composeButton.center = plusButton.center.pointOnCircle(radius: 100, angle: -15)
    }

    private dynamic func dismissController() {
        onDismiss?(self)
    }

    private dynamic func contactsTapped() {
        onAction?(self, .contacts)
    }

    private dynamic func draftsTapped() {
        onAction?(self, .drafts)
    }

    func animateIn() {
        UIView.animate(withDuration: 0.2) { 
            self.view.backgroundColor = UIColor(white: 0, alpha: 0.2)
            self.plusButton.transform = CGAffineTransform(rotationAngle: 90)
        }
    }

    func animateOut() {
        UIView.animate(withDuration: 0.2) {
            self.view.backgroundColor = .clear
            self.plusButton.transform = .identity
        }
    }

}

extension CGPoint {

    func pointOnCircle(radius: CGFloat, angle: CGFloat) -> CGPoint {
        let radians = angle * .pi / 180
        return CGPoint(
            x: x + radius * cos(radians),
            y: y + radius * sin(radians)
        )
    }

}
