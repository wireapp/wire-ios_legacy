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


import Foundation
import Cartography

// MARK: Audio Button

extension ConversationInputBarViewController {
    
    
    @objc func setupCallStateObserver() {
        if let userSession = ZMUserSession.shared() {
            callStateObserverToken = WireCallCenterV3.addCallStateObserver(observer: self, userSession:userSession)
        }
    }

    @objc func setupAppLockedObserver() {

        NotificationCenter.default.addObserver(self,
        selector: #selector(revealRecordKeyboardWhenAppLocked),
        name: .appUnlocked,
        object: .none)

        // If the app is locked and not yet reach the time to unlock and the app became active, reveal the keyboard (it was dismissed when app resign active)
        NotificationCenter.default.addObserver(self, selector: #selector(revealRecordKeyboardWhenAppLocked), name: UIApplication.didBecomeActiveNotification, object: nil)
    }

    @objc func revealRecordKeyboardWhenAppLocked() {
        guard AppLock.isActive,
              !AppLockViewController.isLocked,
              mode == .audioRecord,
              !self.inputBar.textView.isFirstResponder else { return }

        displayRecordKeyboard()
    }

    @objc func configureAudioButton(_ button: IconButton) {
        let longPressRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(audioButtonLongPressed(_:)))
        longPressRecognizer.minimumPressDuration = 0.3
        button.addGestureRecognizer(longPressRecognizer)

        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(audioButtonPressed(_:)))
        tapGestureRecognizer.require(toFail: longPressRecognizer)
        button.addGestureRecognizer(tapGestureRecognizer)
    }
    
    @objc func audioButtonPressed(_ sender: UITapGestureRecognizer) {
        guard sender.state == .ended else {
            return
        }
        
        if displayAudioMessageAlertIfNeeded() {
            return
        }

        if self.mode != .audioRecord {
            UIApplication.wr_requestOrWarnAboutMicrophoneAccess({ accepted in
                if accepted {
                    self.mode = .audioRecord
                    self.inputBar.textView.becomeFirstResponder()
                }
            })
        }
        else {
            hideInKeyboardAudioRecordViewController()
        }
    }
    
    private func displayAudioMessageAlertIfNeeded() -> Bool {
        guard ZMUserSession.shared()?.isCallOngoing ?? false else { return false }
        CameraAccess.displayCameraAlertForOngoingCall(at: .recordAudioMessage, from: self)
        return true
    }
    
    @objc func audioButtonLongPressed(_ sender: UILongPressGestureRecognizer) {
        guard self.mode != .audioRecord else {
            return
        }
        
        if displayAudioMessageAlertIfNeeded() {
            return
        }
        
        type(of: self).cancelPreviousPerformRequests(withTarget: self, selector: #selector(hideInlineAudioRecordViewController), object: nil)
        
        switch sender.state {
        case .began:
            self.createAudioRecord()
            if let audioRecordViewController = self.audioRecordViewController , showAudioRecordViewControllerIfGrantedAccess() {
                audioRecordViewController.setOverlayState(.expanded(0), animated: true)
                audioRecordViewController.setRecordingState(.recording, animated: false)
                audioRecordViewController.beginRecording()
                self.inputBar.buttonContainer.isHidden = true
            }
        case .changed:
            if let audioRecordViewController = self.audioRecordViewController {
                audioRecordViewController.updateWithChangedRecognizer(sender)
            }
        case .ended, .cancelled, .failed:
            if let audioRecordViewController = self.audioRecordViewController {
                audioRecordViewController.finishRecordingIfNeeded(sender)
                audioRecordViewController.setOverlayState(.default, animated: true)
                audioRecordViewController.setRecordingState(.finishedRecording, animated: true)
            }
        default: break
        }
        
    }

    @objc func setupAudioSession() {
        self.audioSession = AVAudioSession.sharedInstance()
    }
    
    fileprivate func showAudioRecordViewControllerIfGrantedAccess() -> Bool {
        if audioSession.recordPermission == .granted {
            self.showAudioRecordViewController()
            return true
        } else {
            requestMicrophoneAccess()
            return false
        }
    }
    
    fileprivate func requestMicrophoneAccess() {
        UIApplication.wr_requestOrWarnAboutMicrophoneAccess { (granted) in
            guard granted else { return }
        }
    }
    
    fileprivate func showAudioRecordViewController() {
        guard let audioRecordViewContainer = self.audioRecordViewContainer,
              let audioRecordViewController = self.audioRecordViewController else {
            return
        }

        audioRecordViewController.setOverlayState(.hidden, animated: false)
        
        UIView.transition(with: inputBar, duration: 0.1, options: [.transitionCrossDissolve, .allowUserInteraction], animations: {
            audioRecordViewContainer.isHidden = false
            }, completion: { _ in
                audioRecordViewController.setOverlayState(.expanded(0), animated: true)
        })
    }
    
    fileprivate func hideAudioRecordViewController() {
        if self.mode == .audioRecord {
            hideInKeyboardAudioRecordViewController()
        }
        else {
            hideInlineAudioRecordViewController()
        }
    }
    
    fileprivate func hideInKeyboardAudioRecordViewController() {
        self.inputBar.textView.resignFirstResponder()
        delay(0.3) {
            self.mode = .textInput
        }
    }
    
    @objc fileprivate func hideInlineAudioRecordViewController() {
        self.inputBar.buttonContainer.isHidden = false
        guard let audioRecordViewContainer = self.audioRecordViewContainer else {
            return
        }
        
        UIView.transition(with: inputBar, duration: 0.2, options: .transitionCrossDissolve, animations: {
            audioRecordViewContainer.isHidden = true
            }, completion: nil)
    }
    
    public func hideCameraKeyboardViewController(_ completion: @escaping ()->()) {
        self.inputBar.textView.resignFirstResponder()
        delay(0.3) {
            self.mode = .textInput
            completion()
        }
    }
}

