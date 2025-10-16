//
//  AddRecordView.swift
//  RunDiary
//
//  Created by 김혜지 on 9/23/25.
//

import SwiftUI

struct AddRecordView: View {
    @State private var viewModel: any AddRecordViewModelProtocol
    @Environment(\.dismiss) private var dismiss

    init(viewModel: any AddRecordViewModelProtocol) {
        self.viewModel = viewModel
    }

    var body: some View {
        NavigationStack {
            Form {
                // HealthKit 데이터 섹션
                HealthKitSectionView(
                    distance: $viewModel.distance,
                    averagePace: $viewModel.averagePace,
                    averageHeartRate: $viewModel.averageHeartRate,
                    averageCadence: $viewModel.averageCadence,
                    isDataLoaded: viewModel.isHealthKitDataLoaded
                )

                // 통증 부위 섹션
                PainAreasSectionView(
                    selectedPainAreas: $viewModel.selectedPainAreas,
                    painAreaOptions: viewModel.painAreaOptions
                )

                // 주법/스타일 섹션
                RunningStyleSectionView(
                    selectedStyle: $viewModel.selectedRunningStyle,
                    styleOptions: viewModel.runningStyleOptions
                )

                // 컨디션 섹션
                ConditionSectionView(
                    sleepHours: $viewModel.sleepHours,
                    hadMeal: $viewModel.hadMeal,
                    hadAlcohol: $viewModel.hadAlcohol,
                    memo: $viewModel.memo
                )

                // 신발 섹션
                ShoesSectionView(
                    selectedShoe: $viewModel.selectedShoe,
                    shoes: viewModel.shoes
                )
            }
            .navigationTitle(viewModel.mode == .add ? "기록 추가" : "기록 수정")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("취소") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("저장") {
                        Task {
                            await viewModel.saveRecord { success in
                                if success {
                                    // 만족도 알럿 표시 후 닫힘
                                } else {
                                    // 에러 처리
                                }
                            }
                        }
                    }
                    .disabled(viewModel.isLoading)
                }
            }
            .task {
                if viewModel.mode == .add {
                    await viewModel.loadHealthKitData()
                }
            }
            .alert("러닝 만족도", isPresented: $viewModel.showSatisfactionAlert) {
                Button("1점") {
                    viewModel.selectedSatisfaction = 1
                    saveSatisfactionAndDismiss()
                }
                Button("2점") {
                    viewModel.selectedSatisfaction = 2
                    saveSatisfactionAndDismiss()
                }
                Button("3점") {
                    viewModel.selectedSatisfaction = 3
                    saveSatisfactionAndDismiss()
                }
                Button("4점") {
                    viewModel.selectedSatisfaction = 4
                    saveSatisfactionAndDismiss()
                }
                Button("5점") {
                    viewModel.selectedSatisfaction = 5
                    saveSatisfactionAndDismiss()
                }
                Button("건너뛰기", role: .cancel) {
                    dismiss()
                }
            } message: {
                Text("오늘 러닝에 만족하셨나요?")
            }
            .overlay {
                if viewModel.isLoading {
                    ProgressView()
                }
            }
        }
    }

    // MARK: - Helper Methods

    private func saveSatisfactionAndDismiss() {
        Task {
            await viewModel.saveSatisfaction { success in
                if success {
                    dismiss()
                }
            }
        }
    }
}

// MARK: - Section Views

private struct HealthKitSectionView: View {
    @Binding var distance: String
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
    @Binding var selectedPainAreas: Set<String>
    let painAreaOptions: [String]

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
                            Text(area)
                            if selectedPainAreas.contains(area) {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            } label: {
                HStack {
                    Text(selectedPainAreas.isEmpty ? "선택하세요" : selectedPainAreas.joined(separator: ", "))
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
    @Binding var selectedStyle: String?
    let styleOptions: [String]

    var body: some View {
        Section("주법/스타일") {
            Menu {
                ForEach(styleOptions, id: \.self) { style in
                    Button(style) {
                        selectedStyle = style
                    }
                }
            } label: {
                HStack {
                    Text(selectedStyle ?? "선택하세요")
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

#Preview("Add Mode") {
    AddRecordView(viewModel: PreviewAddRecordViewModel(mode: .add))
}

#Preview("Edit Mode") {
    AddRecordView(viewModel: PreviewAddRecordViewModel(mode: .edit))
}
