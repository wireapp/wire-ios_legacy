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
    
    
    func setupCallStateObserver() {
        if let userSession = ZMUserSession.shared() {
            callStateObserverToken = WireCallCenterV3.addCallStateObserver(observer: self, userSession:userSession)
        }
    }
    
    func configureAudioButton(_ button: IconButton) {
        let longPressRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(audioButtonLongPressed(_:)))
        longPressRecognizer.minimumPressDuration = 0.3
        button.addGestureRecognizer(longPressRecognizer)

        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(audioButtonPressed(_:)))
        tapGestureRecognizer.require(toFail: longPressRecognizer)
        button.addGestureRecognizer(tapGestureRecognizer)
    }
    
    func audioButtonPressed(_ sender: UITapGestureRecognizer) {
        guard sender.state == .ended else {
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
    
    func audioButtonLongPressed(_ sender: UILongPressGestureRecognizer) {
        guard self.mode != .audioRecord else {
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
    
    fileprivate func showAudioRecordViewControllerIfGrantedAccess() -> Bool {
        if AVAudioSession.sharedInstance().recordPermission() == .granted {
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
    
    public func audioRecordViewControllerDidCancel(_ audioRecordViewController: AudioRecordBaseViewController) {
        self.hideAudioRecordViewController()
    }
    
    public func audioRecordViewControllerDidStartRecording(_ audioRecordViewController: AudioRecordBaseViewController) {
        let type: ConversationMediaRecordingType = audioRecordViewController is AudioRecordKeyboardViewController ? .keyboard : .minimised
        
        if type == .minimised {
            Analytics.shared().tagMediaAction(.audioMessage, inConversation: self.conversation)
        }
        
        Analytics.shared().tagStartedAudioMessageRecording(inConversation: self.conversation, type: type)
    }
    
    public func audioRecordViewControllerWantsToSendAudio(_ audioRecordViewController: AudioRecordBaseViewController, recordingURL: URL, duration: TimeInterval, context: AudioMessageContext, filter: AVSAudioEffectType) {
        let type: ConversationMediaRecordingType = audioRecordViewController is AudioRecordKeyboardViewController ? .keyboard : .minimised
        
        Analytics.shared().tagSentAudioMessage(in: conversation, duration: duration, context: context, filter: filter, type: type)
        uploadFile(at: recordingURL as URL)
        
        self.hideAudioRecordViewController()
    }
    
}


extension ConversationInputBarViewController : WireCallCenterCallStateObserver {
    
    public func callCenterDidChange(callState: CallState, conversation: ZMConversation, caller: ZMUser, timestamp: Date?) {
        
        let isRecording = self.audioRecordKeyboardViewController?.isRecording
        
        switch (callState, isRecording, self.wasRecordingBeforeCall) {
            
        case (.incoming(_, true, _), true, false),      // receiving incoming call while recording an audio
             (.outgoing, true, false):                  // making an outgoing call while recording an audio
            self.wasRecordingBeforeCall = true          // -> remember that we were recording an audio
        case (.incoming(_, false, _), _, true),         // refusing an incoming call
             (.terminating, _, true):                   // terminating/closing the current call
            displayRecordKeyboard()                     // -> show again the audio record keyboard
        default: break
        }
    }
    
    private func displayRecordKeyboard() {
        self.wasRecordingBeforeCall = false
        self.mode = .audioRecord
        self.inputBar.textView.becomeFirstResponder()
    }
    
}
