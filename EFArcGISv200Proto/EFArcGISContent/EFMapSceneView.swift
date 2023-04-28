//
//  EFMapSceneView.swift
//  EFArcGISv200Proto
//
//  Created by Lauren Winter on 12/21/22.
//

import SwiftUI
import Combine
import ArcGIS
import ArcGISToolkit

struct EFMapSceneView: View {
    /// The portal that the user is signed in to.
    @State var portal: Portal?
    
    /// A Boolean value indicating whether the profile view should be presented.
    @State var showProfile = false
    
    /// A Boolean value indicating whether the content and group layer view should be presented.
    @State var showEFPortalUserTabbedView = false
    
    /// A Boolean value indicating whether the basemap selector view should be presented.
    @State var showBasemapSelector = false
    
    /// A Boolean value to toggle the camera controller type
    @State var toggleCameraController = false
    
    /// A Boolean value to toggle the scene 2D or 3D state
    @State var toggleScene2D3DState = true
    
    /// The result of loading the scene.
    @State var sceneLoadResult: Result<Void, Error>?
                
    /// The persistent ArcGIS layer view model for all the User and Group content
    @StateObject var sceneContentViewModel : EFSceneContentViewModel = EFSceneContentViewModel()
    
    /// The point on the screen the user tapped on to identify a feature.
    @State private var identifyScreenPoint: CGPoint?
            
    init() {
        // The default app initializer
    }
    
    init(portal: Portal, sceneLoadResult: Result<Void, Error>) {
        // Initializer for the Preview
        self.portal = portal
        self.sceneLoadResult = sceneLoadResult
    }
    
    var body: some View {
        if let portal = portal {
            NavigationView {
                    switch sceneLoadResult {
                    case .none:
                        ProgressView()
                    case .success:
                        ZStack {
                            // SceneViewReader is needed to get proxy that used for identifying graphics (or layers) and to setViewPoint
                            SceneViewReader { sceneProxy in
                                sceneContentViewModel.sceneView
                                
                                // This is a simple tap and identify test, it will be used to select and drag ROI flight plan graphics  ======================
                                    .onSingleTapGesture { screenPoint, _ in
                                        identifyScreenPoint = screenPoint
                                    }
                                    .task(id: identifyScreenPoint) {
                                        guard let identifyScreenPoint = identifyScreenPoint,
                                              let identifyResult = await Result(awaiting: {
                                                  try await sceneProxy.identifyGraphicsOverlays(
                                                    screenPoint: identifyScreenPoint,
                                                    tolerance: 10                                                  )
                                              })
                                            .cancellationToNil()
                                        else {
                                            return
                                        }
                                        
                                        self.identifyScreenPoint = nil
                                        if let firstGraphic = try? identifyResult.get().first?.graphics.first {
                                            print("xxx identifyResult: \(String(describing: firstGraphic.symbol))")
                                        }
                                    }
                                // End of tap and identify test code ======================
                                
                                // Scene view properties
                                    .edgesIgnoringSafeArea(.top)
                                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                                    .background(Color.black.opacity(0.9).gradient)

                                // Overlay for the Compass view
                                // TODO: 200.1 Compass change breaker, fix this
                                    .overlay(alignment: .bottomLeading) {
                                        Button("Compass") {
                                            print("Compass button tapped!")
                                        }
//                                        MapViewReader { proxy in
//                                            Compass(rotation: sceneContentViewModel.sceneViewpoint?.rotation, mapViewProxy: proxy)
//                                                .compassSize(size: 50.0) // This is an option property
//                                                .padding()
//                                                .onTapGesture {
//                                                    print("tap tap")
//                                                }
//                                        }
//                                        Compass(rotation: sceneContentViewModel.sceneViewpoint?.rotation, mapViewProxy: nil)
//                                            .compassSize(size: 50.0) // This is an option property
//                                            .padding()
                                    }
                                
                                // Toolbar for the top right tools
                                    .toolbar {
                                        ToolbarItemGroup {
                                            Button {
                                                toggleScene2D3DState.toggle()
                                            } label: {
                                                Image(systemName: self.toggleScene2D3DState ? "view.3d" : "view.2d")
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
                                            .disabled(toggleScene2D3DState)
                                            
                                            Button {
                                                showBasemapSelector = true
                                                showProfile = false
                                                showEFPortalUserTabbedView = false
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
                                                showEFPortalUserTabbedView = false
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
                            }
                                
                            HStack {
                                Spacer()
                                VStack {
                                    if !showEFPortalUserTabbedView {
                                        Button {
                                            showEFPortalUserTabbedView.toggle()
                                            if showEFPortalUserTabbedView {
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
                                        EFPortalUserTabbedView(portal: portal, showContentAndGroup: $showEFPortalUserTabbedView, sceneContentViewModel: sceneContentViewModel)
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
                sceneLoadResult = await Result {
                    try await sceneContentViewModel.scene.load()
                }
            }
            .onChange(of: toggleCameraController) { value in
                sceneContentViewModel.toggleCameraController(value)
            }
            .onChange(of: toggleScene2D3DState) { value in
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

//public extension Compass {
//    /// Creates a compass with a rotation (0° indicates a direction toward true North, 90° indicates
//    /// a direction toward true West, etc.).
//    /// - Parameters:
//    ///   - rotation: The rotation whose value determines the heading of the compass.
//    ///   - mapViewProxy: The proxy to provide access to map view operations.
//    init(
//        rotation: Double?
//    ) {
//        let heading: Double
//        if let rotation {
//            heading = rotation.isZero ? .zero : 360 - rotation
//        } else {
//            heading = .nan
//        }
//        MapViewReader { proxy in
//            self.init(rotation: rotation, mapViewProxy: proxy)
//        }
//    }
//}
