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

@testable import Wire
import FBSnapshotTestCase
import UIKit

extension UITableViewCell: UITableViewDelegate, UITableViewDataSource {
    func wrapInTableView() -> UITableView {
        let tableView = UITableView(frame: self.bounds, style: .plain)

        tableView.delegate = self
        tableView.dataSource = self
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.rowHeight = UITableView.automaticDimension
        tableView.layoutMargins = self.layoutMargins

        let size = self.systemLayoutSizeFitting(CGSize(width: bounds.width, height: 0.0), withHorizontalFittingPriority: .required, verticalFittingPriority: .fittingSizeLevel)
        self.layoutSubviews()

        self.bounds = CGRect(x: 0.0, y: 0.0, width: size.width, height: size.height)
        self.contentView.bounds = self.bounds

        tableView.reloadData()
        tableView.bounds = self.bounds
        tableView.layoutIfNeeded()

        NSLayoutConstraint.activate([
            tableView.heightAnchor.constraint(equalToConstant: size.height)
            ])

        self.layoutSubviews()
        return tableView
    }

    public func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }

    public func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return self.bounds.size.height
    }

    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        return self
    }
}

class ZMSnapshotTestCase: FBSnapshotTestCase {

    typealias ConfigurationWithDeviceType = (_ view: UIView, _ isPad: Bool) -> Void
    typealias Configuration = (_ view: UIView) -> Void

    var uiMOC: NSManagedObjectContext!
    var coreDataStack: CoreDataStack!

    /// The color of the container view in which the view to
    /// be snapshot will be placed, defaults to UIColor.lightGrayColor
    var snapshotBackgroundColor: UIColor?

    /// If YES the uiMOC will have image and file caches. Defaults to NO.
    var needsCaches: Bool {
        return false
    }

    var documentsDirectory: URL?

    override open func setUp() {
        super.setUp()

        XCTAssertEqual(UIScreen.main.scale, 2, "Snapshot tests need to be run on a device with a 2x scale")
        if UIDevice.current.systemVersion.compare("13", options: .numeric, range: nil, locale: .current) == .orderedAscending {
            XCTFail("Snapshot tests need to be run on a device running at least iOS 13")
        }
        AppRootRouter.configureAppearance()
        UIView.setAnimationsEnabled(false)
        accentColor = .vividRed
        snapshotBackgroundColor = UIColor.clear

        // Enable when the design of the view has changed in order to update the reference snapshots
        recordMode = strcmp(getenv("RECORDING_SNAPSHOTS"), "YES") == 0

        usesDrawViewHierarchyInRect = true

        do {
            documentsDirectory = try FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        } catch {
            XCTAssertNil(error, "Unexpected error \(error)")
        }

        let account = Account(userName: "", userIdentifier: UUID())
        let coreDataStack = CoreDataStack(account: account,
                                          applicationContainer: documentsDirectory!,
                                          inMemoryStore: true)

        coreDataStack.loadStores(completionHandler: { error in
            XCTAssertNil(error)
        })
        self.coreDataStack = coreDataStack
        self.uiMOC = coreDataStack.viewContext

        if needsCaches {
            setUpCaches()
        }
    }

    override open func tearDown() {
        if needsCaches {
            wipeCaches()
        }
        // Needs to be called before setting self.documentsDirectory to nil.
        removeContentsOfDocumentsDirectory()
        uiMOC = nil
        coreDataStack = nil
        documentsDirectory = nil
        snapshotBackgroundColor = nil
        UIColor.setAccentOverride(.undefined)
        UIView.setAnimationsEnabled(true)
        super.tearDown()
    }

    func removeContentsOfDocumentsDirectory() {
        do {
            let contents = try FileManager.default.contentsOfDirectory(at: documentsDirectory!, includingPropertiesForKeys: nil, options: .skipsHiddenFiles)

            for content: URL in contents {
                do {
                    try FileManager.default.removeItem(at: content)
                } catch {
                    XCTAssertNil(error, "Unexpected error \(error)")
                }
            }

        } catch {
            XCTAssertNil(error, "Unexpected error \(error)")
        }

    }

    func wipeCaches() {
        uiMOC.zm_fileAssetCache.wipeCaches()
        uiMOC.zm_userImageCache.wipeCache()
        PersonName.stringsToPersonNames().removeAllObjects()
    }

    func setUpCaches() {
        uiMOC.zm_userImageCache = UserImageLocalCache(location: nil)
        uiMOC.zm_fileAssetCache = FileAssetCache(location: nil)
    }

}

