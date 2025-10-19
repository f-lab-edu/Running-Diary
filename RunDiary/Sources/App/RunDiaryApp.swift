//
//  RunDiaryApp.swift
//  RunDiary
//
//  Created by 김혜지 on 9/23/25.
//

import SwiftUI
import SwiftData
import ComposableArchitecture

@main
struct RunDiaryApp: App {
    let modelContainer: ModelContainer
    let store: StoreOf<DailyDetailFeature>

    init() {
        let container: ModelContainer
        do {
            container = try ModelContainer(for: RunningRecordModel.self)
        } catch {
            fatalError("Failed to initialize ModelContainer: \(error)")
        }
        self.modelContainer = container

        let mainContext = container.mainContext
        self.store = Store(initialState: DailyDetailFeature.State()) {
            DailyDetailFeature()
        } withDependencies: {
            $0.repositoryClient = .live(modelContext: mainContext)
        }
    }

    var body: some Scene {
        WindowGroup {
            DailyDetailView(store: store)
                .modelContainer(modelContainer)
        }
    }
}
