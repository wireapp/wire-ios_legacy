//
// Wire
// Copyright (C) 2019 Wire Swiss GmbH
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

final class VersionInfoViewController: UIViewController {

    private var closeButton: IconButton!
    private var versionInfoLabel: UILabel!
    private let componentsVersionsFilepath: String


    init(versionsPlist path: String = Bundle.main.path(forResource: "ComponentsVersions", ofType: "plist")!) {
        componentsVersionsFilepath = path

        super.init(nibName: nil, bundle: nil)
    }


    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .white

        setupCloseButton()
        setupVersionInfo()
    }

    private func setupCloseButton() {
        closeButton = IconButton()
        view.addSubview(closeButton)

        //Cosmetics
        closeButton.setIcon(.cross, size: .small, for: UIControl.State.normal)
        closeButton.setIconColor(UIColor.black, for: UIControl.State.normal)

        //Layout
        closeButton.translatesAutoresizingMaskIntoConstraints = false

        closeButton.pinToSuperview(safely: true, anchor: .top, inset: 24)
        closeButton.pinToSuperview(safely: true, anchor: .trailing, inset: 18)

        //Target
        closeButton.addTarget(self, action: #selector(self.closeButtonTapped(_:)), for: .touchUpInside)
    }

    private func setupVersionInfo() {
        guard let versionsPlist = NSDictionary(contentsOfFile: componentsVersionsFilepath),
              let carthageInfo = versionsPlist["CarthageBuildInfo"] as? [String: String] else { return }


        versionInfoLabel = UILabel()
        versionInfoLabel.numberOfLines = 0
        versionInfoLabel.backgroundColor = UIColor.clear
        versionInfoLabel.textColor = UIColor.black
        versionInfoLabel.font = UIFont.systemFont(ofSize: 11)

        view.addSubview(versionInfoLabel)

        versionInfoLabel.translatesAutoresizingMaskIntoConstraints = false
        versionInfoLabel.fitInSuperview(with: EdgeInsets(top: 80, leading: 24, bottom: 24, trailing: 24))

        var versionString: String = ""

        let dictKeySorted = carthageInfo.sorted(by: <)

        for (dependency, version) in dictKeySorted {
            versionString += "\n\(dependency) \(version)"
        }

        versionInfoLabel.text = versionString
    }

    @objc
    private func closeButtonTapped(_ close: Any?) {
        dismiss(animated: true)
    }
}
