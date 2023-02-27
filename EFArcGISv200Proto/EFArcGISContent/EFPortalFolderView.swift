// Copyright 2022 Esri.

// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
// http://www.apache.org/licenses/LICENSE-2.0

// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import SwiftUI
import ArcGIS

struct EFPortalFolderView: View {
    
    @State var portal: Portal
    
    @ObservedObject var contentViewModel : EFUserContentViewModel
    
    var body: some View {
        Group {
            VStack {
                if contentViewModel.portalFolderModels.keys.isEmpty {
                    ProgressView("Loading Content Folders")
                } else {
                    let alphaFolderList = contentViewModel.portalFolderModels.values.sorted { $0.folderTitle.lowercased() < $1.folderTitle.lowercased() }
                    List(alphaFolderList) { folderModel in
                        NavigationLink(destination: ContentFolderView(folderModel: folderModel), label: {
                            HStack {
                                Image(systemName: "folder.fill")
                                Text(folderModel.folderTitle)
                            }
                        })
                    }
                    .listStyle(.plain)
                }
            }
            .refreshable {
                Task {
                    await contentViewModel.updatePortalUserFolders(portal: portal)
                }
            }
        }
        .onAppear() {
            if let _ = portal.user, portal.loadStatus == .loaded {
                if contentViewModel.portalFolderModels.isEmpty {
                    Task {
                        await contentViewModel.updatePortalUserFolders(portal: portal)
                    }
                }
            } else {
                Task {
                    try await contentViewModel.loadPortal(portal: portal)
                }
            }
        }
    }
}

struct ContentFolderView: View {
    
    var folderModel: EFPortalItemFolderModel
    
    var body: some View {
        Group {
            VStack {
                if folderModel.portalItemModels.keys.isEmpty {
                    Text("0 layer items")
                } else {
                    let alphaItemList = folderModel.portalItemModels.values.sorted { $0.portalItem.title.lowercased() < $1.portalItem.title.lowercased() }
                    List(alphaItemList) { itemModel in
                        EFPortalItemView(item: itemModel)
                    }
                    .listStyle(.plain)
                }
            }
        
            // Will add a model function to refresh the folder
//            .refreshable {
//                Task {
//                    await contentViewModel.updatePortalUserFolders(portal: portal)
//                }
//            }
        }
        .navigationTitle(folderModel.portalFolder?.title ?? "")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct EFPortalFolderView_Preview: PreviewProvider {

    static var previews: some View {
        EFPortalFolderView(portal: .arcGISOnline(connection: .anonymous), contentViewModel: EFUserContentViewModel_Preview())
    }
}

