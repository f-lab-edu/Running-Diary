//
//  PreviewDailyDetailViewModel.swift
//  RunDiary
//
//  Created by 김혜지 on 9/23/25.
//

import Foundation
import Observation

// MARK: - Preview Implementation

@Observable
final class PreviewDailyDetailViewModel: DailyDetailViewModelProtocol {
    var selectedDate: Date
    var dates: [Date] = []
    var runningRecord: RunningRecord?
    var isLoading: Bool = false
    var errorMessage: String?
    var isShowingAddRecord: Bool = false

    init(mockRecord: RunningRecord? = nil) {
        let calendar = Calendar.current
        self.selectedDate = calendar.startOfDay(for: Date())
        self.runningRecord = mockRecord
        setupDates()
    }

    private func setupDates() {
        let calendar = Calendar.current
        var dateArray: [Date] = []

        // 오늘 기준 전후 2주씩 생성
        for offset in -14...14 {
            if let date = calendar.date(byAdding: .day, value: offset, to: Date()) {
                dateArray.append(calendar.startOfDay(for: date))
            }
        }

        dates = dateArray
    }

    func selectDate(_ date: Date) {
        selectedDate = date
        // 프리뷰에서는 fetch하지 않음
    }

    @MainActor
    func fetchRunningRecord(for date: Date) async {
        // 프리뷰에서는 기존 데이터 유지, fetch하지 않음
    }

    func showAddRecordView() {
        isShowingAddRecord = true
    }
}
