//
// Wire
// Copyright (C) 2017 Wire Swiss GmbH
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


/**
 Available settings
 
 - ChatHeadsDisabled:      Disable chat heads in conversation and self profile
 - DisableMarkdown:        Disable markdown formatter for messages
 - DarkMode:               Dark mode for conversation
 - PriofileName:           User name
 - SoundAlerts:            Sound alerts level
 - DisableCrashAndAnalyticsSharing: Opt-Out analytics and App Center
 - DisableSendButton:      Opt-Out of new send button
 - DisableLinkPreviews:    Disable link previews for links you send
 - Disable(.*):            Disable some app features (debug)
 */
public enum SettingsPropertyName: String, CustomStringConvertible {
    
    // User defaults
    case chatHeadsDisabled = "ChatHeadsDisabled"
    case notificationContentVisible = "NotificationContentVisible"
    case disableMarkdown = "Markdown"
        
    case darkMode = "DarkMode"
    
    case disableSendButton = "DisableSendButton"
    
    case disableLinkPreviews = "DisableLinkPreviews"
	
    // Profile
    case profileName = "ProfileName"
    case handle = "handle"

    case email = "email"
    case phone = "phone"

    case accentColor = "AccentColor"
    
    // AVS
    case soundAlerts = "SoundAlerts"
    case callingConstantBitRate = "constantBitRate"

    // Sounds
    case messageSoundName = "MessageSoundName"
    case callSoundName = "CallSoundName"
    case pingSoundName = "PingSoundName"
    
    // Open In
    case tweetOpeningOption = "TweetOpeningOption"
    case mapsOpeningOption = "MapsOpeningOption"
    case browserOpeningOption = "BrowserOpeningOption"

    // Persoanl Information
    // Analytics
    case disableCrashSharing = "DisableCrashSharing"
    case disableAnalyticsSharing = "DisableAnalyticsSharing"
    case receiveNewsAndOffers = "ReceiveNewsAndOffers"

    // Debug
    case disableCallKit = "DisableCallKit"
    case callingProtocolStrategy = "CallingProtcolStrategy"
    case enableBatchCollections = "EnableBatchCollections"
    case federationEnabled = "federationEnabled"

    case lockApp = "lockApp"

    case readReceiptsEnabled = "readReceiptsEnabled"
    
    case encryptMessagesAtRest = "encryptMessagesAtRest"
    
    public var changeNotificationName: String {
        return self.description + "ChangeNotification"
    }

    public var notificationName: Notification.Name {
        return Notification.Name(changeNotificationName)
    }
    
    public var description: String {
        return self.rawValue;
    }
}

