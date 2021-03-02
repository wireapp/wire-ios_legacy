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
import WireUtilities

struct Password {
    let value: String

    init?(_ value: String) {
        if case PasswordValidationResult.valid = PasswordRuleSet.shared.validatePassword(value) {
            self.value = value
        } else {
            return nil
        }
    }
}

extension BackupViewController {
    func requestBackupPassword(completion: @escaping (Password?) -> Void) {
        let passwordController = BackupPasswordViewController { controller, password in
            controller.dismiss(animated: true) {
                completion(password)
            }
        }
        let navigationController = KeyboardAvoidingViewController(viewController: passwordController).wrapInNavigationController()
        navigationController.modalPresentationStyle = .formSheet
        present(navigationController, animated: true, completion: nil)
    }
}

final class BackupPasswordViewController: UIViewController {

    typealias Completion = (BackupPasswordViewController, Password?) -> Void
    var completion: Completion?

    fileprivate var password: Password?
    private let passwordView = SimpleTextField()

    private let subtitleLabel = UILabel(
        key: "self.settings.history_backup.password.description",
        size: .medium,
        weight: .regular,
        color: .textDimmed,
        variant: .light
    )

    private let passwordRulesLabel = UILabel(key: nil,
                                             size: .medium,
                                             weight: .regular,
                                             color: .textDimmed,
                                             variant: .light)

    init(completion: @escaping Completion) {
        self.completion = completion
        super.init(nibName: nil, bundle: nil)
        setupViews()
        createConstraints()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setupNavigationBar()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        passwordView.becomeFirstResponder()
    }

    override public var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return wr_supportedInterfaceOrientations
    }

    private func setupViews() {
        view.backgroundColor = UIColor.from(scheme: .contentBackground, variant: .light)

        subtitleLabel.numberOfLines = 0

        passwordRulesLabel.numberOfLines = 0
        passwordRulesLabel.text = PasswordRuleSet.localizedErrorMessage

        [passwordView, subtitleLabel, passwordRulesLabel].forEach {
            view.addSubview($0)
            $0.translatesAutoresizingMaskIntoConstraints = false
        }

        passwordView.colorSchemeVariant = .light
        passwordView.placeholder = "self.settings.history_backup.password.placeholder".localized.localizedUppercase
        passwordView.accessibilityIdentifier = "password input"
        passwordView.returnKeyType = .done
        passwordView.isSecureTextEntry = true
        passwordView.delegate = self
    }

    private func createConstraints() {
        NSLayoutConstraint.activate([
            passwordView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            passwordView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            passwordView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            passwordView.heightAnchor.constraint(equalToConstant: 56),
            subtitleLabel.bottomAnchor.constraint(equalTo: passwordView.topAnchor, constant: -16),
            subtitleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            subtitleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            passwordRulesLabel.topAnchor.constraint(equalTo: passwordView.bottomAnchor, constant: 16),
            passwordRulesLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            passwordRulesLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16)
        ])
    }

    private func setupNavigationBar() {
        navigationController?.navigationBar.backgroundColor = UIColor.from(scheme: .barBackground, variant: .light)
        navigationController?.navigationBar.setBackgroundImage(.singlePixelImage(with: UIColor.from(scheme: .barBackground, variant: .light)), for: .default)
        navigationController?.navigationBar.tintColor = UIColor.from(scheme: .textForeground, variant: .light)
        navigationController?.navigationBar.barTintColor = UIColor.from(scheme: .textForeground, variant: .light)
        navigationController?.navigationBar.titleTextAttributes = DefaultNavigationBar.titleTextAttributes(for: .light)

        title = "self.settings.history_backup.password.title".localized(uppercased: true)
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            title: "self.settings.history_backup.password.cancel".localized(uppercased: true),
            style: .plain,
            target: self,
            action: #selector(cancel)
        )
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "self.settings.history_backup.password.next".localized(uppercased: true),
            style: .done,
            target: self,
            action: #selector(completeWithCurrentResult)
        )
        navigationItem.rightBarButtonItem?.tintColor = .accent()
        navigationItem.rightBarButtonItem?.isEnabled = false
    }

    fileprivate func updateState(with text: String) {
        password = Password(text)
        navigationItem.rightBarButtonItem?.isEnabled = nil != password
    }

    @objc dynamic fileprivate func cancel() {
        completion?(self, nil)
    }

    @objc dynamic fileprivate func completeWithCurrentResult() {
        completion?(self, password)
    }
}

extension BackupPasswordViewController: UITextFieldDelegate {
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {

        if string.containsCharacters(from: .whitespaces) {
            return false
        }

        if string.containsCharacters(from: .newlines) {
            if let _ = password {
                completeWithCurrentResult()
            }
            return false
        }

        let newString = ((textField.text ?? "") as NSString).replacingCharacters(in: range, with: string)

        self.updateState(with: newString)

        return true
    }
}
