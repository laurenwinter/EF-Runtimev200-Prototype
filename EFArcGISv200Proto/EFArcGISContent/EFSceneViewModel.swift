//
//  EFSceneContentViewModel.swift
//  AuthenticationExample
//
//  Created by Lauren Winter on 12/7/22.
//

import SwiftUI
import ArcGIS
import Combine
import OrderedCollections

public final class EFSceneContentViewModel: ObservableObject {
        
    public var sceneView: ArcGIS.SceneView

    @Published var scene: ArcGIS.Scene
    
    // All of the ArcGIS User content, items are placed in associated folders
    @ObservedObject var userContentViewModel = EFUserContentViewModel()
        
    init() {
        let scene = ArcGIS.Scene(basemap: Basemap.init(style: .arcGISNewspaper))
        self.scene = scene
        self.sceneView = SceneView(scene: scene)
        self.userContentViewModel.portalItemSelected = itemSelectedCallback
    }
    
    private func itemSelectedCallback(_ itemModel: EFPortalItemModel, _ state: EFPortalItemModel.ItemState) {
        let title = itemModel.portalItem.title
        print("itemSelectedFunc, \(title), selected: \(state)")
        // WIP, either add or remove the item...to the Scene!
        switch state {
        case .initialized:
            // Do nothing
            ()
        case .visible:
            // WIP, this is simple demo for Web Scene, needs to be a layer handler
            if itemModel.portalItem.typeName.contains("Web Scene") {
                scene = Scene(item: itemModel.portalItem)
                sceneView = SceneView(scene: scene)
            }
        case .hidden:
            // For testing only, return the map scene to it's default state
            let scene = ArcGIS.Scene(basemap: Basemap.init(style: .arcGISNewspaper))
            self.scene = scene
            self.sceneView = SceneView(scene: scene)
        }
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
    var portalFolder: PortalFolder?
    var portalItemModels: Dictionary = [String: EFPortalItemModel]()

    let id = UUID()
    
    init(_ title: String, id: String, portalFolder: PortalFolder?) {
        self.portalID = id
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
                        let title = item.title
                        print("Item \(title) is visible: \(isVisible)")
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
        self.portalItemModels = results
    }
    
    func loadPortal(portal: Portal) async throws -> ArcGIS.PortalUser? {
        do {
            try await portal.load()
            if let user = portal.user {
                print("xxx portal user = \(user.fullName)")
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
                        let title = rootItem.title
                        print("Root Item \(title) is visible: \(isVisible)")
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
                                        let title = folderItem.title
                                        print("Folder Item \(title) is visible: \(isVisible)")
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
            print("xxx portal user content = \(contentItems.count)")
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
                        print("xxx folder: \(folder.title) items = \(folderItems.count)")
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
