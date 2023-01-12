//
//  EFMapSceneView.swift
//  EFArcGISv200Proto
//
//  Created by Lauren Winter on 12/21/22.
//

import SwiftUI
import ArcGIS
import ArcGISToolkit

var scene = ArcGIS.Scene(basemap: Basemap.init(style: .arcGISNewspaper))

struct EFMapSceneView: View {
    /// The portal that the user is signed in to.
    @State var portal: Portal?
    
    /// A Boolean value indicating whether the profile view should be presented.
    @State var showProfile = false
    
    /// A Boolean value indicating whether the content view should be presented.
    @State var showContentAndGroup = false
    
    /// A Boolean value indicating whether the basemap selector view should be presented.
    @State var showBasemapSelector = false
    
    /// The result of loading the scene.
    @State var sceneLoadResult: Result<Void, Error>?
    
    /// The persistent ArcGIS layer view model for all the User and Group content
    @ObservedObject var sceneContentViewModel : EFSceneContentViewModel
    
    init() {
        sceneContentViewModel = EFSceneContentViewModel()
    }
    
    init(portal: Portal, sceneLoadResult: Result<Void, Error>) {
        self.portal = portal
        self.sceneLoadResult = sceneLoadResult
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
                                            showBasemapSelector = true
                                        } label: {
                                            Image(systemName: "rectangle.grid.2x2")
                                                .resizable()
                                                .frame(width: 24.0, height: 24.0)
                                                .tint(Color.blue)
                                        }
                                    }
                                    ToolbarItem(placement: .navigationBarTrailing) {
                                        Button {
                                            showProfile = true
                                        } label: {
                                            Image(systemName: "person.crop.square")
                                                .resizable()
                                                .frame(width: 24.0, height: 24.0)
                                                .tint(Color.blue)
                                        }
                                    }
                                }
                                .overlay(alignment: .topTrailing) {
                                    if showBasemapSelector {
                                        EFBasemapGalleryView(sceneContentViewModel: sceneContentViewModel, showView: $showBasemapSelector)
                                            .padding()
                                    }
                                }
                                .sheet(isPresented: $showProfile) {
                                    ProfileView(portal: portal) {
                                        self.portal = nil
                                    }
                                }
                                .background(Color.black.opacity(0.9).gradient)
                            HStack {
                                Spacer()
                                VStack {
                                    if !showContentAndGroup {
                                        Button {
                                            showContentAndGroup.toggle()
                                        } label: {
                                            Image(systemName: "square.3.layers.3d")
                                                .resizable()
                                                .frame(width: 32.0, height: 32.0)
                                                .tint(Color.white)
                                        }
                                        .padding(.horizontal, 20) // Inset 20 from the right edge
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
            EFSignInView(portal: $portal)
        }
    }
}

struct EFMapSceneView_Preview: PreviewProvider {
    
    static var previews: some View {
            EFMapSceneView(portal: .arcGISOnline(connection: .anonymous), sceneLoadResult: .success(()))
    }
}
