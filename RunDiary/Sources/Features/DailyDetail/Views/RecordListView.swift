//
//  RecordListView.swift
//  RunDiary
//
//  Created by 김혜지 on 9/23/25.
//

import CommonFoundation
import ComposableArchitecture
import Models
import SwiftUI

struct RecordListView: View {
    let store: StoreOf<DailyDetailFeature>
    let dailyRecord: DailyRecord

    init(
        store: StoreOf<DailyDetailFeature>,
        dailyRecord: DailyRecord
    ) {
        self.store = store
        self.dailyRecord = dailyRecord
    }

    var body: some View {
        if dailyRecord.hasAnyData {
            LazyVStack(spacing: 12) {
                ForEach(dailyRecord.savedRecords) { record in
                    RunningRecordCard(record: record, onEdit: { store.send(.editRecord(record)) })
                }

                if !dailyRecord.savedRecords.isEmpty && !dailyRecord.healthKitWorkouts.isEmpty {
                    Divider()
                        .padding(.vertical, 10)
                }

                ForEach(dailyRecord.healthKitWorkouts) { record in
                    HealthKitWorkoutCard(record: record, onCreate: { store.send(.createRecord(record)) })
                }
            }
            .padding(.vertical, 20)
            .padding(.horizontal, 20)
        } else {
            EmptyRecordView()
        }
    }
}



// MARK: - Preview

#Preview(traits: .sampleData) {
    ScrollView(.vertical) {
        RunningRecordCard(record: RunningRecordPersistenceModel.preview.toDomain(), onEdit: {})
    }
}
