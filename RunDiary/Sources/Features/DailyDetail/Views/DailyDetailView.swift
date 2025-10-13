//
//  DailyDetailView.swift
//  RunDiary
//
//  Created by 김혜지 on 9/23/25.
//

import SwiftUI

struct DailyDetailView: View {
    @State private var viewModel: DailyDetailViewModel

    init(viewModel: DailyDetailViewModel) {
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
                if viewModel.isLoading {
                    ProgressView()
                        .padding()
                } else if let record = viewModel.runningRecord {
                    RunningRecordDetailView(record: record)
                        .padding()
                } else {
                    EmptyRecordView(onAddRecord: viewModel.showAddRecordView)
                        .padding()
                }
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
    let viewModel = DailyDetailViewModel()

    // 임시 데이터 주입
    viewModel.runningRecord = RunningRecord(
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

    return DailyDetailView(viewModel: viewModel)
}
