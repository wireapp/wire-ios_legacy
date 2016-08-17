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

let audioRecordTooltipDisplayDuration: NSTimeInterval = 2

extension ConversationInputBarViewController {
    
    func configureAudioButton(button: IconButton) {
        button.addTarget(self, action: #selector(audioButtonPressed(_:)), forControlEvents: .TouchUpInside)
        let longPressRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(audioButtonLongPressed(_:)))
        button.addGestureRecognizer(longPressRecognizer)
    }
    
    func audioButtonPressed(sender: IconButton) {
        if self.mode != .AudioRecord {
            UIApplication.wr_requestOrWarnAboutMicrophoneAccess({ accepted in
                if accepted {
                    self.mode = .AudioRecord
                    self.inputBar.textView.becomeFirstResponder()
                }
            })
        }
        else {
            hideInKeyboardAudioRecordViewController()
        }
    }
    
    func audioButtonLongPressed(sender: UILongPressGestureRecognizer) {
        guard self.mode != .AudioRecord else {
            return
        }
        
        self.dynamicType.cancelPreviousPerformRequestsWithTarget(self, selector: #selector(hideInlineAudioRecordViewController), object: nil)
        
        switch sender.state {
        case .Began:
            self.createAudioRecordViewController()
            if let audioRecordViewController = self.audioRecordViewController where showAudioRecordViewControllerIfGrantedAccess() {
                audioRecordViewController.setRecordingState(.Recording, animated: false)
                audioRecordViewController.beginRecording()
                self.inputBar.buttonContainer.hidden = true
            }
        case .Changed:
            if let audioRecordViewController = self.audioRecordViewController {
                audioRecordViewController.updateWithChangedRecognizer(sender)
            }
        case .Ended, .Cancelled, .Failed:
            if let audioRecordViewController = self.audioRecordViewController {
                audioRecordViewController.finishRecordingIfNeeded(sender)
                audioRecordViewController.setOverlayState(.Default, animated: true)
                audioRecordViewController.setRecordingState(.FinishedRecording, animated: true)
            }
        default: break
        }
        
    }
    
    private func showAudioRecordViewControllerIfGrantedAccess() -> Bool {
        if AVAudioSession.sharedInstance().recordPermission() == .Granted {
            self.showAudioRecordViewController()
            return true
        } else {
            requestMicrophoneAccess()
            return false
        }
    }
    
    private func requestMicrophoneAccess() {
        UIApplication.wr_requestOrWarnAboutMicrophoneAccess { (granted) in
            guard granted else { return }
        }
    }
    
    private func showAudioRecordViewController() {
        guard let audioRecordViewController = self.audioRecordViewController else {
            return
        }
        
        audioRecordViewController.setOverlayState(.Hidden, animated: false)
        
        UIView.transitionWithView(inputBar, duration: 0.1, options: .TransitionCrossDissolve, animations: {
            audioRecordViewController.view.hidden = false
            }, completion: { _ in
                audioRecordViewController.setOverlayState(.Expanded(0), animated: true)
        })
    }
    
    private func hideAudioRecordViewController() {
        if self.mode == .AudioRecord {
            hideInKeyboardAudioRecordViewController()
        }
        else {
            hideInlineAudioRecordViewController()
        }
    }
    
    private func hideInKeyboardAudioRecordViewController() {
        self.inputBar.textView.resignFirstResponder()
        self.audioRecordKeyboardViewController = nil
        delay(0.3) {
            self.mode = .TextInput
        }
    }
    
    @objc private func hideInlineAudioRecordViewController() {
        self.inputBar.buttonContainer.hidden = false
        guard let audioRecordViewController = self.audioRecordViewController else {
            return
        }
        
        UIView.transitionWithView(inputBar, duration: 0.2, options: .TransitionCrossDissolve, animations: {
            audioRecordViewController.view.hidden = true
            }, completion: nil)
    }
    
    public func hideCameraKeyboardViewController(completion: ()->()) {
        self.inputBar.textView.resignFirstResponder()
        self.cameraKeyboardViewController = nil
        delay(0.3) {
            self.mode = .TextInput
            completion()
        }
    }
}


extension ConversationInputBarViewController: AudioRecordViewControllerDelegate {
    
    public func audioRecordViewControllerDidCancel(audioRecordViewController: AudioRecordBaseViewController) {
        self.hideAudioRecordViewController()
    }
    
    public func audioRecordViewControllerDidStartRecording(audioRecordViewController: AudioRecordBaseViewController) {
        let type: ConversationMediaRecordingType = audioRecordViewController is AudioRecordKeyboardViewController ? .Keyboard : .Minimised
        
        if type == .Minimised {
            Analytics.shared()?.tagMediaAction(.AudioMessage, inConversation: self.conversation)
        }
        
        Analytics.shared()?.tagStartedAudioMessageRecording(inConversation: self.conversation, type: type)
    }
    
    public func audioRecordViewControllerWantsToSendAudio(audioRecordViewController: AudioRecordBaseViewController, recordingURL: NSURL, duration: NSTimeInterval, context: AudioMessageContext, filter: AVSAudioEffectType) {
        let type: ConversationMediaRecordingType = audioRecordViewController is AudioRecordKeyboardViewController ? .Keyboard : .Minimised
        
        Analytics.shared()?.tagSentAudioMessage(duration, context: context, filter: filter, type: type)
        uploadFileAtURL(recordingURL)
        
        self.hideAudioRecordViewController()
    }
    
}
