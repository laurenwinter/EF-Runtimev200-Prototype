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
    
    @State private var dragActive = false
            
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
                                    
                                //https://devtopia.esri.com/runtime/swift/pull/4088/files
//                                    .onDragGesture(
//                                                        shouldBegin: { screenPoint, _ in
//                                                        guard let identifyResult = try? await proxy.identify(
//                                                          on: graphicsOverlay,
//                                                          screenPoint: screenPoint,
//                                                          tolerance: 1
//                                                        ), let identifyGraphic = identifyResult.graphics.first else {
//                                                            return false // The SDK should handle the drag gesture.
//                                                        }
//
//                                                        // The user clicked on a valid graphic so lets keep track of that graphic.
//                                                        selectedGraphic = identifyGraphic
//
//                                                        return true // We will handle the drag gesture.
//                                                    }, onChanged: { _, scenePoint in
//
//                                                        // Change location of the selected graphic to the new drag location.
//                                                        selectedGraphic.geometry = scenePoint
//                                                    }, onEnded: { _, _ in
//                                                        selectedGraphic = nil
//                                                    }, onCancelled: {
//                                                        selectedGraphic = nil
//                                                    })
                                
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
                                            if dragActive {
                                                // Dragging the touched graphic
                                                
                                            }
                                        }
                                    }
                                // End of tap and identify test code ======================
                                
                                // Gesture handling test Graphic interaction
                                    .gesture(
                                        DragGesture()
                                            .onChanged { point in
                                                
                                                guard let mapPoint = sceneProxy.baseSurfaceLocation(fromScreenPoint: point.location) else {
                                                    print("Dragged outside the visible scene area")
                                                    return
                                                }
                                                // Note, mapPoint == nil when dragging outside the visible SceneView View area
                                                
                                                // The initial drag change is when to test for touching a Graphic
                                                if !dragActive {
                                                    dragActive = true
                                                    identifyScreenPoint = point.location
                                                    print("ZZZ Drag started: screenPoint: \(point.location), mapPoint: \(mapPoint.x), \(mapPoint.y)")
                                                    //sceneProxy.identify(on: GraphicsOverlay, screenPoint: <#T##CGPoint#>, tolerance: <#T##Double#>)
                                                } else {
                                                    print("ZZZ Drag in progress: screenPoint: \(point.location), mapPoint: \(mapPoint.x), \(mapPoint.y)")
                                                }
                                            }
                                            .onEnded { _ in
                                                print("Drag Ended")
                                                dragActive = false
                                            }
                                    )
                                
                                // Scene view properties
                                    .edgesIgnoringSafeArea(.top)
                                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                                    .background(Color.black.opacity(0.9).gradient)
                                

                                // Overlay for the Compass view
                                // TODO: 200.1 Compass change breaker, fix this
//                                    .overlay(alignment: .bottomLeading) {
//                                        Compass(rotation: $sceneContentViewModel.sceneViewpoint?.rotation, action: {
//                                            //mapViewModel.rotateMapToNorthFacing(sceneViewProxy: sceneViewProxy)
//                                            print("Compass rotate to North")
//                                        })
//                                        .autoHideDisabled(true)
//                                        .compassSize(size: 50.0)
//                                        .padding()
//                                    }
                                
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
