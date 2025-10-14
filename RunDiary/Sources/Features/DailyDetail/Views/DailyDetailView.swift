//
//  DailyDetailView.swift
//  RunDiary
//
//  Created by 김혜지 on 9/23/25.
//

import SwiftUI

struct DailyDetailView: View {
    @State private var viewModel: any DailyDetailViewModelProtocol

    init(viewModel: any DailyDetailViewModelProtocol) {
        self.viewModel = viewModel
    }

    var body: some View {
        VStack(spacing: 0) {
            // 상단 날짜 캐러셀
            DateCarouselView(
                dates: viewModel.dates,
                selectedDate: Binding(
                    get: { viewModel.selectedDate },
                    set: { viewModel.selectDate($0) }
                )
            )
            .padding(.vertical, 16)

            Divider()

            // 러닝 기록 또는 빈 상태
            ScrollView {
                Group {
                    if viewModel.isLoading {
                        ProgressView()
                    } else if let record = viewModel.runningRecord {
                        RecordView(record: record)
                    } else {
                        EmptyRecordView(onAddRecord: viewModel.showAddRecordView)
                    }
                }
                .padding()
            }
        }
        .task {
            await viewModel.fetchRunningRecord(for: viewModel.selectedDate)
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
        distance: 5.2,
        averagePace: "5'30\"",
        averageHeartRate: 155,
        averageCadence: 180,
        painAreas: ["무릎", "발목"],
        runningStyle: "포어풋",
        condition: RunningCondition(
            sleep: "7시간",
            meal: "가볍게",
            alcohol: "없음",
            custom: "컨디션 좋음"
        ),
        shoes: "Nike Pegasus 40",
        hasMap: true
    )
    
    let viewModel = PreviewDailyDetailViewModel(mockRecord: mockRecord)
    return DailyDetailView(viewModel: viewModel)
}
