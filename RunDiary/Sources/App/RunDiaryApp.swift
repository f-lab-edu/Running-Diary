//
//  RunDiaryApp.swift
//  RunDiary
//
//  Created by 김혜지 on 9/23/25.
//

import ComposableArchitecture
import SwiftData
import SwiftUI

@main
struct RunDiaryApp: App {
  let modelContainer = DataModel.shared.modelContainer

  init() {}

    var body: some Scene {
        WindowGroup {
            DailyDetailView(store: Store(initialState: DailyDetailFeature.State()) {
                DailyDetailFeature()
            } withDependencies: {
                $0.repositoryClient = .live(modelContext: modelContainer.mainContext)
            })
        }
      )
      .modelContainer(modelContainer)
    }
  }
}
