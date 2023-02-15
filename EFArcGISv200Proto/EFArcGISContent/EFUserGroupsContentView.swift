//
//  EFUserGroupsContentView.swift
//  EFArcGISv200Proto
//
//  Created by Lauren Winter on 2/14/23.
//

import SwiftUI
import ArcGIS

struct EFUserGroupsContentView: View {
    
    @State var portal: Portal
    
    @ObservedObject var contentViewModel : EFUserContentViewModel
    
    var body: some View {
        Group {
            VStack {
                if contentViewModel.portalGroupModels.keys.isEmpty {
                    ProgressView("Loading Groups")
                } else {
                    let alphaFolderList = contentViewModel.portalGroupModels.values.sorted { $0.groupTitle.lowercased() < $1.groupTitle.lowercased() }
                    List(alphaFolderList) { groupModel in
                        NavigationLink(destination: EFGroupView(groupModel: groupModel), label: {
                            HStack {
                                Image(systemName: "folder.fill")
                                Text(groupModel.groupTitle)
                            }
                        })
                    }
                    .listStyle(.plain)
                }
            }
            .refreshable {
                Task {
                    await contentViewModel.updatePortalGroups(portal: portal)
                }
            }
        }
        .onAppear() {
            if let _ = portal.user, portal.loadStatus == .loaded {
                Task {
                    await contentViewModel.updatePortalGroups(portal: portal)
                }
            } else {
                Task {
                    try await contentViewModel.loadPortal(portal: portal)
                }
            }
        }
    }
}

struct EFGroupView: View {
    
    @ObservedObject var groupModel: EFPortalGroupModel
    
    var body: some View {
        Group {
            VStack {
                    if groupModel.portalItemModels.keys.isEmpty {
                        Text("0 layer items")
                    } else {
                        let alphaItemList = groupModel.portalItemModels.values.sorted { $0.portalItem.title.lowercased() < $1.portalItem.title.lowercased() }
                        List(alphaItemList) { itemModel in
                            EFPortalItemView(item: itemModel)
                        }
                        .listStyle(.plain)
                    }
//                }
            }
            
            .onAppear() {
                if groupModel.searchResultSet == nil {
                    ProgressView("Loading Group Items")
                    Task {
                        await groupModel.loadGroupItems()
                    }
                }
            }
        
            // Need task to fetch more group items when the user scrolls to the bottom of the list
            
            // Will add a model function to refresh the group
//            .refreshable {
//                Task {
//                    await contentViewModel.updatePortalUserGroups(portal: portal)
//                }
//            }
        }
        .navigationTitle(groupModel.portalGroup?.title ?? "")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct EFUserGroupsContentView_Preview: PreviewProvider {

    static var previews: some View {
        EFPortalFolderView(portal: .arcGISOnline(connection: .anonymous), contentViewModel: EFUserContentViewModel_Preview())
    }
}


