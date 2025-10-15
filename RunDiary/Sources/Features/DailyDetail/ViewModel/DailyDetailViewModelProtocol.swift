//
//  DailyDetailViewModelProtocol.swift
//  RunDiary
//
//  Created by 김혜지 on 9/23/25.
//

import Foundation
import Observation

protocol DailyDetailViewModelProtocol: Observable {
    var selectedDate: Date { get set }
    var dates: [Date] { get }
    var runningRecord: RunningRecord? { get set }
    var isLoading: Bool { get set }
    var errorMessage: String? { get set }
    var isShowingAddRecord: Bool { get set }

    func selectDate(_ date: Date)
    func fetchRunningRecord(for date: Date) async
    func showAddRecordView()
}
