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
                DateCarouselSection(store: store)

                Divider()

                RecordContentSection(store: store)
            }
            .sheet(isPresented: Binding(
                get: { store.isShowingAddRecord },
                set: { if !$0 { store.send(.hideAddRecord) } }
            )) {
                // TODO: AddRecordView TCA 통합 후 구현
                Text("기록 추가")
            }
            .task {
                store.send(.onAppear)
            }
        }
    }
}

// MARK: - Subviews

private struct DateCarouselSection: View {
    let store: StoreOf<DailyDetailFeature>

    var body: some View {
        DateCarouselView(
            dates: store.dates,
            selectedDate: Binding(
                get: { store.selectedDate },
                set: { store.send(.dateSelected($0)) }
            )
        )
        .padding(.vertical, 16)
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
