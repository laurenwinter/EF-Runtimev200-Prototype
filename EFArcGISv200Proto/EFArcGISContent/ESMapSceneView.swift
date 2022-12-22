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
    
    /// A Boolean value indicating whether the content view should be presented.
    @State var showContentAndGroup = false
    
    /// The result of loading the scene.
    @State var sceneLoadResult: Result<Void, Error>?
    
    @ObservedObject var sceneContentViewModel : EFSceneContentViewModel
    
    init() {
        sceneContentViewModel = EFSceneContentViewModel()
    }
    
    var body: some View {
        if let portal = portal {
            NavigationView {
                    switch sceneLoadResult {
                    case .none:
                        ProgressView()
                    case .success:
                        ZStack {
                            sceneContentViewModel.sceneView
                                .edgesIgnoringSafeArea(.top)
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                .toolbar {
                                    ToolbarItem(placement: .navigationBarTrailing) {
                                        Button {
                                            showProfile = true
                                        } label: {
                                            Image(systemName: "person.circle")
                                                .resizable()
                                                .frame(width: 16.0, height: 16.0)
                                                .tint(Color.white)
                                        }
                                    }
                                }
                                .sheet(isPresented: $showProfile) {
                                    ProfileView(portal: portal) {
                                        self.portal = nil
                                    }
                                }
                            HStack(alignment: .top) {
                                Spacer()
                                VStack() {
                                    if !showContentAndGroup {
                                        Button {
                                            showContentAndGroup.toggle()
                                        } label: {
                                            Image(systemName: "map.circle")
                                                .resizable()
                                                .frame(width: 32.0, height: 32.0)
                                                .tint(Color.white)
                                        }
                                        .padding()
                                        .background(Color.blue)
                                        .clipShape(Circle())
                                    } else {
                                        EFPortalUserTabbedView(portal: portal, showContentAndGroup: $showContentAndGroup, sceneContentViewModel: sceneContentViewModel)
                                    }
                                }
                            }
                        }
                    case .failure(let error):
                        Text(error.localizedDescription)
                            .font(.footnote)
                            .foregroundColor(.secondary)
                    }
                }
        
            .onChange(of: sceneContentViewModel.scene, perform: { _ in
                print("Scene was changed 2")
                Task {
                    sceneLoadResult = await Result { try await sceneContentViewModel.scene.load() }
                    switch sceneLoadResult {
                    case .failure(_):
                            print("Error loading the scene")
                        default:
                        ()
                    }
                }
            })
            .navigationViewStyle(.stack)
            .task {
                guard sceneLoadResult == nil else { return }
                sceneLoadResult = await Result { try await sceneContentViewModel.scene.load() }
            }
        } else {
            SignInView(portal: $portal)
        }
        
            /*
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
        }*/
    }
}

//struct ContentView_Previews: PreviewProvider {
//    static var previews: some View {
//        ESMapSceneView()
//    }
//}
