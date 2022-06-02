// Copyright (C) 2015 Wire Swiss GmbH <support@wire.com>
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

#ifndef CRYPTOBOX_H
#define CRYPTOBOX_H

#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

// CBoxVec //////////////////////////////////////////////////////////////////

// A heap-allocated vector of bytes.
typedef struct CBoxVec CBoxVec;

// Get a pointer to the contents of a byte vector.
uint8_t * cbox_vec_data(CBoxVec const * v);

// Get the length of a byte vector.
size_t cbox_vec_len(CBoxVec const * v);

// Deallocate a byte vector.
void cbox_vec_free(CBoxVec * v);

// CBoxResult ///////////////////////////////////////////////////////////////

// The result of an operation that might fail.
typedef enum {
    CBOX_SUCCESS                 = 0,

    // An internal storage error occurred.
    CBOX_STORAGE_ERROR           = 1,

    // A CBoxSession was not found.
    CBOX_SESSION_NOT_FOUND       = 2,

    // An error occurred during binary decoding of a data structure.
    CBOX_DECODE_ERROR            = 3,

    // The (prekey-)message being decrypted contains a different
    // remote identity than previously received.
    CBOX_REMOTE_IDENTITY_CHANGED = 4,

    // The (prekey-)message being decrypted has an invalid signature.
    // This might indicate that the message has been tampered with.
    CBOX_INVALID_SIGNATURE       = 5,

    // The (prekey-)message being decrypted is invalid given the
    // current state of the CBoxSession.
    CBOX_INVALID_MESSAGE         = 6,

    // The (prekey-)message being decrypted is a duplicate and can
    // be safely discarded.
    CBOX_DUPLICATE_MESSAGE       = 7,

    // The (prekey-)message being decrypted is out of bounds for the
    // supported range of skipped / delayed messages.
    CBOX_TOO_DISTANT_FUTURE      = 8,

    // The (prekey-)message being decrypted is out of bounds for the
    // supported range of skipped / delayed messages.
    CBOX_OUTDATED_MESSAGE        = 9,

    // A string argument is not utf8-encoded.
    // This is typically a programmer error.
    CBOX_UTF8_ERROR              = 10,

    // A string argument is missing a NUL terminator.
    // This is typically a programmer error.
    CBOX_NUL_ERROR               = 11,

    // An error occurred during binary encoding of a data structure.
    CBOX_ENCODE_ERROR            = 12,

    // A CBox has been opened with an incomplete or mismatching identity.
    // This is typically a programmer error.
    CBOX_IDENTITY_ERROR          = 13,

    // An attempt was made to initialise a new session with a prekey ID
    // for which no prekey could be found.
    CBOX_PREKEY_NOT_FOUND        = 14,

    // An unknown critical error was encountered which prevented the
    // computation from succeeding.
    //
    // Nb. If a `CBOX_PANIC` has been returned from an API operation,
    // any further use of the `CBox` or any `CBoxSession` results in
    // undefined behaviour!
    CBOX_PANIC                   = 15,

    // Failure to initialise proteus/libsodium. Client code should not
    // proceed after encountering this error (which can only happen
    // when opening a cbox).
    CBOX_INIT_ERROR              = 16,

    // Unsafe key material was used.
    CBOX_DEGENERATED_KEY         = 17

} CBoxResult;

// CBoxIdentityMode /////////////////////////////////////////////////////////

// The local storage mode for an external identity in `cbox_file_open_with`.
typedef enum {
    // The full identity is stored locally inside the CBox.
    CBOX_IDENTITY_COMPLETE = 0,

    // Only the public identity is stored locally inside the CBox.
    CBOX_IDENTITY_PUBLIC   = 1
} CBoxIdentityMode;

// CBox /////////////////////////////////////////////////////////////////////

// A container of sessions and prekeys of a single peer with a long-lived
// identity which is either internally or externally managed.
typedef struct CBox CBox;

