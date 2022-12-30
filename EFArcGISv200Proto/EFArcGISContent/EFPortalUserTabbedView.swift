//
//  LRWPortalUserTabbedView.swift
//  AuthenticationExample
//
//  Created by Lauren Winter on 11/9/22.
//

import SwiftUI
import ArcGIS

/// A view that displays the profile of a user.
struct EFPortalUserTabbedView: View {
    
    /// The portal from which the featured content can be fetched.
    /// The portal that the user is signed in to.
    @State var portal: Portal
    
    @Binding var showContentAndGroup: Bool
    
    @State private var selection : Int = 0
    
    let viewTitles = ["My Content", "Group Content"]
    
    @ObservedObject var sceneContentViewModel : EFSceneContentViewModel
    
    var body: some View {
        VStack {
            NavigationStack {
                Spacer()
                Group {
                    TabView (selection: $selection) {
                        EFPortalFolderView(portal: portal, contentViewModel: sceneContentViewModel.userContentViewModel)
                            .tabItem {
                                Label(viewTitles[0], systemImage: "square.2.layers.3d.top.filled")
                            }.tag(0)
                        
                        EFUserContentView(portal: portal, contentViewModel: sceneContentViewModel.userContentViewModel)
                            .tabItem {
                                Label(viewTitles[1], systemImage: "square.3.layers.3d.top.filled")
                            }.tag(1)
                        
                    }
                    .onAppear() {
                        print("LRWPortalUserTabbedView appear")
                    }
                    .onDisappear() {
                        print("LRWPortalUserTabbedView disappear")
                    }
                }
                .navigationTitle(viewTitles[selection])
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Done") {
                            showContentAndGroup.toggle()
                        }
                    }
                }
            }
        }
        .frame(width: 350, alignment: .topTrailing)
        .padding()
        .background(Color.white.opacity(0.9))
        .cornerRadius(10)
        .shadow(radius: 10)
    }
}

struct EFPortalUserTabbedView_Preview: PreviewProvider {
    static var previews: some View {
        EFPortalUserTabbedView(portal: .arcGISOnline(connection: .anonymous), showContentAndGroup: .constant(false), sceneContentViewModel: EFSceneContentViewModel())
    }
}
