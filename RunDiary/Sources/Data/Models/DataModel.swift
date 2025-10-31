//
//  DataModel.swift
//  RunDiary
//
//  Created by 김혜지 on 10/23/25.
//

import SwiftData

actor DataModel {
  static let shared = DataModel()

  private static let container: ModelContainer = {
    let modelContainer: ModelContainer
    do {
      modelContainer = try ModelContainer(for: RunningRecordModel.self)
    } catch {
      fatalError("Failed to initialize ModelContainer: \(error)")
    }
    return modelContainer
    //        self.modelContainer = container
    //
    //        let mainContext = container.mainContext
    //        self.store = Store(initialState: DailyDetailFeature.State()) {
    //            DailyDetailFeature()
    //        } withDependencies: {
    //            $0.repositoryClient = .live(modelContext: mainContext)
    //        }
  }()

  nonisolated var modelContainer: ModelContainer {
    Self.container
  }
}
