//
//  HealthKitWorkoutCard.swift
//  RunDiary
//
//  Created by 김혜지 on 12/5/25.
//

import CommonFoundation
import Models
import SwiftUI

struct HealthKitWorkoutCard: View {
    let workout: HealthKitWorkout
    let onCreate: () -> Void

    init(
        record: HealthKitWorkout,
        onCreate: @escaping () -> Void
    ) {
        self.workout = record
        self.onCreate = onCreate
    }

    var body: some View {
        ZStack {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Spacer()
                    Text(workout.startDate.formattedString(formatter: .hourMinutes))
                        .font(.caption)
                }

                HStack(spacing: 20) {
                    RecordVerticalRow(title: L10n.recordFieldDistance.value, value: workout.distance.to2f)
                    RecordVerticalRow(title: L10n.recordFieldDuration.value, value: workout.formattedDuration)
                }

                HStack(spacing: 20) {
                    RecordVerticalRow(title: L10n.recordFieldPace.value, value: workout.averagePace)
                    RecordVerticalRow(title: L10n.recordFieldHeartRate.value, value: "\(workout.averageHeartRate) bpm")
                }

                HStack(spacing: 20) {
                    RecordVerticalRow(title: L10n.recordFieldCadence.value, value: "\(workout.averageCadence) spm")
                }
            }
            .padding(20)
            .background(Color.white)

            Color.gray500.opacity(0.5)

            Button(action: onCreate) {
                ZStack {
                    Capsule()
                        .foregroundStyle(.yellow100)

                    L10n.recordWriteDiaryButton.text
                        .fontWeight(.semibold)
                        .foregroundColor(.blue700)
                        .padding()
                }
                .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, 20)
        }
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 2)
    }
}
