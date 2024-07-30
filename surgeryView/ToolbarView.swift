//
//  ToolbarView.swift
//  surgeryView
//
//  Created by Tony Zhang on 6/6/24.
//

import SwiftUI

struct ToolbarView: View {
    @Environment(ModelData.self) var modelData: ModelData
    var body: some View {
        HStack{
            if modelData.minimalUI {
                Text(modelData.getLocalIPAddress() ?? "No IP Address found, check wifi settings")
                    .font(.title)
            } else {
                Button {
                    modelData.resetPositions()
                } label: {
                    Label("Reset Positions", systemImage: "arrow.counterclockwise.circle")
                }
                Button {
                    modelData.explodeModels(1)
                } label: {
                    Label("Explode Models", systemImage: "arrow.up.backward.and.arrow.down.forward.square")
                }
            }
        }
        .tint(.black.opacity(0.5))
        .padding()
        .background(.ultraThickMaterial)
        .clipShape(.capsule)
    }
}

#Preview {
    ToolbarView()
}
