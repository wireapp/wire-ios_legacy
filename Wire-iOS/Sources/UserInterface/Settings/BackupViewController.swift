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

import UIKit
import Foundation
import WireSyncEngine
import WireCommonComponents

final class BackupStatusCell: UITableViewCell {
    let descriptionLabel: DynamicFontLabel = {
        let label = DynamicFontLabel(fontSpec: .normalRegularFont,
                                     color: .textForeground,
                                     variant: .dark)
        label.textColor = SemanticColors.Label.textDefault
        label.textAlignment = .left
        label.numberOfLines = 0
        return label
    }()
    let iconView = UIImageView()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        selectionStyle = .none
        backgroundColor = .clear
        contentView.backgroundColor = .clear

        iconView.tintColor = SemanticColors.Label.textDefault
        iconView.setTemplateIcon(.restore, size: .large)
        iconView.contentMode = .center
        iconView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(iconView)

        descriptionLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(descriptionLabel)

        NSLayoutConstraint.activate([
            iconView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 24),
            iconView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            iconView.heightAnchor.constraint(equalTo: iconView.widthAnchor),
            iconView.widthAnchor.constraint(equalToConstant: 48),
            descriptionLabel.topAnchor.constraint(equalTo: iconView.bottomAnchor, constant: 24),
            descriptionLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            descriptionLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24),
            descriptionLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -24)
        ])

        descriptionLabel.attributedText = L10n.Localizable.Self.Settings.HistoryBackup.description && .paragraphSpacing(2)
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

final class BackupActionCell: UITableViewCell {
    let actionTitleLabel: DynamicFontLabel = {
        let label = DynamicFontLabel(text: L10n.Localizable.Self.Settings.HistoryBackup.action,
                                     fontSpec: .normalRegularFont,
                                     color: .textForeground,
                                     variant: .dark)
        label.textColor = SemanticColors.Label.textDefault
        label.textAlignment = .left
        return label
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        backgroundColor = SemanticColors.View.backgroundUserCell
        contentView.backgroundColor = .clear

        actionTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(actionTitleLabel)
        NSLayoutConstraint.activate([
            actionTitleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            actionTitleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24),
            actionTitleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 0),
            actionTitleLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: 0)
        ])
        actionTitleLabel.heightAnchor.constraint(equalToConstant: 44).isActive = true
        addBorder(for: .bottom)
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

protocol BackupSource {
    func backupActiveAccount(password: Password, completion: @escaping SessionManager.BackupResultClosure)
}

extension SessionManager: BackupSource {
    func backupActiveAccount(password: Password, completion: @escaping SessionManager.BackupResultClosure) {
        backupActiveAccount(password: password.value, completion: completion)
    }
}

final class BackupViewController: UIViewController, SpinnerCapable {
    var dismissSpinner: SpinnerCompletion?

    fileprivate let tableView = UITableView(frame: .zero)
    fileprivate var cells: [UITableViewCell.Type] = []
    let backupSource: BackupSource

    init(backupSource: BackupSource) {
        self.backupSource = backupSource
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = L10n.Localizable.Self.Settings.HistoryBackup.title.localizedUppercase
        setupViews()
        setupLayout()
    }

    private func setupViews() {
        view.backgroundColor = .clear

        tableView.isScrollEnabled = false
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 80
        tableView.backgroundColor = .clear
        tableView.separatorColor = UIColor(white: 1, alpha: 0.1)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tableView)
        tableView.delegate = self
        tableView.dataSource = self

        // this is necessary to remove the placeholder cells
        tableView.tableFooterView = UIView()
        cells = [BackupStatusCell.self, BackupActionCell.self]

        cells.forEach {
            tableView.register($0.self, forCellReuseIdentifier: $0.reuseIdentifier)
        }
    }

    private func setupLayout() {
        tableView.fitIn(view: view)
    }

    var loadingHostController: SpinnerCapableViewController {
        return (navigationController as? SpinnerCapableViewController) ?? self
    }
}

// MARK: - UITableViewDataSource & UITableViewDelegate

extension BackupViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        return tableView.dequeueReusableCell(withIdentifier: cells[indexPath.row].reuseIdentifier, for: indexPath)
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return cells.count
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard indexPath.row == 1 else { return }
        backupActiveAccount(indexPath: indexPath)
    }
}

// MARK: - Backup Logic

fileprivate extension BackupViewController {

    func backupActiveAccount(indexPath: IndexPath) {
        requestBackupPassword { [weak self] result in
            guard let `self` = self, let password = result else { return }
            self.loadingHostController.isLoadingViewVisible = true

            self.backupSource.backupActiveAccount(password: password) { backupResult in
                self.loadingHostController.isLoadingViewVisible = false

                switch backupResult {
                case .failure(let error):
                    self.presentAlert(for: error)
                    BackupEvent.exportFailed.track()
                case .success(let url):
                    self.presentShareSheet(with: url, from: indexPath)
                }
            }
        }
    }

    private func presentAlert(for error: Error) {
        let alert = UIAlertController(
            title: L10n.Localizable.Self.Settings.HistoryBackup.Error.title,
            message: error.localizedDescription,
            alertAction: .ok(style: .cancel))
        present(alert, animated: true)
    }

    private func presentShareSheet(with url: URL, from indexPath: IndexPath) {
        let activityController = UIActivityViewController(activityItems: [url], applicationActivities: nil)
        activityController.completionWithItemsHandler = { _, _, _, _ in
            SessionManager.clearPreviousBackups()
        }
        activityController.popoverPresentationController.apply {
            $0.sourceView = tableView
            $0.sourceRect = tableView.rectForRow(at: indexPath)
        }
        self.present(activityController, animated: true)
    }
}
