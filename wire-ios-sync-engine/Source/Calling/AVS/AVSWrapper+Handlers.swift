//
// Wire
// Copyright (C) 2018 Wire Swiss GmbH
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
import avs

extension AVSWrapper {

    enum Handler {

        typealias StringPtr = UnsafePointer<Int8>?
        typealias VoidPtr = UnsafeMutableRawPointer?
        typealias ContextRef = VoidPtr

        /// Callback used to inform user that call uses CBR (in both directions).
        ///
        /// typedef void (wcall_audio_cbr_change_h)(const char *userid,
        ///                                         const char *clientid,
        ///                                         int enabled,
        ///                                         void *arg);

        typealias ConstantBitRateChange = @convention(c) (StringPtr, StringPtr, Int32, ContextRef) -> Void

        /// Callback used to inform user that received video has started or stopped.
        ///
        /// typedef void (wcall_video_state_change_h)(const char *convid,
        ///                                           const char *userid,
        ///                                           const char *clientid,
        ///                                           int state,
        ///                                           void *arg);

        typealias VideoStateChange = @convention(c) (StringPtr, StringPtr, StringPtr, Int32, ContextRef) -> Void

        /// Callback used to inform the user of an incoming call.
        ///
        /// typedef void (wcall_incoming_h)(const char *convid,
        ///                                 uint32_t msg_time,
        ///                                 const char *userid,
        ///                                 const char *clientid,
        ///                                 int video_call /*bool*/,
        ///                                 int should_ring /*bool*/,
        ///                                 int conv_type /*WCALL_CONV_TYPE...*/,
        ///                                 void *arg);

        typealias IncomingCall = @convention(c) (StringPtr, UInt32, StringPtr, StringPtr, Int32, Int32, Int32, ContextRef) -> Void

        /// Callback used to inform the user of a missed call.
        ///
        /// typedef void (wcall_missed_h)(const char *convid,
        ///                               uint32_t msg_time,
        ///                               const char *userid,
        ///                               const char *clientid,
        ///                               int video_call /*bool*/,
        ///                               void *arg);

        typealias MissedCall = @convention(c) (StringPtr, UInt32, StringPtr, StringPtr, Int32, ContextRef) -> Void

        /// Callback used to inform user that a 1:1 call was answered.
        ///
        /// typedef void (wcall_answered_h)(const char *convid, void *arg);

        typealias AnsweredCall = @convention(c) (StringPtr, ContextRef) -> Void

        /// Callback used to inform the user that a data channel was established.
        ///
        /// typedef void (wcall_data_chan_estab_h)(const char *convid,
        ///                                        const char *userid,
        ///                                        const char *clientid,
        ///                                        void *arg);

        typealias DataChannelEstablished = @convention(c) (StringPtr, StringPtr, StringPtr, ContextRef) -> Void

        /// Callback used to inform the user that a call was established (with media).
        ///
        /// typedef void (wcall_estab_h)(const char *convid,
        ///                              const char *userid,
        ///                              const char *clientid,
        ///                              void *arg);

        typealias CallEstablished = @convention(c) (StringPtr, StringPtr, StringPtr, ContextRef) -> Void

        /// Callback used to inform the user that a call was terminated.
        ///
        /// typedef void (wcall_close_h)(int reason,
        ///                              const char *convid,
        ///                              uint32_t msg_time,
        ///                              const char *userid,
        ///                              const char *clientid,
        ///                              void *arg);

        typealias CloseCall = @convention(c) (Int32, StringPtr, UInt32, StringPtr, StringPtr, ContextRef) -> Void

        /// Callback used to inform the user of call metrics.
        ///
        /// typedef void (wcall_metrics_h)(const char *convid,
        ///                                const char *metrics_json,
        ///                                void *arg);

        typealias CallMetrics = @convention(c) (StringPtr, StringPtr, ContextRef) -> Void

