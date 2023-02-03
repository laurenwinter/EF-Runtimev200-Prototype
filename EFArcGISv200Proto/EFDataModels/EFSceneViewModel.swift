//
//  EFSceneContentViewModel.swift
//  AuthenticationExample
//
//  Created by Lauren Winter on 12/7/22.
//

import SwiftUI
import ArcGIS
import Combine

public final class EFSceneContentViewModel: ObservableObject {
        
    public var sceneView: ArcGIS.SceneView {
        willSet {
            // This will force the Views that are using the SceneView to refresh
            // There must be a better SwiftUI way to update the SceneView???
            objectWillChange.send()
        }
    }
    
    // A property that may be used to change the camera controller and elevation.
    // Waiting for Runtime fix to see if this is needed or not
    private var viewpoint: ArcGIS.Viewpoint?
    
    private var sceneCamera: ArcGIS.Camera
    private var sceneCameraController: ArcGIS.CameraController
    private let cameraDistanceDefault: Double = 300

    @Published var scene: ArcGIS.Scene
    
    // All of the ArcGIS User content, items are placed in associated folders
    @ObservedObject var userContentViewModel = EFUserContentViewModel()
    
    // Data model to test the scene basemap changing functionality
    let baseMapDataModel: EFBasemapDataModel
    
    // Set of GraphicsOverlay for testing struct SceneView
    public let dropPinGraphicsOverlay = GraphicsOverlay()
    public let favoritesGraphicsOverlay = GraphicsOverlay()
    public let searchResultsGraphicsOverlay = GraphicsOverlay()
    public let measureGraphicsOverlay = GraphicsOverlay()

    public var graphicsOverlays = [GraphicsOverlay]()
    
    // An array of tasks to handle multiple asynchnous server calls
    private var arcGISGeodatabaseSyncTasks = [ServiceGeodatabase]()
        
    init() {
        let scene = ArcGIS.Scene(basemap: Basemap.init(style: .arcGISImageryStandard))
        self.scene = scene
        self.baseMapDataModel = EFBasemapDataModel(geoModel: scene)

        self.graphicsOverlays.append(contentsOf: [favoritesGraphicsOverlay, searchResultsGraphicsOverlay, dropPinGraphicsOverlay, measureGraphicsOverlay])
        self.sceneView = SceneView(scene: scene, graphicsOverlays: self.graphicsOverlays)
        
        self.sceneCamera = ArcGIS.Camera(latitude: 37.873350, longitude: -122.302525, altitude: cameraDistanceDefault, heading: 0, pitch: 0, roll: 0)
        self.sceneCameraController = ArcGIS.TransformationMatrixCameraController(originCamera: sceneCamera)

        self.userContentViewModel.portalItemSelected = self.itemSelectedCallback
        
        updateSceneView(scene: self.scene, extent: nil, orbitalCameraState: nil)
    }
    
