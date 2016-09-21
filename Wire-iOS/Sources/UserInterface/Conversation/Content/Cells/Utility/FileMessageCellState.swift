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


enum ProgressViewType {
    case determ // stands for deterministic
    case infinite
}

typealias FileMessageCellViewsState = (progressViewType: ProgressViewType?, playButtonIcon: ZetaIconType, playButtonBackgroundColor: UIColor?)

public enum FileMessageCellState {
    
    case unavailable
    
    case uploading /// only for sender
    
    case uploaded
    
    case downloading
    
    case downloaded
    
    case failedUpload /// only for sender
    
    case cancelledUpload /// only for sender
    
    case failedDownload
    
    // Value mapping from message consolidated state (transfer state, previewData, fileURL) to FileMessageCellState
    static func fromConversationMessage(_ message: ZMConversationMessage) -> FileMessageCellState? {
        guard let fileMessageData = message.fileMessageData , Message.isFileTransferMessage(message) else {
            return .None
        }
        
        switch fileMessageData.transferState {
        case .Uploaded: return .Uploaded
        case .Downloaded: return .Downloaded
        case .Uploading:
            if fileMessageData.fileURL != nil {
                return .Uploading
            } else {
                return .Unavailable
            }
            
        case .Downloading: return .Downloading
        case .FailedUpload:
            if fileMessageData.fileURL != nil {
                return .FailedUpload
            } else {
                return .Unavailable
            }
        case .CancelledUpload:
            if fileMessageData.fileURL != nil {
                return .CancelledUpload
            } else {
                return .Unavailable
            }
        case .FailedDownload: return .FailedDownload
        }
    }
    
    static let clearColor   = UIColor.clear
    static let normalColor  = UIColor.black.withAlphaComponent(0.4)
    static let failureColor = UIColor.red.withAlphaComponent(0.24)
    
    typealias ViewsStateMapping = [FileMessageCellState: FileMessageCellViewsState]
    /// Mapping of cell state to it's views state for media message:
    ///  # Cell state ======>      #progressViewType
    ///               ======>      |            #playButtonIcon
    ///               ======>      |            |        #playButtonBackgroundColor
    static let viewsStateForCellStateForVideoMessage: ViewsStateMapping =
        [.uploading:               (.determ,   .cancel, normalColor),
         .uploaded:                (.none,     .play,   normalColor),
         .downloading:             (.determ,   .cancel, normalColor),
         .downloaded:              (.none,     .play,   normalColor),
         .failedUpload:            (.none,     .redo,   failureColor),
         .cancelledUpload:         (.none,     .redo,   normalColor),
         .failedDownload:          (.none,     .redo,   failureColor),]
    
    /// Mapping of cell state to it's views state for media message:
    ///  # Cell state ======>      #progressViewType
    ///               ======>      |            #playButtonIcon
    ///               ======>      |            |        #playButtonBackgroundColor
    static let viewsStateForCellStateForAudioMessage: ViewsStateMapping =
        [.uploading:               (.determ,   .cancel, normalColor),
         .uploaded:                (.none,     .play,   normalColor),
         .downloading:             (.determ,   .cancel, normalColor),
         .downloaded:              (.none,     .play,   normalColor),
         .failedUpload:            (.none,     .redo,   failureColor),
         .cancelledUpload:         (.none,     .redo,   normalColor),
         .failedDownload:          (.none,     .redo,   failureColor),]
    
    /// Mapping of cell state to it's views state for normal file message:
    ///  # Cell state ======>      #progressViewType
    ///               ======>      |            #actionButtonIcon
    ///               ======>      |            |        #actionButtonBackgroundColor
    static let viewsStateForCellStateForFileMessage: ViewsStateMapping =
        [.uploading:               (.determ,   .cancel, normalColor),
         .downloading:             (.determ,   .cancel, normalColor),
         .downloaded:              (.none,     .none,   clearColor),
         .uploaded:                (.none,     .none,   clearColor),
         .failedUpload:            (.none,     .redo,   failureColor),
         .cancelledUpload:         (.none,     .redo,   normalColor),
         .failedDownload:          (.none,     .save,   failureColor),]
    
    func viewsStateForVideo() -> FileMessageCellViewsState? {
        return type(of: self).viewsStateForCellStateForVideoMessage[self]
    }
    
    func viewsStateForAudio() -> FileMessageCellViewsState? {
        return type(of: self).viewsStateForCellStateForAudioMessage[self]
    }
    
    func viewsStateForFile() -> FileMessageCellViewsState? {
        return type(of: self).viewsStateForCellStateForFileMessage[self]
    }

}

