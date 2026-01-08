//
//  DailyDetailView.swift
//  RunDiary
//
//  Created by 김혜지 on 9/23/25.
//

import CommonFoundation
import ComposableArchitecture
import Models
import SwiftUI

struct DailyDetailView: View {
    let store: StoreOf<DailyDetailFeature>

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                YearAndMonthSection(
                    yearMonthDay: store.selectedDate,
                    onCalendarTap: {
                        store.send(.calendarButtonTapped)
                    },
                    onSettingsTap: {
                        store.send(.settingsButtonTapped)
                    }
                )

                DateCarouselSection(store: store)

                Divider()

                RecordContentSection(store: store)
            }
            .refreshable {
                await store.send(.refreshCurrentWeek).finish()
            }
            .navigationDestination(store: store.scope(state: \.$addRecord, action: \.addRecord)) { addRecordStore in
                AddRecordView(store: addRecordStore)
            }
            .navigationDestination(store: store.scope(state: \.$settings, action: \.settings)) { settingsStore in
                SettingsView(store: settingsStore)
            }
            .task {
                store.send(.onAppear)
            }
        }
        .sheet(store: store.scope(state: \.$calendar, action: \.calendar)) { calendarStore in
            CalendarView(store: calendarStore)
                .presentationDragIndicator(.visible)
            // TODO: sheet height를 지정해주면 content 전체가 같이 축소되는 버그 발생
//                .presentationDetents([.height(screenHeight * 0.8)])
        }
    }
}

// MARK: - Subviews

struct YearAndMonthSection: View {
    let title: String
    let onCalendarTap: () -> Void
    let onSettingsTap: () -> Void

    init(yearMonthDay: YearMonthDay, onCalendarTap: @escaping () -> Void, onSettingsTap: @escaping () -> Void) {
        self.title = DateHelper.formattedYearMonth(year: yearMonthDay.year, month: yearMonthDay.month)
        self.onCalendarTap = onCalendarTap
        self.onSettingsTap = onSettingsTap
    }

    var body: some View {
        HStack {
            Button {
                onCalendarTap()
            } label: {
                HStack(spacing: 2) {
                    Text(title)
                        .font(.title2)
                        .fontWeight(.bold)
                        .padding(.leading, 14)

                    Image(systemName: "chevron.right")
                        .scaledToFit()
                }
                .foregroundStyle(.blue700)
            }

            Spacer()

            Button {
                onSettingsTap()
            } label: {
                Image(systemName: "gearshape")
                    .foregroundStyle(.blue700)
                    .font(.title3)
                    .padding(.trailing, 14)
            }
        }
        .frame(height: 48)
    }
}

struct DateCarouselSection: View {
    let store: StoreOf<DailyDetailFeature>

    var body: some View {
        DateCarouselView(store: store)
            .padding(.top, 16)
    }
}

struct RecordContentSection: View {
    let store: StoreOf<DailyDetailFeature>

    var body: some View {
        ScrollView(.vertical) {
            if let currentDailyRecord = store.state.currentDailyRecord {
                RecordListView(store: store, dailyRecord: currentDailyRecord)
            } else {
                EmptyRecordView(error: store.error)
            }
        }
        .background(Color.gray50)
        .loadingIndicatorIfNeeded(store.isLoading, backgroundColor: .gray50)
    }
}

// MARK: - Preview

#Preview(traits: .sampleData) {
    DailyDetailView(
        store: Store(initialState: DailyDetailFeature.State()) {
            DailyDetailFeature()
        } withDependencies: {
            $0.swiftDataClient = .previewValue
        }
    )
}

#Preview("With Record", traits: .sampleData) {
    let previewRecord = RunningRecordPersistenceModel.preview.toDomain()
    let previewDate = Calendar.current.startOfDay(for: previewRecord.startTime)
    let previewKey = YearMonthDay(date: previewDate)

    DailyDetailView(
        store: Store(
            initialState: DailyDetailFeature.State(
                selectedDate: previewRecord.yearMonthDay,
                cachedRecords: [
                    previewKey: DailyRecord(
                        yearMonthDay: previewRecord.yearMonthDay,
                        healthKitWorkouts: [],
                        savedRecords: [previewRecord]
                    )
                ]
            )
        ) {
            DailyDetailFeature()
        } withDependencies: {
            $0.swiftDataClient = .previewValue
        }
    )
}