    // This is a simple test for operational layers, the ArcGIS Online layers that the user can select
    // This is a basic PortalItem (layer) function to add and remove layers.
    private func itemSelectedCallback(_ itemModel: EFPortalItemModel, _ state: EFPortalItemModel.ItemState) {
        //print("itemSelectedFunc, \(itemModel.portalItem.title), selected: \(state)")
        switch state {
        case .initialized:
            // Do nothing
            ()
        case .visible:
            Task {
                // WIP, this is simple demo for Web Scene, needs to be a layer handler
                print("Selected layer: \(itemModel.portalItem.title) type: \(itemModel.portalItem.kind.description)")
                
                switch itemModel.portalItem.kind {
                case .webScene:
                    let operationalLayers = scene.operationalLayers
                    scene.removeAllOperationalLayers()
                    
                    scene = Scene(item: itemModel.portalItem)
                    scene.addOperationalLayers(operationalLayers)

                    // Not using the current extent here, webScene's often have a specific extent
//                  let extent = viewpoint?.targetGeometry.extent
//                  updateSceneView(scene: scene, extent: extent)
                    
                    updateSceneView(scene: scene, extent: nil, orbitalCameraState: nil)
                    
                case .webMap:
                    // Web Map types can not be loaded into a 3D Scene so they're loaded into an AGSMap and then the operational layers are copied for loading into the Scene
                    let map = Map(item: itemModel.portalItem)
                    try await map.load()
                    
                    map.operationalLayers.forEach { (layer) in
                        let clone = layer.clone()
                        if let layerID = clone.id?.rawValue {
                            itemModel.operationalLayerIDs.insert(layerID, at: 0)
                            scene.addOperationalLayer(clone)
                        }
                    }
                    
                    if let extent = itemModel.portalItem.extent {
                        print("webMap full extent: \(extent)")
                        updateSceneView(scene: scene, extent: extent, orbitalCameraState: nil)
                    }
                    
                case .featureService:
                    let layer = ArcGIS.FeatureLayer(item: itemModel.portalItem)
                    scene.addOperationalLayer(layer)
                    
                    try await layer.load()
                    if let extent = layer.fullExtent, let layerID = layer.id?.rawValue {
                        print("featureService full extent: \(extent)")
                        itemModel.operationalLayerIDs.insert(layerID, at: 0)
                        updateSceneView(scene: scene, extent: extent, orbitalCameraState: nil)
                    }
                    
                case .kml:
                    let layer = ArcGIS.KMLLayer(item: itemModel.portalItem)
                    scene.addOperationalLayer(layer)
                    
                    try await layer.load()
                    if let extent = layer.fullExtent, let layerID = layer.id?.rawValue {
                        print("kml full extent: \(extent)")
                        itemModel.operationalLayerIDs.insert(layerID, at: 0)
                        updateSceneView(scene: scene, extent: extent, orbitalCameraState: nil)
                    }
                    
                case .sceneService:
                    let layer = ArcGIS.ArcGISSceneLayer(item: itemModel.portalItem)
                    scene.addOperationalLayer(layer)
                    
                    try await layer.load()
                    if let extent = layer.fullExtent, let layerID = layer.id?.rawValue {
                        print("sceneService full extent: \(extent)")
                        itemModel.operationalLayerIDs.insert(layerID, at: 0)
                        updateSceneView(scene: scene, extent: extent, orbitalCameraState: nil)
                    }
                    
                case .mapService:
                    let layer = ArcGIS.ArcGISTiledLayer(item: itemModel.portalItem)
                    scene.addOperationalLayer(layer)
                    
                    try await layer.load()
                    if let extent = layer.fullExtent, let layerID = layer.id?.rawValue {
                        print("sceneService full extent: \(extent)")
                        itemModel.operationalLayerIDs.insert(layerID, at: 0)
                        updateSceneView(scene: scene, extent: extent, orbitalCameraState: nil)
                    }
                    
                default:
                    // Not supported type
                    print("Not supported layer type: \(itemModel.portalItem.kind.description)")
                }
            }
        case .hidden:
            switch itemModel.portalItem.kind {
            case .webScene:
                
                let operationalLayers = scene.operationalLayers
                scene.removeAllOperationalLayers()

                // For testing only, return the map scene to it's default state
                let scene = ArcGIS.Scene(basemap: Basemap.init(style: .arcGISImageryStandard))
                scene.addOperationalLayers(operationalLayers)

                let extent = viewpoint?.targetGeometry.extent
                updateSceneView(scene: scene, extent: extent, orbitalCameraState: nil)
            default:
                let operationalLayers = scene.operationalLayers
                itemModel.operationalLayerIDs.forEach { layerID in
                    operationalLayers.forEach { layer in
                        if layerID == layer.id?.rawValue {
                            scene.removeOperationalLayer(layer)
                        }
                    }
                }
            }

        }
    }
    
    // No reason to review this function yet
    // We need a Runtime fix before developing this into usable code
    func updateSceneView(scene: ArcGIS.Scene, extent: ArcGIS.Envelope?, orbitalCameraState: Bool?) {
        dropPinGraphicsOverlay.removeAllGraphics()

        if let cameraState = orbitalCameraState {
            if cameraState {
                sceneCameraController = GlobeCameraController()
            } else {
                // This functionality doesn't work yet because Runtime isn't returning the current viewpoint camera, self.viewpoint is incorrect
                // https://devtopia.esri.com/runtime/swift/issues/3434
                let cameraPoint = sceneCamera.location
                if let targetPoint = self.viewpoint?.targetGeometry as? ArcGIS.Point {
                    if let matrix = self.viewpoint?.camera?.transformationMatrix {
                        var camera = Camera(transformationMatrix: matrix)
                        print("Matrix = \(camera.heading), \(camera.pitch), \(camera.roll)")
                    }
                    print("target: \(targetPoint), cameraPoint:\(cameraPoint)")
                    sceneCameraController = OrbitLocationCameraController(targetPoint: targetPoint, cameraPoint: cameraPoint)
                }
            }
        } else {
            self.scene = scene
            if let extent = extent {
                let center = extent.center
                
                sceneCamera = ArcGIS.Camera(lookAtPoint: center, distance: cameraDistanceDefault, heading: 0, pitch: 0, roll: 0)
                sceneCameraController = ArcGIS.TransformationMatrixCameraController(originCamera: sceneCamera)
            }
        }
        
        self.sceneView = SceneView(scene: scene, cameraController: sceneCameraController, graphicsOverlays: graphicsOverlays)
            .onViewpointChanged(kind: .centerAndScale) {
//                if let geometry = self.viewpoint?.targetGeometry {
//                    let newVP = Viewpoint(targetExtent: geometry, camera: self.sceneCamera)
//                    self.viewpoint = newVP
//
//                    //print("new viewpoint: \(self.viewpoint), target: \(self.viewpoint?.targetGeometry), cameraPoint:\(self.sceneCamera.location)")
//                } else {
                    self.viewpoint = $0
                    print("viewpoint: \(self.viewpoint), target: \(self.viewpoint?.targetGeometry), cameraPoint:\(self.sceneCamera.location)")
//                }
            }
            .onLongPressGesture { _, mapPoint in
                self.handleLongPress(point: mapPoint)
        }
                
        baseMapDataModel.geoModel = scene
    }
    
