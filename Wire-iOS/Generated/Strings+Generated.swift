// swiftlint:disable all
// Generated using SwiftGen — https://github.com/SwiftGen/SwiftGen

import Foundation

// swiftlint:disable superfluous_disable_command file_length implicit_return

// MARK: - Strings

// swiftlint:disable explicit_type_interface function_parameter_count identifier_name line_length
// swiftlint:disable nesting type_body_length type_name vertical_whitespace_opening_braces
internal enum L10n {
  internal enum Accessibility {
    internal enum AccountPage {
      internal enum AvailabilityStatus {
        /// Status
        internal static let description = L10n.tr("Accessibility", "accountPage.availabilityStatus.description")
        /// Double tap to change status
        internal static let hint = L10n.tr("Accessibility", "accountPage.availabilityStatus.hint")
      }
      internal enum Handle {
        /// Username
        internal static let description = L10n.tr("Accessibility", "accountPage.handle.description")
      }
      internal enum Name {
        /// Profile name
        internal static let description = L10n.tr("Accessibility", "accountPage.name.description")
      }
      internal enum ProfilePicture {
        /// Profile picture
        internal static let description = L10n.tr("Accessibility", "accountPage.profilePicture.description")
        /// Double tap to change your picture
        internal static let hint = L10n.tr("Accessibility", "accountPage.profilePicture.hint")
      }
      internal enum TeamName {
        /// Team name
        internal static let description = L10n.tr("Accessibility", "accountPage.teamName.description")
      }
    }
    internal enum ClientList {
      internal enum DeviceDetails {
        /// Double tap to open device details
        internal static let hint = L10n.tr("Accessibility", "clientList.deviceDetails.hint")
      }
    }
    internal enum Conversation {
      internal enum BackButton {
        /// Go back to conversation list
        internal static let description = L10n.tr("Accessibility", "conversation.backButton.description")
      }
      internal enum ProfileImage {
        /// Profile picture
        internal static let description = L10n.tr("Accessibility", "conversation.profileImage.description")
        /// Double tap to open profile
        internal static let hint = L10n.tr("Accessibility", "conversation.profileImage.hint")
      }
      internal enum SearchButton {
        /// Open search
        internal static let description = L10n.tr("Accessibility", "conversation.searchButton.description")
      }
    }
    internal enum Options {
      internal enum SoundButton {
        /// Double tap to change setting
        internal static let hint = L10n.tr("Accessibility", "options.soundButton.hint")
      }
    }
    internal enum Settings {
      internal enum BackButton {
        /// Go back to %@
        internal static func description(_ p1: Any) -> String {
          return L10n.tr("Accessibility", "settings.backButton.description", String(describing: p1))
        }
      }
      internal enum CloseButton {
        /// Close settings
        internal static let description = L10n.tr("Accessibility", "settings.closeButton.description")
      }
      internal enum DeviceCount {
        /// %@ devices in use
        internal static func hint(_ p1: Any) -> String {
          return L10n.tr("Accessibility", "settings.deviceCount.hint", String(describing: p1))
        }
      }
    }
  }
  internal enum InfoPlist {
    /// Allow Wire to access your camera so you can place video calls and send photos.
    internal static let nsCameraUsageDescription = L10n.tr("InfoPlist", "NSCameraUsageDescription")
    /// Allow Wire to access your contacts to connect you with others. We anonymize all information before uploading it to our server and do not share it with anyone else.
    internal static let nsContactsUsageDescription = L10n.tr("InfoPlist", "NSContactsUsageDescription")
    /// In order to authenticate in the app allow Wire to access the Face ID feature.
    internal static let nsFaceIDUsageDescription = L10n.tr("InfoPlist", "NSFaceIDUsageDescription")
    /// Allow Wire to access your location so you can send your location to others.
    internal static let nsLocationWhenInUseUsageDescription = L10n.tr("InfoPlist", "NSLocationWhenInUseUsageDescription")
    /// Allow Wire to access your microphone so you can talk to people and send audio messages.
    internal static let nsMicrophoneUsageDescription = L10n.tr("InfoPlist", "NSMicrophoneUsageDescription")
    /// Allow Wire to store pictures you take in the photo library.
    internal static let nsPhotoLibraryAddUsageDescription = L10n.tr("InfoPlist", "NSPhotoLibraryAddUsageDescription")
    /// Allow Wire to access pictures stored in photo library.
    internal static let nsPhotoLibraryUsageDescription = L10n.tr("InfoPlist", "NSPhotoLibraryUsageDescription")
  }
  internal enum Localizable {
    /// Connection Request
    internal static let connectionRequestPendingTitle = L10n.tr("Localizable", "connection_request_pending_title")
    internal enum About {
      internal enum Copyright {
        /// © Wire Swiss GmbH
        internal static let title = L10n.tr("Localizable", "about.copyright.title")
      }
      internal enum License {
        /// Acknowledgements
        internal static let licenseHeader = L10n.tr("Localizable", "about.license.license_header")
        /// View Project Page
        internal static let openProjectButton = L10n.tr("Localizable", "about.license.open_project_button")
        /// Details
        internal static let projectHeader = L10n.tr("Localizable", "about.license.project_header")
        /// License Information
        internal static let title = L10n.tr("Localizable", "about.license.title")
      }
      internal enum Privacy {
        /// Privacy Policy
        internal static let title = L10n.tr("Localizable", "about.privacy.title")
      }
      internal enum Tos {
        /// Terms of Use
        internal static let title = L10n.tr("Localizable", "about.tos.title")
      }
      internal enum Website {
        /// Wire Website
        internal static let title = L10n.tr("Localizable", "about.website.title")
      }
    }
    internal enum AccountDeletedMissingPasscodeAlert {
      /// In order to use Wire, please set a passcode in your device settings.
      internal static let message = L10n.tr("Localizable", "account_deleted_missing_passcode_alert.message")
      /// No device passcode
      internal static let title = L10n.tr("Localizable", "account_deleted_missing_passcode_alert.title")
    }
    internal enum AccountDeletedSessionExpiredAlert {
      /// The application did not communicate with the server for a long period of time, or your session has been remotely invalidated.
      internal static let message = L10n.tr("Localizable", "account_deleted_session_expired_alert.message")
      /// Your session expired
      internal static let title = L10n.tr("Localizable", "account_deleted_session_expired_alert.title")
    }
    internal enum AddParticipants {
      internal enum Alert {
        /// The group is full
        internal static let title = L10n.tr("Localizable", "add_participants.alert.title")
        internal enum Message {
          /// Up to %1$d people can join a conversation. Currently there is only room for %2$d more.
          internal static func existingConversation(_ p1: Int, _ p2: Int) -> String {
            return L10n.tr("Localizable", "add_participants.alert.message.existing_conversation", p1, p2)
          }
          /// Up to %d people can join a conversation.
          internal static func newConversation(_ p1: Int) -> String {
            return L10n.tr("Localizable", "add_participants.alert.message.new_conversation", p1)
          }
        }
      }
    }
    internal enum AppLockModule {
      internal enum GoToSettingsButton {
        /// Go to settings
        internal static let title = L10n.tr("Localizable", "appLockModule.goToSettingsButton.title")
      }
      internal enum Message {
        /// Unlock Wire with Face ID or Passcode
        internal static let faceID = L10n.tr("Localizable", "appLockModule.message.faceID")
        /// Unlock Wire with Passcode
        internal static let passcode = L10n.tr("Localizable", "appLockModule.message.passcode")
        /// To unlock Wire, turn on Passcode in your device settings
        internal static let passcodeUnavailable = L10n.tr("Localizable", "appLockModule.message.passcodeUnavailable")
        /// Unlock Wire with Touch ID or Passcode
        internal static let touchID = L10n.tr("Localizable", "appLockModule.message.touchID")
      }
      internal enum UnlockButton {
        /// Unlock
        internal static let title = L10n.tr("Localizable", "appLockModule.unlockButton.title")
      }
    }
    internal enum ArchivedList {
      /// archive
      internal static let title = L10n.tr("Localizable", "archived_list.title")
    }
    internal enum Availability {
      /// Available
      internal static let available = L10n.tr("Localizable", "availability.available")
      /// Away
      internal static let away = L10n.tr("Localizable", "availability.away")
      /// Busy
      internal static let busy = L10n.tr("Localizable", "availability.busy")
      /// None
      internal static let `none` = L10n.tr("Localizable", "availability.none")
      internal enum Message {
        /// Cancel
        internal static let cancel = L10n.tr("Localizable", "availability.message.cancel")
        /// Set a status
        internal static let setStatus = L10n.tr("Localizable", "availability.message.set_status")
      }
      internal enum Reminder {
        internal enum Action {
          /// Do not display this information again
          internal static let dontRemindMe = L10n.tr("Localizable", "availability.reminder.action.dont_remind_me")
          /// OK
          internal static let ok = L10n.tr("Localizable", "availability.reminder.action.ok")
        }
        internal enum Available {
          /// You will appear as Available to other people. You will receive notifications for incoming calls and for messages according to the Notifications setting in each conversation.
          internal static let message = L10n.tr("Localizable", "availability.reminder.available.message")
          /// You are set to Available
          internal static let title = L10n.tr("Localizable", "availability.reminder.available.title")
        }
        internal enum Away {
          /// You will appear as Away to other people. You will not receive notifications about any incoming calls or messages.
          internal static let message = L10n.tr("Localizable", "availability.reminder.away.message")
          /// You are set to Away
          internal static let title = L10n.tr("Localizable", "availability.reminder.away.title")
        }
        internal enum Busy {
          /// You will appear as Busy to other people. You will only receive notifications for mentions, replies, and calls in conversations that are not muted.
          internal static let message = L10n.tr("Localizable", "availability.reminder.busy.message")
          /// You are set to Busy
          internal static let title = L10n.tr("Localizable", "availability.reminder.busy.title")
        }
        internal enum None {
          /// You will receive notifications for incoming calls and for messages according to the Notifications setting in each conversation.
          internal static let message = L10n.tr("Localizable", "availability.reminder.none.message")
          /// No status set
          internal static let title = L10n.tr("Localizable", "availability.reminder.none.title")
        }
      }
    }
    internal enum BackendNotSupported {
      internal enum Alert {
        /// The server version is not supported by this app. Please contact your system administrator.
        internal static let message = L10n.tr("Localizable", "backend_not_supported.alert.message")
        /// Server version not supported
        internal static let title = L10n.tr("Localizable", "backend_not_supported.alert.title")
      }
    }
    internal enum ButtonMessageCell {
      /// Your answer can't be sent, please retry.
      internal static let genericError = L10n.tr("Localizable", "button_message_cell.generic_error")
      internal enum State {
        /// confirmed
        internal static let confirmed = L10n.tr("Localizable", "button_message_cell.state.confirmed")
        /// selected
        internal static let selected = L10n.tr("Localizable", "button_message_cell.state.selected")
        /// unselected
        internal static let unselected = L10n.tr("Localizable", "button_message_cell.state.unselected")
      }
    }
    internal enum Call {
      internal enum Actions {
        internal enum Label {
          /// Accept call
          internal static let acceptCall = L10n.tr("Localizable", "call.actions.label.accept_call")
          /// Switch camera
          internal static let flipCamera = L10n.tr("Localizable", "call.actions.label.flip_camera")
          /// Join call
          internal static let joinCall = L10n.tr("Localizable", "call.actions.label.join_call")
          /// Start audio call
          internal static let makeAudioCall = L10n.tr("Localizable", "call.actions.label.make_audio_call")
          /// Start video call
          internal static let makeVideoCall = L10n.tr("Localizable", "call.actions.label.make_video_call")
          /// Minimize call
          internal static let minimizeCall = L10n.tr("Localizable", "call.actions.label.minimize_call")
          /// Decline call
          internal static let rejectCall = L10n.tr("Localizable", "call.actions.label.reject_call")
          /// Switch to back camera
          internal static let switchToBackCamera = L10n.tr("Localizable", "call.actions.label.switch_to_back_camera")
          /// Switch to front camera
          internal static let switchToFrontCamera = L10n.tr("Localizable", "call.actions.label.switch_to_front_camera")
          /// End call
          internal static let terminateCall = L10n.tr("Localizable", "call.actions.label.terminate_call")
          /// Unmute
          internal static let toggleMuteOff = L10n.tr("Localizable", "call.actions.label.toggle_mute_off")
          /// Mute
          internal static let toggleMuteOn = L10n.tr("Localizable", "call.actions.label.toggle_mute_on")
          /// Disable speaker
          internal static let toggleSpeakerOff = L10n.tr("Localizable", "call.actions.label.toggle_speaker_off")
          /// Enable speaker
          internal static let toggleSpeakerOn = L10n.tr("Localizable", "call.actions.label.toggle_speaker_on")
          /// Turn off camera
          internal static let toggleVideoOff = L10n.tr("Localizable", "call.actions.label.toggle_video_off")
          /// Turn on camera
          internal static let toggleVideoOn = L10n.tr("Localizable", "call.actions.label.toggle_video_on")
        }
      }
      internal enum Alert {
        internal enum Ongoing {
          /// This will end your other call.
          internal static let alertTitle = L10n.tr("Localizable", "call.alert.ongoing.alert_title")
          internal enum Join {
            /// Join anyway
            internal static let button = L10n.tr("Localizable", "call.alert.ongoing.join.button")
            /// A call is active in another conversation.
            /// Joining this call will hang up the other one.
            internal static let message = L10n.tr("Localizable", "call.alert.ongoing.join.message")
          }
          internal enum Start {
            /// Call anyway
            internal static let button = L10n.tr("Localizable", "call.alert.ongoing.start.button")
            /// A call is active in another conversation.
            /// Calling here will hang up the other call.
            internal static let message = L10n.tr("Localizable", "call.alert.ongoing.start.message")
          }
        }
      }
      internal enum Announcement {
        /// Incoming call from %@
        internal static func incoming(_ p1: Any) -> String {
          return L10n.tr("Localizable", "call.announcement.incoming", String(describing: p1))
        }
      }
      internal enum Degraded {
        internal enum Alert {
          /// New Device
          internal static let title = L10n.tr("Localizable", "call.degraded.alert.title")
          internal enum Action {
            /// Call anyway
            internal static let `continue` = L10n.tr("Localizable", "call.degraded.alert.action.continue")
          }
          internal enum Message {
            /// You started using a new device.
            internal static let `self` = L10n.tr("Localizable", "call.degraded.alert.message.self")
            /// Someone started using a new device.
            internal static let unknown = L10n.tr("Localizable", "call.degraded.alert.message.unknown")
            /// %@ started using a new device.
            internal static func user(_ p1: Any) -> String {
              return L10n.tr("Localizable", "call.degraded.alert.message.user", String(describing: p1))
            }
          }
        }
        internal enum Ended {
          internal enum Alert {
            /// Call ended
            internal static let title = L10n.tr("Localizable", "call.degraded.ended.alert.title")
            internal enum Message {
              /// The call was disconnected because you started using a new device.
              internal static let `self` = L10n.tr("Localizable", "call.degraded.ended.alert.message.self")
              /// The call was disconnected because someone is no longer a verified contact.
              internal static let unknown = L10n.tr("Localizable", "call.degraded.ended.alert.message.unknown")
              /// The call was disconnected because %@ is no longer a verified contact.
              internal static func user(_ p1: Any) -> String {
                return L10n.tr("Localizable", "call.degraded.ended.alert.message.user", String(describing: p1))
              }
            }
          }
        }
      }
      internal enum Grid {
        /// No active video speakers...
        internal static let noActiveSpeakers = L10n.tr("Localizable", "call.grid.no_active_speakers")
        internal enum Hints {
          /// Double tap on a tile for fullscreen
          internal static let fullscreen = L10n.tr("Localizable", "call.grid.hints.fullscreen")
          /// Double tap to go back
          internal static let goBack = L10n.tr("Localizable", "call.grid.hints.go_back")
          /// Double tap to go back, pinch to zoom
          internal static let goBackOrZoom = L10n.tr("Localizable", "call.grid.hints.go_back_or_zoom")
          /// Pinch to zoom
          internal static let zoom = L10n.tr("Localizable", "call.grid.hints.zoom")
        }
      }
      internal enum Overlay {
        internal enum SwitchTo {
          /// ALL
          internal static let all = L10n.tr("Localizable", "call.overlay.switch_to.all")
          /// SPEAKERS
          internal static let speakers = L10n.tr("Localizable", "call.overlay.switch_to.speakers")
        }
      }
      internal enum Participants {
        /// Participants (%d)
        internal static func showAll(_ p1: Int) -> String {
          return L10n.tr("Localizable", "call.participants.show_all", p1)
        }
        internal enum List {
          /// Participants
          internal static let title = L10n.tr("Localizable", "call.participants.list.title")
        }
      }
      internal enum Quality {
        internal enum Indicator {
          /// Your calling relay is not reachable. This may affect your call experience.
          internal static let message = L10n.tr("Localizable", "call.quality.indicator.message")
          internal enum MoreInfo {
            internal enum Button {
              /// More info
              internal static let text = L10n.tr("Localizable", "call.quality.indicator.more_info.button.text")
            }
          }
        }
      }
      internal enum Status {
        /// Connecting…
        internal static let connecting = L10n.tr("Localizable", "call.status.connecting")
        /// Constant Bit Rate
        internal static let constantBitrate = L10n.tr("Localizable", "call.status.constant_bitrate")
        /// Calling…
        internal static let incoming = L10n.tr("Localizable", "call.status.incoming")
        /// Ringing…
        internal static let outgoing = L10n.tr("Localizable", "call.status.outgoing")
        /// Reconnecting…
        internal static let reconnecting = L10n.tr("Localizable", "call.status.reconnecting")
        /// Hanging up…
        internal static let terminating = L10n.tr("Localizable", "call.status.terminating")
        /// Variable Bit Rate
        internal static let variableBitrate = L10n.tr("Localizable", "call.status.variable_bitrate")
        internal enum Incoming {
          /// %@ is calling…
          internal static func user(_ p1: Any) -> String {
            return L10n.tr("Localizable", "call.status.incoming.user", String(describing: p1))
          }
        }
        internal enum Outgoing {
          /// Calling %@…
          internal static func user(_ p1: Any) -> String {
            return L10n.tr("Localizable", "call.status.outgoing.user", String(describing: p1))
          }
        }
      }
      internal enum Video {
        /// Video paused
        internal static let paused = L10n.tr("Localizable", "call.video.paused")
        internal enum TooMany {
          internal enum Alert {
            /// Video calls only work in groups of 4 or less.
            internal static let message = L10n.tr("Localizable", "call.video.too_many.alert.message")
            /// Too many people for Video
            internal static let title = L10n.tr("Localizable", "call.video.too_many.alert.title")
          }
        }
      }
    }
    internal enum Calling {
      internal enum QualitySurvey {
        /// How do you rate the overall quality of the call?
        internal static let question = L10n.tr("Localizable", "calling.quality_survey.question")
        /// Skip
        internal static let skipButtonTitle = L10n.tr("Localizable", "calling.quality_survey.skip_button_title")
        /// Call Quality Feedback
        internal static let title = L10n.tr("Localizable", "calling.quality_survey.title")
        internal enum Answer {
          /// Bad
          internal static let _1 = L10n.tr("Localizable", "calling.quality_survey.answer.1")
          /// Poor
          internal static let _2 = L10n.tr("Localizable", "calling.quality_survey.answer.2")
          /// Fair
          internal static let _3 = L10n.tr("Localizable", "calling.quality_survey.answer.3")
          /// Good
          internal static let _4 = L10n.tr("Localizable", "calling.quality_survey.answer.4")
          /// Excellent
          internal static let _5 = L10n.tr("Localizable", "calling.quality_survey.answer.5")
        }
      }
    }
    internal enum CameraAccess {
      /// Wire needs access to the camera
      internal static let denied = L10n.tr("Localizable", "camera_access.denied")
      internal enum Denied {
        /// 
        internal static let instruction = L10n.tr("Localizable", "camera_access.denied.instruction")
        /// Enable it in Wire Settings
        internal static let openSettings = L10n.tr("Localizable", "camera_access.denied.open_settings")
      }
    }
    internal enum CameraControls {
      /// AE/AF Lock
      internal static let aeafLock = L10n.tr("Localizable", "camera_controls.aeaf_lock")
    }
    internal enum Collections {
      internal enum ImageViewer {
        internal enum Copied {
          /// Picture copied
          internal static let title = L10n.tr("Localizable", "collections.image_viewer.copied.title")
        }
      }
      internal enum Search {
        /// No results
        internal static let noItems = L10n.tr("Localizable", "collections.search.no_items")
        internal enum Field {
          /// Search text messages
          internal static let placeholder = L10n.tr("Localizable", "collections.search.field.placeholder")
        }
      }
      internal enum Section {
        /// No items in collection
        internal static let noItems = L10n.tr("Localizable", "collections.section.no_items")
        internal enum All {
          /// Show all %d →
          internal static func button(_ p1: Int) -> String {
            return L10n.tr("Localizable", "collections.section.all.button", p1)
          }
        }
        internal enum Files {
          /// Files
          internal static let title = L10n.tr("Localizable", "collections.section.files.title")
        }
        internal enum Images {
          /// Images
          internal static let title = L10n.tr("Localizable", "collections.section.images.title")
        }
        internal enum Links {
          /// Links
          internal static let title = L10n.tr("Localizable", "collections.section.links.title")
        }
        internal enum Videos {
          /// Videos
          internal static let title = L10n.tr("Localizable", "collections.section.videos.title")
        }
      }
    }
    internal enum Compose {
      internal enum Contact {
        /// Conversation
        internal static let title = L10n.tr("Localizable", "compose.contact.title")
      }
      internal enum Drafts {
        /// Messages
        internal static let title = L10n.tr("Localizable", "compose.drafts.title")
        internal enum Compose {
          /// Type a message
          internal static let title = L10n.tr("Localizable", "compose.drafts.compose.title")
          internal enum Delete {
            internal enum Confirm {
              /// This action will permanently delete this draft and cannot be undone.
              internal static let message = L10n.tr("Localizable", "compose.drafts.compose.delete.confirm.message")
              /// Confirm Deletion
              internal static let title = L10n.tr("Localizable", "compose.drafts.compose.delete.confirm.title")
              internal enum Action {
                /// Delete
                internal static let title = L10n.tr("Localizable", "compose.drafts.compose.delete.confirm.action.title")
              }
            }
          }
          internal enum Dismiss {
            internal enum Confirm {
              /// Save as draft
              internal static let title = L10n.tr("Localizable", "compose.drafts.compose.dismiss.confirm.title")
              internal enum Action {
                /// Save
                internal static let title = L10n.tr("Localizable", "compose.drafts.compose.dismiss.confirm.action.title")
              }
            }
            internal enum Delete {
              internal enum Action {
                /// Delete
                internal static let title = L10n.tr("Localizable", "compose.drafts.compose.dismiss.delete.action.title")
              }
            }
          }
          internal enum Subject {
            /// Tap to set a subject
            internal static let placeholder = L10n.tr("Localizable", "compose.drafts.compose.subject.placeholder")
          }
        }
        internal enum Empty {
          /// Tap + to compose one
          internal static let subtitle = L10n.tr("Localizable", "compose.drafts.empty.subtitle")
          /// No messages
          internal static let title = L10n.tr("Localizable", "compose.drafts.empty.title")
        }
      }
      internal enum Message {
        /// Message
        internal static let title = L10n.tr("Localizable", "compose.message.title")
      }
    }
    internal enum ConnectionRequest {
      /// Connect
      internal static let sendButtonTitle = L10n.tr("Localizable", "connection_request.send_button_title")
      /// Connect to %@
      internal static func title(_ p1: Any) -> String {
        return L10n.tr("Localizable", "connection_request.title", String(describing: p1))
      }
    }
    internal enum ContactsUi {
      /// Requested to connect
      internal static let connectionRequest = L10n.tr("Localizable", "contacts_ui.connection_request")
      /// Invite others
      internal static let inviteOthers = L10n.tr("Localizable", "contacts_ui.invite_others")
      /// %@ in Contacts
      internal static func nameInContacts(_ p1: Any) -> String {
        return L10n.tr("Localizable", "contacts_ui.name_in_contacts", String(describing: p1))
      }
      /// Search by name
      internal static let searchPlaceholder = L10n.tr("Localizable", "contacts_ui.search_placeholder")
      /// Invite people
      internal static let title = L10n.tr("Localizable", "contacts_ui.title")
      internal enum ActionButton {
        /// Invite
        internal static let invite = L10n.tr("Localizable", "contacts_ui.action_button.invite")
        /// Open
        internal static let `open` = L10n.tr("Localizable", "contacts_ui.action_button.open")
      }
      internal enum InviteSheet {
        /// Cancel
        internal static let cancelButtonTitle = L10n.tr("Localizable", "contacts_ui.invite_sheet.cancel_button_title")
      }
      internal enum Notification {
        /// Failed to send invitation
        internal static let invitationFailed = L10n.tr("Localizable", "contacts_ui.notification.invitation_failed")
        /// Invitation sent
        internal static let invitationSent = L10n.tr("Localizable", "contacts_ui.notification.invitation_sent")
      }
    }
    internal enum Content {
      internal enum File {
        /// Browse
        internal static let browse = L10n.tr("Localizable", "content.file.browse")
        /// Downloading…
        internal static let downloading = L10n.tr("Localizable", "content.file.downloading")
        /// Save
        internal static let saveAudio = L10n.tr("Localizable", "content.file.save_audio")
        /// Save
        internal static let saveVideo = L10n.tr("Localizable", "content.file.save_video")
        /// Record a video
        internal static let takeVideo = L10n.tr("Localizable", "content.file.take_video")
        /// You can send files up to %@
        internal static func tooBig(_ p1: Any) -> String {
          return L10n.tr("Localizable", "content.file.too_big", String(describing: p1))
        }
        /// Upload cancelled
        internal static let uploadCancelled = L10n.tr("Localizable", "content.file.upload_cancelled")
        /// Upload failed
        internal static let uploadFailed = L10n.tr("Localizable", "content.file.upload_failed")
        /// Videos
        internal static let uploadVideo = L10n.tr("Localizable", "content.file.upload_video")
        /// Uploading…
        internal static let uploading = L10n.tr("Localizable", "content.file.uploading")
      }
      internal enum Image {
        /// Save
        internal static let saveImage = L10n.tr("Localizable", "content.image.save_image")
      }
      internal enum Message {
        /// Copy
        internal static let copy = L10n.tr("Localizable", "content.message.copy")
        /// Delete
        internal static let delete = L10n.tr("Localizable", "content.message.delete")
        /// Delete…
        internal static let deleteEllipsis = L10n.tr("Localizable", "content.message.delete_ellipsis")
        /// Details
        internal static let details = L10n.tr("Localizable", "content.message.details")
        /// Download
        internal static let download = L10n.tr("Localizable", "content.message.download")
        /// Share
        internal static let forward = L10n.tr("Localizable", "content.message.forward")
        /// Reveal
        internal static let goToConversation = L10n.tr("Localizable", "content.message.go_to_conversation")
        /// Like
        internal static let like = L10n.tr("Localizable", "content.message.like")
        /// Open
        internal static let `open` = L10n.tr("Localizable", "content.message.open")
        /// Original message
        internal static let originalLabel = L10n.tr("Localizable", "content.message.original_label")
        /// Reply
        internal static let reply = L10n.tr("Localizable", "content.message.reply")
        /// Resend
        internal static let resend = L10n.tr("Localizable", "content.message.resend")
        /// Save
        internal static let save = L10n.tr("Localizable", "content.message.save")
        /// Sign
        internal static let sign = L10n.tr("Localizable", "content.message.sign")
        /// Unlike
        internal static let unlike = L10n.tr("Localizable", "content.message.unlike")
        internal enum AudioMessage {
          /// Play the audio message
          internal static let accessibility = L10n.tr("Localizable", "content.message.audio_message.accessibility")
        }
        internal enum Forward {
          /// Search…
          internal static let to = L10n.tr("Localizable", "content.message.forward.to")
        }
        internal enum LinkAttachment {
          internal enum AccessibilityLabel {
            /// SoundCloud playlist preview
            internal static let soundcloudSet = L10n.tr("Localizable", "content.message.link_attachment.accessibility_label.soundcloud_set")
            /// SoundCloud song preview
            internal static let soundcloudSong = L10n.tr("Localizable", "content.message.link_attachment.accessibility_label.soundcloud_song")
            /// YouTube video preview
            internal static let youtube = L10n.tr("Localizable", "content.message.link_attachment.accessibility_label.youtube")
          }
        }
        internal enum OpenLinkAlert {
          /// This will take you to
          /// %@
          internal static func message(_ p1: Any) -> String {
            return L10n.tr("Localizable", "content.message.open_link_alert.message", String(describing: p1))
          }
          /// Open
          internal static let `open` = L10n.tr("Localizable", "content.message.open_link_alert.open")
          /// Visit Link
          internal static let title = L10n.tr("Localizable", "content.message.open_link_alert.title")
        }
        internal enum Reply {
          /// You cannot see this message.
          internal static let brokenMessage = L10n.tr("Localizable", "content.message.reply.broken_message")
          /// Edited
          internal static let editedMessage = L10n.tr("Localizable", "content.message.reply.edited_message")
          internal enum OriginalTimestamp {
            /// Original message from %@
            internal static func date(_ p1: Any) -> String {
              return L10n.tr("Localizable", "content.message.reply.original_timestamp.date", String(describing: p1))
            }
            /// Original message from %@
            internal static func time(_ p1: Any) -> String {
              return L10n.tr("Localizable", "content.message.reply.original_timestamp.time", String(describing: p1))
            }
          }
        }
      }
      internal enum Ping {
        /// %@ pinged
        internal static func text(_ p1: Any) -> String {
          return L10n.tr("Localizable", "content.ping.text", String(describing: p1))
        }
        /// %@ pinged
        internal static func textYou(_ p1: Any) -> String {
          return L10n.tr("Localizable", "content.ping.text-you", String(describing: p1))
        }
        internal enum Text {
          /// You
          internal static let you = L10n.tr("Localizable", "content.ping.text.you")
        }
      }
      internal enum Player {
        /// UNABLE TO PLAY TRACK
        internal static let unableToPlay = L10n.tr("Localizable", "content.player.unable_to_play")
      }
      internal enum ReactionsList {
        /// Liked by
        internal static let likers = L10n.tr("Localizable", "content.reactions_list.likers")
      }
      internal enum System {
        /// and you
        internal static let andYouDative = L10n.tr("Localizable", "content.system.and_you_dative")
        /// Connected to %@
        /// Start a conversation
        internal static func connectedTo(_ p1: Any) -> String {
          return L10n.tr("Localizable", "content.system.connected_to", String(describing: p1))
        }
        /// Connecting to %@.
        /// Start a conversation
        internal static func connectingTo(_ p1: Any) -> String {
          return L10n.tr("Localizable", "content.system.connecting_to", String(describing: p1))
        }
        /// Start a conversation with %@
        internal static func continuedConversation(_ p1: Any) -> String {
          return L10n.tr("Localizable", "content.system.continued_conversation", String(describing: p1))
        }
        /// Deleted: %@
        internal static func deletedMessagePrefixTimestamp(_ p1: Any) -> String {
          return L10n.tr("Localizable", "content.system.deleted_message_prefix_timestamp", String(describing: p1))
        }
        /// Edited: %@
        internal static func editedMessagePrefixTimestamp(_ p1: Any) -> String {
          return L10n.tr("Localizable", "content.system.edited_message_prefix_timestamp", String(describing: p1))
        }
        /// %@ left
        internal static func ephemeralTimeRemaining(_ p1: Any) -> String {
          return L10n.tr("Localizable", "content.system.ephemeral_time_remaining", String(describing: p1))
        }
        /// Sending failed.
        internal static let failedtosendMessageTimestamp = L10n.tr("Localizable", "content.system.failedtosend_message_timestamp")
        /// Delete
        internal static let failedtosendMessageTimestampDelete = L10n.tr("Localizable", "content.system.failedtosend_message_timestamp_delete")
        /// Resend
        internal static let failedtosendMessageTimestampResend = L10n.tr("Localizable", "content.system.failedtosend_message_timestamp_resend")
        /// All fingerprints are verified
        internal static let isVerified = L10n.tr("Localizable", "content.system.is_verified")
        /// Tap to like
        internal static let likeTooltip = L10n.tr("Localizable", "content.system.like_tooltip")
        /// Delivered
        internal static let messageDeliveredTimestamp = L10n.tr("Localizable", "content.system.message_delivered_timestamp")
        /// %@ turned read receipts off for everyone
        internal static func messageReadReceiptOff(_ p1: Any) -> String {
          return L10n.tr("Localizable", "content.system.message_read_receipt_off", String(describing: p1))
        }
        /// %@ turned read receipts off for everyone
        internal static func messageReadReceiptOffYou(_ p1: Any) -> String {
          return L10n.tr("Localizable", "content.system.message_read_receipt_off-you", String(describing: p1))
        }
        /// %@ turned read receipts on for everyone
        internal static func messageReadReceiptOn(_ p1: Any) -> String {
          return L10n.tr("Localizable", "content.system.message_read_receipt_on", String(describing: p1))
        }
        /// %@ turned read receipts on for everyone
        internal static func messageReadReceiptOnYou(_ p1: Any) -> String {
          return L10n.tr("Localizable", "content.system.message_read_receipt_on-you", String(describing: p1))
        }
        /// Read receipts are on
        internal static let messageReadReceiptOnAddToGroup = L10n.tr("Localizable", "content.system.message_read_receipt_on_add_to_group")
        /// Seen
        internal static let messageReadTimestamp = L10n.tr("Localizable", "content.system.message_read_timestamp")
        /// Sent
        internal static let messageSentTimestamp = L10n.tr("Localizable", "content.system.message_sent_timestamp")
        /// %@ set the message timer to %@
        internal static func messageTimerChanges(_ p1: Any, _ p2: Any) -> String {
          return L10n.tr("Localizable", "content.system.message_timer_changes", String(describing: p1), String(describing: p2))
        }
        /// %@ set the message timer to %@
        internal static func messageTimerChangesYou(_ p1: Any, _ p2: Any) -> String {
          return L10n.tr("Localizable", "content.system.message_timer_changes-you", String(describing: p1), String(describing: p2))
        }
        /// %@ turned off the message timer
        internal static func messageTimerOff(_ p1: Any) -> String {
          return L10n.tr("Localizable", "content.system.message_timer_off", String(describing: p1))
        }
        /// %@ turned off the message timer
        internal static func messageTimerOffYou(_ p1: Any) -> String {
          return L10n.tr("Localizable", "content.system.message_timer_off-you", String(describing: p1))
        }
        /// Plural format key: "%#@d_new_devices@"
        internal static func newDevices(_ p1: Int) -> String {
          return L10n.tr("Localizable", "content.system.new_devices", p1)
        }
        /// New user joined.
        internal static let newUsers = L10n.tr("Localizable", "content.system.new_users")
        /// %@ added %@
        internal static func otherAddedParticipant(_ p1: Any, _ p2: Any) -> String {
          return L10n.tr("Localizable", "content.system.other_added_participant", String(describing: p1), String(describing: p2))
        }
        /// %@ added you
        internal static func otherAddedYou(_ p1: Any) -> String {
          return L10n.tr("Localizable", "content.system.other_added_you", String(describing: p1))
        }
        /// %@ left
        internal static func otherLeft(_ p1: Any) -> String {
          return L10n.tr("Localizable", "content.system.other_left", String(describing: p1))
        }
        /// %@ removed %@
        internal static func otherRemovedOther(_ p1: Any, _ p2: Any) -> String {
          return L10n.tr("Localizable", "content.system.other_removed_other", String(describing: p1), String(describing: p2))
        }
        /// %@ removed you
        internal static func otherRemovedYou(_ p1: Any) -> String {
          return L10n.tr("Localizable", "content.system.other_removed_you", String(describing: p1))
        }
        /// %@ removed the conversation name
        internal static func otherRenamedConvToNothing(_ p1: Any) -> String {
          return L10n.tr("Localizable", "content.system.other_renamed_conv_to_nothing", String(describing: p1))
        }
        /// %@ started a conversation with %@
        internal static func otherStartedConversation(_ p1: Any, _ p2: Any) -> String {
          return L10n.tr("Localizable", "content.system.other_started_conversation", String(describing: p1), String(describing: p2))
        }
        /// %@ called
        internal static func otherWantedToTalk(_ p1: Any) -> String {
          return L10n.tr("Localizable", "content.system.other_wanted_to_talk", String(describing: p1))
        }
        /// %@ and %@
        internal static func participants1Other(_ p1: Any, _ p2: Any) -> String {
          return L10n.tr("Localizable", "content.system.participants_1_other", String(describing: p1), String(describing: p2))
        }
        /// Plural format key: "%@ %#@and_number_of_others@"
        internal static func participantsNOthers(_ p1: Any, _ p2: Int) -> String {
          return L10n.tr("Localizable", "content.system.participants_n_others", String(describing: p1), p2)
        }
        /// You
        internal static let participantsYou = L10n.tr("Localizable", "content.system.participants_you")
        /// Sending…
        internal static let pendingMessageTimestamp = L10n.tr("Localizable", "content.system.pending_message_timestamp")
        /// Plural format key: "%@%#@d_number_of_others@ started using %#@d_new_devices@"
        internal static func peopleStartedUsing(_ p1: Any, _ p2: Int, _ p3: Int) -> String {
          return L10n.tr("Localizable", "content.system.people_started_using", String(describing: p1), p2, p3)
        }
        /// You started using [this device](%@) again. Messages sent in the meantime will not appear here.
        internal static func reactivatedDevice(_ p1: Any) -> String {
          return L10n.tr("Localizable", "content.system.reactivated_device", String(describing: p1))
        }
        /// **You** started using [a new device](%@)
        internal static func selfUserNewClient(_ p1: Any) -> String {
          return L10n.tr("Localizable", "content.system.self_user_new_client", String(describing: p1))
        }
        /// **You** started using [this device](%@)
        internal static func selfUserNewSelfClient(_ p1: Any) -> String {
          return L10n.tr("Localizable", "content.system.self_user_new_self_client", String(describing: p1))
        }
        /// **You** unverified one of [%1$@’s devices](%2$@)
        internal static func unverifiedOtherDevices(_ p1: Any, _ p2: Any) -> String {
          return L10n.tr("Localizable", "content.system.unverified_other_devices", String(describing: p1), String(describing: p2))
        }
        /// **You** unverified one of [your devices](%@)
        internal static func unverifiedSelfDevices(_ p1: Any) -> String {
          return L10n.tr("Localizable", "content.system.unverified_self_devices", String(describing: p1))
        }
        /// Verify devices
        internal static let verifyDevices = L10n.tr("Localizable", "content.system.verify_devices")
        /// you
        internal static let youAccusative = L10n.tr("Localizable", "content.system.you_accusative")
        /// You added %@
        internal static func youAddedParticipant(_ p1: Any) -> String {
          return L10n.tr("Localizable", "content.system.you_added_participant", String(describing: p1))
        }
        /// you
        internal static let youDative = L10n.tr("Localizable", "content.system.you_dative")
        /// You left
        internal static let youLeft = L10n.tr("Localizable", "content.system.you_left")
        /// you
        internal static let youNominative = L10n.tr("Localizable", "content.system.you_nominative")
        /// You removed %@
        internal static func youRemovedOther(_ p1: Any) -> String {
          return L10n.tr("Localizable", "content.system.you_removed_other", String(describing: p1))
        }
        /// You removed the conversation name
        internal static let youRenamedConvToNothing = L10n.tr("Localizable", "content.system.you_renamed_conv_to_nothing")
        /// You
        internal static let youStarted = L10n.tr("Localizable", "content.system.you_started")
        /// You started a conversation with %@
        internal static func youStartedConversation(_ p1: Any) -> String {
          return L10n.tr("Localizable", "content.system.you_started_conversation", String(describing: p1))
        }
        /// You called
        internal static let youWantedToTalk = L10n.tr("Localizable", "content.system.you_wanted_to_talk")
        internal enum Call {
          /// %@ called
          internal static func called(_ p1: Any) -> String {
            return L10n.tr("Localizable", "content.system.call.called", String(describing: p1))
          }
          /// %@ called
          internal static func calledYou(_ p1: Any) -> String {
            return L10n.tr("Localizable", "content.system.call.called-you", String(describing: p1))
          }
          /// Plural format key: "%#@missed_call@"
          internal static func missedCall(_ p1: Int) -> String {
            return L10n.tr("Localizable", "content.system.call.missed-call", p1)
          }
          /// Missed call
          internal static let missedCallYou = L10n.tr("Localizable", "content.system.call.missed-call-you")
          internal enum Called {
            /// You
            internal static let you = L10n.tr("Localizable", "content.system.call.called.you")
          }
          internal enum MissedCall {
            /// Plural format key: "%#@missed_call_from@"
            internal static func groups(_ p1: Int) -> String {
              return L10n.tr("Localizable", "content.system.call.missed-call.groups", p1)
            }
            /// Plural format key: "%#@missed_call_from@"
            internal static func groupsYou(_ p1: Int) -> String {
              return L10n.tr("Localizable", "content.system.call.missed-call.groups-you", p1)
            }
            internal enum Groups {
              /// You
              internal static let you = L10n.tr("Localizable", "content.system.call.missed-call.groups.you")
            }
          }
        }
        internal enum CannotDecrypt {
          /// (Fixed error: %d ID: %@)
          internal static func errorDetails(_ p1: Int, _ p2: Any) -> String {
            return L10n.tr("Localizable", "content.system.cannot_decrypt.error_details", p1, String(describing: p2))
          }
          /// A message from **%@** could not be decrypted.
          internal static func other(_ p1: Any) -> String {
            return L10n.tr("Localizable", "content.system.cannot_decrypt.other", String(describing: p1))
          }
          /// Fix future messages
          internal static let resetSession = L10n.tr("Localizable", "content.system.cannot_decrypt.reset_session")
          /// A message from **you** could not be decrypted.
          internal static let `self` = L10n.tr("Localizable", "content.system.cannot_decrypt.self")
        }
        internal enum CannotDecryptIdentityChanged {
          /// **%@’s** device identity changed. Undelivered message.
          internal static func other(_ p1: Any) -> String {
            return L10n.tr("Localizable", "content.system.cannot_decrypt_identity_changed.other", String(describing: p1))
          }
          /// **Your** device identity changed. Undelivered message.
          internal static let `self` = L10n.tr("Localizable", "content.system.cannot_decrypt_identity_changed.self")
        }
        internal enum CannotDecryptResolved {
          /// You can now decrypt messages from **%1$@**. To recover lost messages, **ask %1$@ to resend them.**
          internal static func other(_ p1: Any) -> String {
            return L10n.tr("Localizable", "content.system.cannot_decrypt_resolved.other", String(describing: p1))
          }
          /// You can now decrypt messages from yourself. To recover lost messages, **you need to resend them.**
          internal static let `self` = L10n.tr("Localizable", "content.system.cannot_decrypt_resolved.self")
        }
        internal enum Conversation {
          internal enum Guest {
            /// %@ joined
            internal static func joined(_ p1: Any) -> String {
              return L10n.tr("Localizable", "content.system.conversation.guest.joined", String(describing: p1))
            }
            /// You joined
            internal static let youJoined = L10n.tr("Localizable", "content.system.conversation.guest.you_joined")
          }
          internal enum Invite {
            /// Invite people
            internal static let button = L10n.tr("Localizable", "content.system.conversation.invite.button")
            /// People outside your team can join this conversation.
            internal static let title = L10n.tr("Localizable", "content.system.conversation.invite.title")
          }
          internal enum Other {
            /// %@ added %@
            internal static func added(_ p1: Any, _ p2: Any) -> String {
              return L10n.tr("Localizable", "content.system.conversation.other.added", String(describing: p1), String(describing: p2))
            }
            /// %@ left
            internal static func `left`(_ p1: Any) -> String {
              return L10n.tr("Localizable", "content.system.conversation.other.left", String(describing: p1))
            }
            /// %@ removed %@
            internal static func removed(_ p1: Any, _ p2: Any) -> String {
              return L10n.tr("Localizable", "content.system.conversation.other.removed", String(describing: p1), String(describing: p2))
            }
            /// %@ started a conversation with %@
            internal static func started(_ p1: Any, _ p2: Any) -> String {
              return L10n.tr("Localizable", "content.system.conversation.other.started", String(describing: p1), String(describing: p2))
            }
            internal enum Removed {
              /// %@ was removed from this conversation because legal hold has been activated.
              internal static func legalhold(_ p1: Any) -> String {
                return L10n.tr("Localizable", "content.system.conversation.other.removed.legalhold", String(describing: p1))
              }
            }
          }
          internal enum Others {
            internal enum Removed {
              /// %@ were removed from this conversation because legal hold has been activated.
              internal static func legalhold(_ p1: Any) -> String {
                return L10n.tr("Localizable", "content.system.conversation.others.removed.legalhold", String(describing: p1))
              }
            }
          }
          internal enum Team {
            /// %@ was removed from the team.
            internal static func memberLeave(_ p1: Any) -> String {
              return L10n.tr("Localizable", "content.system.conversation.team.member-leave", String(describing: p1))
            }
          }
          internal enum WithName {
            /// with
            internal static let participants = L10n.tr("Localizable", "content.system.conversation.with_name.participants")
            /// %@ started the conversation
            internal static func title(_ p1: Any) -> String {
              return L10n.tr("Localizable", "content.system.conversation.with_name.title", String(describing: p1))
            }
            /// %@ started the conversation
            internal static func titleYou(_ p1: Any) -> String {
              return L10n.tr("Localizable", "content.system.conversation.with_name.title-you", String(describing: p1))
            }
          }
          internal enum You {
            /// %@ added %@
            internal static func added(_ p1: Any, _ p2: Any) -> String {
              return L10n.tr("Localizable", "content.system.conversation.you.added", String(describing: p1), String(describing: p2))
            }
            /// %@ left
            internal static func `left`(_ p1: Any) -> String {
              return L10n.tr("Localizable", "content.system.conversation.you.left", String(describing: p1))
            }
            /// %@ removed %@
            internal static func removed(_ p1: Any, _ p2: Any) -> String {
              return L10n.tr("Localizable", "content.system.conversation.you.removed", String(describing: p1), String(describing: p2))
            }
            /// %@ started a conversation with %@
            internal static func started(_ p1: Any, _ p2: Any) -> String {
              return L10n.tr("Localizable", "content.system.conversation.you.started", String(describing: p1), String(describing: p2))
            }
            internal enum Removed {
              /// %@ were removed from this conversation because legal hold has been activated.
              internal static func legalhold(_ p1: Any) -> String {
                return L10n.tr("Localizable", "content.system.conversation.you.removed.legalhold", String(describing: p1))
              }
            }
          }
        }
        internal enum MessageLegalHold {
          /// Legal hold deactivated for this conversation
          internal static let disabled = L10n.tr("Localizable", "content.system.message_legal_hold.disabled")
          /// This conversation is under legal hold
          internal static let enabled = L10n.tr("Localizable", "content.system.message_legal_hold.enabled")
          /// Learn more
          internal static let learnMore = L10n.tr("Localizable", "content.system.message_legal_hold.learn_more")
        }
        internal enum MissingMessages {
          /// Plural format key: "%@ %#@lu_number_of_users@"
          internal static func subtitleAdded(_ p1: Any, _ p2: Int) -> String {
            return L10n.tr("Localizable", "content.system.missing_messages.subtitle_added", String(describing: p1), p2)
          }
          /// Plural format key: "%@ %#@lu_number_of_users@"
          internal static func subtitleRemoved(_ p1: Any, _ p2: Int) -> String {
            return L10n.tr("Localizable", "content.system.missing_messages.subtitle_removed", String(describing: p1), p2)
          }
          /// Meanwhile,
          internal static let subtitleStart = L10n.tr("Localizable", "content.system.missing_messages.subtitle_start")
          /// You haven’t used this device for a while. Some messages may not appear here.
          internal static let title = L10n.tr("Localizable", "content.system.missing_messages.title")
        }
        internal enum RenamedConv {
          /// %@ renamed the conversation
          internal static func title(_ p1: Any) -> String {
            return L10n.tr("Localizable", "content.system.renamed_conv.title", String(describing: p1))
          }
          /// %@ renamed the conversation
          internal static func titleYou(_ p1: Any) -> String {
            return L10n.tr("Localizable", "content.system.renamed_conv.title-you", String(describing: p1))
          }
          internal enum Title {
            /// You
            internal static let you = L10n.tr("Localizable", "content.system.renamed_conv.title.you")
          }
        }
        internal enum Services {
          /// Services have access to the content of this conversation
          internal static let warning = L10n.tr("Localizable", "content.system.services.warning")
        }
        internal enum SessionReset {
          /// **%@ was unable to decrypt some of your messages but has solved the issue**. This affected all conversations you share together.
          internal static func other(_ p1: Any) -> String {
            return L10n.tr("Localizable", "content.system.session_reset.other", String(describing: p1))
          }
          /// **You were unable to decrypt some of your messages but you solved the issue**. This affected all conversations.
          internal static let `self` = L10n.tr("Localizable", "content.system.session_reset.self")
        }
        internal enum StartedConversation {
          /// all team members
          internal static let completeTeam = L10n.tr("Localizable", "content.system.started_conversation.complete_team")
          /// and %@
          internal static func truncatedPeople(_ p1: Any) -> String {
            return L10n.tr("Localizable", "content.system.started_conversation.truncated_people", String(describing: p1))
          }
          internal enum CompleteTeam {
            /// all team members and %@ guests
            internal static func guests(_ p1: Any) -> String {
              return L10n.tr("Localizable", "content.system.started_conversation.complete_team.guests", String(describing: p1))
            }
          }
          internal enum TruncatedPeople {
            /// %@ others
            internal static func others(_ p1: Any) -> String {
              return L10n.tr("Localizable", "content.system.started_conversation.truncated_people.others", String(describing: p1))
            }
          }
        }
        internal enum UnknownMessage {
          /// This message can’t be displayed. You may be using an older version of Wire.
          internal static let body = L10n.tr("Localizable", "content.system.unknown_message.body")
        }
      }
    }
    internal enum Conversation {
      internal enum Action {
        /// Search
        internal static let search = L10n.tr("Localizable", "conversation.action.search")
      }
      internal enum Alert {
        /// The message is deleted.
        internal static let messageDeleted = L10n.tr("Localizable", "conversation.alert.message_deleted")
      }
      internal enum Banner {
        /// %@ are active
        internal static func areActive(_ p1: Any) -> String {
          return L10n.tr("Localizable", "conversation.banner.are_active", String(describing: p1))
        }
        /// %@ are present
        internal static func arePresent(_ p1: Any) -> String {
          return L10n.tr("Localizable", "conversation.banner.are_present", String(describing: p1))
        }
        /// **Externals**
        internal static let externals = L10n.tr("Localizable", "conversation.banner.externals")
        /// **Guests**
        internal static let guests = L10n.tr("Localizable", "conversation.banner.guests")
        /// **Federated users**
        internal static let remotes = L10n.tr("Localizable", "conversation.banner.remotes")
        ///  and 
        internal static let separator = L10n.tr("Localizable", "conversation.banner.separator")
        /// **Services**
        internal static let services = L10n.tr("Localizable", "conversation.banner.services")
      }
      internal enum Call {
        internal enum ManyParticipantsConfirmation {
          /// Call
          internal static let call = L10n.tr("Localizable", "conversation.call.many_participants_confirmation.call")
          /// This will call %d people
          internal static func message(_ p1: Int) -> String {
            return L10n.tr("Localizable", "conversation.call.many_participants_confirmation.message", p1)
          }
          /// Start a call
          internal static let title = L10n.tr("Localizable", "conversation.call.many_participants_confirmation.title")
        }
      }
      internal enum ConnectionView {
        /// in Contacts
        internal static let inAddressBook = L10n.tr("Localizable", "conversation.connection_view.in_address_book")
      }
      internal enum Create {
        internal enum GroupName {
          /// Group name
          internal static let placeholder = L10n.tr("Localizable", "conversation.create.group_name.placeholder")
          /// Create group
          internal static let title = L10n.tr("Localizable", "conversation.create.group_name.title")
        }
        internal enum Guests {
          /// Open this conversation to people outside your team.
          internal static let subtitle = L10n.tr("Localizable", "conversation.create.guests.subtitle")
          /// Allow guests
          internal static let title = L10n.tr("Localizable", "conversation.create.guests.title")
        }
        internal enum Guidance {
          /// At least 1 character
          internal static let empty = L10n.tr("Localizable", "conversation.create.guidance.empty")
          /// Too many characters
          internal static let toolong = L10n.tr("Localizable", "conversation.create.guidance.toolong")
        }
        internal enum Options {
          /// Guests: %@, Services: %@, Read receipts: %@
          internal static func subtitle(_ p1: Any, _ p2: Any, _ p3: Any) -> String {
            return L10n.tr("Localizable", "conversation.create.options.subtitle", String(describing: p1), String(describing: p2), String(describing: p3))
          }
          /// Conversation options
          internal static let title = L10n.tr("Localizable", "conversation.create.options.title")
        }
        internal enum Receipts {
          /// When this is on, people can see when their messages in this conversation are read.
          internal static let subtitle = L10n.tr("Localizable", "conversation.create.receipts.subtitle")
          /// Read receipts
          internal static let title = L10n.tr("Localizable", "conversation.create.receipts.title")
        }
        internal enum Services {
          /// Open this conversation to services.
          internal static let subtitle = L10n.tr("Localizable", "conversation.create.services.subtitle")
          /// Allow services
          internal static let title = L10n.tr("Localizable", "conversation.create.services.title")
        }
      }
      internal enum DeleteRequestDialog {
        /// This will delete the group and all content for all participants on all devices. There is no option to restore the content. All participants will be notified.
        internal static let message = L10n.tr("Localizable", "conversation.delete_request_dialog.message")
        /// Delete group conversation?
        internal static let title = L10n.tr("Localizable", "conversation.delete_request_dialog.title")
      }
      internal enum DeleteRequestErrorDialog {
        /// Delete Group
        internal static let buttonDeleteGroup = L10n.tr("Localizable", "conversation.delete_request_error_dialog.button_delete_group")
        /// An error occurred while trying to delete the group %@. Please try again.
        internal static func title(_ p1: Any) -> String {
          return L10n.tr("Localizable", "conversation.delete_request_error_dialog.title", String(describing: p1))
        }
      }
      internal enum Displayname {
        /// Empty group conversation
        internal static let emptygroup = L10n.tr("Localizable", "conversation.displayname.emptygroup")
      }
      internal enum InputBar {
        /// Cancel reply
        internal static let closeReply = L10n.tr("Localizable", "conversation.input_bar.close_reply")
        /// Type a message
        internal static let placeholder = L10n.tr("Localizable", "conversation.input_bar.placeholder")
        /// Self-deleting message
        internal static let placeholderEphemeral = L10n.tr("Localizable", "conversation.input_bar.placeholder_ephemeral")
        /// Verified
        internal static let verified = L10n.tr("Localizable", "conversation.input_bar.verified")
        internal enum AudioMessage {
          /// Send
          internal static let send = L10n.tr("Localizable", "conversation.input_bar.audio_message.send")
          internal enum Keyboard {
            /// Choose a filter above
            internal static let filterTip = L10n.tr("Localizable", "conversation.input_bar.audio_message.keyboard.filter_tip")
            /// Tap to record
            /// You can  %@  it after that
            internal static func recordTip(_ p1: Any) -> String {
              return L10n.tr("Localizable", "conversation.input_bar.audio_message.keyboard.record_tip", String(describing: p1))
            }
          }
          internal enum TooLong {
            /// Audio messages are limited to %@.
            internal static func message(_ p1: Any) -> String {
              return L10n.tr("Localizable", "conversation.input_bar.audio_message.too_long.message", String(describing: p1))
            }
            /// Recording Stopped
            internal static let title = L10n.tr("Localizable", "conversation.input_bar.audio_message.too_long.title")
          }
          internal enum TooLongSize {
            /// File size for audio messages is limited to %@.
            internal static func message(_ p1: Any) -> String {
              return L10n.tr("Localizable", "conversation.input_bar.audio_message.too_long_size.message", String(describing: p1))
            }
          }
          internal enum Tooltip {
            /// Swipe up to send
            internal static let pullSend = L10n.tr("Localizable", "conversation.input_bar.audio_message.tooltip.pull_send")
            /// Tap to send
            internal static let tapSend = L10n.tr("Localizable", "conversation.input_bar.audio_message.tooltip.tap_send")
          }
        }
        internal enum MessagePreview {
          /// Replying to message: %@
          internal static func accessibilityDescription(_ p1: Any) -> String {
            return L10n.tr("Localizable", "conversation.input_bar.message_preview.accessibility_description", String(describing: p1))
          }
          /// Audio Message
          internal static let audio = L10n.tr("Localizable", "conversation.input_bar.message_preview.audio")
          /// File
          internal static let file = L10n.tr("Localizable", "conversation.input_bar.message_preview.file")
          /// Image
          internal static let image = L10n.tr("Localizable", "conversation.input_bar.message_preview.image")
          /// Location
          internal static let location = L10n.tr("Localizable", "conversation.input_bar.message_preview.location")
          /// Video
          internal static let video = L10n.tr("Localizable", "conversation.input_bar.message_preview.video")
          internal enum Accessibility {
            /// Audio message
            internal static let audioMessage = L10n.tr("Localizable", "conversation.input_bar.message_preview.accessibility.audio_message")
            /// File message (%@)
            internal static func fileMessage(_ p1: Any) -> String {
              return L10n.tr("Localizable", "conversation.input_bar.message_preview.accessibility.file_message", String(describing: p1))
            }
            /// Image message
            internal static let imageMessage = L10n.tr("Localizable", "conversation.input_bar.message_preview.accessibility.image_message")
            /// Location message
            internal static let locationMessage = L10n.tr("Localizable", "conversation.input_bar.message_preview.accessibility.location_message")
            /// %@ from %@
            internal static func messageFrom(_ p1: Any, _ p2: Any) -> String {
              return L10n.tr("Localizable", "conversation.input_bar.message_preview.accessibility.message_from", String(describing: p1), String(describing: p2))
            }
            /// Unknown message
            internal static let unknownMessage = L10n.tr("Localizable", "conversation.input_bar.message_preview.accessibility.unknown_message")
            /// Video message
            internal static let videoMessage = L10n.tr("Localizable", "conversation.input_bar.message_preview.accessibility.video_message")
          }
        }
        internal enum MessageTooLong {
          /// You can send messages up to %d characters long.
          internal static func message(_ p1: Int) -> String {
            return L10n.tr("Localizable", "conversation.input_bar.message_too_long.message", p1)
          }
          /// Message too long
          internal static let title = L10n.tr("Localizable", "conversation.input_bar.message_too_long.title")
        }
        internal enum OngoingCallAlert {
          /// Ongoing call
          internal static let title = L10n.tr("Localizable", "conversation.input_bar.ongoing_call_alert.title")
          internal enum Audio {
            /// You can’t record an audio message during a call.
            internal static let message = L10n.tr("Localizable", "conversation.input_bar.ongoing_call_alert.audio.message")
          }
          internal enum Photo {
            /// You can’t take a picture during a call.
            internal static let message = L10n.tr("Localizable", "conversation.input_bar.ongoing_call_alert.photo.message")
          }
          internal enum Video {
            /// You can’t record a video during a call.
            internal static let message = L10n.tr("Localizable", "conversation.input_bar.ongoing_call_alert.video.message")
          }
        }
        internal enum Shortcut {
          /// Cancel
          internal static let cancelEditingMessage = L10n.tr("Localizable", "conversation.input_bar.shortcut.cancel_editing_message")
          /// Choose next mention
          internal static let chooseNextMention = L10n.tr("Localizable", "conversation.input_bar.shortcut.choose_next_mention")
          /// Choose previous mention
          internal static let choosePreviousMention = L10n.tr("Localizable", "conversation.input_bar.shortcut.choose_previous_mention")
          /// Edit Last Message
          internal static let editLastMessage = L10n.tr("Localizable", "conversation.input_bar.shortcut.edit_last_message")
          /// Insert Line Break
          internal static let newline = L10n.tr("Localizable", "conversation.input_bar.shortcut.newline")
          /// Send Message
          internal static let send = L10n.tr("Localizable", "conversation.input_bar.shortcut.send")
        }
      }
      internal enum InviteMorePeople {
        /// Add People
        internal static let buttonTitle = L10n.tr("Localizable", "conversation.invite_more_people.button_title")
        /// Add people to this conversation
        internal static let description = L10n.tr("Localizable", "conversation.invite_more_people.description")
        /// https://support.wire.com
        internal static let explanationUrl = L10n.tr("Localizable", "conversation.invite_more_people.explanation_url")
        /// Spread the word!
        internal static let title = L10n.tr("Localizable", "conversation.invite_more_people.title")
      }
      internal enum Silenced {
        internal enum Status {
          internal enum Message {
            /// Plural format key: "%#@d_number_of_new@"
            internal static func genericMessage(_ p1: Int) -> String {
              return L10n.tr("Localizable", "conversation.silenced.status.message.generic_message", p1)
            }
            /// Plural format key: "%#@d_number_of_new@"
            internal static func knock(_ p1: Int) -> String {
              return L10n.tr("Localizable", "conversation.silenced.status.message.knock", p1)
            }
            /// Plural format key: "%#@d_number_of_new@"
            internal static func mention(_ p1: Int) -> String {
              return L10n.tr("Localizable", "conversation.silenced.status.message.mention", p1)
            }
            /// Plural format key: "%#@d_number_of_new@"
            internal static func missedcall(_ p1: Int) -> String {
              return L10n.tr("Localizable", "conversation.silenced.status.message.missedcall", p1)
            }
            /// Plural format key: "%#@d_number_of_new@"
            internal static func reply(_ p1: Int) -> String {
              return L10n.tr("Localizable", "conversation.silenced.status.message.reply", p1)
            }
          }
        }
      }
      internal enum Status {
        /// Blocked
        internal static let blocked = L10n.tr("Localizable", "conversation.status.blocked")
        /// %@ is calling…
        internal static func incomingCall(_ p1: Any) -> String {
          return L10n.tr("Localizable", "conversation.status.incoming_call", String(describing: p1))
        }
        /// Poor connection
        internal static let poorConnection = L10n.tr("Localizable", "conversation.status.poor_connection")
        /// Muted
        internal static let silenced = L10n.tr("Localizable", "conversation.status.silenced")
        /// Someone
        internal static let someone = L10n.tr("Localizable", "conversation.status.someone")
        /// %@ started a conversation
        internal static func startedConversation(_ p1: Any) -> String {
          return L10n.tr("Localizable", "conversation.status.started_conversation", String(describing: p1))
        }
        /// Typing a message…
        internal static let typing = L10n.tr("Localizable", "conversation.status.typing")
        /// ⚠️ Unsent message
        internal static let unsent = L10n.tr("Localizable", "conversation.status.unsent")
        /// You
        internal static let you = L10n.tr("Localizable", "conversation.status.you")
        /// You left
        internal static let youLeft = L10n.tr("Localizable", "conversation.status.you_left")
        /// %@ added you
        internal static func youWasAdded(_ p1: Any) -> String {
          return L10n.tr("Localizable", "conversation.status.you_was_added", String(describing: p1))
        }
        /// You were removed
        internal static let youWereRemoved = L10n.tr("Localizable", "conversation.status.you_were_removed")
        internal enum IncomingCall {
          /// Someone is calling…
          internal static let unknown = L10n.tr("Localizable", "conversation.status.incoming_call.unknown")
        }
        internal enum Message {
          /// Shared an audio message
          internal static let audio = L10n.tr("Localizable", "conversation.status.message.audio")
          /// Sent a message
          internal static let ephemeral = L10n.tr("Localizable", "conversation.status.message.ephemeral")
          /// Shared a file
          internal static let file = L10n.tr("Localizable", "conversation.status.message.file")
          /// Shared a picture
          internal static let image = L10n.tr("Localizable", "conversation.status.message.image")
          /// Pinged
          internal static let knock = L10n.tr("Localizable", "conversation.status.message.knock")
          /// Shared a link
          internal static let link = L10n.tr("Localizable", "conversation.status.message.link")
          /// Shared a location
          internal static let location = L10n.tr("Localizable", "conversation.status.message.location")
          /// %@
          internal static func mention(_ p1: Any) -> String {
            return L10n.tr("Localizable", "conversation.status.message.mention", String(describing: p1))
          }
          /// Missed call
          internal static let missedcall = L10n.tr("Localizable", "conversation.status.message.missedcall")
          /// %@
          internal static func reply(_ p1: Any) -> String {
            return L10n.tr("Localizable", "conversation.status.message.reply", String(describing: p1))
          }
          /// %@
          internal static func text(_ p1: Any) -> String {
            return L10n.tr("Localizable", "conversation.status.message.text", String(describing: p1))
          }
          /// Shared a video
          internal static let video = L10n.tr("Localizable", "conversation.status.message.video")
          internal enum Ephemeral {
            /// Someone sent a message
            internal static let group = L10n.tr("Localizable", "conversation.status.message.ephemeral.group")
            /// Pinged
            internal static let knock = L10n.tr("Localizable", "conversation.status.message.ephemeral.knock")
            /// Mentioned you
            internal static let mention = L10n.tr("Localizable", "conversation.status.message.ephemeral.mention")
            /// Replied to your message
            internal static let reply = L10n.tr("Localizable", "conversation.status.message.ephemeral.reply")
            internal enum Knock {
              /// Someone pinged
              internal static let group = L10n.tr("Localizable", "conversation.status.message.ephemeral.knock.group")
            }
            internal enum Mention {
              /// Someone mentioned you
              internal static let group = L10n.tr("Localizable", "conversation.status.message.ephemeral.mention.group")
            }
            internal enum Reply {
              /// Someone replied to your message
              internal static let group = L10n.tr("Localizable", "conversation.status.message.ephemeral.reply.group")
            }
          }
          internal enum Missedcall {
            /// Missed call from %@
            internal static func groups(_ p1: Any) -> String {
              return L10n.tr("Localizable", "conversation.status.message.missedcall.groups", String(describing: p1))
            }
          }
        }
        internal enum SecutityAlert {
          /// New security alert
          internal static let `default` = L10n.tr("Localizable", "conversation.status.secutity_alert.default")
        }
        internal enum Typing {
          /// %@: typing a message…
          internal static func group(_ p1: Any) -> String {
            return L10n.tr("Localizable", "conversation.status.typing.group", String(describing: p1))
          }
        }
      }
      internal enum Voiceover {
        /// legal hold
        internal static let legalhold = L10n.tr("Localizable", "conversation.voiceover.legalhold")
        /// verified
        internal static let verified = L10n.tr("Localizable", "conversation.voiceover.verified")
        internal enum Value {
          /// active
          internal static let active = L10n.tr("Localizable", "conversation.voiceover.value.active")
          /// disabled
          internal static let disabled = L10n.tr("Localizable", "conversation.voiceover.value.disabled")
        }
      }
    }
    internal enum ConversationDetails {
      internal enum OpenButton {
        /// Double tap to view the details of the conversation.
        internal static let accessibilityHint = L10n.tr("Localizable", "conversation_details.open_button.accessibility_hint")
      }
    }
    internal enum ConversationList {
      internal enum BottomBar {
        internal enum Archived {
          /// Archive
          internal static let title = L10n.tr("Localizable", "conversation_list.bottom_bar.archived.title")
        }
        internal enum Contacts {
          /// Contacts
          internal static let title = L10n.tr("Localizable", "conversation_list.bottom_bar.contacts.title")
        }
        internal enum Conversations {
          /// Conversations
          internal static let title = L10n.tr("Localizable", "conversation_list.bottom_bar.conversations.title")
        }
        internal enum Folders {
          /// Folders
          internal static let title = L10n.tr("Localizable", "conversation_list.bottom_bar.folders.title")
        }
      }
      internal enum DataUsagePermissionAlert {
        /// I Agree
        internal static let agree = L10n.tr("Localizable", "conversation_list.data_usage_permission_alert.agree")
        /// No
        internal static let disagree = L10n.tr("Localizable", "conversation_list.data_usage_permission_alert.disagree")
        /// I agree that Wire may create and use anonymous usage and error reports to improve the Wire App. I can revoke this consent at any time.
        internal static let message = L10n.tr("Localizable", "conversation_list.data_usage_permission_alert.message")
        /// Help us make Wire better
        internal static let title = L10n.tr("Localizable", "conversation_list.data_usage_permission_alert.title")
      }
      internal enum Empty {
        internal enum AllArchived {
          /// Everything archived
          internal static let message = L10n.tr("Localizable", "conversation_list.empty.all_archived.message")
        }
        internal enum NoContacts {
          /// Start a conversation or
          /// create a group.
          internal static let message = L10n.tr("Localizable", "conversation_list.empty.no_contacts.message")
        }
      }
      internal enum Header {
        internal enum SelfTeam {
          /// %@ account.
          internal static func accessibilityValue(_ p1: Any) -> String {
            return L10n.tr("Localizable", "conversation_list.header.self_team.accessibility_value", String(describing: p1))
          }
          internal enum AccessibilityValue {
            /// Active now.
            internal static let active = L10n.tr("Localizable", "conversation_list.header.self_team.accessibility_value.active")
            /// Has new messages.
            internal static let hasNewMessages = L10n.tr("Localizable", "conversation_list.header.self_team.accessibility_value.has_new_messages")
            /// Tap to activate.
            internal static let inactive = L10n.tr("Localizable", "conversation_list.header.self_team.accessibility_value.inactive")
          }
        }
      }
      internal enum RightAccessory {
        internal enum JoinButton {
          /// Join
          internal static let title = L10n.tr("Localizable", "conversation_list.right_accessory.join_button.title")
        }
      }
      internal enum Voiceover {
        internal enum BottomBar {
          internal enum ArchivedButton {
            /// list of archived conversations
            internal static let hint = L10n.tr("Localizable", "conversation_list.voiceover.bottom_bar.archived_button.hint")
            /// archived
            internal static let label = L10n.tr("Localizable", "conversation_list.voiceover.bottom_bar.archived_button.label")
          }
          internal enum CameraButton {
            /// take picture and send quickly
            internal static let hint = L10n.tr("Localizable", "conversation_list.voiceover.bottom_bar.camera_button.hint")
            /// camera
            internal static let label = L10n.tr("Localizable", "conversation_list.voiceover.bottom_bar.camera_button.label")
          }
          internal enum ComposeButton {
            /// compose messages and save for later
            internal static let hint = L10n.tr("Localizable", "conversation_list.voiceover.bottom_bar.compose_button.hint")
            /// compose
            internal static let label = L10n.tr("Localizable", "conversation_list.voiceover.bottom_bar.compose_button.label")
          }
          internal enum ContactsButton {
            /// search for people on Wire
            internal static let hint = L10n.tr("Localizable", "conversation_list.voiceover.bottom_bar.contacts_button.hint")
            /// contacts
            internal static let label = L10n.tr("Localizable", "conversation_list.voiceover.bottom_bar.contacts_button.label")
          }
          internal enum FolderButton {
            /// list of conversations organized in folders
            internal static let hint = L10n.tr("Localizable", "conversation_list.voiceover.bottom_bar.folder_button.hint")
            /// folders
            internal static let label = L10n.tr("Localizable", "conversation_list.voiceover.bottom_bar.folder_button.label")
          }
          internal enum RecentButton {
            /// list of recent conversations
            internal static let hint = L10n.tr("Localizable", "conversation_list.voiceover.bottom_bar.recent_button.hint")
            /// recent
            internal static let label = L10n.tr("Localizable", "conversation_list.voiceover.bottom_bar.recent_button.label")
          }
        }
        internal enum OpenConversation {
          /// Open conversation
          internal static let hint = L10n.tr("Localizable", "conversation_list.voiceover.open_conversation.hint")
        }
        internal enum Status {
          /// active call
          internal static let activeCall = L10n.tr("Localizable", "conversation_list.voiceover.status.active_call")
          /// you are mentioned
          internal static let mention = L10n.tr("Localizable", "conversation_list.voiceover.status.mention")
          /// missed call
          internal static let missedCall = L10n.tr("Localizable", "conversation_list.voiceover.status.missed_call")
          /// pause media
          internal static let pauseMedia = L10n.tr("Localizable", "conversation_list.voiceover.status.pause_media")
          /// pending
          internal static let pendingConnection = L10n.tr("Localizable", "conversation_list.voiceover.status.pending_connection")
          /// ping
          internal static let ping = L10n.tr("Localizable", "conversation_list.voiceover.status.ping")
          /// play media
          internal static let playMedia = L10n.tr("Localizable", "conversation_list.voiceover.status.play_media")
          /// reply
          internal static let reply = L10n.tr("Localizable", "conversation_list.voiceover.status.reply")
          /// silenced
          internal static let silenced = L10n.tr("Localizable", "conversation_list.voiceover.status.silenced")
          /// typing
          internal static let typing = L10n.tr("Localizable", "conversation_list.voiceover.status.typing")
        }
        internal enum UnreadMessages {
          /// You have unread messages.
          internal static let hint = L10n.tr("Localizable", "conversation_list.voiceover.unread_messages.hint")
        }
      }
    }
    internal enum CreatePasscode {
      /// It will be used to unlock Wire. If you forget this passcode **it can not be recovered.**
      internal static let infoLabel = L10n.tr("Localizable", "create_passcode.info_label")
      /// Create a passcode to unlock Wire. Please remember it, as **it can not be recovered.**
      internal static let infoLabelForcedApplock = L10n.tr("Localizable", "create_passcode.info_label_forced_applock")
      /// Create a passcode
      internal static let titleLabel = L10n.tr("Localizable", "create_passcode.title_label")
      internal enum CreateButton {
        /// create passcode
        internal static let title = L10n.tr("Localizable", "create_passcode.create_button.title")
      }
      internal enum Textfield {
        /// 
        internal static let placeholder = L10n.tr("Localizable", "create_passcode.textfield.placeholder")
      }
      internal enum Validation {
        /// A lowercase letter
        internal static let noLowercaseChar = L10n.tr("Localizable", "create_passcode.validation.no_lowercase_char")
        /// A number
        internal static let noNumber = L10n.tr("Localizable", "create_passcode.validation.no_number")
        /// A special character
        internal static let noSpecialChar = L10n.tr("Localizable", "create_passcode.validation.no_special_char")
        /// An uppercase letter
        internal static let noUppercaseChar = L10n.tr("Localizable", "create_passcode.validation.no_uppercase_char")
        /// At least eight characters long
        internal static let tooShort = L10n.tr("Localizable", "create_passcode.validation.too_short")
      }
    }
    internal enum DarkTheme {
      internal enum Option {
        /// Dark
        internal static let dark = L10n.tr("Localizable", "dark_theme.option.dark")
        /// Light
        internal static let light = L10n.tr("Localizable", "dark_theme.option.light")
        /// Sync with system settings
        internal static let system = L10n.tr("Localizable", "dark_theme.option.system")
      }
    }
    internal enum Databaseloadingfailure {
      internal enum Alert {
        /// Delete Database
        internal static let deleteDatabase = L10n.tr("Localizable", "databaseloadingfailure.alert.delete_database")
        /// The database could not be loaded due to insufficient storage. Review your device storage usage and try again.
        internal static let message = L10n.tr("Localizable", "databaseloadingfailure.alert.message")
        /// Go to Settings
        internal static let settings = L10n.tr("Localizable", "databaseloadingfailure.alert.settings")
        /// Not Enough Storage
        internal static let title = L10n.tr("Localizable", "databaseloadingfailure.alert.title")
        internal enum DeleteDatabase {
          /// Continue
          internal static let `continue` = L10n.tr("Localizable", "databaseloadingfailure.alert.delete_database.continue")
          /// By deleting the database, all local data and messages for this account will be permanently deleted.
          internal static let message = L10n.tr("Localizable", "databaseloadingfailure.alert.delete_database.message")
        }
      }
    }
    internal enum Device {
      /// Not Verified
      internal static let notVerified = L10n.tr("Localizable", "device.not_verified")
      /// Verified
      internal static let verified = L10n.tr("Localizable", "device.verified")
      internal enum Class {
        /// Desktop
        internal static let desktop = L10n.tr("Localizable", "device.class.desktop")
        /// Legal Hold
        internal static let legalhold = L10n.tr("Localizable", "device.class.legalhold")
        /// Phone
        internal static let phone = L10n.tr("Localizable", "device.class.phone")
        /// Tablet
        internal static let tablet = L10n.tr("Localizable", "device.class.tablet")
        /// Unknown
        internal static let unknown = L10n.tr("Localizable", "device.class.unknown")
      }
      internal enum `Type` {
        /// Legal Hold
        internal static let legalhold = L10n.tr("Localizable", "device.type.legalhold")
        /// Permanent
        internal static let permanent = L10n.tr("Localizable", "device.type.permanent")
        /// Temporary
        internal static let temporary = L10n.tr("Localizable", "device.type.temporary")
        /// Unknown
        internal static let unknown = L10n.tr("Localizable", "device.type.unknown")
      }
    }
    internal enum DigitalSignature {
      internal enum Alert {
        /// Please save and read the document before signing it.
        internal static let downloadNecessary = L10n.tr("Localizable", "digital_signature.alert.download_necessary")
        /// Unfortunately, your digital signature failed.
        internal static let error = L10n.tr("Localizable", "digital_signature.alert.error")
        internal enum Error {
          /// Unfortunately, the signature form did not open. Please try again.
          internal static let noConsentUrl = L10n.tr("Localizable", "digital_signature.alert.error.no_consent_url")
          /// Unfortunately, your digital signature failed. Please try again.
          internal static let noSignature = L10n.tr("Localizable", "digital_signature.alert.error.no_signature")
        }
      }
    }
    internal enum Email {
      /// Email
      internal static let placeholder = L10n.tr("Localizable", "email.placeholder")
      internal enum Guidance {
        /// Invalid email address
        internal static let invalid = L10n.tr("Localizable", "email.guidance.invalid")
        /// Too many characters
        internal static let toolong = L10n.tr("Localizable", "email.guidance.toolong")
        /// Email is too short
        internal static let tooshort = L10n.tr("Localizable", "email.guidance.tooshort")
      }
    }
    internal enum Error {
      /// Please enter a valid email address
      internal static let email = L10n.tr("Localizable", "error.email")
      /// Please enter your full name
      internal static let fullName = L10n.tr("Localizable", "error.full_name")
      /// Please enter your full name and a valid email address
      internal static let nameAndEmail = L10n.tr("Localizable", "error.name_and_email")
      /// Couldn’t update your password.
      internal static let updatingPassword = L10n.tr("Localizable", "error.updating_password")
      internal enum Call {
        /// Please try calling again in several minutes.
        internal static let general = L10n.tr("Localizable", "error.call.general")
        /// Please cancel the cellular call before calling on Wire.
        internal static let gsmOngoing = L10n.tr("Localizable", "error.call.gsm_ongoing")
        /// You might experience issues during the call
        internal static let slowConnection = L10n.tr("Localizable", "error.call.slow_connection")
        internal enum General {
          /// Call error
          internal static let title = L10n.tr("Localizable", "error.call.general.title")
        }
        internal enum GsmOngoing {
          /// Cellular call
          internal static let title = L10n.tr("Localizable", "error.call.gsm_ongoing.title")
        }
        internal enum SlowConnection {
          /// Call anyway
          internal static let callAnyway = L10n.tr("Localizable", "error.call.slow_connection.call_anyway")
          /// Slow connection
          internal static let title = L10n.tr("Localizable", "error.call.slow_connection.title")
        }
      }
      internal enum Connection {
        /// Something went wrong, please try again
        internal static let genericError = L10n.tr("Localizable", "error.connection.generic_error")
        /// You cannot connect to this user due to legal hold.
        internal static let missingLegalholdConsent = L10n.tr("Localizable", "error.connection.missing_legalhold_consent")
        /// Error
        internal static let title = L10n.tr("Localizable", "error.connection.title")
      }
      internal enum Conversation {
        /// Adding the participant failed
        internal static let cannotAdd = L10n.tr("Localizable", "error.conversation.cannot_add")
        /// Removing the participant failed
        internal static let cannotRemove = L10n.tr("Localizable", "error.conversation.cannot_remove")
        /// Due to legal hold, only team members can be added to this conversation
        internal static let missingLegalholdConsent = L10n.tr("Localizable", "error.conversation.missing_legalhold_consent")
        /// There seems to be a problem with your Internet connection. Please make sure it’s working.
        internal static let offline = L10n.tr("Localizable", "error.conversation.offline")
        /// Error
        internal static let title = L10n.tr("Localizable", "error.conversation.title")
        /// The conversation is full
        internal static let tooManyMembers = L10n.tr("Localizable", "error.conversation.too_many_members")
      }
      internal enum Email {
        /// Please enter a valid email address
        internal static let invalid = L10n.tr("Localizable", "error.email.invalid")
      }
      internal enum GroupCall {
        /// Calls work in conversations with up to %d people.
        internal static func tooManyMembersInConversation(_ p1: Int) -> String {
          return L10n.tr("Localizable", "error.group_call.too_many_members_in_conversation", p1)
        }
        /// There’s only room for %d participants in here.
        internal static func tooManyParticipantsInTheCall(_ p1: Int) -> String {
          return L10n.tr("Localizable", "error.group_call.too_many_participants_in_the_call", p1)
        }
        internal enum TooManyMembersInConversation {
          /// Too many people to call
          internal static let title = L10n.tr("Localizable", "error.group_call.too_many_members_in_conversation.title")
        }
        internal enum TooManyParticipantsInTheCall {
          /// The call is full
          internal static let title = L10n.tr("Localizable", "error.group_call.too_many_participants_in_the_call.title")
        }
      }
      internal enum Input {
        /// Please enter a shorter username
        internal static let tooLong = L10n.tr("Localizable", "error.input.too_long")
        /// Please enter a longer username
        internal static let tooShort = L10n.tr("Localizable", "error.input.too_short")
      }
      internal enum Invite {
        /// Please configure your email client to be able to send the invites via email
        internal static let noEmailProvider = L10n.tr("Localizable", "error.invite.no_email_provider")
        /// Please configure your SMS to be able to send the invites via SMS
        internal static let noMessagingProvider = L10n.tr("Localizable", "error.invite.no_messaging_provider")
      }
      internal enum Message {
        internal enum Send {
          /// You cannot send this message because you have at least one outdated device that does not support legal hold. Please update all your devices or remove them from the app settings
          internal static let missingLegalholdConsent = L10n.tr("Localizable", "error.message.send.missing_legalhold_consent")
          /// Messages cannot be sent
          internal static let title = L10n.tr("Localizable", "error.message.send.title")
        }
      }
      internal enum Phone {
        /// Please enter a valid phone number
        internal static let invalid = L10n.tr("Localizable", "error.phone.invalid")
      }
      internal enum User {
        /// You can’t add more than 3 accounts.
        internal static let accountLimitReached = L10n.tr("Localizable", "error.user.account_limit_reached")
        /// The account you are trying access is pending activation. Please verify your details.
        internal static let accountPendingActivation = L10n.tr("Localizable", "error.user.account_pending_activation")
        /// This account is no longer authorized to log in.
        internal static let accountSuspended = L10n.tr("Localizable", "error.user.account_suspended")
        /// You have been logged out from another device.
        internal static let deviceDeletedRemotely = L10n.tr("Localizable", "error.user.device_deleted_remotely")
        /// You can't create this account as your email domain is intentionally blocked.
        /// Please ask your team admin to invite you via email.
        internal static let domainBlocked = L10n.tr("Localizable", "error.user.domain_blocked")
        /// The email address you provided has already been registered. Please try again.
        internal static let emailIsTaken = L10n.tr("Localizable", "error.user.email_is_taken")
        /// Please verify your details and try again.
        internal static let invalidCredentials = L10n.tr("Localizable", "error.user.invalid_credentials")
        /// Either an email address or a phone number is required.
        internal static let lastIdentityCantBeDeleted = L10n.tr("Localizable", "error.user.last_identity_cant_be_deleted")
        /// Please verify your details and try again.
        internal static let needsCredentials = L10n.tr("Localizable", "error.user.needs_credentials")
        /// There seems to be a problem with your network. Please try again later.
        internal static let networkError = L10n.tr("Localizable", "error.user.network_error")
        /// Please enter a valid code
        internal static let phoneCodeInvalid = L10n.tr("Localizable", "error.user.phone_code_invalid")
        /// We already sent you a code via SMS. Tap Resend after 10 minutes to get a new one.
        internal static let phoneCodeTooMany = L10n.tr("Localizable", "error.user.phone_code_too_many")
        /// The phone number you provided has already been registered. Please try again.
        internal static let phoneIsTaken = L10n.tr("Localizable", "error.user.phone_is_taken")
        /// Something went wrong. Please try again.
        internal static let registrationUnknownError = L10n.tr("Localizable", "error.user.registration_unknown_error")
        /// Something went wrong, please try again
        internal static let unkownError = L10n.tr("Localizable", "error.user.unkown_error")
      }
    }
    internal enum FeatureConfig {
      internal enum Alert {
        /// Team settings changed
        internal static let genericTitle = L10n.tr("Localizable", "feature_config.alert.generic_title")
        internal enum ConversationGuestLinks {
          internal enum Message {
            /// Generating guest links is now disabled for all group admins.
            internal static let disabled = L10n.tr("Localizable", "feature_config.alert.conversation_guest_links.message.disabled")
            /// Generating guest links is now enabled for all group admins.
            internal static let enabled = L10n.tr("Localizable", "feature_config.alert.conversation_guest_links.message.enabled")
          }
        }
        internal enum SelfDeletingMessages {
          internal enum Message {
            /// Self-deleting messages are disabled.
            internal static let disabled = L10n.tr("Localizable", "feature_config.alert.self_deleting_messages.message.disabled")
            /// Self-deleting messages are enabled. You can set a timer before writing a message.
            internal static let enabled = L10n.tr("Localizable", "feature_config.alert.self_deleting_messages.message.enabled")
            /// Self-deleting messages are now mandatory. New messages will self-delete after %@.
            internal static func forcedOn(_ p1: Any) -> String {
              return L10n.tr("Localizable", "feature_config.alert.self_deleting_messages.message.forced_on", String(describing: p1))
            }
          }
        }
      }
      internal enum ConferenceCallingRestrictions {
        internal enum Admins {
          internal enum Alert {
            /// Your team is currently on the free Basic plan. Upgrade to Enterprise to access features such as starting conference calls.
            internal static let message = L10n.tr("Localizable", "feature_config.conference_calling_restrictions.admins.alert.message")
            /// Upgrade to Enterprise
            internal static let title = L10n.tr("Localizable", "feature_config.conference_calling_restrictions.admins.alert.title")
            internal enum Action {
              /// Upgrade now
              internal static let upgrade = L10n.tr("Localizable", "feature_config.conference_calling_restrictions.admins.alert.action.upgrade")
            }
            internal enum Message {
              /// Learn more about Wire’s pricing
              internal static let learnMore = L10n.tr("Localizable", "feature_config.conference_calling_restrictions.admins.alert.message.learn_more")
            }
          }
        }
        internal enum Members {
          internal enum Alert {
            /// To start a conference call, your team needs to upgrade to the Enterprise plan.
            internal static let message = L10n.tr("Localizable", "feature_config.conference_calling_restrictions.members.alert.message")
            /// Feature unavailable
            internal static let title = L10n.tr("Localizable", "feature_config.conference_calling_restrictions.members.alert.title")
          }
        }
        internal enum Personal {
          internal enum Alert {
            /// The option to initiate a conference call is only available in the paid version of Wire.
            internal static let message = L10n.tr("Localizable", "feature_config.conference_calling_restrictions.personal.alert.message")
            /// Feature unavailable
            internal static let title = L10n.tr("Localizable", "feature_config.conference_calling_restrictions.personal.alert.title")
          }
        }
      }
      internal enum FileSharingRestrictions {
        /// Receiving audio files is prohibited
        internal static let audio = L10n.tr("Localizable", "feature_config.file_sharing_restrictions.audio")
        /// Receiving files is prohibited
        internal static let file = L10n.tr("Localizable", "feature_config.file_sharing_restrictions.file")
        /// Receiving images is prohibited
        internal static let picture = L10n.tr("Localizable", "feature_config.file_sharing_restrictions.picture")
        /// Receiving videos is prohibited
        internal static let video = L10n.tr("Localizable", "feature_config.file_sharing_restrictions.video")
      }
      internal enum Update {
        internal enum ConferenceCalling {
          internal enum Alert {
            /// Your team was upgraded to the Enterprise plan. You now have access to features such as starting conference calls.
            internal static let message = L10n.tr("Localizable", "feature_config.update.conference_calling.alert.message")
            /// Enterprise plan
            internal static let title = L10n.tr("Localizable", "feature_config.update.conference_calling.alert.title")
            internal enum Message {
              /// Learn more about the Enterprise plan
              internal static let learnMore = L10n.tr("Localizable", "feature_config.update.conference_calling.alert.message.learn_more")
            }
          }
        }
        internal enum FileSharing {
          internal enum Alert {
            /// There has been a change in Wire
            internal static let title = L10n.tr("Localizable", "feature_config.update.file_sharing.alert.title")
            internal enum Message {
              /// Sharing and receiving files of any type is now disabled.
              internal static let disabled = L10n.tr("Localizable", "feature_config.update.file_sharing.alert.message.disabled")
              /// Sharing and receiving files of any type is now enabled.
              internal static let enabled = L10n.tr("Localizable", "feature_config.update.file_sharing.alert.message.enabled")
            }
          }
        }
      }
    }
    internal enum Folder {
      internal enum Creation {
        internal enum Name {
          /// Maximum 64 characters
          internal static let footer = L10n.tr("Localizable", "folder.creation.name.footer")
          /// Move the conversation "%@" to a new folder.
          internal static func header(_ p1: Any) -> String {
            return L10n.tr("Localizable", "folder.creation.name.header", String(describing: p1))
          }
          /// Folder name
          internal static let placeholder = L10n.tr("Localizable", "folder.creation.name.placeholder")
          /// Create new folder
          internal static let title = L10n.tr("Localizable", "folder.creation.name.title")
          internal enum Button {
            /// Create
            internal static let create = L10n.tr("Localizable", "folder.creation.name.button.create")
          }
        }
      }
      internal enum Picker {
        /// Move to
        internal static let title = L10n.tr("Localizable", "folder.picker.title")
        internal enum Empty {
          /// Create a new folder by pressing the + button
          internal static let hint = L10n.tr("Localizable", "folder.picker.empty.hint")
        }
      }
    }
    internal enum Force {
      internal enum Update {
        /// You are missing out on new features.
        /// Get the latest version of Wire in the App Store.
        internal static let message = L10n.tr("Localizable", "force.update.message")
        /// Go to App Store
        internal static let okButton = L10n.tr("Localizable", "force.update.ok_button")
        /// Update necessary
        internal static let title = L10n.tr("Localizable", "force.update.title")
      }
    }
    internal enum General {
      /// Accept
      internal static let accept = L10n.tr("Localizable", "general.accept")
      /// Back
      internal static let back = L10n.tr("Localizable", "general.back")
      /// Cancel
      internal static let cancel = L10n.tr("Localizable", "general.cancel")
      /// Close
      internal static let close = L10n.tr("Localizable", "general.close")
      /// OK
      internal static let confirm = L10n.tr("Localizable", "general.confirm")
      /// No, thanks
      internal static let decline = L10n.tr("Localizable", "general.decline")
      /// Done
      internal static let done = L10n.tr("Localizable", "general.done")
      /// Edit
      internal static let edit = L10n.tr("Localizable", "general.edit")
      /// Something went wrong
      internal static let failure = L10n.tr("Localizable", "general.failure")
      /// Guest room
      internal static let guestRoomName = L10n.tr("Localizable", "general.guest-room-name")
      /// Later
      internal static let later = L10n.tr("Localizable", "general.later")
      /// Loading…
      internal static let loading = L10n.tr("Localizable", "general.loading")
      /// Next
      internal static let next = L10n.tr("Localizable", "general.next")
      /// Off
      internal static let off = L10n.tr("Localizable", "general.off")
      /// OK
      internal static let ok = L10n.tr("Localizable", "general.ok")
      /// On
      internal static let on = L10n.tr("Localizable", "general.on")
      /// Open Wire Settings
      internal static let openSettings = L10n.tr("Localizable", "general.open_settings")
      /// Paste
      internal static let paste = L10n.tr("Localizable", "general.paste")
      /// Service
      internal static let service = L10n.tr("Localizable", "general.service")
      /// Not Now
      internal static let skip = L10n.tr("Localizable", "general.skip")
      ///  
      internal static let spaceBetweenWords = L10n.tr("Localizable", "general.space_between_words")
      internal enum Failure {
        /// Please try again.
        internal static let tryAgain = L10n.tr("Localizable", "general.failure.try_again")
      }
    }
    internal enum Giphy {
      /// cancel
      internal static let cancel = L10n.tr("Localizable", "giphy.cancel")
      /// send
      internal static let confirm = L10n.tr("Localizable", "giphy.confirm")
      /// Search Giphy
      internal static let searchPlaceholder = L10n.tr("Localizable", "giphy.search_placeholder")
      internal enum Conversation {
        /// %@ · via giphy.com
        internal static func message(_ p1: Any) -> String {
          return L10n.tr("Localizable", "giphy.conversation.message", String(describing: p1))
        }
        /// via giphy.com
        internal static let randomMessage = L10n.tr("Localizable", "giphy.conversation.random_message")
      }
      internal enum Error {
        /// no more gifs
        internal static let noMoreResults = L10n.tr("Localizable", "giphy.error.no_more_results")
        /// no gif found
        internal static let noResult = L10n.tr("Localizable", "giphy.error.no_result")
      }
    }
    internal enum GroupDetails {
      internal enum ConversationAdminsHeader {
        /// Group admins
        internal static let title = L10n.tr("Localizable", "group_details.conversation_admins_header.title")
      }
      internal enum ConversationMembersHeader {
        /// Group members
        internal static let title = L10n.tr("Localizable", "group_details.conversation_members_header.title")
      }
      internal enum GuestOptionsCell {
        /// Off
        internal static let disabled = L10n.tr("Localizable", "group_details.guest_options_cell.disabled")
        /// On
        internal static let enabled = L10n.tr("Localizable", "group_details.guest_options_cell.enabled")
        /// Guests
        internal static let title = L10n.tr("Localizable", "group_details.guest_options_cell.title")
      }
      internal enum NotificationOptionsCell {
        /// You can be notified about everything (including audio and video calls) or only when someone mentions you or replies to one of your messages.
        internal static let description = L10n.tr("Localizable", "group_details.notification_options_cell.description")
        /// Notifications
        internal static let title = L10n.tr("Localizable", "group_details.notification_options_cell.title")
      }
      internal enum ReceiptOptionsCell {
        /// When this is on, people can see when their messages in this conversation are read.
        internal static let description = L10n.tr("Localizable", "group_details.receipt_options_cell.description")
        /// Read receipts
        internal static let title = L10n.tr("Localizable", "group_details.receipt_options_cell.title")
      }
      internal enum ServicesOptionsCell {
        /// Off
        internal static let disabled = L10n.tr("Localizable", "group_details.services_options_cell.disabled")
        /// On
        internal static let enabled = L10n.tr("Localizable", "group_details.services_options_cell.enabled")
        /// Services
        internal static let title = L10n.tr("Localizable", "group_details.services_options_cell.title")
      }
      internal enum TimeoutOptionsCell {
        /// Self-deleting messages
        internal static let title = L10n.tr("Localizable", "group_details.timeout_options_cell.title")
      }
    }
    internal enum GuestRoom {
      internal enum Actions {
        /// Link Copied!
        internal static let copiedLink = L10n.tr("Localizable", "guest_room.actions.copied_link")
        /// Copy Link
        internal static let copyLink = L10n.tr("Localizable", "guest_room.actions.copy_link")
        /// Revoke Link…
        internal static let revokeLink = L10n.tr("Localizable", "guest_room.actions.revoke_link")
        /// Share Link
        internal static let shareLink = L10n.tr("Localizable", "guest_room.actions.share_link")
      }
      internal enum AllowGuests {
        /// Open this conversation to people outside your team.
        internal static let subtitle = L10n.tr("Localizable", "guest_room.allow_guests.subtitle")
        /// Allow guests
        internal static let title = L10n.tr("Localizable", "guest_room.allow_guests.title")
      }
      internal enum Error {
        internal enum Generic {
          /// Check your connection and try again
          internal static let message = L10n.tr("Localizable", "guest_room.error.generic.message")
          /// Something went wrong
          internal static let title = L10n.tr("Localizable", "guest_room.error.generic.title")
        }
      }
      internal enum Expiration {
        /// %@h left
        internal static func hoursLeft(_ p1: Any) -> String {
          return L10n.tr("Localizable", "guest_room.expiration.hours_left", String(describing: p1))
        }
        /// Less than %@m left
        internal static func lessThanMinutesLeft(_ p1: Any) -> String {
          return L10n.tr("Localizable", "guest_room.expiration.less_than_minutes_left", String(describing: p1))
        }
      }
      internal enum Link {
        internal enum Button {
          /// Create Link
          internal static let title = L10n.tr("Localizable", "guest_room.link.button.title")
        }
        internal enum Disabled {
          internal enum ForOtherTeam {
            /// You can't disable the guest option in this conversation, as it has been created by someone from another team.
            internal static let explanation = L10n.tr("Localizable", "guest_room.link.disabled.for_other_team.explanation")
          }
        }
        internal enum Header {
          /// Invite others with a link to this conversation. Anyone with the link can join the conversation, even if they don’t have Wire.
          internal static let subtitle = L10n.tr("Localizable", "guest_room.link.header.subtitle")
          /// Guest Links
          internal static let title = L10n.tr("Localizable", "guest_room.link.header.title")
        }
        internal enum NotAllowed {
          internal enum ForOtherTeam {
            /// You can't generate a guest link in this conversation, as it has been created by someone from another team and this team is not allowed to use guest links.
            internal static let explanation = L10n.tr("Localizable", "guest_room.link.not_allowed.for_other_team.explanation")
          }
          internal enum ForSelfTeam {
            /// Generating guest links is not allowed in your team.
            internal static let explanation = L10n.tr("Localizable", "guest_room.link.not_allowed.for_self_team.explanation")
          }
        }
      }
      internal enum RemoveGuests {
        /// Remove
        internal static let action = L10n.tr("Localizable", "guest_room.remove_guests.action")
        /// Current guests will be removed from the conversation. New guests will not be allowed.
        internal static let message = L10n.tr("Localizable", "guest_room.remove_guests.message")
      }
      internal enum RevokeLink {
        /// Revoke Link
        internal static let action = L10n.tr("Localizable", "guest_room.revoke_link.action")
        /// New guests will not be able to join with this link. Current guests will still have access.
        internal static let message = L10n.tr("Localizable", "guest_room.revoke_link.message")
      }
      internal enum Share {
        /// Join me in a conversation on Wire:
        /// %@
        internal static func message(_ p1: Any) -> String {
          return L10n.tr("Localizable", "guest_room.share.message", String(describing: p1))
        }
      }
    }
    internal enum Image {
      /// Add an emoji
      internal static let addEmoji = L10n.tr("Localizable", "image.add_emoji")
      /// Add a sketch
      internal static let addSketch = L10n.tr("Localizable", "image.add_sketch")
      /// Edit image
      internal static let editImage = L10n.tr("Localizable", "image.edit_image")
    }
    internal enum ImageConfirmer {
      /// Cancel
      internal static let cancel = L10n.tr("Localizable", "image_confirmer.cancel")
      /// OK
      internal static let confirm = L10n.tr("Localizable", "image_confirmer.confirm")
    }
    internal enum Inbox {
      /// Connection Requests
      internal static let title = L10n.tr("Localizable", "inbox.title")
      internal enum ConnectionRequest {
        /// Connect
        internal static let connectButtonTitle = L10n.tr("Localizable", "inbox.connection_request.connect_button_title")
        /// Ignore
        internal static let ignoreButtonTitle = L10n.tr("Localizable", "inbox.connection_request.ignore_button_title")
      }
    }
    internal enum Input {
      internal enum Ephemeral {
        /// Set a time for the message to disappear
        internal static let title = L10n.tr("Localizable", "input.ephemeral.title")
        internal enum Timeout {
          /// Off
          internal static let `none` = L10n.tr("Localizable", "input.ephemeral.timeout.none")
        }
      }
    }
    internal enum InviteBanner {
      /// Invite more people
      internal static let inviteButtonTitle = L10n.tr("Localizable", "invite_banner.invite_button_title")
      /// Enjoy calls, messages, sketches, GIFs and more in private or with groups.
      internal static let message = L10n.tr("Localizable", "invite_banner.message")
      /// Bring your friends to Wire!
      internal static let title = L10n.tr("Localizable", "invite_banner.title")
    }
    internal enum Jailbrokendevice {
      internal enum Alert {
        /// For security reasons, Wire can't be used on this device. Any existing Wire data has been erased.
        internal static let message = L10n.tr("Localizable", "jailbrokendevice.alert.message")
        /// Jailbreak detected
        internal static let title = L10n.tr("Localizable", "jailbrokendevice.alert.title")
      }
    }
    internal enum KeyboardPhotosAccess {
      internal enum Denied {
        internal enum Keyboard {
          /// Wire needs access to your camera.
          internal static let camera = L10n.tr("Localizable", "keyboard_photos_access.denied.keyboard.camera")
          /// Wire needs access to your
          /// camera and photos.
          internal static let cameraAndPhotos = L10n.tr("Localizable", "keyboard_photos_access.denied.keyboard.camera_and_photos")
          /// You can’t access the camera while you are on a video call.
          internal static let ongoingCall = L10n.tr("Localizable", "keyboard_photos_access.denied.keyboard.ongoing_call")
          /// Wire needs access to your photos.
          internal static let photos = L10n.tr("Localizable", "keyboard_photos_access.denied.keyboard.photos")
          /// Settings
          internal static let settings = L10n.tr("Localizable", "keyboard_photos_access.denied.keyboard.settings")
        }
      }
    }
    internal enum Keyboardshortcut {
      /// Conversation Details...
      internal static let conversationDetail = L10n.tr("Localizable", "keyboardshortcut.conversationDetail")
      /// People
      internal static let openPeople = L10n.tr("Localizable", "keyboardshortcut.openPeople")
      /// Scroll to Bottom
      internal static let scrollToBottom = L10n.tr("Localizable", "keyboardshortcut.scrollToBottom")
      /// Search in Conversation...
      internal static let searchInConversation = L10n.tr("Localizable", "keyboardshortcut.searchInConversation")
    }
    internal enum Landing {
      /// Wire. Add your Account.
      internal static let header = L10n.tr("Localizable", "landing.header")
      /// Trying to create a Pro or Enterprise account for your business or organization?
      internal static let welcomeMessage = L10n.tr("Localizable", "landing.welcome_message")
      /// Unfortunately, that's not possible in the app - once you have created your team, you can log in here
      internal static let welcomeSubmessage = L10n.tr("Localizable", "landing.welcome_submessage")
      internal enum CreateAccount {
        /// Chat with friends and family?
        internal static let infotitle = L10n.tr("Localizable", "landing.create_account.infotitle")
        /// Chat privately with groups of friends and family
        internal static let subtitle = L10n.tr("Localizable", "landing.create_account.subtitle")
        /// Create a Wire personal account
        internal static let title = L10n.tr("Localizable", "landing.create_account.title")
      }
      internal enum CreateTeam {
        /// Secure collaboration for businesses, institutions and professional organizations
        internal static let subtitle = L10n.tr("Localizable", "landing.create_team.subtitle")
        /// Pro
        internal static let title = L10n.tr("Localizable", "landing.create_team.title")
      }
      internal enum CustomBackend {
        /// Connected to "%@"
        internal static func title(_ p1: Any) -> String {
          return L10n.tr("Localizable", "landing.custom_backend.title", String(describing: p1))
        }
        internal enum MoreInfo {
          internal enum Alert {
            ///  You are connected to a third-party server: %@
            internal static func title(_ p1: Any) -> String {
              return L10n.tr("Localizable", "landing.custom_backend.more_info.alert.title", String(describing: p1))
            }
          }
          internal enum Button {
            /// Show more
            internal static let title = L10n.tr("Localizable", "landing.custom_backend.more_info.button.title")
          }
        }
      }
      internal enum Login {
        /// Already have an account?
        internal static let hints = L10n.tr("Localizable", "landing.login.hints")
        internal enum Button {
          /// Log in
          internal static let title = L10n.tr("Localizable", "landing.login.button.title")
        }
        internal enum Email {
          internal enum Button {
            /// Log in with email
            internal static let title = L10n.tr("Localizable", "landing.login.email.button.title")
          }
        }
        internal enum Enterprise {
          internal enum Button {
            /// Enterprise log in
            internal static let title = L10n.tr("Localizable", "landing.login.enterprise.button.title")
          }
        }
        internal enum Sso {
          internal enum Button {
            /// Log in with SSO
            internal static let title = L10n.tr("Localizable", "landing.login.sso.button.title")
          }
        }
      }
    }
    internal enum LegalHold {
      internal enum Deactivated {
        /// Future messages will not be recorded.
        internal static let message = L10n.tr("Localizable", "legal_hold.deactivated.message")
        /// Legal Hold Deactivated
        internal static let title = L10n.tr("Localizable", "legal_hold.deactivated.title")
      }
    }
    internal enum Legalhold {
      /// Legal hold details
      internal static let accessibility = L10n.tr("Localizable", "legalhold.accessibility")
      internal enum Header {
        /// Legal Hold has been activated for at least one person in this conversation.
        /// All messages will be preserved for future access, including deleted, edited, and self-deleting messages.
        internal static let otherDescription = L10n.tr("Localizable", "legalhold.header.other_description")
        /// Legal Hold has been activated for your account.
        /// All messages will be preserved for future access, including deleted, edited, and self-deleting messages.
        /// Your conversation partners will be aware of the recording.
        internal static let selfDescription = L10n.tr("Localizable", "legalhold.header.self_description")
        /// Legal Hold
        internal static let title = L10n.tr("Localizable", "legalhold.header.title")
      }
      internal enum Participants {
        internal enum Section {
          /// Legal hold subjects
          internal static let title = L10n.tr("Localizable", "legalhold.participants.section.title")
        }
      }
    }
    internal enum LegalholdActive {
      internal enum Alert {
        /// Learn More
        internal static let learnMore = L10n.tr("Localizable", "legalhold_active.alert.learn_more")
        /// Legal Hold has been activated for your account. All messages will be preserved for future access, including deleted, edited, and self-deleting messages.
        /// 
        /// Your conversation partners will be aware of the recording.
        internal static let message = L10n.tr("Localizable", "legalhold_active.alert.message")
        /// Legal Hold is Active
        internal static let title = L10n.tr("Localizable", "legalhold_active.alert.title")
      }
    }
    internal enum LegalholdRequest {
      internal enum Alert {
        /// All future messages will be recorded by the device with fingerprint:
        /// 
        /// %@
        /// 
        /// This includes deleted, edited, and self-deleting messages in all conversations.
        internal static func detail(_ p1: Any) -> String {
          return L10n.tr("Localizable", "legalhold_request.alert.detail", String(describing: p1))
        }
        /// Wrong Password
        internal static let errorWrongPassword = L10n.tr("Localizable", "legalhold_request.alert.error_wrong_password")
        /// Legal Hold Requested
        internal static let title = L10n.tr("Localizable", "legalhold_request.alert.title")
        internal enum Detail {
          /// Enter your password to confirm.
          internal static let enterPassword = L10n.tr("Localizable", "legalhold_request.alert.detail.enter_password")
        }
      }
      internal enum Button {
        /// Pending approval.
        internal static let accessibility = L10n.tr("Localizable", "legalhold_request.button.accessibility")
      }
    }
    internal enum Library {
      internal enum Alert {
        internal enum PermissionWarning {
          /// Wire needs access to your Photos
          internal static let title = L10n.tr("Localizable", "library.alert.permission_warning.title")
          internal enum NotAllowed {
            /// Go to Settings and allow Wire to access your photos.
            internal static let explaination = L10n.tr("Localizable", "library.alert.permission_warning.not_allowed.explaination")
          }
          internal enum Restrictions {
            /// Wire cannot access your library because restrictions are enabled.
            internal static let explaination = L10n.tr("Localizable", "library.alert.permission_warning.restrictions.explaination")
          }
        }
      }
    }
    internal enum List {
      /// ARCHIVE
      internal static let archivedConversations = L10n.tr("Localizable", "list.archived_conversations")
      /// Close archive
      internal static let archivedConversationsClose = L10n.tr("Localizable", "list.archived_conversations_close")
      /// Conversations
      internal static let title = L10n.tr("Localizable", "list.title")
      internal enum ConnectRequest {
        /// Plural format key: "%#@d_number_of_people@ waiting"
        internal static func peopleWaiting(_ p1: Int) -> String {
          return L10n.tr("Localizable", "list.connect_request.people_waiting", p1)
        }
      }
      internal enum Section {
        /// People
        internal static let contacts = L10n.tr("Localizable", "list.section.contacts")
        /// Favorites
        internal static let favorites = L10n.tr("Localizable", "list.section.favorites")
        /// Groups
        internal static let groups = L10n.tr("Localizable", "list.section.groups")
        /// Requests
        internal static let requests = L10n.tr("Localizable", "list.section.requests")
      }
    }
    internal enum Location {
      internal enum SendButton {
        /// Send
        internal static let title = L10n.tr("Localizable", "location.send_button.title")
      }
      internal enum UnauthorizedAlert {
        /// Cancel
        internal static let cancel = L10n.tr("Localizable", "location.unauthorized_alert.cancel")
        /// To send your location, enable Location Services and allow Wire to access your location.
        internal static let message = L10n.tr("Localizable", "location.unauthorized_alert.message")
        /// Settings
        internal static let settings = L10n.tr("Localizable", "location.unauthorized_alert.settings")
        /// Enable Location Services
        internal static let title = L10n.tr("Localizable", "location.unauthorized_alert.title")
      }
    }
    internal enum Login {
      internal enum Sso {
        /// This link is not valid. Please contact your administrator to resolve the issue.
        internal static let linkErrorMessage = L10n.tr("Localizable", "login.sso.link_error_message")
        /// Cannot Start Enterprise Login
        internal static let startErrorTitle = L10n.tr("Localizable", "login.sso.start_error_title")
        internal enum Alert {
          /// Log in
          internal static let action = L10n.tr("Localizable", "login.sso.alert.action")
          /// Enterprise Login
          internal static let title = L10n.tr("Localizable", "login.sso.alert.title")
          internal enum Message {
            /// Please enter your email or SSO code. If your email matches an enterprise installation of Wire, this app will connect to that server.
            internal static let ssoAndEmail = L10n.tr("Localizable", "login.sso.alert.message.sso_and_email")
            /// Please enter your SSO code:
            internal static let ssoOnly = L10n.tr("Localizable", "login.sso.alert.message.sso_only")
          }
          internal enum TextField {
            internal enum Placeholder {
              /// email or SSO access code
              internal static let ssoAndEmail = L10n.tr("Localizable", "login.sso.alert.text_field.placeholder.sso_and_email")
              /// SSO access code
              internal static let ssoOnly = L10n.tr("Localizable", "login.sso.alert.text_field.placeholder.sso_only")
            }
          }
        }
        internal enum BackendSwitch {
          /// Provide credentials only if you're sure this is your organization's log in.
          internal static let information = L10n.tr("Localizable", "login.sso.backend_switch.information")
          /// You are being redirected to your dedicated enterprise service.
          internal static let subtitle = L10n.tr("Localizable", "login.sso.backend_switch.subtitle")
          /// Redirecting...
          internal static let title = L10n.tr("Localizable", "login.sso.backend_switch.title")
        }
        internal enum Error {
          internal enum Alert {
            /// Please contact your team administrator for details (error %@).
            internal static func message(_ p1: Any) -> String {
              return L10n.tr("Localizable", "login.sso.error.alert.message", String(describing: p1))
            }
            internal enum DomainAssociatedWithWrongServer {
              /// This email is linked to a different server, but the app can only be connected to one server at a time. Please log out of all Wire accounts on this device and try to login again.
              internal static let message = L10n.tr("Localizable", "login.sso.error.alert.domain_associated_with_wrong_server.message")
            }
            internal enum DomainNotRegistered {
              /// This email cannot be used for enterprise login. Please enter the SSO code to proceed.
              internal static let message = L10n.tr("Localizable", "login.sso.error.alert.domain_not_registered.message")
            }
            internal enum InvalidCode {
              /// Please verify your company SSO access code and try again.
              internal static let message = L10n.tr("Localizable", "login.sso.error.alert.invalid_code.message")
            }
            internal enum InvalidFormat {
              internal enum Message {
                /// Please enter a valid email or SSO access code
                internal static let ssoAndEmail = L10n.tr("Localizable", "login.sso.error.alert.invalid_format.message.sso_and_email")
                /// Please enter a valid SSO access code
                internal static let ssoOnly = L10n.tr("Localizable", "login.sso.error.alert.invalid_format.message.sso_only")
              }
            }
            internal enum InvalidStatus {
              /// Please try again later (error %@).
              internal static func message(_ p1: Any) -> String {
                return L10n.tr("Localizable", "login.sso.error.alert.invalid_status.message", String(describing: p1))
              }
            }
            internal enum Unknown {
              /// Please try again later.
              internal static let message = L10n.tr("Localizable", "login.sso.error.alert.unknown.message")
            }
          }
          internal enum Offline {
            internal enum Alert {
              /// Please check your Internet connection and try again.
              internal static let message = L10n.tr("Localizable", "login.sso.error.offline.alert.message")
            }
          }
        }
      }
    }
    internal enum Message {
      internal enum DeleteDialog {
        /// This cannot be undone.
        internal static let message = L10n.tr("Localizable", "message.delete_dialog.message")
        internal enum Action {
          /// Cancel
          internal static let cancel = L10n.tr("Localizable", "message.delete_dialog.action.cancel")
          /// Delete for Everyone
          internal static let delete = L10n.tr("Localizable", "message.delete_dialog.action.delete")
          /// Delete for Me
          internal static let hide = L10n.tr("Localizable", "message.delete_dialog.action.hide")
        }
      }
      internal enum Menu {
        internal enum Edit {
          /// Edit
          internal static let title = L10n.tr("Localizable", "message.menu.edit.title")
        }
      }
    }
    internal enum MessageDetails {
      /// Message Details
      internal static let combinedTitle = L10n.tr("Localizable", "message_details.combined_title")
      /// No one has liked this message yet.
      internal static let emptyLikes = L10n.tr("Localizable", "message_details.empty_likes")
      /// No one has read this message yet.
      internal static let emptyReadReceipts = L10n.tr("Localizable", "message_details.empty_read_receipts")
      /// Liked
      internal static let likesTitle = L10n.tr("Localizable", "message_details.likes_title")
      /// Read receipts were not on when this message was sent.
      internal static let readReceiptsDisabled = L10n.tr("Localizable", "message_details.read_receipts_disabled")
      /// Read
      internal static let receiptsTitle = L10n.tr("Localizable", "message_details.receipts_title")
      /// Edited: %@
      internal static func subtitleEditDate(_ p1: Any) -> String {
        return L10n.tr("Localizable", "message_details.subtitle_edit_date", String(describing: p1))
      }
      /// Message Details
      internal static let subtitleLabelVoiceOver = L10n.tr("Localizable", "message_details.subtitle_label_voiceOver")
      /// Sent: %@
      internal static func subtitleSendDate(_ p1: Any) -> String {
        return L10n.tr("Localizable", "message_details.subtitle_send_date", String(describing: p1))
      }
      /// Username
      internal static let userHandleSubtitleLabel = L10n.tr("Localizable", "message_details.user_handle_subtitle_label")
      /// Read at
      internal static let userReadTimestampSubtitleLabel = L10n.tr("Localizable", "message_details.user_read_timestamp_subtitle_label")
      internal enum Tabs {
        /// Liked (%d)
        internal static func likes(_ p1: Int) -> String {
          return L10n.tr("Localizable", "message_details.tabs.likes", p1)
        }
        /// Read (%d)
        internal static func seen(_ p1: Int) -> String {
          return L10n.tr("Localizable", "message_details.tabs.seen", p1)
        }
      }
    }
    internal enum Meta {
      /// Cancel
      internal static let leaveConversationButtonCancel = L10n.tr("Localizable", "meta.leave_conversation_button_cancel")
      /// Leave
      internal static let leaveConversationButtonLeave = L10n.tr("Localizable", "meta.leave_conversation_button_leave")
      /// Leave and clear content
      internal static let leaveConversationButtonLeaveAndDelete = L10n.tr("Localizable", "meta.leave_conversation_button_leave_and_delete")
      /// The participants will be notified and the conversation will be removed from your list.
      internal static let leaveConversationDialogMessage = L10n.tr("Localizable", "meta.leave_conversation_dialog_message")
      /// Leave conversation?
      internal static let leaveConversationDialogTitle = L10n.tr("Localizable", "meta.leave_conversation_dialog_title")
      internal enum Degraded {
        /// Cancel
        internal static let cancelSendingButton = L10n.tr("Localizable", "meta.degraded.cancel_sending_button")
        /// Do you still want to send your message?
        internal static let dialogMessage = L10n.tr("Localizable", "meta.degraded.dialog_message")
        /// Send Anyway
        internal static let sendAnywayButton = L10n.tr("Localizable", "meta.degraded.send_anyway_button")
        /// Verify Devices…
        internal static let verifyDevicesButton = L10n.tr("Localizable", "meta.degraded.verify_devices_button")
        internal enum DegradationReasonMessage {
          /// %@ started using new devices.
          internal static func plural(_ p1: Any) -> String {
            return L10n.tr("Localizable", "meta.degraded.degradation_reason_message.plural", String(describing: p1))
          }
          /// %@ started using a new device.
          internal static func singular(_ p1: Any) -> String {
            return L10n.tr("Localizable", "meta.degraded.degradation_reason_message.singular", String(describing: p1))
          }
          /// Someone started using a new device.
          internal static let someone = L10n.tr("Localizable", "meta.degraded.degradation_reason_message.someone")
        }
      }
      internal enum LeaveConversation {
        /// Also clear the content
        internal static let deleteContentAsWellMessage = L10n.tr("Localizable", "meta.leave_conversation.delete_content_as_well_message")
      }
      internal enum Legalhold {
        /// What Is Legal Hold?
        internal static let infoButton = L10n.tr("Localizable", "meta.legalhold.info_button")
        /// The conversation is now subject to legal hold.
        internal static let sendAlertTitle = L10n.tr("Localizable", "meta.legalhold.send_alert_title")
      }
      internal enum Menu {
        /// More actions
        internal static let accessibilityMoreOptionsButton = L10n.tr("Localizable", "meta.menu.accessibility_more_options_button")
        /// Archive
        internal static let archive = L10n.tr("Localizable", "meta.menu.archive")
        /// Cancel
        internal static let cancel = L10n.tr("Localizable", "meta.menu.cancel")
        /// Cancel Request
        internal static let cancelConnectionRequest = L10n.tr("Localizable", "meta.menu.cancel_connection_request")
        /// Clear Content…
        internal static let clearContent = L10n.tr("Localizable", "meta.menu.clear_content")
        /// Notifications…
        internal static let configureNotifications = L10n.tr("Localizable", "meta.menu.configure_notifications")
        /// Delete Group…
        internal static let delete = L10n.tr("Localizable", "meta.menu.delete")
        /// Leave Group…
        internal static let leave = L10n.tr("Localizable", "meta.menu.leave")
        /// Mark as Read
        internal static let markRead = L10n.tr("Localizable", "meta.menu.mark_read")
        /// Mark as Unread
        internal static let markUnread = L10n.tr("Localizable", "meta.menu.mark_unread")
        /// Move to…
        internal static let moveToFolder = L10n.tr("Localizable", "meta.menu.move_to_folder")
        /// Open Profile
        internal static let openSelfProfile = L10n.tr("Localizable", "meta.menu.open_self_profile")
        /// Remove from "%@"
        internal static func removeFromFolder(_ p1: Any) -> String {
          return L10n.tr("Localizable", "meta.menu.remove_from_folder", String(describing: p1))
        }
        /// Rename
        internal static let rename = L10n.tr("Localizable", "meta.menu.rename")
        /// Unarchive
        internal static let unarchive = L10n.tr("Localizable", "meta.menu.unarchive")
        internal enum ConfigureNotification {
          /// Cancel
          internal static let buttonCancel = L10n.tr("Localizable", "meta.menu.configure_notification.button_cancel")
          /// Everything
          internal static let buttonEverything = L10n.tr("Localizable", "meta.menu.configure_notification.button_everything")
          /// Mentions and Replies
          internal static let buttonMentionsAndReplies = L10n.tr("Localizable", "meta.menu.configure_notification.button_mentions_and_replies")
          /// Nothing
          internal static let buttonNothing = L10n.tr("Localizable", "meta.menu.configure_notification.button_nothing")
          /// Notify me about:
          internal static let dialogMessage = L10n.tr("Localizable", "meta.menu.configure_notification.dialog_message")
        }
        internal enum DeleteContent {
          /// Cancel
          internal static let buttonCancel = L10n.tr("Localizable", "meta.menu.delete_content.button_cancel")
          /// Clear
          internal static let buttonDelete = L10n.tr("Localizable", "meta.menu.delete_content.button_delete")
          /// Clear and leave
          internal static let buttonDeleteAndLeave = L10n.tr("Localizable", "meta.menu.delete_content.button_delete_and_leave")
          /// This will clear the conversation history on all your devices.
          internal static let dialogMessage = L10n.tr("Localizable", "meta.menu.delete_content.dialog_message")
          /// Clear content?
          internal static let dialogTitle = L10n.tr("Localizable", "meta.menu.delete_content.dialog_title")
          /// Also leave the conversation
          internal static let leaveAsWellMessage = L10n.tr("Localizable", "meta.menu.delete_content.leave_as_well_message")
        }
        internal enum Silence {
          /// Mute
          internal static let mute = L10n.tr("Localizable", "meta.menu.silence.mute")
          /// Unmute
          internal static let unmute = L10n.tr("Localizable", "meta.menu.silence.unmute")
        }
      }
    }
    internal enum Migration {
      /// One moment, please
      internal static let pleaseWaitMessage = L10n.tr("Localizable", "migration.please_wait_message")
    }
    internal enum Missive {
      internal enum ConnectionRequest {
        /// Hi %@,
        /// Let’s connect on Wire.
        /// %@
        internal static func defaultMessage(_ p1: Any, _ p2: Any) -> String {
          return L10n.tr("Localizable", "missive.connection_request.default_message", String(describing: p1), String(describing: p2))
        }
      }
    }
    internal enum Name {
      /// Your full name
      internal static let placeholder = L10n.tr("Localizable", "name.placeholder")
      internal enum Guidance {
        /// Too many characters
        internal static let toolong = L10n.tr("Localizable", "name.guidance.toolong")
        /// At least 2 characters
        internal static let tooshort = L10n.tr("Localizable", "name.guidance.tooshort")
      }
    }
    internal enum NewsOffers {
      internal enum Consent {
        /// You can unsubscribe at any time.
        internal static let message = L10n.tr("Localizable", "news_offers.consent.message")
        /// Do you want to receive news and product updates from Wire via email?
        internal static let title = L10n.tr("Localizable", "news_offers.consent.title")
        internal enum Button {
          internal enum PrivacyPolicy {
            /// Privacy Policy
            internal static let title = L10n.tr("Localizable", "news_offers.consent.button.privacy_policy.title")
          }
        }
      }
    }
    internal enum Notifications {
      /// %@ - %@
      internal static func inConversation(_ p1: Any, _ p2: Any) -> String {
        return L10n.tr("Localizable", "notifications.in_conversation", String(describing: p1), String(describing: p2))
      }
      /// pinged
      internal static let pinged = L10n.tr("Localizable", "notifications.pinged")
      /// shared an audio
      internal static let sentAudio = L10n.tr("Localizable", "notifications.sent_audio")
      /// shared a file
      internal static let sentFile = L10n.tr("Localizable", "notifications.sent_file")
      /// shared a location
      internal static let sentLocation = L10n.tr("Localizable", "notifications.sent_location")
      /// shared a video
      internal static let sentVideo = L10n.tr("Localizable", "notifications.sent_video")
      /// shared a picture
      internal static let sharedAPhoto = L10n.tr("Localizable", "notifications.shared_a_photo")
      /// %@ in this conversation
      internal static func thisConversation(_ p1: Any) -> String {
        return L10n.tr("Localizable", "notifications.this_conversation", String(describing: p1))
      }
    }
    internal enum OpenLink {
      internal enum Browser {
        internal enum Option {
          /// Brave
          internal static let brave = L10n.tr("Localizable", "open_link.browser.option.brave")
          /// Chrome
          internal static let chrome = L10n.tr("Localizable", "open_link.browser.option.chrome")
          /// Firefox
          internal static let firefox = L10n.tr("Localizable", "open_link.browser.option.firefox")
          /// Safari
          internal static let safari = L10n.tr("Localizable", "open_link.browser.option.safari")
          /// SnowHaze
          internal static let snowhaze = L10n.tr("Localizable", "open_link.browser.option.snowhaze")
        }
      }
      internal enum Maps {
        /// Some location links will always open in Apple Maps.
        internal static let footer = L10n.tr("Localizable", "open_link.maps.footer")
        internal enum Option {
          /// Maps
          internal static let apple = L10n.tr("Localizable", "open_link.maps.option.apple")
          /// Google Maps
          internal static let google = L10n.tr("Localizable", "open_link.maps.option.google")
        }
      }
      internal enum Twitter {
        internal enum Option {
          /// Browser / Twitter
          internal static let `default` = L10n.tr("Localizable", "open_link.twitter.option.default")
          /// Tweetbot
          internal static let tweetbot = L10n.tr("Localizable", "open_link.twitter.option.tweetbot")
          /// Twitterrific
          internal static let twitterrific = L10n.tr("Localizable", "open_link.twitter.option.twitterrific")
        }
      }
    }
    internal enum Participants {
      /// Add
      internal static let addPeopleButtonTitle = L10n.tr("Localizable", "participants.add_people_button_title")
      /// Details
      internal static let title = L10n.tr("Localizable", "participants.title")
      internal enum All {
        /// People
        internal static let title = L10n.tr("Localizable", "participants.all.title")
      }
      internal enum Avatar {
        internal enum Guest {
          /// Guest
          internal static let title = L10n.tr("Localizable", "participants.avatar.guest.title")
        }
      }
      internal enum Footer {
        /// Add Participants
        internal static let addTitle = L10n.tr("Localizable", "participants.footer.add_title")
      }
      internal enum People {
        /// Plural format key: "%#@lu_number_of_people@"
        internal static func count(_ p1: Int) -> String {
          return L10n.tr("Localizable", "participants.people.count", p1)
        }
      }
      internal enum Section {
        /// People (%d)
        internal static func participants(_ p1: Int) -> String {
          return L10n.tr("Localizable", "participants.section.participants", p1)
        }
        /// Services (%d)
        internal static func services(_ p1: Int) -> String {
          return L10n.tr("Localizable", "participants.section.services", p1)
        }
        /// Options
        internal static let settings = L10n.tr("Localizable", "participants.section.settings")
        internal enum Admins {
          /// There are no admins.
          internal static let footer = L10n.tr("Localizable", "participants.section.admins.footer")
        }
        internal enum Members {
          /// There are no members.
          internal static let footer = L10n.tr("Localizable", "participants.section.members.footer")
        }
        internal enum Name {
          /// Up to %1$d participants can join a group conversation.
          internal static func footer(_ p1: Int) -> String {
            return L10n.tr("Localizable", "participants.section.name.footer", p1)
          }
        }
      }
      internal enum Services {
        internal enum RemoveIntegration {
          /// remove integration
          internal static let button = L10n.tr("Localizable", "participants.services.remove_integration.button")
        }
      }
    }
    internal enum Passcode {
      /// Passcode
      internal static let hintLabel = L10n.tr("Localizable", "passcode.hint_label")
    }
    internal enum Password {
      /// Password
      internal static let placeholder = L10n.tr("Localizable", "password.placeholder")
      internal enum Guidance {
        /// Too many characters
        internal static let toolong = L10n.tr("Localizable", "password.guidance.toolong")
      }
    }
    internal enum Peoplepicker {
      /// Hide
      internal static let hideSearchResult = L10n.tr("Localizable", "peoplepicker.hide_search_result")
      /// Hiding…
      internal static let hideSearchResultProgress = L10n.tr("Localizable", "peoplepicker.hide_search_result_progress")
      /// Invite more people
      internal static let inviteMorePeople = L10n.tr("Localizable", "peoplepicker.invite_more_people")
      /// Invite people to join the team
      internal static let inviteTeamMembers = L10n.tr("Localizable", "peoplepicker.invite_team_members")
      /// No Contacts.
      internal static let noContactsTitle = L10n.tr("Localizable", "peoplepicker.no_contacts_title")
      /// No results.
      internal static let noMatchingResultsAfterAddressBookUploadTitle = L10n.tr("Localizable", "peoplepicker.no_matching_results_after_address_book_upload_title")
      /// No matching results. Try entering a different name.
      internal static let noSearchResults = L10n.tr("Localizable", "peoplepicker.no_search_results")
      /// Search by name or username
      internal static let searchPlaceholder = L10n.tr("Localizable", "peoplepicker.search_placeholder")
      internal enum Button {
        /// Add Participants to Group
        internal static let addToConversation = L10n.tr("Localizable", "peoplepicker.button.add_to_conversation")
        /// Create group
        internal static let createConversation = L10n.tr("Localizable", "peoplepicker.button.create_conversation")
      }
      internal enum Federation {
        /// The federated domain is currently not available. [Learn more](%@)
        internal static func domainUnvailable(_ p1: Any) -> String {
          return L10n.tr("Localizable", "peoplepicker.federation.domain_unvailable", String(describing: p1))
        }
      }
      internal enum Group {
        /// Create
        internal static let create = L10n.tr("Localizable", "peoplepicker.group.create")
        /// Done
        internal static let done = L10n.tr("Localizable", "peoplepicker.group.done")
        /// Skip
        internal static let skip = L10n.tr("Localizable", "peoplepicker.group.skip")
        internal enum Title {
          /// Add Participants (%d)
          internal static func plural(_ p1: Int) -> String {
            return L10n.tr("Localizable", "peoplepicker.group.title.plural", p1)
          }
          /// Add Participants
          internal static let singular = L10n.tr("Localizable", "peoplepicker.group.title.singular")
        }
      }
      internal enum Header {
        /// Contacts
        internal static let contacts = L10n.tr("Localizable", "peoplepicker.header.contacts")
        /// Personal Contacts
        internal static let contactsPersonal = L10n.tr("Localizable", "peoplepicker.header.contacts_personal")
        /// Groups
        internal static let conversations = L10n.tr("Localizable", "peoplepicker.header.conversations")
        /// Connect
        internal static let directory = L10n.tr("Localizable", "peoplepicker.header.directory")
        /// Connect with other domain
        internal static let federation = L10n.tr("Localizable", "peoplepicker.header.federation")
        /// People
        internal static let people = L10n.tr("Localizable", "peoplepicker.header.people")
        /// Invite
        internal static let sendInvitation = L10n.tr("Localizable", "peoplepicker.header.send_invitation")
        /// Services
        internal static let services = L10n.tr("Localizable", "peoplepicker.header.services")
        /// %@ Groups
        internal static func teamConversations(_ p1: Any) -> String {
          return L10n.tr("Localizable", "peoplepicker.header.team_conversations", String(describing: p1))
        }
        /// Top people
        internal static let topPeople = L10n.tr("Localizable", "peoplepicker.header.top_people")
      }
      internal enum NoMatchingResults {
        internal enum Action {
          /// Learn more
          internal static let learnMore = L10n.tr("Localizable", "peoplepicker.no_matching_results.action.learn_more")
          /// Manage Services
          internal static let manageServices = L10n.tr("Localizable", "peoplepicker.no_matching_results.action.manage_services")
          /// Send an invitation
          internal static let sendInvite = L10n.tr("Localizable", "peoplepicker.no_matching_results.action.send_invite")
          /// Share contacts
          internal static let shareContacts = L10n.tr("Localizable", "peoplepicker.no_matching_results.action.share_contacts")
        }
        internal enum Message {
          /// No results.
          internal static let services = L10n.tr("Localizable", "peoplepicker.no_matching_results.message.services")
          /// Services are helpers that can improve your workflow. To enable them, ask your administrator.
          internal static let servicesNotEnabled = L10n.tr("Localizable", "peoplepicker.no_matching_results.message.services_not_enabled")
          /// Services are helpers that can improve your workflow.
          internal static let servicesNotEnabledAdmin = L10n.tr("Localizable", "peoplepicker.no_matching_results.message.services_not_enabled_admin")
          /// Find people in Wire by name or @username
          internal static let users = L10n.tr("Localizable", "peoplepicker.no_matching_results.message.users")
          /// Everyone’s here.
          internal static let usersAllAdded = L10n.tr("Localizable", "peoplepicker.no_matching_results.message.users_all_added")
          /// Find people in Wire by name or @username
          /// 
          /// Find people on another domain by @username@domainname
          internal static let usersAndFederation = L10n.tr("Localizable", "peoplepicker.no_matching_results.message.usersAndFederation")
        }
      }
      internal enum QuickAction {
        /// Manage Services
        internal static let adminServices = L10n.tr("Localizable", "peoplepicker.quick-action.admin-services")
        /// Create group
        internal static let createConversation = L10n.tr("Localizable", "peoplepicker.quick-action.create-conversation")
        /// Create guest room
        internal static let createGuestRoom = L10n.tr("Localizable", "peoplepicker.quick-action.create-guest-room")
        /// Open
        internal static let openConversation = L10n.tr("Localizable", "peoplepicker.quick-action.open-conversation")
      }
      internal enum SendInvitation {
        internal enum Dialog {
          /// It can be used for 2 weeks. Send a new one if it expires.
          internal static let message = L10n.tr("Localizable", "peoplepicker.send_invitation.dialog.message")
          /// OK
          internal static let ok = L10n.tr("Localizable", "peoplepicker.send_invitation.dialog.ok")
          /// Invitation sent
          internal static let title = L10n.tr("Localizable", "peoplepicker.send_invitation.dialog.title")
        }
      }
      internal enum Services {
        internal enum AddService {
          /// Add service
          internal static let button = L10n.tr("Localizable", "peoplepicker.services.add_service.button")
          internal enum Error {
            /// The service is unavailable at the moment
            internal static let `default` = L10n.tr("Localizable", "peoplepicker.services.add_service.error.default")
            /// The conversation is full
            internal static let full = L10n.tr("Localizable", "peoplepicker.services.add_service.error.full")
            /// The service can’t be added
            internal static let title = L10n.tr("Localizable", "peoplepicker.services.add_service.error.title")
          }
        }
        internal enum OpenConversation {
          /// Open conversation
          internal static let item = L10n.tr("Localizable", "peoplepicker.services.open_conversation.item")
        }
      }
      internal enum Suggested {
        /// Plural format key: "Knows %@ and %#@d_number_of_others@"
        internal static func knowsMore(_ p1: Any, _ p2: Int) -> String {
          return L10n.tr("Localizable", "peoplepicker.suggested.knows_more", String(describing: p1), p2)
        }
        /// Knows %@
        internal static func knowsOne(_ p1: Any) -> String {
          return L10n.tr("Localizable", "peoplepicker.suggested.knows_one", String(describing: p1))
        }
        /// Knows %@ and %@
        internal static func knowsTwo(_ p1: Any, _ p2: Any) -> String {
          return L10n.tr("Localizable", "peoplepicker.suggested.knows_two", String(describing: p1), String(describing: p2))
        }
      }
      internal enum Title {
        /// Add participants
        internal static let addToConversation = L10n.tr("Localizable", "peoplepicker.title.add_to_conversation")
        /// Create group
        internal static let createConversation = L10n.tr("Localizable", "peoplepicker.title.create_conversation")
      }
    }
    internal enum Phone {
      internal enum Guidance {
        /// Invalid phone number
        internal static let invalid = L10n.tr("Localizable", "phone.guidance.invalid")
        /// Too many characters
        internal static let toolong = L10n.tr("Localizable", "phone.guidance.toolong")
        /// Phone number is too short
        internal static let tooshort = L10n.tr("Localizable", "phone.guidance.tooshort")
      }
    }
    internal enum Profile {
      /// Block…
      internal static let blockButtonTitle = L10n.tr("Localizable", "profile.block_button_title")
      /// Block
      internal static let blockButtonTitleAction = L10n.tr("Localizable", "profile.block_button_title_action")
      /// CANCEL REQUEST
      internal static let cancelConnectionButtonTitle = L10n.tr("Localizable", "profile.cancel_connection_button_title")
      /// Create group
      internal static let createConversationButtonTitle = L10n.tr("Localizable", "profile.create_conversation_button_title")
      /// Add to Favorites
      internal static let favoriteButtonTitle = L10n.tr("Localizable", "profile.favorite_button_title")
      /// Open conversation
      internal static let openConversationButtonTitle = L10n.tr("Localizable", "profile.open_conversation_button_title")
      /// Cancel
      internal static let removeDialogButtonCancel = L10n.tr("Localizable", "profile.remove_dialog_button_cancel")
      /// Remove From Group…
      internal static let removeDialogButtonRemove = L10n.tr("Localizable", "profile.remove_dialog_button_remove")
      /// Remove From Group
      internal static let removeDialogButtonRemoveConfirm = L10n.tr("Localizable", "profile.remove_dialog_button_remove_confirm")
      /// %@ won’t be able to send or receive messages in this conversation.
      internal static func removeDialogMessage(_ p1: Any) -> String {
        return L10n.tr("Localizable", "profile.remove_dialog_message", String(describing: p1))
      }
      /// Remove?
      internal static let removeDialogTitle = L10n.tr("Localizable", "profile.remove_dialog_title")
      /// Unblock…
      internal static let unblockButtonTitle = L10n.tr("Localizable", "profile.unblock_button_title")
      /// Unblock
      internal static let unblockButtonTitleAction = L10n.tr("Localizable", "profile.unblock_button_title_action")
      /// Remove from Favorites
      internal static let unfavoriteButtonTitle = L10n.tr("Localizable", "profile.unfavorite_button_title")
      internal enum BlockDialog {
        /// Block
        internal static let buttonBlock = L10n.tr("Localizable", "profile.block_dialog.button_block")
        /// Cancel
        internal static let buttonCancel = L10n.tr("Localizable", "profile.block_dialog.button_cancel")
        /// %@ won’t be able to contact you or add you to group conversations.
        internal static func message(_ p1: Any) -> String {
          return L10n.tr("Localizable", "profile.block_dialog.message", String(describing: p1))
        }
        /// Block?
        internal static let title = L10n.tr("Localizable", "profile.block_dialog.title")
      }
      internal enum CancelConnectionRequestDialog {
        /// No
        internal static let buttonNo = L10n.tr("Localizable", "profile.cancel_connection_request_dialog.button_no")
        /// Yes
        internal static let buttonYes = L10n.tr("Localizable", "profile.cancel_connection_request_dialog.button_yes")
        /// Cancel your connection request to %@?
        internal static func message(_ p1: Any) -> String {
          return L10n.tr("Localizable", "profile.cancel_connection_request_dialog.message", String(describing: p1))
        }
        /// Cancel Request?
        internal static let title = L10n.tr("Localizable", "profile.cancel_connection_request_dialog.title")
      }
      internal enum ConnectionRequestDialog {
        /// Ignore
        internal static let buttonCancel = L10n.tr("Localizable", "profile.connection_request_dialog.button_cancel")
        /// Connect
        internal static let buttonConnect = L10n.tr("Localizable", "profile.connection_request_dialog.button_connect")
        /// This will connect you and open the conversation with %@.
        internal static func message(_ p1: Any) -> String {
          return L10n.tr("Localizable", "profile.connection_request_dialog.message", String(describing: p1))
        }
        /// Accept?
        internal static let title = L10n.tr("Localizable", "profile.connection_request_dialog.title")
      }
      internal enum ConnectionRequestState {
        /// BLOCKED
        internal static let blocked = L10n.tr("Localizable", "profile.connection_request_state.blocked")
      }
      internal enum Details {
        /// This user is blocked due to legal hold. [LEARN MORE](%@)
        internal static func blockingReason(_ p1: Any) -> String {
          return L10n.tr("Localizable", "profile.details.blocking_reason", String(describing: p1))
        }
        /// Federated
        internal static let federated = L10n.tr("Localizable", "profile.details.federated")
        /// Group admin
        internal static let groupAdmin = L10n.tr("Localizable", "profile.details.group_admin")
        /// Guest
        internal static let guest = L10n.tr("Localizable", "profile.details.guest")
        /// external
        internal static let partner = L10n.tr("Localizable", "profile.details.partner")
        /// Details
        internal static let title = L10n.tr("Localizable", "profile.details.title")
      }
      internal enum Devices {
        /// %@ is using an old version of Wire. No devices are shown here.
        internal static func fingerprintMessageUnencrypted(_ p1: Any) -> String {
          return L10n.tr("Localizable", "profile.devices.fingerprint_message_unencrypted", String(describing: p1))
        }
        /// Devices
        internal static let title = L10n.tr("Localizable", "profile.devices.title")
        internal enum Detail {
          /// Verify that this matches the fingerprint shown on %@’s device.
          internal static func verifyMessage(_ p1: Any) -> String {
            return L10n.tr("Localizable", "profile.devices.detail.verify_message", String(describing: p1))
          }
          internal enum ResetSession {
            /// Reset Session
            internal static let title = L10n.tr("Localizable", "profile.devices.detail.reset_session.title")
          }
          internal enum ShowMyDevice {
            /// Show my device fingerprint
            internal static let title = L10n.tr("Localizable", "profile.devices.detail.show_my_device.title")
          }
          internal enum VerifyMessage {
            /// How do I do that?
            internal static let link = L10n.tr("Localizable", "profile.devices.detail.verify_message.link")
          }
        }
        internal enum FingerprintMessage {
          /// Why verify conversations?
          internal static let link = L10n.tr("Localizable", "profile.devices.fingerprint_message.link")
          /// Wire gives every device a unique fingerprint. Compare them with %@ and verify your conversation.
          internal static func title(_ p1: Any) -> String {
            return L10n.tr("Localizable", "profile.devices.fingerprint_message.title", String(describing: p1))
          }
        }
      }
      internal enum ExtendedMetadata {
        /// Information
        internal static let header = L10n.tr("Localizable", "profile.extended_metadata.header")
      }
      internal enum GroupAdminStatusMemo {
        /// When this is on, the admin can add or remove people and services, update group settings, and change a participant's role.
        internal static let body = L10n.tr("Localizable", "profile.group_admin_status_memo.body")
      }
      internal enum Profile {
        internal enum GroupAdminOptions {
          /// Group admin
          internal static let title = L10n.tr("Localizable", "profile.profile.group_admin_options.title")
        }
      }
      internal enum ReadReceiptsDisabledMemo {
        /// YOU HAVE DISABLED READ RECEIPTS
        internal static let header = L10n.tr("Localizable", "profile.read_receipts_disabled_memo.header")
      }
      internal enum ReadReceiptsEnabledMemo {
        /// YOU HAVE ENABLED READ RECEIPTS
        internal static let header = L10n.tr("Localizable", "profile.read_receipts_enabled_memo.header")
      }
      internal enum ReadReceiptsMemo {
        /// If both sides turn on read receipts, you can see when messages are read.
        /// 
        /// You can change this option in your account settings.
        internal static let body = L10n.tr("Localizable", "profile.read_receipts_memo.body")
      }
    }
    internal enum Push {
      internal enum Notification {
        /// New message
        internal static let newMessage = L10n.tr("Localizable", "push.notification.new_message")
        /// %@ joined Wire
        internal static func newUser(_ p1: Any) -> String {
          return L10n.tr("Localizable", "push.notification.new_user", String(describing: p1))
        }
      }
    }
    internal enum Registration {
      /// Sign Up
      internal static let confirm = L10n.tr("Localizable", "registration.confirm")
      /// Country Code
      internal static let phoneCode = L10n.tr("Localizable", "registration.phone_code")
      /// Country
      internal static let phoneCountry = L10n.tr("Localizable", "registration.phone_country")
      /// Email
      internal static let registerByEmail = L10n.tr("Localizable", "registration.register_by_email")
      /// Phone
      internal static let registerByPhone = L10n.tr("Localizable", "registration.register_by_phone")
      /// Registration
      internal static let title = L10n.tr("Localizable", "registration.title")
      internal enum AddEmailPassword {
        internal enum Hero {
          /// This lets you use Wire on multiple devices.
          internal static let paragraph = L10n.tr("Localizable", "registration.add_email_password.hero.paragraph")
          /// Add your email and password
          internal static let title = L10n.tr("Localizable", "registration.add_email_password.hero.title")
        }
      }
      internal enum AddPhoneNumber {
        internal enum Hero {
          /// This helps us find people you may know. We never share it.
          internal static let paragraph = L10n.tr("Localizable", "registration.add_phone_number.hero.paragraph")
          /// Add phone number
          internal static let title = L10n.tr("Localizable", "registration.add_phone_number.hero.title")
        }
        internal enum SkipButton {
          /// Not now
          internal static let title = L10n.tr("Localizable", "registration.add_phone_number.skip_button.title")
        }
      }
      internal enum AddressBookAccessDenied {
        internal enum Hero {
          /// Wire helps find your friends if you share your contacts.
          internal static let paragraph1 = L10n.tr("Localizable", "registration.address_book_access_denied.hero.paragraph1")
          /// To enable access tap Settings and turn on Contacts.
          internal static let paragraph2 = L10n.tr("Localizable", "registration.address_book_access_denied.hero.paragraph2")
          /// Wire does not have access to your contacts.
          internal static let title = L10n.tr("Localizable", "registration.address_book_access_denied.hero.title")
        }
        internal enum MaybeLaterButton {
          /// Maybe later
          internal static let title = L10n.tr("Localizable", "registration.address_book_access_denied.maybe_later_button.title")
        }
        internal enum SettingsButton {
          /// Settings
          internal static let title = L10n.tr("Localizable", "registration.address_book_access_denied.settings_button.title")
        }
      }
      internal enum Alert {
        /// Register with Another Email
        internal static let changeEmailAction = L10n.tr("Localizable", "registration.alert.change_email_action")
        /// Register with Another Number
        internal static let changePhoneAction = L10n.tr("Localizable", "registration.alert.change_phone_action")
        /// Log In
        internal static let changeSigninAction = L10n.tr("Localizable", "registration.alert.change_signin_action")
        internal enum AccountExists {
          /// The email address you used to register is already linked to an account.
          /// 
          ///  Use another email address, or try to log in if you own this account.
          internal static let messageEmail = L10n.tr("Localizable", "registration.alert.account_exists.message_email")
          /// The phone number you used to register is already linked to an account.
          /// 
          /// Use another phone number, or try to log in if you own this account.
          internal static let messagePhone = L10n.tr("Localizable", "registration.alert.account_exists.message_phone")
          /// Account Exists
          internal static let title = L10n.tr("Localizable", "registration.alert.account_exists.title")
        }
      }
      internal enum CloseEmailInvitationButton {
        /// Use another email
        internal static let emailTitle = L10n.tr("Localizable", "registration.close_email_invitation_button.email_title")
        /// Register by phone
        internal static let phoneTitle = L10n.tr("Localizable", "registration.close_email_invitation_button.phone_title")
      }
      internal enum ClosePhoneInvitationButton {
        /// Register by email
        internal static let emailTitle = L10n.tr("Localizable", "registration.close_phone_invitation_button.email_title")
        /// Use another phone
        internal static let phoneTitle = L10n.tr("Localizable", "registration.close_phone_invitation_button.phone_title")
      }
      internal enum CountrySelect {
        /// Country
        internal static let title = L10n.tr("Localizable", "registration.country_select.title")
      }
      internal enum Devices {
        /// Activated %@
        internal static func activated(_ p1: Any) -> String {
          return L10n.tr("Localizable", "registration.devices.activated", String(describing: p1))
        }
        /// Active
        internal static let activeListHeader = L10n.tr("Localizable", "registration.devices.active_list_header")
        /// If you don’t recognize a device above, remove it and reset your password.
        internal static let activeListSubtitle = L10n.tr("Localizable", "registration.devices.active_list_subtitle")
        /// Current
        internal static let currentListHeader = L10n.tr("Localizable", "registration.devices.current_list_header")
        /// ID:
        internal static let id = L10n.tr("Localizable", "registration.devices.id")
        /// Devices
        internal static let title = L10n.tr("Localizable", "registration.devices.title")
      }
      internal enum EmailFlow {
        /// Register by Email
        internal static let title = L10n.tr("Localizable", "registration.email_flow.title")
        internal enum EmailStep {
          /// Edit Details
          internal static let title = L10n.tr("Localizable", "registration.email_flow.email_step.title")
        }
      }
      internal enum EmailInvitation {
        /// Invitation
        internal static let title = L10n.tr("Localizable", "registration.email_invitation.title")
        internal enum Hero {
          /// Choose a password to create your account.
          internal static let paragraph = L10n.tr("Localizable", "registration.email_invitation.hero.paragraph")
          /// Hello, %@
          internal static func title(_ p1: Any) -> String {
            return L10n.tr("Localizable", "registration.email_invitation.hero.title", String(describing: p1))
          }
        }
      }
      internal enum EnterName {
        /// What should we call you?
        internal static let hero = L10n.tr("Localizable", "registration.enter_name.hero")
        /// Your full name
        internal static let placeholder = L10n.tr("Localizable", "registration.enter_name.placeholder")
        /// Edit Name
        internal static let title = L10n.tr("Localizable", "registration.enter_name.title")
      }
      internal enum EnterPhoneNumber {
        /// Phone number
        internal static let placeholder = L10n.tr("Localizable", "registration.enter_phone_number.placeholder")
        /// Edit phone number
        internal static let title = L10n.tr("Localizable", "registration.enter_phone_number.title")
      }
      internal enum LaunchBackButton {
        /// Back
        internal static let label = L10n.tr("Localizable", "registration.launch_back_button.label")
      }
      internal enum NoHistory {
        /// OK
        internal static let gotIt = L10n.tr("Localizable", "registration.no_history.got_it")
        /// It’s the first time you’re using Wire on this device.
        internal static let hero = L10n.tr("Localizable", "registration.no_history.hero")
        /// Restore from backup
        internal static let restoreBackup = L10n.tr("Localizable", "registration.no_history.restore_backup")
        /// For privacy reasons, your conversation history will not appear here.
        internal static let subtitle = L10n.tr("Localizable", "registration.no_history.subtitle")
        internal enum LoggedOut {
          /// OK
          internal static let gotIt = L10n.tr("Localizable", "registration.no_history.logged_out.got_it")
          /// You’ve used Wire on this device before.
          internal static let hero = L10n.tr("Localizable", "registration.no_history.logged_out.hero")
          /// Messages sent in the meantime will not appear.
          internal static let subtitle = L10n.tr("Localizable", "registration.no_history.logged_out.subtitle")
        }
        internal enum RestoreBackup {
          /// Completed
          internal static let completed = L10n.tr("Localizable", "registration.no_history.restore_backup.completed")
          /// Restoring…
          internal static let restoring = L10n.tr("Localizable", "registration.no_history.restore_backup.restoring")
          internal enum Password {
            /// The password is required to restore this backup.
            internal static let message = L10n.tr("Localizable", "registration.no_history.restore_backup.password.message")
            /// Password
            internal static let placeholder = L10n.tr("Localizable", "registration.no_history.restore_backup.password.placeholder")
            /// This backup is password protected.
            internal static let title = L10n.tr("Localizable", "registration.no_history.restore_backup.password.title")
          }
          internal enum PasswordError {
            /// Wrong Password
            internal static let title = L10n.tr("Localizable", "registration.no_history.restore_backup.password_error.title")
          }
        }
        internal enum RestoreBackupFailed {
          /// Your history could not be restored.
          internal static let message = L10n.tr("Localizable", "registration.no_history.restore_backup_failed.message")
          /// Something went wrong
          internal static let title = L10n.tr("Localizable", "registration.no_history.restore_backup_failed.title")
          /// Try again
          internal static let tryAgain = L10n.tr("Localizable", "registration.no_history.restore_backup_failed.try_again")
          internal enum WrongAccount {
            /// You cannot restore history from a different account.
            internal static let message = L10n.tr("Localizable", "registration.no_history.restore_backup_failed.wrong_account.message")
            /// Incompatible backup
            internal static let title = L10n.tr("Localizable", "registration.no_history.restore_backup_failed.wrong_account.title")
          }
          internal enum WrongVersion {
            /// This backup was created by a newer or outdated version of Wire and cannot be restored here.
            internal static let message = L10n.tr("Localizable", "registration.no_history.restore_backup_failed.wrong_version.message")
            /// Incompatible backup
            internal static let title = L10n.tr("Localizable", "registration.no_history.restore_backup_failed.wrong_version.title")
          }
        }
        internal enum RestoreBackupWarning {
          /// The backup contents will replace the conversation history on this device.
          /// You can only restore history from a backup of the same platform.
          internal static let message = L10n.tr("Localizable", "registration.no_history.restore_backup_warning.message")
          /// Choose Backup File
          internal static let proceed = L10n.tr("Localizable", "registration.no_history.restore_backup_warning.proceed")
          /// Restore history
          internal static let title = L10n.tr("Localizable", "registration.no_history.restore_backup_warning.title")
        }
      }
      internal enum Password {
        internal enum Rules {
          /// Plural format key: "%#@character_count@"
          internal static func lowercase(_ p1: Int) -> String {
            return L10n.tr("Localizable", "registration.password.rules.lowercase", p1)
          }
          /// Plural format key: "at least %#@character_count@"
          internal static func minLength(_ p1: Int) -> String {
            return L10n.tr("Localizable", "registration.password.rules.min_length", p1)
          }
          /// Use %@.
          internal static func noRequirements(_ p1: Any) -> String {
            return L10n.tr("Localizable", "registration.password.rules.no_requirements", String(describing: p1))
          }
          /// Plural format key: "%#@character_count@"
          internal static func number(_ p1: Int) -> String {
            return L10n.tr("Localizable", "registration.password.rules.number", p1)
          }
          /// Plural format key: "%#@character_count@"
          internal static func special(_ p1: Int) -> String {
            return L10n.tr("Localizable", "registration.password.rules.special", p1)
          }
          /// Plural format key: "%#@character_count@"
          internal static func uppercase(_ p1: Int) -> String {
            return L10n.tr("Localizable", "registration.password.rules.uppercase", p1)
          }
          /// Use %@, with %@.
          internal static func withRequirements(_ p1: Any, _ p2: Any) -> String {
            return L10n.tr("Localizable", "registration.password.rules.with_requirements", String(describing: p1), String(describing: p2))
          }
        }
      }
      internal enum Personal {
        /// Create an account
        internal static let title = L10n.tr("Localizable", "registration.personal.title")
      }
      internal enum Phone {
        internal enum CountryCode {
          /// Double tap to use a phone number from this country.
          internal static let hint = L10n.tr("Localizable", "registration.phone.country_code.hint")
        }
        internal enum Verify {
          /// Verify phone number
          internal static let label = L10n.tr("Localizable", "registration.phone.verify.label")
        }
        internal enum VerifyField {
          /// Verification Code
          internal static let label = L10n.tr("Localizable", "registration.phone.verify_field.label")
        }
      }
      internal enum PhoneCode {
        /// Double tap to select another country code.
        internal static let hint = L10n.tr("Localizable", "registration.phone_code.hint")
      }
      internal enum PhoneCountry {
        /// Double tap to select another country.
        internal static let hint = L10n.tr("Localizable", "registration.phone_country.hint")
      }
      internal enum PhoneInvitation {
        /// Invitation
        internal static let title = L10n.tr("Localizable", "registration.phone_invitation.title")
        internal enum Hero {
          /// You are one step away from creating your account.
          internal static let paragraph = L10n.tr("Localizable", "registration.phone_invitation.hero.paragraph")
          /// Hello, %@
          internal static func title(_ p1: Any) -> String {
            return L10n.tr("Localizable", "registration.phone_invitation.hero.title", String(describing: p1))
          }
        }
      }
      internal enum PushAccessDenied {
        internal enum Hero {
          /// Enable Notifications in Settings.
          internal static let paragraph1 = L10n.tr("Localizable", "registration.push_access_denied.hero.paragraph1")
          /// Never miss a call or a message.
          internal static let title = L10n.tr("Localizable", "registration.push_access_denied.hero.title")
        }
        internal enum MaybeLaterButton {
          /// Maybe later
          internal static let title = L10n.tr("Localizable", "registration.push_access_denied.maybe_later_button.title")
        }
        internal enum SettingsButton {
          /// Go to Settings
          internal static let title = L10n.tr("Localizable", "registration.push_access_denied.settings_button.title")
        }
      }
      internal enum SelectHandle {
        internal enum Takeover {
          /// Choose yours
          internal static let chooseOwn = L10n.tr("Localizable", "registration.select_handle.takeover.choose_own")
          /// Keep this one
          internal static let keepSuggested = L10n.tr("Localizable", "registration.select_handle.takeover.keep_suggested")
          /// Claim your unique name on Wire.
          internal static let subtitle = L10n.tr("Localizable", "registration.select_handle.takeover.subtitle")
          /// Learn more
          internal static let subtitleLink = L10n.tr("Localizable", "registration.select_handle.takeover.subtitle_link")
        }
      }
      internal enum ShareContacts {
        internal enum FindFriendsButton {
          /// Share contacts
          internal static let title = L10n.tr("Localizable", "registration.share_contacts.find_friends_button.title")
        }
        internal enum Hero {
          /// Share your contacts so we can connect you with others. We anonymize all information and do not share it with anyone else.
          internal static let paragraph = L10n.tr("Localizable", "registration.share_contacts.hero.paragraph")
          /// Find people on Wire
          internal static let title = L10n.tr("Localizable", "registration.share_contacts.hero.title")
        }
        internal enum SkipButton {
          /// Not now
          internal static let title = L10n.tr("Localizable", "registration.share_contacts.skip_button.title")
        }
      }
      internal enum Signin {
        /// Log in
        internal static let title = L10n.tr("Localizable", "registration.signin.title")
        internal enum Alert {
          internal enum PasswordNeeded {
            /// Please enter your Password in order to log in.
            internal static let message = L10n.tr("Localizable", "registration.signin.alert.password_needed.message")
            /// Password needed
            internal static let title = L10n.tr("Localizable", "registration.signin.alert.password_needed.title")
          }
        }
        internal enum TooManyDevices {
          /// Remove one of your other devices to start using Wire on this one.
          internal static let subtitle = L10n.tr("Localizable", "registration.signin.too_many_devices.subtitle")
          /// Too Many Devices
          internal static let title = L10n.tr("Localizable", "registration.signin.too_many_devices.title")
          internal enum ManageButton {
            /// Manage devices
            internal static let title = L10n.tr("Localizable", "registration.signin.too_many_devices.manage_button.title")
          }
          internal enum ManageScreen {
            /// Remove a Device
            internal static let title = L10n.tr("Localizable", "registration.signin.too_many_devices.manage_screen.title")
          }
          internal enum SignOutButton {
            /// Log out
            internal static let title = L10n.tr("Localizable", "registration.signin.too_many_devices.sign_out_button.title")
          }
        }
      }
      internal enum TermsOfUse {
        /// Accept
        internal static let accept = L10n.tr("Localizable", "registration.terms_of_use.accept")
        /// I agree
        internal static let agree = L10n.tr("Localizable", "registration.terms_of_use.agree")
        /// By continuing you agree to the Wire Terms of Use.
        internal static let terms = L10n.tr("Localizable", "registration.terms_of_use.terms")
        /// Welcome to Wire.
        internal static let title = L10n.tr("Localizable", "registration.terms_of_use.title")
        internal enum Terms {
          /// Terms of Use
          internal static let link = L10n.tr("Localizable", "registration.terms_of_use.terms.link")
          /// Please accept the Terms of Use to continue.
          internal static let message = L10n.tr("Localizable", "registration.terms_of_use.terms.message")
          /// Terms of Use
          internal static let title = L10n.tr("Localizable", "registration.terms_of_use.terms.title")
          /// View
          internal static let view = L10n.tr("Localizable", "registration.terms_of_use.terms.view")
        }
      }
      internal enum VerifyEmail {
        /// We sent an email to %@.
        ///  Follow the link to verify your address.
        internal static func instructions(_ p1: Any) -> String {
          return L10n.tr("Localizable", "registration.verify_email.instructions", String(describing: p1))
        }
        internal enum Resend {
          /// Re-send
          internal static let buttonTitle = L10n.tr("Localizable", "registration.verify_email.resend.button_title")
          /// Didn’t get the message?
          internal static let instructions = L10n.tr("Localizable", "registration.verify_email.resend.instructions")
        }
      }
      internal enum VerifyPhoneNumber {
        /// Enter the verification code we sent to %@
        internal static func instructions(_ p1: Any) -> String {
          return L10n.tr("Localizable", "registration.verify_phone_number.instructions", String(describing: p1))
        }
        /// Resend
        internal static let resend = L10n.tr("Localizable", "registration.verify_phone_number.resend")
        /// No code showing up?
        /// You can request a new one in %.0f seconds
        internal static func resendPlaceholder(_ p1: Float) -> String {
          return L10n.tr("Localizable", "registration.verify_phone_number.resend_placeholder", p1)
        }
      }
    }
    internal enum SecurityClassification {
      /// SECURITY LEVEL:
      internal static let securityLevel = L10n.tr("Localizable", "security_classification.security_level")
      internal enum Level {
        /// VS-NfD
        internal static let bund = L10n.tr("Localizable", "security_classification.level.bund")
        /// UNCLASSIFIED
        internal static let notClassified = L10n.tr("Localizable", "security_classification.level.not_classified")
      }
    }
    internal enum `Self` {
      /// About
      internal static let about = L10n.tr("Localizable", "self.about")
      /// Account
      internal static let account = L10n.tr("Localizable", "self.account")
      /// Add email address and password
      internal static let addEmailPassword = L10n.tr("Localizable", "self.add_email_password")
      /// Support
      internal static let helpCenter = L10n.tr("Localizable", "self.help_center")
      /// Profile
      internal static let profile = L10n.tr("Localizable", "self.profile")
      /// Report Misuse
      internal static let reportAbuse = L10n.tr("Localizable", "self.report_abuse")
      /// Settings
      internal static let settings = L10n.tr("Localizable", "self.settings")
      /// Log Out
      internal static let signOut = L10n.tr("Localizable", "self.sign_out")
      internal enum HelpCenter {
        /// Contact Support
        internal static let contactSupport = L10n.tr("Localizable", "self.help_center.contact_support")
        /// Wire Support Website
        internal static let supportWebsite = L10n.tr("Localizable", "self.help_center.support_website")
      }
      internal enum NewDevice {
        internal enum Voiceover {
          /// Profile, new devices added
          internal static let label = L10n.tr("Localizable", "self.new-device.voiceover.label")
        }
      }
      internal enum NewDeviceAlert {
        /// Manage devices
        internal static let manageDevices = L10n.tr("Localizable", "self.new_device_alert.manage_devices")
        /// 
        /// %@
        /// 
        /// If you don’t recognize the device above, remove it and reset your password.
        internal static func message(_ p1: Any) -> String {
          return L10n.tr("Localizable", "self.new_device_alert.message", String(describing: p1))
        }
        /// 
        /// %@
        /// 
        /// If you don’t recognize the devices above, remove them and reset your password.
        internal static func messagePlural(_ p1: Any) -> String {
          return L10n.tr("Localizable", "self.new_device_alert.message_plural", String(describing: p1))
        }
        /// Your account was used on:
        internal static let title = L10n.tr("Localizable", "self.new_device_alert.title")
        /// OK
        internal static let trustDevices = L10n.tr("Localizable", "self.new_device_alert.trust_devices")
        internal enum TitlePrefix {
          /// Plural format key: "%#@device_count@"
          internal static func devices(_ p1: Int) -> String {
            return L10n.tr("Localizable", "self.new_device_alert.title_prefix.devices", p1)
          }
        }
      }
      internal enum ReadReceiptsDescription {
        /// You can change this option in your account settings.
        internal static let title = L10n.tr("Localizable", "self.read_receipts_description.title")
      }
      internal enum ReadReceiptsDisabled {
        /// You have disabled read receipts
        internal static let title = L10n.tr("Localizable", "self.read_receipts_disabled.title")
      }
      internal enum ReadReceiptsEnabled {
        /// You have enabled read receipts
        internal static let title = L10n.tr("Localizable", "self.read_receipts_enabled.title")
      }
      internal enum Settings {
        /// Account
        internal static let accountSection = L10n.tr("Localizable", "self.settings.account_section")
        internal enum Account {
          internal enum DataUsagePermissions {
            /// Data Usage Permissions
            internal static let title = L10n.tr("Localizable", "self.settings.account.data_usage_permissions.title")
          }
        }
        internal enum AccountAppearanceGroup {
          /// Appearance
          internal static let title = L10n.tr("Localizable", "self.settings.account_appearance_group.title")
        }
        internal enum AccountDetails {
          internal enum Actions {
            /// Actions
            internal static let title = L10n.tr("Localizable", "self.settings.account_details.actions.title")
          }
          internal enum DeleteAccount {
            /// Delete Account
            internal static let title = L10n.tr("Localizable", "self.settings.account_details.delete_account.title")
            internal enum Alert {
              /// We will send you a message via email or SMS. Follow the link to permanently delete your account.
              internal static let message = L10n.tr("Localizable", "self.settings.account_details.delete_account.alert.message")
              /// Delete Account
              internal static let title = L10n.tr("Localizable", "self.settings.account_details.delete_account.alert.title")
            }
          }
          internal enum KeyFingerprint {
            /// Key Fingerprint
            internal static let title = L10n.tr("Localizable", "self.settings.account_details.key_fingerprint.title")
          }
          internal enum LogOut {
            internal enum Alert {
              /// Your message history will be erased on this device.
              internal static let message = L10n.tr("Localizable", "self.settings.account_details.log_out.alert.message")
              /// Password
              internal static let password = L10n.tr("Localizable", "self.settings.account_details.log_out.alert.password")
              /// Log out
              internal static let title = L10n.tr("Localizable", "self.settings.account_details.log_out.alert.title")
            }
          }
          internal enum RemoveDevice {
            /// Your password is required to remove the device
            internal static let message = L10n.tr("Localizable", "self.settings.account_details.remove_device.message")
            /// Password
            internal static let password = L10n.tr("Localizable", "self.settings.account_details.remove_device.password")
            /// Remove Device
            internal static let title = L10n.tr("Localizable", "self.settings.account_details.remove_device.title")
            internal enum Password {
              /// Wrong password
              internal static let error = L10n.tr("Localizable", "self.settings.account_details.remove_device.password.error")
            }
          }
        }
        internal enum AccountDetailsGroup {
          internal enum Info {
            /// People can find you with these details.
            internal static let footer = L10n.tr("Localizable", "self.settings.account_details_group.info.footer")
            /// Info
            internal static let title = L10n.tr("Localizable", "self.settings.account_details_group.info.title")
          }
          internal enum Personal {
            /// This information is not visible .
            internal static let footer = L10n.tr("Localizable", "self.settings.account_details_group.personal.footer")
            /// Personal
            internal static let title = L10n.tr("Localizable", "self.settings.account_details_group.personal.title")
          }
        }
        internal enum AccountPersonalInformationGroup {
          /// Personal Information
          internal static let title = L10n.tr("Localizable", "self.settings.account_personal_information_group.title")
        }
        internal enum AccountPictureGroup {
          /// Color
          internal static let color = L10n.tr("Localizable", "self.settings.account_picture_group.color")
          /// Picture
          internal static let picture = L10n.tr("Localizable", "self.settings.account_picture_group.picture")
          /// Theme
          internal static let theme = L10n.tr("Localizable", "self.settings.account_picture_group.theme")
        }
        internal enum AccountSection {
          internal enum AddHandle {
            /// Add username
            internal static let title = L10n.tr("Localizable", "self.settings.account_section.add_handle.title")
          }
          internal enum Domain {
            /// Domain
            internal static let title = L10n.tr("Localizable", "self.settings.account_section.domain.title")
          }
          internal enum Email {
            /// Email
            internal static let title = L10n.tr("Localizable", "self.settings.account_section.email.title")
            internal enum Change {
              /// Save
              internal static let save = L10n.tr("Localizable", "self.settings.account_section.email.change.save")
              /// Email
              internal static let title = L10n.tr("Localizable", "self.settings.account_section.email.change.title")
              internal enum Resend {
                /// Confirmation email was resent to %@. Check your email inbox and follow the instructions.
                internal static func message(_ p1: Any) -> String {
                  return L10n.tr("Localizable", "self.settings.account_section.email.change.resend.message", String(describing: p1))
                }
                /// Email resent
                internal static let title = L10n.tr("Localizable", "self.settings.account_section.email.change.resend.title")
              }
              internal enum Verify {
                /// Check your email inbox and follow the instructions.
                internal static let description = L10n.tr("Localizable", "self.settings.account_section.email.change.verify.description")
                /// Resend to %@
                internal static func resend(_ p1: Any) -> String {
                  return L10n.tr("Localizable", "self.settings.account_section.email.change.verify.resend", String(describing: p1))
                }
                /// Verify email
                internal static let title = L10n.tr("Localizable", "self.settings.account_section.email.change.verify.title")
              }
            }
          }
          internal enum Handle {
            /// Username
            internal static let title = L10n.tr("Localizable", "self.settings.account_section.handle.title")
            internal enum Change {
              /// At least 2 characters. a—z, 0—9, and  '.', '-', '_'  only.
              internal static let footer = L10n.tr("Localizable", "self.settings.account_section.handle.change.footer")
              /// Save
              internal static let save = L10n.tr("Localizable", "self.settings.account_section.handle.change.save")
              /// Username
              internal static let title = L10n.tr("Localizable", "self.settings.account_section.handle.change.title")
              internal enum FailureAlert {
                /// There was an error setting your username. Please try again.
                internal static let message = L10n.tr("Localizable", "self.settings.account_section.handle.change.failure_alert.message")
                /// Unable to set username
                internal static let title = L10n.tr("Localizable", "self.settings.account_section.handle.change.failure_alert.title")
              }
              internal enum Footer {
                /// Already taken
                internal static let unavailable = L10n.tr("Localizable", "self.settings.account_section.handle.change.footer.unavailable")
              }
            }
          }
          internal enum Name {
            /// Name
            internal static let title = L10n.tr("Localizable", "self.settings.account_section.name.title")
          }
          internal enum Phone {
            /// Phone
            internal static let title = L10n.tr("Localizable", "self.settings.account_section.phone.title")
          }
          internal enum PhoneNumber {
            internal enum Change {
              /// Remove Phone Number
              internal static let remove = L10n.tr("Localizable", "self.settings.account_section.phone_number.change.remove")
              /// Save
              internal static let save = L10n.tr("Localizable", "self.settings.account_section.phone_number.change.save")
              /// Phone
              internal static let title = L10n.tr("Localizable", "self.settings.account_section.phone_number.change.title")
              internal enum Remove {
                /// Remove Phone Number
                internal static let action = L10n.tr("Localizable", "self.settings.account_section.phone_number.change.remove.action")
              }
              internal enum Resend {
                /// Verification code was resent to %@.
                internal static func message(_ p1: Any) -> String {
                  return L10n.tr("Localizable", "self.settings.account_section.phone_number.change.resend.message", String(describing: p1))
                }
                /// Code resent
                internal static let title = L10n.tr("Localizable", "self.settings.account_section.phone_number.change.resend.title")
              }
              internal enum Verify {
                /// Enter code
                internal static let codePlaceholder = L10n.tr("Localizable", "self.settings.account_section.phone_number.change.verify.code_placeholder")
                /// Enter the verification code we sent to: %@.
                internal static func description(_ p1: Any) -> String {
                  return L10n.tr("Localizable", "self.settings.account_section.phone_number.change.verify.description", String(describing: p1))
                }
                /// Resend Code
                internal static let resend = L10n.tr("Localizable", "self.settings.account_section.phone_number.change.verify.resend")
                /// No code showing up?
                /// You can request a new one every 30 seconds.
                internal static let resendDescription = L10n.tr("Localizable", "self.settings.account_section.phone_number.change.verify.resend_description")
                /// Save
                internal static let save = L10n.tr("Localizable", "self.settings.account_section.phone_number.change.verify.save")
                /// Verify
                internal static let title = L10n.tr("Localizable", "self.settings.account_section.phone_number.change.verify.title")
              }
            }
          }
          internal enum ProfileLink {
            /// Profile link
            internal static let title = L10n.tr("Localizable", "self.settings.account_section.profile_link.title")
            internal enum Actions {
              /// Profile Link Copied!
              internal static let copiedLink = L10n.tr("Localizable", "self.settings.account_section.profile_link.actions.copied_link")
              /// Copy Profile Link
              internal static let copyLink = L10n.tr("Localizable", "self.settings.account_section.profile_link.actions.copy_link")
            }
          }
          internal enum Team {
            /// Team
            internal static let title = L10n.tr("Localizable", "self.settings.account_section.team.title")
          }
        }
        internal enum AddAccount {
          /// Add an account
          internal static let title = L10n.tr("Localizable", "self.settings.add_account.title")
          internal enum Error {
            /// You can only be logged in with three accounts at once. Log out from one to add another.
            internal static let message = L10n.tr("Localizable", "self.settings.add_account.error.message")
            /// Three accounts active
            internal static let title = L10n.tr("Localizable", "self.settings.add_account.error.title")
          }
        }
        internal enum AddTeamOrAccount {
          /// Add Account
          internal static let title = L10n.tr("Localizable", "self.settings.add_team_or_account.title")
        }
        internal enum Advanced {
          /// Advanced
          internal static let title = L10n.tr("Localizable", "self.settings.advanced.title")
          internal enum DebuggingTools {
            /// Debugging Tools
            internal static let title = L10n.tr("Localizable", "self.settings.advanced.debugging_tools.title")
            internal enum EnterDebugCommand {
              /// Enter debug command
              internal static let title = L10n.tr("Localizable", "self.settings.advanced.debugging_tools.enter_debug_command.title")
            }
            internal enum FirstUnreadConversation {
              /// Find first unread conversation
              internal static let title = L10n.tr("Localizable", "self.settings.advanced.debugging_tools.first_unread_conversation.title")
            }
            internal enum ShowUserId {
              /// Show my user ID
              internal static let title = L10n.tr("Localizable", "self.settings.advanced.debugging_tools.show_user_id.title")
            }
          }
          internal enum ResetPushToken {
            /// If you experience problems with push notifications, Wire Support may ask you to reset this token.
            internal static let subtitle = L10n.tr("Localizable", "self.settings.advanced.reset_push_token.subtitle")
            /// Reset Push Notifications Token
            internal static let title = L10n.tr("Localizable", "self.settings.advanced.reset_push_token.title")
          }
          internal enum ResetPushTokenAlert {
            /// Notifications will be restored in a few seconds.
            internal static let message = L10n.tr("Localizable", "self.settings.advanced.reset_push_token_alert.message")
            /// Push token has been reset
            internal static let title = L10n.tr("Localizable", "self.settings.advanced.reset_push_token_alert.title")
          }
          internal enum Troubleshooting {
            /// Troubleshooting
            internal static let title = L10n.tr("Localizable", "self.settings.advanced.troubleshooting.title")
            internal enum SubmitDebug {
              /// This information helps Wire Support diagnose calling problems and improve the overall app experience.
              internal static let subtitle = L10n.tr("Localizable", "self.settings.advanced.troubleshooting.submit_debug.subtitle")
              /// Debug Report
              internal static let title = L10n.tr("Localizable", "self.settings.advanced.troubleshooting.submit_debug.title")
            }
          }
          internal enum VersionTechnicalDetails {
            /// Version Technical Details
            internal static let title = L10n.tr("Localizable", "self.settings.advanced.version_technical_details.title")
          }
        }
        internal enum ApnsLogging {
          /// APNS Logging
          internal static let title = L10n.tr("Localizable", "self.settings.apns_logging.title")
        }
        internal enum Callkit {
          /// Share with iOS
          internal static let caption = L10n.tr("Localizable", "self.settings.callkit.caption")
          /// Show Wire calls on the lock screen and in iOS call history. If iCloud is enabled, call history is shared with Apple.
          internal static let description = L10n.tr("Localizable", "self.settings.callkit.description")
          /// Calls
          internal static let title = L10n.tr("Localizable", "self.settings.callkit.title")
        }
        internal enum Conversations {
          /// History
          internal static let title = L10n.tr("Localizable", "self.settings.conversations.title")
        }
        internal enum CreateTeam {
          /// Create a team
          internal static let title = L10n.tr("Localizable", "self.settings.create_team.title")
        }
        internal enum DeveloperOptions {
          /// Developer Options
          internal static let title = L10n.tr("Localizable", "self.settings.developer_options.title")
          internal enum DatabaseStatistics {
            /// Database Statistics
            internal static let title = L10n.tr("Localizable", "self.settings.developer_options.database_statistics.title")
          }
          internal enum Loggin {
            /// Options
            internal static let title = L10n.tr("Localizable", "self.settings.developer_options.loggin.title")
          }
        }
        internal enum DeviceDetails {
          internal enum Fingerprint {
            /// Wire gives every device a unique fingerprint. Compare them and verify your devices and conversations.
            internal static let subtitle = L10n.tr("Localizable", "self.settings.device_details.fingerprint.subtitle")
          }
          internal enum RemoveDevice {
            /// Remove this device if you have stopped using it. You will be logged out of this device immediately.
            internal static let subtitle = L10n.tr("Localizable", "self.settings.device_details.remove_device.subtitle")
          }
          internal enum ResetSession {
            /// If fingerprints don’t match, reset the session to generate new encryption keys on both sides.
            internal static let subtitle = L10n.tr("Localizable", "self.settings.device_details.reset_session.subtitle")
            /// The session has been reset
            internal static let success = L10n.tr("Localizable", "self.settings.device_details.reset_session.success")
          }
        }
        internal enum EnableReadReceipts {
          /// Send Read Receipts
          internal static let title = L10n.tr("Localizable", "self.settings.enable_read_receipts.title")
        }
        internal enum EncryptMessagesAtRest {
          /// Encrypt messages at rest
          internal static let title = L10n.tr("Localizable", "self.settings.encrypt_messages_at_rest.title")
        }
        internal enum ExternalApps {
          /// Open With
          internal static let header = L10n.tr("Localizable", "self.settings.external_apps.header")
        }
        internal enum HistoryBackup {
          /// Back Up Now
          internal static let action = L10n.tr("Localizable", "self.settings.history_backup.action")
          /// Create a backup to preserve your conversation history. You can use this to restore history if you lose your device or switch to a new one.
          /// 
          /// Choose a strong password to protect the backup file.
          internal static let description = L10n.tr("Localizable", "self.settings.history_backup.description")
          /// Back Up Conversations
          internal static let title = L10n.tr("Localizable", "self.settings.history_backup.title")
          internal enum Error {
            /// Error
            internal static let title = L10n.tr("Localizable", "self.settings.history_backup.error.title")
          }
          internal enum Password {
            /// Cancel
            internal static let cancel = L10n.tr("Localizable", "self.settings.history_backup.password.cancel")
            /// The backup will be compressed and encrypted with the password you set here.
            internal static let description = L10n.tr("Localizable", "self.settings.history_backup.password.description")
            /// Next
            internal static let next = L10n.tr("Localizable", "self.settings.history_backup.password.next")
            /// Password
            internal static let placeholder = L10n.tr("Localizable", "self.settings.history_backup.password.placeholder")
            /// Set Password
            internal static let title = L10n.tr("Localizable", "self.settings.history_backup.password.title")
          }
          internal enum SetEmail {
            /// You need an email and a password in order to back up your conversation history. You can do it from the account page in Settings.
            internal static let message = L10n.tr("Localizable", "self.settings.history_backup.set_email.message")
            /// Set an email and password.
            internal static let title = L10n.tr("Localizable", "self.settings.history_backup.set_email.title")
          }
        }
        internal enum InviteFriends {
          /// Invite people
          internal static let title = L10n.tr("Localizable", "self.settings.invite_friends.title")
        }
        internal enum LinkOptions {
          internal enum Browser {
            /// Browser
            internal static let title = L10n.tr("Localizable", "self.settings.link_options.browser.title")
          }
          internal enum Maps {
            /// Locations
            internal static let title = L10n.tr("Localizable", "self.settings.link_options.maps.title")
          }
          internal enum Twitter {
            /// Tweets
            internal static let title = L10n.tr("Localizable", "self.settings.link_options.twitter.title")
          }
        }
        internal enum ManageTeam {
          /// Manage Team
          internal static let title = L10n.tr("Localizable", "self.settings.manage_team.title")
        }
        internal enum MuteOtherCall {
          /// Silence other calls
          internal static let caption = L10n.tr("Localizable", "self.settings.mute_other_call.caption")
          /// Enable to silence incoming calls when you are already in an ongoing call.
          internal static let description = L10n.tr("Localizable", "self.settings.mute_other_call.description")
        }
        internal enum Notifications {
          internal enum ChatAlerts {
            /// New messages in other conversations.
            internal static let footer = L10n.tr("Localizable", "self.settings.notifications.chat_alerts.footer")
            /// Message Banners
            internal static let toggle = L10n.tr("Localizable", "self.settings.notifications.chat_alerts.toggle")
          }
          internal enum PushNotification {
            /// Sender name and message on the lock screen and in Notification Center.
            internal static let footer = L10n.tr("Localizable", "self.settings.notifications.push_notification.footer")
            /// Notifications
            internal static let title = L10n.tr("Localizable", "self.settings.notifications.push_notification.title")
            /// Message Previews
            internal static let toogle = L10n.tr("Localizable", "self.settings.notifications.push_notification.toogle")
          }
        }
        internal enum OptionsMenu {
          /// Options
          internal static let title = L10n.tr("Localizable", "self.settings.options_menu.title")
        }
        internal enum PasswordResetMenu {
          /// Reset Password
          internal static let title = L10n.tr("Localizable", "self.settings.password_reset_menu.title")
        }
        internal enum PopularDemand {
          /// By popular demand
          internal static let title = L10n.tr("Localizable", "self.settings.popular_demand.title")
          internal enum DarkMode {
            /// Switch between dark and light theme.
            internal static let footer = L10n.tr("Localizable", "self.settings.popular_demand.dark_mode.footer")
          }
          internal enum SendButton {
            /// Disable to send via the return key.
            internal static let footer = L10n.tr("Localizable", "self.settings.popular_demand.send_button.footer")
            /// Send Button
            internal static let title = L10n.tr("Localizable", "self.settings.popular_demand.send_button.title")
          }
        }
        internal enum Privacy {
          internal enum ClearHistory {
            /// This will permanently erase the content of all your conversations.
            internal static let subtitle = L10n.tr("Localizable", "self.settings.privacy.clear_history.subtitle")
            /// Clear History
            internal static let title = L10n.tr("Localizable", "self.settings.privacy.clear_history.title")
          }
        }
        internal enum PrivacyAnalytics {
          /// Send anonymous usage data
          internal static let title = L10n.tr("Localizable", "self.settings.privacy_analytics.title")
        }
        internal enum PrivacyAnalyticsMenu {
          internal enum Description {
            /// Usage data allows Wire to understand how the app is being used and how it can be improved. The data is anonymous and does not include the content of your communications (such as messages, files or calls).
            internal static let title = L10n.tr("Localizable", "self.settings.privacy_analytics_menu.description.title")
          }
          internal enum Devices {
            /// Devices
            internal static let title = L10n.tr("Localizable", "self.settings.privacy_analytics_menu.devices.title")
          }
        }
        internal enum PrivacyAnalyticsSection {
          /// Usage and Crash Reports
          internal static let title = L10n.tr("Localizable", "self.settings.privacy_analytics_section.title")
        }
        internal enum PrivacyContactsMenu {
          internal enum DescriptionDisabled {
            /// This helps you connect with others. We anonymize all the information and do not share it with anyone else. Allow access via Settings > Privacy > Contacts.
            internal static let title = L10n.tr("Localizable", "self.settings.privacy_contacts_menu.description_disabled.title")
          }
          internal enum SettingsButton {
            /// Open Contacts Settings
            internal static let title = L10n.tr("Localizable", "self.settings.privacy_contacts_menu.settings_button.title")
          }
        }
        internal enum PrivacyContactsSection {
          /// Contacts
          internal static let title = L10n.tr("Localizable", "self.settings.privacy_contacts_section.title")
        }
        internal enum PrivacyCrash {
          /// Send anonymous crash data
          internal static let title = L10n.tr("Localizable", "self.settings.privacy_crash.title")
        }
        internal enum PrivacyCrashMenu {
          internal enum Description {
            /// Send anonymous crash reports and basic data like version number and operating system to help Wire identify and solve issues in the app.
            internal static let title = L10n.tr("Localizable", "self.settings.privacy_crash_menu.description.title")
          }
        }
        internal enum PrivacySectionGroup {
          /// When this is off, you won’t be able to see read receipts from other people.
          /// 
          /// This setting does not apply to group conversations.
          internal static let subtitle = L10n.tr("Localizable", "self.settings.privacy_section_group.subtitle")
          /// Privacy
          internal static let title = L10n.tr("Localizable", "self.settings.privacy_section_group.title")
        }
        internal enum PrivacySecurity {
          /// Lock With Passcode
          internal static let lockApp = L10n.tr("Localizable", "self.settings.privacy_security.lock_app")
          internal enum DisableLinkPreviews {
            /// Previews may still be shown for links from other people.
            internal static let footer = L10n.tr("Localizable", "self.settings.privacy_security.disable_link_previews.footer")
            /// Create Link Previews
            internal static let title = L10n.tr("Localizable", "self.settings.privacy_security.disable_link_previews.title")
          }
          internal enum LockApp {
            /// Unlock Wire
            internal static let description = L10n.tr("Localizable", "self.settings.privacy_security.lock_app.description")
            internal enum Subtitle {
              /// If forgotten, your passcode can not be recovered.
              internal static let customAppLockReminder = L10n.tr("Localizable", "self.settings.privacy_security.lock_app.subtitle.custom_app_lock_reminder")
              /// Unlock with Face ID or enter your passcode.
              internal static let faceId = L10n.tr("Localizable", "self.settings.privacy_security.lock_app.subtitle.face_id")
              /// Lock Wire after %@ in the background.
              internal static func lockDescription(_ p1: Any) -> String {
                return L10n.tr("Localizable", "self.settings.privacy_security.lock_app.subtitle.lock_description", String(describing: p1))
              }
              /// Unlock by entering your passcode.
              internal static let `none` = L10n.tr("Localizable", "self.settings.privacy_security.lock_app.subtitle.none")
              /// Unlock with Touch ID or enter your passcode.
              internal static let touchId = L10n.tr("Localizable", "self.settings.privacy_security.lock_app.subtitle.touch_id")
            }
          }
          internal enum LockPassword {
            internal enum Description {
              /// Unlock with your password.
              internal static let unlock = L10n.tr("Localizable", "self.settings.privacy_security.lock_password.description.unlock")
              /// Wrong password. If you recently changed your password, connect to the internet and try again.
              internal static let wrongOfflinePassword = L10n.tr("Localizable", "self.settings.privacy_security.lock_password.description.wrong_offline_password")
              /// Wrong password. Please try again.
              internal static let wrongPassword = L10n.tr("Localizable", "self.settings.privacy_security.lock_password.description.wrong_password")
            }
          }
        }
        internal enum ReceiveNewsAndOffers {
          /// Receive Newsletter
          internal static let title = L10n.tr("Localizable", "self.settings.receiveNews_and_offers.title")
          internal enum Description {
            /// Receive news and product updates from Wire via email.
            internal static let title = L10n.tr("Localizable", "self.settings.receiveNews_and_offers.description.title")
          }
        }
        internal enum SoundMenu {
          /// Sound Alerts
          internal static let title = L10n.tr("Localizable", "self.settings.sound_menu.title")
          internal enum AllSounds {
            /// All
            internal static let title = L10n.tr("Localizable", "self.settings.sound_menu.all_sounds.title")
          }
          internal enum Message {
            /// Text Tone
            internal static let title = L10n.tr("Localizable", "self.settings.sound_menu.message.title")
          }
          internal enum MuteWhileTalking {
            /// First message and pings
            internal static let title = L10n.tr("Localizable", "self.settings.sound_menu.mute_while_talking.title")
          }
          internal enum NoSounds {
            /// None
            internal static let title = L10n.tr("Localizable", "self.settings.sound_menu.no_sounds.title")
          }
          internal enum Ping {
            /// Ping
            internal static let title = L10n.tr("Localizable", "self.settings.sound_menu.ping.title")
          }
          internal enum Ringtone {
            /// Ringtone
            internal static let title = L10n.tr("Localizable", "self.settings.sound_menu.ringtone.title")
          }
          internal enum Ringtones {
            /// Ringtones
            internal static let title = L10n.tr("Localizable", "self.settings.sound_menu.ringtones.title")
          }
          internal enum Sounds {
            /// None
            internal static let `none` = L10n.tr("Localizable", "self.settings.sound_menu.sounds.none")
            /// Sounds
            internal static let title = L10n.tr("Localizable", "self.settings.sound_menu.sounds.title")
            /// Wire Call
            internal static let wireCall = L10n.tr("Localizable", "self.settings.sound_menu.sounds.wire_call")
            /// Wire Message
            internal static let wireMessage = L10n.tr("Localizable", "self.settings.sound_menu.sounds.wire_message")
            /// Wire Ping
            internal static let wirePing = L10n.tr("Localizable", "self.settings.sound_menu.sounds.wire_ping")
            /// Wire
            internal static let wireSound = L10n.tr("Localizable", "self.settings.sound_menu.sounds.wire_sound")
          }
        }
        internal enum SwitchAccount {
          /// Switch anyway
          internal static let action = L10n.tr("Localizable", "self.settings.switch_account.action")
          /// A call is active in this account.
          /// Switching accounts will hang up the current call.
          internal static let message = L10n.tr("Localizable", "self.settings.switch_account.message")
        }
        internal enum TechnicalReport {
          /// Include detailed log
          internal static let includeLog = L10n.tr("Localizable", "self.settings.technical_report.include_log")
          /// No mail client detected. Tap "OK" and send logs manually to: 
          internal static let noMailAlert = L10n.tr("Localizable", "self.settings.technical_report.no_mail_alert")
          /// Detailed logs could contain personal data
          internal static let privacyWarning = L10n.tr("Localizable", "self.settings.technical_report.privacy_warning")
          /// Send report to Wire
          internal static let sendReport = L10n.tr("Localizable", "self.settings.technical_report.send_report")
          internal enum Mail {
            /// Wire Debug Report
            internal static let subject = L10n.tr("Localizable", "self.settings.technical_report.mail.subject")
          }
        }
        internal enum TechnicalReportSection {
          /// Technical Report
          internal static let title = L10n.tr("Localizable", "self.settings.technical_report_section.title")
        }
        internal enum Vbr {
          /// This makes audio calls use less data and work better on slower networks. Turn off to use constant bitrate encoding (CBR). This setting only affects 1:1 calls; conference calls always use CBR encoding.
          internal static let description = L10n.tr("Localizable", "self.settings.vbr.description")
          /// Variable Bit Rate Encoding
          internal static let title = L10n.tr("Localizable", "self.settings.vbr.title")
        }
      }
      internal enum Voiceover {
        /// Open profile and settings
        internal static let hint = L10n.tr("Localizable", "self.voiceover.hint")
        /// Profile
        internal static let label = L10n.tr("Localizable", "self.voiceover.label")
      }
    }
    internal enum SendInvitation {
      /// Connect with me on Wire
      internal static let subject = L10n.tr("Localizable", "send_invitation.subject")
      /// I’m on Wire, search for %@ or visit get.wire.com
      internal static func text(_ p1: Any) -> String {
        return L10n.tr("Localizable", "send_invitation.text", String(describing: p1))
      }
    }
    internal enum SendInvitationNoEmail {
      /// I’m on Wire. Visit get.wire.com to connect with me.
      internal static let text = L10n.tr("Localizable", "send_invitation_no_email.text")
    }
    internal enum ServicesOptions {
      internal enum AllowServices {
        /// Open this conversation to services.
        internal static let subtitle = L10n.tr("Localizable", "services_options.allow_services.subtitle")
        /// Allow services
        internal static let title = L10n.tr("Localizable", "services_options.allow_services.title")
      }
      internal enum RemoveServices {
        /// Remove
        internal static let action = L10n.tr("Localizable", "services_options.remove_services.action")
        /// Current services will be removed from the conversation. New services will not be allowed.
        internal static let message = L10n.tr("Localizable", "services_options.remove_services.message")
      }
    }
    internal enum ShareExtension {
      internal enum Voiceover {
        /// All clients verified.
        internal static let conversationSecure = L10n.tr("Localizable", "share_extension.voiceover.conversation_secure")
        /// Not all clients verified.
        internal static let conversationSecureWithIgnored = L10n.tr("Localizable", "share_extension.voiceover.conversation_secure_with_ignored")
        /// Under legal hold.
        internal static let conversationUnderLegalHold = L10n.tr("Localizable", "share_extension.voiceover.conversation_under_legal_hold")
      }
    }
    internal enum Shortcut {
      internal enum MarkAllAsRead {
        /// Mark All as Read
        internal static let title = L10n.tr("Localizable", "shortcut.mark_all_as_read.title")
      }
    }
    internal enum Signin {
      /// Log In
      internal static let confirm = L10n.tr("Localizable", "signin.confirm")
      /// Forgot password?
      internal static let forgotPassword = L10n.tr("Localizable", "signin.forgot_password")
      internal enum CompanyIdp {
        internal enum Button {
          /// For Companies
          internal static let title = L10n.tr("Localizable", "signin.company_idp.button.title")
        }
      }
      internal enum Email {
        internal enum MissingPassword {
          /// Enter your email address and password to continue.
          internal static let subtitle = L10n.tr("Localizable", "signin.email.missing_password.subtitle")
        }
      }
      internal enum Phone {
        internal enum MissingPassword {
          /// Enter your phone number to continue.
          internal static let subtitle = L10n.tr("Localizable", "signin.phone.missing_password.subtitle")
        }
      }
      internal enum UseEmail {
        /// Login with Email
        internal static let label = L10n.tr("Localizable", "signin.use_email.label")
      }
      internal enum UseOnePassword {
        /// Double tap to fill your password with 1Password
        internal static let hint = L10n.tr("Localizable", "signin.use_one_password.hint")
        /// Log in with 1Password
        internal static let label = L10n.tr("Localizable", "signin.use_one_password.label")
      }
      internal enum UsePhone {
        /// Login with Phone
        internal static let label = L10n.tr("Localizable", "signin.use_phone.label")
      }
    }
    internal enum SigninLogout {
      /// Your session expired. You need to log in again to continue.
      internal static let subheadline = L10n.tr("Localizable", "signin_logout.subheadline")
      internal enum Email {
        /// Your session expired. Enter your email address and password to continue.
        internal static let subheadline = L10n.tr("Localizable", "signin_logout.email.subheadline")
      }
      internal enum Phone {
        /// Your session expired. Enter your phone number to continue.
        internal static let subheadline = L10n.tr("Localizable", "signin_logout.phone.subheadline")
      }
      internal enum Sso {
        /// Enterprise log in
        internal static let buton = L10n.tr("Localizable", "signin_logout.sso.buton")
        /// Your session expired. Log in with your enterprise account to continue.
        internal static let subheadline = L10n.tr("Localizable", "signin_logout.sso.subheadline")
      }
    }
    internal enum Sketchpad {
      /// Tap colors to change brush size
      internal static let initialHint = L10n.tr("Localizable", "sketchpad.initial_hint")
    }
    internal enum SystemStatusBar {
      internal enum NoInternet {
        /// There seems to be a problem with your Internet connection. Please make sure it’s working.
        internal static let explanation = L10n.tr("Localizable", "system_status_bar.no_internet.explanation")
        /// No Internet
        internal static let title = L10n.tr("Localizable", "system_status_bar.no_internet.title")
      }
      internal enum PoorConnectivity {
        /// We can’t guarantee voice quality. Connect to Wi-Fi or try changing your location.
        internal static let explanation = L10n.tr("Localizable", "system_status_bar.poor_connectivity.explanation")
        /// Slow Internet, can’t call now
        internal static let title = L10n.tr("Localizable", "system_status_bar.poor_connectivity.title")
      }
    }
    internal enum Team {
      internal enum ActivationCode {
        /// You’ve got mail
        internal static let headline = L10n.tr("Localizable", "team.activation_code.headline")
        /// Enter the verification code we sent to %@.
        internal static func subheadline(_ p1: Any) -> String {
          return L10n.tr("Localizable", "team.activation_code.subheadline", String(describing: p1))
        }
        internal enum Button {
          /// Change email
          internal static let changeEmail = L10n.tr("Localizable", "team.activation_code.button.change_email")
          /// Change phone number
          internal static let changePhone = L10n.tr("Localizable", "team.activation_code.button.change_phone")
          /// Resend code
          internal static let resend = L10n.tr("Localizable", "team.activation_code.button.resend")
        }
      }
      internal enum FullName {
        /// Your name
        internal static let headline = L10n.tr("Localizable", "team.full_name.headline")
        internal enum Textfield {
          /// Set full name
          internal static let accessibility = L10n.tr("Localizable", "team.full_name.textfield.accessibility")
          /// Full name
          internal static let placeholder = L10n.tr("Localizable", "team.full_name.textfield.placeholder")
        }
      }
      internal enum Invite {
        internal enum Error {
          /// No Internet Connection
          internal static let noInternet = L10n.tr("Localizable", "team.invite.error.no_internet")
        }
      }
      internal enum Password {
        /// Set password
        internal static let headline = L10n.tr("Localizable", "team.password.headline")
      }
      internal enum PhoneActivationCode {
        /// Verification
        internal static let headline = L10n.tr("Localizable", "team.phone_activation_code.headline")
      }
    }
    internal enum ToolTip {
      internal enum Contacts {
        /// Start a conversation. Call, message and share in private or with groups.
        internal static let message = L10n.tr("Localizable", "tool_tip.contacts.message")
        /// Conversations start here
        internal static let title = L10n.tr("Localizable", "tool_tip.contacts.title")
      }
    }
    internal enum TwitterStatus {
      /// %@ on Twitter
      internal static func onTwitter(_ p1: Any) -> String {
        return L10n.tr("Localizable", "twitter_status.on_twitter", String(describing: p1))
      }
    }
    internal enum Unlock {
      /// Wrong passcode
      internal static let errorLabel = L10n.tr("Localizable", "unlock.error_label")
      /// Enter passcode to unlock Wire
      internal static let titleLabel = L10n.tr("Localizable", "unlock.title_label")
      /// Access as new device
      internal static let wipeButton = L10n.tr("Localizable", "unlock.wipe_button")
      internal enum SubmitButton {
        /// unlock
        internal static let title = L10n.tr("Localizable", "unlock.submit_button.title")
      }
      internal enum Textfield {
        /// Enter your passcode
        internal static let placeholder = L10n.tr("Localizable", "unlock.textfield.placeholder")
      }
    }
    internal enum UrlAction {
      /// Confirm
      internal static let confirm = L10n.tr("Localizable", "url_action.confirm")
      /// Confirm URL action
      internal static let title = L10n.tr("Localizable", "url_action.title")
      internal enum AuthorizationRequired {
        /// You need to log in to view this content.
        internal static let message = L10n.tr("Localizable", "url_action.authorization_required.message")
        /// Authorization required.
        internal static let title = L10n.tr("Localizable", "url_action.authorization_required.title")
      }
      internal enum ConnectToBot {
        /// Would you like to connect to the bot?
        internal static let message = L10n.tr("Localizable", "url_action.connect_to_bot.message")
      }
      internal enum InvalidConversation {
        /// You may not have permission with this account or the person may not be on Wire.
        internal static let message = L10n.tr("Localizable", "url_action.invalid_conversation.message")
        /// Wire can't open this conversation.
        internal static let title = L10n.tr("Localizable", "url_action.invalid_conversation.title")
      }
      internal enum InvalidLink {
        /// The link you opened is not valid.
        internal static let message = L10n.tr("Localizable", "url_action.invalid_link.message")
        /// Invalid link.
        internal static let title = L10n.tr("Localizable", "url_action.invalid_link.title")
      }
      internal enum InvalidUser {
        /// You may not have permission with this account or it no longer exists.
        internal static let message = L10n.tr("Localizable", "url_action.invalid_user.message")
        /// Wire can't find this person.
        internal static let title = L10n.tr("Localizable", "url_action.invalid_user.title")
      }
      internal enum JoinConversation {
        internal enum Confirmation {
          /// Join
          internal static let confirmButton = L10n.tr("Localizable", "url_action.join_conversation.confirmation.confirm_button")
          /// You have been invited to a conversation:
          /// %@
          internal static func message(_ p1: Any) -> String {
            return L10n.tr("Localizable", "url_action.join_conversation.confirmation.message", String(describing: p1))
          }
        }
        internal enum Error {
          internal enum Alert {
            /// You could not join the conversation
            internal static let title = L10n.tr("Localizable", "url_action.join_conversation.error.alert.title")
            internal enum ConverationIsFull {
              /// The conversation is full.
              internal static let message = L10n.tr("Localizable", "url_action.join_conversation.error.alert.converation_is_full.message")
            }
            internal enum LearnMore {
              /// Learn more about guest links
              internal static let action = L10n.tr("Localizable", "url_action.join_conversation.error.alert.learn_more.action")
            }
            internal enum LinkIsInvalid {
              /// The conversation link is invalid.
              internal static let message = L10n.tr("Localizable", "url_action.join_conversation.error.alert.link_is_invalid.message")
            }
          }
        }
      }
      internal enum SwitchBackend {
        /// This configuration will connect the app to a third-party server:
        /// %@
        internal static func message(_ p1: Any) -> String {
          return L10n.tr("Localizable", "url_action.switch_backend.message", String(describing: p1))
        }
        /// Connect to server
        internal static let title = L10n.tr("Localizable", "url_action.switch_backend.title")
        internal enum Error {
          /// Please check your internet connection, verify the link and try again.
          internal static let invalidBackend = L10n.tr("Localizable", "url_action.switch_backend.error.invalid_backend")
          /// You are already logged in. To switch to this server, log out of all accounts and try again.
          internal static let loggedIn = L10n.tr("Localizable", "url_action.switch_backend.error.logged_in")
          internal enum InvalidBackend {
            /// The server is not responding
            internal static let title = L10n.tr("Localizable", "url_action.switch_backend.error.invalid_backend.title")
          }
          internal enum LoggedIn {
            /// Can’t switch servers
            internal static let title = L10n.tr("Localizable", "url_action.switch_backend.error.logged_in.title")
          }
        }
      }
    }
    internal enum UserCell {
      internal enum Title {
        ///  (You)
        internal static let youSuffix = L10n.tr("Localizable", "user_cell.title.you_suffix")
      }
    }
    internal enum Verification {
      /// Double tap to enter the code.
      internal static let codeHint = L10n.tr("Localizable", "verification.code_hint")
      /// Six-digit code. Text field.
      internal static let codeLabel = L10n.tr("Localizable", "verification.code_label")
    }
    internal enum VideoCall {
      internal enum CameraAccess {
        /// Wire doesn’t have access to the camera
        internal static let denied = L10n.tr("Localizable", "video_call.camera_access.denied")
      }
    }
    internal enum Voice {
      internal enum AcceptButton {
        /// Accept
        internal static let title = L10n.tr("Localizable", "voice.accept_button.title")
      }
      internal enum Alert {
        internal enum CallInProgress {
          /// OK
          internal static let confirm = L10n.tr("Localizable", "voice.alert.call_in_progress.confirm")
          /// You can have only one active call at a time
          internal static let message = L10n.tr("Localizable", "voice.alert.call_in_progress.message")
          /// Call in progress
          internal static let title = L10n.tr("Localizable", "voice.alert.call_in_progress.title")
        }
        internal enum CameraWarning {
          /// Wire needs access to the camera
          internal static let title = L10n.tr("Localizable", "voice.alert.camera_warning.title")
        }
        internal enum MicrophoneWarning {
          /// Wire needs access to the microphone
          internal static let title = L10n.tr("Localizable", "voice.alert.microphone_warning.title")
        }
      }
      internal enum CallButton {
        /// Call
        internal static let title = L10n.tr("Localizable", "voice.call_button.title")
      }
      internal enum CallError {
        internal enum UnsupportedVersion {
          /// Later
          internal static let dismiss = L10n.tr("Localizable", "voice.call_error.unsupported_version.dismiss")
          /// You received a call that isn't supported by this version of Wire.
          /// Get the latest version in the App Store.
          internal static let message = L10n.tr("Localizable", "voice.call_error.unsupported_version.message")
          /// Please update Wire
          internal static let title = L10n.tr("Localizable", "voice.call_error.unsupported_version.title")
        }
      }
      internal enum CancelButton {
        /// Cancel
        internal static let title = L10n.tr("Localizable", "voice.cancel_button.title")
      }
      internal enum DeclineButton {
        /// Decline
        internal static let title = L10n.tr("Localizable", "voice.decline_button.title")
      }
      internal enum Degradation {
        /// You started using a new device.
        internal static let newSelfDevice = L10n.tr("Localizable", "voice.degradation.new_self_device")
        /// %@ started using a new device.
        internal static func newUserDevice(_ p1: Any) -> String {
          return L10n.tr("Localizable", "voice.degradation.new_user_device", String(describing: p1))
        }
      }
      internal enum DegradationIncoming {
        /// Do you still want to accept the call?
        internal static let prompt = L10n.tr("Localizable", "voice.degradation_incoming.prompt")
      }
      internal enum DegradationOutgoing {
        /// Do you still want to place the call?
        internal static let prompt = L10n.tr("Localizable", "voice.degradation_outgoing.prompt")
      }
      internal enum EndCallButton {
        /// End Call
        internal static let title = L10n.tr("Localizable", "voice.end_call_button.title")
      }
      internal enum FlipVideoButton {
        /// Switch camera
        internal static let title = L10n.tr("Localizable", "voice.flip_video_button.title")
      }
      internal enum HangUpButton {
        /// Hang Up
        internal static let title = L10n.tr("Localizable", "voice.hang_up_button.title")
      }
      internal enum MuteButton {
        /// Microphone
        internal static let title = L10n.tr("Localizable", "voice.mute_button.title")
      }
      internal enum NetworkError {
        /// You must be online to call. Check your connection and try again.
        internal static let body = L10n.tr("Localizable", "voice.network_error.body")
        /// No Internet Connection
        internal static let title = L10n.tr("Localizable", "voice.network_error.title")
      }
      internal enum SpeakerButton {
        /// Speaker
        internal static let title = L10n.tr("Localizable", "voice.speaker_button.title")
      }
      internal enum Status {
        /// Constant Bit Rate
        internal static let cbr = L10n.tr("Localizable", "voice.status.cbr")
        /// %@
        /// Connecting
        internal static func joining(_ p1: Any) -> String {
          return L10n.tr("Localizable", "voice.status.joining", String(describing: p1))
        }
        /// %@
        /// Call ended
        internal static func leaving(_ p1: Any) -> String {
          return L10n.tr("Localizable", "voice.status.leaving", String(describing: p1))
        }
        /// Bad connection
        internal static let lowConnection = L10n.tr("Localizable", "voice.status.low_connection")
        /// Video turned off
        internal static let videoNotAvailable = L10n.tr("Localizable", "voice.status.video_not_available")
        internal enum GroupCall {
          /// %@
          /// ringing
          internal static func incoming(_ p1: Any) -> String {
            return L10n.tr("Localizable", "voice.status.group_call.incoming", String(describing: p1))
          }
        }
        internal enum OneToOne {
          /// %@
          /// calling
          internal static func incoming(_ p1: Any) -> String {
            return L10n.tr("Localizable", "voice.status.one_to_one.incoming", String(describing: p1))
          }
          /// %@
          /// ringing
          internal static func outgoing(_ p1: Any) -> String {
            return L10n.tr("Localizable", "voice.status.one_to_one.outgoing", String(describing: p1))
          }
        }
      }
      internal enum TopOverlay {
        /// Ongoing call
        internal static let accessibilityTitle = L10n.tr("Localizable", "voice.top_overlay.accessibility_title")
        /// Tap to return to call
        internal static let tapToReturn = L10n.tr("Localizable", "voice.top_overlay.tap_to_return")
      }
      internal enum VideoButton {
        /// Camera
        internal static let title = L10n.tr("Localizable", "voice.video_button.title")
      }
    }
    internal enum WarningScreen {
      /// There was a change in Wire
      internal static let titleLabel = L10n.tr("Localizable", "warning_screen.title_label")
      internal enum InfoLabel {
        /// Next time, unlock Wire the same way you unlock your phone.
        internal static let forcedApplock = L10n.tr("Localizable", "warning_screen.info_label.forced_applock")
        /// Your organization does not need app lock anymore. From now, you can access Wire without any obstacles.
        internal static let nonForcedApplock = L10n.tr("Localizable", "warning_screen.info_label.non_forced_applock")
      }
      internal enum MainInfo {
        /// Your organization needs to lock your app when Wire is not in use to keep the team safe.
        internal static let forcedApplock = L10n.tr("Localizable", "warning_screen.main_info.forced_applock")
      }
    }
    internal enum WipeDatabase {
      /// The data stored on this device can only be accessed with your passcode.
      /// 
      /// If you have forgotten your passcode, you can delete the database to log in again as a new device.
      /// 
      /// By deleting the database, 
      internal static let infoLabel = L10n.tr("Localizable", "wipe_database.info_label")
      /// Access as new device
      internal static let titleLabel = L10n.tr("Localizable", "wipe_database.title_label")
      internal enum Alert {
        /// Delete
        internal static let confirm = L10n.tr("Localizable", "wipe_database.alert.confirm")
        /// Delete
        internal static let confirmInput = L10n.tr("Localizable", "wipe_database.alert.confirm_input")
        /// Confirm database deletion
        internal static let description = L10n.tr("Localizable", "wipe_database.alert.description")
        /// Type 'Delete' to verify you want to delete all data in this device.
        internal static let message = L10n.tr("Localizable", "wipe_database.alert.message")
        /// Type 'Delete'
        internal static let placeholder = L10n.tr("Localizable", "wipe_database.alert.placeholder")
      }
      internal enum Button {
        /// I want to delete the database
        internal static let title = L10n.tr("Localizable", "wipe_database.button.title")
      }
      internal enum InfoLabel {
        /// all local data and messages for this account will be permanently deleted.
        internal static let highlighted = L10n.tr("Localizable", "wipe_database.info_label.highlighted")
      }
    }
    internal enum WipeDatabaseCompletion {
      /// Your data and messages have been deleted. You can now log in again as a new device.
      internal static let subtitle = L10n.tr("Localizable", "wipe_database_completion.subtitle")
      /// Database deleted
      internal static let title = L10n.tr("Localizable", "wipe_database_completion.title")
    }
  }
}
// swiftlint:enable explicit_type_interface function_parameter_count identifier_name line_length
// swiftlint:enable nesting type_body_length type_name vertical_whitespace_opening_braces

// MARK: - Implementation Details

extension L10n {
  private static func tr(_ table: String, _ key: String, _ args: CVarArg...) -> String {
    let format = BundleToken.bundle.localizedString(forKey: key, value: nil, table: table)
    return String(format: format, locale: Locale.current, arguments: args)
  }
}

// swiftlint:disable convenience_type
private final class BundleToken {
  static let bundle: Bundle = {
    #if SWIFT_PACKAGE
    return Bundle.module
    #else
    return Bundle(for: BundleToken.self)
    #endif
  }()
}
// swiftlint:enable convenience_type
