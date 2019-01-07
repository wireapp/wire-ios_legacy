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

final class BackupStatusCell: UITableViewCell {
    let descriptionLabel = UILabel()
    let iconView = UIImageView()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        selectionStyle = .none
        backgroundColor = .clear
        contentView.backgroundColor = .clear
        
        let color = UIColor.from(scheme: .textForeground, variant: .dark)
        
        iconView.image = .imageForRestore(with: color, size: .large)
        iconView.contentMode = .center
        iconView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(iconView)
        
        descriptionLabel.translatesAutoresizingMaskIntoConstraints = false
        descriptionLabel.numberOfLines = 0
        contentView.addSubview(descriptionLabel)
        
        NSLayoutConstraint.activate([
            iconView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 24),
            iconView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            iconView.heightAnchor.constraint(equalTo: iconView.widthAnchor),
            iconView.widthAnchor.constraint(equalToConstant: 48),
            descriptionLabel.topAnchor.constraint(equalTo: iconView.bottomAnchor, constant: 24),
            descriptionLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            descriptionLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24),
            descriptionLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -24),
        ])
        
        descriptionLabel.attributedText = "self.settings.history_backup.description".localized && .paragraphSpacing(2)
        descriptionLabel.font = .systemFont(ofSize: 14)
        descriptionLabel.textColor = color
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

final class BackupActionCell: UITableViewCell {
    let actionTitleLabel = UILabel()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        selectionStyle = .none
        backgroundColor = .clear
        contentView.backgroundColor = .clear
        
        actionTitleLabel.textAlignment = .left
        actionTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(actionTitleLabel)
        actionTitleLabel.fitInSuperview(with: EdgeInsets(top: 0, leading: 24, bottom: 0, trailing: 24))
        
        actionTitleLabel.heightAnchor.constraint(equalToConstant: 44).isActive = true
        
        actionTitleLabel.text = "self.settings.history_backup.action".localized
        actionTitleLabel.font = FontSpec(.normal, .regular).font
        actionTitleLabel.textColor = UIColor.from(scheme: .textForeground, variant: .dark)
    }
    
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

final class BackupViewController: UIViewController {
    fileprivate let tableView = UITableView(frame: .zero)
    fileprivate var cells: [UITableViewCell.Type] = []
    let backupSource: BackupSource
    
    init(backupSource: BackupSource) {
        self.backupSource = backupSource
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "self.settings.history_backup.title".localized.uppercased()
        setupViews()
        setupLayout()
    }
    
    override var prefersStatusBarHidden: Bool {
        return false
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        UIApplication.shared.wr_updateStatusBarForCurrentControllerAnimated(animated)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        UIApplication.shared.wr_updateStatusBarForCurrentControllerAnimated(animated)
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
        tableView.fitInSuperview()
    }
    
    var loadingHostController: UIViewController {
        return navigationController ?? self
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

    fileprivate func backupActiveAccount(indexPath: IndexPath) {
        requestBackupPassword { [weak self] result in
            guard let `self` = self, let password = result else { return }
            self.loadingHostController.showLoadingView = true

            self.backupSource.backupActiveAccount(password: password) { backupResult in
                self.loadingHostController.showLoadingView = false
                
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
            title: "self.settings.history_backup.error.title".localized,
            message: error.localizedDescription,
            cancelButtonTitle: "general.ok".localized
        )
        present(alert, animated: true)
    }
    
    private func presentShareSheet(with url: URL, from indexPath: IndexPath) {
        #if arch(i386) || arch(x86_64)
            let tmpURL = URL(fileURLWithPath: "/var/tmp/").appendingPathComponent(url.lastPathComponent)
            try! FileManager.default.moveItem(at: url, to: tmpURL)
        #else
            let activityController = UIActivityViewController(activityItems: [url], applicationActivities: nil)
            activityController.completionWithItemsHandler = { _, _, _, _ in
                SessionManager.clearPreviousBackups()
            }
            activityController.popoverPresentationController.apply {
                $0.sourceView = tableView
                $0.sourceRect = tableView.rectForRow(at: indexPath)
            }
            self.present(activityController, animated: true)
        #endif
        BackupEvent.exportSucceeded.track()
    }
}
