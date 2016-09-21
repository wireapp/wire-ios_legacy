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

let audioRecordTooltipDisplayDuration: TimeInterval = 2

extension ConversationInputBarViewController {
    
    func configureAudioButton(_ button: IconButton) {
        button.addTarget(self, action: #selector(audioButtonPressed(_:)), forControlEvents: .TouchUpInside)
        let longPressRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(audioButtonLongPressed(_:)))
        button.addGestureRecognizer(longPressRecognizer)
    }
    
    func audioButtonPressed(_ sender: IconButton) {
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
    
    func audioButtonLongPressed(_ sender: UILongPressGestureRecognizer) {
        guard self.mode != .AudioRecord else {
            return
        }
        
        type(of: self).cancelPreviousPerformRequestsWithTarget(self, selector: #selector(hideInlineAudioRecordViewController), object: nil)
        
        switch sender.state {
        case .began:
            self.createAudioRecordViewController()
            if let audioRecordViewController = self.audioRecordViewController , showAudioRecordViewControllerIfGrantedAccess() {
                audioRecordViewController.setRecordingState(.Recording, animated: false)
                audioRecordViewController.beginRecording()
                self.inputBar.buttonContainer.hidden = true
            }
        case .changed:
            if let audioRecordViewController = self.audioRecordViewController {
                audioRecordViewController.updateWithChangedRecognizer(sender)
            }
        case .ended, .cancelled, .failed:
            if let audioRecordViewController = self.audioRecordViewController {
                audioRecordViewController.finishRecordingIfNeeded(sender)
                audioRecordViewController.setOverlayState(.Default, animated: true)
                audioRecordViewController.setRecordingState(.FinishedRecording, animated: true)
            }
        default: break
        }
        
    }
    
    fileprivate func showAudioRecordViewControllerIfGrantedAccess() -> Bool {
        if AVAudioSession.sharedInstance().recordPermission() == .Granted {
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
    
    fileprivate func hideAudioRecordViewController() {
        if self.mode == .AudioRecord {
            hideInKeyboardAudioRecordViewController()
        }
        else {
            hideInlineAudioRecordViewController()
        }
    }
    
    fileprivate func hideInKeyboardAudioRecordViewController() {
        self.inputBar.textView.resignFirstResponder()
        self.audioRecordKeyboardViewController = nil
        delay(0.3) {
            self.mode = .TextInput
        }
    }
    
    @objc fileprivate func hideInlineAudioRecordViewController() {
        self.inputBar.buttonContainer.hidden = false
        guard let audioRecordViewController = self.audioRecordViewController else {
            return
        }
        
        UIView.transitionWithView(inputBar, duration: 0.2, options: .TransitionCrossDissolve, animations: {
            audioRecordViewController.view.hidden = true
            }, completion: nil)
    }
    
    public func hideCameraKeyboardViewController(_ completion: @escaping ()->()) {
        self.inputBar.textView.resignFirstResponder()
        self.cameraKeyboardViewController = nil
        delay(0.3) {
            self.mode = .TextInput
            completion()
        }
    }
}


extension ConversationInputBarViewController: AudioRecordViewControllerDelegate {
    
    public func audioRecordViewControllerDidCancel(_ audioRecordViewController: AudioRecordBaseViewController) {
        self.hideAudioRecordViewController()
    }
    
    public func audioRecordViewControllerDidStartRecording(_ audioRecordViewController: AudioRecordBaseViewController) {
        let type: ConversationMediaRecordingType = audioRecordViewController is AudioRecordKeyboardViewController ? .Keyboard : .Minimised
        
        if type == .Minimised {
            Analytics.shared()?.tagMediaAction(.AudioMessage, inConversation: self.conversation)
        }
        
        Analytics.shared()?.tagStartedAudioMessageRecording(inConversation: self.conversation, type: type)
    }
    
    public func audioRecordViewControllerWantsToSendAudio(_ audioRecordViewController: AudioRecordBaseViewController, recordingURL: NSURL, duration: TimeInterval, context: AudioMessageContext, filter: AVSAudioEffectType) {
        let type: ConversationMediaRecordingType = audioRecordViewController is AudioRecordKeyboardViewController ? .Keyboard : .Minimised
        
        Analytics.shared()?.tagSentAudioMessage(duration, context: context, filter: filter, type: type)
        uploadFileAtURL(recordingURL)
        
        self.hideAudioRecordViewController()
    }
    
}
