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
                Button(L10n.uiDone.value) {
                    hideKeyboard()
                }
            }
        }
        .navigationTitle(store.mode == .add ? L10n.recordAdd.value : L10n.recordEdit.value)
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden()
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button(L10n.uiCancel.value) {
                    dismiss()
                }
                .foregroundStyle(.gray500)
            }

            ToolbarItem(placement: .confirmationAction) {
                Button(L10n.uiSave.value) {
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
                        activeEnergyBurned: 450.0,
                        runningVerticalOscillation: 8.2,
                        runningGroundContactTime: 240.0,
                        walkingStepLength: 1.1,
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
                    existingRecord: RunningRecordPersistenceModel.preview.toDomain()
                )
            ) {
                AddRecordFeature()
            }
        )
    }
}
