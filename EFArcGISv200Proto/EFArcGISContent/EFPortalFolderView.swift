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
import OrderedCollections

struct EFPortalFolderView: View {
    
    @State var portal: Portal
    
    @ObservedObject var contentViewModel : EFUserContentViewModel
    
    var body: some View {
        Group {
            VStack {
                let orderedDict = OrderedDictionary(uniqueKeys: contentViewModel.portalFolderModels.keys, values: contentViewModel.portalFolderModels.values)
                if contentViewModel.portalFolderModels.keys.isEmpty {
                    ProgressView("Loading Content Folders")
                } else {
                    List(orderedDict.values) { folderModel in
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
                let orderedDict = OrderedDictionary(uniqueKeys: folderModel.portalItemModels.keys, values: folderModel.portalItemModels.values)
                if folderModel.portalItemModels.keys.isEmpty {
                    Text("0 layer items")
                } else {
                    List(orderedDict.values) { itemModel in
                        LRWPortalItemView(item: itemModel)
                    }
                    .listStyle(.plain)
                }
            }
        
            // Could add a model function to refresh the folder
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

class EFUserContentViewModel_Preview : EFUserContentViewModel {
    override init() {
        super.init()
        let portal: Portal = .arcGISOnline(connection: .anonymous)
        for index in 1...25 {
            let folderModel = EFPortalItemFolderModel("\(index)", id: "\(index)", portalFolder: nil)
            portalFolderModels[folderModel.portalID] = folderModel
            
        }
        
        for itemIndex in 1...5 {
            let item = EFPortalItemModel(portalItem: PortalItem(portal: portal,
                                                                id: Item.ID(rawValue: "\(itemIndex)")!))
            portalItemModels.append(item)
        }
        
    }
}

struct EFPortalFolderView_Preview: PreviewProvider {

    static var previews: some View {
        EFPortalFolderView(portal: .arcGISOnline(connection: .anonymous), contentViewModel: EFUserContentViewModel_Preview())
    }
}

