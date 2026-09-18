//
//  AddPlantView.swift
//  Plantydex
//
//  "Add Plant" sheet presented from the Log tab. Wraps the shared identify flow;
//  finishing dismisses the sheet.
//

import SwiftUI

struct AddPlantView: View {
    @Binding var isPresented: Bool
    let onComplete: () -> Void

    var body: some View {
        NavigationStack {
            IdentifyFlowView(finishTitle: "Done", finishIcon: "checkmark") {
                onComplete()
                isPresented = false
            }
            .navigationTitle("Add Plant")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { isPresented = false }
                }
            }
        }
    }
}

#Preview {
    AddPlantView(isPresented: .constant(true)) {}
}
