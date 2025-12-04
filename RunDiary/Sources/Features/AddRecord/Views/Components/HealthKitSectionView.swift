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
            L10n.recordFitnessData.text
                .font(.headline)
                .foregroundStyle(.blue700)
                .padding(.bottom, 4)

            VStack(spacing: 12) {
                HStack {
                    L10n.recordFieldDistance.text
                        .foregroundColor(.gray500)
                    Spacer()
                    Text(distance)
                        .foregroundStyle(.blue700)
                    L10n.unitKm.text
                        .foregroundColor(.gray)
                }

                HStack {
                    L10n.recordFieldDuration.text
                        .foregroundColor(.gray500)
                    Spacer()
                    Text(duration)
                        .foregroundStyle(.blue700)
                }

                HStack {
                    L10n.recordFieldPace.text
                        .foregroundColor(.gray500)
                    Spacer()
                    Text(averagePace)
                        .foregroundStyle(.blue700)
                }

                HStack {
                    L10n.recordFieldHeartRate.text
                        .foregroundColor(.gray500)
                    Spacer()
                    Text(averageHeartRate)
                        .foregroundStyle(.blue700)
                    L10n.unitBpm.text
                        .foregroundColor(.gray)
                }

                HStack {
                    L10n.recordFieldCadence.text
                        .foregroundColor(.gray500)
                    Spacer()
                    Text(averageCadence)
                        .foregroundStyle(.blue700)
                    L10n.unitSpm.text
                        .foregroundColor(.gray500)
                }
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
    }
}
