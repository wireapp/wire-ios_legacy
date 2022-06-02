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
import Darwin

public protocol JailbreakDetectorProtocol {
    func isJailbroken() -> Bool
}

public final class JailbreakDetector: NSObject, JailbreakDetectorProtocol {

    private let fm = FileManager.default

    public func isJailbroken() -> Bool {
        #if targetEnvironment(simulator)
        return false
        #else
        return hasJailbrokenFiles ||
            hasWriteablePaths ||
            hasSymlinks ||
            callsFork ||
            canOpenJailbrokenStores
        #endif
    }

    private var hasJailbrokenFiles: Bool {
        let paths: [String] = [
            "/private/var/stash",
            "/private/var/lib/apt",
            "/private/var/tmp/cydia.log",
            "/private/var/lib/cydia",
            "/private/var/mobile/Library/SBSettings/Themes",
            "/Library/MobileSubstrate/MobileSubstrate.dylib",
            "/Library/MobileSubstrate/DynamicLibraries/Veency.plist",
            "/Library/MobileSubstrate/DynamicLibraries/LiveClock.plist",
            "/System/Library/LaunchDaemons/com.ikey.bbot.plist",
            "/System/Library/LaunchDaemons/com.saurik.Cydia.Startup.plist",
            "/var/cache/apt",
            "/var/lib/apt",
            "/var/lib/cydia",
            "/var/log/syslog",
            "/var/tmp/cydia.log",
            "/bin/bash",
            "/bin/sh",
            "/usr/sbin/sshd",
            "/usr/libexec/ssh-keysign",
            "/usr/sbin/sshd",
            "/usr/bin/sshd",
            "/usr/libexec/sftp-server",
            "/etc/ssh/sshd_config",
            "/etc/apt",
            "/Applications/Cydia.app",
            "/Applications/RockApp.app",
            "/Applications/Icy.app",
            "/Applications/WinterBoard.app",
            "/Applications/SBSettings.app",
            "/Applications/MxTube.app",
            "/Applications/IntelliScreen.app",
            "/Applications/FakeCarrier.app",
            "/Applications/blackra1n.app"
        ]

        for path in paths {
            if fm.fileExists(atPath: path) {
                return true
            }
        }

        return false
    }

    private var hasWriteablePaths: Bool {
        if fm.isWritableFile(atPath: "/") {
            return true
        }

        if fm.isWritableFile(atPath: "/private") {
            return true
        }

        return false
    }

    private var hasSymlinks: Bool {
        let symlinks: [String] = [
            "/Library/Ringtones",
            "/Library/Wallpaper",
            "/usr/arm-apple-darwin9",
            "/usr/include",
            "/usr/libexec",
            "/usr/share",
            "/Applications"
        ]

        for link in symlinks {
            if fm.fileExists(atPath: link),
                let attributes = try? fm.attributesOfItem(atPath: link),
                attributes[.type] as? String == "NSFileTypeSymbolicLink" {
                return true
            }
        }

        return false
    }

    private var callsFork: Bool {
        let RTLD_DEFAULT = UnsafeMutableRawPointer(bitPattern: -2)
        let forkPtr = dlsym(RTLD_DEFAULT, "fork")
        typealias ForkType = @convention(c) () -> Int32
        let fork = unsafeBitCast(forkPtr, to: ForkType.self)
        return fork() != -1
    }

    private var canOpenJailbrokenStores: Bool {

        let jailbrokenStoresURLs: [String] = ["cydia://app",
                                              "sileo://package",
                                              "sileo://source"]

        for url in jailbrokenStoresURLs {
            if UIApplication.shared.canOpenURL(URL(string: url)!) {
                return true
            }
        }
        return false
    }

}

@objcMembers public class MockJailbreakDetector: NSObject, JailbreakDetectorProtocol {

    public var jailbroken: Bool = false

    @objc(initAsJailbroken:)
    public init(jailbroken: Bool = false) {
        self.jailbroken = jailbroken
    }

    public func isJailbroken() -> Bool {
        return jailbroken
    }
}