// MARK: - Helpers
extension ZMSnapshotTestCase {

    private func snapshotVerify(view: UIView,
                                identifier: String? = nil,
                                suffix: NSOrderedSet? = FBSnapshotTestCaseDefaultSuffixes(),
                                tolerance: CGFloat = tolerance,
                                file: StaticString = #file,
                                line: UInt = #line) {
        let errorDescription = snapshotVerifyViewOrLayer(view,
                                                            identifier: identifier,
                                                            suffixes: suffix!,
                                                            overallTolerance: tolerance,
                                                            defaultReferenceDirectory: (FB_REFERENCE_IMAGE_DIR),
                                                            defaultImageDiffDirectory: (IMAGE_DIFF_DIR))

        if errorDescription.count > 0 {
            XCTFail("\(errorDescription)", file: file, line: line)
        } else {
            XCTAssert(true)
        }
    }

    private func assertAmbigousLayout(_ view: UIView,
                                      file: StaticString = #file,
                                      line: UInt = #line) {
        if view.hasAmbiguousLayout,
            let trace = view._autolayoutTrace() {
            let description = "Ambigous layout in view: \(view) trace: \n\(trace)"

            recordFailure(withDescription: description, inFile: "\(file)", atLine: Int(line), expected: true)

        }
    }

    private func assertEmptyFrame(_ view: UIView,
                                  file: StaticString = #file,
                                  line: UInt = #line) -> Bool {
        if view.frame.isEmpty {
            let description = "View frame can not be empty"
            let filePath = "\(file)"
            recordFailure(withDescription: description, inFile: filePath, atLine: Int(line), expected: true)
            return true
        }
        return false
    }
}

// MARK: - interfaces

extension ZMSnapshotTestCase {

    func finalIdentifier(deviceName: String?, identifier: String?) -> String? {
        var finalIdentifier: String?

        if 0 == (identifier?.count ?? 0) {
            if let deviceName = deviceName,
                deviceName.count > 0 {
                finalIdentifier = deviceName
            }
        } else {
            if let deviceName = deviceName,
                deviceName.count > 0 {
                finalIdentifier = "\(identifier ?? "")-\(deviceName)"
            } else {
                finalIdentifier = "\(identifier ?? "")"
            }
        }

        return finalIdentifier
    }

