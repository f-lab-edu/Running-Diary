//
//  RecordView.swift
//  RunDiary
//
//  Created by 김혜지 on 9/23/25.
//

import SwiftUI

struct RecordView: View {
    let record: RunningRecord
    
    init(record: RunningRecord) {
        self.record = record
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // 주요 지표
            if record.distance != nil || record.averagePace != nil {
                VStack(alignment: .leading, spacing: 12) {
                    Text("주요 지표")
                        .font(.headline)

                    HStack(spacing: 20) {
                        if let distance = record.distance {
                            RecordRowView(title: "거리", value: String(format: "%.2f km", distance))
                        }

                        if let pace = record.averagePace {
                            RecordRowView(title: "평균 페이스", value: pace)
                        }
                    }

                    HStack(spacing: 20) {
                        if let heartRate = record.averageHeartRate {
                            RecordRowView(title: "평균 심박수", value: "\(heartRate) bpm")
                        }

                        if let cadence = record.averageCadence {
                            RecordRowView(title: "평균 케이던스", value: "\(cadence) spm")
                        }
                    }
                }
            }

            Divider()

            // 통증 부위
            if !record.painAreas.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("통증 부위")
                        .font(.headline)

                    DynamicGridLayout(items: record.painAreas) { item in
                        Text(item)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.red.opacity(0.1))
                            .foregroundColor(.red)
                            .cornerRadius(8)
                    }
                }

                Divider()
            }

            // 주법/스타일
            if let style = record.runningStyle {
                DetailRowView(title: "주법/스타일", value: style)
                Divider()
            }

            // 컨디션
            VStack(alignment: .leading, spacing: 8) {
                Text("컨디션")
                    .font(.headline)

                if let sleep = record.condition.sleep {
                    DetailRowView(title: "수면", value: sleep)
                }

                if let meal = record.condition.meal {
                    DetailRowView(title: "식사", value: meal)
                }

                if let alcohol = record.condition.alcohol {
                    DetailRowView(title: "음주", value: alcohol)
                }

                if let custom = record.condition.custom {
                    DetailRowView(title: "메모", value: custom)
                }
            }

            Divider()

            // 신발
            if let shoes = record.shoes {
                DetailRowView(title: "오늘 신은 신발", value: shoes)
                Divider()
            }

            // 지도
            if record.hasMap {
                VStack(alignment: .leading, spacing: 8) {
                    Text("러닝 경로")
                        .font(.headline)

                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 200)
                        .cornerRadius(12)
                        .overlay(
                            Text("지도 영역")
                                .foregroundColor(.gray)
                        )
                }
            }
        }
    }
}

private struct RecordRowView: View {
    let title: String
    let value: String
    
    init(title: String, value: String) {
        self.title = title
        self.value = value
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(.gray)

            Text(value)
                .font(.title3)
                .fontWeight(.semibold)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct DetailRowView: View {
    let title: String
    let value: String
    
    init(title: String, value: String) {
        self.title = title
        self.value = value
    }

    var body: some View {
        HStack {
            Text(title)
                .foregroundColor(.gray)

            Spacer()

            Text(value)
                .fontWeight(.medium)
        }
    }
}
