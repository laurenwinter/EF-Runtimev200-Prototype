//
//  EFProtoModelledApp.swift
//  EFProtoModelled
//
//  Created by Lauren Winter on 3/1/23.
//

import SwiftUI

/*
// MARK: - Site Scan Module (Composition)
class SiteScanApp {
    init() {
        // This is just an example on how to instantiate this
        let baseMapController = ArcGISBaseMapController()
        ViewModel(baseMapController: baseMapController)
    }
}

// MARK: - Core Use Cases Module
class ViewModel {
    let baseMapController: EFBaseMapControllerProtocol
    
    init(baseMapController: EFBaseMapControllerProtocol) {
        self.baseMapController = baseMapController
    }
    
    func setMapForMissionPlanning() {
        let efBaseMap: EFBaseMap = .satellite
        baseMapController.setBaseMap(baseMap: efBaseMap)
    }
}

// MARK: - Core Module
enum EFBaseMap {
    case satellite
    case elevation
}

protocol EFBaseMapControllerProtocol {
    func setBaseMap(baseMap: EFBaseMap)
}


// MARK: - ArcGIS Module
enum ArcGISBaseMap {
    case satellite
    case elevationTerrain
}

class ArcGISBaseMapController: EFBaseMapControllerProtocol {
    var baseMap: ArcGISBaseMap = .elevationTerrain
    
    func setBaseMap(baseMap: EFBaseMap) {
        self.baseMap = baseMap.toArcGISBaseMap()
    }
}

// Mapping
extension EFBaseMap {
    func toArcGISBaseMap() -> ArcGISBaseMap {
        switch self {
        case .elevation:
            return .elevationTerrain
        case .satellite:
            return .satellite
        }
    }
}*/

@main
struct EFProtoModelledApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
