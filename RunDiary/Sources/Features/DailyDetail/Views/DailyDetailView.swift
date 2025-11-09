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
                YearAndMonthSection(date: store.selectedDate) {
                    store.send(.calendarButtonTapped)
                }

                DateCarouselSection(store: store)

                Divider()

                RecordContentSection(store: store)
            }
            .navigationDestination(store: store.scope(state: \.$addRecord, action: \.addRecord)) { addRecordStore in
                AddRecordView(store: addRecordStore)
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

private struct YearAndMonthSection: View {
    let yearAndMonth: String
    let onCalendarTap: () -> Void

    init(date: Date, onCalendarTap: @escaping () -> Void) {
        let formatter = DateFormatter()
        formatter.dateFormat = "YYYY년 M월"
        self.yearAndMonth = formatter.string(from: date)
        self.onCalendarTap = onCalendarTap
    }

    var body: some View {
        HStack {
            Button {
                onCalendarTap()
            } label: {
                HStack(spacing: 2) {
                    Text(yearAndMonth)
                        .font(.title2)
                        .fontWeight(.bold)
                        .padding(.leading, 14)

                    Image(systemName: "chevron.right")
                        .scaledToFit()
                }
                .foregroundStyle(.blue700)
            }

            Spacer()
        }
    }
}

private struct DateCarouselSection: View {
    let store: StoreOf<DailyDetailFeature>

    var body: some View {
        DateCarouselView(store: store)
            .padding(.top, 16)
    }
}

private struct RecordContentSection: View {
    let store: StoreOf<DailyDetailFeature>

    var body: some View {
        ScrollView(.vertical) {
            Group {
                if let record = store.currentRecord {
                    RecordView(record: record, onEdit: { store.send(.showAddRecord) })
                } else {
                    EmptyRecordView(
                        error: store.error,
                        onAddRecord: { store.send(.showAddRecord) }
                    )
                }
            }
        }
        .background(Color.gray50)
    }
}

// MARK: - Preview

#Preview(traits: .sampleData) {
    DailyDetailView(
        store: Store(initialState: DailyDetailFeature.State()) {
            DailyDetailFeature()
        } withDependencies: {
            $0.repositoryClient = .previewValue
        }
    )
}

#Preview("With Record", traits: .sampleData) {
    let previewRecord = RunningRecordModel.preview.toDomain()
    let previewDate = Calendar.current.startOfDay(for: previewRecord.date)

    return DailyDetailView(
        store: Store(
            initialState: DailyDetailFeature.State(
                selectedDate: previewDate,
                cachedRecords: [previewDate: .some(previewRecord)]
            )
        ) {
            DailyDetailFeature()
        } withDependencies: {
            $0.repositoryClient = .previewValue
        }
    )
}
