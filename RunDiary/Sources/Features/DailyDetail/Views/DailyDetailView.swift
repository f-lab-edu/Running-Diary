//
//  DailyDetailView.swift
//  RunDiary
//
//  Created by 김혜지 on 9/23/25.
//

import SwiftUI
import SwiftData
import ComposableArchitecture

struct DailyDetailView: View {
    let store: StoreOf<DailyDetailFeature>
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                YearAndMonthSection(date: store.selectedDate)

                DateCarouselSection(store: store)

                Divider()

                RecordContentSection(store: store)
            }
            .sheet(store: store.scope(state: \.$addRecord, action: \.addRecord)) { addRecordStore in
                AddRecordView(store: addRecordStore)
            }
            .task {
                store.send(.onAppear)
            }
        }
    }
}

// MARK: - Subviews

private struct YearAndMonthSection: View {
    let yearAndMonth: String

    init(date: Date) {
        let formatter = DateFormatter()
        formatter.dateFormat = "YYYY년 M월"
        self.yearAndMonth = formatter.string(from: date)
    }

    var body: some View {
        Text(yearAndMonth)
            .font(.title2)
            .fontWeight(.bold)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.leading, 14)
    }
}

private struct DateCarouselSection: View {
    let store: StoreOf<DailyDetailFeature>

    var body: some View {
        DateCarouselView(store: store)
            .padding(.top, 16)
    }
}

private struct RecordContentSection: View {
    let store: StoreOf<DailyDetailFeature>

    var body: some View {
        ScrollView {
            Group {
                if store.isLoading {
                    ProgressView()
                } else if let record = store.runningRecord {
                    RecordView(record: record)
                } else {
                    EmptyRecordView(onAddRecord: { store.send(.showAddRecord) })
                }
            }
            .padding()
        }
        .background(Color(.systemGray6))
    }
}

// MARK: - Preview

#Preview {
    DailyDetailView(
        store: Store(initialState: DailyDetailFeature.State()) {
            DailyDetailFeature()
        } withDependencies: {
            $0.repositoryClient = .previewValue
        }
    )
}

#Preview("With Record") {
    let mockRecord = RunningRecord(
        date: Date(),
        distanceInKilometers: 5.2,
        averagePace: "5'30\"",
        averageHeartRate: 155,
        averageCadence: 180,
        painAreas: ["무릎", "발목"],
        runningStyle: "포어풋",
        condition: RunningCondition(
            sleep: 7,
            meal: true,
            alcohol: false,
            memo: "컨디션 좋음"
        ),
        shoes: "Nike Pegasus 40",
        hasMap: true
    )

    DailyDetailView(
        store: Store(
            initialState: DailyDetailFeature.State(
                runningRecord: mockRecord
            )
        ) {
            DailyDetailFeature()
        } withDependencies: {
            $0.repositoryClient = .previewValue
        }
    )
}