    func handleLongPress(point: Point?) {

        guard let point = point, let symbol = createDroppedPinSymbol() else {
            return
        }
        
        dropPinGraphicsOverlay.removeAllGraphics()
        dropPinGraphicsOverlay.addGraphic(Graphic(geometry: point, attributes: [:], symbol: symbol))
    }

    private func createDroppedPinSymbol() -> PictureMarkerSymbol? {
        guard let image = UIImage(systemName: "mappin.and.ellipse")?.withTintColor(.systemCyan) else {
            return nil
        }
        let symbol = PictureMarkerSymbol(image: image)
        symbol.height = image.size.height * 2
        symbol.width = image.size.width * 2
        return symbol
    }
    
    // No reason to review this function yet
    public func toggleCameraController(_ selectionState: Bool) {
        updateSceneView(scene: scene, extent: nil, orbitalCameraState: selectionState)
        /*
        if selectionState {
            sceneView = SceneView(scene: scene, cameraController: GlobeCameraController(), graphicsOverlays: graphicsOverlays)
        } else {
            let cameraPoint = sceneCamera.location
            //if let targetPoint = self.viewpoint?.targetGeometry as? ArcGIS.Envelope {
            if let targetPoint = self.viewpoint?.targetGeometry as? ArcGIS.Point {
                if let matrix = self.viewpoint?.camera?.transformationMatrix {
                    var camera = Camera(transformationMatrix: matrix)
                    print("Matrix = \(camera.heading), \(camera.pitch), \(camera.roll)")
                }
                print("target: \(targetPoint), cameraPoint:\(cameraPoint)")
                let cameraController = OrbitLocationCameraController(targetPoint: targetPoint, cameraPoint: cameraPoint)
                sceneView = SceneView(scene: scene, cameraController:cameraController, graphicsOverlays: graphicsOverlays)
                
            }
        }*/
    }
    
    // No reason to review this function yet
    public func toggleScene2D3D(_ controllerState: Bool) {
        print("toggleScene2D3D")
        if controllerState {
            let surface = Surface()
            scene.baseSurface = surface
            if let targetPoint = self.viewpoint?.targetGeometry as? ArcGIS.Point {
                sceneCamera = ArcGIS.Camera(lookAtPoint: targetPoint, distance: cameraDistanceDefault, heading: 0, pitch: 0, roll: 0)
            }
            self.sceneCameraController = ArcGIS.TransformationMatrixCameraController(originCamera: sceneCamera)
            sceneView = SceneView(scene: scene, cameraController:self.sceneCameraController, graphicsOverlays: graphicsOverlays)
        } else {
            let ESRI_ELEVATION_SOURCE_URL: String = "https://elevation3d.arcgis.com/arcgis/rest/services/WorldElevation3D/Terrain3D/ImageServer"
            let worldElevationService = URL(string: ESRI_ELEVATION_SOURCE_URL)!
            let elevationSource = ArcGIS.ArcGISTiledElevationSource(url: worldElevationService)
            
            Task {
                try await elevationSource.load()
                
                let surface = ArcGIS.Surface()
                surface.addElevationSource(elevationSource)
                
                try await surface.load()
                scene.baseSurface = surface
                
                let cameraPoint = sceneCamera.location
                if let targetPoint = self.viewpoint?.targetGeometry as? ArcGIS.Point {
                    //print("target: \(targetPoint), cameraPoint:\(cameraPoint)")
                    let cameraController = OrbitLocationCameraController(targetPoint: targetPoint, cameraPoint: cameraPoint)
                    sceneView = SceneView(scene: scene, cameraController:cameraController, graphicsOverlays: graphicsOverlays)
                }
            }
        }
    }
}

