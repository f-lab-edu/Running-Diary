//
//  ShoesSectionView.swift
//  RunDiary
//
//  Created by 김혜지 on 12/5/25.
//

import Models
import SwiftUI

struct ShoesSectionView: View {
    @State private var isMenuOpen = false

    @Binding var selectedShoe: ShoeModel?

    init(selectedShoe: Binding<ShoeModel?>) {
        self._selectedShoe = selectedShoe
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            L10n.Record.Field.shoes.text
                .font(.headline)
                .padding(.bottom, 4)

            Menu {
                ForEach(ShoeStorage.shoes) { shoe in
                    Button(shoe.name) {
                        selectedShoe = shoe
                    }
                }
            } label: {
                HStack {
                    Text(selectedShoe?.name ?? L10n.Record.Field.shoesPlaceholder.value)
                        .foregroundColor(selectedShoe == nil ? .gray : .primary)
                    Spacer()
                    Image(systemName: "chevron.down")
                        .foregroundColor(.gray)
                }
            }
            .menuStyle(.button)
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
    }
}
