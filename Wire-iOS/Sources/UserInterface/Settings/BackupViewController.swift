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

final class BackupStatusCell: UITableViewCell {
    let descriptionLabel = UILabel()
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        selectionStyle = .none
        backgroundColor = .clear
        contentView.backgroundColor = .clear
        
        descriptionLabel.translatesAutoresizingMaskIntoConstraints = false
        descriptionLabel.numberOfLines = 0
        contentView.addSubview(descriptionLabel)
        descriptionLabel.fitInSuperview(with: EdgeInsets(margin: 24))
        
        descriptionLabel.text = "self.settings.history_backup.description".localized
        descriptionLabel.font = FontSpec(.normal, .light).font
        descriptionLabel.textColor = ColorScheme.default().color(withName: ColorSchemeColorTextForeground, variant: .dark)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

final class BackupActionCell: UITableViewCell {
    let actionTitleLabel = UILabel()
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        selectionStyle = .none
        backgroundColor = .clear
        contentView.backgroundColor = .clear
        
        actionTitleLabel.textAlignment = .center
        actionTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(actionTitleLabel)
        actionTitleLabel.fitInSuperview()
        
        actionTitleLabel.heightAnchor.constraint(equalToConstant: 44).isActive = true
        
        actionTitleLabel.text = "self.settings.history_backup.action".localized
        actionTitleLabel.font = FontSpec(.medium, .light).font
        actionTitleLabel.textColor = ColorScheme.default().color(withName: ColorSchemeColorTextForeground, variant: .dark)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

final class BackupViewController: UIViewController {
    fileprivate let tableView = UITableView(frame: .zero)
    fileprivate var cells: [UITableViewCell.Type] = []
    fileprivate let documentDelegate = DocumentDelegate()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "self.settings.history_backup.title".localized.uppercased()
        setupViews()
        setupLayout()
    }
    
    private func setupViews() {
        view.backgroundColor = .clear
        
        tableView.rowHeight = UITableViewAutomaticDimension
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
}

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
        
        guard indexPath.row == 1 else {
            return
        }
        
        guard let sessionManager = SessionManager.shared else {
            fatal("Session manager is missing")
        }
        
        self.showLoadingView = true

        sessionManager.backupActiveAccount { result in
            self.showLoadingView = false
            
            switch result {
            case .failure(let error):
                let alert = UIAlertController(title: "self.settings.history_backup.error.title".localized,
                                              message: error.localizedDescription,
                                              cancelButtonTitle: "general.ok".localized)
                self.present(alert, animated: true)
            case .success(let url):
                let shareDatabaseDocumentController = UIDocumentInteractionController(url: url)
                shareDatabaseDocumentController.delegate = self.documentDelegate
                shareDatabaseDocumentController.presentPreview(animated: true)
            }
        }
    }
}


