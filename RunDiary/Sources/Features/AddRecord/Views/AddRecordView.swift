//
//  AddRecordView.swift
//  RunDiary
//
//  Created by 김혜지 on 9/23/25.
//

import SwiftUI

struct AddRecordView: View {
    @State private var viewModel: AddRecordViewModel
    @Environment(\.dismiss) private var dismiss

    init(viewModel: AddRecordViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        NavigationStack {
            Form {
                // HealthKit 데이터 섹션
                healthKitSection

                // 통증 부위 섹션
                painAreasSection

                // 주법/스타일 섹션
                runningStyleSection

                // 컨디션 섹션
                conditionSection

                // 신발 섹션
                shoesSection
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

    // MARK: - Health Kit Section

    private var healthKitSection: some View {
        Section("주요 지표") {
            HStack {
                Text("거리")
                    .foregroundColor(.gray)
                Spacer()
                TextField("0.00", text: $viewModel.distance)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                    .allowsHitTesting(!viewModel.isHealthKitDataLoaded)
                Text("km")
                    .foregroundColor(.gray)
            }

            HStack {
                Text("평균 페이스")
                    .foregroundColor(.gray)
                Spacer()
                TextField("0'00\"", text: $viewModel.averagePace)
                    .multilineTextAlignment(.trailing)
                    .allowsHitTesting(!viewModel.isHealthKitDataLoaded)
            }

            HStack {
                Text("평균 심박수")
                    .foregroundColor(.gray)
                Spacer()
                TextField("0", text: $viewModel.averageHeartRate)
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.trailing)
                    .allowsHitTesting(!viewModel.isHealthKitDataLoaded)
                Text("bpm")
                    .foregroundColor(.gray)
            }

            HStack {
                Text("평균 케이던스")
                    .foregroundColor(.gray)
                Spacer()
                TextField("0", text: $viewModel.averageCadence)
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.trailing)
                    .allowsHitTesting(!viewModel.isHealthKitDataLoaded)
                Text("spm")
                    .foregroundColor(.gray)
            }
        }
    }

    // MARK: - Pain Areas Section

    private var painAreasSection: some View {
        Section("통증 부위") {
            Menu {
                ForEach(viewModel.painAreaOptions, id: \.self) { area in
                    Button(action: {
                        if viewModel.selectedPainAreas.contains(area) {
                            viewModel.selectedPainAreas.remove(area)
                        } else {
                            viewModel.selectedPainAreas.insert(area)
                        }
                    }) {
                        HStack {
                            Text(area)
                            if viewModel.selectedPainAreas.contains(area) {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            } label: {
                HStack {
                    Text(viewModel.selectedPainAreas.isEmpty ? "선택하세요" : viewModel.selectedPainAreas.joined(separator: ", "))
                        .foregroundColor(viewModel.selectedPainAreas.isEmpty ? .gray : .primary)
                    Spacer()
                    Image(systemName: "chevron.down")
                        .foregroundColor(.gray)
                }
            }
        }
    }

    // MARK: - Running Style Section

    private var runningStyleSection: some View {
        Section("주법/스타일") {
            Menu {
                ForEach(viewModel.runningStyleOptions, id: \.self) { style in
                    Button(style) {
                        viewModel.selectedRunningStyle = style
                    }
                }
            } label: {
                HStack {
                    Text(viewModel.selectedRunningStyle ?? "선택하세요")
                        .foregroundColor(viewModel.selectedRunningStyle == nil ? .gray : .primary)
                    Spacer()
                    Image(systemName: "chevron.down")
                        .foregroundColor(.gray)
                }
            }
        }
    }

    // MARK: - Condition Section

    private var conditionSection: some View {
        Section("컨디션") {
            HStack {
                Text("수면 시간")
                    .foregroundColor(.gray)
                Spacer()
                TextField("0", text: $viewModel.sleepHours)
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.trailing)
                Text("시간")
                    .foregroundColor(.gray)
            }

            HStack {
                Text("식사 여부")
                    .foregroundColor(.gray)
                Spacer()
                CheckboxView(isChecked: $viewModel.hadMeal)
            }

            HStack {
                Text("음주 여부")
                    .foregroundColor(.gray)
                Spacer()
                CheckboxView(isChecked: $viewModel.hadAlcohol)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("기타 메모")
                    .foregroundColor(.gray)
                TextEditor(text: $viewModel.memo)
                    .frame(minHeight: 100)
            }
        }
    }

    // MARK: - Shoes Section

    private var shoesSection: some View {
        Section("착용 신발") {
            Menu {
                ForEach(viewModel.shoes, id: \.id) { shoe in
                    Button(shoe.name) {
                        viewModel.selectedShoe = shoe.name
                    }
                }
            } label: {
                HStack {
                    Text(viewModel.selectedShoe ?? "선택하세요")
                        .foregroundColor(viewModel.selectedShoe == nil ? .gray : .primary)
                    Spacer()
                    Image(systemName: "chevron.down")
                        .foregroundColor(.gray)
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
    // Preview는 실제 동작하지 않으므로, ViewModel 의존성은 생략
    // 실제 실행 시 DailyDetailView에서 의존성 주입됨
    Text("AddRecordView Preview")
        .font(.title)
        .foregroundColor(.gray)
}
