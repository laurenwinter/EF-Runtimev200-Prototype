//
//  EFBasemapDataModel.swift
//  EFArcGISv200Proto
//
//  Created by Lauren Winter on 1/17/23.
//

import SwiftUI
import ArcGIS
import ArcGISToolkit

/// A very basic data model class containing a Map. Since a `Map` is not an observable object,
/// clients can use `MapDataModel` as an example of how you would store a map in a data model
/// class. The class inherits from `ObservableObject` and the `Map` is defined as a @Published
/// property. This allows SwiftUI views to be updated automatically when a new map is set on the model.
/// Being stored in the model also prevents the map from continually being created during redraws.
/// The data model class would be expanded upon in client code to contain other properties required
/// for the model.
class EFBasemapDataModel {
    /// The `GeoModel` used for display in a `SceneView`.
    public var geoModel: GeoModel? {
        didSet {
            geoModelDidChange(oldValue)
        }
    }
    
    /// The initial list of basemaps.
    public let basemaps = initialBasemaps()
            
    /// Creates a `MapDataModel`.
    /// - Parameter map: The `Map` used for display.
    init(geoModel: GeoModel) {
        self.geoModel = geoModel
    }
    
    private static func initialEndpointBasemaps() -> [BasemapGalleryItem] {
        let identifiers = [
            "46a87c20f09e4fc48fa3c38081e0cae6",
            "f33a34de3a294590ab48f246e99958c9",
            "52bdc7ab7fb044d98add148764eaa30a",  // <<== mismatched spatial reference
            "3a8d410a4a034a2ba9738bb0860d68c4"   // <<== incorrect portal item type
        ]
        
        return identifiers.map { identifier in
            let url = URL(string: "https://www.arcgis.com/home/item.html?id=\(identifier)")!
            return BasemapGalleryItem(basemap: Basemap(item: PortalItem(url: url)!))
        }
    }
    
    private static func initialBasemaps() -> [BasemapGalleryItem] {
        let identifiers = [
            Basemap.Style.arcGISLightGray,
            Basemap.Style.arcGISImageryStandard,
            Basemap.Style.arcGISTerrain,
            Basemap.Style.arcGISStreets,
            Basemap.Style.arcGISNavigationNight
        ]
        
        return identifiers.map { identifier in
            return BasemapGalleryItem(basemap: Basemap(style: identifier))
        }
    }
        
    /// Handles changes to the `geoModel` property.
    /// - Parameter previousGeoModel: The previously set `GeoModel`.
    private func geoModelDidChange(_ previousGeoModel: GeoModel?) {
        guard let geoModel = geoModel else { return }
        if geoModel.loadStatus != .loaded {
            Task {
                try? await geoModel.load()
            }
        }
    }
}

