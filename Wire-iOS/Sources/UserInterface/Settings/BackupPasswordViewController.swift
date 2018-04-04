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

final class BackupPasswordViewController: UIViewController {
    
    struct HistoryPassword {
        static fileprivate let minimumCharacters = 8
        let value: String

        init?(_ value: String) {
            guard value.count >= HistoryPassword.minimumCharacters else { return nil }
            self.value = value
        }
    }
    
    typealias Completion = (BackupPasswordViewController, HistoryPassword?) -> Void
    var completion: Completion?
    
    private var password: HistoryPassword?
    private let passwordView = PasswordView()
    private let subtitleLabel = UILabel(
        key: "self.settings.history_backup.password.description",
        size: .medium, // TODO
        weight: .regular, // TODO
        color: ColorSchemeColorTextDimmed, // TODO
        variant: .light // TODO
    )
    
    init(completion: @escaping Completion) {
        self.completion = completion
        super.init(nibName: nil, bundle: nil)
        setupViews()
        createConstraints()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupViews() {
        title = "self.settings.history_backup.password.title".localized.uppercased()
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            title: "self.settings.history_backup.password.cancel".localized,
            style: .plain,
            target: self,
            action: #selector(completeWithCurrentResult)
        )
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "self.settings.history_backup.password.next".localized,
            style: .done,
            target: self,
            action: #selector(completeWithCurrentResult)
        )
        passwordView.textDidChange = { [unowned self] text in
            self.updateState(with: text)
        }
    }
    
    private func createConstraints() {
        NSLayoutConstraint.activate([
            passwordView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            passwordView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            passwordView.topAnchor.constraint(equalTo: view.topAnchor, constant: 32),
            subtitleLabel.topAnchor.constraint(equalTo: passwordView.topAnchor, constant: 16),
            subtitleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            subtitleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
    }
    
    private func updateState(with text: String) {
        password = HistoryPassword(text)
        navigationItem.rightBarButtonItem?.isEnabled = nil != password
    }
    
    @objc private func completeWithCurrentResult() {
        completion?(self, password)
    }
    
}

fileprivate class PasswordView: UIView {
    typealias TextChange = (String) -> Void
    var textDidChange: TextChange?
    var text = "" {
        didSet {
            textDidChange?(text)
        }
    }
    
    private let textField = UITextField()
    private let topSeparator = UIView()
    private let bottomSeparator = UIView()
    
    init() {
        super.init(frame: .zero)
        setupViews()
        createConstraints()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupViews() {
        NotificationCenter.default.addObserver(self, selector: #selector(textFieldTextDidChange), name: .UITextFieldTextDidChange, object: textField)
        [topSeparator, textField, bottomSeparator].forEach {
            addSubview($0)
            $0.translatesAutoresizingMaskIntoConstraints = false
        }
    }
    
    private func createConstraints() {
        NSLayoutConstraint.activate([
            topSeparator.leadingAnchor.constraint(equalTo: leadingAnchor),
            topSeparator.topAnchor.constraint(equalTo: topAnchor),
            topSeparator.trailingAnchor.constraint(equalTo: trailingAnchor),
            topSeparator.heightAnchor.constraint(equalToConstant: .hairline),
            bottomSeparator.leadingAnchor.constraint(equalTo: leadingAnchor),
            bottomSeparator.bottomAnchor.constraint(equalTo: bottomAnchor),
            bottomSeparator.trailingAnchor.constraint(equalTo: trailingAnchor),
            bottomSeparator.heightAnchor.constraint(equalToConstant: .hairline),
            textField.leadingAnchor.constraint(equalTo: leadingAnchor),
            textField.topAnchor.constraint(equalTo: topSeparator.bottomAnchor),
            textField.trailingAnchor.constraint(equalTo: trailingAnchor),
            textField.bottomAnchor.constraint(equalTo: bottomSeparator.topAnchor),
            textField.heightAnchor.constraint(equalToConstant: 56)
        ])
    }
    
    @objc private func textFieldTextDidChange(_ sender: UITextField) {
        guard sender === textField else { return }
        text = sender.text ?? ""
    }
    
}
