//
//  DailyDetailViewModel.swift
//  RunDiary
//
//  Created by 김혜지 on 9/23/25.
//

import Foundation
import Observation

// MARK: - Protocol

protocol DailyDetailViewModelProtocol: Observable {
    var selectedDate: Date { get set }
    var dates: [Date] { get }
    var runningRecord: RunningRecord? { get set }
    var isLoading: Bool { get set }
    var errorMessage: String? { get set }
    
    func selectDate(_ date: Date)
    func fetchRunningRecord(for date: Date) async
    func showAddRecordView()
}

// MARK: - Production Implementation

@Observable
final class DailyDetailViewModel: DailyDetailViewModelProtocol {
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

// MARK: - Preview Implementation

@Observable
final class PreviewDailyDetailViewModel: DailyDetailViewModelProtocol {
    var selectedDate: Date
    var dates: [Date] = []
    var runningRecord: RunningRecord?
    var isLoading: Bool = false
    var errorMessage: String?
    
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
        print("프리뷰: 러닝 기록 입력 화면 열기")
    }
}
