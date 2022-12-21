//
//  ESMapSceneView.swift
//  EFArcGISv200Proto
//
//  Created by Lauren Winter on 12/21/22.
//

import SwiftUI
import ArcGIS
import ArcGISToolkit

var scene = ArcGIS.Scene(basemap: Basemap.init(style: .arcGISNewspaper))

struct ESMapSceneView: View {
    /// The portal that the user is signed in to.
    @State var portal: Portal?
    
    /// A Boolean value indicating whether the profile view should be presented.
    @State var showProfile = false
    
    var body: some View {
        if let portal = portal {
            VStack {
                let sceneView = ArcGIS.SceneView(scene: scene)
                sceneView
                    .edgesIgnoringSafeArea(.top)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                Image(systemName: "globe")
                    .imageScale(.large)
                    .foregroundColor(.accentColor)
                Text("Hello, world!")
            }
            .padding()
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showProfile = true
                    } label: {
                        Image(systemName: "person.circle")
                    }
                }
            }
            .sheet(isPresented: $showProfile) {
                ProfileView(portal: portal) {
                    self.portal = nil
                }
            }
        } else {
            SignInView(portal: $portal)
        }
    }
}

//struct ContentView_Previews: PreviewProvider {
//    static var previews: some View {
//        ESMapSceneView()
//    }
//}
