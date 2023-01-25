//
//  EFMapSceneView.swift
//  EFArcGISv200Proto
//
//  Created by Lauren Winter on 12/21/22.
//

import SwiftUI
import ArcGIS
import Combine

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
    
    /// A Boolean value to toggle the camera controller type
    @State var toggleCameraController = true
    
    /// A Boolean value to toggle the scene 2D or 3D state
    @State var scene2D3DState = true
    
    /// The result of loading the scene.
    @State var sceneLoadResult: Result<Void, Error>?
                
    /// The persistent ArcGIS layer view model for all the User and Group content
    @ObservedObject var sceneContentViewModel : EFSceneContentViewModel
    
    init() {
        self.sceneContentViewModel = EFSceneContentViewModel()
    }
    
    init(portal: Portal, sceneLoadResult: Result<Void, Error>) {
        self.portal = portal
        self.sceneLoadResult = sceneLoadResult
        self.sceneContentViewModel = EFSceneContentViewModel()
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
                                    ToolbarItemGroup {
                                        Button {
                                            scene2D3DState.toggle()
                                        } label: {
                                            Image(systemName: self.scene2D3DState ? "view.3d" : "view.2d")
                                                .tint(Color.white)
                                        }
                                        .frame(width: 36.0, height: 36.0)
                                        .background(Color.blue)
                                        .clipShape(Circle())
                                        
                                        Button {
                                            toggleCameraController.toggle()
                                        } label: {
                                            Image(systemName: self.toggleCameraController ? "arrow.clockwise.circle" : "arrow.up.and.down.and.arrow.left.and.right")
                                                .tint(Color.white)
                                                .rotationEffect(Angle.degrees(90))
                                        }
                                        .frame(width: 36.0, height: 36.0)
                                        .background(Color.blue)
                                        .clipShape(Circle())
                                        
                                        Button {
                                            showBasemapSelector = true
                                            showProfile = false
                                            showContentAndGroup = false
                                        } label: {
                                            Image(systemName: "rectangle.grid.2x2")
                                                .tint(Color.white)
                                        }
                                        .frame(width: 36.0, height: 36.0)
                                        .background(Color.blue)
                                        .clipShape(Circle())
                                        
                                        Button {
                                            showProfile = true
                                            showBasemapSelector = false
                                            showContentAndGroup = false
                                        } label: {
                                            Image(systemName: "person.crop.circle")
                                                .tint(Color.white)
                                        }
                                        .frame(width: 36.0, height: 36.0)
                                        .background(Color.blue)
                                        .clipShape(Circle())
                                    }
                                }
                                .overlay(alignment: .topTrailing) {
                                    if showBasemapSelector {
                                        EFBasemapGalleryView(baseMapDataModel: sceneContentViewModel.baseMapDataModel, showView: $showBasemapSelector)
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
                                            if showContentAndGroup {
                                                showProfile = false
                                                showBasemapSelector = false
                                            }
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
            .navigationViewStyle(.stack)
            .task {
                guard sceneLoadResult == nil else { return }
                sceneLoadResult = await Result { try await sceneContentViewModel.scene.load() }
            }
            .onChange(of: toggleCameraController) { value in
                sceneContentViewModel.toggleCameraController(value)
            }
            .onChange(of: scene2D3DState) { value in
                sceneContentViewModel.toggleScene2D3D(value)
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
