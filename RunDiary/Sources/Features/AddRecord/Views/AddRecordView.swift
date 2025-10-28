//
//  AddRecordView.swift
//  RunDiary
//
//  Created by 김혜지 on 9/23/25.
//

import SwiftUI

import ComposableArchitecture

import CommonFoundation

struct AddRecordView: View {
    @Bindable var store: StoreOf<AddRecordFeature>
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                // HealthKit 데이터 섹션
                HealthKitSectionView(
                    distance: Binding(
                        get: { store.healthKitData.distance.to2f },
                        set: { store.send(.healthKitData(.updateDistance($0))) }
                    ),
                    duration: Binding(
                        get: { store.healthKitData.duration },
                        set: { store.send(.healthKitData(.updateDuration($0))) }
                    ),
                    averagePace: Binding(
                        get: { store.healthKitData.averagePace },
                        set: { store.send(.healthKitData(.updateAveragePace($0))) }
                    ),
                    averageHeartRate: Binding(
                        get: { store.healthKitData.averageHeartRate.toString },
                        set: { store.send(.healthKitData(.updateAverageHeartRate($0))) }
                    ),
                    averageCadence: Binding(
                        get: { store.healthKitData.averageCadence.toString },
                        set: { store.send(.healthKitData(.updateAverageCadence($0))) }
                    ),
                    isDataLoaded: store.healthKitData.isDataLoaded
                )

                // 통증 부위 섹션
                PainAreasSectionView(
                    selectedPainAreas: Binding(
                        get: { store.condition.selectedPainAreas },
                        set: { store.send(.condition(.updateSelectedPainAreas($0))) }
                    ),
                    painAreaOptions: store.condition.painAreaOptions
                )

                // 주법/스타일 섹션
                RunningStyleSectionView(
                    selectedStyle: Binding(
                        get: { store.condition.selectedRunningStyle },
                        set: { store.send(.condition(.updateSelectedRunningStyle($0))) }
                    ),
                    styleOptions: store.condition.runningStyleOptions
                )

                // 컨디션 섹션
                ConditionSectionView(
                    sleepHours: Binding(
                        get: { store.condition.sleepHours },
                        set: { store.send(.condition(.updateSleepHours($0))) }
                    ),
                    hadMeal: Binding(
                        get: { store.condition.hadMeal },
                        set: { store.send(.condition(.updateHadMeal($0))) }
                    ),
                    hadAlcohol: Binding(
                        get: { store.condition.hadAlcohol },
                        set: { store.send(.condition(.updateHadAlcohol($0))) }
                    ),
                    memo: Binding(
                        get: { store.condition.memo },
                        set: { store.send(.condition(.updateMemo($0))) }
                    )
                )

                // 신발 섹션
                ShoesSectionView(
                    selectedShoe: Binding(
                        get: { store.condition.selectedShoe },
                        set: { store.send(.condition(.updateSelectedShoe($0))) }
                    ),
                    shoes: store.condition.shoes
                )
            }
            .navigationTitle(store.mode == .add ? "기록 추가" : "기록 수정")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("취소") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("저장") {
                        store.send(.saveRecord)
                    }
                    .disabled(store.isLoading)
                }
            }
            .task {
                store.send(.onAppear)
                if store.mode == .add {
                    store.send(.healthKitData(.loadData(store.date)))
                }
            }
            .alert($store.scope(state: \.authorizationAlert, action: \.authorizationAlert))
            .confirmationDialog($store.scope(state: \.satisfactionDialog, action: \.satisfactionDialog))
            .overlay {
                if store.isLoading {
                    ProgressView()
                }
            }
        }
    }

    // MARK: - Helper Methods

    private func saveSatisfactionAndDismiss(satisfaction: Int) {
        store.send(.satisfactionDialog(.presented(.rate(satisfaction))))
        dismiss()
    }
}

// MARK: - Section Views

private struct HealthKitSectionView: View {
    @Binding var distance: String
    @Binding var duration: String
    @Binding var averagePace: String
    @Binding var averageHeartRate: String
    @Binding var averageCadence: String
    let isDataLoaded: Bool

