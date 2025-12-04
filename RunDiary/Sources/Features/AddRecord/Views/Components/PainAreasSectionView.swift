//
//  PainAreasSectionView.swift
//  RunDiary
//
//  Created by 김혜지 on 12/5/25.
//

import Models
import SwiftUI

struct PainAreasSectionView: View {
    @Binding var selectedPainAreas: Set<PainArea>
    let painAreaOptions: [PainArea]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            L10n.recordFieldPainAreas.text
                .font(.headline)
                .padding(.bottom, 4)

            DynamicGridLayout(items: painAreaOptions) { area in
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        if selectedPainAreas.contains(area) {
                            selectedPainAreas.remove(area)
                        } else {
                            selectedPainAreas.insert(area)
                        }
                    }
                } label: {
                    Text(area.localizedName)
                        .font(.subheadline)
                        .bold(selectedPainAreas.contains(area))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 12)
                }
                .buttonStyle(PainAreaButtonStyle(isSelected: selectedPainAreas.contains(area)))
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
    }
}

struct PainAreaButtonStyle: ButtonStyle {
    let isSelected: Bool

    init(isSelected: Bool) {
        self.isSelected = isSelected
    }

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundColor(isSelected ? .white : .gray500)
            .background(isSelected ? Color.blue700 : Color.white)
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(isSelected ? Color.blue700 : Color.gray100, lineWidth: 1)
            )
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}
