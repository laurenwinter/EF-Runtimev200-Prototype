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

/// A value representing a generic password item in the keychain.
struct KeychainItem {
    /// The unique identifier of the item.
    var identifier: String
    /// The service this item is associated with.
    var service: URL?
    /// The date this item was created.
    var created: Date?
    /// The date this item was last modified.
    var modified: Date?
    /// A label for this item.
    var label: String?
    /// The identifier of the group that the item is stored in.
    var groupIdentifier: String?
    /// A Boolean value indicating whether the item is synchronized with iCloud.
    var synchronizesWithiCloud: Bool
    /// The data value of this item.
    var value: Data
}
