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

import UIKit
import WireSyncEngine

class SettingsBaseTableViewController: UIViewController, SpinnerCapable {
    var dismissSpinner: SpinnerCompletion?

    var tableView: UITableView
    let topSeparator = OverflowSeparatorView()
    let footerSeparator = OverflowSeparatorView()
    private let footerContainer = UIView()

    var footer: UIView? {
        didSet {
            updateFooter(footer)
        }
    }

    final fileprivate class IntrinsicSizeTableView: UITableView {
        override var contentSize: CGSize {
            didSet {
                invalidateIntrinsicContentSize()
            }
        }

        override var intrinsicContentSize: CGSize {
            layoutIfNeeded()
            return CGSize(width: UIView.noIntrinsicMetric, height: contentSize.height)
        }
    }

    init(style: UITableView.Style) {
        tableView = IntrinsicSizeTableView(frame: .zero, style: style)
        super.init(nibName: nil, bundle: nil)
        self.edgesForExtendedLayout = UIRectEdge()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init?(coder aDecoder: NSCoder) is not implemented")
    }

    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        fatalError()
    }

    override func viewDidLoad() {
        self.createTableView()
        self.view.addSubview(self.topSeparator)
        self.createConstraints()
        self.view.backgroundColor = UIColor.clear
        super.viewDidLoad()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.tableView.reloadData()
    }

    private func createTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.separatorStyle = .none
        tableView.backgroundColor = SemanticColors.View.backgroundDefault
        tableView.clipsToBounds = true
        tableView.tableFooterView = UIView()
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 56
        view.addSubview(tableView)
        view.addSubview(footerContainer)
        footerContainer.addSubview(footerSeparator)
        footerSeparator.inverse = true
    }

    private func createConstraints() {
        [tableView, topSeparator, footerContainer, footerSeparator].prepareForLayout()

        let footerContainerHeightConstraint = footerContainer.heightAnchor.constraint(equalToConstant: 0)
        footerContainerHeightConstraint.priority = .defaultHigh

        NSLayoutConstraint.activate([
          tableView.leftAnchor.constraint(equalTo: view.leftAnchor),
          tableView.rightAnchor.constraint(equalTo: view.rightAnchor),
          tableView.topAnchor.constraint(equalTo: view.topAnchor),

          topSeparator.leftAnchor.constraint(equalTo: tableView.leftAnchor),
          topSeparator.rightAnchor.constraint(equalTo: tableView.rightAnchor),
          topSeparator.topAnchor.constraint(equalTo: tableView.topAnchor),

          footerContainer.topAnchor.constraint(equalTo: tableView.bottomAnchor),
          footerContainer.leftAnchor.constraint(equalTo: tableView.leftAnchor),
          footerContainer.rightAnchor.constraint(equalTo: tableView.rightAnchor),
          footerContainer.bottomAnchor.constraint(equalTo: view.bottomAnchor),
          footerContainerHeightConstraint,

          footerSeparator.leftAnchor.constraint(equalTo: footerContainer.leftAnchor),
          footerSeparator.rightAnchor.constraint(equalTo: footerContainer.rightAnchor),
          footerSeparator.topAnchor.constraint(equalTo: footerContainer.topAnchor)
        ])
    }

    private func updateFooter(_ newFooter: UIView?) {
        footer?.removeFromSuperview()
        footerSeparator.isHidden = newFooter == nil
        guard let newFooter = newFooter else { return }
        footerContainer.addSubview(newFooter)
        [footerContainer, newFooter].prepareForLayout()
        NSLayoutConstraint.activate([
            newFooter.topAnchor.constraint(equalTo: footerContainer.topAnchor),
            newFooter.bottomAnchor.constraint(equalTo: footerContainer.bottomAnchor),
            newFooter.leftAnchor.constraint(equalTo: footerContainer.leftAnchor),
            newFooter.rightAnchor.constraint(equalTo: footerContainer.rightAnchor)
        ])
    }
}

extension SettingsBaseTableViewController: UITableViewDelegate, UITableViewDataSource {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        self.topSeparator.scrollViewDidScroll(scrollView: scrollView)
        self.footerSeparator.scrollViewDidScroll(scrollView: scrollView)
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        fatalError("Subclasses need to implement this method")
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        fatalError("Subclasses need to implement this method")
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        fatalError("Subclasses need to implement this method")
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) { }

}

final class SettingsTableViewController: SettingsBaseTableViewController {

