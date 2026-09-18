//
//  PlantUploadView.swift
//  Plantydex
//
//  Upload tab. Wraps the shared identify flow; finishing jumps to the Log tab.
//

import SwiftUI

struct PlantUploadView: View {
    @Binding var selectedTab: Int

    var body: some View {
        NavigationStack {
            IdentifyFlowView(finishTitle: "Go to Log", finishIcon: "list.bullet") {
                selectedTab = 0
            }
            .navigationTitle("Upload Plant")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

#Preview {
    PlantUploadView(selectedTab: .constant(1))
}
