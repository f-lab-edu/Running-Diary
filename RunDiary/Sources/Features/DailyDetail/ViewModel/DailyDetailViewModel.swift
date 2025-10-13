//
//  DailyDetailViewModel.swift
//  RunDiary
//
//  Created by 김혜지 on 9/23/25.
//

import Foundation
import Observation

@Observable
final class DailyDetailViewModel {
    var selectedDate: Date
    var dates: [Date] = []
    var runningRecord: RunningRecord?
    var isLoading: Bool = false
    var errorMessage: String?

    init() {
        // 오늘 날짜를 초기 선택 날짜로 설정 (시간 정보는 제거하고 날짜만)
        let calendar = Calendar.current
        self.selectedDate = calendar.startOfDay(for: Date())
        setupDates()
    }

    func setupDates() {
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
        // TODO: UseCase 및 Repository 구현 후 데이터 fetch 로직 추가
        // - 서버 API 연동 vs 로컬 DB 저장 방식 결정 필요
        // - UseCase: FetchRunningRecordUseCase
        // - Repository: RunningRecordRepository (protocol)
        // - DataSource: LocalRunningRecordDataSource / RemoteRunningRecordDataSource

        isLoading = true
        errorMessage = nil

        // 임시: 빈 상태 반환
        runningRecord = nil

        isLoading = false
    }

    func showAddRecordView() {
        // TODO: 기록 추가 화면으로 이동
        print("러닝 기록 입력 화면 열기")
    }
}
