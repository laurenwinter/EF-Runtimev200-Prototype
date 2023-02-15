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

struct EFUserContentView: View {
    
    @State var portal: Portal
    
    @ObservedObject var contentViewModel : EFUserContentViewModel
    
    var body: some View {
        Group {
            VStack {
                if contentViewModel.portalItemModels.isEmpty {
                    ProgressView("Loading Folder Items")
                } else {
                    List(contentViewModel.portalItemModels) { item in
                        EFPortalItemView(item: item)
                    }
                    .listStyle(.plain)
                    .padding()
                }
            }
            .refreshable {
                Task {
                    await contentViewModel.updatePortalItems(portal: portal)
                }
            }
        }
        .onAppear() {
            if let _ = portal.user, portal.loadStatus == .loaded {
                Task {
                    await contentViewModel.updatePortalItems(portal: portal)
                }
            } else {
                Task {
                    try await contentViewModel.loadPortal(portal: portal)
                }
            }
        }
    }
}

/// A view that displays information about a portal item for viewing that information within a list.
struct EFPortalItemView: View {
    /// The portal item to display information about.
    var item: EFPortalItemModel

    @State private var isToggled = false
    
    init(item: EFPortalItemModel) {
        self.item = item
        if item.currentState == .visible {
            self.isToggled = true
        } else {
            self.isToggled = false
        }
    }
    
    var body: some View {
        HStack {
            if let thumbnail = item.portalItem.thumbnail {
                LoadableImageView(loadableImage: thumbnail)
                    .frame(width: 50, height: 50)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(item.portalItem.title)
                    .font(.headline)
                    .lineLimit(2)
                Text("Owner: \(item.portalItem.owner)")
                    .font(.caption)
                Text("Views: \(item.portalItem.viewCount)")
                    .font(.caption)
            }
            Spacer()
            
            Toggle("", isOn: $isToggled)
                .frame(width: 50.0)
                .onChange(of: isToggled) { toggledValue in
                    if toggledValue {
                        item.currentState = .visible
                    } else {
                        item.currentState = .hidden
                    }
                    //print("onChange \(item.portalItem.title) is \(toggledValue)")
                }
            
        }
    }
}

struct EFUserContentView_Preview: PreviewProvider {

    static var previews: some View {
        EFUserContentView(portal: .arcGISOnline(connection: .anonymous), contentViewModel: EFUserContentViewModel_Preview())
    }
}
