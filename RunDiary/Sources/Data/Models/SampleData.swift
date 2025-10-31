//
//  SampleData.swift
//  RunDiary
//
//  Created by 김혜지 on 10/23/25.
//

import SwiftData
import SwiftUI

// 임시(in-memory) 데이터베이스를 구성하고, RunningRecordModel 모델을 샘플 데이터로 생성해서 삽입합니다.
struct SampleData: PreviewModifier {
  static func makeSharedContext() async throws -> ModelContainer {
    let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try ModelContainer(for: RunningRecordModel.self, configurations: configuration)
    SampleData.createSampleData(into: container.mainContext)
    return container
  }

  func body(content: Content, context: ModelContainer) -> some View {
    content.modelContainer(context)
  }

  @MainActor
  private static func createSampleData(into modelContext: ModelContext) {
    let sampleRecords: [RunningRecordModel] = RunningRecordModel.previewRecords
    sampleRecords.forEach {
      modelContext.insert($0)
    }
    try? modelContext.save()
  }
}

extension PreviewTrait where T == Preview.ViewTraits {
  @MainActor static var sampleData: Self = .modifier(SampleData())
}

// 참고 샘플 프로젝트 : https://developer.apple.com/documentation/coredata/adopting-swiftdata-for-a-core-data-app
