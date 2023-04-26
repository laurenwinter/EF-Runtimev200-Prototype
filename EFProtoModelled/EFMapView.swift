//
//  EFMapView.swift
//  EFProtoModelled
//
//  Created by Lauren Winter on 3/1/23.
//

import SwiftUI
import ArcGIS
import ArcGISToolkit

struct EFMapView: View {
    
    @ObservedObject var viewModel: EFMapViewModel
    
    var body: some View {
        SceneViewReader { sceneProxy in
            SceneView(scene: viewModel.scene, cameraController: viewModel.controller)
                .onViewpointChanged(kind: .centerAndScale, perform: viewModel.actionOnViewpointChanged)
                .onCameraChanged(perform: viewModel.actionOnCameraChanged)
            
                .onSingleTapGesture(perform: viewModel.actionOnSingleTapGesture)
                .onLongPressGesture(perform: viewModel.actionOnLongPressGesture)
            
                .overlay(alignment: .topTrailing) {
                    OverlayView(viewPoint: $viewModel.viewpoint,
                                buttonAction: viewModel.createNewScene,
                                autohide: false)
                }
            
                .onChange(of: viewModel.viewpoint!, perform: viewModel.actionOnChange)
        }
    }
}

struct OverlayView: View {
    @Binding var viewPoint: ArcGIS.Viewpoint?
    var buttonAction: ()->()
    let autohide: Bool
    
    var body: some View {
        VStack {
            Compass(viewpoint: $viewPoint, autoHide: autohide)
                .padding()
            Button("button") {
                buttonAction()
            }
        }
    }
}

class EFMapViewModel: ObservableObject {
    @Published var controller: OrbitLocationCameraController =
        OrbitLocationCameraController(
            targetPoint: Point(
                x: -117.19494,
                y: 34.05723,
                spatialReference: .wgs84
            ),
            distance: 2000
        )!
    
    @Published var viewpoint: Viewpoint?
    
    @Published var scene: ArcGIS.Scene
    
    var camera: ArcGIS.Camera?

    var lastNonZeroRotation: Double? = 0
    
    var sceneViewProxy: ArcGIS.SceneViewProxy?
    
    init() {
        let initialViewpoint = Viewpoint(
            center: Point(x: -117.19494, y: 34.05723, spatialReference: .wgs84),
            scale: 10_000,
            rotation: -45
        )
        let url = URL(string: "https://www.arcgis.com/home/item.html?id=c03a526d94704bfb839445e80de95495")!
        let basemap = Basemap(item: PortalItem(url: url)!)
        scene = Scene(basemap: basemap)
        viewpoint = initialViewpoint
        scene.initialViewpoint = initialViewpoint
    }
    
    func actionOnViewpointChanged(viewpoint: ArcGIS.Viewpoint) {
        self.viewpoint = viewpoint
        if let rotation = self.viewpoint?.rotation, rotation != .zero {
            lastNonZeroRotation = rotation
        }
    }
    
    func actionOnCameraChanged(camera: ArcGIS.Camera) {
        self.camera = camera
    }
    
    func actionOnSingleTapGesture(screenPoint: CGPoint, scenePoint: ArcGIS.Point?) {
        
    }
    
    func actionOnLongPressGesture(screenPoint: CGPoint, scenePoint: ArcGIS.Point?) {
        
    }
    
    func actionOnChange(viewpoint: ArcGIS.Viewpoint) {
        if viewpoint.rotation != .zero {
            lastNonZeroRotation = viewpoint.rotation
        }
        if let lastRotation = lastNonZeroRotation, viewpoint.rotation == 0 {
            let delta = lastRotation > .zero && lastRotation < 180 ?
                -lastRotation :
                360 - lastRotation
            Task {
                try await controller.moveCamera(
                    distanceDelta: .zero,
                    headingDelta: delta,
                    pitchDelta: .zero,
                    duration: 0.3
                )
            }
        }
    }
    
    func createNewScene() {
        let url = URL(string: "https://www.arcgis.com/home/item.html?id=67372ff42cd145319639a99152b15bc3")!
        let basemap = Basemap(item: PortalItem(url: url)!)
        scene.basemap = basemap
        //scene.basemap = ArcGIS.Scene(basemap: basemap)
    }
}
