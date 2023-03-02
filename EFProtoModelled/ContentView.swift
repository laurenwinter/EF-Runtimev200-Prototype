//
//  ContentView.swift
//  EFProtoModelled
//
//  Created by Lauren Winter on 3/1/23.
//

import SwiftUI

struct ContentView: View {
    @StateObject var efMapViewModel = EFMapViewModel()
    var body: some View {
        VStack {
            EFMapView(viewModel: efMapViewModel)
        }
        .padding()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
