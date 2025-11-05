//
//  AddRecordView.swift
//  RunDiary
//
//  Created by 김혜지 on 9/23/25.
//

import ComposableArchitecture
import SwiftUI
import Models

struct AddRecordView: View {
    @Bindable var store: StoreOf<AddRecordFeature>
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Group {
                if store.healthKitData.isLoading {
                    ProgressView(L10n.Healthkit.Data.loading)
                        .progressViewStyle(.circular)
                } else {
                    FormContentView(store: store)
                }
            }
            .navigationTitle(store.mode == .add ? L10n.Record.add : L10n.Record.edit)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L10n.UI.cancel) {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button(L10n.UI.save) {
                        store.send(.saveRecord)
                    }
                    .disabled(store.isLoading || !store.isFormValid)
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

            // 메모 섹션
            MemoSectionView(
                memo: Binding(
                    get: { store.condition.memo },
                    set: { store.send(.condition(.updateMemo($0))) }
                )
            )
        }
        .scrollDismissesKeyboard(.interactively)
        .simultaneousGesture(
            TapGesture().onEnded {
                hideKeyboard()
            }
        )
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button(L10n.UI.done) {
                    hideKeyboard()
                }
            }
        }
    }

    private func hideKeyboard() {
        UIApplication.shared.sendAction(
            #selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
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
        Section(L10n.Record.fitnessData) {
            HStack {
                Text(L10n.Record.Field.distance)
                    .foregroundColor(.gray)
                Spacer()
                Text(distance)
                Text(L10n.Unit.km)
                    .foregroundColor(.gray)
            }

            HStack {
                Text(L10n.Record.Field.duration)
                    .foregroundColor(.gray)
                Spacer()
                Text(duration)
            }

            HStack {
                Text(L10n.Record.Field.pace)
                    .foregroundColor(.gray)
                Spacer()
                Text(averagePace)
            }

            HStack {
                Text(L10n.Record.Field.heartRate)
                    .foregroundColor(.gray)
                Spacer()
                Text(averageHeartRate)
                Text(L10n.Unit.bpm)
                    .foregroundColor(.gray)
            }

            HStack {
                Text(L10n.Record.Field.cadence)
                    .foregroundColor(.gray)
                Spacer()
                Text(averageCadence)
                Text(L10n.Unit.spm)
                    .foregroundColor(.gray)
            }
        }
    }
}

private struct PainAreasSectionView: View {
    @Binding var selectedPainAreas: Set<PainArea>
    let painAreaOptions: [PainArea]

    var body: some View {
        Section(L10n.Record.Field.painAreas) {
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
        Section(L10n.Record.Field.runningStyle) {
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
        Section(L10n.Record.Field.intensity) {
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
        Section(L10n.Record.Field.condition) {
            HStack {
                Text(L10n.Record.Field.sleepDuration)
                    .foregroundColor(.gray)
                Spacer()
                TextField("8", text: $sleepHours)
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.trailing)
                    .onChange(of: sleepHours) { oldValue, newValue in
                        // 빈 값 허용 (입력 전/전체 삭제)
                        if newValue.isEmpty {
                            return
                        }

                        // 정수 변환 및 범위 검증
                        if let value = Int(newValue) {
                            if value < 1 {
                                // 1 미만 → 1로 자동 보정
                                sleepHours = "1"
                            } else if value > 24 {
                                // 24 초과 → 24로 자동 보정
                                sleepHours = "24"
                            }
                            // 1~24 범위는 그대로 유지
                        } else {
                            // 숫자가 아닌 경우 → 이전 값으로 되돌림
                            sleepHours = oldValue
                        }
                    }
                Text(L10n.Unit.hours)
                    .foregroundColor(.gray)
            }

            HStack {
                Text(L10n.Record.Field.hasMeal)
                    .foregroundColor(.gray)
                Spacer()
                CheckboxView(isChecked: $hadMeal)
            }

            HStack {
                Text(L10n.Record.Field.wasDrinking)
                    .foregroundColor(.gray)
                Spacer()
                CheckboxView(isChecked: $hadAlcohol)
            }
        }
    }
}

private struct ShoesSectionView: View {
    @Binding var selectedShoe: String?

    var body: some View {
        Section(L10n.Record.Field.shoes) {
            Menu {
                ForEach(ShoeStorage.shared.shoes, id: \.id) { shoe in
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
            .menuStyle(.button)
        }
    }
}

private struct MemoSectionView: View {
    @Binding var memo: String

    var body: some View {
        Section(L10n.Record.Field.memo) {
            ZStack(alignment: .topLeading) {
                TextEditor(text: $memo)
                    .frame(minHeight: 150)

                if memo.isEmpty {
                    Text(L10n.Record.Field.memoPlaceholder)
                        .foregroundColor(.gray)
                        .padding(.top, 8)
                        .padding(.leading, 5)
                        .allowsHitTesting(false)
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