    var body: some View {
        Section("주요 지표") {
            HStack {
                Text("거리")
                    .foregroundColor(.gray)
                Spacer()
                TextField("0.00", text: $distance)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                    .allowsHitTesting(!isDataLoaded)
                Text("km")
                    .foregroundColor(.gray)
            }

            HStack {
                Text("소요시간")
                    .foregroundColor(.gray)
                Spacer()
                TextField("0:00", text: $duration)
                    .multilineTextAlignment(.trailing)
                    .allowsHitTesting(!isDataLoaded)
            }

            HStack {
                Text("평균 페이스")
                    .foregroundColor(.gray)
                Spacer()
                TextField("0'00\"", text: $averagePace)
                    .multilineTextAlignment(.trailing)
                    .allowsHitTesting(!isDataLoaded)
            }

            HStack {
                Text("평균 심박수")
                    .foregroundColor(.gray)
                Spacer()
                TextField("0", text: $averageHeartRate)
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.trailing)
                    .allowsHitTesting(!isDataLoaded)
                Text("bpm")
                    .foregroundColor(.gray)
            }

            HStack {
                Text("평균 케이던스")
                    .foregroundColor(.gray)
                Spacer()
                TextField("0", text: $averageCadence)
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.trailing)
                    .allowsHitTesting(!isDataLoaded)
                Text("spm")
                    .foregroundColor(.gray)
            }
        }
    }
}

private struct PainAreasSectionView: View {
    @Binding var selectedPainAreas: Set<PainArea>
    let painAreaOptions: [PainArea]

    var body: some View {
        Section("통증 부위") {
            Menu {
                ForEach(painAreaOptions, id: \.self) { area in
                    Button(action: {
                        if selectedPainAreas.contains(area) {
                            selectedPainAreas.remove(area)
                        } else {
                            selectedPainAreas.insert(area)
                        }
                    }) {
                        HStack {
                            Text(area.rawValue)
                            if selectedPainAreas.contains(area) {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            } label: {
                HStack {
                    Text(selectedPainAreas.isEmpty ? "선택하세요" : selectedPainAreas.map({$0.rawValue}).joined(separator: ", "))
                        .foregroundColor(selectedPainAreas.isEmpty ? .gray : .primary)
                    Spacer()
                    Image(systemName: "chevron.down")
                        .foregroundColor(.gray)
                }
            }
        }
    }
}

private struct RunningStyleSectionView: View {
    @Binding var selectedStyle: RunninStyle?
    let styleOptions: [RunninStyle]

    var body: some View {
        Section("주법/스타일") {
            Menu {
                ForEach(styleOptions, id: \.self) { style in
                    Button(style.rawValue) {
                        selectedStyle = style
                    }
                }
            } label: {
                HStack {
                    Text(selectedStyle?.rawValue ?? "선택하세요")
                        .foregroundColor(selectedStyle == nil ? .gray : .primary)
                    Spacer()
                    Image(systemName: "chevron.down")
                        .foregroundColor(.gray)
                }
            }
        }
    }
}

private struct ConditionSectionView: View {
    @Binding var sleepHours: String
    @Binding var hadMeal: Bool
    @Binding var hadAlcohol: Bool
    @Binding var memo: String

    var body: some View {
        Section("컨디션") {
            HStack {
                Text("수면 시간")
                    .foregroundColor(.gray)
                Spacer()
                TextField("0", text: $sleepHours)
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.trailing)
                Text("시간")
                    .foregroundColor(.gray)
            }

            HStack {
                Text("식사 여부")
                    .foregroundColor(.gray)
                Spacer()
                CheckboxView(isChecked: $hadMeal)
            }

            HStack {
                Text("음주 여부")
                    .foregroundColor(.gray)
                Spacer()
                CheckboxView(isChecked: $hadAlcohol)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("기타 메모")
                    .foregroundColor(.gray)
                TextEditor(text: $memo)
                    .frame(minHeight: 100)
            }
        }
    }
}

private struct ShoesSectionView: View {
    @Binding var selectedShoe: String?
    let shoes: [ShoeModel]

    var body: some View {
        Section("착용 신발") {
            Menu {
                ForEach(shoes, id: \.id) { shoe in
                    Button(shoe.name) {
                        selectedShoe = shoe.name
                    }
                }
            } label: {
                HStack {
                    Text(selectedShoe ?? "선택하세요")
                        .foregroundColor(selectedShoe == nil ? .gray : .primary)
                    Spacer()
                    Image(systemName: "chevron.down")
                        .foregroundColor(.gray)
                }
            }
        }
    }
}

// MARK: - Checkbox Component

private struct CheckboxView: View {
    @Binding var isChecked: Bool

    var body: some View {
        Button(action: {
            isChecked.toggle()
        }) {
            Image(systemName: isChecked ? "checkmark.square.fill" : "square")
                .foregroundColor(isChecked ? .blue : .gray)
                .font(.title2)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#Preview("Add Mode", traits: .sampleData) {
    AddRecordView(
        store: Store(
            initialState: AddRecordFeature.State(
                date: Date()
            )
        ) {
            AddRecordFeature()
        }
    )
}

#Preview("Edit Mode", traits: .sampleData) {
    AddRecordView(
        store: Store(
            initialState: AddRecordFeature.State(
                date: Date(),
                existingRecord: RunningRecordModel.preview.toDomain()
            )
        ) {
            AddRecordFeature()
        }
    )
}