class EFPortalItemModel: ObservableObject, Identifiable {
    
    enum ItemState {
        case initialized, visible, hidden
    }
    
    /// The ArcGIS PortalItem
    var portalItem: PortalItem
    
    /// String array used to manage the layers added by the user
    var operationalLayerIDs = [String]()
    
    /// State that is set by the app user to load and show the portal item on the map
    @Published var currentState = ItemState.initialized
    
    let id = UUID()
    
    init(portalItem: PortalItem) {
        self.portalItem = portalItem
    }
}

class EFPortalItemFolderModel: ObservableObject, Identifiable {
    public static let ARCGIS_ROOT_FOLDER_ID = "Root"

    var portalID = ""
    var folderTitle = ""
    var portalFolder: PortalFolder?
    var portalItemModels: Dictionary = [String: EFPortalItemModel]()

    let id = UUID()
    
    init(_ title: String, id: String, portalFolder: PortalFolder?) {
        self.portalID = id
        self.folderTitle = title
        self.portalFolder = portalFolder
    }
}

@MainActor class EFUserContentViewModel: ObservableObject {
    
    // Essentially a callback assigned to this model from the parent mode (EFSceneContentViewModel) to handle user select/deselect of a layer
    // We'll review this model hierarchy to determine if there's a better approach
    public var portalItemSelected: ((_ itemModel: EFPortalItemModel, _ state: EFPortalItemModel.ItemState) -> Void)?
       
    // Array of item models that holds the ArcGIs Online users Content items
    @Published var portalItemModels : [EFPortalItemModel] = []
    
    // Array of folder models that holds the ArcGIs Online users Folders items, each Folder model will have an array of item models
    @Published var portalFolderModels : Dictionary = [String: EFPortalItemFolderModel]()
    
    private var itemSubscriptions = Set<AnyCancellable>()
    
    func updatePortalItems(portal: Portal) async {
        guard let user = portal.user else {
            return
        }
        
        var allRootItemModels = [EFPortalItemModel]()
        if let contentItems = await updatePortalContent(user) {
            contentItems.forEach() { item in
                // Create a model for each item
                let portalItemModel = EFPortalItemModel(portalItem: item)
                
                // Add sink to the item model state for change-of-state
                portalItemModel.$currentState
                    .sink { isVisible in
                        self.portalItemSelected?(portalItemModel, isVisible)
                }.store(in: &itemSubscriptions)

                allRootItemModels.append(portalItemModel)
            }
        }
        if let allFolderContent = await updatePortalContentFolders(user) {
            allFolderContent.forEach() { item in
                let portalItemModel = EFPortalItemModel(portalItem: item)
                allRootItemModels.append(portalItemModel)
            }
        }
        self.portalItemModels.removeAll()
        self.portalItemModels = allRootItemModels.sorted { $0.portalItem.title.lowercased() < $1.portalItem.title.lowercased() }
    }
    
    func loadPortal(portal: Portal) async throws -> ArcGIS.PortalUser? {
        do {
            try await portal.load()
            if let user = portal.user {
                return user
            } else {
                return nil
            }
        } catch {
            return nil
        }
    }
    
