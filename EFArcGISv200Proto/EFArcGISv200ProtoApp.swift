//
//  EFArcGISv200ProtoApp.swift
//  EFArcGISv200Proto
//
//  Created by Lauren Winter on 12/21/22.
//

import SwiftUI
import ArcGISToolkit
import ArcGIS

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
        ArcGISEnvironment.authenticationManager.authenticationChallengeHandler = authenticator
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
                // Here we make the authenticator persistent, which means that it will synchronize
                // with they keychain for storing credentials.
                // It also means that a user can sign in without having to be prompted for
                // credentials. Once credentials are cleared from the stores ("sign-out"),
                // then the user will need to be prompted once again.
                try? await authenticator.setupPersistentCredentialStorage(access: .whenUnlockedThisDeviceOnly)
                isSettingUp = false
            }
        }
    }
}

extension URL {
    // If you want to use your own portal, provide your own URL here:
    static let portal = URL(string: "https://www.arcgis.com")!
}
