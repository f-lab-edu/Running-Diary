//
//  SettingsView.swift
//  RunDiary
//
//  Created by Claude on 12/15/25.
//

import ComposableArchitecture
import SwiftUI

struct SettingsView: View {
    let store: StoreOf<SettingsFeature>

    var body: some View {
        List {
            Section {
                ForEach(SettingsFeature.SettingsItem.allCases) { item in
                    Button {
                        store.send(.settingsItemTapped(item))
                    } label: {
                        HStack {
                            Text(item.displayName)
                                .foregroundStyle(.primary)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundStyle(.secondary)
                                .font(.caption)
                        }
                    }
                }
            }
        }
        .navigationTitle("설정")
        .navigationBarTitleDisplayMode(.inline)
    }
}
