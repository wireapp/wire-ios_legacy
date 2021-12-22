// 
// Wire
// Copyright (C) 2020 Wire Swiss GmbH
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

private let WireLastCachedKeyboardHeightKey = "WireLastCachedKeyboardHeightKey"

extension UIView {

    /// Provides correct handling for animating alongside a keyboard animation
    class func animate(withKeyboardNotification notification: Notification?,
                       in view: UIView,
                       delay: TimeInterval = 0,
                       animations: @escaping (_ keyboardFrameInView: CGRect) -> Void,
                       completion: ResultHandler? = nil) {
        let keyboardFrame = self.keyboardFrame(in: view, forKeyboardNotification: notification)

        if let currentFirstResponder = UIResponder.currentFirst {
            let keyboardSize = CGSize(width: keyboardFrame.size.width, height: keyboardFrame.size.height - (currentFirstResponder.inputAccessoryView?.bounds.size.height ?? 0))
            setLastKeyboardSize(keyboardSize)
        }

        let userInfo = notification?.userInfo
        let animationLength: TimeInterval = (userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? NSNumber)?.doubleValue ?? 0
        let animationCurve: AnimationCurve = AnimationCurve(rawValue: (userInfo?[UIResponder.keyboardAnimationCurveUserInfoKey] as AnyObject).intValue ?? 0) ?? .easeInOut

        var animationOptions: UIView.AnimationOptions = .beginFromCurrentState

        switch animationCurve {
        case .easeIn:
            animationOptions.insert(.curveEaseIn)
        case .easeInOut:
            animationOptions.insert(.curveEaseInOut)
        case  .easeOut:
            animationOptions.insert(.curveEaseOut)
        case  .linear:
            animationOptions.insert(.curveLinear)
        default:
            break
        }

        UIView.animate(withDuration: animationLength, delay: delay, options: animationOptions, animations: {
            animations(keyboardFrame)
        }, completion: completion)
    }

    class func setLastKeyboardSize(_ lastSize: CGSize) {
        UserDefaults.standard.set(NSCoder.string(for: lastSize), forKey: WireLastCachedKeyboardHeightKey)
    }

    class var lastKeyboardSize: CGSize {

        if let currentLastValue = UserDefaults.standard.object(forKey: WireLastCachedKeyboardHeightKey) as? String {
            var keyboardSize = NSCoder.cgSize(for: currentLastValue)

            // If keyboardSize value is clearly off we need to pull default value
            if keyboardSize.height < 150 {
                keyboardSize.height = KeyboardHeight.current
            }

            return keyboardSize
        }

        return CGSize(width: UIScreen.main.bounds.size.width, height: KeyboardHeight.current)
    }

    class func keyboardFrame(in view: UIView, forKeyboardNotification notification: Notification?) -> CGRect {
        let userInfo = notification?.userInfo
        return keyboardFrame(in: view, forKeyboardInfo: userInfo)
    }

    class func keyboardFrame(in view: UIView, forKeyboardInfo keyboardInfo: [AnyHashable: Any]?) -> CGRect {
        let screenRect = keyboardInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect
        let windowRect = view.window?.convert(screenRect ?? CGRect.zero, from: nil)
        let viewRect = view.convert(windowRect ?? CGRect.zero, from: nil)

        let intersection = viewRect.intersection(view.bounds)

        return intersection
    }
}

// MARK: - factory methods

extension UIView {
    static func shieldView() -> UIView {
        let loadedObjects = UINib(nibName: "LaunchScreen", bundle: nil).instantiate(withOwner: .none, options: .none)

        let nibView = loadedObjects.first as! UIView

        return nibView
    }
}

extension UIVisualEffectView {
    static func blurView() -> UIVisualEffectView {
        let blurEffect = UIBlurEffect(style: .dark)
        return UIVisualEffectView(effect: blurEffect)
    }
}
