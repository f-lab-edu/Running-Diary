//
//  RunningRecordCard.swift
//  RunDiary
//
//  Created by 김혜지 on 12/5/25.
//

import CommonFoundation
import Models
import SwiftUI

struct RunningRecordCard: View {
    @State private var isFolded: Bool = true

    let record: RunningRecord
    let onEdit: () -> Void

    init(record: RunningRecord, onEdit: @escaping () -> Void) {
        self.record = record
        self.onEdit = onEdit
    }

    var body: some View {
        ZStack(alignment: .topTrailing) {
            VStack(spacing: 10) {
                HStack {
                    Spacer()
                    Text(record.startTime.formattedString(formatter: .hourMinutes))
                        .font(.caption)
                        .foregroundColor(.gray500)
                }

                VStack(spacing: 26) {
                    // HealthKit 데이터
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(spacing: 20) {
                            RecordVerticalRow(
                                title: L10n.recordFieldDistance.value,
                                value: record.distanceInKilometers.to2f
                            )
                            RecordVerticalRow(
                                title: L10n.recordFieldDuration.value,
                                value: record.formattedDuration
                            )
                        }

                        HStack(spacing: 20) {
                            RecordVerticalRow(
                                title: L10n.recordFieldPace.value,
                                value: record.averagePace
                            )
                            RecordVerticalRow(
                                title: L10n.recordFieldHeartRate.value,
                                value: "\(record.averageHeartRate) bpm"
                            )
                        }

                        HStack(spacing: 20) {
                            RecordVerticalRow(
                                title: L10n.recordFieldCadence.value,
                                value: "\(record.averageCadence) spm"
                            )
                        }
                    }

                    if isFolded {
                        Button {
                            withAnimation(.linear(duration: 0.2)) {
                                isFolded = false
                            }
                        } label: {
                            HStack {
                                Spacer()
                                L10n.uiViewDetails.text
                                Image(systemName: "chevron.down")
                                Spacer()
                            }
                            .foregroundStyle(.gray300)
                        }
                        .frame(height: 20)
                    } else {
                        Divider()

                        // 신발
                        if let shoesId = record.shoes, let shoesName = ShoeStorage.search(id: shoesId)?.name {
                            RecordHorizontalRow(
                                title: L10n.recordFieldShoesLabel.value,
                                value: shoesName
                            )
                        }

                        // 주법
                        if let style = record.runningStyle {
                            RecordHorizontalRow(
                                title: L10n.recordFieldRunningStyleLabel.value,
                                value: style.localizedName
                            )
                        }

                        // 통증 부위
                        if !record.painAreas.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                L10n.recordFieldPainAreas.text
                                    .foregroundColor(.gray)

                                DynamicGridLayout(items: record.painAreas) { item in
                                    Text(item.localizedName)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(Color.blue700.opacity(0.1))
                                        .foregroundColor(.blue700)
                                        .cornerRadius(8)
                                }
                            }
                        }

                        Divider()

                        // 날씨 데이터
                        if let weather = record.weather {
                            WeatherSectionView(weather: weather)
                        }

                        Divider()

                        // 수면시간, 식사여부, 음주여부
                        VStack(alignment: .leading, spacing: 14) {
                            if let sleep = record.condition.sleep {
                                RecordHorizontalRow(
                                    title: L10n.recordFieldSleepLabel.value,
                                    value: "\(sleep) \(L10n.unitHours.value)"
                                )
                            }

                            RecordIconRow(
                                title: L10n.recordFieldMealLabel.value,
                                isChecked: record.condition.meal
                            )
                            RecordIconRow(
                                title: L10n.recordFieldAlcoholLabel.value,
                                isChecked: record.condition.alcohol
                            )
                        }

                        // 메모
                        if let memo = record.condition.memo {
                            VStack(spacing: 20) {
                                Image("quotes_leading")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 30)
                                    .opacity(0.3)

                                Text(memo)
                                    .font(.body)
                                    .foregroundColor(.black)
                                    .frame(maxWidth: .infinity)

                                Image("quotes_trailing")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 30)
                                    .opacity(0.3)
                            }
                            .padding(.vertical)
                        }
                    }
                }
            }
            .padding(20)
            .background(Color.white)
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 2)
        }
    }
}