    func updatePortalUserFolders(portal: ArcGIS.Portal) async {
        guard let user = portal.user else {
            return
        }
        do {
            // If there's no Root folder then create and load the root folder with the user content
            if portalFolderModels[EFPortalItemFolderModel.ARCGIS_ROOT_FOLDER_ID] == nil {
                portalFolderModels[EFPortalItemFolderModel.ARCGIS_ROOT_FOLDER_ID] = EFPortalItemFolderModel(user.fullName, id: EFPortalItemFolderModel.ARCGIS_ROOT_FOLDER_ID, portalFolder: nil)
            }
            let contentItems = try await user.content.items
            contentItems.forEach { rootItem in
                // Create a model for each item
                let portalItemModel = EFPortalItemModel(portalItem: rootItem)
                
                // Add sink to the item model state for change-of-state
                portalItemModel.$currentState
                    .sink { isVisible in
                        self.portalItemSelected?(portalItemModel, isVisible)
                }.store(in: &itemSubscriptions)

                // If it doesn't already exist then add the item to the root folder
                if portalFolderModels[EFPortalItemFolderModel.ARCGIS_ROOT_FOLDER_ID]?.portalItemModels[portalItemModel.portalItem.id.rawValue] == nil {
                    portalFolderModels[EFPortalItemFolderModel.ARCGIS_ROOT_FOLDER_ID]?.portalItemModels[portalItemModel.portalItem.id.rawValue] = portalItemModel
                }
            }
        } catch {
           ()
        }
        
        do {
            // Load all folders
            let folders = try await user.content.folders
                for folder in folders {
                    if portalFolderModels[folder.id.rawValue] == nil {
                        portalFolderModels[folder.id.rawValue] = EFPortalItemFolderModel(folder.title, id: folder.id.rawValue, portalFolder: folder)
                    }
                    if let folderItems = await loadFolderContent(user, folder: folder) {
                        folderItems.forEach { folderItem in
                            if let portalFolderModel = portalFolderModels[folder.id.rawValue], portalFolderModel.portalItemModels[folderItem.id.rawValue] == nil {
                                // Create a model for each item
                                let portalItemModel = EFPortalItemModel(portalItem: folderItem)
                                
                                // Add sink to the item model state for change-of-state
                                portalItemModel.$currentState
                                    .sink { isVisible in
                                        self.portalItemSelected?(portalItemModel, isVisible)
                                    }.store(in: &itemSubscriptions)
                                portalFolderModel.portalItemModels[portalItemModel.portalItem.id.rawValue] = portalItemModel
                            }
                        }
                    }
                }
        } catch {
            ()
        }
    }
    
    private func updatePortalContent(_ user: ArcGIS.PortalUser) async -> [PortalItem]? {
        do {
            let contentItems = try await user.content.items
            return contentItems
        } catch {
            return nil
        }
    }
    
    private func updatePortalContentFolders(_ user: ArcGIS.PortalUser) async -> [PortalItem]? {
        do {
            var allFolderItems = [PortalItem]()
            let folders = try await user.content.folders
                for folder in folders {
                    if let folderItems = await loadFolderContent(user, folder: folder) {
                        allFolderItems.append(contentsOf: folderItems)
                    }
                }
                return allFolderItems
        } catch {
            return nil
        }
    }
    
    private func loadFolderContent(_ user: ArcGIS.PortalUser, folder: ArcGIS.PortalFolder) async -> [PortalItem]? {
        do {
            let folderItems = try await user.itemsInFolder(withID: folder.id)
            return folderItems
        } catch {
            return nil
        }
    }
}

///
/// For Previews ============================================
///
class EFUserContentViewModel_Preview : EFUserContentViewModel {
    override init() {
        super.init()
        let portal: Portal = .arcGISOnline(connection: .anonymous)
        for index in 1...25 {
            let folderModel = EFPortalItemFolderModel("\(index)", id: "\(index)", portalFolder: nil)
            portalFolderModels[folderModel.portalID] = folderModel
            
        }
        
        for itemIndex in 1...5 {
            let viewCount = Int.random(in: 0..<100000)
            guard let portalItem = PortalItem(json: "{\"access\":\"private\",\"avgRating\":0,\"commentsEnabled\":false,\"created\":1597947840000,\"culture\":\"en-us\",\"id\":\(itemIndex),\"modified\":1597953188000,\"numComments\":0,\"numRatings\":0,\"numViews\":\(viewCount),\"owner\":\"lwinter@esri.com\",\"ownerFolder\":\"d7975ba758404121895e7136cafdcc47\",\"size\":2298,\"tags\":[\"Site Scan\"],\"thumbnail\":\"thumbnail/ago_downloaded.jpeg\",\"title\":\"BridgeOffsetTest\",\"type\":\"Web Scene\",\"typeKeywords\":[\"3D\",\"Map\",\"Scene\",\"Streaming\",\"Web\",\"Web Scene\"]}", portal: portal) else {
                return
            }
            let uiImage = UIImage(systemName: "moon.stars.fill")?.withTintColor(UIColor(red: CGFloat.random(in: 0.0..<1.0), green: CGFloat.random(in: 0.0..<1.0), blue: CGFloat.random(in: 0.0..<1.0), alpha: 1.0))
            portalItem.setThumbnail(image: uiImage)
            let item = EFPortalItemModel(portalItem: portalItem) //PortalItem(portal: portal, id: Item.ID(rawValue: "\(itemIndex)")!))
            portalItemModels.append(item)
        }
        
    }
}