// Open a CBox in an existing directory with an internally managed identity.
//
// The given directory is the root directory for the CBox in which
// sessions, prekeys, the long-term identity as well auxiliary data may
// be stored. If the directory is empty, it is initialised with a new
// long-term identity.
// ---
// `path` is the path to an existing directory.
// `b` is the pointer to point at the opened CBox.
CBoxResult cbox_file_open(char const * path, CBox ** b);

// Open a CBox using an existing external identity.
//
// The given directory is the root directory for the CBox in which
// sessions, prekeys, the long-term identity as well auxiliary data may
// be stored. If the directory is empty, it is initialised with the given
// long-term identity.
// ---
// `path` is a path to an existing directory.
// `ident` is the external identity to use.  An existing CBox with only
//         a public local identity must always be opened with an external
//         identity.
// `ident_len` is the length of `ident`.
// `mode` specifies the desired storage of the given identity inside the box.
CBoxResult cbox_file_open_with(char const * path,
                               uint8_t const * ident,
                               size_t ident_len,
                               CBoxIdentityMode mode,
                               CBox ** b);

// Copies the serialised long-term identity from the given cryptobox.
//
// The allocated CBoxVec contains the complete long-term identity of the given
// CBox and thus sensitive private key material. It should be stored in a safe
// location and / or transmitted over a secure channel before being disposed
// in a timely manner.
// ---
// `b` is the CBox from which to copy the identity.
// `ident` is the pointer to point at the serialised identity.
CBoxResult cbox_identity_copy(CBox const * b, CBoxVec ** ident);

// Close a CBox, freeing the memory associated with it.
//
// A CBox should only be closed after all sessions acquired through it have
// been closed. Any remaining open sessions that were obtained from the box
// can no longer be used with the exception of being closed via `cbox_session_close`.
void cbox_close(CBox * b);

// Prekeys //////////////////////////////////////////////////////////////////

// The ID of the "last resort" prekey, which is never removed.
extern const uint16_t CBOX_LAST_PREKEY_ID;

// Generate a new prekey, returning the public prekey material for usage by a
// peer to initialise a session.
//
// If a prekey with the same ID already exists, it is replaced.
// ---
// `b` is the CBox in which to create the new prekey.
// `prekey` is the pointer to point at the public key material of the new
//          prekey for usage by a peer.
CBoxResult cbox_new_prekey(CBox const * b, uint16_t id, CBoxVec ** prekey);

// CBoxSession //////////////////////////////////////////////////////////////

// A cryptographic session with a peer.
typedef struct CBoxSession CBoxSession;

// Initialise a session from a public prekey of a peer.
//
// This is the entry point for the sender of a message, if no session exists.
// ---
// `b` is the box in which the session is created. The session will be bound
//     to the lifetime of the box and can only be used until either the
//     session or the box is closed.
// `sid` is a unique ID to use for the new session.
// `peer_prekey` is the public prekey of the peer.
// `peer_prekey_len` is the length (in bytes) of the `peer_prekey`.
// `s` is the pointer to point at the successfully initialised session.
CBoxResult cbox_session_init_from_prekey(CBox const * b,
                                         char const * sid,
                                         uint8_t const * peer_prekey,
                                         size_t peer_prekey_len,
                                         CBoxSession ** s);

// Initialise a session from a ciphertext message.
//
// This is the entry point for the recipient of a message, if no session exists.
// ---
// `b` is the box in which the session is created. The session will be bound
//     to the lifetime of the box and can only be used until either the
//     session or the box is closed.
// `sid` is a unique ID to use for the new session.
// `cipher` is the received ciphertext message.
// `cipher_len` is the length (in bytes) of `cipher`.
// `s` is the pointer to point at the successfully initialised session.
// `plain` is the pointer to point at the successfully decrypted message.
CBoxResult cbox_session_init_from_message(CBox const * b,
                                          char const * sid,
                                          uint8_t const * cipher,
                                          size_t cipher_len,
                                          CBoxSession ** s,
                                          CBoxVec ** plain);

