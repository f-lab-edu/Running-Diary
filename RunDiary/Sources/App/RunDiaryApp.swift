//
//  RunDiaryApp.swift
//  RunDiary
//
//  Created by 김혜지 on 9/23/25.
//

import ComposableArchitecture
import Models
import SwiftData
import SwiftUI

@main
struct RunDiaryApp: App {
    let modelContainer = DataModel.shared.modelContainer
    let store: StoreOf<DailyDetailFeature>

    init() {
        self.store = Store(initialState: DailyDetailFeature.State()) {
            DailyDetailFeature()
                ._printChanges()
        } withDependencies: {
            $0.runningRecordClient = .live(modelContext: DataModel.shared.modelContainer.mainContext)
            $0.healthKitClient = .liveValue
        }
    }

    var body: some Scene {
        WindowGroup {
            DailyDetailView(store: store)
                .modelContainer(modelContainer)
        }
    }
}
