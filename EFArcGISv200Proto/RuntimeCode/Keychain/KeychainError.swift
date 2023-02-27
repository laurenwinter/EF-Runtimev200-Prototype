//
// COPYRIGHT 1995-2022 ESRI
//
// TRADE SECRETS: ESRI PROPRIETARY AND CONFIDENTIAL
// Unpublished material - all rights reserved under the
// Copyright Laws of the United States and applicable international
// laws, treaties, and conventions.
//
// For additional information, contact:
// Environmental Systems Research Institute, Inc.
// Attn: Contracts and Legal Services Department
// 380 New York Street
// Redlands, California, 92373
// USA
//
// email: contracts@esri.com
//

import Foundation

/// An error that can occur in a keychain operation.
struct KeychainError: RawRepresentable, Error, Hashable {
    /// The backing status code for this error.
    /// - Note: Status code numeric values can be found here:
    /// https://opensource.apple.com/source/Security/Security-55471/libsecurity_keychain/lib/SecBase.h.auto.html
    let rawValue: OSStatus
    
    /// Initializes a keychain error. This init will fail if the specified status is a success
    /// status value.
    /// - Parameter rawValue: An `OSStatus`, usually the return value of a keychain operation.
    init?(rawValue: OSStatus) {
        guard rawValue != errSecSuccess else { return nil }
        self.rawValue = rawValue
    }
}

extension KeychainError {
    /// Initializes a keychain error. This init will fail if the specified status is a success
    /// status value.
    /// - Parameter rawValue: An `OSStatus`, usually the return value of a keychain operation.
    init?(_ rawValue: OSStatus) {
        self.init(rawValue: rawValue)
    }
    
    // The message for this error.
    var message: String {
        (SecCopyErrorMessageString(rawValue, nil) as String?) ?? ""
    }
}

extension KeychainError {
    /// The item was not found in the keychain.
    static let itemNotFound = Self(errSecItemNotFound)!
    /// One or more arguments specified were invalid.
    static let invalidArgument = Self(errSecParam)!
    /// An entitlement is missing.
    static let missingEntitlement = Self(errSecMissingEntitlement)!
}