// Lookup a session by ID.
//
// If the session is not found, `CBOX_SESSION_NOT_FOUND` is returned and `s` will
// be unchanged.
// ---
// `b` is the box in which to look for the session. The session will be bound
//     to the lifetime of the box and can only be used until either the
//     session or the box is closed.
// `sid` is the session ID to look for.
// `s` is the pointer to point at the session, if it is found.
CBoxResult cbox_session_load(CBox const * b, char const * sid, CBoxSession ** s);

// Save a session.
//
// Saving a session makes any changes to the key material as a result of
// `cbox_encrypt` and `cbox_decrypt` permanent. Newly initialised sessions
// as a result of `cbox_session_init_from_message` and `cbox_session_init_from_prekey`
// are also only persisted (and prekeys ultimately removed) when saved, to
// facilitate retries in case of intermittent failure.
//
// A session should always be saved before sending newly obtained ciphertext to
// a peer, as well as after decrypting one or more received messages.
// ---
// `s` is the session to save.
CBoxResult cbox_session_save(CBox const * b, CBoxSession * s);

// Close a session, freeing the memory associated with it.
//
// After a session has been closed, it must no longer be used.
void cbox_session_close(CBoxSession * s);

// Delete an existing session.
//
// If the session does not exist, this function does nothing.
CBoxResult cbox_session_delete(CBox const * b, char const * sid);

// Encrypt a plaintext message.
// ---
// `s` is the session to use for encryption.
// `plain` is the plaintext to encrypt.
// `plain_len` is the length of `plain`.
// `cipher` is the pointer to point at the resulting ciphertext.
CBoxResult cbox_encrypt(CBoxSession * s,
                        uint8_t const * plain,
                        size_t plain_len,
                        CBoxVec ** cipher);

// Decrypt a ciphertext nessage.
// ---
// `s` is the session to use for decryption.
// `cipher` is the ciphertext to decrypt.
// `cipher_len` is the length of `cipher`.
// `plain` is the pointer to point at the resulting plaintext.
CBoxResult cbox_decrypt(CBoxSession * s,
                        uint8_t const * cipher,
                        size_t cipher_len,
                        CBoxVec ** plain);

// Get the public key fingerprint of the local identity.
//
// The fingerprint is represented as a hex-encoded byte sequence.
// ---
// `b` is the box from which to obtain the fingerprint.
// `fp` is the pointer to point at the fingerprint.
CBoxResult cbox_fingerprint_local(CBox const * b, CBoxVec ** fp);

// Get the public key fingerprint of the remote identity associated with
// the given session.
//
// The fingerprint is represented as a hex-encoded byte sequence.
// ---
// `s` is the session from which to obtain the fingerprint of the remote peer.
// `fp` is the pointer to point at the fingerprint.
CBoxResult cbox_fingerprint_remote(CBoxSession const * s, CBoxVec ** fp);

// Utilities ////////////////////////////////////////////////////////////////

// Get the public key fingerprint from a prekey
//
// The fingerprint is represented as a hex-encoded byte sequence.
// ---
// `prekey` is the byte array to extract the fingerprint from.
// `prekey_len` is the length of `prekey`.
// `fp` is the pointer to point at the fingerprint.
CBoxResult cbox_fingerprint_prekey(uint8_t const * prekey, size_t prekey_len, CBoxVec ** fp);

// Generate `len` cryptographically strong random bytes.
//
// Returns a pointer to the allocated random bytes.
// ---
// `b` is the CBox that serves as the initialised context for obtaining
// randomness.
// `len` is the number of random bytes to generate.
CBoxResult cbox_random_bytes(CBox const * b, size_t len, CBoxVec ** rb);

// Check if the given byte array is a well-formed prekey.
//
// `prekey` is the byte array to check.
// `prekey_len` is the length of `prekey`.
// `prekey_id` will contain the prekey ID if possible.
CBoxResult cbox_is_prekey(uint8_t const * prekey, size_t prekey_len, uint16_t * prekey_id);

#ifdef __cplusplus
}
#endif

#endif // CRYPTOBOX_H
