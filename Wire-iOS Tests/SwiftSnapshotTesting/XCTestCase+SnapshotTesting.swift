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

import XCTest
import SnapshotTesting
@testable import Wire
import UIKit

extension ViewImageConfig: Hashable {
    public static func == (lhs: ViewImageConfig, rhs: ViewImageConfig) -> Bool {
        return lhs.size == rhs.size && lhs.traits == rhs.traits
    }

    public func hash(into hasher: inout Hasher) {
        if let size = size {
            hasher.combine(size.width)
            hasher.combine(size.height)
        }

        hasher.combine(traits)
    }
}

// MARK: - snapshoting all iPhone sizes
extension XCTestCase {
    /// snapshot file name suffixs
    static let phoneConfigNames: [SnapshotTesting.ViewImageConfig: String] = [
        .iPhoneSe: "iPhone-4_0_Inch",
        .iPhone8: "iPhone-4_7_Inch",
        .iPhone8Plus: "iPhone-5_5_Inch",
        .iPhoneX: "iPhone-5_8_Inch",
        .iPhoneXsMax: "iPhone-6_5_Inch"]

    static let padConfigNames: [SnapshotTesting.ViewImageConfig: String] = [
        .iPadMini(.landscape): "iPad-landscape",
        .iPadMini(.portrait): "iPad-portrait"]

    func verifyAllIPhoneSizes(matching value: UIViewController,
                              file: StaticString = #file,
                              testName: String = #function,
                              line: UInt = #line) {
        
        for(config, name) in XCTestCase.phoneConfigNames {
            verify(matching: value, as: .image(on: config), named: name,
                   file: file,
                   testName: testName,
                   line: line)
        }
    }
    

    func verifyAllIPhoneSizes(createSut: (CGSize) -> UIViewController,
                              file: StaticString = #file,
                              testName: String = #function,
                              line: UInt = #line) {

        for(config, name) in XCTestCase.phoneConfigNames {
            verify(matching: createSut(config.size!),
                   as: .image(on: config),
                   named: name,
                   file: file,
                   testName: testName,
                   line: line)
        }
    }

    func verifyInAllDeviceSizes(matching value: UIViewController,
                                file: StaticString = #file,
                                testName: String = #function,
                                line: UInt = #line) {

        let allDevices = XCTestCase.phoneConfigNames.merging(XCTestCase.padConfigNames) { (current, _) in current }

        for(config, name) in allDevices {
            if let deviceMockable = value as? DeviceMockable {
                (deviceMockable.device as? MockDevice)?.userInterfaceIdiom = config.traits.userInterfaceIdiom
            }

            verify(matching: value, as: .image(on: config), named: name,
                   file: file,
                   testName: testName,
                   line: line)
        }
    }

    func verifyInWidths(matching value: UIView,
                        widths: Set<CGFloat>,
                        snapshotBackgroundColor: UIColor,
                        named name: String? = nil,
                        file: StaticString = #file,
                        testName: String = #function,
                        line: UInt = #line) {
        let container = containerView(with: value,
                                      snapshotBackgroundColor: snapshotBackgroundColor)
        let widthConstraint = container.addWidthConstraint(width: 300)

        for width in widths {
            widthConstraint.constant = width

            let nameWithProperty: String
            if let name = name {
                nameWithProperty = "\(name)-\(width)"
            } else {
                nameWithProperty = "\(width)"
            }

            verify(matching: container,
                   named: nameWithProperty,
                   file: file,
                   testName: testName,
                   line: line)
        }
    }

    func verifyInAllPhoneWidths(matching value: UIView,
                                snapshotBackgroundColor: UIColor? = nil,
                                named name: String? = nil,
                                file: StaticString = #file,
                                testName: String = #function,
                                line: UInt = #line) {
        verifyInWidths(matching: value,
                       widths: phoneWidths(),
                       snapshotBackgroundColor: snapshotBackgroundColor ?? (ColorScheme.default.variant == .light ? .white : .black),
                       named: name,
                       file: file,
                       testName: testName,
                       line: line)
    }

    // MARK: - verify the snapshots in both dark and light scheme

    func verifyInAllColorSchemes(createSut: () -> UIViewController,
                                 file: StaticString = #file,
                                 testName: String = #function,
                                 line: UInt = #line) {
        verifyInDarkScheme(createSut: createSut,
                           name: "DarkTheme",
                           file: file,
                           testName: testName,
                           line: line)
        
        ColorScheme.default.variant = .light

        verify(matching: createSut(),
               named: "LightTheme",
               file: file,
               testName: testName,
               line: line)
    }

    func verifyInDarkScheme(createSut: () -> UIViewController,
                            name: String? = nil,
                            file: StaticString = #file,
                            testName: String = #function,
                            line: UInt = #line) {
        ColorScheme.default.variant = .dark
        
        verify(matching: createSut(),
               named: name,
               file: file,
               testName: testName,
               line: line)
    }

    func verifyInAllColorSchemes(matching: UIView,
                                 file: StaticString = #file,
                                 testName: String = #function,
                                 line: UInt = #line) {
        if var themeable = matching as? Themeable {
            themeable.colorSchemeVariant = .light

            verify(matching: matching,
                   named: "LightTheme",
                   file: file,
                   testName: testName,
                   line: line)
            themeable.colorSchemeVariant = .dark

            verify(matching: matching,
                   named: "DarkTheme",
                   file: file,
                   testName: testName,
                   line: line)
        } else {
            XCTFail("View doesn't support Themable protocol")
        }
    }

}

