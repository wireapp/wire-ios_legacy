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
import WireCommonComponents
import WireShareEngine
import SystemConfiguration
import WireSystem
import UIKit

final class SendingProgressViewController: UIViewController {

    enum ProgressMode {
        case preparing, sending
    }

    var cancelHandler: (() -> Void)?

    private var circularShadow = CircularProgressView()
    private var circularProgress = CircularProgressView()
    private var connectionStatusLabel = UILabel()
    private let minimumProgress: Float = 0.125

    var progress: Float = 0 {
        didSet {
            mode = .sending
            let adjustedProgress = (progress / (1 + minimumProgress)) + minimumProgress
            circularProgress.setProgress(adjustedProgress, animated: true)
        }
    }

    var mode: ProgressMode = .preparing {
        didSet {
            updateProgressMode()
        }
    }

    func updateProgressMode() {
        switch mode {
        case .sending:
            circularProgress.deterministic = true
            self.title = "share_extension.sending_progress.title".localized
        case .preparing:
            circularProgress.deterministic = false
            circularProgress.setProgress(minimumProgress, animated: false)
            self.title = "share_extension.preparing.title".localized
        }
    }

    init() {
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        self.navigationItem.hidesBackButton = true
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(onCancelTapped))

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(SendingProgressViewController.networkStatusDidChange(_:)),
                                               name: Notification.Name.NetworkStatus,
                                               object: nil)

        circularShadow.lineWidth = 2
        circularShadow.setProgress(1, animated: false)
        circularShadow.alpha = 0.2

        circularProgress.lineWidth = 2
        circularProgress.setProgress(0, animated: false)

        connectionStatusLabel.font = UIFont.systemFont(ofSize: UIFont.smallSystemFontSize)
        connectionStatusLabel.textAlignment = .center
        connectionStatusLabel.isHidden = true
        connectionStatusLabel.text = "share_extension.no_internet_connection.title".localized

        view.addSubview(circularShadow)
        view.addSubview(circularProgress)
        view.addSubview(connectionStatusLabel)

        createConstraints()

        updateProgressMode()

        let reachability = NetworkStatus.shared.reachability
        setReachability(from: reachability)
    }

    private func createConstraints() {
        [circularShadow,
         circularProgress,
         connectionStatusLabel].prepareForLayout()

        NSLayoutConstraint.activate([
            circularShadow.widthAnchor.constraint(equalToConstant: 48),
            circularShadow.heightAnchor.constraint(equalToConstant: 48),
            circularShadow.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            circularShadow.centerYAnchor.constraint(equalTo: view.centerYAnchor),

            circularProgress.widthAnchor.constraint(equalToConstant: 48),
            circularProgress.heightAnchor.constraint(equalToConstant: 48),
            circularProgress.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            circularProgress.centerYAnchor.constraint(equalTo: view.centerYAnchor),

            connectionStatusLabel.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -5),
            connectionStatusLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])
    }

    @objc
    private func onCancelTapped() {
        cancelHandler?()
    }

    @objc
    private func networkStatusDidChange(_ notification: Notification) {
        if let status = notification.object as? NetworkStatus {
            setReachability(from: status.reachability)
        }
    }

    func setReachability(from reachability: ServerReachability) {
        switch reachability {
        case .ok:
            connectionStatusLabel.isHidden = true
        case .unreachable:
            connectionStatusLabel.isHidden = false
        }
    }

}
