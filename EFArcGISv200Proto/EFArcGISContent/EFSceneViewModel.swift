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
        
    public var sceneView: ArcGIS.SceneView

    @Published var scene: ArcGIS.Scene
    
    // All of the ArcGIS User content, items are placed in associated folders
    @ObservedObject var userContentViewModel = EFUserContentViewModel()
    
    let baseMapDataModel: EFBasemapDataModel
    
    public let dropPinGraphicsOverlay = GraphicsOverlay()
    public let favoritesGraphicsOverlay = GraphicsOverlay()
    public let searchResultsGraphicsOverlay = GraphicsOverlay()
    public let measureGraphicsOverlay = GraphicsOverlay()

    public var graphicsOverlays = [GraphicsOverlay]()
    
    // An array of tasks to handle multiple asynchnous server calls
    private var arcGISGeodatabaseSyncTasks = [ServiceGeodatabase]()
        
    init() {
        let scene = ArcGIS.Scene(basemap: Basemap.init(style: .arcGISNewspaper))
        self.scene = scene
        self.baseMapDataModel = EFBasemapDataModel(geoModel: scene)

        self.graphicsOverlays.append(contentsOf: [favoritesGraphicsOverlay, searchResultsGraphicsOverlay, dropPinGraphicsOverlay, measureGraphicsOverlay])
        self.sceneView = SceneView(scene: scene, graphicsOverlays: self.graphicsOverlays)
        self.userContentViewModel.portalItemSelected = itemSelectedCallback
    }
    
    private func itemSelectedCallback(_ itemModel: EFPortalItemModel, _ state: EFPortalItemModel.ItemState) {
        //print("itemSelectedFunc, \(itemModel.portalItem.title), selected: \(state)")
        switch state {
        case .initialized:
            // Do nothing
            ()
        case .visible:
            Task {
                // WIP, this is simple demo for Web Scene, needs to be a layer handler
                switch itemModel.portalItem.kind {
                case .webScene:
                    scene = Scene(item: itemModel.portalItem)
                    updateSceneView(scene: scene)
                    
                case .webMap:
                    // Web Map types can not be loaded into a 3D Scene so they're loaded into an AGSMap and then the operational layers are copied for loading into the Scene
                    let map = Map(item: itemModel.portalItem)
                    try await map.load()
                    let extent = map.initialViewpoint?.targetGeometry.extent
                    
                    map.operationalLayers.forEach { (layer) in
                        let clone = layer.clone()
                        scene.addOperationalLayer(clone)
                    }
                    
                    if let extent = itemModel.portalItem.extent {
                        print("full extent: \(extent)")
                        updateSceneExtent(extent: extent)
                    }
                    
                case .featureService:
                    let layer = ArcGIS.FeatureLayer(item: itemModel.portalItem)
                    scene.addOperationalLayer(layer)
                    
                    try await layer.load()
                    if let extent = layer.fullExtent {
                        print("full extent: \(extent)")
                        updateSceneExtent(extent: extent)
                    }
                    
                case .kml:
                    let layer = ArcGIS.KMLLayer(item: itemModel.portalItem)
                    scene.addOperationalLayer(layer)
                    
                    try await layer.load()
                    if let extent = layer.fullExtent {
                        print("full extent: \(extent)")
                        updateSceneExtent(extent: extent)
                    }
                    
                case .sceneService:
                    let layer = ArcGIS.ArcGISSceneLayer(item: itemModel.portalItem)
                    scene.addOperationalLayer(layer)
                    
                    try await layer.load()
                    if let extent = layer.fullExtent {
                        print("full extent: \(extent)")
                        updateSceneExtent(extent: extent)
                    }
                    
                default:
                    () // Do nothing
                }
            }
        case .hidden:
            // For testing only, return the map scene to it's default state
            let scene = ArcGIS.Scene(basemap: Basemap.init(style: .arcGISNewspaper))
            self.scene = scene
            updateSceneView(scene: scene)

        }
    }
    
    func updateSceneExtent(extent: ArcGIS.Envelope?) {
        if let extent = extent {
            let center = extent.center
            
            let cameraDistanceDefault: Double = 300
            
            let sceneCamera = ArcGIS.Camera(lookAtPoint: center, distance: cameraDistanceDefault, heading: 0, pitch: 0, roll: 0)
            let cameraController = ArcGIS.TransformationMatrixCameraController(originCamera: sceneCamera)
            self.sceneView = SceneView(scene: scene, graphicsOverlays: self.graphicsOverlays)
        }
    }
    
    func updateSceneView(scene: ArcGIS.Scene) {
        dropPinGraphicsOverlay.removeAllGraphics()

        sceneView = SceneView(scene: scene, graphicsOverlays: self.graphicsOverlays)
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
}

class EFPortalItemModel: ObservableObject, Identifiable {
    
    enum ItemState {
        case initialized, visible, hidden
    }
    
    /// The ArcGIS PortalItem
    var portalItem: PortalItem
    
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
    
    public var portalItemSelected: ((_ itemModel: EFPortalItemModel, _ state: EFPortalItemModel.ItemState) -> Void)?
        
    @Published var portalItemModels : [EFPortalItemModel] = []
    
    @Published var portalFolderModels : Dictionary = [String: EFPortalItemFolderModel]()
    
    private var subscriptions = Set<AnyCancellable>()
    
    func updatePortalItems(portal: Portal) async {
        guard let user = portal.user else {
            return
        }
        var results = [EFPortalItemModel]()
        if let contentItems = await updatePortalContent(user) {
            contentItems.forEach() { item in
                let portalItemModel = EFPortalItemModel(portalItem: item)
                portalItemModel.$currentState
                    .sink { isVisible in
                        //print("Item \(item.title) is visible: \(isVisible)")
                }.store(in: &subscriptions)

                results.append(portalItemModel)
            }
        }
        if let allFolderContent = await updatePortalContentFolders(user) {
            allFolderContent.forEach() { item in
                let portalItemModel = EFPortalItemModel(portalItem: item)
                results.append(portalItemModel)
            }
        }
        self.portalItemModels.removeAll()
        self.portalItemModels = results.sorted { $0.portalItem.title.lowercased() < $1.portalItem.title.lowercased() }
    }
    
    func loadPortal(portal: Portal) async throws -> ArcGIS.PortalUser? {
        do {
            try await portal.load()
            if let user = portal.user {
                //print("xxx portal user = \(user.fullName)")
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
                let portalItemModel = EFPortalItemModel(portalItem: rootItem)
                portalItemModel.$currentState
                    .sink { isVisible in
                        self.portalItemSelected?(portalItemModel, isVisible)
                        //print("Root Item \(rootItem.title) is visible: \(isVisible)")
                }.store(in: &subscriptions)

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
                                let portalItemModel = EFPortalItemModel(portalItem: folderItem)
                                portalItemModel.$currentState
                                    .sink { isVisible in
                                        self.portalItemSelected?(portalItemModel, isVisible)
                                    }.store(in: &subscriptions)
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
            //print("xxx portal user content = \(contentItems.count)")
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
                    // WIP let folderItem = EFPortalItemFolderModel(portalFolder: folder)
                    if let folderItems = await loadFolderContent(user, folder: folder) {
                        allFolderItems.append(contentsOf: folderItems)
                        //print("xxx folder: \(folder.title) items = \(folderItems.count)")
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