        /// Callback used to request a refresh of the call config.
        ///
        /// typedef int (wcall_config_req_h)(WUSER_HANDLE wuser, void *arg);

        typealias CallConfigRefresh = @convention(c) (UInt32, ContextRef) -> Int32

        /// Callback used when the calling system is ready for calling. The version parameter specifies the call config
        /// version to use.
        ///
        /// typedef void (wcall_ready_h)(int version, void *arg);

        typealias CallReady = @convention(c) (Int32, ContextRef) -> Void

        /// Callback used to send an OTR call message.
        ///
        /// The `targets` argument contains a json payload listing the clients for which the message is targeted.
        /// They payload has the following structure:
        ///
        /// ```
        /// {
        ///     "clients": [
        ///         {"userid": "xxxx", "clientid" "xxxx"},
        ///         {"userid": "xxxx", "clientid" "xxxx"},
        ///         ...
        ///     ]
        /// }
        /// ```
        ///
        /// typedef int (wcall_send_h)(void *ctx,
        ///                            const char *convid,
        ///                            const char *userid_self,
        ///                            const char *clientid_self,
        ///                            const char *targets /*optional*/,
        ///                            const char *clientid_dest /*deprecated - always null*/,
        ///                            const uint8_t *data,
        ///                            size_t len,
        ///                            int transient /*bool*/,
        ///                            void *arg);

        typealias CallMessageSend = @convention(c) (VoidPtr, StringPtr, StringPtr, StringPtr, StringPtr, StringPtr, UnsafePointer<UInt8>?, Int, Int32, ContextRef) -> Int32

        /// Callback used to inform the user when the list of participants in a call changes.
        ///
        /// typedef void (wcall_participant_changed_h)(const char *convid,
        ///                                            const char *mjson,
        ///                                            void *arg);

        typealias CallParticipantChange = @convention(c) (StringPtr, StringPtr, ContextRef) -> Void

        /// Callback used to inform the user that all media has stopped.
        ///
        /// typedef void (wcall_media_stopped_h)(const char *convid, void *arg);

        typealias MediaStoppedChange = @convention(c) (StringPtr, ContextRef) -> Void

        /// Callback used to inform the user of a change in network quality for a participant.
        ///
        /// typedef void (wcall_network_quality_h)(const char *convid,
        ///                                        const char *userid,
        ///                                        const char *clientid,
        ///                                        int quality, /*  WCALL_QUALITY_ */
        ///                                        int rtt, /* round trip time in ms */
        ///                                        int uploss, /* upstream pkt loss % */
        ///                                        int downloss, /* dnstream pkt loss % */
        ///                                        void *arg);

        typealias NetworkQualityChange = @convention(c) (StringPtr, StringPtr, StringPtr, Int32, Int32, Int32, Int32, ContextRef) -> Void

        /// Callback used to inform the user when the mute state changes.
        ///
        /// typedef void (wcall_mute_h)(int muted, void *arg);

        typealias MuteChange = @convention(c) (Int32, ContextRef) -> Void

        /// Callback used to request a the list of clients in a conversation.
        ///
        /// typedef void (wcall_req_clients_h)(WUSER_HANDLE wuser, const char *convid, void *arg);

        typealias RequestClients = @convention(c) (UInt32, StringPtr, ContextRef) -> Void

        /// Callback used to request SFT communication.
        ///
        /// typedef int (wcall_sft_req_h)(void *ctx, const char *url, const uint8_t *data, size_t len, void *arg);

        typealias SFTCallMessageSend = @convention(c) (VoidPtr, StringPtr, UnsafePointer<UInt8>?, Int, ContextRef) -> Int32

        /// Callback used to inform the user of a change in the list of active speakers
        ///
        /// typedef void (wcall_active_speaker_h)(WUSER_HANDLE wuser, const char *convid, const char *json_levels, void *arg);

        typealias ActiveSpeakersChange = @convention(c) (UInt32, StringPtr, StringPtr, ContextRef) -> Void
    }
}
