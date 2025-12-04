//
//  HealthKitSectionView.swift
//  RunDiary
//
//  Created by 김혜지 on 12/5/25.
//

import SwiftUI

struct HealthKitSectionView: View {
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
