//
//  EFBasemapGalleryView.swift
//  EFArcGISv200Proto
//
//  Created by Lauren Winter on 1/12/23.
//

import SwiftUI
import ArcGIS
import ArcGISToolkit

/// A view that displays the profile of a user.
struct EFBasemapGalleryView: View {
    
    /// The data model containing the `Map` displayed in the `MapView`.
    @StateObject private var dataModel = MapDataModel(
        map: Map(basemapStyle: .arcGISImagery)
    )
    
    /// The persistent ArcGIS layer view model for all the User and Group content
    @ObservedObject var sceneContentViewModel : EFSceneContentViewModel
    
    @Binding var showView: Bool
        
    var body: some View {
        VStack {
            HStack {
                Spacer()
                Button("Done") {
                    showView.toggle()
                }
            }
            .padding()
            .frame(width: 300)
            BasemapGallery(items: sceneContentViewModel.basemaps, geoModel: dataModel.map)
        }
        .frame(height: 280)
        .background(Color.white.opacity(0.9))
        .cornerRadius(10)
        .shadow(radius: 10)
    }
}