extension ConversationInputBarViewController: AudioRecordViewControllerDelegate {
    
    @objc public func audioRecordViewControllerDidCancel(_ audioRecordViewController: AudioRecordBaseViewController) {
        self.hideAudioRecordViewController()
    }
    
    @objc public func audioRecordViewControllerDidStartRecording(_ audioRecordViewController: AudioRecordBaseViewController) {
        // no op
    }
    
    @objc public func audioRecordViewControllerWantsToSendAudio(_ audioRecordViewController: AudioRecordBaseViewController, recordingURL: URL, duration: TimeInterval, filter: AVSAudioEffectType) {
        
        uploadFile(at: recordingURL as URL)
        
        self.hideAudioRecordViewController()
    }
    
}



extension ConversationInputBarViewController: WireCallCenterCallStateObserver {
    
    public func callCenterDidChange(callState: CallState, conversation: ZMConversation, caller: ZMUser, timestamp: Date?, previousCallState: CallState?) {
        let isRecording = audioRecordKeyboardViewController?.isRecording

        switch (callState, isRecording, wasRecordingBeforeCall) {
        case (.incoming(_, true, _), true, _),              // receiving incoming call while audio keyboard is visible
             (.outgoing, true, _):                          // making an outgoing call while audio keyboard is visible
            wasRecordingBeforeCall = true                   // -> remember that the audio keyboard was visible
            callCountWhileCameraKeyboardWasVisible += 1     // -> increment calls in progress counter
        case (.incoming(_, false, _), _, true),             // refusing an incoming call
             (.terminating, _, true):                       // terminating/closing the current call
            callCountWhileCameraKeyboardWasVisible -= 1     // -> decrement calls in progress counter
        default: break
        }
        
        if 0 == callCountWhileCameraKeyboardWasVisible, wasRecordingBeforeCall {
            displayRecordKeyboard() // -> show the audio record keyboard again
        }
    }

    private func displayRecordKeyboard() {
        // do not show keyboard if conversation list is shown, 
        guard let splitViewController = self.wr_splitViewController,
              let rightViewController = splitViewController.rightViewController,
              splitViewController.isRightViewControllerRevealed,
              rightViewController.isVisible,
              UIApplication.shared.topMostVisibleWindow == AppDelegate.shared().window
            else { return }

        self.wasRecordingBeforeCall = false
        self.mode = .audioRecord
        self.inputBar.textView.becomeFirstResponder()
    }
    
}
