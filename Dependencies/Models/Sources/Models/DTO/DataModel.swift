//
//  DataModel.swift
//  RunDiary
//
//  Created by 김혜지 on 10/23/25.
//

import SwiftData

public actor DataModel {
    public static let shared = DataModel()

    private static let container: ModelContainer = {
        let modelContainer: ModelContainer
        do {
            modelContainer = try ModelContainer(for: RunningRecordModel.self)
        } catch {
            fatalError("Failed to initialize ModelContainer: \(error)")
        }
        return modelContainer
    }()

    nonisolated public var modelContainer: ModelContainer {
        Self.container
    }
}