extension XCTestCase {
    func snapshotDirectory(file: StaticString = #file) -> String {
        let fileName = "\(file)"
        let path = ProcessInfo.processInfo.environment["SNAPSHOT_REFERENCE_DIR"]! + "/" + URL(fileURLWithPath: fileName).deletingPathExtension().lastPathComponent

        return path
    }

    /// verify for a UIAlertController
    func verify(matching value: UIAlertController,
                file: StaticString = #file,
                testName: String = #function,
                line: UInt = #line) {

        // Reset default tint color to keep constant snapshot result
        UIView.appearance(whenContainedInInstancesOf: [UIAlertController.self]).tintColor = value.view.tintColor

        // Prevent showing cursor
        value.setEditing(false, animated: false)

        // workaround for UIAlertController with actionSheet style crashes for invalid size
        if value.preferredStyle == .actionSheet {
            presentViewController(value)
        }

        let failure = verifySnapshot(matching: value,
                                     as: .image,
                                     snapshotDirectory: snapshotDirectory(file: file),
                                     file: file, testName: testName, line: line)

        XCTAssertNil(failure, file: file, line: line)

        // workaround for UIAlertController with actionSheet style crashes for invalid size
        if value.preferredStyle == .actionSheet {
            dismissViewController(value)
        }
    }

    func verify(matching value: UIViewController,
                customSize: CGSize? = nil,
                named name: String? = nil,
                record recording: Bool = false,
                file: StaticString = #file,
                testName: String = #function,
                line: UInt = #line) {

        let failure = verifySnapshot(matching: value,
                                     as: customSize == nil ? .image : .image(on: ViewImageConfig(safeArea: UIEdgeInsets.zero, size: customSize!, traits: UITraitCollection())),
                                     named: name,
                                     record: recording,
                                     snapshotDirectory: snapshotDirectory(file: file),
                                     file: file,
                                     testName: testName,
                                     line: line)

        XCTAssertNil(failure, file: file, line: line)
    }

    func verify(matching value: UIView,
                named name: String? = nil,
                file: StaticString = #file,
                testName: String = #function,
                line: UInt = #line) {

        let failure = verifySnapshot(matching: value,
                                     as: .image,
                                     named: name,
                                     snapshotDirectory: snapshotDirectory(file: file),
                                     file: file,
                                     testName: testName,
                                     line: line)

        XCTAssertNil(failure, file: file, line: line)
    }

    func verify(matching value: UIImage,
                named name: String? = nil,
                file: StaticString = #file,
                testName: String = #function,
                line: UInt = #line) {

        let failure = verifySnapshot(matching: value,
                                     as: .image,
                                     named: name,
                                     snapshotDirectory: snapshotDirectory(file: file),
                                     file: file,
                                     testName: testName,
                                     line: line)

        XCTAssertNil(failure, file: file, line: line)
    }

    func verify<Value, Format>(matching value: Value,
                               as snapshotting: Snapshotting<Value, Format>,
                               named name: String? = nil,
                               file: StaticString = #file,
                               testName: String = #function,
                               line: UInt = #line) {

        let failure = verifySnapshot(matching: value,
                                     as: snapshotting,
                                     named: name,
                                     snapshotDirectory: snapshotDirectory(file: file),
                                     file: file,
                                     testName: testName,
                                     line: line)

        XCTAssertNil(failure, file: file, line: line)
    }
}

extension Snapshotting where Value == UIAlertController, Format == UIImage {

    /// A snapshot strategy for comparing UIAlertController views based on pixel equality.
    /// Compare UIAlertController.view to prevert the view is resized to fix the default UIViewController.view's size
    public static var image: Snapshotting<UIAlertController, UIImage> {
        return Snapshotting<UIView, UIImage>.image(precision: 1, size: nil).pullback { $0.view }
    }
}

extension UIView {
    func addWidthConstraint(width: CGFloat) -> NSLayoutConstraint {
        translatesAutoresizingMaskIntoConstraints = false

        let widthConstraint = widthAnchor.constraint(equalToConstant: width)

        NSLayoutConstraint.activate([widthConstraint])

        layoutIfNeeded()

        return widthConstraint
    }
}

extension XCTestCase {

    // MARK: - verify in different width helper
    func containerView(with view: UIView, snapshotBackgroundColor: UIColor?) -> UIView {
        let container = UIView(frame: view.bounds)
        container.backgroundColor = snapshotBackgroundColor
        container.addSubview(view)

        view.translatesAutoresizingMaskIntoConstraints = false
        view.fitInSuperview()
        return container
    }

    // MARK: - color scheme
    func resetColorScheme() {
        setColorScheme(.light)
    }

    func setColorScheme(_ variant: ColorSchemeVariant) {
        ColorScheme.default.variant = variant
        NSAttributedString.invalidateMarkdownStyle()
        NSAttributedString.invalidateParagraphStyle()
    }

    // MARK: - UIAlertController hack
    func presentViewController(_ controller: UIViewController,
                               completion: Completion? = nil) {
        let window = UIWindow(frame: CGRect(origin: .zero, size: XCTestCase.DeviceSizeIPhone6))

        let container = UIViewController()
        container.loadViewIfNeeded()

        window.rootViewController = container
        window.makeKeyAndVisible()

        controller.loadViewIfNeeded()
        controller.view.layoutIfNeeded()

        container.present(controller, animated: false, completion: completion)
    }

    func dismissViewController(_ controller: UIViewController,
                               completion: Completion? = nil) {
        controller.dismiss(animated: false, completion: completion)
    }

}