    /// Performs an assertion with the given view and the recorded snapshot.
    func verify(view: UIView,
                extraLayoutPass: Bool = false,
                tolerance: CGFloat = tolerance,
                identifier: String? = nil,
                deviceName: String? = nil,
                file: StaticString = #file,
                line: UInt = #line
        ) {
        let container = containerView(with: view, snapshotBackgroundColor: snapshotBackgroundColor)
        if assertEmptyFrame(container, file: file, line: line) {
            return
        }

        let identifier = finalIdentifier(deviceName: deviceName, identifier: identifier)

        if extraLayoutPass {
            RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.1))
        }

        view.layer.speed = 0 // freeze animations for deterministic tests
        snapshotVerify(view: container,
                       identifier: identifier,
                       suffix: FBSnapshotTestCaseDefaultSuffixes(),
                       tolerance: tolerance,
                       file: file,
                       line: line)

        assertAmbigousLayout(container, file: file, line: line)
    }

    static let tolerance: CGFloat = 0.3
    /// Performs an assertion with the given view and the recorded snapshot with the custom width
    func verifyView(view: UIView,
                    extraLayoutPass: Bool = false,
                    width: CGFloat,
                    tolerance: CGFloat = tolerance,
                    identifier: String? = nil,
                    configuration: ((UIView) -> Swift.Void)? = nil,
                    file: StaticString = #file,
                    line: UInt = #line
        ) {
        let container = containerView(with: view, snapshotBackgroundColor: snapshotBackgroundColor)

        container.addWidthConstraint(width: width)

        if assertEmptyFrame(container, file: file, line: line) {
            return
        }

        configuration?(view)

        if extraLayoutPass {
            RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.1))
        }

        view.layer.speed = 0 // freeze animations for deterministic tests

        let identifier = finalIdentifier(deviceName: "\(Int(width))", identifier: identifier)

        snapshotVerify(view: container,
                       identifier: identifier,
                       tolerance: tolerance,
                       file: file,
                       line: line)
    }

    func verifyInAllPhoneWidths(view: UIView,
                                extraLayoutPass: Bool = false,
                                tolerance: CGFloat = tolerance,
                                configuration: ((UIView) -> Swift.Void)? = nil,
                                file: StaticString = #file,
                                line: UInt = #line) {
        assertAmbigousLayout(view, file: file, line: line)
        for width in phoneWidths() {
            verifyView(view: view,
                       extraLayoutPass: extraLayoutPass,
                       width: width,
                       tolerance: tolerance,
                       configuration: configuration,
                       file: file,
                       line: line)
        }
    }

    func verifyInAllTabletWidths(view: UIView,
                                 extraLayoutPass: Bool = false,
                                 configuration: ((UIView) -> Swift.Void)? = nil,
                                 file: StaticString = #file,
                                 line: UInt = #line) {
        assertAmbigousLayout(view, file: file, line: line)
        for width in tabletWidths() {
            verifyView(view: view,
                       extraLayoutPass: extraLayoutPass,
                       width: width,
                       configuration: configuration,
                       file: file,
                       line: line)
        }
    }

    /// verify the snapshot with default iphone size
    ///
    /// - Parameters:
    ///   - view: the view to verify
    ///   - size: the customize view size, default is iPhone 4-inch's size
    ///   - file: source file
    ///   - line: source line
    func verifyInIPhoneSize(view: UIView,
                            extraLayoutPass: Bool = false,
                            size: CGSize = XCTestCase.DeviceSizeIPhone5,
                            file: StaticString = #file,
                            line: UInt = #line) {
        view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            view.heightAnchor.constraint(equalToConstant: size.height),
            view.widthAnchor.constraint(equalToConstant: size.width)
            ])

        view.layoutIfNeeded()

        verify(view: view,
               extraLayoutPass: extraLayoutPass,
               file: file,
               line: line)
    }

    // MARK: - verify the snapshots in both dark and light scheme

    func verifyInAllColorSchemes(view: UIView,
                                 tolerance: CGFloat = tolerance,
                                 file: StaticString = #file,
                                 line: UInt = #line) {
        if var themeable = view as? Themeable {
            themeable.colorSchemeVariant = .light
            snapshotBackgroundColor = .white
            verify(view: view, tolerance: tolerance, identifier: "LightTheme", file: file, line: line)
            themeable.colorSchemeVariant = .dark
            snapshotBackgroundColor = .black
            verify(view: view, tolerance: tolerance, identifier: "DarkTheme", file: file, line: line)
        } else {
            XCTFail("View doesn't support Themable protocol")
        }
    }

    func verifySafeAreas(
        viewController: UIViewController,
        tolerance: Float = 0,
        file: StaticString = #file,
        line: UInt = #line
        ) {
        viewController.additionalSafeAreaInsets = UIEdgeInsets(top: 44, left: 0, bottom: 34, right: 0)
        viewController.viewSafeAreaInsetsDidChange()
        viewController.view.frame = CGRect(x: 0, y: 0, width: 375, height: 812)
        verify(view: viewController.view)
    }

    // MARK: - verify the snapshots in multiple devices

    /// Performs multiple assertions with the given view using the screen sizes of
    /// the common iPhones in Portrait and iPad in Landscape and Portrait.
    /// This method only makes sense for views that will be on presented fullscreen.
    func verifyMultipleSize(view: UIView,
                            extraLayoutPass: Bool,
                            inSizes sizes: [String: CGSize],
                            configuration: ConfigurationWithDeviceType?,
                            file: StaticString = #file,
                            line: UInt = #line) {
        for (deviceName, size) in sizes {
            view.frame = CGRect(origin: .zero, size: size)
            if let configuration = configuration {
                let isIPad = XCTestCase.tabletScreenSizes.values.contains(size)
                UIView.performWithoutAnimation({
                    configuration(view, isIPad)
                })
            }

            verify(view: view,
                   extraLayoutPass: extraLayoutPass,
                   deviceName: deviceName,
                   file: file,
                   line: line)
        }
    }

    func verifyInAllIPhoneSizes(view: UIView,
                                extraLayoutPass: Bool = false,
                                configuration: Configuration? = nil,
                                file: StaticString = #file,
                                line: UInt = #line) {
        verifyMultipleSize(view: view, extraLayoutPass: extraLayoutPass, inSizes: XCTestCase.phoneScreenSizes, configuration: { view, _ in
            configuration?(view)
        }, file: file, line: line)
    }

    func verifyInAllDeviceSizes(view: UIView,
                                extraLayoutPass: Bool = false,
                                file: StaticString = #file,
                                line: UInt = #line,
                                configuration: ConfigurationWithDeviceType? = nil) {

        verifyMultipleSize(view: view,
                           extraLayoutPass: extraLayoutPass,
                           inSizes: XCTestCase.deviceScreenSizes,
                           configuration: configuration,
                           file: file,
                           line: line)
    }

}

