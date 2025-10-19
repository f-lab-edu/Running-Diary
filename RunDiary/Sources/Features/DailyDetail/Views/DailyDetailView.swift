//
//  DailyDetailView.swift
//  RunDiary
//
//  Created by 김혜지 on 9/23/25.
//

import SwiftUI
import SwiftData

struct DailyDetailView: View {
    @State private var viewModel: any DailyDetailViewModelProtocol
    @Environment(\.modelContext) private var modelContext

    init(viewModel: any DailyDetailViewModelProtocol) {
        self._viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                DateCarouselSection(
                    dates: viewModel.dates,
                    selectedDate: viewModel.selectedDate,
                    onSelectDate: viewModel.selectDate
                )

                Divider()

                RecordContentSection(
                    isLoading: viewModel.isLoading,
                    runningRecord: viewModel.runningRecord,
                    onAddRecord: viewModel.showAddRecordView
                )
            }
            .navigationDestination(
                isPresented: Binding(
                    get: { viewModel.isShowingAddRecord },
                    set: { viewModel.isShowingAddRecord = $0 }
                )
            ) {
                AddRecordView(
                    viewModel: AddRecordViewModel(
                        mode: viewModel.runningRecord == nil ? .add : .edit,
                        date: viewModel.selectedDate,
                        existingRecord: viewModel.runningRecord,
                        healthKitManager: HealthKitManager(),
                        weatherManager: MockWeatherManager(),
                        repository: SwiftDataRunningRecordRepository(modelContext: modelContext),
                        shoeManager: ShoeManager(modelContext: modelContext)
                    )
                )
            }
            .task {
                await viewModel.fetchRunningRecord(for: viewModel.selectedDate)
            }
        }
    }
}

// MARK: - Subviews

private struct DateCarouselSection: View {
    let dates: [Date]
    let selectedDate: Date
    let onSelectDate: (Date) -> Void

    init(dates: [Date], selectedDate: Date, onSelectDate: @escaping (Date) -> Void) {
        self.dates = dates
        self.selectedDate = selectedDate
        self.onSelectDate = onSelectDate
    }

    var body: some View {
        DateCarouselView(
            dates: dates,
            selectedDate: Binding(
                get: { selectedDate },
                set: { onSelectDate($0) }
            )
        )
        .padding(.vertical, 16)
    }
}

private struct RecordContentSection: View {
    let isLoading: Bool
    let runningRecord: RunningRecord?
    let onAddRecord: () -> Void

    init(isLoading: Bool, runningRecord: RunningRecord?, onAddRecord: @escaping () -> Void) {
        self.isLoading = isLoading
        self.runningRecord = runningRecord
        self.onAddRecord = onAddRecord
    }

    var body: some View {
        ScrollView {
            Group {
                if isLoading {
                    ProgressView()
                } else if let record = runningRecord {
                    RecordView(record: record)
                } else {
                    EmptyRecordView(onAddRecord: onAddRecord)
                }
            }
            .padding()
        }
    }
}

// MARK: - Preview

#Preview {
    DailyDetailView(viewModel: DailyDetailViewModel())
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

    let viewModel = PreviewDailyDetailViewModel(mockRecord: mockRecord)
    DailyDetailView(viewModel: viewModel)
}
