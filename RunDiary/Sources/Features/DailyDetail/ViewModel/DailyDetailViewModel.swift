//
//  DailyDetailViewModel.swift
//  RunDiary
//
//  Created by 김혜지 on 9/23/25.
//

import Foundation
import Observation

// MARK: - Production Implementation

@Observable
final class DailyDetailViewModel: DailyDetailViewModelProtocol {
    var selectedDate: Date
    var dates: [Date] = []
    var runningRecord: RunningRecord?
    var isLoading: Bool = false
    var errorMessage: String?
    var isShowingAddRecord: Bool = false

    private let repository: RunningRecordRepositoryProtocol?

    init(repository: RunningRecordRepositoryProtocol? = nil) {
        // 오늘 날짜를 초기 선택 날짜로 설정 (시간 정보는 제거하고 날짜만)
        let calendar = Calendar.current
        self.selectedDate = calendar.startOfDay(for: Date())
        self.repository = repository
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
        Task {
            await fetchRunningRecord(for: date)
        }
    }

    @MainActor
    func fetchRunningRecord(for date: Date) async {
        guard let repository = repository else {
            runningRecord = nil
            return
        }

        isLoading = true
        errorMessage = nil

        do {
            runningRecord = try await repository.fetch(for: date)
        } catch {
            errorMessage = "기록을 불러올 수 없습니다: \(error.localizedDescription)"
            runningRecord = nil
        }

        isLoading = false
    }

    func showAddRecordView() {
        isShowingAddRecord = true
    }
}
