//
//  AddRecordView.swift
//  RunDiary
//
//  Created by 김혜지 on 9/23/25.
//

import ComposableArchitecture
import CommonFoundation
import SwiftUI
import Models

struct AddRecordView: View {
    @Bindable var store: StoreOf<AddRecordFeature>
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        FormContentView(store: store)
            .navigationTitle(store.mode == .add ? L10n.Record.add.value : L10n.Record.edit.value)
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L10n.UI.cancel.value) {
                        dismiss()
                    }
                    .foregroundStyle(.gray500)
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button(L10n.UI.save.value) {
                        hideKeyboard()
                        store.send(.saveRecord)
                    }
                    .foregroundStyle(store.isLoading || !store.isFormValid ? .blue300.opacity(0.3) : .blue300)
                    .disabled(store.isLoading || !store.isFormValid)
                }
            }
            .task {
                store.send(.onAppear)
            }
            .loadingIndicatorIfNeeded(store.isLoading)
    }
}

// MARK: - Form Content

private struct FormContentView: View {
    @Bindable var store: StoreOf<AddRecordFeature>

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // HealthKit 데이터 섹션
                HealthKitSectionView(
                    distance: store.healthKitWorkout.data?.formattedDistance ?? "",
                    duration: store.healthKitWorkout.data?.formattedDuration ?? "",
                    averagePace: store.healthKitWorkout.data?.averagePace ?? "",
                    averageHeartRate: store.healthKitWorkout.data?.formattedAverageHeartRate ?? "",
                    averageCadence: store.healthKitWorkout.data?.formattedAverageCadence ?? ""
                )

                // 신발 섹션
                ShoesSectionView(
                    selectedShoe: Binding(
                        get: { store.condition.selectedShoe },
                        set: { store.send(.condition(.updateSelectedShoe($0))) }
                    ),
                )

                // 주법 섹션
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
            .padding()
        }
        .background(Color.gray50)
        .scrollDismissesKeyboard(.interactively)
        .hideKeyboardOnTapOutside()
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button(L10n.UI.done.value) {
                    hideKeyboard()
                }
            }
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
        VStack(alignment: .leading, spacing: 16) {
            L10n.Record.fitnessData.text
                .font(.headline)
                .foregroundStyle(.blue700)
                .padding(.bottom, 4)

            VStack(spacing: 12) {
                HStack {
                    L10n.Record.Field.distance.text
                        .foregroundColor(.gray500)
                    Spacer()
                    Text(distance)
                        .foregroundStyle(.blue700)
                    L10n.Unit.km.text
                        .foregroundColor(.gray)
                }

                HStack {
                    L10n.Record.Field.duration.text
                        .foregroundColor(.gray500)
                    Spacer()
                    Text(duration)
                        .foregroundStyle(.blue700)
                }

                HStack {
                    L10n.Record.Field.pace.text
                        .foregroundColor(.gray500)
                    Spacer()
                    Text(averagePace)
                        .foregroundStyle(.blue700)
                }

                HStack {
                    L10n.Record.Field.heartRate.text
                        .foregroundColor(.gray500)
                    Spacer()
                    Text(averageHeartRate)
                        .foregroundStyle(.blue700)
                    L10n.Unit.bpm.text
                        .foregroundColor(.gray)
                }

                HStack {
                    L10n.Record.Field.cadence.text
                        .foregroundColor(.gray500)
                    Spacer()
                    Text(averageCadence)
                        .foregroundStyle(.blue700)
                    L10n.Unit.spm.text
                        .foregroundColor(.gray500)
                }
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
    }
}

private struct PainAreasSectionView: View {
    @Binding var selectedPainAreas: Set<PainArea>
    let painAreaOptions: [PainArea]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            L10n.Record.Field.painAreas.text
                .font(.headline)
                .padding(.bottom, 4)

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
                    Text(area.localizedName)
                        .font(.subheadline)
                        .bold(selectedPainAreas.contains(area))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 12)
                }
                .buttonStyle(PainAreaButtonStyle(isSelected: selectedPainAreas.contains(area)))
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
    }
}

private struct RunningStyleSectionView: View {
    @Binding var selectedStyle: RunninStyle?
    let styleOptions: [RunninStyle]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            L10n.Record.Field.runningStyle.text
                .font(.headline)
                .padding(.bottom, 4)

