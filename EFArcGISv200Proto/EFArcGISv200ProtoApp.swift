//
//  EFArcGISv200ProtoApp.swift
//  EFArcGISv200Proto
//
//  Created by Lauren Winter on 12/21/22.
//

import SwiftUI
import ArcGISToolkit
import ArcGIS

//
// Note: This code is copied from the ArcGISToolkit AuthenticationExample app
//

@main
struct EFArcGISv200ProtoApp: App {
    @ObservedObject var authenticator: Authenticator
    @State var isSettingUp = true
    
    init() {
        // Create an authenticator.
        authenticator = Authenticator(
            // If you want to use OAuth, uncomment this code:
            //oAuthUserConfigurations: [.arcgisDotCom]
        )
        // Set the challenge handler to be the authenticator we just created.
        ArcGISEnvironment.authenticationManager.arcGISAuthenticationChallengeHandler = authenticator
    }

    var body: some SwiftUI.Scene {
        WindowGroup {
            Group {
                if isSettingUp {
                    ProgressView()
                } else {
                    EFMapSceneView()
                }
            }
            
            // Using this view modifier will cause a prompt when the authenticator is asked
            // to handle an authentication challenge.
            // This will handle many different types of authentication, for example:
            // - ArcGIS authentication (token and OAuth)
            // - Integrated Windows Authentication (IWA)
            // - Client Certificate (PKI)
            .authenticator(authenticator)
            .environmentObject(authenticator)
            .task {
                isSettingUp = true
                // Runtime fix for v200.1 update.
                // Used only once to clear out the old cache
//                do {
//                    try await Keychain.shared.removeItems(labeled: "ArcGISCredential")
//                } catch {
//                    print("keychain error")
//                }

                // Here we make the authenticator persistent, which means that it will synchronize
                // with they keychain for storing credentials.
                // It also means that a user can sign in without having to be prompted for
                // credentials. Once credentials are cleared from the stores ("sign-out"),
                // then the user will need to be prompted once again.
                try? await setupPersistentCredentialStorage(access: .whenUnlockedThisDeviceOnly)
                isSettingUp = false
            }
        }
    }
}

/*
 This func is copied from the Runtime Authenticator.swift file, it has updates for v200.1.x
 */
/// Sets up new credential stores that will be persisted to the keychain.
/// - Remark: The credentials will be stored in the default access group of the keychain.
/// You can find more information about what the default group would be here:
/// https://developer.apple.com/documentation/security/keychain_services/keychain_items/sharing_access_to_keychain_items_among_a_collection_of_apps
/// - Parameters:
///   - access: When the credentials stored in the keychain can be accessed.
///   - synchronizesWithiCloud: A Boolean value indicating whether the credentials are synchronized with iCloud.
private func setupPersistentCredentialStorage(access: ArcGIS.KeychainAccess, synchronizesWithiCloud: Bool = false) async throws {
    let previousArcGISCredentialStore = ArcGISEnvironment.authenticationManager.arcGISCredentialStore
    
    do {
            ArcGISEnvironment.authenticationManager.arcGISCredentialStore = try await .makePersistent(access: .afterFirstUnlockThisDeviceOnly)
            await ArcGISEnvironment.authenticationManager.setNetworkCredentialStore(try .makePersistent(access: .afterFirstUnlockThisDeviceOnly))
        } catch {
            //Logger.log("Failed to set up persistent credential store: \(error)", category: .authentication)
            ArcGISEnvironment.authenticationManager.arcGISCredentialStore = previousArcGISCredentialStore
            throw error
        }
}

// If you want to use OAuth, you can uncomment this code:
//private extension OAuthUserConfiguration {
//    static let arcgisDotCom = OAuthUserConfiguration(
//        portalURL: .portal,
//        clientID: "SUWt4Y5H6lp92TZ7",
//        // Note: You must have the same redirect URL used here
//        // registered with your client ID.
//        // The scheme of the redirect URL is also specified in the Info.plist file.
//        redirectURL: URL(string: "authexample://auth")!
//    )
//}

extension URL {
    // If you want to use your own portal, provide your own URL here:
    static let portal = URL(string: "https://www.arcgis.com")!
}
