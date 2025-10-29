//
//  AddRecordView.swift
//  RunDiary
//
//  Created by 김혜지 on 9/23/25.
//

import SwiftUI

import ComposableArchitecture

struct AddRecordView: View {
    @Bindable var store: StoreOf<AddRecordFeature>
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Group {
                if store.healthKitData.isLoading {
                    ProgressView("피트니스 기록을 가져오는 중입니다!")
                        .progressViewStyle(.circular)
                } else {
                    FormContentView(store: store)
                }
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
            }
            .alert($store.scope(state: \.authorizationAlert, action: \.authorizationAlert))
            .alert($store.scope(state: \.emptyHealthKitDataAlert, action: \.emptyHealthKitDataAlert))
            .overlay {
                if store.isLoading {
                    ProgressView()
                }
            }
        }
    }
}

// MARK: - Form Content

private struct FormContentView: View {
    @Bindable var store: StoreOf<AddRecordFeature>

    var body: some View {
        Form {
            // HealthKit 데이터 섹션
            HealthKitSectionView(
                distance: store.healthKitData.data?.formattedDistance ?? "",
                duration: store.healthKitData.data?.formattedDuration ?? "",
                averagePace: store.healthKitData.data?.averagePace ?? "",
                averageHeartRate: store.healthKitData.data?.formattedAverageHeartRate ?? "",
                averageCadence: store.healthKitData.data?.formattedAverageCadence ?? ""
            )

            // 신발 섹션
            ShoesSectionView(
                selectedShoe: Binding(
                    get: { store.condition.selectedShoe },
                    set: { store.send(.condition(.updateSelectedShoe($0))) }
                ),
                shoes: store.condition.shoes
            )

            // 주법/스타일 섹션
            RunningStyleSectionView(
                selectedStyle: Binding(
                    get: { store.condition.selectedRunningStyle },
                    set: { store.send(.condition(.updateSelectedRunningStyle($0))) }
                ),
                styleOptions: store.condition.runningStyleOptions
            )

            // 통증 부위 섹션
            PainAreasSectionView(
                selectedPainAreas: Binding(
                    get: { store.condition.selectedPainAreas },
                    set: { store.send(.condition(.updateSelectedPainAreas($0))) }
                ),
                painAreaOptions: store.condition.painAreaOptions
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

            // 난이도 섹션
            DifficultyLevelSectionView(
                selectedLevel: Binding(
                    get: { store.selectedDifficultyLevel },
                    set: { store.send(.updateSelectedDifficultyLevel($0)) }
                )
            )
        }
    }
}

// MARK: - Section Views

private struct HealthKitSectionView: View {
    let distance: String
    let duration: String
    let averagePace: String
    let averageHeartRate: String
    let averageCadence: String

    var body: some View {
        Section("피트니스 기록") {
            HStack {
                Text("거리")
                    .foregroundColor(.gray)
                Spacer()
                Text(distance)
                Text("km")
                    .foregroundColor(.gray)
            }

            HStack {
                Text("소요시간")
                    .foregroundColor(.gray)
                Spacer()
                Text(duration)
            }

            HStack {
                Text("평균 페이스")
                    .foregroundColor(.gray)
                Spacer()
                Text(averagePace)
            }

            HStack {
                Text("평균 심박수")
                    .foregroundColor(.gray)
                Spacer()
                Text(averageHeartRate)
                Text("bpm")
                    .foregroundColor(.gray)
            }

            HStack {
                Text("평균 케이던스")
                    .foregroundColor(.gray)
                Spacer()
                Text(averageCadence)
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
            DynamicGridLayout(items: painAreaOptions) { area in
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        if selectedPainAreas.contains(area) {
                            selectedPainAreas.remove(area)
                        } else {
                            selectedPainAreas.insert(area)
                        }
                    }
                } label: {
                    Text(area.rawValue)
                        .font(.subheadline)
                        .bold(selectedPainAreas.contains(area))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 12)
                }
                .buttonStyle(PainAreaButtonStyle(isSelected: selectedPainAreas.contains(area)))
            }
        }
    }
}

private struct RunningStyleSectionView: View {
    @Binding var selectedStyle: RunninStyle?
    let styleOptions: [RunninStyle]

    var body: some View {
        Section("주법") {
            Menu {
                ForEach(styleOptions, id: \.self) { style in
                    Button(style.rawValue) {
                        selectedStyle = style
                    }
                }
            } label: {
                HStack {
                    Text(selectedStyle?.rawValue ?? "어떤 주법으로 달렸나요?")
                        .foregroundColor(selectedStyle == nil ? .gray : .primary)
                    Spacer()
                    Image(systemName: "chevron.down")
                        .foregroundColor(.gray)
                }
            }
        }
    }
}

private struct DifficultyLevelSectionView: View {
    @Binding var selectedLevel: DifficultyLevel?

    var body: some View {
        Section("운동 강도") {
            Menu {
                ForEach(DifficultyLevel.allCases, id: \.self) { level in
                    Button(level.displayName) {
                        selectedLevel = level
                    }
                }
            } label: {
                HStack {
                    Text(selectedLevel?.displayName ?? "운동 강도를 선택해주세요!")
                        .foregroundColor(selectedLevel == nil ? .gray : .primary)
                    Spacer()
                    if let level = selectedLevel {
                        HStack(spacing: 2) {
                            ForEach(1...5, id: \.self) { index in
                                Image(systemName: index <= level.rawValue ? "star.fill" : "star")
                                    .foregroundColor(index <= level.rawValue ? .yellow : .gray)
                                    .font(.caption)
                            }
                        }
                    }
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
                    Text(selectedShoe ?? "어떤 신발을 착용하셨나요?")
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

// MARK: - Pain Area Button Style

private struct PainAreaButtonStyle: ButtonStyle {
    let isSelected: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundColor(isSelected ? .white : .primary)
            .background(isSelected ? Color.blue : Color.clear)
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(isSelected ? Color.clear : Color.gray.opacity(0.3), lineWidth: 1)
            )
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
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
