//
//  EFBasemapGalleryView.swift
//  EFArcGISv200Proto
//
//  Created by Lauren Winter on 1/12/23.
//

import SwiftUI
import ArcGISToolkit

/// A view that displays the profile of a user.
struct EFBasemapGalleryView: View {
    
    /// The persistent ArcGIS layer view model for all the User and Group content
    var baseMapDataModel : EFBasemapDataModel
    
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
            BasemapGallery(items: baseMapDataModel.basemaps, geoModel: baseMapDataModel.geoModel)
        }
        .frame(width: 600, height: 600)
        .background(Color.white.opacity(0.9))
        .cornerRadius(10)
        .shadow(radius: 10)
    }
}
