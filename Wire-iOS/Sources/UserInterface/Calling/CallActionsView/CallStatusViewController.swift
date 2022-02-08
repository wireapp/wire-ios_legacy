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

final class CallStatusViewController: UIViewController {

    var configuration: CallStatusViewInputType {
        didSet {
            updateState()
        }
    }

    private let stackView = UIStackView()
    private let statusView: CallStatusView
    private let securityLevelView = SecurityLevelView()
    private weak var callDurationTimer: Timer?

    init(configuration: CallStatusViewInputType) {
        self.configuration = configuration
        statusView = CallStatusView(configuration: configuration)
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        createConstraints()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateState()
    }

    deinit {
        stopCallDurationTimer()
    }

    private func setupViews() {
        [stackView, statusView, securityLevelView].prepareForLayout()

        stackView.axis = .vertical
        stackView.spacing = 12
        view.addSubview(stackView)

        statusView.accessibilityTraits = .header
        view.addSubview(statusView)

        view.addSubview(securityLevelView)

        stackView.addArrangedSubview(statusView)
        stackView.addArrangedSubview(securityLevelView)
    }

    private func createConstraints() {
        stackView.fitIn(view: view)
    }

    private func updateState() {
        statusView.configuration = configuration

        securityLevelView.configure(with: configuration.classification)

        switch configuration.state {
        case .established: startCallDurationTimer()
        case .terminating: stopCallDurationTimer()
        default: break
        }
    }

    private func startCallDurationTimer() {
        stopCallDurationTimer()
        callDurationTimer = .scheduledTimer(withTimeInterval: 0.1, repeats: true) { [statusView, configuration] _ in
            statusView.configuration = configuration
        }
    }

    private func stopCallDurationTimer() {
        callDurationTimer?.invalidate()
        callDurationTimer = nil
    }
}