// MARK: - test with different color schemes

extension ZMSnapshotTestCase {
    /// Performs multiple assertions with the given view using the screen widths of
    /// the common iPhones in Portrait.
    ///
    /// - Parameters:
    ///   - initialization: create the view to test in this closure
    ///   - extraLayoutPass: set to true for RunLoop run for extra 0.1 seconds
    ///   - tolerance: The percentage difference to still count as identical - 0 mean pixel perfect, 1 means I don't care
    ///   - configuration: configuration is executed after the view is finished layout.
    ///   - colorSchemes: the color schemes to snapshot, default is a empty set. If the set is empty, it will test without ColorScheme override. Valid values are [.light], [.dark] and [.light, .dark]
    ///   - file: source file
    ///   - line: source line
    func verifyInAllPhoneWidths(initialization: (() -> UIView),
                                extraLayoutPass: Bool = false,
                                tolerance: CGFloat = 0,
                                configuration: ((UIView) -> Swift.Void)? = nil,
                                colorSchemes: Set<ColorSchemeVariant> = [],
                                file: StaticString = #file,
                                line: UInt = #line) {

        let testClosure: (UIView, String?) -> Void = {view, identifier in
            self.assertAmbigousLayout(view, file: file, line: line)
            for width in self.phoneWidths() {
                self.verifyView(view: view,
                                extraLayoutPass: extraLayoutPass,
                                width: width,
                                tolerance: tolerance,
                                identifier: identifier,
                                configuration: configuration,
                                file: file,
                                line: line)
            }
        }

        switch colorSchemes {
        case [.light]:
            ColorScheme.default.variant = .light
            snapshotBackgroundColor = .white
            testClosure(initialization(), "light")
        case [.dark]:
            ColorScheme.default.variant = .dark
            snapshotBackgroundColor = .black
            testClosure(initialization(), "dark")
        case [.dark, .light]:
            for colorScheme in colorSchemes {
                ColorScheme.default.variant = colorScheme
                snapshotBackgroundColor = colorScheme == .dark ? .black : .white
                testClosure(initialization(), colorScheme == .dark ? "dark" : "light")
            }
        case[]:
            testClosure(initialization(), nil)
        default:
            break
        }

        /// restore to default light scheme
        ColorScheme.default.variant = .light
    }

    /// verify the snapshot with default iphone size in different color schemes
    ///
    /// - Parameters:
    ///   - initialization: create the view to test in this closure
    ///   - extraLayoutPass: set to true for RunLoop run for extra 0.1 seconds
    ///   - colorSchemes: the color schemes to snapshot, default is a empty set. If the set is empty, it will test without ColorScheme override. Valid values are [.light], [.dark] and [.light, .dark]
    ///   - file: source file
    ///   - line: source line
    func verifyInIPhoneSize(initialization: (() -> UIView),
                            extraLayoutPass: Bool = false,
                            colorSchemes: Set<ColorSchemeVariant> = [],
                            file: StaticString = #file,
                            line: UInt = #line) {

        let testClosure: (UIView, String?) -> Void = {view, identifier in

            view.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                view.heightAnchor.constraint(equalToConstant: self.defaultIPhoneSize.height),
                view.widthAnchor.constraint(equalToConstant: self.defaultIPhoneSize.width)
                ])

            view.layoutIfNeeded()

            self.verify(view: view,
                        extraLayoutPass: extraLayoutPass,
                        identifier: identifier,
                        file: file,
                        line: line)
        }

        switch colorSchemes {
        case [.light]:
            ColorScheme.default.variant = .light
            snapshotBackgroundColor = .white
            testClosure(initialization(), "light")
        case [.dark]:
            ColorScheme.default.variant = .dark
            snapshotBackgroundColor = .black
            testClosure(initialization(), "dark")
        case [.dark, .light]:
            for colorScheme in colorSchemes {
                ColorScheme.default.variant = colorScheme
                snapshotBackgroundColor = colorScheme == .dark ? .black : .white
                testClosure(initialization(), colorScheme == .dark ? "dark" : "light")
            }
        case[]:
            testClosure(initialization(), nil)
        default:
            break
        }

        /// restore to default light scheme
        ColorScheme.default.variant = .light
        snapshotBackgroundColor = UIColor.lightGray
    }

}