    let group: SettingsInternalGroupCellDescriptorType
    fileprivate var sections: [SettingsSectionDescriptorType]
    fileprivate var selfUserObserver: NSObjectProtocol!

    required init(group: SettingsInternalGroupCellDescriptorType) {
        self.group = group
        self.sections = group.visibleItems
        super.init(style: group.style == .plain ? .plain : .grouped)
        setupNavigationTitle()

        self.group.items.flatMap { return $0.cellDescriptors }.forEach {
            if let groupDescriptor = $0 as? SettingsGroupCellDescriptorType {
                groupDescriptor.viewController = self
            }
        }

        if let userSession = ZMUserSession.shared() {
            self.selfUserObserver = UserChangeInfo.add(observer: self, for: userSession.selfUser, in: userSession)
        }

        NotificationCenter.default.addObserver(self, selector: #selector(applicationDidBecomeActive), name: UIApplication.didBecomeActiveNotification, object: nil)
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init?(coder aDecoder: NSCoder) is not implemented")
    }

    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        fatalError()
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        setupTableView()
        setupNavigationBar()
    }

    private func setupTableView() {
        let allCellTypes: [SettingsTableCell.Type] = [
            SettingsTableCell.self,
            SettingsButtonCell.self,
            SettingsToggleCell.self,
            SettingsValueCell.self,
            SettingsTextCell.self,
            SettingsStaticTextTableCell.self,
            IconActionCell.self,
            SettingsProfileLinkCell.self
        ]

        for aClass in allCellTypes {
            tableView.register(aClass, forCellReuseIdentifier: aClass.reuseIdentifier)
        }
    }

    private func setupNavigationBar() {
        navigationItem.rightBarButtonItem = navigationController?.closeItem()
        setupAccessibility()
    }

    private func setupAccessibility() {
        typealias Accessibility = L10n.Accessibility.Settings

        navigationItem.rightBarButtonItem?.accessibilityLabel = Accessibility.CloseButton.description
        navigationItem.backBarButtonItem?.accessibilityLabel = Accessibility.BackButton.description(group.title)
    }

    func refreshData() {
        sections = group.visibleItems
        tableView.reloadData()
    }

    // MARK: - UITableViewDelegate & UITableViewDelegate

    override func numberOfSections(in tableView: UITableView) -> Int {
        return sections.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let sectionDescriptor = sections[section]
        return sectionDescriptor.visibleCellDescriptors.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let sectionDescriptor = sections[(indexPath as NSIndexPath).section]
        let cellDescriptor = sectionDescriptor.visibleCellDescriptors[(indexPath as NSIndexPath).row]

        if let cell = tableView.dequeueReusableCell(withIdentifier: type(of: cellDescriptor).cellType.reuseIdentifier, for: indexPath) as? SettingsTableCell {
            cell.descriptor = cellDescriptor
            cellDescriptor.featureCell(cell)
            return cell
        }

        fatalError("Cannot dequeue cell for index path \(indexPath) and cellDescriptor \(cellDescriptor)")
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let sectionDescriptor = sections[(indexPath as NSIndexPath).section]
        let property = sectionDescriptor.visibleCellDescriptors[(indexPath as NSIndexPath).row]

        property.select(SettingsPropertyValue.none)
        tableView.deselectRow(at: indexPath, animated: false)
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        let sectionDescriptor = sections[section]
        return sectionDescriptor.header
    }

    func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        let sectionDescriptor = sections[section]
        return sectionDescriptor.footer
    }

    func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        if let headerFooterView = view as? UITableViewHeaderFooterView {
            headerFooterView.textLabel?.textColor = SemanticColors.Label.textSectionHeader
        }
    }

    func tableView(_ tableView: UITableView, willDisplayFooterView view: UIView, forSection section: Int) {
        if let headerFooterView = view as? UITableViewHeaderFooterView {
            headerFooterView.textLabel?.textColor = SemanticColors.Label.textSectionFooter
        }
    }

    private func setupNavigationTitle() {
        let titleLabel = DynamicFontLabel(
            text: group.title.localized,
            fontSpec: .headerSemiboldFont,
            color: SemanticColors.Label.textDefault)
        navigationItem.titleView = titleLabel
    }

}

extension SettingsTableViewController {

    @objc
    func applicationDidBecomeActive() {
        refreshData()
    }

}

extension SettingsTableViewController: ZMUserObserver {
    func userDidChange(_ note: UserChangeInfo) {
        if note.accentColorValueChanged {
            refreshData()
        }
    }
}