            Menu {
                ForEach(styleOptions, id: \.self) { style in
                    Button(style.localizedName) {
                        selectedStyle = style
                    }
                }
            } label: {
                HStack {
                    Text(selectedStyle?.localizedName ?? L10n.Record.Field.runningStylePlaceholder.value)
                        .foregroundColor(selectedStyle == nil ? .gray : .primary)
                    Spacer()
                    Image(systemName: "chevron.down")
                        .foregroundColor(.gray)
                }
                .padding(.vertical, 8)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
    }
}

private struct DifficultyLevelSectionView: View {
    @Binding var selectedLevel: DifficultyLevel?

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            L10n.Record.Field.intensity.text
                .font(.headline)
                .padding(.bottom, 4)

            Menu {
                ForEach(DifficultyLevel.allCases, id: \.self) { level in
                    Button(level.displayName) {
                        selectedLevel = level
                    }
                }
            } label: {
                HStack {
                    Text(selectedLevel?.displayName ?? L10n.Record.Field.intensityPlaceholder.value)
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
                .padding(.vertical, 8)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
    }
}

private struct ConditionSectionView: View {
    @Binding var sleepHours: String
    @Binding var hadMeal: Bool
    @Binding var hadAlcohol: Bool
    @Binding var memo: String

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            L10n.Record.Field.condition.text
                .font(.headline)
                .padding(.bottom, 4)

            VStack(spacing: 12) {
                HStack {
                    L10n.Record.Field.sleepDuration.text
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
                    L10n.Unit.hours.text
                        .foregroundColor(.gray)
                }

                HStack {
                    L10n.Record.Field.hasMeal.text
                        .foregroundColor(.gray)
                    Spacer()
                    CheckboxView(isChecked: $hadMeal)
                }

                HStack {
                    L10n.Record.Field.wasDrinking.text
                        .foregroundColor(.gray)
                    Spacer()
                    CheckboxView(isChecked: $hadAlcohol)
                }
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
    }
}

private struct ShoesSectionView: View {
    @State private var isMenuOpen = false

    @Binding var selectedShoe: ShoeModel?

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            L10n.Record.Field.shoes.text
                .font(.headline)
                .padding(.bottom, 4)

            Menu {
                ForEach(ShoeStorage.shoes) { shoe in
                    Button(shoe.name) {
                        selectedShoe = shoe
                    }
                }
            } label: {
                HStack {
                    Text(selectedShoe?.name ?? L10n.Record.Field.shoesPlaceholder.value)
                        .foregroundColor(selectedShoe == nil ? .gray : .primary)
                    Spacer()
                    Image(systemName: "chevron.down")
                        .foregroundColor(.gray)
                }
            }
            .menuStyle(.button)
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
    }
}

private struct MemoSectionView: View {
    @Binding var memo: String

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            L10n.Record.Field.memo.text
                .font(.headline)
                .padding(.bottom, 4)

            ZStack(alignment: .topLeading) {
                TextEditor(text: $memo)
                    .frame(minHeight: 150)
                    .padding(4)
                    .background(Color(.systemBackground))
                    .cornerRadius(8)

                if memo.isEmpty {
                    Text(L10n.Record.Field.memoPlaceholder.value)
                        .foregroundColor(.gray)
                        .padding(.top, 12)
                        .padding(.leading, 9)
                        .allowsHitTesting(false)
                }
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
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
            .foregroundColor(isSelected ? .white : .gray500)
            .background(isSelected ? Color.blue700 : Color.white)
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(isSelected ? Color.blue700 : Color.gray100, lineWidth: 1)
            )
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - Preview

#Preview("Add Mode", traits: .sampleData) {
    NavigationStack {
        AddRecordView(
            store: Store(
                initialState: AddRecordFeature.State(
                    healthKitWorkout: HealthKitWorkout(
                        distance: 5.2,
                        duration: 3665,  // 1시간 1분 5초
                        averagePace: "5'30\"",
                        averageHeartRate: 155,
                        averageCadence: 180,
                        routeData: nil,
                        startDate: .now,
                        endDate: .now
                    )
                )
            ) {
                AddRecordFeature()
            }
        )
    }
}

#Preview("Edit Mode", traits: .sampleData) {
    NavigationStack {
        AddRecordView(
            store: Store(
                initialState: AddRecordFeature.State(
                    existingRecord: RunningRecordSwiftData.preview.toDomain()
                )
            ) {
                AddRecordFeature()
            }
        )
    }
}
